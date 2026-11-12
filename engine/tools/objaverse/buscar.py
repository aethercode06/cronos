"""Busca en Objaverse (Hugging Face) modelos con licencia comercial (CC-BY / CC0) por palabras clave
y hace hojas de miniaturas. Uso: python buscar.py consultas.json <salida>"""
import json, sys, os, io, urllib.request, gzip
import objaverse
from PIL import Image, ImageDraw
Q, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)
ann = objaverse.load_annotations()
print("ANOTACIONES", len(ann), flush=True)
OK_LIC = {"by", "cc0"}
def lic(a):
    l = (a.get("license") or "").lower()
    return "cc0" if "cc0" in l else ("by" if l in ("by",) or l == "by" or l == "cc-by" else l)
cons = json.load(open(Q))
res = {}
for cat, cfg in cons.items():
    kws = [k.lower() for k in cfg["k"]]
    excl = [k.lower() for k in cfg.get("no", [])] + ["low poly", "lowpoly", "cartoon", "stylized", "toon", "minecraft", "voxel", "anime"]
    hits = []
    for uid, a in ann.items():
        L = (a.get("license") or "").lower()
        if L not in ("by", "cc0"):
            continue
        txt = (a.get("name", "") + " " + " ".join(t["name"] for t in a.get("tags", []))).lower()
        if not any(k in txt for k in kws) or any(k in txt for k in excl):
            continue
        fc = a.get("faceCount") or 0
        if fc <= 0 or fc > cfg.get("max_caras", 150000):
            continue
        hits.append((a.get("likeCount", 0) + a.get("viewCount", 0) / 200.0, uid, a.get("name", ""), fc, L))
    hits.sort(reverse=True)
    sel = hits[: cfg.get("n", 24)]
    res[cat] = []
    for sc, uid, nm, fc, L in sel:
        a = ann[uid]
        th = sorted(a.get("thumbnails", {}).get("images", []), key=lambda i: abs(i.get("width", 0) - 256))
        res[cat].append({"uid": uid, "nombre": nm, "caras": fc, "licencia": L, "autor": a.get("user", {}).get("username", ""), "url": a.get("viewerUrl", ""), "mini": th[0]["url"] if th else ""})
    print(cat, len(hits), "->", len(sel), flush=True)
    # hoja de miniaturas
    S, W = 180, 6
    sheet = Image.new("RGB", (W * S, ((len(sel) + W - 1) // W) * (S + 24)), "white"); d = ImageDraw.Draw(sheet)
    for i, o in enumerate(res[cat]):
        x, y = (i % W) * S, (i // W) * (S + 24)
        try:
            im = Image.open(io.BytesIO(urllib.request.urlopen(o["mini"], timeout=30).read())).convert("RGB").resize((S, S))
            sheet.paste(im, (x, y))
        except Exception:
            pass
        d.text((x + 2, y + S + 1), f"{i} {o['nombre'][:24]}", fill="black"); d.text((x + 2, y + S + 11), f"{o['caras']//1000}k {o['licencia']}", fill="gray")
    sheet.save(os.path.join(OUT, f"hoja_{cat}.jpg"), quality=80)
json.dump(res, open(os.path.join(OUT, "resultados.json"), "w"), indent=1, ensure_ascii=False)
