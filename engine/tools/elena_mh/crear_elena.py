"""Crea a Elena con MPFB (MakeHuman): cuerpo, ojos, dientes, lengua, cejas, pestañas, pelo, esqueleto de juego y
gestos faciales ARKit (formas). Guarda .blend, .glb y capturas. Uso: python crear_elena.py <salida>"""
import bpy, sys, os, math, importlib, json, traceback
OUT = sys.argv[-1]; os.makedirs(OUT, exist_ok=True)
LOG = []
def log(*a):
    s = " ".join(str(x) for x in a); print(s, flush=True); LOG.append(s)
bpy.ops.preferences.addon_enable(module="bl_ext.user_default.mpfb")
def imp(mod, key):
    for m in list(sys.modules):
        if m.endswith(mod):
            return getattr(importlib.import_module(m), key)
    raise ValueError(mod)
HumanService = imp("mpfb.services.humanservice", "HumanService")
AssetService = imp("mpfb.services.assetservice", "AssetService")
TargetService = imp("mpfb.services.targetservice", "TargetService")
HOP = imp("mpfb.entities.objectproperties", "HumanObjectProperties")
FaceService = imp("mpfb.services.faceservice", "FaceService")
ExportService = imp("mpfb.services.exportservice", "ExportService")
ObjectService = imp("mpfb.services.objectservice", "ObjectService")
CFG = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "elena.json")))

for o in list(bpy.data.objects): bpy.data.objects.remove(o)
h = HumanService.create_human()
for k, v in CFG["macros"].items():
    HOP.set_value(k, v, entity_reference=h)
TargetService.reapply_macro_details(h)
for t, v in CFG.get("targets", {}).items():
    try:
        fp = TargetService.target_full_path(t)
        if fp is None: log("target no existe", t); continue
        TargetService.load_target(h, fp, weight=v, name=t); log("target", t, v)
    except Exception as e:
        log("target falla", t, e)
try:
    skin = AssetService.find_asset_absolute_path(CFG["piel"], asset_subdir="skins")
    HumanService.set_character_skin(skin, h, skin_type="GAMEENGINE"); log("piel", skin)
except Exception as e:
    log("piel falla", e)
rig = HumanService.add_builtin_rig(h, CFG.get("rig", "game_engine")); log("rig", rig.name if rig else None)
for sub, fn, typ in CFG["recursos"]:
    p = AssetService.find_asset_absolute_path(fn, asset_subdir=sub)
    if p is None:
        log("NO ENCONTRADO", sub, fn); continue
    try:
        HumanService.add_mhclo_asset(p, h, asset_type=typ, material_type="GAMEENGINE"); log("recurso", fn)
    except Exception as e:
        log("recurso falla", fn, e)
try:
    if FaceService.is_faceunits01_installed(True):
        FaceService.load_targets(h, load_microsoft_visemes=False, load_arkit_faceunits=True)
        FaceService.interpolate_targets(h); log("gestos ARKit cargados")
    else:
        log("faceunits01 NO instalado")
except Exception as e:
    log("gestos falla", e, traceback.format_exc()[-800:])
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "elena_mh.blend"))
# exportación para juego
try:
    root = ExportService.create_character_copy(h, name_suffix="_export")
    eb = ObjectService.find_object_of_type_amongst_nearest_relatives(root, "Basemesh")
    ExportService.bake_modifiers_remove_helpers(eb, bake_masks=True, bake_subdiv=False, remove_helpers=True, also_proxy=True)
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for c in ObjectService.get_list_of_children(root): c.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "elena_mh.glb"), use_selection=True, export_format='GLB',
                              export_morph=True, export_skins=True, export_animations=False, export_yup=True)
    log("GLB exportado")
except Exception as e:
    log("export falla", e, traceback.format_exc()[-1500:])
try:
    bpy.ops.file.pack_all()
except Exception as e:
    log("pack falla", e)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "elena_mh_export.blend"))
for o in bpy.data.objects:
    log("obj", o.name, o.type, (len(o.data.vertices) if o.type == 'MESH' else ""), (len(o.data.shape_keys.key_blocks) if o.type == 'MESH' and o.data.shape_keys else 0))
if h.data.shape_keys:
    log("FORMAS", [k.name for k in h.data.shape_keys.key_blocks])
# capturas
sc = bpy.context.scene; sc.render.engine = 'CYCLES'; sc.cycles.samples = 64; sc.cycles.device = 'CPU'
w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True; w.node_tree.nodes['Background'].inputs[1].default_value = 0.7
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
L = bpy.data.objects.new("L", bpy.data.lights.new("L", 'AREA')); L.data.energy = 250; L.data.size = 2; sc.collection.objects.link(L)
L.location = (1.2, -2.5, 2.4); L.rotation_euler = (math.radians(55), 0, math.radians(25))
for o in bpy.data.objects:
    if o.name.endswith("_export") or (o.parent and o.parent.name.endswith("_export")): o.hide_render = True
zt = max((h.matrix_world @ v.co).z for v in h.data.vertices)
for i, (ang, dist, zc, res) in enumerate(((0, 3.6, 0.92, (600, 1000)), (35, 3.6, 0.92, (600, 1000)), (0, 0.75, zt - 0.12, (700, 700)), (40, 0.75, zt - 0.12, (700, 700)))):
    a = math.radians(ang); sc.render.resolution_x, sc.render.resolution_y = res
    cam.location = (dist * math.sin(a), -dist * math.cos(a), zc); cam.rotation_euler = (math.radians(90), 0, a)
    sc.render.filepath = os.path.join(OUT, f"vista_{i}.png"); bpy.ops.render.render(write_still=True)
open(os.path.join(OUT, "registro.txt"), "w").write("\n".join(LOG))
print("ELENA MH OK")
