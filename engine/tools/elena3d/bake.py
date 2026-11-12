import bpy, sys, math, mathutils, bmesh
glb, img_path, out = sys.argv[-3], sys.argv[-2], sys.argv[-1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb)
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
bpy.ops.object.select_all(action='DESELECT')
for o in meshes: o.select_set(True)
bpy.context.view_layer.objects.active=meshes[0]
if len(meshes)>1: bpy.ops.object.join()
ob=bpy.context.view_layer.objects.active
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
me=ob.data
# limites
xs=[v.co.x for v in me.vertices]; zs=[v.co.z for v in me.vertices]
zmin,zmax=min(zs),max(zs); xmid=(min(xs)+max(xs))/2
IMW,IMH=768,1344; BX0,BX1,BY0,BY1=178,613,12,1330
ppu=(BY1-BY0)/(zmax-zmin); cx=(BX0+BX1)/2
# UV de proyección frontal
proj=me.uv_layers.new(name="proj")
orig=me.uv_layers[0]
for loop in me.loops:
    co=me.vertices[loop.vertex_index].co
    px=cx+(co.x-xmid)*ppu; py=BY0+(zmax-co.z)*ppu
    proj.data[loop.index].uv=(px/IMW, 1-py/IMH)
me.uv_layers.active=orig
mat=ob.material_slots[0].material
nt=mat.node_tree; N=nt.nodes; L=nt.links
bsdf=[n for n in N if n.type=='BSDF_PRINCIPLED'][0]
otex=[n for n in N if n.type=='TEX_IMAGE'][0]
pimg=bpy.data.images.load(img_path)
ptex=N.new('ShaderNodeTexImage'); ptex.image=pimg; ptex.extension='EXTEND'
puv=N.new('ShaderNodeUVMap'); puv.uv_map="proj"; L.new(puv.outputs[0],ptex.inputs[0])
ouv=N.new('ShaderNodeUVMap'); ouv.uv_map=orig.name; L.new(ouv.outputs[0],otex.inputs[0])
geo=N.new('ShaderNodeNewGeometry')
sep=N.new('ShaderNodeSeparateXYZ'); L.new(geo.outputs['Normal'],sep.inputs[0])
# máscara: cara frontal (normal hacia -Y)
neg=N.new('ShaderNodeMath'); neg.operation='MULTIPLY'; neg.inputs[1].default_value=-1; L.new(sep.outputs[1],neg.inputs[0])
mr=N.new('ShaderNodeMapRange'); mr.inputs['From Min'].default_value=0.15; mr.inputs['From Max'].default_value=0.55; L.new(neg.outputs[0],mr.inputs['Value'])
mix=N.new('ShaderNodeMix'); mix.data_type='RGBA'
L.new(mr.outputs[0],mix.inputs['Factor']); L.new(otex.outputs['Color'],mix.inputs['A']); L.new(ptex.outputs['Color'],mix.inputs['B'])
# espalda: tono crema sucio del vestido, conservando el detalle de la textura original
gp=N.new('ShaderNodeSeparateXYZ'); L.new(geo.outputs['Position'],gp.inputs[0])
back=N.new('ShaderNodeMapRange'); back.inputs['From Min'].default_value=0.1; back.inputs['From Max'].default_value=0.5; L.new(sep.outputs[1],back.inputs['Value'])
zl=N.new('ShaderNodeMapRange'); zl.inputs['From Min'].default_value=zmin+(zmax-zmin)*0.66; zl.inputs['From Max'].default_value=zmin+(zmax-zmin)*0.62; L.new(gp.outputs[2],zl.inputs['Value'])
zh=N.new('ShaderNodeMapRange'); zh.inputs['From Min'].default_value=zmin+(zmax-zmin)*0.1; zh.inputs['From Max'].default_value=zmin+(zmax-zmin)*0.14; L.new(gp.outputs[2],zh.inputs['Value'])
ax=N.new('ShaderNodeMath'); ax.operation='ABSOLUTE'; L.new(gp.outputs[0],ax.inputs[0])
xm=N.new('ShaderNodeMapRange'); xm.inputs['From Min'].default_value=0.088; xm.inputs['From Max'].default_value=0.1; xm.inputs['To Min'].default_value=1.0; xm.inputs['To Max'].default_value=0.0; L.new(ax.outputs[0],xm.inputs['Value'])
m0=N.new('ShaderNodeMath'); m0.operation='MULTIPLY'; L.new(back.outputs[0],m0.inputs[0]); L.new(xm.outputs[0],m0.inputs[1])
m1=N.new('ShaderNodeMath'); m1.operation='MULTIPLY'; L.new(m0.outputs[0],m1.inputs[0]); L.new(zl.outputs[0],m1.inputs[1])
m2=N.new('ShaderNodeMath'); m2.operation='MULTIPLY'; L.new(m1.outputs[0],m2.inputs[0]); L.new(zh.outputs[0],m2.inputs[1])
bw=N.new('ShaderNodeRGBToBW'); L.new(otex.outputs['Color'],bw.inputs[0])
lum=N.new('ShaderNodeMath'); lum.operation='MULTIPLY_ADD'; lum.inputs[1].default_value=1.6; lum.inputs[2].default_value=0.55; L.new(bw.outputs[0],lum.inputs[0])
cream=N.new('ShaderNodeMix'); cream.data_type='RGBA'; cream.blend_type='MULTIPLY'; cream.inputs['Factor'].default_value=1.0
cream.inputs['A'].default_value=(0.62,0.57,0.47,1); L.new(lum.outputs[0],cream.inputs['B'])
mix2=N.new('ShaderNodeMix'); mix2.data_type='RGBA'
L.new(m2.outputs[0],mix2.inputs['Factor']); L.new(mix.outputs['Result'],mix2.inputs['A']); L.new(cream.outputs['Result'],mix2.inputs['B'])
# hornear a una textura nueva de 2048
em=N.new('ShaderNodeEmission'); L.new(mix2.outputs['Result'],em.inputs[0])
outn=[n for n in N if n.type=='OUTPUT_MATERIAL'][0]
L.new(em.outputs[0],outn.inputs['Surface'])
newimg=bpy.data.images.new("elena_tex",2048,2048)
bt=N.new('ShaderNodeTexImage'); bt.image=newimg; N.active=bt; bt.select=True
L.new(ouv.outputs[0],bt.inputs[0])
sc=bpy.context.scene; sc.render.engine='CYCLES'; sc.cycles.samples=1; sc.cycles.device='CPU'
sc.render.bake.margin=8
ob.select_set(True)
bpy.ops.object.bake(type='EMIT')
newimg.filepath_raw=out+".png"; newimg.file_format='PNG'; newimg.save()
# material final
for n in list(N):
    if n not in (bsdf,outn): N.remove(n)
ft=N.new('ShaderNodeTexImage'); ft.image=newimg
L.new(ft.outputs['Color'],bsdf.inputs['Base Color']); L.new(bsdf.outputs[0],outn.inputs['Surface'])
bsdf.inputs['Roughness'].default_value=0.85
bsdf.inputs['Metallic'].default_value=0.0
me.uv_layers.remove(me.uv_layers["proj"])
bpy.ops.wm.save_as_mainfile(filepath=out+".blend")
print("BAKE OK", zmin, zmax)
