# import flet as ft
# def main(page):
#     pass
# ft.app(target=main)

import flet as ft

def main(page: ft.Page):

    page.add(
        ft.Row(
            [
                ft.Container(
                    bgcolor=ft.colors.ORANGE_300,
                    alignment=ft.alignment.center,
                    expand=True,
                ),
                 ft.VerticalDivider(),
                ft.Container(
                    bgcolor=ft.colors.BROWN_400,
                    alignment=ft.alignment.center,
                    expand=True,
                ),
                 ft.VerticalDivider(width=1, color="white"),
                ft.Container(
                    bgcolor=ft.colors.BLUE_300,
                    alignment=ft.alignment.center,
                    expand=True,
                ),
                 ft.VerticalDivider(width=9, thickness=3),
                ft.Container(
                    bgcolor=ft.colors.GREEN_300,
                    alignment=ft.alignment.center,
                    expand=True,
                ),
            ],
            spacing=0,
            expand=True,
        )
    )

ft.app(target=main)