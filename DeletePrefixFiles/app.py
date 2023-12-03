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

## SOLO METODOS DE ACCIONES POR COMANDOS


def extract_code_from_filename(folderPath):
    # Utilizamos una expresión regular para buscar un patrón específico (cualquier secuencia de letras mayúsculas y números) en el nombre del archivo.
    match = re.search(r"I[0-9]+", folderPath)
    
    if match:
        # Si se encuentra un patrón, lo extraemos y lo devolvemos.
        return match.group()
    else:
        # Si no se encuentra un patrón, devolvemos None.
        return None

regex1 = "RDD([+-]?(?=\.\d|\d)(?:\d+)?(?:\.?\d*))(?:[Ee]([+-]?\d+))?"
regex2 = "I[0-9]+"


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
    # new_name = secue

    # Imprime el nuevo nombre
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

def main(page: ft.Page):
    page.title = "Octaba directory"
    page.description = "Select a directory to save your files."
    # page.window_bgcolor = ft.colors.TRANSPARENT
    page.window_frameless = False
<<<<<<< HEAD
    page.window_title_bar_hidden = True
    page.bgcolor = ft.colors.with_opacity(0.98, '#01EAD1')
=======
    page.bgcolor = ft.colors.with_opacity(0.90, '#07D2A9')
>>>>>>> ac90733e3cb3cd7be0c61d3a8b945552e4f89192
    page.window_height = 500
    page.window_width = 1000
    page.window_max_width = 1200
    page.window_max_height = 600

    page.appbar = ft.AppBar(
        leading = ft.Icon(ft.icons.DOOR_SLIDING),
        leading_width=40,
        title=ft.Text("Soneto redentor"),
        center_title=False,
        bgcolor=ft.colors.with_opacity(0.98, '#01EAD1')
    )

    # page.title = ft.Text(
    #     style= Text.style(ft.colors.with_opacity(0.98, '#01EAD1'))
    # )

    page.update()

    def check_item_clicked(e):
        e.control.checked = not e.control.checked
        page.update()

    pb = ft.PopupMenuButton(
        items=[
            ft.PopupMenuItem(icon=ft.icons.BROWSER_UPDATED_SHARP,  text="Check with firefox", on_click=lambda e: open_pdf_with_firefox(directory_path.value)),
            ft.PopupMenuItem(icon=ft.icons.BROWSER_UPDATED_SHARP,  text="Check with chrome", on_click=lambda e: open_pdf_with_chrome(directory_path.value)),
            ft.PopupMenuItem(icon=ft.icons.CONTROL_POINT_DUPLICATE_SHARP,  text="Remove duplicates", on_click=lambda e: remove_duplicate_files(directory_path.value)),
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
        selected_files.value = (",".join(map(lambda f: f.name, e.files )) if e.files else "Canceled")
        selected_files.update()

    pick_files_dialog = ft.FilePicker(on_result=pick_files_result)
    selected_files = Text()

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
                ElevatedButton(
                    "Pick files",
                    icon=icons.UPLOAD_FILE,
                    on_click=lambda _: pick_files_dialog.pick_files(allow_multiple=False), 
                    disabled=page.web,
                ),
            ]
        ),
        Row(
            [
                directory_path,
            ]
        ),
    )
    pass

ft.app(target=main)