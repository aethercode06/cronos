"""Añade la capa UV «cara» (2.º juego de UV) proyectando de frente la cara mejorada.
Las expresiones (PNG 1024 con alfa) se pintan encima en Godot con un shader.
Uso: python cara_uv.py <entrada.blend> <salida.blend> <cx_modelo> <cy_modelo> <escala>"""
import bpy, sys
src, out = sys.argv[-5], sys.argv[-4]
MX, MY, SC = float(sys.argv[-3]), float(sys.argv[-2]), float(sys.argv[-1])
bpy.ops.wm.open_mainfile(filepath=src)
ob = [o for o in bpy.data.objects if o.type == 'MESH'][0]
me = ob.data
zs = [v.co.z for v in me.vertices]; xs = [v.co.x for v in me.vertices]
zmin, zmax = min(zs), max(zs); xmid = (min(xs) + max(xs)) / 2
ppu = (1330 - 12) / (zmax - zmin)
CX, CY, RX, RY = 390.0, 157.5, 60.0, 90.0
uv = me.uv_layers.new(name="cara")
me.calc_normals_split() if hasattr(me, "calc_normals_split") else None
n_in = 0
for poly in me.polygons:
    for li in poly.loop_indices:
        v = me.vertices[me.loops[li].vertex_index]
        mx = 390.0 + (v.co.x - xmid) * ppu; my = 12 + (zmax - v.co.z) * ppu
        px = 390.0 + (mx - MX) / SC; py = 157.5 + (my - MY) / SC
        ok = ((px - CX) / RX) ** 2 + ((py - CY) / RY) ** 2 < 1.0 and v.normal.y < -0.3
        if ok:
            uv.data[li].uv = ((px - 270) / 240.0, 1 - (py - 30) / 240.0); n_in += 1
        else:
            uv.data[li].uv = (-1.0, -1.0)
me.uv_layers.active = me.uv_layers[0]
me.uv_layers[0].active_render = True
print("CARA UV", n_in, "loops")
bpy.ops.wm.save_as_mainfile(filepath=out)
