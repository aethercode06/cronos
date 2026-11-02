"""Gran Sapo: modelo de Hunyuan3D + pintura original proyectada desde la cámara del cuadro.
Guarda sapo_base.blend con la cámara del cuadro y el material listo."""
import bpy, sys, math, json
import numpy as np
from mathutils import Vector

PAINT = "/home/claude/cronos/store/fondos_higgsfield/hf_guardian_1.jpg"
A = json.load(open("ajuste.json"))
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
bpy.ops.import_scene.gltf(filepath="sapo_forma.glb")
o = [o for o in sc.objects if o.type == "MESH"][0]
o.name = "GranSapo"
# aplicar transformaciones y reducir polígonos
bpy.context.view_layer.objects.active = o; o.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
md = o.modifiers.new("dec", "DECIMATE"); md.ratio = 0.14
bpy.ops.object.modifier_apply(modifier="dec")
for p in o.data.polygons:
    p.use_smooth = True
print("caras", len(o.data.polygons))

# cámara del cuadro
a, e = math.radians(A["az"]), math.radians(A["el"])
d = Vector((math.sin(a) * math.cos(e), math.cos(a) * math.cos(e), -math.sin(e)))
r = Vector((math.cos(a), -math.sin(a), 0.0))
u = r.cross(d)
V = np.array([tuple(v.co) for v in o.data.vertices])
x = V @ np.array(r); y = V @ np.array(u)
x0, y0, x1, y1 = A["bbox"]
sx = (x1 - x0) / (x.max() - x.min()); sy = (y1 - y0) / (y.max() - y.min())
uvl = o.data.uv_layers.new(name="pintura")
for l in o.data.loops:
    i = l.vertex_index
    px = x0 + (x[i] - x.min()) * sx
    py = y0 + (y.max() - y[i]) * sy
    uvl.data[l.index].uv = (px / 2048.0, 1 - py / 2048.0)
o.data.uv_layers.active = uvl

# cámara ortográfica equivalente (para renders que encajen con el cuadro)
ctr = Vector(((x.max() + x.min()) / 2, 0, 0))
cx = (x.max() + x.min()) / 2; cy = (y.max() + y.min()) / 2
center = r * cx + u * cy
cd = bpy.data.cameras.new("CamCuadro"); cd.type = "ORTHO"
cd.ortho_scale = (x.max() - x.min()) * 2048 / (x1 - x0)  # ancho del cuadro en unidades
cam = bpy.data.objects.new("CamCuadro", cd); sc.collection.objects.link(cam)
img_cx = (x0 + x1) / 2; img_cy = (y0 + y1) / 2
# desplazar para que el centro del cuadro (1024,1024) quede en el centro de la cámara
du = (1024 - img_cx) / sx; dv = -(1024 - img_cy) / sy
cam.location = center + r * du + u * dv - d * 10
cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
sc.camera = cam
sc.render.resolution_x = sc.render.resolution_y = 1024

# material: pintura casi sin iluminar (conserva el arte) + algo de sombreado para el volumen
m = bpy.data.materials.new("Sapo pintado")
try:
    m.use_nodes = True
except Exception:
    pass
nt = m.node_tree; N = nt.nodes; L = nt.links
p = next(n for n in N if n.type == "BSDF_PRINCIPLED")
out = next(n for n in N if n.type == "OUTPUT_MATERIAL")
t = N.new("ShaderNodeTexImage"); t.image = bpy.data.images.load(PAINT)
t.extension = "EXTEND"
em = N.new("ShaderNodeEmission"); em.name = "pintura"
L.new(t.outputs["Color"], em.inputs["Color"]); L.new(t.outputs["Color"], p.inputs["Base Color"])
p.inputs["Roughness"].default_value = 0.6
mix = N.new("ShaderNodeMixShader"); mix.name = "luz"; mix.inputs[0].default_value = 0.22
L.new(em.outputs[0], mix.inputs[1]); L.new(p.outputs[0], mix.inputs[2])
L.new(mix.outputs[0], out.inputs["Surface"])
o.data.materials.clear(); o.data.materials.append(m)

w = bpy.data.worlds.new("w"); sc.world = w
try:
    w.use_nodes = True
except Exception:
    pass
next(n for n in w.node_tree.nodes if n.type == "BACKGROUND").inputs["Strength"].default_value = 1.0
sun = bpy.data.lights.new("Sol", "SUN"); sun.energy = 2.5
so = bpy.data.objects.new("Sol", sun); sc.collection.objects.link(so)
so.rotation_euler = (math.radians(40), 0, math.radians(-30))
sc.render.engine = "CYCLES"; sc.cycles.samples = 16
sc.render.film_transparent = True
sc.view_settings.view_transform = "Standard"
json.dump({"r": list(r), "u": list(u), "d": list(d),
           "xmin": float(x.min()), "xmax": float(x.max())}, open("camara.json", "w"))
bpy.ops.wm.save_as_mainfile(filepath="/home/claude/sapo/sapo_base.blend")
if len(sys.argv) > 1 and sys.argv[-1] == "render":
    sc.render.filepath = "/home/claude/sapo/prueba_cuadro.png"
    bpy.ops.render.render(write_still=True)
