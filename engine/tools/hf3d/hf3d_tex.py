"""Imagen -> modelo 3D CON TEXTURA (PBR) usando Spaces gratis de Hugging Face.
Uso: python hf3d_tex.py <imagen> <carpeta_salida>
Lee la API de cada Space y llama a sus funciones en orden (preprocesar -> generar -> extraer GLB),
rellenando parámetros por nombre. Guarda los GLB y un registro de todo."""
import os, sys, json, shutil, traceback, time, inspect
from gradio_client import Client as _Client, handle_file

IMG, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)
TOKEN = os.environ.get("HF_TOKEN") or None
LOG = []
SPACES = [s for s in os.environ.get("HF3D_SPACES", "microsoft/TRELLIS.2,tencent/Hunyuan3D-2,tencent/Hunyuan3D-2.1").split(",") if s]


def log(*a):
    s = " ".join(str(x) for x in a)
    print(s, flush=True); LOG.append(s)


def Client(space):
    ps = inspect.signature(_Client.__init__).parameters
    kw = {}
    if TOKEN:
        kw["token" if "token" in ps else "hf_token"] = TOKEN
    return _Client(space, **kw)


def files_in(x, out):
    if isinstance(x, str) and os.path.exists(x):
        out.append(x)
    elif isinstance(x, dict):
        for v in x.values():
            files_in(v, out)
    elif isinstance(x, (list, tuple)):
        for v in x:
            files_in(v, out)
    return out


def save(tag, res):
    got = []
    for i, f in enumerate(files_in(res, [])):
        ext = os.path.splitext(f)[1].lower()
        if ext in (".glb", ".obj", ".ply", ".mp4", ".png", ".webp", ".zip", ".fbx"):
            dst = os.path.join(OUT, f"{tag}_{i}{ext}")
            shutil.copy(f, dst)
            log("  guardado", dst, os.path.getsize(dst))
            got.append(dst)
    return got


SKIP = ("example", "clear", "end_session", "lambda", "unload", "reset", "update_", "on_change", "toggle", "show", "hide", "upload")
ORDER = ("start_session", "preprocess", "image_to_3d", "generate", "generation_all", "shape", "texture", "paint", "extract_glb", "extract")

OVR = {"seed": 7, "randomize_seed": False, "texture_size": 2048, "check_box_rembg": True, "remove_bg": True,
       "steps": 25, "num_inference_steps": 25, "octree_resolution": 256, "decimation_target": 300000}


def pick_value(p, img_path):
    n = (p.get("parameter_name") or p.get("label") or "").lower()
    t = json.dumps(p.get("python_type", {})).lower() + json.dumps(p.get("type", {})).lower()
    comp = (p.get("component") or "").lower()
    if comp in ("image", "file", "model3d") or "filepath" in t or "imagedata" in t:
        if "mv_image" in n or "multi" in n:
            return None
        return handle_file(img_path)
    if comp == "gallery" or "multiimage" in n:
        return []
    if n in OVR:
        return OVR[n]
    for k, v in OVR.items():
        if k in n:
            return v
    if "resolution" in n and p.get("parameter_has_default"):
        return p.get("parameter_default")
    if p.get("parameter_has_default"):
        return p.get("parameter_default")
    if "bool" in t:
        return True
    if "int" in t or "float" in t or "number" in t:
        return 0
    return ""


def run_space(space):
    c = Client(space)
    info = c.view_api(return_format="dict", print_info=False) or {}
    tag = space.replace("/", "_")
    with open(os.path.join(OUT, f"{tag}_api.json"), "w") as f:
        json.dump(info, f, indent=1, default=str)
    eps = info.get("named_endpoints", {})
    log("  endpoints:", list(eps))
    names = [e for e in eps if not any(s in e.lower() for s in SKIP)]

    def rank(e):
        for i, k in enumerate(ORDER):
            if k in e.lower():
                return i
        return 99
    names = sorted([e for e in names if rank(e) < 99], key=rank)
    log("  orden:", names)
    img = IMG
    got = []
    done_gen = False
    for ep in names:
        low = ep.lower()
        if done_gen and any(k in low for k in ("shape", "image_to_3d", "generate")) and "extract" not in low:
            continue
        kw = {p["parameter_name"]: pick_value(p, img) for p in eps[ep]["parameters"] if p.get("parameter_name")}
        log("  llamando", ep, {k: ("<img>" if isinstance(v, dict) else v) for k, v in kw.items()})
        t = time.time()
        try:
            res = c.predict(**kw, api_name=ep)
        except Exception as e:
            log("   fallo:", str(e)[:400])
            continue
        log(f"   ok en {time.time() - t:.0f}s:", str(res)[:300])
        if "preprocess" in low:
            fs = files_in(res, [])
            if fs:
                img = fs[0]
            continue
        g = save(f"{tag}{ep.replace('/', '_')}", res)
        got += g
        if any(x.endswith(".glb") for x in g):
            done_gen = True
    return got


ok = {}
for sp in SPACES:
    log(f"== {sp}")
    t = time.time()
    try:
        got = run_space(sp)
        log(f"  resultado: {len(got)} archivos en {time.time() - t:.0f}s")
        if any(g.endswith(".glb") for g in got):
            ok[sp] = [os.path.basename(g) for g in got]
    except Exception as e:
        log("  ERROR:", type(e).__name__, str(e)[:600])
        LOG.append(traceback.format_exc()[-1500:])
log("RESUMEN:", json.dumps(ok))
with open(os.path.join(OUT, "registro.txt"), "w") as f:
    f.write("\n".join(LOG))
