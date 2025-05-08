# Live USB Creator for Windows
# Part of Server Migration and Management Suite

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to get available USB drives
function Get-USBDrives {
    try {
        $usbDrives = Get-WmiObject Win32_DiskDrive | Where-Object { $_.InterfaceType -eq "USB" }
        
        if ($usbDrives.Count -eq 0) {
            Write-Host "`nNo USB drives detected. Please insert a USB drive and try again." -ForegroundColor Red
            return $false
        }
        
        Write-Host "`nAvailable USB drives:" -ForegroundColor Blue
        foreach ($drive in $usbDrives) {
            $size = [math]::Round($drive.Size / 1GB, 2)
            Write-Host "Device ID: $($drive.DeviceID)" -ForegroundColor Yellow
            Write-Host "Model: $($drive.Model)" -ForegroundColor Yellow
            Write-Host "Size: ${size}GB" -ForegroundColor Yellow
            Write-Host "---"
        }
        return $true
    }
    catch {
        Write-Host "Error detecting USB drives: $_" -ForegroundColor Red
        return $false
    }
}

# Function to download Ubuntu ISO if needed
function Get-UbuntuISO {
    param (
        [string]$IsoPath
    )
    
    try {
        if (-not (Test-Path $IsoPath)) {
            Write-Host "Downloading Ubuntu 22.04 ISO..." -ForegroundColor Yellow
            $url = "https://releases.ubuntu.com/22.04/ubuntu-22.04.3-desktop-amd64.iso"
            $progressPreference = 'silentlyContinue'
            Invoke-WebRequest -Uri $url -OutFile $IsoPath -UseBasicParsing
            Write-Host "Download complete!" -ForegroundColor Green
        } else {
            Write-Host "ISO file already exists" -ForegroundColor Green
        }
        return $true
    }
    catch {
        Write-Host "Error downloading ISO: $_" -ForegroundColor Red
        return $false
    }
}

# Function to create live USB
function New-LiveUSB {
    param (
        [string]$IsoPath,
        [string]$TargetDrive
    )
    
    try {
        # Verify target drive exists
        if (-not (Test-Path $TargetDrive)) {
            Write-Host "Error: $TargetDrive is not a valid drive" -ForegroundColor Red
            return $false
        }
        
        # Confirm with user
        Write-Host "WARNING: This will erase all data on $TargetDrive" -ForegroundColor Red
        $confirm = Read-Host "Are you sure you want to continue? (y/N)"
        if ($confirm -notmatch '^[Yy]$') {
            Write-Host "Operation cancelled" -ForegroundColor Yellow
            return $false
        }
        
        # Check if Rufus is installed
        $rufusPath = "C:\Program Files\Rufus\rufus.exe"
        if (-not (Test-Path $rufusPath)) {
            Write-Host "Rufus not found. Installing Rufus..." -ForegroundColor Yellow
            
            # Create temp directory
            $tempDir = Join-Path $env:TEMP "rufus_download"
            New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
            
            # Download Rufus
            $rufusUrl = "https://github.com/pbatard/rufus/releases/download/v4.1/rufus-4.1.exe"
            $rufusInstaller = Join-Path $tempDir "rufus.exe"
            $progressPreference = 'silentlyContinue'
            Invoke-WebRequest -Uri $rufusUrl -OutFile $rufusInstaller -UseBasicParsing
            
            # Create Rufus directory
            New-Item -ItemType Directory -Force -Path "C:\Program Files\Rufus" | Out-Null
            
            # Move Rufus to Program Files
            Move-Item -Path $rufusInstaller -Destination $rufusPath -Force
            
            # Clean up
            Remove-Item -Path $tempDir -Recurse -Force
        }
        
        # Create live USB using Rufus
        Write-Host "Creating live USB... This may take several minutes." -ForegroundColor Yellow
        Write-Host "Please follow the Rufus prompts to complete the process." -ForegroundColor Yellow
        
        # Launch Rufus with parameters
        $process = Start-Process -FilePath $rufusPath -ArgumentList "-i `"$IsoPath`" -d `"$TargetDrive`" --format" -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Host "Live USB creation completed successfully!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "Live USB creation failed with exit code: $($process.ExitCode)" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "Error during live USB creation: $_" -ForegroundColor Red
        return $false
    }
}

# Main execution
try {
    if (-not (Test-Administrator)) {
        Write-Host "Please run this script as Administrator" -ForegroundColor Red
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }

    Write-Host "=== Ubuntu 22.04 Live USB Creator ===" -ForegroundColor Blue
    Write-Host

    # Get available USB drives
    if (-not (Get-USBDrives)) {
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }

    # Get target drive from user
    $targetDrive = Read-Host "Enter the target USB drive letter (e.g., E:)"
    $targetDrive = $targetDrive.TrimEnd(':') + ":"

    # Set ISO path
    $isoPath = Join-Path $PSScriptRoot "ubuntu-22.04.3-desktop-amd64.iso"

    # Download ISO if needed
    if (-not (Get-UbuntuISO -IsoPath $isoPath)) {
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }

    # Create live USB
    if (New-LiveUSB -IsoPath $isoPath -TargetDrive $targetDrive) {
        Write-Host "`nOperation completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "`nOperation failed. Please check the error messages above." -ForegroundColor Red
    }
}
catch {
    Write-Host "`nAn unexpected error occurred: $_" -ForegroundColor Red
}
finally {
    Write-Host "`nPress any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} 