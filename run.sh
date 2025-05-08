#!/bin/bash

# Main Entry Script for Server Migration and Management Suite
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

# Function to check if suite is installed
is_installed() {
    [ -L "$SYMLINK_DIR/$BIN_NAME" ] && [ -d "$INSTALL_DIR" ]
}

# Function to show installation status
show_status() {
    if is_installed; then
        echo -e "${GREEN}Server Migration and Management Suite is installed${NC}"
        echo -e "Installation directory: ${YELLOW}$INSTALL_DIR${NC}"
        echo -e "Command: ${YELLOW}$BIN_NAME${NC}"
        echo -e "To update, run: ${YELLOW}$BIN_NAME --update${NC}"
        echo -e "To uninstall, run: ${YELLOW}$INSTALL_DIR/uninstall.sh${NC}"
    else
        echo -e "${YELLOW}Server Migration and Management Suite is not installed${NC}"
        echo -e "To install, run: ${YELLOW}sudo ./install.sh${NC}"
    fi
}

# Function to show help
show_help() {
    echo -e "${BLUE}Server Migration and Management Suite${NC}"
    echo
    echo "Usage: $0 [OPTION]"
    echo
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -s, --status   Show installation status"
    echo "  -i, --install  Install the suite"
    echo "  -u, --uninstall Uninstall the suite"
    echo "  -U, --update   Update the suite to the latest version"
    echo "  -r, --run      Run the suite (default if no option provided)"
    echo
    echo "Examples:"
    echo "  $0              # Run the suite"
    echo "  $0 --status     # Show installation status"
    echo "  $0 --install    # Install the suite"
    echo "  $0 --update     # Update the suite"
    echo "  $0 --uninstall  # Uninstall the suite"
}

# Function to handle installation
handle_install() {
    if is_installed; then
        echo -e "${YELLOW}Suite is already installed${NC}"
        show_status
        return 1
    fi
    
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run as root or with sudo privileges${NC}"
        return 1
    fi
    
    ./install.sh
}

# Function to handle uninstallation
handle_uninstall() {
    if ! is_installed; then
        echo -e "${YELLOW}Suite is not installed${NC}"
        return 1
    fi
    
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run as root or with sudo privileges${NC}"
        return 1
    fi
    
    "$INSTALL_DIR/uninstall.sh"
}

# Function to handle updates
handle_update() {
    if ! is_installed; then
        echo -e "${YELLOW}Suite is not installed${NC}"
        return 1
    fi
    
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run as root or with sudo privileges${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Updating Server Migration and Management Suite...${NC}"
    cd "$INSTALL_DIR" || return 1
    
    if git pull; then
        chmod +x *.sh
        echo -e "${GREEN}Update completed successfully${NC}"
        return 0
    else
        echo -e "${RED}Update failed${NC}"
        return 1
    fi
}

# Function to run the suite
run_suite() {
    if is_installed; then
        # Run from installation directory
        if [ -f "$INSTALL_DIR/server_migrator.sh" ]; then
            "$INSTALL_DIR/server_migrator.sh"
        else
            echo -e "${RED}Error: server_migrator.sh not found in $INSTALL_DIR${NC}"
            echo -e "${YELLOW}The installation may be corrupted. Please try:${NC}"
            echo -e "1. Uninstall: ${YELLOW}sudo $INSTALL_DIR/uninstall.sh${NC}"
            echo -e "2. Reinstall: ${YELLOW}sudo ./install.sh${NC}"
            return 1
        fi
    else
        # Run from current directory
        if [ -f "./server_migrator.sh" ]; then
            ./server_migrator.sh
        else
            echo -e "${RED}Error: server_migrator.sh not found${NC}"
            echo -e "${YELLOW}Please run this script from the suite's directory or install it first:${NC}"
            echo -e "1. Install: ${YELLOW}sudo ./install.sh${NC}"
            echo -e "2. Or run: ${YELLOW}sudo ./run.sh --install${NC}"
            return 1
        fi
    fi
}

# Main script logic
case "$1" in
    -h|--help)
        show_help
        ;;
    -s|--status)
        show_status
        ;;
    -i|--install)
        handle_install
        ;;
    -u|--uninstall)
        handle_uninstall
        ;;
    -U|--update)
        handle_update
        ;;
    -r|--run|"")
        run_suite
        ;;
    *)
        echo -e "${RED}Invalid option: $1${NC}"
        show_help
        exit 1
        ;;
esac 