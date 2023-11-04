import flet
from flet import ( 
    ElevatedButton, 
    FilePicker, 
    Text, 
    Page,
    )

def main(page: Page):
    
    # Crear elementos de la interfaz de usuario 
    button = ElevatedButton("Da un saludo")
    text_element = Text("Hola, mundo")

    # Definir las interacciones
    def button_click():
        text_element.set_text("Haz hecho click en el boton")
    
    button.on_click(button_click)

    page.add(button)
    page.add(text_element)


flet.app(main)