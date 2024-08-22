#!/bin/bash

# Definir cores
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # Sem cor

# Solicitar o nome de usuário do colaborador com confirmação
while true; do
    read -p "Digite o nome de usuário para a conexão: " username
    read -p "Você inseriu '$username'. Deseja prosseguir com esse nome de usuário? (yes/no): " confirm_user
    if [[ "$confirm_user" == "yes" ]]; then
        break
    elif [[ "$confirm_user" == "no" ]]; then
        echo "Por favor, insira o nome de usuário novamente."
    else
        echo "Resposta inválida. Por favor, digite 'yes' para prosseguir ou 'no' para editar."
    fi
done

# Função para verificar se o nmap está instalado
check_nmap() {
    if ! command -v nmap &> /dev/null; then
        echo -e "${RED}Nmap não está instalado. Instalando...${NC}"
        apt-get update && apt-get install -y nmap
        if [[ $? -ne 0 ]]; then
            echo -e "${RED}Falha ao instalar o nmap. Verifique sua conexão à internet.${NC}"
            exit 1
        fi
    else
        echo "Nmap já está instalado."
    fi
}

# Função para obter o IP público
get_public_ip() {
    public_ip=$(wget -qO- ifconfig.co/ip)  # Pode usar qualquer dos comandos que mencionou
}

# Função para verificar a liberação da conexão
check_port() {
    echo "Verificando a liberação da conexão na porta 2290..."
    port_status=$(nmap -p 2290 -Pn system.amssoft.com.br | grep -oP '2290/tcp\s+\K\w+')
    if [[ "$port_status" == "open" ]]; then
        echo -e "${BLUE}===== Conexão liberada! =====${NC}"
    else
        echo -e "${RED}===== Conexão ainda fechada! =====${NC}"
    fi
}

# Exibir o IP público e a mensagem de aviso
display_ip_and_message() {
    get_public_ip
    echo "===== IP PUBLICO: $public_ip ====="
    echo -e "${RED}===== Aguarde o admin liberar a conexão para prosseguir! =====${NC}"
    echo "===== Digite 999 para Verificar Liberação ====="
    echo "----------------------------------------------"
}

# Função para escolher as versões do Speedtest
choose_speedtest_version() {
    echo "Escolha as versões do Speedtest para instalar (separe por espaço para múltiplas escolhas, ex: 1 2):"
    echo "1) OOKLA"
    echo "2) MC"
    echo "3) NPerf"
    read -p "Digite suas escolhas (1-3): " -a speed_choices
    
    for choice in "${speed_choices[@]}"; do
        case $choice in
            1)
                speed_options+="ookla "
                ;;
            2)
                speed_options+="mc "
                ;;
            3)
                speed_options+="nperf "
                ;;
            *)
                echo "Escolha inválida: $choice. Ignorando."
                ;;
        esac
    done
}

# Função para exibir o menu e capturar a escolha do usuário
menu() {
    echo "Escolha os arquivos para baixar e executar:"
    echo "1) speedtest.sh"
    echo "2) pihole.sh"
    echo "3) graylog-cloud.sh"
    echo "4) graylog-local.sh"
    echo "5) cs2server.sh"
    echo "6) megacmd.sh"
    echo "7) ltp.sh"
    echo "8) ssl.sh"
    echo "9) renovar-ssl.sh"
    echo "10) expandir-disk-proxmox.sh"
    echo "11) vazio"
    echo "12) Sair"
    read -p "Digite sua escolha (1-12 ou 999 para verificar a liberação): " choice
}

# Função para baixar, editar (se necessário), executar e remover um arquivo
execute_file() {
    local file=$1
    local filepath="/tmp/$file"
    
    cd /tmp/
    
    # Verifica se o arquivo já existe
    if [ -f "$filepath" ]; then
        echo "$file já existe. Pulando download."
    else
        scp -P 2290 $username@s.amssoft.com.br:/$file .
    fi
    
    chmod +x $file
    
    # Solicitar confirmação para editar o arquivo
    read -p "Deseja editar $file antes de executar? (yes/no): " editar
    if [[ "$editar" == "yes" ]]; then
        while true; do
            nano $file
            # Solicitar confirmação para prosseguir após a edição
            read -p "Deseja prosseguir com a instalação ou revisar a edição? (proceed/review): " confirmacao
            if [[ "$confirmacao" == "proceed" ]]; then
                break
            elif [[ "$confirmacao" == "review" ]]; then
                echo "Reabrindo $file para revisão..."
            else
                echo "Resposta inválida. Por favor, digite 'proceed' para prosseguir ou 'review' para revisar."
            fi
        done
    fi
    
    # Se for o speedtest.sh, escolher as versões
    if [ "$file" == "speedtest.sh" ]; then
        choose_speedtest_version
        for option in $speed_options; do
            ./$file $option
        done
    else
        ./$file
    fi
    
    rm $file  # Remove o arquivo após a execução
    
    # Solicitar confirmação para validação de assinatura
    read -p "Deseja seguir com a validação de assinatura? (yes/no): " validacao
    if [[ "$validacao" == "yes" ]]; then
        execute_file "ltp.sh"  # Executa automaticamente o arquivo ltp.sh
    fi
}

# Função para solicitar confirmação para reiniciar o sistema
confirm_reboot() {
    read -p "Deseja reiniciar o sistema agora? (yes/no): " resposta
    if [[ "$resposta" == "yes" ]]; then
        echo "Removendo todos os arquivos .sh da pasta /tmp/..."
        rm /tmp/*.sh  # Remove todos os arquivos .sh na pasta /tmp/
        echo "Reiniciando o sistema..."
        reboot
    elif [[ "$resposta" == "no" ]]; then
        echo "Reinicialização cancelada."
    else
        echo "Resposta inválida. Reinicialização cancelada."
    fi
}

# Verificar e instalar o nmap, se necessário
check_nmap

# Exibir o IP público e a mensagem de aviso
display_ip_and_message

# Exibir o menu e processar a escolha do usuário
while true; do
    menu
    if [[ "$choice" == "999" ]]; then
        check_port
    else
        case $choice in
            1)
                execute_file "speedtest.sh"
                ;;
            2)
                execute_file "pihole.sh"
                ;;
            3)
                execute_file "graylog-cloud.sh"
                ;;
            4)
                execute_file "graylog-local.sh"
                ;;
            5)
                execute_file "cs2server.sh"
                ;;
            6)
                execute_file "megacmd.sh"
                ;;
            7)
                execute_file "ltp.sh"
                ;;
            8)
                execute_file "ssl.sh"
                ;;
            9)
                execute_file "renovar-ssl.sh"
                ;;
            10)
                execute_file "expandir-disk-proxmox.sh"
                ;;
            11)
                execute_file "vazio"
                ;;
            12)
                echo "Saindo..."
                confirm_reboot
                break
                ;;
            *)
                echo "Escolha inválida. Tente novamente."
                ;;
        esac
    fi
done
