#!/bin/bash

# One-line installer for Server Migration and Management Suite
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
REPO_URL="https://github.com/lpolish/managelinux.git"

echo "Starting Server Migration and Management Suite installation..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root or with sudo privileges${NC}"
    exit 1
fi

# Check system requirements
echo "Checking system requirements..."

# Update package list
echo "Updating package list..."
apt-get update

# Check for required commands
required_commands=("git" "fdisk" "parted" "tar" "dpkg" "apt-get")
for cmd in "${required_commands[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${RED}Required command not found: $cmd${NC}"
        echo "Installing required packages..."
        apt-get install -y "$cmd"
    fi
done

echo "System requirements met"

# Install the suite
echo "Installing Server Migration and Management Suite..."

# Remove existing installation if it exists
if [ -d "$INSTALL_DIR" ]; then
    echo "Removing existing installation..."
    rm -rf "$INSTALL_DIR"
fi

# Clone repository
echo "Cloning repository..."
if ! git clone "$REPO_URL" "$INSTALL_DIR"; then
    echo -e "${RED}Failed to clone repository${NC}"
    echo "Installation failed"
    exit 1
fi

# Make scripts executable
echo "Setting up scripts..."
chmod +x "$INSTALL_DIR"/*.sh

# Create symlink
echo "Creating symlink..."
ln -sf "$INSTALL_DIR/server_migrator.sh" "/usr/local/bin/managelinux"

# Verify installation
if [ -L "/usr/local/bin/managelinux" ] && [ -d "$INSTALL_DIR" ] && [ -f "$INSTALL_DIR/server_migrator.sh" ]; then
    echo -e "${GREEN}Installation completed successfully!${NC}"
    echo -e "You can now run the suite using: ${YELLOW}managelinux${NC}"
    echo -e "Installation directory: ${YELLOW}$INSTALL_DIR${NC}"
else
    echo -e "${RED}Installation failed${NC}"
    exit 1
fi 
