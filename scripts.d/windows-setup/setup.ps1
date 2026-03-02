# Uso desde internet:
# iwr https://raw.githubusercontent.com/tu-user/windows-setup/main/setup.ps1 | iex
# o con perfil específico:
# iwr "https://raw.githubusercontent.com/.../setup.ps1?profile=desktop" | iex

param(
    [string]$Profile = "base",
    # [string]$BaseUrl = "https://raw.githubusercontent.com/csidevrik/prj-powershell/refs/heads/main/scripts.d/windows-setup/setup.ps1"
    [string]$BaseUrl = "https://raw.githubusercontent.com/csidevrik/prj-powershell/main/scripts.d/windows-setup"
)

function Load-Module {
    param([string]$Name)
    $code = (Invoke-WebRequest -Uri "$BaseUrl/modules/$Name.ps1" -UseBasicParsing).Content
    Invoke-Expression $code
}

function Load-Profile {
    param([string]$Name)
    $code = (Invoke-WebRequest -Uri "$BaseUrl/profiles/$Name.ps1" -UseBasicParsing).Content
    Invoke-Expression $code
}
# function Invoke-Module {
#     param([string]$ModuleName)
#     $url = "$BaseUrl/modules/$ModuleName.ps1"
#     $code = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
#     Invoke-Expression $code
# }

# function Invoke-Profile {
#     param([string]$ProfileName)
#     $url = "$BaseUrl/profiles/$ProfileName.ps1"
#     $code = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
#     Invoke-Expression $code
# }

# # Cargar módulos core siempre
# Invoke-Module "core"
# Invoke-Module "winget"
# Invoke-Module "openssh"

# # Cargar perfil seleccionado
# Invoke-Profile $Profile

# Siempre se cargan
Load-Module "core"
Load-Module "winget"
Load-Module "openssh"

# Se carga según parámetro
Load-Profile $Profile

