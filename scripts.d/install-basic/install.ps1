# install.ps1 - Hosted en GitHub raw
#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

# Colores y banner
function Write-Banner {
    $banner = @"
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║   Windows Server Quick Setup                             ║
║   Automated configuration tool                           ║
║                                                          ║
║   by Carlos Idevrik                                      ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
"@
    Write-Host $banner -ForegroundColor Cyan
}

function Write-Success { param($msg) Write-Host "✓ $msg" -ForegroundColor Green }
function Write-Info { param($msg) Write-Host "→ $msg" -ForegroundColor Yellow }
function Write-Error { param($msg) Write-Host "✗ $msg" -ForegroundColor Red }

# Verificar prerrequisitos
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Verificar Windows Server
    $os = Get-CimInstance Win32_OperatingSystem
    if ($os.Caption -notlike "*Server*") {
        Write-Error "This tool is designed for Windows Server"
        exit 1
    }
    
    # Verificar si es admin
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (!$isAdmin) {
        Write-Error "Please run as Administrator"
        exit 1
    }
    
    Write-Success "Prerequisites OK"
}

# Instalar winget si no está disponible
function Install-Winget {
    if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Info "Installing winget..."
        
        # Descargar e instalar App Installer
        $progressPreference = 'silentlyContinue'
        $latestWingetMsixBundleUri = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        
        $tempPath = [System.IO.Path]::GetTempPath()
        $installerPath = Join-Path $tempPath "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        
        Invoke-WebRequest -Uri $latestWingetMsixBundleUri -OutFile $installerPath
        Add-AppxPackage -Path $installerPath
        
        Write-Success "Winget installed"
    } else {
        Write-Success "Winget already available"
    }
}

# Configurar OpenSSH
function Setup-OpenSSH {
    Write-Info "Configuring OpenSSH Server..."
    
    # Instalar si no está
    $sshCapability = Get-WindowsCapability -Online -Name OpenSSH.Server*
    if ($sshCapability.State -ne 'Installed') {
        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    }
    
    # Iniciar y configurar
    Start-Service sshd -ErrorAction SilentlyContinue
    Set-Service -Name sshd -StartupType 'Automatic'
    
    Write-Success "OpenSSH configured"
}

# Configurar Firewall
function Setup-Firewall {
    Write-Info "Configuring Firewall for SSH..."
    
    # Eliminar reglas existentes
    Get-NetFirewallRule -DisplayName "*OpenSSH*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule
    
    # Crear regla correcta
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' `
        -DisplayName 'OpenSSH SSH Server (sshd)' `
        -Enabled True `
        -Direction Inbound `
        -Protocol TCP `
        -Action Allow `
        -LocalPort 22 `
        -Profile Any `
        -Program '%SystemRoot%\System32\OpenSSH\sshd.exe' | Out-Null
    
    Write-Success "Firewall configured"
}

# Instalar paquetes
function Install-Packages {
    Write-Info "Installing packages..."
    
    $packages = @(
        @{Id="Google.Chrome"; Name="Chrome"},
        @{Id="Mozilla.Firefox"; Name="Firefox"},
        @{Id="GoLang.Go"; Name="Go"},
        @{Id="Python.Python.3.12"; Name="Python 3.12"},
        @{Id="Git.Git"; Name="Git"}
    )
    
    foreach ($pkg in $packages) {
        Write-Info "Installing $($pkg.Name)..."
        winget install --id $pkg.Id --silent --accept-source-agreements --accept-package-agreements
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "$($pkg.Name) installed"
        } else {
            Write-Error "Failed to install $($pkg.Name)"
        }
    }
}

# Main
Write-Banner
Write-Host ""

Test-Prerequisites
Install-Winget
Setup-OpenSSH
Setup-Firewall
Install-Packages

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              Installation Complete! 🎉                   ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Success "SSH Server running on port 22"
Write-Success "Firewall configured"
Write-Success "Development tools installed"
Write-Host ""
Write-Info "You can now connect via SSH from Linux:"
Write-Host "  ssh Administrator@$(hostname)" -ForegroundColor Cyan
Write-Host ""