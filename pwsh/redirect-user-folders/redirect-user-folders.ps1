# redirect-user-folders.ps1
# Redirige las carpetas conocidas del usuario actual (Documents, Pictures, Music,
# Videos, Desktop, Downloads) a <TargetRoot>\<Carpeta>, moviendo el contenido existente.
#
# IMPORTANTE: si usas OneDrive o Google Drive con "copia de seguridad de carpetas
# conocidas" activa, desactívala ANTES de correr esto (esas apps también controlan
# estas rutas y pueden pelear con el cambio). Vuelve a activarla después, apuntando
# a la nueva ubicación.
#
# Uso:
#   .\redirect-user-folders.ps1                       # usa D:\C\<usuario>
#   .\redirect-user-folders.ps1 -TargetRoot D:\Users\carlos

param(
    [string]$TargetRoot = "D:\C\$env:USERNAME"
)

$ErrorActionPreference = 'Stop'

$driveLetter = Split-Path $TargetRoot -Qualifier
if (-not (Test-Path $driveLetter)) {
    throw "La unidad de destino no existe: $driveLetter"
}

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class KnownFolderMover {
    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    public static extern int SHSetKnownFolderPath(ref Guid folderId, uint flags, IntPtr token, string path);
}
"@

# GUID de cada KNOWNFOLDERID — son constantes de Windows, no cambian entre versiones
$knownFolders = @(
    @{ Name = "Documents"; SpecialFolder = "Personal";  Guid = [Guid]"FDD39AD0-238F-46AF-ADB4-6C85480369C7" },
    @{ Name = "Pictures";  SpecialFolder = "MyPictures"; Guid = [Guid]"33E28130-4E1E-4676-835A-98395C3BC3BB" },
    @{ Name = "Music";     SpecialFolder = "MyMusic";    Guid = [Guid]"4BD8D571-6D19-48D3-AF34-6B7EE99CFF29" },
    @{ Name = "Videos";    SpecialFolder = "MyVideos";   Guid = [Guid]"18989B1D-99B5-455B-841C-AB7C74E4DDFC" },
    @{ Name = "Desktop";   SpecialFolder = "Desktop";    Guid = [Guid]"B4BFCC3A-DB2C-424C-B029-7FE99A87C641" },
    @{ Name = "Downloads"; SpecialFolder = $null;        Guid = [Guid]"374DE290-123F-4565-9164-39C4925E467B" }
)

Write-Host ""
Write-Host "Redirigiendo carpetas de usuario a: $TargetRoot" -ForegroundColor Cyan
Write-Host ""

foreach ($kf in $knownFolders) {
    if ($kf.SpecialFolder) {
        $oldPath = [Environment]::GetFolderPath($kf.SpecialFolder)
    } else {
        # Downloads no existe en [Environment]::SpecialFolder, se resuelve vía Shell
        $oldPath = (New-Object -ComObject Shell.Application).Namespace('shell:Downloads').Self.Path
    }

    $newPath = Join-Path $TargetRoot $kf.Name

    if ($oldPath -eq $newPath) {
        Write-Host "✓ $($kf.Name) ya apunta a $newPath" -ForegroundColor Green
        continue
    }

    Write-Host "→ $($kf.Name): $oldPath -> $newPath" -ForegroundColor Yellow

    New-Item -ItemType Directory -Path $newPath -Force | Out-Null

    if (Test-Path $oldPath) {
        robocopy $oldPath $newPath /E /MOVE /R:1 /W:1 /NFL /NDL /NJH /NJS | Out-Null
    }

    $folderIdRef = $kf.Guid
    $result = [KnownFolderMover]::SHSetKnownFolderPath([ref]$folderIdRef, 0, [IntPtr]::Zero, $newPath)

    if ($result -eq 0) {
        Write-Host "  ✓ Redirigido correctamente" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Error al redirigir (HRESULT $result)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Reiniciando Explorer para refrescar accesos directos..." -ForegroundColor Cyan
Stop-Process -Name explorer -Force
Start-Process explorer.exe

Write-Host ""
Write-Host "Listo. Verifica cada carpeta antes de reactivar OneDrive/Google Drive." -ForegroundColor Green
