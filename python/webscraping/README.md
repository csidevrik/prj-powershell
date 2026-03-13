# ETAPA Scraper (Playwright)

Extrae la tabla de https://www.etapa.net.ec/appmietapa/facturacionElectronica y la guarda en CSV.
Incluye Python y TypeScript. **No modifica facturas**; sólo captura datos visibles.

## Python
```bash
pip install playwright
playwright install chromium
python scrape_etapa.py --ruc 0160049360001 --year 2025 --month Septiembre --outfile septiembre_2025.csv
```

## TypeScript
```bash
npm i -D playwright ts-node typescript
npx playwright install chromium
npx ts-node scrape_etapa.ts --ruc 0160049360001 --year 2025 --month Septiembre --outfile septiembre_2025.csv
```
## TypeScript
```bash
python .\etapa_facturas_v2.py --ruc 0160049360001 --year 2025 --month Septiembre --outfile septiembre_2025.csv
```

El script genera también PNG y HTML de respaldo para auditoría.
Si cambian los selectores, abre el PNG/HTML y ajusta el código.
