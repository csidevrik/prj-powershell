import flet as ft

def main (page: ft.Page):
    contenedor = ft.Container(
        content=ft.Text(value="Hola"),
        alignment=ft.alignment.center,
        width=60,
        height=60,
        bgcolor="#edf5f9"

    )
    page.bgcolor = "#e6f9f9"
    page.add(contenedor)


ft.app(target=main)