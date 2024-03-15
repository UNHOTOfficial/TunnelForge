#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to clear the terminal screen
clear_screen() {
    printf "\033c"
}

# Function to check if Cloudflared is installed
check_cloudflared_installation() {
    if [ -d "/root/Argo" ] && [ -f "/root/Argo/$(get_filename)" ]; then
        echo -e "${GREEN}Installed.${NC}"
    else
        echo -e "${RED}Not installed.${NC}"
    fi
}

check_tunnel_status() {
    # Check if the Argo directory exists
    if [ ! -d "/root/Argo" ]; then
        echo -e "${RED}Not Created.${NC}"
        return
    fi

    # Check if cert.pem exists in either /etc/cloudflared or /usr/local/etc/cloudflared
    if [ ! -f "/root/.cloudflared/cert.pem" ]; then
        echo -e "${RED}Not Logged In.${NC}"
        return
    fi

    # Change to the Argo directory
    cd /root/Argo || exit

    # Run the command and save its output
    output=$(./$(get_filename) tunnel list)

    # Check if the output contains any tunnel information
    if [[ $output == *"ID"* && $output == *"NAME"* && $output == *"CONNECTIONS"* ]]; then
        echo -e "${GREEN}Created.${NC}"
    else
        echo -e "${RED}Not Created.${NC}"
    fi
}

check_tunnel_running() {
    # Check if tmux is installed
    if ! command -v tmux &>/dev/null; then
        echo -e "${RED}Not Running.${NC}"
        return
    fi

    # Run the command and save its output, suppressing error messages
    output=$(tmux ls 2>/dev/null)

    # Check if the output contains "no server running on /tmp/tmux-0/default"
    if [[ $output == "no server running on /tmp/tmux-0/default" ]]; then
        echo -e "${RED}Not Running.${NC}"
    elif [[ $output == *"Argo"* ]]; then
        echo -e "${GREEN}Running.${NC}"
    else
        echo -e "${RED}Not Running.${NC}"
    fi
}

# Get ipv4 and ipv6
get_ips() {
    ipv4=$(curl -s4m8 ip.sb -k)
    ipv6=$(curl -s6m8 ip.sb -k)
    echo -e "${YELLOW}Server IPv4: ${NC}$ipv4"
    echo -e "${YELLOW}Server IPv6: ${NC}$ipv6"
}

# Function to detect OS architecture
detect_os_architecture() {
    arch=$(uname -m)
    echo $arch
}

# Function to get the filename based on OS architecture
get_filename() {
    arch=$(detect_os_architecture)
    if [ "$arch" == "x86_64" ]; then
        echo "cloudflared-linux-amd64"
    elif [ "$arch" == "aarch64" ]; then
        echo "cloudflared-linux-arm64"
    elif [ "$arch" == "armv7l" ]; then
        echo "cloudflared-linux-arm"
    elif [ "$arch" == "i686" ]; then
        echo "cloudflared-linux-386"
    else
        echo -e "${RED}OS not supported!${NC}"
        exit 1
    fi
}

# Function to check Argo directory existance
check_argo_directory() {
    # Check if the /root/Argo directory exists
    if [ ! -d "/root/Argo" ]; then
        echo -e "${RED}Error: The /root/Argo directory does not exist.${NC}"
        echo -e "${YELLOW}Please install cloudflared using the 2nd option in the menu.${NC}"
        exit 1
    fi
}

# Function to cd to Argo directory
check_and_change_directory() {
    # Check if the user is in the Argo directory
    if [[ $PWD != *"/Argo"* ]]; then
        echo -e "${YELLOW}Changing to the Argo directory...${NC}"
        cd /root/Argo || exit
    fi
}

# Function to display the menu
display_menu() {
    clear_screen
    echo -e "${PURPLE}===================================="
    echo -e "  ========= ${GREEN}TunnelForge${PURPLE} ========="
    echo -e "====================================${NC}\n"
    echo "1. Config Server"
    echo "2. Install Cloudflared"
    echo "3. Create Tunnel"
    echo "4. Run Tunnel"
    echo "5. List all tunnels"
    echo "6. Close tunnel(s)"
    echo "7. Remove a specific tunnel"
    echo "8. Update Cloudflared"
    echo "9. Uninstall Cloudflared"
    echo "10. Enable BBR"
    echo "11. Disable BBR"
    echo "12. Apply network enhancements"
    echo "13. Reset network"
    echo "0. Exit Menu"

    # Display the system OS and distribution
    echo -e "\n${YELLOW}System OS:${NC} $(uname) $(lsb_release -d -s 2>/dev/null) - $(detect_os_architecture)"

    # Display Tunnel status
    echo -n -e "${YELLOW}Argo status: ${NC}"

    # Check Cloudflared installation status
    check_cloudflared_installation

    # Display Tunnel status
    echo -n -e "${YELLOW}Tunnel status: ${NC}"

    # Check Cloudflared installation status
    check_tunnel_status

    # Display Tunnel status
    echo -n -e "${YELLOW}Tunnel running: ${NC}"

    # Check Cloudflared installation status
    check_tunnel_running

    # Display server IPs
    get_ips

    echo -e "\n${PURPLE}====================================${NC}"
}

# Function to pause and wait for user input
pause() {
    read -p "Press Enter to continue..."
}

# Function to config server
config_server() {
    clear_screen

    # Check if sudo is installed, install if necessary
    if ! [ -x "$(command -v sudo)" ]; then
        # Install sudo
        apt install sudo -y
    fi

    # Update and upgrade server
    sudo apt update
    sudo apt upgrade -y

    # Clean after updating
    sudo apt autoremove
    sudo apt autoclean

    # Install tmux
    sudo apt install -y tmux

    echo -e "${GREEN}Server configured successfully${NC}"

    pause
}

# Function to install Cloudflared
install_cloudflared() {
    clear_screen

    echo -e "${YELLOW}Starting the installation of cloudflared...${NC}"

    # Determine the appropriate file path based on system architecture or other conditions
    local cloudflared_path=$(get_cloudflared_path)

    if [ -d "/root/Argo" ] && [ -f "$cloudflared_path" ]; then
        echo -e "${RED}Error: The cloudflared binary already exist at $cloudflared_path.${NC}"

        exit 1
    fi

    echo -e "${YELLOW}Installing cloudflared from $cloudflared_path...${NC}"

    # Create directory and change into it
    mkdir -p Argo && cd Argo

    # Download cloudflared binary based on OS architecture
    download_cloudflared() {
        arch=$(detect_os_architecture)
        if [ "$arch" == "x86_64" ]; then
            url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
        elif [ "$arch" == "aarch64" ]; then
            url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
        elif [ "$arch" == "armv7l" ]; then
            url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm"
        elif [ "$arch" == "i686" ]; then
            url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386"
        else
            echo -e "${RED}OS not supported!${NC}"
            return 1
        fi

        wget $url && chmod +x $(basename $url)

        echo -e "${GREEN}cloudflared downloaded successfully.${NC}"

    }

    # Run the function to download cloudflared
    download_cloudflared

    # Run cloudflared update
    ./$(get_filename) update

    pause
}

# Function to create a tunnel
create_tunnel() {
    clear_screen

    check_argo_directory

    check_and_change_directory

    echo -e "\033[0;34mStarting the process to create a new tunnel...${NC}"

    # Run cloudflared tunnel login
    echo -e "${YELLOW}Logging in...${NC}"
    ./$(get_filename) tunnel login

    echo -e "${YELLOW}Here are your existing tunnels:${NC}"
    # Get tunnels list
    ./$(get_filename) tunnel list

    # Get tunnel name from user
    read -p "Enter a unique name for the new tunnel: " tunnel_name

    # Run cloudflared tunnel create with user-provided tunnel name
    ./$(get_filename) tunnel create "$tunnel_name"

    echo -e "${GREEN}Tunnel '$tunnel_name' created successfully.${NC}"

    pause
}

# Function to run a tunnel
run_tunnel() {
    clear_screen

    check_argo_directory

    # Enabling ping group
    echo '0 1' | sudo tee /proc/sys/net/ipv4/ping_group_range

    echo -e "\033[0;34mStarting the process to run a tunnel...${NC}"

    # Get and confirm tunnel name from user
    while true; do
        echo -e "\033[1;34mNote:${NC} ${GREEN}The tunnel name should be same as the one you set while creating tunnel.${NC}"
        read -p "Enter the tunnel name: " tunnel_name

        # Confirm tunnel name
        read -p "You entered '$tunnel_name'. Is this correct? (y/n): " confirm

        if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
            clear_screen
            echo "Confirmed. Proceeding with the tunnel name '$tunnel_name'."
            break
        else
            clear_screen
            echo "Tunnel name not confirmed. Please enter the correct tunnel name."
        fi
    done

    # Get and confirm subdomain from user
    while true; do
        echo -e "\033[1;34mNote:${NC} ${GREEN}The subdomain is not needed to be added before in Cloudflare DNS records. It will be added automatically.${NC}"
        echo -e "\033[1;34mInput:${NC} ${YELLOW}Please provide the full sub-domain as: \033[1;31msubdomain.example.com${NC}"
        read -p "Enter the subdomain where you want to run the tunnel: " subdomain

        # Confirm subdomain
        read -p "You entered '$subdomain'. Is this correct? (y/n): " confirm

        if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
            clear_screen
            echo "Confirmed. Proceeding with the subdomain '$subdomain'."
            break
        else
            clear_screen
            echo "Subdomain not confirmed. Please enter the correct subdomain."
        fi
    done

    # Get and confirm port from user
    while true; do
        read -p "Enter the port number (0-65536): " port

        # Confirm port
        read -p "You entered '$port'. Is this correct? (y/n): " confirm

        if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
            # Check if the port is within the valid range
            if [ $port -ge 0 ] && [ $port -le 65535 ]; then
                echo "Confirmed. Proceeding with the port '$port'."
                break
            else
                clear_screen
                echo -e "${RED}Port $port is not within the valid range. Please enter a valid port number.${NC}"
            fi
        else
            clear_screen
            echo "Port not confirmed. Please enter the correct port."
        fi
    done

    # Start tmux
    tmux new-session -d -s cloudflared_session

    # Check if the user is in the Argo directory
    tmux send-keys -t cloudflared_session 'if [[ $PWD != *"/Argo"* ]]; then echo -e "${YELLOW}Changing to the Argo directory...${NC}"; cd /root/Argo || exit; fi' C-m

    # Run cloudflared tunnel inside tmux
    tmux send-keys -t cloudflared_session "./$(get_filename) tunnel route dns $tunnel_name $subdomain" C-m
    tmux send-keys -t cloudflared_session "./$(get_filename) tunnel --url localhost:$port run $tunnel_name" C-m

    # Attach to tmux session
    tmux attach-session -t cloudflared_session

    echo -e "${GREEN}Tunnel '$tunnel_name' running successfully on subdomain '$subdomain'.${NC}"
}

# Function to list all tunnels
list_all_tunnels() {
    clear_screen

    check_argo_directory

    check_and_change_directory

    # Run the command and save its output
    output=$(./$(get_filename) tunnel list | grep -v "You can obtain more detailed information for each")

    # Display the output
    echo "$output"

    pause
}

# Function to close tunnels
close_tunnels() {
    clear_screen

    check_argo_directory

    check_and_change_directory

    # Confirm the action
    read -p "Are you sure you want to close all tunnels? [y/N] " confirmation
    confirmation=${confirmation,,} # tolower

    if [[ $confirmation =~ ^(yes|y)$ ]]; then
        # Run the command to close all tunnels
        tmux kill-server
        echo -e "${GREEN}All tunnels closed successfully.${NC}"
    else
        echo -e "${RED}Action cancelled.${NC}"
    fi
}

# Function to delete a specific tunnel
remove_specific_tunnel() {
    clear_screen

    check_argo_directory

    check_and_change_directory

    # Get the tunnel name or ID from the user
    echo -e "\033[1;34mNote:${NC} ${GREEN}You can see created tunnels by selecting 5 in menu.${NC}"
    read -p "Enter the name or ID of the tunnel to close: " tunnel

    # Confirm the action
    read -p "Are you sure you want to close the tunnel $tunnel? [y/N] " confirmation
    confirmation=${confirmation,,} # tolower

    if [[ $confirmation =~ ^(yes|y)$ ]]; then
        # Run the command to close the tunnel
        ./$(get_filename) tunnel delete "$tunnel"
        echo -e "${GREEN}Tunnel '$tunnel' closed successfully.${NC}"
    else
        echo -e "${RED}Action cancelled.${NC}"

        pause
    fi
}

# Function to update Cloudflared
update_cloudflared() {
    clear_screen

    check_argo_directory

    check_and_change_directory

    # Run cloudflared update
    ./$(get_filename) update

    echo -e "${GREEN}Cloudflared updated successfully.${NC}"

    pause
}

# Function to uninstall Cloudflared
uninstall_cloudflared() {
    clear_screen

    check_argo_directory

    # Confirm the action
    read -p "Are you sure you want to uninstall Cloudflared? [y/N] " confirmation
    confirmation=${confirmation,,} # tolower

    if [[ $confirmation =~ ^(yes|y)$ ]]; then
        # Close all tunnels
        close_tunnels

        # Remove the Argo directory
        rm -rf /root/Argo

        echo -e "${GREEN}Cloudflared uninstalled successfully.${NC}"
    else
        echo -e "${RED}Action cancelled.${NC}"
    fi

    pause
}

# Function to enable BBR
enable_bbr() {
    clear_screen

    # Check if BBR is already enabled
    if sysctl net.ipv4.tcp_congestion_control | grep -q 'bbr'; then
        echo -e "${GREEN}BBR is already enabled.${NC}"
        pause
        return
    fi

    # Enable BBR
    echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    sudo sysctl --system

    echo -e "${GREEN}BBR enabled successfully.${NC}"

    pause
}

# Function to disable BBR
disable_bbr() {
    clear_screen

    # Check if BBR is already disabled
    if [ ! -f "/etc/sysctl.d/99-sysctl.conf" ]; then
        echo -e "${GREEN}BBR is already disabled.${NC}"
        pause
        return
    fi

    # Disable BBR
    sudo rm -f /etc/sysctl.d/99-sysctl.conf
    sudo sysctl --system

    echo -e "${GREEN}BBR disabled successfully.${NC}"

    pause
}

# Function to apply network enhancements
apply_network_enhancements() {
    clear_screen

    # Check if BBR is enabled
    if [ -f "/etc/sysctl.d/99-sysctl.conf" ]; then
        echo -e "${GREEN}BBR is enabled.${NC}"
    else
        echo -e "${RED}BBR is not enabled. Please enable BBR first.${NC}"
        pause
        return
    fi

    echo -e "${RED}Network enhancements applied successfully.${NC}"

    pause
}

# Apply network enhancements
apply_network_enhancements() {
    echo "fs.file-max = 2097152" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.core.rmem_max = 134217728" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.core.wmem_max = 134217728" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.core.rmem_default = 1048576" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.core.wmem_default = 1048576" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.core.optmem_max = 40960" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_rmem = 4096 87380 67108864" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_wmem = 4096 65536 67108864" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_max_syn_backlog = 8096" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_tw_reuse = 1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_keepalive_time = 600" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_keepalive_intvl = 30" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_keepalive_probes = 10" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_fin_timeout = 30" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_syncookies = 1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_max_tw_buckets = 1048576" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_max_orphans = 262144" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_synack_retries = 2" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_syn_retries = 2" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_timestamps = 1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_sack = 1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_dsack = 1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_fack = 1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_window_scaling = 1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_rfc1337 = 1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_early_retrans = 3" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_congestion_control = bbr" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_notsent_lowat = 16384" | sudo tee -a /etc/sysctl.d/99-sysctl.conf

    # Apply the changes
    sudo sysctl -p
}

# Function to reset network
reset_network() {
    clear_screen

    # Confirm the action
    read -p "Are you sure you want to reset the network? [y/N] " confirmation
    confirmation=${confirmation,,} # tolower

    if [[ $confirmation =~ ^(yes|y)$ ]]; then
        # Reset network
        sudo cp /etc/sysctl.d/99-sysctl.conf /etc/sysctl.d/99-sysctl.conf.bak
        sudo sed -i '/net.ipv4/d' /etc/sysctl.d/99-sysctl.conf
        sudo sed -i '/net.core/d' /etc/sysctl.d/99-sysctl.conf
        sudo sysctl -p /etc/sysctl.d/99-sysctl.conf
        echo -e "${GREEN}Network reset successfully.${NC}"
    else
        echo -e "${RED}Action cancelled.${NC}"
    fi

    pause
}

# Main loop
while true; do
    display_menu
    read -p "Enter your choice: " choice
    case $choice in
    1)
        config_server
        ;;
    2)
        install_cloudflared
        ;;
    3)
        create_tunnel
        ;;
    4)
        run_tunnel
        ;;
    5)
        list_all_tunnels
        ;;
    6)
        close_tunnels
        ;;
    7)
        remove_specific_tunnel
        ;;
    8)
        update_cloudflared
        ;;
    9)
        uninstall_cloudflared
        ;;
    10)
        enable_bbr
        ;;
    11)
        disable_bbr
        ;;
    12)
        apply_network_enhancements
        ;;
    13)
        reset_network
        ;;
    0)
        clear_screen
        echo -e "${GREEN}Exiting...${NC}"
        exit
        ;;
    *)
        clear_screen
        echo -e "${RED}Invalid choice. Please enter a valid option.${NC}"
        pause
        ;;
    esac
done
