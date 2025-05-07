# Windows Installation Script for Server Migration Suite

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to create installation directory
function Install-Scripts {
    $installPath = "C:\Program Files\ServerMigrationSuite"
    
    # Create installation directory
    if (-not (Test-Path $installPath)) {
        New-Item -ItemType Directory -Path $installPath | Out-Null
    }
    
    # Copy scripts
    Copy-Item -Path ".\iso_to_docker.ps1" -Destination $installPath -Force
    
    # Create uninstaller
    $uninstallerPath = Join-Path $installPath "uninstall.ps1"
    @"
# Uninstaller for Server Migration Suite
Remove-Item -Path "C:\Program Files\ServerMigrationSuite" -Recurse -Force
Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Server Migration Suite" -Recurse -Force
"@ | Out-File -FilePath $uninstallerPath -Encoding ASCII
    
    # Create shortcuts
    $shortcutPath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Server Migration Suite"
    if (-not (Test-Path $shortcutPath)) {
        New-Item -ItemType Directory -Path $shortcutPath | Out-Null
    }
    
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("$shortcutPath\ISO to Docker Converter.lnk")
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$installPath\iso_to_docker.ps1`""
    $Shortcut.Save()
    
    Write-Host "Installation completed successfully!"
    Write-Host "The ISO to Docker Converter is now available in the Start Menu under 'Server Migration Suite'"
}

# Main script execution
Write-Host "Server Migration Suite - Windows Installation"
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

# Perform installation
Install-Scripts 