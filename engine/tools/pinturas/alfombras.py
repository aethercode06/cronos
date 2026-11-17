"""Fotos de alfombras antiguas reales (persas, turcas, caucásicas…) de dominio público (CC0): Cleveland Museum of
Art Open Access y Art Institute of Chicago. Guarda alfombras/NN.jpg (máx. 1024 px), alfombras/creditos.json y una
hoja de miniaturas para elegir."""
import json, os, time, urllib.request, urllib.parse
from io import BytesIO
from PIL import Image

def get(url):
    for i in range(4):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "AetherCode-Zarek/1.0 (juego; contacto por GitHub)", "AIC-User-Agent": "AetherCode-Zarek"})
            return urllib.request.urlopen(req, timeout=60).read()
        except Exception as e:
            print("reintento", url[:100], e); time.sleep(3 + i * 3)
    return None

os.makedirs("alfombras", exist_ok=True)
creditos, vistos, n = [], set(), 0
def guardar(b, meta):
    global n
    try:
        im = Image.open(BytesIO(b)).convert("RGB")
    except Exception:
        return False
    w, h = im.size
    if w < 300 or h < 300 or max(w / h, h / w) > 2.6:
        return False
    im.thumbnail((1024, 1024))
    meta.update({"archivo": f"{n:02d}.jpg", "ancho": im.size[0], "alto": im.size[1]})
    im.save(f"alfombras/{n:02d}.jpg", quality=88)
    creditos.append(meta); n += 1
    print(n, meta["titulo"])
    return True

for q in ["carpet", "rug", "prayer rug", "medallion carpet", "kilim"]:
    url = "https://openaccess-api.clevelandart.org/api/artworks/?" + urllib.parse.urlencode({"q": q, "type": "Textile", "has_image": 1, "cc0": 1, "limit": 60})
    d = get(url)
    for o in (json.loads(d).get("data", []) if d else []):
        t = (o.get("title") or "").lower()
        if not any(k in t for k in ("carpet", "rug", "kilim", "kelim")) or ("cma", o["id"]) in vistos or "fragment" in t:
            continue
        im = ((o.get("images") or {}).get("web") or {}).get("url")
        if not im:
            continue
        b = get(im)
        meta = {"titulo": o.get("title"), "autor": ", ".join(c.get("description", "") for c in (o.get("creators") or [])) or o.get("culture", [""])[0] if o.get("culture") else "",
                "fecha": o.get("creation_date"), "fuente": o.get("url"), "licencia": "CC0 (Cleveland Museum of Art, Open Access)"}
        if b and guardar(b, meta):
            vistos.add(("cma", o["id"]))
        time.sleep(0.2)
    url = "https://api.artic.edu/api/v1/artworks/search?" + urllib.parse.urlencode({"q": q, "limit": 60,
        "fields": "id,title,artist_display,date_display,image_id,is_public_domain,artwork_type_title"})
    d = get(url)
    for o in (json.loads(d).get("data", []) if d else []):
        t = (o.get("title") or "").lower()
        if not o.get("is_public_domain") or not o.get("image_id") or ("aic", o["id"]) in vistos or "fragment" in t:
            continue
        if not any(k in t for k in ("carpet", "rug", "kilim", "kelim")):
            continue
        b = get(f"https://www.artic.edu/iiif/2/{o['image_id']}/full/843,/0/default.jpg")
        meta = {"titulo": o.get("title"), "autor": o.get("artist_display"), "fecha": o.get("date_display"),
                "fuente": f"https://www.artic.edu/artworks/{o['id']}", "licencia": "CC0 (Art Institute of Chicago, dominio público)"}
        if b and guardar(b, meta):
            vistos.add(("aic", o["id"]))
        time.sleep(0.3)
json.dump(creditos, open("alfombras/creditos.json", "w"), ensure_ascii=False, indent=1)
# hoja de miniaturas numeradas
from PIL import ImageDraw
W = 8; filas = (n + W - 1) // W
hoja = Image.new("RGB", (W * 200, max(1, filas) * 215), "white"); dr = ImageDraw.Draw(hoja)
for i in range(n):
    im = Image.open(f"alfombras/{i:02d}.jpg"); im.thumbnail((200, 200))
    hoja.paste(im, ((i % W) * 200, (i // W) * 215)); dr.text(((i % W) * 200 + 3, (i // W) * 215 + 201), str(i), fill="black")
hoja.save("hoja_alfombras.jpg", quality=85)
print("TOTAL", n)
