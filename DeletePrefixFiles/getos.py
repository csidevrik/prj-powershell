import platform
import json
from datetime import datetime

def obtener_info_sistema():
    # Obtener el nombre del sistema operativo
    sistema_operativo = platform.system()

    # Obtener la fecha actual
    fecha_actual = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    return {'fecha': fecha_actual, 'os': sistema_operativo}

def guardar_en_json(info, archivo='app-exec.json'):
    # Guardar la información en formato JSON en el archivo
    with open(archivo, 'w') as file:
        json.dump(info, file, indent=4)

if __name__ == "__main__":
    # Obtener la información del sistema
    info_sistema = obtener_info_sistema()

    # Guardar la información en el archivo JSON
    guardar_en_json(info_sistema)

    print("Información del sistema guardada exitosamente en app-exec.json.")
