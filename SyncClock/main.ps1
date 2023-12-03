# |///////////////////--------------------------------------
# |   created by CSI      diciembre - 02 - 2023
# ||||||||||||||||||||--------------------------------------
# | Sincronizacion de reloj en windows

# Script para sincronizar el reloj en Windows
# net stop w32time
# w32tm.exe /unregister
# w32tm.exe /register
# net start w32time
# w32tm.exe /resync
# Comprueba si el script se está ejecutando con privilegios de administrador
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Si no se está ejecutando con privilegios de administrador, relanza el script con privilegios elevados
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# Obtiene la zona horaria actual
$timezone = Get-TimeZone

# Muestra la información de la zona horaria actual
Write-Output "Zona horaria actual: $($timezone.Id)"

# Establece la zona horaria deseada
$desiredTimeZone = "SA Pacific Standard Time"
Set-TimeZone -Id $desiredTimeZone

# Muestra la nueva información de la zona horaria
$timezone = Get-TimeZone
Write-Output "Nueva zona horaria: $($timezone.Id)"

# Sincroniza el reloj con un servidor de tiempo
w32tm /resync

Write-Output "Reloj sincronizado correctamente."

Start-Sleep -Seconds 3

