"""Brillo (bloom) y hojas de sprites para los efectos de Blender.
Uso: python3 vfx_post.py <carpeta_fotogramas> <salida_hojas> [vista_previa.png]"""
import os, sys, json
import numpy as np
from PIL import Image, ImageFilter

SRC, DST = sys.argv[1], sys.argv[2]
PREV = sys.argv[3] if len(sys.argv) > 3 else None
os.makedirs(DST, exist_ok=True)
meta = {}
rows = []
for name in sorted(os.listdir(SRC)):
    d = os.path.join(SRC, name)
    if not os.path.isdir(d):
        continue
    frames = []
    for fn in sorted(os.listdir(d)):
        im = Image.open(os.path.join(d, fn)).convert("RGB")
        a = np.asarray(im).astype(np.float32)
        b1 = np.asarray(im.filter(ImageFilter.GaussianBlur(4))).astype(np.float32)
        b2 = np.asarray(im.filter(ImageFilter.GaussianBlur(12))).astype(np.float32)
        out = a + b1 * 0.7 + b2 * 0.6
        out = 255 * (1 - np.exp(-out / 255 * 1.15))
        frames.append(Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)))
    w, h = frames[0].size
    sheet = Image.new("RGB", (w * len(frames), h))
    for i, f in enumerate(frames):
        sheet.paste(f, (i * w, 0))
    sheet.save(os.path.join(DST, f"fx_{name}.png"), optimize=True)
    meta[name] = {"fw": w, "fh": h, "n": len(frames), "file": f"fx_{name}.png", "blend": "add"}
    rows.append((name, frames))
with open(os.path.join(DST, "fx_meta.json"), "w") as f:
    json.dump(meta, f, indent=1)
if PREV:
    cell = 96
    n = max(len(fr) for _, fr in rows)
    pv = Image.new("RGB", (cell * n, cell * len(rows)), (0, 0, 0))
    for r, (_, fr) in enumerate(rows):
        for i, f in enumerate(fr):
            t = f.copy(); t.thumbnail((cell, cell)); pv.paste(t, (i * cell + (cell - t.width) // 2, r * cell + (cell - t.height) // 2))
    pv.save(PREV)
print(json.dumps({k: v["n"] for k, v in meta.items()}))
