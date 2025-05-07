#!/bin/bash

# Backup Manager Script
# Part of Server Migration and Management Suite

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to create backup
create_backup() {
    echo -e "${BLUE}Creating System Backup${NC}"
    
    # Get backup location
    read -p "Enter backup location (default: /root/backups): " backup_location
    backup_location=${backup_location:-/root/backups}
    
    # Create backup directory
    local backup_dir="$backup_location/system_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    echo -e "${YELLOW}Creating backup in $backup_dir${NC}"
    
    # Backup important system files
    echo -e "${BLUE}Backing up /etc...${NC}"
    tar -czf "$backup_dir/etc_backup.tar.gz" /etc
    
    echo -e "${BLUE}Backing up /home...${NC}"
    tar -czf "$backup_dir/home_backup.tar.gz" /home
    
    echo -e "${BLUE}Backing up /var...${NC}"
    tar -czf "$backup_dir/var_backup.tar.gz" /var
    
    # Backup package list
    echo -e "${BLUE}Backing up package list...${NC}"
    dpkg --get-selections > "$backup_dir/package_list.txt"
    
    # Create backup manifest
    echo -e "${BLUE}Creating backup manifest...${NC}"
    {
        echo "Backup created: $(date)"
        echo "System: $(uname -a)"
        echo "Distribution: $(lsb_release -a 2>/dev/null || cat /etc/os-release)"
        echo "Backup location: $backup_dir"
        echo "Files:"
        ls -lh "$backup_dir"
    } > "$backup_dir/manifest.txt"
    
    echo -e "${GREEN}Backup completed successfully${NC}"
    echo -e "Backup location: $backup_dir"
}

# Function to restore backup
restore_backup() {
    echo -e "${BLUE}Restoring System Backup${NC}"
    
    # Get backup location
    read -p "Enter backup directory to restore from: " backup_dir
    
    if [ ! -d "$backup_dir" ]; then
        echo -e "${RED}Backup directory not found${NC}"
        return 1
    fi
    
    # Verify backup files
    if [ ! -f "$backup_dir/etc_backup.tar.gz" ] || \
       [ ! -f "$backup_dir/home_backup.tar.gz" ] || \
       [ ! -f "$backup_dir/var_backup.tar.gz" ] || \
       [ ! -f "$backup_dir/package_list.txt" ]; then
        echo -e "${RED}Invalid backup directory: missing required files${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}WARNING: This will overwrite existing system files!${NC}"
    echo -e "${YELLOW}Make sure you have a current backup before proceeding.${NC}"
    read -p "Continue? (y/N): " confirm
    
    if [[ $confirm != [yY] ]]; then
        return 1
    fi
    
    # Restore files
    echo -e "${BLUE}Restoring /etc...${NC}"
    tar -xzf "$backup_dir/etc_backup.tar.gz" -C /
    
    echo -e "${BLUE}Restoring /home...${NC}"
    tar -xzf "$backup_dir/home_backup.tar.gz" -C /
    
    echo -e "${BLUE}Restoring /var...${NC}"
    tar -xzf "$backup_dir/var_backup.tar.gz" -C /
    
    # Restore packages
    echo -e "${BLUE}Restoring packages...${NC}"
    dpkg --set-selections < "$backup_dir/package_list.txt"
    apt-get dselect-upgrade -y
    
    echo -e "${GREEN}Restore completed successfully${NC}"
}

# Function to list backups
list_backups() {
    echo -e "${BLUE}Available Backups${NC}"
    
    # Get backup location
    read -p "Enter backup location (default: /root/backups): " backup_location
    backup_location=${backup_location:-/root/backups}
    
    if [ ! -d "$backup_location" ]; then
        echo -e "${RED}No backups found in $backup_location${NC}"
        return 1
    fi
    
    # List backups
    for backup in "$backup_location"/system_backup_*; do
        if [ -d "$backup" ]; then
            echo -e "${YELLOW}Backup: $(basename "$backup")${NC}"
            if [ -f "$backup/manifest.txt" ]; then
                echo "Created: $(grep "Backup created:" "$backup/manifest.txt" | cut -d':' -f2-)"
                echo "System: $(grep "System:" "$backup/manifest.txt" | cut -d':' -f2-)"
                echo "Distribution: $(grep "Distribution:" "$backup/manifest.txt" | cut -d':' -f2-)"
            fi
            echo "Size: $(du -sh "$backup" | cut -f1)"
            echo
        fi
    done
}

# Function to verify backup
verify_backup() {
    echo -e "${BLUE}Verify Backup${NC}"
    
    # Get backup location
    read -p "Enter backup directory to verify: " backup_dir
    
    if [ ! -d "$backup_dir" ]; then
        echo -e "${RED}Backup directory not found${NC}"
        return 1
    fi
    
    # Verify backup files
    echo -e "${BLUE}Verifying backup files...${NC}"
    
    for file in etc_backup.tar.gz home_backup.tar.gz var_backup.tar.gz package_list.txt; do
        if [ ! -f "$backup_dir/$file" ]; then
            echo -e "${RED}Missing required file: $file${NC}"
            return 1
        fi
    done
    
    # Verify tar archives
    echo -e "${BLUE}Verifying archive integrity...${NC}"
    
    for archive in etc_backup.tar.gz home_backup.tar.gz var_backup.tar.gz; do
        if ! tar -tzf "$backup_dir/$archive" > /dev/null; then
            echo -e "${RED}Archive verification failed: $archive${NC}"
            return 1
        fi
    done
    
    echo -e "${GREEN}Backup verification completed successfully${NC}"
}

# Main menu
while true; do
    clear
    echo -e "${BLUE}=== Backup Manager Menu ===${NC}"
    echo -e "${YELLOW}1.${NC} Create Backup"
    echo -e "${YELLOW}2.${NC} Restore Backup"
    echo -e "${YELLOW}3.${NC} List Backups"
    echo -e "${YELLOW}4.${NC} Verify Backup"
    echo -e "${YELLOW}5.${NC} Exit"
    echo
    read -p "Select an option (1-5): " choice
    
    case $choice in
        1)
            create_backup
            ;;
        2)
            restore_backup
            ;;
        3)
            list_backups
            ;;
        4)
            verify_backup
            ;;
        5)
            echo -e "${GREEN}Exiting Backup Manager${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    
    echo
    read -p "Press Enter to continue..."
done 