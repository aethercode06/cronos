# Brazos de Sofía en primera persona, con esqueleto y animaciones.
# Brazos: «FPS Arms with Advanced Rig» (bionic_leaf, CC-BY); linterna: «Retro Style Flashlight» (CC-BY).
# Se construye en el espacio de la cámara (Blender: cámara en el origen mirando a +Y, arriba +Z, derecha +X;
# en Godot queda mirando a -Z). Mano derecha: sujeta la linterna. Mano izquierda: interacciones.
# Uso: python3 brazos_fp.py -- brazos.glb linterna.glb salida_prefijo [exportar=ruta.glb] [ver=1] [accion=nombre]
import bpy, sys, math, re
from mathutils import Vector, Matrix, Quaternion
a = sys.argv[sys.argv.index('--') + 1:]
brazos, linterna, out = a[0], a[1], a[2]
P = dict(x.split('=', 1) for x in a[3:])
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
sc.render.fps = 30

# ---------------------------------------------------------------- importar y limpiar
bpy.ops.import_scene.gltf(filepath=brazos)
for o in list(bpy.data.objects):
    if o.name == 'Icosphere':
        bpy.data.objects.remove(o)
arm = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
piel = [o for o in bpy.data.objects if o.type == 'MESH'][0]
for ac in list(bpy.data.actions):
    bpy.data.actions.remove(ac)
if arm.animation_data:
    arm.animation_data_clear()
# todo a metros: un vacío «brazos» por encima de todo
top = arm
while top.parent:
    top = top.parent
ESC = float(P.get('esc', 0.0092))  # la mano de Sofía, algo más pequeña que la del modelo (el modelo va en cm)
bpy.context.view_layer.update()
top.matrix_world = Matrix.Diagonal((ESC, ESC, ESC, 1)) @ top.matrix_world
top.name = 'brazos'
bpy.context.view_layer.update()

def limpio(n):
    return re.sub(r'_\d+$', '', n)

bpy.context.view_layer.objects.active = arm
for o in bpy.context.selected_objects:
    o.select_set(False)
arm.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
eb = arm.data.edit_bones
for b in list(eb):
    if not (b.name.startswith('def.') or b.name.startswith('root')):
        eb.remove(b)
for b in eb:
    b.name = limpio(b.name)
# en el modelo cada brazo está guardado 100 veces más pequeño alrededor de su hombro (lo arreglaba la animación
# en el hueso raíz): se agranda el esqueleto y la malla
K = 100.0
HOMBRO = {'r': eb['def.arm.upper.r'].head.copy(), 'l': eb['def.arm.upper.l'].head.copy()}
for b in eb:
    if b.name.startswith('root'):
        continue
    sd = 'r' if b.name.endswith('.r') else 'l'
    hh = HOMBRO[sd]
    t = hh + (b.tail - hh) * K
    b.head = hh + (b.head - hh) * K
    b.tail = t
# hueso de la linterna (se coloca después): hijo de la mano derecha
bl = eb.new('linterna')
bl.head = eb['def.hand.r'].head.copy()
bl.tail = bl.head + Vector((0, 0, 1.0))
bl.parent = eb['def.hand.r']
bl.use_deform = True
bpy.ops.object.mode_set(mode='OBJECT')
Mp = arm.matrix_world.inverted() @ piel.matrix_world  # malla -> armadura
Mi = Mp.inverted()
for v in piel.data.vertices:
    q = Mp @ v.co
    hh = HOMBRO['r'] if q.x < 0 else HOMBRO['l']
    v.co = Mi @ (hh + (q - hh) * K)
pb = arm.pose.bones
for p in pb:
    p.rotation_mode = 'QUATERNION'
    p.matrix_basis = Matrix.Identity(4)
# la animación importada tenía girado y escalado ×100 el hueso raíz que hemos quitado: se compensa en el objeto
bpy.context.view_layer.update()
top.matrix_world = Matrix.Rotation(math.pi, 4, 'Z') @ Matrix.Rotation(math.radians(float(P.get('rx', 90))), 4, 'X') @ Matrix.Diagonal((0.01, 0.01, 0.01, 1)) @ top.matrix_world

def up():
    bpy.context.view_layer.update()

AW = lambda: arm.matrix_world
def hw(n):
    return AW() @ pb[n].head
def tw(n):
    return AW() @ pb[n].tail

# hombros en el espacio de la cámara (m): el ojo en el origen
S = {'r': Vector((0.17, -0.06, -0.24)), 'l': Vector((-0.17, -0.06, -0.24))}
# en reposo los hombros del modelo están a ±19 y a 179 de alto (unidades del modelo)
up()
centro_hombros = (hw('def.arm.upper.r') + hw('def.arm.upper.l')) / 2
top.matrix_world = Matrix.Translation(Vector((0, -0.06, -0.24)) - centro_hombros) @ top.matrix_world
up()
REST = {}
for p in pb:
    REST[p.name] = p.matrix.copy()

def reset():
    for p in pb:
        p.matrix_basis = Matrix.Identity(4)
    up()

def rot_world(n, R, piv):
    """gira el hueso n (y sus hijos) con la rotación R (3x3, espacio del mundo) alrededor de piv"""
    aw = AW()
    M = Matrix.Translation(piv) @ R.to_4x4() @ Matrix.Translation(-piv)
    pb[n].matrix = aw.inverted() @ M @ aw @ pb[n].matrix
    up()

def alinear(n, desde, hacia, piv):
    q = desde.normalized().rotation_difference(hacia.normalized())
    rot_world(n, q.to_matrix(), piv)

def brazo(lado, muneca, codo_dir, adelante, palma, giro_antebrazo=0.5):
    """IK de dos huesos + orientación de la mano.
    muneca: punto de la muñeca; codo_dir: hacia dónde sale el codo; adelante: hacia dónde apuntan los dedos;
    palma: hacia dónde mira la palma."""
    s = lado
    hom = hw(f'def.arm.upper.{s}')
    L1 = (tw(f'def.arm.lower.{s}') - hom).length
    L2 = (tw(f'def.forearm.lower.{s}') - hw(f'def.forearm.upper.{s}')).length
    d = muneca - hom
    D = min(d.length, (L1 + L2) * 0.995)
    dn = d.normalized()
    x = (L1 * L1 - L2 * L2 + D * D) / (2 * D)
    h = math.sqrt(max(L1 * L1 - x * x, 0.0))
    pole = (codo_dir - dn * codo_dir.dot(dn)).normalized()
    E = hom + dn * x + pole * h
    W = hom + dn * D
    # brazo
    alinear(f'def.arm.upper.{s}', tw(f'def.arm.lower.{s}') - hom, E - hom, hom)
    # antebrazo
    e = hw(f'def.forearm.upper.{s}')
    alinear(f'def.forearm.upper.{s}', tw(f'def.forearm.lower.{s}') - e, W - e, e)
    # mano: marco actual (dedos, palma) -> deseado
    def marco():
        w = hw(f'def.hand.{s}')
        f = ((hw(f'def.f.middle.03.{s}') + hw(f'def.f.ring.03.{s}')) / 2 - w).normalized()
        k = (hw(f'def.f.index.03.{s}') - hw(f'def.f.pinky.03.{s}')).normalized()
        n = f.cross(k).normalized()
        if s == 'r':
            n = -n
        k = n.cross(f).normalized()
        return Matrix((f, k, n)).transposed()
    f2 = adelante.normalized()
    n2 = (palma - f2 * palma.dot(f2)).normalized()
    k2 = n2.cross(f2).normalized()
    Md = Matrix((f2, k2, n2)).transposed()
    R = Md @ marco().inverted()
    # parte del giro se lo lleva el antebrazo (si no, la muñeca se retuerce como un caramelo)
    ax = (W - e).normalized()
    q = R.to_quaternion()
    tw_ang = 2 * math.atan2(Vector((q.x, q.y, q.z)).dot(ax), q.w)
    if giro_antebrazo:
        rot_world(f'def.forearm.lower.{s}', Quaternion(ax, tw_ang * giro_antebrazo).to_matrix(), hw(f'def.forearm.lower.{s}'))
    R = Md @ marco().inverted()
    rot_world(f'def.hand.{s}', R, hw(f'def.hand.{s}'))

DEDOS = ('index', 'middle', 'ring', 'pinky')
def dedos(lado, curl, pulgar=(0.3, 0.3, 0.3), abre=0.0, cada=None):
    """curl: (base, medio, punta) en radianes para los cuatro dedos; cada: {dedo: factor}"""
    s = lado
    sg = 1 if s == 'r' else 1
    for i, d in enumerate(DEDOS):
        fac = (cada or {}).get(d, 1.0)
        for j, seg in enumerate(('03', '02', '01')):
            p = pb[f'def.f.{d}.{seg}.{s}']
            ang = curl[j] * fac
            q = Quaternion(Vector((1, 0, 0)), ang * float(P.get('sx', 1)))
            if j == 0 and abre:
                q = Quaternion(Vector((0, 0, 1)), (i - 1.5) * abre * (1 if s == 'r' else -1)) @ q
            p.rotation_quaternion = q
    for j, seg in enumerate(('03', '02', '01')):
        p = pb[f'def.f.thumb.{seg}.{s}']
        p.rotation_quaternion = Quaternion(Vector((1, 0, 0)), pulgar[j] * float(P.get('sx', 1)))
    up()

# ---------------------------------------------------------------- linterna
antes = set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=linterna)
lin = [o for o in bpy.data.objects if o not in antes and o.type == 'MESH']
for o in list(bpy.data.objects):
    if o not in antes and o.type == 'EMPTY':
        for c in o.children:
            mw = c.matrix_world.copy(); c.parent = None; c.matrix_world = mw
for o in list(bpy.data.objects):
    if o not in antes and o.type == 'EMPTY':
        bpy.data.objects.remove(o)
pts = [o.matrix_world @ v.co for o in lin for v in o.data.vertices]
mn = Vector(map(min, *pts)); mx = Vector(map(max, *pts)); cc = (mn + mx) / 2
ext = mx - mn
ax = max(range(3), key=lambda i: ext[i])
def caja(o):
    q = [o.matrix_world @ v.co for v in o.data.vertices]
    return Vector(map(min, *q)), Vector(map(max, *q))
lens = min(lin, key=lambda o: (caja(o)[1] - caja(o)[0])[ax] / max(1e-6, max(caja(o)[1] - caja(o)[0])))
lc = (caja(lens)[0] + caja(lens)[1]) / 2
signo = 1 if lc[ax] > cc[ax] else -1
punta = cc.copy(); punta[ax] = mx[ax] if signo > 0 else mn[ax]
dir_l = Vector((0, 0, 0)); dir_l[ax] = signo
LARGO = float(P.get('largo', 0.2))
sl = LARGO / ext[ax]
# la linterna en su propio marco: lente en el origen, haz hacia +Y, cola hacia -Y
Rl = dir_l.rotation_difference(Vector((0, 1, 0))).to_matrix().to_4x4()
for o in lin:
    o.matrix_world = Rl @ Matrix.Diagonal((sl, sl, sl, 1)) @ Matrix.Translation(-punta) @ o.matrix_world
print('DBG linterna', [o.name for o in lin], 'lente', lens.name, 'eje', ax, signo, 'diametro', round(max(ext[i] for i in range(3) if i != ax) * sl, 3))
bpy.ops.object.select_all(action='DESELECT')
for o in lin:
    o.select_set(True)
bpy.context.view_layer.objects.active = lin[0]
bpy.ops.object.join()
lint = bpy.context.active_object
lint.name = 'linterna'
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
RADIO_MANGO = 0.016
AGARRE = float(P.get('agarre', 0.13))  # del cristal al centro del puño

# ---------------------------------------------------------------- poses
LENTE = Vector((float(P.get('lx', 0.12)), float(P.get('ly', 0.52)), float(P.get('lz', -0.10))))
APUNTA = Vector((0, 6.0, 0))  # a dónde apunta la linterna (un poco hacia el centro de la vista)

def mano_linterna(dl=Vector(), ang=Vector()):
    """mano derecha con el puño cerrado alrededor del mango"""
    lente = LENTE + dl
    eje = (APUNTA - lente).normalized()
    if ang.length:
        eje = (Quaternion(Vector((1, 0, 0)), ang.x) @ Quaternion(Vector((0, 0, 1)), ang.z) @ eje).normalized()
    puno = lente - eje * AGARRE
    lado = eje.cross(Vector((0, 0, 1))).normalized()   # hacia la izquierda de la linterna
    arriba = lado.cross(eje).normalized()
    # agarre de martillo: palma hacia la izquierda, pulgar arriba, los dedos bajan y rodean el mango
    g = float(P.get('giro', 0.35))
    adelante = (-arriba * math.cos(g) + lado * math.sin(g)).normalized()
    palma = adelante.cross(eje).normalized()
    # la muñeca: detrás del puño, y la palma apoyada al lado del mango (el mango queda en la palma)
    muneca = puno - eje * float(P.get('mb', 0.055)) - palma * float(P.get('mp', 0.035)) - adelante * float(P.get('mf', 0.03))
    brazo('r', muneca, Vector((1.0, -0.3, -1.2)), adelante, palma, float(P.get('ga', 0.5)))
    dedos('r', (float(P.get('c1', 1.1)), float(P.get('c2', 1.35)), float(P.get('c3', 0.9))),
          (float(P.get('t1', 0.2)), float(P.get('t2', 0.5)), float(P.get('t3', 0.4))))
    return lente, eje

def colocar_linterna(lente, eje):
    """el hueso «linterna»: cabeza en el cristal, cola hacia delante (el haz)"""
    global LINT_W
    aw = AW()
    LINT_W = Matrix.Translation(lente) @ Vector((0, 1, 0)).rotation_difference(eje).to_matrix().to_4x4()
    m = aw.inverted() @ LINT_W
    loc, rot, _ = m.decompose()
    pb['linterna'].matrix = Matrix.Translation(loc) @ rot.to_matrix().to_4x4()
    up()

# la mano izquierda en reposo: abajo, fuera de la vista
IZQ_FUERA = dict(muneca=Vector((-0.2, 0.12, -0.55)), adelante=Vector((0.2, 0.6, -0.6)), palma=Vector((1, 0, 0)))

def izquierda(muneca, adelante, palma, curl=(0.25, 0.3, 0.2), pulgar=(0.2, 0.2, 0.2), codo=Vector((-1, -0.2, -1)), abre=0.0, cada=None):
    brazo('l', muneca, codo, adelante, palma)
    dedos('l', curl, pulgar, abre, cada)

def pose_base(lente_dl=Vector(), ang=Vector()):
    reset()
    l, e = mano_linterna(lente_dl, ang)
    colocar_linterna(l, e)
    izquierda(**IZQ_FUERA)

if not P.get("nopose"):
    pose_base()
if P.get('dbg'):
    for n in ('def.arm.upper.r','def.forearm.upper.r','def.hand.r','def.hand.l','linterna'):
        print('DBG',n,tuple(round(x,3) for x in hw(n)))
    dg=bpy.context.evaluated_depsgraph_get(); e=piel.evaluated_get(dg); me=e.to_mesh()
    ps=[piel.matrix_world@v.co for v in me.vertices]
    print('DBG piel',tuple(round(min(p[i] for p in ps),3) for i in range(3)),tuple(round(max(p[i] for p in ps),3) for i in range(3)))

# ---------------------------------------------------------------- cámara y vistas
def camara_fp():
    cam = bpy.data.objects.new("cfp", bpy.data.cameras.new("cfp")); sc.collection.objects.link(cam)
    cam.data.sensor_fit = 'HORIZONTAL'; cam.data.angle = math.radians(82)
    cam.data.clip_start = 0.02
    cam.rotation_euler = (math.radians(90), 0, 0)
    return cam

def preparar_render():
    sc.render.engine = 'BLENDER_EEVEE' if P.get('eevee') else 'BLENDER_WORKBENCH'
    sc.display.shading.light = 'STUDIO'; sc.display.shading.color_type = 'TEXTURE'
    sc.render.resolution_x = 1000; sc.render.resolution_y = 450
    w = bpy.data.worlds.new("w"); w.color = (0.03, 0.03, 0.035); sc.world = w
    l = bpy.data.objects.new("l", bpy.data.lights.new("l", 'POINT')); l.data.energy = 6
    l.location = (0.1, 0.3, 0.15); sc.collection.objects.link(l)
    l2 = bpy.data.objects.new("l2", bpy.data.lights.new("l2", 'SUN')); l2.data.energy = 1.5
    l2.rotation_euler = (0.9, 0.3, 0.4); sc.collection.objects.link(l2)
    # pared y suelo para ver la escala
    bpy.ops.mesh.primitive_plane_add(size=6, location=(0, 3, 0), rotation=(math.radians(90), 0, 0))
    bpy.ops.mesh.primitive_plane_add(size=6, location=(0, 1.5, -1.6))

# la linterna va pegada al hueso
def pegar_linterna():
    lint.parent = arm
    lint.parent_type = 'BONE'
    lint.parent_bone = 'linterna'
    up()
    lint.matrix_world = LINT_W
    up()
pegar_linterna()

if P.get('ver'):
    preparar_render()
    cam = camara_fp(); sc.camera = cam
    sc.render.filepath = out + '_fp.png'; bpy.ops.render.render(write_still=True)
    c2 = bpy.data.objects.new("c2", bpy.data.cameras.new("c2")); sc.collection.objects.link(c2)
    c2.data.clip_start = 0.01
    obj = LINT_W @ Vector((0, -AGARRE, 0))
    if P.get('lejos'):
        obj = Vector((0.0, 0.25, -0.2))
    sc.render.resolution_x = 500; sc.render.resolution_y = 400
    for i, d in enumerate([(1, 0.2, 0.3), (-1, 0.6, 0.6), (0.2, 0.3, 1), (0.3, -1, 0.2)]):
        c2.location = obj + Vector(d).normalized() * float(P.get('dist', 0.4))
        c2.rotation_euler = (obj - c2.location).to_track_quat('-Z', 'Y').to_euler(); sc.camera = c2
        sc.render.filepath = out + f'_lado{i}.png'; bpy.ops.render.render(write_still=True)
