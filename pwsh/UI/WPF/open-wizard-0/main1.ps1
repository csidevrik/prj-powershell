Add-Type -AssemblyName PresentationFramework

# Definir el XAML de la interfaz
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Ejemplo WPF con Colores RGB" Height="200" Width="400">
    <Grid>
        <Label Name="lblColored" Width="200" Height="50" VerticalAlignment="Center" HorizontalAlignment="Center" Content="Texto Coloreado"/>
    </Grid>
</Window>
"@

# Cargar el XAML
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# Acceder al label
$label = $window.FindName("lblColored")

# Definir el color de texto y fondo usando RGB
$label.Foreground = New-Object System.Windows.Media.SolidColorBrush (New-Object System.Windows.Media.ColorConverter).ConvertFromString("#FF0000") # Rojo
$label.Background = New-Object System.Windows.Media.SolidColorBrush (New-Object System.Windows.Media.ColorConverter).ConvertFromString("#00FF00") # Verde

# Mostrar la ventana
$window.ShowDialog()
