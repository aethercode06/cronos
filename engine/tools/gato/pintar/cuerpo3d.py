import bpy, mathutils, bmesh, numpy as np, runpy
N=2048
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath='/tmp/ovg/glb/gt_cat57.glb')
for o in list(bpy.context.scene.objects):
    if o.name.startswith('Icosphere'): bpy.data.objects.remove(o)
arm=[o for o in bpy.context.scene.objects if o.type=='ARMATURE'][0]
m=[o for o in bpy.context.scene.objects if o.type=='MESH'][0]
runpy.run_path('/home/claude/cronos/engine/tools/gato/editar.py', init_globals={'ob': m, 'arm': arm})
act=[a for a in bpy.data.actions if 'Idle_1' in a.name][0]; arm.animation_data.action=act; bpy.context.scene.frame_set(1)
dg=bpy.context.evaluated_depsgraph_get(); e=m.evaluated_get(dg); me=e.to_mesh()
P=np.array([tuple(e.matrix_world@v.co) for v in me.vertices],np.float32)
nombres=[g.name for g in m.vertex_groups]
dom=np.zeros(len(m.data.vertices),np.int32)
for v in m.data.vertices:
    if v.groups:
        g=max(v.groups,key=lambda g:g.weight); dom[v.index]=g.group
uvd=m.data.uv_layers.active.data
Pt=np.zeros((N,N,3),np.float32); B=np.full((N,N),-1,np.int16)
me.calc_loop_triangles()
for t in me.loop_triangles:
    vs=list(t.vertices)
    uv=np.array([tuple(uvd[li].uv) for li in t.loops]); px=np.stack([uv[:,0]*N,(1-uv[:,1])*N],1)
    x0,y0=np.floor(px.min(0)).astype(int); x1,y1=np.ceil(px.max(0)).astype(int)
    x0=max(x0,0);y0=max(y0,0);x1=min(x1,N-1);y1=min(y1,N-1)
    if x1<x0 or y1<y0: continue
    yy,xx=np.mgrid[y0:y1+1,x0:x1+1]+0.5
    a,b,c=px
    den=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
    if abs(den)<1e-12: continue
    w1=((b[1]-c[1])*(xx-c[0])+(c[0]-b[0])*(yy-c[1]))/den
    w2=((c[1]-a[1])*(xx-c[0])+(a[0]-c[0])*(yy-c[1]))/den
    w3=1-w1-w2
    ins=(w1>=-0.03)&(w2>=-0.03)&(w3>=-0.03)
    if not ins.any(): continue
    pos=w1[...,None]*P[vs[0]]+w2[...,None]*P[vs[1]]+w3[...,None]*P[vs[2]]
    k=np.argmax(np.stack([w1,w2,w3],-1),-1)
    ys=(yy[ins]-0.5).astype(int); xs=(xx[ins]-0.5).astype(int)
    Pt[ys,xs]=pos[ins]; B[ys,xs]=np.array([dom[vs[0]],dom[vs[1]],dom[vs[2]]])[k[ins]]
pb=arm.pose.bones
def bp(n,cola=False): b=pb[n]; return list(arm.matrix_world@(b.tail if cola else b.head))
huesos={n:[bp(n),bp(n,True)] for n in [b.name for b in pb]}
np.save('/tmp/ovg/cuerpo_P.npy',Pt); np.save('/tmp/ovg/cuerpo_B.npy',B)
import json; json.dump({"nombres":nombres,"huesos":huesos},open('/tmp/ovg/cuerpo_info.json','w'))
print("CUERPO OK", int((B>=0).sum()))
