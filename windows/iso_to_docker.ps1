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
        Write-Host "Docker is installed: $dockerVersion" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Docker is not installed or not in PATH" -ForegroundColor Red
        return $false
    }
}

# Function to check if 7-Zip is installed
function Test-7ZipInstallation {
    try {
        $7zipPath = "C:\Program Files\7-Zip\7z.exe"
        if (Test-Path $7zipPath) {
            Write-Host "7-Zip is installed" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "7-Zip is not installed" -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "Error checking 7-Zip installation: $_" -ForegroundColor Red
        return $false
    }
}

# Function to install 7-Zip
function Install-7Zip {
    Write-Host "Installing 7-Zip..." -ForegroundColor Yellow
    $downloadUrl = "https://www.7-zip.org/a/7z2301-x64.exe"
    $installerPath = "$env:TEMP\7zip-installer.exe"
    
    try {
        $progressPreference = 'silentlyContinue'
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath
        $process = Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Remove-Item $installerPath
            Write-Host "7-Zip installed successfully" -ForegroundColor Green
            return $true
        } else {
            Write-Host "7-Zip installation failed with exit code: $($process.ExitCode)" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "Failed to install 7-Zip: $_" -ForegroundColor Red
        return $false
    }
}

# Main script execution
try {
    Write-Host "ISO to Docker Converter for Windows" -ForegroundColor Blue
    Write-Host "==================================" -ForegroundColor Blue

    # Check if ISO file exists
    if (-not (Test-Path $IsoPath)) {
        Write-Host "Error: ISO file not found at $IsoPath" -ForegroundColor Red
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }

    # Check Docker installation
    if (-not (Test-DockerInstallation)) {
        Write-Host "Please install Docker Desktop for Windows first" -ForegroundColor Red
        Write-Host "Download from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }

    # Check and install 7-Zip if needed
    if (-not (Test-7ZipInstallation)) {
        if (-not (Install-7Zip)) {
            Write-Host "Failed to install 7-Zip. Please install it manually from https://www.7-zip.org/" -ForegroundColor Red
            Write-Host "Press any key to exit..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            exit 1
        }
    }

    # Create temporary directory
    $tempDir = Join-Path $env:TEMP "iso_to_docker_$(Get-Random)"
    New-Item -ItemType Directory -Path $tempDir | Out-Null

    try {
        Write-Host "Extracting ISO contents..." -ForegroundColor Yellow
        $process = Start-Process -FilePath "C:\Program Files\7-Zip\7z.exe" -ArgumentList "x `"$IsoPath`" -o`"$tempDir`" -y" -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -ne 0) {
            throw "7-Zip extraction failed with exit code: $($process.ExitCode)"
        }

        # Create Dockerfile
        $dockerfilePath = Join-Path $tempDir "Dockerfile"
        @"
FROM scratch
COPY . /
CMD ["/bin/bash"]
"@ | Out-File -FilePath $dockerfilePath -Encoding ASCII

        Write-Host "Building Docker image..." -ForegroundColor Yellow
        Set-Location $tempDir
        $process = Start-Process -FilePath "docker" -ArgumentList "build -t $DockerTag ." -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Write-Host "Docker image built successfully with tag: $DockerTag" -ForegroundColor Green
            Write-Host "You can now run the container using: docker run -it $DockerTag" -ForegroundColor Green
        } else {
            throw "Docker build failed with exit code: $($process.ExitCode)"
        }
    }
    catch {
        Write-Host "Error during conversion: $_" -ForegroundColor Red
        exit 1
    }
    finally {
        # Cleanup
        Write-Host "Cleaning up temporary files..." -ForegroundColor Yellow
        Remove-Item -Path $tempDir -Recurse -Force
    }
}
catch {
    Write-Host "An unexpected error occurred: $_" -ForegroundColor Red
}
finally {
    Write-Host "`nPress any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} 