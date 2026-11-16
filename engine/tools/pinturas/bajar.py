"""Baja pinturas antiguas de dominio público (CC0) para los cuadros de la mansión: Art Institute of Chicago
(api.artic.edu) y, si faltan, Cleveland Museum of Art (Open Access). Guarda pinturas/NN.jpg (máx. 512 px) y
pinturas/creditos.json."""
import json, os, time, urllib.request, urllib.parse
from io import BytesIO
from PIL import Image

BUSQUEDAS = [("portrait", 20), ("portrait of a woman", 8), ("portrait of a man", 6), ("landscape", 12), ("moonlight", 4),
             ("still life", 5), ("ruins", 3), ("storm", 3), ("forest", 4), ("church interior", 2), ("children", 3)]

def get(url):
    for i in range(4):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "AetherCode-Zarek/1.0 (juego; contacto por GitHub)", "AIC-User-Agent": "AetherCode-Zarek"})
            return urllib.request.urlopen(req, timeout=40).read()
        except Exception as e:
            print("reintento", url[:100], e); time.sleep(3 + i * 3)
    return None

def guardar(img_bytes, meta, n):
    try:
        im = Image.open(BytesIO(img_bytes)).convert("RGB")
    except Exception:
        return False
    w, h = im.size
    if w < 200 or h < 200 or max(w / h, h / w) > 2.2:
        return False
    im.thumbnail((512, 512))
    meta.update({"archivo": f"{n:02d}.jpg", "ancho": im.size[0], "alto": im.size[1]})
    im.save(f"pinturas/{n:02d}.jpg", quality=86)
    return True

os.makedirs("pinturas", exist_ok=True)
creditos, vistos, n = [], set(), 0
for q, cuantos in BUSQUEDAS:
    tomados = 0
    url = "https://api.artic.edu/api/v1/artworks/search?" + urllib.parse.urlencode({
        "q": q, "limit": 60, "fields": "id,title,artist_display,date_display,date_start,image_id,is_public_domain,classification_title,artwork_type_title"})
    d = get(url)
    datos = json.loads(d).get("data", []) if d else []
    for o in datos:
        if tomados >= cuantos: break
        if not o.get("is_public_domain") or not o.get("image_id") or o["id"] in vistos: continue
        if (o.get("artwork_type_title") or "") != "Painting": continue
        if not o.get("date_start") or not (1600 <= o["date_start"] <= 1900): continue
        img = get(f"https://www.artic.edu/iiif/2/{o['image_id']}/full/600,/0/default.jpg")
        meta = {"titulo": o.get("title"), "autor": o.get("artist_display"), "fecha": o.get("date_display"), "tipo": q,
                "fuente": f"https://www.artic.edu/artworks/{o['id']}", "licencia": "CC0 (Art Institute of Chicago, dominio público)"}
        if img and guardar(img, meta, n):
            creditos.append(meta); vistos.add(o["id"]); n += 1; tomados += 1
            print(n, q, o.get("title"))
        time.sleep(0.3)
    if tomados < cuantos:
        url = "https://openaccess-api.clevelandart.org/api/artworks/?" + urllib.parse.urlencode({
            "q": q, "type": "Painting", "has_image": 1, "cc0": 1, "limit": 40, "created_before": 1900, "created_after": 1600})
        d = get(url)
        for o in (json.loads(d).get("data", []) if d else []):
            if tomados >= cuantos: break
            im = ((o.get("images") or {}).get("web") or {}).get("url")
            if not im or ("cma", o["id"]) in vistos: continue
            img = get(im)
            meta = {"titulo": o.get("title"), "autor": ", ".join(c.get("description", "") for c in o.get("creators", [])), "fecha": o.get("creation_date"),
                    "tipo": q, "fuente": o.get("url"), "licencia": "CC0 (Cleveland Museum of Art Open Access)"}
            if guardar(img, meta, n) if img else False:
                creditos.append(meta); vistos.add(("cma", o["id"])); n += 1; tomados += 1
                print(n, q, o.get("title"))
            time.sleep(0.3)
json.dump(creditos, open("pinturas/creditos.json", "w"), indent=1, ensure_ascii=False)
print("TOTAL", n)
