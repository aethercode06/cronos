"""Baja pinturas del siglo XIX de dominio público (Open Access del Met Museum, CC0) para los cuadros de la mansión.
Guarda pinturas/NN.jpg (máx. 512 px) y pinturas/creditos.json."""
import json, os, sys, time, urllib.request, urllib.parse
from io import BytesIO
from PIL import Image

API = "https://collectionapi.metmuseum.org/public/collection/v1"
BUSQUEDAS = [("portrait", 22), ("woman portrait", 8), ("landscape", 14), ("night", 4), ("still life", 6), ("ruins", 4), ("storm", 3), ("forest", 4)]

def get(url):
    for i in range(4):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "AetherCode-Zarek/1.0"})
            return urllib.request.urlopen(req, timeout=40).read()
        except Exception as e:
            print("reintento", url, e); time.sleep(3 + i * 3)
    return None

os.makedirs("pinturas", exist_ok=True)
creditos, vistos, n = [], set(), 0
for q, cuantos in BUSQUEDAS:
    url = f"{API}/search?" + urllib.parse.urlencode({"q": q, "hasImages": "true", "medium": "Paintings", "dateBegin": 1780, "dateEnd": 1885})
    d = get(url)
    ids = json.loads(d).get("objectIDs") or [] if d else []
    tomados = 0
    for oid in ids:
        if tomados >= cuantos: break
        if oid in vistos: continue
        o = get(f"{API}/objects/{oid}")
        if not o: continue
        o = json.loads(o)
        if not o.get("isPublicDomain") or not o.get("primaryImageSmall"): continue
        if "Paintings" not in (o.get("classification") or "") and "Painting" not in (o.get("objectName") or ""): continue
        img = get(o["primaryImageSmall"])
        if not img: continue
        try:
            im = Image.open(BytesIO(img)).convert("RGB")
        except Exception:
            continue
        w, h = im.size
        if w < 200 or h < 200 or max(w / h, h / w) > 2.2: continue
        im.thumbnail((512, 512))
        nombre = f"{n:02d}.jpg"
        im.save(f"pinturas/{nombre}", quality=86)
        creditos.append({"archivo": nombre, "titulo": o.get("title"), "autor": o.get("artistDisplayName"), "fecha": o.get("objectDate"),
                         "tipo": q, "ancho": im.size[0], "alto": im.size[1], "fuente": o.get("objectURL"), "licencia": "CC0 (Met Open Access)"})
        vistos.add(oid); n += 1; tomados += 1
        print(n, q, o.get("title"), o.get("artistDisplayName"))
        time.sleep(0.2)
json.dump(creditos, open("pinturas/creditos.json", "w"), indent=1, ensure_ascii=False)
print("TOTAL", n)
