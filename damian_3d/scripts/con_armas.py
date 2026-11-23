"""Render de Damián con cada arma en la mano derecha (colocada en el mundo según la palma)."""
import bpy, sys, math, os
import numpy as np
from mathutils import Matrix, Vector, Euler
OUT = sys.argv[-1]; os.makedirs(OUT, exist_ok=True)
POSES = {  # arma: (dirección de la punta en el mundo, dirección del filo)
 "w_machete": (Vector((0.1, -0.35, -1.0)), Vector((1, 0, 0))),
 "w_hacha_vieja": (Vector((0.1, -0.2, -1.0)), Vector((1, 0, 0))),
 "w_motosierra_vintage": (Vector((0.15, -1.0, -0.5)), Vector((0, 0, 1))),
}
for nom, (punta, filo) in POSES.items():
    bpy.ops.wm.open_mainfile(filepath="/home/claude/damian/out/damian.blend")
    rig = bpy.data.objects["rig"]; body = bpy.data.objects["cuerpo"]
    pb = rig.pose.bones
    for b in pb: b.rotation_mode = 'XYZ'
    pb["upperarm_r"].rotation_euler = Euler((math.radians(-55), 0, 0))
    pb["upperarm_l"].rotation_euler = Euler((math.radians(-55), 0, 0))
    pb["lowerarm_r"].rotation_euler = Euler((0, 0, math.radians(-15)))
    pb["spine_03"].rotation_euler = Euler((math.radians(10), 0, 0))
    pb["head"].rotation_euler = Euler((math.radians(12), 0, 0))
    for d in ("index", "middle", "ring", "pinky"):
        for k in (1, 2, 3):
            n = f"{d}_0{k}_r"
            if n in pb: pb[n].rotation_euler = Euler((math.radians(70), 0, 0)) if False else Euler((0, 0, math.radians(-70)))
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get(); be = body.evaluated_get(dg); me = be.to_mesh()
    g = body.vertex_groups["hand_r"].index
    idx = [v.index for v in body.data.vertices if any(gg.group == g and gg.weight > 0.6 for gg in v.groups)]
    palma = sum((body.matrix_world @ me.vertices[i].co for i in idx), Vector()) / len(idx)
    be.to_mesh_clear()
    bpy.ops.import_scene.gltf(filepath=f"/home/claude/damian/armas/{nom}.glb")
    arma = [o for o in bpy.context.selected_objects if o.type == 'MESH'][0]
    z = punta.normalized(); x = (filo - z * filo.dot(z)).normalized(); y = z.cross(x)
    M = Matrix((x, y, z)).transposed().to_4x4(); M.translation = palma + Vector((0, -0.01, 0))
    arma.matrix_world = M
    # que siga a la mano
    mw = arma.matrix_world.copy(); arma.parent = rig; arma.parent_type = 'BONE'; arma.parent_bone = "hand_r"; arma.matrix_world = mw
    sc = bpy.context.scene; sc.render.engine = 'CYCLES'; sc.cycles.samples = 48; sc.cycles.use_denoising = True; sc.view_settings.view_transform = 'AgX'
    w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True; w.node_tree.nodes['Background'].inputs[0].default_value = (0.005, 0.006, 0.01, 1)
    cam = bpy.data.objects.new("c", bpy.data.cameras.new("c")); sc.collection.objects.link(cam); sc.camera = cam
    cam.location = (-0.9, -2.3, 1.25); cam.rotation_euler = (math.radians(88), 0, math.radians(-20)); cam.data.lens = 32
    sp = bpy.data.objects.new("lin", bpy.data.lights.new("lin", 'SPOT')); sp.data.energy = 300; sp.data.spot_size = math.radians(45); sp.data.spot_blend = 0.6
    sp.data.color = (1, 0.92, 0.8); sc.collection.objects.link(sp); sp.location = (-0.7, -2.0, 1.3); sp.rotation_euler = (math.radians(92), 0, math.radians(-18))
    r = bpy.data.objects.new("rim", bpy.data.lights.new("rim", 'AREA')); r.data.energy = 80; r.data.color = (0.5, 0.6, 1); sc.collection.objects.link(r); r.location = (1, 1.5, 2.3); r.rotation_euler = (math.radians(-50), 0, math.radians(150))
    import bmesh
    m2 = bpy.data.meshes.new("s"); bm = bmesh.new(); bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=8); bm.to_mesh(m2)
    so = bpy.data.objects.new("suelo", m2); sc.collection.objects.link(so)
    ms = bpy.data.materials.new("s"); ms.use_nodes = True; ms.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.06, 0.045, 0.035, 1); m2.materials.append(ms)
    sc.render.resolution_x = 800; sc.render.resolution_y = 1100
    sc.render.filepath = os.path.join(OUT, nom + ".png"); bpy.ops.render.render(write_still=True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, nom + ".blend"))
