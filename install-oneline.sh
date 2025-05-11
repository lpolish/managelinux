#!/bin/bash

# One-line installer for Server Migration and Management Suite
# Repo: https://github.com/lpolish/managelinux
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
    
    # Update package list
    echo -e "${BLUE}Updating package list...${NC}"
    apt-get update
    
    # Check for required packages
    local required_packages=("git" "curl" "wget")
    for package in "${required_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            echo -e "${YELLOW}Installing $package...${NC}"
            apt-get install -y "$package"
        fi
    done
    
    echo -e "${GREEN}System requirements met${NC}"
}

# Function to clean up old installation
cleanup_old_install() {
    echo -e "${BLUE}Cleaning up old installation...${NC}"
    
    # Remove old installation directory
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}Removing old installation directory...${NC}"
        rm -rf "$INSTALL_DIR"
    fi
    
    # Remove old symlink
    if [ -L "$SYMLINK_DIR/$BIN_NAME" ]; then
        echo -e "${YELLOW}Removing old symlink...${NC}"
        rm -f "$SYMLINK_DIR/$BIN_NAME"
    fi
    
    # Create fresh directory
    mkdir -p "$INSTALL_DIR"
}

# Function to copy scripts
copy_scripts() {
    echo -e "${BLUE}Copying scripts...${NC}"
    
    # List of required scripts
    local scripts=(
        "run.sh"
        "container_manager.sh"
        "partition_manager.sh"
        "migration_manager.sh"
        "system_info.sh"
        "backup_manager.sh"
        "git_server_manager.sh"
        "user_manager.sh"
    )
    
    # Copy each script
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            cp "$script" "$INSTALL_DIR/"
            chmod +x "$INSTALL_DIR/$script"
            echo -e "${GREEN}Copied $script${NC}"
        else
            echo -e "${RED}Warning: $script not found${NC}"
        fi
    done
}

# Main installation process
echo -e "${BLUE}Starting Server Migration and Management Suite installation...${NC}"

# Check root privileges
check_root

# Check system requirements
check_requirements

# Clean up old installation
cleanup_old_install

# Clone repository
echo -e "${BLUE}Cloning repository...${NC}"
git clone https://github.com/lpolish/managelinux.git "$INSTALL_DIR"

if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to clone repository${NC}"
    exit 1
fi

# Make scripts executable
echo -e "${BLUE}Setting up scripts...${NC}"
chmod +x "$INSTALL_DIR"/*.sh

# Create symlink
echo -e "${BLUE}Creating symlink...${NC}"
ln -sf "$INSTALL_DIR/run.sh" "$SYMLINK_DIR/$BIN_NAME"

# Create uninstall script
cat > "$INSTALL_DIR/uninstall.sh" << EOF
#!/bin/bash
rm -rf "$INSTALL_DIR"
rm -f "$SYMLINK_DIR/$BIN_NAME"
echo "Uninstallation completed successfully"
EOF
chmod +x "$INSTALL_DIR/uninstall.sh"

echo -e "${GREEN}Installation completed successfully${NC}"
echo -e "${BLUE}You can now run the suite using: ${YELLOW}managelinux${NC}" 
