"""Busca en Freesound (filtro CC0) y baja las vistas previas HQ de los mejores resultados con su ficha.
Uso: python freesound_buscar.py freesound.txt <salida>"""
import re, sys, os, json, html, urllib.request, urllib.parse
UA = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/124 Safari/537.36"}
def get(u, binario=False):
    try:
        r = urllib.request.urlopen(urllib.request.Request(u, headers=UA), timeout=25).read()
        return r if binario else r.decode("utf-8", "ignore")
    except Exception as e:
        print("no", u, e); return b"" if binario else ""
out = sys.argv[2]; os.makedirs(out, exist_ok=True)
from concurrent.futures import ThreadPoolExecutor
fichas = {}
tareas = []
consultas = [l.strip() for l in open(sys.argv[1]) if l.strip() and not l.startswith("#")]
def buscar(linea):
    q, mx = (linea.split("|") + ["8"])[:2]
    url = "https://freesound.org/search/?" + urllib.parse.urlencode({"q": q, "f": 'license:"Creative Commons 0"', "s": "Downloads (most first)"})
    h = get(url)
    ids = []
    for m in re.finditer(r'/people/([^/"]+)/sounds/(\d+)/', h):
        if m.group(2) not in [i[1] for i in ids]:
            ids.append((m.group(1), m.group(2)))
    print(q, "->", len(ids), "resultados", flush=True)
    return [(u, sid, q) for u, sid in ids[: int(mx)]]
with ThreadPoolExecutor(6) as ex:
    for lista in ex.map(buscar, consultas):
        for u, sid, q in lista:
            if sid in fichas:
                fichas[sid]["consultas"].append(q)
            else:
                fichas[sid] = {"id": sid, "user": u, "consultas": [q]}
def ficha(f):
    user, sid = f["user"], f["id"]
    p = get("https://freesound.org/people/%s/sounds/%s/" % (user, sid))
    prev = re.search(r'https://cdn\.freesound\.org/previews/[^"\']+?-hq\.mp3', p)
    tit = re.search(r'<meta property="og:title" content="([^"]*)"', p)
    desc = re.search(r'<meta (?:name|property)="(?:og:)?description" content="([^"]*)"', p)
    lic = re.search(r'creativecommons\.org/(publicdomain/zero|licenses/[a-z\-]+)/[0-9.]+', p)
    tags = re.findall(r'/browse/tags/([^/"]+)/', p)
    f.update({"titulo": html.unescape(tit.group(1)) if tit else "", "desc": html.unescape(desc.group(1))[:400] if desc else "",
         "licencia": lic.group(0) if lic else "?", "tags": sorted(set(tags))[:25], "preview": prev.group(0) if prev else ""})
    if prev and "zero" in f["licencia"]:
        data = get(prev.group(0), True)
        if data:
            open(os.path.join(out, "%s.mp3" % sid), "wb").write(data)
            f["archivo"] = "%s.mp3" % sid
    print("ficha", sid, f["titulo"][:40], flush=True)
with ThreadPoolExecutor(8) as ex:
    list(ex.map(ficha, list(fichas.values())))
json.dump(fichas, open(os.path.join(out, "fichas.json"), "w"), indent=1, ensure_ascii=False)
print("fichas", len(fichas), "con audio", sum(1 for f in fichas.values() if f.get("archivo")))
