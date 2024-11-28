Comandos para verificar soporte de virtualización

REM Verificar si la virtualización está habilitada en la BIOS/UEFI
systeminfo | findstr /i "Hyper-V"

REM Verificar el estado de virtualización usando PowerShell
powershell Get-ComputerInfo -Property "HyperVRequirementVirtualizationFirmwareEnabled", "HyperVRequirementVMMonitorModeExtensions"

REM Verificar si Hyper-V está instalado
dism /online /get-featureinfo /featurename:Microsoft-Hyper-V

REM Verificar detalles del procesador incluyendo soporte de virtualización
wmic cpu get Name, NumberOfCores, NumberOfLogicalProcessors, VirtualizationFirmwareEnabled

REM Verificar la edición de Windows
wmic os get Caption, Version, BuildNumber, OSArchitecture

REM Verificar memoria RAM disponible
wmic memorychip get Capacity, Speed

REM Verificar si el servicio de Hyper-V está ejecutándose
sc query "vmms"

REM Verificar estado detallado de Hyper-V usando PowerShell
powershell Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All

REM Verificar si la característica de Hyper-V está habilitada en Windows
bcdedit /enum | findstr -i "hypervisorlaunchtype"