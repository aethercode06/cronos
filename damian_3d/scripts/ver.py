import bpy, sys, math, os
from mathutils import Vector
bpy.ops.wm.open_mainfile(filepath=sys.argv[-2])
OUT=sys.argv[-1]; os.makedirs(OUT, exist_ok=True)
sc=bpy.context.scene
for o in bpy.data.objects:
    if o.type=='MESH': print("OBJ", o.name, len(o.data.vertices), [m.name for m in o.data.materials], o.hide_render, o.parent.name if o.parent else None)
    if not (o.name.endswith("_export") or (o.parent and o.parent.name.endswith("_export"))): o.hide_render=True
h=bpy.data.objects["Human_export"]
dg=bpy.context.evaluated_depsgraph_get(); he=h.evaluated_get(dg)
zs=[(he.matrix_world@v.co).z for v in he.data.vertices]; xs=[(he.matrix_world@v.co).x for v in he.data.vertices]; ys=[(he.matrix_world@v.co).y for v in he.data.vertices]
print("ALTO", min(zs), max(zs), "ANCHO", min(xs), max(xs), "FONDO", min(ys), max(ys))
sc.render.engine='CYCLES'; sc.cycles.samples=48; sc.cycles.device='CPU'
w=bpy.data.worlds.new("w"); sc.world=w; w.use_nodes=True; w.node_tree.nodes['Background'].inputs[1].default_value=0.6
cam=bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera=cam
L=bpy.data.objects.new("L", bpy.data.lights.new("L",'AREA')); L.data.energy=400; L.data.size=2; sc.collection.objects.link(L)
L.location=(1.5,-3,2.6); L.rotation_euler=(math.radians(55),0,math.radians(28))
zt=max(zs)
for i,(ang,dist,zc,res,lens) in enumerate(((0,4.6,zt*0.5,(500,900),50),(40,4.6,zt*0.5,(500,900),50),(90,4.6,zt*0.5,(500,900),50),(15,0.9,zt-0.13,(600,600),50))):
    a=math.radians(ang); sc.render.resolution_x,sc.render.resolution_y=res; cam.data.lens=lens
    cam.location=(dist*math.sin(a),-dist*math.cos(a),zc); cam.rotation_euler=(math.radians(90),0,a)
    sc.render.filepath=os.path.join(OUT,f"v{i}.png"); bpy.ops.render.render(write_still=True)
