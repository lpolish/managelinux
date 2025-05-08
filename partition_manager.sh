#!/bin/bash

# Partition Manager Script
# Part of Server Migration and Management Suite

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if running from USB
check_usb_boot() {
    if [ -d "/cdrom" ] || [ -d "/media/cdrom" ]; then
        return 0
    fi
    return 1
}

# Function to list available disks
list_disks() {
    echo -e "${BLUE}Available Disks:${NC}"
    echo -e "${YELLOW}Device\tSize\tModel${NC}"
    echo "----------------------------------------"
    lsblk -d -o NAME,SIZE,MODEL | grep -v "NAME" | while read -r line; do
        echo -e "${GREEN}$line${NC}"
    done
    echo
}

# Function to show detailed partition information
show_partitions() {
    echo -e "${BLUE}Detailed Partition Information:${NC}"
    echo -e "${YELLOW}Device\t\tSize\tType\t\tMount Point\tFilesystem${NC}"
    echo "--------------------------------------------------------------------------------"
    
    # Get partition information using lsblk
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE | grep -v "NAME" | while read -r line; do
        # Skip empty lines and disk devices (only show partitions)
        if [[ $line == *"part"* ]] || [[ $line == *"lvm"* ]]; then
            echo -e "${GREEN}$line${NC}"
        fi
    done
    
    echo
    echo -e "${BLUE}Additional Information:${NC}"
    echo -e "${YELLOW}Disk Usage Summary:${NC}"
    df -h | grep -v "tmpfs" | grep -v "udev" | while read -r line; do
        echo -e "${GREEN}$line${NC}"
    done
}

# Function to create new partition
create_partition() {
    list_disks
    read -p "Enter disk name (e.g., /dev/sda): " disk
    
    if [ ! -b "$disk" ]; then
        echo -e "${RED}Invalid disk device${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Creating new partition on $disk${NC}"
    echo -e "${YELLOW}WARNING: This will modify disk partitions. Make sure you have backups!${NC}"
    read -p "Continue? (y/N): " confirm
    
    if [[ $confirm != [yY] ]]; then
        return 1
    fi
    
    # Start fdisk in interactive mode
    fdisk "$disk"
    
    echo -e "${GREEN}Partition created successfully${NC}"
}

# Function to resize partition
resize_partition() {
    list_disks
    read -p "Enter disk name (e.g., /dev/sda): " disk
    
    if [ ! -b "$disk" ]; then
        echo -e "${RED}Invalid disk device${NC}"
        return 1
    fi
    
    show_partitions
    echo
    
    read -p "Enter partition number to resize (e.g., 1): " partition
    
    if [ ! -b "${disk}${partition}" ]; then
        echo -e "${RED}Invalid partition${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Resizing partition ${disk}${partition}${NC}"
    echo -e "${YELLOW}WARNING: This operation can be dangerous. Make sure you have backups!${NC}"
    read -p "Continue? (y/N): " confirm
    
    if [[ $confirm != [yY] ]]; then
        return 1
    fi
    
    # Use parted for resizing
    parted "$disk" resizepart "$partition" -- -1
    
    echo -e "${GREEN}Partition resized successfully${NC}"
}

# Function to format partition
format_partition() {
    list_disks
    read -p "Enter disk name (e.g., /dev/sda): " disk
    
    if [ ! -b "$disk" ]; then
        echo -e "${RED}Invalid disk device${NC}"
        return 1
    fi
    
    show_partitions
    echo
    
    read -p "Enter partition number to format (e.g., 1): " partition
    
    if [ ! -b "${disk}${partition}" ]; then
        echo -e "${RED}Invalid partition${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Available filesystem types:${NC}"
    echo "1. ext4 (Recommended for Linux)"
    echo "2. xfs (Good for large files)"
    echo "3. btrfs (Advanced features)"
    echo "4. ntfs (Windows compatibility)"
    
    read -p "Select filesystem type (1-4): " fs_type
    
    case $fs_type in
        1) fs="ext4" ;;
        2) fs="xfs" ;;
        3) fs="btrfs" ;;
        4) fs="ntfs" ;;
        *)
            echo -e "${RED}Invalid filesystem type${NC}"
            return 1
            ;;
    esac
    
    echo -e "${YELLOW}Formatting ${disk}${partition} with $fs${NC}"
    echo -e "${YELLOW}WARNING: This will erase all data on the partition!${NC}"
    read -p "Continue? (y/N): " confirm
    
    if [[ $confirm != [yY] ]]; then
        return 1
    fi
    
    case $fs in
        ext4)
            mkfs.ext4 "${disk}${partition}"
            ;;
        xfs)
            mkfs.xfs "${disk}${partition}"
            ;;
        btrfs)
            mkfs.btrfs "${disk}${partition}"
            ;;
        ntfs)
            mkfs.ntfs "${disk}${partition}"
            ;;
    esac
    
    echo -e "${GREEN}Partition formatted successfully${NC}"
}

# Main script logic
case "$1" in
    "create")
        create_partition
        ;;
    "resize")
        resize_partition
        ;;
    "format")
        format_partition
        ;;
    *)
        show_partitions
        ;;
esac 