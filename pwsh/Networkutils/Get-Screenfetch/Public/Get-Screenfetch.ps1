# screenfetch.ps1

function Get-SystemInfo {
    # Obtener información del sistema operativo
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $osVersion = $os.Caption
    $osBuild = $os.BuildNumber

    # Obtener información de la CPU
    $cpu = Get-CimInstance -ClassName Win32_Processor
    $cpuName = $cpu.Name

    # Obtener información de la memoria RAM
    $memory = Get-CimInstance -ClassName Win32_ComputerSystem
    $totalMemory = [math]::Round($memory.TotalPhysicalMemory / 1GB, 2)

    # Obtener información de la GPU
    $gpu = Get-CimInstance -ClassName Win32_VideoController
    $gpuName = $gpu.Name

    # Obtener información del hostname
    $hostname = $env:COMPUTERNAME

    # Obtener información de la versión de PowerShell
    $psVersion = $PSVersionTable.PSVersion

    # Crear un objeto con la información recopilada
    $systemInfo = [PSCustomObject]@{
        Hostname       = $hostname
        OSVersion      = "$osVersion (Build $osBuild)"
        CPU            = $cpuName
        Memory         = "$totalMemory GB"
        GPU            = $gpuName
        PowerShell     = $psVersion
    }

    return $systemInfo
}

function Get-Screenfetch {
    $systemInfo = Get-SystemInfo

    # Mostrar la información en un formato similar a screenfetch
    Write-Host "Hostname: $($systemInfo.Hostname)" -ForegroundColor Cyan
    Write-Host "OS: $($systemInfo.OSVersion)" -ForegroundColor Green
    Write-Host "CPU: $($systemInfo.CPU)" -ForegroundColor Yellow
    Write-Host "Memory: $($systemInfo.Memory)" -ForegroundColor Magenta
    Write-Host "GPU: $($systemInfo.GPU)" -ForegroundColor Blue
    Write-Host "PowerShell: $($systemInfo.PowerShell)" -ForegroundColor Red
}

# Ejecutar la función principal
Get-Screenfetch