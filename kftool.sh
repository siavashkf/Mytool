#!/bin/bash

show_menu() {
    clear
    echo "----------------------------------"
    echo "Backhaul Installer"
    echo "https://github.com/PixelShellGIT"
    echo "Thanks to Musixal"
    echo "----------------------------------"
    ipv4=$(ip -4 a | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1")
    ipv6=$(ip -6 a | grep -oP '(?<=inet6\s)[a-fA-F0-9:]+(?=/)' | grep -v "::1")
    echo "IPv4: $ipv4"
    if [ -z "$ipv6" ]; then
        echo -e "IPv6: \e[31mNot Available\e[0m"
    else
        echo "IPv6: $ipv6"
    fi
    echo "----------------------------------"
    echo "1 - Install core"
    echo "2 - Configure"
    echo "3 - Uninstall core"
    echo "4 - Update core"
    echo "5 - Restart core"
    echo "6 - Status"
    echo "10 - Install ezwarp"
    echo "11 - Install x-UI"
    echo "12 - Install Tool"
    echo "0 - Exit"
}

install_core() {
    clear
    echo "Installing core..."
    arch=$(uname -m)
    mkdir -p backhaul
    cd backhaul
    if [ "$arch" == "x86_64" ]; then
        wget https://github.com/Musixal/Backhaul/releases/download/v0.6.3/backhaul_linux_amd64.tar.gz
        tar -xf backhaul_linux_amd64.tar.gz
        rm backhaul_linux_amd64.tar.gz
    elif [ "$arch" == "aarch64" ]; then
        wget https://github.com/Musixal/Backhaul/releases/download/v0.6.3/backhaul_darwin_arm64.tar.gz
        tar -xf backhaul_darwin_arm64.tar.gz
        rm backhaul_darwin_arm64.tar.gz
    else
        echo "Unsupported architecture: $arch"
        sleep 2
        return
    fi
    chmod +x backhaul
    mv backhaul /usr/bin/backhaul
    echo "Backhaul installed successfully!"
    sleep 2
    cd ..
}

uninstall_core() {
    echo "Uninstalling core..."
    rm -f /usr/bin/backhaul
    echo "Backhaul uninstalled successfully!"
    sleep 2
}

update_core() {
    echo "Updating core..."
    rm -f /usr/bin/backhaul
    install_core
    sudo systemctl restart backhaul.service
    echo "Backhaul updated successfully!"
    sleep 2
}

restart_core() {
    echo "Restarting core..."
    sudo systemctl restart backhaul.service
    echo "Backhaul restarted successfully!"
    sleep 2
}

status_core() {
    sudo systemctl status backhaul.service
    echo -e "\nPress Enter to return to menu..."
    read -r
}

install_ezwarp() {
    echo "Installing ezwarp..."
    set -e

    architecture() {
      case "$(uname -m)" in
        'i386' | 'i686') arch='386' ;;
        'x86_64') arch='amd64' ;;
        'armv5tel') arch='armv5' ;;
        'armv6l') arch='armv6' ;;
        'armv7' | 'armv7l') arch='armv7' ;;
        'aarch64') arch='arm64' ;;
        'mips64el') arch='mips64le_softfloat' ;;
        'mips64') arch='mips64_softfloat' ;;
        'mipsel') arch='mipsle_softfloat' ;;
        'mips') arch='mips_softfloat' ;;
        's390x') arch='s390x' ;;
        *) echo "error: The architecture is not supported."; return 1 ;;
      esac
      echo "$arch"
    }

    if [ "$(id -u)" -ne 0 ]; then
        echo "This script requires root privileges. Please run it as root."
        exit 1
    fi

    apt update && apt upgrade
    ubuntu_major_version=$(grep DISTRIB_RELEASE /etc/lsb-release | cut -d'=' -f2 | cut -d'.' -f1)
    if [[ "$ubuntu_major_version" == "24" ]]; then
      sudo apt install -y wireguard
    else
      sudo apt install -y wireguard-dkms wireguard-tools resolvconf
    fi

    if ! command -v wg-quick &> /dev/null
    then
        echo "something went wrong with wireguard package installation"
        exit 1
    fi
    if ! command -v resolvconf &> /dev/null
    then
        echo "something went wrong with resolvconf package installation"
        exit 1
    fi

    clear
    arch=$(architecture)
    wget -O "/usr/bin/wgcf" https://github.com/ViRb3/wgcf/releases/download/v2.2.23/wgcf_2.2.23_linux_$arch
    chmod +x /usr/bin/wgcf

    clear

    rm -rf wgcf-account.toml &> /dev/null || true
    rm -rf /etc/wireguard/warp.conf &> /dev/null || true

    wgcf register
    read -rp "Do you want to use your own key? (Y/n): " response
    if [[ $response =~ ^[Yy]$ ]]; then
        read -rp "ENTER YOUR LICENSE: " LICENSE_KEY
        sed -i "s/license_key = '.*'/license_key = '$LICENSE_KEY'/" wgcf-account.toml
        wgcf update
    fi

    wgcf generate

    sed -i '/\n\[Peer\]\n/i Table = off' wgcf-profile.conf
    mv wgcf-profile.conf /etc/wireguard/warp.conf

    systemctl disable --now wg-quick@warp &> /dev/null || true
    systemctl enable --now wg-quick@warp

    echo "Wireguard warp is up and running"
    sleep 2
}

install_x_ui() {
    echo "Installing x-UI..."
    bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh)
    echo "x-UI installed successfully!"
    sleep 2
}

install_tool() {
    echo "Installing Tool..."
    curl -Ls https://raw.githubusercontent.com/Mmdd93/v2ray-assistance/refs/heads/main/node.sh -o node.sh
    sudo bash node.sh
    echo "Tool installed successfully!"
    sleep 2
}

while true; do
    show_menu
    read -p "Choose an option: " choice
    case $choice in
        1) install_core ;;
        2)
            echo "1 - Iran Server"
            echo "2 - Kharej Server"
            read -p "Choose server type: " server_choice
            case $server_choice in
                1) configure_iran ;;
                2) configure_kharej ;;
            esac
            ;;
        3) uninstall_core ;;
        4) update_core ;;
        5) restart_core ;;
        6) status_core ;;
        10) install_ezwarp ;;
        11) install_x_ui ;;
        12) install_tool ;;
        0) exit 0 ;;
        *) echo "Invalid option. Please choose a valid option." ;;
    esac
done
