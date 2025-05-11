function Get-Current-Date {
    [CmdletBinding(DefaultParameterSetName = "FullDate")]
    param (
        [Parameter(ParameterSetName = "JustDate")]
        [switch]$JustDate,

        [Parameter(ParameterSetName = "JustHour")]
        [switch]$JustHour,

        [Parameter(ParameterSetName = "DayAndHour")]
        [switch]$DayAndHour
    )

    # Mapa de months en español
    $months = @{
        1  = "ENE"
        2  = "FEB"
        3  = "MAR"
        4  = "ABR"
        5  = "MAY"
        6  = "JUN"
        7  = "JUL"
        8  = "AGO"
        9  = "SEP"
        10 = "OCT"
        11 = "NOV"
        12 = "DIC"
    }

    # Obtener la fecha y hora actual
    $actualDate = Get-Date

    switch ($PsCmdlet.ParameterSetName) {
        "JustDate" {
            $resultado = "{0:D4}{1:D2}{2}-{3:D2}_" -f `
                $actualDate.Year, `
                $actualDate.Month, `
                $months[$actualDate.Month], `
                $actualDate.Day    
        }
        "JustHour" {
            # Formato para sólo la hora
            $resultado = "{0:D2}h{1:D2}m{2:D2}s" -f `
                $actualDate.Hour, `
                $actualDate.Minute, `
                $actualDate.Second
        }
        "DayAndHour" {
            # Formato para el mes y día, seguido de la hora
            $resultado = "{0}{1:D2}{2:D2}-{3:D2}h{4:D2}m{5:D2}s" -f `
                $actualDate.Year, `
                $actualDate.Month, `
                $actualDate.Day, `
                $actualDate.Hour, `
                $actualDate.Minute, `
                $actualDate.Second
        }
        "FullDate" {
            # Formato completo de fecha y hora
            $resultado = "{0:D4}{1:D2}{2:D2}{3:D2}{4:D2}{5:D2}" -f `
                $actualDate.Year, `
                $actualDate.Month, `
                $actualDate.Day, `
                $actualDate.Hour, `
                $actualDate.Minute, `
                $actualDate.Second
        }
    }

    # Mostrar el resultado
    Write-Output $resultado
}

# Ejemplos de uso:
# Para obtener solo la fecha:
Get-Current-Date -JustDate

# Para obtener solo la hora:
Get-Current-Date -JustHour

# Para obtener la fecha y hora (con mes y día):
Get-Current-Date -DayAndHour

# Para obtener la fecha completa (default):
Get-Current-Date