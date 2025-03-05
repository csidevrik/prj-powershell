import platform
import json
from datetime import datetime
from typing import Dict

# Constante para el nombre del archivo JSON
ARCHIVO_JSON = 'app-exec.json'

def obtener_info_sistema() -> Dict[str, str]:
    """Obtiene información del sistema operativo y la fecha actual.
    
    Returns:
        Dict[str, str]: Diccionario con la fecha actual y el nombre del sistema operativo.
    """
    sistema_operativo = platform.system()
    fecha_actual = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    return {'fecha': fecha_actual, 'os': sistema_operativo}

def guardar_en_json(info: Dict[str, str], archivo: str = ARCHIVO_JSON) -> None:
    """Guarda la información en un archivo JSON.
    
    Args:
        info (Dict[str, str]): Información a guardar.
        archivo (str): Nombre del archivo JSON.
    """
    try:
        with open(archivo, 'w') as file:
            json.dump(info, file, indent=4)
        print(f"Información del sistema guardada exitosamente en {archivo}.")
    except IOError as e:
        print(f"Error al guardar la información en {archivo}: {e}")

if __name__ == "__main__":
    info_sistema = obtener_info_sistema()
    guardar_en_json(info_sistema)
