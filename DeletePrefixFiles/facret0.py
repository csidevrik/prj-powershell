import flet as ft
import os

# if  __name__ == "__main__":
#     async def check_item_clicked(e):
#         e.control.checked = not e.control.checked
#         page.update()
    
#     async def main(page: ft.Page):
#         page.appbar = ft.AppBar(
#             leading=ft.Icon(ft.icons.PALETTE),
#             leading_width=40,
#             title=ft.Text("facret space"),
#             center_title=False,
#             bgcolor=ft.colors.SURFACE_TINT,
#             actions=[
#                 ft.IconButton(ft.icons.WB_SUNNY_OUTLINED),
#                 ft.IconButton(ft.icons.FILTER_3),
#                 ft.PopupMenuButton(
#                     items=[
#                         ft.PopupMenuItem(text="File"),
#                         ft.PopupMenuItem(),
#                         ft.PopupMenuItem(
#                             text="Exit", checked=False, on_click=check_item_clicked
#                         ),
#                     ]
#                 ),
#             ],
#             )
#         # page.add()

#         contenedor = ft.Container(width=1920, height=1080 ,bgcolor='#78a083', alignment=ft.alignment.top_center)
#         await page.add_async(contenedor)
#         pass
#     ft.app(target=main)

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
    page.drawer = ft.NavigationDrawer(
        controls=[
            # ft.Container(height=12),
            ft.NavigationDrawerDestination(
                label="Delete duplicates",
                icon=ft.icons.DOOR_BACK_DOOR_OUTLINED,
                selected_icon_content=ft.Icon(ft.icons.DOOR_BACK_DOOR),
                on_click=lambda e: open_pdf_with_firefox(directory_path.value)
            ),
            ft.NavigationDrawerDestination(
                label="Delete duplicates",
                icon=ft.icons.DOOR_BACK_DOOR_OUTLINED,
                selected_icon_content=ft.Icon(ft.icons.DOOR_BACK_DOOR),
                on_click=lambda e: open_pdf_with_firefox(directory_path.value)
            ),
            ft.Divider(thickness=1),
            ft.NavigationDrawerDestination(
                icon_content=ft.Icon(ft.icons.REMOVE_CIRCLE_OUTLINE),
                label="Remove prefix RIDE",
                selected_icon=ft.icons.REMOVE_CIRCLE,
                on_click=lambda e: open_pdf_with_firefox(directory_path.value)
            ),
            ft.NavigationDrawerDestination(
                icon_content=ft.Icon(ft.icons.PHONE_OUTLINED),
                label="Rename files using the xml",
                selected_icon=ft.icons.PHONE,
            ),
            ft.NavigationDrawerDestination(
                icon_content=ft.Icon(ft.icons.FILE_PRESENT_OUTLINED),
                label="Process al xml files and get json",
                selected_icon=ft.icons.FILE_PRESENT,
            ),
        ],
    )
    def show_drawer(e):
        page.drawer.open = True
        page.drawer.update()

    page.add(ft.ElevatedButton("Show drawer", on_click=show_drawer))

ft.app(target=main)