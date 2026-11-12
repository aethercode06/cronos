import bpy, sys, math, mathutils
from mathutils import Vector
src, out = sys.argv[-2], sys.argv[-1]
bpy.ops.wm.open_mainfile(filepath=src)
ob=[o for o in bpy.context.scene.objects if o.type=='MESH'][0]
H=1.82
ob.scale=(H,H,H); ob.location=(0,0,0.5*H)
bpy.context.view_layer.objects.active=ob; ob.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
me=ob.data
xs=[v.co.x for v in me.vertices]; xm=(min(xs)+max(xs))/2
for v in me.vertices: v.co.x-=xm
def P(x,z,y=0.0): return Vector((x*H/1.0*(1/1.0), y, z*H))
# esqueleto (alturas normalizadas 0=pies, 1=cabeza; x en unidades del modelo de 1 m de alto)
J={
 'hips':(0,0.50),'spine':(0,0.60),'chest':(0,0.72),'neck':(0,0.82),'head':(0,0.87),'head_end':(0,1.0),
}
arm=bpy.data.armatures.new('rig'); rig=bpy.data.objects.new('Elena',arm); bpy.context.scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig; ob.select_set(False); rig.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
eb=arm.edit_bones
def bone(name,a,b,parent=None,conn=False,roll=0.0):
    e=eb.new(name); e.head=Vector((a[0]*H,0,a[1]*H)); e.tail=Vector((b[0]*H,0,b[1]*H)); e.roll=roll
    if parent: e.parent=eb[parent]; e.use_connect=conn
    return e
# brazos (x,z normalizados): hombro, codo, muñeca, punta de la mano; y separación brazo/vestido
import os
AX=[float(v) for v in os.environ.get('RIG_ARM','0.085,0.795,0.112,0.625,0.125,0.475,0.128,0.39').split(',')]
GAP=[float(v) for v in os.environ.get('RIG_GAP','0.068,0.09,0.78').split(',')]
bone('root',(0,0.0),(0,0.12))
bone('hips',(0,0.50),(0,0.60),'root')
bone('spine',(0,0.60),(0,0.72),'hips',True)
bone('chest',(0,0.72),(0,0.81),'spine',True)
bone('neck',(0,0.81),(0,0.87),'chest',True)
bone('head',(0,0.87),(0,1.0),'neck',True)
for s,sx in (('L',1),('R',-1)):
    bone('shoulder.'+s,(0.02*sx,0.80),(AX[0]*sx,AX[1]),'chest')
    bone('upper_arm.'+s,(AX[0]*sx,AX[1]),(AX[2]*sx,AX[3]),'shoulder.'+s,True)
    bone('forearm.'+s,(AX[2]*sx,AX[3]),(AX[4]*sx,AX[5]),'upper_arm.'+s,True)
    bone('hand.'+s,(AX[4]*sx,AX[5]),(AX[6]*sx,AX[7]),'forearm.'+s,True)
    bone('thigh.'+s,(0.045*sx,0.50),(0.045*sx,0.27),'hips')
    bone('shin.'+s,(0.045*sx,0.27),(0.042*sx,0.045),'thigh.'+s,True)
    e=bone('foot.'+s,(0.042*sx,0.045),(0.045*sx,0.01),'shin.'+s,True)
    e.tail.y=-0.12
JAW = '--jaw' in sys.argv or True
if JAW:
    ys=[v.co.y for v in ob.data.vertices if abs(v.co.x)<0.03*H and 0.85*H<v.co.z<0.88*H]
    yf=min(ys) if ys else -0.06
    e=eb.new('jaw'); e.head=Vector((0, yf*0.25, 0.884*H)); e.tail=Vector((0, yf+0.004, 0.856*H)); e.parent=eb['head']
bpy.ops.object.mode_set(mode='OBJECT')
# pesos propios: distancia a cada hueso con reglas (brazos solo fuera del torso)
def seg_d(p,a,b):
    ab=b-a; t=max(0.0,min(1.0,(p-a).dot(ab)/ab.length_squared)); return (p-(a+ab*t)).length
bones=[(bn.name, rig.matrix_world@bn.head_local, rig.matrix_world@bn.tail_local) for bn in rig.data.bones if bn.name not in ('root','jaw')]
groups={n:ob.vertex_groups.new(name=n) for n,_,_ in bones}
def sstep(e0,e1,x):
    t=max(0.0,min(1.0,(x-e0)/(e1-e0))); return t*t*(3-2*t)
for v in me.vertices:
    p=v.co; ax=abs(p.x); ws=[]
    for n,hd,tl in bones:
        d=seg_d(p,hd,tl)
        w=1.0/((d+0.015)**4)
        if n in ('spine','chest','neck','head') and p.z < hd.z-0.04: w=0
        isarm=any(k in n for k in ('upper_arm','forearm','hand'))
        if isarm:
            if p.z < GAP[2]*H:
                w*=sstep(GAP[0]*H,GAP[1]*H,ax)
            elif p.z < 0.78*H:
                w*=sstep(0.068*H,0.09*H,ax)
                if d > (0.065 if 'hand' in n else 0.048): w=0
            if (n.endswith('.L') and p.x<0) or (n.endswith('.R') and p.x>0): w=0
        if n.startswith('shoulder') and ((n.endswith('.L') and p.x<0) or (n.endswith('.R') and p.x>0)): w=0
        if any(k in n for k in ('thigh','shin','foot')):
            lim=0.075 if 'thigh' in n else 0.14
            if p.z>0.52*H or d>lim: w=0
            elif 'thigh' in n: w*=0.5
            if (n.endswith('.L') and p.x<-0.01) or (n.endswith('.R') and p.x>0.01): w*=0.15
        ws.append((w,n))
    ws.sort(reverse=True); ws=ws[:3]; tot=sum(w for w,_ in ws) or 1
    for w,n in ws:
        if w/tot>0.02: groups[n].add([v.index], w/tot, 'REPLACE')
# mandíbula: parte baja de la cara (bajo la línea de la boca, por delante)
if JAW:
    gj=ob.vertex_groups.new(name='jaw'); nj=0
    yc=sum(ys)/len(ys) if ys else -0.05
    for v in me.vertices:
        p=v.co
        if not (0.835*H < p.z < 0.878*H) or p.y > 0.0: continue
        w=sstep(0.878*H,0.871*H,p.z)*sstep(0.835*H,0.848*H,p.z)*sstep(0.047*H,0.036*H,abs(p.x))*sstep(0.0,-0.02*H,p.y)
        if w<0.02: continue
        for g in v.groups:
            ob.vertex_groups[g.group].add([v.index], g.weight*(1-w), 'REPLACE')
        gj.add([v.index], w, 'REPLACE'); nj+=1
    print('MANDIBULA', nj)
ob.parent=rig
am=ob.modifiers.new('Armature','ARMATURE'); am.object=rig
unw=sum(1 for v in me.vertices if not any(g.weight>0.01 for g in v.groups))
print("SIN PESO", unw, "de", len(me.vertices))

# ---------------- animaciones ----------------
bpy.context.view_layer.objects.active=rig
bpy.ops.object.mode_set(mode='POSE')
pb=rig.pose.bones
for b in pb: b.rotation_mode='XYZ'
def calib(name, axis, target):
    """signo para que girar el eje local `axis` mueva la punta hacia `target`"""
    b=pb[name]; t0=(rig.matrix_world@b.tail).copy()
    r=[0,0,0]; r[axis]=0.3; b.rotation_euler=r; bpy.context.view_layer.update()
    t1=(rig.matrix_world@b.tail); b.rotation_euler=(0,0,0); bpy.context.view_layer.update()
    return 1.0 if (t1-t0).dot(target)>0 else -1.0
FWD=Vector((0,-1,0)); SIDE=Vector((1,0,0))
S={}
for b in pb:
    if b.name in ('root','jaw'): continue
    S[b.name]=(calib(b.name,0,FWD), calib(b.name,2,SIDE))
def key(name, f, fwd=0.0, side=0.0, twist=0.0):
    b=pb[name]; sf,ss=S[name]
    b.rotation_euler=(fwd*sf, twist, side*ss)
    b.keyframe_insert('rotation_euler', frame=f)
def loc(name,f,v):
    pb[name].location=v; pb[name].keyframe_insert('location',frame=f)
def clear():
    for b in pb:
        b.rotation_euler=(0,0,0); b.location=(0,0,0)
def new_action(n):
    clear()
    a=bpy.data.actions.new(n); a.use_fake_user=True
    rig.animation_data_create(); rig.animation_data.action=a
    return a
def all_bones_key(f):
    for b in pb:
        if b.name in S: b.keyframe_insert('rotation_euler',frame=f)
import random
random.seed(4)
# IDLE: respira, cabeza ladeada con tics
a=new_action('idle'); all_bones_key(0)
for f in range(0,61,10):
    k=math.sin(f/60*math.tau)
    key('chest',f,fwd=0.04+0.025*k); key('spine',f,fwd=0.05)
    key('head',f,fwd=0.18,side=0.42+(0.18 if f in (20,30) else 0.0)*random.choice([1,-1]))
    key('neck',f,fwd=0.12)
    for s,sx in (('L',1),('R',-1)):
        key('upper_arm.'+s,f,fwd=0.05*k,side=-0.05*sx); key('forearm.'+s,f,fwd=0.1); key('hand.'+s,f,fwd=0.2)
        key('thigh.'+s,f); key('shin.'+s,f)
# WALK: tambaleo lento
a=new_action('walk'); all_bones_key(0)
for f in range(0,33,4):
    ph=f/32*math.tau; k=math.sin(ph)
    key('hips',f,side=0.06*k); key('spine',f,fwd=0.12,side=-0.04*k); key('chest',f,fwd=0.06)
    key('neck',f,fwd=0.15); key('head',f,fwd=0.2,side=0.45+0.06*math.sin(ph*2))
    for s,sx in (('L',1),('R',-1)):
        sw=k*sx
        key('thigh.'+s,f,fwd=0.09*sw); key('shin.'+s,f,fwd=-0.12*max(0.0,-sw))
        key('upper_arm.'+s,f,fwd=-0.15*sw,side=-0.06*sx); key('forearm.'+s,f,fwd=0.25); key('hand.'+s,f,fwd=0.3)
# RUN: persecución, inclinada y con los brazos estirados hacia delante
a=new_action('run'); all_bones_key(0)
for f in range(0,21,2):
    ph=f/20*math.tau; k=math.sin(ph)
    key('hips',f,fwd=0.04,side=0.04*k); key('spine',f,fwd=0.42); key('chest',f,fwd=0.15,side=0.05*k)
    key('neck',f,fwd=-0.25); key('head',f,fwd=-0.1,side=0.35+0.25*random.uniform(-1,1))
    for s,sx in (('L',1),('R',-1)):
        sw=k*sx
        key('thigh.'+s,f,fwd=0.13*sw); key('shin.'+s,f,fwd=-0.16*max(0.0,-sw))
        key('upper_arm.'+s,f,fwd=0.28+0.1*sw,side=0.04*sx); key('forearm.'+s,f,fwd=0.25+0.1*random.uniform(-1,1)); key('hand.'+s,f,fwd=-0.2)
# ATTACK: se abalanza y agarra
a=new_action('attack'); all_bones_key(0)
for f,(sp,ua,fa,hd) in ((0,(0.1,0.1,0.2,0.1)),(6,(-0.2,0.45,0.2,-0.45)),(12,(0.6,0.55,0.45,-0.2)),(20,(0.55,0.5,0.5,-0.15)),(24,(0.55,0.5,0.5,-0.15))):
    key('spine',f,fwd=sp); key('chest',f,fwd=sp*0.6); key('neck',f,fwd=hd); key('head',f,fwd=hd,side=0.2)
    for s,sx in (('L',1),('R',-1)):
        key('upper_arm.'+s,f,fwd=ua,side=0.06*sx); key('forearm.'+s,f,fwd=fa); key('hand.'+s,f,fwd=-0.3)
        key('thigh.'+s,f,fwd=0.12 if s=='L' else -0.05); key('shin.'+s,f,fwd=-0.08)
for act in bpy.data.actions:
    for fc in act.fcurves if hasattr(act,'fcurves') else []:
        for kp in fc.keyframe_points: kp.interpolation='BEZIER'
clear()
rig.animation_data.action=bpy.data.actions['idle']
bpy.ops.object.mode_set(mode='OBJECT')
bpy.ops.wm.save_as_mainfile(filepath=out+".blend")
bpy.ops.export_scene.gltf(filepath=out+".glb", export_format='GLB', export_animations=True, export_animation_mode='ACTIONS', export_apply=False, export_yup=True)
print("EXPORT OK", [a.name for a in bpy.data.actions])
