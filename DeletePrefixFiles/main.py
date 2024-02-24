import flet as ft


async def main(page: ft.Page):
    page.window_height = 1080
    page.window_width = 1920
    page.window_resizable = True
    page.title = "AAA"
    page.padding = 0

    async def move_vertical_divider1(e: ft.DragUpdateEvent):
        if (e.delta_x > 0 and left01.width < 800) or (e.delta_x < 0 and left01.width > 100):
            left01.width += e.delta_x
        await left01.update_async()

    async def move_vertical_divider2(e: ft.DragUpdateEvent):
        if (e.delta_x > 0 and left02.width < 600) or (e.delta_x < 0 and left02.width > 200):
            left02.width += e.delta_x
        await left02.update_async()

    async def show_draggable_cursor(e: ft.HoverEvent):
        e.control.mouse_cursor = ft.MouseCursor.RESIZE_LEFT_RIGHT
        await e.control.update_async()

    left01 = ft.Container(
        bgcolor="#f5f5f5",
        alignment=ft.alignment.center_left,
        width=100,
    )
    left02 = ft.Container(
        bgcolor= "#263238",
        alignment=ft.alignment.center,
        width=200,
    )
    right01 = ft.Container(
         bgcolor= "#263238",
        alignment=ft.alignment.center,
        expand=1,
    )

    gestureDetector1 = ft.GestureDetector(
        content=ft.VerticalDivider(),
        drag_interval=10,
        on_pan_update=move_vertical_divider1,
        on_hover=show_draggable_cursor,
    )

    gestureDetector2 = ft.GestureDetector(
        content=ft.VerticalDivider(),
        drag_interval=10,
        on_pan_update=move_vertical_divider2,
        on_hover=show_draggable_cursor,
    )

    row = ft.Row(spacing=0, controls=[
        left01,
        gestureDetector1,
        left02,
        gestureDetector2,
        right01,
    ])
    contenedor = ft.Container(row,width=1920, height=1080 ,bgcolor='#78a083', alignment=ft.alignment.top_center)
    
    await page.add_async(contenedor)
    pass
# ft.app(port=3000,target=main, view=ft.AppView.WEB_BROWSER)
ft.app(target=main)