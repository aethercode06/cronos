class_name ZarekDecorado
extends RefCounted
## Viste cada sala de la mansión Varela (1874) con objetos de época de Objaverse (CC-BY/CC0, créditos en
## zarek/objetos/creditos.json) y Poly Haven (CC0): muebles contra las paredes, objetos cotidianos encima de
## mesas y estanterías, cosas por el suelo y telarañas en las esquinas. Todo con semilla fija.

var m: ZarekMansion
var rng := RandomNumberGenerator.new()
var _ocupado: Array[Rect2] = []
var _superficies: Array = []
var _altos: Array[Rect2] = []
var _en_pared: Array[Vector3] = []

## ¿Hay sitio en la pared? (sin otro cuadro, aplique o estante a menos de «hueco» metros)
func _pared_libre(p: Vector3, hueco: float) -> bool:
	for q in _en_pared:
		if absf(q.y - p.y) < 1.5 and Vector2(q.x - p.x, q.z - p.z).length() < hueco:
			return false
	return true

## Muebles con tapa donde se pueden dejar cosas y la altura de su tapa (m, sin escalar).
const SUPERFICIE := {"ClassicConsole_01": 0.949, "GothicCommode_01": 1.212, "vict_antique_desk": 0.8, "vict_antique_wooden_desk": 0.8, "WoodenTable_03": 0.83,
	"painted_wooden_table": 0.959, "wooden_table_02": 0.8, "side_table_01": 0.551, "side_table_tall_01": 0.761, "small_wooden_table_01": 0.533,
	"ClassicNightstand_01": 0.7, "painted_wooden_nightstand": 0.616, "vintage_wooden_drawer_01": 1.091, "painted_wooden_cabinet": 1.182,
	"GothicCabinet_01": 2.362, "vintage_cabinet_01": 2.236, "vict_victorian_coffee_table": 0.5, "coffee_table_round_01": 0.491, "gothic_coffee_table": 0.558,
	"round_wooden_table_01": 1.005, "treasure_chest": 0.62, "wine_barrel_01": 0.871, "terr_old_and_dusty_multi_crate_st": 0.66, "vict_antique_wooden_bookcase___ga": 2.1,
	"vict_small_antique_table_asset": 0.376, "painted_wooden_cabinet_02": 1.02, "vintage_suitcase": 0.569}



## Lo ocupado va por plantas: un mueble de la planta baja no impide poner otro encima, en el primer piso.
var _ocupado_nivel := {}
func _init(mansion: ZarekMansion) -> void:
	m = mansion
	rng.seed = 1874
	for nv in [-1, 0, 1, 2]:
		var lista: Array[Rect2] = []
		_ocupado_nivel[nv] = lista
	for st in m.stairs_spec:
		var a := m.cell_to_world(st.key, st.r[0], st.r[1])
		var b := m.cell_to_world(st.key, st.r[2], st.r[3])
		var rr := Rect2(a.x + 0.05, a.z - 1.4, b.x - a.x - 0.1, b.z - a.z + 2.8)
		for nv in [int(st.from), int(st.to)]:
			(_ocupado_nivel[nv] as Array).append(rr)
	for c in ZarekMansion.CARACOLES:
		var p := m.cell_to_world(c[0], c[1], c[2])
		for nv in [int(m.plan[c[0]].nivel), int(m.plan[c[3]].nivel)]:
			(_ocupado_nivel[nv] as Array).append(Rect2(p.x - 1.9, p.z - 1.9, 3.8, 3.8))

func _nivel_de(r: Dictionary) -> void:
	var nv := int(r.level)
	if not _ocupado_nivel.has(nv):
		var lista: Array[Rect2] = []
		_ocupado_nivel[nv] = lista
	_ocupado = _ocupado_nivel[nv]

const O := "objetos/"
# ---- catálogos por tipo de sala: [pared], [centro], [encima], [suelo] ----
const SALA := {
	"vestibulo": {"pared": ["vict_grandfather_clock", "ClassicConsole_01", "vict_dusty_antique_mirror__free", "painted_wooden_bench", "t_angel_reza", "obj_coat_rack_bowler_hat", "GothicCommode_01", "vict_victorian_lounge_sofa"], "centro": [], "techo": ["pian_medieval_chandelier"], "encima": ["pian_candelabra", "coti_three_candles_and_a_golden_c", "obj_flower_vase", "obj_letter_box", "obj_antique_vase"], "suelo": []},
	"salon": {"pared": ["pian_victorian_fire_place___fre", "pian_dusty_old_piano", "vict_antique_wooden_bookcase__", "vict_grandfather_clock", "vict_antique_wardrobe"], "centro": ["vict_victorian_lounge_sofa", "vict_victorian_two_seat_sofa", "vict_victorian_armchair", "vict_victorian_coffee_table", "vict_antique_chair"], "techo": ["pian_chandelier"], "encima": ["coci_old_teapot", "vict_cup___saucer", "coti_three_candles_and_a_golde", "coti_pocket_watch", "vict_torsion_pendulum_clock___ani"], "suelo": ["coti_simple_bookstack", "coti_shabby_books"]},
	"musica": {"pared": ["pian_old_piano", "pian_dusty_piano", "pian_candelabra"], "centro": ["pian_old_wooden_grand_piano", "pian_piano_chair__free_downloa", "vict_victorian_armchair"], "techo": ["pian_medieval_chandelier"], "encima": ["coti_three_candles_and_a_golde"]},
	"baile": {"pared": ["pian_candelabra", "pian_medieval_candelabra__free", "vict_victorian_lounge_sofa", "pian_grandfather_clock"], "centro": ["pian_old_wooden_grand_piano"], "techo": ["pian_medieval_chandelier", "pian_medieval_chandelier"]},
	"comedor": {"pared": ["vict_antique_wardrobe__free", "pian_victorian_fire_place___fre", "pian_candelabra"], "centro": ["vict_table_and_chairs"], "techo": ["pian_chandelier"], "encima": ["coci_samovar", "coci_old_teapot", "vict_cup___saucer", "coti_wine_bottle", "coti_three_candles_and_a_golde", "coti_bread_in_basket"]},
	"cocina": {"pared": ["coci_old_kitchen_cabinets", "coci_old_gas_stove_and_oven", "coci_vintage_wooden_cabinets", "coci_hanging_kitchen_cupboards", "bano_washbasin"], "centro": ["vict_table"], "encima": ["coci_vintage_kettle", "coci_teapot_old_2_100517", "coci_basic_bowl", "coci_wooden_cutting_board", "s_olla_vieja", "s_cazo_cobre", "coci_sliced_bread", "coci_old_spoon", "coti_glass_bottle", "coti_basic_bottle", "coci_pantry_shelf"]},
	"servicio": {"pared": ["coci_old_kitchen_shelf", "terr_old_and_dusty_multi_crat", "bano_washbasin", "vict_antique_wardrobe", "coci_vintage_wooden_cabinets"], "centro": ["vict_table", "vict_antique_chair"], "encima": ["coti_three_candles_and_a_golde", "coti_glass_bottle", "coci_basic_bowl", "coti_bread_in_basket", "coti_shabby_books"], "suelo": ["vintage_suitcase", "terr_old_and_dusty_multi_crat"]},
	"despensa": {"pared": ["coci_old_kitchen_shelf", "coci_vintage_wooden_cabinets", "terr_old_and_dusty_multi_crat"], "encima": ["coti_glass_bottle", "coti_small_bottle", "coti_wine_bottle", "coci_basic_bowl", "coci_pantry_shelf"], "suelo": ["terr_old_and_dusty_multi_crat"]},
	"biblioteca": {"pared": ["vict_antique_wooden_bookcase__", "terr_dusty_bookshelfs", "coti_chocolate_beech_bookshel", "vict_antique_wooden_bookcase__"], "centro": ["vict_antique_wooden_desk", "vict_antique_chair", "coti_celestial_globe", "vict_victorian_armchair"], "techo": ["pian_chandelier"], "encima": ["coti_occult_books", "vict_old_books___free_download", "coti_three_candles_and_a_golde", "coti_celestial_globe", "vict_key"], "suelo": ["coti_12_old_books", "coti_simple_bookstack"]},
	"estudio": {"pared": ["s_secreter", "vict_antique_wooden_bookcase__", "vict_grandfather_clock"], "centro": ["vict_antique_desk", "vict_antique_chair"], "encima": ["coti_typewriter", "coti_pocket_watch", "coti_joachim_liebermann_s_pock", "vict_old_books___free_download", "coti_three_candles_and_a_golde"], "suelo": ["coti_shabby_books"]},
	"billar": {"pared": ["vict_antique_wooden_bookcase__", "pian_victorian_fire_place___fre"], "centro": ["vict_victorian_armchair", "vict_antique_chair"], "encima": ["coti_wine_bottle", "coti_glass_bottle"]},
	"dormitorio": {"pared": ["vict_antique_wardrobe", "vict_dusty_antique_mirror___fre", "vict_antique_desk", "s_comoda", "s_tocador"], "centro": ["vict_antique_chair"], "encima": ["coti_three_candles_and_a_golde", "vict_old_books___free_download", "coti_pocket_watch", "vict_cup___saucer"], "suelo": ["vintage_suitcase", "s_orinal"]},
	"tocador": {"pared": ["vict_dusty_antique_mirror___fre", "vict_antique_wardrobe__free", "vict_ornate_mirror"], "centro": ["vict_antique_chair", "vict_victorian_armchair"], "encima": ["coti_small_bottle", "coti_glass_bottle", "coti_pocket_watch"]},
	"ninos": {"pared": ["jugu_dollhouse", "vict_antique_wardrobe"], "centro": ["jugu_rocking_horse", "vict_antique_chair"], "encima": ["jugu_music_box_prop", "vict_old_books___free_download"], "suelo": ["jugu_rocking_horse", "coti_shabby_books"]},
	"costura": {"pared": ["vict_singer_15___old_sewing_ma", "coti_willoughsby_sewing_machin", "vict_antique_wardrobe__free"], "centro": ["vict_antique_chair", "vict_table"], "encima": ["coti_three_candles_and_a_golde", "coti_bread_in_basket"]},
	"bano": {"primero": ["s_inodoro"], "pared": ["bano_washbasin_model", "vict_ornate_mirror", "s_aguamanil"], "encima": ["coti_small_bottle", "coti_glass_bottle", "s_toallas"], "suelo": ["s_cesto_ropa"]},
	# --- salas del plano de medidas reales: cada una con lo que tendría de verdad ---
	"aseo": {"primero": ["s_inodoro", "s_aguamanil"], "pared": ["vict_ornate_mirror", "painted_wooden_shelves"], "encima": ["coti_small_bottle", "jug_01", "coti_glass_bottle", "s_toallas"], "suelo": ["s_orinal", "wooden_bucket_01"]},
	"vestidor": {"primero": ["vict_antique_wardrobe", "s_armario_alto"], "pared": ["s_tocador", "s_comoda", "GothicCommode_01", "s_biombo", "obj_coat_rack"], "centro": ["ropa_1900_dress_form"], "encima": ["obj_jewelry_box_2", "obj_perfume_bottle", "ropa_sunday_hat", "ropa_bowler_hat", "obj_oriental_perfume_bottle"], "suelo": ["ropa_old_shoes", "ropa_boots", "s_baul_viaje", "s_maleta_vieja"]},
	"ropero": {"primero": ["obj_coat_rack_bowler_hat", "s_paraguero"], "colgado": ["ropa_wood_cloths_hangers_30x4x3"], "pared": ["vict_antique_wardrobe", "painted_wooden_shelves", "obj_coat_rack_2"], "encima": ["ropa_bowler_hat", "ropa_worn_leather_glove", "ropa_leather_gloves"], "suelo": ["ropa_old_dirty_boots", "s_maleta_vieja"]},
	"lamparas": {"primero": ["WoodenTable_03"], "pared": ["painted_wooden_shelves", "wooden_display_shelves_01", "coci_old_kitchen_shelf"], "encima": ["obj_kerosene_lamp", "obj_kerosene_lamp_2", "obj_old_lantern", "wooden_lantern_01", "Lantern_01", "obj_miners_oil_lamp", "obj_oil_lamp", "metal_jug"], "suelo": ["wooden_bucket_02", "obj_dry_firewood"]},
	"mayordomo": {"primero": ["s_escritorio"], "pared": ["s_secreter", "wooden_display_shelves_01", "wall_clock"], "centro": ["vict_antique_chair"], "encima": ["obj_victorian_typewriter", "obj_inkwell_from_bell_rock_light", "obj_quill", "obj_seal_and_letter", "obj_old_book_2", "vict_key", "obj_pocket_watch"], "suelo": ["coti_shabby_books"]},
	"armas": {"primero": ["GothicCabinet_01"], "pared": ["s_comoda2", "wooden_display_shelves_01"], "centro": ["WoodenTable_02"], "colgado": ["s_mosquete", "s_mosquete2", "s_cabeza_ciervo", "obj_deerhead"], "encima": ["obj_old_map_3d_model", "obj_military_telescope", "obj_hour_glass", "hatchet", "obj_candlestick"], "suelo": ["wooden_crate_01", "obj_dry_firewood"]},
	"fregadero": {"primero": ["s_fregadero_piedra"], "pared": ["coci_old_kitchen_shelf", "painted_wooden_cabinet", "coci_vintage_wooden_cabinets"], "centro": ["WoodenTable_01"], "encima": ["coci_basic_bowl", "obj_wooden_plate", "metal_jug", "s_olla_vieja", "s_cazo_cobre", "coci_old_spoon", "obj_jar"], "suelo": ["wooden_bucket_01", "s_cestos", "wooden_broom"]},
	"carne": {"primero": ["WoodenTable_03"], "pared": ["coci_old_kitchen_shelf", "wooden_barrels_01"], "encima": ["s_jamon", "x_carne_meat", "x_carne_cote_de_boeuf", "obj_meat_cleaver", "x_carnicero_knife_collection", "obj_jar"], "suelo": ["wooden_bucket_02", "wine_barrel_01"]},
	"trofeos": {"primero": ["GothicCabinet_01"], "pared": ["painted_wooden_shelves", "wooden_display_shelves_01"], "colgado": ["s_craneo_ciervo", "s_cabeza_ciervo"], "encima": ["x_huesos_human_skull", "x_restos_formaldehyde_jar_asset_p", "ropa_ladies_handbag_vol_1", "ropa_leather_belt", "obj_pocket_watch", "round_spectacles", "x_huesos_skeleton_hand"], "suelo": ["vintage_suitcase", "ropa_leather_bag", "obj_sack_v1", "ropa_boots", "ropa_old_shoes", "ropa_party_shoe_for_girls"]},
	"criados": {"pared": ["painted_wooden_nightstand", "vict_antique_wardrobe", "s_comoda2", "s_aguamanil", "s_estufa"], "centro": ["painted_wooden_chair_02"], "encima": ["obj_candlestick", "jug_01", "obj_old_bible", "round_spectacles"], "suelo": ["s_baul_viaje", "ropa_old_shoes", "s_orinal"]},
	"ropa_blanca": {"primero": ["painted_wooden_shelves"], "pared": ["painted_wooden_shelves", "vict_antique_wardrobe", "painted_wooden_cabinet_02"], "encima": ["ropa_towel", "ropa_frosted_sheets", "s_toallas"], "suelo": ["s_cesto_ropa", "wicker_basket_02"]},
	"plancha2": {"primero": ["painted_wooden_table"], "pared": ["painted_wooden_shelves", "pian_small_stove"], "encima": ["ropa_towel", "ropa_frosted_sheets", "s_toallas"], "suelo": ["s_cesto_ropa", "wooden_bucket_02"]},
	"bajada": {"pared": ["wooden_barrels_01", "coci_old_kitchen_shelf", "terr_old_and_dusty_multi_crate_st"], "encima": ["obj_kerosene_lamp", "obj_jar", "coti_glass_bottle"], "suelo": ["obj_sack_v2", "wooden_crate_02", "obj_dry_firewood"]},
	"antecomedor": {"primero": ["coci_vintage_wooden_cabinets"], "colgado": ["obj_ornate_picture_frame", "obj_wooden_cuckoo_clock"], "pared": ["painted_wooden_cabinet_02", "ClassicConsole_01"], "encima": ["tea_set_01", "obj_elegant_victorian_porcelan_t", "brass_goblets", "obj_antique_silver_goblets_type__2", "carved_wooden_plate"], "suelo": []},
	"recibidor": {"primero": ["vict_grandfather_clock"], "pared": ["ClassicConsole_01", "obj_coat_rack_bowler_hat", "vict_victorian_lounge_sofa", "s_paraguero"], "techo": ["pian_medieval_chandelier"], "encima": ["obj_letter_box", "obj_flower_vase", "pian_candelabra", "postcard_set_01"], "suelo": []},
	"deposito": {"primero": ["s_deposito"], "pared": ["wooden_barrels_01", "terr_old_and_dusty_multi_crate_st"], "suelo": ["wooden_bucket_01", "wooden_bucket_02", "watering_can_metal_01"]},
	"palomar": {"pared": ["wooden_crate_02", "terr_old_and_dusty_multi_crate_st"], "suelo": ["obj_sack_v1", "obj_grain_scoop", "obj_birdcage_3", "s_paloma", "s_paloma", "s_pajaro_muerto"]},
	"pasillo": {"pared": ["ClassicConsole_01", "vict_victorian_lounge_sofa", "pian_candelabra", "vict_grandfather_clock"], "encima": ["coti_three_candles_and_a_golde", "vict_torsion_pendulum_clock___ani"]},
	"atico": {"pared": ["terr_old_and_dusty_multi_crat", "vict_antique_wardrobe", "pian_dusty_old_piano", "s_armario_alto"], "centro": ["treasure_chest", "s_baul_viaje", "vintage_suitcase", "terr_creepy_lady_bust_statue_s", "terr_old_and_dusty_multi_crat"], "suelo": ["coti_12_old_books", "coti_shabby_books"]},
	"sotano": {"pared": ["terr_old_and_dusty_multi_crat", "coci_old_kitchen_shelf"], "centro": ["terr_old_and_dusty_multi_crat"], "suelo": ["coti_wine_bottle", "coti_glass_bottle"]},
	"cava": {"pared": ["coci_old_kitchen_shelf"], "centro": ["terr_old_and_dusty_multi_crat"], "suelo": ["coti_wine_bottle", "coti_wine_bottle"]},
	"calderas": {"pared": ["pian_old_stove", "pian_small_stove", "terr_old_and_dusty_multi_crat"], "centro": ["terr_old_and_dusty_multi_crat"]},
	"archivo": {"pared": ["coti_chocolate_beech_bookshel", "terr_dusty_bookshelfs", "s_comoda2"], "centro": ["vict_antique_desk"], "encima": ["coti_typewriter", "coti_shabby_books"], "suelo": ["coti_12_old_books", "coti_simple_bookstack"]},
}

var _nombres: Dictionary = {}
## Los nombres del catálogo pueden ir recortados: se busca el archivo cuyo nombre empiece igual (sin signos).
func _real(nombre: String) -> String:
	if _nombres.is_empty():
		m._load_props_info()
		for k in m._props_info.keys():
			_nombres[_norm(k)] = k
	var n := _norm(nombre)
	if _nombres.has(n):
		return _nombres[n]
	for k in _nombres:
		if String(k).begins_with(n) or n.begins_with(String(k)):
			return _nombres[k]
	return nombre

static func _norm(s: String) -> String:
	var o := ""
	for ch in s.to_lower():
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
			o += ch
	return o

## Medidas que tenían las salas antes de rehacer el plano con tamaños reales. Los montajes hechos a mano se
## escribieron para esas medidas: lo pegado a una pared sigue pegado a la misma pared y lo del medio se reparte
## en proporción (ver `_ajustar`); lo que ya no cabe, `_en` no lo pone.
const TAM_ANTES := {"Pasillo principal": Vector2(43.2, 2.4), "Biblioteca": Vector2(9.6, 9.6), "Estudio del padre": Vector2(4.8, 9.6), "Salón de baile": Vector2(14.4, 9.6), "Sala de fumar y billar": Vector2(7.2, 9.6), "Cuarto de servicio": Vector2(7.2, 9.6), "Salón con chimenea": Vector2(12.0, 9.6), "Sala de las mañanas": Vector2(4.8, 9.6), "Sala de música": Vector2(9.6, 7.2), "Vestíbulo y gran escalera": Vector2(9.6, 16.8), "Comedor formal": Vector2(9.6, 9.6), "Guardarropa": Vector2(4.8, 7.2), "Antecocina": Vector2(4.8, 7.2), "Despensa": Vector2(7.2, 7.2), "Pasillo": Vector2(43.2, 2.4), "Dormitorio de los padres": Vector2(9.6, 9.6), "Tocador de la madre": Vector2(4.8, 9.6), "Cuarto de Damián": Vector2(9.6, 9.6), "Cuarto del hermano": Vector2(7.2, 9.6), "Baño": Vector2(4.8, 9.6), "Cuarto de huéspedes azul": Vector2(7.2, 9.6), "Sala de costura": Vector2(9.6, 9.6), "Cuarto de la institutriz": Vector2(9.6, 7.2), "Galería de retratos": Vector2(9.6, 12.0), "Cuarto de huéspedes": Vector2(9.6, 9.6), "Escalera de servicio": Vector2(7.2, 9.6), "Cuarto de lectura": Vector2(9.6, 7.2), "Cuarto de plancha": Vector2(7.2, 7.2), "Ático (vigas, baúles, muñecos tapados)": Vector2(36.0, 24.0)}
var _sin_ajuste := false
var DBG_CAMA := OS.get_environment("DBG_CAMA") != ""
var DBG_SALA := OS.get_environment("DBG_SALA")
func _ajustar(r: Dictionary, x: float, z: float) -> Vector2:
	if _sin_ajuste:
		return Vector2(x, z)
	var antes: Vector2 = TAM_ANTES.get(String(r.name), Vector2.ZERO)
	var ahora: Vector2 = (r.rect as Rect2).size
	if antes == Vector2.ZERO or antes.is_equal_approx(ahora):
		return Vector2(x, z)
	return Vector2(_eje(x, antes.x, ahora.x), _eje(z, antes.y, ahora.y))

func _eje(v: float, antes: float, ahora: float) -> float:
	if ahora < 3.6 or antes < 3.6:
		return v / maxf(0.01, antes) * ahora
	if v < 1.6:
		return v
	if antes - v < 1.6:
		return ahora - (antes - v)
	return 1.6 + (v - 1.6) / maxf(0.01, antes - 3.2) * maxf(0.0, ahora - 3.2)

func _tipo(r: Dictionary) -> String:
	var n: String = String(r.name).to_lower()
	for k in [["dormitorio de los criados", "criados"], ["mozo", "criados"], ["criada vieja", "criados"], ["cocinera", "criados"],
			["habitación del mayordomo", "criados"], ["cuarto de las criadas", "criados"], ["cuarto de la doncella", "criados"],
			["aseo", "aseo"], ["vestidor", "vestidor"], ["ropero", "ropero"], ["guardarropa", "ropero"], ["antecocina", "antecomedor"], ["maletas", "ropero"], ["limpieza", "ropero"],
			["armario de servicio", "ropa_blanca"], ["ropa blanca", "ropa_blanca"], ["lámparas", "lamparas"],
			["despacho del mayordomo", "mayordomo"], ["sala de armas", "armas"], ["fregadero", "fregadero"], ["carne", "carne"],
			["trofeos", "trofeos"], ["bajada", "bajada"], ["antecomedor", "antecomedor"], ["recibidor", "recibidor"],
			["depósito", "deposito"], ["palomar", "palomar"], ["vestidor", "tocador"], ["ropa blanca", "costura"], ["recibidor", "vestibulo"], ["galería del vestíbulo", "recibidor"],
			["sala de armas", "estudio"], ["despacho del mayordomo", "estudio"], ["salita", "salon"], ["antecomedor", "despensa"], ["fregadero", "cocina"],
			["carne", "despensa"], ["lámparas", "servicio"], ["ropero", "servicio"], ["maletas", "servicio"], ["limpieza", "servicio"],
			["armario de servicio", "servicio"], ["bajada", "servicio"], ["trofeos", "servicio"],
			["vestíbulo", "vestibulo"], ["chimenea", "salon"], ["mañanas", "salon"], ["música", "musica"], ["baile", "baile"], ["comedor", "comedor"],
			["antecocina", "despensa"], ["cocina", "cocina"], ["despensa", "despensa"], ["biblioteca", "biblioteca"], ["lectura", "biblioteca"],
			["estudio", "estudio"], ["billar", "billar"], ["tocador", "tocador"], ["niños", "ninos"], ["costura", "costura"], ["plancha", "costura"],
			["baño", "bano"], ["ático", "atico"], ["rincón", "atico"], ["cava", "cava"], ["calderas", "calderas"], ["archivo", "archivo"],
			["galería de retratos", "pasillo"], ["pasillo", "pasillo"], ["guardarropa", "dormitorio"], ["galería de servicio", "sotano"], ["cuarto de servicio", "servicio"], ["escalera de servicio", "servicio"]]:
		if k[0] in n:
			return k[1]
	if int(r.level) == 2 and String(r.type) == "servicio":
		return "atico"
	match String(r.type):
		"dormitorio": return "dormitorio"
		"sotano": return "sotano"
		"pasillo": return "pasillo"
		"sala": return "salon"
		"servicio": return "servicio"
	return ""

func _libre(c: Vector3, t: Vector3, rect: Rect2) -> bool:
	var a := Rect2(c.x - t.x * 0.5 - 0.15, c.z - t.z * 0.5 - 0.15, t.x + 0.3, t.z + 0.3)
	# la huella real tiene que caber en la sala (lo pegado a la pared llega hasta su cara interior)
	if not rect.grow(0.02).encloses(Rect2(c.x - t.x * 0.5, c.z - t.z * 0.5, t.x, t.z)):
		return false
	for o in _ocupado:
		if o.intersects(a):
			return false
	var rad := maxf(t.x, t.z) * 0.5
	if not m.door_near(c, rad + 1.1).is_empty() or not m.portal_near(c, rad + 1.2).is_empty() or not m.wardrobe_near(c, rad + 0.8).is_empty():
		return false
	return true

var _n_puestos := 0
func _ocupar(c: Vector3, t: Vector3) -> void:
	_n_puestos += 1
	_ocupado.append(Rect2(c.x - t.x * 0.5, c.z - t.z * 0.5, t.x, t.z).abs())

## Pone un objeto contra una pared libre mirando hacia dentro de la sala. Devuelve [nodo, posición, tamaño].
func _contra_pared(nombre: String, r: Dictionary) -> Array:
	nombre = _real(nombre)
	var rect: Rect2 = r.rect
	var tam := m._prop_size(nombre)
	for intento in 48:
		var lado := rng.randi_range(0, 3)
		var p: Vector3
		var yaw := 0.0
		var ext := Vector3(tam.x, tam.y, tam.z)
		var f := _caras(r)
		match lado:
			0:
				p = Vector3(rng.randf_range(rect.position.x + f[0] + tam.x * 0.6, rect.end.x - f[1] - tam.x * 0.6), r.y, rect.position.y + f[2] + tam.z * 0.5 + 0.03); yaw = 0.0
			1:
				p = Vector3(rng.randf_range(rect.position.x + f[0] + tam.x * 0.6, rect.end.x - f[1] - tam.x * 0.6), r.y, rect.end.y - f[3] - tam.z * 0.5 - 0.03); yaw = PI
			2:
				p = Vector3(rect.position.x + f[0] + tam.z * 0.5 + 0.03, r.y, rng.randf_range(rect.position.y + f[2] + tam.x * 0.6, rect.end.y - f[3] - tam.x * 0.6)); yaw = PI * 0.5; ext = Vector3(tam.z, tam.y, tam.x)
			_:
				p = Vector3(rect.end.x - f[1] - tam.z * 0.5 - 0.03, r.y, rng.randf_range(rect.position.y + f[2] + tam.x * 0.6, rect.end.y - f[3] - tam.x * 0.6)); yaw = -PI * 0.5; ext = Vector3(tam.z, tam.y, tam.x)
		if t_alto_ventana(r, p, ext):
			continue
		if _libre(p, ext, rect):
			_ocupar(p, ext)
			return [m._prop(nombre, p, yaw), p, ext]
	return [null, Vector3.ZERO, Vector3.ZERO]

## Un mueble alto pegado a la pared no puede tapar una ventana.
func t_alto_ventana(r: Dictionary, p: Vector3, ext: Vector3) -> bool:
	return ext.y > 1.3 and m.ventana_cerca(p, maxf(ext.x, ext.z) * 0.5 + 0.4)

func _en_el_centro(nombre: String, r: Dictionary) -> Array:
	nombre = _real(nombre)
	var rect: Rect2 = r.rect
	var tam := m._prop_size(nombre)
	for intento in 24:
		var p := Vector3(rng.randf_range(rect.position.x + 1.2, rect.end.x - 1.2), r.y, rng.randf_range(rect.position.y + 1.2, rect.end.y - 1.2))
		var yaw: float = rng.randf_range(-0.4, 0.4) + [0.0, PI * 0.5, PI, -PI * 0.5][rng.randi_range(0, 3)]
		var ext := tam if absf(sin(yaw)) < 0.7 else Vector3(tam.z, tam.y, tam.x)
		if _libre(p, ext, rect):
			_ocupar(p, ext)
			return [m._prop(nombre, p, yaw), p, ext]
	return [null, Vector3.ZERO, Vector3.ZERO]

## Pone objetos pequeños encima de un mueble (mesa, consola, cómoda, escritorio).
func _encima(base: Array, lista: Array, n: int) -> void:
	if base[0] == null or lista.is_empty():
		return
	var p: Vector3 = base[1]
	var t: Vector3 = base[2]
	if t.y > 1.3 or t.y < 0.35:
		return
	for k in n:
		var nombre: String = _real(lista[rng.randi_range(0, lista.size() - 1)])
		var q := p + Vector3(rng.randf_range(-t.x * 0.32, t.x * 0.32), t.y, rng.randf_range(-t.z * 0.28, t.z * 0.28))
		m._prop(nombre, q, rng.randf() * TAU, 1.0, false)

## Deja libre un paso de 1,5 m desde cada puerta de la sala hasta su centro (para jugador y Elena).
func _reservar_pasos(r: Dictionary) -> void:
	# delante de cada puerta de la sala queda libre un rellano de 1,3 × 1,4 m (hacia dentro); en las salas
	# grandes, además, un paso hasta el centro
	var rect: Rect2 = r.rect
	var cen := rect.get_center()
	var grande := rect.size.x > 8.0 and rect.size.y > 8.0
	for d in m.doors:
		var dp: Vector3 = d.pos
		if absf(dp.y - float(r.y)) > 1.0 or not rect.grow(0.3).has_point(Vector2(dp.x, dp.z)):
			continue
		var a := Vector2(dp.x, dp.z)
		var dentro := (cen - a)
		if absf(dentro.x) > absf(dentro.y):
			dentro = Vector2(signf(dentro.x), 0)
		else:
			dentro = Vector2(0, signf(dentro.y))
		var fin := a + dentro * 1.1
		var mn := Vector2(minf(a.x, fin.x), minf(a.y, fin.y))
		var mx := Vector2(maxf(a.x, fin.x), maxf(a.y, fin.y))
		_ocupado.append(Rect2(mn, mx - mn).grow(0.55).intersection(rect))
		if grande:
			mn = Vector2(minf(a.x, cen.x), minf(a.y, cen.y))
			mx = Vector2(maxf(a.x, cen.x), maxf(a.y, cen.y))
			_ocupado.append(Rect2(mn, mx - mn).grow(0.6).intersection(rect))

## Coloca un objeto en coordenadas locales de la sala (x hacia el este, z hacia el sur, en metros desde la esquina NO).
func _en(r: Dictionary, nombre: String, x: float, z: float, yaw := 0.0, escala := 1.0, alto := 0.0, choca := true) -> Node3D:
	var rect: Rect2 = r.rect
	if nombre in ["GothicBed_01", "old_bed_frame"] and alto < 0.3 and String(r.name) != "Cuarto de niños" and String(r.name) != "Cuarto de servicio":
		for c in _camas:
			if int(c.sala) == int(r.id):
				return null
	if nombre == "bano_classic_bathtub" and _con_banera.has(int(r.id)):
		return null
	var aj := _ajustar(r, x, z)
	x = aj.x
	z = aj.y
	var t := m._prop_size(_real(nombre)) * escala
	var ext := t if absf(sin(yaw)) < 0.7 else Vector3(t.z, t.y, t.x)
	# nada puede meterse dentro de la pared: se empuja hasta la cara interior (las exteriores son más gruesas)
	if alto < ZarekMansion.WALL_H - 1.2:
		var f := _caras(r)
		x = clampf(x, f[0] + ext.x * 0.5 + 0.01, rect.size.x - f[1] - ext.x * 0.5 - 0.01) if ext.x < rect.size.x * 0.5 else x
		z = clampf(z, f[2] + ext.z * 0.5 + 0.01, rect.size.y - f[3] - ext.z * 0.5 - 0.01) if ext.z < rect.size.y * 0.5 else z
	var p := Vector3(rect.position.x + x, float(r.y) + alto, rect.position.y + z)
	# un mueble alto pegado a la pared no puede tapar una ventana: se corre a lo largo de la pared
	if t.y > 1.3 and alto < 0.5:
		p = _esquivar_ventana(r, p, ext)
	# las salas son de tamaño real: lo que no cabe (fuera de la sala, encima de otro mueble o delante de una
	# puerta) no se pone, en vez de amontonarse
	if alto < 0.3 and (choca or t.y > 0.25):
		var a := Rect2(p.x - ext.x * 0.5, p.z - ext.z * 0.5, ext.x, ext.z).abs()
		if not rect.grow(0.02).encloses(a):
			if (DBG_CAMA and nombre in ["old_bed_frame", "GothicBed_01", "bano_classic_bathtub"]) or DBG_SALA == String(r.name): print("  CAMA_NO sala ", nombre, " ", r.name, " ", a)
			return null
		for o in _ocupado:
			var ob := (o as Rect2).abs()
			if ob.size.x > 0.1 and ob.size.y > 0.1 and ob.grow(-0.04).intersects(a):
				if (DBG_CAMA and nombre in ["old_bed_frame", "GothicBed_01", "bano_classic_bathtub"]) or DBG_SALA == String(r.name): print("  CAMA_NO ocupado ", nombre, " ", r.name, " ", a, " ", ob)
				return null
		if not m.door_near(p, maxf(ext.x, ext.z) * 0.5 + 0.75).is_empty() or not m.portal_near(p, maxf(ext.x, ext.z) * 0.5 + 0.9).is_empty():
			if (DBG_CAMA and nombre in ["old_bed_frame", "GothicBed_01", "bano_classic_bathtub"]) or DBG_SALA == String(r.name): print("  CAMA_NO puerta ", nombre, " ", r.name, " ", a)
			return null
	# lo que va encima de un mueble necesita el mueble debajo
	elif alto >= 0.3 and alto <= 1.2:
		var apoyo := false
		for o in _ocupado:
			if (o as Rect2).grow(0.05).has_point(Vector2(p.x, p.z)):
				apoyo = true
				break
		if not apoyo:
			return null
	var n := m._prop(_real(nombre), p, yaw, escala, choca)
	if DBG_SALA == String(r.name): print("  PUESTO ", nombre, " ", p, " ", n != null)
	if n and nombre == "t_mu_polly":
		_ensuciar(n, Color(0.78, 0.72, 0.62))
		m.munecas.append(n)
	if n and (choca or (alto < 0.3 and t.y > 0.25)):
		_ocupar(p, ext)
		var real := _real(nombre)
		if SUPERFICIE.has(real) and alto < 0.3:
			_superficies.append({"pos": p, "ext": ext, "tam": t, "yaw": yaw, "nombre": real, "alto": float(SUPERFICIE[real]) * escala, "sala": r.id, "n": 0, "grupo": _grupo(r)})
		if real in ["GothicBed_01", "old_bed_frame"]:
			_camas.append({"pos": p, "yaw": yaw, "tam": t, "alto": 0.62 if real == "GothicBed_01" else 0.58, "sala": r.id})
		if t.y > 1.5:
			_altos.append(Rect2(p.x - ext.x * 0.5 - 0.1, p.z - ext.z * 0.5 - 0.1, ext.x + 0.2, ext.z + 0.2))
	elif n and alto > 0.3:
		# algo puesto encima de una superficie: cuenta para no amontonar
		for sf in _superficies:
			if Vector2(sf.pos.x - p.x, sf.pos.z - p.z).length() < 0.9:
				sf.n += 1
	return n

func _esquivar_ventana(r: Dictionary, p: Vector3, ext: Vector3) -> Vector3:
	var rect: Rect2 = r.rect
	var dx := minf(p.x - rect.position.x, rect.end.x - p.x)
	var dz := minf(p.z - rect.position.y, rect.end.y - p.z)
	if minf(dx, dz) > 0.9:
		return p
	var eje := Vector3(0, 0, 1) if dx < dz else Vector3(1, 0, 0)
	var media := (ext.z if dx < dz else ext.x) * 0.5
	var y0 := float(r.y)
	var muro := Vector3(p.x, y0, p.z)
	if not m.ventana_cerca(muro, media + 0.85):
		return p
	for paso in [0.6, -0.6, 1.2, -1.2, 1.8, -1.8, 2.4, -2.4]:
		var q: Vector3 = muro + eje * paso
		if not rect.grow(-media).has_point(Vector2(q.x, q.z)):
			continue
		if not m.ventana_cerca(q, media + 0.85):
			return Vector3(q.x, p.y, q.z)
	return p

var _caras_cache: Dictionary = {}
## Distancia de cada borde de la sala a la cara interior de su pared [oeste, este, norte, sur]
## (+ zócalo/revestimiento): 0,25 en paredes exteriores, 0,155 en las interiores.
func _caras(r: Dictionary) -> Array:
	if _caras_cache.has(r.id):
		return _caras_cache[r.id]
	var rect: Rect2 = r.rect
	var y := float(r.y)
	var c := rect.get_center()
	var prueba := [Vector3(rect.position.x - 0.6, y, c.y), Vector3(rect.end.x + 0.6, y, c.y), Vector3(c.x, y, rect.position.y - 0.6), Vector3(c.x, y, rect.end.y + 0.6)]
	var out: Array = []
	for q in prueba:
		out.append(0.155 if m.room_at(q) >= 0 else 0.25)
	_caras_cache[r.id] = out
	return out

## Oscurece y ensucia los materiales de un objeto (telas claras que llevan décadas cogiendo polvo).
func _ensuciar(n: Node3D, tinte: Color) -> void:
	if n == null:
		return
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var mm: Mesh = (mi as MeshInstance3D).mesh
		for si in mm.get_surface_count():
			var mat := mm.surface_get_material(si)
			if mat is BaseMaterial3D:
				var d: BaseMaterial3D = mat.duplicate()
				d.albedo_color = d.albedo_color * tinte
				(mi as MeshInstance3D).set_surface_override_material(si, d)

## Cuadro o espejo colgado (origen en el centro del marco) en coordenadas locales de la sala.
func _cuadro(r: Dictionary, nombre: String, x: float, z: float, yaw: float, escala: float, alto := 2.25) -> Vector3:
	var aj := _ajustar(r, x, z)
	x = aj.x
	z = aj.y
	var f := _caras(r)
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	var dmin := minf(minf(x, W - x), minf(z, D - z))
	if dmin == x: x = f[0] + 0.03
	elif dmin == W - x: x = W - f[1] - 0.03
	elif dmin == z: z = f[2] + 0.03
	else: z = D - f[3] - 0.03
	var rect: Rect2 = r.rect
	var q := Vector3(rect.position.x + x, float(r.y) + alto, rect.position.y + z)
	var media := m._prop_size(_real(nombre)).x * escala * 0.5
	var radio_v := 1.0 + media
	if m.ventana_cerca(Vector3(q.x, float(r.y), q.z), radio_v) or not _pared_libre(Vector3(q.x, float(r.y), q.z), media + 0.5):
		var eje := Vector3(0, 0, 1) if (dmin == x or dmin == W - x) else Vector3(1, 0, 0)
		var hecho := false
		for paso in [1.2, -1.2, 2.0, -2.0]:
			var q2: Vector3 = q + eje * paso
			if rect.grow(-0.5).has_point(Vector2(q2.x, q2.z)) and not m.ventana_cerca(Vector3(q2.x, float(r.y), q2.z), radio_v) and m.door_near(Vector3(q2.x, float(r.y), q2.z), 1.3).is_empty() and _pared_libre(Vector3(q2.x, float(r.y), q2.z), media + 0.5):
				q = q2
				hecho = true
				break
		if not hecho:
			return Vector3.ZERO
	var real := _real(nombre)
	if real.begins_with("obj_") or real.begins_with("s_"):
		var tq := m._prop_size(real) * escala
		q += Vector3(0, -tq.y * 0.5, 0) + Vector3(0, 0, 1).rotated(Vector3.UP, yaw) * tq.z * 0.5
	m._prop(real, q, yaw, escala, false)
	_en_pared.append(Vector3(q.x, float(r.y), q.z))
	return q

## Cuelga algo de pared (escopetas, trofeos) en un tramo libre de cualquier pared, a la altura de los ojos.
func _colgar(r: Dictionary, nombre: String) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	for intento in 8:
		var lado := rng.randi() % 4
		var x := 0.0
		var z := 0.0
		var yaw := 0.0
		match lado:
			0:
				x = rng.randf_range(0.8, W - 0.8); z = 0.0; yaw = 0.0
			1:
				x = rng.randf_range(0.8, W - 0.8); z = D; yaw = PI
			2:
				x = 0.0; z = rng.randf_range(0.8, D - 0.8); yaw = PI * 0.5
			_:
				x = W; z = rng.randf_range(0.8, D - 0.8); yaw = -PI * 0.5
		var q := Vector3(r.rect.position.x + x, float(r.y), r.rect.position.y + z)
		if not m.door_near(q, 1.4).is_empty() or not _pared_libre(q, 0.9):
			continue
		var alto := 1.55 if nombre.contains("mosquete") else 1.95
		if _cuadro(r, nombre, x, z, yaw, 1.0, alto) != Vector3.ZERO:
			return

## Salón con chimenea: sala de muestra montada a mano, como una sala real abandonada de golpe en 1908.
## Local: x al este, z al sur. Chimenea en la pared oeste (z 3,6) entre dos ventanas (z 1,2 y 6,0);
## puertas al norte (x 4,8-7,2) y al este (z 4,8-7,2); armario-escondite en la pared sur (x≈10,5).
## Giros: los modelos que miran a +Z usan N=PI, S=0, E=PI/2, O=-PI/2; los que miran a +X (sofás vict_, pianos) usan O=PI, E=0, N=PI/2, S=-PI/2.
func _salon_chimenea(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	# --- repisa de la chimenea (1,54 m) ---
	_en(r, "mantel_clock_01", 0.42, 3.6, PI * 0.5, 1.0, 1.55, false)
	_en(r, "wooden_candlestick", 0.42, 3.05, 0.0, 1.0, 1.55, false)
	_en(r, "wooden_candlestick", 0.42, 4.15, 0.0, 1.0, 1.55, false)
	_en(r, "antique_ceramic_vase_01", 0.4, 4.42, 0.0, 0.6, 1.55, false)
	# --- tertulia frente al fuego, sobre la alfombra grande ---
	_en(r, "vict_victorian_two_seat_sofa", 4.5, 3.6, PI)
	_en(r, "vict_victorian_coffee_table", 3.05, 3.6, 0.0)
	_en(r, "vict_victorian_armchair", 2.5, 1.75, 0.29)
	_en(r, "vict_victorian_armchair", 2.5, 5.45, 2.86)
	_en(r, "Ottoman_01", 1.75, 5.0, 0.4, 0.8)
	_en(r, "coci_samovar", 3.05, 3.2, 0.5, 0.7, 0.5, false)
	_en(r, "vict_cup___saucer", 2.95, 3.7, 0.0, 1.0, 0.5, false)
	_en(r, "vict_cup___saucer", 3.15, 3.95, 1.2, 1.0, 0.5, false)
	_en(r, "book_encyclopedia_set_01", 3.1, 4.0, 1.4, 0.7, 0.5, false)
	_en(r, "coti_occult_books", 5.4, 4.6, 0.8, 0.8, 0.0, false)
	# --- pared sur: librería doble, reloj de pie y escritorio ---
	_en(r, "vict_antique_wooden_bookcase___ga", 1.75, D - 0.24, PI)
	_en(r, "vict_antique_wooden_bookcase___ga", 3.65, D - 0.24, PI)
	_en(r, "pian_grandfather_clock", 5.25, D - 0.33, PI)
	_en(r, "vict_antique_desk", 7.3, D - 0.42, PI)
	_en(r, "dining_chair_02", 7.3, D - 1.15, 0.15)
	_en(r, "vintage_oil_lamp", 7.75, D - 0.35, 0.0, 0.55, 0.8, false)
	_en(r, "vict_old_books___free_download", 6.95, D - 0.35, 0.3, 0.6, 0.8, false)
	_en(r, "coti_pocket_watch", 7.35, D - 0.55, 0.9, 1.0, 0.8, false)
	_en(r, "coti_celestial_globe", 8.75, D - 0.65, 0.4)
	_cuadro(r, "fancy_picture_frame_01", 7.3, D - 0.09, PI, 1.7, 2.2)
	# --- pared norte, lado oeste: consola con espejo ---
	_en(r, "ClassicConsole_01", 2.7, 0.36, 0.0)
	_en(r, "vict_ornate_mirror", 2.7, 0.1, 0.0, 0.62, 1.3, false)
	_en(r, "coti_three_candles_and_a_golden_c", 2.2, 0.36, 0.0, 1.0, 0.95, false)
	_en(r, "marble_bust_01", 3.2, 0.36, 0.2, 0.7, 0.95, false)
	_en(r, "coti_wine_bottle", 2.6, 0.3, 0.0, 1.0, 0.95, false)
	_en(r, "coti_glass_bottle", 2.78, 0.4, 0.0, 1.0, 0.95, false)
	_en(r, "Rockingchair_01", 1.15, 1.25, 0.9)
	_cuadro(r, "fancy_picture_frame_02", 4.25, 0.09, 0.0, 0.9, 2.0)
	_cuadro(r, "fancy_picture_frame_02", 1.2, 0.09, 0.0, 0.9, 2.0)
	# --- pared norte, lado este: piano vertical con banqueta y candelabro de pie ---
	_en(r, "pian_dusty_piano", 9.2, 0.55, 0.0)
	_en(r, "pian_medieval_candelabra__free_do", 10.9, 0.55, 0.0)
	_cuadro(r, "fancy_picture_frame_02", 9.2, 0.09, 0.0, 1.5, 2.45)
	# --- rincón de música: sofá claro y butaca mirando al piano, sobre la alfombra pequeña ---
	_ensuciar(_en(r, "Sofa_01", 9.2, 3.9, PI), Color(0.72, 0.64, 0.55))
	_ensuciar(_en(r, "ArmChair_01", 7.7, 2.7, 2.1), Color(0.72, 0.64, 0.55))
	# --- rincón de juego (suroeste): mesita con ajedrez a medio jugar y dos sillas ---
	_en(r, "vict_small_antique_table_asset", 2.9, 7.5, 0.3, 0.75)
	_en(r, "chess_set", 2.9, 7.5, 0.3, 0.75, 0.29, false)
	_en(r, "vict_antique_chair", 2.9, 6.75, PI + 0.3)
	_en(r, "vict_antique_chair", 2.75, 8.3, 0.2)
	_en(r, "wooden_lantern_01", 3.2, 7.25, 0.0, 0.6, 0.29, false)
	# --- pared este (al norte de la puerta): diván y paisaje ---
	_en(r, "vict_victorian_lounge_sofa", W - 0.42, 2.4, PI)
	_cuadro(r, "fancy_picture_frame_01", W - 0.09, 2.4, -PI * 0.5, 2.1, 2.3)
	# --- pared este (al sur de la puerta): baúl de viaje ---
	_en(r, "treasure_chest", W - 0.4, 7.75, -PI * 0.5)
	# --- rincón suroeste: cómoda con busto junto a la ventana ---
	_en(r, "GothicCommode_01", 0.42, 8.3, PI * 0.5)
	_en(r, "terr_creepy_lady_bust_statue_scan", 0.42, 8.55, PI * 0.5, 0.75, 1.21, false)
	_en(r, "wooden_candlestick", 0.42, 7.95, 0.0, 1.0, 1.21, false)
	_cuadro(r, "ornate_mirror_01", 0.09, 8.3, PI * 0.5, 1.2, 2.2)
	# --- abandono: silla volcada y libros por el suelo ---
	var silla := _en(r, "vict_antique_chair", 7.9, 7.3, 2.2)
	if silla:
		silla.rotation.x = PI * 0.5
		silla.position.y += 0.22
	_en(r, "coti_12_old_books", 6.3, 7.9, 0.7, 1.0, 0.0, false)
	_en(r, "coti_shabby_books", 9.6, 7.4, 1.9, 1.0, 0.0, false)
	_en(r, "coti_simple_bookstack", 1.2, 9.0 - 0.75, 0.3, 0.8, 0.0, false)
	# --- telarañas en las esquinas altas ---
	for esq in [Vector2(0.4, 0.4), Vector2(W - 0.4, 0.4), Vector2(0.4, D - 0.4), Vector2(W - 0.4, D - 0.4)]:
		_en(r, "terr_cobwebs", esq.x, esq.y, atan2(W * 0.5 - esq.x, D * 0.5 - esq.y), 0.9, ZarekMansion.WALL_H - 0.9, false)

## Vestíbulo y gran escalera (9,6 × 16,8 m): la escalera ocupa el centro (x 2,4-7,2, z 4,8-10,6, sube hacia el norte);
## puerta principal al sur (x 4,8-7,2), puertas laterales a z 4,8-7,2 y 12-14,4 en ambos lados y al norte (x 4,8-7,2).
## Se deja libre el paso de la puerta principal a la escalera y a las puertas laterales.
func _vestibulo(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	var rect: Rect2 = r.rect
	var y := float(r.y)
	# alfombra de la entrada hasta el pie de la escalera
	m._alfombra(Vector3(rect.position.x + 4.8, y, rect.position.y + 13.9), 2.2, 4.6, 0.0)
	# pared sur, a los lados de la puerta: reloj de pie y consola con espejo
	_en(r, "vintage_grandfather_clock_01", 1.2, D - 0.3, PI)
	_en(r, "vict_dusty_antique_mirror__free", 3.3, D - 0.45, PI)
	_en(r, "ClassicConsole_01", 8.3, D - 0.36, PI)
	_en(r, "vict_ornate_mirror", 8.3, D - 0.1, PI, 0.62, 1.3, false)
	_en(r, "brass_candleholders", 8.0, D - 0.36, PI, 0.4, 0.95, false)
	_en(r, "vintage_oil_lamp", 8.8, D - 0.36, 0.0, 0.55, 0.95, false)
	# pared oeste entre puertas: diván para las visitas y un trofeo de caza encima
	_en(r, "vict_victorian_lounge_sofa", 0.45, 9.6, 0.0)
	_cuadro(r, "lion_head", 0.1, 9.6, PI * 0.5, 1.0, 2.15)
	_en(r, "side_table_01", 0.45, 11.3, 0.0, 0.9)
	_en(r, "antique_ceramic_vase_01", 0.45, 11.3, 0.0, 0.8, 0.5, false)
	# pared este entre puertas: consola gótica con candelabro y retrato grande
	_en(r, "GothicCommode_01", W - 0.42, 9.6, -PI * 0.5)
	_en(r, "pian_candelabra", W - 0.45, 9.2, -PI * 0.5, 0.35, 1.21, false)
	_en(r, "marble_bust_01", W - 0.45, 10.05, -PI * 0.5, 0.7, 1.21, false)
	_cuadro(r, "fancy_picture_frame_02", W - 0.1, 9.6, -PI * 0.5, 1.8, 2.05)
	# norte, detrás de la escalera: rincón de espera con dos sillones, mesita y estatua
	_en(r, "vict_victorian_armchair", 1.0, 1.0, 0.6)
	_en(r, "vict_victorian_armchair", 2.6, 0.9, -0.5)
	_en(r, "small_wooden_table_01", 1.8, 1.6, 0.2, 0.8)
	_en(r, "gothic_statue", W - 1.0, 1.1, -PI * 0.75, 0.75)
	_en(r, "obj_coat_rack_bowler_hat", W - 0.5, 3.5, -PI * 0.5)
	# bajo la escalera: baúles y maletas olvidadas
	_en(r, "treasure_chest", 3.6, 5.6, 0.2, 0.9)
	_en(r, "vintage_suitcase", 5.4, 5.4, -0.3)
	# cosas de quien llegó y se fue: bastón, sombrero no; cartas y un candelero caído en el suelo
	_en(r, "vict_old_books___free_download", 6.6, 12.4, 0.8, 0.5, 0.0, false)
	_en(r, "wooden_candlestick", 3.4, 13.2, 1.2, 1.0, 0.04, false)
	for esq in [Vector2(0.4, 0.4), Vector2(W - 0.4, 0.4), Vector2(0.4, D - 0.4), Vector2(W - 0.4, D - 0.4)]:
		_en(r, "terr_cobwebs", esq.x, esq.y, atan2(W * 0.5 - esq.x, D * 0.5 - esq.y), 0.9, ZarekMansion.WALL_H - 0.9, false)

## Cocina (7,2 × 9,6 m): la escalera de servicio ocupa x 2,4-4,8, z 1,4-7,2. Puertas: norte (x 2,4-4,8) y oeste (z 4,8-7,2).
## Pared este exterior con ventanas; al sur, la pared de la despensa. Cocina de servicio de 1900 dejada a medio hacer.
func _cocina(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	# rincón NE: estufa de azulejos con olla y cazo encima
	_en(r, "scandinavian_masonry_heater", W - 0.75, 0.8, -PI * 0.5)
	# pared este: alacena azul con loza; mesa de trabajo en el centro de la franja este
	_en(r, "painted_wooden_cabinet_02", W - 0.42, 2.7, -PI * 0.5)
	_en(r, "tea_set_01", W - 0.42, 2.7, -PI * 0.5, 0.55, 1.02, false)
	_en(r, "painted_wooden_table", 5.85, 5.4, PI * 0.5)
	_en(r, "painted_wooden_chair_01", 5.1, 4.8, PI * 0.5 + 0.2)
	_en(r, "painted_wooden_stool", 6.55, 6.4, 0.4)
	_en(r, "wooden_stool_01", 5.0, 6.3, 0.0)
	# encima de la mesa: pan, tabla con cebollas, cuenco con manzanas, jarra, olla esmaltada
	var tm := 0.96
	_en(r, "coti_bread_in_basket", 5.7, 4.6, 0.3, 1.0, tm, false)
	_en(r, "wooden_cutting_board", 5.85, 5.2, 1.4, 1.0, tm, false)
	for k in 4:
		_en(r, "yellow_onion", 5.78 + (k % 2) * 0.08, 5.1 + k * 0.06, k * 1.3, 1.0, tm + 0.04, false)
	_en(r, "wooden_spoon", 6.05, 5.3, 0.2, 1.0, tm, false)
	_en(r, "wooden_bowl_01", 5.95, 5.9, 0.0, 1.0, tm, false)
	for k in 4:
		_en(r, "food_apple_01", 5.9 + (k % 2) * 0.08, 5.85 + (k / 2) * 0.08, k, 1.0, tm + 0.05, false)
	_en(r, "jug_01", 5.6, 6.2, 0.9, 1.0, tm, false)
	_en(r, "pot_enamel_01", 6.15, 4.8, 0.3, 1.0, tm, false)
	_en(r, "sweet_potato", 6.2, 6.4, 1.0, 1.0, tm, false)
	_en(r, "lemon", 6.25, 6.5, 0.0, 1.0, tm, false)
	# pared sur: fregadero de piedra con cubos y escoba
	_en(r, "bano_washbasin", 6.0, D - 0.48, PI, 0.85)
	_en(r, "wooden_bucket_01", W - 0.45, 7.4, 0.3)
	_en(r, "wooden_bucket_02", W - 0.55, 8.1, 1.0)
	_en(r, "wooden_broom", 5.25, D - 0.25, PI, 1.0, 0.0, false)
	_en(r, "metal_jug", 5.6, D - 0.4, 0.0, 1.0, 0.81, false)
	# pared oeste (norte de la puerta): estantes con cazos y botes; barril y cajas debajo
	_en(r, "painted_wooden_shelves", 0.25, 1.4, PI * 0.5)
	_en(r, "painted_wooden_shelves", 0.25, 2.0, PI * 0.5)
	_en(r, "brass_pot_02", 0.25, 1.4, PI * 0.5, 1.0, 1.13, false)
	_en(r, "brass_pot_01", 0.25, 2.0, 0.0, 0.8, 1.13, false)
	_en(r, "brass_pan_01", 0.6, 3.4, 0.4, 1.0, 0.0, false)
	_en(r, "wine_barrel_01", 0.5, 3.4, 0.0, 0.85)
	_en(r, "wicker_basket_02", 1.5, 0.5, 0.6)
	_en(r, "wicker_basket_01", 1.2, 0.95, 1.2, 1.0, 0.0, false)
	# rincón SO (sur de la puerta oeste): cajas de verduras y un banco
	_en(r, "wooden_crate_02", 0.4, 8.3, 0.0)
	_en(r, "wooden_crate_01", 1.4, 8.9, 0.3)
	_en(r, "painted_wooden_bench", 0.3, 7.6, PI * 0.5, 0.9)
	# lo que no debería estar: una rata junto al cubo y una ratonera
	_en(r, "street_rat", 3.2, D - 0.9, 2.4, 1.7, 0.0, false)
	_en(r, "mousetrap", 1.0, 7.0, 0.5, 1.4, 0.0, false)
	for esq in [Vector2(0.4, 0.4), Vector2(W - 0.4, D - 0.4), Vector2(0.4, D - 0.4)]:
		_en(r, "terr_cobwebs", esq.x, esq.y, atan2(W * 0.5 - esq.x, D * 0.5 - esq.y), 0.9, ZarekMansion.WALL_H - 0.9, false)

## Comedor formal (9,6 × 9,6 m): chimenea al sur (x 4,8), puertas al oeste (z 4,8-7,2) y al norte (x 2,4-4,8).
## La cena quedó servida y nadie volvió a sentarse.
func _comedor(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	var mz := 4.5
	_en(r, "dining_table", 3.7, mz, 0.0)
	_en(r, "dining_table", 5.95, mz, 0.0)
	for k in 4:
		var x := 2.95 + k * 1.12
		_en(r, "dining_chair_02", x, mz - 1.05, 0.0)
		if k != 2:
			_en(r, "dining_chair_02", x, mz + 1.05, PI)
	_en(r, "dining_chair_02", 2.2, mz, PI * 0.5)
	_en(r, "dining_chair_02", 7.5, mz, -PI * 0.5)
	# la silla que falta en el lado sur está volcada en el suelo
	var caida := _en(r, "dining_chair_02", 5.4, mz + 2.0, 2.6, 1.0, 0.0, false)
	if caida:
		caida.rotation.x = -PI * 0.5
		caida.position.y += 0.22
	# la mesa servida
	var t := 0.877
	_en(r, "brass_candleholders", 3.3, mz, 0.0, 0.55, t, false)
	_en(r, "brass_candleholders", 6.3, mz, 0.0, 0.55, t, false)
	_en(r, "tea_set_01", 4.85, mz, 0.0, 0.8, t, false)
	_en(r, "coti_bread_in_basket", 4.2, mz + 0.15, 0.4, 1.0, t, false)
	_en(r, "wine_bottles_01", 5.6, mz - 0.1, 0.3, 0.8, t, false)
	# mantel blanco sobre las dos mesas y un cubierto completo en cada sitio (también donde falta la silla)
	_mantel(Vector3(r.rect.position.x + 4.825, float(r.y) + t, r.rect.position.y + mz), Vector2(4.75, 1.62))
	var tt := t + 0.004
	for k in 4:
		var x := 2.95 + k * 1.12
		_cubierto(Vector3(r.rect.position.x + x, float(r.y) + tt, r.rect.position.y + mz - 0.45), Vector3(0, 0, 1))
		_cubierto(Vector3(r.rect.position.x + x, float(r.y) + tt, r.rect.position.y + mz + 0.45), Vector3(0, 0, -1))
	_cubierto(Vector3(r.rect.position.x + 2.8, float(r.y) + tt, r.rect.position.y + mz), Vector3(1, 0, 0))
	_cubierto(Vector3(r.rect.position.x + 6.9, float(r.y) + tt, r.rect.position.y + mz), Vector3(-1, 0, 0))
	# fuentes en el centro
	_en(r, "obj_elegant_victorian_porcelan_t", 4.1, mz - 0.05, 0.6, 1.0, tt, false)
	_en(r, "obj_cup_and_plate", 5.25, mz + 0.12, 0.0, 1.0, tt, false)
	# una copa derramada junto a un plato
	var copa := _en(r, "brass_goblets", 4.7, mz + 0.4, 1.0, 0.6, t + 0.05, false)
	if copa:
		copa.rotation.z = PI * 0.5
	# pared este: vitrina de loza y aparador con candelabro
	_en(r, "vintage_cabinet_01", W - 0.4, 2.4, -PI * 0.5)
	_en(r, "GothicCommode_01", W - 0.36, 6.9, -PI * 0.5)
	_en(r, "pian_candelabra", W - 0.4, 6.6, -PI * 0.5, 0.35, 1.21, false)
	_en(r, "brass_vase_01", W - 0.4, 7.4, 0.0, 0.6, 1.21, false)
	# pared norte (al este de la puerta): consola con fuente y jarrones
	_en(r, "ClassicConsole_01", 7.0, 0.36, 0.0)
	_en(r, "ceramic_vase_01", 6.5, 0.36, 0.0, 1.0, 0.95, false)
	_en(r, "ceramic_vase_01", 7.5, 0.36, 0.0, 1.0, 0.95, false)
	_en(r, "coci_samovar", 7.0, 0.36, 0.0, 0.8, 0.95, false)
	_cuadro(r, "fancy_picture_frame_01", 7.0, 0.09, 0.0, 2.0, 2.0)
	# pared oeste (norte de la puerta): mesita con lámpara; rincón sur: sillón y retrato
	_en(r, "side_table_01", 0.4, 2.2, PI * 0.5)
	_en(r, "vintage_oil_lamp", 0.4, 2.2, 0.0, 0.55, 0.55, false)
	_cuadro(r, "fancy_picture_frame_02", 0.09, 2.4, PI * 0.5, 1.4, 2.1)
	_en(r, "vict_victorian_armchair", 1.0, 8.6, PI * 0.8)
	_cuadro(r, "fancy_picture_frame_01", 2.4, D - 0.09, PI, 1.7, 2.1)
	_cuadro(r, "fancy_picture_frame_02", 7.2, D - 0.09, PI, 1.2, 2.0)
	for esq in [Vector2(0.4, 0.4), Vector2(W - 0.4, 0.4), Vector2(0.4, D - 0.4), Vector2(W - 0.4, D - 0.4)]:
		_en(r, "terr_cobwebs", esq.x, esq.y, atan2(W * 0.5 - esq.x, D * 0.5 - esq.y), 0.9, ZarekMansion.WALL_H - 0.9, false)

## Tumba un objeto que viene de pie (cartas, lupa): queda plano sobre su apoyo.
func _tumbar(n: Node3D) -> void:
	if n:
		n.rotate_object_local(Vector3.RIGHT, -PI * 0.5)

## Biblioteca (9,6 × 9,6 m): chimenea al norte (x 4,8), puertas al sur (x 4,8-7,2) y al este (z 4,8-7,2),
## armario-escondite en la pared oeste (z 4,8). Estanterías hasta el techo en todas las paredes libres.
func _biblioteca(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	var est := "vict_antique_wooden_bookcase___ga"
	for z in [1.05, 2.9, 6.7, 8.5]:
		_en(r, est, 0.17, z, PI * 0.5)
	for x in [2.05, 3.9]:
		_en(r, est, x, D - 0.17, PI)
	_en(r, est, 8.45, D - 0.17, PI)
	for z in [1.05, 2.9]:
		_en(r, est, W - 0.17, z, -PI * 0.5)
	for x in [2.0, 7.6]:
		_en(r, est, x, 0.17, 0.0)
	# lectura frente al fuego
	_en(r, "vict_victorian_armchair", 3.6, 2.7, PI - 0.45)
	_en(r, "vict_victorian_armchair", 6.0, 2.7, PI + 0.45)
	_en(r, "side_table_01", 4.8, 2.9, 0.0, 0.85)
	_en(r, "wooden_candlestick", 4.75, 2.9, 0.0, 1.0, 0.47, false)
	_en(r, "round_spectacles", 4.9, 2.95, 0.6, 1.0, 0.47, false)
	_en(r, "Ottoman_01", 6.5, 1.9, 0.3, 0.7)
	# escritorio de consulta en el centro, con todo a medio usar
	_en(r, "vict_antique_wooden_desk", 4.6, 5.9, PI * 0.5)
	_en(r, "vict_antique_chair", 4.6, 5.1, PI)
	var t := 0.8
	_en(r, "vintage_oil_lamp", 3.8, 6.0, 0.0, 0.55, t, false)
	_en(r, "coti_simple_bookstack", 4.5, 6.0, 0.4, 0.7, t, false)
	_en(r, "vict_old_books___free_download", 5.3, 6.1, 1.2, 0.7, t, false)
	_tumbar(_en(r, "magnifying_glass_01", 4.9, 5.8, 0.7, 1.0, t + 0.01, false))
	_en(r, "vintage_pocket_watch", 4.2, 5.75, 0.3, 1.0, t, false)
	_en(r, "coti_celestial_globe", 8.3, 7.2, 0.5)
	# libros por el suelo: alguien buscaba algo con prisa
	_en(r, "coti_12_old_books", 1.3, 6.3, 0.4, 1.0, 0.0, false)
	_en(r, "coti_shabby_books", 2.4, 8.4, 2.0, 1.0, 0.0, false)
	_en(r, "coti_simple_bookstack", 7.6, 1.3, 0.9, 0.9, 0.0, false)
	_en(r, "coti_simple_bookstack", 1.1, 2.0, 0.2, 0.9, 0.0, false)
	_en(r, "book_encyclopedia_set_01", 3.0, 7.6, 1.7, 0.8, 0.0, false)
	_en(r, "wooden_ladder", 0.75, 7.6, PI * 0.5, 1.4)
	for esq in [Vector2(0.4, 0.4), Vector2(W - 0.4, 0.4), Vector2(0.4, D - 0.4), Vector2(W - 0.4, D - 0.4)]:
		_en(r, "terr_cobwebs", esq.x, esq.y, atan2(W * 0.5 - esq.x, D * 0.5 - esq.y), 0.9, ZarekMansion.WALL_H - 0.9, false)

## Estudio del padre (4,8 × 9,6 m): puertas al sur (x 2,4-4,8), oeste (z 4,8-7,2) y este (z 2,4-4,8);
## pasadizo secreto en (2,4; 8,4), que hay que dejar libre.
func _estudio(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_en(r, "vict_antique_desk", 2.4, 1.55, 0.0)
	_en(r, "vict_antique_chair", 2.4, 0.85, 0.0)
	var t := 0.8
	_en(r, "coti_typewriter", 2.1, 1.5, 0.15, 1.0, t, false)
	_en(r, "vintage_oil_lamp", 2.9, 1.4, 0.0, 0.5, t, false)
	_en(r, "coti_pocket_watch", 2.75, 1.7, 0.4, 1.0, t, false)
	_en(r, "coti_simple_bookstack", 1.75, 1.45, 0.4, 0.6, t, false)
	_en(r, "round_spectacles", 2.5, 1.75, 0.2, 1.0, t, false)
	_cuadro(r, "fancy_picture_frame_02", 2.4, 0.09, 0.0, 1.6, 1.9)
	_en(r, "vict_antique_wooden_bookcase___ga", 0.17, 2.4, PI * 0.5)
	_en(r, "vintage_grandfather_clock_01", W - 0.3, 1.0, -PI * 0.5)
	# (la caja fuerte de verdad la pone interaccion.gd contra una pared: aquí no va otra)
	_en(r, "s_secreter", W - 0.5, 6.3, -PI * 0.5)
	_cuadro(r, "bull_head", W - 0.1, 7.6, -PI * 0.5, 1.1, 2.2)
	_en(r, "vict_victorian_lounge_sofa", 0.4, 8.3, 0.0)
	_en(r, "vict_old_books___free_download", 3.6, 6.0, 0.8, 0.6, 0.0, false)
	for esq in [Vector2(0.4, 0.4), Vector2(W - 0.4, 0.4), Vector2(W - 0.4, D - 0.4)]:
		_en(r, "terr_cobwebs", esq.x, esq.y, atan2(W * 0.5 - esq.x, D * 0.5 - esq.y), 0.9, ZarekMansion.WALL_H - 0.9, false)

## Dormitorio de los padres (9,6 × 9,6, primer piso): puertas al sur (x 4,8-7,2) y este (z 4,8-7,2);
## sello 2 en (3,6; 3,6) libre; armario-escondite en (8,4; 8,4); chimenea en la pared oeste.
func _dormitorio_padres(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_en(r, "GothicBed_01", 5.2, 1.15, 0.0)
	_en(r, "throw_pillows_01", 5.2, 0.6, 0.0, 0.9, 0.62, false)
	_en(r, "ClassicNightstand_01", 3.95, 0.33, 0.0)
	_en(r, "ClassicNightstand_01", 6.45, 0.33, 0.0)
	_en(r, "vintage_oil_lamp", 3.95, 0.33, 0.0, 0.5, 0.7, false)
	_en(r, "wooden_candlestick", 6.35, 0.3, 0.0, 1.0, 0.7, false)
	_en(r, "vict_old_books___free_download", 6.55, 0.4, 0.4, 0.4, 0.7, false)
	_en(r, "coti_pocket_watch", 4.05, 0.45, 0.8, 1.0, 0.7, false)
	_en(r, "vintage_suitcase", 5.2, 2.75, 0.1, 0.9)
	_cuadro(r, "fancy_picture_frame_02", 5.2, 0.09, 0.0, 1.5, 2.15)
	# tocador con espejo en la pared este (al norte de la puerta)
	_en(r, "GothicCommode_01", W - 0.36, 2.4, -PI * 0.5)
	_en(r, "vict_ornate_mirror", W - 0.1, 2.4, -PI * 0.5, 0.6, 1.25, false)
	_en(r, "coti_small_bottle", W - 0.4, 2.0, 0.0, 0.4, 1.21, false)
	_en(r, "coti_glass_bottle", W - 0.4, 2.15, 0.0, 0.8, 1.21, false)
	_en(r, "brass_vase_02", W - 0.4, 2.85, 0.0, 0.5, 1.21, false)
	# rincón de la chimenea: sillón y mesita; espejo de cuerpo entero en la esquina SO
	_en(r, "vict_victorian_armchair", 1.9, 6.4, -PI * 0.5 - 0.5)
	_en(r, "side_table_tall_01", 1.6, 7.3, 0.0)
	_en(r, "wooden_candlestick", 1.6, 7.3, 0.0, 1.0, 0.76, false)
	_en(r, "vict_dusty_antique_mirror__free", 0.6, 8.8, PI * 0.75)
	_en(r, "GothicCabinet_01", 3.4, D - 0.6, PI)
	_en(r, "vict_antique_chair", 7.0, 6.6, 2.4)
	for esq in [Vector2(0.4, 0.4), Vector2(W - 0.4, 0.4), Vector2(0.4, D - 0.4)]:
		_en(r, "terr_cobwebs", esq.x, esq.y, atan2(W * 0.5 - esq.x, D * 0.5 - esq.y), 0.9, ZarekMansion.WALL_H - 0.9, false)

## Cuarto de Damián (9,6 × 9,6): una sola puerta al sur (x 4,8-7,2). En el centro, su colchón (lo pone la mansión:
## ahí se prepara la trampa, radio 1,9 libre). Su ropa de niño, los trofeos de sus víctimas, la pared de fotos.
func _cuarto_elena(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	# trofeos: mochilas, maletas, chaquetas, botas y zapatos apilados contra la pared oeste
	for q in [[0.5, 1.2, "vintage_suitcase", 0.0], [0.45, 2.1, "obj_sack_v1", 0.4], [0.5, 2.9, "obj_sack_v2", 1.2], [0.9, 1.6, "ropa_leather_bag", 0.7],
			[0.5, 3.8, "ropa_heavy_worn_jacket", 1.4], [1.2, 3.4, "ropa_boots", 0.3], [1.0, 4.4, "ropa_old_shoes", 2.0], [1.4, 2.4, "ropa_old_dirty_boots", 4.0],
			[0.6, 5.2, "ropa_purse", 0.6], [1.0, 5.8, "ropa_umbrella", 1.5], [0.5, 6.4, "ropa_kirza_boots", 0.2]]:
		_en(r, q[2], q[0], q[1], q[3], 1.0, 0.0, false)
	# la pared de fotos de las víctimas, con chinchetas; las tachadas ya se las comió su madre
	if not ZarekTerror._en_pared(m, r, "fotos_victimas", Vector2(3.0, 2.25), 1.7):
		ZarekTerror._en_pared(m, r, "fotos_victimas", Vector2(2.0, 1.5), 1.7)
	# mesa de trabajo con cuchillos, la cuchilla y una calavera; el hacha colgada encima
	_en(r, "WoodenTable_03", W - 1.0, 2.2, -PI * 0.5)
	ZarekGore._x(m, "carnicero_knife_collection", Vector3(r.rect.position.x + W - 1.0, float(r.y) + 0.83, r.rect.position.y + 1.8), PI * 0.5, 0.8)
	ZarekGore._x(m, "carnicero_cleaver___butcher_s_best", Vector3(r.rect.position.x + W - 0.9, float(r.y) + 0.83, r.rect.position.y + 2.7), 1.2)
	ZarekGore._x(m, "huesos_human_skull", Vector3(r.rect.position.x + W - 1.1, float(r.y) + 0.83, r.rect.position.y + 3.1), -PI * 0.5)
	ZarekGore._x(m, "restos_bloody_axe", Vector3(r.rect.position.x + W - 0.12, float(r.y) + 1.1, r.rect.position.y + 2.2), -PI * 0.5)
	# su infancia: el oso de peluche, el caballito y una foto de su madre en la mesilla
	_en(r, "painted_wooden_nightstand", 2.4, D - 0.4, PI)
	_en(r, "obj_craft_teddy_bear_photogramme", 2.4, D - 0.4, PI + 0.3, 0.9, 0.62, false)
	_en(r, "d_fotos_familia", 2.7, D - 0.38, PI, 1.0, 0.62, false)
	_en(r, "jugu_rocking_horse", W - 1.4, D - 1.4, -2.4, 0.9)
	# delantal de carnicero colgado, cadenas y un cubo
	_en(r, "ropa_apron", W - 0.15, 5.4, -PI * 0.5, 1.0, 0.9, false)
	ZarekGore._x(m, "tortura_rusty_chains", Vector3(r.rect.position.x + W - 1.6, float(r.y), r.rect.position.y + 6.4), 0.4)
	ZarekGore._cubo_sangre(m, Vector3(r.rect.position.x + 1.4, float(r.y), r.rect.position.y + D - 1.2))
	_en(r, "GothicCabinet_01", 0.6, D - 1.6, PI * 0.5)
	for esq in [Vector2(0.4, 0.4), Vector2(W - 0.4, 0.4), Vector2(0.4, D - 0.4), Vector2(W - 0.4, D - 0.4)]:
		_en(r, "terr_cobwebs", esq.x, esq.y, atan2(W * 0.5 - esq.x, D * 0.5 - esq.y), 1.0, ZarekMansion.WALL_H - 0.9, false)

## Cuarto de niños (7,2 × 9,6): puertas al sur (x 2,4-4,8) y oeste (z 4,8-7,2); armario en (6,0; 8,4);
## la caja de música del juego va en (3,6; 3,6).
func _cuarto_ninos(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_cama_hierro(r, 1.2, 1.1, 0.0, 0.85)
	_cama_hierro(r, 6.0, 1.1, 0.0, 0.85)
	_en(r, "painted_wooden_nightstand", 3.6, 0.35, 0.0)
	_en(r, "wooden_candlestick", 3.6, 0.35, 0.0, 1.0, 0.62, false)
	_en(r, "jugu_dollhouse", W - 0.5, 3.6, -PI * 0.5)
	_en(r, "jugu_rocking_horse", 5.2, 5.6, 0.7)
	_en(r, "treasure_chest", 0.45, 3.2, PI * 0.5, 0.8)
	# la merienda de muñecas que nadie recogió
	_en(r, "small_wooden_table_01", 1.6, 8.5, 0.0, 0.8)
	_en(r, "painted_wooden_stool", 0.9, 8.5, 0.6)
	_en(r, "painted_wooden_stool", 2.3, 8.6, -0.4)
	_en(r, "tea_set_01", 1.6, 8.5, 0.2, 0.45, 0.43, false)
	_en(r, "coti_simple_bookstack", 4.6, 7.8, 1.2, 0.6, 0.0, false)
	# juguetes: el tren a medio camino, el oso en la cama, la gallina de madera
	_en(r, "obj_wooden_toy_train", 3.4, 6.6, 0.9, 1.0, 0.0, false)
	_en(r, "obj_craft_teddy_bear_photogramme", 1.2, 1.5, 0.3, 0.6, 0.62, false)
	_en(r, "obj_pecking_chicken_wooden_toy", 4.2, 4.4, 2.0, 1.0, 0.0, false)
	_cuadro(r, "fancy_picture_frame_01", 3.6, 0.09, 0.0, 1.2, 1.9)
	# la cuna de Clara, vacía; las muñecas sentadas a la merienda y otra en la cama, mirando a la puerta
	_en(r, "t_cuna_madera", W - 1.0, 7.6, -PI * 0.5)
	_en(r, "t_mu_polly", 0.9, 8.5, PI * 0.6, 1.0, 0.45, false)
	_en(r, "t_mu_polly", 2.3, 8.6, -PI * 0.6, 0.85, 0.45, false)
	_en(r, "t_mu_polly", 6.0, 1.6, 0.1, 1.0, 0.62, false)
	_en(r, "t_mu_polly", W - 1.0, 7.6, -PI * 0.4, 0.8, 0.42, false)
	# juguetes de hojalata por el suelo y la caja sorpresa abierta
	_en(r, "t_jug_caja_payaso", 5.6, 6.2, PI + 0.4, 1.0, 0.0, false)
	_en(r, "t_jug_soldado", 2.7, 6.9, 0.7, 1.0, 0.0, false)
	_en(r, "t_jug_soldado", 2.9, 7.1, 1.4, 1.0, 0.0, false)
	_en(r, "t_jug_peonza", 4.4, 7.4, 0.0, 1.0, 0.0, false)
	_en(r, "t_jug_musico", 3.85, 0.4, 0.3, 1.0, 0.62, false)
	for esq in [Vector2(0.4, 0.4), Vector2(W - 0.4, 0.4)]:
		_en(r, "terr_cobwebs", esq.x, esq.y, atan2(W * 0.5 - esq.x, D * 0.5 - esq.y), 0.9, ZarekMansion.WALL_H - 0.9, false)

## Sala de música (9,6 × 7,2): puertas al oeste y al este (z 2,4-4,8); el piano de cola va en el centro (marca).
func _sala_musica(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	# sillas para el público en arco, mirando al piano (al norte de él)
	for k in 5:
		var a := lerpf(-0.9, 0.9, k / 4.0)
		var x := 4.8 + sin(a) * 2.6
		var z := 6.1 - (1.0 - cos(a)) * 1.2
		_en(r, "vict_antique_chair", x, z, PI + a)
	_en(r, "pian_dusty_old_piano", 0.6, 0.9, PI * 0.5)
	_en(r, "pian_medieval_candelabra__free_do", W - 0.5, 0.5, 0.0)
	_en(r, "pian_medieval_candelabra__free_do", 0.5, D - 0.5, 0.0)
	_en(r, "sofa_02", W - 0.5, 5.8, -PI * 0.5)
	_en(r, "vintage_grandfather_clock_01", 3.0, 0.3, 0.0)
	_cuadro(r, "fancy_picture_frame_02", 6.5, 0.09, 0.0, 1.6, 2.0)
	_cuadro(r, "fancy_picture_frame_01", 4.8, D - 0.09, PI, 1.8, 2.1)
	_en(r, "coti_shabby_books", 6.4, 3.9, 0.5, 1.0, 0.0, false)

## Salón de baile (14,4 × 9,6): puertas norte y sur (x 7,2-9,6) y oeste (z 2,4-4,8); sello 1 en (7,2; 3,6),
## piano en (3,6; 2,4), chimenea al norte. El centro queda despejado para bailar; sillas contra las paredes.
func _salon_baile(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	for z in [6.0, 7.0, 8.0]:
		_en(r, "vict_antique_chair", 0.35, z, PI * 0.5)
	for z in [1.2, 2.2, 3.2, 6.0, 7.0, 8.0]:
		_en(r, "vict_antique_chair", W - 0.35, z, -PI * 0.5)
	for x in [1.5, 2.5, 3.5, 4.5, 11.0, 12.2]:
		_en(r, "vict_antique_chair", x, D - 0.35, PI)
	var caida := _en(r, "vict_antique_chair", 9.8, 6.4, 1.1, 1.0, 0.0, false)
	if caida:
		caida.rotation.x = PI * 0.5
		caida.position.y += 0.22
	for z in [3.2, 7.0]:
		_cuadro(r, "vict_ornate_mirror", W - 0.08, z - 1.3, -PI * 0.5, 0.75, 1.0)
	_cuadro(r, "vict_ornate_mirror", 0.08, 7.0 - 1.3, PI * 0.5, 0.75, 1.0)
	for esq in [Vector2(0.55, 0.55), Vector2(W - 0.55, 0.55), Vector2(0.55, D - 0.55), Vector2(W - 0.55, D - 0.55)]:
		_en(r, "pian_medieval_candelabra__free_do", esq.x, esq.y, 0.0)
	_en(r, "painted_wooden_sofa", 3.6, 0.5, 0.0, 0.9)
	_en(r, "gothic_statue", W - 2.0, 4.8, -PI * 0.5, 0.6)
	# el fonógrafo que se enciende solo con el segundo sello
	_en(r, "small_wooden_table_01", 1.6, 1.5, 0.3, 0.9)
	_en(r, "obj_phonograph_v2", 1.6, 1.5, 0.6, 1.0, 0.48, false)
	_cuadro(r, "fancy_picture_frame_02", 11.0, 0.09, 0.0, 2.0, 2.0)
	for esq in [Vector2(0.4, 0.4), Vector2(W - 0.4, 0.4), Vector2(0.4, D - 0.4), Vector2(W - 0.4, D - 0.4)]:
		_en(r, "terr_cobwebs", esq.x, esq.y, atan2(W * 0.5 - esq.x, D * 0.5 - esq.y), 1.0, ZarekMansion.WALL_H - 0.9, false)

## Telarañas en las esquinas altas indicadas (0 NO, 1 NE, 2 SO, 3 SE).
func _telas(r: Dictionary, esquinas := [0, 1, 2, 3]) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	var e := [Vector2(0.4, 0.4), Vector2(W - 0.4, 0.4), Vector2(0.4, D - 0.4), Vector2(W - 0.4, D - 0.4)]
	for i in esquinas:
		var q: Vector2 = e[i]
		_en(r, "terr_cobwebs", q.x, q.y, atan2(W * 0.5 - q.x, D * 0.5 - q.y), 0.9, ZarekMansion.WALL_H - 0.9, false)

## Mesa de billar de 1,5 × 2,8 m hecha a medida: patas torneadas, banda de caoba, paño verde, troneras.
func _mesa_billar(r: Dictionary, x: float, z: float, yaw := 0.0) -> void:
	var rect: Rect2 = r.rect
	var piv := Node3D.new()
	piv.position = Vector3(rect.position.x + x, float(r.y), rect.position.y + z)
	piv.rotation.y = yaw
	m._house.add_child(piv)
	var c := Vector3.ZERO
	m.box(Vector3(1.5, 0.22, 2.8), c + Vector3(0, 0.7, 0), m._mat.madera, true, piv)
	m.box(Vector3(1.26, 0.03, 2.56), c + Vector3(0, 0.82, 0), m._mat.tela_verde, false, piv, false)
	for sx in [-0.69, 0.69]:
		m.box(Vector3(0.12, 0.07, 2.8), c + Vector3(sx, 0.845, 0), m._mat.madera, false, piv, false)
	for sz in [-1.34, 1.34]:
		m.box(Vector3(1.5, 0.07, 0.12), c + Vector3(0, 0.845, sz), m._mat.madera, false, piv, false)
	for px in [-0.62, 0.62]:
		for pz in [-1.27, 0.0, 1.27]:
			m.cyl(0.055, 0.055, 0.02, c + Vector3(px, 0.84, pz), m._mat.oscuro, piv, 10)
	for lx in [-0.6, 0.6]:
		for lz in [-1.2, 0.0, 1.2]:
			m.cyl(0.07, 0.1, 0.6, c + Vector3(lx, 0.3, lz), m._mat.madera, piv, 8)
	# bolas por el paño y un taco olvidado encima
	var cols := [Color(0.95, 0.93, 0.85), Color(0.8, 0.1, 0.08), Color(0.9, 0.75, 0.1)]
	for k in 3:
		var mat := m._plain(cols[k], 0.25)
		var b := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.03
		sm.height = 0.06
		b.mesh = sm
		b.material_override = mat
		b.position = c + Vector3(-0.3 + k * 0.28, 0.865, -0.5 + k * 0.45)
		piv.add_child(b)
	var taco := m.cyl(0.008, 0.016, 1.45, c + Vector3(0.2, 0.87, 0.3), m._mat.madera_clara, piv, 6)
	taco.rotation = Vector3(PI * 0.5, 0.35, 0)
	var ext := Vector3(1.5, 0.9, 2.8) if absf(sin(yaw)) < 0.7 else Vector3(2.8, 0.9, 1.5)
	_ocupar(piv.position, ext + Vector3(1.4, 0, 1.4))

## Sala de fumar y billar (7,2 × 4,8): puertas al norte (biblioteca) y al sur (pasillo), en el centro. La mesa va
## a lo largo, con paso alrededor para tacar; butacas y licores en el lado oeste, librería en el este.
func _billar(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_sin_ajuste = true
	_mesa_billar(r, W * 0.5 + 0.2, D * 0.5, PI * 0.5)
	# tacos apoyados en la pared oeste
	for k in 4:
		var t := m.cyl(0.008, 0.016, 1.45, Vector3(r.rect.position.x + 0.2, float(r.y) + 0.72, r.rect.position.y + D * 0.5 - 0.2 + k * 0.12), m._mat.madera_clara, null, 6)
		t.rotation.z = -0.08
	_en(r, "ArmChair_01", 0.75, 0.85, 0.6)
	_en(r, "side_table_01", 0.45, 1.75, 0.0, 0.8)
	_en(r, "coti_wine_bottle", 0.4, 1.75, 0.0, 1.0, 0.44, false)
	_en(r, "coti_glass_bottle", 0.55, 1.7, 0.0, 1.0, 0.44, false)
	_en(r, "ArmChair_01", 0.75, D - 0.85, 2.5)
	_en(r, "vict_antique_wooden_bookcase___ga", W - 0.2, D * 0.5, -PI * 0.5)
	_en(r, "vict_antique_chair", W - 1.0, 0.7, -0.4)
	_cuadro(r, "bull_head", 0.1, D * 0.5, PI * 0.5, 1.2, 2.25)
	_cuadro(r, "fancy_picture_frame_01", W * 0.3, 0.09, 0.0, 1.3, 2.1)
	_sin_ajuste = false
	_telas(r)

## Sala de las mañanas (4,8 × 9,6): puertas norte (x 2,4-4,8), oeste y este (z 4,8-7,2). Desayuno a media luz.
func _mananas(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_en(r, "round_wooden_table_01", 2.4, 2.9, 0.0, 0.75)
	for k in 3:
		var a := TAU * k / 3.0 + 0.4
		_en(r, "painted_wooden_chair_01", 2.4 + cos(a) * 0.95, 2.9 + sin(a) * 0.95, -a - PI * 0.5)
	_en(r, "tea_set_01", 2.4, 2.9, 0.4, 0.5, 0.755, false)
	_en(r, "coti_bread_in_basket", 2.2, 3.15, 0.0, 1.0, 0.755, false)
	_en(r, "sofa_02", 2.4, D - 0.45, PI)
	_en(r, "painted_wooden_cabinet", 0.36, 1.2, PI * 0.5)
	_en(r, "ceramic_vase_02", 0.36, 1.0, 0.0, 1.0, 1.18, false)
	_en(r, "Rockingchair_01", 3.9, 8.0, PI + 0.6)
	_cuadro(r, "fancy_picture_frame_02", W - 0.09, 2.6, -PI * 0.5, 1.3, 2.0)
	_telas(r, [1, 2, 3])

## Tocador de la madre (4,8 × 9,6): puertas sur (x 2,4-4,8) y oeste (z 4,8-7,2); tocador con espejo al norte.
func _tocador(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_en(r, "GothicCommode_01", 2.4, 0.33, 0.0)
	_en(r, "vict_ornate_mirror", 2.4, 0.1, 0.0, 0.62, 1.25, false)
	_en(r, "vict_antique_chair", 2.4, 1.1, PI)
	_en(r, "coti_small_bottle", 2.0, 0.35, 0.0, 0.35, 1.21, false)
	_en(r, "coti_glass_bottle", 2.15, 0.3, 0.0, 0.8, 1.21, false)
	_en(r, "jugu_music_box_prop", 2.85, 0.35, 0.3, 1.0, 1.21, false)
	_en(r, "brass_vase_03", 1.75, 0.35, 0.0, 0.4, 1.21, false)
	_en(r, "GothicCabinet_01", W - 0.6, 3.0, -PI * 0.5)
	_en(r, "vintage_day_bed", W - 0.45, 7.6, -PI * 0.5)
	_en(r, "vict_dusty_antique_mirror__free", 0.6, 3.0, PI * 0.5)
	_en(r, "vintage_suitcase", 0.5, 8.6, PI * 0.5, 0.9)
	_telas(r, [0, 1, 3])

## Cuarto del hermano (7,2 × 9,6): puertas sur (x 2,4-4,8) y este (z 4,8-7,2); armario en (6,0; 1,2).
func _hermano(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_cama_hierro(r, 0.6, 1.3, 0.0)
	_en(r, "painted_wooden_nightstand", 1.5, 0.35, 0.0)
	_en(r, "wooden_candlestick", 1.5, 0.35, 0.0, 1.0, 0.62, false)
	_en(r, "vict_antique_desk", 1.2, D - 0.4, PI)
	_en(r, "vict_antique_chair", 1.2, D - 1.05, 0.2)
	_en(r, "coti_celestial_globe", 0.9, D - 0.4, 0.0, 0.5, 0.8, false)
	_en(r, "vict_old_books___free_download", 1.6, D - 0.4, 0.4, 0.5, 0.8, false)
	_en(r, "vict_antique_wooden_bookcase___ga", 0.17, 5.4, PI * 0.5)
	_en(r, "treasure_chest", 3.2, 2.4, 0.2, 0.8)
	_en(r, "obj_floor_globe", 5.6, 8.3, -2.6)
	_en(r, "hatchet", 4.6, 8.9, 1.2, 1.0, 0.0, false)
	_cuadro(r, "fancy_picture_frame_01", 0.09, 1.4, PI * 0.5, 1.2, 2.2)
	_telas(r, [0, 2, 3])

## Baño (4,8 × 9,6): una puerta al sur (x 2,4-4,8). Bañera de patas, lavabo de pie con espejo.
func _bano(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_banera_donde_quepa(r)
	_en(r, "bano_washbasin_model", 0.35, 3.6, PI * 0.5)
	_en(r, "ornate_mirror_01", 0.12, 3.6, PI * 0.5, 1.2, 1.45, false)
	_en(r, "wooden_bucket_01", 3.9, 1.4, 0.3)
	_en(r, "painted_wooden_stool", 3.6, 2.0, 0.5)
	_en(r, "coti_small_bottle", 3.6, 2.0, 0.0, 0.35, 0.58, false)
	_en(r, "painted_wooden_shelves", W - 0.25, 4.6, -PI * 0.5)
	_en(r, "coti_glass_bottle", W - 0.25, 4.5, 0.0, 0.8, 1.13, false)
	_en(r, "jug_01", W - 0.25, 4.75, 0.3, 1.0, 1.13, false)
	_en(r, "wicker_basket_02", 0.5, 8.6, 0.3)
	_en(r, "painted_wooden_cabinet", W - 0.33, 7.4, -PI * 0.5)
	_en(r, "coti_small_bottle", W - 0.33, 7.2, 0.0, 0.35, 1.18, false)
	_en(r, "jug_01", W - 0.33, 7.7, 0.6, 1.0, 1.18, false)
	_en(r, "painted_wooden_chair_01", 1.3, 6.4, 0.7)
	_en(r, "wooden_bucket_02", 1.0, 1.4, 0.4)
	_telas(r, [0, 1, 2, 3])

## Huéspedes azul (7,2 × 9,6): puertas norte y sur (x 2,4-4,8); armario en (1,2; 7,2).
func _huespedes_azul(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_en(r, "GothicBed_01", W - 1.15, 4.6, -PI * 0.5)
	_en(r, "ClassicNightstand_01", W - 0.3, 3.1, -PI * 0.5)
	_en(r, "vintage_oil_lamp", W - 0.3, 3.1, 0.0, 0.5, 0.7, false)
	_en(r, "ClassicNightstand_01", W - 0.3, 6.1, -PI * 0.5)
	_en(r, "vintage_suitcase", 4.2, 4.6, PI * 0.5, 0.9)
	_en(r, "GothicCommode_01", 0.36, 2.6, PI * 0.5)
	_en(r, "ornate_mirror_01", 0.12, 2.6, PI * 0.5, 1.2, 1.4, false)
	_en(r, "vict_victorian_armchair", 1.4, 4.6, PI * 0.5 + 0.3)
	_cuadro(r, "fancy_picture_frame_02", W - 0.09, 4.6, -PI * 0.5, 1.3, 2.25)
	_telas(r, [0, 1, 3])

## Sala de costura (9,6 × 9,6): puertas norte y sur (x 4,8-7,2).
func _costura(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_en(r, "vict_singer_15___old_sewing_machi", 0.4, 2.4, PI * 0.5)
	_en(r, "painted_wooden_chair_01", 1.15, 2.4, -PI * 0.5)
	_en(r, "coti_willoughsby_sewing_machine", 0.55, 5.6, PI * 0.5)
	_en(r, "spinning_wheel_01", W - 1.2, 2.6, -0.7)
	_en(r, "painted_wooden_stool", W - 1.9, 3.2, 0.3)
	_en(r, "painted_wooden_table", 4.8, 4.8, 0.0, 0.8)
	_en(r, "wicker_basket_01", 4.4, 4.7, 0.3, 1.0, 0.77, false)
	_en(r, "wicker_basket_02", 5.3, 4.9, 1.0, 1.0, 0.77, false)
	_en(r, "painted_wooden_chair_02", 4.8, 3.9, 0.0)
	_en(r, "vintage_wooden_drawer_01", W - 0.55, 7.2, -PI * 0.5)
	_en(r, "painted_wooden_cabinet_02", 0.4, 8.6, PI * 0.5)
	_en(r, "wicker_basket_02", 2.4, 8.9, 0.4)
	_en(r, "wicker_basket_01", 7.6, 0.5, 1.4)
	_telas(r)

## Cuarto de la institutriz (9,6 × 7,2): una puerta al norte (x 4,8-7,2); armario en (8,4; 6,0).
func _institutriz(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_cama_hierro(r, 0.6, 4.6, 0.0)
	_en(r, "painted_wooden_nightstand", 1.4, 6.8, 0.0)
	_en(r, "wooden_candlestick", 1.4, 6.8, 0.0, 1.0, 0.62, false)
	_en(r, "vict_antique_desk", 2.6, 0.35, 0.0)
	_en(r, "vict_antique_chair", 2.6, 1.0, PI)
	_en(r, "vict_old_books___free_download", 2.3, 0.35, 0.2, 0.5, 0.8, false)
	_en(r, "coti_pocket_watch", 2.9, 0.45, 0.6, 1.0, 0.8, false)
	_en(r, "vict_antique_wooden_bookcase___ga", 0.17, 1.6, PI * 0.5)
	_en(r, "bano_washbasin_model", W - 0.3, 2.2, -PI * 0.5)
	_en(r, "painted_wooden_bench", 5.2, D - 0.35, PI)
	_cuadro(r, "fancy_picture_frame_01", 4.8, D - 0.09, PI, 1.3, 2.1)
	_telas(r, [0, 2, 3])

## Galería de retratos (9,6 × 12): llega la gran escalera (hueco x 2,4-7,2, z 4,8-10,6); puertas norte y sur.
## Retratos en todas las paredes y bustos en el extremo norte.
func _galeria(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	for z in [1.6, 4.0, 6.4, 8.8]:
		_cuadro(r, "fancy_picture_frame_02" if int(z) % 2 == 0 else "fancy_picture_frame_01", 0.09, z, PI * 0.5, 1.5, 1.9)
		_cuadro(r, "fancy_picture_frame_01" if int(z) % 2 == 0 else "fancy_picture_frame_02", W - 0.09, z, -PI * 0.5, 1.5, 1.9)
	for x in [1.6, 8.0]:
		_cuadro(r, "fancy_picture_frame_02", x, 0.09, 0.0, 1.6, 1.9)
		_en(r, "side_table_tall_01", x, 0.6, 0.0)
		_en(r, "marble_bust_01", x, 0.6, 0.0, 0.8, 0.76, false)
	_en(r, "painted_wooden_bench", 0.4, 11.0, PI * 0.5)
	_en(r, "painted_wooden_bench", W - 0.4, 11.0, -PI * 0.5)
	_en(r, "t_mu_polly", W - 0.4, 11.3, -PI * 0.5, 1.0, 0.45, false)
	_telas(r)

## Cuarto de huéspedes (9,6 × 9,6): puertas norte y sur (x 4,8-7,2); armario en (8,4; 8,4).
func _huespedes(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_en(r, "GothicBed_01", 1.15, 4.8, PI * 0.5)
	_en(r, "throw_pillows_01", 0.6, 4.8, PI * 0.5, 0.9, 0.62, false)
	_en(r, "ClassicNightstand_01", 0.3, 3.3, PI * 0.5)
	_en(r, "ClassicNightstand_01", 0.3, 6.3, PI * 0.5)
	_en(r, "wooden_candlestick", 0.3, 3.3, 0.0, 1.0, 0.7, false)
	_en(r, "GothicCommode_01", W - 0.36, 2.4, -PI * 0.5)
	_en(r, "ornate_mirror_01", W - 0.12, 2.4, -PI * 0.5, 1.2, 1.4, false)
	_en(r, "ArmChair_01", 7.6, 5.6, -2.2)
	_en(r, "treasure_chest", 3.3, 4.8, PI * 0.5, 0.85)
	_cuadro(r, "fancy_picture_frame_01", 0.09, 4.8, PI * 0.5, 1.6, 2.3)
	_telas(r, [0, 1, 2])

## Cuarto de lectura (9,6 × 7,2): una puerta al norte (x 4,8-7,2).
func _lectura(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	for x in [1.2, 3.1, 6.5, 8.4]:
		_en(r, "vict_antique_wooden_bookcase___ga", x, D - 0.17, PI)
	_en(r, "sofa_03", 0.5, 3.4, PI * 0.5, 0.85)
	_en(r, "coffee_table_round_01", 2.0, 3.4, 0.0, 0.8)
	_en(r, "vintage_oil_lamp", 2.0, 3.4, 0.0, 0.5, 0.4, false)
	_en(r, "vict_old_books___free_download", 2.2, 3.6, 0.6, 0.5, 0.4, false)
	_en(r, "vict_victorian_armchair", 4.8, 4.2, PI + 0.2)
	_en(r, "coti_celestial_globe", W - 0.9, 1.4, 0.4)
	_en(r, "Ottoman_01", 4.2, 3.2, 0.2, 0.7)
	_telas(r, [0, 1])

## Pasillos (43,2 × 2,4): alfombra corrida, consolas con candelabros y retratos entre las puertas de la pared norte.
func _pasillo(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	var rect: Rect2 = r.rect
	var y := float(r.y)
	var x := 3.0
	while x < W - 3.0:
		m._alfombra(Vector3(rect.position.x + x + 2.0, y, rect.position.y + D * 0.5), 1.1, 3.6, PI * 0.5)
		x += 4.4
	x = 2.4
	var k := 0
	while x < W - 1.8:
		var pn := Vector3(rect.position.x + x, y, rect.position.y + 0.3)
		if m.door_near(pn, 1.7).is_empty() and m.portal_near(pn, 2.0).is_empty():
			if k % 2 == 0:
				_en(r, "ClassicConsole_01", x, 0.33, 0.0, 0.8)
				_en(r, "brass_candleholders", x, 0.33, 0.0, 0.35, 0.76, false)
			else:
				_en(r, "side_table_tall_01", x, 0.3, 0.0)
				_en(r, "ceramic_vase_03", x, 0.3, 0.0, 1.0, 0.76, false)
			_cuadro(r, "fancy_picture_frame_02" if k % 3 else "fancy_picture_frame_01", x, 0.09, 0.0, 1.3, 1.95)
			k += 1
			x += 3.6
		else:
			x += 0.6
	if String(r.name) == "Pasillo":
		# una silla de ruedas vieja en mitad del pasillo, mirando hacia la escalera
		_en(r, "t_silla_ruedas_rota", W * 0.62, D - 0.75, -PI * 0.5)
		_en(r, "t_mu_polly", W - 0.6, D * 0.5, -PI * 0.5, 1.0, 0.0, false)
	else:
		# una muñeca sentada al fondo del pasillo, de cara a quien entra
		_en(r, "t_mu_polly", W - 0.5, D * 0.5, -PI * 0.5, 1.0, 0.0, false)
		_cuadro(r, "t_espejo_roto", W * 0.35, D - 0.09, PI, 1.0, 1.7)

## Cama de hierro con colchón mullido de bordes redondos, manta que cae por los lados con arrugas y almohada
## hinchada (antes eran cajas: parecían de Minecraft).
## Si el montaje a mano no pudo poner la cama (la sala es más pequeña que antes), se pone donde quepa.
func _cama_si_falta(r: Dictionary) -> void:
	if not (String(r.type) in ["dormitorio", "epicentro"]) or "vestidor" in String(r.name).to_lower() or "trofeos" in String(r.name).to_lower() or "tocador" in String(r.name).to_lower():
		return
	if String(r.name) == "Cuarto de Damián":
		return  # duerme en el colchón del suelo
	for c in _camas:
		if int(c.sala) == int(r.id):
			return
	if "padres" in String(r.name).to_lower() or "azul" in String(r.name).to_lower():
		var W: float = r.rect.size.x
		var D: float = r.rect.size.y
		_sin_ajuste = true
		for op in [[W * 0.5, 1.15, 0.0], [1.15, D * 0.5, PI * 0.5], [W - 1.15, D * 0.5, -PI * 0.5], [W * 0.65, 1.15, 0.0], [W * 0.35, 1.15, 0.0]]:
			if _en(r, "GothicBed_01", op[0], op[1], op[2]) != null:
				_sin_ajuste = false
				return
		_sin_ajuste = false
	_cama_donde_quepa(r)

func _banera_si_falta(r: Dictionary) -> void:
	if not String(r.name).begins_with("Baño"):
		return
	_banera_donde_quepa(r)

## Bañera de patas contra la pared más larga que quepa, lejos de la puerta.
## Prueba a poner un mueble contra cada pared (norte, oeste, este, sur) en varios puntos, de cara a la sala.
## `fondo` = distancia del centro del mueble a la pared. Devuelve el nodo o null.
func _donde_quepa(r: Dictionary, nombre: String, fondo: float, escala := 1.0) -> Node3D:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	var previo := _sin_ajuste
	_sin_ajuste = true
	var n: Node3D = null
	for t in [0.5, 0.3, 0.7, 0.18, 0.82]:
		for lado in 4:
			var op: Array = [[W * t, fondo, 0.0], [fondo, D * t, PI * 0.5], [W - fondo, D * t, -PI * 0.5], [W * t, D - fondo, PI]][lado]
			n = _en(r, nombre, op[0], op[1], op[2], escala)
			if n != null:
				_sin_ajuste = previo
				return n
	_sin_ajuste = previo
	return null

var _con_banera := {}
func _banera_donde_quepa(r: Dictionary) -> void:
	if _con_banera.has(int(r.id)):
		return
	if _donde_quepa(r, "bano_classic_bathtub", 0.48) != null:
		_con_banera[int(r.id)] = true

## Un dormitorio sin cama no es un dormitorio: cama de hierro con el cabecero contra la pared que quepa
## (norte, oeste, este, sur), lejos de las puertas.
func _cama_donde_quepa(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	var antes := _ocupado.size()
	_sin_ajuste = true
	for t in [0.5, 0.3, 0.7, 0.2, 0.8]:
		for lado in 4:
			var op: Array = [[W * t, 1.08, 0.0], [1.08, D * t, PI * 0.5], [W - 1.08, D * t, -PI * 0.5], [W * t, D - 1.08, PI]][lado]
			_cama_hierro(r, op[0], op[1], op[2])
			if _ocupado.size() > antes:
				_sin_ajuste = false
				return
	_sin_ajuste = false

func _cama_hierro(r: Dictionary, x: float, z: float, yaw: float, escala := 1.0) -> void:
	var n := _en(r, "old_bed_frame", x, z, yaw, escala)
	if n == null:
		return
	var c := n.global_position if n.is_inside_tree() else n.position
	var giro := Basis(Vector3.UP, yaw)
	var colchon := MeshInstance3D.new()
	colchon.mesh = _blando(Vector3(0.84 * escala, 0.17, 1.9 * escala), 0.06, 0.03, 0.006)
	colchon.material_override = m._mat.sabana
	colchon.transform = Transform3D(giro, c + Vector3(0, 0.5, 0))
	m._house.add_child(colchon)
	var manta := MeshInstance3D.new()
	manta.mesh = _manta(Vector2(1.02 * escala, 1.3 * escala), Vector2(0.84 * escala, 1.9 * escala), 0.62 * escala, c.x + c.z)
	if _mat_manta == null:
		_mat_manta = (m._mat.tela_roja as StandardMaterial3D).duplicate()
		_mat_manta.cull_mode = BaseMaterial3D.CULL_DISABLED
	manta.material_override = _mat_manta
	manta.transform = Transform3D(giro * Basis(Vector3.UP, 0.04), c + Vector3(0, 0.595, 0) + giro * Vector3(0, 0, 0.3 * escala))
	m._house.add_child(manta)
	var alm := MeshInstance3D.new()
	alm.mesh = _blando(Vector3(0.6 * escala, 0.13, 0.36 * escala), 0.06, 0.05, 0.008)
	alm.material_override = m._mat.sabana
	alm.transform = Transform3D(giro * Basis(Vector3.UP, 0.08) * Basis(Vector3.RIGHT, -0.12), c + Vector3(0, 0.66, 0) + giro * Vector3(0, 0, -0.72 * escala))
	m._house.add_child(alm)

var _blandos: Dictionary = {}
var _mat_manta: StandardMaterial3D
## Malla blanda (colchón, almohada, cojín): caja de bordes redondeados (radio), cara de arriba abombada y un poco
## de ruido para que no parezca perfecta.
func _blando(tam: Vector3, radio: float, abombado: float, ruido: float) -> ArrayMesh:
	var clave := "%s|%.3f|%.3f" % [tam, radio, abombado]
	if _blandos.has(clave):
		return _blandos[clave]
	var bm := BoxMesh.new()
	bm.size = tam
	bm.subdivide_width = 10
	bm.subdivide_height = 3
	bm.subdivide_depth = 14
	var arr := bm.surface_get_arrays(0)
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var h := tam * 0.5
	var nz := FastNoiseLite.new()
	nz.frequency = 6.0
	for i in vs.size():
		var v: Vector3 = vs[i]
		var dentro := Vector3(clampf(v.x, -h.x + radio, h.x - radio), clampf(v.y, -h.y + radio, h.y - radio), clampf(v.z, -h.z + radio, h.z - radio))
		var d := v - dentro
		if d.length() > 0.0001:
			v = dentro + d.normalized() * radio
		if v.y > 0.0:
			var fx := 1.0 - pow(v.x / h.x, 2.0)
			var fz := 1.0 - pow(v.z / h.z, 2.0)
			v.y += abombado * clampf(fx, 0.0, 1.0) * clampf(fz, 0.0, 1.0) * (v.y / h.y)
		v += Vector3(0, nz.get_noise_2d(v.x * 3.0, v.z * 3.0) * ruido, 0)
		vs[i] = v
	arr[Mesh.ARRAY_VERTEX] = vs
	var st := SurfaceTool.new()
	st.create_from_arrays(arr)
	st.generate_normals()
	st.generate_tangents()
	var am := st.commit()
	_blandos[clave] = am
	return am

## Manta: tela de «tam» sobre un colchón de «base» (ancho × largo); lo que sobra cae por los lados con pliegues.
func _manta(tam: Vector2, base: Vector2, caida: float, semilla: float) -> ArrayMesh:
	var pm := PlaneMesh.new()
	pm.size = tam + Vector2(caida, 0.0) * 0.0
	pm.size = Vector2(tam.x + caida * 0.7, tam.y + caida * 0.35)
	pm.subdivide_width = 24
	pm.subdivide_depth = 28
	var arr := pm.surface_get_arrays(0)
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nz := FastNoiseLite.new()
	nz.seed = int(semilla * 10.0)
	nz.frequency = 3.5
	var hx := base.x * 0.5
	for i in vs.size():
		var v: Vector3 = vs[i]
		var fuera := maxf(0.0, absf(v.x) - hx)
		# cae por el borde: se dobla hacia abajo y un poco hacia dentro
		if fuera > 0.0:
			v.y -= fuera * 0.95
			v.x = signf(v.x) * (hx + fuera * 0.25)
		var pie := maxf(0.0, v.z - (tam.y * 0.5 - 0.02))
		if pie > 0.0:
			v.y -= pie * 0.9
			v.z = tam.y * 0.5 + pie * 0.25
		# arrugas
		v.y += nz.get_noise_2d(v.x * 4.0, v.z * 4.0) * 0.022 + sin(v.x * 18.0 + v.z * 3.0) * 0.004
		vs[i] = v
	arr[Mesh.ARRAY_VERTEX] = vs
	var st := SurfaceTool.new()
	st.create_from_arrays(arr)
	st.generate_normals()
	st.generate_tangents()
	var am := st.commit()
	return am

## Despensa (7,2 × 7,2): baja la escalera al sótano por x 2,4-4,8; puerta al oeste (z 2,4-4,8).
func _despensa(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_en(r, "wine_barrel_01", W - 0.5, 0.6, 0.0, 0.9)
	_en(r, "wine_barrel_01", W - 0.5, 1.5, 0.7, 0.9)
	_en(r, "wooden_crate_02", W - 0.4, 3.3, 0.0)
	_en(r, "wooden_crate_01", W - 0.55, 4.6, 0.2)
	_en(r, "wicker_basket_02", W - 0.55, 4.6, 0.4, 1.0, 0.35, false)
	for k in 5:
		_en(r, "food_apple_01", W - 0.6 + (k % 2) * 0.08, 4.55 + k * 0.03, k, 1.0, 0.45, false)
	_en(r, "painted_wooden_cabinet_02", W - 0.38, 6.3, -PI * 0.5)
	_en(r, "painted_wooden_shelves", 0.25, 0.7, PI * 0.5)
	_en(r, "painted_wooden_shelves", 0.25, 1.3, PI * 0.5)
	_en(r, "coti_glass_bottle", 0.25, 0.6, 0.0, 1.0, 1.13, false)
	_en(r, "jug_01", 0.25, 0.85, 0.5, 1.0, 1.13, false)
	_en(r, "pot_enamel_01", 0.25, 1.3, 0.0, 1.0, 1.13, false)
	_en(r, "wooden_bucket_01", 0.45, 6.4, 0.3)
	_en(r, "wicker_basket_01", 1.2, 6.7, 1.0)
	_en(r, "yellow_onion", 1.15, 6.65, 0.0, 1.0, 0.06, false)
	_en(r, "street_rat", 1.7, 5.4, 0.9, 1.7, 0.0, false)
	_telas(r, [0, 1, 3])

## Antecocina (4,8 × 7,2): se cruza de oeste a este por z 2,4-4,8. Vajilla y la mesa de emplatar.
func _antecocina(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_en(r, "vintage_cabinet_01", 2.4, 0.38, 0.0)
	_en(r, "painted_wooden_table", 2.4, 6.3, 0.0, 0.8)
	_en(r, "tea_set_01", 2.1, 6.3, 0.2, 0.5, 0.77, false)
	_en(r, "carved_wooden_plate", 2.9, 6.2, 0.0, 1.0, 0.77, false)
	_en(r, "carved_wooden_plate", 3.1, 6.45, 0.0, 1.0, 0.79, false)
	_en(r, "coti_wine_bottle", 1.6, 6.4, 0.0, 1.0, 0.77, false)
	_en(r, "painted_wooden_stool", 3.9, 5.6, 0.4)
	_telas(r, [0, 1, 2, 3])

## Guardarropa (4,8 × 7,2): puertas al oeste y este (z 2,4-4,8); armario-escondite en (2,4; 6,0).
func _guardarropa(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_en(r, "GothicCabinet_01", 1.2, 0.6, 0.0)
	_en(r, "vintage_wooden_drawer_01", 3.5, 0.55, 0.0)
	_en(r, "vintage_suitcase", 3.5, 0.55, 0.3, 0.8, 1.09, false)
	_en(r, "painted_wooden_bench", 0.3, 5.6, PI * 0.5, 0.9)
	_en(r, "treasure_chest", W - 0.5, 5.9, -PI * 0.5, 0.8)
	_en(r, "vintage_suitcase", 1.4, 6.8, 0.1, 0.9)
	_telas(r, [0, 1, 2])

## Cuarto de servicio (7,2 × 9,6): puertas sur (x 2,4-4,8) y oeste (z 4,8-7,2); armario en (6,0; 6,0).
func _servicio(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_cama_hierro(r, 0.6, 1.3, 0.0, 0.9)
	_cama_hierro(r, 2.6, 1.3, 0.0, 0.9)
	_en(r, "painted_wooden_nightstand", 1.6, 0.35, 0.0)
	_en(r, "wooden_candlestick", 1.6, 0.35, 0.0, 1.0, 0.62, false)
	_en(r, "bano_washbasin_model", W - 0.3, 2.0, -PI * 0.5)
	_en(r, "painted_wooden_chair_01", 4.6, 2.6, 0.8)
	_en(r, "treasure_chest", W - 0.5, 8.8, -PI * 0.5, 0.75)
	_en(r, "wooden_broom", 0.3, 8.9, PI * 0.5, 1.0, 0.0, false)
	_en(r, "wooden_bucket_01", 0.6, 8.3, 0.2)
	_telas(r, [0, 1, 2, 3])

## Cuarto de plancha (7,2 × 7,2): una puerta al norte (x 2,4-4,8). Ropa por planchar y la estufa de los hierros.
func _plancha(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_en(r, "painted_wooden_table", 3.6, 4.0, 0.0, 0.9)
	_en(r, "wicker_basket_01", 3.2, 4.0, 0.3, 1.0, 0.86, false)
	_en(r, "wicker_basket_02", 4.1, 3.9, 0.8, 1.0, 0.86, false)
	_en(r, "pian_small_stove", W - 0.5, D - 0.5, 0.0, 1.0)
	_en(r, "wooden_bucket_02", 0.6, D - 0.6, 0.3)
	_en(r, "wooden_bucket_01", 1.4, D - 0.4, 0.8)
	_en(r, "painted_wooden_shelves", 0.25, 1.4, PI * 0.5)
	_en(r, "jug_01", 0.25, 1.4, 0.0, 1.0, 1.13, false)
	_en(r, "painted_wooden_stool", 2.4, 5.2, 0.5)
	_en(r, "wicker_basket_02", W - 0.6, 1.0, 0.2)
	_telas(r, [0, 1, 2, 3])

## Tubería de hierro a lo largo del techo (en coordenadas locales), con abrazaderas.
func _tuberia(r: Dictionary, x0: float, z0: float, x1: float, z1: float, alto := 3.55, grosor := 0.07) -> void:
	var rect: Rect2 = r.rect
	var a := Vector3(rect.position.x + x0, float(r.y) + alto, rect.position.y + z0)
	var b := Vector3(rect.position.x + x1, float(r.y) + alto, rect.position.y + z1)
	var t := m.cyl(grosor, grosor, a.distance_to(b), (a + b) * 0.5, m._mat.hierro, null, 8)
	t.rotation = Vector3(PI * 0.5, atan2(b.x - a.x, b.z - a.z), 0) if absf(b.z - a.z) > absf(b.x - a.x) else Vector3(0, 0, PI * 0.5)
	var n := int(a.distance_to(b) / 1.6)
	for i in n:
		var q := a.lerp(b, (i + 0.5) / n)
		m.box(Vector3(0.04, 0.45, 0.04), q + Vector3(0, 0.22, 0), m._mat.hierro, false, null, false)

## Pasillo del sótano (36 × 4,8): tuberías por el techo, barriles y cajas contra las paredes, faroles colgados.
## Viguetas de madera bajo el techo de tablas del sótano.
func _viguetas(r: Dictionary) -> void:
	var rect: Rect2 = r.rect
	var top := float(r.y) + ZarekMansion.WALL_H - 0.11
	var largo_x := rect.size.x >= rect.size.y
	var n := int((rect.size.y if largo_x else rect.size.x) / 0.9)
	for i in range(1, n):
		if largo_x:
			m.box(Vector3(rect.size.x - 0.2, 0.22, 0.14), Vector3(rect.get_center().x, top - 0.11, rect.position.y + rect.size.y * i / n), m._mat.madera, false, null, true)
		else:
			m.box(Vector3(0.14, 0.22, rect.size.y - 0.2), Vector3(rect.position.x + rect.size.x * i / n, top - 0.11, rect.get_center().y), m._mat.madera, false, null, true)

func _pasillo_sotano(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_viguetas(r)
	_tuberia(r, 0.4, 0.35, W - 0.4, 0.35)
	_tuberia(r, 0.4, 0.6, W - 0.4, 0.6, 3.4, 0.045)
	var x := 1.5
	var k := 0
	while x < W - 1.5:
		var rect: Rect2 = r.rect
		var pn := Vector3(rect.position.x + x, float(r.y), rect.position.y + 0.4)
		var ps := Vector3(rect.position.x + x, float(r.y), rect.position.y + D - 0.4)
		if m.door_near(pn, 1.8).is_empty():
			match k % 4:
				0: _en(r, "wine_barrel_01", x, 0.55, k * 0.7, 0.9)
				1: _en(r, "terr_old_and_dusty_multi_crate_st", x, 0.7, 0.0, 0.8)
				2: _en(r, "wooden_crate_02", x, 0.4, PI * 0.5)
				_: _en(r, "wooden_crate_01", x, 0.35, 0.2)
		if m.door_near(ps, 1.8).is_empty() and k % 2 == 1:
			_en(r, "wooden_crate_01", x + 0.6, D - 0.35, 0.3)
		if k % 3 == 0:
			_en(r, "wooden_lantern_01", x, 0.3, 0.0, 0.8, 2.2, false)
		x += 2.6
		k += 1
	_telas(r)

## Galería de servicio (14,4 × 12): taller y trastero; pasadizo al estudio en (4,8; 3,6); armario en (13,2; 1,2).
func _galeria_servicio(r: Dictionary) -> void:
	# ahora es el matadero de Damián (ZarekGore.matadero); se conservan las viguetas, la tubería y el armario
	var W: float = r.rect.size.x
	_viguetas(r)
	_tuberia(r, 0.4, 0.4, W - 0.4, 0.4)
	_en(r, "vintage_cabinet_01", W - 0.4, 6.0, -PI * 0.5)
	ZarekGore.matadero(m, r)

## Archivo (12 × 12): puertas norte y sur (x 4,8-7,2); armario en (1,2; 9,6). Papeles de la familia y de la mina.
func _archivo(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_viguetas(r)
	for z in [1.2, 3.1, 5.0]:
		_en(r, "vict_antique_wooden_bookcase___ga", 0.17, z, PI * 0.5)
	for z in [1.2, 3.1, 5.0, 6.9, 8.8, 10.7]:
		_en(r, "vict_antique_wooden_bookcase___ga", W - 0.17, z, -PI * 0.5)
	for x in [1.5, 3.4]:
		_en(r, "vintage_wooden_drawer_01", x, 0.5, 0.0, 0.9)
	for x in [8.8, 10.6]:
		_en(r, "vintage_wooden_drawer_01", x, 0.5, 0.0, 0.9)
	_en(r, "vict_antique_desk", 5.4, 6.4, 0.0)
	_en(r, "vict_antique_chair", 5.4, 5.7, 0.0)
	_en(r, "coti_typewriter", 5.2, 6.4, 0.1, 1.0, 0.8, false)
	_en(r, "vintage_oil_lamp", 5.9, 6.3, 0.0, 0.5, 0.8, false)
	_en(r, "vict_old_books___free_download", 4.8, 6.5, 0.6, 0.5, 0.8, false)
	_en(r, "terr_old_and_dusty_multi_crate_st", 2.6, D - 0.55, PI, 0.8)
	for q in [Vector2(3.2, 8.2), Vector2(8.0, 9.6), Vector2(7.2, 3.0)]:
		_en(r, "coti_12_old_books", q.x, q.y, q.x, 1.0, 0.0, false)
	_en(r, "terr_old_and_dusty_multi_crate_st", 9.5, D - 0.7, 0.0, 0.8)
	# mesa larga de clasificar papeles
	_en(r, "WoodenTable_03", 7.6, 8.4, PI * 0.5)
	_en(r, "WoodenTable_03", 7.6, 9.8, PI * 0.5)
	_en(r, "coti_simple_bookstack", 7.5, 8.2, 0.3, 0.8, 0.83, false)
	_en(r, "vict_old_books___free_download", 7.7, 9.6, 1.4, 0.5, 0.83, false)
	_en(r, "wooden_lantern_01", 7.6, 10.2, 0.0, 0.7, 0.83, false)
	_en(r, "wooden_crate_01", 6.6, 9.0, 0.1)
	_en(r, "folding_wooden_stool", 8.4, 8.9, 0.6)
	_telas(r)

## Sala de calderas (12 × 12): puerta al norte (x 4,8-7,2); armario en (9,6; 10,8). Caldera de carbón remachada.
func _calderas(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_viguetas(r)
	var rect: Rect2 = r.rect
	var c := Vector3(rect.position.x + 3.0, float(r.y), rect.position.y + 7.5)
	# cuerpo de la caldera, remaches, puerta del hogar con resplandor y chimenea al techo
	var cuerpo := m.cyl(1.05, 1.1, 2.2, c + Vector3(0, 1.1, 0), m._mat.hierro, null, 20)
	m.box(Vector3(2.4, 0.3, 2.4), c + Vector3(0, 0.15, 0), m._mat.cimiento, true)
	var col := m.box(Vector3(2.0, 2.2, 2.0), c + Vector3(0, 1.1, 0), m._mat.metal, true)
	col.visible = false
	col.set_meta("dyn", true)
	for k in 3:
		m.cyl(1.12, 1.12, 0.05, c + Vector3(0, 0.5 + k * 0.7, 0), m._mat.oscuro, null, 20)
	m.box(Vector3(0.6, 0.5, 0.1), c + Vector3(0, 0.7, 1.08), m._mat.oscuro, false)
	var brasa := m.box(Vector3(0.5, 0.06, 0.04), c + Vector3(0, 0.58, 1.12), m._mat.fuego, false, null, false)
	brasa.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var luz := OmniLight3D.new()
	luz.light_color = Color(1.0, 0.4, 0.12)
	luz.light_energy = 0.8
	luz.omni_range = 4.0
	luz.position = c + Vector3(0, 0.7, 1.5)
	m._house.add_child(luz)
	m.cyl(0.22, 0.22, 1.4, c + Vector3(0, 2.9, 0), m._mat.hierro, null, 12)
	_tuberia(r, 3.0, 7.5, 3.0, 0.4, 3.6, 0.1)
	_tuberia(r, 3.0, 0.5, W - 0.4, 0.5, 3.6, 0.1)
	# montón de carbón y herramientas
	var carbon := m._plain(Color(0.04, 0.04, 0.045), 0.6, 0.1)
	for k in 7:
		var piedra := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.5 - k * 0.05
		sm.height = 0.5 - k * 0.04
		piedra.mesh = sm
		piedra.material_override = carbon
		piedra.position = Vector3(rect.position.x + 1.0 + (k % 3) * 0.4, float(r.y) + 0.1, rect.position.y + D - 1.2 - (k / 3) * 0.4)
		piedra.scale = Vector3(1.4, 1.0, 1.2)
		m._house.add_child(piedra)
	_en(r, "rusted_spade_01", 2.4, D - 0.5, 0.4, 1.0, 0.0, false)
	_en(r, "wooden_bucket_02", 2.8, D - 1.6, 0.3)
	_en(r, "wooden_bucket_01", 0.5, 4.4, 0.0)
	_en(r, "WoodenTable_03", W - 0.4, 3.5, -PI * 0.5)
	_en(r, "wooden_lantern_01", W - 0.4, 3.3, 0.0, 0.7, 0.83, false)
	_en(r, "Lantern_01", W - 0.4, 3.8, 0.0, 1.0, 0.83, false)
	_en(r, "pian_old_stove", 8.0, 0.4, 0.0, 1.2)
	_telas(r)
	# la jaula oxidada y la cuna de hierro: aquí abajo encerraron a Elena las últimas semanas
	_jaula(r, W - 1.7, D - 1.7)
	_ensuciar(_en(r, "t_cuna_madera", W - 4.4, D - 0.8, PI, 1.0), Color(0.45, 0.3, 0.22))

## Jaula de barrotes oxidados (1,6 × 1,6 × 1,9 m) con la puerta abierta.
func _jaula(r: Dictionary, x: float, z: float) -> void:
	var c := Vector3(r.rect.position.x + x, float(r.y), r.rect.position.y + z)
	var oxido: StandardMaterial3D = m._mat.get("oxido", null)
	if oxido == null:
		oxido = StandardMaterial3D.new()
		oxido.albedo_color = Color(0.32, 0.17, 0.09)
		oxido.roughness = 0.85
		oxido.metallic = 0.6
		m._mat["oxido"] = oxido
	var L := 1.6
	var H := 1.9
	for lado in 4:
		for k in 9:
			var u := -L * 0.5 + k * L / 8.0
			if lado == 3 and k > 2 and k < 6:
				continue  # la puerta, abierta
			var p := Vector3(u, H * 0.5, -L * 0.5) if lado == 0 else (Vector3(u, H * 0.5, L * 0.5) if lado == 1 else (Vector3(-L * 0.5, H * 0.5, u) if lado == 2 else Vector3(L * 0.5, H * 0.5, u)))
			m.box(Vector3(0.025, H, 0.025), c + p, oxido, false, m._house, true)
	for hy in [0.05, H * 0.5, H]:
		for s in [-1.0, 1.0]:
			m.box(Vector3(L, 0.04, 0.04), c + Vector3(0, hy, s * L * 0.5), oxido, false, m._house, false)
			m.box(Vector3(0.04, 0.04, L), c + Vector3(s * L * 0.5, hy, 0), oxido, false, m._house, false)
	m.box(Vector3(L, 0.03, L), c + Vector3(0, H, 0), oxido, false, m._house, false)
	# la puerta de la jaula, abierta hacia fuera
	var puerta := Node3D.new()
	m._house.add_child(puerta)
	puerta.position = c + Vector3(L * 0.5, 0, -L * 0.2)
	puerta.rotation.y = 1.9
	for k in 4:
		m.box(Vector3(0.025, H * 0.95, 0.025), Vector3(0, H * 0.48, k * 0.2), oxido, false, puerta, false)
	# colisión de la jaula entera (tres paredes)
	var cuerpo := StaticBody3D.new()
	m._house.add_child(cuerpo)
	cuerpo.position = c + Vector3(0, H * 0.5, 0)
	for q in [[Vector3(L, H, 0.06), Vector3(0, 0, -L * 0.5)], [Vector3(L, H, 0.06), Vector3(0, 0, L * 0.5)], [Vector3(0.06, H, L), Vector3(-L * 0.5, 0, 0)]]:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = q[0]
		cs.shape = bs
		cs.position = q[1]
		cuerpo.add_child(cs)
	_ocupar(c, Vector3(L + 0.3, H, L + 0.3))
	# una manta sucia y un cuenco dentro
	_en(r, "wooden_bowl_01", x - 0.3, z + 0.2, 0.0, 1.0, 0.0, false)

## Capilla de la madre (sótano, 14,4 × 12 m): puerta al norte (x 2,4-4,8, desde la cava). Bancos de iglesia a los
## lados, el altar con el tríptico al sur bajo un crucifijo, el sarcófago del fundador y, en el centro, el círculo
## del ritual pintado en el suelo (lo pone ZarekTerror).
func _capilla(r: Dictionary) -> void:
	# la capilla de la familia, con el fondo convertido en la celda donde Damián tiene encadenada a su madre
	var W: float = r.rect.size.x
	_cuadro(r, "obj_withered_wooden_crucifix", W * 0.5, 0.09, 0.0, 1.6, 2.7)
	_en(r, "obj_bible_on_stand", 1.4, 1.4, 0.4)
	var filas := [2.4, 4.0, 5.6]
	for i in filas.size():
		for lado in [0, 1]:
			var bx: float = 2.3 if lado == 0 else W - 2.3
			var b := _en(r, "t_banco_iglesia", bx, filas[i], PI)
			if b and i == 1 and lado == 1:
				b.rotation.y += 0.5
			if b and i == 2 and lado == 0:
				_tumbar(b)
	for esq in [Vector2(0.4, 0.4), Vector2(W - 0.4, 0.4)]:
		_en(r, "terr_cobwebs", esq.x, esq.y, atan2(W * 0.5 - esq.x, 6.0 - esq.y), 0.9, ZarekMansion.WALL_H - 0.9, false)
	ZarekGore.celda_madre(m, r)

## Botellero de roble oscuro (1,6 m a lo largo de la pared, 2 m de alto) con botellas en cada balda.
func _botellero(r: Dictionary, x: float, z: float, en_pared_x: bool) -> void:
	var rect: Rect2 = r.rect
	var c := Vector3(rect.position.x + x, float(r.y), rect.position.y + z)
	var largo := Vector3(0, 0, 1) if en_pared_x else Vector3(1, 0, 0)
	var sz := Vector3(0.42, 0.04, 1.6) if en_pared_x else Vector3(1.6, 0.04, 0.42)
	var col := m.box(Vector3(0.42, 2.0, 1.6) if en_pared_x else Vector3(1.6, 2.0, 0.42), c + Vector3(0, 1.0, 0), m._mat.madera, true)
	col.visible = false
	col.set_meta("dyn", true)
	for k in 6:
		m.box(sz, c + Vector3(0, 0.12 + k * 0.36, 0), m._mat.madera, false, null, true)
	for sgn in [-1.0, 0.0, 1.0]:
		var lat := Vector3(0.42, 2.0, 0.05) if en_pared_x else Vector3(0.05, 2.0, 0.42)
		m.box(lat, c + largo * sgn * 0.78 + Vector3(0, 1.0, 0), m._mat.madera, false, null, true)
	# botellas de vidrio sueltas en las cuatro baldas de abajo: cada una distinta y rompible
	for k in 4:
		for sgn in [-0.4, 0.4]:
			for j in 3:
				if rng.randf() < 0.18:
					continue
				var b := ZarekBotella.azar(rng)
				b.position = c + largo * (sgn + (j - 1) * 0.2) + Vector3(0, 0.143 + k * 0.36, 0)
				b.rotation.y = rng.randf() * TAU
				m._house.add_child(b)
				b.sleeping = true

## Cava de vinos (12 × 14,4): puerta al norte (x 4,8-7,2); sello 3 en (3,6; 3,6) libre; sube la escalera de la despensa.
func _cava(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_viguetas(r)
	for z in [1.4, 3.4, 5.4, 7.4, 9.4, 11.4]:
		_botellero(r, W - 0.3, z, true)
	for z in [6.2, 8.2, 10.2, 12.2]:
		_botellero(r, 0.3, z, true)
	_en(r, "wooden_barrels_01", 3.0, D - 1.9, 0.0, 0.7)
	_en(r, "wine_barrel_01", 1.0, 1.0, 0.0)
	_en(r, "wine_barrel_01", 1.0, 1.9, 0.6)
	_en(r, "wine_barrel_01", 1.0, 1.45, 0.3, 1.0, 0.85, false)
	_en(r, "vict_small_antique_table_asset", 8.4, 1.3, 0.2, 0.7)
	_en(r, "coti_wine_bottle", 8.3, 1.3, 0.0, 1.0, 0.27, false)
	_en(r, "brass_goblets", 8.5, 1.25, 0.6, 0.7, 0.27, false)
	var caida := _en(r, "coti_wine_bottle", 6.4, 4.6, 0.8, 1.0, 0.04, false)
	if caida:
		caida.rotation.z = PI * 0.5
	_en(r, "street_rat", 8.0, 9.0, 2.1, 1.7, 0.0, false)
	_telas(r)

## Mueble tapado con una sábana polvorienta (la forma se adivina debajo).
func _tapado(r: Dictionary, nombre: String, x: float, z: float, yaw: float, escala := 1.0) -> void:
	var n := _en(r, nombre, x, z, yaw, escala)
	if n == null:
		return
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = m._mat.sabana

## Estructura de cubierta del ático: pies derechos, tirantes y jabalcones de madera vieja.
func _cerchas(r: Dictionary) -> void:
	var rect: Rect2 = r.rect
	var y := float(r.y)
	var alto := 3.25
	var x := 1.8
	while x < rect.size.x - 1.0:
		var cx := rect.position.x + x
		m.box(Vector3(0.22, 0.24, rect.size.y - 0.2), Vector3(cx, y + alto - 0.12, rect.get_center().y), m._mat.madera, false, null, true)
		for zz in [rect.size.y * 0.3, rect.size.y * 0.7]:
			var cz: float = rect.position.y + zz
			m.box(Vector3(0.2, alto - 0.24, 0.2), Vector3(cx, y + (alto - 0.24) * 0.5, cz), m._mat.madera, true, null, true)
			for sgn in [-1.0, 1.0]:
				var j := m.box(Vector3(0.12, 1.3, 0.12), Vector3(cx, y + alto - 0.75, cz + sgn * 0.42), m._mat.madera, false, null, true)
				j.rotation.x = sgn * 0.6
		x += 3.6

## Ático (36 × 24): vigas, baúles, muebles tapados, cuadros apoyados contra la pared y juguetes viejos.
## Escalera de servicio en (30; 15,6), armarios en (14,4; 22,8) y (32,4; 2,4); el diario de Elena en (6; 4,8).
func _atico(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_cerchas(r)
	var tapados := [["GothicCabinet_01", 12.0, 3.0, 0.4], ["Sofa_01", 16.5, 6.0, 1.9], ["ArmChair_01", 18.4, 4.6, 2.6], ["GothicCommode_01", 22.0, 1.0, 0.0],
		["vintage_cabinet_01", 26.0, 8.0, 1.2], ["dining_table", 14.0, 11.5, 0.2], ["ArmChair_01", 20.5, 12.4, -0.8], ["GothicBed_01", 8.0, 15.5, 1.57],
		["vict_victorian_lounge_sofa", 24.0, 17.0, 0.3], ["Rockingchair_01", 5.0, 20.5, 2.2], ["vict_dusty_antique_mirror__free", 33.5, 9.0, -1.2]]
	for t in tapados:
		_tapado(r, t[0], t[1], t[2], t[3])
	# baúles, maletas y cajas
	for q in [[2.0, 9.5, 0.3], [34.4, 13.0, -1.3]]:
		_en(r, "treasure_chest", q[0], q[1], q[2], 0.9)
	for q in [[3.4, 12.2, 1.2], [27.6, 3.0, 0.2], [11.0, 20.8, 0.5], [6.5, 4.0, -0.4]]:
		_baul_abierto(r, q[0], q[1], q[2])
	for q in [[3.0, 13.5, 0.4], [28.6, 3.6, 1.1], [17.0, 20.0, 0.2]]:
		_en(r, "vintage_suitcase", q[0], q[1], q[2])
	for q in [[33.5, 20.5, 0.0], [34.4, 18.8, 0.6], [9.6, 22.6, 0.3], [21.0, 22.8, 0.0]]:
		_en(r, "terr_old_and_dusty_multi_crate_st", q[0], q[1], q[2], 0.8)
	# juguetes de los niños, olvidados
	_en(r, "ropa_mannequin_1900s_m_size", 13.0, 16.0, 2.6)
	_en(r, "t_maniqui_1900", 14.2, 16.6, 2.2)
	_en(r, "t_maniqui_1900", 30.0, 12.0, -2.0)
	_en(r, "t_mu_polly", 2.0, 9.5, PI * 0.5, 1.0, 0.62, false)
	_en(r, "t_cuna_madera", 22.0, 20.5, 0.4, 0.95)
	_en(r, "obj_birdcage_2", 10.4, 18.4, 0.8)
	_en(r, "Ottoman_01", 19.0, 15.0, 0.4)
	# cuadros apoyados contra las paredes, de cara a la pared alguno
	for q in [[0.35, 6.0, PI * 0.5], [0.35, 7.1, PI * 0.5], [W - 0.35, 5.0, -PI * 0.5], [17.0, D - 0.35, PI], [18.2, D - 0.35, 0.0]]:
		var aq := _ajustar(r, q[0], q[1])
		var cu := m._prop("fancy_picture_frame_02", Vector3(r.rect.position.x + aq.x, float(r.y), r.rect.position.y + aq.y), q[2], 1.6, false)
		if cu:
			cu.rotation.x = -0.2
	_en(r, "terr_creepy_lady_bust_statue_scan", 25.0, 12.0, 2.0)
	_en(r, "coti_simple_bookstack", 23.0, 10.4, 0.4)
	_en(r, "vict_old_books___free_download", 7.0, 9.0, 1.0, 0.8)
	_en(r, "wooden_lantern_01", 12.6, 11.2, 0.0, 0.8)
	for x in [2.0, 9.0, 16.0, 23.0, 30.0]:
		for z in [0.5, D - 0.5]:
			_en(r, "terr_cobwebs", x, z, 0.0 if z < 1.0 else PI, 1.2, 2.4, false)

## Escondite de Damián niño (en el ático, 7,2 × 4,8): donde se escondía a escribir. El diario va en el centro.
func _rincon_elena(r: Dictionary) -> void:
	_cama_hierro(r, 1.2, 2.4, PI * 0.5, 0.8)
	_en(r, "small_wooden_table_01", 5.0, 1.0, 0.0, 0.8)
	_en(r, "coti_three_candles_and_a_golden_c", 4.8, 1.0, 0.0, 0.9, 0.43, false)
	_en(r, "jugu_music_box_prop", 5.3, 1.05, 0.4, 1.0, 0.43, false)
	_en(r, "ornate_mirror_01", 6.8, 3.6, -PI * 0.5 + 0.3, 1.0)
	_en(r, "painted_wooden_stool", 5.0, 1.8, 0.3)

## Torre (planta baja y primer piso, 7,2 × 7,2): escalera de caracol en el centro.
func _torre(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	if int(r.level) == 0:
		_en(r, "vict_victorian_armchair", 1.0, 1.0, 0.7)
		_en(r, "side_table_tall_01", 1.9, 0.6, 0.0)
		_en(r, "wooden_candlestick", 1.9, 0.6, 0.0, 1.0, 0.76, false)
		_en(r, "coti_celestial_globe", 1.0, D - 1.0, 0.3)
		_en(r, "vict_antique_wooden_bookcase___ga", 3.6, D - 0.17, PI)
	else:
		_en(r, "vict_antique_desk", 1.1, 3.6, PI * 0.5)
		_en(r, "vict_antique_chair", 1.8, 3.6, -PI * 0.5)
		_en(r, "obj_military_telescope", 1.1, 3.4, PI * 0.5, 1.0, 0.8, false)
		_en(r, "vintage_suitcase", W - 1.0, D - 0.6, 0.4)
	_telas(r)

## Mirador de la torre (7,2 × 7,2, ático): se ve todo el bosque. Escalera de caracol en el centro.
func _mirador(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_en(r, "Rockingchair_01", 1.2, 1.2, 0.8)
	_en(r, "small_wooden_table_01", 1.2, D - 0.8, 0.3, 0.8)
	_en(r, "vintage_oil_lamp", 1.2, D - 0.8, 0.0, 0.5, 0.43, false)
	_en(r, "magnifying_glass_01", 1.4, D - 0.7, 0.3, 1.0, 0.43, false)
	_en(r, "vict_antique_chair", W - 1.0, 1.0, -0.7)
	_telas(r)

## Grupo de sala para elegir qué objetos van en ella.
func _grupo(r: Dictionary) -> String:
	var t := _tipo(r)
	match t:
		"salon", "vestibulo", "musica", "baile", "billar", "comedor", "pasillo": return "salon"
		"dormitorio", "tocador", "ninos", "costura", "bano": return "dormitorio"
		"cocina", "despensa", "servicio": return "cocina"
		"biblioteca", "estudio", "archivo": return "biblioteca"
		"sotano", "cava", "calderas": return "sotano"
		"atico": return "atico"
	if String(r.type) in ["tunel", "roca"]:
		return "tunel"
	return "salon"

## Relleno ordenado: cada mueble con tapa recibe una composición pensada para él (simétrica en consolas,
## de trabajo en escritorios, de noche en mesillas…), cada tramo libre de pared un cuadro centrado con apliques
## a los lados, y el suelo solo lo que tiene sentido (leña junto a la chimenea, libros junto a las estanterías).
func _relleno(r: Dictionary) -> void:
	if String(r.name) == "Capilla de la madre":
		return
	var g := _grupo(r)
	if g != "tunel":
		# las salas amuebladas a mano ya tienen sus muebles grandes: el relleno de paredes ponía otra bañera u
		# otro lavabo pegado al suyo
		if not String(r.name) in ZarekMansion.SALAS_A_MANO:
			_paredes(r, g)
		_suelo_con_sentido(r, g)
		_ropa(r, g)
		for sf in _superficies:
			if sf.sala == r.id and int(sf.n) == 0:
				_componer(r, sf)
	_restos(r, g)

## Variantes de cada clase de objeto (se amplían con los modelos nuevos que existan).
const VARIANTES := {
	"vela": ["wooden_candlestick", "obj_candlestick", "obj_candlestick_2", "obj_candle_holder", "obj_old_brass_candle_holder", "obj_ornate_antique_candlestick"],
	"candelabro": ["brass_candleholders", "coti_three_candles_and_a_golden_c", "pian_candelabra", "obj_old_candelabra"],
	"reloj": ["mantel_clock_01", "vict_torsion_pendulum_clock___ani", "obj_antique_clock"],
	"jarron": ["ceramic_vase_01", "ceramic_vase_02", "antique_ceramic_vase_01", "brass_vase_01", "brass_vase_02", "obj_japan_porcelain_vase", "obj_floral_vase", "obj_cracked_porcelain_vase", "obj_thai_jar_c_1000_bce", "obj_antique_vase"],
	"jarron_peq": ["brass_vase_03", "ceramic_vase_03", "obj_flower_vase", "obj_antique_vase_s5139506"],
	"libros": ["vict_old_books___free_download", "coti_simple_bookstack", "coti_shabby_books", "obj_old_books", "obj_old_books_sketchfab_weekly", "obj_book_stack", "obj_stack_of_old_books"],
	"libro": ["obj_old_book", "obj_old_book_2", "obj_old_book_3", "obj_old_book_4", "obj_old_book_5", "obj_old_bible", "obj_museums_old_book_1767"],
	"lampara": ["vintage_oil_lamp", "obj_kerosene_lamp", "obj_kerosene_lamp_2", "obj_oil_lamp", "obj_old_lantern"],
	"busto": ["marble_bust_01", "terr_creepy_lady_bust_statue_scan"],
	"curiosidad": ["obj_armillary_sphere", "obj_globe", "obj_antique_globe", "obj_hourglass", "obj_hourglass_2", "obj_hour_glass", "obj_birdcage_2", "obj_military_telescope"],
	"perfume": ["coti_small_bottle", "obj_oriental_perfume_bottle", "obj_porcelain_perfume_bottle", "obj_perfume_bottle", "obj_perfume_bottle_with_a_landsc", "obj_perfume_bottle_with_floral_d", "obj_perfume_bottles_with_floral_"],
	"joyero": ["jugu_music_box_prop", "obj_old_jewelry_box", "obj_art_of_chokin_vintage_piano_"],
	"cepillo": ["round_spectacles", "obj_pocket_watch", "obj_old_pocket_watch", "obj_pocket_watch_model"],
	"te": ["tea_set_01", "vict_cup___saucer", "obj_tea_set", "obj_tea_set_01_4k", "obj_elegant_victorian_porcelan_t", "obj_teapot_2", "obj_cup_and_plate"],
	"taza": ["vict_cup___saucer", "obj_cup_and_plate"],
	"escribir": ["obj_inkwell_from_bell_rock_light", "obj_quill", "vintage_pocket_watch", "magnifying_glass_01", "round_spectacles", "obj_fountain_pens", "obj_seal_and_letter"],
	"carta": ["obj_envelope", "obj_scroll", "obj_scroll_2", "obj_old_map_3d_model", "obj_old_book_4"],
	"cuenco": ["wooden_bowl_01", "wooden_bowl_02", "obj_wooden_plate"],
	"jarra": ["jug_01", "metal_jug", "obj_jar", "obj_brocal_quadra_jar"],
	"olla": ["pot_enamel_01", "brass_pot_01", "brass_pot_02", "coci_vintage_kettle", "obj_polished_tea_kettle", "obj_teapot_weathered_metal_teapo", "obj_old_soviet_teapot", "obj_teapot"],
	"comida": ["coti_bread_in_basket", "food_apple_01", "yellow_onion", "lemon", "sweet_potato", "obj_cereal_bread", "obj_garlic", "obj_garlic_game_ready_2k_pbr"],
	"utensilio": ["obj_classic_coffee_grinder", "obj_coffee_grinder_pbr", "obj_wooden_rolling_pin", "obj_meat_cleaver", "obj_medieval_cutlery", "obj_samovar"],
	"farol": ["wooden_lantern_01", "Lantern_01", "obj_miners_oil_lamp", "obj_old_lantern"],
	"caja": ["obj_jewelry_box_2", "vintage_suitcase"],
	"juguete": ["obj_teddy_bear_2", "obj_wooden_toy_train", "obj_pecking_chicken_wooden_toy", "obj_craft_teddy_bear_photogramme"],
	"cuadro_peq": ["obj_fancy_picture_frame_01_freep", "obj_fancy_picture_frame_02_freep", "obj_hanging_picture_frame_freepo", "obj_biblical_scene_from_nurember", "obj_sir_isaac_newton_portrait_pa"],
	"religioso": ["obj_unending_torment", "obj_withered_wooden_crucifix", "obj_empty_cross"],
	"herramienta": ["obj_shovel", "obj_dirty_shovel", "obj_round_nosed_shovel", "obj_pickaxe"],
	"yunque": ["obj_anvil_nature_morte", "obj_asset02_medieval_anvil"],
	"saco": ["obj_sack_v1", "obj_sack_v2", "obj_photogrammetry_cloth_sack_wi"],
	"lena": ["obj_firewood", "obj_dry_firewood", "obj_firewood_hp"],
	"jaula": ["obj_birdcage", "obj_birdcage_3"],
	"perchero": ["obj_coat_rack", "obj_coat_rack_2", "obj_coat_rack_bowler_hat"],
	"botella": ["coti_wine_bottle", "coti_glass_bottle"],
	"complemento_m": ["ropa_bowler_hat", "ropa_leather_belt", "ropa_worn_leather_glove", "ropa_leather_bag", "obj_top_hat_2", "ropa_folded_newspaper"],
	"complemento_f": ["ropa_sunday_hat", "ropa_ladies_handbag_vol_1", "ropa_worn_leather_glove", "ropa_ribbon_ball"],
	"prenda_f": ["ropa_black_dress", "ropa_dress_plain2"],
	"prenda_m": ["ropa_1830s_frock_coat_unbuttoned", "ropa_a_fashionable_waistcoat", "ropa_heavy_worn_jacket", "ropa_victorian_vampire", "ropa_gray_sweater"],
	"zapatos_f": ["ropa_worn_vagabond_women_leather_", "ropa_photoscanned_female_ankle_bo", "ropa_worn_rieker_women_leather_sh", "ropa_coraline_riding_boot"],
	"zapatos_m": ["ropa_old_shoes", "ropa_old_dirty_boots", "ropa_kirza_boots", "ropa_shoes", "ropa_old_oxford_shoe", "ropa_dress_shoe_left", "ropa_boots"],
	"zapatos_n": ["ropa_party_shoe_for_girls"],
	"maniqui": ["ropa_1900_dress_form", "ropa_mannequin_1900s_m_size", "ropa_wedding_dress"],
}
## Pares que ya vienen dobles en el modelo (el resto de zapatos se ponen dos).
const PARES := ["ropa_old_shoes", "ropa_old_dirty_boots", "ropa_kirza_boots"]

## Elige una variante que exista (modelo cargable) de una clase de objeto.
func _var(clase: String) -> String:
	var lista: Array = VARIANTES.get(clase, [clase])
	var validas: Array = []
	for n in lista:
		var real := _real(n)
		if m._props_info.has(real) or ResourceLoader.exists("res://zarek/objetos/%s.glb" % real) or ResourceLoader.exists("res://zarek/muebles/%s.glb" % real):
			validas.append(n)
	if validas.is_empty():
		return ""
	return validas[rng.randi_range(0, validas.size() - 1)]

## Pone un objeto en la tapa de un mueble, en coordenadas del mueble: u a lo ancho (-1 izquierda … 1 derecha),
## v a lo hondo (-1 pegado a la pared … 1 borde delantero). Pequeña variación de giro y tamaño, y de color en
## cerámica y latón, para que dos objetos iguales nunca parezcan copiados.
func _sobre(sf: Dictionary, clase: String, u: float, v: float, giro := 0.0, forzar := "") -> Node3D:
	var nombre := forzar if forzar != "" else _var(clase)
	if nombre == "":
		return null
	var real := _real(nombre)
	var t := m._prop_size(real)
	var tam: Vector3 = sf.tam
	var yaw: float = sf.yaw
	var hu := maxf(tam.x * 0.5 - maxf(t.x, t.z) * 0.5 - 0.03, 0.0)
	var hv := maxf(tam.z * 0.5 - maxf(t.x, t.z) * 0.5 - 0.03, 0.0)
	if maxf(t.x, t.z) > minf(tam.x, tam.z) * 1.1:
		return null
	if t.y > 0.6 and float(sf.alto) > 1.6:
		return null
	var local := Vector3(u * hu, 0, v * hv)
	var p: Vector3 = sf.pos + local.rotated(Vector3.UP, yaw) + Vector3(0, float(sf.alto) + 0.004, 0)
	var esc := rng.randf_range(0.92, 1.06)
	var n := m._prop(real, p, yaw + giro + rng.randf_range(-0.12, 0.12), esc, false)
	if n and (real.contains("vase") or real.contains("brass") or real.contains("ceramic")) and rng.randf() < 0.7:
		m._tenir(n, Color(rng.randf_range(0.75, 1.05), rng.randf_range(0.7, 1.0), rng.randf_range(0.65, 1.0)))
	return n

## Composición según el mueble y la sala.
func _componer(r: Dictionary, sf: Dictionary) -> void:
	var nombre: String = sf.nombre
	var g: String = sf.grupo
	var alto: float = sf.alto
	if alto > 1.6:
		# encima de armarios y estanterías: cajas y algún jarrón, ordenados
		if rng.randf() < 0.6:
			_sobre(sf, "caja", -0.5, 0.0, 0.0)
			if rng.randf() < 0.5:
				_sobre(sf, "jarron_peq", 0.6, 0.0)
		return
	if nombre in ["vict_antique_desk", "vict_antique_wooden_desk"] or (nombre == "WoodenTable_03" and g == "biblioteca"):
		_sobre(sf, "lampara", -0.8, -0.6)
		_sobre(sf, "libros", 0.75, -0.55, PI * 0.5)
		# en el centro: o la máquina de escribir del estudio, o el papeleo del día
		if g == "biblioteca" and rng.randf() < 0.35 and _sobre(sf, "", 0.0, 0.1, 0.0, "obj_victorian_typewriter"):
			_sobre(sf, "carta", 0.55, 0.45, 0.3)
		else:
			_sobre(sf, "carta", 0.0, 0.4)
			_sobre(sf, "escribir", 0.45, 0.1)
		if rng.randf() < 0.6:
			_sobre(sf, "curiosidad" if rng.randf() < 0.5 else "libro", -0.35, 0.3, 0.4)
		return
	if nombre in ["ClassicNightstand_01", "painted_wooden_nightstand"]:
		_sobre(sf, "vela" if rng.randf() < 0.6 else "lampara", -0.4, -0.4)
		if _tipo(r) == "ninos":
			_sobre(sf, "juguete", 0.35, 0.2, PI)
			return
		_sobre(sf, "libro", 0.3, 0.3, 0.3)
		var mesilla: Array = ["taza", "cepillo", "jarron_peq", "escribir", "complemento_f" if _sexo(r) == "f" else "complemento_m"]
		if rng.randf() < 0.6:
			_sobre(sf, String(mesilla[rng.randi_range(0, mesilla.size() - 1)]), 0.45, -0.3)
		return
	if g == "dormitorio" and nombre in ["GothicCommode_01", "vintage_wooden_drawer_01", "painted_wooden_cabinet"]:
		# tocador: frascos en fila, joyero en medio, cepillo delante
		for k in 3:
			_sobre(sf, "perfume", -0.8 + k * 0.22, -0.5)
		_sobre(sf, "joyero", 0.0, -0.2)
		_sobre(sf, "cepillo" if rng.randf() < 0.5 else "complemento_f", 0.5, 0.4, 0.6)
		_sobre(sf, "vela", 0.85, -0.5)
		return
	if g == "cocina" and nombre in ["painted_wooden_table", "WoodenTable_03", "wooden_table_02", "round_wooden_table_01"]:
		# mesa de trabajo: lo que se estaba usando cuando se fueron
		_sobre(sf, "cuenco", -0.4, 0.0)
		_sobre(sf, "jarra", 0.45, -0.3)
		_sobre(sf, "comida", 0.1, 0.35)
		_sobre(sf, "olla", 0.75, 0.3)
		_sobre(sf, "utensilio", -0.75, 0.35, 0.3)
		if rng.randf() < 0.6:
			_sobre(sf, "comida", -0.1, -0.4)
		return
	if nombre in ["ClassicConsole_01", "GothicCommode_01", "vintage_wooden_drawer_01", "painted_wooden_cabinet", "painted_wooden_cabinet_02", "vintage_cabinet_01"]:
		# consola simétrica: pieza central y pareja de candelabros (la misma variante a ambos lados)
		var centros: Array = ["reloj", "busto", "jarron", "lampara", "curiosidad", "candelabro"]
		if g == "cocina":
			centros = ["olla", "jarra", "utensilio"]
		var centro: String = centros[rng.randi_range(0, centros.size() - 1)]
		_sobre(sf, centro, 0.0, -0.3)
		var par := _var("vela")
		if par != "":
			_sobre(sf, "vela", -0.75, -0.3, 0.0, par)
			_sobre(sf, "vela", 0.75, -0.3, 0.0, par)
		if rng.randf() < 0.5:
			_sobre(sf, "libro", 0.4, 0.45, 0.2)
		return
	if nombre in ["vict_victorian_coffee_table", "coffee_table_round_01", "gothic_coffee_table", "vict_small_antique_table_asset"]:
		match rng.randi_range(0, 3):
			0: _sobre(sf, "te", 0.0, 0.0)
			1:
				_sobre(sf, "libros", -0.3, 0.0, 0.5)
				_sobre(sf, "vela", 0.45, 0.0)
			2:
				_sobre(sf, "jarron_peq", 0.0, 0.0)
				_sobre(sf, "libro", 0.5, 0.3, 0.6)
			_:
				_sobre(sf, "taza", -0.35, 0.2)
				_sobre(sf, "", 0.3, -0.1, 0.4, "ropa_folded_newspaper")
		return
	if _tipo(r) == "costura" and alto < 1.1 and float(sf.tam.x) > 0.8:
		# mesa de costura: máquina en el centro, ovillos y perchas a los lados
		_sobre(sf, "", 0.0, -0.2, 0.0, "ropa_sewing_machine")
		_sobre(sf, "", -0.7, 0.3, 0.0, "ropa_ribbon_ball")
		_sobre(sf, "", -0.5, 0.45, 0.0, "ropa_ribbon_ball")
		_sobre(sf, "", 0.7, 0.3, 0.3, "ropa_hanger_pile")
		return
	if nombre in ["side_table_01", "side_table_tall_01", "small_wooden_table_01"]:
		var cosas: Array = ["jarron", "lampara", "vela", "libros", "busto", "curiosidad", "jaula", "candelabro"]
		if g == "dormitorio":
			cosas = ["jarron", "lampara", "vela", "joyero", "perfume", "libro"]
		_sobre(sf, String(cosas[rng.randi_range(0, cosas.size() - 1)]), 0.0, 0.0)
		return
	if nombre in ["treasure_chest", "wine_barrel_01", "terr_old_and_dusty_multi_crate_st"] and rng.randf() < 0.45:
		var sob: Array = ["farol", "lampara", "saco"] if g in ["sotano", "atico"] else ["libros", "caja", "farol"]
		_sobre(sf, String(sob[rng.randi_range(0, sob.size() - 1)]), 0.0, 0.0)

## Paredes: cada tramo libre (sin puertas, ventanas ni muebles altos delante) recibe un cuadro centrado;
## los tramos largos, un cuadro grande con dos apliques simétricos a los lados.
func _paredes(r: Dictionary, g: String) -> void:
	if g in ["sotano", "atico", "tunel"]:
		return
	var rect: Rect2 = r.rect
	var y := float(r.y)
	if DBG and _tipo(r) in ["cocina", "ninos"]: print("PAREDES ", r.name, " g=", g, " rect=", rect)
	for lado in 4:
		var horiz := lado < 2
		var largo := rect.size.x if horiz else rect.size.y
		var bloqueos: Array = []
		var paso := 0.2
		var t := 0.0
		while t <= largo:
			var lx := t if horiz else (0.0 if lado == 2 else rect.size.x)
			var lz := (0.0 if lado == 0 else rect.size.y) if horiz else t
			var pw := Vector3(rect.position.x + lx, y, rect.position.y + lz)
			var malo := not m.door_near(pw, 1.0).is_empty() or m.ventana_cerca(pw, 1.05) or not _pared_libre(pw, 0.7)
			for a in _altos:
				if a.grow(0.3).has_point(Vector2(pw.x, pw.z)):
					malo = true
			bloqueos.append(malo)
			t += paso
		# tramos libres continuos
		var i := 0
		while i < bloqueos.size():
			if bloqueos[i]:
				i += 1
				continue
			var j := i
			while j < bloqueos.size() and not bloqueos[j]:
				j += 1
			var a0 := i * paso
			var a1 := (j - 1) * paso
			var tramo := a1 - a0
			if DBG and _tipo(r) in ["cocina", "ninos"]: print("TRAMO ", r.name, " lado ", lado, " ", a0, "-", a1)
			if tramo >= 1.4:
				var mid := (a0 + a1) * 0.5
				var x := mid if horiz else (0.1 if lado == 2 else rect.size.x - 0.1)
				var z := (0.1 if lado == 0 else rect.size.y - 0.1) if horiz else mid
				var yaw: float = [0.0, PI, PI * 0.5, -PI * 0.5][lado]
				var grande := tramo >= 3.2
				if g == "cocina":
					# en cocina y despensa no se cuelgan cuadros: baldas con loza, botes y cacharros
					var tpc := _tipo(r)
					if tpc == "cocina" and not _crucifijo.has(-r.id - 1) and rng.randf() < 0.35:
						_crucifijo[-r.id - 1] = true
						_cuadro(r, "obj_wooden_cuckoo_clock", x, z, yaw, 1.0, 1.95)
					else:
						_estante(r, x, z, yaw, g)
						if grande:
							var off2 := minf(tramo * 0.5 - 0.6, 1.2)
							_estante(r, (mid + off2) if horiz else x, z if horiz else (mid + off2), yaw, g)
					i = j
					continue
				var marco := "fancy_picture_frame_02" if rng.randf() < 0.5 else "fancy_picture_frame_01"
				var esc := 1.8 if grande else 1.2
				var cy := 1.75 if grande else 1.85
				var tp := _tipo(r)
				if not grande:
					# tramos cortos: cada sala cuelga lo suyo, y nunca dos salas igual
					var tira := rng.randf()
					if tp in ["dormitorio"] and not _crucifijo.has(r.id) and tira < 0.45:
						marco = _var("religioso"); esc = 1.0; cy = 1.95
						_crucifijo[r.id] = true
					elif tp in ["biblioteca", "estudio", "billar"] and tira < 0.3:
						marco = "obj_deerhead"; esc = 1.0; cy = 2.0
					elif tp in ["cocina", "comedor", "servicio"] and tira < 0.3 and not _crucifijo.has(-r.id - 1):
						marco = "obj_wooden_cuckoo_clock"; esc = 1.0; cy = 1.95
						_crucifijo[-r.id - 1] = true
					elif g == "dormitorio" and tira < 0.3:
						marco = "ornate_mirror_01"
					elif tira < 0.75:
						marco = _var("cuadro_peq")
						esc = 1.0 if marco.contains("hanging") or marco.contains("newton") or marco.contains("biblical") else 1.35
				if marco == "":
					marco = "fancy_picture_frame_01"
				# composición clásica: un mueble contra la pared y el cuadro encima, centrado
				var bajo := _mueble_bajo(r, tp, x, z, yaw, tramo)
				if bajo > 1.0:
					cy = maxf(cy, bajo + 0.75)
					if marco.begins_with("fancy_picture_frame_0") and not marco.begins_with("obj_"):
						esc = minf(esc, 1.2)
				_cuadro(r, marco, x, z, yaw, esc, cy)
				if grande and bajo > 0.0 and tp in ["salon", "pasillo", "vestibulo", "baile", "comedor", "musica"] and rng.randf() < 0.6:
					# dos sillas iguales a los lados del mueble
					var silla := "vict_antique_chair" if rng.randf() < 0.5 else "painted_wooden_chair_01"
					var offs := minf(tramo * 0.5 - 0.5, 1.25)
					var dentro2 := Vector3(0, 0, 1).rotated(Vector3.UP, yaw)
					for sgn in [-1.0, 1.0]:
						var sx: float = (mid + sgn * offs) if horiz else x
						var sz: float = z if horiz else (mid + sgn * offs)
						var sc := Vector3(r.rect.position.x + sx, float(r.y), r.rect.position.y + sz) + dentro2 * 0.35
						if _libre(sc, Vector3(0.55, 1.0, 0.55), r.rect.grow(0.3)):
							_en(r, silla, sx + dentro2.x * 0.35, sz + dentro2.z * 0.35, yaw, 1.0)
				if grande and g != "cocina":
					var off := minf(tramo * 0.5 - 0.35, 1.3)
					for sgn in [-1.0, 1.0]:
						var ax: float = (mid + sgn * off) if horiz else x
						var az: float = z if horiz else (mid + sgn * off)
						_aplique(r, ax, az, yaw, false)
			i = j

var _m_porcelana: StandardMaterial3D
var _m_plata: StandardMaterial3D
var _m_copa: StandardMaterial3D
func _mats_mesa() -> void:
	if _m_porcelana:
		return
	_m_porcelana = StandardMaterial3D.new()
	_m_porcelana.albedo_color = Color(0.93, 0.91, 0.86)
	_m_porcelana.roughness = 0.2
	_m_porcelana.clearcoat_enabled = true
	_m_plata = StandardMaterial3D.new()
	_m_plata.albedo_color = Color(0.72, 0.7, 0.66)
	_m_plata.metallic = 1.0
	_m_plata.roughness = 0.32
	_m_copa = StandardMaterial3D.new()
	_m_copa.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_m_copa.albedo_color = Color(0.85, 0.9, 0.95, 0.16)
	_m_copa.roughness = 0.15
	_m_copa.metallic_specular = 1.0
	_m_copa.rim_enabled = true
	_m_copa.rim = 0.6
	_m_copa.cull_mode = BaseMaterial3D.CULL_DISABLED

## Mantel de hilo: tapa y faldones que caen por los cuatro lados.
func _mantel(c: Vector3, tam: Vector2) -> void:
	var caida := 0.32
	m.box(Vector3(tam.x, 0.006, tam.y), c + Vector3(0, 0.003, 0), m._mat.sabana, false, null, false)
	for sgn in [-1.0, 1.0]:
		m.box(Vector3(tam.x, caida, 0.008), c + Vector3(0, -caida * 0.5, sgn * tam.y * 0.5), m._mat.sabana, false, null, false)
		m.box(Vector3(0.008, caida, tam.y), c + Vector3(sgn * tam.x * 0.5, -caida * 0.5, 0), m._mat.sabana, false, null, false)

## Un cubierto completo: bajoplato dorado, plato de porcelana, tenedor a la izquierda, cuchillo y cuchara a la derecha,
## servilleta doblada, copa de vino y vaso de agua de cristal. «hacia» apunta del comensal al centro de la mesa.
func _cubierto(p: Vector3, hacia: Vector3) -> void:
	_mats_mesa()
	var der := Vector3(-hacia.z, 0, hacia.x)
	var yaw := atan2(hacia.x, hacia.z)
	m.cyl(0.155, 0.155, 0.008, p + Vector3(0, 0.004, 0), m._mat.oro, null, 24)
	m.cyl(0.125, 0.1, 0.018, p + Vector3(0, 0.017, 0), _m_porcelana, null, 24)
	if rng.randf() < 0.5:
		m.cyl(0.085, 0.07, 0.03, p + Vector3(0, 0.041, 0), _m_porcelana, null, 20)
	for piezas in [[-0.19, 0.17, 0.016], [0.19, 0.2, 0.014], [0.235, 0.17, 0.02]]:
		var b := m.box(Vector3(float(piezas[2]), 0.005, float(piezas[1])), p + der * float(piezas[0]) + Vector3(0, 0.003, 0), _m_plata, false, null, false)
		b.rotation.y = yaw
	var serv := m.box(Vector3(0.11, 0.03, 0.15), p - der * 0.31 + Vector3(0, 0.015, 0), m._mat.sabana, false, null, false)
	serv.rotation.y = yaw + rng.randf_range(-0.1, 0.1)
	for vaso in [[0.17, 0.2, true], [0.06, 0.24, false]]:
		var q: Vector3 = p + der * float(vaso[0]) + hacia * float(vaso[1])
		var piezas_copa: Array[MeshInstance3D] = []
		if vaso[2]:
			piezas_copa.append(m.cyl(0.032, 0.034, 0.004, q + Vector3(0, 0.002, 0), _m_copa, null, 16))
			piezas_copa.append(m.cyl(0.004, 0.004, 0.085, q + Vector3(0, 0.046, 0), _m_copa, null, 8))
			piezas_copa.append(m.cyl(0.036, 0.022, 0.075, q + Vector3(0, 0.125, 0), _m_copa, null, 16))
		else:
			piezas_copa.append(m.cyl(0.034, 0.03, 0.1, q + Vector3(0, 0.05, 0), _m_copa, null, 16))
		for pc in piezas_copa:
			pc.set_meta("dyn", true)
			pc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## Baúl abierto del ático: caja de madera con flejes de hierro, tapa levantada y cosas dentro.
func _baul_abierto(r: Dictionary, x: float, z: float, yaw: float) -> void:
	var c := Vector3(r.rect.position.x + x, float(r.y), r.rect.position.y + z)
	var tam := Vector3(0.95, 0.5, 0.55)
	if m._huella_en_escalera(c, tam, yaw):
		return
	_ocupar(c, tam)
	var n := Node3D.new()
	n.position = c
	n.rotation.y = yaw
	m._house.add_child(n)
	var mad: Material = m._mat.madera
	m.box(Vector3(tam.x, 0.04, tam.z), Vector3(0, 0.06, 0), mad, false, n)
	m.box(Vector3(tam.x, tam.y, 0.035), Vector3(0, tam.y * 0.5, -tam.z * 0.5), mad, true, n)
	m.box(Vector3(tam.x, tam.y, 0.035), Vector3(0, tam.y * 0.5, tam.z * 0.5), mad, true, n)
	m.box(Vector3(0.035, tam.y, tam.z), Vector3(-tam.x * 0.5, tam.y * 0.5, 0), mad, true, n)
	m.box(Vector3(0.035, tam.y, tam.z), Vector3(tam.x * 0.5, tam.y * 0.5, 0), mad, true, n)
	for fx in [-0.32, 0.32]:
		m.box(Vector3(0.05, tam.y + 0.01, tam.z + 0.01), Vector3(fx, tam.y * 0.5, 0), m._mat.hierro, false, n)
	# tapa abierta hacia atrás, apoyada
	var bisagra := Node3D.new()
	bisagra.position = Vector3(0, tam.y, -tam.z * 0.5)
	bisagra.rotation.x = -1.9
	n.add_child(bisagra)
	m.box(Vector3(tam.x, 0.04, tam.z), Vector3(0, 0.02, tam.z * 0.5), mad, false, bisagra)
	m.box(Vector3(tam.x - 0.06, 0.012, tam.z - 0.06), Vector3(0, 0.046, tam.z * 0.5), m._mat.tela_roja, false, bisagra)
	for fx in [-0.32, 0.32]:
		m.box(Vector3(0.05, 0.05, tam.z + 0.01), Vector3(fx, 0.02, tam.z * 0.5), m._mat.hierro, false, bisagra)
	# lo de dentro: sábanas dobladas al fondo y encima lo que guardaron
	var fondo := Vector3(0, 0.08, 0)
	var sab := m._prop("ropa_frosted_sheets", fondo, rng.randf_range(-0.2, 0.2), 1.0, false, n)
	if sab:
		sab.scale = Vector3(1.05, 1.4, 0.75)
	var guardado: Array = [["ropa_dress_plain2", 0], ["obj_teddy_bear_2", 1], ["obj_old_book_3", 1], ["obj_envelope", 1], ["obj_fancy_picture_frame_01_freep", 2], ["obj_wooden_toy_train", 1], ["ropa_long_white_cotton_socks", 0], ["obj_old_jewelry_box", 1], ["ropa_bowler_hat", 1], ["obj_pocket_watch", 1], ["obj_scroll", 1]]
	guardado.shuffle()
	var sitios := [Vector3(-0.25, 0.25, 0.05), Vector3(0.22, 0.25, -0.05), Vector3(0.0, 0.3, 0.12)]
	for k in 3:
		var g: Array = guardado[k]
		var nombre: String = g[0]
		if not m._props_info.has(nombre):
			continue
		var pq := m._prop(nombre, sitios[k], rng.randf() * TAU, 1.0, false, n)
		if pq == null:
			continue
		if int(g[1]) == 0:
			# prenda doblada: aplastada y tumbada
			pq.rotation = Vector3(-PI * 0.5, rng.randf() * TAU, 0)
			var tq := m._prop_size(nombre)
			var e := 0.35 / maxf(tq.y, 0.1)
			pq.scale = Vector3(e, e, e * 0.25)
		elif int(g[1]) == 2:
			pq.rotation = Vector3(-PI * 0.5, rng.randf_range(-0.3, 0.3), 0)

## ¿De quién es la sala? f mujer, m hombre, n niños, x matrimonio (al azar en las demás).
func _sexo(r: Dictionary) -> String:
	var n := String(r.name).to_lower()
	for k in ["madre", "institutriz", "elena", "costura", "tocador", "plancha"]:
		if k in n: return "f"
	for k in ["hermano", "estudio", "billar", "fumar"]:
		if k in n: return "m"
	if "niños" in n: return "n"
	if "padres" in n: return "x"
	return "f" if (int(r.id) * 7919) % 2 == 0 else "m"

## La ropa de la casa: prendas extendidas a los pies de las camas, zapatos junto a ellas, batas y delantales
## colgados de percheros de pared, toallas en el baño, maniquíes de costura, sábanas en el ático.
func _ropa(r: Dictionary, g: String) -> void:
	var tp := _tipo(r)
	var sx := _sexo(r)
	for cama in _camas:
		if cama.sala != r.id:
			continue
		var c: Vector3 = cama.pos
		var yaw: float = cama.yaw
		var t: Vector3 = cama.tam
		var cabeza := Vector3(0, 0, -1).rotated(Vector3.UP, yaw)
		var lado := Vector3(1, 0, 0).rotated(Vector3.UP, yaw)
		if false:  # las prendas aplastadas sobre la cama parecían de cartón y quedaban flotando sobre el edredón
			var quien: String = sx if sx != "x" else ("f" if rng.randf() < 0.5 else "m")
			if quien != "n":
				_tendida(c + Vector3(0, float(cama.alto), 0) - cabeza * (t.z * 0.5 - 0.15), yaw, _var("prenda_" + quien))
		# zapatos al lado de la cama, mirando hacia fuera
		for lad in ([1.0, -1.0] if sx == "x" else [1.0 if rng.randf() < 0.5 else -1.0]):
			var quien2: String = sx if sx != "x" else ("f" if lad > 0 else "m")
			var zp: Vector3 = c + lado * lad * (t.x * 0.5 + 0.28) - cabeza * 0.3
			_zapatos(zp, yaw + PI * 0.5 * lad, _var("zapatos_" + quien2))
	match tp:
		"costura":
			for k in 2:
				_pie(r, _var("maniqui"), true)
		"bano":
			var pr := _pared_al_azar(r)
			if pr.size() == 3:
				_cuadro(r, "ropa_towel_rail", pr[0], pr[1], pr[2], 1.0, 1.45)
		"vestibulo":
			var bz := _pie(r, _var("zapatos_m"), true)
		"dormitorio", "tocador":
			if rng.randf() < 0.55:
				var pr2 := _pared_al_azar(r)
				if pr2.size() == 3:
					_percha(r, pr2[0], pr2[1], pr2[2], "ropa_robe" if rng.randf() < 0.6 else "")
		"cocina":
			var pr3 := _pared_al_azar(r)
			if pr3.size() == 3:
				_percha(r, pr3[0], pr3[1], pr3[2], "ropa_apron")
	if g == "atico":
		_pie(r, "ropa_wedding_dress", false)
		var q := _pie(r, "ropa_frosted_sheets", false)

## Prenda extendida y aplastada sobre una cama (el cuello hacia el cabecero).
func _tendida(pie: Vector3, yaw: float, nombre: String) -> void:
	var real := _real(nombre)
	if nombre == "" or not m._props_info.has(real):
		return
	var t := m._prop_size(real)
	var esc := minf(1.0, 1.25 / maxf(t.y, 0.1)) * 0.92
	var n := m._prop(real, pie, yaw, esc, false)
	if n == null:
		return
	n.rotation = Vector3(-PI * 0.5, yaw + rng.randf_range(-0.12, 0.12), 0)
	n.scale = Vector3(esc, esc, esc * 0.3)
	n.position = pie + Vector3(0, t.z * esc * 0.15 + 0.01, 0)

## Un par de zapatos en el suelo, juntos y ordenados.
func _zapatos(p: Vector3, yaw: float, nombre: String) -> void:
	var real := _real(nombre)
	if nombre == "" or not m._props_info.has(real) or m._sobre_escalera(p, 0.3) or not m.door_near(p, 0.9).is_empty():
		return
	if real in PARES:
		m._prop(real, p, yaw + rng.randf_range(-0.15, 0.15), 1.0, false)
		return
	var lado := Vector3(1, 0, 0).rotated(Vector3.UP, yaw)
	m._prop(real, p - lado * 0.07, yaw + rng.randf_range(-0.1, 0.1), 1.0, false)
	m._prop(real, p + lado * 0.07, yaw + rng.randf_range(-0.1, 0.25), 1.0, false)

## Perchero de pared (listón con ganchos) y, si se pide, una prenda colgada de él.
func _percha(r: Dictionary, x: float, z: float, yaw: float, prenda: String) -> void:
	var q := _cuadro(r, "ropa_wooden_tool_hanger", x, z, yaw, 1.0, 1.75)
	if q == Vector3.ZERO or prenda == "":
		return
	var real := _real(prenda)
	if not m._props_info.has(real):
		return
	var t := m._prop_size(real)
	var dentro := Vector3(0, 0, 1).rotated(Vector3.UP, yaw)
	m._prop(real, Vector3(q.x, q.y + 0.02 - t.y, q.z) + dentro * (t.z * 0.5 + 0.03), yaw, 1.0, false)

## Un punto de pared libre (sin puertas, ventanas ni nada colgado cerca) en coordenadas locales: [x, z, yaw].
func _pared_al_azar(r: Dictionary) -> Array:
	var rect: Rect2 = r.rect
	for k in 30:
		var lado := rng.randi_range(0, 3)
		var horiz := lado < 2
		var u := rng.randf_range(0.8, (rect.size.x if horiz else rect.size.y) - 0.8)
		var x := u if horiz else (0.1 if lado == 2 else rect.size.x - 0.1)
		var z := (0.1 if lado == 0 else rect.size.y - 0.1) if horiz else u
		var w := Vector3(rect.position.x + x, float(r.y), rect.position.y + z)
		if not m.door_near(w, 1.1).is_empty() or m.ventana_cerca(w, 1.2) or not _pared_libre(w, 1.0):
			continue
		var tapado := false
		for a in _altos:
			if a.grow(0.3).has_point(Vector2(w.x, w.z)):
				tapado = true
		if not tapado:
			return [x, z, [0.0, PI, PI * 0.5, -PI * 0.5][lado]]
	return []

## Mueble bajo contra la pared, centrado en un tramo libre (consola, cómoda, mesilla, baúl… según la sala).
## Devuelve su altura (0 si no se puso).
func _mueble_bajo(r: Dictionary, tp: String, x: float, z: float, yaw: float, tramo: float) -> float:
	var op: Array = []
	match tp:
		"salon", "pasillo", "vestibulo", "baile", "billar", "musica":
			op = ["ClassicConsole_01", "side_table_tall_01", "small_wooden_table_01", "painted_wooden_cabinet"]
		"dormitorio", "tocador":
			op = ["GothicCommode_01", "ClassicNightstand_01", "painted_wooden_cabinet", "small_wooden_table_01"]
		"ninos":
			op = ["treasure_chest", "small_wooden_table_01", "painted_wooden_nightstand"]
		"biblioteca", "estudio", "archivo":
			op = ["small_wooden_table_01", "side_table_tall_01", "ClassicConsole_01"]
		"comedor":
			op = ["painted_wooden_cabinet", "ClassicConsole_01"]
	if op.is_empty() or rng.randf() > 0.7:
		return 0.0
	var nombre: String = op[rng.randi_range(0, op.size() - 1)]
	var t := m._prop_size(_real(nombre))
	if t.x > tramo - 0.3:
		return 0.0
	var f := _caras(r)
	var rect: Rect2 = r.rect
	var dentro := Vector3(0, 0, 1).rotated(Vector3.UP, yaw)
	var lx := x
	var lz := z
	if absf(dentro.x) > 0.5:
		lx = (f[0] + t.z * 0.5 + 0.02) if dentro.x > 0 else (rect.size.x - f[1] - t.z * 0.5 - 0.02)
	else:
		lz = (f[2] + t.z * 0.5 + 0.02) if dentro.z > 0 else (rect.size.y - f[3] - t.z * 0.5 - 0.02)
	var ext := t if absf(dentro.z) > 0.5 else Vector3(t.z, t.y, t.x)
	var c := Vector3(rect.position.x + lx, float(r.y), rect.position.y + lz)
	if not _libre(c, ext, rect.grow(0.3)) or m._huella_en_escalera(c, ext, 0.0):
		return 0.0
	var n := _en(r, nombre, lx, lz, yaw, 1.0)
	return t.y if n else 0.0

## Suelo: solo lo que tiene sentido donde está.
func _suelo_con_sentido(r: Dictionary, g: String) -> void:
	var rect: Rect2 = r.rect
	var y := float(r.y)
	# leña junto a cada chimenea de la sala
	for ch in m.chimeneas:
		var cp: Vector3 = ch.pos
		if absf(cp.y - y) > 1.0 or not rect.grow(0.5).has_point(Vector2(cp.x, cp.z)):
			continue
		var back: Vector3 = ch.back
		var lado := Vector3(-back.z, 0, back.x)
		var leña := cp - back * 0.35 + lado * 1.35
		var lm := _var("lena")
		if lm != "" and rng.randf() < 0.6:
			m._prop(_real(lm), leña, atan2(lado.x, lado.z) + rng.randf_range(-0.2, 0.2), 1.0, false)
		else:
			_monton_lena(leña, atan2(lado.x, lado.z))
		if _var("obj_fireplace_tools_1") != "":
			m._prop(_real("obj_fireplace_tools_1"), cp - back * 0.3 - lado * 1.3, atan2(-back.x, -back.z), 1.0, true)
	# piezas de pie, cada una en su sala y contra una pared libre (nunca en mitad del paso)
	var tp := _tipo(r)
	match tp:
		"vestibulo":
			_pie(r, _var("perchero"), true)
			_pie(r, "obj_pendulum_clock", false)
		"pasillo":
			if rng.randf() < 0.35:
				_pie(r, "obj_pendulum_clock", false)
		"biblioteca":
			_pie(r, "obj_floor_globe", true)
			if rng.randf() < 0.6:
				_pie(r, "obj_bible_on_stand", false)
		"estudio":
			_pie(r, "obj_floor_globe" if rng.randf() < 0.5 else "obj_telescope", true)
		"salon", "mananas":
			_pie(r, "obj_victorian_brass_oil_lamp", true)
		"musica":
			_pie(r, "obj_harp", true)
			_pie(r, "obj_old_violin", true)
		"ninos":
			_pie(r, "obj_loshadka_rocking_horse_woode", true)
			for k in 3:
				_pie(r, _var("juguete"), false)
		"costura":
			_pie(r, "obj_shawl_3d_scan", true)
		"dormitorio":
			if rng.randf() < 0.4:
				_pie(r, _var("perchero"), true)
		"calderas":
			_pie(r, _var("yunque"), true)
			for k in 2:
				_pie(r, _var("herramienta"), true)
			_pie(r, _var("saco"), true)
		"despensa":
			for k in 3:
				_pie(r, _var("saco"), true)
			_pie(r, "obj_ancient_clay_pots", true)
		"sotano", "cava":
			if rng.randf() < 0.6:
				_pie(r, _var("herramienta"), true)
			if rng.randf() < 0.5:
				_pie(r, _var("saco"), true)
	if g == "atico":
		_pie(r, _var("caja"), true)
		_pie(r, _var("juguete"), true)
		_pie(r, "obj_birdcage_3", true)
	# junto a las estanterías: una pila de libros ordenada en el suelo, a un lado
	if g in ["biblioteca", "salon"]:
		for a in _altos:
			var c := a.get_center()
			if not rect.has_point(c) or rng.randf() > 0.4:
				continue
			var lado := Vector3(1, 0, 0) if a.size.x > a.size.y else Vector3(0, 0, 1)
			var q := Vector3(c.x, y, c.y) + lado * (maxf(a.size.x, a.size.y) * 0.5 + 0.25)
			var t := Vector3(0.35, 0.3, 0.35)
			if _libre(q, t, rect):
				var n := m._prop(_real(_var("libros")), q, rng.randf_range(-0.2, 0.2), 1.0, false)
				if n:
					_ocupar(q, t)

## Pieza de pie contra una pared libre de la sala, mirando hacia dentro; «esquina» la lleva cerca de un extremo.
## Las altas no tapan ventanas; respeta puertas, pasos, armarios y lo ya colocado.
func _pie(r: Dictionary, nombre: String, esquina: bool) -> Node3D:
	if nombre == "":
		return null
	var real := _real(nombre)
	if not m._props_info.has(real):
		if DBG: print("PIE sin info ", nombre, " -> ", real)
		return null
	var t := m._prop_size(real)
	var rect: Rect2 = r.rect
	var f := _caras(r)
	var fallos := [0, 0, 0, 0]
	for intento in 40:
		var lado := rng.randi_range(0, 3)
		var horiz := lado < 2
		var largo := rect.size.x if horiz else rect.size.y
		var yaw: float = [0.0, PI, PI * 0.5, -PI * 0.5][lado]
		var ext := t if horiz else Vector3(t.z, t.y, t.x)
		var media := (ext.x if horiz else ext.z) * 0.5
		var a := rng.randf_range(0.0, 1.0)
		if esquina:
			a = rng.randf_range(0.0, 0.15) if rng.randf() < 0.5 else rng.randf_range(0.85, 1.0)
		var u := lerpf(media + 0.45, largo - media - 0.45, a)
		var x: float = u if horiz else (f[0] + ext.x * 0.5 + 0.03 if lado == 2 else rect.size.x - f[1] - ext.x * 0.5 - 0.03)
		var z: float = (f[2] + ext.z * 0.5 + 0.03 if lado == 0 else rect.size.y - f[3] - ext.z * 0.5 - 0.03) if horiz else u
		var c := Vector3(rect.position.x + x, float(r.y), rect.position.y + z)
		if not _libre(c, ext, rect.grow(0.3)):
			fallos[0] += 1
			continue
		if t.y > 0.9 and m.ventana_cerca(Vector3(c.x, float(r.y), c.z), media + 0.7):
			fallos[1] += 1
			continue
		if m._huella_en_escalera(c, ext, 0.0):
			fallos[2] += 1
			continue
		var n := _en(r, real, x, z, yaw, 1.0, 0.0, true)
		if n:
			return n
		fallos[3] += 1
	if DBG: print("PIE falla ", r.name, " ", real, " ", fallos)
	return null

## Montón de leña ordenado (troncos de corteza apilados en pirámide).
func _monton_lena(p: Vector3, yaw: float) -> void:
	var fila := [4, 3, 2]
	var lado := Vector3(cos(yaw), 0, -sin(yaw))
	for nivel in 3:
		for k in fila[nivel]:
			var off: float = (k - (fila[nivel] - 1) * 0.5) * 0.13
			var tr := m.cyl(0.06 + rng.randf() * 0.015, 0.065, 0.55 + rng.randf() * 0.08, p + lado * off + Vector3(0, 0.065 + nivel * 0.115, 0), m._mat.corteza, null, 7)
			tr.rotation = Vector3(PI * 0.5, yaw + rng.randf_range(-0.06, 0.06), 0)

## Aplique de pared: brazo de latón con vela (o farol de hierro en sótano y ático), sin luz propia.
func _aplique(r: Dictionary, x: float, z: float, yaw: float, farol: bool) -> void:
	var f := _caras(r)
	var rect: Rect2 = r.rect
	var dentro := Vector3(0, 0, 1).rotated(Vector3.UP, yaw)
	var W: float = rect.size.x
	var D: float = rect.size.y
	if x < 0.5: x = f[0] + 0.02
	elif x > W - 0.5: x = W - f[1] - 0.02
	if z < 0.5: z = f[2] + 0.02
	elif z > D - 0.5: z = D - f[3] - 0.02
	var p := Vector3(rect.position.x + x, float(r.y) + 1.85, rect.position.y + z)
	if m.ventana_cerca(Vector3(p.x, float(r.y), p.z), 1.2) or not _pared_libre(Vector3(p.x, float(r.y), p.z), 0.9):
		return
	_en_pared.append(Vector3(p.x, float(r.y), p.z))
	if farol:
		m.box(Vector3(0.03, 0.03, 0.22), p + dentro * 0.11 + Vector3(0, 0.12, 0), m._mat.hierro, false, null, false).rotation.y = yaw
		m._prop("Lantern_01", p + dentro * 0.2 - Vector3(0, 0.1, 0), yaw, 1.0, false)
		return
	if not _ap_tipo.has(r.id):
		_ap_tipo[r.id] = rng.randf() < 0.5
	# (el modelo obj_candle_wall_lamp se veía como una placa negra: se usa el aplique dorado hecho por código)
	if false and _ap_tipo[r.id] and m._prop_size("obj_candle_wall_lamp") != Vector3.ONE:
		# aplique de hierro con vela (modelo)
		var tl := m._prop_size("obj_candle_wall_lamp")
		m._prop("obj_candle_wall_lamp", p - Vector3(0, tl.y * 0.5, 0) + dentro * tl.z * 0.5, yaw, 1.0, false)
		return
	m.box(Vector3(0.12, 0.2, 0.025), p + dentro * 0.012, m._mat.oro, false, null, false).rotation.y = yaw
	var brazo := m.cyl(0.01, 0.01, 0.2, p + dentro * 0.1 - Vector3(0, 0.05, 0), m._mat.oro, null, 6)
	brazo.rotation = Vector3(PI * 0.5, yaw, 0)
	m.cyl(0.035, 0.02, 0.03, p + dentro * 0.2 - Vector3(0, 0.05, 0), m._mat.oro, null, 8)
	var vela := m.cyl(0.012, 0.012, 0.11 + rng.randf() * 0.06, p + dentro * 0.2 + Vector3(0, 0.02, 0), m._mat.sal, null, 8)
	vela.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## Estante de pared con cosas encima.
func _estante(r: Dictionary, x: float, z: float, yaw: float, g: String) -> void:
	var f := _caras(r)
	var rect: Rect2 = r.rect
	var W: float = rect.size.x
	var D: float = rect.size.y
	var dentro := Vector3(0, 0, 1).rotated(Vector3.UP, yaw)
	var lado := Vector3(1, 0, 0).rotated(Vector3.UP, yaw)
	if x < 0.5: x = f[0] + 0.01
	elif x > W - 0.5: x = W - f[1] - 0.01
	if z < 0.5: z = f[2] + 0.01
	elif z > D - 0.5: z = D - f[3] - 0.01
	var base := Vector3(rect.position.x + x, float(r.y) + 1.6, rect.position.y + z)
	if m.ventana_cerca(Vector3(base.x, float(r.y), base.z), 1.6) or not _pared_libre(Vector3(base.x, float(r.y), base.z), 1.2):
		if DBG: print("ESTANTE no ", r.name, " ventana=", m.ventana_cerca(Vector3(base.x, float(r.y), base.z), 1.6))
		return
	if DBG: print("ESTANTE ok ", r.name, " ", base)
	_en_pared.append(Vector3(base.x, float(r.y), base.z))
	var tabla := m.box(Vector3(1.0, 0.035, 0.24), base + dentro * 0.12, m._mat.madera, false, null, true)
	tabla.rotation.y = yaw
	for s in [-0.42, 0.42]:
		var esc := m.box(Vector3(0.03, 0.16, 0.2), base + dentro * 0.1 + lado * s - Vector3(0, 0.09, 0), m._mat.madera, false, null, false)
		esc.rotation.y = yaw
	var pool: Array = ["jarron_peq", "libro", "vela", "taza", "perfume"] if g != "cocina" else ["cuenco", "jarra", "olla", "utensilio", "jarra"]
	# fila ordenada: a veces la misma pieza repetida (botes iguales), a veces piezas distintas, siempre alineadas
	var igual := rng.randf() < 0.35
	var fija := _var(String(pool[rng.randi_range(0, pool.size() - 1)]))
	var cuantos := 4 if g == "cocina" else 3
	for k in cuantos:
		var nombre := fija if igual else _var(String(pool[rng.randi_range(0, pool.size() - 1)]))
		if nombre == "" or m._prop_size(_real(nombre)).y > 0.4 or maxf(m._prop_size(_real(nombre)).x, m._prop_size(_real(nombre)).z) > 0.3:
			continue
		var u := (-0.36 + k * 0.24) if cuantos == 4 else (-0.32 + k * 0.32)
		m._prop(_real(nombre), base + dentro * 0.12 + lado * u + Vector3(0, 0.02, 0), yaw + rng.randf_range(-0.15, 0.15), 0.9, false)

var _crucifijo: Dictionary = {}
var _camas: Array = []
var DBG := OS.get_environment("DECO_DBG") != ""
var _ap_tipo: Dictionary = {}
var _tex_papel: Texture2D
var _tex_hoja: Texture2D
## Papeles y cartas por el suelo, trozos de yeso caídos del techo y hojas secas junto a las ventanas (MultiMesh: una llamada por tipo).
func _restos(r: Dictionary, g: String) -> void:
	var rect: Rect2 = r.rect
	var y := float(r.y)
	var area := rect.size.x * rect.size.y
	if _tex_papel == null:
		_tex_papel = _hacer_papel()
		_tex_hoja = _hacer_hoja()
	# papeles
	var np := int(area * (0.12 if g in ["biblioteca", "atico"] else 0.05))
	var xs: Array[Transform3D] = []
	for k in np:
		# los papeles caídos se quedan junto a muebles y paredes (por donde los empuja la corriente), no en mitad
		var p := Vector3(rng.randf_range(rect.position.x + 0.3, rect.end.x - 0.3), y + 0.006 + rng.randf() * 0.004, rng.randf_range(rect.position.y + 0.3, rect.end.y - 0.3))
		if rng.randf() < 0.7:
			if rng.randf() < 0.5:
				p.x = rect.position.x + rng.randf_range(0.25, 0.7) if rng.randf() < 0.5 else rect.end.x - rng.randf_range(0.25, 0.7)
			else:
				p.z = rect.position.y + rng.randf_range(0.25, 0.7) if rng.randf() < 0.5 else rect.end.y - rng.randf_range(0.25, 0.7)
		if m._sobre_escalera(p, 0.1):
			continue
		var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, -PI * 0.5 + rng.randf_range(-0.05, 0.05))
		xs.append(Transform3D(b.scaled(Vector3(rng.randf_range(0.55, 1.2), 1, rng.randf_range(0.55, 1.2))), p))
	_multi(_quad(Vector2(0.21, 0.29)), _mat_tex(_tex_papel, Color(0.66, 0.6, 0.5)), xs)
	# yeso y polvo caídos (más en las salas grandes y viejas)
	var nc := int(area * (0.12 if g != "tunel" else 0.4))
	var ys: Array[Transform3D] = []
	for k in nc:
		var junto := rng.randf() < 0.85
		var px := rng.randf_range(rect.position.x + 0.2, rect.end.x - 0.2)
		var pz := rng.randf_range(rect.position.y + 0.2, rect.end.y - 0.2)
		if junto:
			if rng.randf() < 0.5:
				px = rect.position.x + rng.randf_range(0.18, 0.6) if rng.randf() < 0.5 else rect.end.x - rng.randf_range(0.18, 0.6)
			else:
				pz = rect.position.y + rng.randf_range(0.18, 0.6) if rng.randf() < 0.5 else rect.end.y - rng.randf_range(0.18, 0.6)
		var sc := Vector3(rng.randf_range(0.03, 0.14), rng.randf_range(0.01, 0.04), rng.randf_range(0.03, 0.12))
		var b := Basis(Vector3.UP, rng.randf() * TAU).rotated(Vector3.RIGHT, rng.randf_range(-0.3, 0.3)).scaled(sc)
		ys.append(Transform3D(b, Vector3(px, y + sc.y * 0.3, pz)))
	var mat_yeso: Material = m._mat.yeso if g != "tunel" and g != "sotano" else m._mat.muro_sotano
	_multi(_caja_unidad(), mat_yeso, ys)
	# hojas secas que entraron por las ventanas rotas
	var hs: Array[Transform3D] = []
	for v in m.ventanas:
		if absf(v.y - y) > 1.0 or not rect.grow(0.5).has_point(Vector2(v.x, v.z)):
			continue
		var dentro := Vector2(rect.get_center().x - v.x, rect.get_center().y - v.z).normalized()
		for k in rng.randi_range(6, 16):
			var d := rng.randf_range(0.2, 2.2)
			var q := Vector2(v.x, v.z) + dentro * d + Vector2(-dentro.y, dentro.x) * rng.randf_range(-1.2, 1.2)
			if not rect.has_point(q):
				continue
			var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, -PI * 0.5 + rng.randf_range(-0.25, 0.25))
			hs.append(Transform3D(b.scaled(Vector3.ONE * rng.randf_range(0.7, 1.3)), Vector3(q.x, y + 0.008, q.y)))
	_multi(_quad(Vector2(0.09, 0.12)), _mat_tex(_tex_hoja, Color(0.75, 0.6, 0.4)), hs)

var _mallas_restos := {}
func _quad(sz: Vector2) -> Mesh:
	var k := "q%s" % sz
	if not _mallas_restos.has(k):
		var q := QuadMesh.new()
		q.size = sz
		_mallas_restos[k] = q
	return _mallas_restos[k]

func _caja_unidad() -> Mesh:
	if not _mallas_restos.has("caja"):
		var b := BoxMesh.new()
		b.size = Vector3.ONE
		_mallas_restos["caja"] = b
	return _mallas_restos["caja"]

func _mat_tex(tex: Texture2D, tinte: Color) -> StandardMaterial3D:
	var k := "m%d" % tex.get_instance_id()
	if not _mallas_restos.has(k):
		var mt := StandardMaterial3D.new()
		mt.albedo_texture = tex
		mt.albedo_color = tinte
		mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		mt.alpha_scissor_threshold = 0.4
		mt.cull_mode = BaseMaterial3D.CULL_DISABLED
		mt.roughness = 0.95
		_mallas_restos[k] = mt
	return _mallas_restos[k]

func _multi(mesh: Mesh, mat: Material, xs: Array[Transform3D]) -> void:
	if xs.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xs.size()
	for i in xs.size():
		mm.set_instance_transform(i, xs[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m._house.add_child(mi)

## Hoja de papel envejecido con renglones manuscritos y bordes gastados.
func _hacer_papel() -> Texture2D:
	var img := Image.create(64, 88, false, Image.FORMAT_RGBA8)
	var nz := FastNoiseLite.new()
	nz.frequency = 0.08
	for yy in 88:
		for xx in 64:
			var borde := minf(minf(xx, 63 - xx), minf(yy, 87 - yy))
			var a := 1.0 if borde > 1.5 + nz.get_noise_2d(xx * 3, yy * 3) * 1.5 else 0.0
			var c := Color(0.93, 0.89, 0.78).darkened(0.08 + nz.get_noise_2d(xx, yy) * 0.12)
			var linea := (yy - 10) % 6 == 0 and yy > 8 and yy < 80 and xx > 6 and xx < 58 - (yy * 7) % 13
			if linea and absf(sin(xx * 0.9 + yy)) > 0.25:
				c = Color(0.18, 0.15, 0.2)
			img.set_pixel(xx, yy, Color(c.r, c.g, c.b, a))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

## Hoja seca (silueta de hoja de roble con nervio).
func _hacer_hoja() -> Texture2D:
	var img := Image.create(48, 64, false, Image.FORMAT_RGBA8)
	for yy in 64:
		for xx in 48:
			var v := yy / 63.0
			var ancho := sin(v * PI) * 0.42 * (0.8 + 0.2 * sin(v * 22.0))
			var u := absf(xx / 47.0 - 0.5)
			var dentro := u < ancho
			var c := Color(0.45, 0.26, 0.1).lerp(Color(0.62, 0.42, 0.16), absf(sin(xx * 0.4 + yy * 0.2)) * 0.5)
			if u < 0.025:
				c = c.darkened(0.3)
			img.set_pixel(xx, yy, Color(c.r, c.g, c.b, 1.0 if dentro else 0.0))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func vestir(r: Dictionary) -> void:
	_nivel_de(r)
	_vestir_base(r)
	if not String(r.type) in ["jardin", "agua"]:
		_relleno(r)

func _vestir_base(r: Dictionary) -> void:
	var antes := _n_puestos
	var hecha := _vestir_base0(r)
	if not hecha:
		return
	# una sala montada a mano que quedó medio vacía (era más grande antes): se completa con lo de su tipo
	var area: float = (r.rect as Rect2).get_area()
	var piezas := _n_puestos - antes
	var tipo := _tipo(r)
	if tipo != "" and SALA.has(tipo) and piezas < int(area / 9.0) and int(r.level) >= 0 \
			and not (String(r.name) in ["Cuarto de Damián", "Cuarto de huéspedes", "Torre", "Mirador de la torre", "Escondite de Damián niño"]):
		_generico(r, tipo)

## Devuelve true si la sala tiene montaje a mano.
func _vestir_base0(r: Dictionary) -> bool:
	if String(r.name) == "Salón con chimenea":
		_reservar_pasos(r)
		_salon_chimenea(r)
		return true
	var a_mano := {"Ático (vigas, baúles, muñecos tapados)": _atico, "Escondite de Damián niño": _rincon_elena, "Torre": _torre, "Mirador de la torre": _mirador,
		"Pasillo del sótano": _pasillo_sotano, "Galería de servicio": _galeria_servicio, "Archivo": _archivo, "Sala de calderas": _calderas, "Cava de vinos": _cava,
		"Despensa": _despensa, "Antecocina": _antecocina, "Guardarropa": _guardarropa, "Cuarto de servicio": _servicio, "Cuarto de plancha": _plancha,
		"Sala de fumar y billar": _billar, "Sala de las mañanas": _mananas, "Tocador de la madre": _tocador, "Cuarto del hermano": _hermano,
		"Baño": _bano, "Cuarto de huéspedes azul": _huespedes_azul, "Sala de costura": _costura, "Cuarto de la institutriz": _institutriz,
		"Galería de retratos": _galeria, "Cuarto de huéspedes": _huespedes, "Cuarto de lectura": _lectura, "Pasillo principal": _pasillo, "Pasillo": _pasillo,
		"Dormitorio de los padres": _dormitorio_padres, "Cuarto de Damián": _cuarto_elena, "Cuarto de niños": _cuarto_ninos, "Sala de música": _sala_musica, "Salón de baile": _salon_baile, "Capilla de la madre": _capilla}
	if a_mano.has(String(r.name)):
		_reservar_pasos(r)
		# primero lo que define la sala (la cama, la bañera) donde quepa; luego el montaje a mano alrededor
		_cama_si_falta(r)
		_banera_si_falta(r)
		(a_mano[String(r.name)] as Callable).call(r)
		return true
	if String(r.name) == "Biblioteca":
		_reservar_pasos(r)
		_biblioteca(r)
		return true
	if String(r.name) == "Estudio del padre":
		_reservar_pasos(r)
		_estudio(r)
		return true
	if String(r.name) == "Comedor formal":
		_reservar_pasos(r)
		_comedor(r)
		return true
	if String(r.name) == "Cocina":
		_reservar_pasos(r)
		_cocina(r)
		return true
	if String(r.name).begins_with("Vestíbulo"):
		_reservar_pasos(r)
		_vestibulo(r)
		return true
	var tipo := _tipo(r)
	if tipo == "" or not SALA.has(tipo):
		return false
	_reservar_pasos(r)
	_generico(r, tipo)
	return false

func _generico(r: Dictionary, tipo: String) -> void:
	if tipo in ["dormitorio", "criados"]:
		_cama_donde_quepa(r)
	if tipo == "bano" and not String(r.name).begins_with("Aseo"):
		_banera_donde_quepa(r)
	var c: Dictionary = SALA[tipo]
	# lo que define la sala va primero, contra la pared donde quepa (fregadero, armario, mesa de trabajo...)
	var superficies0: Array = []
	for nombre0 in c.get("primero", []):
		var real0 := _real(nombre0)
		var t0 := m._prop_size(real0)
		var n0 := _donde_quepa(r, real0, t0.z * 0.5 + 0.06)
		if n0 and not (real0.contains("inodoro") or real0.contains("paraguero") or real0.contains("coat_rack") or real0.contains("fregadero") or real0.contains("deposito") or real0.contains("washbasin")):
			var e0 := t0 if absf(sin(n0.rotation.y)) < 0.7 else Vector3(t0.z, t0.y, t0.x)
			superficies0.append([n0, n0.global_position, e0])
	var rect: Rect2 = r.rect
	var area := rect.size.x * rect.size.y
	var superficies: Array = []
	var veces := clampi(int(area / 14.0), 2, 5)
	var repetibles := ["shel", "crate", "barrel", "cabinet", "bookcase", "chair", "cupboard", "wardrobe", "commode", "Commode", "nightstand", "comoda"]
	for v in veces:
		for nombre in c.get("pared", []):
			if v > 0 and rng.randf() < 0.5:
				continue
			if v > 0:
				# lo que hay uno por sala (bañera, lavabo, reloj, tocador, estufa...) no se repite
				var rep := false
				for k in repetibles:
					if String(nombre).contains(k):
						rep = true
				if not rep:
					continue
			var res := _contra_pared(nombre, r)
			superficies.append(res)
	for v in 2:
		for nombre in c.get("centro", []):
			if v > 0 and rng.randf() < 0.5:
				continue
			var sc0 = _en_el_centro(nombre, r)
			# en una silla no se deja nada encima
			var ln := String(nombre).to_lower()
			if not (ln.contains("chair") or ln.contains("stool") or ln.contains("ottoman") or ln.contains("sofa") or ln.contains("dress_form") or ln.contains("barrel")):
				superficies.append(sc0)
	superficies.append_array(superficies0)
	for s in superficies:
		_encima(s, c.get("encima", []), rng.randi_range(2, 4))
	for nombre in c.get("colgado", []):
		_colgar(r, nombre)
	for nombre in c.get("suelo", []):
		for k in rng.randi_range(1, 2):
			_en_el_centro(nombre, r)
	for nombre0 in c.get("techo", []):
		var nombre := _real(nombre0)
		var tam := m._prop_size(nombre)
		var p := Vector3(rect.get_center().x + rng.randf_range(-rect.size.x * 0.2, rect.size.x * 0.2), r.y + ZarekMansion.WALL_H - tam.y - 0.05, rect.get_center().y + rng.randf_range(-rect.size.y * 0.2, rect.size.y * 0.2))
		m._prop(nombre, p, rng.randf() * TAU, 1.0, false)
	# telarañas en esquinas altas
	if r.level >= 0 or tipo in ["sotano", "cava", "calderas", "archivo"]:
		for esq: Vector2 in [rect.position, Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), rect.end]:
			if rng.randf() < 0.6:
				var d: Vector2 = (rect.get_center() - esq).normalized() * 0.5
				m._prop(_real("terr_cobwebs"), Vector3(esq.x + d.x, r.y + ZarekMansion.WALL_H - 0.8, esq.y + d.y), atan2(d.x, d.y), 0.8, false)
