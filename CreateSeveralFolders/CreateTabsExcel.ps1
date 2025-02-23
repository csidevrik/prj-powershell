# Definir la lista de nombres de carpetas y pestañas de Excel
$nombres = @(
    "DPA-0028-2020",
    "DPA-0036-2021",
    "DPA-0037-2022",
    "DPA-0011-2023",
    "DPA-0016-2023",
    "DPA-0039-2023",
    "DPA-0045-2023"
)

# Especificar la ruta base donde se crearán las carpetas
$rutaBase = "D:\C\Documents\APOYANDOLAVAGANCIA"

# Verificar si la ruta base existe, si no, crearla
if (-not (Test-Path -Path $rutaBase)) {
    Write-Host "La ruta base no existe. Creando la ruta base: $rutaBase"
    New-Item -Path $rutaBase -ItemType Directory | Out-Null
}

# Crear un nuevo libro de Excel
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false  # Cambia a $true si quieres ver Excel en ejecución
$workbook = $excel.Workbooks.Add()

# Eliminar hojas predeterminadas para evitar conflictos
while ($workbook.Sheets.Count -gt 1) {
    ($workbook.Sheets.Item(1)).Delete()
}

# Definir las etiquetas que se agregarán en cada pestaña (ahora en filas)
$filas = @(
    "NUT",
    "OBJETO",
    "IS-CONTRATO",
    "IS-PROCEDI",
    "DOC1",
    "DOC2",
    "IMAGE1",
    "IMAGE2",
    "URL-CONTRALORIA",
    "IMAG-QUIPUX1",
    "IMAG-QUIPUX2"
)

# Crear una pestaña para cada nombre y agregar las filas
foreach ($nombre in $nombres) {
    $sheet = $workbook.Sheets.Add()
    $sheet.Name = $nombre
    
    # Insertar nombres de las filas en la primera columna
    for ($i = 0; $i -lt $filas.Length; $i++) {
        $sheet.Cells.Item($i + 1, 1) = $filas[$i]
        # Aplicar negrita a los nombres de fila
        $sheet.Cells.Item($i + 1, 1).Font.Bold = $true
    }
}

# Guardar el archivo en la ruta base
$rutaExcel = Join-Path -Path $rutaBase -ChildPath "Resumen.xlsx"
$workbook.SaveAs($rutaExcel)

# Cerrar Excel
$workbook.Close($true)
$excel.Quit()

# Liberar recursos de COM
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($sheet) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null

Write-Output "Libro de Excel creado en: $rutaExcel"
