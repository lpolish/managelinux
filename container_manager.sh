#!/bin/bash

# Container Manager Script
# Part of Server Migration and Management Suite
# Repo: https://github.com/lpolish/managelinux
# Version: 1.0.0

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration
APPS_DIR="applications"
DEFAULT_APP="default"
CONTAINER_BACKUP_DIR="backups"
CONTAINER_LOGS_DIR="logs"
CONTAINER_CONFIG_DIR="config"
K8S_MANIFESTS_DIR="kubernetes-manifests"
K8S_MANIFESTS_VERSION="v1.0.0"

# Function to check Docker installation
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker is not installed.${NC}"
        echo -e "Please install Docker using:"
        echo -e "curl -fsSL https://get.docker.com -o get-docker.sh"
        echo -e "sudo sh get-docker.sh"
        exit 1
    fi
}

# Function to check Docker Compose installation
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}Docker Compose is not installed.${NC}"
        echo -e "Please install Docker Compose using:"
        echo -e "sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
        echo -e "sudo chmod +x /usr/local/bin/docker-compose"
        exit 1
    fi
}

# Function to check kompose installation
check_kompose() {
    if ! command -v kompose &> /dev/null; then
        echo -e "${YELLOW}kompose is not installed.${NC}"
        echo -e "Please install kompose using:"
        echo -e "curl -L https://github.com/kubernetes/kompose/releases/latest/download/kompose-linux-amd64 -o kompose"
        echo -e "chmod +x kompose"
        echo -e "sudo mv kompose /usr/local/bin/"
        return 1
    fi
    return 0
}

# Function to initialize application structure
init_app_structure() {
    local app_name=${1:-$DEFAULT_APP}
    local app_dir="$APPS_DIR/$app_name"
    
    # Create directory structure
    mkdir -p "$app_dir"/{config,logs,backups,kubernetes-manifests}
    
    # Create default docker-compose.yml
    cat > "$app_dir/docker-compose.yml" << EOF
version: '3.8'

services:
  app:
    image: nginx:latest
    container_name: ${app_name}_app
    ports:
      - "80:80"
    volumes:
      - ./config:/etc/nginx/conf.d
      - ./logs:/var/log/nginx
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped
EOF

    # Create metadata.json
    cat > "$app_dir/metadata.json" << EOF
{
    "name": "$app_name",
    "version": "1.0.0",
    "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "status": "initialized",
    "containers": [],
    "volumes": [],
    "networks": []
}
EOF

    echo -e "${GREEN}Application '$app_name' initialized successfully${NC}"
}

# Function to list applications
list_applications() {
    if [ ! -d "$APPS_DIR" ]; then
        echo -e "${YELLOW}No applications found.${NC}"
        return
    fi

    echo -e "${BLUE}=== Applications ===${NC}"
    for app_dir in "$APPS_DIR"/*/; do
        if [ -f "$app_dir/metadata.json" ]; then
            app_name=$(basename "$app_dir")
            status=$(jq -r '.status' "$app_dir/metadata.json")
            containers=$(jq -r '.containers | length' "$app_dir/metadata.json")
            volumes=$(jq -r '.volumes | length' "$app_dir/metadata.json")
            networks=$(jq -r '.networks | length' "$app_dir/metadata.json")
            
            echo -e "${YELLOW}$app_name${NC}"
            echo -e "  Status: $status"
            echo -e "  Containers: $containers"
            echo -e "  Volumes: $volumes"
            echo -e "  Networks: $networks"
            echo
        fi
    done
}

# Function to start services
start_services() {
    local app_name=${1:-$DEFAULT_APP}
    local app_dir="$APPS_DIR/$app_name"
    
    if [ ! -f "$app_dir/docker-compose.yml" ]; then
        echo -e "${RED}Application '$app_name' not found${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Starting services for '$app_name'...${NC}"
    cd "$app_dir" || return 1
    
    if docker-compose up -d; then
        # Update metadata
        containers=$(docker-compose ps -q | wc -l)
        volumes=$(docker-compose config --volumes | wc -l)
        networks=$(docker-compose config --networks | wc -l)
        
        jq --arg status "running" \
           --arg containers "$containers" \
           --arg volumes "$volumes" \
           --arg networks "$networks" \
           '.status = $status | 
            .containers = [$containers] | 
            .volumes = [$volumes] | 
            .networks = [$networks]' \
           metadata.json > metadata.json.tmp && mv metadata.json.tmp metadata.json
        
        echo -e "${GREEN}Services started successfully${NC}"
    else
        echo -e "${RED}Failed to start services${NC}"
        return 1
    fi
}

# Function to stop services
stop_services() {
    local app_name=${1:-$DEFAULT_APP}
    local app_dir="$APPS_DIR/$app_name"
    
    if [ ! -f "$app_dir/docker-compose.yml" ]; then
        echo -e "${RED}Application '$app_name' not found${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Stopping services for '$app_name'...${NC}"
    cd "$app_dir" || return 1
    
    if docker-compose down; then
        # Update metadata
        jq '.status = "stopped" | 
            .containers = [] | 
            .volumes = [] | 
            .networks = []' \
           metadata.json > metadata.json.tmp && mv metadata.json.tmp metadata.json
        
        echo -e "${GREEN}Services stopped successfully${NC}"
    else
        echo -e "${RED}Failed to stop services${NC}"
        return 1
    fi
}

# Function to restart services
restart_services() {
    local app_name=${1:-$DEFAULT_APP}
    stop_services "$app_name" && start_services "$app_name"
}

# Function to update services
update_services() {
    local app_name=${1:-$DEFAULT_APP}
    local app_dir="$APPS_DIR/$app_name"
    
    if [ ! -f "$app_dir/docker-compose.yml" ]; then
        echo -e "${RED}Application '$app_name' not found${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Updating services for '$app_name'...${NC}"
    cd "$app_dir" || return 1
    
    if docker-compose pull && docker-compose up -d; then
        echo -e "${GREEN}Services updated successfully${NC}"
    else
        echo -e "${RED}Failed to update services${NC}"
        return 1
    fi
}

# Function to cleanup resources
cleanup_resources() {
    local app_name=${1:-$DEFAULT_APP}
    local app_dir="$APPS_DIR/$app_name"
    
    if [ ! -f "$app_dir/docker-compose.yml" ]; then
        echo -e "${RED}Application '$app_name' not found${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Cleaning up resources for '$app_name'...${NC}"
    cd "$app_dir" || return 1
    
    # Stop services
    docker-compose down
    
    # Remove unused volumes
    docker volume prune -f
    
    # Remove unused networks
    docker network prune -f
    
    # Update metadata
    jq '.status = "cleaned" | 
        .containers = [] | 
        .volumes = [] | 
        .networks = []' \
       metadata.json > metadata.json.tmp && mv metadata.json.tmp metadata.json
    
    echo -e "${GREEN}Resources cleaned up successfully${NC}"
}

# Function to generate Kubernetes manifests
generate_k8s_manifests() {
    local app_name=${1:-$DEFAULT_APP}
    local app_dir="$APPS_DIR/$app_name"
    
    if [ ! -f "$app_dir/docker-compose.yml" ]; then
        echo -e "${RED}Application '$app_name' not found${NC}"
        return 1
    fi
    
    if ! check_kompose; then
        return 1
    fi
    
    echo -e "${BLUE}Generating Kubernetes manifests for '$app_name'...${NC}"
    cd "$app_dir" || return 1
    
    if kompose convert -f docker-compose.yml -o "$K8S_MANIFESTS_DIR"; then
        # Create version file
        cat > "$K8S_MANIFESTS_DIR/version" << EOF
version: $K8S_MANIFESTS_VERSION
generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
        
        echo -e "${GREEN}Kubernetes manifests generated successfully${NC}"
        echo -e "Manifests are available in: $app_dir/$K8S_MANIFESTS_DIR"
        echo -e "To apply these manifests to your Kubernetes cluster:"
        echo -e "kubectl apply -f $app_dir/$K8S_MANIFESTS_DIR"
    else
        echo -e "${RED}Failed to generate Kubernetes manifests${NC}"
        return 1
    fi
}

# Function to show status
show_status() {
    local app_name=${1:-$DEFAULT_APP}
    local app_dir="$APPS_DIR/$app_name"
    
    if [ ! -f "$app_dir/docker-compose.yml" ]; then
        echo -e "${RED}Application '$app_name' not found${NC}"
        return 1
    fi
    
    echo -e "${BLUE}=== Status for '$app_name' ===${NC}"
    cd "$app_dir" || return 1
    
    # Show container status
    echo -e "\n${YELLOW}Container Status:${NC}"
    docker-compose ps
    
    # Show recent logs
    echo -e "\n${YELLOW}Recent Logs:${NC}"
    docker-compose logs --tail=10
    
    # Show resource usage
    echo -e "\n${YELLOW}Resource Usage:${NC}"
    docker stats --no-stream
}

# Function to backup application
backup_application() {
    local app_name=${1:-$DEFAULT_APP}
    local app_dir="$APPS_DIR/$app_name"
    local backup_date=$(date +"%Y-%m-%d")
    local backup_dir="$app_dir/$CONTAINER_BACKUP_DIR/$backup_date"
    
    if [ ! -f "$app_dir/docker-compose.yml" ]; then
        echo -e "${RED}Application '$app_name' not found${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Backing up '$app_name'...${NC}"
    mkdir -p "$backup_dir"
    
    # Backup docker-compose.yml
    cp "$app_dir/docker-compose.yml" "$backup_dir/"
    
    # Backup config
    if [ -d "$app_dir/$CONTAINER_CONFIG_DIR" ]; then
        cp -r "$app_dir/$CONTAINER_CONFIG_DIR" "$backup_dir/"
    fi
    
    # Backup volumes
    cd "$app_dir" || return 1
    for volume in $(docker-compose config --volumes); do
        docker run --rm -v "$volume:/source" -v "$backup_dir:/backup" alpine tar czf "/backup/$volume.tar.gz" -C /source .
    done
    
    echo -e "${GREEN}Backup completed successfully${NC}"
    echo -e "Backup location: $backup_dir"
}

# Function to restore application
restore_application() {
    local app_name=${1:-$DEFAULT_APP}
    local backup_date=${2:-$(date +"%Y-%m-%d")}
    local app_dir="$APPS_DIR/$app_name"
    local backup_dir="$app_dir/$CONTAINER_BACKUP_DIR/$backup_date"
    
    if [ ! -d "$backup_dir" ]; then
        echo -e "${RED}Backup not found for date: $backup_date${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Restoring '$app_name' from backup...${NC}"
    
    # Stop services
    cd "$app_dir" || return 1
    docker-compose down
    
    # Restore docker-compose.yml
    cp "$backup_dir/docker-compose.yml" "$app_dir/"
    
    # Restore config
    if [ -d "$backup_dir/$CONTAINER_CONFIG_DIR" ]; then
        rm -rf "$app_dir/$CONTAINER_CONFIG_DIR"
        cp -r "$backup_dir/$CONTAINER_CONFIG_DIR" "$app_dir/"
    fi
    
    # Restore volumes
    for volume in $(docker-compose config --volumes); do
        if [ -f "$backup_dir/$volume.tar.gz" ]; then
            docker volume create "$volume"
            docker run --rm -v "$volume:/target" -v "$backup_dir:/backup" alpine sh -c "rm -rf /target/* && tar xzf /backup/$volume.tar.gz -C /target"
        fi
    done
    
    # Start services
    docker-compose up -d
    
    echo -e "${GREEN}Restore completed successfully${NC}"
}

# Function to show help
show_help() {
    echo -e "${BLUE}Container Manager - Help${NC}"
    echo
    echo "Usage: $0 [OPTION] [APP_NAME] [BACKUP_DATE]"
    echo
    echo "Options:"
    echo "  init [APP_NAME]     Initialize new application structure"
    echo "  list               List all applications"
    echo "  start [APP_NAME]   Start Docker Compose services"
    echo "  stop [APP_NAME]    Stop Docker Compose services"
    echo "  restart [APP_NAME] Restart Docker Compose services"
    echo "  update [APP_NAME]  Update Docker Compose services"
    echo "  status [APP_NAME]  Show service status"
    echo "  cleanup [APP_NAME] Clean up unused Docker resources"
    echo "  migrate [APP_NAME] Generate Kubernetes manifests"
    echo "  backup [APP_NAME]  Backup application"
    echo "  restore [APP_NAME] [BACKUP_DATE] Restore application from backup"
    echo "  help              Show this help message"
    echo
    echo "If APP_NAME is not provided, the default application will be used."
    echo "If BACKUP_DATE is not provided for restore, today's date will be used."
}

# Main script
check_docker
check_docker_compose

case "$1" in
    init)
        init_app_structure "$2"
        ;;
    list)
        list_applications
        ;;
    start)
        start_services "$2"
        ;;
    stop)
        stop_services "$2"
        ;;
    restart)
        restart_services "$2"
        ;;
    update)
        update_services "$2"
        ;;
    status)
        show_status "$2"
        ;;
    cleanup)
        cleanup_resources "$2"
        ;;
    migrate)
        generate_k8s_manifests "$2"
        ;;
    backup)
        backup_application "$2"
        ;;
    restore)
        restore_application "$2" "$3"
        ;;
    help|*)
        show_help
        ;;
esac 