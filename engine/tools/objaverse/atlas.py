"""Hornea todos los materiales de un GLB en una sola textura (atlas) para dibujarlo en una sola llamada.
Uso: python atlas.py entrada.glb salida.glb [tam=1024] [max_tris=0]"""
import bpy, sys
A = [a for a in sys.argv if not a.startswith('--')]
SRC, OUT = A[-4] if len(A) >= 5 else A[-2], A[-3] if len(A) >= 5 else A[-1]
TAM = int(A[-2]) if len(A) >= 5 else 1024
MAXT = int(A[-1]) if len(A) >= 5 else 0
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
ms = [o for o in bpy.data.objects if o.type == 'MESH']
for o in bpy.data.objects: o.select_set(o in ms)
bpy.context.view_layer.objects.active = ms[0]
if len(ms) > 1: bpy.ops.object.join()
ob = bpy.context.view_layer.objects.active
if MAXT and len(ob.data.polygons) > MAXT:
    md = ob.modifiers.new("dec", 'DECIMATE'); md.ratio = MAXT / len(ob.data.polygons); bpy.ops.object.modifier_apply(modifier="dec")
orig_uv = ob.data.uv_layers.active.name
atlas = ob.data.uv_layers.new(name="atlas")
ob.data.uv_layers.active = atlas
bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=0.004)
bpy.ops.object.mode_set(mode='OBJECT')
img = bpy.data.images.new("atlas", TAM, TAM)
for mat in ob.data.materials:
    nt = mat.node_tree
    n = nt.nodes.new('ShaderNodeTexImage'); n.image = img
    uv = nt.nodes.new('ShaderNodeUVMap'); uv.uv_map = "atlas"
    nt.links.new(uv.outputs[0], n.inputs[0])
    nt.nodes.active = n
    # los mapas de la textura original siguen usando su UV
    for nd in nt.nodes:
        if nd.type == 'TEX_IMAGE' and nd != n and not nd.inputs[0].is_linked:
            u2 = nt.nodes.new('ShaderNodeUVMap'); u2.uv_map = orig_uv; nt.links.new(u2.outputs[0], nd.inputs[0])
sc = bpy.context.scene
sc.render.engine = 'CYCLES'; sc.cycles.device = 'CPU'; sc.cycles.samples = 4
sc.render.bake.use_pass_direct = False; sc.render.bake.use_pass_indirect = False; sc.render.bake.use_pass_color = True
sc.render.bake.margin = 4
ob.select_set(True)
bpy.ops.object.bake(type='DIFFUSE')
img.filepath_raw = "/tmp/atlas_bake.png"; img.file_format = 'PNG'; img.save()
nueva = bpy.data.materials.new("atlas"); nueva.use_nodes = True
bsdf = nueva.node_tree.nodes["Principled BSDF"]; bsdf.inputs["Roughness"].default_value = 0.55
tx = nueva.node_tree.nodes.new('ShaderNodeTexImage'); tx.image = img
nueva.node_tree.links.new(tx.outputs[0], bsdf.inputs["Base Color"])
ob.data.materials.clear(); ob.data.materials.append(nueva)
ob.data.uv_layers.remove(ob.data.uv_layers[orig_uv])
bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', export_image_format='WEBP', export_apply=True)
print("ATLAS OK", OUT, len(ob.data.polygons))
