"""Rellena los huecos negros del atlas de TRELLIS (fuera de las islas UV) con el color de la isla más cercana,
para que no salgan rayas negras en las costuras ni al reducir el modelo. Uso (python de Blender):
python dilatar.py <modelo.glb> <salida_dir>"""
import bpy, sys, os, numpy as np
from PIL import Image, ImageDraw
glb, out = sys.argv[-2], sys.argv[-1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb)
ob = [o for o in bpy.data.objects if o.type == 'MESH'][0]
me = ob.data; uv = me.uv_layers[0].data
mat = ob.material_slots[0].material
imgs = [n.image for n in mat.node_tree.nodes if n.type == 'TEX_IMAGE' and n.image]
W, H = imgs[0].size
mask = Image.new("L", (W, H), 0); d = ImageDraw.Draw(mask)
for p in me.polygons:
    pts = [(uv[li].uv[0] * W, (1 - uv[li].uv[1]) * H) for li in p.loop_indices]
    d.polygon(pts, fill=255, outline=255)
m = np.array(mask) > 0
print("cobertura", m.mean())
from scipy import ndimage
idx = ndimage.distance_transform_edt(~m, return_distances=False, return_indices=True)
for im in imgs:
    a = np.array(im.pixels[:], dtype=np.float32).reshape(H, W, im.channels)[::-1]
    a = a[idx[0], idx[1]]
    nm = im.name.replace(".", "_")
    Image.fromarray((np.clip(a[..., :3], 0, 1) * 255).astype(np.uint8)).save(os.path.join(out, nm + ".png"))
    print("DILATADO", nm, im.colorspace_settings.name)
