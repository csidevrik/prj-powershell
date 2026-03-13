# prj-powershell

Scripts de automatización para administración de sistemas Windows y tareas de utilidad general.
Incluye PowerShell, Python y TypeScript.

---

## Estructura

```
prj-powershell/
├── pwsh/          # Scripts PowerShell — automatización Windows
└── python/        # Scripts Python — utilidades y web scraping
```

---

## pwsh/ — PowerShell

| Carpeta | Descripción |
|---|---|
| `CreateSeveralFolders/` | Crea estructuras de carpetas y pestañas en Excel de forma automática |
| `CreateTaskSckedule/` | Instala una tarea programada en el Programador de tareas de Windows |
| `Networkutils/` | Escaneo de red, obtener info del sistema (`Get-Screenfetch`) |
| `OpenPortFirewallWindows/` | Abre un puerto en el Firewall de Windows |
| `RemoveBluetoothUnknow-win/` | Elimina dispositivos Bluetooth desconocidos |
| `SyncClock/` | Sincroniza el reloj del sistema |
| `UI/WPF/` | Ejemplos de interfaces gráficas con WPF en PowerShell |
| `Update-Hosts/` | Actualiza el archivo `hosts` del sistema |
| `utils/` | Funciones reutilizables: fecha formateada, conectar a equipo AD, verificar soporte de VM |
| `install-basic/` | Instalación básica de herramientas en Windows vía `winget` |
| `install-nettools/` | Instalación de herramientas de red |
| `windows-setup/` | Setup modular de Windows: core, OpenSSH, winget |

---

## python/ — Python

| Carpeta | Descripción |
|---|---|
| `webscraping/etapa/` | Extrae facturas electrónicas desde el portal de ETAPA EP. Soporta Python (Playwright) y TypeScript. |
| `addhostCheckpoint/` | Agrega entradas de hosts para equipos Checkpoint desde un archivo CSV |

---

## Uso rápido

### Abrir un puerto en el Firewall
```powershell
.\pwsh\OpenPortFirewallWindows\openport.ps1 -Port 8080 -Protocol TCP
```

### Sincronizar el reloj
```powershell
.\pwsh\SyncClock\main.ps1
```

### Obtener la fecha en formato personalizado
```powershell
. .\pwsh\utils\Get-Current-Date.ps1
Get-Current-Date -JustDate      # 202408AGO_23
Get-Current-Date -JustHour      # 15h45m30s
Get-Current-Date -DayAndHour    # AGO23_15h45m30s
Get-Current-Date                # 202408_AGO23_154530
```

### Scraping de facturas ETAPA
```bash
cd python/webscraping/etapa
pip install playwright
playwright install chromium
python scrape_etapa.py --ruc 0160049360001 --year 2025 --month Septiembre --outfile out.csv
```

---

## Notas

- Los archivos de output (CSV, XML, JSON de debug) están en `.gitignore` y no se versionan.
- `DeletePrefixFiles/` es un subproyecto independiente (app Python/Flet). Existe localmente
  pero no está rastreado por este repositorio.
