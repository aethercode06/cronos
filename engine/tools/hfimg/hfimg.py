"""Imágenes gratis con Spaces de Hugging Face (FLUX) desde GitHub Actions.
Uso: python hfimg.py pedidos.json <salida>
pedidos.json: [{"nombre": "...", "prompt": "...", "w": 768, "h": 1344, "seed": 1}]"""
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
        for k in ("path", "url", "image"):
            if k in res and isinstance(res[k], str) and os.path.exists(res[k]):
                return res[k]
        for v in res.values():
            f = first_file(v)
            if f: return f
    if isinstance(res, (list, tuple)):
        for v in res:
            f = first_file(v)
            if f: return f
    return None

SPACES = [
    ("black-forest-labs/FLUX.1-schnell", lambda c, p: c.predict(prompt=p["prompt"], seed=p.get("seed", 1), randomize_seed=False, width=p.get("w", 768), height=p.get("h", 1344), num_inference_steps=4, api_name="/infer")),
    ("black-forest-labs/FLUX.1-dev", lambda c, p: c.predict(prompt=p["prompt"], seed=p.get("seed", 1), randomize_seed=False, width=p.get("w", 768), height=p.get("h", 1344), guidance_scale=3.5, num_inference_steps=28, api_name="/infer")),
    ("stabilityai/stable-diffusion-3.5-large-turbo", lambda c, p: c.predict(prompt=p["prompt"], negative_prompt=p.get("negativo", ""), seed=p.get("seed", 1), randomize_seed=False, width=p.get("w", 768), height=p.get("h", 1344), guidance_scale=0.0, num_inference_steps=4, api_name="/infer")),
]

clients = {}
for p in json.load(open(PED)):
    done = False
    for space, fn in SPACES:
        if p.get("space") and p["space"] != space:
            continue
        for intento in range(2):
            try:
                if space not in clients:
                    clients[space] = Client(space)
                t = time.time()
                res = fn(clients[space], p)
                f = first_file(res)
                if f:
                    ext = os.path.splitext(f)[1] or ".webp"
                    dst = os.path.join(OUT, p["nombre"] + ext)
                    shutil.copy(f, dst)
                    log("OK", p["nombre"], space, f"{time.time()-t:.0f}s", os.path.getsize(dst))
                    done = True
                    break
                log("sin archivo", space, str(res)[:200])
            except Exception as e:
                log("ERROR", p["nombre"], space, intento, type(e).__name__, str(e)[:300])
                time.sleep(10)
        if done:
            break
open(os.path.join(OUT, "registro.txt"), "w").write("\n".join(LOG))
