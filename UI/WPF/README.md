# WPF Windows Presentation Framework

## INTRODUCCION

Este es mi resumen por ahora de WPFde powershell, WPF es un framework UI que es un motor de renderizado basado en vectores, construido para tomar ventaja de hardware grafico moderno.

WPF provee un conjunto comprensible de componentes para el desarrollo de aplicaciones en windows.


Bueno vamos a ver un ejemplo

## EJEMPLOS

Example 01. Hola mundo con WPF


```
Add-Type -AssemblyName System.Windows.Forms

# Crear el formulario
$form = New-Object System.Windows.Forms.Form
$form.Text = "Ejemplo de Interfaz Gráfica"
$form.Size = New-Object System.Drawing.Size(300, 200)
$form.StartPosition = "CenterScreen"

# Crear una etiqueta
$label = New-Object System.Windows.Forms.Label
$label.Text = "Hola, Mundo!"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(100, 50)
$form.Controls.Add($label)

# Crear un botón
$button = New-Object System.Windows.Forms.Button
$button.Text = "Click Me"
$button.Size = New-Object System.Drawing.Size(100, 30)
$button.Location = New-Object System.Drawing.Point(100, 100)
$form.Controls.Add($button)

# Evento para el botón
$button.Add_Click({
    [System.Windows.Forms.MessageBox]::Show("Botón Clickado!")
})

# Mostrar el formulario
$form.ShowDialog()
```


Add-Type -AssemblyName System.Windows.Forms



# Crear el formulario

$form = New-Object System.Windows.Forms.Form

$form.Text = "Ejemplo de Interfaz Gráfica"

$form.Size = New-Object System.Drawing.Size(300, 200)

$form.StartPosition = "CenterScreen"



# Crear una etiqueta

$label = New-Object System.Windows.Forms.Label

$label.Text = "Hola, Mundo!"

$label.AutoSize = $true

$label.Location = New-Object System.Drawing.Point(100, 50)

$form.Controls.Add($label)



# Crear un botón

$button = New-Object System.Windows.Forms.Button

$button.Text = "Click Me"

$button.Size = New-Object System.Drawing.Size(100, 30)

$button.Location = New-Object System.Drawing.Point(100, 100)

$form.Controls.Add($button)



# Evento para el botón

$button.Add_Click({

    [System.Windows.Forms.MessageBox]::Show("Botón Clickado!")

})



# Mostrar el formulario

$form.ShowDialog()
