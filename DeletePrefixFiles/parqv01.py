# import flet as ft
# from datetime import datetime
# import csv

# # Función para calcular el tiempo transcurrido en minutos y el costo
# def calcular_tiempo(e, page):
#     hora_ingreso = ingreso_input.value
#     hora_salida = salida_input.value

#     try:
#         # Convertir las horas de ingreso y salida a objetos datetime
#         formato_hora = "%H:%M"
#         ingreso = datetime.strptime(hora_ingreso, formato_hora)
#         salida = datetime.strptime(hora_salida, formato_hora)

#         # Calcular la diferencia en minutos
#         diferencia = (salida - ingreso).total_seconds() / 60
#         diferencia = int(diferencia)  # Convertir a entero

#         # Calcular el costo en centavos
#         costo_centavos = diferencia  # 1 centavo por minuto
#         costo_dolares = costo_centavos // 100
#         costo_restante_centavos = costo_centavos % 100

#         resultado_text.value = f"Tiempo total: {diferencia} minutos. Costo: {costo_dolares} dólares con {costo_restante_centavos} centavos."

#         # Registrar en el archivo CSV
#         with open("registro_tiempos.csv", mode="a", newline="") as file:
#             writer = csv.writer(file)
#             writer.writerow([hora_ingreso, hora_salida, diferencia, f"{costo_dolares} dólares con {costo_restante_centavos} centavos"])

#         page.update()
#     except ValueError:
#         resultado_text.value = "Formato de hora inválido. Use HH:MM."
#         page.update()

# # Crear la aplicación de Flet
# def main(page: ft.Page):
#     global ingreso_input, salida_input, resultado_text

#     page.title = "Cálculo de Estacionamiento"
#     page.padding = 20

#     ingreso_input = ft.TextField(label="Hora de Ingreso (HH:MM)", width=200)
#     salida_input = ft.TextField(label="Hora de Salida (HH:MM)", width=200)
#     calcular_btn = ft.ElevatedButton("Calcular", on_click=lambda e: calcular_tiempo(e,page))
#     resultado_text = ft.Text()

#     page.add(
#         ingreso_input,
#         salida_input,
#         calcular_btn,
#         resultado_text
#     )

# ft.app(target=main)



# ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


import flet as ft
from datetime import datetime, time
import csv

# Función para calcular el tiempo transcurrido en minutos y el costo
def calcular_tiempo(e, page):
    hora_ingreso = ingreso_input.value
    hora_salida = salida_input.value

    try:
        if hora_ingreso is None or hora_salida is None:
            raise ValueError("Debe seleccionar ambas horas.")

        # Convertir las horas de ingreso y salida a objetos datetime
        formato_hora = "%H:%M"
        ingreso = datetime.strptime(hora_ingreso.strftime(formato_hora), formato_hora)
        salida = datetime.strptime(hora_salida.strftime(formato_hora), formato_hora)

        # Calcular la diferencia en minutos
        diferencia = (salida - ingreso).total_seconds() / 60
        diferencia = int(diferencia)  # Convertir a entero

        # Calcular el costo en centavos
        costo_centavos = diferencia  # 1 centavo por minuto
        costo_dolares = costo_centavos // 100
        costo_restante_centavos = costo_centavos % 100

        resultado_text.value = f"Tiempo total: {diferencia} minutos. Costo: {costo_dolares} dólares con {costo_restante_centavos} centavos."

        # Registrar en el archivo CSV
        with open("registro_tiempos.csv", mode="a", newline="") as file:
            writer = csv.writer(file)
            writer.writerow([hora_ingreso, hora_salida, diferencia, f"{costo_dolares} dólares con {costo_restante_centavos} centavos"])

        page.update()  # Actualizar la página
    except ValueError as ve:
        resultado_text.value = str(ve)
        page.update()

# Crear la aplicación de Flet
def main(page: ft.Page):
    global ingreso_input, salida_input, resultado_text

    page.title = "Cálculo de Estacionamiento"
    page.padding = 20

    # Métodos handlers para los TimePickers de ingreso y salida
    def handle_change_ingreso(e):
        page.add(ft.Text(f"Hora de ingreso seleccionada: {ingreso_input.value}"))

    def handle_change_salida(e):
        page.add(ft.Text(f"Hora de salida seleccionada: {salida_input.value}"))

    # Configuración de los TimePickers
    ingreso_input = ft.TimePicker(
        help_text="Seleccione la hora de ingreso",
        confirm_text="Confirmar",
        hour_label_text="Horas",
        minute_label_text="Minutos",
        on_change=handle_change_ingreso
    )

    salida_input = ft.TimePicker(
        help_text="Seleccione la hora de salida",
        confirm_text="Confirmar",
        hour_label_text="Horas",
        minute_label_text="Minutos",
        on_change=handle_change_salida
    )

    hinit_tpicker = ft.ElevatedButton(
        "Pick init time",
        icon=ft.icons.TIME_TO_LEAVE_SHARP,
        on_click=lambda e: page.open(ingreso_input),
    )

    hfin_tpicker = ft.ElevatedButton(
        "Pick end time",
        icon=ft.icons.TIMELAPSE,
        on_click=lambda e: page.open(salida_input),
    )

    calcular_btn = ft.ElevatedButton("Calcular", on_click=lambda e: calcular_tiempo(e, page))
    resultado_text = ft.Text()

    page.add(
        hinit_tpicker,
        hfin_tpicker,
        calcular_btn,
        resultado_text
    )

ft.app(target=main)


