param (
    [string]$RangoIP = "192.169.100.0/24",
    [string]$ArchivoXML = "resultado.xml",
    [string]$ArchivoCSV = "reporte_red.csv"
)

Write-Host "📡 Escaneando la red: $RangoIP..." -ForegroundColor Cyan

# Ejecutar nmap con salida en XML
$nmap = "nmap"
$nmapArgs = "-sn $RangoIP -oX $ArchivoXML"
Start-Process -FilePath $nmap -ArgumentList $nmapArgs -NoNewWindow -Wait

Write-Host "✅ Escaneo completado. Procesando resultados..." -ForegroundColor Yellow

# Cargar XML
[xml]$xml = Get-Content $ArchivoXML

# Extraer hosts activos
$nmapHosts = $xml.nmaprun.host | Where-Object { $_.status.state -eq "up" }

# Generar reporte
$reporte = foreach ($h in $nmapHosts) {
    $ip = $h.address | Where-Object { $_.addrtype -eq "ipv4" } | Select-Object -ExpandProperty addr
    $mac = $h.address | Where-Object { $_.addrtype -eq "mac" } | Select-Object -ExpandProperty addr
    $vendor = $h.address | Where-Object { $_.addrtype -eq "mac" } | Select-Object -ExpandProperty vendor

    [PSCustomObject]@{
        IP      = $ip
        MAC     = $mac
        Vendor  = $vendor
    }
}

# Verificar si se encontró algo
if ($reporte.Count -eq 0) {
    Write-Host "⚠️ No se encontraron dispositivos activos." -ForegroundColor DarkYellow
} else {
    $reporte | Format-Table -AutoSize
    $reporte | Export-Csv -Path $ArchivoCSV -NoTypeInformation -Encoding UTF8
    Write-Host "`n📁 Reporte guardado en: $ArchivoCSV" -ForegroundColor Green
}
