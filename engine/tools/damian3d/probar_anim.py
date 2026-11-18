import bpy, sys, math, os
sys.path.insert(0, "/home/claude/damian/scr")
from mixamo_play import cargar_anim, aplicar
from mathutils import Vector
bpy.ops.wm.open_mainfile(filepath="/home/claude/damian/out/damian_mixamo.blend")
tgt = bpy.data.objects["Damian_rig"]
src = cargar_anim("/home/claude/mixamo/Great_Sword_Idle.fbx")
aplicar(src, tgt, 1, float(os.environ.get("BRAZOS", "12")))
sc = bpy.context.scene; sc.render.engine='CYCLES'; sc.cycles.samples=24; sc.cycles.use_denoising=True; sc.view_settings.view_transform='AgX'
w=bpy.data.worlds.new("w"); sc.world=w; w.use_nodes=True; w.node_tree.nodes['Background'].inputs[0].default_value=(0.05,0.05,0.06,1)
for ang,en in ((50,3),(-60,1.2),(180,1.0)):
    l=bpy.data.objects.new('l', bpy.data.lights.new('l','SUN')); l.data.energy=en; sc.collection.objects.link(l); l.rotation_euler=(math.radians(55),0,math.radians(ang))
cam=bpy.data.objects.new("c", bpy.data.cameras.new("c")); sc.collection.objects.link(cam); sc.camera=cam
pb=tgt.pose.bones; W=tgt.matrix_world
for tag,pos,tg,res in (("c0",Vector((-1.6,-3.0,1.3)),Vector((0,-0.2,1.0)),(500,800)),("c1",Vector((2.0,-2.6,1.2)),Vector((0,-0.2,1.0)),(500,800)),("c2",Vector((0,-1.4,1.25)),Vector((0,-0.3,1.15)),(700,700))):
    cam.location=pos; cam.rotation_euler=(tg-cam.location).to_track_quat('-Z','Y').to_euler(); cam.data.lens=35
    sc.render.resolution_x,sc.render.resolution_y=res; sc.render.filepath=f"/tmp/mx/n_{tag}.png"; bpy.ops.render.render(write_still=True)
for lado in ("Right","Left"):
    c=W@pb[f"mixamorig:{lado}HandMiddle2"].head
    cam.location=c+Vector((-0.6 if lado=="Right" else 0.6,-1,0.4)).normalized()*0.3; cam.rotation_euler=(c-cam.location).to_track_quat('-Z','Y').to_euler(); cam.data.lens=40
    sc.render.resolution_x=sc.render.resolution_y=400; sc.render.filepath=f"/tmp/mx/n_mano{lado}.png"; bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath="/tmp/mx/damian_gsidle.blend")
