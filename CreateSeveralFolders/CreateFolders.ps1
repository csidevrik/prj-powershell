# Definir la lista de nombres de carpetas
$nombresCarpetas = @(
    "DPA-0028-2020",
    "DPA-0036-2021",
    "DPA-0037-2022",
    "DPA-0011-2023",
    "DPA-0016-2023",
    "DPA-0039-2023",
    "DPA-0045-2023"
)

# Especificar la ruta donde se crearán las carpetas
$rutaBase = "D:\C\Documents\APOYANDOLAVAGANCIA"

# Verificar si la ruta base existe, si no, crearla
if (-not (Test-Path -Path $rutaBase)) {
    Write-Host "La ruta base no existe. Creando la ruta base: $rutaBase"
    New-Item -Path $rutaBase -ItemType Directory
}

# Crear las carpetas
foreach ($nombre in $nombresCarpetas) {
    $rutaCarpeta = Join-Path -Path $rutaBase -ChildPath $nombre
    if (-not (Test-Path -Path $rutaCarpeta)) {
        New-Item -Path $rutaCarpeta -ItemType Directory
        Write-Host "Carpeta creada: $rutaCarpeta"
    } else {
        Write-Host "La carpeta ya existe: $rutaCarpeta"
    }
}