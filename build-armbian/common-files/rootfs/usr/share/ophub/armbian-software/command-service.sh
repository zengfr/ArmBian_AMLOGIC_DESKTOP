#!/bin/bash
#============================================================================
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
# This file is a part of the Armbian for Amlogic TV Boxes
# https://github.com/ophub/amlogic-s9xxx-armbian
#
# Function: Execute service software install/update/remove command
# Copyright (C) 2021- https://github.com/unifreq/openwrt_packit
# Copyright (C) 2021- https://github.com/ophub/amlogic-s9xxx-armbian
#
# Command: command-service.sh -s <software_id> -m <install/update/remove>
# Example: command-service.sh -s 303 -m install
#          command-service.sh -s 303 -m update
#          command-service.sh -s 303 -m remove
#
#============================== Software list ===============================
#
# software_303  : For nps
# software_304  : For npc
# software_305  : For plex
# software_306  : For emby-server
# software_307  : For openmediavault(OMV-6.x)
# software_308  : For kvm
#
#============================================================================

# Execute generic functions
software_path="/usr/share/ophub/armbian-software"
software_command="${software_path}/software-command.sh"
source "${software_command}"

# For nps
software_303() {
    case "${software_manage}" in
    install)
        # Software version query api
        software_api="https://api.github.com/repos/ehang-io/nps/releases"
        # Check the latest version, E.g: v0.26.10
        software_latest_version="$(curl -s "${software_api}" | grep "tag_name" | awk -F '"' '{print $4}' | tr " " "\n" | sort -rV | head -n 1)"
        # Query download address, E.g: https://github.com/ehang-io/nps/releases/download/v0.26.10/linux_arm64_server.tar.gz
        software_url="$(curl -s "${software_api}" | grep -oE "https:.*/${software_latest_version}/linux_arm64_server.tar.gz")"
        [[ -n "${software_url}" ]] || error_msg "The download address is empty!"
        echo -e "${INFO} Software download from: [ ${software_url} ]"

        # Download software, E.g: /tmp/tmp.xxx/linux_arm64_server.tar.gz
        tmp_download="$(mktemp -d)"
        software_filename="${software_url##*/}"
        echo -e "${STEPS} Start downloading NPS..."
        wget -q -P ${tmp_download} ${software_url}
        [[ "${?}" -eq "0" && -s "${tmp_download}/${software_filename}" ]] || error_msg "Software download failed!"
        echo -e "${INFO} Software downloaded successfully: $(ls ${tmp_download} -l)"

        # Installing and start NPS
        echo -e "${STEPS} Start the installation and start NPS..."
        cd ${tmp_download} && tar -xf ${software_filename}
        sudo ./nps install
        sudo nps start

        sync && sleep 3
        echo -e "${NOTE} The NPS address: [ http://ip:8080 ]"
        echo -e "${NOTE} The NPS account: [ username:admin  /  password:123 ]"
        echo -e "${NOTE} The NPS Instructions for Use: [ https://ehang-io.github.io/nps ]"
        echo -e "${SUCCESS} The NPS installation is successful."
        ;;
    update)
        sudo nps stop && sudo nps-update update && sudo nps restart
        echo -e "${SUCCESS} The NPS update and restart successfully."
        ;;
    remove)
        sudo nps stop && sudo nps uninstall
        sudo rm -rf /etc/nps /root/conf/nps.conf /usr/local/bin/nps /usr/local/bin/nps-update /usr/bin/nps /usr/bin/nps-update 2>/dev/null
        echo -e "${SUCCESS} The NPS remove successfully."
        ;;
    *) error_msg "Invalid input parameter: [ ${@} ]" ;;
    esac
}

# For npc
software_304() {
    case "${software_manage}" in
    install)
        # Software version query api
        software_api="https://api.github.com/repos/ehang-io/nps/releases"
        # Check the latest version, E.g: v0.26.10
        software_latest_version="$(curl -s "${software_api}" | grep "tag_name" | awk -F '"' '{print $4}' | tr " " "\n" | sort -rV | head -n 1)"
        # Query download address, E.g: https://github.com/ehang-io/nps/releases/download/v0.26.10/linux_arm64_client.tar.gz
        software_url="$(curl -s "${software_api}" | grep -oE "https:.*/${software_latest_version}/linux_arm64_client.tar.gz")"
        [[ -n "${software_url}" ]] || error_msg "The download address is empty!"
        echo -e "${INFO} Software download from: [ ${software_url} ]"

        # Download software, E.g: /tmp/tmp.xxx/linux_arm64_client.tar.gz
        tmp_download="$(mktemp -d)"
        software_filename="${software_url##*/}"
        echo -e "${STEPS} Start downloading NPC..."
        wget -q -P ${tmp_download} ${software_url}
        [[ "${?}" -eq "0" && -s "${tmp_download}/${software_filename}" ]] || error_msg "Software download failed!"
        echo -e "${INFO} Software downloaded successfully: $(ls ${tmp_download} -l)"

        # Installing and start NPC
        echo -e "${STEPS} Start the installation and start NPC..."
        cd ${tmp_download} && tar -xf ${software_filename}
        sudo mkdir -p /etc/npc && sudo cp -rf conf /etc/npc
        sudo ./npc install
        sudo npc start

        sync && sleep 3
        echo -e "${NOTE} The NPS config file path: [ /etc/npc/conf/npc.conf ]"
        echo -e "${NOTE} The NPS enable config command: [ sudo npc -config=/etc/npc/conf/npc.conf ]"
        echo -e "${NOTE} The NPC Instructions for Use: [ https://ehang-io.github.io/nps ]"
        echo -e "${SUCCESS} The NPC installation is successful."
        ;;
    update)
        sudo npc stop && sudo npc-update update && sudo npc restart
        echo -e "${SUCCESS} The NPC update and restart successfully."
        ;;
    remove)
        sudo npc stop && sudo npc uninstall
        sudo rm -rf /etc/npc /root/conf/npc.conf /usr/local/bin/npc /usr/local/bin/npc-update /usr/bin/npc /usr/bin/npc-update 2>/dev/null
        echo -e "${SUCCESS} The NPC remove successfully."
        ;;
    *) error_msg "Invalid input parameter: [ ${@} ]" ;;
    esac
}

# For plex
software_305() {
    case "${software_manage}" in
    install)
        # Install basic dependencies
        echo -e "${STEPS} Start installing basic dependencies..."
        software_install "wget curl gpg gnupg2 software-properties-common apt-transport-https lsb-release ca-certificates"

        # Add Plex Media Server APT repository
        echo -e "${STEPS} Start adding the Plex Media Server APT repository..."
        echo "deb https://downloads.plex.tv/repo/deb public main" | sudo tee /etc/apt/sources.list.d/plexmediaserver.list

        # Import GPG key
        echo -e "${STEPS} Start importing GPG keys..."
        wget https://downloads.plex.tv/plex-keys/PlexSign.key
        cat PlexSign.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/PlexSigkey.gpg
        rm -f PlexSign.key

        # Installing Plex Media server
        echo -e "${STEPS} Start installing Plex Media server..."
        software_install "plexmediaserver"

        # Ensure to open the port 32400 through the firewall
        echo -e "${STEPS} Set firewall to open port 32400..."
        sudo ufw allow 32400 2>/dev/null

        # Enable Plex server to start automatically on system boot
        echo -e "${STEPS} Start setting up the Plex server to start automatically at system boot..."
        sudo systemctl daemon-reload
        sudo systemctl enable --now plexmediaserver.service
        sudo systemctl restart plexmediaserver.service

        # Confirm the service is enabled
        echo -e "${STEPS} Confirm the service is enabled..."
        systemctl is-enabled plexmediaserver.service

        # Configure Plex Media Server: http://ip:32400/web
        sync && sleep 3
        echo -e "${NOTE} The Plex Media Server address: [ http://ip:32400/web ]"
        echo -e "${SUCCESS} The Plex Media Server installation is successful."
        ;;
    update) software_update ;;
    remove) software_remove "plexmediaserver" ;;
    *) error_msg "Invalid input parameter: [ ${@} ]" ;;
    esac
}

# For emby-server
software_306() {
    case "${software_manage}" in
    install)
        # Software version query api
        software_api="https://api.github.com/repos/MediaBrowser/Emby.Releases/releases"
        # Check the latest version, E.g: 4.7.5.0
        software_latest_version="$(curl -s "${software_api}" | grep "tag_name" | awk -F '"' '{print $4}' | grep -E [.]0$ | tr " " "\n" | sort -rV | head -n 1)"
        # Query download address, E.g: https://github.com/MediaBrowser/Emby.Releases/releases/download/4.7.5.0/emby-server-deb_4.7.5.0_arm64.deb
        software_url="$(curl -s "${software_api}" | grep -oE "https:.*${software_latest_version}.*_arm64.deb")"
        [[ -n "${software_url}" ]] || error_msg "The download address is empty!"
        echo -e "${INFO} Software download from: [ ${software_url} ]"

        # Download software, E.g: /tmp/tmp.xxx/emby-server-deb_4.7.5.0_arm64.deb
        tmp_download="$(mktemp -d)"
        software_filename="${software_url##*/}"
        echo -e "${STEPS} Start downloading Emby Server..."
        wget -q -P ${tmp_download} ${software_url}
        [[ "${?}" -eq "0" && -s "${tmp_download}/${software_filename}" ]] || error_msg "Software download failed!"
        echo -e "${INFO} Software downloaded successfully: $(ls ${tmp_download} -l)"

        # Installing Emby Server
        echo -e "${STEPS} Start installing Emby Server..."
        sudo dpkg -i ${tmp_download}/${software_filename}

        # Enable Emby Server to start automatically on system boot
        echo -e "${STEPS} Start setting up the Emby Server to start automatically at system boot..."
        sudo systemctl daemon-reload
        sudo systemctl enable --now emby-server.service
        sudo systemctl restart emby-server.service

        # Confirm the service is enabled
        echo -e "${STEPS} Confirm the service is enabled..."
        systemctl is-enabled emby-server.service

        # Configure Emby Server: http://ip:8096
        sync && sleep 3
        echo -e "${NOTE} The Emby Server address: [ http://ip:8096 ]"
        echo -e "${SUCCESS} The Emby Server installation is successful."
        ;;
    update) software_update ;;
    remove) software_remove "emby-server" ;;
    *) error_msg "Invalid input parameter: [ ${@} ]" ;;
    esac
}

# For openmediavault(OMV-6.x)
software_307() {
    case "${software_manage}" in
    install)
        echo -e "${STEPS} Start checking the installation environment..."
        # Check systemd running status
        systemd="$(ps --no-headers -o comm 1)"
        [[ "${systemd}" == "systemd" ]] || error_msg "This system is not running systemd."
        # Check the system operating environment
        [[ -z "$(dpkg -l | grep -wE 'gdm3|sddm|lxdm|xdm|lightdm|slim|wdm|xfce')" ]] || error_msg "OpenMediaVault does not support running in desktop environment!"

        # Download software, E.g: /tmp/tmp.xxx/install
        tmp_download="$(mktemp -d)"
        software_url="https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install"
        software_filename="${software_url##*/}"
        echo -e "${STEPS} Start downloading the OpenMediaVault installation script..."
        wget -q -P ${tmp_download} ${software_url}
        [[ "${?}" -eq "0" && -s "${tmp_download}/${software_filename}" ]] || error_msg "Software download failed!"
        chmod +x ${tmp_download}/${software_filename}
        echo -e "${INFO} Software downloaded successfully: $(ls ${tmp_download} -l)"

        # Install OpenMediaVault and omv-extras extension: https://github.com/OpenMediaVault-Plugin-Developers/installScript
        echo -e "${STEPS} Start installing OpenMediaVault and omv-extras extension..."
        sudo ${tmp_download}/${software_filename} -n

        # Configure OpenMediaVault: http://ip
        sync && sleep 3
        echo -e "${NOTE} The OpenMediaVault address: [ http://ip ]"
        echo -e "${NOTE} The OpenMediaVault account: [ username:admin  /  password:openmediavault ]"
        echo -e "${NOTE} How to use OpenMediaVault: [ https://forum.openmediavault.org/ ]"
        echo -e "${SUCCESS} The OpenMediaVault installation is successful."
        ;;
    update) software_update ;;
    remove) software_remove "openmediavault" ;;
    *) error_msg "Invalid input parameter: [ ${@} ]" ;;
    esac
}

# For kvm
software_308() {
    # kvm general settings
    my_network_br0="/etc/network/interfaces.d/br0"
    kvm_package_list="\
        gconf2 qemu-system-arm qemu-utils qemu-efi ipxe-qemu libvirt-daemon-system libvirt-clients bridge-utils \
        virtinst virt-manager seabios vgabios gir1.2-spiceclientgtk-3.0 xauth fonts-noto* \
        "

    case "${software_manage}" in
    install)
        echo -e "${STEPS} Start installing KVM and other related virtualization packages..."
        software_install "${kvm_package_list}"

        # Get desktop system login user
        echo -ne "${OPTIONS} Please input the login desktop system user(non-root): "
        read get_desktop_user
        [[ -n "${get_desktop_user}" ]] && my_user="${get_desktop_user}" || my_user="${USER}"
        # Add the login desktop system user to the kvm​ and libvirt user groups
        echo -e "${STEPS} Start adding the current logged-in user(${my_user}) to the kvm and libvirt user groups..."
        sudo usermod -aG kvm ${my_user}
        sudo usermod -aG libvirt ${my_user}

        # Enable X11Forwarding to run Linux GUI programs remotely
        sed -i '/X11Forwarding/d' /etc/ssh/sshd_config 2>/dev/null
        echo "X11Forwarding yes" >>/etc/ssh/sshd_config 2>/dev/null

        # Enable and start the libvirtd.service daemon
        echo -e "${STEPS} Start enabling and starting the libvirtd.service daemon..."
        sudo systemctl daemon-reload
        sudo systemctl enable --now libvirtd.service
        sudo systemctl restart libvirtd.service
        #sudo systemctl status libvirtd.service

        # Add network bridge settings template
        echo -e "${STEPS} Start adding bridged network settings template..."
        [[ -z "${my_address}" || -z "${my_broadcast}" || -z "${my_netmask}" || -z "${my_gateway}" ]] && {
            echo -ne "${OPTIONS} Please input IP address, the default is [ ${my_address} ]: "
            read get_address
            [[ -n "${get_address}" ]] && my_address="${get_address}"

            echo -ne "${OPTIONS} Please input broadcast, the default is [ ${my_broadcast} ]: "
            read get_broadcast
            [[ -n "${get_broadcast}" ]] && my_broadcast="${get_broadcast}"

            echo -ne "${OPTIONS} Please input netmask, the default is [ ${my_netmask} ]: "
            read get_netmask
            [[ -n "${get_netmask}" ]] && my_netmask="${get_netmask}"

            echo -ne "${OPTIONS} Please input gateway, the default is [ ${my_gateway} ]: "
            read get_gateway
            [[ -n "${get_gateway}" ]] && my_gateway="${get_gateway}"
        }
        sudo rm -f ${my_network_br0} 2>/dev/null
        sudo cat >${my_network_br0} <<EOF
# eth0 setup
allow-hotplug eth0
iface eth0 inet manual
        pre-up ifconfig \$IFACE up
        pre-down ifconfig \$IFACE down

# Bridge setup
auto br0
iface br0 inet static
        bridge_ports eth0
        bridge_stp off
        bridge_waitport 0
        bridge_fd 0
        address ${my_address}
        broadcast ${my_broadcast}
        netmask ${my_netmask}
        gateway ${my_gateway}
        dns-nameservers ${my_gateway}
EOF

        # Disable netfilter on KVM bridge
        sudo cat >>/etc/sysctl.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 0
net.bridge.bridge-nf-call-iptables = 0
net.bridge.bridge-nf-call-arptables = 0
EOF
        # Reload /etc/sysctl.conf
        sudo sysctl -p /etc/sysctl.conf

        # Set the virtual machine to start automatically
        vm_autostart="/etc/default/libvirt-guests"
        [[ -f "${vm_autostart}" ]] && {
            sed -i '/^ON_BOOT=.*/d' ${vm_autostart} 2>/dev/null
            sed -i '/^ON_SHUTDOWN=.*/d' ${vm_autostart} 2>/dev/null
            echo "ON_BOOT=start" >>${vm_autostart} 2>/dev/null
            echo "ON_SHUTDOWN=shutdown" >>${vm_autostart} 2>/dev/null
        }

        sync && sleep 3
        echo -e "${NOTE} The bridge network settings: [ ${my_network_br0} ]"
        echo -e "${NOTE} KVM can install OpenWrt, Debian, Ubuntu, OpenSUSE, ArchLinux, Centos, Gentoo, KyLin, UOS, etc."
        echo -e "${NOTE} Making and using OpenWrt: [ https://github.com/unifreq/openwrt_packit ]"
        echo -e "${SUCCESS} The KVM installation is successful."
        ;;
    update) software_update ;;
    remove)
        software_remove "${kvm_package_list}"
        sudo rm -f ${my_network_br0} 2>/dev/null
        ;;
    *) error_msg "Invalid input parameter: [ ${@} ]" ;;
    esac
}

# Initialize variables
init_var "${@}"
software_${software_id} ${software_manage}
