# |///////////////////--------------------------------------
# |   created by CSI      07-10-2023
# ||||||||||||||||||||--------------------------------------
# | Organiza facturas de CONTRATO que son de ETAPA EP
# |

# VARIABLES
# --------------------------------------
$terminal = "terminal"

$global:folderPath

function Main {
    param (
        $folderPath
    )
    # Add-Type -AssemblyName System.Windows.Forms

    # # Crea una instancia del cuadro de diálogo de selección de carpeta
    # $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog

    # # Configura el título y la descripción del cuadro de diálogo
    # $folderBrowser.Description = "Selecciona la carpeta de tu área de trabajo"
    # $folderBrowser.RootFolder = [System.Environment+SpecialFolder]::Desktop

    # # Muestra el cuadro de diálogo y espera a que el usuario seleccione una carpeta
    # $result = $folderBrowser.ShowDialog()

    # # Verifica si el usuario ha hecho una selección
    # if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    #     # Obtiene la carpeta seleccionada por el usuario
    #     $selectedFolder = $folderBrowser.SelectedPath
        
        
    #     $folderPath=$selectedFolder
    #     Write-Host "Carpeta seleccionada: $folderPath"  

    # } else {
    #     Write-Host "El usuario canceló la selección de carpeta."
    # }

    # $folderPath = "C:\Users\adminos\OneDrive\2A-JOB02-EMOVEP\2023\CONTRATOS\RE-EP-EMOVEP-2023-02\FACTURAS\SEP\RDD"
    $folderPath = "C:\Users\csigua\OneDrive\2A-JOB02-EMOVEP\2023\CONTRATOS\RE-EP-EMOVEP-2023-02\FACTURAS\MES"

    # -------------------------------------------------------------------

    # # Remove duplicate files
    Remove-DuplicateFiles   -FolderPath $folderPath
    Remove-PrefixFilesPDF   -FolderPath $folderPath -Prefix 'RIDE_'
    Move-FailedFiles        -FolderPath $folderPath
    # Ejemplo de uso:
    Rename-FileswithAttributes -FolderPath $folderPath

    # Get-PDF-WithFirefox -FolderPath $folderPath
    # Get-PDF-WithChrome -FolderPath $folderPath
    
 
}
function Remove-DuplicateFiles {
    param (
        [string]$FolderPath
    )

    # Obtiene la lista de archivos en la carpeta
    $files = Get-ChildItem -Path $FolderPath

    # Agrupa los archivos por su valor de hash SHA-256
    $duplicateFiles = $files | Sort-Object -Property CreationTime | Group-Object -Property { (Get-FileHash $_.FullName).Hash } 
    # $duplicateFiles = $filesA | Group-Object -Property { (Get-FileHash $_.FullName).Hash }


    # Elimina los archivos duplicados
    foreach ($group in $duplicateFiles) {
        $oldestFile = $group.Group | Sort-Object -Property CreationTime | Select-Object -First 1
        $group.Group | Where-Object { $_ -ne $oldestFile } | ForEach-Object { Remove-Item $_.FullName -Force }

        # $group.Group | Select-Object -Skip 1 | ForEach-Object { Remove-Item $_.FullName -Force }
    }
}
function Remove-PrefixFilesPDF {
    param (
        [string]$FolderPath,
        [string]$Prefix
    )

    # Obtiene la lista de archivos en la carpeta
    $files = Get-ChildItem -Path $FolderPath
    $filesPDF = $files | Sort -Descending -Property LastWriteTime | where {$_.extension -eq ".pdf"}

    # Iterar a través de los archivos PDF y renombrarlos
    foreach ($archivoPDF in $filesPDF) {
        # Obtener el nombre del archivo sin extensión
        $nombreSinExtension = [System.IO.Path]::GetFileNameWithoutExtension($archivoPDF.Name)


        # Verificar si el nombre del archivo PDF comienza con "RIDE_"
        if ($nombreSinExtension -match $Prefix) {
            # Eliminar el prefijo "RIDE_" del nombre del archivo
            $nuevoNombre = $nombreSinExtension -replace $Prefix, ''

            # Construir el nuevo nombre del archivo PDF
            $nuevoNombrePDF = $nuevoNombre + ".pdf"

            # Ruta completa del archivo original y nuevo
            $rutaArchivoOriginal = $archivoPDF.FullName
            # $rutaArchivoNuevo = Join-Path -Path $filesB -ChildPath $nuevoNombrePDF

            # Renombrar el archivo PDF
            Rename-Item -Path $rutaArchivoOriginal -NewName $nuevoNombrePDF -Force
        }
    }
        
}
function Move-FailedFiles {
    param (
        [string]$FolderPath
    )

    # Patrón para los nombres de archivo válidos
    $patron = "FAC\d{9}_\d{3}(\.pdf|\.xml)"

    # Lista de archivos en la carpeta
    $archivos = Get-ChildItem $FolderPath

    # Lista para almacenar archivos que no cumplen con el patrón
    $archivosNoValidos = @()

    # Recorrer los archivos y separar los no válidos
    foreach ($archivo in $archivos) {
        if ($archivo.Name -notmatch $patron) {
            $archivosNoValidos += $archivo.Name
        }
    }

    # Ruta de la carpeta "corregir"
    $rutaCorregir = Join-Path -Path $FolderPath -ChildPath "corregir"

    # Comprobar si la carpeta "corregir" no está vacía y vaciarla
    if (Test-Path -Path $rutaCorregir -PathType Container) {
        Remove-Item -Path "$rutaCorregir\*" -Force
    }

    # Crear la carpeta "corregir" si no existe
    if (-not (Test-Path -Path $rutaCorregir -PathType Container)) {
        New-Item -Path $rutaCorregir -ItemType Directory
    }

    # Mover los archivos no válidos a la carpeta "corregir"
    foreach ($archivoNoValido in $archivosNoValidos) {
        $rutaArchivoNoValido = Join-Path -Path $FolderPath -ChildPath $archivoNoValido
        $rutaDestino = Join-Path -Path $rutaCorregir -ChildPath $archivoNoValido
        Move-Item -Path $rutaArchivoNoValido -Destination $rutaDestino
    }

    # Mostrar los archivos no válidos
    # $archivosNoValidos
}
function Extract-XMLContent {
    param (
        [Parameter (Mandatory=$false)][string] $FolderPath    
    )
    $xmlC = Get-Content -Path $FolderPath -Raw

    # Declara el texto  del inicio y el fin para la extraccion
    $startLimit = '<infoTributaria>'
    $endLimit = '</infoAdicional>'

    #Encontrar los indices de inicio y fin
    $startIndex = $xmlC.IndexOf($startLimit)
    $endIndex   = $xmlC.IndexOf($endLimit,$startIndex)

    #Extrae la parte deseada del contenido
    $extractedXML = $xmlC.Substring($startIndex, $endIndex-$startIndex + $endLimit.Length)
    $extractedXMLFac = "<factura>`n$extractedXML`n</factura>"

    $estab = Select-Xml -Content $extractedXMLFac -XPath "//estab" 
    $ptoEm = Select-Xml -Content $extractedXMLFac -XPath "//ptoEmi"
    $secue =  Select-Xml -Content $extractedXMLFac -XPath "//secuencial"
    $codig = (Select-Xml -Content $extractedXMLFac -XPath '//campoAdicional[@nombre="Instalacion"]').Node.InnerText

    # Crear el nuevo nombre
    $newname = "FAC$estab$ptoEm$secue-$codig"

    # Rename-Item -Path $FolderPath -NewName "$newname.xml" -Force
    write-host $newname
    return $newname
}
function Rename-FileswithAttributes {
    param (
        [string]$FolderPath
    )

    # Ruta de la carpeta "corregir"
    $rutaCorregir = Join-Path -Path $FolderPath -ChildPath "corregir"
    Write-Host $rutaCorregir
    $filesB =  Get-ChildItem -Path $FolderPath

    # Lista de archivos .xml en la carpeta
    # $archivosXml = Get-ChildItem $rutaCorregir -Filter "*.xml"
    $filesXML = $filesB | Sort -Descending -Property LastWriteTime | where {$_.extension -eq ".xml"}


    foreach ($filexml in $filesXML) {
        #  obtener el nuevo nombre del archivo XML
        $newname = Extract-XMLContent -FolderPath $filexml.FullName
        # Write-host $newname

        # Construir el nombre del archivo PDF con la misma base
        $pdfFileName = [System.IO.Path]::ChangeExtension($filexml.FullName, "pdf")
        # Write-host $pdfFileName

        # Renombrar el archivo XML
        Rename-Item -Path $filexml.FullName -NewName "$newName.xml" -Force

        # Renombrar el archivo PDF
        Rename-Item -Path $pdfFileName -NewName "$newName.pdf" -Force

    }
}
function Get-PDF-WithFirefox {
    param(
        [string] $FolderPath
    )
    # Obtener los nombres de todos los pdfs
    $files = Get-ChildItem -Path $FolderPath
    $listPdfNames = $files | Sort -Descending -Property LastWriteTime | where {$_.extension -eq ".pdf"}
    $contador = 0
      # Abre una nueva instancia de Firefox
      Start-Process -FilePath "firefox.exe" -ArgumentList "--new-instance"

    foreach ($archivo in $listPdfNames) {
        $contador++
        # Write-Host $contador
        Write-Output $archivo.FullName
        Start-Process -FilePath "firefox.exe" -ArgumentList "--new-tab", "file://$(Resolve-Path $archivo.FullName)"
        Write-Output $contador
        Start-Sleep -Seconds 1
    }

}
function Get-PDF-WithChrome {
    param(
        [string] $FolderPath
    )
    # Obtener los nombres de todos los pdfs
    $files = Get-ChildItem -Path $FolderPath
    $listPdfNames = $files | Sort -Descending -Property LastWriteTime | where {$_.extension -eq ".pdf"}
    $contador = 0

    foreach ($archivo in $listPdfNames) {
        $contador++
        # Write-Host $contador
        Write-Output $archivo.FullName
        Start-Process -FilePath "chrome.exe" -ArgumentList "--new-tab", "file://$(Resolve-Path $archivo.FullName)"
        Write-Output $contador
        Start-Sleep -Seconds 1
    }

}
function Get-NamesFacs {
    param (
        [string] $FolderPath
    )

}


Main
