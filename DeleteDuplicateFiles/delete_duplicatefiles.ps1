# $folderPath = "C:\Users\adminos\OneDrive\2A-JOB02-EMOVEP\2023\CONTRATOS\RE-EP-EMOVEP-2023-02\FACTURAS\SEP\RDD"  # Cambia esto a la ruta de tu carpeta

# Obtiene la lista de archivos en la carpeta
# $files = Get-ChildItem -Path $folderPath

# Write-Output $files

# Get-FileHash $files

# $files | Get-Member


# $files | ForEach-Object {
#     # write-host "init"
#     Write-Host $_.FullName
#     # write-host "end"
# }

# Agrupa los archivos por su contenido (hash) y selecciona los duplicados
# $duplicateFiles = $files | Group-Object -Property { Get-FileHash $_.FullName } | Where-Object { $_.Count -gt 1 }
# $duplicateFiles = $files | Group-Object -Property $_.FullName 
# Write-Output $duplicateFiles.Count

# Elimina los archivos duplicados
# foreach ($group in $duplicateFiles) {
#    $group.Group | Select-Object -Skip 1 | ForEach-Object { Remove-Item $_.FullName -Force }
# }

# ;l;l;l;l;l;l;l

$folderPath = "C:\Users\adminos\OneDrive\2A-JOB02-EMOVEP\2023\CONTRATOS\RE-EP-EMOVEP-2023-02\FACTURAS\SEP\RDD"  # Cambia esto a la ruta de tu carpeta

# Obtiene la lista de archivos en la carpeta
$files = Get-ChildItem -Path $folderPath

# Agrupa los archivos por su valor de hash SHA-256
$duplicateFiles = $files | Group-Object -Property { (Get-FileHash $_.FullName).Hash }
Write-Output $duplicateFiles.Count


# Elimina los archivos duplicados
foreach ($group in $duplicateFiles) {
    $group.Group | Select-Object -Skip 1 | ForEach-Object { Remove-Item $_.FullName -Force }
}
