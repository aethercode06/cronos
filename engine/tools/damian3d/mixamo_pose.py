import bpy, sys, math, os
sys.path.insert(0, "/home/claude/damian/scr")
from retarget import importar_mixamo, copiar_mixamo, mover_manos
from empunar import hueco
from mathutils import Vector, Matrix
bpy.ops.wm.open_mainfile(filepath="/home/claude/damian/out/damian.blend")
tgt = bpy.data.objects["rig"]; body = bpy.data.objects["cuerpo"]
src, nuevos = importar_mixamo("/home/claude/mixamo/Great_Sword_Idle.fbx")
src.animation_data.action = bpy.data.actions[0]
copiar_mixamo(src, tgt, 1)
import os
mover_manos(tgt, Vector([float(x) for x in os.environ.get('MOV','0,-0.2,0').split(',')]))
pbx=tgt.pose.bones; print('MANOS', tgt.matrix_world@pbx['hand_r'].head, tgt.matrix_world@pbx['hand_l'].head)
for o in nuevos: bpy.data.objects.remove(o)
sc = bpy.context.scene; sc.render.engine='CYCLES'; sc.cycles.samples=24; sc.cycles.use_denoising=True; sc.view_settings.view_transform='AgX'
w=bpy.data.worlds.new("w"); sc.world=w; w.use_nodes=True; w.node_tree.nodes['Background'].inputs[0].default_value=(0.05,0.05,0.06,1)
for ang,en in ((50,3),(-60,1.2),(180,1.0)):
    l=bpy.data.objects.new('l', bpy.data.lights.new('l','SUN')); l.data.energy=en; sc.collection.objects.link(l); l.rotation_euler=(math.radians(55),0,math.radians(ang))
cam=bpy.data.objects.new("c", bpy.data.cameras.new("c")); sc.collection.objects.link(cam); sc.camera=cam
pb=tgt.pose.bones; Wm=tgt.matrix_world
for tag, pos, tg, res in (("cuerpo", Vector((-1.6,-3.0,1.3)), Vector((0,0,1.0)), (500,800)), ("cuerpo2", Vector((2.2,-2.4,1.3)), Vector((0,0,1.0)), (500,800))):
    cam.location=pos; cam.rotation_euler=(tg-cam.location).to_track_quat('-Z','Y').to_euler(); cam.data.lens=35
    sc.render.resolution_x,sc.render.resolution_y=res; sc.render.filepath=f"/tmp/mx/{tag}.png"; bpy.ops.render.render(write_still=True)
for lado in ("r","l"):
    c=Wm@pb[f"middle_02_{lado}"].head
    for i,dv in enumerate((Vector((-1,-0.5,0.2)) if lado=="r" else Vector((1,-0.5,0.2)), Vector((0,-1,0.3)))):
        cam.location=c+dv.normalized()*0.28; cam.rotation_euler=(c-cam.location).to_track_quat('-Z','Y').to_euler(); cam.data.lens=40
        sc.render.resolution_x=sc.render.resolution_y=400; sc.render.filepath=f"/tmp/mx/mano_{lado}{i}.png"; bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath="/tmp/mx/pose_gs_idle.blend")
