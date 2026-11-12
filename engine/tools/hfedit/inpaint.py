"""Rellena (inpainting) una zona de una imagen con FLUX.1 Fill desde GitHub Actions.
Uso: python inpaint.py <carpeta_inpaint> <salida>; por cada X.png necesita X.mask.png (blanco = rehacer) y X.json {prompt, seeds}."""
import os, sys, json, glob, shutil, inspect, time
from gradio_client import Client as _Client, handle_file
D, OUT = sys.argv[1], sys.argv[2]; os.makedirs(OUT, exist_ok=True)
TOKEN = os.environ.get("HF_TOKEN") or None
LOG = []
def log(*a):
    s = " ".join(str(x) for x in a); print(s, flush=True); LOG.append(s)
def Client(sp):
    ps = inspect.signature(_Client.__init__).parameters
    return _Client(sp, **({("token" if "token" in ps else "hf_token"): TOKEN} if TOKEN else {}))
def files(x, o):
    if isinstance(x, str) and os.path.exists(x): o.append(x)
    elif isinstance(x, dict): [files(v, o) for v in x.values()]
    elif isinstance(x, (list, tuple)): [files(v, o) for v in x]
    return o
SPACES = os.environ.get("INPAINT_SPACES", "black-forest-labs/FLUX.1-Fill-dev,vilarin/Flux.1-Fill-dev").split(",")
for img in sorted(glob.glob(os.path.join(D, "*.png"))):
    if img.endswith(".mask.png"): continue
    n = os.path.basename(img)[:-4]; cfg = json.load(open(os.path.join(D, n + ".json")))
    mask = os.path.join(D, n + ".mask.png")
    for sp in SPACES:
        try:
            c = Client(sp)
            info = c.view_api(return_format="dict", print_info=False) or {}
            json.dump(info, open(os.path.join(OUT, sp.replace("/", "_") + "_api.json"), "w"), indent=1, default=str)
            eps = info.get("named_endpoints", {}); log("==", sp, list(eps))
            ep = next((e for e in ("/infer", "/inpaint", "/process", "/predict", "/run") if e in eps), None)
            if not ep: continue
            ok = 0
            for seed in cfg.get("seeds", [1]):
                kw = {}
                for p in eps[ep]["parameters"]:
                    pn = p["parameter_name"]; comp = (p.get("component") or "").lower()
                    if comp == "imageeditor" or "edit" in pn:
                        kw[pn] = {"background": handle_file(img), "layers": [handle_file(mask)], "composite": None}
                    elif "mask" in pn: kw[pn] = handle_file(mask)
                    elif comp == "image": kw[pn] = handle_file(img)
                    elif pn == "prompt": kw[pn] = cfg["prompt"]
                    elif pn == "seed": kw[pn] = seed
                    elif "randomize" in pn: kw[pn] = False
                    elif pn in ("width", "height"): kw[pn] = 1024
                    elif p.get("parameter_has_default"): kw[pn] = p["parameter_default"]
                log(" llamando", ep, {k: (v if not isinstance(v, dict) else "<img>") for k, v in kw.items()})
                t = time.time()
                try:
                    res = c.predict(**kw, api_name=ep)
                except Exception as e:
                    log("  fallo:", str(e)[:300]); continue
                for i, f in enumerate(files(res, [])):
                    dst = os.path.join(OUT, f"{n}_s{seed}_{i}{os.path.splitext(f)[1]}"); shutil.copy(f, dst); log("  guardado", dst, f"{time.time()-t:.0f}s")
                    ok += 1
            if ok: break
        except Exception as e:
            log(" ERROR", sp, type(e).__name__, str(e)[:300])
open(os.path.join(OUT, "registro.txt"), "w").write("\n".join(LOG))
