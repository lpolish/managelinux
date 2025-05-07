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

# Function to create installation directory
function Install-Scripts {
    try {
        $installPath = "C:\Program Files\ServerMigrationSuite"
        
        # Create installation directory
        if (-not (Test-Path $installPath)) {
            Write-Host "Creating installation directory: $installPath"
            New-Item -ItemType Directory -Path $installPath | Out-Null
        }
        
        # Get the script directory
        $scriptPath = Get-ScriptDirectory
        $isoToDockerPath = Join-Path $scriptPath "iso_to_docker.ps1"
        
        # Copy scripts
        if (Test-Path $isoToDockerPath) {
            Write-Host "Copying iso_to_docker.ps1 to $installPath"
            Copy-Item -Path $isoToDockerPath -Destination $installPath -Force
        }
        else {
            Write-Host "Error: iso_to_docker.ps1 not found at $isoToDockerPath"
            exit 1
        }
        
        # Create uninstaller
        $uninstallerPath = Join-Path $installPath "uninstall.ps1"
        Write-Host "Creating uninstaller at: $uninstallerPath"
        @"
# Uninstaller for ISOToDocker
Remove-Item -Path "C:\Program Files\ServerMigrationSuite" -Recurse -Force
Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\ISOToDocker" -Recurse -Force
"@ | Out-File -FilePath $uninstallerPath -Encoding ASCII
        
        # Create shortcuts
        $shortcutPath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\ISOToDocker"
        if (-not (Test-Path $shortcutPath)) {
            Write-Host "Creating Start Menu shortcut directory"
            New-Item -ItemType Directory -Path $shortcutPath | Out-Null
        }
        
        Write-Host "Creating Start Menu shortcut"
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut("$shortcutPath\ISO to Docker Converter.lnk")
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$installPath\iso_to_docker.ps1`""
        $Shortcut.Save()
        
        Write-Host "Installation completed successfully!"
        Write-Host "The ISO to Docker Converter is now available in the Start Menu under 'ISOToDocker'"
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