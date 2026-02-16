# install.ps1 - Universal Windows Setup
#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

# Configuración global
$Script:IsServer = $false
$Script:OSVersion = ""
$Script:OSName = ""

# Colores y banner
function Write-Banner {
    param([string]$OSType)
    
    $banner = @"
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║   Windows Quick Setup - $OSType                    
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
function Write-Warning { param($msg) Write-Host "⚠ $msg" -ForegroundColor DarkYellow }

# Detectar tipo de sistema operativo
function Get-SystemType {
    $os = Get-CimInstance Win32_OperatingSystem
    $Script:OSName = $os.Caption
    $Script:OSVersion = $os.Version
    
    if ($os.Caption -like "*Server*") {
        $Script:IsServer = $true
        return "Windows Server"
    } elseif ($os.Caption -like "*Windows 11*") {
        return "Windows 11"
    } elseif ($os.Caption -like "*Windows 10*") {
        return "Windows 10"
    } else {
        return "Windows (Unknown)"
    }
}

# Verificar prerrequisitos
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    $osType = Get-SystemType
    Write-Success "Detected: $osType ($OSVersion)"
    
    # Verificar si es admin
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (!$isAdmin) {
        Write-Error "Please run as Administrator"
        exit 1
    }
    
    Write-Success "Running with Administrator privileges"
    return $osType
}

# Instalar winget si no está disponible
function Install-Winget {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Success "Winget already available"
        return
    }
    
    Write-Info "Installing winget..."
    
    try {
        # Método para Windows 11/10
        if (!$Script:IsServer) {
            # Intentar actualizar desde Microsoft Store
            Write-Info "Updating App Installer from Microsoft Store..."
            winget source update
        }
        
        # Método manual (funciona en ambos)
        $progressPreference = 'silentlyContinue'
        
        # Descargar VCLibs
        Write-Info "Downloading dependencies..."
        $vcLibsUrl = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
        $vcLibsPath = "$env:TEMP\Microsoft.VCLibs.x64.14.00.Desktop.appx"
        Invoke-WebRequest -Uri $vcLibsUrl -OutFile $vcLibsPath
        Add-AppxPackage -Path $vcLibsPath
        
        # Descargar UI.Xaml
        $uiXamlUrl = "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx"
        $uiXamlPath = "$env:TEMP\Microsoft.UI.Xaml.2.8.x64.appx"
        Invoke-WebRequest -Uri $uiXamlUrl -OutFile $uiXamlPath
        Add-AppxPackage -Path $uiXamlPath
        
        # Descargar winget
        $wingetUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        $wingetPath = "$env:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        Invoke-WebRequest -Uri $wingetUrl -OutFile $wingetPath
        Add-AppxPackage -Path $wingetPath
        
        Write-Success "Winget installed successfully"
    } catch {
        Write-Warning "Could not install winget automatically. Some packages may need manual installation."
    }
}

# Configurar OpenSSH
function Setup-OpenSSH {
    Write-Info "Configuring OpenSSH Server..."
    
    try {
        # Método para Windows Server
        if ($Script:IsServer) {
            $sshCapability = Get-WindowsCapability -Online -Name OpenSSH.Server*
            if ($sshCapability.State -ne 'Installed') {
                Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
            }
        } else {
            # Método para Windows 10/11
            $sshFeature = Get-WindowsCapability -Online -Name OpenSSH.Server*
            if ($sshFeature.State -ne 'Installed') {
                Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
            }
        }
        
        # Iniciar y configurar (común para ambos)
        Start-Service sshd -ErrorAction SilentlyContinue
        Set-Service -Name sshd -StartupType 'Automatic'
        
        # Configurar shell por defecto a PowerShell
        New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force | Out-Null
        
        Write-Success "OpenSSH Server configured and running"
    } catch {
        Write-Warning "OpenSSH installation encountered issues: $_"
    }
}

# Configurar Firewall
function Setup-Firewall {
    Write-Info "Configuring Firewall for SSH..."
    
    try {
        # Eliminar reglas existentes
        Get-NetFirewallRule -DisplayName "*OpenSSH*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule
        
        # Crear regla correcta para SSH
        New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' `
            -DisplayName 'OpenSSH SSH Server (sshd)' `
            -Enabled True `
            -Direction Inbound `
            -Protocol TCP `
            -Action Allow `
            -LocalPort 22 `
            -Profile Any `
            -Program '%SystemRoot%\System32\OpenSSH\sshd.exe' | Out-Null
        
        Write-Success "Firewall configured for SSH"
    } catch {
        Write-Warning "Firewall configuration failed: $_"
    }
}

# Instalar paquetes según plataforma
function Install-Packages {
    Write-Info "Installing packages for your system..."
    
    # Paquetes comunes para ambas plataformas
    $commonPackages = @(
        @{Id="Git.Git"; Name="Git"},
        @{Id="GoLang.Go"; Name="Go"},
        @{Id="Python.Python.3.12"; Name="Python 3.12"}
    )
    
    # Paquetes específicos de Windows Server
    $serverPackages = @(
        @{Id="Google.Chrome"; Name="Chrome"},
        @{Id="Mozilla.Firefox"; Name="Firefox"},
        @{Id="Microsoft.VisualStudioCode"; Name="VS Code"},
        @{Id="Microsoft.PowerShell"; Name="PowerShell 7"}
    )
    
    # Paquetes específicos de Windows 10/11
    $desktopPackages = @(
        @{Id="Microsoft.WindowsTerminal"; Name="Windows Terminal"},
        @{Id="Microsoft.PowerToys"; Name="PowerToys"},
        @{Id="Microsoft.VisualStudioCode"; Name="VS Code"}
    )
    
    # Seleccionar paquetes según plataforma
    $packagesToInstall = $commonPackages
    
    if ($Script:IsServer) {
        Write-Info "Installing server-specific packages..."
        $packagesToInstall += $serverPackages
    } else {
        Write-Info "Installing desktop-specific packages..."
        $packagesToInstall += $desktopPackages
    }
    
    # Instalar cada paquete
    foreach ($pkg in $packagesToInstall) {
        Write-Info "Installing $($pkg.Name)..."
        
        try {
            winget install --id $pkg.Id --silent --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "$($pkg.Name) installed"
            } else {
                Write-Warning "$($pkg.Name) may already be installed or encountered an issue"
            }
        } catch {
            Write-Warning "Could not install $($pkg.Name): $_"
        }
    }
}

# Configuraciones específicas de Windows Server
function Configure-ServerSpecific {
    Write-Info "Applying Windows Server specific configurations..."
    
    # Deshabilitar IE Enhanced Security Configuration (molesto para servers)
    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0
        Write-Success "IE Enhanced Security disabled"
    } catch {
        Write-Warning "Could not disable IE Enhanced Security"
    }
    
    # Configurar Server Manager para no iniciar automáticamente
    try {
        Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask | Out-Null
        Write-Success "Server Manager auto-start disabled"
    } catch {
        Write-Warning "Could not disable Server Manager auto-start"
    }
}

# Configuraciones específicas de Windows 10/11
function Configure-DesktopSpecific {
    Write-Info "Applying Windows desktop specific configurations..."
    
    # Configurar Developer Mode (facilita desarrollo)
    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Value 1
        Write-Success "Developer Mode enabled"
    } catch {
        Write-Warning "Could not enable Developer Mode"
    }
}

# Main
$osType = ""
try {
    $osType = Test-Prerequisites
    Write-Banner $osType
    Write-Host ""
    
    Install-Winget
    Setup-OpenSSH
    Setup-Firewall
    Install-Packages
    
    # Configuraciones específicas por plataforma
    if ($Script:IsServer) {
        Configure-ServerSpecific
    } else {
        Configure-DesktopSpecific
    }
    
    # Resumen final
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║              Installation Complete! 🎉                   ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Success "Platform: $osType"
    Write-Success "SSH Server: Running on port 22"
    Write-Success "Firewall: Configured"
    Write-Success "Development tools: Installed"
    Write-Host ""
    
    if ($Script:IsServer) {
        Write-Info "Server-specific configurations applied"
    } else {
        Write-Info "Desktop-specific configurations applied"
    }
    
    Write-Host ""
    Write-Info "You can now connect via SSH:"
    Write-Host "  ssh $env:USERNAME@$env:COMPUTERNAME" -ForegroundColor Cyan
    Write-Host ""
    Write-Info "Restart your terminal to use newly installed tools"
    
} catch {
    Write-Host ""
    Write-Error "Installation failed: $_"
    Write-Host ""
    exit 1
}