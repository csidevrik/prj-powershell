# etapa_capture_after_click.py
import re, json, csv, sys
from pathlib import Path
from playwright.sync_api import sync_playwright, TimeoutError as PWTimeout

URL = "https://www.etapa.net.ec/appmietapa/facturacionElectronica"

# Ajusta el patrón si ves otra URL en Network (DevTools):
DATA_RE = re.compile(r"(factura|facturacion|consulta|documento)", re.I)

def main(ruc: str, year: str, month: str, outfile: str):
    outfile = Path(outfile)

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False)  # visible para que hagas el clic
        ctx = browser.new_context(viewport={"width": 1366, "height": 900})
        page = ctx.new_page()

        # Bloquear recursos pesados para que cargue más rápido
        def filter_route(route):
            r = route.request
            if r.resource_type in {"image","font","stylesheet","media"}:
                return route.abort()
            if any(x in r.url for x in ["googletagmanager","google-analytics","hotjar","facebook","pdfjs-"]):
                return route.abort()
            return route.continue_()
        page.route("**/*", filter_route)

        page.goto(URL, timeout=60000)

        # Escribir el RUC con “tecleo” (dispara eventos reales)
        inp = page.locator("input").first
        inp.click()
        page.keyboard.type(ruc, delay=60)

        # (Opcional) si hay selects de año/mes en esta vista, ajústalos aquí si existen:
        # for s in page.locator("select").all():
        #     try: s.select_option(value=year)
        #     except: pass
        # for s in page.locator("select").all():
        #     try: s.select_option(label=month)
        #     except: pass

        print("\n👉 Ahora HAZ CLIC tú en el botón naranja 'Consultar'.")
        print("   Cuando lo hagas y veas que empieza a cargar, vuelve a esta consola y presiona ENTER.")
        # Preparamos el “sniffer” de respuestas ANTES de que hagas clic:
        captures = []
        def on_response(resp):
            url = resp.url
            if DATA_RE.search(url):
                try:
                    if "application/json" in (resp.headers.get("content-type","")) or url.endswith(".json"):
                        data = resp.json()
                        captures.append((url, data))
                        print("[NET] JSON capturado:", url)
                except Exception:
                    pass
        ctx.on("response", on_response)

        input("⏸️  Esperando tu clic...  (presiona ENTER aquí después de hacer clic en 'Consultar')\n")

        # Dar unos segundos para que lleguen las XHR
        try:
            # espera explícita a una respuesta que machee el patrón
            with page.expect_response(lambda r: DATA_RE.search(r.url), timeout=20000) as resp_wait:
                pass
            _ = resp_wait.value  # no usamos directamente; igual tenemos 'captures'
        except PWTimeout:
            pass

        page.wait_for_timeout(2500)

        # Auditoría: captura pantalla y HTML (por si hace falta depurar)
        page.screenshot(path=str(outfile.with_suffix(".png")), full_page=True)
        outfile.with_suffix(".html").write_text(page.content(), encoding="utf-8")

        if not captures:
            print("⚠️ No se detectó ninguna respuesta JSON. Abre DevTools → Network y dime la URL real; ajustamos DATA_RE.")
            return

        # Toma el primer payload “útil”
        url, payload = captures[-1]  # el último suele ser el listado
        # Guarda el JSON tal cual también
        outfile.with_suffix(".json").write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

        # ---- adapta esta función si la estructura difiere ----
        def extrae_filas(js):
            """
            Devuelve lista de dicts con 'documento', 'instalacion', 'fecha'
            Ajusta campos según el JSON real (revisa el .json guardado).
            """
            filas = []
            data = js.get("data") if isinstance(js, dict) else js
            if isinstance(data, list):
                for it in data:
                    filas.append({
                        "documento": str(it.get("documento","")).strip(),
                        "instalacion": str(it.get("instalacion","")).strip(),
                        "fecha": str(it.get("fecha","")).strip(),
                    })
            elif isinstance(data, dict) and "items" in data:
                for it in data["items"]:
                    filas.append({
                        "documento": str(it.get("documento","")).strip(),
                        "instalacion": str(it.get("instalacion","")).strip(),
                        "fecha": str(it.get("fecha","")).strip(),
                    })
            return filas
        # ------------------------------------------------------

        filas = extrae_filas(payload)
        if not filas:
            print("⚠️ No pude mapear campos. Revisa el JSON guardado y dime cómo vienen los nombres (te ajusto la función).")
            return

        with open(outfile, "w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=["documento","instalacion","fecha"])
            w.writeheader(); w.writerows(filas)

        print(f"✅ CSV generado: {outfile}  (filas: {len(filas)})")
        print(f"🧾 JSON crudo:  {outfile.with_suffix('.json')}")
        print(f"🖼️ PNG:         {outfile.with_suffix('.png')}")
        print(f"🧩 HTML:        {outfile.with_suffix('.html')}")
        browser.close()

if __name__ == "__main__":
    # Uso: python etapa_capture_after_click.py --ruc 0160049360001 --year 2025 --month Septiembre --outfile septiembre_2025.csv
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--ruc", required=True)
    ap.add_argument("--year", required=True)
    ap.add_argument("--month", required=True)
    ap.add_argument("--outfile", default="salida.csv")
    args = ap.parse_args()
    main(args.ruc, args.year, args.month, args.outfile)
