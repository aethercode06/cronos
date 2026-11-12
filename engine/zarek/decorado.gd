class_name ZarekDecorado
extends RefCounted
## Viste cada sala de la mansión Varela (1874) con objetos de época de Objaverse (CC-BY/CC0, créditos en
## zarek/objetos/creditos.json) y Poly Haven (CC0): muebles contra las paredes, objetos cotidianos encima de
## mesas y estanterías, cosas por el suelo y telarañas en las esquinas. Todo con semilla fija.

var m: ZarekMansion
var rng := RandomNumberGenerator.new()
var _ocupado: Array[Rect2] = []

func _init(mansion: ZarekMansion) -> void:
	m = mansion
	rng.seed = 1874
	for sr in m.stair_rects():
		_ocupado.append(sr)

const O := "objetos/"
# ---- catálogos por tipo de sala: [pared], [centro], [encima], [suelo] ----
const SALA := {
	"vestibulo": {"pared": ["vict_grandfather_clock", "ClassicConsole_01", "vict_dusty_antique_mirror___fre", "vict_antique_iron_safe"], "centro": [], "techo": ["pian_medieval_chandelier"], "encima": ["pian_candelabra", "coti_three_candles_and_a_golde"]},
	"salon": {"pared": ["pian_victorian_fire_place___fre", "pian_dusty_old_piano", "vict_antique_wooden_bookcase__", "vict_grandfather_clock", "vict_antique_wardrobe"], "centro": ["vict_victorian_lounge_sofa", "vict_victorian_two_seat_sofa", "vict_victorian_armchair", "vict_victorian_coffee_table", "vict_antique_chair"], "techo": ["pian_chandelier"], "encima": ["coci_old_teapot", "vict_cup___saucer", "coti_three_candles_and_a_golde", "coti_pocket_watch", "vict_torsion_pendulum_clock___ani"], "suelo": ["coti_simple_bookstack", "coti_shabby_books"]},
	"musica": {"pared": ["pian_old_piano", "pian_dusty_piano", "pian_candelabra"], "centro": ["pian_old_wooden_grand_piano", "pian_piano_chair__free_downloa", "vict_victorian_armchair"], "techo": ["pian_medieval_chandelier"], "encima": ["coti_three_candles_and_a_golde"]},
	"baile": {"pared": ["pian_candelabra", "pian_medieval_candelabra__free", "vict_victorian_lounge_sofa", "pian_grandfather_clock"], "centro": ["pian_old_wooden_grand_piano"], "techo": ["pian_medieval_chandelier", "pian_medieval_chandelier"]},
	"comedor": {"pared": ["vict_antique_wardrobe__free", "pian_victorian_fire_place___fre", "pian_candelabra"], "centro": ["vict_table_and_chairs"], "techo": ["pian_chandelier"], "encima": ["coci_samovar", "coci_old_teapot", "vict_cup___saucer", "coti_wine_bottle", "coti_three_candles_and_a_golde", "coti_bread_in_basket"]},
	"cocina": {"pared": ["coci_old_kitchen_cabinets", "coci_old_gas_stove_and_oven", "coci_vintage_wooden_cabinets", "coci_hanging_kitchen_cupboards", "bano_washbasin"], "centro": ["vict_table"], "encima": ["coci_vintage_kettle", "coci_teapot_old_2_100517", "coci_basic_bowl", "coci_wooden_cutting_board", "coci_simple_cutting_board", "coci_sliced_bread", "coci_old_spoon", "coti_glass_bottle", "coti_basic_bottle", "coci_pantry_shelf"]},
	"despensa": {"pared": ["coci_old_kitchen_shelf", "coci_vintage_wooden_cabinets", "terr_old_and_dusty_multi_crat"], "encima": ["coti_glass_bottle", "coti_small_bottle", "coti_wine_bottle", "coci_basic_bowl", "coci_pantry_shelf"], "suelo": ["terr_old_and_dusty_multi_crat"]},
	"biblioteca": {"pared": ["vict_antique_wooden_bookcase__", "terr_dusty_bookshelfs", "coti_chocolate_beech_bookshel", "vict_antique_wooden_bookcase__"], "centro": ["vict_antique_wooden_desk", "vict_antique_chair", "coti_celestial_globe", "vict_victorian_armchair"], "techo": ["pian_chandelier"], "encima": ["coti_typewriter", "coti_occult_books", "vict_old_books___free_download", "coti_three_candles_and_a_golde", "coti_vintage_globe", "vict_key"], "suelo": ["coti_12_old_books", "coti_simple_bookstack"]},
	"estudio": {"pared": ["vict_antique_iron_safe", "vict_antique_wooden_bookcase__", "vict_grandfather_clock"], "centro": ["vict_antique_desk", "vict_antique_chair"], "encima": ["coti_typewriter", "coti_pocket_watch", "coti_joachim_liebermann_s_pock", "vict_old_books___free_download", "coti_three_candles_and_a_golde"], "suelo": ["coti_shabby_books"]},
	"billar": {"pared": ["vict_antique_wooden_bookcase__", "pian_victorian_fire_place___fre"], "centro": ["vict_victorian_armchair", "vict_antique_chair"], "encima": ["coti_wine_bottle", "coti_glass_bottle"]},
	"dormitorio": {"pared": ["vict_antique_wardrobe", "vict_dusty_antique_mirror___fre", "vict_antique_desk"], "centro": ["vict_antique_chair"], "encima": ["coti_three_candles_and_a_golde", "vict_old_books___free_download", "coti_pocket_watch", "vict_cup___saucer"], "suelo": ["vintage_suitcase"]},
	"tocador": {"pared": ["vict_dusty_antique_mirror___fre", "vict_antique_wardrobe__free", "vict_ornate_mirror"], "centro": ["vict_antique_chair", "vict_victorian_armchair"], "encima": ["coti_small_bottle", "coti_glass_bottle", "coti_pocket_watch"]},
	"ninos": {"pared": ["jugu_dollhouse", "vict_antique_wardrobe"], "centro": ["jugu_rocking_horse", "vict_antique_chair"], "encima": ["jugu_music_box_prop", "vict_old_books___free_download"], "suelo": ["jugu_rocking_horse", "coti_shabby_books"]},
	"costura": {"pared": ["vict_singer_15___old_sewing_ma", "coti_willoughsby_sewing_machin", "vict_antique_wardrobe__free"], "centro": ["vict_antique_chair", "vict_table"], "encima": ["coti_three_candles_and_a_golde", "coti_bread_in_basket"]},
	"bano": {"pared": ["bano_classic_bathtub", "bano_washbasin_model", "vict_ornate_mirror"], "encima": ["coti_small_bottle", "coti_glass_bottle"]},
	"pasillo": {"pared": ["ClassicConsole_01", "vict_victorian_lounge_sofa", "pian_candelabra", "vict_grandfather_clock"], "encima": ["coti_three_candles_and_a_golde", "vict_torsion_pendulum_clock___ani"]},
	"atico": {"pared": ["terr_old_and_dusty_multi_crat", "vict_antique_wardrobe", "pian_dusty_old_piano"], "centro": ["jugu_rocking_horse", "jugu_dollhouse", "treasure_chest", "vintage_suitcase", "terr_creepy_lady_bust_statue_s", "terr_old_and_dusty_multi_crat"], "suelo": ["coti_12_old_books", "coti_shabby_books"]},
	"sotano": {"pared": ["terr_old_and_dusty_multi_crat", "coci_old_kitchen_shelf"], "centro": ["terr_old_and_dusty_multi_crat"], "suelo": ["coti_wine_bottle", "coti_glass_bottle"]},
	"cava": {"pared": ["coci_old_kitchen_shelf"], "centro": ["terr_old_and_dusty_multi_crat"], "suelo": ["coti_wine_bottle", "coti_wine_bottle"]},
	"calderas": {"pared": ["pian_old_stove", "pian_small_stove", "terr_old_and_dusty_multi_crat"], "centro": ["terr_old_and_dusty_multi_crat"]},
	"archivo": {"pared": ["coti_chocolate_beech_bookshel", "terr_dusty_bookshelfs", "vict_antique_iron_safe"], "centro": ["vict_antique_desk"], "encima": ["coti_typewriter", "coti_shabby_books"], "suelo": ["coti_12_old_books", "coti_simple_bookstack"]},
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

func _tipo(r: Dictionary) -> String:
	var n: String = String(r.name).to_lower()
	for k in [["vestíbulo", "vestibulo"], ["chimenea", "salon"], ["mañanas", "salon"], ["música", "musica"], ["baile", "baile"], ["comedor", "comedor"],
			["antecocina", "despensa"], ["cocina", "cocina"], ["despensa", "despensa"], ["biblioteca", "biblioteca"], ["lectura", "biblioteca"],
			["estudio", "estudio"], ["billar", "billar"], ["tocador", "tocador"], ["niños", "ninos"], ["costura", "costura"], ["plancha", "costura"],
			["baño", "bano"], ["ático", "atico"], ["rincón", "atico"], ["cava", "cava"], ["calderas", "calderas"], ["archivo", "archivo"],
			["galería de retratos", "pasillo"], ["pasillo", "pasillo"], ["guardarropa", "dormitorio"], ["galería de servicio", "sotano"]]:
		if k[0] in n:
			return k[1]
	match String(r.type):
		"dormitorio": return "dormitorio"
		"sotano": return "sotano"
		"pasillo": return "pasillo"
		"sala": return "salon"
	return ""

func _libre(c: Vector3, t: Vector3, rect: Rect2) -> bool:
	var a := Rect2(c.x - t.x * 0.5 - 0.15, c.z - t.z * 0.5 - 0.15, t.x + 0.3, t.z + 0.3)
	if not rect.grow(-0.2).encloses(a):
		return false
	for o in _ocupado:
		if o.intersects(a):
			return false
	var rad := maxf(t.x, t.z) * 0.5
	if not m.door_near(c, rad + 1.1).is_empty() or not m.portal_near(c, rad + 1.2).is_empty() or not m.wardrobe_near(c, rad + 0.8).is_empty():
		return false
	return true

func _ocupar(c: Vector3, t: Vector3) -> void:
	_ocupado.append(Rect2(c.x - t.x * 0.5, c.z - t.z * 0.5, t.x, t.z))

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
		match lado:
			0:
				p = Vector3(rng.randf_range(rect.position.x + tam.x * 0.6, rect.end.x - tam.x * 0.6), r.y, rect.position.y + tam.z * 0.5 + 0.08); yaw = 0.0
			1:
				p = Vector3(rng.randf_range(rect.position.x + tam.x * 0.6, rect.end.x - tam.x * 0.6), r.y, rect.end.y - tam.z * 0.5 - 0.08); yaw = PI
			2:
				p = Vector3(rect.position.x + tam.z * 0.5 + 0.08, r.y, rng.randf_range(rect.position.y + tam.x * 0.6, rect.end.y - tam.x * 0.6)); yaw = PI * 0.5; ext = Vector3(tam.z, tam.y, tam.x)
			_:
				p = Vector3(rect.end.x - tam.z * 0.5 - 0.08, r.y, rng.randf_range(rect.position.y + tam.x * 0.6, rect.end.y - tam.x * 0.6)); yaw = -PI * 0.5; ext = Vector3(tam.z, tam.y, tam.x)
		if _libre(p, ext, rect):
			_ocupar(p, ext)
			return [m._prop(nombre, p, yaw), p, ext]
	return [null, Vector3.ZERO, Vector3.ZERO]

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
	var rect: Rect2 = r.rect
	var cen := rect.get_center()
	for d in m.doors:
		var dp: Vector3 = d.pos
		if absf(dp.y - float(r.y)) > 1.0 or not rect.grow(0.6).has_point(Vector2(dp.x, dp.z)):
			continue
		var a := Vector2(dp.x, dp.z)
		var mn := Vector2(minf(a.x, cen.x), minf(a.y, cen.y))
		var mx := Vector2(maxf(a.x, cen.x), maxf(a.y, cen.y))
		_ocupado.append(Rect2(mn, mx - mn).grow(0.75))

func vestir(r: Dictionary) -> void:
	var tipo := _tipo(r)
	if tipo == "" or not SALA.has(tipo):
		return
	_reservar_pasos(r)
	var c: Dictionary = SALA[tipo]
	var rect: Rect2 = r.rect
	var area := rect.size.x * rect.size.y
	var superficies: Array = []
	var veces := clampi(int(area / 18.0), 1, 4)
	for v in veces:
		for nombre in c.get("pared", []):
			if v > 0 and rng.randf() < 0.5:
				continue
			var res := _contra_pared(nombre, r)
			superficies.append(res)
	for nombre in c.get("centro", []):
		superficies.append(_en_el_centro(nombre, r))
	for s in superficies:
		_encima(s, c.get("encima", []), rng.randi_range(1, 3))
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
