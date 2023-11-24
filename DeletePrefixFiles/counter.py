import flet
from flet import (
    ElevatedButton,
    FilePicker,
    FilePickerResultEvent,
    Page,
    Row,
    Text,
    icons,
)

## SOLO METODOS DE ACCIONES POR COMANDOS


def extract_code_from_filename(folderPath):
# Utilizamos una expresión regular para buscar un patrón específico (cualquier secuencia de letras mayúsculas y números) en el nombre del archivo.
match = re.search(r"I[0-9]+", folderPath)

if match:
    # Si se encuentra un patrón, lo extraemos y lo devolvemos.
    return match.group()
else:
    # Si no se encuentra un patrón, devolvemos None.
    return None

regex1 = "RDD([+-]?(?=\.\d|\d)(?:\d+)?(?:\.?\d*))(?:[Ee]([+-]?\d+))?"
regex2 = "I[0-9]+"

def open_pdf_with_firefox(folderPath):
    #Obtener los nombres de todos los pdfs
    files = os.listdir(folderPath)
    filesPDF = [file for file in files if file.endswith(".pdf")]
    filesPDF.sort(key=lambda x: os.path.getmtime(os.path.join(folderPath, x)), reverse=True)
    contador = 0
    for filePDF in filesPDF:
        contador += 1
        pathComplete = os.path.abspath(os.path.join(folderPath, filePDF))
        print(pathComplete)
        # Abre el archivo PDF en Firefox
        subprocess.run(["firefox", "--new-tab", f"file://{pathComplete}"])
        print(contador)
        time.sleep(1)


def main(page: Page):
    # Pick files dialog
    def pick_files_result(e: FilePickerResultEvent):
        selected_files.value = (
            ", ".join(map(lambda f: f.name, e.files)) if e.files else "Cancelled!"
        )
        selected_files.update()

    pick_files_dialog = FilePicker(on_result=pick_files_result)
    selected_files = Text()

    # Save file dialog
    def save_file_result(e: FilePickerResultEvent):
        save_file_path.value = e.path if e.path else "Cancelled!"
        save_file_path.update()

    save_file_dialog = FilePicker(on_result=save_file_result)
    save_file_path = Text()

    # Open directory dialog
    def get_directory_result(e: FilePickerResultEvent):
        directory_path.value = e.path if e.path else "Cancelled!"
        directory_path.update()

    get_directory_dialog = FilePicker(on_result=get_directory_result)
    directory_path = Text()

    # hide all dialogs in overlay
    page.overlay.extend([pick_files_dialog, save_file_dialog, get_directory_dialog])

    page.add(
        Row(
            [
                ElevatedButton(
                    "Pick files",
                    icon=icons.UPLOAD_FILE,
                    on_click=lambda _: pick_files_dialog.pick_files(
                        allow_multiple=True
                    ),
                ),
                selected_files,
            ]
        ),
        Row(
            [
                ElevatedButton(
                    "Save file",
                    icon=icons.SAVE,
                    on_click=lambda _: save_file_dialog.save_file(),
                    disabled=page.web,
                ),
                save_file_path,
            ]
        ),
        Row(
            [
                ElevatedButton(
                    "Open directory",
                    icon=icons.FOLDER_OPEN,
                    on_click=lambda _: get_directory_dialog.get_directory_path(),
                    disabled=page.web,
                ),
                directory_path,
            ]
        ),
    )


flet.app(target=main)