"""Lista Spaces de Hugging Face que corren TRELLIS.2 y sus funciones (no gasta cupo de GPU)."""
import json, sys, os
from huggingface_hub import HfApi
from gradio_client import Client
out = sys.argv[1]; os.makedirs(out, exist_ok=True)
api = HfApi(); res = []
for q in ("TRELLIS.2", "trellis2", "TRELLIS-2"):
    for s in api.list_spaces(search=q, sort="likes", limit=25):
        if s.id in [r["id"] for r in res]:
            continue
        r = {"id": s.id, "likes": s.likes}
        try:
            info = Client(s.id).view_api(return_format="dict", print_info=False) or {}
            r["eps"] = {k: [p["parameter_name"] for p in v["parameters"]] for k, v in info.get("named_endpoints", {}).items()}
        except Exception as e:
            r["error"] = str(e)[:150]
        print(json.dumps(r)[:600], flush=True); res.append(r)
json.dump(res, open(os.path.join(out, "spaces.json"), "w"), indent=1)
