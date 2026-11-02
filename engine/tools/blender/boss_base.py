"""Jefe pintado -> muñeco 3D con la pintura original encima (paso 1 de la animación con Blender).

Uso:  python3 boss_base.py <forma.glb> <pintura.jpg> <salida.blend> [diezmado=0.14]

1. Recorta la silueta del cuadro (fondo liso).
2. Busca el ángulo de cámara en que la forma 3D (Hunyuan3D) coincide con la silueta.
3. Proyecta la pintura como textura desde esa cámara (UV «pintura»).
4. Guarda el .blend con la cámara del cuadro (CamCuadro), material y luz; y <salida>.json con el ajuste.
Luego cada jefe tiene su script de esqueleto y animación (p. ej. sapo_anim.py, hechicero_anim.py)."""
import sys, os, math, json
import numpy as np
import bpy
from PIL import Image, ImageFilter
from mathutils import Vector

GLB, PAINT, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
RATIO = float(sys.argv[4]) if len(sys.argv) > 4 else 0.14

# ---------------------------------------------------------------- silueta del cuadro
im = np.asarray(Image.open(PAINT).convert("RGB")).astype(float)
S = im.shape[0]
c = 40
bg = np.median(np.concatenate([im[:c, :c].reshape(-1, 3), im[:c, -c:].reshape(-1, 3),
                               im[-c:, :c].reshape(-1, 3), im[-c:, -c:].reshape(-1, 3)]), 0)
M = np.linalg.norm(im - bg, axis=2) > 28
mi = Image.fromarray((M * 255).astype(np.uint8)).filter(ImageFilter.MedianFilter(9)).filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.MinFilter(5))
M = np.asarray(mi) > 127
ys, xs = np.nonzero(M)
x0, y0, x1, y1 = int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())
T = M[y0:y1 + 1, x0:x1 + 1]
# pintura con transparencia: lo que en el cuadro es fondo no se pinta (silueta exacta del dibujo)
alpha = Image.fromarray((M * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.5))
rgba = Image.open(PAINT).convert("RGB"); rgba.putalpha(alpha)
PAINT_A = os.path.splitext(os.path.abspath(OUT))[0] + "_pintura.png"
rgba.save(PAINT_A)

# ---------------------------------------------------------------- forma 3D
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
bpy.ops.import_scene.gltf(filepath=GLB)
o = [o for o in sc.objects if o.type == "MESH"][0]
o.name = "Jefe"
bpy.context.view_layer.objects.active = o; o.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
if RATIO < 1:
    md = o.modifiers.new("dec", "DECIMATE"); md.ratio = RATIO
    bpy.ops.object.modifier_apply(modifier="dec")
for p in o.data.polygons:
    p.use_smooth = True
V = np.array([tuple(v.co) for v in o.data.vertices])


def basis(a, e):
    a, e = math.radians(a), math.radians(e)
    d = np.array([math.sin(a) * math.cos(e), math.cos(a) * math.cos(e), -math.sin(e)])
    r = np.array([math.cos(a), -math.sin(a), 0.0])
    return d, r, np.cross(r, d)


def iou(a, e, k=4):
    d, r, u = basis(a, e)
    x, y = V @ r, V @ u
    h, w = T.shape
    px = ((x - x.min()) * (w - 1) / (x.max() - x.min())).astype(int)
    py = ((y.max() - y) * (h - 1) / (y.max() - y.min())).astype(int)
    R = np.zeros((h // k + 1, w // k + 1), bool); R[py // k, px // k] = True
    Tk = T[::k, ::k][:R.shape[0], :R.shape[1]]; R = R[:Tk.shape[0], :Tk.shape[1]]
    return (R & Tk).sum() / max(1, (R | Tk).sum())


best = (0, 0, 0)
for a in range(-180, 180, 6):
    for e in range(-15, 46, 5):
        s = iou(a, e, 8)
        if s > best[0]:
            best = (s, a, e)
for a in np.arange(best[1] - 6, best[1] + 6.1, 1.5):
    for e in np.arange(best[2] - 5, best[2] + 5.1, 1.25):
        s = iou(a, e)
        if s > best[0]:
            best = (s, float(a), float(e))
print("ajuste: iou %.3f az %.1f el %.1f" % best)

# ---------------------------------------------------------------- proyección
d, r, u = basis(best[1], best[2])
x, y = V @ r, V @ u
sx = (x1 - x0) / (x.max() - x.min()); sy = (y1 - y0) / (y.max() - y.min())
uvl = o.data.uv_layers.new(name="pintura")
for l in o.data.loops:
    i = l.vertex_index
    uvl.data[l.index].uv = ((x0 + (x[i] - x.min()) * sx) / S, 1 - (y0 + (y.max() - y[i]) * sy) / S)
o.data.uv_layers.active = uvl

# cámara ortográfica equivalente al cuadro
d, r, u = Vector(d), Vector(r), Vector(u)
cx = (x.max() + x.min()) / 2; cy = (y.max() + y.min()) / 2
cd = bpy.data.cameras.new("CamCuadro"); cd.type = "ORTHO"
cd.ortho_scale = (x.max() - x.min()) * S / (x1 - x0)
cam = bpy.data.objects.new("CamCuadro", cd); sc.collection.objects.link(cam)
du = (S / 2 - (x0 + x1) / 2) / sx; dv = -(S / 2 - (y0 + y1) / 2) / sy
cam.location = r * cx + u * cy + r * du + u * dv - d * 10
cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
sc.camera = cam

# material: la pintura casi sin iluminar (conserva el arte) + algo de sombreado para el volumen
m = bpy.data.materials.new("Pintura")
m.use_nodes = True
nt = m.node_tree; N = nt.nodes; L = nt.links
p = next(n for n in N if n.type == "BSDF_PRINCIPLED")
out = next(n for n in N if n.type == "OUTPUT_MATERIAL")
t = N.new("ShaderNodeTexImage"); t.image = bpy.data.images.load(PAINT_A); t.extension = "CLIP"
em = N.new("ShaderNodeEmission")
L.new(t.outputs["Color"], em.inputs["Color"]); L.new(t.outputs["Color"], p.inputs["Base Color"])
p.inputs["Roughness"].default_value = 0.6
mix = N.new("ShaderNodeMixShader"); mix.name = "luz"; mix.inputs[0].default_value = 0.22
L.new(em.outputs[0], mix.inputs[1]); L.new(p.outputs[0], mix.inputs[2])
tr = N.new("ShaderNodeBsdfTransparent")
mx2 = N.new("ShaderNodeMixShader"); mx2.name = "alfa"
L.new(t.outputs["Alpha"], mx2.inputs[0]); L.new(tr.outputs[0], mx2.inputs[1]); L.new(mix.outputs[0], mx2.inputs[2])
L.new(mx2.outputs[0], out.inputs["Surface"])
o.data.materials.clear(); o.data.materials.append(m)

w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True
next(n for n in w.node_tree.nodes if n.type == "BACKGROUND").inputs["Strength"].default_value = 1.0
sun = bpy.data.lights.new("Sol", "SUN"); sun.energy = 2.5
so = bpy.data.objects.new("Sol", sun); sc.collection.objects.link(so)
so.rotation_euler = (math.radians(40), 0, math.radians(-30))
sc.render.engine = "CYCLES"; sc.cycles.samples = 16
sc.render.film_transparent = True
sc.view_settings.view_transform = "Standard"
sc.render.resolution_x = sc.render.resolution_y = 768
json.dump({"iou": best[0], "az": best[1], "el": best[2], "bbox": [x0, y0, x1, y1], "size": S,
           "r": list(r), "u": list(u), "d": list(d)}, open(os.path.splitext(OUT)[0] + ".json", "w"), indent=1)
bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(OUT))
if os.environ.get("PRUEBA"):
    sc.render.filepath = os.path.splitext(os.path.abspath(OUT))[0] + "_prueba.png"
    bpy.ops.render.render(write_still=True)
