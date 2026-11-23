"""Agarre realista: la mano rodea el mango. Cada falange se dobla hasta tocar la superficie del arma."""
import bpy, sys, math, os
import numpy as np
from mathutils import Matrix, Vector, Euler, Quaternion
from mathutils.bvhtree import BVHTree
OUT = sys.argv[-1]; os.makedirs(OUT, exist_ok=True)
# arma: (desviación de la muñeca hacia el meñique en grados, giro del filo, giro vertical extra)
ARMAS = {"w_machete": (28, 0, 0), "w_hacha_vieja": (36, 180, 0), "w_motosierra_vintage": (0, 0, 0)}
# asas que no están en el eje del arma: (punto de agarre local, eje del asa local, vector local que debe mirar a DIR, DIR en el mundo, radio)
ASA = {"w_motosierra_vintage": (Vector((-0.226, 0.016, 0.366)), Vector((0, 1, 0)), Vector((0, 0, 1)), Vector((0.0, -1.0, -0.9)), 0.0125)}
SOLO = os.environ.get("SOLO")
DEDOS = ("index", "middle", "ring", "pinky")

def apuntar(rig, pb, nombre, direccion):
    bpy.context.view_layer.update()
    M = rig.matrix_world @ pb[nombre].matrix
    q = M.to_3x3().col[1].normalized().rotation_difference(direccion.normalized())
    t = M.translation.copy()
    pb[nombre].matrix = rig.matrix_world.inverted() @ (Matrix.Translation(t) @ q.to_matrix().to_4x4() @ Matrix.Translation(-t) @ M)
    bpy.context.view_layer.update()

def W(rig, pb, n, cola=False):
    return rig.matrix_world @ (pb[n].tail if cola else pb[n].head)

def radio_dedo(body, rig, pb, hueso):
    """grosor real del dedo: distancia media de sus vértices al eje del hueso"""
    g = body.vertex_groups[hueso].index
    bo = rig.data.bones[hueso]
    a, b = rig.matrix_world @ bo.head_local, rig.matrix_world @ bo.tail_local; ab = b - a
    ds = []
    for v in body.data.vertices:
        if any(x.group == g and x.weight > 0.6 for x in v.groups):
            p = body.matrix_world @ v.co
            t = max(0, min(1, (p - a).dot(ab) / ab.length_squared)); ds.append((p - (a + ab * t)).length)
    return float(np.median(ds)) if ds else 0.009

def toca(bvh, rig, pb, hueso, r, muestras=5):
    a, b = W(rig, pb, hueso), W(rig, pb, hueso, True)
    for k in range(muestras + 1):
        p = a.lerp(b, 0.55 + 0.45 * k / muestras)
        loc, nrm, idx, d = bvh.find_nearest(p, 0.2)
        if loc is None: continue
        if os.environ.get("DBG"): print("      dbg", hueso, round(k/muestras,2), "d", round(d,4), "sd", round((p - loc).dot(nrm),4), "r", round(r,4))
        if d < r * 1.0: return True
    return False

def cerrar(rig, pb, bvh, hueso, eje_local, r, maxang=100, paso=2.0):
    ang = 0.0
    base = pb[hueso].rotation_quaternion.copy() if pb[hueso].rotation_mode == 'QUATERNION' else None
    pb[hueso].rotation_mode = 'XYZ'
    e0 = list(pb[hueso].rotation_euler)
    while ang < maxang:
        ang += paso
        e = e0[:]; e[eje_local[0]] = e0[eje_local[0]] + math.radians(ang * eje_local[1])
        pb[hueso].rotation_euler = Euler(e); bpy.context.view_layer.update()
        if toca(bvh, rig, pb, hueso, r):
            ang -= paso * 0.5
            e = e0[:]; e[eje_local[0]] = e0[eje_local[0]] + math.radians(ang * eje_local[1])
            pb[hueso].rotation_euler = Euler(e); bpy.context.view_layer.update()
            return ang, True
    return ang, False

for nom, (desv, giro, giroz) in ARMAS.items():
    if SOLO and nom != SOLO: continue
    bpy.ops.wm.open_mainfile(filepath="/home/claude/damian/out/damian.blend")
    rig = bpy.data.objects["rig"]; pb = rig.pose.bones; body = bpy.data.objects["cuerpo"]
    for b in pb: b.rotation_mode = 'XYZ'
    apuntar(rig, pb, "upperarm_r", Vector((-0.22, 0.03, -1)))
    apuntar(rig, pb, "lowerarm_r", Vector((-0.08, -0.28, -1)))
    apuntar(rig, pb, "hand_r", Vector((-0.04, -0.18, -1)))
    apuntar(rig, pb, "upperarm_l", Vector((0.22, 0.03, -1)))
    apuntar(rig, pb, "lowerarm_l", Vector((0.08, -0.2, -1)))
    apuntar(rig, pb, "hand_l", Vector((0.04, -0.1, -1)))
    # dirección de la palma: hacia donde se cierran los dedos (prueba con el corazón doblado)
    k0 = W(rig, pb, "middle_01_r")
    pb["middle_01_r"].rotation_euler = Euler((math.radians(90), 0, 0)); bpy.context.view_layer.update()
    haciadentro = (W(rig, pb, "middle_01_r", True) - k0); pb["middle_01_r"].rotation_euler = Euler((0, 0, 0)); bpy.context.view_layer.update()
    # muñeca: la punta del arma cae (hacia el meñique) o sube
    if desv:
        Mh = rig.matrix_world @ pb["hand_r"].matrix
        ej = (W(rig, pb, "index_01_r") - W(rig, pb, "pinky_01_r")).normalized(); ad = (W(rig, pb, "middle_01_r") - W(rig, pb, "hand_r")).normalized()
        n = ej.cross(ad).normalized(); t = Mh.translation.copy()
        for sg in (1, -1):
            R = Matrix.Rotation(math.radians(abs(desv) * sg), 4, n)
            pb["hand_r"].matrix = rig.matrix_world.inverted() @ (Matrix.Translation(t) @ R @ Matrix.Translation(-t) @ Mh); bpy.context.view_layer.update()
            ej2 = (W(rig, pb, "index_01_r") - W(rig, pb, "pinky_01_r")).normalized()
            if (ej2.z < ej.z) == (desv > 0): break
        k0 = W(rig, pb, "middle_01_r")
        pb["middle_01_r"].rotation_euler = Euler((math.radians(90), 0, 0)); bpy.context.view_layer.update()
        haciadentro = (W(rig, pb, "middle_01_r", True) - k0); pb["middle_01_r"].rotation_euler = Euler((0, 0, 0)); bpy.context.view_layer.update()
    i1, p1 = W(rig, pb, "index_01_r"), W(rig, pb, "pinky_01_r"); muneca = W(rig, pb, "hand_r")
    eje = (i1 - p1).normalized()
    adelante = ((i1 + p1) / 2 - muneca).normalized()
    palma = haciadentro - eje * haciadentro.dot(eje) - adelante * haciadentro.dot(adelante)
    palma = palma.normalized() if palma.length > 1e-6 else adelante.cross(eje).normalized()
    # el mango cruza la palma en diagonal (del índice al talón de la mano en el lado del meñique)
    eje_m = (eje - adelante * 0.28).normalized()
    # grosor de la palma en el punto de agarre
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get(); be = body.evaluated_get(dg); me = be.to_mesh()
    import bmesh
    bmb = bmesh.new(); bmb.from_mesh(me); bmb.transform(body.matrix_world); bvb = BVHTree.FromBMesh(bmb); be.to_mesh_clear()
    P = (i1 + p1) / 2 * 0.72 + muneca * 0.28
    hit = bvb.ray_cast(P + palma * 0.08, -palma, 0.1)
    piel = hit[0] if hit[0] is not None else P + palma * 0.015
    # arma: radio del mango junto al agarre
    bpy.ops.import_scene.gltf(filepath=f"/home/claude/damian/armas/{nom}.glb")
    arma = [o for o in bpy.context.selected_objects if o.type == 'MESH'][0]
    Va = np.array([v.co for v in arma.data.vertices])
    cerca = Va[np.abs(Va[:, 2]) < 0.05]
    rad = float(np.median(np.hypot(cerca[:, 0], cerca[:, 1]))) if len(cerca) > 8 else 0.017
    rad = min(max(rad, 0.012), 0.025)
    if nom in ASA: rad = ASA[nom][4]
    centro = piel + palma * (rad + 0.004)
    z = eje_m
    x = (adelante - z * adelante.dot(z)).normalized()
    x = Matrix.Rotation(math.radians(giro), 3, z) @ x
    y = z.cross(x)
    M = Matrix((x, y, z)).transposed().to_4x4(); M.translation = centro
    if giroz: M = Matrix.Translation(centro) @ Matrix.Rotation(math.radians(giroz), 4, palma) @ Matrix.Translation(-centro) @ M
    if nom in ASA:
        G, A, F, D, _ = ASA[nom]
        R1 = A.rotation_difference(eje_m).to_matrix()
        f1 = R1 @ F; f1 = (f1 - eje_m * f1.dot(eje_m)).normalized(); d1 = (D - eje_m * D.dot(eje_m)).normalized()
        ang = math.atan2(f1.cross(d1).dot(eje_m), f1.dot(d1))
        R = Matrix.Rotation(ang, 3, eje_m) @ R1
        M = R.to_4x4(); M.translation = centro - R @ G
    arma.matrix_world = M
    bpy.context.view_layer.update()
    bma = bmesh.new(); bma.from_mesh(arma.data); bma.transform(arma.matrix_world); bvh = BVHTree.FromBMesh(bma)
    print(nom, "radio mango", round(rad, 4), "palma", palma, "eje", eje_m)
    # cerrar dedos: cada falange hasta tocar
    for d in DEDOS[:1] if os.environ.get('DBG') else DEDOS:
        for k in (1, 2, 3):
            h = f"{d}_0{k}_r"; r = radio_dedo(body, rig, pb, h)
            ang, ok = cerrar(rig, pb, bvh, h, (0, 1), r, maxang=(95 if k > 1 else 85))
            print("  ", h, "radio", round(r, 4), "ángulo", round(ang, 1), "toca" if ok else "NO TOCA")
    # pulgar: se acerca hasta tocar el mango o el índice
    pb["thumb_01_r"].rotation_euler = Euler((math.radians(15), 0, math.radians(20))); bpy.context.view_layer.update()
    for k in (2, 3):
        h = f"thumb_0{k}_r"; r = radio_dedo(body, rig, pb, h) * 0.6
        ang, ok = cerrar(rig, pb, bvh, h, (2, 1), r, maxang=75)
        print("  ", h, "radio", round(r, 4), "ángulo", round(ang, 1), "toca" if ok else "NO TOCA")
    mw = arma.matrix_world.copy(); arma.parent = rig; arma.parent_type = 'BONE'; arma.parent_bone = "hand_r"; arma.matrix_world = mw
    # vistas de cerca
    sc = bpy.context.scene; sc.render.engine = 'CYCLES'; sc.cycles.samples = 32; sc.cycles.use_denoising = True; sc.view_settings.view_transform = 'AgX'
    w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True; w.node_tree.nodes['Background'].inputs[0].default_value = (0.05, 0.05, 0.06, 1)
    for ang, e in ((50, 3.0), (-60, 1.2)):
        l = bpy.data.objects.new('l', bpy.data.lights.new('l', 'SUN')); l.data.energy = e; sc.collection.objects.link(l); l.rotation_euler = (math.radians(55), 0, math.radians(ang))
    cam = bpy.data.objects.new("c", bpy.data.cameras.new("c")); sc.collection.objects.link(cam); sc.camera = cam
    sc.render.resolution_x = sc.render.resolution_y = 500
    c_m = W(rig, pb, "middle_01_r")
    vistas = {"fuera": -eje.cross(adelante).normalized() * 0 + (palma * -1).normalized(), "dentro": palma, "frente": (adelante + palma * 0.3).normalized()}
    # cámara siempre del lado de fuera del cuerpo (x negativo) para que no se meta dentro
    vistas = {"fuera": Vector((-1, -0.25, 0.1)).normalized(), "delante": Vector((-0.3, -1, 0.15)).normalized(), "abajo": Vector((-0.6, -0.4, -0.7)).normalized()}
    for tag, dv in vistas.items():
        cam.location = c_m + dv * 0.3; cam.rotation_euler = (c_m - cam.location).to_track_quat('-Z', 'Y').to_euler(); cam.data.lens = 40
        sc.render.filepath = os.path.join(OUT, f"{nom}_{tag}.png"); bpy.ops.render.render(write_still=True)
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, nom + ".blend"))
