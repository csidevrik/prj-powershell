# Variables globales
$Script:IsServer = $false
$Script:OSVersion = ""
$Script:OSName = ""
$Script:OSType = ""

# Funciones de output
function Write-Banner { ... }
function Write-Success { ... }
function Write-Info { ... }
function Write-Failure { ... }   # renombrado desde Write-Error
function Write-Warn { ... }      # renombrado desde Write-Warning

# Detección de OS
function Get-SystemType { ... }
function Test-Prerequisites { ... }

# PATH
function Update-EnvironmentPath { ... }

# Verificación de programas
function Test-ProgramInstalled { ... }

# Instalación de un paquete individual
function Install-Package { ... }