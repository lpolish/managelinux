#!/bin/bash

# Container Manager Script
# Part of the Server Migration and Management Suite
# Handles Docker containers, Docker Compose services, and Kubernetes migration preparation

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default configuration
APPS_DIR="applications"
DEFAULT_APP="default"
K8S_MANIFESTS_VERSION="v1.0.0"
CONTAINER_BACKUP_DIR="container-backups"
CONTAINER_LOGS_DIR="container-logs"
CONTAINER_CONFIG_DIR="container-config"

# Function to check if Docker is installed
check_docker() {
    echo -e "${BLUE}Checking Docker installation...${NC}"
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker is not installed.${NC}"
        echo -e "${YELLOW}Please install Docker using:${NC}"
        echo "curl -fsSL https://get.docker.com -o get-docker.sh"
        echo "sudo sh get-docker.sh"
        return 1
    fi
    echo -e "${GREEN}Docker is installed${NC}"
    return 0
}

# Function to check if Docker Compose is installed
check_docker_compose() {
    echo -e "${BLUE}Checking Docker Compose installation...${NC}"
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}Docker Compose is not installed.${NC}"
        echo -e "${YELLOW}Please install Docker Compose using:${NC}"
        echo "sudo apt-get update && sudo apt-get install -y docker-compose-plugin"
        return 1
    fi
    echo -e "${GREEN}Docker Compose is installed${NC}"
    return 0
}

# Function to check if kompose is installed
check_kompose() {
    echo -e "${BLUE}Checking kompose installation...${NC}"
    if ! command -v kompose &> /dev/null; then
        echo -e "${YELLOW}kompose is not installed.${NC}"
        echo -e "To install kompose, run:"
        echo "curl -L https://github.com/kubernetes/kompose/releases/download/v1.26.0/kompose-linux-amd64 -o kompose"
        echo "chmod +x kompose"
        echo "sudo mv kompose /usr/local/bin/"
        return 1
    fi
    echo -e "${GREEN}kompose is installed${NC}"
    return 0
}

# Function to initialize application structure
init_app_structure() {
    local app_name="$1"
    local app_dir="$APPS_DIR/$app_name"
    
    echo -e "${BLUE}Initializing application structure for '$app_name'...${NC}"
    
    # Create application directory structure
    mkdir -p "$app_dir"
    mkdir -p "$app_dir/kubernetes-manifests"
    mkdir -p "$app_dir/config"
    mkdir -p "$app_dir/logs"
    mkdir -p "$app_dir/backups"
    
    # Create default docker-compose.yml if it doesn't exist
    if [ ! -f "$app_dir/docker-compose.yml" ]; then
        cat > "$app_dir/docker-compose.yml" << EOF
version: '3.8'

services:
  app:
    image: nginx:latest
    ports:
      - "8080:80"
    volumes:
      - ./config:/etc/nginx/conf.d
      - ./logs:/var/log/nginx
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF
        echo -e "${GREEN}Created default docker-compose.yml for '$app_name'${NC}"
    fi
    
    # Create application metadata
    cat > "$app_dir/metadata.json" << EOF
{
    "name": "$app_name",
    "version": "1.0.0",
    "created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "last_updated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "status": "initialized",
    "containers": [],
    "volumes": [],
    "networks": []
}
EOF
    
    echo -e "${GREEN}Application structure initialized for '$app_name'${NC}"
    return 0
}

# Function to list applications
list_applications() {
    echo -e "${BLUE}Available applications:${NC}"
    
    if [ ! -d "$APPS_DIR" ]; then
        echo -e "${YELLOW}No applications found. Use 'init' to create your first application.${NC}"
        return 1
    fi
    
    for app_dir in "$APPS_DIR"/*/; do
        if [ -d "$app_dir" ]; then
            local app_name=$(basename "$app_dir")
            local status="unknown"
            local containers=0
            local volumes=0
            local networks=0
            
            if [ -f "$app_dir/metadata.json" ]; then
                status=$(jq -r '.status' "$app_dir/metadata.json" 2>/dev/null || echo "unknown")
                containers=$(jq -r '.containers | length' "$app_dir/metadata.json" 2>/dev/null || echo "0")
                volumes=$(jq -r '.volumes | length' "$app_dir/metadata.json" 2>/dev/null || echo "0")
                networks=$(jq -r '.networks | length' "$app_dir/metadata.json" 2>/dev/null || echo "0")
            fi
            
            echo -e "${GREEN}$app_name${NC} - Status: $status"
            echo "  Containers: $containers"
            echo "  Volumes: $volumes"
            echo "  Networks: $networks"
        fi
    done
    
    return 0
}

# Function to get application directory
get_app_dir() {
    local app_name="$1"
    if [ -z "$app_name" ]; then
        app_name="$DEFAULT_APP"
    fi
    
    local app_dir="$APPS_DIR/$app_name"
    if [ ! -d "$app_dir" ]; then
        echo -e "${RED}Application '$app_name' not found${NC}"
        return 1
    fi
    
    echo "$app_dir"
    return 0
}

# Function to start services
start_services() {
    local app_name="$1"
    local app_dir
    
    app_dir=$(get_app_dir "$app_name")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo -e "${BLUE}Starting Docker Compose services for '$app_name'...${NC}"
    
    if ! docker-compose -f "$app_dir/docker-compose.yml" up -d; then
        echo -e "${RED}Failed to start services${NC}"
        return 1
    fi
    
    # Update metadata with container information
    local containers=$(docker-compose -f "$app_dir/docker-compose.yml" ps -q)
    local volumes=$(docker-compose -f "$app_dir/docker-compose.yml" config --volumes)
    local networks=$(docker-compose -f "$app_dir/docker-compose.yml" config --networks)
    
    jq --arg status "running" \
       --arg updated "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       --arg containers "$containers" \
       --arg volumes "$volumes" \
       --arg networks "$networks" \
       '.status = $status | 
        .last_updated = $updated |
        .containers = ($containers | split("\n")) |
        .volumes = ($volumes | split("\n")) |
        .networks = ($networks | split("\n"))' \
       "$app_dir/metadata.json" > "$app_dir/metadata.json.tmp" && \
       mv "$app_dir/metadata.json.tmp" "$app_dir/metadata.json"
    
    echo -e "${GREEN}Services started successfully${NC}"
    return 0
}

# Function to stop services
stop_services() {
    local app_name="$1"
    local app_dir
    
    app_dir=$(get_app_dir "$app_name")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo -e "${BLUE}Stopping Docker Compose services for '$app_name'...${NC}"
    
    if ! docker-compose -f "$app_dir/docker-compose.yml" down; then
        echo -e "${RED}Failed to stop services${NC}"
        return 1
    fi
    
    # Update metadata
    jq --arg status "stopped" \
       --arg updated "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.status = $status | 
        .last_updated = $updated |
        .containers = [] |
        .volumes = [] |
        .networks = []' \
       "$app_dir/metadata.json" > "$app_dir/metadata.json.tmp" && \
       mv "$app_dir/metadata.json.tmp" "$app_dir/metadata.json"
    
    echo -e "${GREEN}Services stopped successfully${NC}"
    return 0
}

# Function to restart services
restart_services() {
    local app_name="$1"
    
    if ! stop_services "$app_name"; then
        return 1
    fi
    
    if ! start_services "$app_name"; then
        return 1
    fi
    
    echo -e "${GREEN}Services restarted successfully${NC}"
    return 0
}

# Function to update services
update_services() {
    local app_name="$1"
    local app_dir
    
    app_dir=$(get_app_dir "$app_name")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo -e "${BLUE}Updating Docker Compose services for '$app_name'...${NC}"
    
    # Backup current configuration
    local backup_dir="$app_dir/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    cp "$app_dir/docker-compose.yml" "$backup_dir/"
    cp "$app_dir/metadata.json" "$backup_dir/"
    
    if ! docker-compose -f "$app_dir/docker-compose.yml" pull; then
        echo -e "${RED}Failed to pull latest images${NC}"
        return 1
    fi
    
    if ! docker-compose -f "$app_dir/docker-compose.yml" up -d; then
        echo -e "${RED}Failed to update services${NC}"
        echo -e "${YELLOW}Restoring from backup...${NC}"
        cp "$backup_dir/docker-compose.yml" "$app_dir/"
        cp "$backup_dir/metadata.json" "$app_dir/"
        return 1
    fi
    
    # Update metadata
    local containers=$(docker-compose -f "$app_dir/docker-compose.yml" ps -q)
    local volumes=$(docker-compose -f "$app_dir/docker-compose.yml" config --volumes)
    local networks=$(docker-compose -f "$app_dir/docker-compose.yml" config --networks)
    
    jq --arg status "running" \
       --arg updated "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       --arg containers "$containers" \
       --arg volumes "$volumes" \
       --arg networks "$networks" \
       '.status = $status | 
        .last_updated = $updated |
        .containers = ($containers | split("\n")) |
        .volumes = ($volumes | split("\n")) |
        .networks = ($networks | split("\n"))' \
       "$app_dir/metadata.json" > "$app_dir/metadata.json.tmp" && \
       mv "$app_dir/metadata.json.tmp" "$app_dir/metadata.json"
    
    echo -e "${GREEN}Services updated successfully${NC}"
    return 0
}

# Function to clean up unused resources
cleanup_resources() {
    local app_name="$1"
    local app_dir
    
    if [ -n "$app_name" ]; then
        app_dir=$(get_app_dir "$app_name")
        if [ $? -ne 0 ]; then
            return 1
        fi
    fi
    
    echo -e "${BLUE}Cleaning up unused Docker resources...${NC}"
    
    # Remove stopped containers
    if ! docker container prune -f; then
        echo -e "${YELLOW}Warning: Failed to remove stopped containers${NC}"
    fi
    
    # Remove unused volumes
    if ! docker volume prune -f; then
        echo -e "${YELLOW}Warning: Failed to remove unused volumes${NC}"
    fi
    
    # Remove unused networks
    if ! docker network prune -f; then
        echo -e "${YELLOW}Warning: Failed to remove unused networks${NC}"
    fi
    
    # Remove unused images
    if ! docker image prune -f; then
        echo -e "${YELLOW}Warning: Failed to remove unused images${NC}"
    fi
    
    echo -e "${GREEN}Cleanup completed${NC}"
    return 0
}

# Function to generate Kubernetes manifests
generate_k8s_manifests() {
    local app_name="$1"
    local app_dir
    
    app_dir=$(get_app_dir "$app_name")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo -e "${BLUE}Generating Kubernetes manifests for '$app_name'...${NC}"
    
    if ! check_kompose; then
        return 1
    fi
    
    local k8s_dir="$app_dir/kubernetes-manifests"
    
    # Generate manifests using kompose
    if ! kompose convert -f "$app_dir/docker-compose.yml" -o "$k8s_dir"; then
        echo -e "${RED}Failed to generate Kubernetes manifests${NC}"
        return 1
    fi
    
    # Add version information
    echo "version: $K8S_MANIFESTS_VERSION" > "$k8s_dir/version.txt"
    echo "generated: $(date)" >> "$k8s_dir/version.txt"
    echo "application: $app_name" >> "$k8s_dir/version.txt"
    
    # Add application metadata to manifests
    jq --arg app "$app_name" \
       --arg version "$K8S_MANIFESTS_VERSION" \
       --arg generated "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.metadata.labels.app = $app |
        .metadata.labels.version = $version |
        .metadata.annotations.generated = $generated' \
       "$k8s_dir/*.yaml" > "$k8s_dir/manifests.yaml"
    
    echo -e "${GREEN}Kubernetes manifests generated successfully in $k8s_dir${NC}"
    echo -e "${YELLOW}To apply these manifests to a Kubernetes cluster:${NC}"
    echo "1. Ensure kubectl is configured with your cluster"
    echo "2. Run: kubectl apply -f $k8s_dir/"
    return 0
}

# Function to show service status
show_status() {
    local app_name="$1"
    local app_dir
    
    if [ -z "$app_name" ]; then
        echo -e "${BLUE}All applications status:${NC}"
        list_applications
        return 0
    fi
    
    app_dir=$(get_app_dir "$app_name")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo -e "${BLUE}Docker Compose services status for '$app_name':${NC}"
    
    if ! docker-compose -f "$app_dir/docker-compose.yml" ps; then
        echo -e "${RED}Failed to get service status${NC}"
        return 1
    fi
    
    # Show container logs
    echo -e "\n${BLUE}Recent container logs:${NC}"
    docker-compose -f "$app_dir/docker-compose.yml" logs --tail=10
    
    # Show resource usage
    echo -e "\n${BLUE}Container resource usage:${NC}"
    docker stats --no-stream $(docker-compose -f "$app_dir/docker-compose.yml" ps -q)
    
    return 0
}

# Function to backup application
backup_application() {
    local app_name="$1"
    local app_dir
    
    app_dir=$(get_app_dir "$app_name")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo -e "${BLUE}Backing up application '$app_name'...${NC}"
    
    local backup_dir="$app_dir/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup docker-compose.yml
    cp "$app_dir/docker-compose.yml" "$backup_dir/"
    
    # Backup metadata
    cp "$app_dir/metadata.json" "$backup_dir/"
    
    # Backup volumes
    local volumes=$(docker-compose -f "$app_dir/docker-compose.yml" config --volumes)
    for volume in $volumes; do
        if docker volume inspect "$volume" >/dev/null 2>&1; then
            docker run --rm -v "$volume:/source" -v "$backup_dir:/backup" alpine tar czf "/backup/$volume.tar.gz" -C /source .
        fi
    done
    
    echo -e "${GREEN}Backup completed successfully in $backup_dir${NC}"
    return 0
}

# Function to restore application
restore_application() {
    local app_name="$1"
    local backup_date="$2"
    local app_dir
    
    app_dir=$(get_app_dir "$app_name")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    if [ -z "$backup_date" ]; then
        echo -e "${RED}Error: Backup date required${NC}"
        return 1
    fi
    
    local backup_dir="$app_dir/backups/$backup_date"
    if [ ! -d "$backup_dir" ]; then
        echo -e "${RED}Error: Backup not found${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Restoring application '$app_name' from backup...${NC}"
    
    # Stop services
    if ! stop_services "$app_name"; then
        return 1
    fi
    
    # Restore docker-compose.yml
    cp "$backup_dir/docker-compose.yml" "$app_dir/"
    
    # Restore metadata
    cp "$backup_dir/metadata.json" "$app_dir/"
    
    # Restore volumes
    for volume_backup in "$backup_dir"/*.tar.gz; do
        if [ -f "$volume_backup" ]; then
            local volume_name=$(basename "$volume_backup" .tar.gz)
            if docker volume inspect "$volume_name" >/dev/null 2>&1; then
                docker run --rm -v "$volume_name:/target" -v "$backup_dir:/backup" alpine sh -c "rm -rf /target/* && tar xzf /backup/$volume_name.tar.gz -C /target"
            fi
        fi
    done
    
    # Start services
    if ! start_services "$app_name"; then
        return 1
    fi
    
    echo -e "${GREEN}Restore completed successfully${NC}"
    return 0
}

# Function to show help
show_help() {
    echo -e "${BLUE}Container Manager - Usage:${NC}"
    echo "Usage: $0 [OPTION] [APP_NAME] [BACKUP_DATE]"
    echo
    echo "Options:"
    echo "  init [APP_NAME]    Initialize new application structure"
    echo "  list              List all applications"
    echo "  start [APP_NAME]  Start Docker Compose services"
    echo "  stop [APP_NAME]   Stop Docker Compose services"
    echo "  restart [APP_NAME] Restart Docker Compose services"
    echo "  update [APP_NAME] Update Docker Compose services"
    echo "  status [APP_NAME] Show service status"
    echo "  cleanup [APP_NAME] Clean up unused Docker resources"
    echo "  migrate [APP_NAME] Generate Kubernetes manifests"
    echo "  backup [APP_NAME] Backup application"
    echo "  restore [APP_NAME] [BACKUP_DATE] Restore application from backup"
    echo "  help              Show this help message"
    echo
    echo "If APP_NAME is not specified, the default application will be used."
    echo "Applications are stored in the '$APPS_DIR' directory."
    echo
    echo "For more information about Kubernetes migration, see the README.md file."
}

# Main script execution
main() {
    # Check if Docker is installed
    if ! check_docker; then
        exit 1
    fi
    
    # Check if Docker Compose is installed
    if ! check_docker_compose; then
        exit 1
    fi
    
    # Create applications directory if it doesn't exist
    mkdir -p "$APPS_DIR"
    
    # Handle command line arguments
    case "$1" in
        init)
            if [ -z "$2" ]; then
                echo -e "${RED}Error: Application name required${NC}"
                show_help
                exit 1
            fi
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
            if [ -z "$2" ] || [ -z "$3" ]; then
                echo -e "${RED}Error: Application name and backup date required${NC}"
                show_help
                exit 1
            fi
            restore_application "$2" "$3"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}Error: Unknown option '$1'${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Execute main function
main "$@" 