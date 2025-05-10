# Server Migration and Management Suite (managelinux)

A comprehensive command-line suite for managing Debian-based Linux servers, with a focus on partition management and system migration capabilities.

## Features

- **Partition Management**
  - Create, resize, and format partitions
  - Support for various filesystem types (ext4, xfs, btrfs, ntfs)
  - Interactive disk selection and management
  - Safety checks and confirmations

- **System Migration**
  - Migrate to Ubuntu LTS (22.04)
  - Migrate to Debian Enterprise
  - Custom migration support
  - System requirements checking
  - Automatic backup before migration

- **System Information**
  - Comprehensive system overview
  - Package information and updates
  - Service status monitoring
  - Hardware details
  - System logs viewer
  - Migration report generation
  - Live USB creation for Ubuntu 22.04

- **Backup Management**
  - Create system backups
  - Restore from backups
  - Backup verification
  - Backup listing and management
  - Automatic manifest generation

- **ISO to Docker Conversion**
  - Convert Linux ISO images to Docker containers
  - Support for various Linux distributions
  - Automatic dependency installation
  - Custom Docker image tagging

- **Container Management**
  - Comprehensive Docker and Docker Compose management
  - Application-based organization and isolation
  - Automatic health checks and monitoring
  - Resource usage tracking and optimization
  - Backup and restore capabilities
  - Volume management and persistence
  - Network configuration and isolation
  - Kubernetes migration preparation
  - Application metadata and state tracking
  - Structured directory layout:
    ```
    applications/
    ├── app_name/
    │   ├── docker-compose.yml
    │   ├── metadata.json
    │   ├── config/
    │   ├── logs/
    │   ├── backups/
    │   └── kubernetes-manifests/
    └── ...
    ```

- **Git Server Management**
  - SSH-based Git server installation
  - Secure repository hosting
  - User and SSH key management
  - Repository creation and listing
  - Server status monitoring
  - Ready for Kubernetes deployment

- **User Management**
  - Create and delete system users
  - Manage user groups and permissions
  - Integrated Git server access control
  - SSH key management
  - User listing and status monitoring
  - Secure password handling

- **Samba Management**
  - Install and configure Samba server
  - Create and manage network shares
  - User authentication and access control
  - Share permissions management
  - Active connections monitoring
  - Secure configuration backup

- **SSH Management**
  - Install and configure SSH server
  - Manage SSH keys and authorized users
  - Configure security settings
  - Monitor active connections
  - Custom port configuration
  - Root login control
  - Password authentication control

## Requirements

### Linux Requirements
- Debian-based Linux distribution
- Root or sudo privileges
- Basic system utilities (fdisk, parted, tar, etc.)
- Minimum 4GB RAM
- 20GB free disk space for migrations
- Docker (for ISO to Docker conversion)

### Windows Requirements
- Windows 10 or later
- PowerShell 5.1 or later
- Administrator privileges
- Docker Desktop for Windows (for ISO to Docker conversion)
- 7-Zip (automatically installed if missing)

## Installation

### Linux Installation

#### Quick Start

1. One-line installation:
   ```bash
   curl https://raw.githubusercontent.com/lpolish/managelinux/refs/heads/main/install-oneline.sh | sudo bash
   ```

2. Or clone and install manually:
   ```bash
   git clone https://github.com/lpolish/managelinux.git
   cd managelinux
   chmod +x *.sh
   ./run.sh
   ```

#### Installation Options

The suite can be used in two ways:

1. **Direct Usage** (from the repository directory):
   ```bash
   ./run.sh              # Run the suite
   ./run.sh --status     # Check installation status
   ```

2. **System-wide Installation**:
   ```bash
   sudo ./run.sh --install    # Install the suite system-wide
   managelinux            # Run the installed suite
   managelinux --update   # Update to the latest version
   ```

#### Uninstallation

The suite can be uninstalled in two ways:

1. **One-line Uninstaller** (recommended):
   ```bash
   curl https://raw.githubusercontent.com/lpolish/managelinux/refs/heads/main/uninstall-oneline.sh | sudo bash
   ```

2. **Manual Uninstallation**:
   ```bash
   sudo ./uninstall.sh   # If you have a local copy
   # OR
   sudo /usr/local/bin/linux_quick_manage/uninstall.sh  # If installed system-wide
   ```

The uninstaller will:
- Remove all installation directories (both old and new paths)
- Remove the system-wide symlink
- Provide detailed feedback about the uninstallation process
- Handle any existing installations from previous versions

#### Command-line Options

The `run.sh` script supports the following options:

- `-h, --help`: Show help message
- `-s, --status`: Show installation status
- `-i, --install`: Install the suite system-wide
- `-u, --uninstall`: Uninstall the suite
- `-U, --update`: Update the suite to the latest version
- `-r, --run`: Run the suite (default if no option provided)

#### Script Documentation

##### Main Scripts

1. **run.sh**
   - Main entry point for the suite
   - Handles installation, uninstallation, and execution
   - Provides command-line interface for all operations
   - Manages both installed and non-installed usage
   - Supports automatic updates via git

2. **install.sh**
   - Handles system-wide installation
   - Creates necessary directories and symlinks
   - Generates uninstaller script
   - Checks system requirements

3. **server_migrator.sh**
   - Core functionality script
   - Provides main menu interface
   - Coordinates all suite operations
   - Manages user interactions

##### Feature Scripts

4. **partition_manager.sh**
   - Handles all partition-related operations
   - Supports creation, resizing, and formatting
   - Includes safety checks and confirmations
   - Provides interactive disk selection

5. **migration_manager.sh**
   - Manages system migrations
   - Supports Ubuntu LTS and Debian Enterprise
   - Handles custom migrations
   - Performs automatic backups

6. **system_info.sh**
   - Displays comprehensive system information
   - Shows hardware and software details
   - Monitors services and packages
   - Provides system logs viewer

7. **backup_manager.sh**
   - Manages system backups
   - Handles backup creation and restoration
   - Verifies backup integrity
   - Generates backup manifests

8. **iso_to_docker.sh**
   - Converts Linux ISO images to Docker containers
   - Extracts ISO contents and creates Dockerfile
   - Builds Docker image with custom tags
   - Automatically installs required dependencies
   - Usage: `./iso_to_docker.sh <iso_file> [docker_tag]`

9. **container_manager.sh**
   - Comprehensive container management
   - Application-based organization
   - Health monitoring and resource tracking
   - Backup and restore functionality
   - Volume and network management
   - Kubernetes migration support
   - Application structure:
     ```
     applications/
     ├── app_name/
     │   ├── docker-compose.yml
     │   ├── metadata.json
     │   ├── config/
     │   ├── logs/
     │   ├── backups/
     │   └── kubernetes-manifests/
     └── ...
     ```
   - Usage: `./container_manager.sh [OPTION] [APP_NAME] [BACKUP_DATE]`
   - Options:
     - `init [APP_NAME]`: Initialize new application structure
     - `list`: List all applications
     - `start [APP_NAME]`: Start Docker Compose services
     - `stop [APP_NAME]`: Stop Docker Compose services
     - `restart [APP_NAME]`: Restart Docker Compose services
     - `update [APP_NAME]`: Update Docker Compose services
     - `status [APP_NAME]`: Show service status
     - `cleanup [APP_NAME]`: Clean up unused Docker resources
     - `migrate [APP_NAME]`: Generate Kubernetes manifests
     - `backup [APP_NAME]`: Backup application
     - `restore [APP_NAME] [BACKUP_DATE]`: Restore application from backup
     - `help`: Show help message
   - Features:
     - Automatic health checks
     - Resource usage monitoring
     - Volume backup and restore
     - Network isolation
     - Application state tracking
     - Kubernetes manifest generation
     - Backup versioning
     - Configuration management

10. **generate_migration_report.sh**
    - Generates comprehensive system reports for migration preparation
    - Collects detailed system information and configurations
    - Creates timestamped reports in migration_reports directory
    - Includes software versions, services, and security information
    - Usage: `./generate_migration_report.sh`

11. **create_live_usb.sh**
    - Creates bootable Ubuntu 22.04 live USB
    - Downloads Ubuntu 22.04 ISO if not present
    - Lists available USB drives
    - Handles drive formatting and ISO writing
    - Includes safety checks and progress monitoring
    - Usage: `sudo ./create_live_usb.sh`

12. **git_server_manager.sh**
    - Installs and configures SSH-based Git server
    - Creates dedicated git user with proper permissions
    - Manages SSH keys for secure access
    - Handles repository creation and listing
    - Monitors server status
    - Usage: `./git_server_manager.sh [OPTION]`
    - Options:
      - `-i, --install`: Install Git server
      - `-a, --add-key`: Add SSH key
      - `-c, --create`: Create new repository
      - `-l, --list`: List repositories
      - `-s, --status`: Show Git server status

13. **user_manager.sh**
    - Manages system users and permissions
    - Creates and deletes users
    - Manages Git server access
    - Handles SSH key generation and management
    - Lists users and their access levels
    - Usage: `./user_manager.sh [OPTION]`
    - Options:
      - `-c, --create`: Create new user
      - `-d, --delete`: Delete user
      - `-l, --list`: List users
      - `-g, --git`: Manage Git server access

14. **samba_manager.sh**
    - Installs and configures Samba server
    - Creates and manages network shares
    - Handles user authentication
    - Manages share permissions
    - Monitors active connections
    - Usage: `./samba_manager.sh`
    - Features:
      - Install Samba server
      - Create new shares
      - List existing shares
      - Remove shares
      - Add Samba users
      - Show server status

15. **ssh_manager.sh**
    - Installs and configures SSH server
    - Manages SSH keys and authorized users
    - Configures security settings
    - Monitors active connections
    - Usage: `./ssh_manager.sh`
    - Features:
      - Install SSH server
      - Add/remove SSH keys
      - List authorized keys
      - Configure server settings
      - Monitor connections
      - Security hardening

#### Project Structure

```
linux_quick_manage/
├── server_migrator.sh    # Main script
├── partition_manager.sh  # Partition management
├── migration_manager.sh  # System migration
├── system_info.sh       # System information
├── backup_manager.sh    # Backup management
├── iso_to_docker.sh     # ISO to Docker converter
├── kubernetes_manager.sh # Kubernetes installation and management
├── git_server_manager.sh # Git server installation and management
├── user_manager.sh      # User management and access control
├── generate_migration_report.sh  # Migration report generator
├── create_live_usb.sh   # Live USB creator
├── run.sh              # Entry point script
├── install.sh          # Installation script
├── README.md           # Documentation
└── LICENSE             # License file
```

#### Safety Features

- All destructive operations require confirmation
- Automatic backup creation before migrations
- System requirements checking
- Backup verification
- USB boot detection for partition operations

#### Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

#### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

#### Support

For support, please open an issue in the GitHub repository.

#### Disclaimer

This tool performs system-level operations that can potentially damage your system if used incorrectly. Always ensure you have proper backups before performing any operations. The authors are not responsible for any data loss or system damage that may occur from using this tool.

### Windows Installation

1. **Prerequisites**:
   - Install Docker Desktop for Windows from [Docker's website](https://www.docker.com/products/docker-desktop)
   - Ensure PowerShell is running with administrator privileges

2. **Installation Options**:

   a. **Quick Installation** (Recommended):
   ```powershell
   # Open PowerShell as Administrator and run:
   Set-ExecutionPolicy Bypass -Scope Process -Force
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/lpolish/managelinux/main/windows/install.ps1" -OutFile "install.ps1"
   .\install.ps1
   ```
   The installer will automatically download any required files.

   b. **Manual Installation**:
   ```powershell
   # Clone the repository
   git clone https://github.com/lpolish/managelinux.git
   cd managelinux/windows
   
   # Run the installer
   .\install.ps1
   ```

3. **Using the ISO to Docker Converter**:
   ```powershell
   # Using the installed version
   Start-Process "C:\Program Files\ServerMigrationSuite\iso_to_docker.ps1" -Verb RunAs

   # Or run directly from the repository
   .\iso_to_docker.ps1 -IsoPath "path\to\your.iso" -DockerTag "custom-tag"
   ```

   Features:
   - Automatic 7-Zip installation if missing
   - Progress feedback during extraction
   - Error handling and validation
   - Clean temporary files
   - Interactive user prompts
   - Color-coded output for better visibility

4. **Creating Live USB**:
   ```powershell
   # Using the installed version
   Start-Process "C:\Program Files\ServerMigrationSuite\create_live_usb.ps1" -Verb RunAs

   # Or run directly from the repository
   .\create_live_usb.ps1
   ```

   Features:
   - Automatic Rufus installation if missing
   - USB drive detection and validation
   - Automatic Ubuntu ISO download
   - Progress feedback during operations
   - Error handling and validation
   - Interactive user prompts
   - Color-coded output for better visibility

5. **Uninstallation**:
   ```powershell
   # Run the uninstaller
   & "C:\Program Files\ServerMigrationSuite\uninstall.ps1"
   ```

## Project Structure

```
linux_quick_manage/
├── server_migrator.sh    # Main script
├── partition_manager.sh  # Partition management
├── migration_manager.sh  # System migration
├── system_info.sh       # System information
├── backup_manager.sh    # Backup management
├── iso_to_docker.sh     # ISO to Docker converter
├── kubernetes_manager.sh # Kubernetes installation and management
├── git_server_manager.sh # Git server installation and management
├── user_manager.sh      # User management and access control
├── generate_migration_report.sh  # Migration report generator
├── create_live_usb.sh   # Live USB creator
├── run.sh              # Entry point script
├── install.sh          # Installation script
├── windows/            # Windows-specific scripts
│   ├── iso_to_docker.ps1      # Windows ISO to Docker converter
│   ├── create_live_usb.ps1    # Windows Live USB creator
│   └── install.ps1            # Windows installation script
├── README.md           # Documentation
└── LICENSE             # License file
``` 
