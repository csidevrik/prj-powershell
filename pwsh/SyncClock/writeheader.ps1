param(
    [string]$autor,
    [string]$titulo
)

# Obtiene la ruta del directorio del script actual
$scriptDirectorio = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Construye la ruta completa del archivo main.ps1
$rutaArchivo = Join-Path $scriptDirectorio "main.ps1"

# Formato de la nueva cabecera
$nuevaCabecera = @"
# |///////////////////--------------------------------------
# |   created by $autor      $(Get-Date -Format 'MMMM - dd - yyyy')
# ||||||||||||||||||||--------------------------------------
# | $titulo
"@

# Escribe la nueva cabecera en el archivo main.ps1
$nuevaCabecera | Set-Content $rutaArchivo

Write-Host "Se escribió la nueva cabecera en el archivo main.ps1."
