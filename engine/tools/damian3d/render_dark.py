import bpy, sys, math, os
bpy.ops.wm.open_mainfile(filepath=sys.argv[-2]); OUT=sys.argv[-1]
sc=bpy.context.scene; sc.render.engine='CYCLES'; sc.cycles.samples=64; sc.cycles.use_denoising=True; sc.view_settings.view_transform='AgX'
w=bpy.data.worlds.new("w"); sc.world=w; w.use_nodes=True; w.node_tree.nodes['Background'].inputs[0].default_value=(0.004,0.005,0.008,1)
cam=bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera=cam
cam.location=(0.5,-1.75,1.4); cam.rotation_euler=(math.radians(90),0,math.radians(16)); cam.data.lens=32
sp=bpy.data.objects.new("lin", bpy.data.lights.new("lin",'SPOT')); sp.data.energy=260; sp.data.spot_size=math.radians(38); sp.data.spot_blend=0.6
sp.data.color=(1,0.92,0.8); sc.collection.objects.link(sp); sp.location=(0.35,-1.6,1.3); sp.rotation_euler=(math.radians(95),0,math.radians(12))
r=bpy.data.objects.new("rim", bpy.data.lights.new("rim",'AREA')); r.data.energy=60; r.data.color=(0.5,0.6,1); sc.collection.objects.link(r); r.location=(-1,1.5,2.3); r.rotation_euler=(math.radians(-50),0,math.radians(210))
import bmesh
me=bpy.data.meshes.new("s"); bm=bmesh.new(); bmesh.ops.create_grid(bm,x_segments=1,y_segments=1,size=8); bm.to_mesh(me)
so=bpy.data.objects.new("suelo",me); sc.collection.objects.link(so)
m=bpy.data.materials.new("s"); m.use_nodes=True; m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value=(0.06,0.045,0.035,1); me.materials.append(m)
sc.render.resolution_x=900; sc.render.resolution_y=1200; sc.render.filepath=OUT; bpy.ops.render.render(write_still=True)
