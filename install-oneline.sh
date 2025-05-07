#!/bin/bash

# One-line installer for Server Migration and Management Suite
# Usage: curl @https://raw.githubusercontent.com/lpolish/managelinux/refs/heads/main/install.sh | sh

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Temporary directory for installation
TEMP_DIR=$(mktemp -d)
REPO_URL="@https://raw.githubusercontent.com/lpolish/managelinux/refs/heads/main/install.sh"

# Function to cleanup on exit
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

# Set up cleanup on script exit
trap cleanup EXIT

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run as root or with sudo privileges${NC}"
        exit 1
    fi
}

# Function to check system requirements
check_requirements() {
    echo -e "${BLUE}Checking system requirements...${NC}"
    
    # Check if required commands are available
    local required_commands=("fdisk" "parted" "tar" "dpkg" "apt-get" "curl")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${RED}Required command not found: $cmd${NC}"
            return 1
        fi
    done
    
    echo -e "${GREEN}System requirements met${NC}"
    return 0
}

# Main installation process
echo -e "${BLUE}Starting Server Migration and Management Suite installation...${NC}"

# Check root privileges
check_root

# Check system requirements
if ! check_requirements; then
    exit 1
fi

# Download and execute the installation script
echo -e "${BLUE}Downloading and running installation script...${NC}"
if ! curl -sSL "$REPO_URL" | bash; then
    echo -e "${RED}Installation failed${NC}"
    exit 1
fi

echo -e "${GREEN}Installation completed successfully${NC}"
echo -e "You can now run the suite using: ${YELLOW}managelinux${NC}"
echo -e "To uninstall, run: ${YELLOW}/usr/local/bin/linux_quick_manage/uninstall.sh${NC}" 