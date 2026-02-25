# install.ps1 - Universal Windows Setup
#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

# Configuración global
$Script:IsServer = $false
$Script:OSVersion = ""
$Script:OSName = ""
$Script:OSType = ""  # "WindowsServer", "Windows11", "Windows10"

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
        $Script:OSType = "Windows11"
        return "Windows 11"
    } elseif ($os.Caption -like "*Windows 10*") {
        $Script:OSType = "Windows10"
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

# Verificar si un programa está instalado
function Test-ProgramInstalled {
    param(
        [string]$ProgramId,
        [string]$VerifyCommand = "",
        [string]$ExecutableName = ""
    )
    
    # Primero buscar el ejecutable en rutas estándar
    if ($ExecutableName) {
        $possiblePaths = @(
            "C:\Program Files\$ExecutableName",
            "C:\Program Files (x86)\$ExecutableName",
            "$env:USERPROFILE\AppData\Local\Programs\$ExecutableName",
            "C:\$ExecutableName"
        )
        
        foreach ($path in $possiblePaths) {
            if (Test-Path "$path\*.exe" -ErrorAction SilentlyContinue) {
                return $true
            }
        }
    }
    
    # Si hay comando de verificación, usarlo
    if ($VerifyCommand) {
        try {
            $result = & cmd.exe /c $VerifyCommand 2>&1
            if ($LASTEXITCODE -eq 0) { return $true }
        } catch {
            return $false
        }
    }
    
    # Alternativa: buscar en registro de Windows
    try {
        $installed = Get-ChildItem -Path @(
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
        ) -ErrorAction SilentlyContinue | 
        Get-ItemProperty | 
        Where-Object { $_.DisplayName -match $ProgramId }
        
        return $null -ne $installed
    } catch {
        return $false
    }
}

# Actualizar PATH del usuario
function Update-EnvironmentPath {
    Write-Info "Refreshing Environment PATH..."
    
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    # Rutas comunes que winget puede usar
    $commonPaths = @(
        "C:\Program Files\Git\cmd",
        "C:\Program Files\Git\bin",
        "C:\Program Files\Go\bin",
        "C:\Users\$env:USERNAME\AppData\Local\Microsoft\WindowsApps",
        "$env:USERPROFILE\AppData\Local\Programs\Python\Python312",
        "$env:USERPROFILE\AppData\Local\Programs\Python\Python312\Scripts"
    )
    
    foreach ($path in $commonPaths) {
        if ((Test-Path $path) -and ($env:Path -notlike "*$path*")) {
            $env:Path += ";$path"
        }
    }
    
    Write-Success "PATH updated in current session"
}

# Permitir seleccionar paquetes manualmente
function Show-PackageSelector {
    param(
        [array]$PackageList,
        [string]$Category
    )
    
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║ $Category" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    for ($i = 0; $i -lt $PackageList.Count; $i++) {
        $critical = if ($PackageList[$i].Critical) { " [CRITICAL]" } else { "" }
        Write-Host "  [$($i+1)] $($PackageList[$i].Name)$critical"
    }
    
    Write-Host ""
    Write-Host "  [A] Install All"
    Write-Host "  [S] Skip All"
}

# Permitir preferencias interactivas
function Get-InstallPreferences {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║ Installation Preferences                                 ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Quick Options:"
    Write-Host "  [1] Full Installation (all packages)"
    Write-Host "  [2] Essential Only (Git, Python, Go)"
    Write-Host "  [3] Custom Selection"
    Write-Host "  [4] Show installed packages and exit"
    Write-Host ""
    
    $choice = Read-Host "Select option (1-4, default: 1)"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }
    
    return $choice
}

# Instalar paquetes según plataforma
function Install-Packages {
    param(
        [array]$Packages = $null
    )
    
    # Si no se proporcionan paquetes, compilar lista según OS específico
    if ($null -eq $Packages -or $Packages -eq "FULL") {
        Write-Info "Building package list for: $Script:OSName"
        
        # ==================== PAQUETES COMUNES PARA TODAS LAS PLATAFORMAS ====================
        $commonPackages = @(
            @{
                Id="Git.Git"
                Name="Git"
                VerifyCommand="git --version"
                ExecutableName="git.exe"
                Critical=$true
            },
            @{
                Id="GoLang.Go"
                Name="Go"
                VerifyCommand="go version"
                ExecutableName="go.exe"
                Critical=$false
            },
            @{
                Id="Python.Python.3.12"
                Name="Python 3.12"
                VerifyCommand="python --version"
                ExecutableName="python.exe"
                Critical=$false
            }
        )
        
        # ==================== PAQUETES ESPECÍFICOS DE WINDOWS SERVER ====================
        # Los servidores necesitan herramientas de desarrollo y navegadores para actualizaciones
        if ($Script:IsServer) {
            Write-Info "Detected Windows Server - installing server tools"
            
            $specificPackages = @(
                @{
                    Id="Google.Chrome"
                    Name="Chrome"
                    VerifyCommand="chrome --version"
                    ExecutableName="chrome.exe"
                    Critical=$false
                },
                @{
                    Id="Mozilla.Firefox"
                    Name="Firefox"
                    VerifyCommand="firefox --version"
                    ExecutableName="firefox.exe"
                    Critical=$false
                },
                @{
                    Id="Microsoft.VisualStudioCode"
                    Name="VS Code"
                    VerifyCommand="code --version"
                    ExecutableName="code.exe"
                    Critical=$false
                },
                @{
                    Id="Microsoft.PowerShell"
                    Name="PowerShell 7"
                    VerifyCommand="pwsh --version"
                    ExecutableName="pwsh.exe"
                    Critical=$false
                }
            )
        }
        # ==================== PAQUETES ESPECÍFICOS DE WINDOWS 11 ====================
        elseif ($Script:OSType -eq "Windows11") {
            Write-Info "Detected Windows 11 - installing desktop and modern tools"
            
            $specificPackages = @(
                @{
                    Id="Microsoft.WindowsTerminal"
                    Name="Windows Terminal"
                    VerifyCommand="wt.exe --version"
                    ExecutableName="wt.exe"
                    Critical=$false
                },
                @{
                    Id="Microsoft.PowerToys"
                    Name="PowerToys"
                    VerifyCommand=""
                    ExecutableName="PowerToys.exe"
                    Critical=$false
                },
                @{
                    Id="Microsoft.VisualStudioCode"
                    Name="VS Code"
                    VerifyCommand="code --version"
                    ExecutableName="code.exe"
                    Critical=$false
                },
                @{
                    Id="Google.Chrome"
                    Name="Chrome"
                    VerifyCommand="chrome --version"
                    ExecutableName="chrome.exe"
                    Critical=$false
                },
                @{
                    Id="Mozilla.Firefox"
                    Name="Firefox"
                    VerifyCommand="firefox --version"
                    ExecutableName="firefox.exe"
                    Critical=$false
                }
            )
        }
        # ==================== PAQUETES ESPECÍFICOS DE WINDOWS 10 ====================
        elseif ($Script:OSType -eq "Windows10") {
            Write-Info "Detected Windows 10 - installing compatible tools"
            
            $specificPackages = @(
                @{
                    Id="Microsoft.VisualStudioCode"
                    Name="VS Code"
                    VerifyCommand="code --version"
                    ExecutableName="code.exe"
                    Critical=$false
                },
                @{
                    Id="Google.Chrome"
                    Name="Chrome"
                    VerifyCommand="chrome --version"
                    ExecutableName="chrome.exe"
                    Critical=$false
                },
                @{
                    Id="Mozilla.Firefox"
                    Name="Firefox"
                    VerifyCommand="firefox --version"
                    ExecutableName="firefox.exe"
                    Critical=$false
                },
                @{
                    Id="Microsoft.PowerShell"
                    Name="PowerShell 7"
                    VerifyCommand="pwsh --version"
                    ExecutableName="pwsh.exe"
                    Critical=$false
                }
            )
        }
        else {
            Write-Warning "Unknown OS type, using common packages only"
            $specificPackages = @()
        }
        
        $Packages = $commonPackages + $specificPackages
    }
    
    Write-Host ""
    Write-Info "Package list prepared: $($Packages.Count) packages to process"
    
    # Contadores
    $results = @{
        Success = @()
        Failed = @()
        Skipped = @()
        VerificationFailed = @()
    }
    
    # Instalar cada paquete
    foreach ($pkg in $Packages) {
        $maxRetries = 2
        $attempt = 1
        $installed = $false
        
        while ($attempt -le $maxRetries -and -not $installed) {
            if ($attempt -gt 1) {
                Write-Host "  Retry $attempt/$maxRetries..." -ForegroundColor Yellow
            }
            
            Write-Host "→ Installing $($pkg.Name)..." -ForegroundColor Yellow -NoNewline
            
            try {
                # Ejecutar winget install
                $output = & winget install --id $pkg.Id --silent --accept-source-agreements --accept-package-agreements --force 2>&1
                $exitCode = $LASTEXITCODE
                
                # Wait más largo para permitir que se complete la instalación
                Write-Host " (waiting...)" -ForegroundColor Gray -NoNewline
                Start-Sleep -Seconds 4
                
                # Limpiar PATH y verificar
                Update-EnvironmentPath
                
                # Verificar si se instaló
                $installed = Test-ProgramInstalled -ProgramId $pkg.Id -VerifyCommand $pkg.VerifyCommand -ExecutableName $pkg.ExecutableName
                
                if ($installed) {
                    Write-Host " ✓" -ForegroundColor Green
                    Write-Success "  → $($pkg.Name) confirmed installed"
                    $results.Success += $pkg.Name
                    break
                } else {
                    if ($attempt -lt $maxRetries) {
                        Write-Host " ⚠" -ForegroundColor Yellow
                        Write-Warning "  → Installation not confirmed, retrying..."
                    }
                }
            } catch {
                Write-Host " ✗" -ForegroundColor Red
                Write-Error "  → Error: $_"
            }
            
            $attempt++
        }
        
        # Si no se instaló después de reintentos
        if (-not $installed) {
            Write-Host "✗" -ForegroundColor Red
            Write-Error "  → Failed to install $($pkg.Name) after $maxRetries attempts"
            
            # Intentar verificar si simplemente el comando no funciona pero está instalado
            try {
                $regCheck = Get-ChildItem -Path @(
                    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
                    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
                    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
                ) -ErrorAction SilentlyContinue | 
                Get-ItemProperty | 
                Where-Object { $_.DisplayName -match $pkg.Id -or $_.DisplayName -match $pkg.Name }
                
                if ($regCheck) {
                    Write-Warning "  → Found in registry but command verification failed. Needs PATH refresh or restart."
                    $results.VerificationFailed += $pkg.Name
                } else {
                    if ($pkg.Critical) {
                        $results.Failed += $pkg.Name
                    } else {
                        $results.Skipped += $pkg.Name
                    }
                }
            } catch {
                if ($pkg.Critical) {
                    $results.Failed += $pkg.Name
                } else {
                    $results.Skipped += $pkg.Name
                }
            }
        }
    }
    
    # Mostrar resumen
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           Installation Summary ($($Script:OSName))     ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    if ($results.Success.Count -gt 0) {
        Write-Success "Verified installed ($($results.Success.Count)):"
        $results.Success | ForEach-Object { Write-Host "  ✓ $_" -ForegroundColor Green }
    }
    
    if ($results.VerificationFailed.Count -gt 0) {
        Write-Warning "Installed but command failed ($($results.VerificationFailed.Count)):"
        $results.VerificationFailed | ForEach-Object { Write-Host "  ⚠ $_" -ForegroundColor DarkYellow }
        Write-Info "  These may work after restarting PowerShell"
    }
    
    if ($results.Failed.Count -gt 0) {
        Write-Error "Failed to install (CRITICAL) ($($results.Failed.Count)):"
        $results.Failed | ForEach-Object { Write-Host "  ✗ $_" -ForegroundColor Red }
        Write-Warning "Some critical packages failed. Solutions:"
        Write-Host "  1. Check: https://www.winget.run" -ForegroundColor Yellow
        Write-Host "  2. Manual: https://git-scm.com/download/win" -ForegroundColor Yellow
    }
    
    if ($results.Skipped.Count -gt 0) {
        Write-Warning "Skipped ($($results.Skipped.Count)):"
        $results.Skipped | ForEach-Object { Write-Host "  ⚠ $_" -ForegroundColor DarkYellow }
    }
    
    Write-Host ""
    return $results
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
    Write-Host ""
    
    Setup-OpenSSH
    Write-Host ""
    
    Setup-Firewall
    Write-Host ""
    
    # Obtener preferencias del usuario
    $preference = Get-InstallPreferences
    
    Write-Host ""
    
    # Instalar paquetes según preferencia
    switch ($preference) {
        "4" {
            # Mostrar paquetes ya instalados
            Write-Info "Checking installed programs..."
            Write-Host ""
            
            # Programas comunes a verificar
            $checkPrograms = @(
                @{Name="Git"; Command="git --version"},
                @{Name="Python"; Command="python --version"},
                @{Name="Go"; Command="go version"},
                @{Name="Node.js"; Command="node --version"},
                @{Name="VS Code"; Command="code --version"}
            )
            
            foreach ($prog in $checkPrograms) {
                if (Get-Command $prog.Command.Split()[0] -ErrorAction SilentlyContinue) {
                    $version = & cmd.exe /c $prog.Command 2>&1
                    Write-Success "$($prog.Name): $version"
                } else {
                    Write-Warning "$($prog.Name): Not installed"
                }
            }
            Write-Host ""
            exit 0
        }
        
        "2" {
            # Solo esenciales (Git, Python, Go)
            Write-Info "Installing Essential packages only (Git, Python, Go)..."
            
            # Crear lista simple con solo esenciales
            $packagesToInstall = @(
                @{
                    Id="Git.Git"
                    Name="Git"
                    VerifyCommand="git --version"
                    ExecutableName="git.exe"
                    Critical=$true
                },
                @{
                    Id="Python.Python.3.12"
                    Name="Python 3.12"
                    VerifyCommand="python --version"
                    ExecutableName="python.exe"
                    Critical=$true
                },
                @{
                    Id="GoLang.Go"
                    Name="Go"
                    VerifyCommand="go version"
                    ExecutableName="go.exe"
                    Critical=$true
                }
            )
        }
        
        "3" {
            # Custom selection
            Write-Info "Custom package selection mode"
            Write-Host ""
            Write-Warning "Current system: $Script:OSName"
            Write-Warning "Script will install platform-specific packages."
            Write-Host ""
            
            # Let Install-Packages handle platform determination
            $packagesToInstall = "FULL"
        }
        
        default {
            # Full installation (opción por defecto)
            Write-Info "Full Installation mode selected"
            Write-Host "Platform: $Script:OSName"
            
            # Let Install-Packages handle everything based on OS type
            $packagesToInstall = "FULL"
        }
    }
    
    # Instalar paquetes si no es el caso de salida
    if ($preference -ne "4") {
        $installResults = Install-Packages -Packages $packagesToInstall
        
        # Actualizar PATH final
        Update-EnvironmentPath
        
        # Configuraciones específicas por plataforma
        if ($Script:IsServer) {
            Configure-ServerSpecific
        } else {
            Configure-DesktopSpecific
        }
        
        # Resumen final mejorado
        Write-Host ""
        Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║              Installation Complete! 🎉                   ║" -ForegroundColor Green
        Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        Write-Success "Platform: $osType"
        Write-Success "SSH Server: Running on port 22"
        Write-Success "Firewall: Configured for SSH"
        Write-Success "Total successfully verified: $($installResults.Success.Count)"
        
        if ($installResults.VerificationFailed.Count -gt 0) {
            Write-Warning "Found in Registry but not verified: $($installResults.VerificationFailed.Count)"
        }
        
        if ($installResults.Failed.Count -gt 0) {
            Write-Error "Failed packages: $($installResults.Failed.Count)"
        }
        
        Write-Host ""
        Write-Success "Verification Results:"
        Write-Host ""
        
        # Git
        $gitCmd = "git --version" 
        if (Get-Command git -ErrorAction SilentlyContinue) {
            try {
                $gitVersion = & cmd.exe /c $gitCmd 2>&1
                Write-Host "  ✓ Git: $gitVersion" -ForegroundColor Green
            } catch {
                Write-Host "  ⚠ Git found in registry but cmd failed (needs restart)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  ✗ Git: NOT FOUND IN PATH" -ForegroundColor Red
            Write-Warning "    Install manually from: https://git-scm.com/download/win"
        }
        
        # Python
        if (Get-Command python -ErrorAction SilentlyContinue) {
            try {
                $pythonVersion = & cmd.exe /c "python --version" 2>&1
                Write-Host "  ✓ Python: $pythonVersion" -ForegroundColor Green
            } catch {
                Write-Host "  ⚠ Python found but cmd failed" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  ? Python: Not in PATH (check if installed)" -ForegroundColor Yellow
        }
        
        # Go
        if (Get-Command go -ErrorAction SilentlyContinue) {
            try {
                $goVersion = & cmd.exe /c "go version" 2>&1
                Write-Host "  ✓ Go: $goVersion" -ForegroundColor Green
            } catch {
                Write-Host "  ⚠ Go found but cmd failed" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  ? Go: Not in PATH (check if installed)" -ForegroundColor Yellow
        }
        
        Write-Host ""
        
        if ($Script:IsServer) {
            Write-Info "Server-specific configurations applied"
        } else {
            Write-Info "Desktop-specific configurations applied"
        }
        
        Write-Host ""
        Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║           Next Steps                                     ║" -ForegroundColor Cyan
        Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "1. Restart PowerShell/Terminal:" -ForegroundColor Cyan
        Write-Host "   Close this terminal and open a NEW one for full PATH refresh" -ForegroundColor Gray
        Write-Host ""
        
        Write-Host "2. Verify installation:" -ForegroundColor Cyan
        Write-Host "   git --version" -ForegroundColor DarkCyan
        Write-Host "   python --version" -ForegroundColor DarkCyan
        Write-Host "   go version" -ForegroundColor DarkCyan
        Write-Host ""
        
        Write-Host "3. SSH Connection:" -ForegroundColor Cyan
        Write-Host "   ssh $env:USERNAME@$env:COMPUTERNAME" -ForegroundColor DarkCyan
        Write-Host ""
        
        if ($installResults.Failed.Count -gt 0 -or $installResults.VerificationFailed.Count -gt 0) {
            Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
            Write-Host "║           Troubleshooting                                 ║" -ForegroundColor Yellow
            Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
            Write-Host ""
            
            if ($installResults.Failed.Count -gt 0) {
                Write-Warning "Critical packages not installed:"
                $installResults.Failed | ForEach-Object {
                    Write-Host "  • $_" -ForegroundColor Red
                }
                Write-Host ""
                Write-Host "  Options:" -ForegroundColor Yellow
                Write-Host "    1. Run: winget install --id Git.Git --force" -ForegroundColor DarkYellow
                Write-Host "    2. Manual download: https://www.winget.run" -ForegroundColor DarkYellow
                Write-Host "    3. Direct links:" -ForegroundColor DarkYellow
                Write-Host "       • Git: https://git-scm.com/download/win" -ForegroundColor DarkYellow
                Write-Host "       • Python: https://www.python.org/downloads" -ForegroundColor DarkYellow
                Write-Host "       • Go: https://golang.org/dl" -ForegroundColor DarkYellow
            }
            
            if ($installResults.VerificationFailed.Count -gt 0) {
                Write-Warning "Found in registry but command failed:"
                $installResults.VerificationFailed | ForEach-Object {
                    Write-Host "  • $_" -ForegroundColor Yellow
                }
                Write-Host ""
                Write-Host "  → Restart PowerShell and try: git --version" -ForegroundColor Yellow
            }
            Write-Host ""
        }
    }
        
} catch {
    Write-Host ""
    Write-Error "Installation failed: $_"
    Write-Host ""
    exit 1
}