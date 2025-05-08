#!/bin/bash

# Installation script for Server Migration and Management Suite
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

# Create installation directory
echo -e "${BLUE}Creating installation directory...${NC}"
mkdir -p "$INSTALL_DIR"

# Copy all script files
echo -e "${BLUE}Copying script files...${NC}"
cp -f *.sh "$INSTALL_DIR/"

# Make all scripts executable
echo -e "${BLUE}Setting executable permissions...${NC}"
chmod +x "$INSTALL_DIR"/*.sh

# Create symlink
echo -e "${BLUE}Creating symlink...${NC}"
ln -sf "$INSTALL_DIR/server_migrator.sh" "$SYMLINK_DIR/$BIN_NAME"

# Verify installation
if [ -L "$SYMLINK_DIR/$BIN_NAME" ] && [ -d "$INSTALL_DIR" ]; then
    echo -e "${GREEN}Installation completed successfully!${NC}"
    echo -e "You can now run the suite using: ${YELLOW}$BIN_NAME${NC}"
    echo -e "Installation directory: ${YELLOW}$INSTALL_DIR${NC}"
else
    echo -e "${RED}Installation failed${NC}"
    exit 1
fi 