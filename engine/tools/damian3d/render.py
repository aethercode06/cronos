import bpy, sys, math, os
bpy.ops.wm.open_mainfile(filepath=sys.argv[-2]); OUT=sys.argv[-1]; os.makedirs(OUT, exist_ok=True)
for o in bpy.data.objects:
    if o.type=='MESH' and o.data.shape_keys:
        for kb in o.data.shape_keys.key_blocks:
            pass
            pass
            pass
sc=bpy.context.scene; sc.render.engine='CYCLES'; sc.cycles.samples=40; sc.cycles.use_denoising=True; sc.cycles.device='CPU'
sc.view_settings.view_transform='AgX'
w=bpy.data.worlds.new("w"); sc.world=w; w.use_nodes=True; w.node_tree.nodes['Background'].inputs[0].default_value=(0.02,0.022,0.03,1); w.node_tree.nodes['Background'].inputs[1].default_value=1.0
cam=bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera=cam
def luz(n,t,e,loc,rot,size=1.5,col=(1,1,1)):
    L=bpy.data.objects.new(n, bpy.data.lights.new(n,t)); L.data.energy=e; L.data.color=col
    if t=='AREA': L.data.size=size
    sc.collection.objects.link(L); L.location=loc; L.rotation_euler=[math.radians(r) for r in rot]; return L
luz("key",'AREA',350,(1.4,-2.6,2.5),(55,0,28),1.6,(1,0.93,0.85))
luz("rim",'AREA',220,(-1.3,1.8,2.4),(-55,0,200),1.2,(0.7,0.8,1))
luz("fill",'AREA',60,(-2,-2,1.2),(75,0,-45),3,(0.8,0.85,1))
suelo=bpy.data.meshes.new("s"); import bmesh; bm=bmesh.new(); bmesh.ops.create_grid(bm,x_segments=1,y_segments=1,size=6); bm.to_mesh(suelo)
so=bpy.data.objects.new("suelo",suelo); sc.collection.objects.link(so); ms=bpy.data.materials.new("s"); ms.use_nodes=True; ms.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value=(0.05,0.045,0.04,1); suelo.materials.append(ms)
vistas=[(0,4.4,1.0,(560,1000),45),(35,4.4,1.0,(560,1000),45),(160,4.4,1.0,(560,1000),45),(12,0.95,1.76,(800,800),55),(-25,1.6,1.25,(800,1000),50)]
for i,(ang,dist,zc,res,lens) in enumerate(vistas):
    a=math.radians(ang); sc.render.resolution_x,sc.render.resolution_y=res; cam.data.lens=lens
    cam.location=(dist*math.sin(a),-dist*math.cos(a),zc+(0.02 if i<3 else 0)); cam.rotation_euler=(math.radians(90),0,a)
    sc.render.filepath=os.path.join(OUT,f"r{i}.png"); bpy.ops.render.render(write_still=True)
