# Server Migration and Management Suite

A comprehensive suite of tools for managing Linux servers, containers, and system migrations.

## Features

### Container Management
- Manage multiple Docker applications
- Initialize application structures
- Start, stop, and restart services
- Update and monitor applications
- Backup and restore functionality
- Kubernetes migration support
- Resource cleanup and optimization

### System Management
- Partition management
- System migration tools
- System information gathering
- Backup management
- User management
- Git server management

## Installation

1. Clone the repository:
```bash
git clone https://github.com/lpolish/managelinux.git
cd managelinux
```

2. Make scripts executable:
```bash
chmod +x *.sh
```

3. Run the suite:
```bash
sudo ./run.sh
```

## Usage

### Container Management

The container manager (`container_manager.sh`) provides comprehensive Docker application management:

```bash
# Initialize a new application
./container_manager.sh init myapp

# List all applications
./container_manager.sh list

# Start an application
./container_manager.sh start myapp

# Stop an application
./container_manager.sh stop myapp

# Show application status
./container_manager.sh status myapp

# Backup an application
./container_manager.sh backup myapp

# Restore an application
./container_manager.sh restore myapp 2024-03-20

# Generate Kubernetes manifests
./container_manager.sh migrate myapp
```

### Application Structure

Each application is organized in the following structure:
```
applications/
└── myapp/
    ├── docker-compose.yml
    ├── metadata.json
    ├── config/
    ├── logs/
    ├── backups/
    └── kubernetes-manifests/
```

### Main Menu

The main menu (`run.sh`) provides access to all suite components:

1. Partition Management
2. System Migration
3. System Information
4. Backup Management
5. Container Management
6. Git Server Management
7. User Management
8. Exit

## Requirements

- Linux operating system
- Docker and Docker Compose
- Root privileges (for most operations)
- Basic system utilities (tar, curl, etc.)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, please open an issue in the GitHub repository.
