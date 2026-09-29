#!/usr/bin/env bash

sudo apt install arp-scan -y >/dev/null 2>&1

# Procura o diretório do EVE-NG
VM_DIR=$(find "$HOME/vmware" -maxdepth 1 -type d -name 'EVE_CCM_CIPI*' | head -n1)

if [ -z "$VM_DIR" ]; then
    echo "Não encontrei o diretório do EVE-NG."
    exit 1
fi

# Procura o arquivo VMX dentro do diretório encontrado
VMX=$(find "$VM_DIR" -maxdepth 1 -type f -name '*.vmx' | head -n1)

if [ -z "$VMX" ]; then
    echo "Não encontrei o arquivo .vmx."
    exit 1
fi

echo "VM encontrada: $VMX"

echo "Iniciando serviços do VMware..."
sudo /etc/init.d/vmware start

echo "Iniciando EVE-NG..."
vmrun start "$VMX" nogui >/dev/null 2>&1

# Pega o MAC da VM
MAC=$(grep -i "generatedAddress" "$VMX" | head -1 | cut -d'"' -f2 | tr '[:upper:]' '[:lower:]')

echo "MAC: $MAC"
echo "Aguardando o EVE-NG pegar IP..."

for i in {1..40}; do

    IP=$(sudo arp-scan --localnet 2>/dev/null | \
        awk -v mac="$MAC" 'tolower($2)==mac {print $1}' | head -n1)

    if [ -n "$IP" ]; then
        echo
        echo "EVE-NG iniciado!"
        echo "IP: $IP"
        echo "URL: http://$IP"

        xdg-open "http://$IP" >/dev/null 2>&1 &

        exit 0
    fi

    echo "Tentativa $i/40..."
    sleep 3
done

echo "Não consegui localizar o IP da VM."
exit 1
