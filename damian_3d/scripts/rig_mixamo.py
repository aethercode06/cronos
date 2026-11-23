"""Rehace el esqueleto de Damián como el de Mixamo: mismos nombres, misma postura de reposo (T) y mismos ejes de
cada hueso que el maniquí X Bot, con las articulaciones en el cuerpo de Damián. Así las animaciones de Mixamo se
copian hueso a hueso (giro local) sin conversiones."""
import bpy, sys, os, math
from mathutils import Matrix, Vector
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from retarget import MIXAMO, orden
OUT = sys.argv[-1]
bpy.ops.wm.open_mainfile(filepath="/home/claude/damian/out/damian.blend")
rig = bpy.data.objects["rig"]
for n in ("pelo", "eyebrow001", "eyelashes01"):
    if n in bpy.data.objects: bpy.data.objects.remove(bpy.data.objects[n])
mallas = [o for o in bpy.data.objects if o.type == 'MESH' and any(m.type == 'ARMATURE' for m in o.modifiers)]
# ---- maniquí de Mixamo en reposo ----
antes = set(bpy.data.objects)
bpy.ops.import_scene.fbx(filepath="/home/claude/mixamo/Great_Sword_Idle.fbx")
nuevos = [o for o in bpy.data.objects if o not in antes]
xb = [o for o in nuevos if o.type == 'ARMATURE'][0]
for o in nuevos:
    if o.type == 'MESH': bpy.data.objects.remove(o)
xb.data.pose_position = 'REST'; bpy.context.view_layer.update()
Wx, Wr = xb.matrix_world, rig.matrix_world
inv = {v: "mixamorig:" + k for k, v in MIXAMO.items()}
R = lambda m: m.to_3x3().normalized()
# ---- 1. llevar a Damián a la postura de reposo del maniquí (cada hueso con la misma dirección y giro) ----
for nt in orden(rig):
    ns = inv.get(nt)
    if not ns or ns not in xb.data.bones: continue
    tb = rig.pose.bones[nt]
    rx = R(Wx @ xb.data.bones[ns].matrix_local)
    rt = R(Wr @ tb.bone.matrix_local)
    # dirección del maniquí, y el giro sobre el eje que menos cambie la orientación actual de Damián
    actual = R(Wr @ tb.matrix)
    rot = actual.col[1].normalized().rotation_difference(rx.col[1].normalized()).to_matrix() @ actual
    M = rot.to_4x4(); M.translation = (Wr @ tb.matrix).translation
    tb.matrix = Wr.inverted() @ M; bpy.context.view_layer.update()
# ---- 2. fijar esa postura como reposo: hornear la malla y aplicar la pose al esqueleto ----
for o in mallas:
    if o.data.shape_keys: o.shape_key_clear()
    bpy.context.view_layer.objects.active = o
    for md in list(o.modifiers):
        if md.type == 'ARMATURE':
            nombre = md.name
            bpy.ops.object.modifier_copy(modifier=nombre)
            bpy.ops.object.modifier_apply(modifier=nombre)
bpy.ops.object.select_all(action='DESELECT'); rig.select_set(True); bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='POSE'); bpy.ops.pose.select_all(action='SELECT'); bpy.ops.pose.armature_apply(selected=False)
bpy.ops.object.mode_set(mode='OBJECT')
# ---- 3. mismos ejes (dirección y giro) que los huesos del maniquí, conservando las articulaciones de Damián ----
bpy.ops.object.mode_set(mode='EDIT')
eb = rig.data.edit_bones
for nt in list(MIXAMO.values()):
    ns = inv[nt]
    if nt not in eb or ns not in xb.data.bones: continue
    b = eb[nt]; largo = b.length
    rx = (Wr.inverted().to_3x3() @ R(Wx @ xb.data.bones[ns].matrix_local)).normalized()
    cab = b.head.copy()
    M = rx.to_4x4(); M.translation = cab
    b.matrix = M
    b.length = largo
bpy.ops.object.mode_set(mode='OBJECT')
# ---- 4. nombres de Mixamo (los grupos de vértices de las mallas se renombran igual) ----
for nt, ns in [(v, "mixamorig:" + k) for k, v in MIXAMO.items()]:
    if nt in rig.data.bones:
        rig.data.bones[nt].name = ns
        for o in mallas:
            if nt in o.vertex_groups: o.vertex_groups[nt].name = ns
# las armas siguen a la mano derecha
bpy.data.objects.remove(xb)
for o in [o for o in bpy.data.objects if o.type == 'ARMATURE' and o != rig]: bpy.data.objects.remove(o)
rig.name = "Damian_rig"
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=OUT)
print("RIG MIXAMO OK", len(rig.data.bones))
