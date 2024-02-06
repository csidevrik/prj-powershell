import json
import hashlib
import os
import re
import subprocess
import time
import flet as ft
from flet import (
    ElevatedButton,
    FilePicker,
    FilePickerResultEvent,
    Page,
    Row,
    Text,
    icons,
)
import xml.etree.ElementTree as ET


# regex1 = "RDD([+-]?(?=\.\d|\d)(?:\d+)?(?:\.?\d*))(?:[Ee]([+-]?\d+))?"
regex1 = r"RDD([+-]?(?=\.\d|\d)(?:\d+)?(?:\.?\d*))(?:[Ee]([+-]?\d+))?"
regex2 = "I[0-9]+"
## SOLO METODOS DE ACCIONES POR COMANDOSy metodos

class Registro:
    def __init__(self, code_inst, number_fac, value_serv):
        self.code_inst = code_inst
        self.number_fac = number_fac
        self.value_serv = value_serv

def extract_code_from_filename(folderPath):
    # Utilizamos una expresión regular para buscar un patrón específico (cualquier secuencia de letras mayúsculas y números) en el nombre del archivo.
    match = re.search(r"I[0-9]+", folderPath)
    if match:
        # Si se encuentra un patrón, lo extraemos y lo devolvemos.
        return match.group()
    else:
        # Si no se encuentra un patrón, devolvemos None.
        return None


def remove_duplicate_files(folder_path):
    files = os.listdir(folder_path)
    # Agrupa los archivos por su valor de hash SHA-256
    grouped_files = {}
    for file_name in files:
        file_path = os.path.join(folder_path, file_name)
        with open(file_path, 'rb') as f:
            file_hash = hashlib.sha256(f.read()).hexdigest()

        if file_hash not in grouped_files:
            grouped_files[file_hash] = []

        grouped_files[file_hash].append(file_path)

    # Elimina los archivos duplicados
    for file_group in grouped_files.values():
        oldest_file = min(file_group, key=lambda x: os.path.getctime(x))
        for file_path in file_group:
            if file_path != oldest_file:
                os.remove(file_path)

def remove_prefix_files_pdf(folder_path, prefix):
    # Obtener la lista de archivos en la carpeta
    files = os.listdir(folder_path)
    files_pdf = [file for file in files if file.lower().endswith(".pdf")]

    # Iterar a través de los archivos PDF y renombrarlos
    for file_pdf in files_pdf:
        # Obtener el nombre del archivo sin extensión
        nombre_sin_extension = os.path.splitext(file_pdf)[0]

        # Verificar si el nombre del archivo PDF comienza con el prefijo dado
        if nombre_sin_extension.startswith(prefix):
            # Eliminar el prefijo del nombre del archivo PDF
            nuevo_nombre = nombre_sin_extension[len(prefix):]

            # Construir el nuevo nombre del archivo PDF
            nuevo_nombre_pdf = nuevo_nombre + ".pdf"

            # Ruta completa del archivo original y nuevo
            ruta_archivo_original = os.path.join(folder_path, file_pdf)
            ruta_archivo_nuevo = os.path.join(folder_path, nuevo_nombre_pdf)

            # Renombrar el archivo PDF
            os.rename(ruta_archivo_original, ruta_archivo_nuevo)

def update_json_with_xml_data(directory_path, json_path):
    # Cargar el archivo JSON
    with open(json_path, 'r') as json_file:
        data = json.load(json_file)

    # Iterar sobre los archivos XML en el directorio
    for filename in os.listdir(directory_path):
        if filename.lower().endswith('.xml'):
            xml_file_path = os.path.join(directory_path, filename)

            # Obtener datos de la factura del archivo XML
            factura_xml = extract_xml_data(xml_file_path)

            # Buscar el registro correspondiente en el archivo JSON
            for registro in data["facs"]["registro"]:
                if registro.code_inst == factura_xml.code_inst:
                    # Actualizar los valores en el registro del JSON
                    registro.number_fac = factura_xml.number_fac
                    registro.value_serv = factura_xml.value_serv
                    break  # Romper el bucle una vez que se encuentra el registro correspondiente

    # Guardar el archivo JSON actualizado
    with open(json_path, 'w') as json_file:
        json.dump(data, json_file, indent=2)

def process_all_xml_files(directory_path):
    registros = []

    # Asegúrate de que el directorio exista
    if not os.path.exists(directory_path):
        print(f"El directorio {directory_path} no existe.")
        return

    # Recorre todos los archivos en el directorio
    for filename in os.listdir(directory_path):
        if filename.endswith(".xml"):
            xml_file_path = os.path.join(directory_path, filename)

            # Extrae los datos del archivo XML
            registro = extract_xml_data(xml_file_path)

            # Agrega el registro a la lista
            registros.append({
                'code_inst': registro.code_inst,
                'number_fac': registro.number_fac,
                'value_serv': registro.value_serv
            })

    # Guarda la lista de registros en un archivo JSON
    json_path = os.path.join(directory_path, 'registros.json')
    with open(json_path, 'w') as json_file:
        json.dump(registros, json_file, indent=4)

    print(f"Se han procesado los archivos XML en {directory_path}.")
    print(f"Se han guardado los registros en {json_path}.")


def extract_xml_data(xml_file_path):
    with open(xml_file_path, 'r', encoding='utf-8') as file:
        xml_content = file.read()
    # Declara el texto del inicio y el fin para la extracción
    start_limit = '<infoTributaria>'
    end_limit = '</infoAdicional>'

    # Encuentra los índices de inicio y fin
    start_index = xml_content.find(start_limit)
    end_index = xml_content.find(end_limit, start_index)

    # Extrae la parte deseada del contenido
    extracted_xml = xml_content[start_index:end_index + len(end_limit)]
    extracted_xml_fac = f"<factura>\n{extracted_xml}\n</factura>"

    root = ET.fromstring(extracted_xml_fac)

    # Obtén los elementos deseados usando XPath
    estab = root.find(".//estab").text
    pto_em = root.find(".//ptoEmi").text
    secue = root.find(".//secuencial").text
    codigo = root.find('.//campoAdicional[@nombre="Instalacion"]').text

    numero_factura = f"FAC{estab}{pto_em}{secue}"


    valor_servicio = root.find(".//totalSinImpuestos").text

    # Retornar un objeto Registro con los datos relevantes
    print(codigo)
    print(numero_factura)
    print(valor_servicio)

    return Registro(code_inst=codigo, number_fac=numero_factura, value_serv=valor_servicio)

def rename_files_with_attributes(folder_path):
    # Ruta de la carpeta "corregir"
    ruta_corregir = os.path.join(folder_path, "corregir")
    print(ruta_corregir)

    # Lista de archivos en la carpeta
    files = os.listdir(folder_path)

    # Filtra los archivos .xml en la carpeta
    xml_files = [file for file in files if file.lower().endswith(".xml")]

    for xml_file in xml_files:
        # Obtener el nuevo nombre del archivo XML
        new_name = extract_xml_content(os.path.join(folder_path, xml_file))

        # Construir el nombre del archivo PDF con la misma base
        pdf_file_name = os.path.splitext(xml_file)[0] + ".pdf"

        # Renombrar el archivo XML
        os.rename(os.path.join(folder_path, xml_file), os.path.join(folder_path, f"{new_name}.xml"))

        # Renombrar el archivo PDF
        os.rename(os.path.join(folder_path, pdf_file_name), os.path.join(folder_path, f"{new_name}.pdf"))

def extract_xml_content(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        xml_content = file.read()

    # Declara el texto del inicio y el fin para la extracción
    start_limit = '<infoTributaria>'
    end_limit = '</infoAdicional>'

    # Encuentra los índices de inicio y fin
    start_index = xml_content.find(start_limit)
    end_index = xml_content.find(end_limit, start_index)

    # Extrae la parte deseada del contenido
    extracted_xml = xml_content[start_index:end_index + len(end_limit)]
    extracted_xml_fac = f"<factura>\n{extracted_xml}\n</factura>"

    root = ET.fromstring(extracted_xml_fac)

    # Obtén los elementos deseados usando XPath
    estab = root.find(".//estab").text
    pto_em = root.find(".//ptoEmi").text
    secue = root.find(".//secuencial").text
    codigo = root.find('.//campoAdicional[@nombre="Instalacion"]').text

    # Crea el nuevo nombre
    new_name = f"FAC{estab}{pto_em}{secue}-{codigo}"

    print(new_name)
    return new_name

def open_pdf_with_browser(folder_path, browser_command):
    files = os.listdir(folder_path)
    filesPDF = [file for file in files if file.endswith(".pdf")]
    filesPDF.sort(key=lambda x: os.path.getmtime(os.path.join(folder_path,x)), reverse=True)
    contador = 0
    for filePDF in filesPDF:
        contador += 1
        pathComplete = os.path.abspath(os.path.join(folder_path, filePDF))
        # print(pathComplete)
        subprocess.run(f"{browser_command} --new-tab {pathComplete}", shell=True)
        # print(contador)

def open_pdf_with_firefox(folder_path):
    open_pdf_with_browser(folder_path, "start firefox")

def open_pdf_with_chrome(folder_path):
    open_pdf_with_browser(folder_path, "start chrome")  


if __name__ == "__main__":
    # Flet application for desktop GUI definition
    def main(page: ft.Page):
        #Pick files dialog
        page.title = "Octaba facturas"
        page.padding = 0
        page.description = "APP for try facturas"
        # page.window_bgcolor = ft.colors.TRANSPARENT
        page.window_frameless = False
        page.bgcolor = ft.colors.with_opacity(0.90, '#07D2A9')
        page.window_height = 500
        page.window_width = 1000
        page.window_max_width = 1200
        page.window_max_height = 600

        page.appbar = ft.AppBar(
            leading = ft.Icon(ft.icons.DOOR_SLIDING),
            leading_width=100,
            title=ft.Text("App facturas"),
            center_title=True,
            bgcolor=ft.colors.with_opacity(0.90, '#07D2A9')
        )

        page.update()

        # def check_item_clicked(e):
        #     e.control.checked = not e.control.checked
        #     page.update()

        pb = ft.PopupMenuButton(
            items=[
                ft.PopupMenuItem(
                    icon=ft.icons.BROWSER_UPDATED_SHARP,  text="Check with firefox", on_click=lambda e: open_pdf_with_firefox(directory_path.value)
                    ),
                ft.PopupMenuItem(
                    icon=ft.icons.BROWSER_UPDATED_SHARP,  text="Check with chrome", on_click=lambda e: open_pdf_with_chrome(directory_path.value)
                    ),
                ft.PopupMenuItem(
                    icon=ft.icons.CONTROL_POINT_DUPLICATE_SHARP,  text="Remove duplicates", on_click=lambda e: remove_duplicate_files(directory_path.value)
                    ),
                ft.PopupMenuItem(
                    icon=ft.icons.TEXT_FORMAT_ROUNDED,  text="Remove prefix RIDE", on_click=lambda e: remove_prefix_files_pdf(directory_path.value,"RIDE_")
                    ),
                ft.PopupMenuItem(
                    icon=ft.icons.TEXT_FORMAT_ROUNDED,  text="Rename files using the xml", on_click=lambda e: rename_files_with_attributes(directory_path.value)
                    ),
                ft.PopupMenuItem(
                    icon=ft.icons.TEXT_FORMAT_ROUNDED,  text="Process all xml files for json", on_click=lambda e: process_all_xml_files(directory_path.value)
                    ),
            ]
        )
        page.add(pb)

        # Open directory dialog
        def get_directory_result(e: FilePickerResultEvent):
            directory_path.value = e.path if e.path else "Cancelled!"
            directory_path.update()

        get_directory_dialog = FilePicker(on_result=get_directory_result)
        directory_path = Text()

        def pick_files_result(e: FilePickerResultEvent):
            selected_files.value = (
                ",".join(map(lambda f: f.name, e.files )) if e.files else "Canceled!"
            )
            selected_files.update()

        pick_files_dialog = ft.FilePicker(on_result=pick_files_result)
        selected_files = Text()

        page.add(directory_path)
        page.add(selected_files)

        # hide all dialogs in overlay
        page.overlay.extend([get_directory_dialog])
        page.overlay.append(pick_files_dialog)

        page.add(
            Row(
                
            ),
            Row(
                [
                    ElevatedButton(
                        "Open directory",
                        icon=icons.FOLDER_OPEN,
                        on_click=lambda _: get_directory_dialog.get_directory_path(),
                        disabled=page.web,
                    ), 
                    directory_path,
                ]
            ),
            Row(
                [   
                    ElevatedButton(
                        "Pick files",
                        icon=icons.UPLOAD_FILE,
                        on_click=lambda _: pick_files_dialog.pick_files(
                            allow_multiple=True
                        ), 
                        disabled=page.web,
                    ),
                    selected_files,
                ]
            ),
        )
    ft.app(target=main)