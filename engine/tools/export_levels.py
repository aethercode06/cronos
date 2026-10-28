"""Exporta las 54 fases de Chronos (4 dificultades) generadas por el propio juego web
a engine/chronos/niveles/*.json, más los datos de mundos y enemigos.
Así Aether usa exactamente las mismas fases que la versión web."""
import json, os, sys
from playwright.sync_api import sync_playwright

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, 'engine', 'chronos', 'niveles')
os.makedirs(OUT, exist_ok=True)
JS = r"""
(diff) => {
  const seen = new WeakMap(); let nextId = 1;
  const clean = (o, depth) => {
    if (o === null || typeof o !== 'object') return (typeof o === 'function') ? undefined : o;
    if (o instanceof HTMLCanvasElement || o instanceof Image || (typeof OffscreenCanvas !== 'undefined' && o instanceof OffscreenCanvas)) return undefined;
    if (o instanceof Set || o instanceof Map) return undefined;
    if (seen.has(o)) return { $ref: seen.get(o) };
    const id = nextId++; seen.set(o, id);
    if (Array.isArray(o)) return o.map(v => clean(v, depth + 1));
    const r = { $id: id };
    for (const k in o) { if (k === 'cache' || k === 'cache2' || k === 'd') continue; const v = clean(o[k], depth + 1); if (v !== undefined) r[k] = v; }
    return r;
  };
  diffIdx = diff; const out = {};
  for (const wi of ORDER) for (let a = 0; a < 3; a++) {
    try { startStage(wi, a, true); } catch (e) { out[wi + '_' + a] = { error: String(e) }; continue; }
    out[wi + '_' + a] = clean(level, 0);
  }
  state = 'title';
  return out;
}
"""
INFO = r"""
() => {
  const W = WORLDS.map(w => { const r = {}; for (const k in w) if (typeof w[k] !== 'function') r[k] = w[k]; return r; });
  return { worlds: W, enemy: ENEMY, diffs: DIFFS, order: ORDER, hints: HINTS, wbase: WBASE };
}
"""
with sync_playwright() as pw:
    b = pw.chromium.launch(args=['--headless=new', '--autoplay-policy=no-user-gesture-required'])
    pg = b.new_page(viewport={'width': 960, 'height': 540})
    errs = []
    pg.on('pageerror', lambda e: errs.append(str(e)))
    pg.goto('file://' + os.path.join(ROOT, 'www', 'index.html'))
    pg.wait_for_function("typeof state !== 'undefined' && state !== 'loading'", timeout=120000)
    info = pg.evaluate(INFO)
    json.dump(info, open(os.path.join(OUT, 'datos.json'), 'w'), ensure_ascii=False)
    for d in range(len(info['diffs'])):
        res = pg.evaluate(JS, d)
        for k, v in res.items():
            json.dump(v, open(os.path.join(OUT, 'd%d_%s.json' % (d, k)), 'w'), ensure_ascii=False, separators=(',', ':'))
        print('dificultad', d, 'fases', len(res), 'errores', [k for k, v in res.items() if 'error' in v])
    print('errores de página', errs[:5])
    b.close()
