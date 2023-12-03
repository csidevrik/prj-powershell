import re
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



def main(page: ft.Page):
    page.title = "App for select directory"
    page.description = "Select a directory to save your files."
    page.window_bgcolor = ft.colors.TRANSPARENT
    page.window_frameless = False
    page.window_title_bar_hidden = True
    page.bgcolor = ft.colors.with_opacity(0.98, '#01EAD1')
    page.window_height = 500
    page.window_width = 500
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


    def extract_code_from_filename(filename):
        # Utilizamos una expresión regular para buscar un patrón específico (cualquier secuencia de letras mayúsculas y números) en el nombre del archivo.
        match = re.search(r"I[0-9]+", filename)
        
        if match:
            # Si se encuentra un patrón, lo extraemos y lo devolvemos.
            return match.group()
        else:
            # Si no se encuentra un patrón, devolvemos None.
            return None

    regex1 = "RDD([+-]?(?=\.\d|\d)(?:\d+)?(?:\.?\d*))(?:[Ee]([+-]?\d+))?"
    regex2 = "I[0-9]+"


ft.app(target=main)