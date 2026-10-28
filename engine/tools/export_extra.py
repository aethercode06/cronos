"""Exporta fases de la Torre del Tiempo (40 pisos × 2 variantes) y las 18 Grietas del Tiempo
del juego web a engine/chronos/niveles/ (torre_v*_*.json, grieta_*.json)."""
import json, os
from playwright.sync_api import sync_playwright
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, 'engine', 'chronos', 'niveles')
CLEAN = r"""
  const seen = new WeakMap(); let nextId = 1;
  const clean = (o) => {
    if (o === null || typeof o !== 'object') return (typeof o === 'function') ? undefined : o;
    if (o instanceof HTMLCanvasElement || o instanceof Image || o instanceof Set || o instanceof Map) return undefined;
    if (seen.has(o)) return { $ref: seen.get(o) };
    const id = nextId++; seen.set(o, id);
    if (Array.isArray(o)) return o.map(v => clean(v));
    const r = { $id: id };
    for (const k in o) { if (k === 'cache' || k === 'cache2' || k === 'd') continue; const v = clean(o[k]); if (v !== undefined) r[k] = v; }
    return r;
  };
"""
JS = "() => {" + CLEAN + r"""
  diffIdx = 1; const out = {};
  for (let v = 0; v < 2; v++) for (let f = 1; f <= 40; f++) {
    const boss = f % 10 === 0;
    let wi = ORDER[(f * 7 + v * 5) % ORDER.length], act = boss ? 2 : ((f + v) % 2);
    if (act === 0 && wi === 0) act = 1; if (boss && wi === 2) wi = 0;
    TOWER_ON = true; TOWER_SEED = 4242 + v * 100003 + f * 7919; TOWER_N = boss ? 2 : Math.min(10, 4 + Math.floor(f / 3)); TOWER_TRIAL = !boss && f % 5 === 0;
    try { startStage(wi, act, false); } finally { TOWER_ON = false; }
    out['torre_v' + v + '_' + f] = clean(level);
  }
  for (const w of ORDER) {
    TOWER_ON = true; TOWER_SEED = 90001 + w * 977; TOWER_N = 5; TOWER_TRIAL = false;
    try { startStage(w, 1, false); } finally { TOWER_ON = false; }
    out['grieta_' + w] = clean(level);
  }
  state = 'title'; return out;
}"""
with sync_playwright() as pw:
    b = pw.chromium.launch(args=['--headless=new'])
    pg = b.new_page(viewport={'width': 960, 'height': 540})
    pg.goto('file://' + os.path.join(ROOT, 'www', 'index.html'))
    pg.wait_for_function("typeof state !== 'undefined' && state !== 'loading'", timeout=120000)
    res = pg.evaluate(JS)
    for k, v in res.items():
        json.dump(v, open(os.path.join(OUT, k + '.json'), 'w'), ensure_ascii=False, separators=(',', ':'))
    print(len(res), 'fases extra')
    b.close()
