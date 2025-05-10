#!/bin/bash

# Server Migration and Management Suite
# Main Entry Point
# Repo: https://github.com/lpolish/managelinux
# Version: 1.0.0

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}This script must be run as root${NC}"
        exit 1
    fi
}

# Function to show main menu
show_menu() {
    clear
    echo -e "${BLUE}=== Server Migration and Management Suite ===${NC}"
    echo
    echo "1. Partition Management"
    echo "2. System Migration"
    echo "3. System Information"
    echo "4. Backup Management"
    echo "5. Container Management"
    echo "6. Git Server Management"
    echo "7. User Management"
    echo "8. Exit"
    echo
    echo -n "Enter your choice (1-8): "
}

# Function to handle container management
handle_container_management() {
    while true; do
        clear
        echo -e "${BLUE}=== Container Management ===${NC}"
        echo
        echo "1. Initialize Application"
        echo "2. List Applications"
        echo "3. Start Application"
        echo "4. Stop Application"
        echo "5. Restart Application"
        echo "6. Update Application"
        echo "7. Show Application Status"
        echo "8. Backup Application"
        echo "9. Restore Application"
        echo "10. Cleanup Resources"
        echo "11. Generate Kubernetes Manifests"
        echo "12. Return to Main Menu"
        echo
        echo -n "Enter your choice (1-12): "
        read -r choice

        case $choice in
            1)
                echo -n "Enter application name: "
                read -r app_name
                "$SCRIPT_DIR/container_manager.sh" init "$app_name"
                ;;
            2)
                "$SCRIPT_DIR/container_manager.sh" list
                ;;
            3)
                echo -n "Enter application name: "
                read -r app_name
                "$SCRIPT_DIR/container_manager.sh" start "$app_name"
                ;;
            4)
                echo -n "Enter application name: "
                read -r app_name
                "$SCRIPT_DIR/container_manager.sh" stop "$app_name"
                ;;
            5)
                echo -n "Enter application name: "
                read -r app_name
                "$SCRIPT_DIR/container_manager.sh" restart "$app_name"
                ;;
            6)
                echo -n "Enter application name: "
                read -r app_name
                "$SCRIPT_DIR/container_manager.sh" update "$app_name"
                ;;
            7)
                echo -n "Enter application name: "
                read -r app_name
                "$SCRIPT_DIR/container_manager.sh" status "$app_name"
                ;;
            8)
                echo -n "Enter application name: "
                read -r app_name
                "$SCRIPT_DIR/container_manager.sh" backup "$app_name"
                ;;
            9)
                echo -n "Enter application name: "
                read -r app_name
                echo -n "Enter backup date (YYYY-MM-DD): "
                read -r backup_date
                "$SCRIPT_DIR/container_manager.sh" restore "$app_name" "$backup_date"
                ;;
            10)
                echo -n "Enter application name: "
                read -r app_name
                "$SCRIPT_DIR/container_manager.sh" cleanup "$app_name"
                ;;
            11)
                echo -n "Enter application name: "
                read -r app_name
                "$SCRIPT_DIR/container_manager.sh" migrate "$app_name"
                ;;
            12)
                return
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                ;;
        esac
        echo
        echo -n "Press Enter to continue..."
        read -r
    done
}

# Main script
check_root

while true; do
    show_menu
    read -r choice

    case $choice in
        1)
            "$SCRIPT_DIR/partition_manager.sh"
            ;;
        2)
            "$SCRIPT_DIR/migration_manager.sh"
            ;;
        3)
            "$SCRIPT_DIR/system_info.sh"
            ;;
        4)
            "$SCRIPT_DIR/backup_manager.sh"
            ;;
        5)
            handle_container_management
            ;;
        6)
            "$SCRIPT_DIR/git_server_manager.sh"
            ;;
        7)
            "$SCRIPT_DIR/user_manager.sh"
            ;;
        8)
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            ;;
    esac
    echo
    echo -n "Press Enter to continue..."
    read -r
done 