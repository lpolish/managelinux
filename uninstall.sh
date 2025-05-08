#!/bin/bash

# Uninstaller for Server Migration and Management Suite
# Repo: https://github.com/lpolish/managelinuxr
# Version: 1.0.0

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation paths
INSTALL_DIR="/usr/local/bin/linux_quick_manage"
SYMLINK_DIR="/usr/local/bin"
BIN_NAME="managelinux"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root or with sudo privileges${NC}"
    exit 1
fi

echo -e "${YELLOW}Uninstalling Server Migration and Management Suite...${NC}"

# Remove symlink
if [ -L "$SYMLINK_DIR/$BIN_NAME" ]; then
    rm "$SYMLINK_DIR/$BIN_NAME"
    echo -e "${GREEN}Removed symlink: $SYMLINK_DIR/$BIN_NAME${NC}"
fi

# Remove installation directory
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo -e "${GREEN}Removed installation directory: $INSTALL_DIR${NC}"
fi

echo -e "${GREEN}Uninstallation completed successfully${NC}" 