"""Pinta a Elena sobre el personaje de MakeHuman (se ejecuta en local con el .blend que genera CI):
piel de muerta con la cara demoníaca proyectada, pelo negro, ojos ámbar, dientes podridos y camisón sucio.
Hornea todo a texturas para el juego y exporta el GLB con esqueleto y gestos.
Uso: python pintar_elena.py <elena_mh.blend> <cara.png> <salida_dir>"""
import bpy, sys, os, math, mathutils
from mathutils import Vector
SRC, CARA, OUT = sys.argv[-3], sys.argv[-2], sys.argv[-1]
os.makedirs(OUT, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=SRC)
sc = bpy.context.scene
objs = {o.name: o for o in bpy.data.objects}
exp = [o for o in bpy.data.objects if o.name.endswith("_export") or (o.parent and o.parent.name.endswith("_export"))]
orig = [o for o in bpy.data.objects if o not in exp]
for o in orig: bpy.data.objects.remove(o)
def find(part):
    for o in bpy.data.objects:
        if part in o.name.lower() and o.type == 'MESH': return o
body = [o for o in bpy.data.objects if o.type == 'MESH' and o.name.startswith("Human_export")][0]
rig = [o for o in bpy.data.objects if o.type == 'ARMATURE'][0]
print("OBJETOS", [o.name for o in bpy.data.objects])
# los objetos que quedaron colgando del esqueleto original pasan al de exportación
for o in bpy.data.objects:
    if o.type != 'MESH': continue
    for md in o.modifiers:
        if md.type == 'ARMATURE' and md.object is None: md.object = rig
    if o.parent is None:
        mw = o.matrix_world.copy(); o.parent = rig; o.matrix_world = mw
dg = bpy.context.evaluated_depsgraph_get()
def eval_pos(o):
    oe = o.evaluated_get(dg); m = oe.to_mesh()
    r = [o.matrix_world @ v.co for v in m.vertices]; oe.to_mesh_clear(); return r

def principled(o):
    m = o.material_slots[0].material; nt = m.node_tree
    return m, nt, [n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'][0]

def bake_to(o, name, res, build):
    """build(nt, links) devuelve el socket de color final; se hornea como emisión al UV del objeto."""
    m, nt, b = principled(o)
    N, L = nt.nodes, nt.links
    sock = build(m, nt, b)
    em = N.new('ShaderNodeEmission'); L.new(sock, em.inputs[0])
    out = [n for n in N if n.type == 'OUTPUT_MATERIAL'][0]
    prev = out.inputs['Surface'].links[0].from_socket if out.inputs['Surface'].links else None
    L.new(em.outputs[0], out.inputs['Surface'])
    img = bpy.data.images.new(name, res, res)
    t = N.new('ShaderNodeTexImage'); t.image = img; N.active = t
    sc.render.engine = 'CYCLES'; sc.cycles.samples = 4; sc.render.bake.margin = 12; sc.render.bake.use_selected_to_active = False
    for x in bpy.data.objects: x.select_set(False)
    o.hide_render = False; o.hide_set(False); o.select_set(True); bpy.context.view_layer.objects.active = o
    bpy.ops.object.bake(type='EMIT')
    img.filepath_raw = os.path.join(OUT, name + ".png"); img.file_format = 'PNG'; img.save()
    # material final: solo la textura horneada
    for n in list(N):
        if n not in (b, out, t): N.remove(n)
    L.new(t.outputs['Color'], b.inputs['Base Color']); L.new(b.outputs[0], out.inputs['Surface'])
    print("HORNEADO", name)
    return b

def tex_of(b):
    l = b.inputs['Base Color'].links
    return l[0].from_socket if l else None

# ---------- piel ----------
eyes = find("high-poly")
ev = eval_pos(eyes)
L_eye = sum((v for v in ev if v.x > 0), Vector()) / max(1, sum(1 for v in ev if v.x > 0))
R_eye = sum((v for v in ev if v.x <= 0), Vector()) / max(1, sum(1 for v in ev if v.x <= 0))
print("OJOS", L_eye, R_eye)
# en la imagen (1024): ojos en (390,465) y (625,465) -> escala px/m
s_img = (625 - 390) / (L_eye - R_eye).length
cx_img, cy_img = (390 + 625) / 2, 465.0
eye_mid = (L_eye + R_eye) / 2
me = body.data
bp = eval_pos(body)
uvp = me.uv_layers.new(name="cara")
for loop in me.loops:
    co = bp[loop.vertex_index]
    px = cx_img - (co.x - eye_mid.x) * s_img   # el modelo mira a -Y: +x del modelo = izquierda de la imagen
    py = cy_img - (co.z - eye_mid.z) * s_img
    uvp.data[loop.index].uv = (px / 1024.0, 1 - py / 1024.0)
me.uv_layers.active = me.uv_layers[0]
def piel(m, nt, b):
    N, L = nt.nodes, nt.links
    base = tex_of(b)
    rgb = N.new('ShaderNodeRGB'); rgb.outputs[0].default_value = (0.5, 0.5, 0.5, 1)
    if base is None: base = rgb.outputs[0]
    # piel de muerta: desaturada, gris azulada, más oscura
    hsv = N.new('ShaderNodeHueSaturation'); hsv.inputs['Saturation'].default_value = 0.25; hsv.inputs['Value'].default_value = 0.78
    L.new(base, hsv.inputs['Color'])
    tint = N.new('ShaderNodeMix'); tint.data_type = 'RGBA'; tint.blend_type = 'MULTIPLY'; tint.inputs['Factor'].default_value = 1.0
    tint.inputs['B'].default_value = (0.80, 0.84, 0.90, 1); L.new(hsv.outputs[0], tint.inputs['A'])
    # manchas y suciedad
    nz = N.new('ShaderNodeTexNoise'); nz.inputs['Scale'].default_value = 18; nz.inputs['Detail'].default_value = 8
    cr = N.new('ShaderNodeValToRGB'); cr.color_ramp.elements[0].position = 0.45; cr.color_ramp.elements[1].position = 0.75
    cr.color_ramp.elements[0].color = (1, 1, 1, 1); cr.color_ramp.elements[1].color = (0.55, 0.5, 0.47, 1)
    L.new(nz.outputs['Fac'], cr.inputs[0])
    dirt = N.new('ShaderNodeMix'); dirt.data_type = 'RGBA'; dirt.blend_type = 'MULTIPLY'; dirt.inputs['Factor'].default_value = 0.8
    L.new(tint.outputs['Result'], dirt.inputs['A']); L.new(cr.outputs['Color'], dirt.inputs['B'])
    # cara proyectada
    ft = N.new('ShaderNodeTexImage'); ft.image = bpy.data.images.load(CARA); ft.extension = 'CLIP'
    uvn = N.new('ShaderNodeUVMap'); uvn.uv_map = "cara"; L.new(uvn.outputs[0], ft.inputs[0])
    geo = N.new('ShaderNodeNewGeometry'); sep = N.new('ShaderNodeSeparateXYZ'); L.new(geo.outputs['Normal'], sep.inputs[0])
    fr = N.new('ShaderNodeMapRange'); fr.inputs['From Min'].default_value = -0.2; fr.inputs['From Max'].default_value = -0.55; L.new(sep.outputs[1], fr.inputs['Value'])
    k = N.new('ShaderNodeMath'); k.operation = 'MULTIPLY'; L.new(ft.outputs['Alpha'], k.inputs[0]); L.new(fr.outputs[0], k.inputs[1])
    mx = N.new('ShaderNodeMix'); mx.data_type = 'RGBA'; L.new(k.outputs[0], mx.inputs['Factor'])
    L.new(dirt.outputs['Result'], mx.inputs['A']); L.new(ft.outputs['Color'], mx.inputs['B'])
    return mx.outputs['Result']
bake_to(body, "elena_piel", 4096, piel)
body.data.uv_layers.remove(body.data.uv_layers["cara"])

# ---------- pelo negro ----------
hair = find("long01") or find("hair")
if hair:
    m, nt, b = principled(hair)
    t = tex_of(b)
    if t:
        hsv = nt.nodes.new('ShaderNodeHueSaturation'); hsv.inputs['Saturation'].default_value = 0.15; hsv.inputs['Value'].default_value = 0.18
        nt.links.new(t, hsv.inputs['Color']); nt.links.new(hsv.outputs[0], b.inputs['Base Color'])
    b.inputs['Roughness'].default_value = 0.55
# ---------- ojos ámbar ----------
if eyes:
    m, nt, b = principled(eyes)
    t = tex_of(b)
    if t:
        hsv = nt.nodes.new('ShaderNodeHueSaturation'); hsv.inputs['Hue'].default_value = 0.58; hsv.inputs['Saturation'].default_value = 1.4
        nt.links.new(t, hsv.inputs['Color']); nt.links.new(hsv.outputs[0], b.inputs['Base Color'])
# ---------- dientes podridos ----------
teeth = find("teeth")
if teeth:
    m, nt, b = principled(teeth)
    t = tex_of(b)
    mul = nt.nodes.new('ShaderNodeMix'); mul.data_type = 'RGBA'; mul.blend_type = 'MULTIPLY'; mul.inputs['Factor'].default_value = 1
    mul.inputs['B'].default_value = (0.78, 0.62, 0.36, 1)
    if t: nt.links.new(t, mul.inputs['A'])
    nt.links.new(mul.outputs['Result'], b.inputs['Base Color'])
# ---------- camisón sucio ----------
def tela(m, nt, b):
    N, L = nt.nodes, nt.links
    crema = N.new('ShaderNodeRGB'); crema.outputs[0].default_value = (0.70, 0.64, 0.52, 1)
    tc = N.new('ShaderNodeTexCoord')
    nz = N.new('ShaderNodeTexNoise'); nz.inputs['Scale'].default_value = 6; nz.inputs['Detail'].default_value = 10; L.new(tc.outputs['Object'], nz.inputs['Vector'])
    cr = N.new('ShaderNodeValToRGB'); cr.color_ramp.elements[0].position = 0.4; cr.color_ramp.elements[1].position = 0.8
    cr.color_ramp.elements[0].color = (1, 1, 1, 1); cr.color_ramp.elements[1].color = (0.45, 0.38, 0.3, 1); L.new(nz.outputs['Fac'], cr.inputs[0])
    d = N.new('ShaderNodeMix'); d.data_type = 'RGBA'; d.blend_type = 'MULTIPLY'; d.inputs['Factor'].default_value = 1
    L.new(crema.outputs[0], d.inputs['A']); L.new(cr.outputs['Color'], d.inputs['B'])
    # suciedad del borde (abajo) y sangre en el pecho
    sxyz = N.new('ShaderNodeSeparateXYZ'); L.new(tc.outputs['Object'], sxyz.inputs[0])
    low = N.new('ShaderNodeMapRange'); low.inputs['From Min'].default_value = 0.25; low.inputs['From Max'].default_value = 0.05; L.new(sxyz.outputs[2], low.inputs['Value'])
    mud = N.new('ShaderNodeMix'); mud.data_type = 'RGBA'; L.new(low.outputs[0], mud.inputs['Factor'])
    L.new(d.outputs['Result'], mud.inputs['A']); mud.inputs['B'].default_value = (0.22, 0.17, 0.12, 1)
    v = N.new('ShaderNodeTexVoronoi'); v.inputs['Scale'].default_value = 3.0; L.new(tc.outputs['Object'], v.inputs['Vector'])
    bl = N.new('ShaderNodeMapRange'); bl.inputs['From Min'].default_value = 0.12; bl.inputs['From Max'].default_value = 0.05; L.new(v.outputs['Distance'], bl.inputs['Value'])
    chest = N.new('ShaderNodeMapRange'); chest.inputs['From Min'].default_value = 1.15; chest.inputs['From Max'].default_value = 1.3; L.new(sxyz.outputs[2], chest.inputs['Value'])
    front = N.new('ShaderNodeMapRange'); front.inputs['From Min'].default_value = 0.0; front.inputs['From Max'].default_value = -0.08; L.new(sxyz.outputs[1], front.inputs['Value'])
    k1 = N.new('ShaderNodeMath'); k1.operation = 'MULTIPLY'; L.new(bl.outputs[0], k1.inputs[0]); L.new(chest.outputs[0], k1.inputs[1])
    k2 = N.new('ShaderNodeMath'); k2.operation = 'MULTIPLY'; L.new(k1.outputs[0], k2.inputs[0]); L.new(front.outputs[0], k2.inputs[1])
    blood = N.new('ShaderNodeMix'); blood.data_type = 'RGBA'; L.new(k2.outputs[0], blood.inputs['Factor'])
    L.new(mud.outputs['Result'], blood.inputs['A']); blood.inputs['B'].default_value = (0.32, 0.03, 0.02, 1)
    b.inputs['Roughness'].default_value = 0.92
    return blood.outputs['Result']
for o in bpy.data.objects:
    if o.type == 'MESH' and ("tunic" in o.name.lower() or "skirt" in o.name.lower()):
        bake_to(o, "elena_" + ("blusa" if "tunic" in o.name.lower() else "falda"), 2048, tela)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "elena_pintada.blend"))
# exportar
for x in bpy.data.objects: x.select_set(x in exp or True)
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "elena.glb"), export_format='GLB', export_morph=True, export_skins=True,
                          export_animations=True, export_yup=True, export_image_format='WEBP')
print("PINTADA OK")
