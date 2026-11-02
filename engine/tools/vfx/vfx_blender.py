"""Efectos de poderes de Chronos renderizados en Blender (fotograma a fotograma).
Fondo negro para mezcla aditiva en el motor. Uso: python3 vfx_blender.py <salida> [efecto,...]"""
import sys, os, math, random
import bpy, bmesh
from mathutils import Vector

OUT = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else "vfx_out")
ONLY = sys.argv[2].split(",") if len(sys.argv) > 2 else None
os.makedirs(OUT, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.engine = "CYCLES"
sc.cycles.device = "CPU"
sc.cycles.samples = 12
sc.cycles.use_denoising = False
sc.cycles.max_bounces = 0
sc.view_settings.view_transform = "Standard"
sc.render.film_transparent = False
w = bpy.data.worlds.new("negro"); sc.world = w
try:
    w.use_nodes = True
except Exception:
    pass
next(n for n in w.node_tree.nodes if n.type == "BACKGROUND").inputs["Color"].default_value = (0, 0, 0, 1)

cd = bpy.data.cameras.new("cam"); cd.type = "ORTHO"
cam = bpy.data.objects.new("cam", cd); sc.collection.objects.link(cam)
cam.location = (0, -5, 0); cam.rotation_euler = (math.pi / 2, 0, 0)
sc.camera = cam


def lin(c):
    return tuple((v / 255.0) ** 2.2 for v in c)


# ---------------------------------------------------------------- material de brillo
def glow_mat(name, stops, noise=4.0, edge=1.6):
    """Emisión con perfil a lo ancho (v), forma a lo largo (u) y ruido animable."""
    m = bpy.data.materials.new(name)
    try:
        m.use_nodes = True
    except Exception:
        pass
    nt = m.node_tree; N = nt.nodes; L = nt.links
    for n in list(N):
        N.remove(n)
    out = N.new("ShaderNodeOutputMaterial")
    em = N.new("ShaderNodeEmission")
    tc = N.new("ShaderNodeTexCoord")
    sep = N.new("ShaderNodeSeparateXYZ")
    L.new(tc.outputs["UV"], sep.inputs[0])
    # perfil transversal: 1 en el centro, 0 en los bordes
    a = N.new("ShaderNodeMath"); a.operation = "MULTIPLY_ADD"; a.inputs[1].default_value = 2; a.inputs[2].default_value = -1
    L.new(sep.outputs["Y"], a.inputs[0])
    ab = N.new("ShaderNodeMath"); ab.operation = "ABSOLUTE"; L.new(a.outputs[0], ab.inputs[0])
    inv = N.new("ShaderNodeMath"); inv.operation = "SUBTRACT"; inv.inputs[0].default_value = 1
    L.new(ab.outputs[0], inv.inputs[1])
    pw = N.new("ShaderNodeMath"); pw.operation = "POWER"; pw.inputs[1].default_value = edge
    L.new(inv.outputs[0], pw.inputs[0])
    # ruido animado (desplazamiento en círculo para bucles)
    mp = N.new("ShaderNodeMapping"); mp.name = "mov"
    L.new(tc.outputs["Object"], mp.inputs["Vector"])
    nz = N.new("ShaderNodeTexNoise"); nz.inputs["Scale"].default_value = noise; nz.inputs["Detail"].default_value = 6
    L.new(mp.outputs["Vector"], nz.inputs["Vector"])
    nzm = N.new("ShaderNodeMath"); nzm.operation = "MULTIPLY_ADD"; nzm.inputs[1].default_value = 1.1; nzm.inputs[2].default_value = 0.45
    L.new(nz.outputs["Fac"], nzm.inputs[0])
    mix = N.new("ShaderNodeMath"); mix.operation = "MULTIPLY"; mix.use_clamp = True
    L.new(pw.outputs[0], mix.inputs[0]); L.new(nzm.outputs[0], mix.inputs[1])
    # forma a lo largo (u): atributo de vértice "k" (0..1) multiplicado
    at = N.new("ShaderNodeAttribute"); at.attribute_name = "k"
    mk = N.new("ShaderNodeMath"); mk.operation = "MULTIPLY"; mk.use_clamp = True
    L.new(mix.outputs[0], mk.inputs[0]); L.new(at.outputs["Fac"], mk.inputs[1])
    ramp = N.new("ShaderNodeValToRGB"); cr = ramp.color_ramp
    cr.elements[0].position = 0.0; cr.elements[0].color = (0, 0, 0, 1)
    cr.elements[1].position = 1.0; cr.elements[1].color = (*lin(stops[-1][1]), 1)
    for pos, col in stops[:-1]:
        e = cr.elements.new(pos); e.color = (*lin(col), 1)
    L.new(mk.outputs[0], ramp.inputs["Fac"])
    st = N.new("ShaderNodeValue"); st.name = "fade"; st.outputs[0].default_value = 1.0
    sm = N.new("ShaderNodeMath"); sm.operation = "MULTIPLY"; sm.inputs[1].default_value = 4.0
    L.new(st.outputs[0], sm.inputs[0])
    L.new(ramp.outputs["Color"], em.inputs["Color"]); L.new(sm.outputs[0], em.inputs["Strength"])
    L.new(em.outputs[0], out.inputs["Surface"])
    return m


def set_mat(m, fade=1.0, phase=0.0, r=0.6):
    m.node_tree.nodes["fade"].outputs[0].default_value = fade
    mv = m.node_tree.nodes["mov"]
    mv.inputs["Location"].default_value = (math.cos(phase) * r, math.sin(phase) * r, phase * 0.05)


GOLD = [(0.25, (90, 40, 0)), (0.55, (255, 150, 30)), (0.8, (255, 220, 120)), (1.0, (255, 252, 235))]
CYAN = [(0.25, (0, 40, 90)), (0.55, (40, 170, 255)), (0.8, (150, 235, 255)), (1.0, (245, 255, 255))]
AMBER = [(0.25, (80, 20, 0)), (0.55, (255, 110, 20)), (0.8, (255, 190, 90)), (1.0, (255, 245, 220))]
VIOLET = [(0.25, (40, 10, 80)), (0.55, (140, 110, 255)), (0.8, (200, 190, 255)), (1.0, (250, 248, 255))]


# ---------------------------------------------------------------- geometría
class Geo:
    def __init__(self):
        self.bm = bmesh.new(); self.uv = self.bm.loops.layers.uv.new("UVMap")
        self.k = []

    def strip(self, pts, widths, ks, normals=None):
        """Tira en el plano XZ: pts=[(x,z)], ancho y opacidad por punto."""
        rows = []
        n = len(pts)
        for i, (x, z) in enumerate(pts):
            if normals:
                nx, nz = normals[i]
            else:
                a = pts[max(0, i - 1)]; b = pts[min(n - 1, i + 1)]
                dx, dz = b[0] - a[0], b[1] - a[1]; l = math.hypot(dx, dz) or 1
                nx, nz = -dz / l, dx / l
            h = widths[i] / 2
            rows.append((self.bm.verts.new((x - nx * h, 0, z - nz * h)), self.bm.verts.new((x + nx * h, 0, z + nz * h))))
            self.k += [ks[i], ks[i]]
        for i in range(n - 1):
            f = self.bm.faces.new([rows[i][0], rows[i + 1][0], rows[i + 1][1], rows[i][1]])
            u0, u1 = i / (n - 1), (i + 1) / (n - 1)
            for l, uv in zip(f.loops, [(u0, 0), (u1, 0), (u1, 1), (u0, 1)]):
                l[self.uv].uv = uv

    def blob(self, x, z, r, k=1.0, seg=10):
        """Chispa: disco con brillo radial (uv.v = 0 en el borde, 1 en el centro -> perfil)."""
        c = self.bm.verts.new((x, 0, z)); self.k.append(k)
        ring = []
        for i in range(seg):
            a = 2 * math.pi * i / seg
            ring.append(self.bm.verts.new((x + r * math.cos(a), 0, z + r * math.sin(a)))); self.k.append(k)
        for i in range(seg):
            f = self.bm.faces.new([c, ring[i], ring[(i + 1) % seg]])
            for l, uv in zip(f.loops, [(0.5, 0.5), (0.5, 0.0), (0.5, 0.0)]):
                l[self.uv].uv = uv

    def build(self, mat):
        me = bpy.data.meshes.new("fx"); self.bm.to_mesh(me); self.bm.free()
        attr = me.attributes.new("k", "FLOAT", "POINT")
        for i, v in enumerate(self.k):
            attr.data[i].value = v
        me.materials.append(mat)
        o = bpy.data.objects.new("fx", me); sc.collection.objects.link(o)
        return o


def clear():
    for o in list(sc.collection.objects):
        if o.type == "MESH":
            bpy.data.objects.remove(o, do_unlink=True)


def arc_pts(cx, cz, rx, rz, a0, a1, n):
    return [(cx + rx * math.cos(math.radians(a0 + (a1 - a0) * i / (n - 1))),
             cz + rz * math.sin(math.radians(a0 + (a1 - a0) * i / (n - 1)))) for i in range(n)]


def ease(t):
    t = max(0.0, min(1.0, t)); return 1 - (1 - t) ** 3


def render(path, res):
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)


# ---------------------------------------------------------------- efectos
def fx_slash(f, n, M):
    """Media luna de luz (Espada de Luz / combo)."""
    g = Geo()
    head = -110 + 235 * ease(f / 4.5)
    tail = -110 + 235 * ease((f - 2.2) / 6.5)
    pts = arc_pts(0, 0, 0.82, 0.82, tail, head, 40)
    u = [i / 39 for i in range(40)]
    g.strip(pts, [0.04 + 0.30 * x ** 0.8 for x in u], [x ** 0.6 for x in u])
    pts2 = arc_pts(0, 0, 0.66, 0.66, tail + 15, head - 5, 30)
    u2 = [i / 29 for i in range(30)]
    g.strip(pts2, [0.02 + 0.12 * x for x in u2], [0.6 * x for x in u2])
    r = random.Random(f * 7)
    for _ in range(8 + f):
        a = math.radians(r.uniform(tail, head)); rr = 0.82 + r.uniform(-0.1, 0.25) * (1 + f * 0.1)
        g.blob(rr * math.cos(a), rr * math.sin(a), r.uniform(0.012, 0.03), 0.9)
    g.build(M)
    return max(0.0, 1 - max(0, f - 6) / 4.0)


def fx_wave(f, n, M):
    """Onda de luz del Golpe Cargado (bucle)."""
    g = Geo()
    for k, (dx, sc_, op) in enumerate([(0.0, 1.0, 1.0), (-0.28, 0.82, 0.55), (-0.5, 0.66, 0.3)]):
        pts = arc_pts(-0.45 + dx, 0, 0.62 * sc_, 0.85 * sc_, -72, 72, 40)
        u = [i / 39 for i in range(40)]
        g.strip(pts, [0.05 + 0.28 * sc_ * math.sin(math.pi * x) ** 0.7 for x in u],
                [op * math.sin(math.pi * x) ** 0.5 for x in u])
    r = random.Random(f)
    for _ in range(14):
        x = r.uniform(-0.9, 0.1); z = r.uniform(-0.6, 0.6)
        g.blob(x - (f / n) * 0.3, z, r.uniform(0.01, 0.025), 0.8)
    g.build(M)
    return 1.0


def fx_impact(f, n, M):
    """Impacto de golpe: estrella, anillo y chispas."""
    g = Geo(); r = random.Random(3)
    t = f / (n - 1)
    L = 0.9 * ease(f / 2.0) * (1 - 0.6 * t)
    for i in range(9):
        a = math.radians(i * 40 + r.uniform(-12, 12)); l = L * r.uniform(0.55, 1.1)
        pts = [(0.05 * math.cos(a) + l * math.cos(a) * s, 0.05 * math.sin(a) + l * math.sin(a) * s) for s in (0, 0.5, 1)]
        g.strip(pts, [0.16 * (1 - t), 0.07 * (1 - t), 0.005], [1, 0.8, 0.0])
    rad = 0.15 + 0.85 * ease(t * 1.4)
    g.strip(arc_pts(0, 0, rad, rad, 0, 360, 60), [0.12 * (1 - t) ** 1.5 + 0.01] * 60, [0.8 * (1 - t)] * 60)
    for i in range(16):
        a = r.uniform(0, 6.28); v = r.uniform(0.6, 1.3)
        x = math.cos(a) * v * t * 1.1; z = math.sin(a) * v * t * 1.1 - 0.5 * t * t
        g.blob(x, z, 0.025 * (1 - t) + 0.006, 1.0)
    g.blob(0, 0, 0.35 * (1 - t) ** 2 + 0.01, 1.0, seg=20)
    g.build(M)
    return 1.0


def fx_quake(f, n, M):
    """Golpe Sísmico: ondas a ras de suelo, columna de luz y chispas."""
    g = Geo(); r = random.Random(5)
    t = f / (n - 1)
    gz = -0.55
    for k in range(3):
        tt = max(0.0, t * 1.25 - k * 0.12)
        if tt <= 0:
            continue
        rx = 0.15 + 1.85 * ease(tt); rz = 0.08 + 0.45 * ease(tt) * (1 - tt * 0.6)
        pts = arc_pts(0, gz, rx, rz, 0, 180, 50)
        u = [i / 49 for i in range(50)]
        g.strip(pts, [(0.26 * (1 - tt) + 0.03) * (0.4 + 0.6 * math.sin(math.pi * x)) for x in u], [(1 - tt) * (1 - 0.5 * k / 2)] * 50)
    hp = 1.9 * ease(t * 3) * (1 - t * 0.8)
    g.strip([(0, gz), (0, gz + hp * 0.5), (0, gz + hp)], [0.9 * (1 - t), 0.5 * (1 - t), 0.04], [1, 0.75, 0])
    for i in range(26):
        x0 = r.uniform(-1.6, 1.6) * min(1, t * 2); vz = r.uniform(0.6, 1.6)
        z = gz + vz * t * 1.3 - 1.8 * t * t
        if z > gz:
            g.blob(x0 * 1.05, z, 0.035 + 0.03 * (1 - t), 0.95)
    g.blob(0, gz, 0.95 * (1 - t) ** 2 + 0.02, 0.95, seg=24)
    g.build(M)
    return 1.0


def fx_parry(f, n, M):
    """Parada Perfecta: esfera de reloj que aparece, gira y estalla."""
    g = Geo(); t = f / (n - 1); r = random.Random(9)
    if t < 0.6:
        s = ease(t / 0.25)
        R = 0.7 * s
        g.strip(arc_pts(0, 0, R, R, 0, 360, 72), [0.07] * 72, [1.0] * 72)
        g.strip(arc_pts(0, 0, R * 0.82, R * 0.82, 0, 360, 72), [0.025] * 72, [0.6] * 72)
        rot = t * 220
        for i in range(12):
            a = math.radians(i * 30 + rot); l0, l1 = R * 0.62, R * (0.78 if i % 3 else 0.7)
            g.strip([(l0 * math.cos(a), l0 * math.sin(a)), (l1 * math.cos(a), l1 * math.sin(a))], [0.05, 0.05], [0.9, 0.9])
        for ang, ln in ((90 - rot * 2, 0.5), (90 - rot * 0.4, 0.34)):
            a = math.radians(ang)
            g.strip([(0, 0), (R * ln * math.cos(a), R * ln * math.sin(a))], [0.06, 0.02], [1, 0.9])
        g.blob(0, 0, 0.08 * s + 0.01, 1)
    else:
        tt = (t - 0.6) / 0.4
        for i in range(10):
            a0 = i * 36 + r.uniform(-5, 5); d = 0.7 + 0.8 * ease(tt)
            mid = math.radians(a0 + 15)
            pts = arc_pts(math.cos(mid) * (d - 0.7), math.sin(mid) * (d - 0.7), 0.7, 0.7, a0, a0 + 28, 10)
            g.strip(pts, [0.07 * (1 - tt)] * 10, [1 - tt] * 10)
        g.blob(0, 0, 0.9 * ease(tt) * (1 - tt) + 0.01, 0.7, seg=24)
    g.build(M)
    return 1.0


def fx_rewind(f, n, M):
    """Segunda Oportunidad: espirales de reloj girando hacia atrás (bucle)."""
    g = Geo(); ph = 2 * math.pi * f / n
    for k in range(3):
        base = math.degrees(ph) + k * 120
        R0 = 0.82 - k * 0.04
        pts = []
        for i in range(36):
            u = i / 35
            a = math.radians(base + 200 * u); rr = R0 * (0.45 + 0.55 * u)
            pts.append((rr * math.cos(a), rr * math.sin(a)))
        u = [i / 35 for i in range(36)]
        g.strip(pts, [0.02 + 0.09 * x for x in u], [x ** 0.7 for x in u])
        hx, hz = pts[-1]; a = math.radians(base + 200 + 90)
        tip = (hx + 0.12 * math.cos(a), hz + 0.12 * math.sin(a))
        g.strip([(hx - 0.08 * math.cos(a), hz - 0.08 * math.sin(a)), tip], [0.2, 0.01], [1, 0.7])
    for i in range(12):
        a = math.radians(i * 30 - math.degrees(ph) * 0.5)
        g.strip([(0.93 * math.cos(a), 0.93 * math.sin(a)), (1.0 * math.cos(a), 1.0 * math.sin(a))], [0.035, 0.035], [0.7, 0.7])
    g.build(M)
    return 1.0


def fx_charge(f, n, M):
    """Carga del golpe: llamas de energía que suben en espiral (bucle)."""
    g = Geo(); ph = 2 * math.pi * f / n; r = random.Random(2)
    for i in range(7):
        a = ph + i * 2 * math.pi / 7
        x0 = 0.45 * math.cos(a); depth = math.sin(a)
        h = 0.9 + 0.3 * math.sin(ph * 2 + i)
        pts = [(x0 * (1 - s * 0.7) + 0.06 * math.sin(s * 6 + ph * 2 + i), -0.75 + h * s) for s in [j / 11 for j in range(12)]]
        g.strip(pts, [0.16 * (1 - s) ** 0.7 + 0.01 for s in [j / 11 for j in range(12)]],
                [(0.55 + 0.45 * depth * 0.5) * (1 - s) ** 0.5 for s in [j / 11 for j in range(12)]])
    for i in range(12):
        s = ((f / n) + i / 12) % 1.0
        a = i * 2.4 + ph
        g.blob(0.5 * (1 - s) * math.cos(a), -0.7 + 1.4 * s, 0.025 * (1 - s) + 0.008, 1 - s)
    g.blob(0, -0.2, 0.28 + 0.03 * math.sin(ph * 2), 0.55, seg=20)
    g.build(M)
    return 1.0


def fx_dash(f, n, M):
    """Dash Fantasma: estelas horizontales."""
    g = Geo(); r = random.Random(4); t = f / (n - 1)
    for i in range(14):
        z = r.uniform(-0.55, 0.55); L = r.uniform(1.2, 2.6)
        x1 = -1.4 + 2.9 * ease(t * 1.4 + r.uniform(0, 0.15)); x0 = x1 - L * (1 - t * 0.5)
        pts = [(x0 + (x1 - x0) * s, z) for s in (0, 0.35, 0.7, 1)]
        wz = 1 - abs(z) * 0.9
        g.strip(pts, [0.01, 0.12 * wz, 0.22 * wz, 0.26 * wz], [0, 0.4 * (1 - t), 0.85 * (1 - t), 1 - t])
    hx = -1.4 + 2.9 * ease(t * 1.4)
    g.blob(hx, 0, 0.45 * (1 - t) + 0.02, 0.8, seg=20)
    for i in range(10):
        g.blob(hx - r.uniform(0.2, 2.0), r.uniform(-0.5, 0.5), 0.03 * (1 - t) + 0.008, 0.9)
    g.build(M)
    return 1.0


EFFECTS = {
    # nombre: (función, fotogramas, resolución, escala ortográfica, colores, ruido)
    "media_luna": (fx_slash, 11, (256, 256), 2.3, GOLD, 5),
    "onda_luz": (fx_wave, 8, (256, 256), 2.2, GOLD, 4),
    "impacto": (fx_impact, 8, (192, 192), 2.4, [(0.25, (90, 50, 10)), (0.55, (255, 200, 90)), (0.85, (255, 245, 210)), (1.0, (255, 255, 255))], 6),
    "sismo": (fx_quake, 12, (384, 192), 4.2, AMBER, 4),
    "parada": (fx_parry, 10, (224, 224), 2.1, CYAN, 3),
    "rebobinar": (fx_rewind, 12, (224, 224), 2.3, CYAN, 3),
    "carga": (fx_charge, 12, (192, 192), 2.0, GOLD, 5),
    "dash_fantasma": (fx_dash, 8, (384, 160), 3.6, VIOLET, 3),
}

for name, (fn, n, res, osc, stops, nzs) in EFFECTS.items():
    if ONLY and name not in ONLY:
        continue
    M = glow_mat(name, stops, noise=nzs)
    cd.ortho_scale = osc
    os.makedirs(os.path.join(OUT, name), exist_ok=True)
    for f in range(n):
        clear()
        fade = fn(f, n, M)
        set_mat(M, fade=fade, phase=2 * math.pi * f / n)
        render(os.path.join(OUT, name, f"{f:02d}.png"), res)
    print("efecto", name, n)
