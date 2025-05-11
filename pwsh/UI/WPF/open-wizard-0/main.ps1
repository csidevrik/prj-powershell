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
$backColor = (Get-Random -InputObject @("red","black","blue","yellow","green"))
$foreColor = (Get-Random -InputObject @("red","black","blue","yellow","green"))
$label.BackColor = $backColor
$label.ForeColor = $foreColor
$form.Controls.Add($label)

# Crear un botón
$button = New-Object System.Windows.Forms.Button
$button.Text = "Click Me"
$button.Size = New-Object System.Drawing.Size(100, 30)
$button.Location = New-Object System.Drawing.Point(100, 100)
$form.Controls.Add($button)

# Evento para el botón
$button.Add_Click({
    [System.Windows.Forms.MessageBox]::Show("Boton Presionado!")
})

# Mostrar el formulario
$form.ShowDialog()
