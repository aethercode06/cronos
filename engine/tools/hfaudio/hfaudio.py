"""Efectos y música gratis con Stable Audio Open en Spaces de Hugging Face (ZeroGPU), desde GitHub Actions.
Uso: python hfaudio.py pedidos.json <salida>
pedidos.json: [{"nombre": "...", "prompt": "...", "seg": 8, "pasos": 100}]
Licencia de lo generado: Stability AI Community License (uso comercial gratis por debajo de 1 M$ al año)."""
import os, sys, json, shutil, time, inspect
from gradio_client import Client as _Client

PED, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)
TOKEN = os.environ.get("HF_TOKEN") or None
LOG = []

def log(*a):
    s = " ".join(str(x) for x in a); print(s, flush=True); LOG.append(s)

def Client(space):
    ps = inspect.signature(_Client.__init__).parameters
    kw = {}
    if TOKEN:
        kw["token" if "token" in ps else "hf_token"] = TOKEN
    return _Client(space, **kw)

def first_file(res):
    if isinstance(res, str) and os.path.exists(res):
        return res
    if isinstance(res, dict):
        for v in res.values():
            f = first_file(v)
            if f: return f
    if isinstance(res, (list, tuple)):
        for v in res:
            f = first_file(v)
            if f: return f
    return None

SPACES = ["artificialguybr/Stable-Audio-Open-Zero", "innoai/Stable-Audio-Open-Zero", "1inkusFace/Stable-Audio-Open-Zero",
          "MakiAi/Stable-Audio-Open-Zero", "Serhii1024/Stable-Audio-Open-Zero"]

clients, apis, malos = {}, {}, set()
for p in json.load(open(PED)):
    if os.path.exists(os.path.join(OUT, p["nombre"] + ".wav")):
        continue
    hecho = False
    for space in SPACES:
        if space in malos:
            continue
        try:
            if space not in clients:
                clients[space] = Client(space)
                try:
                    apis[space] = clients[space].view_api(return_format="dict", print_info=False)
                    log("API", space, json.dumps(apis[space])[:600])
                except Exception as e:
                    log("sin api", space, e)
            c = clients[space]
            t = time.time()
            intentos = [
                lambda: c.predict(p["prompt"], p.get("seg", 8), p.get("pasos", 100), p.get("cfg", 7), api_name="/predict"),
                lambda: c.predict(p["prompt"], p.get("seg", 8), p.get("pasos", 100), p.get("cfg", 7)),
                lambda: c.predict(p["prompt"], p.get("seg", 8), api_name="/predict"),
            ]
            res = None
            for k, f in enumerate(intentos):
                try:
                    res = f()
                    break
                except Exception as e:
                    log("forma", k, space, type(e).__name__, str(e)[:200])
                    if "quota" in str(e).lower() or "exceeded" in str(e).lower():
                        raise
            fa = first_file(res)
            if fa:
                dst = os.path.join(OUT, p["nombre"] + os.path.splitext(fa)[1])
                shutil.copy(fa, dst)
                log("OK", p["nombre"], space, f"{time.time()-t:.0f}s", os.path.getsize(dst))
                hecho = True
                break
            log("sin archivo", space, str(res)[:200])
        except Exception as e:
            log("ERROR", p["nombre"], space, type(e).__name__, str(e)[:300])
            if "quota" in str(e).lower() or "exceeded" in str(e).lower() or "not found" in str(e).lower() or "paused" in str(e).lower():
                malos.add(space)
            time.sleep(5)
    if not hecho:
        log("FALLO", p["nombre"])
open(os.path.join(OUT, "registro.txt"), "w").write("\n".join(LOG))
