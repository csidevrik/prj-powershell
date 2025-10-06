# scrape_etapa.py
"""
Scraper para https://www.etapa.net.ec/appmietapa/facturacionElectronica
- Simula un navegador humano (Playwright + Chromium)
- Rellena el RUC, el año y el mes
- Extrae la tabla renderizada (sea <table> o "div-rows")
- Guarda CSV + captura de pantalla + HTML de respaldo (auditoría)

Requisitos:
  pip install playwright
  playwright install chromium

Uso:
  python scrape_etapa.py --ruc 0160049360001 --year 2025 --month Septiembre --outfile septiembre_2025.csv
"""
import argparse
import csv
from pathlib import Path
from playwright.sync_api import sync_playwright, TimeoutError as PlaywrightTimeout

def safe_text(el):
    try:
        return el.inner_text().strip()
    except Exception:
        return ""

def find_table_rows(page):
    # 1) tabla convencional
    rows = page.query_selector_all("table tbody tr")
    if rows:
        return rows, "table"
    # 2) por roles
    grid = page.query_selector("[role='grid'], table, div[role='table']")
    if grid:
        rows = grid.query_selector_all("[role='row']")
        rows = [r for r in rows if not r.query_selector("[role='columnheader']")]
        if rows:
            return rows, "role-grid"
    # 3) fallback: heurística por divs
    candidates = page.query_selector_all("div,section,main,article")
    best = []
    for c in candidates[:200]:
        cells = c.query_selector_all(":scope > *")
        if len(cells) >= 3:
            txts = [safe_text(x) for x in cells[:3]]
            if all(t for t in txts):
                best.append(c)
    if best:
        return best, "div-heuristic"
    return [], "none"

def scrape_etapa(ruc: str, year: str, month_label: str, outfile: Path):
    url = "https://www.etapa.net.ec/appmietapa/facturacionElectronica"
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={"width": 1366, "height": 900})
        page.goto(url, timeout=60000)

        # input del RUC
        sel_input = "input[placeholder*='Cédula'], input[placeholder*='RUC'], input[placeholder*='titular']"
        if page.query_selector(sel_input):
            page.fill(sel_input, ruc)
        else:
            # fallback: primer input
            inputs = page.query_selector_all("input")
            if inputs:
                inputs[0].fill(ruc)

        # seleccionar año
        selects = page.query_selector_all("select")
        for s in selects:
            try:
                s.select_option(value=year)
                break
            except Exception:
                pass

        # seleccionar mes por label
        for s in selects:
            try:
                s.select_option(label=month_label)
                break
            except Exception:
                pass

        # click Consultar
        btn = page.locator("button:has-text('Consultar')")
        btn.first.click()

        page.wait_for_timeout(1500)
        try:
            page.wait_for_selector("table tbody tr, [role='row']", timeout=20000)
        except PlaywrightTimeout:
            pass

        # scroll para virtualización
        for _ in range(5):
            page.mouse.wheel(0, 2000)
            page.wait_for_timeout(400)

        rows, mode = find_table_rows(page)

        # Auditoría
        outfile = Path(outfile)
        page.screenshot(path=str(outfile.with_suffix(".png")), full_page=True)
        with open(outfile.with_suffix(".html"), "w", encoding="utf-8") as f:
            f.write(page.content())

        data = []
        for r in rows:
            cells = r.query_selector_all("td, [role='gridcell'], div, span")
            texts = [safe_text(c) for c in cells if safe_text(c)]
            if not texts:
                t = safe_text(r)
                if t:
                    texts = [t]
            documento = texts[0] if len(texts) > 0 else ""
            instalacion = texts[1] if len(texts) > 1 else ""
            fecha = texts[2] if len(texts) > 2 else ""
            data.append({"documento": documento, "instalacion": instalacion, "fecha": fecha})

        browser.close()

    # CSV
    with open(outfile, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["documento","instalacion","fecha"])
        w.writeheader()
        for row in data:
            w.writerow(row)

    print(f"[OK] Filas extraídas: {len(data)} | Modo: {mode}")
    print(f"[CSV] {outfile}")
    print(f"[PNG] {outfile.with_suffix('.png')}")
    print(f"[HTML] {outfile.with_suffix('.html')}")

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--ruc", required=True)
    ap.add_argument("--year", required=True)
    ap.add_argument("--month", required=True)
    ap.add_argument("--outfile", default="salida.csv")
    args = ap.parse_args()
    scrape_etapa(args.ruc, args.year, args.month, Path(args.outfile))
