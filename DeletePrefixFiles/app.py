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
    page.bgcolor = ft.colors.with_opacity(0.5, '#07D2A9')
    page.window_height = 500
    page.window_width = 500
    page.window_max_width = 1200
    page.window_max_height = 600
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


ft.app(target=main)