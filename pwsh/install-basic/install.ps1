# install.ps1 - Universal Windows Setup v3
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

# Detectar tipo de sistema operativo
function Get-SystemType {
    $os = Get-CimInstance Win32_OperatingSystem
    $Script:OSName = $os.Caption
    $Script:OSVersion = $os.Version

    if ($os.Caption -like "*Server*") {
        $Script:IsServer = $true
        $Script:OSType = "WindowsServer"
        return "Windows Server"
    } elseif ($os.Caption -like "*Windows 11*") {
        $Script:OSType = "Windows11"
        $Script:IsServer = $false
        return "Windows 11"
    } elseif ($os.Caption -like "*Windows 10*") {
        $Script:OSType = "Windows10"
        $Script:IsServer = $false
        return "Windows 10"
    } else {
        $Script:OSType = "Unknown"
        $Script:IsServer = $false
        return "Windows (Unknown)"
    }
}

# Verificar prerrequisitos
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."

    $osLabel = Get-SystemType
    Write-Success "Detected: $osLabel ($Script:OSVersion)"

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (!$isAdmin) {
        Write-Error "Please run as Administrator"
        exit 1
    }

    Write-Success "Running with Administrator privileges"
    return $osLabel
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

        Write-Info "Downloading dependencies..."
        $vcLibsUrl = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
        $vcLibsPath = "$env:TEMP\Microsoft.VCLibs.x64.14.00.Desktop.appx"
        Invoke-WebRequest -Uri $vcLibsUrl -OutFile $vcLibsPath -ErrorAction SilentlyContinue
        Add-AppxPackage -Path $vcLibsPath -ErrorAction SilentlyContinue

        $uiXamlUrl = "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx"
        $uiXamlPath = "$env:TEMP\Microsoft.UI.Xaml.2.8.x64.appx"
        Invoke-WebRequest -Uri $uiXamlUrl -OutFile $uiXamlPath -ErrorAction SilentlyContinue
        Add-AppxPackage -Path $uiXamlPath -ErrorAction SilentlyContinue

        $wingetUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        $wingetPath = "$env:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        Invoke-WebRequest -Uri $wingetUrl -OutFile $wingetPath -ErrorAction SilentlyContinue
        Add-AppxPackage -Path $wingetPath -ErrorAction SilentlyContinue

        Write-Success "Winget installed successfully"
    } catch {
        Write-Warning "Could not install winget automatically."
    }
}

# Instalar OpenSSH Client (RÁPIDO - < 1 minuto)
function Setup-OpenSSHClient {
    Write-Info "Installing OpenSSH Client..."

    try {
        $sshClient = Get-WindowsCapability -Online -Name "OpenSSH.Client*" -ErrorAction SilentlyContinue

        if ($sshClient.State -eq 'Installed') {
            Write-Success "OpenSSH Client already installed"
            return
        }

        Add-WindowsCapability -Online -Name "OpenSSH.Client~~~~0.0.1.0" -NoRestart | Out-Null
        Write-Success "OpenSSH Client installed successfully"

    } catch {
        Write-Warning "OpenSSH Client installation encountered issues: $_"
    }
}

# Verificar si un programa está instalado
function Test-ProgramInstalled {
    param(
        [string]$ProgramId,
        [string]$VerifyCommand = ""
    )

    # Camino rápido: comando en PATH (funciona para Git, Python, Go, etc.)
    if ($VerifyCommand) {
        try {
            & cmd.exe /c $VerifyCommand 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { return $true }
        } catch {}
    }

    # Respaldo: preguntarle a winget directamente. Necesario para apps que no
    # se agregan al PATH (Chrome, Firefox, Insomnia, PowerToys, Windows Terminal, ...)
    try {
        $output = & winget list --id $ProgramId --source winget --accept-source-agreements 2>&1
        return [bool]($output | Select-String -SimpleMatch $ProgramId)
    } catch {
        return $false
    }
}

# Actualizar PATH
function Update-EnvironmentPath {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# Menú de preferencias interactivas
function Get-InstallPreferences {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║ Installation Preferences                                 ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Quick Options:"
    Write-Host "  [1] Full Installation (all packages + browsers)"
    Write-Host "  [2] Essential Only (Git, Python, Go)"
    Write-Host "  [3] Custom Selection"
    Write-Host "  [4] Show installed packages and exit"
    Write-Host ""

    $choice = Read-Host "Select option (1-4, default: 1)"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }

    return $choice
}

# Catálogo de paquetes disponibles para la plataforma detectada
function Get-AvailablePackages {
    param(
        [string]$Mode = "FULL"  # FULL o ESSENTIAL
    )

    # ==================== PAQUETES SIEMPRE COMUNES ====================
    $commonPackages = @(
        @{
            Id="Git.Git"
            Name="Git"
            VerifyCommand="git --version"
            Critical=$true
        },
        @{
            Id="Python.Python.3.12"
            Name="Python 3.12"
            VerifyCommand="python --version"
            Critical=$true
        },
        @{
            Id="GoLang.Go"
            Name="Go"
            VerifyCommand="go version"
            Critical=$false
        }
    )

    if ($Mode -eq "ESSENTIAL") {
        return $commonPackages
    }

    # ==================== PAQUETES ESPECÍFICOS POR SO ====================
    if ($Script:OSType -eq "WindowsServer" -or $Script:IsServer) {
        $specificPackages = @(
            @{
                Id="Google.Chrome"
                Name="Chrome"
                VerifyCommand="chrome --version"
                Critical=$false
            },
            @{
                Id="Mozilla.Firefox"
                Name="Firefox"
                VerifyCommand="firefox --version"
                Critical=$false
            },
            @{
                Id="Insomnia.Insomnia"
                Name="Insomnia"
                VerifyCommand=""
                Critical=$false
            },
            @{
                Id="Microsoft.VisualStudioCode"
                Name="VS Code"
                VerifyCommand="code --version"
                Critical=$false
            },
            @{
                Id="Nmap.Nmap"
                Name="Nmap"
                VerifyCommand="nmap --version"
                Critical=$false
            },
            @{
                Id="Microsoft.PowerShell"
                Name="PowerShell 7"
                VerifyCommand="pwsh --version"
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
                Critical=$false
            },
            @{
                Id="Microsoft.PowerToys"
                Name="PowerToys"
                VerifyCommand=""
                Critical=$false
            },
            @{
                Id="Microsoft.VisualStudioCode"
                Name="VS Code"
                VerifyCommand="code --version"
                Critical=$false
            },
            @{
                Id="Google.Chrome"
                Name="Chrome"
                VerifyCommand="chrome --version"
                Critical=$false
            },
            @{
                Id="Mozilla.Firefox"
                Name="Firefox"
                VerifyCommand="firefox --version"
                Critical=$false
            },
            @{
                Id="Nmap.Nmap"
                Name="Nmap"
                VerifyCommand="nmap --version"
                Critical=$false
            }
        )
    }
    elseif ($Script:OSType -eq "Windows10") {
        $specificPackages = @(
            @{
                Id="Microsoft.VisualStudioCode"
                Name="VS Code"
                VerifyCommand="code --version"
                Critical=$false
            },
            @{
                Id="Google.Chrome"
                Name="Chrome"
                VerifyCommand="chrome --version"
                Critical=$false
            },
            @{
                Id="Mozilla.Firefox.ESR"
                Name="Firefox"
                VerifyCommand="firefox --version"
                Critical=$false
            },
            @{
                Id="Nmap.Nmap"
                Name="Nmap"
                VerifyCommand="nmap --version"
                Critical=$false
            },
            @{
                Id="Microsoft.PowerShell"
                Name="PowerShell 7"
                VerifyCommand="pwsh --version"
                Critical=$false
            }
        )
    }
    else {
        Write-Warning "Unknown OS type, using common packages only"
        $specificPackages = @()
    }

    return $commonPackages + $specificPackages
}

# Menú de selección manual de paquetes
function Get-CustomSelection {
    $available = Get-AvailablePackages -Mode "FULL"

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║ Custom Selection                                          ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    for ($i = 0; $i -lt $available.Count; $i++) {
        $critical = if ($available[$i].Critical) { " [recommended]" } else { "" }
        Write-Host ("  [{0}] {1}{2}" -f ($i + 1), $available[$i].Name, $critical)
    }

    Write-Host ""
    Write-Host "Escribe los números separados por coma (ej: 1,2,4), o 'A' para todos." -ForegroundColor Gray
    $choice = Read-Host "Selección"

    if ($choice -match '^[Aa]$') {
        return $available
    }

    $indexes = $choice -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ - 1 }
    $selected = @($indexes | Where-Object { $_ -ge 0 -and $_ -lt $available.Count } | ForEach-Object { $available[$_] })

    if ($selected.Count -eq 0) {
        Write-Warning "No se seleccionó ningún paquete válido, usando lista completa."
        return $available
    }

    return $selected
}

# Instalación de paquetes
function Install-Packages {
    param(
        [array]$Packages = $null,
        [string]$Mode = "FULL"  # FULL o ESSENTIAL
    )

    # Si no se proporcionan paquetes, compilar lista según el modo
    if ($null -eq $Packages) {
        Write-Info "Building package list for: $Script:OSName (Mode: $Mode)"
        Write-Host ""
        $Packages = Get-AvailablePackages -Mode $Mode
        Write-Info "Package installation ($Mode mode): $($Packages.Count) packages"
        Write-Host ""
    }

    if ($null -eq $Packages -or $Packages.Count -eq 0) {
        Write-Error "No packages to install"
        return
    }

    $results = @{
        Success = @()
        Failed = @()
        Skipped = @()
        Packages = $Packages
    }

    # Instalar paquetes
    foreach ($pkg in $Packages) {
        $maxRetries = 2
        $attempt = 1
        $installed = $false

        while ($attempt -le $maxRetries -and -not $installed) {
            if ($attempt -gt 1) {
                Write-Host "→ Retrying $($pkg.Name) ($attempt/$maxRetries)..." -ForegroundColor Yellow
            } else {
                Write-Host "→ Installing $($pkg.Name)..." -ForegroundColor Yellow
            }

            try {
                & winget install --id $pkg.Id --source winget --accept-source-agreements --accept-package-agreements
                Start-Sleep -Seconds 2

                Update-EnvironmentPath

                $installed = Test-ProgramInstalled -ProgramId $pkg.Id -VerifyCommand $pkg.VerifyCommand
            } catch {
                $installed = $false
            }

            $attempt++
        }

        if ($installed) {
            Write-Host "  ✓ $($pkg.Name)" -ForegroundColor Green
            $results.Success += $pkg.Name
        } else {
            if ($pkg.Critical) {
                Write-Host "  ✗ $($pkg.Name)" -ForegroundColor Red
                $results.Failed += $pkg.Name
            } else {
                Write-Host "  ⚠ $($pkg.Name)" -ForegroundColor Yellow
                $results.Skipped += $pkg.Name
            }
        }
    }

    # Resumen
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           Installation Summary                           ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    if ($results.Success.Count -gt 0) {
        Write-Success "Verified installed ($($results.Success.Count)):"
        $results.Success | ForEach-Object { Write-Host "  ✓ $_" -ForegroundColor Green }
    }

    if ($results.Failed.Count -gt 0) {
        Write-Error "Failed to install (CRITICAL) ($($results.Failed.Count)):"
        $results.Failed | ForEach-Object { Write-Host "  ✗ $_" -ForegroundColor Red }
    }

    if ($results.Skipped.Count -gt 0) {
        Write-Warning "Skipped ($($results.Skipped.Count)):"
        $results.Skipped | ForEach-Object { Write-Host "  ⚠ $_" -ForegroundColor DarkYellow }
    }

    Write-Host ""
    return $results
}

# OpenSSH Server opcional (al final)
function Setup-OpenSSHServer-Optional {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║ OPTIONAL: Configure OpenSSH Server (SSH Remote Access)   ║" -ForegroundColor Yellow
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""

    $sshServer = Get-WindowsCapability -Online -Name "OpenSSH.Server*" -ErrorAction SilentlyContinue

    if ($sshServer.State -eq 'Installed') {
        Write-Success "OpenSSH Server already installed"
        return
    }

    Write-Host "This will take approximately 15-20 minutes due to Windows package patching." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Install OpenSSH Server now?" -ForegroundColor Cyan
    Write-Host "  [Y] Yes, install (wait 15-20 minutes)" -ForegroundColor Green
    Write-Host "  [N] No, skip for now" -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "Select [Y/N] (default: N)"

    if ($choice -eq 'Y' -or $choice -eq 'y') {
        Write-Host ""
        Write-Info "Installing OpenSSH Server (this will take time)..."
        Write-Host "⏳ Installation in progress..." -ForegroundColor Cyan

        try {
            Add-WindowsCapability -Online -Name "OpenSSH.Server~~~~0.0.1.0" -NoRestart | Out-Null

            Start-Sleep -Seconds 2

            $sshService = Get-Service -Name sshd -ErrorAction SilentlyContinue
            if ($sshService) {
                Start-Service sshd -ErrorAction SilentlyContinue
                Set-Service -Name sshd -StartupType 'Automatic'
            }

            $sshRegPath = "HKLM:\SOFTWARE\OpenSSH"
            if (!(Test-Path $sshRegPath)) {
                New-Item -Path $sshRegPath -Force | Out-Null
            }

            New-ItemProperty -Path $sshRegPath -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force | Out-Null

            $existingRule = Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue
            if (!$existingRule) {
                Get-NetFirewallRule -DisplayName "*OpenSSH*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue

                New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' `
                    -DisplayName 'OpenSSH SSH Server (sshd)' `
                    -Enabled True `
                    -Direction Inbound `
                    -Protocol TCP `
                    -Action Allow `
                    -LocalPort 22 `
                    -Profile Any `
                    -Program '%SystemRoot%\System32\OpenSSH\sshd.exe' | Out-Null
            }

            Write-Success "OpenSSH Server configured and running on port 22"
            Write-Success "You can now connect via: ssh $env:USERNAME@$env:COMPUTERNAME"

        } catch {
            Write-Warning "OpenSSH Server installation failed: $_"
        }
    } else {
        Write-Info "OpenSSH Server installation skipped"
        Write-Info "You can install it later by running:"
        Write-Host "  Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -NoRestart" -ForegroundColor DarkCyan
    }
}

# Configuraciones específicas
function Configure-SystemSpecific {
    if ($Script:IsServer) {
        Write-Info "Applying Windows Server configurations..."
        try {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0 -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0 -ErrorAction SilentlyContinue
            Write-Success "IE Enhanced Security disabled"
        } catch {
            Write-Warning "Could not disable IE Enhanced Security"
        }
    } else {
        Write-Info "Applying Windows Desktop configurations..."
        try {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -ErrorAction SilentlyContinue
            Write-Success "Developer Mode enabled"
        } catch {
            Write-Warning "Could not enable Developer Mode"
        }
    }
}

# MAIN
$osLabel = ""
try {
    $osLabel = Test-Prerequisites
    Write-Banner $osLabel
    Write-Host ""

    Install-Winget
    Write-Host ""

    Setup-OpenSSHClient
    Write-Host ""

    # Menú de preferencias
    $preference = Get-InstallPreferences
    Write-Host ""

    # Procesador según preferencia
    switch ($preference) {
        "4" {
            Write-Info "Checking installed programs..."
            Write-Host ""

            $checkPrograms = @(
                @{Name="Git"; Command="git --version"},
                @{Name="Python"; Command="python --version"},
                @{Name="Go"; Command="go version"},
                @{Name="Chrome"; Command="chrome --version"},
                @{Name="Firefox"; Command="firefox --version"},
                @{Name="Nmap"; Command="nmap --version"},
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
            Write-Info "Installing Essential packages only (Git, Python, Go)..."
            Write-Host ""
            $installResults = Install-Packages -Mode "ESSENTIAL"
        }

        "3" {
            Write-Info "Custom Selection mode"
            $customPackages = Get-CustomSelection
            Write-Host ""
            Write-Info "Installing $($customPackages.Count) selected package(s)..."
            $installResults = Install-Packages -Packages $customPackages
        }

        default {
            Write-Info "Full Installation mode selected (default)"
            Write-Host "Installing all available packages for your platform..." -ForegroundColor Cyan
            $installResults = Install-Packages -Mode "FULL"
        }
    }

    # Instalar si no es opción 4
    if ($preference -ne "4") {

        Update-EnvironmentPath
        Configure-SystemSpecific

        Write-Host ""
        Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║         Core Installation Complete! ✓                    ║" -ForegroundColor Green
        Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""

        Write-Success "Platform: $osLabel"
        Write-Success "Packages installed: $($installResults.Success.Count)"
        Write-Success "OpenSSH Client: Ready (can connect to remote servers)"

        if ($installResults.Failed.Count -gt 0) {
            Write-Error "Failed packages: $($installResults.Failed -join ', ')"
        }

        Write-Host ""
        $verifiableSuccess = $installResults.Packages | Where-Object {
            $_.VerifyCommand -and $installResults.Success -contains $_.Name
        }
        if ($verifiableSuccess) {
            Write-Info "Verify installations:"
            $verifiableSuccess | ForEach-Object {
                Write-Host "  $($_.VerifyCommand)" -ForegroundColor DarkCyan
            }
            Write-Host ""
        }

        if ($installResults.Skipped.Count -gt 0) {
            Write-Warning "Skipped (not critical, may need manual install): $($installResults.Skipped -join ', ')"
            Write-Host ""
        }

        # Tarea opcional: OpenSSH Server
        Setup-OpenSSHServer-Optional

        Write-Host ""
        Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║           Setup Complete!                                ║" -ForegroundColor Cyan
        Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Info "Restart PowerShell for full PATH refresh"
        Write-Host ""
    }

} catch {
    Write-Host ""
    Write-Error "Installation failed: $_"
    exit 1
}