"""Genera imágenes con Pollinations (gratis) desde GitHub Actions.
Lee pedidos.json: [{"nombre": "...", "prompt": "...", "w": 1024, "h": 1024, "seed": 1, "modelo": "flux"}]
Guarda cada imagen en <salida>/<nombre>.<ext> y un registro."""
import os, sys, json, time, urllib.parse, urllib.request

PED, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)
KEY = os.environ.get("POLLINATIONS_KEY") or ""
LOG = []


def log(*a):
    s = " ".join(str(x) for x in a); print(s, flush=True); LOG.append(s)


def get(url, headers=None, timeout=180):
    req = urllib.request.Request(url, headers={"User-Agent": "AetherCode/1.0", **(headers or {})})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.status, r.headers.get("Content-Type", ""), r.read()


# modelos disponibles (para el registro)
for u in ("https://image.pollinations.ai/models", "https://gen.pollinations.ai/image/models"):
    try:
        st, ct, b = get(u, timeout=30)
        log("modelos", u, st, b[:600].decode("utf-8", "ignore"))
    except Exception as e:
        log("modelos", u, "ERROR", e)

for p in json.load(open(PED)):
    q = {"width": p.get("w", 1024), "height": p.get("h", 1024), "seed": p.get("seed", 1),
         "model": p.get("modelo", "flux"), "nologo": "true", "private": "true", "enhance": "false"}
    if p.get("negativo"):
        q["negative_prompt"] = p["negativo"]
    prompt = urllib.parse.quote(p["prompt"])
    urls = []
    if KEY:
        urls.append((f"https://gen.pollinations.ai/image/{prompt}?{urllib.parse.urlencode(q)}",
                     {"Authorization": f"Bearer {KEY}"}))
    urls.append((f"https://image.pollinations.ai/prompt/{prompt}?{urllib.parse.urlencode(q)}", {}))
    ok = False
    for url, hd in urls:
        for intento in range(3):
            try:
                t = time.time()
                st, ct, b = get(url, hd)
                if st == 200 and ct.startswith("image"):
                    ext = "jpg" if "jpeg" in ct else ct.split("/")[-1]
                    path = os.path.join(OUT, f"{p['nombre']}.{ext}")
                    open(path, "wb").write(b)
                    log("OK", p["nombre"], len(b), f"{time.time() - t:.0f}s", url.split("?")[0][:60])
                    ok = True
                    break
                log("respuesta", st, ct, b[:200])
            except Exception as e:
                log("ERROR", p["nombre"], intento, type(e).__name__, str(e)[:300])
                time.sleep(8 * (intento + 1))
        if ok:
            break
    time.sleep(3)
open(os.path.join(OUT, "registro.txt"), "w").write("\n".join(LOG))
