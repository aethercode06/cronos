"""Exporta a Damián para subirlo a Mixamo: una sola malla en reposo (pose A), sin esqueleto, sin formas, con texturas."""
import bpy, os, sys
OUT = sys.argv[-1]
bpy.ops.wm.open_mainfile(filepath="/home/claude/damian/out/damian.blend")
quitar = ["pelo", "eyebrow001", "eyelashes01"]
for n in quitar:
    if n in bpy.data.objects: bpy.data.objects.remove(bpy.data.objects[n])
mallas = [o for o in bpy.data.objects if o.type == 'MESH' and o.name != "suelo"]
for o in mallas:
    bpy.context.view_layer.objects.active = o
    if o.data.shape_keys:
        o.shape_key_clear()
    for md in list(o.modifiers):
        o.modifiers.remove(md)
    o.vertex_groups.clear()
    mw = o.matrix_world.copy(); o.parent = None; o.matrix_world = mw
for o in [o for o in bpy.data.objects if o.type != 'MESH']:
    bpy.data.objects.remove(o)
bpy.ops.object.select_all(action='DESELECT')
for o in mallas: o.select_set(True)
bpy.context.view_layer.objects.active = mallas[0]
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bpy.ops.object.join()
d = bpy.context.active_object; d.name = "Damian"
print("caras", len(d.data.polygons), "materiales", [m.name for m in d.data.materials])
zs = [v.co.z for v in d.data.vertices]; print("altura", max(zs) - min(zs))
# texturas a disco junto al fbx
tex = os.path.join(OUT, "textures"); os.makedirs(tex, exist_ok=True)
for im in bpy.data.images:
    if im.size[0] > 0 and (im.packed_file or im.filepath):
        nombre = bpy.path.clean_name(os.path.splitext(os.path.basename(im.filepath or im.name))[0]) + ".png"
        im.filepath_raw = os.path.join(tex, nombre); im.file_format = 'PNG'
        try:
            im.save(); print("textura", nombre)
        except Exception as e: print("textura falla", nombre, e)
bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, "Damian.fbx"), use_selection=True, object_types={'MESH'},
                         path_mode='COPY', embed_textures=True, apply_unit_scale=True, apply_scale_options='FBX_SCALE_ALL',
                         mesh_smooth_type='FACE', add_leaf_bones=False)
print("FBX OK")
