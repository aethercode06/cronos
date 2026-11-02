"""Imagen -> modelo 3D con modelos gratuitos de Hugging Face (se ejecuta en GitHub Actions).
Uso: python hf3d.py <imagen> <carpeta_salida>
Prueba varios Spaces y guarda cada GLB que consiga, más un registro con lo que pasó."""
import os, sys, json, shutil, traceback, time

from gradio_client import Client as _Client, handle_file
import inspect


def Client(space, hf_token=None):
    ps = inspect.signature(_Client.__init__).parameters
    kw = {}
    if hf_token:
        kw["token" if "token" in ps else "hf_token"] = hf_token
    return _Client(space, **kw)

IMG, OUT = sys.argv[1], sys.argv[2]
MV = None
if os.path.isdir(IMG):
    MV = {k: os.path.join(IMG, k + ".png") for k in ("front", "back", "right", "left") if os.path.exists(os.path.join(IMG, k + ".png"))}
    IMG = MV["front"]
os.makedirs(OUT, exist_ok=True)
TOKEN = os.environ.get("HF_TOKEN") or None
LOG = []


def log(*a):
    s = " ".join(str(x) for x in a)
    print(s, flush=True); LOG.append(s)


def save(name, res):
    """Busca rutas de archivo .glb/.obj en el resultado y las copia."""
    found = []

    def walk(x):
        if isinstance(x, str) and os.path.exists(x) and x.lower().endswith((".glb", ".obj", ".ply", ".mp4")):
            found.append(x)
        elif isinstance(x, dict):
            for v in x.values():
                walk(v)
        elif isinstance(x, (list, tuple)):
            for v in x:
                walk(v)
    walk(res)
    for i, f in enumerate(found):
        dst = os.path.join(OUT, f"{name}_{i}{os.path.splitext(f)[1]}")
        shutil.copy(f, dst)
        log("  guardado", dst, os.path.getsize(dst))
    return found


def api(c, name):
    try:
        info = c.view_api(return_format="dict", print_info=False)
        with open(os.path.join(OUT, f"{name}_api.json"), "w") as f:
            json.dump(info, f, indent=1, default=str)
        return info
    except Exception as e:
        log("  view_api falló:", e)
        return {}


def try_trellis(space):
    c = Client(space, hf_token=TOKEN)
    api(c, "trellis")
    try:
        c.predict(api_name="/start_session")
    except Exception as e:
        log("  start_session:", str(e)[:200])
    img = c.predict(image=handle_file(IMG), api_name="/preprocess_image")
    log("  preprocesada:", str(img)[:120])
    src = handle_file(img if isinstance(img, str) else IMG)
    res = c.predict(image=src, multiimages=[], seed=7, ss_guidance_strength=7.5, ss_sampling_steps=12,
                    slat_guidance_strength=3.0, slat_sampling_steps=12, multiimage_algo="stochastic",
                    mesh_simplify=0.92, texture_size=1024, api_name="/generate_and_extract_glb")
    return save("trellis", res)


def try_hunyuan(space):
    c = Client(space, hf_token=TOKEN)
    api(c, "hunyuan")
    got = []
    for ep, steps, octree in (("/generation_all", 20, 256), ("/shape_generation", 20, 256), ("/shape_generation", 12, 192)):
        try:
            log("  llamando", ep, steps, octree)
            res = c.predict(image=handle_file(IMG), steps=steps, guidance_scale=5.0, seed=7, octree_resolution=octree,
                            check_box_rembg=True, num_chunks=8000, randomize_seed=False, api_name=ep)
            got = save("hunyuan" + ep.replace("/", "_") + f"_{steps}", res)
            if got:
                return got
        except Exception as e:
            log("   fallo:", str(e)[:300])
    return got


def try_triposr(space):
    c = Client(space, hf_token=TOKEN)
    api(c, "triposr")
    pre = c.predict(handle_file(IMG), True, 0.85, api_name="/preprocess")
    res = c.predict(handle_file(pre), 256, api_name="/generate")
    return save("triposr", res)


def try_mv(space):
    c = Client(space, hf_token=TOKEN)
    info = api(c, "mv_" + space.split("/")[-1])
    eps = (info or {}).get("named_endpoints", {})
    log("  endpoints:", list(eps))
    for ep in ("/shape_generation", "/generation_all"):
        if ep not in eps:
            continue
        kw = {}
        for prm in eps[ep]["parameters"]:
            n = prm["parameter_name"]
            if n == "image":
                kw[n] = handle_file(MV["front"]) if "mv_image_front" not in [q["parameter_name"] for q in eps[ep]["parameters"]] else None
            elif n.startswith("mv_image_"):
                side = n.replace("mv_image_", "")
                kw[n] = handle_file(MV[side]) if side in MV else None
            elif n == "steps":
                kw[n] = 20
            elif n == "octree_resolution":
                kw[n] = 256
            elif n == "check_box_rembg":
                kw[n] = True
            elif n == "randomize_seed":
                kw[n] = False
            elif n == "seed":
                kw[n] = 7
        try:
            log("  llamando", ep, {k: (v if not hasattr(v, "keys") else "img") for k, v in kw.items()})
            res = c.predict(**kw, api_name=ep)
            got = save("mv" + ep.replace("/", "_"), res)
            if got:
                return got
        except Exception as e:
            log("   fallo:", str(e)[:300])
    return []


TRIES = [
    ("TRELLIS", try_trellis, ["trellis-community/TRELLIS", "JeffreyXiang/TRELLIS"]),
    ("Hunyuan3D-2", try_hunyuan, ["tencent/Hunyuan3D-2.1", "tencent/Hunyuan3D-2", "tencent/Hunyuan3D-2mini-Turbo"]),
    ("TripoSR", try_triposr, ["stabilityai/TripoSR", "VAST-AI/TripoSG"]),
]
if MV:
    TRIES = [("Hunyuan3D-2mv", try_mv, ["tencent/Hunyuan3D-2mv"]),
             ("Hunyuan3D-2.1 frente", try_hunyuan, ["tencent/Hunyuan3D-2.1"])]
ok = {}
for label, fn, spaces in TRIES:
    for sp in spaces:
        log(f"== {label} :: {sp}")
        t = time.time()
        try:
            got = fn(sp)
            log(f"  resultado: {len(got)} archivos en {time.time() - t:.0f}s")
            if got:
                ok[label] = sp
                break
        except Exception as e:
            log("  ERROR:", type(e).__name__, str(e)[:600])
            LOG.append(traceback.format_exc()[-1500:])
    if MV and ok:
        break
log("RESUMEN:", json.dumps(ok))
with open(os.path.join(OUT, "registro.txt"), "w") as f:
    f.write("\n".join(LOG))
