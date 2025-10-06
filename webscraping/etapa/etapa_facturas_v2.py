import requests, csv, json
from pathlib import Path

API_URL = "https://www.etapa.net.ec/EtapaMobileApi/api/swrefael"
APP_URL = "https://www.etapa.net.ec/appmietapa/facturacionElectronica"

def find_first_list(obj):
    """Busca recursivamente la primera lista en un JSON (útil si varían las llaves)."""
    if isinstance(obj, list):
        return obj
    if isinstance(obj, dict):
        for v in obj.values():
            L = find_first_list(v)
            if L is not None:
                return L
    return None

def obtener_facturas(ruc: str, anio: int, mes: int | str, outfile: str, instalacion: str = ""):
    outfile = Path(outfile)

    # 1) Sesión para heredar cookies ASP.NET/Imperva
    s = requests.Session()
    ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36"
    s.get(APP_URL, headers={"User-Agent": ua}, timeout=30)

    # 2) Payload EXACTO de tus capturas (mes como '9', no '09')
    payload = {
        "anio": str(anio),
        "identificador": str(ruc),
        "instalacion": str(instalacion or ""),
        "mes": str(int(mes)),     # fuerza '9' si pasaste '09'
        "tipo": "01"
    }
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json, text/plain, */*",
        "Origin": "https://www.etapa.net.ec",
        "Referer": APP_URL,
        "User-Agent": ua,
    }

    # 3) POST y logs mínimos
    r = s.post(API_URL, headers=headers, json=payload, timeout=45)
    raw_path = outfile.with_suffix(".raw.txt")
    raw_path.write_text(r.text, encoding="utf-8")
    print(f"[HTTP] {r.status_code}  ct={r.headers.get('content-type')}  len={len(r.text)}")
    print(f"[INFO] Payload enviado: {payload}")

    if r.status_code != 200:
        raise RuntimeError(f"HTTP {r.status_code}. Guardé la respuesta en {raw_path}")

    # 4) Parse seguro + debug
    try:
        data = r.json()
    except json.JSONDecodeError:
        raise RuntimeError(f"La respuesta no es JSON. Revisa {raw_path}")

    debug_json = outfile.with_suffix(".debug.json")
    debug_json.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[DEBUG] Guardé el JSON completo en {debug_json}")

    # 5) Localiza la lista de facturas con tolerancia
    facturas = None
    if isinstance(data, dict):
        xfac = data.get("xFac") or data.get("xfac") or {}
        facturas = xfac.get("Facturas") or xfac.get("facturas")
    if not facturas:
        # fallback: encuentra la primera lista en el JSON
        facturas = find_first_list(data)

    if not facturas:
        tops = list(data.keys()) if isinstance(data, dict) else type(data)
        raise RuntimeError(f"Estructura inesperada. Top-level: {tops}. Revisa {debug_json}")

    # 6) Mapear campos (según los nombres que viste: insid, facdid, felanioem, felmesem, felacacc)
    rows = []
    for f in facturas:
        if not isinstance(f, dict): 
            continue
        rows.append({
            "instalacion": str(f.get("insid", "")),
            "factura": str(f.get("facdid", "")),
            "anio": str(f.get("felanioem", "")),
            "mes": str(f.get("felmesem", "")),
            "codigo_acceso": str(f.get("felacacc", "")),
            "tipo": str(f.get("felcodigo", "")),
        })

    if not rows:
        raise RuntimeError(f"Encontré la lista pero sin campos esperados. Revisa {debug_json}")

    # 7) CSV
    with open(outfile, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=rows[0].keys())
        w.writeheader(); w.writerows(rows)

    print(f"✅ CSV: {outfile} ({len(rows)} filas)")
    print(f"🧾 JSON crudo: {debug_json}")
    print(f"🗒️  Respuesta cruda: {raw_path}")

if __name__ == "__main__":
    # Ejemplo: septiembre 2025
    obtener_facturas("0160049360001", 2025, 9, "facturas_etapa_sep_2025.csv")
