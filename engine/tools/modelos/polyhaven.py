"""Poly Haven (CC0): lista modelos con miniaturas o descarga los pedidos en glTF 1K.
Uso: python polyhaven.py lista <salida>   |   python polyhaven.py bajar pedidos.json <salida>"""
import json, sys, os, urllib.request
UA = {"User-Agent": "AetherCode/1.0"}
def get(u): return urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=120).read()
modo = sys.argv[1]
if modo == "lista":
    out = sys.argv[2]; os.makedirs(out + "/mini", exist_ok=True)
    a = json.loads(get("https://api.polyhaven.com/assets?t=models"))
    lista = {k: {"cat": v.get("categories", []), "tags": v.get("tags", []), "name": v.get("name")} for k, v in a.items()}
    json.dump(lista, open(out + "/modelos.json", "w"), indent=1)
    from PIL import Image, ImageDraw
    ks = sorted(lista); S = 160; W = 10
    hoja = Image.new("RGB", (W * S, ((len(ks) + W - 1) // W) * (S + 14)), "white"); d = ImageDraw.Draw(hoja)
    for i, k in enumerate(ks):
        try:
            im = Image.open(__import__("io").BytesIO(get(f"https://cdn.polyhaven.com/asset_img/thumbs/{k}.png?width=160"))).convert("RGB").resize((S, S))
            x, y = (i % W) * S, (i // W) * (S + 14); hoja.paste(im, (x, y)); d.text((x + 2, y + S), k[:26], fill="black")
        except Exception as e:
            print("mini", k, e)
    hoja.save(out + "/hoja.jpg", quality=80); print("LISTA", len(ks))
else:
    ped, out = sys.argv[2], sys.argv[3]
    for k in json.load(open(ped)):
        try:
            f = json.loads(get(f"https://api.polyhaven.com/files/{k}"))
            g = f["gltf"]["1k"]["gltf"]
            dst = os.path.join(out, k); os.makedirs(dst, exist_ok=True)
            open(os.path.join(dst, os.path.basename(g["url"])), "wb").write(get(g["url"]))
            for rel, inc in g.get("include", {}).items():
                p = os.path.join(dst, rel); os.makedirs(os.path.dirname(p), exist_ok=True)
                open(p, "wb").write(get(inc["url"]))
            print("OK", k)
        except Exception as e:
            print("FALLO", k, e)
