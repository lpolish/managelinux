#!/bin/bash

# Samba Server Management Script
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

# Function to install Samba
install_samba() {
    echo -e "${BLUE}Installing Samba...${NC}"
    apt-get update
    apt-get install -y samba samba-common
    
    # Create backup of original config
    cp /etc/samba/smb.conf /etc/samba/smb.conf.backup
    
    echo -e "${GREEN}Samba installed successfully${NC}"
}

# Function to create a new share
create_share() {
    read -p "Enter share name: " share_name
    read -p "Enter path to share: " share_path
    read -p "Enter share description: " share_desc
    read -p "Is this share writable? (y/n): " is_writable
    
    # Create directory if it doesn't exist
    mkdir -p "$share_path"
    chmod 777 "$share_path"
    
    # Add share configuration
    cat >> /etc/samba/smb.conf << EOF

[$share_name]
    comment = $share_desc
    path = $share_path
    browseable = yes
    read only = no
    create mask = 0777
    directory mask = 0777
EOF
    
    # Restart Samba
    systemctl restart smbd
    
    echo -e "${GREEN}Share '$share_name' created successfully${NC}"
}

# Function to list shares
list_shares() {
    echo -e "${BLUE}Current Samba Shares:${NC}"
    smbstatus -S
}

# Function to remove a share
remove_share() {
    read -p "Enter share name to remove: " share_name
    
    # Create temporary config file
    grep -v "\[$share_name\]" /etc/samba/smb.conf > /etc/samba/smb.conf.tmp
    mv /etc/samba/smb.conf.tmp /etc/samba/smb.conf
    
    # Restart Samba
    systemctl restart smbd
    
    echo -e "${GREEN}Share '$share_name' removed successfully${NC}"
}

# Function to add Samba user
add_samba_user() {
    read -p "Enter username: " username
    read -s -p "Enter password: " password
    echo
    
    # Create system user if doesn't exist
    if ! id "$username" &>/dev/null; then
        useradd -m "$username"
    fi
    
    # Add Samba user
    (echo "$password"; echo "$password") | smbpasswd -a "$username"
    
    echo -e "${GREEN}Samba user '$username' added successfully${NC}"
}

# Function to show Samba status
show_status() {
    echo -e "${BLUE}Samba Service Status:${NC}"
    systemctl status smbd
    
    echo -e "\n${BLUE}Active Connections:${NC}"
    smbstatus
}

# Main menu
while true; do
    clear
    echo -e "${BLUE}=== Samba Server Management ===${NC}"
    echo -e "${YELLOW}1.${NC} Install Samba"
    echo -e "${YELLOW}2.${NC} Create New Share"
    echo -e "${YELLOW}3.${NC} List Shares"
    echo -e "${YELLOW}4.${NC} Remove Share"
    echo -e "${YELLOW}5.${NC} Add Samba User"
    echo -e "${YELLOW}6.${NC} Show Status"
    echo -e "${YELLOW}7.${NC} Exit"
    
    read -p "Select an option (1-7): " choice
    
    case $choice in
        1)
            install_samba
            ;;
        2)
            create_share
            ;;
        3)
            list_shares
            ;;
        4)
            remove_share
            ;;
        5)
            add_samba_user
            ;;
        6)
            show_status
            ;;
        7)
            echo -e "${GREEN}Exiting Samba Manager${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    read -p "Press Enter to continue..."
done 