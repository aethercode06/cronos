"""Exporta la historia de Chronos (escenas, diálogos y frases de Tic) a engine/chronos/niveles/historia.json."""
import json, os
from playwright.sync_api import sync_playwright
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
with sync_playwright() as pw:
    b = pw.chromium.launch(args=['--headless=new'])
    pg = b.new_page(viewport={'width': 960, 'height': 540})
    pg.goto('file://' + os.path.join(ROOT, 'www', 'index.html'))
    pg.wait_for_function("typeof state !== 'undefined' && state !== 'loading'", timeout=120000)
    d = pg.evaluate("() => ({who: WHO, cuts: CUTS, ticl: TICL, bossl: BOSSL, fragl: FRAGL, ticq: TICQ, lore: WORLDS.map(w => w.lore)})")
    json.dump(d, open(os.path.join(ROOT, 'engine', 'chronos', 'niveles', 'historia.json'), 'w'), ensure_ascii=False)
    print({k: len(v) for k, v in d.items()})
    b.close()
