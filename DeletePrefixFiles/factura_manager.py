import platform
import csv
import json
import hashlib
import os
import subprocess
import flet as ft
import xml.etree.ElementTree as ET
from flet import (
    ElevatedButton,
    FilePicker,
    FilePickerResultEvent,
    Page,
    Row,
    Text,
    Icons,
)

class Factura:
    """Modelo de datos de una factura muy basica extraída de un XML."""
    def __init__(self, code_inst, number_fac, value_serv):
        self.code_inst = code_inst
        self.number_fac = number_fac
        self.value_serv = value_serv

class Retencion:
    """Modelo de datos de una retención muy basica extraída de un XML."""
    def __init__(self, ret_number, ret_value, fac_number):
        self.ret_number = ret_number
        self.ret_value = ret_value
        self.fac_number = fac_number


# ── File Utilities ────────────────────────────────────────────────────────────

def get_files_extension(folder, extension):
    """Retorna lista de archivos en folder que coincidan con la extension dada."""
    files = os.listdir(folder)
    return [file for file in files if file.lower().endswith(extension.lower())]

def get_name(filename):
    """Retorna el nombre del archivo sin extension, en minusculas."""
    return os.path.splitext(filename)[0].lower()

def get_extension(filename):
    """Retorna la extension del archivo en minusculas."""
    return os.path.splitext(filename)[1].lower()

def get_path(filename):
    """Retorna el directorio del archivo, o '.' si no tiene directorio."""
    return os.path.dirname(filename) if os.path.dirname(filename) else '.'

def remove_prefix(filename, prefix):
    """Elimina el prefix del nombre de un archivo conservando su extension."""
    name, ext = os.path.splitext(os.path.basename(filename))
    if name.startswith(prefix):
        return name[len(prefix):] + ext
    return name + ext

def remove_prefix_files(folder, prefix, extension):
    """Elimina el prefix de todos los archivos con la extension dada en folder."""
    for file in get_files_extension(folder, extension):
        if get_name(file).startswith(prefix.lower()):
            new_name = remove_prefix(file, prefix)
            os.rename(os.path.join(folder, file), os.path.join(folder, new_name))

def folder_exists(folder):
    """Verifica que folder exista. Retorna False e imprime mensaje si no existe."""
    if not os.path.exists(folder):
        print(f"El directorio {folder} no existe.")
        return False
    return True


# ── XML Utilities ─────────────────────────────────────────────────────────────

def replace_string_onxml(filexml: str, ssearch: str, sreplace: str):
    """Busca ssearch en el archivo y lo reemplaza por sreplace. Solo escribe si hubo cambios."""
    try:
        with open(filexml, 'r+', encoding='utf-8') as f:
            contenido = f.read()
            nuevo_contenido = contenido.replace(ssearch, sreplace)
            if nuevo_contenido != contenido:
                f.seek(0)
                f.write(nuevo_contenido)
                f.truncate()
    except Exception as e:
        print(f"Error processing file {filexml}: {e}")

def replace_in_all_xml_files(folder, ssearch, sreplace=''):
    """Aplica replace_string_onxml a todos los archivos XML de folder."""
    for archivo in get_files_extension(folder, '.xml'):
        ruta = os.path.join(folder, archivo)
        replace_string_onxml(ruta, ssearch, sreplace)

def clean_xml_files(folder):
    """Limpia todos los XMLs de folder: normaliza entidades HTML y elimina envolturas CDATA de retenciones."""
    replace_in_all_xml_files(folder, '&gt;', '>')
    replace_in_all_xml_files(folder, '&lt;', '<')
    replace_in_all_xml_files(folder, '<![CDATA[<?xml version="1.0" encoding="UTF-8"?><comprobanteRetencion id="comprobante" version="1.0.0">')
    replace_in_all_xml_files(folder, '</comprobanteRetencion>]]>')


def get_file_hash(file_path):
    """Calcula y retorna el hash SHA-256 de un archivo."""
    with open(file_path, 'rb') as f:
        return hashlib.sha256(f.read()).hexdigest()

def remove_duplicate_files(folder):
    """Elimina archivos duplicados en folder usando hash SHA-256, conservando el mas antiguo."""
    files = os.listdir(folder)
    grouped_files = {}
    for file_name in files:
        file_path = os.path.join(folder, file_name)
        file_hash = get_file_hash(file_path)
        if file_hash not in grouped_files:
            grouped_files[file_hash] = []
        grouped_files[file_hash].append(file_path)

    for file_group in grouped_files.values():
        oldest_file = min(file_group, key=lambda x: os.path.getctime(x))
        for file_path in file_group:
            if file_path != oldest_file:
                os.remove(file_path)

def remove_prefix_files_pdf(folder, prefix):
    """Wrapper: elimina el prefix de todos los PDFs en folder."""
    remove_prefix_files(folder, prefix, '.pdf')

def update_json_with_xml_data(folder, json_path):
    """Actualiza number_fac y value_serv en un JSON existente cruzando con los XMLs de folder."""
    with open(json_path, 'r') as json_file:
        data = json.load(json_file)

    for filename in get_files_extension(folder, '.xml'):
        xml_file_path = os.path.join(folder, filename)
        factura_xml = extract_fac_register(xml_file_path)
        for registro in data["facs"]["registro"]:
            if registro.code_inst == factura_xml.code_inst:
                registro.number_fac = factura_xml.number_fac
                registro.value_serv = factura_xml.value_serv
                break

    with open(json_path, 'w') as json_file:
        json.dump(data, json_file, indent=2)

def save_to_json(data, json_path):
    """Guarda data como JSON en json_path con indentacion de 4 espacios."""
    with open(json_path, 'w') as json_file:
        json.dump(data, json_file, indent=4)

def save_to_csv(data, csv_path):
    """Guarda data (lista de dicts) directamente como CSV."""
    if not data:
        print("No hay datos para guardar.")
        return
    header = list(data[0].keys())
    with open(csv_path, 'w', newline='') as csv_file:
        csv_writer = csv.writer(csv_file)
        csv_writer.writerow(header)
        for row in data:
            csv_writer.writerow(row.values())

def json_to_csv(json_file_path, csv_file_path):
    """Lee un archivo JSON y lo convierte a CSV usando save_to_csv."""
    with open(json_file_path, 'r') as json_file:
        data = json.load(json_file)
    save_to_csv(data, csv_file_path)

def process_all_xml_facs(folder):
    """Procesa todos los XMLs de facturas en folder y genera facturas.json y facturas.csv ordenados por code_inst."""
    if not folder_exists(folder):
        return

    registros = []
    for filename in get_files_extension(folder, '.xml'):
        registro = extract_fac_register(os.path.join(folder, filename))
        registros.append({
            'code_inst': registro.code_inst,
            'number_fac': registro.number_fac,
            'value_serv': registro.value_serv
        })

    registros.sort(key=lambda x: x['code_inst'])

    json_path = os.path.join(folder, 'facturas.json')
    save_to_json(registros, json_path)

    csv_path = os.path.join(folder, 'facturas.csv')
    json_to_csv(json_path, csv_path)
    print(f"Procesados {len(registros)} XMLs → facturas.json + facturas.csv")
    
def process_all_xml_rets(folder):
    """Limpia, procesa todos los XMLs de retenciones en folder y genera retenciones.json y retenciones.csv."""
    if not folder_exists(folder):
        return

    clean_xml_files(folder)

    registros = []
    for filename in get_files_extension(folder, '.xml'):
        registro = get_register_xml_retencion(os.path.join(folder, filename))
        registros.append({
            'ret_number': registro.ret_number,
            'ret_value': registro.ret_value,
            'fac_number': registro.fac_number
        })

    json_path = os.path.join(folder, 'retenciones.json')
    save_to_json(registros, json_path)

    csv_path = os.path.join(folder, 'retenciones.csv')
    json_to_csv(json_path, csv_path)
    print(f"Procesadas {len(registros)} retenciones → retenciones.json + retenciones.csv")

def extract_xml_fragment(file_path, start_limit, end_limit):
    """Extrae y parsea un fragmento XML delimitado por start_limit y end_limit. Retorna el root ET."""
    with open(file_path, 'r', encoding='utf-8') as file:
        xml_content = file.read()

    start_index = xml_content.find(start_limit)
    end_index   = xml_content.find(end_limit, start_index)
    extracted_xml = xml_content[start_index:end_index + len(end_limit)]
    return ET.fromstring(f"<factura>\n{extracted_xml}\n</factura>")

def build_numero_factura(estab, pto_em, secue):
    """Construye el numero de factura en formato FAC+estab+ptoEmi+secuencial."""
    return f"FAC{estab}{pto_em}{secue}"

def extract_fac_register(xml_file_path):
    """Extrae los datos de una factura desde un XML y retorna un objeto Factura."""
    root = extract_xml_fragment(xml_file_path, '<infoTributaria>', '</infoAdicional>')

    estab  = root.find(".//estab").text
    pto_em = root.find(".//ptoEmi").text
    secue  = root.find(".//secuencial").text
    codigo = root.find('.//campoAdicional[@nombre="Instalacion"]').text

    numero_factura = build_numero_factura(estab, pto_em, secue)
    valor_servicio = root.find(".//totalSinImpuestos").text

    print(codigo, numero_factura, valor_servicio)
    return Factura(code_inst=codigo, number_fac=numero_factura, value_serv=valor_servicio)

def get_register_xml_retencion(xml_file_path):
    """Extrae los datos de una retencion desde un XML y retorna un objeto Retencion."""
    with open(xml_file_path, 'r', encoding='utf-8') as file:
        xml_content = file.read()

    root   = ET.fromstring(xml_content)
    estab  = root.find(".//estab").text
    pto_em = root.find(".//ptoEmi").text
    secue  = root.find(".//secuencial").text

    ret_num = f"{estab}-{pto_em}-{secue}"
    ret_val = root.find(".//valorRetenido").text
    fac_num = "FAC" + root.find(".//numDocSustento").text

    print(ret_num, ret_val, fac_num)
    return Retencion(ret_number=ret_num, ret_value=ret_val, fac_number=fac_num)

def rename_file_pair(folder, old_name, new_name):
    """Renombra un par XML+PDF en folder con el nuevo nombre dado."""
    os.rename(os.path.join(folder, old_name),                              os.path.join(folder, f"{new_name}.xml"))
    os.rename(os.path.join(folder, os.path.splitext(old_name)[0] + ".pdf"), os.path.join(folder, f"{new_name}.pdf"))

def rename_files_with_attributes(folder):
    """Renombra pares XML+PDF en folder usando los atributos del XML como nuevo nombre."""
    for xml_file in get_files_extension(folder, '.xml'):
        new_name = build_filename_from_xml(os.path.join(folder, xml_file))
        rename_file_pair(folder, xml_file, new_name)

def build_filename_from_xml(file_path):
    """Construye el nuevo nombre de archivo a partir de los datos del XML (estab+ptoEmi+secuencial-codigo)."""
    root = extract_xml_fragment(file_path, '<infoTributaria>', '</infoAdicional>')

    estab  = root.find(".//estab").text
    pto_em = root.find(".//ptoEmi").text
    secue  = root.find(".//secuencial").text
    codigo = root.find('.//campoAdicional[@nombre="Instalacion"]').text

    new_name = f"{build_numero_factura(estab, pto_em, secue)}-{codigo}"
    print(new_name)
    return new_name

def open_pdf_with_browser(folder, browser_command):
    """Abre todos los PDFs de folder en el browser indicado, ordenados por fecha de modificacion."""
    filesPDF = get_files_extension(folder, '.pdf')
    filesPDF.sort(key=lambda x: os.path.getmtime(os.path.join(folder, x)), reverse=True)
    for filePDF in filesPDF:
        pathComplete = os.path.abspath(os.path.join(folder, filePDF))
        subprocess.run(f"{browser_command} --new-tab {pathComplete}", shell=True)

def open_pdf_with_firefox(folder):
    """Wrapper: abre todos los PDFs de folder en Firefox."""
    open_pdf_with_browser(folder, get_browser_command("firefox"))

def open_pdf_with_chrome(folder):
    """Wrapper: abre todos los PDFs de folder en Chrome."""
    open_pdf_with_browser(folder, get_browser_command("chrome"))

def get_browser_command(browser):
    """Retorna el comando del sistema para abrir el browser indicado segun el OS."""
    if platform.system() == "Linux":
        return "google-chrome" if browser == "chrome" else "firefox"
    elif platform.system() == "Windows":
        return f"start {browser}"
    raise OSError("Sistema operativo no compatible")


if __name__ == "__main__":
    # Flet application for desktop GUI definition
    def main(page: ft.Page):
        page.title = "Octaba facturas"
        page.padding = 0
        page.description = "APP for try facturas"
        # page.window_bgcolor = ft.Colors.TRANSPARENT
        page.window.frameless = False
        # page.window_title_bar_hidden = True
        page.bgcolor = ft.Colors.with_opacity(0.90, '#07D2A9')
        page.window.heigh = 500
        page.window.width = 1000
        page.window.max_width = 1200
        page.window.max_height = 600

        page.appbar = ft.AppBar(
            leading = ft.Icon(ft.Icons.DOOR_SLIDING),
            leading_width=100,
            title=ft.Text("App facturas"),
            center_title=True,
            bgcolor=ft.Colors.with_opacity(0.90, '#07D2A9')
        )

        page.update()

        # def check_item_clicked(e):
        #     e.control.checked = not e.control.checked
        #     page.update()

        pb = ft.PopupMenuButton(
            items=[
                ft.PopupMenuItem(
                    icon=ft.Icons.BROWSER_UPDATED_SHARP,  text="Check with firefox", on_click=lambda e: open_pdf_with_firefox(folder.value)
                    ),
                ft.PopupMenuItem(
                    icon=ft.Icons.BROWSER_UPDATED_SHARP,  text="Check with chrome", on_click=lambda e: open_pdf_with_chrome(folder.value)
                    ),
                ft.PopupMenuItem(
                    icon=ft.Icons.CONTROL_POINT_DUPLICATE_SHARP,  text="Remove duplicates", on_click=lambda e: remove_duplicate_files(folder.value)
                    ),
                ft.PopupMenuItem(
                    icon=ft.Icons.TEXT_FORMAT_ROUNDED,  text="Remove prefix RIDE", on_click=lambda e: remove_prefix_files_pdf(folder.value,"RIDE_")
                    ),
                ft.PopupMenuItem(
                    icon=ft.Icons.TEXT_FORMAT_ROUNDED,  text="Rename files using the xml", on_click=lambda e: rename_files_with_attributes(folder.value)
                    ),
                ft.PopupMenuItem(
                    icon=ft.Icons.TEXT_FORMAT_ROUNDED,  text="Process all xml files facturas for json", on_click=lambda e: process_all_xml_facs(folder.value)
                    ),
                ft.PopupMenuItem(
                    icon=ft.Icons.TEXT_FORMAT_ROUNDED,  text="Process all xml retenciones", on_click=lambda e: process_all_xml_rets(folder.value)
                    ),
            ]
        )
        page.add(pb)

        # Open directory dialog
        def get_directory_result(e: FilePickerResultEvent):
            folder.value = e.path if e.path else "Cancelled!"
            folder.update()

        get_directory_dialog = FilePicker(on_result=get_directory_result)
        folder = Text()

        def pick_files_result(e: FilePickerResultEvent):
            selected_files.value = (
                ",".join(map(lambda f: f.name, e.files )) if e.files else "Canceled!"
            )
            selected_files.update()

        pick_files_dialog = ft.FilePicker(on_result=pick_files_result)
        selected_files = Text()

        page.add(folder)
        page.add(selected_files)

        # hide all dialogs in overlay
        page.overlay.extend([get_directory_dialog])
        page.overlay.append(pick_files_dialog)

        page.add(
            Row(
                [
                    ElevatedButton(
                        "Open directory",
                        icon=Icons.FOLDER_OPEN,
                        on_click=lambda _: get_directory_dialog.get_directory_path(),
                        disabled=page.web,
                    ), 
                    folder,
                ]
            ),
        )
    ft.app(target=main)