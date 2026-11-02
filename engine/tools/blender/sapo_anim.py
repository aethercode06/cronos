"""Gran Sapo: esqueleto, lengua, boca y animaciones; renderiza cada acción desde la cámara del cuadro.
Uso: python3 sapo_anim.py <salida> [acción,...] [paso]"""
import bpy, bmesh, sys, os, math, json
import numpy as np
from mathutils import Vector, Quaternion, Matrix

OUT = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else "anim")
ONLY = sys.argv[2].split(",") if len(sys.argv) > 2 and sys.argv[2] != "all" else None
RES = int(os.environ.get("RES", "512"))
os.makedirs(OUT, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=os.environ.get("BASE", "/home/claude/sapo/sapo_base.blend"))
sc = bpy.context.scene
sapo = bpy.data.objects["GranSapo"]
me = sapo.data


def ss(a, b, t):
    t = np.clip((t - a) / (b - a), 0, 1); return t * t * (3 - 2 * t)


V = np.array([tuple(v.co) for v in me.vertices]); x, y, z = V.T

# ---------------------------------------------------------------- pesos
mouth_z = 0.02 + np.maximum(0, 0.95 - x) * 0.16
front = ss(0.42, 0.56, x)
w = {}
w["jaw"] = front * (z < mouth_z) * ss(-0.42, -0.22, z) * (1 - ss(0.62, 0.8, np.abs(y)))
w["head"] = ss(0.22, 0.42, x) * (z >= mouth_z) * ss(-0.2, 0.0, z)
w["head"] = np.maximum(w["head"], (z > 0.42) * ss(0.05, 0.2, x))       # corona
w["throat"] = np.exp(-(((x - 0.45) / 0.32) ** 2 + (y / 0.55) ** 2 + ((z + 0.3) / 0.25) ** 2)) * (1 - w["jaw"])
legs = {"pata_del_izq": (0.48, 0.48, -0.62, 0.3), "pata_del_der": (0.48, -0.48, -0.62, 0.3),
        "pata_tra_izq": (-0.48, 0.6, -0.5, 0.38), "pata_tra_der": (-0.48, -0.6, -0.5, 0.38)}
for k, (cx, cy, cz, r) in legs.items():
    d2 = ((x - cx) ** 2 + (y - cy) ** 2 + ((z - cz) * 0.8) ** 2) / r ** 2
    w[k] = np.exp(-d2 * 1.6) * ss(-0.15, -0.35, z) * (np.sign(y) == np.sign(cy))
tot = sum(w.values())
scale = np.where(tot > 1, 1 / np.maximum(tot, 1e-6), 1.0)
for k in w:
    w[k] = w[k] * scale
w["body"] = np.clip(1 - sum(w.values()), 0, 1)
for k, arr in w.items():
    g = sapo.vertex_groups.new(name=k)
    for i, val in enumerate(arr):
        if val > 0.003:
            g.add([i], float(val), "REPLACE")

# caras que cruzan la línea de la boca: interior oscuro (se ve al abrirla)
mm = bpy.data.materials.new("Boca")
mm.use_nodes = True
pb = next(n for n in mm.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
pb.inputs["Base Color"].default_value = (0.16, 0.02, 0.025, 1); pb.inputs["Roughness"].default_value = 0.35
me.materials.append(mm)
jw = w["jaw"] > 0.5; hd = w["head"] > 0.5
for p in me.polygons:
    vs = p.vertices
    if any(jw[i] for i in vs) and any(hd[i] or (not jw[i]) for i in vs) and p.center.x > 0.5:
        p.material_index = 1

# lengua: tubo rosado dentro de la boca, se estira con su hueso
bm = bmesh.new()
segs, rings = 12, 14
rowsv = []
for j in range(rings + 1):
    t = j / rings
    xx = 0.6 + 0.32 * t
    rr = 0.11 * (1 - 0.3 * t) * (1.35 if j >= rings - 1 else 1)
    rowsv.append([bm.verts.new((xx, rr * math.cos(2 * math.pi * i / segs) * 1.3, -0.02 + rr * math.sin(2 * math.pi * i / segs) * 0.6)) for i in range(segs)])
for j in range(rings):
    for i in range(segs):
        bm.faces.new([rowsv[j][i], rowsv[j][(i + 1) % segs], rowsv[j + 1][(i + 1) % segs], rowsv[j + 1][i]])
bm.faces.new(rowsv[-1]); bm.faces.new(rowsv[0][::-1])
bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
tme = bpy.data.meshes.new("Lengua"); bm.to_mesh(tme); bm.free()
for p in tme.polygons:
    p.use_smooth = True
tm = bpy.data.materials.new("Lengua"); tm.use_nodes = True
pt = next(n for n in tm.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
pt.inputs["Base Color"].default_value = (0.95, 0.32, 0.38, 1); pt.inputs["Roughness"].default_value = 0.25
pt.inputs["Subsurface Weight"].default_value = 0.3
tme.materials.append(tm)
lengua = bpy.data.objects.new("Lengua", tme); sc.collection.objects.link(lengua)
lengua.vertex_groups.new(name="lengua").add(list(range(len(tme.vertices))), 1.0, "REPLACE")

# ---------------------------------------------------------------- esqueleto
arm_d = bpy.data.armatures.new("Esqueleto")
arm = bpy.data.objects.new("Esqueleto", arm_d); sc.collection.objects.link(arm)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="EDIT")
eb = arm_d.edit_bones


def bone(name, h, t, parent=None):
    b = eb.new(name); b.head = h; b.tail = t
    if parent:
        b.parent = eb[parent]
    return b


bone("root", (0, 0, -0.8), (0, 0, -0.5))
bone("body", (-0.15, 0, -0.35), (0.3, 0, 0.15), "root")
bone("head", (0.32, 0, 0.08), (0.95, 0, 0.25), "body")
bone("jaw", (0.48, 0, 0.0), (0.95, 0, -0.12), "head")
bone("lengua", (0.6, 0, -0.02), (0.92, 0, -0.02), "jaw")
bone("throat", (0.45, 0, -0.3), (0.75, 0, -0.32), "body")
for k, (cx, cy, cz, r) in legs.items():
    top = (cx * 0.85, cy * 0.75, -0.25)
    bone(k, top, (cx + (0.12 if "del" in k else -0.1), cy, -0.78), "root")
bpy.ops.object.mode_set(mode="OBJECT")
for ob in (sapo, lengua):
    md = ob.modifiers.new("arm", "ARMATURE"); md.object = arm
for pbn in arm.pose.bones:
    pbn.rotation_mode = "QUATERNION"

# boca interior estable: el material "Boca" ya marca la franja

# ---------------------------------------------------------------- utilidades de animación
REST = {b.name: b.matrix_local.to_quaternion() for b in arm_d.bones}


def qworld(axis, deg):
    return Quaternion(Vector(axis).normalized(), math.radians(deg))


def key(bname, f, rot=None, loc=None, scl=None):
    pbn = arm.pose.bones[bname]
    Bq = REST[bname]
    q = Quaternion()
    if rot:
        for axis, deg in rot:
            q = qworld(axis, deg) @ q
    pbn.rotation_quaternion = Bq.inverted() @ q @ Bq
    pbn.keyframe_insert("rotation_quaternion", frame=f)
    if loc is not None:
        lv = Bq.inverted() @ Vector(loc)
        pbn.location = lv
        pbn.keyframe_insert("location", frame=f)
    if scl is not None:
        pbn.scale = scl
        pbn.keyframe_insert("scale", frame=f)


def reset(f):
    for b in arm.pose.bones:
        key(b.name, f, rot=None, loc=(0, 0, 0), scl=(1, 1, 1))


Y = (0, 1, 0)   # cabeceo (subir/bajar la cabeza): giro alrededor de Y del mundo
X = (1, 0, 0)
Z = (0, 0, 1)

ACC = {}


def accion(nombre, frames, loop=False):
    def deco(fn):
        ACC[nombre] = (fn, frames, loop)
        return fn
    return deco


@accion("quieto", 24, loop=True)
def a_quieto():
    for f, s in ((0, 0.0), (6, 1.0), (12, 0.0), (18, 1.0), (24, 0.0)):
        k = math.sin(f / 24 * 2 * math.pi)
        reset(f)
        key("throat", f, scl=(1 + 0.18 * s, 1 + 0.25 * s, 1 + 0.25 * s))
        key("body", f, loc=(0, 0, 0.012 * math.sin(f / 24 * 4 * math.pi)), scl=(1, 1 + 0.02 * s, 1 + 0.03 * s))
        key("head", f, rot=[(Y, -2.5 * k)])


@accion("salto", 22)
def a_salto():
    # anticipación, impulso, aire, caída, aterrizaje
    P = [(0, 0, 0, 0, 0), (5, -0.16, -8, 18, 0), (7, 0.08, 6, -25, 0.05), (10, 0.55, 4, -40, 0.0),
         (14, 0.65, -4, -30, 0.0), (17, 0.25, -10, -10, 0.0), (19, -0.1, -6, 15, 0.0), (22, 0, 0, 0, 0)]
    for f, h, pitch, legs_, st in P:
        reset(f)
        key("body", f, rot=[(Y, pitch)], loc=(0, 0, min(0, h)),
            scl=(1 + (0.08 if h < 0 else -0.05 if h > 0.3 else 0), 1, 1 - (0.1 if h < 0 else -0.08 if 0 < h < 0.3 else 0)))
        for lg in legs:
            sgn = 1 if "tra" in lg else 0.6
            key(lg, f, rot=[(Y, legs_ * sgn * (1 if "tra" in lg else -1))])
        key("head", f, rot=[(Y, -pitch * 0.5)])


@accion("lengua", 18)
def a_lengua():
    T = [(0, 0, 0, 0.0), (3, -8, 4, 0.0), (5, -10, 22, 0.2), (7, -6, 26, 9.5), (9, -6, 24, 9.0),
         (12, -8, 20, 1.5), (14, -6, 10, 0.1), (18, 0, 0, 0.0)]
    for f, hp, jaw, tl in T:
        reset(f)
        key("head", f, rot=[(Y, hp)])
        key("jaw", f, rot=[(Y, jaw)])
        key("lengua", f, scl=(1, max(0.05, tl), 1))
        key("body", f, rot=[(Y, -3 if 5 <= f <= 12 else 0)], loc=(0.04 if 5 <= f <= 12 else 0, 0, 0))
        key("throat", f, scl=(1.1, 1.1, 1.1) if f in (3, 5) else (1, 1, 1))


@accion("hincharse", 16)
def a_hincharse():
    for f, s in ((0, 0), (5, 1.0), (8, 1.08), (12, 1.0), (16, 0)):
        reset(f)
        key("throat", f, scl=(1 + 0.9 * s, 1 + 1.1 * s, 1 + 1.0 * s))
        key("body", f, scl=(1 + 0.12 * s, 1 + 0.22 * s, 1 + 0.18 * s))
        key("head", f, rot=[(Y, -10 * s)], loc=(-0.05 * s, 0, 0.05 * s))


@accion("escupir", 14)
def a_escupir():
    for f, j, th, hp in ((0, 0, 0, 0), (4, 6, 0.5, 6), (6, 30, -0.1, -8), (9, 28, 0.0, -6), (14, 0, 0, 0)):
        reset(f)
        key("throat", f, scl=(1 + th, 1 + th * 1.2, 1 + th))
        key("jaw", f, rot=[(Y, j)])
        key("head", f, rot=[(Y, hp)])
        key("body", f, loc=(-0.04 if f == 6 else 0, 0, 0))


@accion("golpe", 10)
def a_golpe():
    for f, b, hp, sq in ((0, 0, 0, 0), (2, 12, -14, 0.12), (5, 6, -6, 0.05), (10, 0, 0, 0)):
        reset(f)
        key("body", f, rot=[(Y, b)], loc=(-0.1 * sq / 0.12, 0, 0), scl=(1 - sq * 0.5, 1 + sq, 1 - sq))
        key("head", f, rot=[(Y, hp)])
        key("jaw", f, rot=[(Y, 10 if f == 2 else 0)])


@accion("furia", 20)
def a_furia():
    for f in range(0, 21, 2):
        reset(f)
        k = min(1, f / 6) * (1 if f < 17 else (20 - f) / 3)
        sh = math.sin(f * 2.3) * 3 * k
        key("head", f, rot=[(Y, -22 * k), (Z, sh)])
        key("jaw", f, rot=[(Y, 34 * k)])
        key("body", f, rot=[(Y, -8 * k), (X, sh * 0.6)], scl=(1, 1 + 0.06 * k, 1 + 0.06 * k))
        key("throat", f, scl=(1 + 0.5 * k, 1 + 0.6 * k, 1 + 0.5 * k))


@accion("muerte", 24)
def a_muerte():
    for f, k in ((0, 0), (4, 0.25), (10, 0.7), (16, 1.0), (24, 1.0)):
        reset(f)
        key("root", f, rot=[(X, 0)], loc=(0, 0, -0.05 * k))
        key("body", f, rot=[(Y, 14 * k), (X, -10 * k)], loc=(0, 0, -0.18 * k), scl=(1 + 0.1 * k, 1 + 0.12 * k, 1 - 0.25 * k))
        key("head", f, rot=[(Y, 28 * k), (Z, -8 * k)])
        key("jaw", f, rot=[(Y, 18 * k)])
        key("lengua", f, scl=(1, 0.05 + 2.2 * max(0, k - 0.6), 1))
        for lg in legs:
            key(lg, f, rot=[(X, (22 if "izq" in lg else -22) * k)])


# ---------------------------------------------------------------- render
sc.render.resolution_x = sc.render.resolution_y = RES
sc.render.film_transparent = True
sc.cycles.samples = int(os.environ.get("SAMPLES", "10"))
sc.cycles.use_denoising = True
cam = sc.camera
cam.data.ortho_scale *= 1.5
cam.data.shift_x = 0.1
cam.data.shift_y = 0.02
meta = {}
for nombre, (fn, nf, loop) in ACC.items():
    if ONLY and nombre not in ONLY:
        continue
    arm.animation_data_clear()
    arm.animation_data_create()
    act = bpy.data.actions.new(nombre); arm.animation_data.action = act
    fn()
    step = int(os.environ.get("STEP", "2"))
    frames = list(range(0, nf + (0 if loop else 1), step))
    os.makedirs(os.path.join(OUT, nombre), exist_ok=True)
    for i, f in enumerate(frames):
        sc.frame_set(f)
        sc.render.filepath = os.path.join(OUT, nombre, f"{i:02d}.png")
        bpy.ops.render.render(write_still=True)
    meta[nombre] = {"n": len(frames), "loop": loop}
    print("accion", nombre, len(frames), flush=True)
json.dump(meta, open(os.path.join(OUT, "acciones.json"), "w"), indent=1)
bpy.ops.wm.save_as_mainfile(filepath=os.environ.get("RIG", "/home/claude/sapo/sapo_rig.blend"))
