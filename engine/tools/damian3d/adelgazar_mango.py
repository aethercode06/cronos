import bpy, numpy as np
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath="/home/claude/damian/armas/w_hacha_vieja.glb")
o=[x for x in bpy.data.objects if x.type=='MESH'][0]
V=np.array([v.co for v in o.data.vertices]); z=V[:,2]; zmin,zmax=z.min(),z.max()
t=(z-zmin)/(zmax-zmin)
cerca=V[(t<0.6)]; cx,cy=np.median(cerca[:,0]),np.median(cerca[:,1]); r=np.median(np.hypot(cerca[:,0]-cx,cerca[:,1]-cy)); print("radio antes", r)
f=0.0125/r
k=np.clip((0.78-t)/0.05,0,1)*(1-f)+f  # mango: factor f; cerca de la cabeza, sin cambio
for i,v in enumerate(o.data.vertices):
    if t[i]<0.83:
        kk=k[i] if t[i]>0.73 else f
        v.co.x=cx+(v.co.x-cx)*kk; v.co.y=cy+(v.co.y-cy)*kk
bpy.ops.export_scene.gltf(filepath="/home/claude/damian/armas/w_hacha_vieja.glb", export_format='GLB')
print("radio objetivo 0.0125")
