# |///////////////////--------------------------------------
# |   created by CSI      07-10-2023
# ||||||||||||||||||||--------------------------------------
# | Organiza facturas de CONTRATO que son de ETAPA EP
# |

# VARIABLES
# --------------------------------------

$global:folderPath

function Main {
    param (
        $folderPath
    )
    Add-Type -AssemblyName System.Windows.Forms

    # Crea una instancia del cuadro de diálogo de selección de carpeta
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog

    # Configura el título y la descripción del cuadro de diálogo
    $folderBrowser.Description = "Selecciona la carpeta de tu área de trabajo"
    $folderBrowser.RootFolder = [System.Environment+SpecialFolder]::Desktop

    # Muestra el cuadro de diálogo y espera a que el usuario seleccione una carpeta
    $result = $folderBrowser.ShowDialog()

    # Verifica si el usuario ha hecho una selección
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        # Obtiene la carpeta seleccionada por el usuario
        $selectedFolder = $folderBrowser.SelectedPath
        
        
        $folderPath=$selectedFolder
        Write-Host "Carpeta seleccionada: $folderPath"  

    } else {
        Write-Host "El usuario canceló la selección de carpeta."
    }

    # -------------------------------------------------------------------

    # Remove duplicate files
    Remove-DuplicateFiles -FolderPath $folderPath
    Write-Host "termino" 
 
}


function Remove-DuplicateFiles {
    param (
        [string]$FolderPath
    )

    # Obtiene la lista de archivos en la carpeta
    $files = Get-ChildItem -Path $FolderPath

    # Agrupa los archivos por su valor de hash SHA-256
    $duplicateFiles = $files | Sort-Object - -Property LastWriteTime| Group-Object -Property { (Get-FileHash $_.FullName).Hash } 

    # Elimina los archivos duplicados
    foreach ($group in $duplicateFiles) {
        $oldesFile = $group.Group | Sort-Object -Property LastWriteTime | Select-Object -First 1
        $group.Group | Where-Object { $_ -ne $oldestFile } | ForEach-Object { Remove-Item $_.FullName -Force }

        # $group.Group | Select-Object -Skip 1 | ForEach-Object { Remove-Item $_.FullName -Force }
    }
}



Main
