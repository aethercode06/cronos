"""Saca la malla del gato (editada o no) de Blender como datos: posiciones y normales en el espacio glTF del modelo
original, UV, triángulos y los 4 huesos con más peso de cada vértice (por nombre). Godot la monta sobre el
esqueleto y la piel ORIGINALES, así las 57 animaciones siguen siendo las de siempre.
Uso: python exportar_malla.py <entrada.glb> <salida.json> [editar.py]"""
import bpy, sys, json, runpy, numpy as np
A=[a for a in sys.argv if not a.startswith('--')]
SRC, DST = A[1], A[2]
EDIT = A[3] if len(A) > 3 else None
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
for o in list(bpy.context.scene.objects):
    if o.name.startswith('Icosphere'):
        bpy.data.objects.remove(o)
ob = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
arm = [o for o in bpy.context.scene.objects if o.type == 'ARMATURE'][0]
if EDIT:
    runpy.run_path(EDIT, init_globals={"ob": ob, "arm": arm})
me = ob.data
me.calc_loop_triangles()
uvl = me.uv_layers.active.data
grupos = {g.index: g.name for g in ob.vertex_groups}
clave = {}
pos, nor, uv, bon, pes, tris = [], [], [], [], [], []
me_normales = [tuple(l.normal) for l in me.loops] if hasattr(me.loops[0], 'normal') else None
for t in me.loop_triangles:
    idx = []
    for li, vi in zip(t.loops, t.vertices):
        u = tuple(round(c, 5) for c in uvl[li].uv)
        k = (vi, u)
        if k not in clave:
            clave[k] = len(pos)
            v = me.vertices[vi]
            p = v.co
            n = me.corner_normals[li].vector if hasattr(me, 'corner_normals') else v.normal
            pos.append([p.x, p.z, -p.y])
            nor.append([n.x, n.z, -n.y])
            uv.append([u[0], 1.0 - u[1]])
            gs = sorted([(g.weight, grupos[g.group]) for g in v.groups if g.weight > 0.0001], reverse=True)[:4]
            s = sum(w for w, _ in gs) or 1.0
            gs = [(w / s, n_) for w, n_ in gs] + [(0.0, "")] * (4 - len(gs))
            bon.append([n_ for _, n_ in gs])
            pes.append([w for w, _ in gs])
        idx.append(clave[k])
    tris.append(idx)
json.dump({"pos": pos, "nor": nor, "uv": uv, "huesos": bon, "pesos": pes, "tris": tris}, open(DST, "w"))
print("MALLA OK", len(pos), "vértices", len(tris), "triángulos")
