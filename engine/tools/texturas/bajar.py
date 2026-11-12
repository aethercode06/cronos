"""Descarga texturas PBR CC0 de ambientCG (1K, JPG) por categoría y hace una hoja de muestras.
Uso: python bajar.py pedidos.json <salida>"""
import json, sys, os, io, zipfile, urllib.request, urllib.parse
from PIL import Image, ImageDraw
PED, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)
UA = {"User-Agent": "AetherCode-texturas/1.0"}
def get(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60).read()
hoja = []
for cat, cfg in json.load(open(PED)).items():
    ids = cfg.get("ids", [])
    if not ids:
        q = urllib.parse.urlencode({"q": cfg["q"], "type": "Material", "limit": cfg.get("n", 4), "sort": "Popular", "include": "downloadData"})
        try:
            data = json.loads(get("https://ambientcg.com/api/v2/full_json?" + q))
            ids = [a["assetId"] for a in data.get("foundAssets", [])]
        except Exception as e:
            print("FALLO búsqueda", cat, e); continue
    for aid in ids:
        dst = os.path.join(OUT, aid)
        if os.path.isdir(dst): continue
        try:
            z = zipfile.ZipFile(io.BytesIO(get(f"https://ambientcg.com/get?file={aid}_1K-JPG.zip")))
            os.makedirs(dst, exist_ok=True)
            for n in z.namelist():
                low = n.lower()
                for key, nm in (("_color", "color"), ("_normalgl", "normal"), ("_roughness", "rough"), ("_ambientocclusion", "ao")):
                    if key in low and low.endswith(".jpg"):
                        open(os.path.join(dst, nm + ".jpg"), "wb").write(z.read(n))
            print("OK", cat, aid); hoja.append((cat, aid))
        except Exception as e:
            print("FALLO", cat, aid, e)
# hoja de muestras
W = 6; S = 200
img = Image.new("RGB", (W * S, ((len(hoja) + W - 1) // W) * (S + 20)), "white")
d = ImageDraw.Draw(img)
for i, (cat, aid) in enumerate(hoja):
    p = os.path.join(OUT, aid, "color.jpg")
    if not os.path.exists(p): continue
    x, y = (i % W) * S, (i // W) * (S + 20)
    img.paste(Image.open(p).convert("RGB").resize((S, S)), (x, y)); d.text((x + 3, y + S + 3), f"{cat}:{aid}", fill="black")
img.save(os.path.join(OUT, "hoja.jpg"), quality=85)
json.dump(hoja, open(os.path.join(OUT, "lista.json"), "w"), indent=1)
