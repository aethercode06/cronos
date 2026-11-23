"""Damián con cada arma colgando del puño (pose Idle_Lantern de la UAL2): agarre por el hueco real del puño."""
import bpy, sys, math, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from retarget import importar_ual, copiar_pose, copiar_dedos
from empunar import hueco
from mathutils import Vector, Matrix
OUT = sys.argv[-1]; os.makedirs(OUT, exist_ok=True)
POSE = (os.environ.get("ACC", "colgando"), int(os.environ.get("FR", "1")))
# asa: punto local de agarre, eje local del asa, vector local que mira a DIR, DIR (None = punta hacia abajo)
ARMAS = {
 "w_machete": (Vector((0, 0, 0)), Vector((0, 0, 1)), Vector((1, 0, 0)), None),
 "w_hacha_vieja": (Vector((0, 0, 0)), Vector((0, 0, 1)), Vector((1, 0, 0)), None),
 "w_motosierra_vintage": (Vector((-0.226, 0.016, 0.366)), Vector((0, 1, 0)), Vector((0, 0, 1)), Vector((0, -1, -1.2))),
}
SOLO = os.environ.get("SOLO")
for nom, (G, A, F, D) in ARMAS.items():
    if SOLO and nom != SOLO: continue
    bpy.ops.wm.open_mainfile(filepath="/home/claude/damian/out/damian.blend")
    tgt = bpy.data.objects["rig"]; body = bpy.data.objects["cuerpo"]
    src, nuevos = importar_ual()
    if POSE[0] == "colgando":
        from agarre_brazos import brazos_colgando
        brazos_colgando(tgt)
    else:
        copiar_pose(src, tgt, *POSE)
    copiar_dedos(src, tgt, 'Sword_Regular_A', 1)   # mano agarrando un mango de espada (hueco del grosor justo)
    h, c, e = hueco(tgt, body)
    pb = tgt.pose.bones; Wm = tgt.matrix_world
    adel = ((Wm @ pb["middle_01_r"].head) - (Wm @ pb["hand_r"].head)).normalized()
    if D is None:
        if e.z > 0: e = -e                      # la punta cuelga hacia abajo
        Dw = adel                               # el filo mira hacia las puntas de los dedos
    else:
        Dw = D
    R1 = A.rotation_difference(e).to_matrix()
    f1 = R1 @ F; f1 = (f1 - e * f1.dot(e)).normalized(); d1 = (Dw - e * Dw.dot(e)).normalized()
    ang = math.atan2(f1.cross(d1).dot(e), f1.dot(d1))
    R = Matrix.Rotation(ang, 3, e) @ R1
    bpy.ops.import_scene.gltf(filepath=f"/home/claude/damian/armas/{nom}.glb")
    arma = [o for o in bpy.context.selected_objects if o.type == 'MESH'][0]
    M = R.to_4x4(); M.translation = c - R @ G; arma.matrix_world = M
    mw = arma.matrix_world.copy(); arma.parent = tgt; arma.parent_type = 'BONE'; arma.parent_bone = "hand_r"; arma.matrix_world = mw
    for o in nuevos: bpy.data.objects.remove(o)
    sc = bpy.context.scene; sc.render.engine = 'CYCLES'; sc.cycles.samples = int(os.environ.get("MUESTRAS", "32")); sc.cycles.use_denoising = True; sc.view_settings.view_transform = 'AgX'
    w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True; w.node_tree.nodes['Background'].inputs[0].default_value = (0.04, 0.04, 0.05, 1)
    for a_, en in ((50, 3), (-60, 1.2), (180, 1.0)):
        l = bpy.data.objects.new('l', bpy.data.lights.new('l', 'SUN')); l.data.energy = en; sc.collection.objects.link(l); l.rotation_euler = (math.radians(55), 0, math.radians(a_))
    cam = bpy.data.objects.new("c", bpy.data.cameras.new("c")); sc.collection.objects.link(cam); sc.camera = cam
    for i, dv in enumerate((Vector((-1, -0.3, 0.2)), Vector((-0.3, -1, 0.15)), Vector((-0.4, 0.3, -0.8)))):
        cam.location = c + dv.normalized() * 0.3; cam.rotation_euler = (c - cam.location).to_track_quat('-Z', 'Y').to_euler(); cam.data.lens = 40
        sc.render.resolution_x = sc.render.resolution_y = 450; sc.render.filepath = os.path.join(OUT, f"{nom}_mano{i}.png"); bpy.ops.render.render(write_still=True)
    cam.location = Vector((-1.5, -2.8, 1.3)); cam.rotation_euler = (Vector((-0.1, 0, 1.0)) - cam.location).to_track_quat('-Z', 'Y').to_euler(); cam.data.lens = 35
    sc.render.resolution_x, sc.render.resolution_y = 600, 900; sc.render.filepath = os.path.join(OUT, f"{nom}_cuerpo.png"); bpy.ops.render.render(write_still=True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, nom + ".blend"))
