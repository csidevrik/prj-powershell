import flet as ft

# VARIABLES
LIMIT_VD1_MAX=200
LIMIT_VD1_MIN=100

LIMIT_VD2_MAX=200
LIMIT_VD2_MIN=100


async def main(page: ft.Page):
    page.window.heigh = 1080
    page.window.width = 1920
    page.window_resizable = True
    page.title = "PAYMENTS"
    page.padding = 0

    async def move_vertical_divider1(e: ft.DragUpdateEvent):
        if (e.delta_x > 0 and left01.width < LIMIT_VD1_MAX) or (e.delta_x < 0 and left01.width > LIMIT_VD1_MIN):
            left01.width += e.delta_x
        await left01.update()

    async def move_vertical_divider2(e: ft.DragUpdateEvent):
        if (e.delta_x > 0 and left02.width < LIMIT_VD2_MAX) or (e.delta_x < 0 and left02.width > LIMIT_VD2_MIN):
            left02.width += e.delta_x
        await left02.update()

    async def show_draggable_cursor(e: ft.HoverEvent):
        e.control.mouse_cursor = ft.MouseCursor.RESIZE_LEFT_RIGHT
        await e.control.update()

    left01 = ft.Container(
        bgcolor="#f9f1ef",
        alignment=ft.alignment.center,
        width=100,
    )
    left02 = ft.Container(
        bgcolor= "#f9f1ef",
        alignment=ft.alignment.center,
        width=100,
    )
    right01 = ft.Container(
        bgcolor= "#f9f1ef",
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

    row = ft.Row(spacing=10, controls=[
        left01,
        gestureDetector1,
        left02,
        gestureDetector2,
        right01,
    ])
    container = ft.Container(row,
                              width=1920, 
                              height=1080 ,
                              bgcolor='#f9f1ef', 
                              alignment=ft.alignment.bottom_center)
    
    await page.add_async(container)
    pass
# ft.app(port=3000,target=main, view=ft.AppView.WEB_BROWSER)
ft.app(target=main, assets_dir="assets") 
    #    view=ft.WEB_BROWSER)