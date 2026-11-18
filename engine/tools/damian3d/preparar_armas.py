"""Pone cada arma a tamaño real, con el mango abajo en el eje Z y el punto de agarre en el origen."""
import bpy, sys, os, math
import numpy as np
from mathutils import Vector, Matrix
ARMAS = {  # archivo: (largo real m, agarre desde el extremo del mango (fracción), mango = extremo 'estrecho' o 'ancho', caras máx)
 "w_machete": (0.66, 0.09, "estrecho", 4000),
 "w_hacha_vieja": (0.95, 0.12, "estrecho", 6000),
 "w_motosierra_vintage": (0.86, 0.12, "ancho", 9000),
}
OUT = sys.argv[-1]
for nom, (largo, agarre, mango, maxc) in ARMAS.items():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=f"/tmp/wdl2/glb/{nom}.glb")
    ms = [o for o in bpy.data.objects if o.type == 'MESH']
    bpy.ops.object.select_all(action='DESELECT')
    for o in ms: o.select_set(True)
    bpy.context.view_layer.objects.active = ms[0]
    # aplicar transformaciones y quitar padres
    for o in ms:
        mw = o.matrix_world.copy(); o.parent = None; o.matrix_world = mw
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if len(ms) > 1: bpy.ops.object.join()
    o = bpy.context.active_object
    for e in [x for x in bpy.data.objects if x.type != 'MESH']: bpy.data.objects.remove(e)
    V = np.array([v.co for v in o.data.vertices])
    mn, mx = V.min(0), V.max(0); size = mx - mn; ax = int(np.argmax(size))
    t = (V[:, ax] - mn[ax]) / size[ax]
    otros = [i for i in range(3) if i != ax]
    def ancho(sel): 
        S = V[sel][:, otros]; return (S.max(0) - S.min(0)).prod() if len(S) else 0
    a0, a1 = ancho(t < 0.1), ancho(t > 0.9)
    extremo_mango = 0 if ((a0 < a1) == (mango == "estrecho")) else 1
    print(nom, "eje", ax, "anchos", a0, a1, "mango en", extremo_mango)
    # escalar a largo real, mango abajo (Z), agarre en el origen
    esc = largo / size[ax]
    tg = agarre if extremo_mango == 0 else 1 - agarre
    selg = np.abs(t - tg) < 0.03
    if selg.sum() < 3: selg = np.abs(t - tg) < 0.08
    p_agarre = V[selg].mean(0) if selg.sum() else (mn + mx) / 2
    p_agarre[ax] = mn[ax] + tg * size[ax]
    dirv = np.zeros(3); dirv[ax] = 1 if extremo_mango == 0 else -1     # de mango hacia la punta
    R = Vector(dirv).to_track_quat('Z', 'Y').to_matrix().to_4x4()
    M = Matrix.Scale(esc, 4) @ R.inverted() @ Matrix.Translation(-Vector(p_agarre))
    o.data.transform(M)
    # el filo / la cara ancha mirando a +X
    V2 = np.array([v.co for v in o.data.vertices]); ext = V2.max(0) - V2.min(0)
    if ext[1] > ext[0]:
        o.data.transform(Matrix.Rotation(math.radians(90), 4, 'Z'))
    if len(o.data.polygons) > maxc:
        dm = o.modifiers.new("dec", 'DECIMATE'); dm.ratio = maxc / len(o.data.polygons)
        bpy.ops.object.modifier_apply(modifier="dec")
    o.name = nom
    V2 = np.array([v.co for v in o.data.vertices]); print(nom, "medidas", np.round(V2.max(0) - V2.min(0), 3), "caras", len(o.data.polygons))
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, nom + ".glb"), export_format='GLB', use_selection=False)
