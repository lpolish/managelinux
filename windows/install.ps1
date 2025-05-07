# Windows Installation Script for ISOToDocker

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to get script directory
function Get-ScriptDirectory {
    if ($MyInvocation.MyCommand.Path) {
        return Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    return $PWD.Path
}

# Function to download required files
function Get-RequiredFiles {
    $scriptPath = Get-ScriptDirectory
    $isoToDockerPath = Join-Path $scriptPath "iso_to_docker.ps1"
    
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
}

# Function to create installation directory
function Install-Scripts {
    $installPath = "C:\Program Files\ServerMigrationSuite"
    
    # Create installation directory
    if (-not (Test-Path $installPath)) {
        New-Item -ItemType Directory -Path $installPath | Out-Null
    }
    
    # Get the script directory
    $scriptPath = Get-ScriptDirectory
    $isoToDockerPath = Join-Path $scriptPath "iso_to_docker.ps1"
    
    # Copy scripts
    if (Test-Path $isoToDockerPath) {
        Copy-Item -Path $isoToDockerPath -Destination $installPath -Force
        Write-Host "Copied iso_to_docker.ps1 to $installPath"
    }
    else {
        Write-Host "Error: iso_to_docker.ps1 not found. Please ensure you have downloaded both files."
        exit 1
    }
    
    # Create uninstaller
    $uninstallerPath = Join-Path $installPath "uninstall.ps1"
    @"
# Uninstaller for ISOToDocker
Remove-Item -Path "C:\Program Files\ServerMigrationSuite" -Recurse -Force
Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\ISOToDocker" -Recurse -Force
"@ | Out-File -FilePath $uninstallerPath -Encoding ASCII
    
    # Create shortcuts
    $shortcutPath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\ISOToDocker"
    if (-not (Test-Path $shortcutPath)) {
        New-Item -ItemType Directory -Path $shortcutPath | Out-Null
    }
    
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$shortcutPath\ISO to Docker Converter.lnk")
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$installPath\iso_to_docker.ps1`""
    $Shortcut.Save()
    
    Write-Host "Installation completed successfully!"
    Write-Host "The ISO to Docker Converter is now available in the Start Menu under 'ISOToDocker'"
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