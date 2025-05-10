#!/bin/bash

# Migration Manager Script
# Part of Server Migration and Management Suite

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check system requirements
check_requirements() {
    echo -e "${BLUE}Checking system requirements...${NC}"
    
    # Check available disk space
    local required_space=20 # GB
    local available_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    
    if [ "$available_space" -lt "$required_space" ]; then
        echo -e "${RED}Insufficient disk space. Required: ${required_space}GB, Available: ${available_space}GB${NC}"
        return 1
    fi
    
    # Check memory
    local required_mem=4 # GB
    local available_mem=$(free -g | awk '/^Mem:/{print $2}')
    
    if [ "$available_mem" -lt "$required_mem" ]; then
        echo -e "${RED}Insufficient memory. Required: ${required_mem}GB, Available: ${available_mem}GB${NC}"
        return 1
    fi
    
    echo -e "${GREEN}System requirements met${NC}"
    return 0
}

# Function to backup system
backup_system() {
    echo -e "${BLUE}Creating system backup...${NC}"
    
    # Create backup directory
    local backup_dir="/root/system_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup important system files
    tar -czf "$backup_dir/etc_backup.tar.gz" /etc
    tar -czf "$backup_dir/home_backup.tar.gz" /home
    tar -czf "$backup_dir/var_backup.tar.gz" /var
    
    # Backup package list
    dpkg --get-selections > "$backup_dir/package_list.txt"
    
    echo -e "${GREEN}Backup completed: $backup_dir${NC}"
}

# Function to migrate to Ubuntu LTS
migrate_to_ubuntu() {
    echo -e "${BLUE}Starting migration to Ubuntu LTS 22.04...${NC}"
    
    if ! check_requirements; then
        return 1
    fi
    
    echo -e "${YELLOW}WARNING: This will modify your system. Make sure you have backups!${NC}"
    read -p "Continue? (y/N): " confirm
    
    if [[ $confirm != [yY] ]]; then
        return 1
    fi
    
    backup_system
    
    # Add Ubuntu repositories
    echo -e "${BLUE}Adding Ubuntu repositories...${NC}"
    echo "deb http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse" > /etc/apt/sources.list
    echo "deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse" >> /etc/apt/sources.list
    echo "deb http://archive.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse" >> /etc/apt/sources.list
    
    # Update package lists
    apt-get update
    
    # Install Ubuntu base system
    echo -e "${BLUE}Installing Ubuntu base system...${NC}"
    apt-get install --yes ubuntu-minimal
    
    # Update system
    echo -e "${BLUE}Updating system...${NC}"
    apt-get dist-upgrade --yes
    
    echo -e "${GREEN}Migration to Ubuntu LTS completed${NC}"
}

# Function to migrate to Debian Enterprise
migrate_to_debian() {
    echo -e "${BLUE}Starting migration to Debian Enterprise...${NC}"
    
    if ! check_requirements; then
        return 1
    fi
    
    echo -e "${YELLOW}WARNING: This will modify your system. Make sure you have backups!${NC}"
    read -p "Continue? (y/N): " confirm
    
    if [[ $confirm != [yY] ]]; then
        return 1
    fi
    
    backup_system
    
    # Add Debian repositories
    echo -e "${BLUE}Adding Debian repositories...${NC}"
    echo "deb http://deb.debian.org/debian/ bullseye main contrib non-free" > /etc/apt/sources.list
    echo "deb http://deb.debian.org/debian/ bullseye-updates main contrib non-free" >> /etc/apt/sources.list
    echo "deb http://security.debian.org/ bullseye-security main contrib non-free" >> /etc/apt/sources.list
    
    # Update package lists
    apt-get update
    
    # Install Debian base system
    echo -e "${BLUE}Installing Debian base system...${NC}"
    apt-get install --yes debian-archive-keyring
    
    # Update system
    echo -e "${BLUE}Updating system...${NC}"
    apt-get dist-upgrade --yes
    
    echo -e "${GREEN}Migration to Debian Enterprise completed${NC}"
}

# Function to handle custom migration
custom_migration() {
    echo -e "${BLUE}Custom Migration Setup${NC}"
    
    if ! check_requirements; then
        return 1
    fi
    
    echo -e "${YELLOW}Enter custom repository information:${NC}"
    read -p "Repository URL: " repo_url
    read -p "Distribution name: " dist_name
    read -p "Components (space-separated): " components
    
    echo -e "${YELLOW}WARNING: This will modify your system. Make sure you have backups!${NC}"
    read -p "Continue? (y/N): " confirm
    
    if [[ $confirm != [yY] ]]; then
        return 1
    fi
    
    backup_system
    
    # Add custom repository
    echo -e "${BLUE}Adding custom repository...${NC}"
    echo "deb $repo_url $dist_name $components" > /etc/apt/sources.list
    
    # Update package lists
    apt-get update
    
    # Update system
    echo -e "${BLUE}Updating system...${NC}"
    apt-get dist-upgrade --yes
    
    echo -e "${GREEN}Custom migration completed${NC}"
}

# Main script logic
case "$1" in
    "ubuntu")
        migrate_to_ubuntu
        ;;
    "debian")
        migrate_to_debian
        ;;
    "custom")
        custom_migration
        ;;
    *)
        echo -e "${RED}Invalid command${NC}"
        echo "Usage: $0 {ubuntu|debian|custom}"
        exit 1
        ;;
esac 