"""Prepara los GLB de Objaverse para el juego: escala real (por tipo de objeto), origen en la base y centrado,
reduce triángulos y texturas para móvil. Uso: python preparar.py <carpeta_glb> <salida> <max_tris> <max_tex>"""
import bpy, sys, os, glob, json, mathutils
A = [a for a in sys.argv if not a.startswith('--')]
SRC, OUT, MAXT, MAXTEX = A[-4], A[-3], int(A[-2]), int(A[-1])
# altura real aproximada (m) por palabra clave del nombre
ALTO = [("bombilla_casquillo", 0.3), ("bombilla", 0.12), ("aplique_doble", 0.4), ("aplique", 0.38), ("colgante_esmalte", 0.3), ("colgante", 0.4), ("grandfather", 2.1), ("wardrobe", 2.1), ("bookcase", 2.1), ("bookshel", 2.0), ("cabinet", 1.9), ("cupboard", 1.0), ("piano_stool", 0.75), ("stool", 0.7),
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
# medidas exactas de los objetos pequeños nuevos: ("h" altura | "m" dimensión mayor, metros)
EXACTO = {'obj_candlestick': ('h', 0.28), 'obj_kerosene_lamp': ('h', 0.45), 'obj_victorian_brass_oil_lamp': ('h', 1.55), 'obj_candle_holder': ('h', 0.3), 'obj_kerosene_lamp_2': ('h', 0.42), 'obj_candlestick_2': ('h', 0.2), 'obj_miners_oil_lamp': ('h', 0.32), 'obj_old_candelabra': ('h', 0.55), 'obj_kerosene_lamp_3': ('h', 0.4), 'obj_old_oil_lamp': ('h', 0.3), 'obj_ornate_antique_candlestick': ('h', 0.3), 'obj_kerosene_lamp_4': ('h', 0.35), 'obj_old_lantern': ('h', 0.38), 'obj_old_brass_candle_holder': ('h', 0.22), 'obj_oil_lamp': ('h', 0.38), 'obj_kerosene_lamp_5': ('h', 0.36), 'obj_antique_clock': ('h', 0.75), 'obj_wooden_cuckoo_clock': ('h', 0.55), 'obj_pocket_watch': ('m', 0.06), 'obj_mantel_clock': ('h', 0.42), 'obj_gustav_becker_glass_dome_pen': ('h', 0.32), 'obj_pocket_watch_model': ('m', 0.06), 'obj_old_pocket_watch': ('m', 0.06), 'obj_pendulum_clock': ('h', 2.0), 'obj_handmade_porcelain_mantel_cl': ('h', 0.4), 'obj_japan_porcelain_vase': ('h', 0.32), 'obj_floral_vase': ('h', 0.38), 'obj_antique_vase': ('h', 0.45), 'obj_cracked_porcelain_vase': ('h', 0.3), 'obj_greek_flower_vase': ('h', 0.36), 'obj_flower_vase': ('h', 0.28), 'obj_decorative_ceramic_jugs_type': ('m', 0.6), 'obj_antique_vase_s5139506': ('h', 0.3), 'obj_old_soviet_teapot': ('h', 0.22), 'obj_wine_glass': ('h', 0.18), 'obj_medieval_cutlery': ('m', 0.25), 'obj_tea_set_01_4k': ('m', 0.42), 'obj_japanese_teapot': ('h', 0.15), 'obj_teapot': ('h', 0.24), 'obj_antique_silver_goblets_type_': ('h', 0.2), 'obj_cup_and_plate': ('m', 0.16), 'obj_antique_silver_goblets_type__2': ('m', 0.5), 'obj_teapot_weathered_metal_teapo': ('h', 0.26), 'obj_wine_glass_2': ('h', 0.2), 'obj_tea_set': ('m', 0.45), 'obj_teapot_2': ('h', 0.2), 'obj_wooden_plate': ('m', 0.26), 'obj_elegant_victorian_porcelan_t': ('h', 0.24), 'obj_old_map_3d_model': ('m', 0.55), 'obj_old_book': ('m', 0.26), 'obj_scroll': ('m', 0.3), 'obj_quill': ('m', 0.3), 'obj_victorian_typewriter': ('m', 0.4), 'obj_old_book_2': ('m', 0.28), 'obj_hourglass': ('h', 0.24), 'obj_old_book_3': ('m', 0.27), 'obj_old_book_4': ('m', 0.36), 'obj_hourglass_2': ('h', 0.26), 'obj_hour_glass': ('h', 0.22), 'obj_stack_of_old_books': ('m', 0.35), 'obj_seal_and_letter': ('m', 0.25), 'obj_inkwell_from_bell_rock_light': ('h', 0.12), 'obj_fountain_pens': ('m', 0.16), 'obj_letter_box': ('m', 0.35), 'obj_old_books_sketchfab_weekly': ('m', 0.32), 'obj_old_books': ('m', 0.33), 'obj_stamp_envelope': ('m', 0.25), 'obj_envelope': ('m', 0.18), 'obj_museums_old_book_1767': ('m', 0.3), 'obj_scroll_2': ('m', 0.3), 'obj_old_book_5': ('m', 0.25), 'obj_book_stack': ('m', 0.32), 'obj_jewelry_case': ('h', 0.2), 'obj_oriental_perfume_bottle': ('h', 0.16), 'obj_porcelain_perfume_bottle': ('h', 0.13), 'obj_perfume_bottles_with_floral_': ('m', 0.2), 'obj_perfume_bottle': ('h', 0.15), 'obj_jewelry_box': ('h', 0.24), 'obj_old_jewelry_box': ('h', 0.3), 'obj_perfume_bottle_with_a_landsc': ('h', 0.15), 'obj_perfume_bottle_with_floral_d': ('h', 0.16), 'obj_antique_jewelry_box_with_dee': ('m', 0.22), 'obj_music_box': ('m', 0.2), 'obj_jewelry_box_2': ('h', 0.3), 'obj_art_of_chokin_vintage_piano_': ('m', 0.16), 'obj_old_music_box': ('m', 0.22), 'obj_hair_brush_scan': ('m', 0.24), 'obj_samovar': ('h', 0.5), 'obj_classic_coffee_grinder': ('h', 0.3), 'obj_loaf_of_bread_scan': ('m', 0.24), 'obj_jar': ('h', 0.18), 'obj_coffee_grinder_pbr': ('h', 0.3), 'obj_garlic_game_ready_2k_pbr': ('m', 0.06), 'obj_meat_cleaver': ('m', 0.3), 'obj_polished_tea_kettle': ('h', 0.26), 'obj_brocal_quadra_jar': ('h', 0.22), 'obj_thai_jar_c_1000_bce': ('h', 0.35), 'obj_wooden_rolling_pin': ('m', 0.45), 'obj_mason_jars': ('m', 0.25), 'obj_cereal_bread': ('m', 0.3), 'obj_garlic': ('m', 0.06), 'obj_ancient_clay_pots': ('m', 0.4), 'obj_firewood_hp': ('m', 0.9), 'obj_deerhead': ('h', 0.7), 'obj_floor_globe': ('h', 1.0), 'obj_birdcage': ('h', 0.55), 'obj_birdcage_2': ('h', 0.5), 'obj_globe': ('h', 0.45), 'obj_coat_rack': ('h', 1.85), 'obj_dry_firewood': ('m', 0.55), 'obj_antique_globe': ('h', 0.5), 'obj_antique_globe_2': ('h', 0.45), 'obj_armillary_sphere': ('h', 0.45), 'obj_old_violin': ('m', 0.6), 'obj_coat_rack_bowler_hat': ('h', 1.85), 'obj_firewood': ('m', 0.8), 'obj_telescope': ('h', 1.5), 'obj_birdcage_3': ('h', 0.6), 'obj_coat_rack_2': ('h', 1.85), 'obj_note_stand': ('h', 1.2), 'obj_phonograph_v2': ('h', 0.7), 'obj_sheet_music': ('m', 0.32), 'obj_military_telescope': ('m', 0.45), 'obj_harp': ('h', 1.6), 'obj_teddy_bears': ('m', 0.4), 'obj_craft_teddy_bear_photogramme': ('h', 0.32), 'obj_teddy_bear': ('h', 0.3), 'obj_loshadka_rocking_horse_woode': ('m', 0.9), 'obj_wood_spinning_top': ('h', 0.08), 'obj_wooden_toy_train': ('m', 0.35), 'obj_day_31_spinning_top': ('h', 0.07), 'obj_teddy_bear_2': ('h', 0.3), 'obj_wooden_toy_train_2': ('m', 0.4), 'obj_pecking_chicken_wooden_toy': ('m', 0.25), 'obj_skipping_rope_wooden_toy': ('h', 0.3), 'obj_teddy_bear_scan': ('h', 0.3), 'obj_top_hat': ('h', 0.18), 'obj_top_hat_2': ('h', 0.18), 'obj_benjamin_harrison_s_top_hat_': ('h', 0.18), 'obj_1888_harrison_and_morton_top': ('h', 0.18), 'obj_case_for_top_hat_preview': ('h', 0.25), 'obj_shawl_3d_scan': ('h', 1.7), 'obj_wash_basin': ('h', 1.6), 'obj_shawl': ('m', 1.6), 'obj_sack_v2': ('h', 0.7), 'obj_anvil_nature_morte': ('h', 0.85), 'obj_dirty_shovel': ('h', 1.1), 'obj_asset02_medieval_anvil': ('h', 0.8), 'obj_sack_v1': ('h', 0.65), 'obj_round_nosed_shovel': ('h', 1.2), 'obj_pbr_anvil': ('h', 0.35), 'obj_photogrammetry_cloth_sack_wi': ('h', 0.6), 'obj_shovel': ('h', 1.1), 'obj_pickaxe': ('h', 0.9), 'obj_anvil': ('h', 0.35), 'obj_old_pickaxe': ('m', 0.9), 'obj_anvil_water_bucket_and_water': ('m', 1.2), 'obj_old_shovel': ('m', 1.0), 'obj_grain_scoop': ('m', 0.35), 'obj_log_workbench_asset': ('h', 0.75), 'obj_picture_frame': ('m', 0.3), 'obj_old_bible': ('m', 0.28), 'obj_empty_cross': ('h', 0.6), 'obj_fancy_picture_frame_01_freep': ('h', 0.5), 'obj_withered_wooden_crucifix': ('h', 0.55), 'obj_oil_painting_of_peaches_prev': ('h', 0.6), 'obj_ornate_picture_frame': ('h', 0.7), 'obj_eagle_oil_painting_by_markus': ('h', 0.8), 'obj_fancy_picture_frame_02_freep': ('h', 0.55), 'obj_candle_wall_lamp': ('h', 0.35), 'obj_bible_on_stand': ('h', 1.15), 'obj_sir_isaac_newton_portrait_pa': ('h', 0.9), 'obj_hanging_picture_frame_freepo': ('h', 0.6), 'obj_unending_torment': ('h', 0.7), 'obj_biblical_scene_from_nurember': ('h', 0.6), 'obj_square_picture_frame_white': ('h', 0.7)}
EXACTO.update({'ropa_1830s_frock_coat_unbuttoned': ('h', 1.2), 'ropa_dress_of_a_poor_woman_victor': ('h', 1.45), 'ropa_robe': ('h', 1.4), 'ropa_black_dress': ('h', 1.4), 'ropa_dress': ('h', 1.3), 'ropa_mannequin_1900s_m_size': ('h', 1.6), 'ropa_dress_plain2': ('h', 1.3), 'ropa_wedding_dress': ('h', 1.65), 'ropa_1900_dress_form': ('h', 1.6), 'ropa_mannequin_armor_dummy_mediev': ('h', 1.7), 'ropa_victorian_vampire': ('h', 1.3), 'ropa_cape': ('h', 1.3), 'ropa_heavy_worn_jacket': ('h', 0.8), 'ropa_a_fashionable_waistcoat': ('h', 0.8), 'ropa_bowler_hat': ('h', 0.13), 'ropa_coraline_riding_boot': ('h', 0.5), 'ropa_worn_vagabond_women_leather_': ('h', 0.3), 'ropa_shoes': ('m', 0.28), 'ropa_old_oxford_shoe': ('m', 0.28), 'ropa_photoscanned_female_ankle_bo': ('h', 0.2), 'ropa_kirza_boots': ('h', 0.42), 'ropa_dress_shoe_left': ('m', 0.28), 'ropa_worn_rieker_women_leather_sh': ('h', 0.25), 'ropa_old_shoes': ('m', 0.3), 'ropa_party_shoe_for_girls': ('m', 0.18), 'ropa_boots': ('h', 0.42), 'ropa_old_dirty_boots': ('h', 0.4), 'ropa_folded_newspaper': ('m', 0.38), 'ropa_towel': ('m', 0.6), 'ropa_towel_rail': ('m', 0.6), 'ropa_apron': ('h', 0.9), 'ropa_sunday_hat': ('m', 0.42), 'ropa_wood_clothes_hanger': ('m', 0.43), 'ropa_leather_belt': ('m', 0.45), 'ropa_elegant_umbrella': ('h', 0.9), 'ropa_leather_bag': ('h', 0.25), 'ropa_umbrella': ('m', 1.0), 'ropa_leather_gloves': ('m', 0.26), 'ropa_worn_leather_glove': ('m', 0.24), 'ropa_purse': ('h', 0.3), 'ropa_long_white_cotton_socks': ('h', 0.7), 'ropa_ladies_handbag_vol_1': ('h', 0.35), 'ropa_sewing_machine': ('m', 0.45), 'ropa_couch_pillow': ('m', 0.45), 'ropa_frosted_sheets': ('m', 0.8), 'ropa_ribbon_ball': ('m', 0.12), 'ropa_cresent_witch_clothes': ('h', 1.4), 'ropa_gray_sweater': ('h', 0.7), 'ropa_gas_lamp': ('h', 0.45), 'ropa_simple_paper_clip': ('m', 0.08), 'ropa_hanger': ('h', 1.8), 'ropa_wood_cloths_hangers_30x4x3': ('m', 0.6), 'ropa_hanger_pile': ('m', 0.45), 'ropa_wooden_tool_hanger': ('m', 1.0)})
EXACTO.update({'ave_common_barn_owl': ('h', 0.55), 'ave_snowy_owl': ('h', 0.6), 'ave_my_grandfather_s_owl': ('h', 0.62), 'ave_eastern_screech_owl': ('h', 0.36), 'ave_great_horned_owl': ('h', 0.7), 'ave_owl_download': ('h', 0.5), 'ave_moth_number_1': ('m', 0.12), 'ave_townsend_bat': ('m', 0.32), 'ave_owl': ('m', 1.0)})
EXACTO.update({'fuente_huntington': ('m', 7.0), 'fuente_vieja': ('m', 7.0), 'fuente_festoneada': ('m', 6.5)})
EXACTO.update({'veg_3d_fern_01': ('h', 0.7), 'veg_boletus_edulis_mushroom': ('h', 0.14), 'veg_cattail': ('h', 1.6), 'veg_cattail_plant': ('h', 1.5), 'veg_chanterelle': ('h', 0.08), 'veg_ivy_patch': ('m', 0.8), 'veg_mushroom': ('m', 0.5), 'veg_mushroom_on_tree_baked_l': ('m', 0.8), 'veg_mushroom_scan': ('m', 0.35), 'veg_oyster_mushrooms': ('m', 0.35), 'veg_shaggy_parasol_mushroom_': ('m', 0.5), 'veg_tricholoma_murrillianum_': ('h', 0.1), 'veg_weeds_and_grass': ('m', 1.5)})
EXACTO.update({'pomo_simple': ('m', 0.075), 'pomo_laton': ('m', 0.075), 'picaporte_laton': ('m', 0.13), 'bocallave_hierro': ('m', 0.1), 'bocallave_laton': ('m', 0.085), 'candado_viejo': ('m', 0.1), 'llave_antigua': ('m', 0.11)})
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
    ex = EXACTO.get(name)
    if ex:
        s = ex[1] / (h if ex[0] == "h" else max(mx.x - mn.x, mx.y - mn.y, h))
    elif md:
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
