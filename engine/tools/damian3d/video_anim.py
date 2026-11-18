import bpy, sys, os, math
from mathutils import Vector
BL, OUT = sys.argv[-2:]
bpy.ops.wm.open_mainfile(filepath=BL)
sc = bpy.context.scene; sc.render.engine = 'CYCLES'; sc.cycles.samples = int(os.environ.get("MUESTRAS", "12")); sc.cycles.use_denoising = True
sc.view_settings.view_transform = 'AgX'
for o in [o for o in bpy.data.objects if o.type in ('LIGHT', 'CAMERA')]: bpy.data.objects.remove(o)
w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True; w.node_tree.nodes['Background'].inputs[0].default_value = (0.02, 0.022, 0.03, 1)
def luz(t, e, loc, tgt, col=(1, 1, 1), size=1.5):
    L = bpy.data.objects.new("l", bpy.data.lights.new("l", t)); L.data.energy = e; L.data.color = col
    if t == 'AREA': L.data.size = size
    sc.collection.objects.link(L); L.location = loc; L.rotation_euler = (Vector(tgt) - Vector(loc)).to_track_quat('-Z', 'Y').to_euler()
luz('AREA', 420, (-1.6, -2.4, 2.6), (0, 0, 1.1), (1, 0.92, 0.82), 2)
luz('AREA', 200, (1.4, 1.8, 2.4), (0, 0, 1.2), (0.6, 0.7, 1.0), 1.5)
luz('AREA', 70, (2, -2.2, 0.8), (0, 0, 1.0), (0.8, 0.85, 1), 3)
import bmesh
me = bpy.data.meshes.new("s"); bm = bmesh.new(); bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=10); bm.to_mesh(me)
so = bpy.data.objects.new("suelo", me); sc.collection.objects.link(so)
m = bpy.data.materials.new("s"); m.use_nodes = True; m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.07, 0.06, 0.05, 1); me.materials.append(m)
cam = bpy.data.objects.new("c", bpy.data.cameras.new("c")); sc.collection.objects.link(cam); sc.camera = cam
cam.location = Vector((-1.7, -3.1, 1.45)); cam.rotation_euler = (Vector((0, -0.2, 1.0)) - cam.location).to_track_quat('-Z', 'Y').to_euler(); cam.data.lens = 33
sc.render.resolution_x, sc.render.resolution_y = 540, 810
sc.render.image_settings.file_format = 'PNG'
os.makedirs(OUT, exist_ok=True)
sc.render.filepath = os.path.join(OUT, "f_")
bpy.ops.render.render(animation=True)
