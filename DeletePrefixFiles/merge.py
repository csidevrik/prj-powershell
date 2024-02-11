import os
from PyPDF2 import PdfReader, PdfWriter

def mezclar_pdfs(path_a, path_b, archivo_resultante):
    pdf_writer = PdfWriter()

    archivos_a = sorted(os.listdir(path_a))
    archivos_b = sorted(os.listdir(path_b))

    for archivo_a, archivo_b in zip(archivos_a, archivos_b):
        ruta_a = os.path.join(path_a, archivo_a)
        ruta_b = os.path.join(path_b, archivo_b)

        with open(ruta_a, 'rb') as pdf_a, open(ruta_b, 'rb') as pdf_b:
            pdf_reader_a = PdfReader(pdf_a)
            pdf_reader_b = PdfReader(pdf_b)

            # Alternar páginas de A y B
            for pagina_a, pagina_b in zip(pdf_reader_a.pages, pdf_reader_b.pages):
                pdf_writer.add_page(pagina_a)
                pdf_writer.add_page(pagina_b)

    with open(archivo_resultante, 'wb') as resultante:
        pdf_writer.write(resultante)

# Llamada a la función
path_a = r'D:\C\Documents\mezcla\a'
path_b = r'D:\C\Documents\mezcla\b'
archivo_resultante = r'D:\C\Documents\mezcla\resultante.pdf'

mezclar_pdfs(path_a, path_b, archivo_resultante)