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
