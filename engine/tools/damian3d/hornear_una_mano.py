"""Animación con el arma en la mano derecha (una mano): el puño se cierra con la pose de agarre de Great Sword Idle,
el mango pasa por el hueco del puño y el arma cuelga hacia el lado del meñique."""
import bpy, sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mixamo_play import cargar_anim, aplicar
from empunar import hueco
from mathutils import Vector, Matrix
ANIM, ARMA, NOMBRE, OUT = sys.argv[-4:]
BRAZOS = float(os.environ.get("BRAZOS", "8")); AGARRE = float(os.environ.get("AGARRE", "0.12"))
bpy.ops.wm.open_mainfile(filepath="/home/claude/damian/out/damian_mixamo.blend")
tgt = bpy.data.objects["Damian_rig"]; body = bpy.data.objects["cuerpo"]; W = tgt.matrix_world; pb = tgt.pose.bones
puno_src = cargar_anim("/home/claude/mixamo/Great_Sword_Idle.fbx")
bpy.context.scene.frame_set(1)
DEDOS_D = [n for n in puno_src.pose.bones.keys() if n.startswith("mixamorig:RightHand") and n != "mixamorig:RightHand"]
puno = {n: puno_src.pose.bones[n].rotation_quaternion.copy() for n in DEDOS_D}
bpy.data.objects.remove(puno_src)
src = cargar_anim(ANIM); acc_src = src.animation_data.action
f0, f1 = [int(round(x)) for x in acc_src.frame_range]
def pose(f):
    aplicar(src, tgt, f, BRAZOS)
    for n, q in puno.items():
        if n in pb: pb[n].rotation_quaternion = q
    h = pb["mixamorig:Hips"]; h.location.x = 0; h.location.z = 0     # en el sitio (el juego lo mueve)
    bpy.context.view_layer.update()
pose(f0)
hr, cr, er = hueco(tgt, body, "r")
Hm0 = (W @ pb["mixamorig:RightHand"].matrix)
meñ = (W @ pb["mixamorig:RightHandPinky1"].head) - (W @ pb["mixamorig:RightHandIndex1"].head)
e_loc = Hm0.to_3x3().normalized().inverted() @ (er if er.dot(meñ) > 0 else -er)   # eje del puño (hacia el meñique), local a la mano
c_loc = Hm0.inverted() @ cr                                                           # centro del hueco, local a la mano
def muñeca():
    """como se lleva un hacha colgando: el antebrazo gira sobre sí mismo (sin doblar la muñeca) para que el mango
    quede casi vertical; la torsión se reparte entre antebrazo y mano y la muñeca solo se dobla un poco"""
    h = pb["mixamorig:RightHand"]; fa = pb["mixamorig:RightForeArm"]
    eje_fa = ((W @ fa.matrix).to_3x3().col[1]).normalized()
    D = Vector([float(v) for v in os.environ.get("DIR", "-0.15,0.6,-1").split(",")]).normalized()
    e = ((W @ h.matrix).to_3x3().normalized() @ e_loc).normalized()
    # giro sobre el eje del antebrazo que más acerca e a D
    def proy(v): return (v - eje_fa * v.dot(eje_fa)).normalized()
    a, b = proy(e), proy(D)
    ang = math.atan2(a.cross(b).dot(eje_fa), a.dot(b))
    for hueso, parte in ((fa, 0.5), (h, 1.0)):
        M = W @ hueso.matrix; t = M.translation.copy()
        rot = ang * parte if hueso is fa else ang * 0.5
        R = Matrix.Rotation(rot, 4, eje_fa)
        hueso.matrix = W.inverted() @ (Matrix.Translation(t) @ R @ Matrix.Translation(-t) @ M)
        bpy.context.view_layer.update()
    # resto: doblar la muñeca como mucho unos grados
    M = W @ h.matrix; e = (M.to_3x3().normalized() @ e_loc).normalized()
    q = e.rotation_difference(D)
    ang_max = math.radians(float(os.environ.get("MUNECA_MAX", "18")))
    if q.angle > ang_max: q = q.__class__(q.axis, ang_max)
    t = M.translation.copy()
    h.matrix = W.inverted() @ (Matrix.Translation(t) @ q.to_matrix().to_4x4() @ Matrix.Translation(-t) @ M)
    bpy.context.view_layer.update()
muñeca()
hr, cr, er = hueco(tgt, body, "r")
Hm = W @ pb["mixamorig:RightHand"].matrix
# el arma cuelga hacia el meñique: su eje va hacia el lado del meñique
meñique = (W @ pb["mixamorig:RightHandPinky1"].head) - (W @ pb["mixamorig:RightHandIndex1"].head)
z = er if er.dot(Vector((0, 0.5, -1))) > 0 else -er          # el arma cuelga hacia atrás y abajo
fuera = Vector((0, -1, 0)); x = (fuera - z * fuera.dot(z)).normalized(); y = z.cross(x)
bpy.ops.import_scene.gltf(filepath=ARMA)
arma = [o for o in bpy.context.selected_objects if o.type == 'MESH'][0]
M = Matrix((x, y, z)).transposed().to_4x4(); M.translation = cr - z * AGARRE
arma.matrix_world = M
mw = arma.matrix_world.copy(); arma.parent = tgt; arma.parent_type = 'BONE'; arma.parent_bone = "mixamorig:RightHand"; arma.matrix_world = mw
accion = bpy.data.actions.new(NOMBRE); tgt.animation_data_create(); tgt.animation_data.action = accion
huesos = [b for b in pb if b.name in src.pose.bones]
for f in range(f0, f1 + 1):
    pose(f); muñeca()
    for b in huesos:
        b.keyframe_insert("rotation_quaternion", frame=f)
        if b.name == "mixamorig:Hips": b.keyframe_insert("location", frame=f)
bpy.data.objects.remove(src)
sc = bpy.context.scene; sc.frame_start, sc.frame_end = f0, f1
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, NOMBRE + ".blend"))
print("HORNEADO", NOMBRE, f0, f1)
