#!/bin/bash

# ISO to Docker Image Converter
# Part of Server Migration and Management Suite
# Author: Luis Pulido Diaz
# Version: 1.0.0

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run as root or with sudo privileges${NC}"
        exit 1
    fi
}

# Function to check required tools
check_requirements() {
    echo -e "${BLUE}Checking requirements...${NC}"
    
    local required_commands=("docker" "xorriso" "squashfs-tools" "debootstrap")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${RED}Required command not found: $cmd${NC}"
            echo -e "${YELLOW}Installing required packages...${NC}"
            apt-get update
            apt-get install -y docker.io xorriso squashfs-tools debootstrap
            break
        fi
    done
    
    echo -e "${GREEN}Requirements met${NC}"
}

# Function to extract ISO contents
extract_iso() {
    local iso_file="$1"
    local work_dir="$2"
    
    echo -e "${BLUE}Extracting ISO contents...${NC}"
    
    # Create working directory
    mkdir -p "$work_dir"
    
    # Mount ISO
    mount -o loop "$iso_file" /mnt
    
    # Copy contents
    cp -r /mnt/* "$work_dir/"
    
    # Unmount ISO
    umount /mnt
    
    echo -e "${GREEN}ISO contents extracted${NC}"
}

# Function to create Dockerfile
create_dockerfile() {
    local work_dir="$1"
    local distro_name="$2"
    
    echo -e "${BLUE}Creating Dockerfile...${NC}"
    
    cat > "$work_dir/Dockerfile" << EOF
FROM scratch
COPY . /
CMD ["/bin/bash"]
EOF
    
    echo -e "${GREEN}Dockerfile created${NC}"
}

# Function to build Docker image
build_docker_image() {
    local work_dir="$1"
    local distro_name="$2"
    local tag="$3"
    
    echo -e "${BLUE}Building Docker image...${NC}"
    
    # Build image
    docker build -t "$tag" "$work_dir"
    
    echo -e "${GREEN}Docker image built successfully${NC}"
    echo -e "Image tag: ${YELLOW}$tag${NC}"
}

# Main script
main() {
    # Check arguments
    if [ $# -lt 1 ]; then
        echo -e "${RED}Usage: $0 <iso_file> [docker_tag]${NC}"
        exit 1
    fi
    
    local iso_file="$1"
    local docker_tag="${2:-linux-distro:latest}"
    local work_dir="/tmp/iso_to_docker_work"
    
    # Check if ISO file exists
    if [ ! -f "$iso_file" ]; then
        echo -e "${RED}ISO file not found: $iso_file${NC}"
        exit 1
    fi
    
    # Check root privileges
    check_root
    
    # Check requirements
    check_requirements
    
    # Extract ISO
    extract_iso "$iso_file" "$work_dir"
    
    # Create Dockerfile
    create_dockerfile "$work_dir" "$(basename "$iso_file" .iso)"
    
    # Build Docker image
    build_docker_image "$work_dir" "$(basename "$iso_file" .iso)" "$docker_tag"
    
    # Cleanup
    echo -e "${BLUE}Cleaning up...${NC}"
    rm -rf "$work_dir"
    
    echo -e "${GREEN}Process completed successfully${NC}"
    echo -e "You can now use the Docker image with: ${YELLOW}docker run -it $docker_tag${NC}"
}

# Run main function
main "$@" 