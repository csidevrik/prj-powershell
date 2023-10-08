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

    $folderPath = "C:\Users\adminos\OneDrive\2A-JOB02-EMOVEP\2023\CONTRATOS\RE-EP-EMOVEP-2023-02\FACTURAS\SEP\RDD"

    # -------------------------------------------------------------------

    # Remove duplicate files
    # Remove-DuplicateFiles   -FolderPath $folderPath
    # Remove-PrefixFilesPDF   -FolderPath $folderPath -Prefix 'RIDE_'
    # Move-FailedFiles        -FolderPath $folderPath
    # Ejemplo de uso:
    Rename-FileswithAttributes -FolderPath $folderPath
    
 
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
        $nombreSinExtension = $archivoPDF.Name

        # Verificar si el nombre del archivo PDF comienza con "RIDE_"
        if ($nombreSinExtension -match $Prefix) {
            # Eliminar el prefijo "RIDE_" del nombre del archivo
            $nuevoNombre = $nombreSinExtension -replace $Prefix, ''

            # Construir el nuevo nombre del archivo PDF
            $nuevoNombrePDF = $nuevoNombre + $archivoPDF.Extension

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
    $archivosNoValidos
}

function Rename-FileswithAttributes {
    param (
        [string]$FolderPath
    )

    # Ruta de la carpeta "corregir"
    $rutaCorregir = Join-Path -Path $FolderPath -ChildPath "corregir"
    Write-Host $rutaCorregir
    $filesB =  Get-ChildItem -Path $rutaCorregir

    # Lista de archivos .xml en la carpeta
    # $archivosXml = Get-ChildItem $rutaCorregir -Filter "*.xml"
    $filesXML = $filesB | Sort -Descending -Property LastWriteTime | where {$_.extension -eq ".xml"}


    foreach ($filexml in $filesXML) {
        Write-host $filexml.FullName
        # [Method 1]   not working
        # $xfile = New-Object System.Xml.XmlDocument
        # $file = Resolve-Path($fileXml)
        # $xfile.load($file)

        # Método 2
        # [xml]$fxml01 = Get-Content $filexml.FullName

        # Cargamos el contenido XML desde el archivo
        $xml = [xml](Get-Content $filexml.FullName)

        # Accedemos a la sección CDATA y obtenemos su contenido como una cadena XML
        $comprobanteCDATA = $xml.autorizacion.comprobante
        $comprobanteXmlString = $comprobanteCDATA.InnerText

        # Encapsulamos el contenido de la sección CDATA en un elemento raíz ficticio
        $comprobanteXmlString = "<root>$comprobanteXmlString</root>"

        # Creamos un nuevo objeto XmlDocument y le asignamos el contenido como cadena XML
        $comprobanteXml = [System.Xml.XmlDocument]::new()
        $comprobanteXml.LoadXml($comprobanteXmlString)

        # Ahora puedes trabajar con el objeto $comprobanteXml
        $factura = $comprobanteXml.SelectSingleNode("//factura")

        # Mostrar el contenido de <factura>
        Write-Host "Contenido de <factura>:"
        Write-Host $factura.OuterXml

        # if ($estab -and $ptoEmi -and $secuencial -and $campoAdicional) {
        #     # Formar el nuevo nombre
        #     $nuevoNombre = "FAC-$$estab$ptoEmi$secuencial_$campoAdicional"
        #     write-host $nuevoNombre
        #     # Ruta del archivo .pdf con el mismo nombre
        #     $rutaPdf = Join-Path -Path $rutaCorregir -ChildPath "$($fileXml.BaseName).pdf"

        #     # Renombrar los archivos .pdf y .xml
        #     Rename-Item -Path $fileXml.FullName -NewName "$nuevoNombre.xml"
        #     Rename-Item -Path $rutaPdf -NewName "$nuevoNombre.pdf"
        # }
    }
}




Main
