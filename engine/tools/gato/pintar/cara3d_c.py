import bpy, mathutils, bmesh, numpy as np
N=2048
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath='/tmp/ovg/glb/gt_cat57.glb')
for o in list(bpy.context.scene.objects):
    if o.name.startswith('Icosphere'): bpy.data.objects.remove(o)
arm=[o for o in bpy.context.scene.objects if o.type=='ARMATURE'][0]
m=[o for o in bpy.context.scene.objects if o.type=='MESH'][0]
import runpy
runpy.run_path('/home/claude/cronos/engine/tools/gato/editar.py', init_globals={'ob': m, 'arm': arm})
act=[a for a in bpy.data.actions if 'Idle_1' in a.name][0]; arm.animation_data.action=act; bpy.context.scene.frame_set(1)
dg=bpy.context.evaluated_depsgraph_get(); e=m.evaluated_get(dg); me=e.to_mesh()
P=np.array([tuple(e.matrix_world@v.co) for v in me.vertices])
# ojos = piezas de 22 vértices
bm=bmesh.new(); bm.from_mesh(m.data); bm.verts.ensure_lookup_table()
vist=set(); ojos=[]; ojos_v=set(); piezas_todas=[]
for v in bm.verts:
    if v.index in vist: continue
    pila=[v]; comp=[]
    while pila:
        x=pila.pop()
        if x.index in vist: continue
        vist.add(x.index); comp.append(x.index)
        for ed in x.link_edges: pila.append(ed.other_vert(x))
    uvs_c=[m.data.uv_layers.active.data[l.index].uv for f in [bm.verts[comp[0]]] for l in []]
    piezas_todas.append(comp)
# ojos: piezas cuya UV cae en la isla del ojo
uvd0=m.data.uv_layers.active.data
vuv={}
for poly in m.data.polygons:
    for li in poly.loop_indices:
        vuv[m.data.loops[li].vertex_index]=uvd0[li].uv
for comp in piezas_todas:
    u=vuv.get(comp[0])
    if u is not None and 0.828<u[0]<0.907 and 0.008<u[1]<0.09 and len(comp)<300:
        ojos.append(P[comp].mean(axis=0)); ojos_v.update(comp)
print("OJOS", len(ojos))
EL,ER=ojos[0],ojos[1]
if EL[0]<ER[0]: EL,ER=ER,EL
C=(EL+ER)/2
pb=arm.pose.bones
def bpos(n): return np.array(tuple(arm.matrix_world@pb[n].head))
cuello=bpos('neck_023'); oreja=(bpos('ear_1_L_029')+bpos('ear_1_R_033'))/2; boca=bpos('mouth_025')
X=(EL-ER); X/=np.linalg.norm(X)
F=C-cuello; F-=X*F.dot(X); F/=np.linalg.norm(F)
U=np.cross(F,X)
if U.dot(oreja-C)<0: U=-U
# ajustar F para que apunte hacia la boca/nariz (delante)
print("C",C.round(4),"X",X.round(3),"U",U.round(3),"F",F.round(3), "boca local", [round(float((boca-C).dot(a)),4) for a in (X,U,F)], "oreja local", [round(float((oreja-C).dot(a)),4) for a in (X,U,F)])
# rasterizar triángulos de la cabeza en UV con su posición local
vg={g.index:g.name for g in m.vertex_groups}
cabn=('head_024','mouth_025','ear_1_L_029','ear_2_L_030','ear_1_R_033','ear_2_R_034','eyelid_L_031','eyelid_R_035','mustache_L_032','mustache_R_036','neck_023')
cab=set(v.index for v in m.data.vertices if sum(g.weight for g in v.groups if vg[g.group] in cabn)>0.3)
uvd=m.data.uv_layers.active.data
L=np.zeros((N,N,3),np.float32); M=np.zeros((N,N),np.uint8)
me.calc_loop_triangles()
for t in me.loop_triangles:
    vs=list(t.vertices)
    if any(vi in ojos_v for vi in vs): continue
    cerca=all(np.linalg.norm(P[vi]-C)<0.11 for vi in vs)
    if sum(1 for vi in vs if vi in cab)<2 and not cerca: continue
    uv=np.array([tuple(uvd[li].uv) for li in t.loops]); px=np.stack([uv[:,0]*N,(1-uv[:,1])*N],1)
    loc=np.array([[(P[vi]-C).dot(X),(P[vi]-C).dot(U),(P[vi]-C).dot(F)] for vi in vs])
    x0,y0=np.floor(px.min(0)).astype(int); x1,y1=np.ceil(px.max(0)).astype(int)
    x0=max(x0,0);y0=max(y0,0);x1=min(x1,N-1);y1=min(y1,N-1)
    if x1<x0 or y1<y0: continue
    yy,xx=np.mgrid[y0:y1+1,x0:x1+1]+0.5
    a,b,c=px
    den=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
    if abs(den)<1e-9: continue
    w1=((b[1]-c[1])*(xx-c[0])+(c[0]-b[0])*(yy-c[1]))/den
    w2=((c[1]-a[1])*(xx-c[0])+(a[0]-c[0])*(yy-c[1]))/den
    w3=1-w1-w2
    ins=(w1>=-0.02)&(w2>=-0.02)&(w3>=-0.02)
    if not ins.any(): continue
    pos=w1[...,None]*loc[0]+w2[...,None]*loc[1]+w3[...,None]*loc[2]
    ys=(yy[ins]-0.5).astype(int); xs=(xx[ins]-0.5).astype(int)
    L[ys,xs]=pos[ins]; M[ys,xs]=1
np.save('/tmp/ovg/cara3_L.npy',L); np.save('/tmp/ovg/cara3_M.npy',M)
print("CARA px", int(M.sum()), "x", L[M>0,0].min().round(3), L[M>0,0].max().round(3), "y", L[M>0,1].min().round(3), L[M>0,1].max().round(3), "z", L[M>0,2].min().round(3), L[M>0,2].max().round(3))
