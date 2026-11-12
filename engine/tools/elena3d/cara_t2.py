"""Proyecta una cara mejorada (alta resolución) sobre la cabeza del modelo de TRELLIS.2 y hornea la textura.
Uso: python cara_t2.py <entrada.blend> <cara.png> <salida> <cx_modelo> <cy_modelo> <escala>  (de la búsqueda por plantilla)"""
import bpy, sys, math
src, face, out = sys.argv[-6], sys.argv[-5], sys.argv[-4]
DX, DZ, SC = float(sys.argv[-3]), float(sys.argv[-2]), float(sys.argv[-1])
bpy.ops.wm.open_mainfile(filepath=src)
ob = [o for o in bpy.data.objects if o.type == 'MESH'][0]
me = ob.data
zs = [v.co.z for v in me.vertices]; xs = [v.co.x for v in me.vertices]
zmin, zmax = min(zs), max(zs); xmid = (min(xs) + max(xs)) / 2
# concepto 768x1344: figura de y=12 (pelo) a y=1330 (pies); la cara recortada es (270,30)-(510,270)
ppu = (1330 - 12) / (zmax - zmin)
CX, CY = 390.0, 152.0          # centro de la cara en el concepto
RX, RY = 52.0, 78.0            # semiejes de la máscara (px del concepto)
orig = me.uv_layers[0]
proj = me.uv_layers.new(name="proj")
for loop in me.loops:
    co = me.vertices[loop.vertex_index].co
    mx = 390.0 + (co.x - xmid) * ppu; my = 12 + (zmax - co.z) * ppu   # px del modelo en el encuadre del concepto
    px = 390.0 + (mx - DX) / SC; py = 157.5 + (my - DZ) / SC   # DX,DZ = centro de la cara del modelo; SC = escala modelo/concepto
    proj.data[loop.index].uv = ((px - 270) / 240.0, 1 - (py - 30) / 240.0)
me.uv_layers.active = orig
mat = ob.material_slots[0].material; nt = mat.node_tree; N = nt.nodes; L = nt.links
bsdf = [n for n in N if n.type == 'BSDF_PRINCIPLED'][0]
outn = [n for n in N if n.type == 'OUTPUT_MATERIAL'][0]
otex = bsdf.inputs['Base Color'].links[0].from_node
ouv = N.new('ShaderNodeUVMap'); ouv.uv_map = orig.name; L.new(ouv.outputs[0], otex.inputs[0])
ftex = N.new('ShaderNodeTexImage'); ftex.image = bpy.data.images.load(face); ftex.extension = 'EXTEND'
puv = N.new('ShaderNodeUVMap'); puv.uv_map = "proj"; L.new(puv.outputs[0], ftex.inputs[0])
# máscara elíptica en el espacio del concepto * mirando al frente
sx = N.new('ShaderNodeSeparateXYZ'); L.new(puv.outputs[0], sx.inputs[0])
def lin(inp, a, b):
    m = N.new('ShaderNodeMath'); m.operation = 'MULTIPLY_ADD'; m.inputs[1].default_value = a; m.inputs[2].default_value = b
    L.new(inp, m.inputs[0]); return m.outputs[0]
ux = lin(sx.outputs[0], 240.0 / RX, (270 - CX) / RX)            # (px-CX)/RX
uy = lin(sx.outputs[1], -240.0 / RY, (270 - CY) / RY)           # (py-CY)/RY con py = 30+240*(1-v)
def sq(x):
    m = N.new('ShaderNodeMath'); m.operation = 'POWER'; m.inputs[1].default_value = 2; L.new(x, m.inputs[0]); return m.outputs[0]
ad = N.new('ShaderNodeMath'); ad.operation = 'ADD'; L.new(sq(ux), ad.inputs[0]); L.new(sq(uy), ad.inputs[1])
rad = N.new('ShaderNodeMapRange'); rad.inputs['From Min'].default_value = 0.55; rad.inputs['From Max'].default_value = 1.0
rad.inputs['To Min'].default_value = 1.0; rad.inputs['To Max'].default_value = 0.0; L.new(ad.outputs[0], rad.inputs['Value'])
geo = N.new('ShaderNodeNewGeometry'); sn = N.new('ShaderNodeSeparateXYZ'); L.new(geo.outputs['Normal'], sn.inputs[0])
fr = N.new('ShaderNodeMapRange'); fr.inputs['From Min'].default_value = -0.15; fr.inputs['From Max'].default_value = -0.5
L.new(sn.outputs[1], fr.inputs['Value'])
mk = N.new('ShaderNodeMath'); mk.operation = 'MULTIPLY'; L.new(rad.outputs[0], mk.inputs[0]); L.new(fr.outputs[0], mk.inputs[1])
mix = N.new('ShaderNodeMix'); mix.data_type = 'RGBA'
L.new(mk.outputs[0], mix.inputs['Factor']); L.new(otex.outputs['Color'], mix.inputs['A']); L.new(ftex.outputs['Color'], mix.inputs['B'])
L.new(mix.outputs['Result'], bsdf.inputs['Base Color'])
if '--preview' in sys.argv or out.endswith('_prev'):
    bpy.ops.wm.save_as_mainfile(filepath=out + ".blend"); print("PREV OK"); sys.exit(0)
em = N.new('ShaderNodeEmission'); L.new(mix.outputs['Result'], em.inputs[0]); L.new(em.outputs[0], outn.inputs['Surface'])
img = bpy.data.images.new("elena_tex", 4096, 4096)
bt = N.new('ShaderNodeTexImage'); bt.image = img; L.new(ouv.outputs[0], bt.inputs[0]); N.active = bt
sc = bpy.context.scene; sc.render.engine = 'CYCLES'; sc.cycles.samples = 4; sc.render.bake.margin = 16
bpy.context.view_layer.objects.active = ob; ob.select_set(True)
bpy.ops.object.bake(type='EMIT')
img.filepath_raw = out + ".png"; img.file_format = 'PNG'; img.save()
for n in (em, mix, ftex, puv, sx, geo, sn, fr, mk, rad, ad, bt): pass
L.new(bsdf.outputs[0], outn.inputs['Surface'])
otex.image = img
L.new(otex.outputs['Color'], bsdf.inputs['Base Color'])
for n in list(N):
    if n.type not in ('BSDF_PRINCIPLED', 'OUTPUT_MATERIAL', 'TEX_IMAGE', 'UVMAP', 'NORMAL_MAP', 'SEPARATE_COLOR') or n in (ftex, bt):
        if n.type != 'BSDF_PRINCIPLED' and n.type != 'OUTPUT_MATERIAL' and n is not otex and not (n.type == 'TEX_IMAGE' and n is not ftex and n is not bt): N.remove(n)
me.uv_layers.remove(me.uv_layers["proj"])
bpy.ops.wm.save_as_mainfile(filepath=out + ".blend")
print("CARA OK")
