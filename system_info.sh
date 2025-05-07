#!/bin/bash

# System Information Script
# Part of Server Migration and Management Suite

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display system overview
show_system_overview() {
    echo -e "${BLUE}=== System Overview ===${NC}"
    
    # OS Information
    echo -e "${YELLOW}Operating System:${NC}"
    lsb_release -a 2>/dev/null || cat /etc/os-release
    
    # Kernel Information
    echo -e "\n${YELLOW}Kernel Information:${NC}"
    uname -a
    
    # CPU Information
    echo -e "\n${YELLOW}CPU Information:${NC}"
    lscpu | grep -E "Model name|Socket|Thread|Core|CPU\(s\)"
    
    # Memory Information
    echo -e "\n${YELLOW}Memory Information:${NC}"
    free -h
    
    # Disk Usage
    echo -e "\n${YELLOW}Disk Usage:${NC}"
    df -h
    
    # Network Information
    echo -e "\n${YELLOW}Network Interfaces:${NC}"
    ip addr show
}

# Function to display package information
show_package_info() {
    echo -e "${BLUE}=== Package Information ===${NC}"
    
    # Total installed packages
    echo -e "${YELLOW}Total Installed Packages:${NC}"
    dpkg -l | wc -l
    
    # Recently updated packages
    echo -e "\n${YELLOW}Recently Updated Packages:${NC}"
    grep -h "status installed" /var/log/dpkg.log* | tail -n 10
    
    # Available updates
    echo -e "\n${YELLOW}Available Updates:${NC}"
    apt list --upgradable 2>/dev/null
}

# Function to display service status
show_service_status() {
    echo -e "${BLUE}=== Service Status ===${NC}"
    
    # Systemd services
    echo -e "${YELLOW}Systemd Services:${NC}"
    systemctl list-units --type=service --state=running | grep -v "systemd"
    
    # Network services
    echo -e "\n${YELLOW}Network Services:${NC}"
    netstat -tulpn 2>/dev/null | grep LISTEN
}

# Function to display hardware details
show_hardware_details() {
    echo -e "${BLUE}=== Hardware Details ===${NC}"
    
    # PCI Devices
    echo -e "${YELLOW}PCI Devices:${NC}"
    lspci
    
    # USB Devices
    echo -e "\n${YELLOW}USB Devices:${NC}"
    lsusb
    
    # Block Devices
    echo -e "\n${YELLOW}Block Devices:${NC}"
    lsblk -f
}

# Function to display system logs
show_system_logs() {
    echo -e "${BLUE}=== System Logs ===${NC}"
    
    # Recent system messages
    echo -e "${YELLOW}Recent System Messages:${NC}"
    journalctl -n 20 --no-pager
    
    # Recent authentication logs
    echo -e "\n${YELLOW}Recent Authentication Logs:${NC}"
    tail -n 20 /var/log/auth.log 2>/dev/null
}

# Main menu
while true; do
    clear
    echo -e "${BLUE}=== System Information Menu ===${NC}"
    echo -e "${YELLOW}1.${NC} System Overview"
    echo -e "${YELLOW}2.${NC} Package Information"
    echo -e "${YELLOW}3.${NC} Service Status"
    echo -e "${YELLOW}4.${NC} Hardware Details"
    echo -e "${YELLOW}5.${NC} System Logs"
    echo -e "${YELLOW}6.${NC} Exit"
    echo
    read -p "Select an option (1-6): " choice
    
    case $choice in
        1)
            show_system_overview
            ;;
        2)
            show_package_info
            ;;
        3)
            show_service_status
            ;;
        4)
            show_hardware_details
            ;;
        5)
            show_system_logs
            ;;
        6)
            echo -e "${GREEN}Exiting System Information${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
done 