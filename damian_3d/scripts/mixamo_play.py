"""Reproduce una animación de Mixamo en el esqueleto Mixamo de Damián (copia directa hueso a hueso)."""
import bpy, math
from mathutils import Matrix, Vector, Quaternion

def cargar_anim(ruta):
    antes = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=ruta)
    nuevos = [o for o in bpy.data.objects if o not in antes]
    src = [o for o in nuevos if o.type == 'ARMATURE'][0]
    for o in nuevos:
        if o.type == 'MESH': bpy.data.objects.remove(o)
    return src

def aplicar(src, tgt, frame, brazos=12.0):
    bpy.context.scene.frame_set(int(frame)); bpy.context.view_layer.update()
    hs = src.data.bones["mixamorig:Hips"]; ht = tgt.data.bones["mixamorig:Hips"]
    esc = (tgt.matrix_world @ ht.head_local).z / max((src.matrix_world @ hs.head_local).z, 1e-6)
    for b in tgt.pose.bones:
        if b.name not in src.pose.bones: continue
        s = src.pose.bones[b.name]
        b.rotation_mode = 'QUATERNION'
        q = s.rotation_quaternion if s.rotation_mode == 'QUATERNION' else s.rotation_euler.to_quaternion()
        b.rotation_quaternion = q
        if b.name == "mixamorig:Hips":
            # desplazamiento de la cadera (en el espacio del hueso), a escala de Damián
            b.location = s.location * (src.matrix_world.to_scale().x / tgt.matrix_world.to_scale().x) * esc
    bpy.context.view_layer.update()
    if brazos:
        # «Character Arm-Space»: separa los brazos del cuerpo (es mucho más ancho que el maniquí)
        W = tgt.matrix_world
        for lado, sg in (("Right", -1), ("Left", 1)):
            pb = tgt.pose.bones[f"mixamorig:{lado}Arm"]
            M = W @ pb.matrix; t = M.translation.copy()
            fw = Vector((0, -1, 0))
            R = Matrix.Rotation(math.radians(brazos) * sg * -1, 4, fw)
            pb.matrix = W.inverted() @ (Matrix.Translation(t) @ R @ Matrix.Translation(-t) @ M)
            bpy.context.view_layer.update()
