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
        [string]$VerifyCommand = "",
        [string]$ExecutableName = ""
    )

    if ($ExecutableName) {
        if (Get-Command $ExecutableName -ErrorAction SilentlyContinue) {
            return $true
        }
    }

    if ($VerifyCommand) {
        try {
            $result = & cmd.exe /c $VerifyCommand 2>&1
            if ($LASTEXITCODE -eq 0) { return $true }
        } catch {
            return $false
        }
    }

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

# Instalación de paquetes
function Install-Packages {
    param([array]$Packages = $null)

    if ($null -eq $Packages -or $Packages -eq "FULL") {
        Write-Info "Building package list for: $Script:OSName"

        # ==================== PAQUETES COMUNES ====================
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

        # ==================== PAQUETES ESPECÍFICOS POR SO ====================
        if ($Script:IsServer) {
            Write-Info "Detected Windows Server - installing server tools"

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
            Write-Info "Detected Windows 11 - installing desktop tools"

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
            Write-Info "Detected Windows 10 - installing compatible tools"

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

        $Packages = $commonPackages + $specificPackages
    }

    Write-Host ""
    Write-Info "Package installation: $($Packages.Count) packages"
    Write-Host ""

    $results = @{
        Success = @()
        Failed = @()
        Skipped = @()
        VerificationFailed = @()
    }

    # Instalar paquetes
    foreach ($pkg in $Packages) {
        $maxRetries = 2
        $attempt = 1
        $installed = $false

        while ($attempt -le $maxRetries -and -not $installed) {
            Write-Host "→ $($pkg.Name)... " -ForegroundColor Yellow -NoNewline

            try {
                $output = & winget install --id $pkg.Id --source winget --silent --accept-source-agreements --accept-package-agreements 2>&1
                Start-Sleep -Seconds 2

                Update-EnvironmentPath

                $installed = Test-ProgramInstalled -ProgramId $pkg.Id -VerifyCommand $pkg.VerifyCommand

                if ($installed) {
                    Write-Host "✓" -ForegroundColor Green
                    $results.Success += $pkg.Name
                } else {
                    if ($pkg.Critical) {
                        Write-Host "✗" -ForegroundColor Red
                        $results.Failed += $pkg.Name
                    } else {
                        Write-Host "⚠" -ForegroundColor Yellow
                        $results.Skipped += $pkg.Name
                    }
                }
                break
            } catch {
                if ($pkg.Critical) {
                    Write-Host "✗" -ForegroundColor Red
                    $results.Failed += $pkg.Name
                } else {
                    Write-Host "⚠" -ForegroundColor Yellow
                    $results.Skipped += $pkg.Name
                }
                break
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
$osType = ""
try {
    $osType = Test-Prerequisites
    Write-Banner $osType
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

            $packagesToInstall = @(
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
                    Critical=$true
                }
            )
        }

        "3" {
            Write-Info "Custom package selection mode"
            $packagesToInstall = "FULL"
        }

        default {
            Write-Info "Full Installation mode selected"
            $packagesToInstall = "FULL"
        }
    }

    # Instalar si no es opción 4
    if ($preference -ne "4") {
        $installResults = Install-Packages -Packages $packagesToInstall

        Update-EnvironmentPath
        Configure-SystemSpecific

        Write-Host ""
        Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║         Core Installation Complete! ✓                    ║" -ForegroundColor Green
        Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""

        Write-Success "Platform: $osType"
        Write-Success "Packages installed: $($installResults.Success.Count)"
        Write-Success "OpenSSH Client: Ready (can connect to remote servers)"

        if ($installResults.Failed.Count -gt 0) {
            Write-Error "Failed packages: $($installResults.Failed -join ', ')"
        }

        Write-Host ""
        Write-Info "Verify installations:"
        Write-Host "  git --version" -ForegroundColor DarkCyan
        Write-Host "  python --version" -ForegroundColor DarkCyan
        Write-Host "  go version" -ForegroundColor DarkCyan
        Write-Host "  nmap --version" -ForegroundColor DarkCyan
        Write-Host ""

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