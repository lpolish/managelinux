# Windows Installation Script for ISOToDocker

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to get script directory
function Get-ScriptDirectory {
    try {
        if ($PSCommandPath) {
            return Split-Path -Parent $PSCommandPath
        }
        elseif ($MyInvocation.MyCommand.Path) {
            return Split-Path -Parent $MyInvocation.MyCommand.Path
        }
        else {
            return $PWD.Path
        }
    }
    catch {
        Write-Host "Warning: Could not determine script directory, using current directory"
        return $PWD.Path
    }
}

# Function to download required files
function Get-RequiredFiles {
    try {
        $scriptPath = Get-ScriptDirectory
        Write-Host "Script directory: $scriptPath"
        
        $isoToDockerPath = Join-Path $scriptPath "iso_to_docker.ps1"
        Write-Host "Looking for iso_to_docker.ps1 at: $isoToDockerPath"
        
        if (-not (Test-Path $isoToDockerPath)) {
            Write-Host "Downloading iso_to_docker.ps1..."
            try {
                $url = "https://raw.githubusercontent.com/lpolish/managelinux/refs/heads/main/windows/iso_to_docker.ps1"
                Invoke-WebRequest -Uri $url -OutFile $isoToDockerPath
                Write-Host "Successfully downloaded iso_to_docker.ps1"
            }
            catch {
                Write-Host "Failed to download iso_to_docker.ps1: $_"
                exit 1
            }
        }
        else {
            Write-Host "Found existing iso_to_docker.ps1"
        }
    }
    catch {
        Write-Host "Error in Get-RequiredFiles: $_"
        exit 1
    }
}

# Function to verify installation
function Test-Installation {
    param (
        [string]$installPath,
        [string]$cmdPath
    )
    
    Write-Host "`nVerifying installation..."
    
    # Check installation directory
    if (-not (Test-Path $installPath)) {
        Write-Host "Error: Installation directory not found at $installPath"
        return $false
    }
    Write-Host "✓ Installation directory exists"
    
    # Check iso_to_docker.ps1
    $scriptPath = Join-Path $installPath "iso_to_docker.ps1"
    if (-not (Test-Path $scriptPath)) {
        Write-Host "Error: iso_to_docker.ps1 not found at $scriptPath"
        return $false
    }
    Write-Host "✓ iso_to_docker.ps1 found"
    
    # Check command file
    if (-not (Test-Path $cmdPath)) {
        Write-Host "Error: Command file not found at $cmdPath"
        return $false
    }
    Write-Host "✓ Command file found"
    
    # Test command availability
    try {
        $result = & $cmdPath -ErrorAction Stop
        Write-Host "✓ Command test successful"
    }
    catch {
        Write-Host "Error: Command test failed: $_"
        return $false
    }
    
    return $true
}

# Function to create installation directory
function Install-Scripts {
    try {
        Write-Host "`nStarting installation process..."
        $installPath = "C:\Program Files\ServerMigrationSuite"
        
        # Create installation directory
        if (-not (Test-Path $installPath)) {
            Write-Host "Creating installation directory: $installPath"
            New-Item -ItemType Directory -Path $installPath | Out-Null
            if (-not (Test-Path $installPath)) {
                throw "Failed to create installation directory"
            }
        }
        Write-Host "✓ Installation directory ready"
        
        # Get the script directory
        $scriptPath = Get-ScriptDirectory
        $isoToDockerPath = Join-Path $scriptPath "iso_to_docker.ps1"
        
        # Copy scripts
        if (Test-Path $isoToDockerPath) {
            Write-Host "Copying iso_to_docker.ps1 to $installPath"
            Copy-Item -Path $isoToDockerPath -Destination $installPath -Force
            if (-not (Test-Path (Join-Path $installPath "iso_to_docker.ps1"))) {
                throw "Failed to copy iso_to_docker.ps1"
            }
        }
        else {
            throw "Error: iso_to_docker.ps1 not found at $isoToDockerPath"
        }
        Write-Host "✓ Scripts copied successfully"

        # Create global command (command-line mode)
        $system32Path = [Environment]::GetFolderPath("System")
        $cmdPath = Join-Path $system32Path "isotodocker.cmd"
        Write-Host "Creating global command at: $cmdPath"
        @"
@echo off
powershell.exe -ExecutionPolicy Bypass -File "C:\Program Files\ServerMigrationSuite\iso_to_docker.ps1" %*
"@ | Out-File -FilePath $cmdPath -Encoding ASCII
        if (-not (Test-Path $cmdPath)) {
            throw "Failed to create command file"
        }
        Write-Host "✓ Global command created"
        
        # Create uninstaller
        $uninstallerPath = Join-Path $installPath "uninstall.ps1"
        Write-Host "Creating uninstaller at: $uninstallerPath"
        @"
# Uninstaller for ISOToDocker
Remove-Item -Path "C:\Program Files\ServerMigrationSuite" -Recurse -Force
Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\ISOToDocker" -Recurse -Force
Remove-Item -Path "$([Environment]::GetFolderPath('System'))\isotodocker.cmd" -Force
"@ | Out-File -FilePath $uninstallerPath -Encoding ASCII
        if (-not (Test-Path $uninstallerPath)) {
            throw "Failed to create uninstaller"
        }
        Write-Host "✓ Uninstaller created"
        
        # Create shortcuts
        $shortcutPath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\ISOToDocker"
        if (-not (Test-Path $shortcutPath)) {
            Write-Host "Creating Start Menu shortcut directory"
            New-Item -ItemType Directory -Path $shortcutPath | Out-Null
            if (-not (Test-Path $shortcutPath)) {
                throw "Failed to create shortcut directory"
            }
        }
        
        # Create GUI shortcut (Start Menu)
        Write-Host "Creating Start Menu shortcut (GUI mode)"
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut("$shortcutPath\ISO to Docker Converter.lnk")
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Normal -File `"$installPath\iso_to_docker.ps1`""
        $Shortcut.WorkingDirectory = $installPath
        $Shortcut.Description = "ISO to Docker Converter (GUI Mode)"
        $Shortcut.Save()
        if (-not (Test-Path "$shortcutPath\ISO to Docker Converter.lnk")) {
            throw "Failed to create Start Menu shortcut"
        }
        Write-Host "✓ Start Menu shortcut created"

        # Create command-line shortcut (Start Menu)
        Write-Host "Creating command-line shortcut in Start Menu"
        $Shortcut = $WshShell.CreateShortcut("$shortcutPath\ISO to Docker Converter (Command Line).lnk")
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-ExecutionPolicy Bypass -NoExit -File `"$installPath\iso_to_docker.ps1`""
        $Shortcut.WorkingDirectory = $installPath
        $Shortcut.Description = "ISO to Docker Converter (Command Line Mode)"
        $Shortcut.Save()
        if (-not (Test-Path "$shortcutPath\ISO to Docker Converter (Command Line).lnk")) {
            throw "Failed to create command-line shortcut"
        }
        Write-Host "✓ Command-line shortcut created"
        
        # Verify installation
        if (-not (Test-Installation -installPath $installPath -cmdPath $cmdPath)) {
            throw "Installation verification failed"
        }
        
        Write-Host "`nInstallation completed successfully!"
        Write-Host "The ISO to Docker Converter is available in two modes:"
        Write-Host "1. GUI Mode: Use the Start Menu shortcut 'ISO to Docker Converter'"
        Write-Host "2. Command Line Mode: Use 'isotodocker' command in PowerShell or Command Prompt"
        Write-Host "`nTo test the command-line mode, try running: isotodocker --help"
    }
    catch {
        Write-Host "Error in Install-Scripts: $_"
        exit 1
    }
}

# Main script execution
Write-Host "ISOToDocker - Windows Installation"
Write-Host "============================================"

# Check if running as administrator
if (-not (Test-Administrator)) {
    Write-Host "This script requires administrator privileges."
    Write-Host "Please run PowerShell as Administrator and try again."
    exit 1
}

# Check if Docker is installed
try {
    $dockerVersion = docker --version
    Write-Host "Docker is installed: $dockerVersion"
}
catch {
    Write-Host "Docker is not installed or not in PATH"
    Write-Host "Please install Docker Desktop for Windows first:"
    Write-Host "https://www.docker.com/products/docker-desktop"
    exit 1
}

# Download required files if needed
Get-RequiredFiles

# Perform installation
Install-Scripts 