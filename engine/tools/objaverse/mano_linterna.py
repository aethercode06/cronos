# Mano derecha de Sofía (FREE FPS Arms with glove, CC-BY) sujetando la linterna (Retro Style Flashlight, CC-BY).
import bpy, sys, math, mathutils
from mathutils import Vector, Matrix
a=sys.argv[sys.argv.index('--')+1:]
brazos, linterna, out = a[0], a[1], a[2]
P=dict(x.split('=') for x in a[3:])
f=lambda k,d: float(P.get(k,d))
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=brazos)
for o in list(bpy.data.objects):
    if o.type=='MESH' and o.name!='Object_7': bpy.data.objects.remove(o)
mano=bpy.data.objects['Object_7']; arm=bpy.data.objects['GLTF_created_0']
pb=arm.pose.bones
def up(): bpy.context.view_layer.update()
def headw(n): return arm.matrix_world@pb[n].head
def rot_bone(n, axis, ang, piv=None):
    piv = headw(n) if piv is None else piv
    aw=arm.matrix_world
    R=Matrix.Translation(piv)@Matrix.Rotation(ang,4,axis.normalized())@Matrix.Translation(-piv)
    pb[n].matrix = aw.inverted()@R@aw@pb[n].matrix
    up()
# muñeca: dedos hacia abajo/dentro para que los nudillos queden a lo largo del cañón
mu=headw('hand_r_39')
rot_bone('hand_r_39', Vector((1,0,0)), math.radians(f('pitch',80)), mu)
rot_bone('hand_r_39', Vector((0,0,1)), math.radians(f('yaw',0)), mu)
rot_bone('hand_r_39', Vector((0,1,0)), math.radians(f('roll',0)), mu)
# eje de los nudillos (del meñique al índice)
def knuck(): return (headw('index_01_r_26')-headw('pinky_01_r_32')).normalized()
for dedo in ('index','middle','ring','pinky'):
    for i,ang in ((1,f('c1',55)),(2,f('c2',70)),(3,f('c3',45))):
        n=[b.name for b in pb if b.name.startswith(f'{dedo}_0{i}_r_')][0]
        rot_bone(n, knuck(), math.radians(ang)*f('sg',1))
for i,ang in ((1,f('t1',20)),(2,f('t2',25)),(3,f('t3',20))):
    n=[b.name for b in pb if b.name.startswith(f'thumb_0{i}_r_')][0]
    rot_bone(n, knuck(), math.radians(ang)*f('sg',1))
up()
# centro del puño: entre la base de los dedos curvados y la palma
k=knuck()
base=(headw('middle_01_r_29')+headw('ring_01_r_35'))/2
punta=(headw('middle_03_r_27')+arm.matrix_world@pb['middle_03_r_27'].tail)/2
palma=headw('hand_r_39').lerp(base,0.75)
centro=(base+punta+palma)/3 + (punta-base)*f('cofs',0.0)
print("NUDILLOS", tuple(round(v,3) for v in k), "CENTRO", tuple(round(v,3) for v in centro))
# malla estática y sin el brazo izquierdo
dg=bpy.context.evaluated_depsgraph_get()
me=bpy.data.meshes.new_from_object(mano.evaluated_get(dg))
gi={g.index:g.name for g in mano.vertex_groups}
fija=bpy.data.objects.new('mano',me); bpy.context.scene.collection.objects.link(fija)
fija.matrix_world=mano.matrix_world.copy()
import bmesh
bm=bmesh.new(); bm.from_mesh(me)
quita=[]
for v in bm.verts:
    g=max(mano.data.vertices[v.index].groups,key=lambda g:g.weight)
    nm=gi[g.group]
    if nm.endswith(tuple('_%d'%i for i in range(1,24))) and ('_l_' in nm or nm.startswith('lk_mano_L')) or 'rootJoint' in nm or nm.startswith(('clavicle','upperarm')):
        quita.append(v)
bmesh.ops.delete(bm, geom=quita, context='VERTS')
bm.to_mesh(me); bm.free()
bpy.data.objects.remove(mano); bpy.data.objects.remove(arm)
for o in list(bpy.data.objects):
    if o.type=='EMPTY': bpy.data.objects.remove(o)
# linterna: cabeza en +X, la paso a lo largo de los nudillos (índice -> cabeza)
antes=set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=linterna)
lin=[o for o in bpy.data.objects if o not in antes and o.type=='MESH']
for o in list(bpy.data.objects):
    if o not in antes and o.type=='EMPTY':
        for c in o.children: 
            mw=c.matrix_world.copy(); c.parent=None; c.matrix_world=mw
for o in list(bpy.data.objects):
    if o not in antes and o.type=='EMPTY': bpy.data.objects.remove(o)
pts=[o.matrix_world@v.co for o in lin for v in o.data.vertices]
mn=Vector(map(min,*pts)); mx=Vector(map(max,*pts)); cc=(mn+mx)/2
largo=f('largo',0.9)  # en unidades de los brazos
s=largo/(mx.x-mn.x)
eje=Vector((1,0,0))
R=eje.rotation_difference(k).to_matrix().to_4x4()
# el mango (parte fina) en el puño: el agarre a 1/3 desde la cola
agarre=Vector((mn.x+(mx.x-mn.x)*f('agarre',0.33),cc.y,cc.z))
M=Matrix.Translation(centro)@R@Matrix.Diagonal((s,s,s,1))@Matrix.Translation(-agarre)
for o in lin: o.matrix_world=M@o.matrix_world
if P.get('nolin'):
    for o in lin: o.hide_render=True
lente=M@Vector((mx.x,cc.y,cc.z))
print("LENTE", tuple(round(v,3) for v in lente))
# todo junto, con el origen en la lente y el haz mirando a -Z (Godot) => en Blender -Y
Rk=k.rotation_difference(Vector((0,-1,0))).to_matrix().to_4x4()
for o in [fija]+lin:
    o.matrix_world=Rk@Matrix.Translation(-lente)@o.matrix_world
centro=Rk@(centro-lente)+lente
bpy.context.scene['lente_dir']=list(k)
# cámara de primera persona para revisar
sc=bpy.context.scene
cam=bpy.data.objects.new("c",bpy.data.cameras.new("c")); sc.collection.objects.link(cam)
cam.data.sensor_fit='VERTICAL'; cam.data.angle=math.radians(72)
ojo=Vector((0,0,0.97))-lente
cam.location=ojo+Vector((f('cx',0),0,f('cz',0))); cam.rotation_euler=(math.radians(90+f('cp',0)),0,math.radians(180)); sc.camera=cam
sc.render.engine='BLENDER_WORKBENCH'; sc.display.shading.light='STUDIO'; sc.display.shading.color_type='TEXTURE'
sc.render.resolution_x=640; sc.render.resolution_y=360
sc.render.filepath=out+'_fp.png'; bpy.ops.render.render(write_still=True)
c2=bpy.data.objects.new("c2",bpy.data.cameras.new("c2")); sc.collection.objects.link(c2)
for i,d in enumerate([(-1,0.4,0.4),(1,0.3,0.3),(0,0.2,1)]):
    c2.location=(centro-lente)+Vector(d).normalized()*float(P.get('dist',0.9)); c2.rotation_euler=((centro-lente)-c2.location).to_track_quat('-Z','Y').to_euler(); sc.camera=c2
    sc.render.filepath=out+f'_lado{i}.png'; bpy.ops.render.render(write_still=True)
if P.get('exportar'):
    esc=0.23/largo  # la linterna mide 23 cm
    for o in bpy.data.objects:
        if o.type=='MESH': o.matrix_world=Matrix.Diagonal((esc,esc,esc,1))@o.matrix_world
    for i,im in enumerate(bpy.data.images):
        im.name='sofia_mano_tex%d'%i
        if im.size[0]>1024: im.scale(1024, max(1,int(im.size[1]*1024/im.size[0])))
    for o in bpy.data.objects:
        o.select_set(o.type=='MESH')
    bpy.ops.export_scene.gltf(filepath=P['exportar'], use_selection=True, export_format='GLB', export_image_format='JPEG', export_jpeg_quality=85, export_apply=True)
