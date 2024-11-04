import platform
import csv
import json
import hashlib
import os
import re
import subprocess
import flet as ft
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from typing import Optional, List
from pathlib import Path

@dataclass
class Invoice:
    """Represents an invoice record with installation code, invoice number and service value."""
    code_inst: str
    number_fac: str
    value_serv: float

@dataclass
class Retention:
    """Represents a retention record with retention number, value and associated invoice number."""
    ret_number: str
    ret_value: float
    fac_number: str

class XMLProcessor:
    """Handles XML file processing and modifications."""
    
    @staticmethod
    def clean_xml_content(file_path: Path) -> None:
        """Removes CDATA tags and replaces XML entities in the file."""
        replacements = {
            '<![CDATA[<?xml version="1.0" encoding="UTF-8"?><comprobanteRetencion id="comprobante" version="1.0.0">': '',
            '</comprobanteRetencion>]]>': '',
            '&lt;': '<',
            '&gt;': '>'
        }
        
        content = file_path.read_text(encoding='utf-8')
        for old, new in replacements.items():
            content = content.replace(old, new)
        file_path.write_text(content, encoding='utf-8')

    @staticmethod
    def extract_invoice_data(xml_path: Path) -> Invoice:
        """Extracts invoice data from XML file."""
        tree = ET.parse(xml_path)
        root = tree.getroot()
        
        estab = root.find(".//estab").text
        pto_em = root.find(".//ptoEmi").text
        secue = root.find(".//secuencial").text
        codigo = root.find('.//campoAdicional[@nombre="Instalacion"]').text
        
        numero_factura = f"FAC{estab}{pto_em}{secue}"
        valor_servicio = float(root.find(".//totalSinImpuestos").text)
        
        return Invoice(codigo, numero_factura, valor_servicio)

    @staticmethod
    def extract_retention_data(xml_path: Path) -> Retention:
        """Extracts retention data from XML file."""
        tree = ET.parse(xml_path)
        root = tree.getroot()
        
        estab = root.find(".//estab").text
        pto_em = root.find(".//ptoEmi").text
        secue = root.find(".//secuencial").text
        
        ret_number = f"{estab}-{pto_em}-{secue}"
        ret_value = float(root.find(".//valorRetenido").text)
        fac_num = root.find(".//numDocSustento").text
        fac_number = f"FAC{fac_num}"
        
        return Retention(ret_number, ret_value, fac_number)

class FileManager:
    """Handles file operations including renaming, removing duplicates, and converting formats."""
    
    @staticmethod
    def remove_duplicates(folder_path: Path) -> None:
        """Removes duplicate files based on their content hash."""
        files = list(folder_path.glob('*'))
        hash_map = {}
        
        for file_path in files:
            file_hash = hashlib.sha256(file_path.read_bytes()).hexdigest()
            if file_hash in hash_map:
                hash_map[file_hash].append(file_path)
            else:
                hash_map[file_hash] = [file_path]
        
        for file_group in hash_map.values():
            if len(file_group) > 1:
                oldest_file = min(file_group, key=lambda x: x.stat().st_ctime)
                for file_path in file_group:
                    if file_path != oldest_file:
                        file_path.unlink()

    @staticmethod
    def remove_pdf_prefix(folder_path: Path, prefix: str) -> None:
        """Removes specified prefix from PDF filenames."""
        for pdf_file in folder_path.glob('*.pdf'):
            if pdf_file.stem.startswith(prefix):
                new_name = pdf_file.with_name(f"{pdf_file.stem[len(prefix):]}.pdf")
                pdf_file.rename(new_name)

class DocumentViewer:
    """Handles document viewing operations."""
    
    @staticmethod
    def get_browser_command(browser: str) -> str:
        """Returns the appropriate browser command based on the operating system."""
        if platform.system() == "Linux":
            return {"chrome": "google-chrome", "firefox": "firefox"}[browser]
        elif platform.system() == "Windows":
            return f"start {browser}"
        raise OSError("Unsupported operating system")

    @classmethod
    def open_pdfs_in_browser(cls, folder_path: Path, browser: str) -> None:
        """Opens all PDFs in the specified browser."""
        command = cls.get_browser_command(browser)
        pdf_files = sorted(folder_path.glob('*.pdf'), 
                         key=lambda x: x.stat().st_mtime, 
                         reverse=True)
        
        for pdf_file in pdf_files:
            subprocess.run(f"{command} --new-tab {pdf_file.absolute()}", shell=True)

class AppGUI:
    """Main GUI application class using Flet."""
    
    def __init__(self):
        self.file_manager = FileManager()
        self.doc_viewer = DocumentViewer()
        self.xml_processor = XMLProcessor()
        
    def main(self, page: ft.Page):
        """Initialize and configure the main application window."""
        self._configure_page(page)
        self._setup_controls(page)
        self._create_layout(page)
    
    def _configure_page(self, page: ft.Page):
        """Configure page properties."""
        page.title = "Document Processor"
        page.padding = 0
        page.bgcolor = ft.colors.with_opacity(0.90, '#07D2A9')
        page.window.height = 500
        page.window.width = 1000
        page.window.max_width = 1200
        page.window.max_height = 600
        
        page.appbar = ft.AppBar(
            leading=ft.Icon(ft.icons.DOOR_SLIDING),
            leading_width=100,
            title=ft.Text("Document Processor"),
            center_title=True,
            bgcolor=ft.colors.with_opacity(0.90, '#07D2A9')
        )
        
        page.update()

    def _setup_controls(self, page: ft.Page):
        """Set up all control elements."""
        self.directory_path = ft.Text()
        self.selected_files = ft.Text()
        
        self.get_directory_dialog = ft.FilePicker(
            on_result=lambda e: self._handle_directory_selection(e, page)
        )
        
        self.pick_files_dialog = ft.FilePicker(
            on_result=lambda e: self._handle_file_selection(e, page)
        )
        
        page.overlay.extend([self.get_directory_dialog, self.pick_files_dialog])

    def _create_layout(self, page: ft.Page):
        """Create the main application layout."""
        actions_button = self._create_actions_menu()
        directory_button = ft.ElevatedButton(
            "Open directory",
            icon=ft.icons.FOLDER_OPEN,
            on_click=lambda _: self.get_directory_dialog.get_directory_path(),
            disabled=page.web
        )
        
        page.add(
            actions_button,
            self.directory_path,
            self.selected_files,
            ft.Row([directory_button, self.directory_path])
        )

    def _create_actions_menu(self) -> ft.PopupMenuButton:
        """Create the actions popup menu."""
        return ft.PopupMenuButton(items=[
            ft.PopupMenuItem(
                icon=ft.icons.BROWSER_UPDATED_SHARP,
                text="Open in Firefox",
                on_click=lambda _: self.doc_viewer.open_pdfs_in_browser(
                    Path(self.directory_path.value), "firefox"
                )
            ),
            ft.PopupMenuItem(
                icon=ft.icons.BROWSER_UPDATED_SHARP,
                text="Open in Chrome",
                on_click=lambda _: self.doc_viewer.open_pdfs_in_browser(
                    Path(self.directory_path.value), "chrome"
                )
            ),
            ft.PopupMenuItem(
                icon=ft.icons.CONTROL_POINT_DUPLICATE_SHARP,
                text="Remove duplicates",
                on_click=lambda _: self.file_manager.remove_duplicates(
                    Path(self.directory_path.value)
                )
            ),
            # Add other menu items as needed
        ])

    def _handle_directory_selection(self, e: ft.FilePickerResultEvent, page: ft.Page):
        """Handle directory selection event."""
        self.directory_path.value = e.path if e.path else "Cancelled!"
        self.directory_path.update()

    def _handle_file_selection(self, e: ft.FilePickerResultEvent, page: ft.Page):
        """Handle file selection event."""
        self.selected_files.value = (
            ",".join(map(lambda f: f.name, e.files)) if e.files else "Cancelled!"
        )
        self.selected_files.update()

def main():
    """Application entry point."""
    app = AppGUI()
    ft.app(target=app.main)

if __name__ == "__main__":
    main()