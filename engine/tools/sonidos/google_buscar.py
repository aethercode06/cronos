"""Recorre la biblioteca de sonidos de Google (CC BY 4.0) y baja los que coinciden con palabras clave.
Uso: python google_buscar.py palabras.txt <salida>   (palabras.txt: una palabra clave por línea, 'clave|max')"""
import re, sys, os, json, urllib.request
BASE = "https://developers.google.com/assistant/tools/sound-library"
UA = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) Chrome/120"}
def get(u):
    try:
        return urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=60).read().decode("utf-8", "ignore")
    except Exception as e:
        print("no", u, e); return ""
out = sys.argv[2]; os.makedirs(out, exist_ok=True)
idx = get(BASE)
cats = sorted(set(re.findall(r'href="(/assistant/tools/sound-library/[a-z0-9\-_/]+)"', idx)))
print("categorías", len(cats))
todos = {}
for c in cats:
    h = get("https://developers.google.com" + c)
    for u in re.findall(r'https://actions\.google\.com/sounds/v1/[a-z0-9_\-/]+\.ogg', h):
        todos[u] = c.split("/")[-1]
for u in re.findall(r'https://actions\.google\.com/sounds/v1/[a-z0-9_\-/]+\.ogg', idx):
    todos.setdefault(u, "index")
print("sonidos", len(todos))
json.dump(todos, open(os.path.join(out, "catalogo.json"), "w"), indent=1)
pal = [l.strip().split("|") for l in open(sys.argv[1]) if l.strip() and not l.startswith("#")]
bajados = set()
for p in pal:
    clave, mx = p[0], int(p[1]) if len(p) > 1 else 6
    n = 0
    for u in sorted(todos):
        nombre = u.split("/")[-1]
        if clave in nombre and u not in bajados and n < mx:
            d = os.path.join(out, clave.replace("/", "_"))
            os.makedirs(d, exist_ok=True)
            try:
                urllib.request.urlretrieve(u, os.path.join(d, nombre))
                bajados.add(u); n += 1
            except Exception as e:
                print("fallo", u, e)
    print(clave, n)
