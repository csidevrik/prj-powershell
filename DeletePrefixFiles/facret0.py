import flet as ft
import os

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

async def main(page: ft.Page):
    # page.drawer = ft.NavigationDrawer(
    #     controls=[
    #         # ft.Container(height=12),
    #         ft.NavigationDrawerDestination(
    #             label="Delete duplicates",
    #             icon=ft.icons.DOOR_BACK_DOOR_OUTLINED,
    #             selected_icon_content=ft.Icon(ft.icons.DOOR_BACK_DOOR),
    #             # on_click=lambda e: open_pdf_with_firefox(directory_path.value)
    #         ),
    #         ft.NavigationDrawerDestination(
    #             label="Delete duplicates",
    #             icon=ft.icons.DOOR_BACK_DOOR_OUTLINED,
    #             selected_icon_content=ft.Icon(ft.icons.DOOR_BACK_DOOR),
    #             # on_click=lambda e: open_pdf_with_firefox(directory_path.value)
    #         ),
    #         ft.Divider(thickness=1),
    #         ft.NavigationDrawerDestination(
    #             icon_content=ft.Icon(ft.icons.REMOVE_CIRCLE_OUTLINE),
    #             label="Remove prefix RIDE",
    #             selected_icon=ft.icons.REMOVE_CIRCLE,
    #             # on_click=lambda e: open_pdf_with_firefox(directory_path.value)
    #         ),
    #         ft.NavigationDrawerDestination(
    #             icon_content=ft.Icon(ft.icons.PHONE_OUTLINED),
    #             label="Rename files using the xml",
    #             selected_icon=ft.icons.PHONE,
    #         ),
    #         ft.NavigationDrawerDestination(
    #             icon_content=ft.Icon(ft.icons.FILE_PRESENT_OUTLINED),
    #             label="Process al xml files and get json",
    #             selected_icon=ft.icons.FILE_PRESENT,
    #         ),
    #     ],
    # )
    # def show_drawer(e):
    #     page.drawer.open = True
    #     page.drawer.update()

    # page.add(ft.ElevatedButton("Show drawer", on_click=show_drawer))
    page.title = "Facturas y Retenciones"
    page.padding = 0
    # page.window_title_bar_hidden = True
    page.window_resizable = True
    # page.window_frameless = False
    page.bgcolor = ft.colors.with_opacity(0.90, '#07D2A9')
    page.window_height = 500
    page.window_width = 1000
    page.window_max_width = 1200
    page.window_max_height = 600
    

    leftC = ft.Container(
        width=300,height=400,
        content=ft.ElevatedButton("Elevated Button in Container"),
        bgcolor=ft.colors.YELLOW,
        padding=5,
        border=ft.border.all(),
    )
    rightC = ft.Container(
        width=300,height=400,border=ft.border.all(),
    )
    
    row = ft.Row(spacing=0, controls=[
        leftC,
        rightC
    ])
    container = ft.Container(
        width=1000,
        height=600,
        alignment=ft.alignment.center,
        bgcolor="#1f1f1f",
    )

    await page.add_async(container)
    await page.update_async()
ft.app(target=main)