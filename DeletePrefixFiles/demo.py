import flet as ft

name = "Draggable VerticalDivider"

async def main(page: ft.Page):
    page.window_width = 1920
    page.window_height = 1080
    page.title = "facturet"
    page.bgcolor = "#263238"

    async def move_vertical_divider(e: ft.DragUpdateEvent):
        if (e.delta_x > 0 and c.width < 800) or (e.delta_x < 0 and c.width > 400):
            c.width += e.delta_x
        await c.update_async()

    async def show_draggable_cursor(e: ft.HoverEvent):
        e.control.mouse_cursor = ft.MouseCursor.RESIZE_LEFT_RIGHT
        await e.control.update_async()

    c = ft.Container(
        bgcolor=ft.colors.ORANGE_300,
        alignment=ft.alignment.center,
        width=300,
        # expand=1,
    )

    fila= ft.Row(
        controls=[
            c,
            ft.GestureDetector(
                content=ft.VerticalDivider(),
                drag_interval=10,
                on_pan_update=move_vertical_divider,
                on_hover=show_draggable_cursor,
            ),
            ft.Container(
                bgcolor= "#263238",
                alignment=ft.alignment.center,
                expand=1,
            ),
        ],
        spacing=0,
        width=1920,
        height=1080,
    )




    await page.add_async(fila)
    pass


ft.app(target=main)