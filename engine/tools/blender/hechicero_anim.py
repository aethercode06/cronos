"""Hechicero de Lava: esqueleto y animaciones sobre base.blend (de boss_base.py).
Uso: python3 hechicero_anim.py <base.blend> <salida_fotogramas> [acción,...|all]
Variables: RES, SAMPLES, STEP, PRUEBA=1 (solo 2 fotogramas por acción)."""
import bpy, sys, os, math, json
import numpy as np
from mathutils import Vector, Quaternion

BASE, OUT = sys.argv[1], os.path.abspath(sys.argv[2])
ONLY = sys.argv[3].split(",") if len(sys.argv) > 3 and sys.argv[3] != "all" else None
PRUEBA = bool(os.environ.get("PRUEBA"))
os.makedirs(OUT, exist_ok=True)
J = json.load(open(os.path.splitext(BASE)[0] + ".json"))
bpy.ops.wm.open_mainfile(filepath=os.path.abspath(BASE))
sc = bpy.context.scene
body = bpy.data.objects["Jefe"]
me = body.data
V = np.array([tuple(v.co) for v in me.vertices])
r, u, d = np.array(J["r"]), np.array(J["u"]), np.array(J["d"])
x0, y0, x1, y1 = J["bbox"]
px_, py_ = V @ r, V @ u
sx = (x1 - x0) / (px_.max() - px_.min()); sy = (y1 - y0) / (py_.max() - py_.min())


def at(ix, iy, rad=40, depth="mid"):
    """Punto 3D bajo el píxel (ix, iy) del cuadro de 2048: media de los vértices que caen cerca."""
    X = x0 + (px_ - px_.min()) * sx; Y = y0 + (py_.max() - py_) * sy
    sel = (X - ix) ** 2 + (Y - iy) ** 2 < rad ** 2
    if sel.sum() < 5:
        sel = (X - ix) ** 2 + (Y - iy) ** 2 < (rad * 2.5) ** 2
    P = V[sel]
    dd = P @ d
    if depth == "front":
        P = P[dd < np.percentile(dd, 40)]
    elif depth == "back":
        P = P[dd > np.percentile(dd, 60)]
    return Vector(P.mean(0))


# puntos clave del cuadro (píxeles del original de 2048)
K = {
    "pies": at(1150, 1830, 120), "cadera": at(1170, 1150, 90), "pecho": at(1200, 820, 90),
    "cuello": at(1260, 560, 60), "cabeza": at(1290, 380, 60), "capucha": at(1270, 210, 60),
    "hombro_f": at(1460, 640, 60), "codo_f": at(1560, 800, 50), "mano_f": at(1600, 560, 50),   # brazo del fuego
    "hombro_b": at(980, 700, 60), "codo_b": at(880, 950, 50), "mano_b": at(940, 1150, 50),    # brazo del bastón
    "baston_alto": at(1020, 1030, 40), "baston_bajo": at(300, 1760, 50),
    "rodilla_f": at(1340, 1450, 60), "pie_f": at(1380, 1800, 60),
    "rodilla_b": at(1000, 1450, 60), "pie_b": at(860, 1820, 60),
    "capa_b": at(450, 1300, 120), "capa_f": at(1500, 1100, 80),
}
for k, v in K.items():
    print(k, [round(c, 2) for c in v])

# ---------------------------------------------------------------- esqueleto
arm_d = bpy.data.armatures.new("Esqueleto")
arm = bpy.data.objects.new("Esqueleto", arm_d); sc.collection.objects.link(arm)
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="EDIT")
eb = arm_d.edit_bones


def bone(n, h, t, parent=None):
    b = eb.new(n); b.head = h; b.tail = t
    if parent:
        b.parent = eb[parent]
    return b


bone("root", K["pies"], K["pies"] + Vector((0, 0, 0.2)))
bone("cadera", K["cadera"], K["pecho"], "root")
bone("pecho", K["pecho"], K["cuello"], "cadera")
bone("cabeza", K["cuello"], K["capucha"], "pecho")
bone("brazo_f", K["hombro_f"], K["codo_f"], "pecho")
bone("antebrazo_f", K["codo_f"], K["mano_f"], "brazo_f")
bone("brazo_b", K["hombro_b"], K["codo_b"], "pecho")
bone("antebrazo_b", K["codo_b"], K["mano_b"], "brazo_b")
bone("baston", K["baston_alto"], K["baston_bajo"], "root")
bone("muslo_f", K["cadera"] + (K["rodilla_f"] - K["cadera"]) * 0.1, K["rodilla_f"], "cadera")
bone("pierna_f", K["rodilla_f"], K["pie_f"], "muslo_f")
bone("muslo_b", K["cadera"] + (K["rodilla_b"] - K["cadera"]) * 0.1, K["rodilla_b"], "cadera")
bone("pierna_b", K["rodilla_b"], K["pie_b"], "muslo_b")
bone("capa_b", K["pecho"] + (K["capa_b"] - K["pecho"]) * 0.25, K["capa_b"], "pecho")
bone("capa_f", K["hombro_f"], K["capa_f"], "pecho")
bpy.ops.object.mode_set(mode="OBJECT")

# pesos por distancia a cada hueso (la malla de Hunyuan no es apta para pesos por calor)
names = [b.name for b in arm_d.bones if b.name != "root"]
Dm = []
for n in names:
    b = arm_d.bones[n]
    a = np.array(b.head_local); c = np.array(b.tail_local); ab = c - a
    t = np.clip(((V - a) @ ab) / (ab @ ab), 0, 1)
    Dm.append(np.linalg.norm(V - (a + t[:, None] * ab), axis=1))
Dm = np.array(Dm)
scale = np.linalg.norm(V.max(0) - V.min(0))
# alcance de cada hueso (el bastón es fino; la capa, ancha)
RAD = {"baston": 0.022, "antebrazo_b": 0.04, "brazo_b": 0.045, "antebrazo_f": 0.045, "brazo_f": 0.05,
       "capa_b": 0.09, "capa_f": 0.07, "cabeza": 0.06, "pecho": 0.08, "cadera": 0.09}
rad = np.array([RAD.get(n, 0.06) * scale for n in names])[:, None]
W = np.exp(-(Dm / rad) ** 2) + 1e-9
W[Dm > Dm.min(0) + 0.07 * scale] = 0
W /= W.sum(0)
body.vertex_groups.clear()
for k, n in enumerate(names):
    g = body.vertex_groups.new(name=n)
    idx = np.nonzero(W[k] > 0.01)[0]
    for i in idx:
        g.add([int(i)], float(W[k, i]), "REPLACE")
md = body.modifiers.new("arm", "ARMATURE"); md.object = arm
for pb in arm.pose.bones:
    pb.rotation_mode = "QUATERNION"
REST = {b.name: b.matrix_local.to_quaternion() for b in arm_d.bones}
# ejes de la vista: R = derecha en pantalla, U = arriba en pantalla, D = hacia el fondo
R, U, D = Vector(r), Vector(u), Vector(d)


def key(bn, f, rot=(), loc=None, scl=None):
    pb = arm.pose.bones[bn]; Bq = REST[bn]
    q = Quaternion()
    for axis, deg in rot:
        q = Quaternion(Vector(axis), math.radians(deg)) @ q
    pb.rotation_quaternion = Bq.inverted() @ q @ Bq
    pb.keyframe_insert("rotation_quaternion", frame=f)
    pb.location = Bq.inverted() @ Vector(loc or (0, 0, 0))
    pb.keyframe_insert("location", frame=f)
    pb.scale = scl or (1, 1, 1)
    pb.keyframe_insert("scale", frame=f)


def pose(f, P):
    for b in arm.pose.bones:
        v = P.get(b.name, ())
        key(b.name, f, v[0] if len(v) > 0 else (), v[1] if len(v) > 1 else None, v[2] if len(v) > 2 else None)


ACC = {}


def accion(nombre, frames, loop=False):
    def deco(fn):
        ACC[nombre] = (fn, frames, loop); return fn
    return deco


# giro «en el plano de la pantalla» = alrededor de D (positivo = antihorario visto por la cámara)
@accion("quieto", 32, loop=True)
def a_quieto(N):
    for f in range(0, N + 1, 4):
        t = f / N * 2 * math.pi; s = math.sin(t)
        pose(f, {
            "cadera": ([(D, 1.2 * s)], U * (0.006 * s)),
            "pecho": ([(D, -1.5 * s)],),
            "cabeza": ([(D, 2.5 * math.sin(t + 0.6))],),
            "brazo_f": ([(D, 3 * math.sin(t + 1.2))],),
            "antebrazo_f": ([(D, 4 * math.sin(t + 1.6))],),
            "brazo_b": ([(D, -1.5 * s)],),
            "capa_b": ([(D, 4 * math.sin(t + 0.4)), (U, 3 * s)],),
            "capa_f": ([(D, -3 * math.sin(t + 0.9))],),
        })


@accion("lanzar", 18)
def a_lanzar(N):
    # carga atrás, empuja el brazo del fuego hacia delante, recupera
    K_ = [(0, 0), (6, -1), (9, 1.0), (12, 0.8), (18, 0)]
    for f, k in K_:
        back = max(0.0, -k); fwd = max(0.0, k)
        pose(f, {
            "cadera": ([(D, 3 * back - 4 * fwd)], R * (0.02 * fwd - 0.015 * back)),
            "pecho": ([(D, 8 * back - 10 * fwd)],),
            "cabeza": ([(D, -4 * fwd)],),
            "brazo_f": ([(D, 35 * back - 70 * fwd)],),
            "antebrazo_f": ([(D, 25 * back - 40 * fwd)],),
            "brazo_b": ([(D, -6 * fwd)],),
            "capa_b": ([(D, 6 * fwd - 3 * back)],),
            "capa_f": ([(D, -12 * fwd + 4 * back)],),
        })


@accion("invocar", 28)
def a_invocar(N):
    # alza ambos brazos al cielo (lluvia de meteoros), tiembla y los baja
    for f in range(0, N + 1, 2):
        up = min(1.0, f / 8) * (1 if f < 22 else max(0.0, (N - f) / 6))
        sh = math.sin(f * 2.1) * 2.5 * (1 if 8 <= f < 22 else 0)
        pose(f, {
            "cadera": ([(D, sh * 0.4)], U * (0.03 * up)),
            "pecho": ([(D, -6 * up + sh), (R, -8 * up)],),
            "cabeza": ([(R, -14 * up)],),
            "brazo_f": ([(D, 45 * up)],),
            "antebrazo_f": ([(D, 25 * up + sh * 2)],),
            "brazo_b": ([(D, -4 * up)],),
            "capa_b": ([(D, 6 * up + sh * 0.6)],),
            "capa_f": ([(D, -10 * up)],),
        })


@accion("aturdido", 24, loop=True)
def a_aturdido(N):
    # escudo roto: se dobla, se apoya en el bastón y jadea
    for f in range(0, N + 1, 4):
        t = f / N * 2 * math.pi; s = math.sin(t)
        pose(f, {
            "root": ([], U * (-0.05)),
            "cadera": ([(D, 10 + 2 * s)], U * (-0.04)),
            "pecho": ([(D, 14 + 3 * s), (R, 10)],),
            "cabeza": ([(D, 12 + 4 * s)],),
            "brazo_f": ([(D, -30)],),
            "antebrazo_f": ([(D, -20 + 5 * s)],),
            "brazo_b": ([(D, -15)],),
            "muslo_f": ([(D, -10)],), "pierna_f": ([(D, 15)],),
            "capa_b": ([(D, -6 + 3 * s)],),
        })


@accion("golpe", 10)
def a_golpe(N):
    for f, k in ((0, 0), (2, 1), (5, 0.5), (10, 0)):
        pose(f, {
            "cadera": ([(D, 8 * k)], R * (-0.04 * k)),
            "pecho": ([(D, 12 * k)],),
            "cabeza": ([(D, 14 * k)],),
            "brazo_f": ([(D, 25 * k)],),
            "capa_b": ([(D, -8 * k)],), "capa_f": ([(D, 10 * k)],),
        })


@accion("muerte", 26)
def a_muerte(N):
    # se dobla y cae de rodillas; el motor añade la desintegración en lava
    for f, k in ((0, 0), (5, 0.3), (12, 0.8), (18, 1.0), (26, 1.0)):
        pose(f, {
            "root": ([], U * (-0.12 * k)),
            "cadera": ([(D, 9 * k)], U * (-0.05 * k)),
            "pecho": ([(D, 14 * k), (R, 8 * k)],),
            "cabeza": ([(D, 18 * k)],),
            "brazo_f": ([(D, -35 * k)],), "antebrazo_f": ([(D, -20 * k)],),
            "baston": ([(D, 6 * k)],),
            "muslo_f": ([(D, -14 * k)],), "pierna_f": ([(D, 24 * k)],),
            "muslo_b": ([(D, 10 * k)],), "pierna_b": ([(D, -14 * k)],),
            "capa_b": ([(D, -6 * k)],), "capa_f": ([(D, 8 * k)],),
        })


# ---------------------------------------------------------------- render (cámara del cuadro, más margen)
cam = sc.camera
cam.data.ortho_scale *= 1.25
RES = int(os.environ.get("RES", "640"))
sc.render.resolution_x = sc.render.resolution_y = RES
sc.render.film_transparent = True
sc.cycles.samples = int(os.environ.get("SAMPLES", "10"))
sc.cycles.use_denoising = True
STEP = int(os.environ.get("STEP", "2"))
arm.animation_data_create()
meta = {}
for nombre, (fn, nf, loop) in ACC.items():
    if ONLY and nombre not in ONLY:
        continue
    act = bpy.data.actions.new(nombre); arm.animation_data.action = act
    fn(nf)
    frames = [nf // 3, (2 * nf) // 3] if PRUEBA else list(range(0, nf + (0 if loop else 1), STEP))
    os.makedirs(os.path.join(OUT, nombre), exist_ok=True)
    for i, f in enumerate(frames):
        sc.frame_set(f)
        sc.render.filepath = os.path.join(OUT, nombre, f"{i:02d}.png")
        bpy.ops.render.render(write_still=True)
    meta[nombre] = {"n": len(frames), "loop": loop}
    print("accion", nombre, len(frames), flush=True)
json.dump(meta, open(os.path.join(OUT, "acciones.json"), "w"), indent=1)
bpy.ops.wm.save_as_mainfile(filepath=os.path.splitext(os.path.abspath(BASE))[0] + "_rig.blend")
