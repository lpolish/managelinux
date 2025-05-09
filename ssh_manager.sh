#!/bin/bash

# SSH Server Management Script
# Part of Server Migration and Management Suite
# Version: 1.0.0

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration if available
if [ -f "$SCRIPT_DIR/config.sh" ]; then
    source "$SCRIPT_DIR/config.sh"
else
    # Default installation paths
    INSTALL_DIR="/usr/local/bin/linux_quick_manage"
fi

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root or with sudo privileges${NC}"
    exit 1
fi

# Function to install SSH server
install_ssh() {
    echo -e "${BLUE}Installing SSH Server...${NC}"
    apt-get update
    apt-get install -y openssh-server
    
    # Create backup of original config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # Secure default configuration
    sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
    
    # Restart SSH service
    systemctl restart sshd
    
    echo -e "${GREEN}SSH Server installed successfully${NC}"
}

# Function to add SSH key
add_ssh_key() {
    read -p "Enter username: " username
    read -p "Enter public key: " pubkey
    
    # Create .ssh directory if it doesn't exist
    mkdir -p "/home/$username/.ssh"
    chmod 700 "/home/$username/.ssh"
    
    # Add key to authorized_keys
    echo "$pubkey" >> "/home/$username/.ssh/authorized_keys"
    chmod 600 "/home/$username/.ssh/authorized_keys"
    
    # Set ownership
    chown -R "$username:$username" "/home/$username/.ssh"
    
    echo -e "${GREEN}SSH key added successfully for user '$username'${NC}"
}

# Function to remove SSH key
remove_ssh_key() {
    read -p "Enter username: " username
    read -p "Enter public key to remove: " pubkey
    
    # Remove key from authorized_keys
    sed -i "\|$pubkey|d" "/home/$username/.ssh/authorized_keys"
    
    echo -e "${GREEN}SSH key removed successfully for user '$username'${NC}"
}

# Function to list authorized keys
list_ssh_keys() {
    read -p "Enter username (leave empty for all users): " username
    
    if [ -z "$username" ]; then
        for user_home in /home/*; do
            if [ -f "$user_home/.ssh/authorized_keys" ]; then
                echo -e "${BLUE}Keys for user $(basename "$user_home"):${NC}"
                cat "$user_home/.ssh/authorized_keys"
                echo
            fi
        done
    else
        if [ -f "/home/$username/.ssh/authorized_keys" ]; then
            echo -e "${BLUE}Keys for user $username:${NC}"
            cat "/home/$username/.ssh/authorized_keys"
        else
            echo -e "${YELLOW}No authorized keys found for user $username${NC}"
        fi
    fi
}

# Function to configure SSH server
configure_ssh() {
    echo -e "${BLUE}SSH Server Configuration${NC}"
    echo -e "${YELLOW}1.${NC} Disable root login"
    echo -e "${YELLOW}2.${NC} Enable/Disable password authentication"
    echo -e "${YELLOW}3.${NC} Change SSH port"
    echo -e "${YELLOW}4.${NC} Back to main menu"
    
    read -p "Select an option (1-4): " config_choice
    
    case $config_choice in
        1)
            read -p "Disable root login? (y/n): " disable_root
            if [ "$disable_root" = "y" ]; then
                sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
            else
                sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config
            fi
            ;;
        2)
            read -p "Enable password authentication? (y/n): " enable_pass
            if [ "$enable_pass" = "y" ]; then
                sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
            else
                sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
            fi
            ;;
        3)
            read -p "Enter new SSH port (1-65535): " new_port
            if [[ "$new_port" =~ ^[0-9]+$ ]] && [ "$new_port" -ge 1 ] && [ "$new_port" -le 65535 ]; then
                sed -i "s/#Port 22/Port $new_port/" /etc/ssh/sshd_config
            else
                echo -e "${RED}Invalid port number${NC}"
                return 1
            fi
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            return 1
            ;;
    esac
    
    # Restart SSH service
    systemctl restart sshd
    echo -e "${GREEN}SSH configuration updated successfully${NC}"
}

# Function to show SSH status
show_status() {
    echo -e "${BLUE}SSH Service Status:${NC}"
    systemctl status sshd
    
    echo -e "\n${BLUE}Active Connections:${NC}"
    netstat -tnpa | grep ':22'
}

# Main menu
while true; do
    clear
    echo -e "${BLUE}=== SSH Server Management ===${NC}"
    echo -e "${YELLOW}1.${NC} Install SSH Server"
    echo -e "${YELLOW}2.${NC} Add SSH Key"
    echo -e "${YELLOW}3.${NC} Remove SSH Key"
    echo -e "${YELLOW}4.${NC} List Authorized Keys"
    echo -e "${YELLOW}5.${NC} Configure SSH Server"
    echo -e "${YELLOW}6.${NC} Show Status"
    echo -e "${YELLOW}7.${NC} Exit"
    
    read -p "Select an option (1-7): " choice
    
    case $choice in
        1)
            install_ssh
            ;;
        2)
            add_ssh_key
            ;;
        3)
            remove_ssh_key
            ;;
        4)
            list_ssh_keys
            ;;
        5)
            configure_ssh
            ;;
        6)
            show_status
            ;;
        7)
            echo -e "${GREEN}Exiting SSH Manager${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    read -p "Press Enter to continue..."
done 