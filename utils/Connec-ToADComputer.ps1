# Script para conectarse a un equipo Windows en Active Directory
# Requiere tener instalado el módulo Active Directory

# Importar módulo de Active Directory
Import-Module ActiveDirectory

# Función para conectarse a un equipo remoto
function Connect-ToADComputer {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,
        
        [Parameter(Mandatory=$true)]
        [string]$Username,
        
        [Parameter(Mandatory=$true)]
        [SecureString]$Password
    )
    
    try {
        # Verificar si el equipo existe en AD
        $computer = Get-ADComputer -Identity $ComputerName -ErrorAction Stop
        
        # Crear credenciales
        $credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)
        
        # Establecer conexión remota
        $session = New-PSSession -ComputerName $ComputerName -Credential $credential
        
        Write-Host "Conexión establecida exitosamente con $ComputerName" -ForegroundColor Green
        return $session
    }
    catch {
        Write-Host "Error al conectar: $_" -ForegroundColor Red
    }
}

# Ejemplo de uso:
# $password = ConvertTo-SecureString "TuContraseña" -AsPlainText -Force
# $session = Connect-ToADComputer -ComputerName "NombrePC" -Username "dominio\usuario" -Password $password
$password = ConvertTo-SecureString "Alien..C0venant" -AsPlainText -Force
$session = Connect-ToADComputer -ComputerName "MI-GC-C4-AA-215" -Username "local.emov.gob.ec\cmsiguarik" -Password $password