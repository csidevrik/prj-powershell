# scrape_etapa_v2.py
import argparse, csv, time
from pathlib import Path
from playwright.sync_api import sync_playwright, TimeoutError as PWTimeout

URL = "https://www.etapa.net.ec/appmietapa/facturacionElectronica"

def safe(el, fn, default=""):
    try:
        return fn(el)
    except Exception:
        return default

def find_rows(page):
    rows = page.query_selector_all("table tbody tr")
    if rows: return rows, "table"
    grid = page.query_selector("[role='grid'], div[role='table']")
    if grid:
        rows = [r for r in grid.query_selector_all("[role='row']") if not r.query_selector("[role='columnheader']")]
        if rows: return rows, "role-grid"
    # Heurística: contenedores con varios hijos tipo columna
    cands = page.query_selector_all("div,section,main,article")
    best = []
    for c in cands[:200]:
        cells = c.query_selector_all(":scope > *")
        if len(cells) >= 3:
            txts = [safe(x, lambda e: e.inner_text().strip()) for x in cells[:3]]
            if all(t for t in txts): best.append(c)
    if best: return best, "div-heuristic"
    return [], "none"

def click_consultar(page):
    tried = []
    # 1) por rol
    try:
        page.get_by_role("button", name="Consultar").click(timeout=5000)
        return "role-name"
    except Exception as e:
        tried.append(f"role-name:{e}")

    # 2) por texto
    try:
        page.locator("button:has-text('Consultar')").first.click(timeout=5000)
        return "button-has-text"
    except Exception as e:
        tried.append(f"button-has-text:{e}")

    # 3) cualquier botón con texto aproximado
    try:
        page.get_by_text("Consultar", exact=False).first.click(timeout=5000)
        return "text"
    except Exception as e:
        tried.append(f"text:{e}")

    # 4) ejecutar JS (último recurso)
    try:
        page.evaluate("""
            (() => {
              const btns = Array.from(document.querySelectorAll('button, [role=button]'));
              const b = btns.find(b => (b.innerText||'').toLowerCase().includes('consultar'));
              if (b) b.click();
            })();
        """)
        return "evaluate-js"
    except Exception as e:
        tried.append(f"eval-js:{e}")

    raise RuntimeError("No pude clicar el botón Consultar. Intentos: " + " | ".join(tried))

def fill_ruc_resistente(page, ruc: str):
    # 0) espera a que termine de cargar bien la vista
    page.wait_for_load_state("domcontentloaded")
    try:
        page.wait_for_load_state("networkidle", timeout=8000)
    except PWTimeout:
        pass

    # 1) placeholder directo (si el componente lo expone)
    try:
        loc = page.get_by_placeholder("Cédula/RUC del titular")
        loc.wait_for(state="visible", timeout=3000)
        loc.fill(ruc)
        # verifica si quedó algo escrito
        if loc.input_value().strip():
            return "placeholder.fill"
    except Exception:
        pass

    # 2) click + teclear (eventos reales de teclado)
    try:
        loc = page.locator("input").first
        loc.wait_for(state="visible", timeout=3000)
        loc.click()
        page.keyboard.type(ruc, delay=80)  # simula tecleo humano
        if loc.input_value().strip():
            return "keyboard.type"
    except Exception:
        pass

    # 3) fill forzado
    try:
        loc = page.locator("input").first
        loc.fill(ruc, force=True)
        if loc.input_value().strip():
            return "fill.force"
    except Exception:
        pass

    # 4) setear por JS y disparar eventos (Angular/React)
    try:
        loc = page.locator("input").first
        handle = loc.element_handle(timeout=3000)
        page.evaluate(
            """(el, value) => {
                const set = Object.getOwnPropertyDescriptor(el.__proto__, 'value')?.set;
                if (set) set.call(el, value); else el.value = value;
                el.dispatchEvent(new Event('input', { bubbles: true }));
                el.dispatchEvent(new Event('change', { bubbles: true }));
            }""",
            handle, ruc
        )
        # verifica
        if loc.input_value().strip():
            return "js.dispatch"
    except Exception:
        pass

    # 5) si estuviera en un iframe
    try:
        for fr in page.frames:
            if fr == page.main_frame: 
                continue
            loc = fr.locator("input").first
            if loc.is_visible():
                loc.click()
                fr.keyboard.type(ruc, delay=80)
                if loc.input_value().strip():
                    return "iframe.type"
    except Exception:
        pass

    return "no-pudo"

def click_consultar_resistente(page):
    """
    Clic en 'Consultar' usando varias estrategias válidas para Playwright.
    Devuelve el modo que funcionó.
    """
    # 1) Por rol + nombre exacto
    try:
        page.get_by_role("button", name="Consultar").click(timeout=3000)
        return "role:name=Consultar"
    except Exception:
        pass

    # 2) Por rol + regex (por si hay espacios o mayúsculas/minúsculas)
    try:
        page.get_by_role("button", name=re.compile(r"Consultar", re.I)).first.click(timeout=3000)
        return "role:regex"
    except Exception:
        pass

    # 3) CSS con has_text (solo CSS, sin mezclar 'text=')
    try:
        page.locator("button", has_text="Consultar").first.click(timeout=3000)
        return "css:button[has_text]"
    except Exception:
        pass

    # 4) Por elemento con role=button y has_text
    try:
        page.locator("[role=button]", has_text="Consultar").first.click(timeout=3000)
        return "css:[role=button][has_text]"
    except Exception:
        pass

    # 5) Texto visible (motor de texto de Playwright, llamado aparte)
    try:
        page.get_by_text("Consultar", exact=False).first.click(timeout=3000)
        return "text-engine"
    except Exception:
        pass

    # 6) Presionar Enter en el input (muchos formularios lo aceptan)
    try:
        page.locator("input").first.press("Enter")
        return "press-enter"
    except Exception:
        pass

    # 7) Click por bounding box (coordenadas del centro)
    try:
        btn = page.get_by_role("button", name=re.compile(r"Consultar", re.I)).first
        handle = btn.element_handle(timeout=3000)
        box = handle.bounding_box()
        if box:
            x = box["x"] + box["width"]/2
            y = box["y"] + box["height"]/2
            page.mouse.move(x, y); page.mouse.click(x, y)
            return "bbox-mouse"
    except Exception:
        pass

    # 8) Último recurso: ejecutar click vía JS sobre el primer botón con ese texto
    try:
        page.evaluate("""
            const nodes = Array.from(document.querySelectorAll('button,[role=button],.btn,.q-btn,.v-btn'));
            const b = nodes.find(n => (n.innerText||'').trim().includes('Consultar'));
            if (b) b.click();
        """)
        return "js-click"
    except Exception as e:
        raise RuntimeError(f"No pude clicar 'Consultar': {e}")



def scrape(ruc, year, month, outfile):
    with sync_playwright() as p:
        # headless=False para ver qué pasa
        browser = p.chromium.launch(headless=False, slow_mo=150)
        page = browser.new_page(viewport={"width": 1366, "height": 900})
        page.goto(URL, timeout=60000)

        # Aceptar posibles banners (intenta cerrarlos, si existen)
        for sel in ["button:has-text('Aceptar')", "button:has-text('Entendido')", "text=Aceptar", "text=Entendido"]:
            try: page.locator(sel).first.click(timeout=1000)
            except: pass

        # Completar RUC
        modo = fill_ruc_resistente(page, ruc)
        print("[DEBUG] modo de llenado RUC =", modo)

        modo_click = click_consultar_resistente(page)
        print("[DEBUG] click Consultar =", modo_click)

        # # Si la app muestra pantalla negra “Cargando…”, espera a que desaparezca:
        # try:
        #     page.wait_for_load_state("networkidle", timeout=15000)
        # except:
        #     pass
        # page.wait_for_timeout(800)  # respiro corto

        

        # Seleccionar año
        selects = page.query_selector_all("select")
        for s in selects:
            try:
                s.select_option(value=year); break
            except: pass

        # Seleccionar mes por label
        for s in selects:
            try:
                s.select_option(label=month); break
            except: pass

        # A veces el botón aparece fuera de vista
        page.mouse.wheel(0, 1500)
        time.sleep(0.5)

        mode_click = click_consultar(page)

        # Espera carga de filas
        time.sleep(1.0)
        try:
            page.wait_for_selector("table tbody tr, [role='row']", timeout=20000)
        except PWTimeout:
            pass

        # Scroll adicional por si hay virtualización
        for _ in range(6):
            page.mouse.wheel(0, 1800)
            time.sleep(0.35)

        rows, mode_rows = find_rows(page)

        # Auditoría
        outfile = Path(outfile)
        page.screenshot(path=str(outfile.with_suffix(".png")), full_page=True)
        outfile.with_suffix(".html").write_text(page.content(), encoding="utf-8")

        data = []
        for r in rows:
            cells = r.query_selector_all("td, [role='gridcell'], div, span")
            texts = []
            for c in cells:
                t = safe(c, lambda e: e.inner_text().strip())
                if t: texts.append(t)
                if len(texts) >= 3: break
            if not texts:
                t = safe(r, lambda e: e.inner_text().strip())
                if t: texts = [t]
            documento = texts[0] if len(texts)>0 else ""
            instalacion = texts[1] if len(texts)>1 else ""
            fecha = texts[2] if len(texts)>2 else ""
            if documento or instalacion or fecha:
                data.append({"documento": documento, "instalacion": instalacion, "fecha": fecha})

        browser.close()

    # Guardar CSV
    with open(outfile, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["documento","instalacion","fecha"])
        w.writeheader()
        w.writerows(data)

    print(f"[OK] clic por: {mode_click} | filas: {len(data)} | modo filas: {mode_rows}")
    print(f"[CSV] {outfile} | [PNG] {outfile.with_suffix('.png')} | [HTML] {outfile.with_suffix('.html')}")

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--ruc", required=True)
    ap.add_argument("--year", required=True)
    ap.add_argument("--month", required=True)
    ap.add_argument("--outfile", default="salida.csv")
    args = ap.parse_args()
    scrape(args.ruc, args.year, args.month, Path(args.outfile))
