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
	"servicio": {"pared": ["coci_old_kitchen_shelf", "terr_old_and_dusty_multi_crat", "bano_washbasin", "vict_antique_wardrobe", "coci_vintage_wooden_cabinets"], "centro": ["vict_table", "vict_antique_chair"], "encima": ["coti_three_candles_and_a_golde", "coti_glass_bottle", "coci_basic_bowl", "coti_bread_in_basket", "coti_shabby_books"], "suelo": ["vintage_suitcase", "terr_old_and_dusty_multi_crat"]},
	"despensa": {"pared": ["coci_old_kitchen_shelf", "coci_vintage_wooden_cabinets", "terr_old_and_dusty_multi_crat"], "encima": ["coti_glass_bottle", "coti_small_bottle", "coti_wine_bottle", "coci_basic_bowl", "coci_pantry_shelf"], "suelo": ["terr_old_and_dusty_multi_crat"]},
	"biblioteca": {"pared": ["vict_antique_wooden_bookcase__", "terr_dusty_bookshelfs", "coti_chocolate_beech_bookshel", "vict_antique_wooden_bookcase__"], "centro": ["vict_antique_wooden_desk", "vict_antique_chair", "coti_celestial_globe", "vict_victorian_armchair"], "techo": ["pian_chandelier"], "encima": ["coti_typewriter", "coti_occult_books", "vict_old_books___free_download", "coti_three_candles_and_a_golde", "coti_celestial_globe", "vict_key"], "suelo": ["coti_12_old_books", "coti_simple_bookstack"]},
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
			["galería de retratos", "pasillo"], ["pasillo", "pasillo"], ["guardarropa", "dormitorio"], ["galería de servicio", "sotano"], ["cuarto de servicio", "servicio"], ["escalera de servicio", "servicio"]]:
		if k[0] in n:
			return k[1]
	match String(r.type):
		"dormitorio": return "dormitorio"
		"sotano": return "sotano"
		"pasillo": return "pasillo"
		"sala": return "salon"
		"servicio": return "servicio"
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

## Coloca un objeto en coordenadas locales de la sala (x hacia el este, z hacia el sur, en metros desde la esquina NO).
func _en(r: Dictionary, nombre: String, x: float, z: float, yaw := 0.0, escala := 1.0, alto := 0.0, choca := true) -> Node3D:
	var rect: Rect2 = r.rect
	var t := m._prop_size(_real(nombre)) * escala
	var ext := t if absf(sin(yaw)) < 0.7 else Vector3(t.z, t.y, t.x)
	# nada puede meterse dentro de la pared: se empuja hasta la cara interior (las exteriores son más gruesas)
	if alto < ZarekMansion.WALL_H - 1.2:
		var f := _caras(r)
		x = clampf(x, f[0] + ext.x * 0.5 + 0.01, rect.size.x - f[1] - ext.x * 0.5 - 0.01) if ext.x < rect.size.x * 0.5 else x
		z = clampf(z, f[2] + ext.z * 0.5 + 0.01, rect.size.y - f[3] - ext.z * 0.5 - 0.01) if ext.z < rect.size.y * 0.5 else z
	var p := Vector3(rect.position.x + x, float(r.y) + alto, rect.position.y + z)
	var n := m._prop(_real(nombre), p, yaw, escala, choca)
	if n and choca:
		_ocupar(p, ext)
	return n

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
func _cuadro(r: Dictionary, nombre: String, x: float, z: float, yaw: float, escala: float, alto := 2.25) -> void:
	var f := _caras(r)
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	var dmin := minf(minf(x, W - x), minf(z, D - z))
	if dmin == x: x = f[0] + 0.03
	elif dmin == W - x: x = W - f[1] - 0.03
	elif dmin == z: z = f[2] + 0.03
	else: z = D - f[3] - 0.03
	var rect: Rect2 = r.rect
	m._prop(_real(nombre), Vector3(rect.position.x + x, float(r.y) + alto, rect.position.y + z), yaw, escala, false)

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
	_en(r, "vict_antique_iron_safe", W - 0.5, 3.5, -PI * 0.5)
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
	for k in 4:
		var x := 2.95 + k * 1.12
		_en(r, "carved_wooden_plate", x, mz - 0.45, 0.0, 1.0, t, false)
		if k != 2:
			_en(r, "carved_wooden_plate", x, mz + 0.45, 0.0, 1.0, t, false)
	_en(r, "brass_goblets", 3.5, mz - 0.25, 0.0, 0.8, t, false)
	_en(r, "brass_goblets", 6.1, mz + 0.25, PI, 0.8, t, false)
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
	_en(r, "vict_antique_iron_safe", W - 0.5, 6.3, -PI * 0.5)
	_cuadro(r, "bull_head", W - 0.1, 7.6, -PI * 0.5, 1.1, 2.2)
	_en(r, "vict_victorian_lounge_sofa", 0.4, 8.3, 0.0)
	_en(r, "vict_old_books___free_download", 3.6, 6.0, 0.8, 0.6, 0.0, false)
	for esq in [Vector2(0.4, 0.4), Vector2(W - 0.4, 0.4), Vector2(W - 0.4, D - 0.4)]:
		_en(r, "terr_cobwebs", esq.x, esq.y, atan2(W * 0.5 - esq.x, D * 0.5 - esq.y), 0.9, ZarekMansion.WALL_H - 0.9, false)

func vestir(r: Dictionary) -> void:
	if String(r.name) == "Salón con chimenea":
		_reservar_pasos(r)
		_salon_chimenea(r)
		return
	if String(r.name) == "Biblioteca":
		_reservar_pasos(r)
		_biblioteca(r)
		return
	if String(r.name) == "Estudio del padre":
		_reservar_pasos(r)
		_estudio(r)
		return
	if String(r.name) == "Comedor formal":
		_reservar_pasos(r)
		_comedor(r)
		return
	if String(r.name) == "Cocina":
		_reservar_pasos(r)
		_cocina(r)
		return
	if String(r.name).begins_with("Vestíbulo"):
		_reservar_pasos(r)
		_vestibulo(r)
		return
	var tipo := _tipo(r)
	if tipo == "" or not SALA.has(tipo):
		return
	_reservar_pasos(r)
	var c: Dictionary = SALA[tipo]
	var rect: Rect2 = r.rect
	var area := rect.size.x * rect.size.y
	var superficies: Array = []
	var veces := clampi(int(area / 14.0), 2, 5)
	for v in veces:
		for nombre in c.get("pared", []):
			if v > 0 and rng.randf() < 0.5:
				continue
			var res := _contra_pared(nombre, r)
			superficies.append(res)
	for v in 2:
		for nombre in c.get("centro", []):
			if v > 0 and rng.randf() < 0.5:
				continue
			superficies.append(_en_el_centro(nombre, r))
	for s in superficies:
		_encima(s, c.get("encima", []), rng.randi_range(2, 4))
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
