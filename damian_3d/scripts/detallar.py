"""Damián: del cuerpo base de MakeHuman al personaje del juego.
Quita la camiseta, el cuerpo tapado por el overol, pinta mugre/vello/sangre, dientes podridos, máscara de plástico vieja,
pelo largo grasiento a los lados (calvo arriba). Uso: python detallar.py base.blend salida_dir"""
import bpy, bmesh, sys, os, math, random
import numpy as np
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rast import rasterizar, ruido, sangre
from PIL import Image, ImageDraw, ImageFilter

BASE, OUT = sys.argv[-2], sys.argv[-1]; os.makedirs(OUT, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=BASE)
random.seed(7); RNG = np.random.default_rng(7)

# ---------- limpieza: solo la copia de exportación ----------
for o in list(bpy.data.objects):
    if not (o.name.endswith("_export") or (o.parent and o.parent.name.endswith("_export"))):
        bpy.data.objects.remove(o)
OB = {}
for o in list(bpy.data.objects):
    n = o.name.replace("_export", "").replace("Human.", "").replace("Human", "cuerpo")
    o.name = n; OB[n] = o
    for md in list(o.modifiers):
        if md.type in ('SUBSURF', 'MASK'): o.modifiers.remove(md)
print("OBJETOS", list(OB))
# fijar las formas del cuerpo (macros y ajustes) en la malla base; solo se quedan los gestos ARKit
def fijar_formas(o):
    sk = o.data.shape_keys
    if not sk: return
    base = sk.key_blocks[0]
    co = np.array([v.co for v in base.data])
    ref = co.copy()
    for kb in sk.key_blocks[1:]:
        if kb.name.startswith("$") or "-" in kb.name:
            co += kb.value * (np.array([v.co for v in kb.data]) - ref)
    for kb in sk.key_blocks[1:]:
        if not (kb.name.startswith("$") or "-" in kb.name):
            d = np.array([v.co for v in kb.data]) - ref
            for i, v in enumerate(kb.data): v.co = Vector(co[i] + d[i])
    for i, v in enumerate(base.data): v.co = Vector(co[i])
    for i, v in enumerate(o.data.vertices): v.co = Vector(co[i])
    for kb in list(sk.key_blocks[1:]):
        if kb.name.startswith("$") or "-" in kb.name: o.shape_key_remove(kb)
    if len(o.data.shape_keys.key_blocks) == 1: o.shape_key_clear()
for o in OB.values():
    if o.type == 'MESH': fijar_formas(o)
# mueca fija: labios retraídos que dejan ver los dientes podridos (se puede seguir animando encima)
MUECA = {'jawOpen': 0.32, 'mouthUpperUpLeft': 2.4, 'mouthUpperUpRight': 2.4, 'mouthLowerDownLeft': 2.2, 'mouthLowerDownRight': 2.2,
         'mouthStretchLeft': 0.7, 'mouthStretchRight': 0.7, 'noseSneerLeft': 0.6, 'noseSneerRight': 0.6}
for o in OB.values():
    if o.type != 'MESH' or not o.data.shape_keys: continue
    kbs = o.data.shape_keys.key_blocks; base = np.array([v.co for v in kbs[0].data]); d = np.zeros_like(base)
    for kb in kbs[1:]:
        if kb.name in MUECA: d += MUECA[kb.name] * (np.array([v.co for v in kb.data]) - base)
    if not d.any(): continue
    for kb in kbs:
        arr = np.array([v.co for v in kb.data]) + d
        for i, v in enumerate(kb.data): v.co = Vector(arr[i])
    for i, v in enumerate(o.data.vertices): v.co = Vector(base[i] + d[i])
    print("mueca", o.name)
# altura final: casi 2 metros
dg0 = bpy.context.evaluated_depsgraph_get()
alto0 = max((OB["cuerpo"].matrix_world @ v.co).z for v in OB["cuerpo"].data.vertices)
f_esc = 1.97 / alto0
print("ESCALA", alto0, "->", f_esc)
bpy.ops.object.select_all(action='DESELECT')
for o in OB.values(): o.select_set(True)
OB["rig"].scale = (f_esc,) * 3
bpy.context.view_layer.objects.active = OB["rig"]
bpy.context.view_layer.update()
bpy.ops.object.transform_apply(location=False, rotation=False, scale=True, properties=False)
# los hijos heredan la escala del padre: aplicarla también en ellos
for o in OB.values():
    if o.type == 'MESH' and o.matrix_world.to_scale().x != 1.0:
        mwo = o.matrix_world.copy()
        for v in o.data.vertices: v.co = mwo @ v.co
        if o.data.shape_keys:
            for kb in o.data.shape_keys.key_blocks:
                for d in kb.data: d.co = mwo @ d.co
        o.matrix_parent_inverse = Matrix.Identity(4); o.matrix_basis = Matrix.Identity(4)
rig = OB["rig"]; body = OB["cuerpo"]; suit = OB["male_worksuit01"]; teeth = OB["teeth_base"]
print("HUESOS", [b.name for b in rig.data.bones][:80])
mw = body.matrix_world
H = max((mw @ v.co).z for v in body.data.vertices)
print("ALTURA", H)

def img_de(obj):
    for n in obj.active_material.node_tree.nodes:
        if n.type == 'TEX_IMAGE' and n.name.startswith("Diffuse"): return n.image
def a_np(im):
    a = np.array(im.pixels[:], np.float32).reshape(im.size[1], im.size[0], 4)[::-1]; return a
def de_np(im, a, nombre):
    im2 = bpy.data.images.new(nombre, a.shape[1], a.shape[0], alpha=True)
    im2.pixels = np.ascontiguousarray(a[::-1]).ravel(); im2.filepath_raw = os.path.join(OUT, nombre + ".png"); im2.file_format = 'PNG'; im2.save(); im2.pack()
    for o in bpy.data.objects:
        if o.type == 'MESH' and o.active_material:
            for n in o.active_material.node_tree.nodes:
                if n.type == 'TEX_IMAGE' and n.image == im: n.image = im2
    return im2

def _bm_mundo(o):
    b = bmesh.new(); b.from_mesh(o.data); b.transform(o.matrix_world); return b

# ---------- 0. más gordo: barriga, costados, pecho, papada, brazos (cuerpo y overol a la vez) ----------
def engordar(o):
    me = o.data; mwo = o.matrix_world
    me.calc_normals_split() if hasattr(me, "calc_normals_split") else None
    pts = np.array([mwo @ v.co for v in me.vertices]); nr = np.array([v.normal for v in me.vertices])
    z = pts[:, 2] / 1.97; x = pts[:, 0]; y = pts[:, 1]
    g = lambda a, c, s: np.exp(-((a - c) / s) ** 2)
    barr = g(z, 0.56, 0.09) * np.clip(-(y + 0.02) / 0.15, 0, 1) * 0.10          # barriga hacia delante y abajo
    cost = g(z, 0.58, 0.10) * g(np.abs(x), 0.17, 0.08) * 0.035                  # michelines
    pech = g(z, 0.70, 0.05) * g(np.abs(x), 0.08, 0.08) * np.clip(-(y) / 0.1, 0, 1) * 0.035
    espa = g(z, 0.72, 0.06) * np.clip((y - 0.02) / 0.1, 0, 1) * 0.03           # espalda redonda
    papa = g(z, 0.885, 0.018) * g(np.abs(x), 0.0, 0.06) * np.clip(-(y + 0.04) / 0.06, 0, 1) * 0.022
    braz = g(z, 0.74, 0.05) * np.clip((np.abs(x) - 0.2) / 0.06, 0, 1) * g(np.abs(x), 0.36, 0.12) * 0.022
    nalg = g(z, 0.48, 0.06) * np.clip((y - 0.03) / 0.08, 0, 1) * 0.03
    tor = np.clip((0.3 - np.abs(x)) / 0.06, 0, 1)                                 # solo el tronco (no las manos)
    d = (barr + cost + pech + espa + papa + nalg) * tor + braz * np.clip((0.55 - np.abs(x)) / 0.1, 0, 1)
    nuevo = pts + nr * d[:, None]
    inv = mwo.inverted()
    for i, v in enumerate(me.vertices): v.co = inv @ Vector(nuevo[i])
    if me.shape_keys:
        base = np.array([k.co for k in me.shape_keys.key_blocks[0].data])
        for kb in me.shape_keys.key_blocks:
            dd = np.array([k.co for k in kb.data]) - base
            for i, k in enumerate(kb.data): k.co = me.vertices[i].co + Vector(dd[i])
for o in (OB["cuerpo"], OB["male_worksuit01"]):
    engordar(o)
bpy.context.view_layer.update()

# ---------- 1. overol sin camiseta ----------
sim = img_de(suit); S = a_np(sim); sz = S.shape[0]
bm = bmesh.new(); bm.from_mesh(suit.data); uvl = bm.loops.layers.uv.active
borrar = []
for f in bm.faces:
    u = sum((l[uvl].uv for l in f.loops), Vector((0, 0))) / len(f.loops)
    px = S[int((1 - u.y) * (sz - 1)), int(u.x * (sz - 1))]
    if px[:3].min() > 0.8: borrar.append(f)
bmesh.ops.delete(bm, geom=borrar, context='FACES'); bm.to_mesh(suit.data); bm.free()
print("camiseta: caras quitadas", len(borrar))

# ---------- 2. cuerpo tapado por el overol (para que no asome) ----------
bpy.context.view_layer.update()
bvs = BVHTree.FromBMesh(_bm_mundo(suit))
bm = bmesh.new(); bm.from_mesh(body.data)
helper = None
tap = set()
for v in bm.verts:
    p = mw @ v.co
    nv = (mw.to_3x3() @ v.normal).normalized()
    hit = bvs.ray_cast(p - nv * 0.002, nv, 0.05)
    if hit[0] is not None and p.z < H * 0.78:
        loc, nrm, idx, d = bvs.find_nearest(p, 0.05)
        if loc is not None and (p - loc).dot(nrm) < 0.0:
            tap.add(v.index)
caras = [f for f in bm.faces if all(v.index in tap for v in f.verts)]
bmesh.ops.delete(bm, geom=caras, context='FACES_ONLY')
bm.to_mesh(body.data); bm.free()
print("cuerpo: caras tapadas quitadas", len(caras))

# ---------- 3. piel: mugre, vello, llagas, sangre ----------
bim = img_de(body); B = a_np(bim); bs = B.shape[0]
P, N, M = rasterizar(body.data, mw, bs)
z = P[..., 2] / H; x = np.abs(P[..., 0]); y = P[..., 1]
# vello: pecho, barriga, hombros, brazos, antebrazos, espalda alta, piernas
cx = np.abs(P[..., 0])
frente = N[..., 1] < 0.2
vello = np.zeros(z.shape, np.float32)
vello += ((z > 0.50) & (z < 0.80) & (cx < 0.26)) * 1.0           # pecho y barriga
vello += ((z > 0.62) & (z < 0.84) & (cx > 0.17)) * 0.8           # hombros y brazos
vello += ((z > 0.78) & (z < 0.84) & (cx < 0.2) & ~frente) * 0.5  # nuca/espalda alta
vello += ((cx > 0.45) & (cx < 0.68)) * 0.7                          # antebrazos (en pose A)
vello += (z < 0.45) * 0.7                                          # piernas
vello = np.clip(vello, 0, 1) * M
vello = np.array(Image.fromarray((vello * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(28)), np.float32) / 255
vello *= ruido(P, 9, 1) * 0.5 + 0.7
vello = np.clip(vello * 1.3, 0, 1) * M
vimg = Image.new("L", (bs, bs), 0); dr = ImageDraw.Draw(vimg)
cand = np.argwhere(vello > 0.15)
n = min(len(cand), 90000)
sel = cand[RNG.choice(len(cand), n, replace=False)]
for (yy, xx) in sel:
    if RNG.random() > vello[yy, xx]: continue
    a = RNG.uniform(0, math.pi); L = RNG.uniform(5, 11)
    x2 = xx + math.cos(a) * L; y2 = yy + math.sin(a) * L
    xm = (xx + x2) / 2 + RNG.uniform(-1.5, 1.5); ym = (yy + y2) / 2 + RNG.uniform(-1.5, 1.5)
    dr.line([(xx, yy), (xm, ym), (x2, y2)], fill=int(150 + 100 * RNG.random()), width=1)
V = np.array(vimg.filter(ImageFilter.GaussianBlur(0.4)), np.float32) / 255.0
col = B[..., :3]
# piel más pálida y sucia
gris = col.mean(-1, keepdims=True)
col = col * 0.7 + gris * 0.3
col *= np.array([0.86, 0.8, 0.72])
mug = ruido(P, 14, 2)
suc = np.clip((0.35 - z) * 2.5, 0, 1)[..., None] * 0.6          # pies y piernas muy sucios
suc += (mug * 0.35)[..., None]
manos = (cx > 0.66)[..., None] * 0.3
suc = np.array(Image.fromarray((np.clip(suc + manos * mug[..., None], 0, 0.7)[..., 0] * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(3)), np.float32)[..., None] / 255
tierra = np.array([0.18, 0.13, 0.08])
col = col * (1 - suc) + tierra * suc
# sombra del vello + pelos
col = col * (1 - vello[..., None] * 0.08)
col = col * (1 - V[..., None] * 0.8) + np.array([0.035, 0.025, 0.018]) * V[..., None] * 0.8
# llagas y granos rojizos
ll = (ruido(P, 40, 3) > 0.95) & M
col[ll] = col[ll] * 0.55 + np.array([0.35, 0.08, 0.06]) * 0.45
# sangre seca en manos, antebrazos y barriga baja
sang = sangre(P, M, (cx > 0.6), 70, RNG, 0.01, 0.03)                     # manos y dedos
sang = np.maximum(sang, sangre(P, M, (cx > 0.4) & (cx < 0.6), 25, RNG, 0.008, 0.025))
sang = np.maximum(sang, sangre(P, M, (z > 0.6) & (z < 0.84) & (cx < 0.25), 18, RNG, 0.01, 0.035))
sang = np.maximum(sang, sangre(P, M, (z > 0.82) & (z < 0.88) & (y < -0.02) & (cx < 0.08), 8, RNG, 0.006, 0.018))
sang = np.clip(sang * 1.2, 0, 1)[..., None] * (0.85 + 0.15 * ruido(P, 50, 19))[..., None]
borde_s = np.clip(sang * (1 - sang) * 4, 0, 1)
col = col * (1 - sang * 0.97) + np.array([0.13, 0.012, 0.006]) * sang * 0.97
col = col * (1 - borde_s * 0.35)
cara = ((z > 0.86) & (z < 0.925) & (y < -0.03) & (cx < 0.07)).astype(np.float32) * M
cara = np.array(Image.fromarray((cara * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(10)), np.float32) / 255
bimg = Image.new("L", (bs, bs), 0); dbb = ImageDraw.Draw(bimg)
cb = np.argwhere(cara > 0.2)
for (yy, xx) in cb[RNG.choice(len(cb), min(len(cb), 60000), replace=False)]:
    if RNG.random() > cara[yy, xx]: continue
    a = RNG.uniform(0, 6.28); L = RNG.uniform(1.5, 3.5)
    dbb.line([(xx, yy), (xx + math.cos(a) * L, yy + math.sin(a) * L)], fill=int(120 + 120 * RNG.random()), width=1)
barba = np.array(bimg.filter(ImageFilter.GaussianBlur(0.5)), np.float32) / 255

col = col * (1 - cara[..., None] * 0.06)
col = col * (1 - cara[..., None] * 0.12)
# cuero cabelludo: costras y manchas
cab = (z > 0.95) & M
cst = cab & (ruido(P, 35, 6) > 0.78)
col[cst] = col[cst] * 0.5 + np.array([0.25, 0.1, 0.07]) * 0.5
B[..., :3] = np.clip(col, 0, 1)
bim2 = de_np(bim, B, "damian_piel")
print("piel pintada")

# ---------- 4. overol: oscuro, gastado, barro y sangre ----------
P2, N2, M2 = rasterizar(suit.data, suit.matrix_world, sz)
z2 = P2[..., 2] / H
c = S[..., :3]
g = c.mean(-1, keepdims=True)
c = c * 0.35 + g * 0.2 + np.array([0.0, 0.01, 0.025])             # vaquero oscuro y desteñido
c *= 0.45
m2 = ruido(P2, 10, 7)
barro = np.clip((0.3 - z2) * 4, 0, 1) * (0.5 + 0.5 * m2)
barro = np.array(Image.fromarray((np.clip(barro + m2 * 0.35, 0, 0.75) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(4)), np.float32)[..., None] / 255
c = c * (1 - barro) + np.array([0.13, 0.09, 0.05]) * barro
grasa = (ruido(P2, 25, 8) > 0.7)[..., None] * 0.35
c = c * (1 - grasa * 0.6)
frente2 = P2[..., 1] < 0
s2 = sangre(P2, M2, (z2 > 0.45) & (z2 < 0.75) & frente2, 30, RNG, 0.02, 0.07)
s2 = np.maximum(s2, sangre(P2, M2, (z2 > 0.3) & (z2 < 0.5) & frente2, 16, RNG, 0.015, 0.05))
s2 = np.maximum(s2, sangre(P2, M2, M2, 25, RNG, 0.008, 0.02))
s2 = (s2 * (0.7 + 0.3 * ruido(P2, 40, 20)))[..., None]
c = c * (1 - s2 * 0.85) + np.array([0.09, 0.012, 0.008]) * s2 * 0.85
S[..., :3] = np.clip(c, 0, 1)
de_np(sim, S, "damian_overol")
print("overol pintado")

# ---------- 5. dientes podridos ----------
tim = img_de(teeth); T = a_np(tim); P3, N3, M3 = rasterizar(teeth.data, teeth.matrix_world, T.shape[0])
t = T[..., :3]; br = t.mean(-1)
diente = br > 0.55
podr = ruido(P3, 220, 11)
t[diente] = t[diente] * np.array([0.6, 0.45, 0.22])
neg = diente & (podr > 0.5)
t[neg] = t[neg] * 0.1 + np.array([0.05, 0.03, 0.01]) * 0.9
mar = diente & (podr > 0.32) & ~neg
t[mar] = t[mar] * 0.45 + np.array([0.25, 0.14, 0.04]) * 0.55
t[~diente] = t[~diente] * np.array([0.55, 0.28, 0.25])        # encías oscuras e irritadas
T[..., :3] = np.clip(t, 0, 1)
de_np(tim, T, "damian_dientes")
# quitar algunos dientes (piezas sueltas)
bm = bmesh.new(); bm.from_mesh(teeth.data); bm.verts.ensure_lookup_table()
islas = []; vist = set()
for v in bm.verts:
    if v.index in vist: continue
    pila = [v]; isla = []
    while pila:
        a = pila.pop()
        if a.index in vist: continue
        vist.add(a.index); isla.append(a)
        for e in a.link_edges: pila.append(e.other_vert(a))
    islas.append(isla)
print("dientes: piezas", len(islas))
if len(islas) > 10:
    fuera = [isla for isla in islas if len(isla) < 400]
    random.shuffle(fuera)
    for isla in fuera[:4]:
        bmesh.ops.delete(bm, geom=isla, context='VERTS')
bm.to_mesh(teeth.data); bm.free()

# ---------- referencias de la cabeza ----------
ojos = OB["high-poly"]
ov = [ojos.matrix_world @ v.co for v in ojos.data.vertices]
oi = [p for p in ov if p.x > 0]; od = [p for p in ov if p.x < 0]
ci = sum(oi, Vector()) / len(oi); cd = sum(od, Vector()) / len(od)
ojo_z = (ci.z + cd.z) / 2; ojo_y = min(ci.y, cd.y)
hb = rig.data.bones["head"]; cab_c = rig.matrix_world @ hb.head_local
print("OJOS", ci, cd, "CABEZA", cab_c)
bvb = BVHTree.FromObject(body, bpy.context.evaluated_depsgraph_get())
# punta de la nariz: el vértice más adelantado entre los ojos y 6 cm por debajo
nar = min((mw @ v.co for v in body.data.vertices if abs((mw @ v.co).x) < 0.02 and ojo_z - 0.07 < (mw @ v.co).z < ojo_z - 0.01), key=lambda p: p.y)
print("NARIZ", nar)

# ---------- 6. el saco: saco de harina con la cara pintada con pintalabios (hecho por él a los 9 años) ----------
bpy.context.view_layer.update()
bvc = BVHTree.FromBMesh(_bm_mundo(body))
boca_z = nar.z - 0.036
menton_z = nar.z - 0.085
cuerda_z = menton_z - 0.05
eje = Vector((cab_c.x, cab_c.y + 0.005, 0))
C0 = Vector((cab_c.x, cab_c.y + 0.005, ojo_z - 0.01))
NF, NT = 168, 104
TMAX = math.radians(150)
def dirde(t, f):
    return Vector((math.sin(t) * math.sin(f), -math.sin(t) * math.cos(f), math.cos(t)))
# radio de la cabeza en cada dirección (rayo desde fuera hacia el centro)
R = np.zeros((NT + 1, NF)); 
for a in range(NT + 1):
    t = TMAX * a / NT
    for b in range(NF):
        f = 2 * math.pi * b / NF - math.pi
        d = dirde(t, f)
        lim = 0.2
        if d.z < -1e-3: lim = min(lim, (cuerda_z - 0.005 - C0.z) / d.z)
        hit = bvc.ray_cast(C0 + d * 0.22, -d, 0.22)
        R[a, b] = min((hit[0] - C0).length, lim) if hit[0] is not None else min(0.12, lim)
R0 = R.copy()
# la tela no sigue nariz ni labios: radio suavizado pero nunca dentro de la cabeza
from scipy.ndimage import gaussian_filter
Rs = R + 0.006
for it in range(12):
    Rs = gaussian_filter(Rs, sigma=(2.2, 2.6), mode=('nearest', 'wrap'))
    Rs = np.maximum(Rs, R0 + 0.007)
    Rs = np.minimum(Rs, np.where(R0 < 0.199, 0.2, Rs))
_gx, _gy = np.meshgrid(np.arange(NF) / NF * 6, np.arange(NT + 1) / NT * 4, indexing='xy')
nz = ruido(np.stack([_gx, _gy, np.zeros_like(_gx)], -1).astype(np.float32), 1.5, 31)
Rs += 0.006 + 0.012 * nz
bm = bmesh.new(); uvq = bm.loops.layers.uv.new("UV")
V = {}
for a in range(NT + 1):
    t = TMAX * a / NT
    for b in range(NF):
        f = 2 * math.pi * b / NF - math.pi
        p_ = C0 + dirde(t, f) * Rs[a, b]
        # esquinas del saco arriba a los lados
        lado = abs(math.sin(f))
        if t < 0.7:
            k = (0.7 - t) / 0.7
            p_.z += 0.018 * k * lado ** 4
            p_.x += math.copysign(0.015 * k * lado ** 4, math.sin(f))
        # bajo la barbilla el saco se cierra hacia el cuello (no se abre como una campana)
        if p_.z < menton_z + 0.01:
            hmax = 0.076 + 0.05 * np.clip((p_.z - cuerda_z) / (menton_z + 0.01 - cuerda_z), 0, 1)
            h = Vector((p_.x - eje.x, p_.y - eje.y, 0))
            if h.length > hmax: p_.x = eje.x + h.x / h.length * hmax; p_.y = eje.y + h.y / h.length * hmax
        # atado al cuello
        if p_.z < cuerda_z + 0.022:
            k = np.clip((cuerda_z + 0.022 - p_.z) / 0.022, 0, 1)
            h = Vector((p_.x - eje.x, p_.y - eje.y, 0)); hl = h.length
            nr = hl * (1 - k) + 0.074 * k
            if hl > 1e-6: p_.x = eje.x + h.x / hl * nr; p_.y = eje.y + h.y / hl * nr
            p_.z = max(p_.z, cuerda_z - 0.005)
        V[(a, b)] = bm.verts.new(p_)
# falda bajo la cuerda
for b in range(NF):
    f = 2 * math.pi * b / NF - math.pi
    h = Vector((math.sin(f), -math.cos(f), 0))
    V[(NT + 1, b)] = bm.verts.new(Vector((eje.x, eje.y, cuerda_z - 0.075 - 0.012 * math.sin(f * 7) ** 2)) + h * (0.11 + 0.012 * math.sin(f * 5)))
def pr_(pt):
    d = (pt - C0).normalized(); t = math.acos(max(-1, min(1, d.z))); f = math.atan2(d.x, -d.y); return t, f
huecos = [(pr_(ci), 0.17, 0.13), (pr_(cd), 0.17, 0.13), (pr_(Vector((cab_c.x, cab_c.y - 0.1, boca_z + 0.034))), 0.25, 0.1)]
def roto(t, f):
    for (tc, fc), wf, wt in huecos:
        df = (f - fc); dt = (t - tc)
        rag = 1 + 0.12 * math.sin(f * 37 + t * 23) + 0.07 * math.sin(f * 89 - t * 61)
        if (df / wf) ** 2 + (dt / wt) ** 2 < rag: return True
    return False
NTT = NT + 1
for a in range(NTT):
    for b in range(NF):
        b2 = (b + 1) % NF
        q = [V[(a, b)], V[(a, b2)], V[(a + 1, b2)], V[(a + 1, b)]]
        t = TMAX * (a + 0.5) / NT; f = 2 * math.pi * (b + 0.5) / NF - math.pi
        if a < NT and roto(t, f): continue
        try: fc = bm.faces.new(q)
        except ValueError: continue
        us = [(b / NF, 1 - a / NTT), ((b + 1) / NF, 1 - a / NTT), ((b + 1) / NF, 1 - (a + 1) / NTT), (b / NF, 1 - (a + 1) / NTT)]
        for l, uv in zip(fc.loops, us): l[uvq].uv = uv
# tapa de arriba
top = bm.verts.new(C0 + Vector((0, 0, Rs[0].mean() + 0.003)))
for b in range(NF):
    try:
        fc = bm.faces.new([top, V[(0, (b + 1) % NF)], V[(0, b)]])
        for l, uv in zip(fc.loops, [((b + 0.5) / NF, 1.0), ((b + 1) / NF, 1.0), (b / NF, 1.0)]): l[uvq].uv = uv
    except ValueError: pass
bmesh.ops.remove_doubles(bm, verts=[V[(a, 0)] for a in range(NTT + 1)] + [V[(a, NF - 1)] for a in range(NTT + 1)], dist=0.0)
for it in range(6):
    bv = [v for v in bm.verts if v.is_boundary and v.co.z > cuerda_z]
    nuevo = {}
    for v in bv:
        vec = [e.other_vert(v) for e in v.link_edges if e.is_boundary]
        if len(vec) == 2: nuevo[v] = v.co * 0.4 + (vec[0].co + vec[1].co) * 0.3
    for v, c_ in nuevo.items(): v.co = c_
bm.normal_update()
def uvde(pt):
    t, f = pr_(pt); return ((f + math.pi) / (2 * math.pi), 1 - (t / TMAX) * NT / NTT)
masc_me = bpy.data.meshes.new("saco"); bm.to_mesh(masc_me); bm.free()
for p in masc_me.polygons: p.use_smooth = True
masc = bpy.data.objects.new("saco", masc_me); bpy.context.scene.collection.objects.link(masc)
sol = masc.modifiers.new("grosor", 'SOLIDIFY'); sol.thickness = 0.0025; sol.offset = -1
bpy.context.view_layer.objects.active = masc; masc.select_set(True)
bpy.ops.object.modifier_apply(modifier="grosor")
# textura: arpillera sucia, sello de harina descolorido, cara de niño con pintalabios, sangre seca
TW, TH = 2048, 1024
base = np.zeros((TH, TW, 3), np.float32) + np.array([0.44, 0.36, 0.25])
xx, yy = np.meshgrid(np.arange(TW), np.arange(TH))
trama = (0.5 + 0.5 * np.sin(xx * 0.9)) * 0.5 + (0.5 + 0.5 * np.sin(yy * 0.9)) * 0.5
base *= (0.82 + 0.18 * trama)[..., None]
def _ri(sig, sem, w=TW, h=TH):
    r = np.random.default_rng(sem).random((h, w)).astype(np.float32)
    r = np.array(Image.fromarray((r * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(sig)), np.float32)
    return (r - r.min()) / max(r.max() - r.min(), 1)
hilo = np.random.default_rng(40).random((TH, TW)).astype(np.float32)
base *= (0.9 + 0.2 * hilo)[..., None]
mug = _ri(30, 41) * 0.6 + _ri(6, 42) * 0.4
mm = np.clip(mug - 0.45, 0, 1)[..., None] * 1.6
base = base * (1 - mm * 0.6) + np.array([0.16, 0.12, 0.08]) * mm * 0.6
abajo = np.clip((yy / TH - 0.55) * 2.5, 0, 1)[..., None]            # más sucio abajo (cuello y falda)
base = base * (1 - abajo * 0.45) + np.array([0.12, 0.09, 0.06]) * abajo * 0.45
img = Image.fromarray((np.clip(base, 0, 1) * 255).astype(np.uint8)); d = ImageDraw.Draw(img, "RGBA")
# sello de harina en la espalda (u = 0) muy gastado
try:
    from PIL import ImageFont
    fnt = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf", 90); fnt2 = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf", 46)
    for ox in (0, TW):
        d.text((ox - 230, 300), "HARINA", font=fnt, fill=(60, 50, 90, 70)); d.text((ox - 160, 410), "FLOR · 50 kg", font=fnt2, fill=(60, 50, 90, 60))
except Exception as e:
    print("fuente", e)
def p2(p):
    u, w = uvde(p); return u * TW, (1 - w) * TH
labial = (95, 0, 8)
def trazo(pts, ancho, alfa=210):
    for k in range(3):
        jit = [(x + random.uniform(-2, 2), y + random.uniform(-2, 2)) for x, y in pts]
        d.line(jit, fill=labial + (int(min(255, alfa * 1.2) * random.uniform(0.8, 1.0)),), width=ancho - k * 2, joint="curve")
for oc in (ci, cd):
    cx_, cy_ = p2(oc)
    pts = [(cx_ + math.cos(t) * 62 * (1 + 0.08 * math.sin(t * 3)), cy_ + math.sin(t) * 75) for t in np.linspace(0, 2 * math.pi * 1.08, 48)]
    trazo(pts, 14)
    for k in range(2):                                            # chorretones del pintalabios
        x0_ = cx_ + random.uniform(-60, 60); trazo([(x0_, cy_ + 90), (x0_ + random.uniform(-3, 3), cy_ + 90 + random.uniform(30, 90))], 6, 150)
mx, my = p2(Vector((cab_c.x, cab_c.y - 0.2, boca_z)))
mx = TW * 0.5
_, my = p2(Vector((cab_c.x, cab_c.y - 0.1, boca_z)))
AW, AH = 240, 120                                                # sonrisa enorme alrededor del agujero de la boca
sonr = [(mx + t * AW, my + 30 + AH * (1 - t * t)) for t in np.linspace(-1, 1, 40)]
trazo(sonr, 16)
trazo([(mx - AW, my + 30), (mx - AW - 30, my - 15)], 13); trazo([(mx + AW, my + 30), (mx + AW + 30, my - 15)], 13)
for t in np.linspace(-0.85, 0.85, 9):
    x_ = mx + t * AW; y_ = my + 30 + AH * (1 - t * t)
    trazo([(x_, y_ - 4), (x_, y_ - 45)], 6, 180)

# sangre seca: alrededor de la boca, chorreando hacia el cuello, salpicaduras
for k in range(9):
    x_ = mx + random.uniform(-80, 80); y0 = my + random.uniform(10, 60); L = random.uniform(80, 260); w_ = random.uniform(8, 20)
    d.line([(x_, y0), (x_ + random.uniform(-10, 10), y0 + L)], fill=(70, 8, 8, 200), width=int(w_))
    d.ellipse([x_ - w_ * 0.7, y0 + L - w_ * 0.7, x_ + w_ * 0.7, y0 + L + w_ * 0.7], fill=(60, 6, 6, 210))
for k in range(60):
    r = random.uniform(2, 14); x_ = random.uniform(0.25, 0.75) * TW; y_ = random.uniform(0.2, 0.95) * TH
    d.ellipse([x_ - r, y_ - r * random.uniform(0.6, 1.4), x_ + r, y_ + r], fill=(80, 10, 10, int(random.uniform(120, 220))))
mancha = Image.new("L", (TW, TH), 0); dm = ImageDraw.Draw(mancha)
dm.ellipse([mx - 120, my + 20, mx + 120, my + 260], fill=170)
mancha = mancha.filter(ImageFilter.GaussianBlur(40))
img = Image.composite(Image.new("RGB", (TW, TH), (58, 10, 8)), img, mancha.point(lambda v: int(v * 0.8)))
img = img.filter(ImageFilter.GaussianBlur(0.6))
img.transpose(Image.FLIP_TOP_BOTTOM).transpose(Image.FLIP_TOP_BOTTOM).save(os.path.join(OUT, "damian_saco.png"))
mat = bpy.data.materials.new("saco"); mat.use_nodes = True
bsdf = mat.node_tree.nodes["Principled BSDF"]; tn = mat.node_tree.nodes.new("ShaderNodeTexImage")
tn.image = bpy.data.images.load(os.path.join(OUT, "damian_saco.png")); tn.image.pack()
mat.node_tree.links.new(tn.outputs[0], bsdf.inputs["Base Color"]); bsdf.inputs["Roughness"].default_value = 0.95
masc_me.materials.append(mat)
# cuerda atada al cuello
bpy.ops.mesh.primitive_torus_add(major_radius=0.093, minor_radius=0.009, major_segments=36, minor_segments=8, location=(eje.x, eje.y, cuerda_z))
cor = bpy.context.active_object; cor.name = "cuerda"
mc = bpy.data.materials.new("cuerda"); mc.use_nodes = True; mc.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.09, 0.065, 0.04, 1)
mc.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.9
cor.data.materials.append(mc)
# ---------- 7. pelo largo y grasiento a los lados y atrás (calvo arriba) ----------
ps, pl = 256, 1024
hp = Image.new("RGBA", (ps, pl), (0, 0, 0, 0)); d = ImageDraw.Draw(hp)
for k in range(260):
    x0_ = RNG.uniform(0, ps); xw = x0_; pts = []
    for yy in range(0, pl, 16):
        xw += RNG.normal(0, 1.0); pts.append((xw, yy))
    largo = int(RNG.uniform(0.55, 1.0) * len(pts))
    tono = int(RNG.uniform(10, 40))
    d.line(pts[:largo], fill=(tono, tono - 4 if tono > 4 else 0, tono - 6 if tono > 6 else 0, int(RNG.uniform(140, 255))), width=int(RNG.integers(1, 3)))
hp = hp.filter(ImageFilter.GaussianBlur(0.6)); hp.save(os.path.join(OUT, "damian_pelo.png"))
mp = bpy.data.materials.new("pelo"); mp.use_nodes = True; nt = mp.node_tree
bp = nt.nodes["Principled BSDF"]; tp = nt.nodes.new("ShaderNodeTexImage"); tp.image = bpy.data.images.load(os.path.join(OUT, "damian_pelo.png")); tp.image.pack()
nt.links.new(tp.outputs[0], bp.inputs["Base Color"]); nt.links.new(tp.outputs[1], bp.inputs["Alpha"])
bp.inputs["Roughness"].default_value = 0.55
mp.blend_method = 'HASHED' if hasattr(mp, "blend_method") else None
pme = bpy.data.meshes.new("pelo"); bmh = bmesh.new()
uvh = bmh.loops.layers.uv.new("UV")
z_ini = cuerda_z - 0.035
for capa in range(4):
    for k in range(75):
        ang = math.radians(RNG.uniform(75, 285))          # 0 = de frente: deja la frente y la cara libres
        d3 = Vector((math.sin(ang), -math.cos(ang), 0))   # 0 = de frente (el frente es -Y)
        p0 = Vector((cab_c.x, cab_c.y, z_ini + RNG.uniform(-0.01, 0.025) - capa * 0.012))
        hit = bvb.ray_cast(p0 + d3 * 0.3, -d3)
        if hit[0] is None: continue
        base = hit[0] + hit[1] * (0.004 + capa * 0.006)
        out = Vector((hit[1].x, hit[1].y, 0)).normalized()
        L = RNG.uniform(0.16, 0.3); w = RNG.uniform(0.01, 0.02); onda = RNG.uniform(0.004, 0.012); fase = RNG.uniform(0, 6.28)
        tang = out.cross(Vector((0, 0, 1))).normalized()
        segs = 7; prev = None
        for s in range(segs + 1):
            tt = s / segs
            p = base + out * (0.012 + 0.03 * tt) * (1 + capa * 0.3) + Vector((0, 0, -L * tt)) + tang * math.sin(tt * 9 + fase) * onda * tt
            # que no atraviese la cabeza ni el cuello
            loc, nrm, idx, dd = bvb.find_nearest(p)
            if loc is not None and (p - loc).dot(nrm) < 0.006: p = loc + nrm * (0.006 + capa * 0.004)
            a_ = bmh.verts.new(p - tang * w * (1 - 0.4 * tt)); b_ = bmh.verts.new(p + tang * w * (1 - 0.4 * tt))
            if prev:
                f = bmh.faces.new((prev[0], prev[1], b_, a_))
                u0 = RNG.uniform(0, 0.6)
                for l, uv in zip(f.loops, ((u0, 1 - (s - 1) / segs), (u0 + 0.4, 1 - (s - 1) / segs), (u0 + 0.4, 1 - tt), (u0, 1 - tt))):
                    l[uvh].uv = uv
            prev = (a_, b_)
bmh.to_mesh(pme); bmh.free()
pelo = bpy.data.objects.new("pelo", pme); bpy.context.scene.collection.objects.link(pelo); pme.materials.append(mp)
pelo.hide_render = True; pelo.hide_viewport = True
print("pelo: caras", len(pme.polygons))

# ---------- 8. pesos de los añadidos (cabeza; pelo baja al cuello) ----------
def pesar(o, grupos):
    o.parent = rig
    for g in grupos: o.vertex_groups.new(name=g)
    am = o.modifiers.new("Armature", 'ARMATURE'); am.object = rig
    return o
for o in (masc, cor):
    pesar(o, ["head"]); o.vertex_groups["head"].add(list(range(len(o.data.vertices))), 1.0, 'REPLACE')
pesar(pelo, ["head", "neck_01"])
for v in pelo.data.vertices:
    t_ = np.clip((z_ini - v.co.z) / 0.25, 0, 1)
    pelo.vertex_groups["head"].add([v.index], 1 - 0.6 * t_, 'REPLACE'); pelo.vertex_groups["neck_01"].add([v.index], 0.6 * t_, 'REPLACE')

bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "damian.blend"))
print("DETALLAR OK")
