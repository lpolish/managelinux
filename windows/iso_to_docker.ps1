# ISO to Docker Converter for Windows
# This script converts Linux ISO images to Docker containers on Windows

param(
    [Parameter(Mandatory=$true)]
    [string]$IsoPath,
    
    [Parameter(Mandatory=$false)]
    [string]$DockerTag = "linux-iso"
)

# Function to check if Docker is installed
function Test-DockerInstallation {
    try {
        $dockerVersion = docker --version
        Write-Host "Docker is installed: $dockerVersion"
        return $true
    }
    catch {
        Write-Host "Docker is not installed or not in PATH"
        return $false
    }
}

# Function to check if 7-Zip is installed
function Test-7ZipInstallation {
    try {
        $7zipPath = "C:\Program Files\7-Zip\7z.exe"
        if (Test-Path $7zipPath) {
            Write-Host "7-Zip is installed"
            return $true
        }
        else {
            Write-Host "7-Zip is not installed"
            return $false
        }
    }
    catch {
        Write-Host "Error checking 7-Zip installation"
        return $false
    }
}

# Function to install 7-Zip
function Install-7Zip {
    Write-Host "Installing 7-Zip..."
    $downloadUrl = "https://www.7-zip.org/a/7z2301-x64.exe"
    $installerPath = "$env:TEMP\7zip-installer.exe"
    
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath
        Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
        Remove-Item $installerPath
        Write-Host "7-Zip installed successfully"
        return $true
    }
    catch {
        Write-Host "Failed to install 7-Zip: $_"
        return $false
    }
}

# Main script execution
Write-Host "ISO to Docker Converter for Windows"
Write-Host "=================================="

# Check if ISO file exists
if (-not (Test-Path $IsoPath)) {
    Write-Host "Error: ISO file not found at $IsoPath"
    exit 1
}

# Check Docker installation
if (-not (Test-DockerInstallation)) {
    Write-Host "Please install Docker Desktop for Windows first"
    Write-Host "Download from: https://www.docker.com/products/docker-desktop"
    exit 1
}

# Check and install 7-Zip if needed
if (-not (Test-7ZipInstallation)) {
    if (-not (Install-7Zip)) {
        Write-Host "Failed to install 7-Zip. Please install it manually from https://www.7-zip.org/"
        exit 1
    }
}

# Create temporary directory
$tempDir = Join-Path $env:TEMP "iso_to_docker_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir | Out-Null

try {
    Write-Host "Extracting ISO contents..."
    & "C:\Program Files\7-Zip\7z.exe" x $IsoPath -o"$tempDir" -y

    # Create Dockerfile
    $dockerfilePath = Join-Path $tempDir "Dockerfile"
    @"
FROM scratch
COPY . /
CMD ["/bin/bash"]
"@ | Out-File -FilePath $dockerfilePath -Encoding ASCII

    Write-Host "Building Docker image..."
    Set-Location $tempDir
    docker build -t $DockerTag .
    
    Write-Host "Docker image built successfully with tag: $DockerTag"
    Write-Host "You can now run the container using: docker run -it $DockerTag"
}
catch {
    Write-Host "Error during conversion: $_"
    exit 1
}
finally {
    # Cleanup
    Write-Host "Cleaning up temporary files..."
    Remove-Item -Path $tempDir -Recurse -Force
} 