# etapa_api_to_csv.py
import argparse
import requests
import csv
import json
from pathlib import Path

def fetch_etapa_data(ruc: str, year: str, month: str):
    """
    Llama directamente al endpoint de ETAPA.
    Ajusta los parámetros según lo que responda la API real.
    """
    url = "https://www.etapa.net.ec/EtapaMobileApi/api/swrefael"
    params = {
        "cedula": ruc,       # algunos endpoints esperan 'cedula' en vez de 'ruc'
        "anio": year,
        "mes": month,        # puede requerir número ('09') o nombre ('Septiembre')
    }

    print(f"[INFO] Consultando {url} con parámetros {params}")
    resp = requests.get(url, params=params, timeout=20)

    if not resp.ok:
        raise RuntimeError(f"Error HTTP {resp.status_code}: {resp.text[:200]}")
    
    try:
        data = resp.json()
    except json.JSONDecodeError:
        raise RuntimeError("❌ La respuesta no es JSON. ETAPA pudo devolver HTML o un error temporal.")

    return data


def extract_rows(data: dict):
    """
    Extrae las filas relevantes del JSON. 
    Ajusta los nombres de campos según la estructura real.
    """
    # Verifica cómo viene el JSON: lista, dict, o dict con clave 'data'
    items = []
    if isinstance(data, dict):
        if "data" in data:
            items = data["data"]
        elif "lista" in data:
            items = data["lista"]
        elif "result" in data:
            items = data["result"]
        else:
            # Si solo hay un dict, lo convertimos en lista
            items = [data]
    elif isinstance(data, list):
        items = data
    else:
        raise ValueError("Formato de JSON desconocido.")

    # Ajusta estos nombres según el JSON real
    rows = []
    for it in items:
        if not isinstance(it, dict):
            continue
        rows.append({
            "documento": str(it.get("documento") or it.get("factura") or it.get("numFactura") or "").strip(),
            "instalacion": str(it.get("instalacion") or it.get("codigoInstalacion") or it.get("codigo") or "").strip(),
            "fecha": str(it.get("fecha") or it.get("periodo") or it.get("fechaEmision") or "").strip(),
            "valor": str(it.get("valor") or it.get("total") or "").strip(),
        })
    return rows


def save_csv(rows, outfile: Path):
    """
    Guarda las filas en un CSV con encabezados fijos.
    """
    outfile.parent.mkdir(parents=True, exist_ok=True)
    with open(outfile, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["documento", "instalacion", "fecha", "valor"])
        writer.writeheader()
        for r in rows:
            writer.writerow(r)
    print(f"✅ Archivo CSV generado: {outfile} ({len(rows)} filas)")


def main(ruc, year, month, outfile):
    try:
        data = fetch_etapa_data(ruc, year, month)
    except Exception as e:
        print("❌ Error al consultar la API:", e)
        return

    # Guarda el JSON crudo también para análisis
    json_path = Path(outfile).with_suffix(".json")
    json_path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"📁 JSON crudo guardado: {json_path}")

    try:
        rows = extract_rows(data)
    except Exception as e:
        print("⚠️ No se pudieron extraer las filas automáticamente:", e)
        print("Revisa el JSON guardado y ajusta los nombres de campos en extract_rows().")
        return

    if not rows:
        print("⚠️ No se encontraron registros. Revisa el JSON.")
        return

    save_csv(rows, Path(outfile))


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description="Consulta la API de ETAPA y exporta las facturas a CSV")
    ap.add_argument("--ruc", required=True, help="RUC o cédula del titular")
    ap.add_argument("--year", required=True, help="Año de consulta (ej. 2025)")
    ap.add_argument("--month", required=True, help="Mes (ej. 09 o Septiembre)")
    ap.add_argument("--outfile", default="etapa_facturas.csv", help="Archivo de salida CSV")
    args = ap.parse_args()
    main(args.ruc, args.year, args.month, args.outfile)
