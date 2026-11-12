"""Prepara el modelo de TRELLIS.2: importa, reduce triángulos (para móvil) y guarda .blend para rig.py."""
import bpy, sys
src, out, target = sys.argv[-3], sys.argv[-2], int(sys.argv[-1])
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
ob = [o for o in bpy.data.objects if o.type == 'MESH'][0]
for o in list(bpy.data.objects):
    if o != ob: bpy.data.objects.remove(o)
ob.parent = None
bpy.context.view_layer.objects.active = ob; ob.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
n0 = len(ob.data.polygons)
m = ob.modifiers.new('dec', 'DECIMATE'); m.ratio = min(1.0, target / n0); m.use_collapse_triangulate = True
bpy.ops.object.modifier_apply(modifier='dec')
bpy.ops.object.shade_smooth()
print("TRIS", n0, "->", len(ob.data.polygons))
bpy.ops.wm.save_as_mainfile(filepath=out)
