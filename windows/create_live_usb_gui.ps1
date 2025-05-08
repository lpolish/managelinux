# Live USB Creator GUI for Windows
# Part of Server Migration and Management Suite

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to get available USB drives
function Get-USBDrives {
    $usbDrives = Get-WmiObject Win32_DiskDrive | Where-Object { $_.InterfaceType -eq "USB" }
    return $usbDrives
}

# Function to download Ubuntu ISO if needed
function Get-UbuntuISO {
    param (
        [string]$IsoPath,
        [System.Windows.Forms.ProgressBar]$ProgressBar,
        [System.Windows.Forms.Label]$StatusLabel
    )
    
    if (-not (Test-Path $IsoPath)) {
        $StatusLabel.Text = "Downloading Ubuntu 22.04 ISO..."
        $ProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
        $ProgressBar.MarqueeAnimationSpeed = 30
        $ProgressBar.Visible = $true
        
        $url = "https://releases.ubuntu.com/22.04/ubuntu-22.04.3-desktop-amd64.iso"
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($url, $IsoPath)
        
        $ProgressBar.Visible = $false
        $StatusLabel.Text = "Download complete!"
    } else {
        $StatusLabel.Text = "ISO file already exists"
    }
}

# Function to create live USB
function New-LiveUSB {
    param (
        [string]$IsoPath,
        [string]$TargetDrive,
        [System.Windows.Forms.ProgressBar]$ProgressBar,
        [System.Windows.Forms.Label]$StatusLabel
    )
    
    # Verify target drive exists
    if (-not (Test-Path $TargetDrive)) {
        $StatusLabel.Text = "Error: Invalid drive selected"
        return $false
    }
    
    # Check if Rufus is installed
    $rufusPath = "C:\Program Files\Rufus\rufus.exe"
    if (-not (Test-Path $rufusPath)) {
        $StatusLabel.Text = "Installing Rufus..."
        $ProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
        $ProgressBar.Visible = $true
        
        # Create temp directory
        $tempDir = Join-Path $env:TEMP "rufus_download"
        New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
        
        # Download Rufus
        $rufusUrl = "https://github.com/pbatard/rufus/releases/download/v4.1/rufus-4.1.exe"
        $rufusInstaller = Join-Path $tempDir "rufus.exe"
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($rufusUrl, $rufusInstaller)
        
        # Create Rufus directory
        New-Item -ItemType Directory -Force -Path "C:\Program Files\Rufus" | Out-Null
        
        # Move Rufus to Program Files
        Move-Item -Path $rufusInstaller -Destination $rufusPath -Force
        
        # Clean up
        Remove-Item -Path $tempDir -Recurse -Force
        
        $ProgressBar.Visible = $false
    }
    
    # Create live USB using Rufus
    $StatusLabel.Text = "Creating live USB... This may take several minutes."
    $ProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
    $ProgressBar.Visible = $true
    
    # Launch Rufus with parameters
    Start-Process -FilePath $rufusPath -ArgumentList "-i `"$IsoPath`" -d `"$TargetDrive`" --format" -Wait
    
    $ProgressBar.Visible = $false
    $StatusLabel.Text = "Live USB creation completed!"
    return $true
}

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Ubuntu 22.04 Live USB Creator"
$form.Size = New-Object System.Drawing.Size(600, 400)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSCommandPath)

# Create controls
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Ubuntu 22.04 Live USB Creator"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)
$titleLabel.Size = New-Object System.Drawing.Size(560, 30)
$titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($titleLabel)

$driveLabel = New-Object System.Windows.Forms.Label
$driveLabel.Text = "Select USB Drive:"
$driveLabel.Location = New-Object System.Drawing.Point(20, 70)
$driveLabel.Size = New-Object System.Drawing.Size(120, 20)
$form.Controls.Add($driveLabel)

$driveComboBox = New-Object System.Windows.Forms.ComboBox
$driveComboBox.Location = New-Object System.Drawing.Point(150, 70)
$driveComboBox.Size = New-Object System.Drawing.Size(400, 20)
$form.Controls.Add($driveComboBox)

# Populate drive list
$usbDrives = Get-USBDrives
foreach ($drive in $usbDrives) {
    $size = [math]::Round($drive.Size / 1GB, 2)
    $driveComboBox.Items.Add("$($drive.Model) (${size}GB)")
}

if ($driveComboBox.Items.Count -gt 0) {
    $driveComboBox.SelectedIndex = 0
}

$createButton = New-Object System.Windows.Forms.Button
$createButton.Text = "Create Live USB"
$createButton.Location = New-Object System.Drawing.Point(250, 120)
$createButton.Size = New-Object System.Drawing.Size(100, 30)
$form.Controls.Add($createButton)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 170)
$progressBar.Size = New-Object System.Drawing.Size(560, 20)
$progressBar.Visible = $false
$form.Controls.Add($progressBar)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready"
$statusLabel.Location = New-Object System.Drawing.Point(20, 200)
$statusLabel.Size = New-Object System.Drawing.Size(560, 20)
$statusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($statusLabel)

# Add event handlers
$createButton.Add_Click({
    if ($driveComboBox.SelectedIndex -eq -1) {
        $statusLabel.Text = "Please select a USB drive"
        return
    }
    
    $selectedDrive = $usbDrives[$driveComboBox.SelectedIndex]
    $targetDrive = $selectedDrive.DeviceID -replace "\\\\.\\PHYSICALDRIVE", ""
    $targetDrive = [char]([int]$targetDrive + 65) + ":"
    
    $isoPath = Join-Path $PSScriptRoot "ubuntu-22.04.3-desktop-amd64.iso"
    
    Get-UbuntuISO -IsoPath $isoPath -ProgressBar $progressBar -StatusLabel $statusLabel
    New-LiveUSB -IsoPath $isoPath -TargetDrive $targetDrive -ProgressBar $progressBar -StatusLabel $statusLabel
})

# Show the form
if (-not (Test-Administrator)) {
    [System.Windows.Forms.MessageBox]::Show("Please run this program as Administrator", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit 1
}

$form.ShowDialog() 