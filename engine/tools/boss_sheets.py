"""Empaqueta las animaciones de un jefe renderizadas en Blender como hojas para el motor.
Uso: python3 boss_sheets.py <carpeta_acciones> <prefijo> <ancho_cuerpo_juego> <salida_assets>
- Recorta todos los fotogramas al mismo marco (unión de siluetas), para que el ancla no salte.
- Escala para que el cuerpo en reposo mida <ancho_cuerpo_juego> unidades con densidad 3.
- Escribe <prefijo>_<acción>.webp y añade las entradas a meta.json."""
import os, sys, json
import numpy as np
from PIL import Image

SRC, PREF, BODYW, DST = sys.argv[1], sys.argv[2], float(sys.argv[3]), sys.argv[4]
D = 3.0
acts = json.load(open(os.path.join(SRC, "acciones.json")))
frames = {a: [Image.open(os.path.join(SRC, a, f)).convert("RGBA") for f in sorted(os.listdir(os.path.join(SRC, a)))]
          for a in acts}
# marco común
x0 = y0 = 10 ** 9; x1 = y1 = -1
for fr in frames.values():
    for im in fr:
        a = np.asarray(im)[..., 3]
        ys, xs = np.nonzero(a > 8)
        if len(xs):
            x0, y0 = min(x0, xs.min()), min(y0, ys.min()); x1, y1 = max(x1, xs.max()), max(y1, ys.max())
pad = 6
x0, y0, x1, y1 = max(0, x0 - pad), max(0, y0 - pad), x1 + pad, y1 + pad
# medida del cuerpo en reposo (primer fotograma de "quieto")
rest = np.asarray(frames["quieto"][0])[..., 3]
ys, xs = np.nonzero(rest > 8)
body_w = xs.max() - xs.min()
foot_y = ys.max()
cx = (xs.min() + xs.max()) / 2
s = BODYW * D / body_w
W, H = int(round((x1 - x0) * s)), int(round((y1 - y0) * s))
meta_path = os.path.join(DST, "meta.json")
meta = json.load(open(meta_path))
for a, fr in frames.items():
    sheet = Image.new("RGBA", (W * len(fr), H))
    for i, im in enumerate(fr):
        sheet.paste(im.crop((x0, y0, x1, y1)).resize((W, H), Image.LANCZOS), (i * W, 0))
    name = f"{PREF}_{a}"
    sheet.save(os.path.join(DST, name + ".webp"), quality=90, method=6)
    meta[name] = {"fw": round(W / D, 2), "fh": round(H / D, 2), "n": len(fr), "d": D,
                  "ax": round((cx - x0) * s / D, 2), "ay": round((foot_y - y0) * s / D, 2),
                  "file": name + ".webp", "loop": bool(acts[a]["loop"])}
    print(name, meta[name])
json.dump(meta, open(meta_path, "w"), separators=(",", ":"))
