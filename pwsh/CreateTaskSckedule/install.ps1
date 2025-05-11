# |///////////////////--------------------------------------
# |   created by CSI      28-08-2023
# ||||||||||||||||||||--------------------------------------
# | Create a schedule task with taskschedule folder personal
# |

# VARIABLES
# --------------------------------------
$TaskName="OctabaRobocopy" # Name of the scheduled task.


# - 1. Create schedule.service object
$scheduleObject = New-Object -ComObject schedule.service
# - 2. Connect to the schedule service.
$scheduleObject.connect()
# - 3. Create a folder object.
$rootFolder = $scheduleObject.GetFolder("\")
# - 4. Create a new folder
$rootFolder.CreateFolder($TaskName)

# - 5. Posicionarse dentro de la carpeta creada
$rootFolder = $scheduleObject.GetFolder("\$TaskName")

# Ruta de origen y destino
$origen = "C:\Users\adminos\Downloads\ISOS"
$destino = "D:\C\Downloads\ISOS"

# Opciones de Robocopy (puedes ajustarlas según tus necesidades)
$optionsRobocopy = "/E /Z /NP /R:3 /W:5"

# - 6. Create a new task definition
$taskDefinition = $scheduleObject.NewTask(0)
Write-Host "pivote"

# ]]]]]]]]]]]]]]]]]]]]]
# hay un problema todavia 


# - 5. Create an action for the task
$action = $taskDefinition.Actions.Create(0)
$action.Path = "robocopy.exe"
$action.Arguments = "$origen $destino $optionsRobocopy"

# - 6. Register the task within the folder
$rootFolder.RegisterTaskDefinition($TaskName, $taskDefinition, 6, $null, $null, 1)


# Crear una acción para ejecutar Robocopy
# $action = New-ScheduledTaskAction -Execute "robocopy.exe" -Argument "$origen $destino $opcionesRobocopy"

# Crear un disparador para la tarea (por ejemplo, ejecutarla cada día a las 2 PM)
$trigger = New-ScheduledTaskTrigger -Daily -At 2pm

# Configurar la tarea programada
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "CopiaDiaria" -Description "Tarea programada para copiar archivos con Robocopy"
