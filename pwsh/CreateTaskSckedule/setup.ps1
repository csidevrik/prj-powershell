```powershell
# ============================
# CONFIGURACIÓN
# ============================

$BaseStructure = @(
    "\Empresa",
    "\Empresa\Infraestructura",
    "\Empresa\Infraestructura\Backups",
    "\Empresa\Infraestructura\Monitoreo",
    "\Empresa\Infraestructura\Red",
    "\Empresa\Usuarios",
    "\Empresa\Testing"
)

# ============================
# CONEXIÓN AL SCHEDULER (COM)
# ============================

function Get-SchedulerService {
    $service = New-Object -ComObject "Schedule.Service"
    $service.Connect()
    return $service
}

# ============================
# CREAR CARPETA (IDEMPOTENTE)
# ============================

function Ensure-TaskFolder {
    param (
        [string]$Path,
        $Service
    )

    try {
        $null = $Service.GetFolder($Path)
        Write-Host " Existe: $Path"
    }
    catch {
        $parentPath = Split-Path $Path -Parent
        if ($parentPath -eq "" -or $parentPath -eq "\") {
            $parent = $Service.GetFolder("\")
        } else {
            Ensure-TaskFolder -Path $parentPath -Service $Service
            $parent = $Service.GetFolder($parentPath)
        }

        $folderName = Split-Path $Path -Leaf
        $parent.CreateFolder($folderName)
        Write-Host " Creada: $Path"
    }
}

# ============================
# CREAR TODA LA ESTRUCTURA
# ============================

function Initialize-TaskStructure {
    param ($Structure)

    $service = Get-SchedulerService

    foreach ($path in $Structure) {
        Ensure-TaskFolder -Path $path -Service $service
    }
}

# ============================
# REGISTRAR TAREA (GENÉRICO)
# ============================

function Register-CustomTask {
    param (
        [string]$TaskName,
        [string]$TaskPath,
        [string]$Executable,
        [string]$Arguments = "",
        [datetime]$Time = (Get-Date).Date.AddHours(2)
    )

    $action = New-ScheduledTaskAction `
        -Execute $Executable `
        -Argument $Arguments

    $trigger = New-ScheduledTaskTrigger `
        -Daily `
        -At $Time

    try {
        Register-ScheduledTask `
            -TaskName $TaskName `
            -TaskPath $TaskPath `
            -Action $action `
            -Trigger $trigger `
            -Force

        Write-Host "🚀 Tarea registrada: $TaskPath$TaskName"
    }
    catch {
        Write-Host "❌ Error registrando tarea: $TaskName"
    }
}

# ============================
# EJECUCIÓN
# ============================

Write-Host "== Inicializando estructura =="
Initialize-TaskStructure -Structure $BaseStructure

Write-Host "== Registrando tareas de ejemplo =="

# Ejemplo 1: Backup
Register-CustomTask `
    -TaskName "BackupDiario" `
    -TaskPath "\Empresa\Infraestructura\Backups\" `
    -Executable "powershell.exe" `
    -Arguments "-File C:\Scripts\backup.ps1"

# Ejemplo 2: Monitoreo
Register-CustomTask `
    -TaskName "PingCheck" `
    -TaskPath "\Empresa\Infraestructura\Monitoreo\" `
    -Executable "powershell.exe" `
    -Arguments "-File C:\Scripts\monitor.ps1"

# Ejemplo 3: Red
Register-CustomTask `
    -TaskName "NetScan" `
    -TaskPath "\Empresa\Infraestructura\Red\" `
    -Executable "nmap.exe" `
    -Arguments "192.168.1.0/24"

Write-Host " Todo listo"
