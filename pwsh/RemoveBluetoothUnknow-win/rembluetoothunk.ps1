# 1. Obtener los InstanceId de todos los dispositivos JBL Unknown
$jblDevices = Get-PnpDevice | Where-Object {$_.FriendlyName -like '*JBL*' -and $_.Status -eq 'Unknown'}

# 2. Mostrar los que vamos a eliminar
$jblDevices | Format-Table FriendlyName, InstanceId

# 3. Eliminar cada uno usando pnputil
$jblDevices | ForEach-Object {
    Write-Host "Eliminando: $($_.FriendlyName)"
    pnputil /remove-device $_.InstanceId /force
}