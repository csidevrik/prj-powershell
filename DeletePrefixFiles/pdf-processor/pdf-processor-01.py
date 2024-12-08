from docling import Document

# Cargar el archivo PDF
doc = Document("001-200-000022198.pdf")

# Cargar la primera página
page = doc.pages[0]

# Definir regiones para extraer texto
rectNretencion = (320, 100, 685, 120)
rectNfactura = (10, 480, 203, 540)

# Extraer texto usando las regiones definidas
region_textNretencion = page.extract_text(region=rectNretencion)
region_textNfactura = page.extract_text(region=rectNfactura)

# Mostrar resultados
print("Texto extraído de retención:", region_textNretencion)
print("Texto extraído de factura:", region_textNfactura)
