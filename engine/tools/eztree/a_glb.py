"""Pasa los árboles de Ez-Tree (JSON de generar.mjs) a GLB para el juego: altura real, corteza ambientCG (CC0) con
normal y rugosidad, ramas con hojas de foto (alfa recortado), y menos polígonos para móvil.
Uso: python a_glb.py <carpeta_json> <carpeta_texturas> <salida>"""
import bpy, bmesh, json, os, sys, random
A = [a for a in sys.argv if not a.startswith('--')]
SRC, TEX, OUT = A[-3], A[-2], A[-1]
os.makedirs(OUT, exist_ok=True)
# nombre: (altura m, corteza, tinte corteza, hoja, fracción de tarjetas de hoja que se quedan, triángulos máx. de ramas)
CFG = {
    "pino_grande_1": (19.0, "Bark001", (0.55, 0.45, 0.38), "pine", 0.9, 3000),
    "pino_grande_2": (17.5, "Bark001", (0.5, 0.42, 0.36), "pine", 0.9, 3000),
    "pino_grande_3": (20.5, "Bark001", (0.52, 0.44, 0.37), "pine", 0.9, 3000),
    "pino_mediano_1": (13.0, "Bark001", (0.55, 0.45, 0.38), "pine", 0.85, 2400),
    "pino_mediano_2": (12.0, "Bark001", (0.5, 0.42, 0.36), "pine", 0.85, 2400),
    "pino_joven": (6.0, "Bark001", (0.58, 0.48, 0.4), "pine", 0.9, 1600),
    "muerto_roble": (11.0, "Bark001", (0.62, 0.6, 0.58), None, 0, 4000),
    "muerto_fresno": (12.0, "Bark001", (0.6, 0.58, 0.56), None, 0, 4000),
    "muerto_roble_2": (7.5, "Bark001", (0.6, 0.58, 0.55), None, 0, 2500),
    "arbusto_1": (1.6, "Bark001", (0.5, 0.45, 0.4), "ash", 0.6, 1200),
    "arbusto_2": (1.3, "Bark001", (0.5, 0.45, 0.4), "aspen", 0.8, 800),
}

def img(path, color=True):
    im = bpy.data.images.load(path, check_existing=True)
    if not color:
        im.colorspace_settings.name = "Non-Color"
    return im

def mat_corteza(nombre, bark, tinte, escala_v):
    m = bpy.data.materials.new("corteza_" + nombre)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    d = os.path.join(TEX, "bark", bark + "_1K-JPG", bark + "_1K-JPG_")
    uvn = nt.nodes.new("ShaderNodeUVMap")
    mp = nt.nodes.new("ShaderNodeMapping")
    mp.inputs["Scale"].default_value = (1.0, escala_v, 1.0)
    nt.links.new(uvn.outputs["UV"], mp.inputs["Vector"])
    c = nt.nodes.new("ShaderNodeTexImage"); c.image = img(d + "Color.jpg")
    nt.links.new(mp.outputs["Vector"], c.inputs["Vector"])
    mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"; mix.blend_type = "MULTIPLY"; mix.inputs["Factor"].default_value = 1.0
    mix.inputs[7].default_value = (*tinte, 1.0)
    nt.links.new(c.outputs["Color"], mix.inputs[6])
    nt.links.new(mix.outputs[2], bsdf.inputs["Base Color"])
    r = nt.nodes.new("ShaderNodeTexImage"); r.image = img(d + "Roughness.jpg", False)
    nt.links.new(mp.outputs["Vector"], r.inputs["Vector"])
    nt.links.new(r.outputs["Color"], bsdf.inputs["Roughness"])
    n = nt.nodes.new("ShaderNodeTexImage"); n.image = img(d + "NormalGL.jpg", False)
    nt.links.new(mp.outputs["Vector"], n.inputs["Vector"])
    nm = nt.nodes.new("ShaderNodeNormalMap")
    nt.links.new(n.outputs["Color"], nm.inputs["Color"])
    nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
    return m

def mat_hoja(hoja):
    m = bpy.data.materials.new("hojas_" + hoja)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    t = nt.nodes.new("ShaderNodeTexImage"); t.image = img(os.path.join(TEX, "leaves", hoja + ".png"))
    # color algo más oscuro y apagado: bosque de noche, no de catálogo
    mix = nt.nodes.new("ShaderNodeMix"); mix.data_type = "RGBA"; mix.blend_type = "MULTIPLY"; mix.inputs["Factor"].default_value = 1.0
    mix.inputs[7].default_value = (0.55, 0.62, 0.5, 1.0)
    nt.links.new(t.outputs["Color"], mix.inputs[6])
    nt.links.new(mix.outputs[2], bsdf.inputs["Base Color"])
    nt.links.new(t.outputs["Alpha"], bsdf.inputs["Alpha"])
    bsdf.inputs["Roughness"].default_value = 0.85
    m.blend_method = "CLIP" if hasattr(m, "blend_method") else m.blend_method
    try:
        m.surface_render_method = "DITHERED"
    except Exception:
        pass
    m.use_backface_culling = False
    return m

def malla(nombre, d, escala):
    pos, uv, idx = d["pos"], d["uv"], d["idx"]
    nv = len(pos) // 3
    verts = [(pos[i * 3] * escala, -pos[i * 3 + 2] * escala, pos[i * 3 + 1] * escala) for i in range(nv)]
    tris = [(idx[i], idx[i + 1], idx[i + 2]) for i in range(0, len(idx), 3)] if idx else [(i, i + 1, i + 2) for i in range(0, nv, 3)]
    me = bpy.data.meshes.new(nombre)
    me.from_pydata(verts, [], tris)
    me.update()
    if uv:
        uvl = me.uv_layers.new(name="UVMap")
        for poly in me.polygons:
            for li in poly.loop_indices:
                vi = me.loops[li].vertex_index
                uvl.data[li].uv = (uv[vi * 2], uv[vi * 2 + 1])
    for p in me.polygons:
        p.use_smooth = True
    ob = bpy.data.objects.new(nombre, me)
    bpy.context.collection.objects.link(ob)
    return ob

info = {}
for f in sorted(os.listdir(SRC)):
    if not f.endswith(".json") or f == "info.json":
        continue
    nombre = f[:-5]
    if nombre not in CFG:
        continue
    alto, bark, tinte, hoja, quedan, max_t = CFG[nombre]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    d = json.load(open(os.path.join(SRC, f)))
    ys = d["ramas"]["pos"][1::3]
    escala = alto / max(max(ys), 0.01)
    ram = malla(nombre + "_ramas", d["ramas"], escala)
    ram.data.materials.append(mat_corteza(nombre, bark, tinte, 1.0 / float(d["bark"].get("textureScale", {}).get("y", 1) or 1)))
    t0 = len(ram.data.polygons)
    if t0 > max_t:
        mod = ram.modifiers.new("dec", "DECIMATE"); mod.ratio = max_t / t0
        bpy.context.view_layer.objects.active = ram
        bpy.ops.object.modifier_apply(modifier="dec")
    objs = [ram]
    th = 0
    if hoja and d.get("hojas"):
        hj = malla(nombre + "_hojas", d["hojas"], escala)
        hj.data.materials.append(mat_hoja(hoja))
        # menos tarjetas pero algo más grandes (cada tarjeta son 2 triángulos de un mismo quad)
        bm = bmesh.new(); bm.from_mesh(hj.data)
        bm.faces.ensure_lookup_table()
        random.seed(7)
        quitar = []
        caras = list(bm.faces)
        for i in range(0, len(caras) - 1, 2):
            if random.random() > quedan:
                quitar += [caras[i], caras[i + 1]]
        bmesh.ops.delete(bm, geom=quitar, context="FACES")
        bm.to_mesh(hj.data); bm.free()
        th = len(hj.data.polygons)
        objs.append(hj)
    for o in objs:
        o.select_set(True)
    out = os.path.join(OUT, nombre + ".glb")
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=True, export_image_format="WEBP", export_apply=True)
    info[nombre] = {"alto": alto, "tris_ramas": len(ram.data.polygons), "tris_hojas": th}
    print("ARBOL", nombre, info[nombre], flush=True)
json.dump(info, open(os.path.join(OUT, "arboles.json"), "w"), indent=1)
