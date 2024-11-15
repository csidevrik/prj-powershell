""" import sys
import pathlib
import pymupdf  # Asegúrate de tener instalada la versión correcta de PyMuPDF

# Obtener el nombre del archivo del argumento de la línea de comandos
fname = sys.argv[1]

# Asegurarse de que se trabaja con un archivo PDF
if not fname.lower().endswith('.pdf'):
    raise ValueError("El archivo debe ser un PDF.")

# Abrir el documento y extraer el texto en formato Markdown
with pymupdf.open(fname) as doc:
    markdown_text = '\n\n'.join([f"### Página {i + 1}\n\n{page.get_text('text')}" for i, page in enumerate(doc)])

# Guardar el texto como un archivo de Markdown
output_path = pathlib.Path(fname).with_suffix('.md')
output_path.write_text(markdown_text, encoding='utf-8')

print(f"Archivo Markdown generado: {output_path}")
 """

import pymupdf

# Cargar el archivo PDF
doc = pymupdf.open("001-200-000022198.pdf")
page = doc.load_page(0)  # Cargar la primera página

# Definir la región de la que quieres extraer texto (x0, y0, x1, y1)
rectNretencion = pymupdf.Rect(320, 100, 685, 120)  # Reemplazar con coordenadas calculadas

# Extraer texto de la región especificada
region_textNretencion = page.get_text("text", clip=rectNretencion)
print("Texto extraído:", region_textNretencion)

# +++++++++++++++++++++++++++++++++
# +                               +
# +                               +
# +                               +
# +               +  320*100 ++++++
# +               +               +
# +               +               +
# +               +               +
# +++++++++++++++++++++++++++++++++ 685*120

#    (x0,y0)
# -> 320*100
# +++++++++++++++++
# +               +           
# +               +           
# +               +     (x1,y1)
# +++++++++++++++++ -> 685*120

# Definir la región de la que quieres extraer texto (x0, y0, x1, y1)
rectNfactura = pymupdf.Rect(10, 480, 203, 540)  # Reemplazar con coordenadas calculadas

# Extraer texto de la región especificada
region_textNfactura = page.get_text("text", clip=rectNfactura)
print("Texto extraído:", region_textNfactura)





doc.close()
