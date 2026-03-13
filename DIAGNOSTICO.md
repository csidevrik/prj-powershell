# Diagnóstico y plan de reorganización — prj-powershell

## Estado actual: problemas identificados

### 🔴 Crítico — archivos trackeados en git que NO deberían estarlo

| Archivo / Carpeta | Problema | Acción |
|---|---|---|
| `DeletePrefixFiles/` (completa) | Está en `.gitignore` pero fue committeada antes. Git la sigue rastreando. | `git rm -r --cached DeletePrefixFiles/` |
| `webscraping/etapa/facturas_etapa_sep_2025.csv` | Datos de producción en git | `git rm --cached` + agregar al `.gitignore` |
| `webscraping/etapa/facturas_etapa_sep_2025.debug.json` | Output de debug en git | ídem |
| `webscraping/etapa/facturas_etapa_sep_2025.raw.txt` | Output crudo en git | ídem |
| `pwsh/Networkutils/reporte_red.csv` | Output de scan de red en git | ídem |
| `pwsh/Networkutils/resultado.xml` | Output de escaneo en git | ídem |
| `package-lock.json` | No hay `package.json` — archivo huérfano | `git rm --cached` |

### 🟡 Estructural — dos carpetas con el mismo propósito

`pwsh/` y `scripts.d/` contienen scripts PowerShell de administración Windows.
No hay una razón técnica para tenerlos separados. `scripts.d/` además mezcla
un script Python (`addhostCheckpoint/`) con PowerShell.

**scripts.d/ contiene:**
- `install-basic/` → PowerShell → debería estar en `pwsh/`
- `install-nettools/` → Solo un README → debería estar en `pwsh/`
- `windows-setup/` → PowerShell → debería estar en `pwsh/`
- `addhostCheckpoint/` → **Python** → debería estar en `python/`

### 🟡 Estructural — Python sin un directorio propio

Los scripts Python están dispersos en:
- `webscraping/etapa/` (scraper Playwright)
- `scripts.d/addhostCheckpoint/` (script de hosts para Checkpoint)
- `DeletePrefixFiles/` (app Python/Flet — proyecto separado)

No existe una carpeta `python/` que agrupe los scripts Python del repositorio.

### 🟠 Calidad — archivos con nombres no descriptivos

| Archivo | Problema |
|---|---|
| `pwsh/utils/R.md` | Nombre sin sentido |
| `pwsh/utils/OTRO.md` | Nombre temporal/placeholder |
| `pwsh/utils/README.md` | Contiene HTML crudo copy-paste de ChatGPT (divs, botones, etc.) en lugar de Markdown limpio |
| `DeletePrefixFiles/src/data/facs_vals copy.json` | Nombre con "copy" — archivo borrador/temporal |

### 🟠 Calidad — README.md raíz muy pobre

El README actual tiene 2 líneas útiles y el resto son comentarios HTML. No describe
la estructura del repositorio, qué hace cada carpeta, ni cómo usar los scripts.

---

## Estructura propuesta

```
prj-powershell/
├── pwsh/                          # TODOS los scripts PowerShell
│   ├── CreateSeveralFolders/      (sin cambios)
│   ├── CreateTaskSckedule/        (sin cambios)
│   ├── Networkutils/              (sin cambios — outputs csv/xml removidos)
│   ├── OpenPortFirewallWindows/   (sin cambios)
│   ├── RemoveBluetoothUnknow-win/ (sin cambios)
│   ├── SyncClock/                 (sin cambios)
│   ├── UI/                        (sin cambios)
│   ├── Update-Hosts/              (sin cambios)
│   ├── utils/                     (sin cambios)
│   ├── install-basic/             ← movido desde scripts.d/
│   ├── install-nettools/          ← movido desde scripts.d/
│   └── windows-setup/             ← movido desde scripts.d/
│
├── python/                        # TODOS los scripts Python
│   ├── webscraping/               ← movido desde raíz (webscraping/)
│   │   └── etapa/
│   └── addhostCheckpoint/         ← movido desde scripts.d/
│
├── LICENSE
├── README.md                      (mejorado)
└── .gitignore                     (mejorado)
```

### ¿Qué NO se mueve?
- `DeletePrefixFiles/` — ya está en `.gitignore`. Es un subproyecto separado (app Python/Flet).
  Solo se necesita ejecutar `git rm -r --cached` para que git deje de rastrearlo.

---

## Cambios aplicados

- [x] Archivos de output desvinculados de git (`git rm --cached`)
- [x] `.gitignore` actualizado con reglas para outputs de datos
- [x] `scripts.d/` disuelto — contenido movido a `pwsh/` y `python/`
- [x] `webscraping/` movido a `python/webscraping/`
- [x] `python/` creado como punto único de entrada para scripts Python
- [x] `README.md` reescrito
