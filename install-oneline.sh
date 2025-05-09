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
BIN_DIR="/usr/local/bin"
REPO_URL="https://github.com/lpolish/managelinux.git"

echo "Starting Server Migration and Management Suite installation..."

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
    
    # Ensure apt-get is available first
    if ! command -v apt-get &> /dev/null; then
        echo -e "${RED}This script requires apt-get package manager${NC}"
        return 1
    fi
    
    # Update package list
    echo -e "${BLUE}Updating package list...${NC}"
    apt-get update || {
        echo -e "${RED}Failed to update package list${NC}"
        return 1
    }
    
    # Map commands to their package names
    declare -A cmd_packages=(
        ["git"]="git"
        ["fdisk"]="util-linux"
        ["parted"]="parted"
        ["tar"]="tar"
        ["dpkg"]="dpkg"
        ["curl"]="curl"
    )
    
    # Check and install required packages
    local missing_packages=()
    local missing_commands=()
    
    for cmd in "${!cmd_packages[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${YELLOW}Required command not found: $cmd${NC}"
            missing_commands+=("$cmd")
            missing_packages+=("${cmd_packages[$cmd]}")
        fi
    done
    
    # Install missing packages if any
    if [ ${#missing_packages[@]} -gt 0 ]; then
        echo -e "${BLUE}Installing missing packages: ${missing_packages[*]}${NC}"
        if ! apt-get install -y "${missing_packages[@]}"; then
            echo -e "${RED}Failed to install required packages${NC}"
            return 1
        fi
        
        # Verify commands are now available
        for cmd in "${missing_commands[@]}"; do
            if ! command -v "$cmd" &> /dev/null; then
                echo -e "${RED}Command '$cmd' is still not available after package installation${NC}"
                return 1
            fi
        done
    fi
    
    echo -e "${GREEN}System requirements met${NC}"
    return 0
}

# Function to install the suite
install_suite() {
    echo -e "${BLUE}Installing Server Migration and Management Suite...${NC}"
    
    # Create installation directory if it doesn't exist
    mkdir -p "$INSTALL_DIR"
    
    # Clone the repository
    echo -e "${BLUE}Cloning repository...${NC}"
    if ! git clone "$REPO_URL" "$INSTALL_DIR"; then
        echo -e "${RED}Failed to clone repository${NC}"
        return 1
    fi
    
    # Make all scripts executable and ensure proper line endings
    echo -e "${BLUE}Setting up scripts...${NC}"
    find "$INSTALL_DIR" -type f -name "*.sh" -exec chmod +x {} \;
    find "$INSTALL_DIR" -type f -name "*.sh" -exec dos2unix {} \; 2>/dev/null || true
    
    # Create symlink for the main script
    ln -sf "$INSTALL_DIR/run.sh" "$BIN_DIR/managelinux"
    
    # Create update script
    cat > "$INSTALL_DIR/update.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
git pull
find . -type f -name "*.sh" -exec chmod +x {} \;
find . -type f -name "*.sh" -exec dos2unix {} \; 2>/dev/null || true
echo "Update completed successfully"
EOF
    
    chmod +x "$INSTALL_DIR/update.sh"
    
    # Create uninstall script
    cat > "$INSTALL_DIR/uninstall.sh" << EOF
#!/bin/bash
rm -f "$BIN_DIR/managelinux"
rm -rf "$INSTALL_DIR"
echo "Uninstallation completed successfully"
EOF
    
    chmod +x "$INSTALL_DIR/uninstall.sh"
    
    # Create a config file to store installation paths
    cat > "$INSTALL_DIR/config.sh" << EOF
#!/bin/bash
# Configuration file for Server Migration and Management Suite
INSTALL_DIR="$INSTALL_DIR"
BIN_DIR="$BIN_DIR"
EOF
    
    chmod +x "$INSTALL_DIR/config.sh"
    
    echo -e "${GREEN}Installation completed successfully${NC}"
    return 0
}

# Main installation process
echo -e "${BLUE}Starting Server Migration and Management Suite installation...${NC}"

# Check root privileges
check_root

# Check system requirements
check_requirements || {
    echo -e "${RED}System requirements check failed${NC}"
    exit 1
}

# Install the suite
install_suite || {
    echo -e "${RED}Installation failed${NC}"
    exit 1
}

echo -e "${GREEN}Installation completed successfully!${NC}"
echo -e "You can now run the suite using: ${YELLOW}managelinux${NC}"
echo -e "Installation directory: ${YELLOW}$INSTALL_DIR${NC}" 
