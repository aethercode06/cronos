"""Remodelado del gato sobre su esqueleto (se ejecuta dentro de Blender con `ob` = malla y `arm` = esqueleto):
ojos más grandes y cuencas abiertas, orejas más grandes y puntiagudas, hocico más fino, cabeza menos redonda y
una subdivisión para que la forma sea suave. Los pesos de los huesos se conservan."""
import bpy, bmesh, mathutils
me = ob.data
grupos = {g.name: g.index for g in ob.vertex_groups}
def peso(v, nombre):
    gi = grupos.get(nombre)
    for g in v.groups:
        if g.group == gi:
            return g.weight
    return 0.0
# piezas sueltas
bm = bmesh.new(); bm.from_mesh(me); bm.verts.ensure_lookup_table()
vist = set(); piezas = []
for v in bm.verts:
    if v.index in vist: continue
    pila = [v]; comp = []
    while pila:
        x = pila.pop()
        if x.index in vist: continue
        vist.add(x.index); comp.append(x.index)
        for e in x.link_edges: pila.append(e.other_vert(x))
    piezas.append(comp)
bm.free()
ojos = [p for p in piezas if len(p) == 22]
V = me.vertices
def centro(ids): return sum((V[i].co for i in ids), mathutils.Vector()) / len(ids)
a_malla = ob.matrix_world.inverted() @ arm.matrix_world
def hueso(n, cola=False):
    b = arm.data.bones[n]
    return a_malla @ (b.tail_local if cola else b.head_local)
nuevos = {v.index: v.co.copy() for v in V}
# 1) ojos: globo 1,4 veces y la cuenca alrededor se abre en proporción
for ids in ojos:
    c = centro(ids)
    r = max((V[i].co - c).length for i in ids)
    for i in ids:
        nuevos[i] = c + (V[i].co - c) * 1.4
    r1 = r * 2.8
    sid = set(ids)
    for v in V:
        if v.index in sid: continue
        d = (v.co - c).length
        if d < r1:
            k = 1.0 + 0.4 * (1.0 - d / r1) ** 1.5
            nuevos[v.index] = c + (nuevos[v.index] - c) * k
# 2) orejas: 1,3 veces desde su base y más largas hacia la punta
for lado in ("L", "R"):
    base = hueso("ear_1_%s_0%s" % (lado, "29" if lado == "L" else "33"))
    punta = hueso("ear_2_%s_0%s" % (lado, "30" if lado == "L" else "34"), cola=True)
    eje = (punta - base).normalized()
    for v in V:
        w = peso(v, "ear_1_%s_0%s" % (lado, "29" if lado == "L" else "33")) + peso(v, "ear_2_%s_0%s" % (lado, "30" if lado == "L" else "34"))
        if w > 0.05:
            q = nuevos[v.index] - base
            a_lo_largo = q.dot(eje)
            q2 = q * 1.25 + eje * max(a_lo_largo, 0.0) * 0.2
            nuevos[v.index] = v.co.lerp(base + q2, min(w * 1.2, 1.0)) if False else (nuevos[v.index].lerp(base + q2, min(w * 1.2, 1.0)))
# 3) cabeza menos redonda (algo más estrecha) y hocico más fino
cab = hueso("head_024")
for v in V:
    wh = peso(v, "head_024")
    wm = peso(v, "mouth_025")
    if wh + wm > 0.05:
        p = nuevos[v.index]
        f = 1.0 - 0.06 * min(wh + wm, 1.0) - 0.06 * wm
        nuevos[v.index] = mathutils.Vector((cab.x + (p.x - cab.x) * f, p.y, p.z))
for v in V:
    v.co = nuevos[v.index]
me.update()
# 4) más polígonos y forma suave (los pesos y las UV se interpolan)
bpy.context.view_layer.objects.active = ob
sub = ob.modifiers.new("sub", 'SUBSURF')
sub.levels = 1; sub.render_levels = 1; sub.uv_smooth = 'PRESERVE_CORNERS'
# el modificador de esqueleto debe ir después de la subdivisión
for m in list(ob.modifiers):
    if m.type == 'ARMATURE':
        ob.modifiers.move(ob.modifiers.find(m.name), len(ob.modifiers) - 1)
bpy.ops.object.modifier_apply(modifier="sub")
print("EDITADO", len(ob.data.vertices), "vértices")
