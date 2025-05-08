#!/bin/bash

# One-line installer for Server Migration and Management Suite
# Usage: curl -sSL https://raw.githubusercontent.com/lpolish/managelinux/main/install-oneline.sh | sudo bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation paths
INSTALL_DIR="/usr/local/lib/managelinux"
BIN_DIR="/usr/local/bin"
REPO_URL="https://github.com/lpolish/managelinux.git"

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
    
    # Check if git is installed
    if ! command -v git &> /dev/null; then
        echo -e "${YELLOW}Git is not installed. Installing git...${NC}"
        apt-get update && apt-get install -y git || {
            echo -e "${RED}Failed to install git${NC}"
            return 1
        }
    fi
    
    # Check other required commands
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
    
    # Make scripts executable
    chmod +x "$INSTALL_DIR"/*.sh
    
    # Create symlink for the main script
    ln -sf "$INSTALL_DIR/run.sh" "$BIN_DIR/managelinux"
    
    # Create update script
    cat > "$INSTALL_DIR/update.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
git pull
chmod +x *.sh
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
    
    echo -e "${GREEN}Installation completed successfully${NC}"
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

# Install the suite
if ! install_suite; then
    echo -e "${RED}Installation failed${NC}"
    exit 1
fi

echo -e "${GREEN}Installation completed successfully${NC}"
echo -e "You can now run the suite using: ${YELLOW}managelinux${NC}"
echo -e "To update, run: ${YELLOW}managelinux update${NC}"
echo -e "To uninstall, run: ${YELLOW}/usr/local/lib/managelinux/uninstall.sh${NC}" 
