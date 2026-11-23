"""Damián empuñando cada arma: brazo caído, puño cerrado, mango atravesando el puño."""
import bpy, sys, math, os
import numpy as np
from mathutils import Matrix, Vector, Euler
OUT = sys.argv[-1]; os.makedirs(OUT, exist_ok=True)
ARMAS = {  # arma: (punta hacia el lado del pulgar (+1) o del meñique (-1), giro del filo en grados)
 "w_machete": (1, 0, 30), "w_hacha_vieja": (1, 180, 38), "w_motosierra_vintage": (1, 90, -25)}
GIROZ = {"w_motosierra_vintage": -38}
CURL = float(os.environ.get("CURL", "65")); PUL = os.environ.get("PUL", "Z")
BRAZO = [float(x) for x in os.environ.get("BRAZO", "0,0,50").split(",")]
def apuntar(rig, pb, nombre, direccion, giro_eje=None):
    """gira un hueso para que apunte en una dirección del mundo (manteniendo su raíz)"""
    bpy.context.view_layer.update()
    M = rig.matrix_world @ pb[nombre].matrix
    actual = M.to_3x3().col[1].normalized()
    q = actual.rotation_difference(direccion.normalized())
    R = q.to_matrix().to_4x4()
    t = M.translation.copy()
    nueva = Matrix.Translation(t) @ R @ Matrix.Translation(-t) @ M
    pb[nombre].matrix = rig.matrix_world.inverted() @ nueva
    bpy.context.view_layer.update()
def montar(nom, desv=0):
    bpy.ops.wm.open_mainfile(filepath="/home/claude/damian/out/damian.blend")
    rig = bpy.data.objects["rig"]; pb = rig.pose.bones; body = bpy.data.objects["cuerpo"]
    for b in pb: b.rotation_mode = 'XYZ'
    apuntar(rig, pb, "upperarm_r", Vector((-0.22, 0.02, -1)))
    apuntar(rig, pb, "lowerarm_r", Vector((-0.08, -0.3, -1)))
    apuntar(rig, pb, "hand_r", Vector((-0.04, -0.2, -1)))
    # muñeca doblada hacia el meñique: la punta del arma cae hacia el suelo
    if desv:
        M = rig.matrix_world @ pb["hand_r"].matrix
        Wl = lambda n: rig.matrix_world @ pb[n].head
        ej = (Wl("index_01_r") - Wl("pinky_01_r")).normalized(); ad = (Wl("middle_01_r") - Wl("hand_r")).normalized()
        n = ej.cross(ad).normalized()
        t = M.translation.copy()
        for sg in (1, -1):
            R = Matrix.Rotation(math.radians(abs(desv) * sg), 4, n)
            prueba = Matrix.Translation(t) @ R @ Matrix.Translation(-t) @ M
            pb["hand_r"].matrix = rig.matrix_world.inverted() @ prueba; bpy.context.view_layer.update()
            ej2 = (Wl("index_01_r") - Wl("pinky_01_r")).normalized()
            if (ej2.z < ej.z) == (desv > 0): break
    apuntar(rig, pb, "upperarm_l", Vector((0.22, 0.02, -1)))
    apuntar(rig, pb, "lowerarm_l", Vector((0.08, -0.2, -1)))
    apuntar(rig, pb, "hand_l", Vector((0.04, -0.1, -1)))
    for d in ("index", "middle", "ring", "pinky"):
        for k, f in ((1, 1.0), (2, 1.15), (3, 0.9)):
            pb[f"{d}_0{k}_r"].rotation_euler = Euler((math.radians(CURL * f), 0, 0))
    for k, f in ((2, 0.6), (3, 0.6)):
        e = [0, 0, 0]; e[{'X': 0, 'Z': 2, '-X': 0, '-Z': 2}[PUL]] = math.radians((55 if '-' not in PUL else -55) * f)
        pb[f"thumb_0{k}_r"].rotation_euler = Euler(e)
    bpy.context.view_layer.update()
    W = lambda n: rig.matrix_world @ pb[n].head
    i1, p1 = W("index_01_r"), W("pinky_01_r")
    eje = (i1 - p1).normalized()
    # centro del hueco del puño: media de los vértices de las falanges y la palma junto a los nudillos
    dg = bpy.context.evaluated_depsgraph_get(); be = body.evaluated_get(dg); me = be.to_mesh()
    gids = {body.vertex_groups[f"{d}_0{k}_r"].index for d in ("index", "middle", "ring", "pinky") for k in (1, 2)}
    pts = [body.matrix_world @ me.vertices[v.index].co for v in body.data.vertices if any(g.group in gids and g.weight > 0.5 for g in v.groups)]
    be.to_mesh_clear()
    centro = sum(pts, Vector()) / len(pts)
    adelante = (W("middle_01_r") - W("hand_r")).normalized()
    return rig, eje, centro, adelante
for nom, (lado, giro, desv) in ARMAS.items():
    if os.environ.get('SOLO') and nom != os.environ['SOLO']: continue
    rig, eje, centro, adelante = montar(nom, desv)
    bpy.ops.import_scene.gltf(filepath=f"/home/claude/damian/armas/{nom}.glb")
    arma = [o for o in bpy.context.selected_objects if o.type == 'MESH'][0]
    z = eje * lado
    x = (adelante - z * adelante.dot(z)).normalized()
    x = Matrix.Rotation(math.radians(giro), 3, z) @ x
    y = z.cross(x)
    M = Matrix((x, y, z)).transposed().to_4x4(); M.translation = centro
    if nom in GIROZ: M = Matrix.Translation(centro) @ Matrix.Rotation(math.radians(GIROZ[nom]), 4, 'Z') @ Matrix.Translation(-centro) @ M
    arma.matrix_world = M
    bpy.context.view_layer.update()
    import numpy as _np
    Vw = _np.array([arma.matrix_world @ v.co for v in arma.data.vertices]); dd = _np.linalg.norm(Vw - _np.array(centro), axis=1)
    print('DEBUG', nom, 'centro', centro, 'dist min', dd.min(), 'origen', arma.matrix_world.translation)
    mw = arma.matrix_world.copy(); arma.parent = rig; arma.parent_type = 'BONE'; arma.parent_bone = "hand_r"; arma.matrix_world = mw
    sc = bpy.context.scene; sc.render.engine = 'CYCLES'; sc.cycles.samples = 32; sc.cycles.use_denoising = True; sc.view_settings.view_transform = 'AgX'
    w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True; w.node_tree.nodes['Background'].inputs[0].default_value = (0.03, 0.03, 0.04, 1)
    l = bpy.data.objects.new('l', bpy.data.lights.new('l', 'SUN')); l.data.energy = 3.5; sc.collection.objects.link(l); l.rotation_euler = (math.radians(55), 0, math.radians(-30))
    cam = bpy.data.objects.new("c", bpy.data.cameras.new("c")); sc.collection.objects.link(cam); sc.camera = cam
    # vista del puño de cerca y vista entera
    for tag, off, lens, res in (("mano", Vector((-0.25, -0.35, 0.05)), 35, (500, 500)), ("mano2", Vector((-0.42, 0.05, 0.02)), 35, (500, 500)), ("cuerpo", Vector((-1.4, -2.8, -0.1)), 35, (600, 900))):
        tgt = centro if tag == "mano" else Vector((0, 0, 1.05))
        cam.location = tgt + off; cam.rotation_euler = (tgt - cam.location).to_track_quat('-Z', 'Y').to_euler(); cam.data.lens = lens
        sc.render.resolution_x, sc.render.resolution_y = res
        sc.render.filepath = os.path.join(OUT, f"{nom}_{tag}.png"); bpy.ops.render.render(write_still=True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, nom + ".blend"))
