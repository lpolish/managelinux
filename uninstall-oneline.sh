#!/bin/bash

# One-line uninstaller for Server Migration and Management Suite
# Repo: https://github.com/lpolish/managelinuxr
# Version: 1.0.0

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation paths (both old and new)
INSTALL_DIRS=(
    "/usr/local/bin/linux_quick_manage"
    "/usr/local/lib/managelinux"
)
SYMLINK_DIR="/usr/local/bin"
BIN_NAME="managelinux"

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run as root or with sudo privileges${NC}"
        exit 1
    fi
}

# Function to remove a directory if it exists
remove_dir() {
    local dir="$1"
    if [ -d "$dir" ]; then
        echo -e "${BLUE}Removing directory: ${YELLOW}$dir${NC}"
        rm -rf "$dir"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Successfully removed directory${NC}"
        else
            echo -e "${RED}Failed to remove directory${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}Directory not found: $dir${NC}"
    fi
}

# Function to remove a symlink if it exists
remove_symlink() {
    local link="$1"
    if [ -L "$link" ]; then
        echo -e "${BLUE}Removing symlink: ${YELLOW}$link${NC}"
        rm -f "$link"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Successfully removed symlink${NC}"
        else
            echo -e "${RED}Failed to remove symlink${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}Symlink not found: $link${NC}"
    fi
}

# Main uninstallation process
echo -e "${BLUE}Starting Server Migration and Management Suite uninstallation...${NC}"

# Check root privileges
check_root

# Remove symlink
remove_symlink "$SYMLINK_DIR/$BIN_NAME"

# Remove all possible installation directories
for dir in "${INSTALL_DIRS[@]}"; do
    remove_dir "$dir"
done

# Check if anything remains
remaining=false
for dir in "${INSTALL_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        remaining=true
        echo -e "${RED}Warning: Directory still exists: $dir${NC}"
    fi
done

if [ -L "$SYMLINK_DIR/$BIN_NAME" ]; then
    remaining=true
    echo -e "${RED}Warning: Symlink still exists: $SYMLINK_DIR/$BIN_NAME${NC}"
fi

if [ "$remaining" = true ]; then
    echo -e "${YELLOW}Some components could not be removed. You may need to remove them manually.${NC}"
    exit 1
else
    echo -e "${GREEN}Uninstallation completed successfully${NC}"
    exit 0
fi 