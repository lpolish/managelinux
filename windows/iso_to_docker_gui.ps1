# ISO to Docker Converter GUI
# Part of Server Migration and Management Suite

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to check if Docker is installed
function Test-DockerInstallation {
    try {
        $dockerVersion = docker --version
        return $true
    }
    catch {
        return $false
    }
}

# Function to convert ISO to Docker
function Convert-ISOToDocker {
    param (
        [string]$IsoPath,
        [string]$DockerTag,
        [System.Windows.Forms.ProgressBar]$ProgressBar,
        [System.Windows.Forms.Label]$StatusLabel,
        [System.Windows.Forms.TextBox]$LogTextBox
    )
    
    # Verify ISO exists
    if (-not (Test-Path $IsoPath)) {
        $StatusLabel.Text = "Error: ISO file not found"
        return $false
    }
    
    # Create temp directory
    $tempDir = Join-Path $env:TEMP "iso_to_docker_$(Get-Random)"
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
    
    try {
        # Extract ISO
        $StatusLabel.Text = "Extracting ISO contents..."
        $ProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
        $ProgressBar.Visible = $true
        $LogTextBox.AppendText("Extracting ISO contents...`r`n")
        
        # Use 7-Zip to extract ISO
        $sevenZipPath = "C:\Program Files\7-Zip\7z.exe"
        if (-not (Test-Path $sevenZipPath)) {
            $StatusLabel.Text = "Installing 7-Zip..."
            $LogTextBox.AppendText("Installing 7-Zip...`r`n")
            
            # Download and install 7-Zip
            $sevenZipUrl = "https://www.7-zip.org/a/7z2301-x64.exe"
            $installerPath = Join-Path $env:TEMP "7z-installer.exe"
            Invoke-WebRequest -Uri $sevenZipUrl -OutFile $installerPath
            Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
            Remove-Item $installerPath
        }
        
        # Extract ISO
        & $sevenZipPath x $IsoPath -o"$tempDir" -y | Out-Null
        $LogTextBox.AppendText("ISO extraction completed`r`n")
        
        # Create Dockerfile
        $StatusLabel.Text = "Creating Dockerfile..."
        $LogTextBox.AppendText("Creating Dockerfile...`r`n")
        
        $dockerfilePath = Join-Path $tempDir "Dockerfile"
        @"
FROM scratch
COPY . /
CMD ["/bin/bash"]
"@ | Out-File -FilePath $dockerfilePath -Encoding ASCII
        
        # Build Docker image
        $StatusLabel.Text = "Building Docker image..."
        $LogTextBox.AppendText("Building Docker image...`r`n")
        
        Push-Location $tempDir
        docker build -t $DockerTag . 2>&1 | ForEach-Object {
            $LogTextBox.AppendText("$_`r`n")
            $LogTextBox.ScrollToCaret()
        }
        Pop-Location
        
        $StatusLabel.Text = "Docker image created successfully!"
        $LogTextBox.AppendText("Docker image created successfully!`r`n")
        return $true
    }
    catch {
        $StatusLabel.Text = "Error: $_"
        $LogTextBox.AppendText("Error: $_`r`n")
        return $false
    }
    finally {
        # Cleanup
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force
        }
        $ProgressBar.Visible = $false
    }
}

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "ISO to Docker Converter"
$form.Size = New-Object System.Drawing.Size(800, 600)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($PSCommandPath)

# Create controls
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "ISO to Docker Converter"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)
$titleLabel.Size = New-Object System.Drawing.Size(760, 30)
$titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($titleLabel)

# ISO File Selection
$isoLabel = New-Object System.Windows.Forms.Label
$isoLabel.Text = "ISO File:"
$isoLabel.Location = New-Object System.Drawing.Point(20, 70)
$isoLabel.Size = New-Object System.Drawing.Size(100, 20)
$form.Controls.Add($isoLabel)

$isoTextBox = New-Object System.Windows.Forms.TextBox
$isoTextBox.Location = New-Object System.Drawing.Point(130, 70)
$isoTextBox.Size = New-Object System.Drawing.Size(550, 20)
$form.Controls.Add($isoTextBox)

$isoButton = New-Object System.Windows.Forms.Button
$isoButton.Text = "Browse..."
$isoButton.Location = New-Object System.Drawing.Point(690, 70)
$isoButton.Size = New-Object System.Drawing.Size(80, 23)
$form.Controls.Add($isoButton)

# Docker Tag
$tagLabel = New-Object System.Windows.Forms.Label
$tagLabel.Text = "Docker Tag:"
$tagLabel.Location = New-Object System.Drawing.Point(20, 100)
$tagLabel.Size = New-Object System.Drawing.Size(100, 20)
$form.Controls.Add($tagLabel)

$tagTextBox = New-Object System.Windows.Forms.TextBox
$tagTextBox.Location = New-Object System.Drawing.Point(130, 100)
$tagTextBox.Size = New-Object System.Drawing.Size(550, 20)
$tagTextBox.Text = "ubuntu-custom:latest"
$form.Controls.Add($tagTextBox)

# Convert Button
$convertButton = New-Object System.Windows.Forms.Button
$convertButton.Text = "Convert to Docker Image"
$convertButton.Location = New-Object System.Drawing.Point(350, 140)
$convertButton.Size = New-Object System.Drawing.Size(150, 30)
$form.Controls.Add($convertButton)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 190)
$progressBar.Size = New-Object System.Drawing.Size(760, 20)
$progressBar.Visible = $false
$form.Controls.Add($progressBar)

# Status Label
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready"
$statusLabel.Location = New-Object System.Drawing.Point(20, 220)
$statusLabel.Size = New-Object System.Drawing.Size(760, 20)
$statusLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($statusLabel)

# Log TextBox
$logTextBox = New-Object System.Windows.Forms.TextBox
$logTextBox.Multiline = $true
$logTextBox.ScrollBars = "Vertical"
$logTextBox.Location = New-Object System.Drawing.Point(20, 250)
$logTextBox.Size = New-Object System.Drawing.Size(760, 300)
$logTextBox.ReadOnly = $true
$form.Controls.Add($logTextBox)

# Add event handlers
$isoButton.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "ISO Files (*.iso)|*.iso|All Files (*.*)|*.*"
    $openFileDialog.Title = "Select ISO File"
    
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $isoTextBox.Text = $openFileDialog.FileName
    }
})

$convertButton.Add_Click({
    if ([string]::IsNullOrWhiteSpace($isoTextBox.Text)) {
        $statusLabel.Text = "Please select an ISO file"
        return
    }
    
    if ([string]::IsNullOrWhiteSpace($tagTextBox.Text)) {
        $statusLabel.Text = "Please enter a Docker tag"
        return
    }
    
    $logTextBox.Clear()
    Convert-ISOToDocker -IsoPath $isoTextBox.Text -DockerTag $tagTextBox.Text -ProgressBar $progressBar -StatusLabel $statusLabel -LogTextBox $logTextBox
})

# Show the form
if (-not (Test-Administrator)) {
    [System.Windows.Forms.MessageBox]::Show("Please run this program as Administrator", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit 1
}

if (-not (Test-DockerInstallation)) {
    [System.Windows.Forms.MessageBox]::Show("Docker is not installed. Please install Docker Desktop for Windows first.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit 1
}

$form.ShowDialog() 