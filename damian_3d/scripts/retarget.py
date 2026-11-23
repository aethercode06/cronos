"""Pasa poses/animaciones de la Universal Animation Library 2 (CC0, Quaternius) al esqueleto de Damián.
Los nombres de huesos coinciden (esqueleto tipo Unreal). Cada hueso de Damián apunta donde apunta el del maniquí."""
import bpy, math
from mathutils import Matrix

MAPA = {"Head": "head"}

def importar_ual(ruta="/home/claude/ual/ual2.glb"):
    antes = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=ruta)
    nuevos = [o for o in bpy.data.objects if o not in antes]
    src = [o for o in nuevos if o.type == 'ARMATURE'][0]
    for o in nuevos:
        if o.type == 'MESH': o.hide_render = True; o.hide_viewport = True
    return src, nuevos

def orden(arm):
    res = []
    def rec(b):
        res.append(b.name)
        for c in b.children: rec(c)
    for b in arm.data.bones:
        if b.parent is None: rec(b)
    return res

def copiar_pose(src, tgt, accion, frame, solo=None, desplazar_raiz=False):
    src.animation_data_create(); src.animation_data.action = bpy.data.actions[accion]
    bpy.context.scene.frame_set(int(frame)); bpy.context.view_layer.update()
    Ws, Wt = src.matrix_world, tgt.matrix_world
    for nt in orden(tgt):
        ns = {v: k for k, v in MAPA.items()}.get(nt, nt)
        if ns not in src.pose.bones: continue
        if solo and not any(nt.startswith(p) for p in solo): continue
        sb, tb = src.pose.bones[ns], tgt.pose.bones[nt]
        rs = (Ws @ sb.bone.matrix_local).to_3x3().normalized(); ps = (Ws @ sb.matrix).to_3x3().normalized()
        rt = (Wt @ tb.bone.matrix_local).to_3x3().normalized()
        rot = ps @ rs.inverted() @ rt
        cabeza = (Wt @ tb.matrix).translation
        M = rot.to_4x4(); M.translation = cabeza
        tb.matrix = Wt.inverted() @ M
        bpy.context.view_layer.update()

def acciones(src):
    return sorted(a.name for a in bpy.data.actions)

def copiar_dedos(src, tgt, accion, frame, lado="r"):
    """copia la pose de los dedos de otra animación, relativa a la mano (sirve aunque el brazo esté en otra pose)"""
    src.animation_data_create(); src.animation_data.action = bpy.data.actions[accion]
    bpy.context.scene.frame_set(int(frame)); bpy.context.view_layer.update()
    Ws, Wt = src.matrix_world, tgt.matrix_world
    pref = tuple(f"{d}_0" for d in ("index", "middle", "ring", "pinky", "thumb"))
    for nt in orden(tgt):
        if not (nt.startswith(pref) and nt.endswith("_" + lado)): continue
        if nt not in src.pose.bones: continue
        sb, tb = src.pose.bones[nt], tgt.pose.bones[nt]
        sp, tp = sb.parent, tb.parent
        R = lambda m: m.to_3x3().normalized()
        rs, rt = R(Ws @ sb.bone.matrix_local), R(Wt @ tb.bone.matrix_local)
        rsp, rtp = R(Ws @ sp.bone.matrix_local), R(Wt @ tp.bone.matrix_local)
        Ps, ps, Pt = R(Ws @ sp.matrix), R(Ws @ sb.matrix), R(Wt @ tp.matrix)
        O, Op = rs.inverted() @ rt, rsp.inverted() @ rtp
        rot = Pt @ Op.inverted() @ Ps.inverted() @ ps @ O
        M = rot.to_4x4(); M.translation = (Wt @ tb.matrix).translation
        tb.matrix = Wt.inverted() @ M
        bpy.context.view_layer.update()

# ---------- Mixamo ----------
MIXAMO = {"Hips": "pelvis", "Spine": "spine_01", "Spine1": "spine_02", "Spine2": "spine_03", "Neck": "neck_01", "Head": "head"}
for L, l in (("Right", "r"), ("Left", "l")):
    MIXAMO.update({f"{L}Shoulder": f"clavicle_{l}", f"{L}Arm": f"upperarm_{l}", f"{L}ForeArm": f"lowerarm_{l}", f"{L}Hand": f"hand_{l}",
                   f"{L}UpLeg": f"thigh_{l}", f"{L}Leg": f"calf_{l}", f"{L}Foot": f"foot_{l}", f"{L}ToeBase": f"ball_{l}"})
    for f_m, f_u in (("Thumb", "thumb"), ("Index", "index"), ("Middle", "middle"), ("Ring", "ring"), ("Pinky", "pinky")):
        for k in (1, 2, 3): MIXAMO[f"{L}Hand{f_m}{k}"] = f"{f_u}_0{k}_{l}"

def importar_mixamo(ruta):
    antes = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=ruta)
    nuevos = [o for o in bpy.data.objects if o not in antes]
    src = [o for o in nuevos if o.type == 'ARMATURE'][0]
    for o in nuevos:
        if o.type == 'MESH': o.hide_render = True; o.hide_viewport = True
    return src, nuevos

def copiar_mixamo(src, tgt, frame, mover_cadera=True):
    """huesos largos: solo la dirección (sin giro sobre su eje, que retuerce la piel); clavículas quietas;
    manos y dedos: giro completo, y la torsión de la mano se reparte con el antebrazo"""
    bpy.context.scene.frame_set(int(frame)); bpy.context.view_layer.update()
    Ws, Wt = src.matrix_world, tgt.matrix_world
    inv = {v: "mixamorig:" + k for k, v in MIXAMO.items()}
    R = lambda m: m.to_3x3().normalized()
    for nt in orden(tgt):
        ns = inv.get(nt)
        if ns is None or ns not in src.pose.bones: continue
        if nt.startswith("clavicle"): continue
        sb, tb = src.pose.bones[ns], tgt.pose.bones[nt]
        rs, ps, rt = R(Ws @ sb.bone.matrix_local), R(Ws @ sb.matrix), R(Wt @ tb.bone.matrix_local)
        actual = R(Wt @ tb.matrix)
        es_dedo = nt.startswith(("thumb", "index", "middle", "ring", "pinky"))
        if nt.startswith("hand") or es_dedo or nt == "pelvis":
            rt_T = rt.col[1].normalized().rotation_difference(rs.col[1].normalized()).to_matrix() @ rt
            rot = ps @ rs.inverted() @ rt_T
        else:
            # solo girar desde la orientación actual (que hereda del padre) hasta la dirección del maniquí
            rot = actual.col[1].normalized().rotation_difference(ps.col[1].normalized()).to_matrix() @ actual
        cab = (Wt @ tb.matrix).translation
        if nt == "pelvis" and mover_cadera:
            hs_r = (Ws @ sb.bone.matrix_local).translation; hs_p = (Ws @ sb.matrix).translation
            ht_r = (Wt @ tb.bone.matrix_local).translation
            esc = ht_r.z / max(hs_r.z, 1e-6)
            cab = ht_r + (hs_p - hs_r) * esc
        M = rot.to_4x4(); M.translation = cab
        tb.matrix = Wt.inverted() @ M
        bpy.context.view_layer.update()
    for l in ("r", "l"): repartir_torsion(tgt, l)

def repartir_torsion(tgt, l, parte=0.5):
    """la mano gira sobre el eje del antebrazo: la mitad de ese giro la toma el antebrazo (la piel no se estrangula en la muñeca)"""
    import math
    from mathutils import Matrix, Quaternion
    Wt = tgt.matrix_world; pb = tgt.pose.bones
    R = lambda m: m.to_3x3().normalized()
    fa, ha = pb[f"lowerarm_{l}"], pb[f"hand_{l}"]
    Fa = R(Wt @ fa.matrix); Ha = R(Wt @ ha.matrix)
    eje = Fa.col[1].normalized()
    # giro de la mano respecto al antebrazo, descompuesto en torsión (sobre el eje del antebrazo)
    rel = (Fa.inverted() @ Ha).to_quaternion()
    tw = Quaternion((rel.w, 0, rel.y, 0)).normalized()        # torsión sobre la Y local del antebrazo
    ang = 2 * math.atan2(tw.y, tw.w)
    if ang > math.pi: ang -= 2 * math.pi
    if ang < -math.pi: ang += 2 * math.pi
    giro = Matrix.Rotation(ang * parte, 3, eje)
    manoW = R(Wt @ ha.matrix); manoT = (Wt @ ha.matrix).translation
    nuevo = giro @ Fa; M = nuevo.to_4x4(); M.translation = (Wt @ fa.matrix).translation
    fa.matrix = Wt.inverted() @ M; bpy.context.view_layer.update()
    M2 = manoW.to_4x4(); M2.translation = (Wt @ ha.matrix).translation
    ha.matrix = Wt.inverted() @ M2; bpy.context.view_layer.update()

def mover_manos(tgt, desplazamiento, lados=("r", "l")):
    """mueve las dos manos la misma distancia (p. ej. hacia delante para no meterlas en la barriga) con IK de 2 huesos,
    conservando el giro de cada mano: el agarre entre las dos manos no cambia"""
    from mathutils import Vector
    Wt = tgt.matrix_world; pb = tgt.pose.bones
    giros = {l: (Wt @ pb[f"hand_{l}"].matrix).to_3x3().normalized() for l in lados}
    vacios = []
    for l in lados:
        destino = (Wt @ pb[f"hand_{l}"].matrix).translation + desplazamiento
        e = bpy.data.objects.new(f"ik_{l}", None); bpy.context.scene.collection.objects.link(e); e.location = destino; vacios.append(e)
        # polo: codo hacia fuera y atrás
        codo = (Wt @ pb[f"lowerarm_{l}"].matrix).translation
        p = bpy.data.objects.new(f"polo_{l}", None); bpy.context.scene.collection.objects.link(p)
        p.location = codo + Vector((0.4 if l == "l" else -0.4, 0.3, -0.1)); vacios.append(p)
        c = pb[f"lowerarm_{l}"].constraints.new('IK'); c.target = e; c.pole_target = p; c.chain_count = 2; c.pole_angle = 0
        c.name = "ik_tmp"
    bpy.context.view_layer.update()
    # fijar el resultado y quitar las restricciones
    vis = {n: (Wt.inverted() @ (Wt @ pb[n].matrix)) for l in lados for n in (f"upperarm_{l}", f"lowerarm_{l}")}
    for l in lados:
        pb[f"lowerarm_{l}"].constraints.remove(pb[f"lowerarm_{l}"].constraints["ik_tmp"])
    for n in [f"upperarm_{l}" for l in lados] + [f"lowerarm_{l}" for l in lados]:
        pb[n].matrix = vis[n]; bpy.context.view_layer.update()
    for l in lados:
        M = giros[l].to_4x4(); M.translation = (Wt @ pb[f"hand_{l}"].matrix).translation
        pb[f"hand_{l}"].matrix = Wt.inverted() @ M; bpy.context.view_layer.update()
    for e in vacios: bpy.data.objects.remove(e)
