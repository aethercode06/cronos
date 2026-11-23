"""Hornea una animación de Mixamo completa en Damián con un arma.
Fotograma 1: agarre por el hueco del puño (dos manos con IK). Resto: el arma va con la mano derecha y la izquierda
se mantiene en el mismo punto del mango (IK por fotograma). Guarda la acción y un vídeo."""
import bpy, sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mixamo_play import cargar_anim, aplicar
from dos_manos import agarre_dos_manos, ik_mano
from mathutils import Vector, Matrix
ANIM, ARMA, NOMBRE, OUT = sys.argv[-4:]
DOS = os.environ.get("DOS_MANOS", "1") == "1"
bpy.ops.wm.open_mainfile(filepath="/home/claude/damian/out/damian_mixamo.blend")
tgt = bpy.data.objects["Damian_rig"]; body = bpy.data.objects["cuerpo"]; W = tgt.matrix_world; pb = tgt.pose.bones
src = cargar_anim(ANIM); acc_src = src.animation_data.action
f0, f1 = [int(round(x)) for x in acc_src.frame_range]
# ---- fotograma 1: agarre ----
aplicar(src, tgt, f0, 0)
cr, er, cl = agarre_dos_manos(tgt, body)
bpy.ops.import_scene.gltf(filepath=ARMA)
arma = [o for o in bpy.context.selected_objects if o.type == 'MESH'][0]
z = er; fuera = Vector((0, 0.3, 1)); x = (fuera - z * fuera.dot(z)).normalized(); y = z.cross(x)
M = Matrix((x, y, z)).transposed().to_4x4(); M.translation = cl - z * float(os.environ.get("OFF", "-0.07"))
arma.matrix_world = M
Hr = W @ pb["mixamorig:RightHand"].matrix
arma_rel = Hr.inverted() @ arma.matrix_world                 # arma respecto a la mano derecha
Hl = W @ pb["mixamorig:LeftHand"].matrix
izq_rel = arma.matrix_world.inverted() @ Hl                    # mano izquierda respecto al arma
mw = arma.matrix_world.copy(); arma.parent = tgt; arma.parent_type = 'BONE'; arma.parent_bone = "mixamorig:RightHand"; arma.matrix_world = mw
# ---- todos los fotogramas ----
accion = bpy.data.actions.new(NOMBRE); tgt.animation_data_create(); tgt.animation_data.action = accion
huesos = [b for b in pb if b.name in src.pose.bones]
for f in range(f0, f1 + 1):
    aplicar(src, tgt, f, 0)
    if DOS:
        Hr = W @ pb["mixamorig:RightHand"].matrix
        armaW = Hr @ arma_rel
        objetivo = armaW @ izq_rel
        ik_mano(tgt, "l", objetivo.translation, objetivo.to_3x3().normalized())
    for b in huesos:
        b.keyframe_insert("rotation_quaternion", frame=f)
        if b.name == "mixamorig:Hips": b.keyframe_insert("location", frame=f)
    if f % 10 == 0: print("fotograma", f, "/", f1)
bpy.data.objects.remove(src)
for o in [o for o in bpy.data.objects if o.type == 'ARMATURE' and o != tgt]: bpy.data.objects.remove(o)
sc = bpy.context.scene; sc.frame_start, sc.frame_end = f0, f1
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, NOMBRE + ".blend"))
print("HORNEADO", NOMBRE, f0, f1)
