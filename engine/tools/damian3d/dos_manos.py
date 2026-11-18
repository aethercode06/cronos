"""Armas a dos manos: la mano izquierda se coloca sobre el eje del puño derecho (IK de 2 huesos), como hacen los juegos."""
import bpy, math
from mathutils import Vector, Matrix
from empunar import hueco

def ik_mano(tgt, lado, destino_mano, giro_mano):
    W = tgt.matrix_world; pb = tgt.pose.bones
    L = "Right" if lado == "r" else "Left"
    fa = pb[f"mixamorig:{L}ForeArm"]
    e = bpy.data.objects.new("ik_t", None); bpy.context.scene.collection.objects.link(e); e.location = destino_mano
    codo = (W @ fa.matrix).translation
    p = bpy.data.objects.new("ik_p", None); bpy.context.scene.collection.objects.link(p)
    p.location = codo + Vector((0.35 if lado == "l" else -0.35, 0.35, -0.05))
    c = fa.constraints.new('IK'); c.target = e; c.pole_target = p; c.chain_count = 2; c.name = "ik_tmp"
    bpy.context.view_layer.update()
    vis = {n: W.inverted() @ (W @ pb[n].matrix) for n in (f"mixamorig:{L}Arm", f"mixamorig:{L}ForeArm")}
    fa.constraints.remove(fa.constraints["ik_tmp"])
    for n in (f"mixamorig:{L}Arm", f"mixamorig:{L}ForeArm"):
        pb[n].matrix = vis[n]; bpy.context.view_layer.update()
    h = pb[f"mixamorig:{L}Hand"]; M = giro_mano.to_4x4(); M.translation = (W @ h.matrix).translation
    h.matrix = W.inverted() @ M; bpy.context.view_layer.update()
    bpy.data.objects.remove(e); bpy.data.objects.remove(p)

def agarre_dos_manos(tgt, body, separacion=0.17, iter=4):
    W = tgt.matrix_world; pb = tgt.pose.bones
    hr, cr, er = hueco(tgt, body, "r")
    for k in range(iter):
        hl, cl, el = hueco(tgt, body, "l")
        if el.dot(er) < 0: el = -el
        q = el.rotation_difference(er).to_matrix()
        H = W @ pb["mixamorig:LeftHand"].matrix
        Rn = q @ H.to_3x3().normalized()
        cl_rot = H.translation + q @ (cl - H.translation)           # dónde quedaría el hueco al girar la mano
        deseado = cr - er * separacion
        ik_mano(tgt, "l", H.translation + (deseado - cl_rot), Rn)
    hl, cl, el = hueco(tgt, body, "l")
    if el.dot(er) < 0: el = -el
    print("dos manos: fuera del eje", round(((cl - cr).cross(er)).length, 4), "ángulo", round(math.degrees(er.angle(el)), 1))
    return cr, er, cl
