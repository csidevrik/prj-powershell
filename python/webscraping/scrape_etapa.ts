// scrape_etapa.ts
import { chromium } from "playwright";
import * as fs from "fs";

function arg(key: string, def?: string) {
  const i = process.argv.indexOf(`--${key}`);
  return i >= 0 ? process.argv[i+1] : def;
}

(async () => {
  const RUC = arg("ruc")!;
  const YEAR = arg("year")!;
  const MONTH = arg("month")!;
  const OUTFILE = arg("outfile", "salida.csv")!;
  const URL = "https://www.etapa.net.ec/appmietapa/facturacionElectronica";

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1366, height: 900 } });
  await page.goto(URL, { timeout: 60000 });

  const input = await page.$("input[placeholder*='Cédula'], input[placeholder*='RUC'], input[placeholder*='titular']") || await page.$("input");
  if (input) await input.fill(RUC);

  const selects = await page.$$("select");
  for (const s of selects) { try { await s.selectOption({ value: YEAR }); break; } catch {} }
  for (const s of selects) { try { await s.selectOption({ label: MONTH }); break; } catch {} }

  const btn = await page.$("button:has-text('Consultar')");
  if (btn) await btn.click({ timeout: 20000 });

  await page.waitForTimeout(1500);
  try { await page.waitForSelector("table tbody tr, [role='row']", { timeout: 20000 }); } catch {}

  for (let i=0; i<5; i++) { await page.mouse.wheel(0,2000); await page.waitForTimeout(400); }

  let rows = await page.$$("table tbody tr");
  let mode = "table";
  if (!rows.length) { rows = await page.$$("[role='grid'] [role='row']"); mode = rows.length ? "role-grid" : mode; }
  if (!rows.length) { rows = await page.$$("div,section,main,article"); mode = rows.length ? "div-heuristic" : "none"; }

  const data: {documento:string, instalacion:string, fecha:string}[] = [];
  for (const r of rows) {
    const cells = await r.$$(":scope td, [role='gridcell'], div, span");
    const texts: string[] = [];
    for (const c of cells) {
      const t = (await c.innerText()).trim();
      if (t) texts.push(t);
      if (texts.length >= 3) break;
    }
    if (!texts.length) {
      const t = (await r.innerText()).trim();
      if (t) texts.push(t);
    }
    const documento = texts[0] || "";
    const instalacion = texts[1] || "";
    const fecha = texts[2] || "";
    if (documento || instalacion || fecha) data.push({ documento, instalacion, fecha });
  }

  await page.screenshot({ path: OUTFILE.replace(/\.csv$/, ".png"), fullPage: true });
  require("fs").writeFileSync(OUTFILE.replace(/\.csv$/, ".html"), await page.content(), "utf8");

  await browser.close();

  const header = "documento,instalacion,fecha\n";
  const rowsCsv = data.map(d => `${d.documento},${d.instalacion},${d.fecha}`).join("\n");
  fs.writeFileSync(OUTFILE, header + rowsCsv, "utf8");
  console.log(`[OK] Filas: ${data.length} | Modo: ${mode}`);
  console.log(`[CSV] ${OUTFILE}`);
})().catch(e => { console.error(e); process.exit(1); });
