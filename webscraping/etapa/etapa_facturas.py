import requests, csv, json
from pathlib import Path

API_URL = "https://www.etapa.net.ec/EtapaMobileApi/api/swrefael"
APP_URL = "https://www.etapa.net.ec/appmietapa/facturacionElectronica"

def obtener_facturas(ruc, anio, mes, outfile):
    # Sesión persistente para cookies
    s = requests.Session()
    s.get(APP_URL)  # inicializa cookies

    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Origin": "https://www.etapa.net.ec",
        "Referer": APP_URL,
        "User-Agent": "Mozilla/5.0"
    }

    payload = {
        "anio": str(anio),
        "identificador": str(ruc),
        "instalacion": "",
        "mes": str(int(mes)),
        "tipo": "01"
    }

    r = s.post(API_URL, headers=headers, json=payload)
    r.raise_for_status()

    data = r.json()
    facturas = data["xFac"]["Facturas"]

    filas = []
    for f in facturas:
        filas.append({
            "instalacion": f.get("insid", ""),
            "factura": f.get("facdid", ""),
            "codigo_acceso": f.get("felacacc", ""),
            "anio": f.get("felanioem", ""),
            "mes": f.get("felmesem", ""),
            "tipo": f.get("felcodigo", "")
        })

    with open(outfile, "w", newline="", encoding="utf-8") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=filas[0].keys())
        writer.writeheader()
        writer.writerows(filas)

    print(f"✅ {len(filas)} facturas guardadas en {outfile}")

if __name__ == "__main__":
    obtener_facturas("0160049360001", 2025, 9, "facturas_etapa.csv")
