"""Convierte los modelos glTF de Poly Haven a GLB ligeros para móvil: reduce triángulos y texturas.
Uso: python optimizar.py <carpeta_modelos> <salida> [max_tris] [max_tex]"""
import bpy, sys, os, glob, json
A = [a for a in sys.argv if not a.startswith('--')]
SRC, OUT = A[-4], A[-3]
MAXT, MAXTEX = int(A[-2]), int(A[-1])
GRANDES = {"GothicBed_01": 1024, "GothicCabinet_01": 1024, "vintage_grandfather_clock_01": 1024, "Sofa_01": 1024, "dining_table": 1024, "old_bed_frame": 1024, "wooden_bookshelf_worn": 1024, "gothic_statue": 1024}
os.makedirs(OUT, exist_ok=True)
info = {}
for d in sorted(glob.glob(os.path.join(SRC, "*"))):
    name = os.path.basename(d)
    g = glob.glob(os.path.join(d, "*.gltf"))
    if not g: continue
    bpy.ops.wm.read_factory_settings(use_empty=True)
    try:
        bpy.ops.import_scene.gltf(filepath=g[0])
    except Exception as e:
        print("FALLO", name, e); continue
    meshes = [o for o in bpy.data.objects if o.type == 'MESH']
    t0 = sum(len(o.data.polygons) for o in meshes)
    if t0 > MAXT:
        r = MAXT / t0
        for o in meshes:
            m = o.modifiers.new("dec", 'DECIMATE'); m.ratio = r
            bpy.context.view_layer.objects.active = o
            for x in bpy.data.objects: x.select_set(x == o)
            bpy.ops.object.modifier_apply(modifier="dec")
    t1 = sum(len(o.data.polygons) for o in meshes)
    lim = GRANDES.get(name, MAXTEX)
    for im in bpy.data.images:
        if im.size[0] > lim:
            im.scale(lim, lim * im.size[1] // max(1, im.size[0]))
    import mathutils
    pts = [o.matrix_world @ mathutils.Vector(c) for o in meshes for c in o.bound_box]
    mn = [min(p[i] for p in pts) for i in range(3)]; mx = [max(p[i] for p in pts) for i in range(3)]
    info[name] = {"tris": t1, "tam": [round(mx[0] - mn[0], 3), round(mx[2] - mn[2], 3), round(mx[1] - mn[1], 3)]}
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, name + ".glb"), export_format='GLB', export_image_format='WEBP')
    print("OK", name, t0, "->", t1, info[name]["tam"])
json.dump(info, open(os.path.join(OUT, "muebles.json"), "w"), indent=1)
