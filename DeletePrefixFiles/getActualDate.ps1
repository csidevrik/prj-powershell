# $actualDay = Get-Date
# $actualDayFormat = $actualDay.ToString("D")
# Write-Host $actualDay
# Write-Host $actualDayFormat

# Obtener la fecha actual
$actualDay = Get-Date
$actualDayFormat = $actualDay.ToString("D")

# Ruta del archivo .properties
$propertiesFile = "config.properties"

# Leer el archivo .properties y convertirlo en un hash table
$properties = @{}
Get-Content $propertiesFile | ForEach-Object {
    if ($_ -match '^\s*([^#].+?)\s*=\s*(.+?)\s*$') {
        $properties[$matches[1]] = $matches[2]
    }
}

# Actualizar el valor de la clave 'fecha' en el hash table
$properties["fecha"] = $actualDayFormat

# Crear un archivo temporal con las propiedades actualizadas
$tempFile = "temp.properties"
$properties.GetEnumerator() | ForEach-Object {
    "$($_.Key)=$($_.Value)"
} | Set-Content -Path $tempFile

# Reemplazar el archivo original con el archivo temporal
Move-Item -Path $tempFile -Destination $propertiesFile -Force
Write-Host $propertiesFile
Write-Host $properties["fecha"]