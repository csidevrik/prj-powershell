# Definir la ruta del archivo hosts
$hostsFile = "$env:windir\System32\Drivers\etc\hosts"

# Nuevo contenido
$newContent = @"
# Copyright (c) 1993-2009 Microsoft Corp.
#
# This is a sample HOSTS file used by Microsoft TCP/IP for Windows.
#
127.0.0.1       localhost
::1             localhost
# 127.0.0.3       www.facebook.com       first local server
# 127.0.0.4       chatgpt.com            second local server
"@

# Escribir el nuevo contenido
try {
    Set-Content -Path $hostsFile -Value $newContent -Force
    Write-Host "Archivo hosts actualizado exitosamente"
    
    # Limpiar caché DNS [[2](https://superuser.com/questions/1509619/my-host-file-is-not-working-on-windows-10)]
    Start-Process "ipconfig.exe" -ArgumentList "/flushdns" -Verb RunAs
    Write-Host "Cache DNS limpiado exitosamente"
} catch {
    Write-Host "Error: $_"
}