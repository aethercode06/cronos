import bpy, math
from mathutils import Vector, Matrix
def apuntar(rig, nombre, direccion):
    pb = rig.pose.bones
    bpy.context.view_layer.update()
    M = rig.matrix_world @ pb[nombre].matrix
    q = M.to_3x3().col[1].normalized().rotation_difference(direccion.normalized())
    t = M.translation.copy()
    pb[nombre].matrix = rig.matrix_world.inverted() @ (Matrix.Translation(t) @ q.to_matrix().to_4x4() @ Matrix.Translation(-t) @ M)
    bpy.context.view_layer.update()
def brazos_colgando(rig):
    """brazos caídos junto al cuerpo, un poco separados (es muy grueso) y con el codo algo doblado"""
    apuntar(rig, "upperarm_r", Vector((-0.24, 0.04, -1)))
    apuntar(rig, "lowerarm_r", Vector((-0.1, -0.3, -1)))
    apuntar(rig, "hand_r", Vector((-0.06, -0.22, -1)))
    apuntar(rig, "upperarm_l", Vector((0.24, 0.04, -1)))
    apuntar(rig, "lowerarm_l", Vector((0.1, -0.2, -1)))
    apuntar(rig, "hand_l", Vector((0.05, -0.12, -1)))
