"""Prepara los GLB de Objaverse para el juego: escala real (por tipo de objeto), origen en la base y centrado,
reduce triángulos y texturas para móvil. Uso: python preparar.py <carpeta_glb> <salida> <max_tris> <max_tex>"""
import bpy, sys, os, glob, json, mathutils
A = [a for a in sys.argv if not a.startswith('--')]
SRC, OUT, MAXT, MAXTEX = A[-4], A[-3], int(A[-2]), int(A[-1])
# altura real aproximada (m) por palabra clave del nombre
ALTO = [("grandfather", 2.1), ("wardrobe", 2.1), ("bookcase", 2.1), ("bookshel", 2.0), ("cabinet", 1.9), ("cupboard", 1.0), ("piano_stool", 0.75), ("stool", 0.7),
        ("grand_piano", 1.0), ("piano", 1.3), ("fireplace", 1.4), ("fire_place", 1.4), ("caminetto", 1.5), ("stove", 0.9), ("chandelier", 0.9), ("candelabra", 1.5),
        ("bathtub", 0.7), ("bathtube", 0.7), ("tub", 0.7), ("washbasin", 0.95), ("sink", 0.9), ("sofa", 0.95), ("lounge", 0.95), ("armchair", 1.05), ("chair", 1.0),
        ("desk", 0.8), ("coffee_table", 0.5), ("table", 0.78), ("mirror", 1.7), ("safe", 1.1), ("sewing", 1.0), ("typewriter", 0.25), ("globe", 0.5),
        ("rocking_horse", 0.75), ("dollhouse", 0.9), ("music_box", 0.18), ("kettle", 0.25), ("teapot", 0.2), ("samovar", 0.5), ("cup", 0.08), ("bowl", 0.08),
        ("spoon", 0.02), ("cutting_board", 0.03), ("bread", 0.06), ("books", 0.3), ("book", 0.25), ("bottle", 0.3), ("jar", 0.2), ("pocket", 0.06), ("watch", 0.06),
        ("candle", 0.3), ("key", 0.02), ("knocker", 0.25), ("clock", 0.5), ("lamp", 0.6), ("lantern", 0.5), ("cobweb", 0.6), ("statue", 0.6), ("bust", 0.6),
        ("crate", 0.8), ("pine", 14.0), ("spruce", 14.0), ("fir", 14.0), ("dead_tree", 7.0), ("tree_trunk", 2.0), ("stump", 0.7), ("lying", 1.0), ("tree", 9.0)]
# objetos planos o alargados: la medida es la dimensión mayor, no la altura
MAXDIM = [("12_old_books", 0.9), ("old_books", 0.7), ("occult_books", 0.5), ("books", 0.4), ("bookstack", 0.4), ("key", 0.09), ("spoon", 0.2), ("bread", 0.25),
          ("cutting_board", 0.4), ("cup", 0.14), ("bowl", 0.16), ("watch", 0.06), ("stump", 1.2), ("log", 3.0), ("lying", 8.0), ("kitchen_shelf", 1.2),
          ("cobweb", 1.2), ("pantry_shelf", 1.2), ("rocking_horse", 1.1), ("crate", 1.2), ("knocker", 0.25), ("table_and_chairs", 2.6), ("small_antique_table", 0.9)]
GRANDE = ("piano", "wardrobe", "bookcase", "bookshel", "fireplace", "fire_place", "sofa", "lounge", "bathtub", "tree", "pine", "spruce", "fir", "stove", "cabinet", "clock", "desk", "table", "safe", "armchair", "chair", "mirror")
os.makedirs(OUT, exist_ok=True)
info = {}
for f in sorted(glob.glob(os.path.join(SRC, "*.glb"))):
    name = os.path.basename(f)[:-4]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    try:
        bpy.ops.import_scene.gltf(filepath=f)
    except Exception as e:
        print("FALLO", name, e); continue
    for o in list(bpy.data.objects):
        if o.type in ('CAMERA', 'LIGHT', 'EMPTY') and not o.children: bpy.data.objects.remove(o)
    meshes = [o for o in bpy.data.objects if o.type == 'MESH']
    if not meshes: print("VACIO", name); continue
    # aplicar transformaciones y unir
    for o in bpy.data.objects: o.select_set(o in meshes)
    bpy.context.view_layer.objects.active = meshes[0]
    for o in meshes:
        if o.parent:
            mw = o.matrix_world.copy(); o.parent = None; o.matrix_world = mw
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if len(meshes) > 1:
        bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active
    for o in list(bpy.data.objects):
        if o != ob: bpy.data.objects.remove(o)
    pts = [ob.matrix_world @ mathutils.Vector(c) for c in ob.bound_box]
    mn = mathutils.Vector([min(p[i] for p in pts) for i in range(3)]); mx = mathutils.Vector([max(p[i] for p in pts) for i in range(3)])
    h = mx.z - mn.z
    low = name.lower()
    md = next((v for k, v in MAXDIM if k in low), None)
    if md:
        s = md / max(mx.x - mn.x, mx.y - mn.y, h)
    else:
        target = next((v for k, v in ALTO if k in low), None)
        s = target / h if (target and h > 0) else 1.0
        if s * max(mx.x - mn.x, mx.y - mn.y, h) > 6.0 and not any(k in low for k in ("tree", "pine", "spruce", "fir", "forest")):
            s = 1.5 / max(mx.x - mn.x, mx.y - mn.y, h)
    # origen: centro de la base
    ob.location -= mathutils.Vector(((mn.x + mx.x) / 2, (mn.y + mx.y) / 2, mn.z))
    bpy.ops.object.transform_apply(location=True)
    ob.scale = (s, s, s); bpy.ops.object.transform_apply(scale=True)
    t0 = len(ob.data.polygons)
    lim_t = MAXT * (3 if any(k in low for k in ("pine", "spruce", "fir", "tree")) else 1)
    if t0 > lim_t:
        m = ob.modifiers.new("dec", 'DECIMATE'); m.ratio = lim_t / t0; bpy.ops.object.modifier_apply(modifier="dec")
    for im in bpy.data.images:
        lim = MAXTEX if any(k in low for k in GRANDE) else MAXTEX // 2
        if im.size[0] > lim:
            im.scale(lim, max(1, lim * im.size[1] // im.size[0]))
    d = ob.dimensions
    info[name] = {"tam": [round(d.x, 3), round(d.z, 3), round(d.y, 3)], "tris": len(ob.data.polygons), "escala": round(s, 4)}
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, name + ".glb"), export_format='GLB', export_image_format='WEBP', export_apply=True)
    print("OK", name, t0, "->", len(ob.data.polygons), info[name]["tam"])
json.dump(info, open(os.path.join(OUT, "objetos.json"), "w"), indent=1)
