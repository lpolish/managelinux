#!/bin/bash

# User Management Script
# Part of Server Migration and Management Suite
# Repo: https://github.com/lpolish/managelinuxr
# Version: 1.0.0

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Git server configuration
GIT_USER="git"
GIT_HOME="/home/$GIT_USER"
GIT_REPO_DIR="$GIT_HOME/repositories"
SSH_DIR="$GIT_HOME/.ssh"

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run as root or with sudo privileges${NC}"
        exit 1
    fi
}

# Function to create a new user
create_user() {
    echo -e "${BLUE}Creating new user...${NC}"
    read -p "Enter username: " username
    read -p "Enter full name: " fullname
    read -s -p "Enter password: " password
    echo
    
    if [ -z "$username" ] || [ -z "$fullname" ] || [ -z "$password" ]; then
        echo -e "${RED}All fields are required${NC}"
        return 1
    fi
    
    # Check if user exists
    if id "$username" &>/dev/null; then
        echo -e "${RED}User already exists${NC}"
        return 1
    fi
    
    # Create user
    useradd -m -c "$fullname" "$username"
    echo "$username:$password" | chpasswd
    
    # Add to sudo group if requested
    read -p "Add user to sudo group? (y/n): " add_sudo
    if [ "$add_sudo" = "y" ] || [ "$add_sudo" = "Y" ]; then
        usermod -aG sudo "$username"
        echo -e "${GREEN}User added to sudo group${NC}"
    fi
    
    echo -e "${GREEN}User created successfully${NC}"
}

# Function to delete a user
delete_user() {
    echo -e "${BLUE}Deleting user...${NC}"
    read -p "Enter username to delete: " username
    
    if [ -z "$username" ]; then
        echo -e "${RED}Username is required${NC}"
        return 1
    fi
    
    # Check if user exists
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}User does not exist${NC}"
        return 1
    fi
    
    # Confirm deletion
    read -p "Are you sure you want to delete user $username? (y/n): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo -e "${YELLOW}User deletion cancelled${NC}"
        return 0
    fi
    
    # Delete user and home directory
    userdel -r "$username"
    echo -e "${GREEN}User deleted successfully${NC}"
}

# Function to list users
list_users() {
    echo -e "${BLUE}System Users:${NC}"
    echo -e "${YELLOW}Username\tFull Name\tGroups${NC}"
    echo "----------------------------------------"
    
    while IFS=: read -r username _ uid gid fullname home shell; do
        if [ "$uid" -ge 1000 ] && [ "$uid" -ne 65534 ]; then
            groups=$(groups "$username" | cut -d: -f2)
            echo -e "$username\t$fullname\t$groups"
        fi
    done < /etc/passwd
}

# Function to manage Git server access
manage_git_access() {
    echo -e "${BLUE}Git Server Access Management${NC}"
    echo -e "${YELLOW}1.${NC} Add Git access for user"
    echo -e "${YELLOW}2.${NC} Remove Git access for user"
    echo -e "${YELLOW}3.${NC} List users with Git access"
    echo -e "${YELLOW}4.${NC} Back to main menu"
    
    read -p "Select an option (1-4): " git_choice
    
    case $git_choice in
        1)
            add_git_access
            ;;
        2)
            remove_git_access
            ;;
        3)
            list_git_users
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
}

# Function to add Git access for a user
add_git_access() {
    echo -e "${BLUE}Adding Git access...${NC}"
    read -p "Enter username: " username
    
    if [ -z "$username" ]; then
        echo -e "${RED}Username is required${NC}"
        return 1
    fi
    
    # Check if user exists
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}User does not exist${NC}"
        return 1
    fi
    
    # Check if user already has Git access
    if [ -f "$SSH_DIR/authorized_keys" ] && grep -q "$username" "$SSH_DIR/authorized_keys"; then
        echo -e "${YELLOW}User already has Git access${NC}"
        return 0
    fi
    
    # Get user's public key
    user_home=$(eval echo ~$username)
    if [ ! -f "$user_home/.ssh/id_rsa.pub" ]; then
        echo -e "${YELLOW}User does not have an SSH key. Generating one...${NC}"
        sudo -u "$username" ssh-keygen -t rsa -b 4096 -f "$user_home/.ssh/id_rsa" -N ""
    fi
    
    # Add user's public key to Git server
    cat "$user_home/.ssh/id_rsa.pub" >> "$SSH_DIR/authorized_keys"
    chown "$GIT_USER:$GIT_USER" "$SSH_DIR/authorized_keys"
    
    echo -e "${GREEN}Git access added successfully${NC}"
}

# Function to remove Git access for a user
remove_git_access() {
    echo -e "${BLUE}Removing Git access...${NC}"
    read -p "Enter username: " username
    
    if [ -z "$username" ]; then
        echo -e "${RED}Username is required${NC}"
        return 1
    fi
    
    # Check if user exists
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}User does not exist${NC}"
        return 1
    fi
    
    # Remove user's public key from Git server
    if [ -f "$SSH_DIR/authorized_keys" ]; then
        user_home=$(eval echo ~$username)
        if [ -f "$user_home/.ssh/id_rsa.pub" ]; then
            key=$(cat "$user_home/.ssh/id_rsa.pub")
            sed -i "\|$key|d" "$SSH_DIR/authorized_keys"
            echo -e "${GREEN}Git access removed successfully${NC}"
        else
            echo -e "${YELLOW}User does not have an SSH key${NC}"
        fi
    else
        echo -e "${YELLOW}No authorized keys file found${NC}"
    fi
}

# Function to list users with Git access
list_git_users() {
    echo -e "${BLUE}Users with Git Access:${NC}"
    if [ -f "$SSH_DIR/authorized_keys" ]; then
        while IFS=: read -r username _ uid gid _ home _; do
            if [ "$uid" -ge 1000 ] && [ "$uid" -ne 65534 ]; then
                if [ -f "$home/.ssh/id_rsa.pub" ]; then
                    key=$(cat "$home/.ssh/id_rsa.pub")
                    if grep -q "$key" "$SSH_DIR/authorized_keys"; then
                        echo -e "${GREEN}$username${NC}"
                    fi
                fi
            fi
        done < /etc/passwd
    else
        echo -e "${YELLOW}No users with Git access found${NC}"
    fi
}

# Function to show help
show_help() {
    echo -e "${BLUE}User Management${NC}"
    echo
    echo "Usage: $0 [OPTION]"
    echo
    echo "Options:"
    echo "  -c, --create    Create new user"
    echo "  -d, --delete    Delete user"
    echo "  -l, --list      List users"
    echo "  -g, --git       Manage Git server access"
    echo "  -h, --help      Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --create     # Create new user"
    echo "  $0 --delete     # Delete user"
    echo "  $0 --list       # List users"
    echo "  $0 --git        # Manage Git server access"
}

# Main script logic
check_root

case "$1" in
    -c|--create)
        create_user
        ;;
    -d|--delete)
        delete_user
        ;;
    -l|--list)
        list_users
        ;;
    -g|--git)
        manage_git_access
        ;;
    -h|--help|"")
        show_help
        ;;
    *)
        echo -e "${RED}Invalid option: $1${NC}"
        show_help
        exit 1
        ;;
esac 