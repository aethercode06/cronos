"""Modelo listo para juego: UV nuevo y limpio en el modelo reducido y horneado del color, relieve y rugosidad
desde el modelo original de TRELLIS.2 (evita las rayas negras de las costuras del atlas fragmentado).
Uso: python rebake.py <bajo.blend> <alto.glb> <salida_prefijo> <res_color>  (por defecto conserva el UV del modelo reducido; --uv-nuevo lo rehace)"""
import bpy, sys
A = [a for a in sys.argv if not a.startswith('--')]
low_blend, high_glb, out, RES = A[-4], A[-3], A[-2], int(A[-1])
bpy.ops.wm.open_mainfile(filepath=low_blend)
low = [o for o in bpy.data.objects if o.type == 'MESH'][0]
bpy.ops.import_scene.gltf(filepath=high_glb)
high = [o for o in bpy.context.selected_objects if o.type == 'MESH'][0]
bpy.ops.object.select_all(action='DESELECT')
bpy.context.view_layer.objects.active = high; high.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
# UV nuevo
bpy.ops.object.select_all(action='DESELECT')
bpy.context.view_layer.objects.active = low; low.select_set(True)
me = low.data
NUEVO_UV = '--uv-nuevo' in sys.argv
while NUEVO_UV and len(me.uv_layers) > 0:
    me.uv_layers.remove(me.uv_layers[0])
if NUEVO_UV:
    me.uv_layers.new(name="UVMap")
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.remove_doubles(threshold=0.0008)
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=0.004, area_weight=0.6)
    bpy.ops.uv.pack_islands(margin=0.004)
    bpy.ops.object.mode_set(mode='OBJECT')
else:
    while len(me.uv_layers) > 1: me.uv_layers.remove(me.uv_layers[-1])
print('VERTICES', len(me.vertices), 'CARAS', len(me.polygons))
# material nuevo
mat = bpy.data.materials.new("Elena"); mat.use_nodes = True
N = mat.node_tree.nodes; L = mat.node_tree.links
b = N["Principled BSDF"]
me.materials.clear(); me.materials.append(mat)
def img(name, res, color=True):
    i = bpy.data.images.new(name, res, res)
    if not color: i.colorspace_settings.name = 'Non-Color'
    t = N.new('ShaderNodeTexImage'); t.image = i
    return t
tc = img("elena_color", RES); tn = img("elena_normal", RES // 2, False); tr = img("elena_rough", RES // 4, False)
sc = bpy.context.scene; sc.render.engine = 'CYCLES'; sc.cycles.samples = 1
bk = sc.render.bake; bk.use_selected_to_active = True; bk.cage_extrusion = 0.008; bk.max_ray_distance = 0.03; bk.margin = 6
bpy.ops.object.select_all(action='DESELECT'); high.select_set(True); low.select_set(True); bpy.context.view_layer.objects.active = low
# el material del modelo alto se convierte en emisión del canal que se quiere hornear
hm = high.material_slots[0].material; HN = hm.node_tree.nodes; HL = hm.node_tree.links
hb = [n for n in HN if n.type == 'BSDF_PRINCIPLED'][0]; ho = [n for n in HN if n.type == 'OUTPUT_MATERIAL'][0]
hem = HN.new('ShaderNodeEmission')
def src(inp):
    if hb.inputs[inp].links: return hb.inputs[inp].links[0].from_socket
    return None
for t, kind in ((tc, 'COLOR'), (tn, 'NORMAL'), (tr, 'ROUGH')):
    N.active = t
    if kind == 'NORMAL':
        HL.new(hb.outputs[0], ho.inputs['Surface']); bpy.ops.object.bake(type='NORMAL')
    else:
        so = src('Base Color' if kind == 'COLOR' else 'Roughness')
        for l in list(hem.inputs[0].links): HL.remove(l)
        if so: HL.new(so, hem.inputs[0])
        else: hem.inputs[0].default_value = (0.7, 0.7, 0.7, 1)
        HL.new(hem.outputs[0], ho.inputs['Surface'])
        bpy.ops.object.bake(type='EMIT')
    t.image.filepath_raw = f"{out}_{t.image.name}.png"; t.image.file_format = 'PNG'; t.image.save()
    print("HORNEADO", kind)
bpy.data.objects.remove(high)
L.new(tc.outputs['Color'], b.inputs['Base Color'])
nm = N.new('ShaderNodeNormalMap'); L.new(tn.outputs['Color'], nm.inputs['Color']); L.new(nm.outputs['Normal'], b.inputs['Normal'])
L.new(tr.outputs['Color'], b.inputs['Roughness'])
bpy.ops.wm.save_as_mainfile(filepath=out + ".blend")
print("REBAKE OK")
