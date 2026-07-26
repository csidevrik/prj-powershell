# install.ps1 - Universal Windows Setup (MEJORADO)
#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

# Configuración global
$Script:IsServer = $false
$Script:OSVersion = ""
$Script:OSName = ""
$Script:OSType = ""

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

# ============================================================================
# MEJORA 1: Spinner para mostrar progreso durante operaciones largas
# ============================================================================
function Start-Spinner {
    param(
        [string]$Message,
        [scriptblock]$ScriptBlock
    )

    Write-Host "→ $Message" -ForegroundColor Yellow -NoNewline

    $spinner = @('◐', '◓', '◑', '◒')
    $job = Start-Job -ScriptBlock $ScriptBlock
    $i = 0

    while ($job.State -eq 'Running') {
        Write-Host "`b$($spinner[$i % 4])" -NoNewline
        Start-Sleep -Milliseconds 500
        $i++
    }

    $result = Receive-Job -Job $job
    Remove-Job -Job $job

    Write-Host "`b✓" -ForegroundColor Green
    return $result
}

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
    Write-Success "Detected: $osType ($Script:OSVersion)"

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

# ============================================================================
# MEJORA 2: Setup-OpenSSH Simplificado y Optimizado
# ============================================================================
function Setup-OpenSSH {
    Write-Info "Configuring OpenSSH Server..."

    try {
        # MEJORA: Verificar si ya está instalado ANTES de hacer nada
        $sshFeature = Get-WindowsCapability -Online -Name "OpenSSH.Server*" -ErrorAction SilentlyContinue

        if ($sshFeature.State -eq 'Installed') {
            Write-Success "OpenSSH Server already installed, skipping..."
        } else {
            Write-Warning "OpenSSH Server installation will take 15-20 minutes (FOD package download + OS patching)"
            Write-Info "Progress spinner active - do not interrupt"

            # MEJORA: Usar scriptblock con progreso visible
            $installBlock = {
                Add-WindowsCapability -Online -Name "OpenSSH.Server~~~~0.0.1.0" -NoRestart
            }

            # Mostrar progreso mientras se instala
            Start-Spinner -Message "Installing OpenSSH Server (this takes time)..." -ScriptBlock $installBlock
        }

        # Esperar un momento antes de iniciar servicio
        Start-Sleep -Seconds 2

        # Iniciar y configurar (común para todos)
        $sshService = Get-Service -Name sshd -ErrorAction SilentlyContinue
        if ($sshService) {
            Start-Service sshd -ErrorAction SilentlyContinue
            Set-Service -Name sshd -StartupType 'Automatic'
        }

        # Configurar shell por defecto a PowerShell
        $sshRegPath = "HKLM:\SOFTWARE\OpenSSH"
        if (!(Test-Path $sshRegPath)) {
            New-Item -Path $sshRegPath -Force | Out-Null
        }

        New-ItemProperty -Path $sshRegPath -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force | Out-Null

        Write-Success "OpenSSH Server configured and running"
    } catch {
        Write-Warning "OpenSSH installation encountered issues: $_"
    }
}

# Configurar Firewall
function Setup-Firewall {
    Write-Info "Configuring Firewall for SSH..."

    try {
        # MEJORA: Verificar si la regla ya existe
        $existingRule = Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue

        if ($existingRule) {
            Write-Success "Firewall rule already configured"
            return
        }

        # Eliminar reglas antiguas si existen
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

    # MEJORA: Priorizar búsqueda en PATH antes que registro
    if ($ExecutableName) {
        if (Get-Command $ExecutableName -ErrorAction SilentlyContinue) {
            return $true
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

    Write-Success "PATH updated in current session"
}

# ============================================================================
# MEJORA 3: Install-Packages Optimizado con mejor logging
# ============================================================================
function Install-Packages {
    param(
        [array]$Packages = $null
    )

    # Si no se proporcionan paquetes, compilar lista según OS específico
    if ($null -eq $Packages -or $Packages -eq "FULL") {
        Write-Info "Building package list for: $Script:OSName"

        # ==================== PAQUETES COMUNES ====================
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

        # ==================== PAQUETES ESPECÍFICOS ====================
        if ($Script:IsServer) {
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
                }
            )
        }
        elseif ($Script:OSType -eq "Windows11") {
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
                }
            )
        }
        else {
            $specificPackages = @(
                @{
                    Id="Microsoft.VisualStudioCode"
                    Name="VS Code"
                    VerifyCommand="code --version"
                    ExecutableName="code.exe"
                    Critical=$false
                }
            )
        }

        $Packages = $commonPackages + $specificPackages
    }

    Write-Host ""
    Write-Info "Package list prepared: $($Packages.Count) packages to process"

    $results = @{
        Success = @()
        Failed = @()
        Skipped = @()
    }

    # MEJORA: Parallelizar instalaciones no críticas
    $criticalPackages = @($Packages | Where-Object { $_.Critical })
    $optionalPackages = @($Packages | Where-Object { !$_.Critical })

    # Instalar críticos en serie
    foreach ($pkg in $criticalPackages) {
        Write-Host "→ Installing $($pkg.Name)..." -ForegroundColor Yellow -NoNewline

        try {
            $output = & winget install --id $pkg.Id --source winget --silent --accept-source-agreements --accept-package-agreements 2>&1
            Start-Sleep -Seconds 2

            Update-EnvironmentPath

            $installed = Test-ProgramInstalled -ProgramId $pkg.Id -VerifyCommand $pkg.VerifyCommand -ExecutableName $pkg.ExecutableName

            if ($installed) {
                Write-Host " ✓" -ForegroundColor Green
                $results.Success += $pkg.Name
            } else {
                Write-Host " ✗" -ForegroundColor Red
                $results.Failed += $pkg.Name
            }
        } catch {
            Write-Host " ✗" -ForegroundColor Red
            Write-Error "  → Error: $_"
            $results.Failed += $pkg.Name
        }
    }

    # Instalar opcionales (más rápido, sin validación estricta)
    foreach ($pkg in $optionalPackages) {
        Write-Host "→ Installing $($pkg.Name)..." -ForegroundColor Yellow -NoNewline

        try {
            $output = & winget install --id $pkg.Id --source winget --silent --accept-source-agreements --accept-package-agreements 2>&1
            Write-Host " ✓" -ForegroundColor Green
            $results.Success += $pkg.Name
        } catch {
            Write-Host " ⚠" -ForegroundColor DarkYellow
            $results.Skipped += $pkg.Name
        }
    }

    # Mostrar resumen compacto
    Write-Host ""
    Write-Success "Installation Summary: $($results.Success.Count) succeeded"

    if ($results.Failed.Count -gt 0) {
        Write-Error "Failed: $($results.Failed.Count)"
    }

    if ($results.Skipped.Count -gt 0) {
        Write-Warning "Skipped: $($results.Skipped.Count)"
    }

    return $results
}

# Configuraciones específicas
function Configure-SystemSpecific {
    if ($Script:IsServer) {
        Write-Info "Applying Windows Server specific configurations..."
        try {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0 -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0 -ErrorAction SilentlyContinue
            Write-Success "IE Enhanced Security disabled"
        } catch {
            Write-Warning "Could not disable IE Enhanced Security"
        }
    } else {
        Write-Info "Applying Windows Desktop specific configurations..."
        try {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -ErrorAction SilentlyContinue
            Write-Success "Developer Mode enabled"
        } catch {
            Write-Warning "Could not enable Developer Mode"
        }
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

    # ⭐ OPERACIÓN QUE TARDA: OpenSSH setup con spinner visible
    Setup-OpenSSH
    Write-Host ""

    Setup-Firewall
    Write-Host ""

    # Instalación de paquetes
    Write-Info "Proceeding with package installation..."
    $installResults = Install-Packages

    Update-EnvironmentPath
    Configure-SystemSpecific

    # Resumen final
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║              Installation Complete! 🎉                   ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Success "Platform: $osType"
    Write-Success "Total packages installed: $($installResults.Success.Count)"
    Write-Host ""
    Write-Info "Next steps: Restart PowerShell for full PATH refresh"

} catch {
    Write-Host ""
    Write-Error "Installation failed: $_"
    exit 1
}
