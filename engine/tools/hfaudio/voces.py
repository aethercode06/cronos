"""Voces gratis con Kokoro-82M (Apache 2.0), en el propio servidor de GitHub (sin GPU).
Uso: python voces.py voces.json <salida>
voces.json: [{"nombre": "k1_julian", "voz": "em_alex", "texto": "...", "vel": 1.0}]
Voces en español: ef_dora (mujer), em_alex y em_santa (hombre)."""
import os, sys, json
import numpy as np, soundfile as sf
from kokoro import KPipeline

PED, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)
pipe = KPipeline(lang_code="e")
log = []
for p in json.load(open(PED)):
    try:
        trozos = []
        for _, _, audio in pipe(p["texto"], voice=p["voz"], speed=p.get("vel", 1.0)):
            trozos.append(np.asarray(audio))
            trozos.append(np.zeros(int(24000 * 0.25), dtype=np.float32))
        a = np.concatenate(trozos)
        sf.write(os.path.join(OUT, p["nombre"] + ".wav"), a, 24000)
        log.append("OK %s %.1fs" % (p["nombre"], len(a) / 24000))
        print(log[-1], flush=True)
    except Exception as e:
        log.append("ERROR %s %s" % (p["nombre"], e))
        print(log[-1], flush=True)
open(os.path.join(OUT, "registro.txt"), "w").write("\n".join(log))
