#!/bin/bash

# Function to clear the terminal screen
clear_screen() {
    printf "\033c"
}

# Function to check if Cloudflared is installed
check_cloudflared_installation() {
    if [ -d "/root/Argo" ] && [ -f "/root/Argo/$(get_filename)" ]; then
        echo -e "\033[0;32mInstalled.\033[0m"
    else
        echo -e "\033[0;31mNot installed.\033[0m"
    fi
}

check_tunnel_status() {
    # Check if the Argo directory exists
    if [ ! -d "/root/Argo" ]; then
        echo -e "\033[0;31mNot Created.\033[0m"
        return
    fi

    # Change to the Argo directory
    cd /root/Argo || exit

    # Run the command and save its output
    output=$(./$(get_filename) tunnel list)

    # Check if the output contains any tunnel information
    if [[ $output == *"ID"* && $output == *"NAME"* && $output == *"CONNECTIONS"* ]]; then
        echo -e "\033[0;32mCreated.\033[0m"
    else
        echo -e "\033[0;31mNot Created.\033[0m"
    fi
}

check_tunnel_running() {
    # Check if tmux is installed
    if ! command -v tmux &> /dev/null; then
        echo -e "\033[0;32mRunning.\033[0m"
        return
    fi

    # Run the command and save its output
    output=$(tmux ls)

    # Check if the output contains any tunnel information
    if [[ $output == *"Argo"* ]]; then
        echo -e "\033[0;32mRunning.\033[0m"
    else
        echo -e "\033[0;31mNot Running.\033[0m"
    fi
}

# Get ipv4 and ipv6
get_ips() {
    ipv4=$(curl -s4m8 ip.sb -k)
    ipv6=$(curl -s6m8 ip.sb -k)
    echo -e "\033[0;33mServer IPv4: \033[0m$ipv4"
    echo -e "\033[0;33mServer IPv6: \033[0m$ipv6"
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
        echo -e "\033[0;31mOS not supported!\033[0m"
        exit 1
    fi
}

# Function to display the menu
display_menu() {
    clear_screen
    echo -e "\033[0;35m===================================="
    echo -e "  ========= \033[0;32mTunnelForge\033[0;35m ========="
    echo -e "====================================\033[0m\n"
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
    echo -e "\n\033[0;33mSystem OS:\033[0m $(uname) $(lsb_release -d -s 2>/dev/null) - $(detect_os_architecture)"

    # Display Tunnel status
    echo -n -e "\033[0;33mArgo status: \033[0m"

    # Check Cloudflared installation status
    check_cloudflared_installation

    # Display Tunnel status
    echo -n -e "\033[0;33mTunnel status: \033[0m"

    # Check Cloudflared installation status
    check_tunnel_status

    # Display Tunnel status
    echo -n -e "\033[0;33mTunnel running: \033[0m"

    # Check Cloudflared installation status
    check_tunnel_running

    # Display server IPs
    get_ips

    echo -e "\n\033[0;35m====================================\033[0m"
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

    echo -e "\033[0;32mServer configured successfully\033[0m"

    pause
}

# Function to install Cloudflared
install_cloudflared() {
    clear_screen

    if [ -d "/root/Argo" ] && [ -f "/root/cloudflared-linux-amd64" ]; then
        echo "Argo directory and Cloudflared are already installed."
        return
    fi

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
            echo -e "\033[0;31mOS not supported!\033[0m"
            return 1
        fi

        wget $url && chmod +x $(basename $url)

        echo -e "\033[0;32mcloudflared downloaded successfully\033[0m"
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

    # Check if the user is in the Argo directory
    if [[ $PWD != *"/Argo"* ]]; then
        echo -e "\033[0;33mChanging to the Argo directory...\033[0m"
        cd /root/Argo || exit
    fi

    echo -e "\033[0;34mStarting the process to create a new tunnel...\033[0m"

    # Run cloudflared tunnel login
    echo -e "\033[0;33mLogging in...\033[0m"
    ./$(get_filename) tunnel login

    echo -e "\033[0;33mHere are your existing tunnels:\033[0m"
    # Get tunnels list
    ./$(get_filename) tunnel list

    # Get tunnel name from user
    read -p "Enter a unique name for the new tunnel: " tunnel_name

    # Run cloudflared tunnel create with user-provided tunnel name
    ./$(get_filename) tunnel create "$tunnel_name"

    echo -e "\033[0;32mTunnel '$tunnel_name' created successfully.\033[0m"

    pause
}

# Function to run a tunnel
run_tunnel() {
    clear_screen

    # Enabling ping group
    echo '0 1' | sudo tee /proc/sys/net/ipv4/ping_group_range

    echo -e "\033[0;34mStarting the process to run a tunnel...\033[0m"

    # Get and confirm tunnel name from user
    while true; do
        echo -e "\033[1;34mNote:\033[0m \033[0;32mThe tunnel name should be same as the one you set while creating tunnel.\033[0m"
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
        echo -e "\033[1;34mNote:\033[0m \033[0;32mThe subdomain is not needed to be added before in Cloudflare DNS records. It will be added automatically.\033[0m"
        echo -e "\033[1;34mInput:\033[0m \033[0;33mPlease provide the full sub-domain as: \033[1;31msubdomain.example.com\033[0m"
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
                echo -e "\033[0;31mPort $port is not within the valid range. Please enter a valid port number.\033[0m"
            fi
        else
            clear_screen
            echo "Port not confirmed. Please enter the correct port."
        fi
    done

    # Start tmux
    tmux new-session -d -s cloudflared_session

    # Check if the user is in the Argo directory
    tmux send-keys -t cloudflared_session 'if [[ $PWD != *"/Argo"* ]]; then echo -e "\033[0;33mChanging to the Argo directory...\033[0m"; cd /root/Argo || exit; fi' C-m

    # Run cloudflared tunnel inside tmux
    tmux send-keys -t cloudflared_session "./$(get_filename) tunnel route dns $tunnel_name $subdomain" C-m
    tmux send-keys -t cloudflared_session "./$(get_filename) tunnel --url localhost:$port run $tunnel_name" C-m

    # Attach to tmux session
    tmux attach-session -t cloudflared_session

    echo -e "\033[0;32mTunnel '$tunnel_name' running successfully on subdomain '$subdomain'.\033[0m"
}

# Function to list all tunnels
list_all_tunnels() {
    clear_screen
    # Check if the user is in the Argo directory
    if [[ $PWD != *"/Argo"* ]]; then
        cd /root/Argo || exit
    fi

    # Run the command and save its output
    output=$(./$(get_filename) tunnel list | grep -v "You can obtain more detailed information for each")

    # Display the output
    echo "$output"

    pause
}

# Function to close tunnels
close_tunnels() {
    # Check if the user is in the Argo directory
    if [[ $PWD != *"/Argo"* ]]; then
        cd /root/Argo || exit
    fi

    # Confirm the action
    read -p "Are you sure you want to close all tunnels? [y/N] " confirmation
    confirmation=${confirmation,,} # tolower

    if [[ $confirmation =~ ^(yes|y)$ ]]; then
        # Run the command to close all tunnels
        tmux kill-server
        echo -e "\033[0;32mAll tunnels closed successfully.\033[0m"
    else
        echo -e "\033[0;31mAction cancelled.\033[0m"
    fi
}

# Function to delete a specific tunnel
remove_specific_tunnel() {
    clear_screen

    # Check if the user is in the Argo directory
    if [[ $PWD != *"/Argo"* ]]; then
        cd /root/Argo || exit
    fi

    # Get the tunnel name or ID from the user
    echo -e "\033[1;34mNote:\033[0m \033[0;32mYou can see created tunnels by selecting 5 in menu.\033[0m"
    read -p "Enter the name or ID of the tunnel to close: " tunnel

    # Confirm the action
    read -p "Are you sure you want to close the tunnel $tunnel? [y/N] " confirmation
    confirmation=${confirmation,,} # tolower

    if [[ $confirmation =~ ^(yes|y)$ ]]; then
        # Run the command to close the tunnel
        ./$(get_filename) tunnel delete "$tunnel"
        echo -e "\033[0;32mTunnel '$tunnel' closed successfully.\033[0m"
    else
        echo -e "\033[0;31mAction cancelled.\033[0m"

        pause
    fi
}

# Function to update Cloudflared
update_cloudflared() {
    clear_screen

    # Check if the user is in the Argo directory
    if [[ $PWD != *"/Argo"* ]]; then
        echo -e "\033[0;33mChanging to the Argo directory...\033[0m"
        cd /root/Argo || exit
    fi

    # Run cloudflared update
    ./$(get_filename) update

    echo -e "\033[0;32mCloudflared updated successfully.\033[0m"

    pause
}

# Function to uninstall Cloudflared
uninstall_cloudflared() {
    clear_screen

    # Confirm the action
    read -p "Are you sure you want to uninstall Cloudflared? [y/N] " confirmation
    confirmation=${confirmation,,} # tolower

    if [[ $confirmation =~ ^(yes|y)$ ]]; then
        # Close all tunnels
        close_tunnels

        # Remove the Argo directory
        rm -rf /root/Argo

        echo -e "\033[0;32mCloudflared uninstalled successfully.\033[0m"
    else
        echo -e "\033[0;31mAction cancelled.\033[0m"
    fi

    pause
}

# Function to enable BBR
enable_bbr() {
    clear_screen

    # Check if BBR is already enabled
    if sysctl net.ipv4.tcp_congestion_control | grep -q 'bbr'; then
        echo -e "\033[0;32mBBR is already enabled.\033[0m"
        pause
        return
    fi

    # Enable BBR
    echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
    sudo sysctl --system

    echo -e "\033[0;32mBBR enabled successfully.\033[0m"

    pause
}

# Function to disable BBR
disable_bbr() {
    clear_screen

    # Check if BBR is already disabled
    if [ ! -f "/etc/sysctl.d/99-sysctl.conf" ]; then
        echo -e "\033[0;32mBBR is already disabled.\033[0m"
        pause
        return
    fi

    # Disable BBR
    sudo rm -f /etc/sysctl.d/99-sysctl.conf
    sudo sysctl --system

    echo -e "\033[0;32mBBR disabled successfully.\033[0m"

    pause
}

# Function to apply network enhancements
apply_network_enhancements() {
    clear_screen

    # Check if BBR is enabled
    if [ -f "/etc/sysctl.d/99-sysctl.conf" ]; then
        echo -e "\033[0;32mBBR is enabled.\033[0m"
    else
        echo -e "\033[0;31mBBR is not enabled. Please enable BBR first.\033[0m"
        pause
        return
    fi

    echo -e "\033[0;31mNetwork enhancements applied successfully.\033[0m"

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
        echo -e "\033[0;32mNetwork reset successfully.\033[0m"
    else
        echo -e "\033[0;31mAction cancelled.\033[0m"
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
        echo -e "\033[0;32mExiting...\033[0m"
        exit
        ;;
    *)
        clear_screen
        echo -e "\033[0;31mInvalid choice. Please enter a valid option.\033[0m"
        pause
        ;;
    esac
done
