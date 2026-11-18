"""Coloca el arma en el hueco del puño (pose sacada de la UAL2). Busca el centro y la dirección del hueco
donde un mango cabe sin tocar la piel."""
import bpy, sys, math, os
import numpy as np
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree
import bmesh

def bvh_cuerpo(body):
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get(); be = body.evaluated_get(dg); me = be.to_mesh()
    bm = bmesh.new(); bm.from_mesh(me); bm.transform(body.matrix_world); t = BVHTree.FromBMesh(bm); be.to_mesh_clear(); return t

def hueco(rig, body, lado="r"):
    pb = rig.pose.bones; Wm = rig.matrix_world
    P = lambda n: Wm @ pb[n].head
    i1, p1, w = P(f"index_01_{lado}"), P(f"pinky_01_{lado}"), P(f"hand_{lado}")
    medios = sum((P(f"{d}_02_{lado}") for d in ("index", "middle", "ring", "pinky")), Vector()) / 4
    eje0 = (i1 - p1).normalized()
    c0 = ((i1 + p1) / 2 + medios) / 2
    bvh = bvh_cuerpo(body)
    def holgura(c, e):
        m = 1.0
        for t in np.linspace(-0.035, 0.035, 9):
            loc, n, i, d = bvh.find_nearest(c + e * t, 0.1)
            if loc is not None: m = min(m, d)
        return m
    def encierro(c, e):
        o1 = e.orthogonal().normalized(); o2 = e.cross(o1)
        n = 0
        for t in (-0.02, 0.0, 0.02):
            for k in range(8):
                a = 2 * math.pi * k / 8; dv = o1 * math.cos(a) + o2 * math.sin(a)
                if bvh.ray_cast(c + e * t, dv, 0.045)[0] is not None: n += 1
        return n / 24.0
    def puntos(c, e):
        h = holgura(c, e); return encierro(c, e) * 2.0 - abs(h - 0.016) * 60.0, h
    s0, h0 = puntos(c0, eje0)
    mejor = (s0, c0, eje0, h0)
    # búsqueda: posición en una rejilla y dirección en un cono
    ortos = [eje0.orthogonal().normalized()]; ortos.append(eje0.cross(ortos[0]).normalized())
    for paso in (0.012, 0.006, 0.003):
        c_b, e_b = mejor[1], mejor[2]
        for dx in (-2, -1, 0, 1, 2):
            for dy in (-2, -1, 0, 1, 2):
                for dz in (-1, 0, 1):
                    c = c_b + ortos[0] * dx * paso + ortos[1] * dy * paso + e_b * dz * paso
                    for a in (-10, 0, 10):
                        for b in (-10, 0, 10):
                            e = (Matrix.Rotation(math.radians(a), 3, ortos[0]) @ Matrix.Rotation(math.radians(b), 3, ortos[1]) @ e_b).normalized()
                            sc_, h = puntos(c, e)
                            if sc_ > mejor[0]: mejor = (sc_, c, e, h)
    e = mejor[2] if mejor[2].dot(eje0) > 0 else -mejor[2]
    print("hueco: encierro/puntos", round(mejor[0], 3), "holgura", round(mejor[3], 4))
    return mejor[3], mejor[1], e
