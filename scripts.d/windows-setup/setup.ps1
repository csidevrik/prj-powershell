# Uso desde internet:
# iwr https://raw.githubusercontent.com/tu-user/windows-setup/main/setup.ps1 | iex
# o con perfil específico:
# iwr "https://raw.githubusercontent.com/.../setup.ps1?profile=desktop" | iex

param(
    [string]$Profile = "base",
    [string]$BaseUrl = "https://raw.githubusercontent.com/tu-user/windows-setup/main"
)

function Invoke-Module {
    param([string]$ModuleName)
    $url = "$BaseUrl/modules/$ModuleName.ps1"
    $code = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
    Invoke-Expression $code
}

function Invoke-Profile {
    param([string]$ProfileName)
    $url = "$BaseUrl/profiles/$ProfileName.ps1"
    $code = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
    Invoke-Expression $code
}

# Cargar módulos core siempre
Invoke-Module "core"
Invoke-Module "winget"
Invoke-Module "openssh"

# Cargar perfil seleccionado
Invoke-Profile $Profile