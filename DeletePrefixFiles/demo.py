import flet as ft

name = "Draggable VerticalDivider"

async def main(page: ft.Page):
    page.window_width = 960
    page.window_height = 540
    page.title = "facturet"
    page.bgcolor = "#263238"

    async def move_vertical_divider(e: ft.DragUpdateEvent):
        if (e.delta_x > 0 and cleft.width < 360) or (e.delta_x < 0 and cleft.width > 200):
            cleft.width += e.delta_x
        await cleft.update_async()

    async def show_draggable_cursor(e: ft.HoverEvent):
        e.control.mouse_cursor = ft.MouseCursor.RESIZE_LEFT_RIGHT
        await e.control.update_async()
    # /////////////////////////////////////////////////////////////
    
    inputSearch = ft.TextField(
        # hint_text="SEARCH", 
        text_align=ft.TextAlign.CENTER,
        border=ft.InputBorder.OUTLINE,
        filled=True,
        bgcolor="#f6f8fa",
        # helper_text="Ingresa aqui la herramienta que deseas usar",
        # helper_style=ft.ShadowBlurStyle.SOLID,
    )

    colu=ft.Column(
        controls=[inputSearch],
        animate_offset=ft.Animation.curve,

    )
    cleft = ft.Container(
        colu, 
        bgcolor="#ff9e47",
        alignment=ft.alignment.center,
        width=300,
        # expand=1,
    )
    cright = ft.Container(
        bgcolor= "#ffffff",
        alignment=ft.alignment.center,
        expand=1,
    )


    fila= ft.Row(
        spacing=0,
        width=960,
        height=540,
        controls=[
            cleft,
            ft.GestureDetector(
                content=ft.VerticalDivider(),
                drag_interval=10,
                on_pan_update=move_vertical_divider,
                on_hover=show_draggable_cursor,
            ),
            cright,
        ],
        
    )
    
    await page.add_async(fila)
    pass
ft.app(target=main)