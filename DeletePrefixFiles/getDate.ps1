# Obtiene la fecha actual en formato largo (timestamp)
$fechaActual = [datetime]::Now.ToFileTime()

# Obtiene la ubicación del script actual
$scriptDirectorio = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host $scriptDirectorio

# Construye la ruta al archivo JSON utilizando la ubicación del script
$jsonFile = Join-Path -Path $scriptDirectorio -ChildPath "properties.json"

Write-Host $jsonFile

# Verifica si el archivo JSON existe antes de intentar leerlo
if (Test-Path -Path $jsonFile) {
    # Lee el contenido del archivo JSON
    $jsonContent = Get-Content -Path $jsonFile | ConvertFrom-Json

    Write-Host $jsonContent

    # Actualiza la propiedad "fecha" con la fecha obtenida
    $jsonContent.fecha = $fechaActual

    # Convierte el objeto JSON actualizado de nuevo a formato JSON
    $jsonContent | ConvertTo-Json | Set-Content -Path $jsonFile
} else {
    Write-Host "El archivo JSON no existe en la ubicación especificada: $jsonFile"
}