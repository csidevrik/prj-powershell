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

def open_pdf_with_firefox(folderPath):
    print(folderPath)
    files = os.listdir(folderPath)
    filesPDF = [file for file in files if file.endswith(".pdf")]
    filesPDF.sort(key=lambda x: os.path.getmtime(os.path.join(folderPath, x)), reverse=True)
    contador = 0
    for filePDF in filesPDF:
        contador += 1
        pathComplete = os.path.abspath(os.path.join(folderPath, filePDF))
        print(pathComplete)
        # subprocess.call(["start", "firefox"])
        subprocess.call(f"start firefox --new-tab  {pathComplete}", shell=True)
        print(contador)
        # time.sleep(1)

def open_pdf_with_chrome(folderPath):
    print(folderPath)
    files = os.listdir(folderPath)
    filesPDF = [file for file in files if file.endswith(".pdf")]
    filesPDF.sort(key=lambda x: os.path.getmtime(os.path.join(folderPath, x)), reverse=True)
    contador = 0
    for filePDF in filesPDF:
        contador += 1
        pathComplete = os.path.abspath(os.path.join(folderPath, filePDF))
        print(pathComplete)
        # subprocess.call(["start", "firefox"])
        subprocess.call(f"start chrome --new-tab  {pathComplete}", shell=True)
        print(contador)
        # time.sleep(1)

def main(page: ft.Page):
    page.title = "App for select directory"
    page.description = "Select a directory to save your files."
    page.window_bgcolor = ft.colors.TRANSPARENT
    page.window_frameless = False
    page.bgcolor = ft.colors.with_opacity(0.5, '#07D2A9')
    page.window_height = 500
    page.window_width = 500
    page.window_max_width = 1200
    page.window_max_height = 600
    page.update()

    def check_item_clicked(e):
        e.control.checked = not e.control.checked
        page.update()

    pb = ft.PopupMenuButton(
        items=[
            ft.PopupMenuItem(icon=ft.icons.BROWSER_UPDATED_SHARP, text="Check with firefox", on_click=lambda e: open_pdf_with_firefox(directory_path.value)),
            ft.PopupMenuItem(icon=ft.icons.BROWSER_UPDATED_SHARP, text="Check with chrome", on_click=lambda e: open_pdf_with_chrome(directory_path.value)),
        ]
    )
    page.add(pb)

    # Open directory dialog
    def get_directory_result(e: FilePickerResultEvent):
        directory_path.value = e.path if e.path else "Cancelled!"
        directory_path.update()

    get_directory_dialog = FilePicker(on_result=get_directory_result)
    directory_path = Text()

    # hide all dialogs in overlay
    page.overlay.extend([get_directory_dialog])

    page.add(
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
    )
    pass





ft.app(target=main)