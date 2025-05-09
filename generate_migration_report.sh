#!/bin/bash

# Migration Report Generator
# Part of Server Migration and Management Suite

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create reports directory if it doesn't exist
REPORTS_DIR="migration_reports"
mkdir -p "$REPORTS_DIR"

# Generate timestamp for the report
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="$REPORTS_DIR/migration_report_$TIMESTAMP.txt"

# Function to write section headers
write_section() {
    echo -e "\n=== $1 ===" >> "$REPORT_FILE"
    echo -e "Generated on: $(date)\n" >> "$REPORT_FILE"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get installed software versions
get_software_versions() {
    local software_list=(
        "git"
        "python3"
        "node"
        "npm"
        "docker"
        "vncserver"
        "apache2"
        "nginx"
        "mysql"
        "postgresql"
        "php"
        "ruby"
        "java"
        "python"
        "perl"
    )

    echo -e "\nInstalled Software Versions:" >> "$REPORT_FILE"
    for software in "${software_list[@]}"; do
        if command_exists "$software"; then
            version=$("$software" --version 2>&1 | head -n 1)
            echo "$software: $version" >> "$REPORT_FILE"
        fi
    done
}

# Function to get system information
get_system_info() {
    write_section "System Information"
    
    # OS Information
    echo -e "Operating System:" >> "$REPORT_FILE"
    lsb_release -a 2>/dev/null >> "$REPORT_FILE" || cat /etc/os-release >> "$REPORT_FILE"
    
    # Kernel Information
    echo -e "\nKernel Information:" >> "$REPORT_FILE"
    uname -a >> "$REPORT_FILE"
    
    # CPU Information
    echo -e "\nCPU Information:" >> "$REPORT_FILE"
    lscpu >> "$REPORT_FILE"
    
    # Memory Information
    echo -e "\nMemory Information:" >> "$REPORT_FILE"
    free -h >> "$REPORT_FILE"
    
    # Disk Usage
    echo -e "\nDisk Usage:" >> "$REPORT_FILE"
    df -h >> "$REPORT_FILE"
    
    # Mount Points
    echo -e "\nMount Points:" >> "$REPORT_FILE"
    mount >> "$REPORT_FILE"
}

# Function to get network information
get_network_info() {
    write_section "Network Information"
    
    # Network Interfaces
    echo -e "Network Interfaces:" >> "$REPORT_FILE"
    ip addr show >> "$REPORT_FILE"
    
    # Routing Table
    echo -e "\nRouting Table:" >> "$REPORT_FILE"
    ip route show >> "$REPORT_FILE"
    
    # DNS Configuration
    echo -e "\nDNS Configuration:" >> "$REPORT_FILE"
    cat /etc/resolv.conf >> "$REPORT_FILE"
    
    # Active Network Connections
    echo -e "\nActive Network Connections:" >> "$REPORT_FILE"
    netstat -tulpn 2>/dev/null >> "$REPORT_FILE"
}

# Function to get installed packages
get_installed_packages() {
    write_section "Installed Packages"
    
    # List all installed packages
    echo -e "All Installed Packages:" >> "$REPORT_FILE"
    dpkg -l >> "$REPORT_FILE"
    
    # Get software versions
    get_software_versions
}

# Function to get service information
get_service_info() {
    write_section "Service Information"
    
    # Systemd Services
    echo -e "Systemd Services:" >> "$REPORT_FILE"
    systemctl list-units --type=service --state=running >> "$REPORT_FILE"
    
    # Enabled Services
    echo -e "\nEnabled Services:" >> "$REPORT_FILE"
    systemctl list-unit-files --state=enabled >> "$REPORT_FILE"
}

# Function to get hardware information
get_hardware_info() {
    write_section "Hardware Information"
    
    # PCI Devices
    echo -e "PCI Devices:" >> "$REPORT_FILE"
    lspci -v >> "$REPORT_FILE"
    
    # USB Devices
    echo -e "\nUSB Devices:" >> "$REPORT_FILE"
    lsusb -v >> "$REPORT_FILE"
    
    # Block Devices
    echo -e "\nBlock Devices:" >> "$REPORT_FILE"
    lsblk -f >> "$REPORT_FILE"
}

# Function to get security information
get_security_info() {
    write_section "Security Information"
    
    # Open Ports
    echo -e "Open Ports:" >> "$REPORT_FILE"
    netstat -tulpn 2>/dev/null >> "$REPORT_FILE"
    
    # Firewall Status
    echo -e "\nFirewall Status:" >> "$REPORT_FILE"
    if command_exists ufw; then
        ufw status verbose >> "$REPORT_FILE"
    fi
    
    # Failed Login Attempts
    echo -e "\nFailed Login Attempts:" >> "$REPORT_FILE"
    grep "Failed password" /var/log/auth.log 2>/dev/null | tail -n 50 >> "$REPORT_FILE"
}

# Main execution
echo -e "${BLUE}Generating Migration Report...${NC}"

# Generate all sections
get_system_info
get_network_info
get_installed_packages
get_service_info
get_hardware_info
get_security_info

echo -e "${GREEN}Report generated successfully!${NC}"
echo -e "${YELLOW}Report location: $REPORT_FILE${NC}"

# Display the report using less
less -R "$REPORT_FILE" 