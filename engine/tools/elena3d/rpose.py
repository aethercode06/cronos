import bpy, sys, math
bpy.ops.wm.open_mainfile(filepath=sys.argv[-2])
sc=bpy.context.scene; sc.render.engine='CYCLES'; sc.cycles.samples=16
sc.render.resolution_x=360; sc.render.resolution_y=600
w=bpy.data.worlds.new("w"); sc.world=w; w.use_nodes=True; w.node_tree.nodes['Background'].inputs[1].default_value=1.6
cam=bpy.data.objects.new("cam",bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera=cam
rig=bpy.data.objects['Elena']
k=0
for act,f in (('idle',20),('walk',8),('run',5),('attack',12)):
    rig.animation_data.action=bpy.data.actions[act]; sc.frame_set(f)
    for loc,rot in (((0,-4.0,0.95),(90,0,0)),((4.0,0,0.95),(90,0,90))):
        cam.location=loc; cam.rotation_euler=[math.radians(r) for r in rot]
        sc.render.filepath=sys.argv[-1]+f"_{k}.png"; bpy.ops.render.render(write_still=True); k+=1
