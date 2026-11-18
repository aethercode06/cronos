import bpy, sys, math, os
sys.path.insert(0, "/home/claude/damian/scr")
from empunar import hueco
from mathutils import Vector, Matrix
bpy.ops.wm.open_mainfile(filepath="/tmp/mx/pose_gs_idle.blend")
tgt = bpy.data.objects["rig"]; body = bpy.data.objects["cuerpo"]
hr, cr, er = hueco(tgt, body, "r"); hl, cl, el = hueco(tgt, body, "l")
eje = (cr - cl).normalized()
print("HUECOS", round(hr,4), round(hl,4), "distancia", round((cr-cl).length,3), "angulo con ejes de puño", round(math.degrees(eje.angle(er if er.dot(eje)>0 else -er)),1), round(math.degrees(eje.angle(el if el.dot(eje)>0 else -el)),1))
NOM = os.environ.get("ARMA", "w_hacha_vieja")
bpy.ops.import_scene.gltf(filepath=f"/home/claude/damian/armas/{NOM}.glb")
arma = [o for o in bpy.context.selected_objects if o.type == 'MESH'][0]
pb = tgt.pose.bones; Wm = tgt.matrix_world
# el filo hacia delante y abajo (fuera del cuerpo)
fuera = Vector((0, -1, -0.3))
z = eje; x = (fuera - z * fuera.dot(z)).normalized(); y = z.cross(x)
M = Matrix((x, y, z)).transposed().to_4x4()
off = float(os.environ.get("OFF", "-0.07"))   # punto del arma (en su eje) que queda en la mano izquierda
M.translation = cl - z * off
arma.matrix_world = M
mw = arma.matrix_world.copy(); arma.parent = tgt; arma.parent_type = 'BONE'; arma.parent_bone = "hand_r"; arma.matrix_world = mw
sc = bpy.context.scene
cam = bpy.data.objects.get("c")
for i, (c, dv) in enumerate(((cr, Vector((-1,-0.5,0.3))), (cr, Vector((0.3,-1,0.4))), (cl, Vector((1,-0.6,0.2))), ((cr+cl)/2, Vector((0,-1,-0.6))))):
    cam.location = c + dv.normalized() * 0.32; cam.rotation_euler = (c - cam.location).to_track_quat('-Z','Y').to_euler(); cam.data.lens = 40
    sc.render.resolution_x = sc.render.resolution_y = 420; sc.render.filepath = f"/tmp/mx/{NOM}_m{i}.png"; bpy.ops.render.render(write_still=True)
for j, pos in enumerate((Vector((-1.6,-3.0,1.3)), Vector((2.0,-2.6,1.2)))):
    cam.location = pos; cam.rotation_euler = (Vector((0,-0.2,0.9)) - cam.location).to_track_quat('-Z','Y').to_euler(); cam.data.lens = 35
    sc.render.resolution_x, sc.render.resolution_y = 500, 800; sc.render.filepath = f"/tmp/mx/{NOM}_c{j}.png"; bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=f"/tmp/mx/{NOM}_gs_idle.blend")
