import json
import os
import fnmatch

def get_files_pdf(path):
    files_pdf = []
    for (root, dirs, files) in os.walk(path):
        for filename in files:
            if fnmatch.fnmatch(filename, '*.pdf'):
                file_complete = os.path.join(root,filename)
                files_pdf.append(file_complete)
                print(file_complete)
    
    return files_pdf

def extract_code_from_filename(filename):
    regex1 = "RDD([+-]?(?=\.\d|\d)(?:\d+)?(?:\.?\d*))(?:[Ee]([+-]?\d+))?"
    regex2 = "I[0-9]+"
    # Utilizamos una expresión regular para buscar un patrón específico (cualquier secuencia de letras mayúsculas y números) en el nombre del archivo.
    match = re.search(regex2, filename)

        
    if match:
        # Si se encuentra un patrón, lo extraemos y lo devolvemos.
        return match.group()
    else:
        # Si no se encuentra un patrón, devolvemos None.
        return None



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