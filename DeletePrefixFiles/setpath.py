import json
import os
import fnmatch
import xml.etree.ElementTree as ET
import re

def get_files_pdf(path):
    files_pdf = []
    for (root, dirs, files) in os.walk(path):
        for filename in files:
            if fnmatch.fnmatch(filename, '*.xml'):
                file_complete = os.path.join(root,filename)
                files_pdf.append(file_complete)
                print(file_complete)
                # Ejemplo de uso:
                # xml_file_path = 
                # start_limit = '<infoTributaria>'
                # end_limit = '</infoAdicional>'
                start_limit = '<factura id="comprobante" version="2.1.0">'
                end_limit = '<ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#" xmlns:etsi="http://uri.etsi.org/01903/v1.3.2#" Id="Signature933451">'
                extracted_xml = extract_xml_content_between_limits(file_complete, start_limit, end_limit)

                if extracted_xml:
                    print("Contenido XML extraído:")
                    print(extracted_xml)
                else:
                    print("No se pudo extraer el contenido XML.")
    
    return files_pdf

def extract_xml_content_between_limits(file_path, start_limit, end_limit):
    try:
        with open(file_path, "r", encoding="utf-8") as file:
            xml_content = file.read()

            # Buscar el contenido entre los límites
            match = re.search(f"{start_limit}(.*?){end_limit}", xml_content, re.DOTALL)

            if match:
                extracted_xml = match.group(1)
                return extracted_xml
            else:
                return None

    except FileNotFoundError:
        print(f"El archivo '{file_path}' no se encontró.")
    except Exception as e:
        print(f"Error al procesar el archivo: {e}")

    return None

# def extract_xml_content(file_path):
#     try:
#         with open(file_path, "r", encoding="utf-8") as file:
#             xml_content = file.read()
#         # Parsea el archivo XML
#         # tree = ET.parse(xml_content)
#         # root = tree.getroot()
#         root = ET.fromstring(xml_content)
#         # Encuentra el nodo 'infoTributaria'
#         info_tributaria = root.find('.//infoTributaria')

#         if info_tributaria is not None:
#             # Encuentra los elementos que necesitas
#             estab = info_tributaria.find('.//estab')
#             ptoEm = info_tributaria.find('.//ptoEmi')
#             secue = info_tributaria.find('.//secuencial')
#             campo_adicional = root.find('.//campoAdicional[@nombre="Instalacion"]')

#             if estab is not None and ptoEm is not None and secue is not None and campo_adicional is not None:
#                 # Obtiene el contenido de los elementos
#                 estab_text = estab.text
#                 ptoEm_text = ptoEm.text
#                 secue_text = secue.text
#                 codig_text = campo_adicional.text

#                 # Crea el nuevo nombre
#                 newname = f"FAC{estab_text}{ptoEm_text}{secue_text}-{codig_text}"
#                 return newname

#     except ET.ParseError as e:
#         print(f"Error al parsear el archivo XML: {e}")
#     return None

def main():
    try:
        with open("config.json", "r") as config_file:
            config = json.load(config_file)
            directorio = config.get("directorio")
            if directorio:
                listfiles = get_files_pdf(directorio)
            else:
                print("La configuracion no contiene la ruta del directorio.")
    except FileNotFoundError:
        print("El archivo de configuracion 'config.json' no se encuentra")

if __name__ == "__main__":
    main()