"""Sábanas de verdad: simula en Blender una tela cayendo sobre cada mueble (física de tela con colisiones) y
guarda la forma final como <mueble>.glb, en el mismo espacio que el modelo del mueble.
Uso: python simular.py <mueble.glb> <salida.glb> [semilla]"""
import bpy, sys, math, random, mathutils
A = [a for a in sys.argv if not a.startswith('--')]
SRC, DST = A[-3], A[-2]
random.seed(int(A[-1]))
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
mallas = [o for o in bpy.context.scene.objects if o.type == 'MESH']
for o in bpy.context.scene.objects:
    o.select_set(False)
# colisionador: copia unida de todas las mallas, con las transformaciones aplicadas
bpy.context.view_layer.objects.active = mallas[0]
for o in mallas:
    o.select_set(True)
bpy.ops.object.duplicate()
copias = [o for o in bpy.context.selected_objects]
bpy.context.view_layer.objects.active = copias[0]
if len(copias) > 1:
    bpy.ops.object.join()
col = bpy.context.view_layer.objects.active
bpy.ops.object.parent_clear(type='CLEAR_KEEP_TRANSFORM')
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
# simplificar el colisionador para que la simulación vaya rápida
if len(col.data.polygons) > 6000:
    d = col.modifiers.new("d", 'DECIMATE'); d.ratio = 6000 / len(col.data.polygons)
    bpy.ops.object.modifier_apply(modifier="d")
cm = col.modifiers.new("col", 'COLLISION')
col.collision.thickness_outer = 0.012
col.collision.cloth_friction = 8.0
pts = [col.matrix_world @ mathutils.Vector(v.co) for v in col.data.vertices]
mn = mathutils.Vector([min(p[i] for p in pts) for i in range(3)])
mx = mathutils.Vector([max(p[i] for p in pts) for i in range(3)])
alto = mx.z - mn.z
cx, cy = (mn.x + mx.x) / 2, (mn.y + mx.y) / 2
# suelo
bpy.ops.mesh.primitive_plane_add(size=20, location=(cx, cy, mn.z))
suelo = bpy.context.active_object
suelo.modifiers.new("col", 'COLLISION'); suelo.collision.cloth_friction = 10.0
# la sábana: un rectángulo que cubre el mueble y cuelga casi hasta el suelo
caida = alto * random.uniform(0.85, 1.0)
sx = (mx.x - mn.x) + 2 * caida + 0.1
sy = (mx.y - mn.y) + 2 * caida + 0.1
lado = max(sx, sy)
n = int(min(120, max(40, lado / 0.03)))
bpy.ops.mesh.primitive_grid_add(x_subdivisions=int(n * sx / lado), y_subdivisions=int(n * sy / lado), size=1, location=(cx + random.uniform(-0.05, 0.05), cy + random.uniform(-0.05, 0.05), mx.z + 0.04))
tela = bpy.context.active_object
tela.scale = (sx, sy, 1)
tela.rotation_euler.z = random.uniform(-0.12, 0.12)
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
# arrugas iniciales leves para que no caiga perfecta
for v in tela.data.vertices:
    v.co.z += random.uniform(-0.004, 0.004)
cl = tela.modifiers.new("tela", 'CLOTH')
s = cl.settings
s.quality = 6
s.mass = 0.18
s.tension_stiffness = 10; s.compression_stiffness = 10; s.shear_stiffness = 5
s.bending_stiffness = 0.15
s.air_damping = 1.5
cl.collision_settings.distance_min = 0.006
cl.collision_settings.collision_quality = 3
cl.collision_settings.use_self_collision = False
fin = 110
bpy.context.scene.frame_start = 1
bpy.context.scene.frame_end = fin
cl.point_cache.frame_end = fin
for f in range(1, fin + 1):
    bpy.context.scene.frame_set(f)
# congelar la forma final
dg = bpy.context.evaluated_depsgraph_get()
ev = tela.evaluated_get(dg)
me = bpy.data.meshes.new_from_object(ev)
final = bpy.data.objects.new("sabana", me)
final.matrix_world = tela.matrix_world.copy()
bpy.context.scene.collection.objects.link(final)
for o in list(bpy.context.scene.objects):
    if o != final:
        bpy.data.objects.remove(o, do_unlink=True)
bpy.context.view_layer.objects.active = final
final.select_set(True)
if len(me.polygons) > 5000:
    d = final.modifiers.new("d", 'DECIMATE'); d.ratio = 5000 / len(me.polygons)
    bpy.ops.object.modifier_apply(modifier="d")
for p in final.data.polygons:
    p.use_smooth = True
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bpy.ops.export_scene.gltf(filepath=DST, use_selection=True, export_materials='NONE', export_normals=True, export_texcoords=True)
print("SABANA OK", DST, len(final.data.polygons), round(alto, 2))
