#!/bin/bash

# Git Server Management Script
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

# Function to install Git server
install_git_server() {
    echo -e "${BLUE}Installing Git server...${NC}"
    
    # Install Git if not already installed
    if ! command -v git &> /dev/null; then
        apt-get update
        apt-get install -y git
    fi
    
    # Create git user if it doesn't exist
    if ! id "$GIT_USER" &>/dev/null; then
        useradd -m -s /usr/bin/git-shell "$GIT_USER"
        echo -e "${GREEN}Created git user${NC}"
    fi
    
    # Create necessary directories
    mkdir -p "$GIT_REPO_DIR"
    mkdir -p "$SSH_DIR"
    
    # Set proper permissions
    chown -R "$GIT_USER:$GIT_USER" "$GIT_HOME"
    chmod 700 "$SSH_DIR"
    
    # Create authorized_keys file
    touch "$SSH_DIR/authorized_keys"
    chmod 600 "$SSH_DIR/authorized_keys"
    chown "$GIT_USER:$GIT_USER" "$SSH_DIR/authorized_keys"
    
    echo -e "${GREEN}Git server installation completed${NC}"
}

# Function to add SSH key
add_ssh_key() {
    echo -e "${BLUE}Adding SSH key...${NC}"
    read -p "Enter the public SSH key: " ssh_key
    
    if [ -z "$ssh_key" ]; then
        echo -e "${RED}No SSH key provided${NC}"
        return 1
    fi
    
    echo "$ssh_key" >> "$SSH_DIR/authorized_keys"
    chown "$GIT_USER:$GIT_USER" "$SSH_DIR/authorized_keys"
    echo -e "${GREEN}SSH key added successfully${NC}"
}

# Function to create new repository
create_repository() {
    echo -e "${BLUE}Creating new repository...${NC}"
    read -p "Enter repository name: " repo_name
    
    if [ -z "$repo_name" ]; then
        echo -e "${RED}Repository name cannot be empty${NC}"
        return 1
    fi
    
    repo_path="$GIT_REPO_DIR/$repo_name.git"
    
    if [ -d "$repo_path" ]; then
        echo -e "${RED}Repository already exists${NC}"
        return 1
    fi
    
    # Create bare repository
    sudo -u "$GIT_USER" git init --bare "$repo_path"
    
    echo -e "${GREEN}Repository created successfully${NC}"
    echo -e "Clone URL: ${YELLOW}git@$(hostname):$repo_path${NC}"
}

# Function to list repositories
list_repositories() {
    echo -e "${BLUE}Available repositories:${NC}"
    if [ -d "$GIT_REPO_DIR" ]; then
        ls -1 "$GIT_REPO_DIR"
    else
        echo -e "${YELLOW}No repositories found${NC}"
    fi
}

# Function to show Git server status
show_status() {
    echo -e "${BLUE}Git Server Status:${NC}"
    
    # Check if Git is installed
    if command -v git &> /dev/null; then
        echo -e "Git version: ${GREEN}$(git --version)${NC}"
    else
        echo -e "Git: ${RED}Not installed${NC}"
    fi
    
    # Check if git user exists
    if id "$GIT_USER" &>/dev/null; then
        echo -e "Git user: ${GREEN}Exists${NC}"
    else
        echo -e "Git user: ${RED}Not found${NC}"
    fi
    
    # Check repository directory
    if [ -d "$GIT_REPO_DIR" ]; then
        repo_count=$(ls -1 "$GIT_REPO_DIR" 2>/dev/null | wc -l)
        echo -e "Repositories: ${GREEN}$repo_count${NC}"
    else
        echo -e "Repository directory: ${RED}Not found${NC}"
    fi
}

# Function to show help
show_help() {
    echo -e "${BLUE}Git Server Management${NC}"
    echo
    echo "Usage: $0 [OPTION]"
    echo
    echo "Options:"
    echo "  -i, --install    Install Git server"
    echo "  -a, --add-key    Add SSH key"
    echo "  -c, --create     Create new repository"
    echo "  -l, --list       List repositories"
    echo "  -s, --status     Show Git server status"
    echo "  -h, --help       Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --install     # Install Git server"
    echo "  $0 --add-key     # Add SSH key"
    echo "  $0 --create      # Create new repository"
    echo "  $0 --list        # List repositories"
    echo "  $0 --status      # Show Git server status"
}

# Main script logic
check_root

case "$1" in
    -i|--install)
        install_git_server
        ;;
    -a|--add-key)
        add_ssh_key
        ;;
    -c|--create)
        create_repository
        ;;
    -l|--list)
        list_repositories
        ;;
    -s|--status)
        show_status
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