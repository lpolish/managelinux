#!/bin/bash

# Installation Script for Server Migration and Management Suite
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
    local required_commands=("fdisk" "parted" "tar" "dpkg" "apt-get")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${RED}Required command not found: $cmd${NC}"
            return 1
        fi
    done
    
    echo -e "${GREEN}System requirements met${NC}"
    return 0
}

# Function to create uninstaller
create_uninstaller() {
    echo -e "${BLUE}Creating uninstaller...${NC}"
    
    cat > "$INSTALL_DIR/uninstall.sh" << 'EOF'
#!/bin/bash

# Uninstaller for Server Migration and Management Suite

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root or with sudo privileges${NC}"
    exit 1
fi

# Installation paths
INSTALL_DIR="/usr/local/bin/linux_quick_manage"
SYMLINK_DIR="/usr/local/bin"
BIN_NAME="managelinux"

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
EOF

    chmod +x "$INSTALL_DIR/uninstall.sh"
    echo -e "${GREEN}Uninstaller created: $INSTALL_DIR/uninstall.sh${NC}"
}

# Main installation process
echo -e "${BLUE}Installing Server Migration and Management Suite...${NC}"

# Check root privileges
check_root

# Check system requirements
if ! check_requirements; then
    exit 1
fi

# Create installation directory
echo -e "${BLUE}Creating installation directory...${NC}"
mkdir -p "$INSTALL_DIR"

# Copy all script files
echo -e "${BLUE}Copying files...${NC}"
cp *.sh "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR"/*.sh

# Create symlink
echo -e "${BLUE}Creating symlink...${NC}"
ln -sf "$INSTALL_DIR/server_migrator.sh" "$SYMLINK_DIR/$BIN_NAME"

# Create uninstaller
create_uninstaller

echo -e "${GREEN}Installation completed successfully${NC}"
echo -e "You can now run the suite using: ${YELLOW}$BIN_NAME${NC}"
echo -e "To uninstall, run: ${YELLOW}$INSTALL_DIR/uninstall.sh${NC}" 