"""Imagen -> modelo 3D con modelos gratuitos de Hugging Face (se ejecuta en GitHub Actions).
Uso: python hf3d.py <imagen> <carpeta_salida>
Prueba varios Spaces y guarda cada GLB que consiga, más un registro con lo que pasó."""
import os, sys, json, shutil, traceback, time

from gradio_client import Client, handle_file

IMG, OUT = sys.argv[1], sys.argv[2]
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
    res = c.predict(image=handle_file(img if isinstance(img, str) else IMG), multiimages=[], seed=7,
                    ss_guidance_strength=7.5, ss_sampling_steps=12, slat_guidance_strength=3.0,
                    slat_sampling_steps=12, multiimage_algo="stochastic", api_name="/image_to_3d")
    save("trellis_preview", res)
    glb = c.predict(mesh_simplify=0.9, texture_size=1024, api_name="/extract_glb")
    return save("trellis", glb)


def try_hunyuan(space):
    c = Client(space, hf_token=TOKEN)
    info = api(c, "hunyuan")
    names = list((info or {}).get("named_endpoints", {}).keys())
    log("  endpoints:", names)
    for ep in ("/generation_all", "/shape_generation"):
        if ep in names:
            params = info["named_endpoints"][ep]["parameters"]
            kw = {}
            for p in params:
                n = p["parameter_name"]
                if n == "image":
                    kw[n] = handle_file(IMG)
                elif n in ("check_box_rembg",):
                    kw[n] = True
                elif n in ("randomize_seed",):
                    kw[n] = False
                elif p.get("parameter_has_default"):
                    continue
                else:
                    kw[n] = None
            log("  llamando", ep, list(kw))
            res = c.predict(**kw, api_name=ep)
            got = save("hunyuan" + ep.replace("/", "_"), res)
            if got:
                return got
    return []


def try_triposr(space):
    c = Client(space, hf_token=TOKEN)
    api(c, "triposr")
    pre = c.predict(handle_file(IMG), True, 0.85, api_name="/preprocess")
    res = c.predict(handle_file(pre), 256, api_name="/generate")
    return save("triposr", res)


TRIES = [
    ("TRELLIS", try_trellis, ["trellis-community/TRELLIS", "JeffreyXiang/TRELLIS"]),
    ("Hunyuan3D-2", try_hunyuan, ["tencent/Hunyuan3D-2", "tencent/Hunyuan3D-2.1"]),
    ("TripoSR", try_triposr, ["stabilityai/TripoSR"]),
]
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
log("RESUMEN:", json.dumps(ok))
with open(os.path.join(OUT, "registro.txt"), "w") as f:
    f.write("\n".join(LOG))
