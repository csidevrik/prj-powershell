# Get-Current-Date PowerShell Function

Este script en PowerShell proporciona una función llamada `Get-Current-Date` que permite obtener la fecha y/o la hora en diferentes formatos. La función utiliza un conjunto de parámetros para especificar el formato deseado.

## Parámetros

La función `Get-Current-Date` tiene los siguientes parámetros:

- **`-JustDate`**: Retorna solo la fecha en el formato `AAAA-MM-DD`.
- **`-JustHour`**: Retorna solo la hora en el formato `HHhMMmSSs`.
- **`-DayAndHour`**: Retorna la fecha y hora en el formato `AAAAMMDD-HHhMMmSSs`.
- **`-FullDate`** (por defecto): Retorna la fecha completa con hora en el formato `AAAAMMDDHHMMSS`.

### Explicación de los parámetros

1. **`-JustDate`**:

   - **Formato de salida**: `AAAA-MM-DD`.
   - **Ejemplo**: Si la fecha actual es 23 de agosto de 2024, el formato de salida sería `2024-AGO-23`.
   - **Construcción del formato**:
     ```powershell
     $resultado = "{0:D4}{1:D2}{2}-{3:D2}_" -f `
        $actualDate.Year, `
        $actualDate.Month, `
        $months[$actualDate.Month], `
        $actualDate.Day
     ```

     - **`{0:D4}`**: Año completo con cuatro dígitos.
     - **`{1:D2}`**: Mes como número de dos dígitos.
     - **`{2}`**: Nombre del mes en español.
     - **`{3:D2}`**: Día del mes como dos dígitos.
2. **`-JustHour`**:

   - **Formato de salida**: `HHhMMmSSs`.
   - **Ejemplo**: Si la hora actual es 15:45:30, el formato de salida sería `15h45m30s`.
   - **Construcción del formato**:
     ```powershell
     $resultado = "{0:D2}h{1:D2}m{2:D2}s" -f `
        $actualDate.Hour, `
        $actualDate.Minute, `
        $actualDate.Second
     ```

     - **`{0:D2}`**: Hora como dos dígitos.
     - **`{1:D2}`**: Minutos como dos dígitos.
     - **`{2:D2}`**: Segundos como dos dígitos.
3. **`-DayAndHour`**:

   - **Formato de salida**: `AAAAMMDD-HHhMMmSSs`.
   - **Ejemplo**: Si la fecha y hora actual es 23 de agosto de 2024, 15:45:30, el formato de salida sería `20240823-15h45m30s`.
   - **Construcción del formato**:
     ```powershell
     $resultado = "{0}{1:D2}{2:D2}-{3:D2}h{4:D2}m{5:D2}s" -f `
        $actualDate.Year, `
        $actualDate.Month, `
        $actualDate.Day, `
        $actualDate.Hour, `
        $actualDate.Minute, `
        $actualDate.Second
     ```

     - **`{0}`**: Año completo.
     - **`{1:D2}`**: Mes como dos dígitos.
     - **`{2:D2}`**: Día como dos dígitos.
     - **`{3:D2}`**: Hora como dos dígitos.
     - **`{4:D2}`**: Minutos como dos dígitos.
     - **`{5:D2}`**: Segundos como dos dígitos.
4. **`-FullDate`** (por defecto):

   - **Formato de salida**: `AAAAMMDDHHMMSS`.
   - **Ejemplo**: Si la fecha y hora actual es 23 de agosto de 2024, 15:45:30, el formato de salida sería `20240823154530`.
   - **Construcción del formato**:
     ```powershell
     $resultado = "{0:D4}{1:D2}{2:D2}{3:D2}{4:D2}{5:D2}" -f `
        $actualDate.Year, `
        $actualDate.Month, `
        $actualDate.Day, `
        $actualDate.Hour, `
        $actualDate.Minute, `
        $actualDate.Second
     ```

     - **`{0:D4}`**: Año completo con cuatro dígitos.
     - **`{1:D2}`**: Mes como dos dígitos.
     - **`{2:D2}`**: Día como dos dígitos.
     - **`{3:D2}`**: Hora como dos dígitos.
     - **`{4:D2}`**: Minutos como dos dígitos.
     - **`{5:D2}`**: Segundos como dos dígitos.

## Ejemplos de Uso

```powershell
# Para obtener solo la fecha:
Get-Current-Date -JustDate

# Para obtener solo la hora:
Get-Current-Date -JustHour

# Para obtener la fecha y hora (con mes y día):
Get-Current-Date -DayAndHour

# Para obtener la fecha completa (default):
Get-Current-Date
```
