#!/bin/bash

# Live USB Creator
# Part of Server Migration and Management Suite

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run this script as root or with sudo${NC}"
        exit 1
    fi
}

# Function to check required tools
check_requirements() {
    local missing_tools=()
    
    for tool in "wget" "dd" "lsblk" "parted" "mkfs.vfat" "mkfs.ext4"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}Missing required tools: ${missing_tools[*]}${NC}"
        echo -e "${YELLOW}Installing required tools...${NC}"
        apt-get update
        apt-get install -y "${missing_tools[@]}"
    fi
}

# Function to list available USB drives
list_usb_drives() {
    echo -e "${BLUE}Available USB drives:${NC}"
    lsblk -d -o NAME,SIZE,MODEL | grep -v "loop"
    echo
}

# Function to download Ubuntu 22.04 ISO
download_iso() {
    local iso_url="https://releases.ubuntu.com/22.04/ubuntu-22.04.3-desktop-amd64.iso"
    local iso_file="ubuntu-22.04.3-desktop-amd64.iso"
    
    if [ ! -f "$iso_file" ]; then
        echo -e "${YELLOW}Downloading Ubuntu 22.04 ISO...${NC}"
        wget -q --show-progress "$iso_url"
    else
        echo -e "${GREEN}ISO file already exists${NC}"
    fi
}

# Function to create live USB
create_live_usb() {
    local target_drive="$1"
    local iso_file="ubuntu-22.04.3-desktop-amd64.iso"
    
    # Verify target drive exists
    if [ ! -b "$target_drive" ]; then
        echo -e "${RED}Error: $target_drive is not a valid block device${NC}"
        return 1
    fi
    
    # Confirm with user
    echo -e "${RED}WARNING: This will erase all data on $target_drive${NC}"
    read -p "Are you sure you want to continue? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Operation cancelled${NC}"
        return 1
    fi
    
    # Unmount any mounted partitions
    echo -e "${YELLOW}Unmounting any mounted partitions...${NC}"
    umount "${target_drive}"* 2>/dev/null
    
    # Create live USB
    echo -e "${YELLOW}Creating live USB...${NC}"
    echo -e "${YELLOW}This may take several minutes. Please wait...${NC}"
    
    # Use dd to write the ISO
    dd if="$iso_file" of="$target_drive" bs=4M status=progress
    
    # Sync to ensure all data is written
    sync
    
    echo -e "${GREEN}Live USB created successfully!${NC}"
}

# Main execution
check_root
check_requirements

echo -e "${BLUE}=== Ubuntu 22.04 Live USB Creator ===${NC}"
echo

# List available USB drives
list_usb_drives

# Get target drive from user
read -p "Enter the target USB drive (e.g., /dev/sdb): " target_drive

# Download ISO if needed
download_iso

# Create live USB
create_live_usb "$target_drive" 