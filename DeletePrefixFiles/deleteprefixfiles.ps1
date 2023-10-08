$folderPath = "C:\Users\adminos\OneDrive\2A-JOB02-EMOVEP\2023\CONTRATOS\RE-EP-EMOVEP-2023-02\FACTURAS\SEP\RDD"  # Cambia esto a la ruta de tu carpeta

# Obtiene la lista de archivos en la carpeta
$filesA = Get-ChildItem -Path $folderPath

# Agrupa los archivos por su valor de hash SHA-256
$duplicateFiles = $filesA | Group-Object -Property { (Get-FileHash $_.FullName).Hash }

# Elimina los archivos duplicados
foreach ($group in $duplicateFiles) {
    $group.Group | Select-Object -Skip 1 | ForEach-Object { Remove-Item $_.FullName -Force }
}

$filesB =  Get-ChildItem -Path $folderPath

$filesXML = $filesB | Sort -Descending -Property LastWriteTime | where {$_.extension -eq ".xml"}
Write-Output $filesXML.
$filesPDF = $filesB | Sort -Descending -Property LastWriteTime | where {$_.extension -eq ".pdf"}
Write-Output $filesPDF

# PRIMERO QUITAR LOS PREFIJOS DE LOS PDF
# /////////////////////////////////////////////////////////////////////////////////////////////////

# Iterar a través de los archivos PDF y renombrarlos
foreach ($archivoPDF in $filesPDF) {
    # Obtener el nombre del archivo sin extensión
    $nombreSinExtension = $archivoPDF.Name

    # Verificar si el nombre del archivo PDF comienza con "RIDE_"
    if ($nombreSinExtension -match 'RIDE_') {
        # Eliminar el prefijo "RIDE_" del nombre del archivo
        $nuevoNombre = $nombreSinExtension -replace 'RIDE_', ''

        # Construir el nuevo nombre del archivo PDF
        $nuevoNombrePDF = $nuevoNombre + $archivoPDF.Extension

        # Ruta completa del archivo original y nuevo
        $rutaArchivoOriginal = $archivoPDF.FullName
        # $rutaArchivoNuevo = Join-Path -Path $filesB -ChildPath $nuevoNombrePDF

        # Renombrar el archivo PDF
        Rename-Item -Path $rutaArchivoOriginal -NewName $nuevoNombrePDF -Force
    }
}

# SEGUNDO ENCONTRAR LOS ATRIBUTOS
# /////////////////////////////////////////////////////////////////////////////////////////////////

# # Iterar a través de los archivos XML
# foreach ($archivoXML in $archivosXML) {
#     # Leer los atributos necesarios del archivo XML
#     $xml = [xml](Get-Content $archivoXML.FullName)
#     $estab = $xml.SelectSingleNode("//estab").InnerText
#     $ptoEmi = $xml.SelectSingleNode("//ptoEmi").InnerText
#     $secuencial = $xml.SelectSingleNode("//secuencial").InnerText
#     $instalacion = $xml.SelectSingleNode("//campoAdicional[@nombre='Instalacion']").InnerText  # Atributo Instalacion

#     # Verificar si se encontraron todos los atributos necesarios
#     if (-not [string]::IsNullOrEmpty($estab) -and -not [string]::IsNullOrEmpty($ptoEmi) -and -not [string]::IsNullOrEmpty($secuencial) -and -not [string]::IsNullOrEmpty($instalacion)) {
#         $oldNameXML = $archivoXML.FullName
#         $oldNamePDF = 
#         # Construir el nuevo nombre del archivo PDF y la carpeta
#         $nuevoNombre = "${instalacion}FAC${estab}${ptoEmi}${secuencial}"
        
#         $nuevoNombrePDF = $nuevoNombre + ".pdf"
#         $nuevoNombreXML = $nuevoNombre + ".xml"
#         $nuevaCarpeta = Join-Path -Path $filesB -ChildPath $nuevoNombre

#         # Renombrar el archivo PDF
#         $archivoPDF = Get-ChildItem -Path $filesB -Filter "$old.pdf"
#         if ($archivoPDF) {
#             Rename-Item -Path $archivoPDF.FullName -NewName $nuevoNombrePDF -Force
#         }

#         # Renombrar el archivo XML
#         Rename-Item -Path $oldNameXML -NewName $nuevoNombreXML -Force


#         # Crear la carpeta si no existe
#         if (-not (Test-Path -Path $nuevaCarpeta -PathType Container)) {
#             New-Item -Path $nuevaCarpeta -ItemType Directory
#         }

#         # Mover archivos XML y PDF a la carpeta
#         Move-Item -Path $archivoXML.FullName -Destination $nuevaCarpeta
#         Move-Item -Path $nuevoNombrePDF -Destination $nuevaCarpeta
#     }
# }

# # Comprimir la carpeta en un archivo ZIP
# $nombreCarpeta = (Get-ChildItem -Path $carpeta -Directory).Name
# Compress-Archive -Path $carpeta -DestinationPath "$carpeta\$nombreCarpeta.zip" -Force