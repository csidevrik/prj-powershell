import platform
import csv
import json
import hashlib
import os
import subprocess
import flet as ft
import xml.etree.ElementTree as ET

# ─────────────────────────────────────────────────────────────────────────────
# COMPATIBILIDAD FLET 0.82.2 — resumen de todos los cambios vs 0.25:
#
#  1. Imports: solo "import flet as ft", sin from flet import (...)
#  2. page.description eliminado (nunca existió)
#  3. page.window.heigh → page.window.height  (typo)
#  4. FilePicker es ahora un Service:
#       - NO se agrega a page.overlay
#       - Se instancia dentro de main() y se auto-registra con la página
#       - get_directory_path() y pick_files() son métodos async que
#         retornan el valor directamente (sin callback on_result)
#  5. main() debe ser "async def" para poder usar await en el FilePicker
#  6. PopupMenuItem: ya no acepta text= / icon= → usar content=ft.Row(...)
#  7. ft.app(main) → ft.run(main)   (deprecated desde 0.80)
# ─────────────────────────────────────────────────────────────────────────────

regex1 = r"RDD([+-]?(?=\.\d|\d)(?:\d+)?(?:\.?\d*))(?:[Ee]([+-]?\d+))?"
regex2 = "I[0-9]+"


# ── Modelos ───────────────────────────────────────────────────────────────────

class Registro:
    def __init__(self, code_inst, number_fac, value_serv):
        self.code_inst  = code_inst
        self.number_fac = number_fac
        self.value_serv = value_serv

class RegistroRet:
    def __init__(self, ret_number, ret_value, fac_number):
        self.ret_number = ret_number
        self.ret_value  = ret_value
        self.fac_number = fac_number


# ── Lógica de negocio (sin cambios) ───────────────────────────────────────────

def replace_string_onxml(filexml: str, ssearch: str, sreplace: str):
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

def delete_CDATA(folder):
    s1 = '<![CDATA[<?xml version="1.0" encoding="UTF-8"?><comprobanteRetencion id="comprobante" version="1.0.0">'
    s2 = '</comprobanteRetencion>]]>'
    for archivo in os.listdir(folder):
        if archivo.lower().endswith('.xml'):
            ruta = os.path.join(folder, archivo)
            replace_string_onxml(ruta, s1, '')
            replace_string_onxml(ruta, s2, '')

def replace_menorque(folder):
    for archivo in os.listdir(folder):
        if archivo.lower().endswith('.xml'):
            replace_string_onxml(os.path.join(folder, archivo), '&lt;', '<')

def replace_mayorque(folder):
    for archivo in os.listdir(folder):
        if archivo.lower().endswith('.xml'):
            replace_string_onxml(os.path.join(folder, archivo), '&gt;', '>')

def clean_xml_files(folder):
    replace_mayorque(folder)
    replace_menorque(folder)
    delete_CDATA(folder)

def remove_duplicate_files(folder):
    grouped = {}
    for file_name in os.listdir(folder):
        file_path = os.path.join(folder, file_name)
        with open(file_path, 'rb') as f:
            h = hashlib.sha256(f.read()).hexdigest()
        grouped.setdefault(h, []).append(file_path)
    for group in grouped.values():
        oldest = min(group, key=lambda x: os.path.getctime(x))
        for fp in group:
            if fp != oldest:
                os.remove(fp)

def remove_prefix_files_pdf(folder, prefix):
    for file_pdf in [f for f in os.listdir(folder) if f.lower().endswith(".pdf")]:
        name = os.path.splitext(file_pdf)[0]
        if name.startswith(prefix):
            new_name = name[len(prefix):] + ".pdf"
            os.rename(os.path.join(folder, file_pdf), os.path.join(folder, new_name))

def json_to_csv(json_file_path, csv_file_path):
    with open(json_file_path, 'r') as jf:
        data = json.load(jf)
    if not data or not isinstance(data, list):
        print("JSON sin datos válidos.")
        return
    header = list(data[0].keys())
    with open(csv_file_path, 'w', newline='') as cf:
        w = csv.writer(cf)
        w.writerow(header)
        for row in data:
            w.writerow(row.values())

def process_all_xml_files(folder):
    if not os.path.exists(folder):
        print(f"Directorio no existe: {folder}")
        return
    registros = []
    for filename in os.listdir(folder):
        if filename.endswith(".xml"):
            r = extract_xml_data(os.path.join(folder, filename))
            registros.append({'code_inst': r.code_inst, 'number_fac': r.number_fac, 'value_serv': r.value_serv})
    json_path = os.path.join(folder, 'registros.json')
    with open(json_path, 'w') as jf:
        json.dump(registros, jf, indent=4)
    json_to_csv(json_path, os.path.join(folder, 'registros.csv'))
    print(f"Procesados {len(registros)} XMLs → registros.json + registros.csv")

def process_all_xml_rets(folder):
    clean_xml_files(folder)
    if not os.path.exists(folder):
        print(f"Directorio no existe: {folder}")
        return
    registros = []
    for filename in os.listdir(folder):
        if filename.endswith(".xml"):
            r = get_register_xml_retencion(os.path.join(folder, filename))
            registros.append({'ret_number': r.ret_number, 'ret_value': r.ret_value, 'fac_number': r.fac_number})
    json_path = os.path.join(folder, 'retenciones.json')
    with open(json_path, 'w') as jf:
        json.dump(registros, jf, indent=4)
    json_to_csv(json_path, os.path.join(folder, 'retenciones.csv'))
    print(f"Procesadas {len(registros)} retenciones → retenciones.json + retenciones.csv")

def extract_xml_data(xml_file_path):
    with open(xml_file_path, 'r', encoding='utf-8') as f:
        xml_content = f.read()
    start = xml_content.find('<infoTributaria>')
    end   = xml_content.find('</infoAdicional>', start)
    chunk = f"<factura>\n{xml_content[start:end + len('</infoAdicional>')]}\n</factura>"
    root  = ET.fromstring(chunk)
    estab   = root.find(".//estab").text
    pto_em  = root.find(".//ptoEmi").text
    secue   = root.find(".//secuencial").text
    codigo  = root.find('.//campoAdicional[@nombre="Instalacion"]').text
    nro_fac = f"FAC{estab}{pto_em}{secue}"
    valor   = root.find(".//totalSinImpuestos").text
    print(codigo, nro_fac, valor)
    return Registro(code_inst=codigo, number_fac=nro_fac, value_serv=valor)

def get_register_xml_retencion(xml_file_path):
    with open(xml_file_path, 'r', encoding='utf-8') as f:
        xml_content = f.read()
    root = ET.fromstring(xml_content)
    estab  = root.find(".//estab").text
    pto_em = root.find(".//ptoEmi").text
    secue  = root.find(".//secuencial").text
    ret_num   = f"{estab}-{pto_em}-{secue}"
    ret_val   = root.find(".//valorRetenido").text
    fac_num   = "FAC" + root.find(".//numDocSustento").text
    print(ret_num, ret_val, fac_num)
    return RegistroRet(ret_number=ret_num, ret_value=ret_val, fac_number=fac_num)

def rename_files_with_attributes(folder):
    for xml_file in [f for f in os.listdir(folder) if f.lower().endswith(".xml")]:
        new_name = extract_xml_content(os.path.join(folder, xml_file))
        pdf_file = os.path.splitext(xml_file)[0] + ".pdf"
        os.rename(os.path.join(folder, xml_file),   os.path.join(folder, f"{new_name}.xml"))
        os.rename(os.path.join(folder, pdf_file),   os.path.join(folder, f"{new_name}.pdf"))

def extract_xml_content(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        xml_content = f.read()
    start = xml_content.find('<infoTributaria>')
    end   = xml_content.find('</infoAdicional>', start)
    chunk = f"<factura>\n{xml_content[start:end + len('</infoAdicional>')]}\n</factura>"
    root  = ET.fromstring(chunk)
    estab  = root.find(".//estab").text
    pto_em = root.find(".//ptoEmi").text
    secue  = root.find(".//secuencial").text
    codigo = root.find('.//campoAdicional[@nombre="Instalacion"]').text
    new_name = f"{estab}{pto_em}{secue}-{codigo}"
    print(new_name)
    return new_name

def open_pdf_with_browser(folder, browser_command):
    files = [f for f in os.listdir(folder) if f.endswith(".pdf")]
    files.sort(key=lambda x: os.path.getmtime(os.path.join(folder, x)), reverse=True)
    for f in files:
        subprocess.run(f"{browser_command} --new-tab {os.path.abspath(os.path.join(folder, f))}", shell=True)

def get_browser_command(browser):
    if platform.system() == "Linux":
        return "google-chrome" if browser == "chrome" else "firefox"
    elif platform.system() == "Windows":
        return f"start {browser}"
    raise OSError("Sistema operativo no compatible")

def open_pdf_with_firefox(folder): open_pdf_with_browser(folder, get_browser_command("firefox"))
def open_pdf_with_chrome(folder):  open_pdf_with_browser(folder, get_browser_command("chrome"))


# ── UI ────────────────────────────────────────────────────────────────────────

def _menu_item(icon, label, handler):
    """PopupMenuItem compatible con Flet 0.82 (sin text= ni icon= directos)."""
    return ft.PopupMenuItem(
        content=ft.Row([ft.Icon(icon, size=18), ft.Text(label)], spacing=10),
        on_click=handler,
    )


async def main(page: ft.Page):
    # ── Configuración de ventana ───────────────────────────────────────────────
    page.title      = "Octaba facturas"
    page.padding    = 0
    page.bgcolor    = ft.Colors.with_opacity(0.90, '#07D2A9')

    page.window.frameless  = False
    page.window.height     = 500
    page.window.width      = 1000
    page.window.max_width  = 1200
    page.window.max_height = 600

    page.appbar = ft.AppBar(
        leading=ft.Icon(ft.Icons.DOOR_SLIDING),
        leading_width=100,
        title=ft.Text("App facturas"),
        center_title=True,
        bgcolor=ft.Colors.with_opacity(0.90, '#07D2A9'),
    )
    page.update()

    # ── FilePicker como Service ────────────────────────────────────────────────
    # En 0.82 FilePicker es un Service: se instancia aquí y se auto-registra
    # con la página. NO va en page.overlay. Los métodos son async y retornan
    # el valor directamente (no hay callback on_result).
    file_picker = ft.FilePicker()

    # Widget que muestra la ruta seleccionada
    folder_text = ft.Text()

    async def pick_directory(_):
        path = await file_picker.get_directory_path()
        folder_text.value = path if path else "Cancelled!"
        folder_text.update()

    # ── Menú popup ────────────────────────────────────────────────────────────
    pb = ft.PopupMenuButton(
        items=[
            _menu_item(ft.Icons.BROWSER_UPDATED_SHARP,       "Check with firefox",
                       lambda e: open_pdf_with_firefox(folder_text.value)),
            _menu_item(ft.Icons.BROWSER_UPDATED_SHARP,       "Check with chrome",
                       lambda e: open_pdf_with_chrome(folder_text.value)),
            _menu_item(ft.Icons.CONTROL_POINT_DUPLICATE_SHARP, "Remove duplicates",
                       lambda e: remove_duplicate_files(folder_text.value)),
            _menu_item(ft.Icons.TEXT_FORMAT_ROUNDED,         "Remove prefix RIDE",
                       lambda e: remove_prefix_files_pdf(folder_text.value, "RIDE_")),
            _menu_item(ft.Icons.TEXT_FORMAT_ROUNDED,         "Rename files using the xml",
                       lambda e: rename_files_with_attributes(folder_text.value)),
            _menu_item(ft.Icons.TEXT_FORMAT_ROUNDED,         "Process all xml files facturas for json",
                       lambda e: process_all_xml_files(folder_text.value)),
            _menu_item(ft.Icons.TEXT_FORMAT_ROUNDED,         "Process all xml retenciones",
                       lambda e: process_all_xml_rets(folder_text.value)),
        ]
    )

    page.add(pb)
    page.add(folder_text)
    page.add(
        ft.Row([
            ft.ElevatedButton(
                "Open directory",
                icon=ft.Icons.FOLDER_OPEN,
                on_click=pick_directory,   # async handler, await interno
                disabled=page.web,
            ),
            folder_text,
        ])
    )


if __name__ == "__main__":
    # ft.run(main)   
    ## ft.app() deprecated desde 0.80 → ft.run()
    # esto es una alternativa que sigue funcionando, pero ft.run() es la forma recomendada ahora:
    ft.app(target=main)   # Alternativa, pero ft.run() es la forma recomendada ahora.
