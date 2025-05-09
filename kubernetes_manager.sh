#!/bin/bash

# Kubernetes Manager Script
# Part of the Server Migration and Management Suite
# Handles Kubernetes installation and management for single-node and multi-node clusters

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check system requirements
check_requirements() {
    echo -e "${BLUE}Checking system requirements...${NC}"
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run as root or with sudo privileges${NC}"
        return 1
    fi
    
    # Check if running on a supported OS
    if ! command -v lsb_release >/dev/null 2>&1; then
        echo -e "${RED}lsb_release command not found. Please install lsb-release package.${NC}"
        return 1
    fi
    
    local os_name=$(lsb_release -si)
    local os_version=$(lsb_release -sr)
    
    if [[ "$os_name" != "Ubuntu" && "$os_name" != "Debian" ]]; then
        echo -e "${RED}Unsupported operating system: $os_name. Only Ubuntu and Debian are supported.${NC}"
        return 1
    fi
    
    # Check memory
    local total_mem=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$total_mem" -lt 2000 ]; then
        echo -e "${RED}Insufficient memory. Minimum 2GB required.${NC}"
        return 1
    fi
    
    # Check CPU
    local cpu_cores=$(nproc)
    if [ "$cpu_cores" -lt 2 ]; then
        echo -e "${RED}Insufficient CPU cores. Minimum 2 cores required.${NC}"
        return 1
    fi
    
    # Check swap
    local swap_size=$(free -m | awk '/^Swap:/{print $2}')
    if [ "$swap_size" -lt 1000 ]; then
        echo -e "${YELLOW}Warning: Less than 1GB swap space detected. It's recommended to have at least 1GB of swap space.${NC}"
        read -p "Do you want to continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # Check disk space
    local free_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$free_space" -lt 10 ]; then
        echo -e "${RED}Insufficient disk space. Minimum 10GB free space required.${NC}"
        return 1
    fi
    
    # Check if system is running in a virtual environment
    if [ -f "/.dockerenv" ]; then
        echo -e "${RED}Running in a Docker container is not supported.${NC}"
        return 1
    fi
    
    # Check if system is running in a VM
    if [ -f "/sys/class/dmi/id/product_name" ]; then
        local product_name=$(cat /sys/class/dmi/id/product_name)
        if [[ "$product_name" == *"VMware"* || "$product_name" == *"VirtualBox"* ]]; then
            echo -e "${YELLOW}Warning: Running in a virtual machine. Some features might be limited.${NC}"
        fi
    fi
    
    echo -e "${GREEN}System requirements met${NC}"
    return 0
}

# Function to install prerequisites
install_prerequisites() {
    echo -e "${BLUE}Installing prerequisites...${NC}"
    
    # Update package lists
    if ! apt-get update; then
        echo -e "${RED}Failed to update package lists${NC}"
        return 1
    fi
    
    # Install required packages
    if ! apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release; then
        echo -e "${RED}Failed to install required packages${NC}"
        return 1
    fi
    
    # Add Docker's official GPG key
    if ! curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg; then
        echo -e "${RED}Failed to add Docker's GPG key${NC}"
        return 1
    fi
    
    # Add Docker repository
    if ! echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null; then
        echo -e "${RED}Failed to add Docker repository${NC}"
        return 1
    fi
    
    # Update package lists again
    if ! apt-get update; then
        echo -e "${RED}Failed to update package lists after adding Docker repository${NC}"
        return 1
    fi
    
    # Install Docker
    if ! apt-get install -y docker-ce docker-ce-cli containerd.io; then
        echo -e "${RED}Failed to install Docker${NC}"
        return 1
    fi
    
    # Start and enable Docker
    if ! systemctl start docker; then
        echo -e "${RED}Failed to start Docker service${NC}"
        return 1
    fi
    
    if ! systemctl enable docker; then
        echo -e "${RED}Failed to enable Docker service${NC}"
        return 1
    fi
    
    # Add current user to docker group
    if ! usermod -aG docker $SUDO_USER; then
        echo -e "${RED}Failed to add user to docker group${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Prerequisites installed successfully${NC}"
    return 0
}

# Function to install kubeadm, kubelet, and kubectl
install_kubernetes_components() {
    echo -e "${BLUE}Installing Kubernetes components...${NC}"
    
    # Add Kubernetes GPG key
    if ! curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /usr/share/keyrings/kubernetes-apt-keyring.gpg; then
        echo -e "${RED}Failed to add Kubernetes GPG key${NC}"
        return 1
    fi
    
    # Add Kubernetes repository
    if ! echo "deb [signed-by=/usr/share/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list > /dev/null; then
        echo -e "${RED}Failed to add Kubernetes repository${NC}"
        return 1
    fi
    
    # Update package lists
    if ! apt-get update; then
        echo -e "${RED}Failed to update package lists after adding Kubernetes repository${NC}"
        return 1
    fi
    
    # Install Kubernetes components
    if ! apt-get install -y kubelet kubeadm kubectl; then
        echo -e "${RED}Failed to install Kubernetes components${NC}"
        return 1
    fi
    
    # Hold the versions to prevent automatic updates
    if ! apt-mark hold kubelet kubeadm kubectl; then
        echo -e "${YELLOW}Warning: Failed to hold Kubernetes package versions${NC}"
    fi
    
    echo -e "${GREEN}Kubernetes components installed successfully${NC}"
    return 0
}

# Function to initialize Kubernetes cluster
initialize_cluster() {
    echo -e "${BLUE}Initializing Kubernetes cluster...${NC}"
    
    # Initialize kubeadm
    if ! kubeadm init --pod-network-cidr=10.244.0.0/16; then
        echo -e "${RED}Failed to initialize Kubernetes cluster${NC}"
        return 1
    fi
    
    # Create .kube directory for current user
    if ! mkdir -p /home/$SUDO_USER/.kube; then
        echo -e "${RED}Failed to create .kube directory${NC}"
        return 1
    fi
    
    if ! cp -i /etc/kubernetes/admin.conf /home/$SUDO_USER/.kube/config; then
        echo -e "${RED}Failed to copy Kubernetes config${NC}"
        return 1
    fi
    
    if ! chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.kube; then
        echo -e "${RED}Failed to set ownership of .kube directory${NC}"
        return 1
    fi
    
    # Install Calico network plugin
    if ! kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml; then
        echo -e "${RED}Failed to install Calico network plugin${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Kubernetes cluster initialized successfully${NC}"
    echo -e "${YELLOW}Important:${NC} To start using your cluster, you need to run the following commands:"
    echo "  mkdir -p $HOME/.kube"
    echo "  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config"
    echo "  sudo chown $(id -u):$(id -g) $HOME/.kube/config"
    echo -e "${YELLOW}To join worker nodes, use the command shown above${NC}"
    return 0
}

# Function to join worker node
join_worker_node() {
    echo -e "${BLUE}Joining worker node...${NC}"
    
    if [ -z "$1" ]; then
        echo -e "${RED}Please provide the join command from the master node${NC}"
        return 1
    fi
    
    # Execute the join command
    eval "$1"
    
    echo -e "${GREEN}Worker node joined successfully${NC}"
}

# Function to show cluster status
show_cluster_status() {
    echo -e "${BLUE}Cluster Status:${NC}"
    kubectl get nodes
    echo -e "\n${BLUE}Pods Status:${NC}"
    kubectl get pods --all-namespaces
}

# Handle command line arguments
if [ "$#" -gt 0 ]; then
    case "$1" in
        "install")
            if check_requirements && install_prerequisites && install_kubernetes_components && initialize_cluster; then
                echo -e "${GREEN}Kubernetes installation completed successfully${NC}"
                exit 0
            else
                echo -e "${RED}Kubernetes installation failed${NC}"
                exit 1
            fi
            ;;
        "join")
            if [ -z "$2" ]; then
                echo -e "${RED}Error: Join command is required${NC}"
                exit 1
            fi
            if join_worker_node "$2"; then
                echo -e "${GREEN}Worker node joined successfully${NC}"
                exit 0
            else
                echo -e "${RED}Failed to join worker node${NC}"
                exit 1
            fi
            ;;
        "status")
            show_cluster_status
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid command: $1${NC}"
            echo "Usage: $0 [install|join <command>|status]"
            exit 1
            ;;
    esac
fi

# Main menu
show_menu() {
    while true; do
        echo -e "\n${BLUE}Kubernetes Manager${NC}"
        echo "1. Install Kubernetes (Master Node)"
        echo "2. Join Worker Node"
        echo "3. Show Cluster Status"
        echo "4. Exit"
        
        read -p "Select an option: " choice
        
        case $choice in
            1)
                if check_requirements && install_prerequisites && install_kubernetes_components && initialize_cluster; then
                    echo -e "${GREEN}Kubernetes installation completed successfully${NC}"
                else
                    echo -e "${RED}Kubernetes installation failed${NC}"
                fi
                read -p "Press Enter to continue..."
                ;;
            2)
                read -p "Enter the join command from the master node: " join_cmd
                if join_worker_node "$join_cmd"; then
                    echo -e "${GREEN}Worker node joined successfully${NC}"
                else
                    echo -e "${RED}Failed to join worker node${NC}"
                fi
                read -p "Press Enter to continue..."
                ;;
            3)
                show_cluster_status
                read -p "Press Enter to continue..."
                ;;
            4)
                echo -e "${GREEN}Exiting...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Run the menu
show_menu 