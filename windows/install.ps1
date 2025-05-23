﻿# Windows Installation Script for Server Migration Suite

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

# Function to delete script after execution
function Remove-Script {
    try {
        $scriptPath = $MyInvocation.MyCommand.Path
        if ($scriptPath) {
            Write-Host "`nCleaning up installation script..."
            # Create a scheduled task to delete the script after PowerShell exits
            $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c del `"$scriptPath`""
            $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(2)
            $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
            Register-ScheduledTask -TaskName "DeleteInstallScript" -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null
            Write-Host "✓ Installation script will be removed"
        }
    }
    catch {
        Write-Host "Warning: Could not schedule script removal: $_"
    }
}

# Function to install .NET SDK
function Install-DotNetSdk {
    try {
        Write-Host "`nChecking .NET SDK installation..."
        
        # Check if .NET SDK is already installed
        try {
            $dotnetVersion = dotnet --version
            Write-Host "Found .NET SDK version: $dotnetVersion"
            return $true
        }
        catch {
            Write-Host ".NET SDK not found, proceeding with installation..."
        }

        # Create temporary directory for download
        $tempDir = Join-Path $env:TEMP "dotnet-install"
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir | Out-Null
        }

        # Download .NET SDK installer
        $installerUrl = "https://dot.net/v1/dotnet-install.ps1"
        $installerPath = Join-Path $tempDir "dotnet-install.ps1"
        
        Write-Host "Downloading .NET SDK installer..."
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
        
        # Install .NET SDK 6.0
        Write-Host "Installing .NET SDK 6.0..."
        & $installerPath -Channel 6.0 -Version latest -InstallDir "C:\Program Files\dotnet" -NoPath
        
        # Add to PATH if not already present
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
        $dotnetPath = "C:\Program Files\dotnet"
        if (-not $currentPath.Contains($dotnetPath)) {
            [Environment]::SetEnvironmentVariable("Path", "$currentPath;$dotnetPath", "Machine")
            $env:Path = "$env:Path;$dotnetPath"
        }

        # Verify installation
        try {
            $dotnetVersion = dotnet --version
            Write-Host "Successfully installed .NET SDK version: $dotnetVersion"
            return $true
        }
        catch {
            Write-Host "Failed to verify .NET SDK installation"
            return $false
        }
    }
    catch {
        Write-Host "Error installing .NET SDK: $_"
        return $false
    }
    finally {
        # Cleanup
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force
        }
    }
}

# Function to build WPF application
function Build-WpfApplication {
    try {
        Write-Host "`nBuilding WPF Live USB Creator application..."
        $scriptPath = Get-ScriptDirectory
        $wpfProjectPath = Join-Path $scriptPath "..\LiveUsbCreator"
        
        if (-not (Test-Path $wpfProjectPath)) {
            throw "WPF project directory not found at: $wpfProjectPath"
        }

        # Check if .NET SDK is installed
        if (-not (Install-DotNetSdk)) {
            throw ".NET SDK installation failed"
        }

        # Create Resources directory if it doesn't exist
        $resourcesPath = Join-Path $wpfProjectPath "LiveUsbCreator\Resources"
        if (-not (Test-Path $resourcesPath)) {
            New-Item -ItemType Directory -Path $resourcesPath | Out-Null
        }

        # Create a simple USB icon if it doesn't exist
        $iconPath = Join-Path $resourcesPath "usb-icon.ico"
        if (-not (Test-Path $iconPath)) {
            Write-Host "Creating default USB icon..."
            # TODO: Create or download a proper USB icon
            # For now, we'll use a system icon
            Copy-Item "C:\Windows\System32\shell32.dll,7" -Destination $iconPath
        }

        # Build the application
        Write-Host "Building WPF application..."
        Push-Location $wpfProjectPath
        dotnet build -c Release
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to build WPF application"
        }
        Pop-Location

        # Get the built executable path
        $exePath = Join-Path $wpfProjectPath "LiveUsbCreator\bin\Release\net6.0-windows\LiveUsbCreator.exe"
        if (-not (Test-Path $exePath)) {
            throw "Built executable not found at: $exePath"
        }

        Write-Host "✓ WPF application built successfully"
        return $exePath
    }
    catch {
        Write-Host "Error building WPF application: $_"
        return $null
    }
}

# Function to create shortcut
function New-Shortcut {
    param (
        [string]$TargetPath,
        [string]$ShortcutPath,
        [string]$Description,
        [string]$Arguments,
        [string]$IconPath,
        [int]$WindowStyle = 1  # 1 = Normal, 3 = Maximized, 7 = Minimized
    )
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $TargetPath
    $Shortcut.Arguments = $Arguments
    $Shortcut.Description = $Description
    $Shortcut.WindowStyle = $WindowStyle
    if ($IconPath) {
        $Shortcut.IconLocation = $IconPath
    }
    $Shortcut.Save()
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
        
        # Build and copy WPF application
        $wpfExePath = Build-WpfApplication
        if ($wpfExePath) {
            Write-Host "Copying WPF application to installation directory..."
            Copy-Item -Path $wpfExePath -Destination $installPath -Force
            if (-not (Test-Path (Join-Path $installPath "LiveUsbCreator.exe"))) {
                throw "Failed to copy WPF application"
            }
            Write-Host "✓ WPF application copied successfully"
        }
        
        # Copy terminal-based scripts
        $scripts = @(
            "create_live_usb.ps1",
            "iso_to_docker.ps1"
        )
        
        foreach ($script in $scripts) {
            $sourcePath = Join-Path $scriptPath $script
            $destPath = Join-Path $installPath $script
            if (Test-Path $sourcePath) {
                Write-Host "Copying $script to $installPath"
                # Ensure the script is copied with proper permissions
                Copy-Item -Path $sourcePath -Destination $destPath -Force
                # Set proper permissions
                $acl = Get-Acl $destPath
                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "ReadAndExecute", "Allow")
                $acl.SetAccessRule($rule)
                Set-Acl $destPath $acl
                
                if (-not (Test-Path $destPath)) {
                    throw "Failed to copy $script"
                }
                Write-Host "✓ Copied and set permissions for $script"
            }
        }
        Write-Host "✓ Terminal scripts copied successfully"

        # Create global commands (command-line mode)
        $system32Path = [Environment]::GetFolderPath("System")
        $commands = @{
            "createliveusb.cmd" = "create_live_usb.ps1"
            "isotodocker.cmd" = "iso_to_docker.ps1"
        }
        
        foreach ($cmd in $commands.GetEnumerator()) {
            $cmdPath = Join-Path $system32Path $cmd.Key
            Write-Host "Creating global command at: $cmdPath"
            @"
@echo off
cd /d "C:\Program Files\ServerMigrationSuite"
powershell.exe -NoProfile -ExecutionPolicy Bypass -NoExit -WindowStyle Normal -Command "& { Set-Location 'C:\Program Files\ServerMigrationSuite'; & .\$($cmd.Value) %* }"
pause
"@ | Out-File -FilePath $cmdPath -Encoding ASCII -Force
            
            # Set proper permissions for the command file
            $acl = Get-Acl $cmdPath
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "ReadAndExecute", "Allow")
            $acl.SetAccessRule($rule)
            Set-Acl $cmdPath $acl
            
            if (-not (Test-Path $cmdPath)) {
                throw "Failed to create command file $($cmd.Key)"
            }
            Write-Host "✓ Created and set permissions for $($cmd.Key)"
        }
        Write-Host "✓ Global commands created"
        
        # Create uninstaller
        $uninstallerPath = Join-Path $installPath "uninstall.ps1"
        Write-Host "Creating uninstaller at: $uninstallerPath"
        @"
# Uninstaller for Server Migration Suite
Remove-Item -Path "C:\Program Files\ServerMigrationSuite" -Recurse -Force
Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Server Migration Suite" -Recurse -Force
Remove-Item -Path "$([Environment]::GetFolderPath('System'))\createliveusb.cmd" -Force
Remove-Item -Path "$([Environment]::GetFolderPath('System'))\isotodocker.cmd" -Force
"@ | Out-File -FilePath $uninstallerPath -Encoding ASCII
        if (-not (Test-Path $uninstallerPath)) {
            throw "Failed to create uninstaller"
        }
        Write-Host "✓ Uninstaller created"
        
        # Create Start Menu shortcuts
        $startMenuPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Server Migration Suite"
        if (-not (Test-Path $startMenuPath)) {
            Write-Host "Creating Start Menu shortcut directory"
            New-Item -ItemType Directory -Path $startMenuPath | Out-Null
            if (-not (Test-Path $startMenuPath)) {
                throw "Failed to create shortcut directory"
            }
        }
        
        # Create shortcuts for terminal-based tools
        $terminalShortcuts = @{
            "Create Live USB (Terminal)" = "create_live_usb.ps1"
            "ISO to Docker Converter (Terminal)" = "iso_to_docker.ps1"
        }
        
        foreach ($shortcut in $terminalShortcuts.GetEnumerator()) {
            Write-Host "Creating Start Menu shortcut: $($shortcut.Key)"
            New-Shortcut -TargetPath "powershell.exe" `
                -ShortcutPath "$startMenuPath\$($shortcut.Key).lnk" `
                -Description $shortcut.Key `
                -Arguments "-NoProfile -ExecutionPolicy Bypass -NoExit -WindowStyle Normal -Command `"& { Set-Location 'C:\Program Files\ServerMigrationSuite'; & .\$($shortcut.Value) }`"" `
                -IconPath "shell32.dll,7" `
                -WindowStyle 1
        }
        
        # Create shortcut for WPF Live USB Creator
        $wpfAppPath = Join-Path $installPath "LiveUsbCreator.exe"
        if (Test-Path $wpfAppPath) {
            Write-Host "Creating Start Menu shortcut for WPF Live USB Creator"
            New-Shortcut -TargetPath $wpfAppPath `
                -ShortcutPath "$startMenuPath\Create Live USB.lnk" `
                -Description "Create Live USB (Modern GUI)" `
                -IconPath "$wpfAppPath,0" `
                -WindowStyle 1
        }
        
        Write-Host "✓ Start Menu shortcuts created"
        
        # Remove old GUI scripts
        $oldGuiScripts = @(
            "create_live_usb_gui.ps1",
            "iso_to_docker_gui.ps1"
        )
        
        foreach ($script in $oldGuiScripts) {
            $scriptPath = Join-Path $installPath $script
            if (Test-Path $scriptPath) {
                Write-Host "Removing old GUI script: $script"
                Remove-Item -Path $scriptPath -Force
            }
        }
        
        return $true
    }
    catch {
        Write-Host "Error in Install-Scripts: $_"
        return $false
    }
}

# Function to uninstall the application
function Uninstall-Application {
    try {
        Write-Host "`nStarting uninstallation process..."
        
        # Define paths
        $installPath = "C:\Program Files\ServerMigrationSuite"
        $startMenuPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Server Migration Suite"
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $cmdPath = Join-Path ([Environment]::GetFolderPath('System')) "isotodocker.cmd"
        $uninstallerPath = Join-Path $installPath "uninstall.ps1"

        # Remove command file
        if (Test-Path $cmdPath) {
            Write-Host "Removing command file: $cmdPath"
            Remove-Item -Path $cmdPath -Force
            Write-Host "✓ Command file removed"
        }

        # Remove Start Menu shortcuts
        if (Test-Path $startMenuPath) {
            Write-Host "Removing Start Menu shortcuts: $startMenuPath"
            Remove-Item -Path $startMenuPath -Recurse -Force
            Write-Host "✓ Start Menu shortcuts removed"
        }

        # Remove Desktop shortcuts
        $desktopShortcuts = @(
            "$desktopPath\ISO to Docker Converter.lnk",
            "$desktopPath\Create Live USB.lnk"
        )
        foreach ($shortcut in $desktopShortcuts) {
            if (Test-Path $shortcut) {
                Write-Host "Removing Desktop shortcut: $shortcut"
                Remove-Item -Path $shortcut -Force
            }
        }
        Write-Host "✓ Desktop shortcuts removed"

        # Remove installation directory
        if (Test-Path $installPath) {
            Write-Host "Removing installation directory: $installPath"
            Remove-Item -Path $installPath -Recurse -Force
            Write-Host "✓ Installation directory removed"
        }

        # Remove the uninstaller itself if present
        if (Test-Path $uninstallerPath) {
            Write-Host "Removing uninstaller script: $uninstallerPath"
            Remove-Item -Path $uninstallerPath -Force
        }

        Write-Host "`nUninstallation completed successfully!"
        Write-Host "All Server Migration Suite components have been removed from your system."
    }
    catch {
        Write-Host "Error during uninstallation: $_"
        exit 1
    }
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

# Check for uninstall option
if ($args -contains "--uninstall") {
    Uninstall-Application
    exit 0
}

# Perform installation
$success = Install-Scripts

if ($success) {
    Write-Host "`nInstallation completed successfully!"
    Write-Host "You can find the tools in the Start Menu under 'Server Migration Suite'"
    Remove-Script
}
else {
    Write-Host "`nInstallation failed. Please check the error messages above."
    exit 1
} 
