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
	# un mueble alto pegado a la pared no puede tapar una ventana: se corre a lo largo de la pared
	if t.y > 1.3 and alto < 0.5:
		p = _esquivar_ventana(r, p, ext)
	var n := m._prop(_real(nombre), p, yaw, escala, choca)
	if n and choca:
		_ocupar(p, ext)
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
	var q := Vector3(rect.position.x + x, float(r.y) + alto, rect.position.y + z)
	if m.ventana_cerca(Vector3(q.x, float(r.y), q.z), 1.25):
		var eje := Vector3(0, 0, 1) if (dmin == x or dmin == W - x) else Vector3(1, 0, 0)
		var hecho := false
		for paso in [1.2, -1.2, 2.0, -2.0]:
			var q2: Vector3 = q + eje * paso
			if rect.grow(-0.5).has_point(Vector2(q2.x, q2.z)) and not m.ventana_cerca(Vector3(q2.x, float(r.y), q2.z), 1.25) and m.door_near(Vector3(q2.x, float(r.y), q2.z), 1.3).is_empty():
				q = q2
				hecho = true
				break
		if not hecho:
			return
	m._prop(_real(nombre), q, yaw, escala, false)

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

## Cuarto de Elena (EPICENTRO, 9,6 × 9,6): una sola puerta al sur (x 4,8-7,2). El círculo de sal del ritual
## va en el centro y debe quedar libre (radio 1,9). Habitación de una joven de 1908, ahora corrompida.
func _cuarto_elena(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_cama_hierro(r, 1.6, 1.15, 0.0)
	_en(r, "painted_wooden_nightstand", 2.55, 0.35, 0.0)
	_en(r, "jugu_music_box_prop", 2.55, 0.35, 0.3, 1.2, 0.62, false)
	_en(r, "wooden_candlestick", 2.7, 0.45, 0.0, 1.0, 0.62, false)
	_en(r, "jugu_dollhouse", W - 0.6, 0.6, -PI * 0.75)
	# tocador con el espejo donde se mira lo que no es ella
	_en(r, "GothicCommode_01", W - 0.36, 4.4, -PI * 0.5)
	_en(r, "vict_ornate_mirror", W - 0.1, 4.4, -PI * 0.5, 0.6, 1.25, false)
	_en(r, "coti_small_bottle", W - 0.4, 4.1, 0.0, 0.35, 1.21, false)
	_en(r, "terr_creepy_lady_bust_statue_scan", W - 0.42, 4.85, -PI * 0.5, 0.6, 1.21, false)
	_en(r, "GothicCabinet_01", 0.6, 5.4, PI * 0.5)
	_en(r, "Rockingchair_01", 7.9, 7.6, -2.4)
	_en(r, "jugu_rocking_horse", 7.4, 2.4, -0.6)
	# velas alrededor del círculo, alguna caída; páginas arrancadas por el suelo
	for k in 6:
		var a := TAU * k / 6.0 + 0.3
		var v := _en(r, "coti_three_candles_and_a_golden_c", 4.8 + cos(a) * 2.25, 4.8 + sin(a) * 2.25, a, 0.9, 0.0, false)
		if v and k == 4:
			v.rotation.z = PI * 0.5
			v.position.y += 0.1
	_en(r, "vict_old_books___free_download", 2.2, 3.6, 1.0, 0.6, 0.0, false)
	_en(r, "coti_occult_books", 7.0, 5.6, 0.4, 0.8, 0.0, false)
	_en(r, "coti_shabby_books", 3.0, 7.6, 2.2, 1.0, 0.0, false)
	var silla := _en(r, "vict_antique_chair", 6.8, 8.6, 0.8)
	if silla:
		silla.rotation.x = PI * 0.5
		silla.position.y += 0.22
	_cuadro(r, "fancy_picture_frame_01", 1.6, 0.09, 0.0, 1.4, 2.2)
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
	_cuadro(r, "fancy_picture_frame_01", 3.6, 0.09, 0.0, 1.2, 1.9)
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
func _mesa_billar(r: Dictionary, x: float, z: float) -> void:
	var rect: Rect2 = r.rect
	var c := Vector3(rect.position.x + x, float(r.y), rect.position.y + z)
	m.box(Vector3(1.5, 0.22, 2.8), c + Vector3(0, 0.7, 0), m._mat.madera, true)
	m.box(Vector3(1.26, 0.03, 2.56), c + Vector3(0, 0.82, 0), m._mat.tela_verde, false, null, false)
	for sx in [-0.69, 0.69]:
		m.box(Vector3(0.12, 0.07, 2.8), c + Vector3(sx, 0.845, 0), m._mat.madera, false, null, false)
	for sz in [-1.34, 1.34]:
		m.box(Vector3(1.5, 0.07, 0.12), c + Vector3(0, 0.845, sz), m._mat.madera, false, null, false)
	for px in [-0.62, 0.62]:
		for pz in [-1.27, 0.0, 1.27]:
			m.cyl(0.055, 0.055, 0.02, c + Vector3(px, 0.84, pz), m._mat.oscuro, null, 10)
	for lx in [-0.6, 0.6]:
		for lz in [-1.2, 0.0, 1.2]:
			m.cyl(0.07, 0.1, 0.6, c + Vector3(lx, 0.3, lz), m._mat.madera, null, 8)
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
		m.add_child(b)
	var taco := m.cyl(0.008, 0.016, 1.45, c + Vector3(0.2, 0.87, 0.3), m._mat.madera_clara, null, 6)
	taco.rotation = Vector3(PI * 0.5, 0.35, 0)

## Sala de fumar y billar (7,2 × 9,6): puertas al sur (x 2,4-4,8) y este (z 4,8-7,2); armario en (6,0; 4,8).
func _billar(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_mesa_billar(r, 3.3, 4.0)
	# tacos apoyados en la pared oeste
	for k in 4:
		var t := m.cyl(0.008, 0.016, 1.45, Vector3(r.rect.position.x + 0.2, float(r.y) + 0.72, r.rect.position.y + 3.4 + k * 0.12), m._mat.madera_clara, null, 6)
		t.rotation.z = -0.08
	_en(r, "ArmChair_01", 1.1, 8.2, 0.6)
	_en(r, "ArmChair_01", 2.3, 8.7, -0.3)
	_en(r, "side_table_01", 1.7, 9.1, 0.0, 0.8)
	_en(r, "coti_wine_bottle", 1.6, 9.1, 0.0, 1.0, 0.44, false)
	_en(r, "coti_glass_bottle", 1.8, 9.05, 0.0, 1.0, 0.44, false)
	_en(r, "vict_antique_wooden_bookcase___ga", W - 0.17, 1.6, -PI * 0.5)
	_en(r, "vict_small_antique_table_asset", 6.0, 8.6, 0.3, 0.7)
	_en(r, "chess_set", 6.0, 8.6, 0.3, 0.6, 0.27, false)
	_en(r, "vict_antique_chair", 5.4, 8.7, PI * 0.5 + 0.3)
	_cuadro(r, "bull_head", 3.3, 0.1, 0.0, 1.2, 2.25)
	_cuadro(r, "fancy_picture_frame_01", 0.09, 7.6, PI * 0.5, 1.6, 2.1)
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
	_en(r, "jugu_rocking_horse", 5.6, 8.3, -2.6)
	_en(r, "hatchet", 4.6, 8.9, 1.2, 1.0, 0.0, false)
	_cuadro(r, "fancy_picture_frame_01", 0.09, 1.4, PI * 0.5, 1.2, 2.2)
	_telas(r, [0, 2, 3])

## Baño (4,8 × 9,6): una puerta al sur (x 2,4-4,8). Bañera de patas, lavabo de pie con espejo.
func _bano(r: Dictionary) -> void:
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_en(r, "bano_classic_bathtub", 2.4, 0.5, 0.0, 1.05)
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

## Cama de hierro con colchón, sábana arrugada y almohada (el armazón solo parecía abandonado de más).
func _cama_hierro(r: Dictionary, x: float, z: float, yaw: float, escala := 1.0) -> void:
	var n := _en(r, "old_bed_frame", x, z, yaw, escala)
	if n == null:
		return
	var c := n.global_position if n.is_inside_tree() else n.position
	var colchon := m.box(Vector3(0.84, 0.16, 1.9) * Vector3(escala, 1, escala), c + Vector3(0, 0.5, 0), m._mat.sabana, false)
	colchon.rotation.y = yaw
	var manta := m.box(Vector3(0.9, 0.04, 1.2) * Vector3(escala, 1, escala), c + Vector3(0, 0.6, 0) + Vector3(0, 0, 0.3 * escala).rotated(Vector3.UP, yaw), m._mat.tela_roja, false)
	manta.rotation = Vector3(0.03, yaw + 0.05, 0.02)
	var alm := m.box(Vector3(0.6, 0.12, 0.35) * Vector3(escala, 1, escala), c + Vector3(0, 0.64, 0) + Vector3(0, 0, -0.75 * escala).rotated(Vector3.UP, yaw), m._mat.sabana, false)
	alm.rotation.y = yaw + 0.08

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
	var W: float = r.rect.size.x
	var D: float = r.rect.size.y
	_viguetas(r)
	_tuberia(r, 0.4, 0.4, W - 0.4, 0.4)
	_en(r, "WoodenTable_03", 9.0, 0.45, 0.0)
	_en(r, "wooden_lantern_01", 8.6, 0.45, 0.0, 0.7, 0.83, false)
	_en(r, "hatchet", 9.3, 0.5, 1.2, 1.2, 0.83, false)
	_en(r, "folding_wooden_stool", 9.0, 1.2, 0.4)
	_en(r, "wooden_ladder", 11.4, 0.4, 0.0, 1.3)
	_en(r, "rusted_spade_01", 12.2, 0.15, 0.0, 1.0, 0.0, false)
	_en(r, "vintage_wooden_drawer_01", 0.5, 7.6, PI * 0.5, 0.9)
	_en(r, "vintage_cabinet_01", W - 0.4, 6.0, -PI * 0.5)
	# muebles viejos bajados aquí y tapados con sábanas
	for q in [Vector3(3.0, 0, 8.6), Vector3(5.2, 0, 9.4), Vector3(11.0, 0, 9.0)]:
		var rect: Rect2 = r.rect
		var c := Vector3(rect.position.x + q.x, float(r.y), rect.position.y + q.z)
		var cub := m.box(Vector3(1.2 + rng.randf() * 0.6, 0.9 + rng.randf() * 0.7, 0.8 + rng.randf() * 0.4), c + Vector3(0, 0.6, 0), m._mat.sabana, true)
		cub.rotation.y = rng.randf() * 0.6
	_en(r, "treasure_chest", 1.6, D - 0.5, 0.0, 0.9)
	_en(r, "vintage_suitcase", 7.4, D - 0.4, 0.2)
	_en(r, "jugu_rocking_horse", 8.6, 10.0, 2.4)
	_en(r, "wooden_crate_02", W - 0.4, D - 0.8, 0.0)
	_en(r, "watering_can_metal_01", W - 1.2, D - 0.4, 0.6)
	_telas(r)

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
	_en(r, "vict_antique_iron_safe", 2.6, D - 0.55, PI)
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
	for q in [[2.0, 9.5, 0.3], [3.4, 12.2, 1.2], [27.6, 3.0, 0.2], [34.4, 13.0, -1.3], [11.0, 20.8, 0.5]]:
		_en(r, "treasure_chest", q[0], q[1], q[2], 0.9)
	for q in [[3.0, 13.5, 0.4], [28.6, 3.6, 1.1], [17.0, 20.0, 0.2]]:
		_en(r, "vintage_suitcase", q[0], q[1], q[2])
	for q in [[33.5, 20.5, 0.0], [34.4, 18.8, 0.6], [9.6, 22.6, 0.3], [21.0, 22.8, 0.0]]:
		_en(r, "terr_old_and_dusty_multi_crate_st", q[0], q[1], q[2], 0.8)
	# juguetes de los niños, olvidados
	_en(r, "jugu_rocking_horse", 13.0, 16.0, 2.6)
	_en(r, "jugu_dollhouse", 10.4, 18.4, 0.8)
	_en(r, "Ottoman_01", 19.0, 15.0, 0.4)
	# cuadros apoyados contra las paredes, de cara a la pared alguno
	for q in [[0.35, 6.0, PI * 0.5], [0.35, 7.1, PI * 0.5], [W - 0.35, 5.0, -PI * 0.5], [17.0, D - 0.35, PI], [18.2, D - 0.35, 0.0]]:
		var cu := m._prop("fancy_picture_frame_02", Vector3(r.rect.position.x + q[0], float(r.y), r.rect.position.y + q[1]), q[2], 1.6, false)
		if cu:
			cu.rotation.x = -0.2
	_en(r, "terr_creepy_lady_bust_statue_scan", 25.0, 12.0, 2.0)
	_en(r, "coti_simple_bookstack", 23.0, 10.4, 0.4)
	_en(r, "vict_old_books___free_download", 7.0, 9.0, 1.0, 0.8)
	_en(r, "wooden_lantern_01", 12.6, 11.2, 0.0, 0.8)
	for x in [2.0, 9.0, 16.0, 23.0, 30.0]:
		for z in [0.5, D - 0.5]:
			_en(r, "terr_cobwebs", x, z, 0.0 if z < 1.0 else PI, 1.2, 2.4, false)

## Rincón de Elena (en el ático, 7,2 × 4,8): donde se escondía a escribir. El diario va en el centro.
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
		_en(r, "coti_typewriter", 1.1, 3.4, PI * 0.5, 1.0, 0.8, false)
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

func vestir(r: Dictionary) -> void:
	if String(r.name) == "Salón con chimenea":
		_reservar_pasos(r)
		_salon_chimenea(r)
		return
	var a_mano := {"Ático (vigas, baúles, muñecos tapados)": _atico, "Rincón de Elena": _rincon_elena, "Torre": _torre, "Mirador de la torre": _mirador,
		"Pasillo del sótano": _pasillo_sotano, "Galería de servicio": _galeria_servicio, "Archivo": _archivo, "Sala de calderas": _calderas, "Cava de vinos": _cava,
		"Despensa": _despensa, "Antecocina": _antecocina, "Guardarropa": _guardarropa, "Cuarto de servicio": _servicio, "Cuarto de plancha": _plancha,
		"Sala de fumar y billar": _billar, "Sala de las mañanas": _mananas, "Tocador de la madre": _tocador, "Cuarto del hermano": _hermano,
		"Baño": _bano, "Cuarto de huéspedes azul": _huespedes_azul, "Sala de costura": _costura, "Cuarto de la institutriz": _institutriz,
		"Galería de retratos": _galeria, "Cuarto de huéspedes": _huespedes, "Cuarto de lectura": _lectura, "Pasillo principal": _pasillo, "Pasillo": _pasillo,
		"Dormitorio de los padres": _dormitorio_padres, "EPICENTRO · cuarto de Elena": _cuarto_elena, "Cuarto de niños": _cuarto_ninos, "Sala de música": _sala_musica, "Salón de baile": _salon_baile}
	if a_mano.has(String(r.name)):
		_reservar_pasos(r)
		(a_mano[String(r.name)] as Callable).call(r)
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
