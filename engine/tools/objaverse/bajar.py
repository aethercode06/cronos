"""Descarga de Objaverse los modelos de pedidos.json y los copia como <clave>.glb.
Uso: python bajar.py pedidos.json <salida>"""
import json, sys, os, shutil, objaverse
ped, out = json.load(open(sys.argv[1])), sys.argv[2]
os.makedirs(out, exist_ok=True)
objs = objaverse.load_objects(uids=[p["uid"] for p in ped], download_processes=4)
for p in ped:
    f = objs.get(p["uid"])
    if f and os.path.exists(f):
        shutil.copy(f, os.path.join(out, p["clave"] + ".glb")); print("OK", p["clave"], os.path.getsize(f))
    else:
        print("FALLO", p["clave"])
json.dump(ped, open(os.path.join(out, "creditos.json"), "w"), indent=1, ensure_ascii=False)
