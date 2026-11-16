class_name ZarekMansion
extends Node3D
## La Mansión Varela (victoriana) y el bosque que la rodea, construidos a partir
## del plano de arquitecto (res://zarek/plano/plano.json). 1 celda = 3 m.
## Plantas: sótano (-1), baja (0), primer piso (1), ático (2).

const CELL := 2.4
const LEVEL_H := 4.2
const WALL_H := 4.0
const WT := 0.25
const PLAN := "res://zarek/plano/plano.json"

var plan := {}
var quality := 2
var rooms: Array = []      # {name, type, level, rect(Rect2 en metros, xz), y, id}
var lamps: Array = []      # {node, light, bulb, pos, room, on, broken, base, flicker}
var doors: Array = []      # {pivot, shape, pos, open, locked, ang, target, base, snd}
var wardrobes: Array = []  # {pos, inside, yaw}
var seals: Array = []      # {node, pos, taken}
var pickups: Array = []    # {node, pos, kind, taken, item}
var portals: Array = []    # {pos, to, text}
var fires: Array = []
var start_pos := Vector3.ZERO
var start_yaw := 0.0
var circle_pos := Vector3.ZERO
var radio_pos := Vector3.ZERO
var musicbox_pos := Vector3.ZERO
var front_door := Vector3.ZERO
var house_rect := Rect2()
var grounds_rect := Rect2()
var epicentro_room := -1
var swing: Node3D
var nav_region: NavigationRegion3D
var nav_ready := false
var _rng := RandomNumberGenerator.new()
## Botellas que se sustituyen por botellas de vidrio con física (cuántas hay en cada modelo).
const BOTELLAS := {"coti_wine_bottle": 1, "coti_glass_bottle": 1, "coti_small_bottle": 1, "coti_basic_bottle": 1, "wine_bottles_01": 4}
## Objetos sueltos con física y su masa en kg.
const FISICOS := {"vict_antique_chair": 7.0, "painted_wooden_chair_01": 6.0, "painted_wooden_chair_02": 7.0, "dining_chair_02": 7.0, "WoodenChair_01": 6.0,
	"folding_wooden_stool": 3.0, "painted_wooden_stool": 3.0, "wooden_stool_01": 3.0, "wooden_stool_02": 1.0, "pian_piano_stool_3d_scan": 6.0, "Rockingchair_01": 9.0,
	"side_table_01": 6.0, "side_table_tall_01": 5.0, "small_wooden_table_01": 8.0, "painted_wooden_nightstand": 10.0, "vict_small_antique_table_asset": 8.0,
	"wooden_bucket_01": 3.0, "wooden_bucket_02": 4.0, "wicker_basket_01": 1.0, "wicker_basket_02": 1.0, "wooden_crate_01": 6.0, "wooden_crate_02": 8.0,
	"vintage_suitcase": 6.0, "Ottoman_01": 9.0, "brass_pot_01": 2.0, "brass_pot_02": 1.5, "brass_pan_01": 1.0, "pot_enamel_01": 1.0, "jug_01": 1.0, "metal_jug": 1.0,
	"wooden_bowl_01": 0.5, "wooden_candlestick": 0.6, "vintage_oil_lamp": 1.5, "coti_simple_bookstack": 3.0, "vict_old_books___free_download": 2.5, "coti_12_old_books": 2.0,
	"book_encyclopedia_set_01": 4.0, "coti_bread_in_basket": 0.6, "wooden_cutting_board": 0.8, "carved_wooden_plate": 0.4, "brass_goblets": 0.6,
	"brass_vase_01": 1.0, "brass_vase_02": 1.0, "brass_vase_03": 1.0, "ceramic_vase_01": 1.5, "ceramic_vase_02": 1.5, "ceramic_vase_03": 1.5, "antique_ceramic_vase_01": 1.5,
	"tea_set_01": 2.0, "wine_barrel_01": 45.0, "jugu_rocking_horse": 6.0, "jugu_music_box_prop": 0.8, "marble_bust_01": 12.0, "coti_celestial_globe": 4.0,
	"coci_samovar": 4.0, "watering_can_metal_01": 1.0, "wooden_lantern_01": 1.2, "Lantern_01": 0.6, "food_apple_01": 0.15, "yellow_onion": 0.12, "lemon": 0.1,
	"sweet_potato": 0.15, "wooden_spoon": 0.1, "round_spectacles": 0.05, "coti_pocket_watch": 0.1, "vintage_pocket_watch": 0.1, "magnifying_glass_01": 0.2,
	"vict_cup___saucer": 0.3, "coti_typewriter": 9.0, "coti_three_candles_and_a_golden_c": 0.8, "brass_candleholders": 2.0, "mousetrap": 0.1}
## Modelos de Objaverse que vienen mirando de lado: giro para que miren a +Z como los demás.
## Plantas que mueve el viento: nombre → [flex, temblor].
const VEG_VIENTO := {"veg_3d_fern_01": [0.15, 0.02], "veg_cattail": [0.25, 0.01], "veg_cattail_plant": [0.25, 0.01],"fern_02": [0.15, 0.02], "shrub_02": [0.1, 0.02], "shrub_03": [0.1, 0.02], "shrub_04": [0.1, 0.02], "grass_medium_01": [0.3, 0.01],
	"grass_medium_02": [0.3, 0.01], "nettle_plant": [0.22, 0.015], "dandelion_01": [0.25, 0.01], "celandine_01": [0.22, 0.01]}
const GIRO := {"obj_pendulum_clock": -PI * 0.5, "obj_withered_wooden_crucifix": -PI * 0.5, "obj_wooden_cuckoo_clock": -PI * 0.5,
	"obj_teddy_bear_2": -PI * 0.5, "obj_old_violin": -PI * 0.5, "obj_biblical_scene_from_nurember": PI * 0.5, "obj_candle_wall_lamp": PI * 0.5, "ropa_towel_rail": -PI * 0.5}
## Objetos de pared o fijos: nunca sueltos con física.
const FIJOS := ["ropa_hanger", "ropa_towel", "ropa_frosted", "ropa_wooden_tool", "frame", "crucifix", "cross", "deerhead", "cuckoo", "wall_lamp", "portrait", "biblical", "torment", "painting"]
const METAL_PAL := ["lamp", "candle", "kettle", "teapot", "anvil", "goblet", "lantern", "watch", "candelabra", "pickaxe", "shovel", "cleaver", "grinder", "samovar", "cutlery", "scoop", "pens", "inkwell", "hourglass", "hour_glass", "sphere"]

## Masa (kg) si el objeto va suelto con física; 0 si es fijo. Los objetos pequeños nuevos (obj_*) se calculan por tamaño.
func _masa_fisica(nombre: String) -> float:
	if FISICOS.has(nombre):
		return float(FISICOS[nombre])
	if not (nombre.begins_with("obj_") or nombre.begins_with("ropa_")) or not _props_info.has(nombre):
		return 0.0
	for f in FIJOS:
		if nombre.contains(f):
			return 0.0
	var t: Array = _props_info[nombre].tam
	var mx := maxf(float(t[0]), maxf(float(t[1]), float(t[2])))
	if mx > 0.62:
		return 0.0
	return clampf(float(t[0]) * float(t[1]) * float(t[2]) * 350.0, 0.15, 8.0)

func _es_metal(nombre: String) -> bool:
	if nombre in METALICOS:
		return true
	for k in METAL_PAL:
		if nombre.contains(k):
			return true
	return false

const METALICOS := ["brass_pot_01", "brass_pot_02", "brass_pan_01", "pot_enamel_01", "metal_jug", "brass_goblets", "brass_vase_01", "brass_vase_02", "brass_vase_03",
	"coci_samovar", "watering_can_metal_01", "brass_candleholders", "coti_typewriter", "Lantern_01"]

## Salas montadas a mano en ZarekDecorado: el decorado genérico no les añade nada al azar.
const SALAS_A_MANO := ["Salón con chimenea", "Comedor formal", "Cocina", "Vestíbulo y gran escalera", "Biblioteca", "Estudio del padre", "Dormitorio de los padres", "EPICENTRO · cuarto de Elena", "Cuarto de niños", "Sala de música", "Salón de baile",
	"Sala de fumar y billar", "Sala de las mañanas", "Tocador de la madre", "Cuarto del hermano", "Baño", "Cuarto de huéspedes azul", "Sala de costura", "Cuarto de la institutriz", "Galería de retratos", "Cuarto de huéspedes", "Cuarto de lectura", "Pasillo principal", "Pasillo",
	"Despensa", "Antecocina", "Guardarropa", "Cuarto de servicio", "Cuarto de plancha",
	"Pasillo del sótano", "Galería de servicio", "Archivo", "Sala de calderas", "Cava de vinos",
	"Ático (vigas, baúles, muñecos tapados)", "Rincón de Elena", "Torre", "Mirador de la torre"]
var _house: Node3D
var _mat := {}
var _hole := {}

# ---------------- coordenadas ----------------
func lvl_y(level: int) -> float:
	return level * LEVEL_H

func cell_to_world(key: String, cx: float, cy: float) -> Vector3:
	var p: Dictionary = plan[key]
	var o: Array = p.get("origen", [0, 0])
	return Vector3((float(o[0]) + cx) * CELL, lvl_y(int(p.get("nivel", 0))), (float(o[1]) + cy) * CELL)

func level_of(y: float) -> int:
	return int(round(y / LEVEL_H))

func room_at(p: Vector3) -> int:
	var lv := level_of(p.y + 0.5)
	for r in rooms:
		if r.level == lv and r.type != "jardin" and (r.rect as Rect2).has_point(Vector2(p.x, p.z)):
			return r.id
	return -1

func room_name(p: Vector3) -> String:
	var id := room_at(p)
	if id < 0:
		if grounds_rect.has_point(Vector2(p.x, p.z)):
			return "los jardines"
		return "el bosque"
	return str(rooms[id].name).to_lower() if not str(rooms[id].name).begins_with("EPICENTRO") else "el Epicentro"

func inside_house(p: Vector3) -> bool:
	return room_at(p) >= 0

# ---------------- construcción ----------------
func build(q := 2) -> void:
	quality = q
	_rng.seed = 1874
	var f := FileAccess.open(PLAN, FileAccess.READ)
	plan = JSON.parse_string(f.get_as_text())
	var t0 := Time.get_ticks_msec()
	_materials()
	_tiempo("materiales", t0)
	nav_region = NavigationRegion3D.new()
	add_child(nav_region)
	_house = Node3D.new()
	nav_region.add_child(_house)
	_stairs_plan()
	for key in ["sotano", "baja", "alta", "atico"]:
		_level(key)
	_build_stairs()
	_roof()
	_ornatos_fachada()
	_abandono_exterior()
	_tiempo("casa", t0)
	_exterior()
	_tiempo("exterior", t0)
	_markers()
	_portals()
	_decorate()
	_tiempo("decorado", t0)
	_merge_static()
	_optimizar()
	_tiempo("fusion", t0)

func _tiempo(paso: String, t0: int) -> void:
	print("ZAREK paso %s hasta %d ms" % [paso, Time.get_ticks_msec() - t0])

func _optimizar() -> void:
	_oclusores()
	# los muebles y objetos de dentro van en la capa 2: la luna no calcula su sombra (el tejado ya la tapa);
	# la linterna y las lámparas sí
	var dentro := house_rect.grow(0.5)
	for g in find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		var en_casa := dentro.has_point(Vector2(gi.global_position.x, gi.global_position.z))
		# piezas sueltas hechas por código (platos, cubiertos, libros, botellas...): alcance según tamaño
		if gi.visibility_range_end <= 0.0 and gi.get_parent() is RigidBody3D:
			var lado := gi.get_aabb().size.length() * gi.global_transform.basis.get_scale().x
			gi.visibility_range_end = 8.0 if lado < 0.4 else (14.0 if lado < 1.0 else 24.0)
			gi.visibility_range_end_margin = 1.5
			if en_casa:
				gi.layers = 2
			continue
		if gi.owner != null and en_casa:
			gi.layers = 2
		elif not en_casa and (gi.owner != null or gi is MultiMeshInstance3D):
			gi.layers = 4
	for l in find_children("*", "Light3D", true, false):
		if not (l is DirectionalLight3D):
			(l as Light3D).distance_fade_enabled = true
			(l as Light3D).distance_fade_begin = 22.0
			(l as Light3D).distance_fade_length = 6.0
			(l as Light3D).distance_fade_shadow = 12.0

# ---------------- materiales ----------------
func _plain(col: Color, rough := 0.85, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	return m

func _tex_mat(img: Image, col: Color, rough: float, scale: float, normal := 0.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	img.generate_mipmaps()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.albedo_color = col
	m.roughness = rough
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(scale, scale, scale)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if normal > 0.0:
		var n: Image = img.duplicate()
		n.clear_mipmaps()
		n.convert(Image.FORMAT_RGBA8)
		n.bump_map_to_normal_map(3.0)
		n.generate_mipmaps()
		m.normal_enabled = true
		m.normal_texture = ImageTexture.create_from_image(n)
		m.normal_scale = normal
	return m

func _noise(freq: float, seed_v: int, oct := 4) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed = seed_v
	n.frequency = freq
	n.fractal_octaves = oct
	return n

## Papel tapiz victoriano (damasco).
func _damask(base: Color, motif: Color, seed_v: int) -> Image:
	var s := 256
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	var st := _noise(0.015, seed_v, 4)
	for y in s:
		for x in s:
			var u := float(x) / s * TAU * 2.0
			var v := float(y) / s * TAU * 2.0
			var d := sin(u) * sin(v * 0.5 + sin(u) * 0.8)
			var flower := smoothstep(0.55, 0.75, absf(d)) * 0.8 + smoothstep(0.9, 1.0, absf(cos(u * 0.5) * cos(v * 0.25))) * 0.4
			var c := base.lerp(motif, clampf(flower, 0.0, 1.0))
			if x % 128 < 2:
				c = c.lerp(motif, 0.5)
			var k := 0.78 + 0.32 * (st.get_noise_2d(x, y) * 0.5 + 0.5)
			img.set_pixel(x, y, Color(c.r * k, c.g * k, c.b * k))
	return img

func _planks(base: Color, w := 32) -> Image:
	var s := 256
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	var g := _noise(0.02, 3)
	for y in s:
		var plank := y / w
		var off := (plank * 97) % s
		for x in s:
			var gx := float((x + off) % s)
			var gr := g.get_noise_2d(gx * 0.12, y * 3.0) * 0.5 + 0.5
			var k := (0.75 + 0.35 * gr) * (0.85 + 0.15 * float((plank * 37) % 5) / 4.0)
			if y % w < 1 or (x + off) % 128 < 1:
				k *= 0.4
			img.set_pixel(x, y, Color(base.r * k, base.g * k, base.b * k))
	return img

func _noise_img(base: Color, freq: float, amp: float, seed_v: int, sz := 128) -> Image:
	var img := Image.create(sz, sz, false, Image.FORMAT_RGB8)
	var n := _noise(freq, seed_v, 5)
	for y in sz:
		for x in sz:
			var k := 1.0 + amp * n.get_noise_2d(x, y)
			img.set_pixel(x, y, Color(base.r * k, base.g * k, base.b * k))
	return img

func _siding(base: Color) -> Image:
	var s := 128
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	var n := _noise(0.05, 8)
	for y in s:
		for x in s:
			var k := 0.85 + 0.15 * n.get_noise_2d(x, y)
			if y % 16 >= 14:
				k *= 0.55
			img.set_pixel(x, y, Color(base.r * k, base.g * k, base.b * k))
	return img

func _checker() -> Image:
	var s := 128
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	var n := _noise(0.08, 5)
	for y in s:
		for x in s:
			var c := Color(0.75, 0.72, 0.66) if ((x / 32) + (y / 32)) % 2 == 0 else Color(0.12, 0.11, 0.11)
			var k := 0.9 + 0.12 * n.get_noise_2d(x, y)
			if x % 32 < 1 or y % 32 < 1:
				k *= 0.6
			img.set_pixel(x, y, Color(c.r * k, c.g * k, c.b * k))
	return img

func _stone(base: Color) -> Image:
	var s := 128
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	var n := _noise(0.09, 6)
	for y in s:
		var row := y / 24
		for x in s:
			var off := 20 if row % 2 else 0
			var k := 0.8 + 0.25 * n.get_noise_2d(x, y)
			if y % 24 < 2 or (x + off) % 40 < 2:
				k *= 0.45
			img.set_pixel(x, y, Color(base.r * k, base.g * k, base.b * k))
	return img

func _shingles() -> Image:
	var s := 128
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	var n := _noise(0.1, 9)
	for y in s:
		var row := y / 12
		for x in s:
			var off := 8 if row % 2 else 0
			var k := 0.75 + 0.25 * n.get_noise_2d(x, y)
			var fx := float((x + off) % 16) / 16.0
			if y % 12 > 9:
				k *= 0.5
			k *= 0.85 + 0.15 * sin(fx * PI)
			img.set_pixel(x, y, Color(0.2 * k, 0.17 * k, 0.2 * k))
	return img

## Material PBR con texturas fotográficas CC0 (ambientCG) de res://zarek/texturas/<id>/.
## escala = repeticiones por metro (proyección triplanar en coordenadas del mundo).
## Material de fachada (fachada.gdshader): sillería con churretes, base húmeda y manchas.
func _fachada_mat(id: String, escala: float, tinte: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://zarek/fachada.gdshader")
	var base := "res://zarek/texturas/%s/" % id
	m.set_shader_parameter("c_tex", load(base + "color.jpg"))
	m.set_shader_parameter("n_tex", load(base + "normal.jpg"))
	m.set_shader_parameter("r_tex", load(base + "rough.jpg"))
	if ResourceLoader.exists(base + "ao.jpg"):
		m.set_shader_parameter("ao_tex", load(base + "ao.jpg"))
	var nt := NoiseTexture2D.new()
	nt.width = 512
	nt.height = 512
	nt.seamless = true
	nt.generate_mipmaps = true
	var fn := FastNoiseLite.new()
	fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	fn.frequency = 0.03
	fn.fractal_octaves = 4
	nt.noise = fn
	m.set_shader_parameter("ruido", nt)
	m.set_shader_parameter("escala", escala)
	m.set_shader_parameter("tinte", Vector3(tinte.r, tinte.g, tinte.b))
	return m

var _ruido_suelo: NoiseTexture2D
## Suelo exterior sin repetición visible (ver suelo.gdshader): base, manchas de una segunda capa y de una tercera.
func _suelo(a: String, b: String, c: String, escala: float, t1: Color, t2: Color, t3: Color, k2: float, k3: float) -> ShaderMaterial:
	if _ruido_suelo == null:
		_ruido_suelo = NoiseTexture2D.new()
		_ruido_suelo.width = 512
		_ruido_suelo.height = 512
		_ruido_suelo.seamless = true
		_ruido_suelo.generate_mipmaps = true
		var fn := FastNoiseLite.new()
		fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		fn.frequency = 0.008
		fn.fractal_octaves = 5
		_ruido_suelo.noise = fn
	var m := ShaderMaterial.new()
	m.shader = load("res://zarek/suelo.gdshader")
	var capas := [[a, "1"], [b, "2"], [c, "3"]]
	for cp in capas:
		var base := "res://zarek/texturas/%s/" % cp[0]
		m.set_shader_parameter("c" + cp[1], load(base + "color.jpg"))
		if ResourceLoader.exists(base + "normal.jpg"):
			m.set_shader_parameter("n" + cp[1], load(base + "normal.jpg"))
		if ResourceLoader.exists(base + "height.jpg"):
			m.set_shader_parameter("h" + cp[1], load(base + "height.jpg"))
			if cp[1] == "1":
				m.set_shader_parameter("con_alturas", true)
		if cp[1] == "1" and ResourceLoader.exists(base + "ao.jpg"):
			m.set_shader_parameter("a1", load(base + "ao.jpg"))
	if ResourceLoader.exists("res://zarek/texturas/%s/rough.jpg" % a):
		m.set_shader_parameter("r1", load("res://zarek/texturas/%s/rough.jpg" % a))
	m.set_shader_parameter("ruido", _ruido_suelo)
	m.set_shader_parameter("escala", escala)
	m.set_shader_parameter("tinte1", Vector3(t1.r, t1.g, t1.b))
	m.set_shader_parameter("tinte2", Vector3(t2.r, t2.g, t2.b))
	m.set_shader_parameter("tinte3", Vector3(t3.r, t3.g, t3.b))
	m.set_shader_parameter("cantidad2", k2)
	m.set_shader_parameter("cantidad3", k3)
	return m

func _pbr(id: String, escala: float, tinte := Color(1, 1, 1), rough_mul := 1.0, normal := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	var base := "res://zarek/texturas/%s/" % id
	if ResourceLoader.exists(base + "color.jpg"):
		m.albedo_texture = load(base + "color.jpg")
	m.albedo_color = tinte
	if ResourceLoader.exists(base + "rough.jpg"):
		m.roughness_texture = load(base + "rough.jpg")
		m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
		m.roughness = rough_mul
	else:
		m.roughness = 0.8 * rough_mul
	if normal > 0.0 and ResourceLoader.exists(base + "normal.jpg"):
		m.normal_enabled = true
		m.normal_texture = load(base + "normal.jpg")
		m.normal_scale = normal
	if ResourceLoader.exists(base + "ao.jpg"):
		m.ao_enabled = true
		m.ao_texture = load(base + "ao.jpg")
		m.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
		m.ao_light_affect = 0.35
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 4.0
	m.uv1_scale = Vector3(escala, escala, escala)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m

## Papel tapiz victoriano de rayas tono sobre tono con filete dorado.
func _rayas(base: Color, seed_v: int) -> Image:
	var sz := 512
	var img := Image.create(sz, sz, false, Image.FORMAT_RGB8)
	var nz := _noise(0.02, seed_v, 3)
	var fino := _noise(0.4, seed_v + 7, 1)
	var oro := Color(0.55, 0.45, 0.25)
	for y in sz:
		for x in sz:
			var t := x % 64
			var c := base
			if t >= 40:
				c = base.darkened(0.22)
			if t == 39 or t == 40 or t == 63 or t == 0:
				c = base.lerp(oro, 0.45)
			elif t == 51 or t == 52:
				c = base.lerp(oro, 0.2)
			var k := 1.0 + nz.get_noise_2d(x, y) * 0.12 + fino.get_noise_2d(x, y) * 0.05
			img.set_pixel(x, y, Color(c.r * k, c.g * k, c.b * k))
	return img

## Papel tapiz: rayas + desconchones y suciedad fotográficos encima (ambientCG Wallpaper001C).
func _papel(img: Image, tinte: Color) -> StandardMaterial3D:
	var m := _tex_mat(img, tinte, 0.9, 0.42, 0.0)
	var base := "res://zarek/texturas/Wallpaper001C/"
	if ResourceLoader.exists(base + "color.jpg"):
		m.detail_enabled = true
		m.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
		m.detail_albedo = load(base + "color.jpg")
		m.detail_uv_layer = BaseMaterial3D.DETAIL_UV_1
		m.normal_enabled = true
		m.normal_texture = load(base + "normal.jpg")
		m.normal_scale = 1.0
		m.roughness_texture = load(base + "rough.jpg")
	return m

func _materials() -> void:
	var papers := [Color(0.33, 0.15, 0.14), Color(0.17, 0.24, 0.2), Color(0.2, 0.22, 0.28), Color(0.44, 0.38, 0.28)]
	for i in papers.size():
		_mat["papel%d" % i] = _papel(_rayas(papers[i], 30 + i), Color(1.15, 1.15, 1.15))
	_mat["cortina"] = _pbr("Fabric085", 1.6, Color(0.42, 0.1, 0.11), 1.0, 1.4)
	_mat["cortina"].cull_mode = BaseMaterial3D.CULL_DISABLED
	var cristal := _plain(Color(0.2, 0.2, 0.17, 0.5), 0.35, 0.2)
	cristal.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat["cristal"] = cristal
	var persa := StandardMaterial3D.new()
	if ResourceLoader.exists("res://zarek/texturas/alfombra_persa.jpg"):
		persa.albedo_texture = load("res://zarek/texturas/alfombra_persa.jpg")
	persa.albedo_color = Color(0.9, 0.85, 0.8)
	persa.roughness = 1.0
	_mat["persa"] = persa
	_mat["revestimiento"] = _pbr("Wood094", 0.6, Color(0.5, 0.36, 0.27), 0.7)
	_mat["parquet"] = _pbr("WoodFloor070", 0.45, Color(0.64, 0.58, 0.54), 0.8)
	_mat["baldosa"] = _pbr("Tiles140", 0.5, Color(1, 1, 1), 0.9)
	_mat["piedra"] = _pbr("Bricks108A", 0.4, Color(0.8, 0.78, 0.75), 1.0, 1.2)
	_mat["yeso"] = _pbr("Plaster007", 0.35, Color(0.85, 0.8, 0.72), 1.0)
	_mat["techo"] = _pbr("PaintedPlaster017", 0.3, Color(0.86, 0.8, 0.68), 1.0, 0.8)
	_mat["fachada"] = _fachada_mat("Bricks066", 0.32, Color(0.66, 0.64, 0.58))
	_mat["fachada"].set_shader_parameter("suciedad", 1.35)
	var torre := StandardMaterial3D.new()
	torre.albedo_texture = load("res://zarek/texturas/Bricks066/color.jpg")
	torre.albedo_color = Color(0.5, 0.48, 0.44)
	torre.normal_enabled = true
	torre.normal_texture = load("res://zarek/texturas/Bricks066/normal.jpg")
	torre.roughness_texture = load("res://zarek/texturas/Bricks066/rough.jpg")
	torre.uv1_scale = Vector3(8.5, 4.4, 1)
	torre.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mat["fachada_torre"] = torre
	_mat["piedra_clara"] = _fachada_mat("Travertine009", 0.45, Color(0.66, 0.63, 0.56))
	_mat["piedra_clara"].set_shader_parameter("suciedad", 1.25)
	_mat["contraventana"] = _pbr("Wood049", 0.8, Color(0.16, 0.2, 0.17), 0.7)
	_mat["tejado"] = _pbr("RoofingTiles013A", 0.5, Color(0.9, 0.9, 0.95), 0.9)
	_mat["cesped"] = _suelo("Ground037", "ScatteredLeaves009", "Ground110", 0.25, Color(0.5, 0.52, 0.42), Color(0.66, 0.62, 0.56), Color(0.75, 0.72, 0.68), 0.3, 0.2)
	_mat["bosque"] = _suelo("ScatteredLeaves009", "Ground085", "Ground037", 0.25, Color(0.7, 0.68, 0.62), Color(0.55, 0.5, 0.45), Color(0.48, 0.52, 0.4), 0.32, 0.28)
	_mat["tierra"] = _suelo("Ground110", "Ground085", "ScatteredLeaves009", 0.35, Color(0.85, 0.82, 0.78), Color(0.62, 0.56, 0.5), Color(0.66, 0.62, 0.56), 0.35, 0.15)
	_mat["agua"] = _plain(Color(0.03, 0.05, 0.07), 0.05, 0.3)
	_mat["barro"] = _pbr("Ground085", 0.35, Color(0.35, 0.3, 0.26), 0.6)
	_mat["madera_vieja"] = _pbr("Wood049", 0.5, Color(0.62, 0.57, 0.52), 0.9, 1.2)
	_mat["madera"] = _pbr("Wood066", 0.55, Color(0.8, 0.68, 0.6), 0.75)
	_mat["madera_clara"] = _pbr("WoodFloor043", 0.4, Color(0.9, 0.85, 0.8), 0.9)
	_mat["moldura"] = _pbr("Plaster007", 0.8, Color(0.78, 0.73, 0.64), 0.7)
	_mat["cimiento"] = _pbr("Bricks106A", 0.4, Color(0.8, 0.78, 0.75), 1.0)
	# sótano: muros de sillería ennegrecida, suelo de losas, túneles en roca viva, hierro oxidado
	_mat["muro_sotano"] = _pbr("Bricks106A", 0.42, Color(0.5, 0.46, 0.42), 1.0, 1.3)
	_mat["losa"] = _pbr("Rock030", 0.3, Color(0.75, 0.72, 0.68), 1.0, 1.2)
	_mat["roca"] = _pbr("Rock022", 0.3, Color(0.7, 0.66, 0.6), 1.0, 1.4)
	_mat["hierro"] = _pbr("Metal063", 0.6, Color(0.42, 0.33, 0.27), 1.0, 1.0)
	_mat["hierro"].metallic = 0.6
	_mat["tablas"] = _pbr("Planks037A", 0.45, Color(1, 1, 1), 0.95)
	_mat["oscuro"] = _plain(Color(0.05, 0.04, 0.04), 0.8)
	_mat["tela_roja"] = _pbr("Fabric028", 1.2, Color(0.75, 0.2, 0.2), 1.0)
	_mat["tela_verde"] = _pbr("Fabric028", 1.2, Color(0.25, 0.5, 0.32), 1.0)
	_mat["sabana"] = _pbr("Fabric028", 1.5, Color(0.95, 0.92, 0.85), 1.0, 1.5)
	_mat["alfombra"] = _pbr("Fabric028", 0.8, Color(0.45, 0.3, 0.55), 1.0, 1.2)
	_mat["metal"] = _plain(Color(0.4, 0.36, 0.3), 0.35, 0.85)
	_mat["oro"] = _plain(Color(0.9, 0.66, 0.25), 0.3, 1.0)
	_mat["marmol"] = _pbr("Marble012", 0.4, Color(0.95, 0.93, 0.9), 0.5)
	_mat["vidrio"] = _plain(Color(0.07, 0.09, 0.12), 0.05, 0.6)
	var lit := _plain(Color(1.0, 0.75, 0.4), 0.4)
	lit.emission_enabled = true
	lit.emission = Color(1.0, 0.62, 0.28)
	lit.emission_energy_multiplier = 1.4
	_mat["ventana_luz"] = lit
	var gold := _plain(Color(0.95, 0.7, 0.25), 0.3, 0.9)
	gold.emission_enabled = true
	gold.emission = Color(1.0, 0.65, 0.2)
	gold.emission_energy_multiplier = 1.6
	_mat["sello"] = gold
	var salt := _plain(Color(0.92, 0.92, 0.88), 0.9)
	salt.emission_enabled = true
	salt.emission = Color(0.6, 0.6, 0.58)
	salt.emission_energy_multiplier = 0.35
	_mat["sal"] = salt
	var fire := _plain(Color(1, 0.5, 0.15), 1.0)
	fire.emission_enabled = true
	fire.emission = Color(1.0, 0.45, 0.1)
	fire.emission_energy_multiplier = 3.5
	_mat["fuego"] = fire
	_mat["seto"] = _tex_mat(_noise_img(Color(0.09, 0.18, 0.08), 0.12, 0.45, 21), Color(1, 1, 1), 1.0, 0.5, 0.8)
	_mat["corteza"] = _pbr("Bark016", 0.8, Color(0.8, 0.75, 0.7), 1.0)
	_mat["pino"] = _plain(Color(0.07, 0.15, 0.09), 0.95)

# ---------------- primitivas ----------------
func box(size: Vector3, pos: Vector3, mat: Material, collide := true, parent: Node3D = null, shadow := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(parent if parent else _house).add_child(mi)
	if collide:
		var sb := StaticBody3D.new()
		sb.collision_layer = 1
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		sb.add_child(cs)
		mi.add_child(sb)
	return mi

func cyl(r_top: float, r_bot: float, h: float, pos: Vector3, mat: Material, parent: Node3D = null, seg := 12) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bot
	cm.height = h
	cm.radial_segments = seg
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	(parent if parent else _house).add_child(mi)
	return mi

# ---------------- escaleras ----------------
var stairs_spec := [
	{"key": "baja", "r": [8.0, 7.0, 10.0, 9.4], "low": "s", "from": 0, "to": 1},
	{"key": "baja", "r": [16.0, 5.6, 17.0, 8.0], "low": "s", "from": 0, "to": 1},
	{"key": "baja", "r": [16.0, 9.9, 17.0, 12.0], "low": "s", "from": -1, "to": 0},
]

func _stairs_plan() -> void:
	for s in stairs_spec:
		var a := cell_to_world(s.key, s.r[0], s.r[1])
		var b := cell_to_world(s.key, s.r[2], s.r[3])
		var top_level: int = s.to
		if not _hole.has(top_level):
			_hole[top_level] = []
		_hole[top_level].append(Rect2(a.x, a.z, b.x - a.x, b.z - a.z))

## Zonas de escalera (con rellano a cada lado) donde no se puede poner nada.
func stair_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for st in stairs_spec:
		var a := cell_to_world(st.key, st.r[0], st.r[1])
		var b := cell_to_world(st.key, st.r[2], st.r[3])
		# la escalera y un rellano de 1,4 m en cada extremo (a lo largo de la escalera)
		out.append(Rect2(a.x - 0.3, a.z - 1.4, b.x - a.x + 0.6, b.z - a.z + 2.8))
	return out

func _build_stairs() -> void:
	for s in stairs_spec:
		var a := cell_to_world(s.key, s.r[0], s.r[1])
		var b := cell_to_world(s.key, s.r[2], s.r[3])
		var y0 := lvl_y(s.from)
		var y1 := lvl_y(s.to)
		var w := b.x - a.x
		var run := b.z - a.z
		var steps := int(run / 0.3)
		var low_south: bool = s.low == "s"
		var rise := (y1 - y0) / steps
		var dep := run / steps
		var cx := (a.x + b.x) * 0.5
		for i in steps:
			var t := (i + 0.5) / steps
			var z := (b.z - run * t) if low_south else (a.z + run * t)
			var y := y0 + (y1 - y0) * (i + 1.0) / steps
			# peldaño macizo con huella saliente y alfombra que baja por el centro
			box(Vector3(w - 0.1, rise, dep + 0.01), Vector3(cx, y - rise * 0.5, z), _mat.madera, false, null, true)
			box(Vector3(w - 0.06, 0.035, dep + 0.05), Vector3(cx, y - 0.017, z + (0.02 if low_south else -0.02)), _mat.madera_clara, false, null, false)
			box(Vector3(w * 0.58, 0.012, dep + 0.06), Vector3(cx, y + 0.006, z), _mat.cortina, false, null, false)
			var frente := z + dep * 0.5 * (1.0 if low_south else -1.0)
			box(Vector3(w * 0.58, rise, 0.012), Vector3(cx, y - rise * 0.5, frente + (0.03 if low_south else -0.03)), _mat.cortina, false, null, false)
			# balaustres torneados a cada lado
			for sx in [a.x + 0.09, b.x - 0.09]:
				var bal := cyl(0.016, 0.024, 0.86, Vector3(sx, y + 0.43, z), _mat.madera, null, 6)
				bal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		var largo := Vector2(run, y1 - y0).length()
		var incl := atan2(y1 - y0, run) * (1.0 if low_south else -1.0)
		var mid := Vector3(cx, (y0 + y1) * 0.5, (a.z + b.z) * 0.5)
		# zancas a los lados y techo inclinado debajo (la escalera no flota)
		for sx in [a.x + 0.04, b.x - 0.04]:
			var zan := box(Vector3(0.08, 0.42, largo + 0.3), mid + Vector3(sx - cx, -0.12, 0), _mat.madera, false)
			zan.rotation.x = incl
		var bajo := box(Vector3(w, 0.06, largo), mid + Vector3(0, -0.36, 0), _mat.revestimiento, false)
		bajo.rotation.x = incl
		# pasamanos y postes de arranque y llegada
		var lo_z := b.z if low_south else a.z
		var hi_z := a.z if low_south else b.z
		for sx in [a.x + 0.09, b.x - 0.09]:
			var pm := cyl(0.035, 0.035, largo + 0.2, mid + Vector3(sx - cx, 0.92, 0), _mat.madera, null, 8)
			pm.rotation.x = PI * 0.5 + incl
			for ext in [[lo_z + (0.15 if low_south else -0.15), y0], [hi_z, y1]]:
				box(Vector3(0.15, 1.15, 0.15), Vector3(sx, float(ext[1]) + 0.575, float(ext[0])), _mat.madera, false)
				box(Vector3(0.21, 0.06, 0.21), Vector3(sx, float(ext[1]) + 1.18, float(ext[0])), _mat.madera, false, null, false)
				var bola := cyl(0.06, 0.05, 0.1, Vector3(sx, float(ext[1]) + 1.26, float(ext[0])), _mat.madera, null, 8)
				bola.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# barandilla en la planta de arriba: los dos lados largos del hueco y el extremo que da al vacío
		if s.to >= 0:
			var bordes := [[Vector3(a.x, y1, a.z), Vector3(a.x, y1, b.z)], [Vector3(b.x, y1, a.z), Vector3(b.x, y1, b.z)]]
			var fondo_z := b.z if low_south else a.z
			bordes.append([Vector3(a.x, y1, fondo_z), Vector3(b.x, y1, fondo_z)])
			for bd in bordes:
				var p0: Vector3 = bd[0]
				var p1: Vector3 = bd[1]
				var lg := p0.distance_to(p1)
				var md := (p0 + p1) * 0.5
				var horiz := absf(p1.x - p0.x) > 0.01
				box(Vector3(lg, 0.07, 0.09) if horiz else Vector3(0.09, 0.07, lg), md + Vector3(0, 0.98, 0), _mat.madera, false)
				box(Vector3(lg, 0.06, 0.12) if horiz else Vector3(0.12, 0.06, lg), md + Vector3(0, 0.03, 0), _mat.madera, false, null, false)
				var nb := int(lg / 0.22)
				for i in nb:
					var bp := p0.lerp(p1, (i + 0.5) / nb)
					var bal := cyl(0.016, 0.024, 0.92, bp + Vector3(0, 0.49, 0), _mat.madera, null, 6)
					bal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
				# pared invisible para no caer al hueco
				var col := box(Vector3(lg, 1.1, 0.1) if horiz else Vector3(0.1, 1.1, lg), md + Vector3(0, 0.55, 0), _mat.madera, true)
				col.visible = false
				col.set_meta("dyn", true)
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		var length := Vector2(run, y1 - y0).length()
		bs.size = Vector3(w, 0.1, length)
		cs.shape = bs
		sb.add_child(cs)
		_house.add_child(sb)
		sb.position = Vector3((a.x + b.x) * 0.5, (y0 + y1) * 0.5 - 0.05, (a.z + b.z) * 0.5)
		var ang := atan2(y1 - y0, run)
		sb.rotation.x = ang if low_south else -ang

# ---------------- plantas ----------------
func _level(key: String) -> void:
	var p: Dictionary = plan[key]
	var level := int(p.nivel)
	var y := lvl_y(level)
	var o: Array = p.origen
	var zl: Array = p.zonas
	var edges := {}
	var paper_i := 0
	for z in zl:
		var name: String = z[0]
		var t: String = z[1]
		var r := Rect2((float(o[0]) + float(z[2])) * CELL, (float(o[1]) + float(z[3])) * CELL, float(z[4]) * CELL, float(z[5]) * CELL)
		var id := rooms.size()
		var paper := "papel%d" % (paper_i % 4)
		paper_i += 1
		if t == "servicio":
			paper = "yeso"
		if t in ["sotano", "agua"]:
			paper = "muro_sotano"
		if t in ["tunel", "roca"]:
			paper = "roca"
		if t == "epicentro":
			paper = "papel0"
		if level == 2 and t in ["servicio", "epicentro"]:
			paper = "tablas"
		rooms.append({"name": name, "type": t, "level": level, "rect": r, "y": y, "id": id, "paper": paper})
		if t == "epicentro" and level == 1:
			epicentro_room = id
		if level == 0 and t != "jardin":
			house_rect = r if house_rect.size == Vector2.ZERO else house_rect.merge(r)
		var fmat: Material = _mat.parquet
		if t in ["servicio", "pasillo"]:
			fmat = _mat.baldosa if level >= 0 else _mat.piedra
		if t in ["sotano", "agua"]:
			fmat = _mat.losa
		if t in ["tunel", "roca"]:
			fmat = _mat.roca
		if t == "jardin":
			fmat = _mat.madera_clara
		if level == 2 and t != "jardin":
			fmat = _mat.tablas
		for fr in _split_holes(r, _hole.get(level, [])):
			box(Vector3(fr.size.x, 0.2, fr.size.y), Vector3(fr.position.x + fr.size.x * 0.5, y - 0.1, fr.position.y + fr.size.y * 0.5), fmat, true, null, false)
		if t != "jardin" and level < 2:
			var ceil_mat: Material = _mat.techo if level >= 0 else (_mat.tablas if t in ["sotano", "agua"] else _mat.roca)
			for fr in _split_holes(r, _hole.get(level + 1, [])):
				box(Vector3(fr.size.x, 0.1, fr.size.y), Vector3(fr.position.x + fr.size.x * 0.5, y + WALL_H - 0.06, fr.position.y + fr.size.y * 0.5), ceil_mat, false, null, true)
		elif level == 2:
			box(Vector3(r.size.x, 0.15, r.size.y), Vector3(r.get_center().x, y + 3.3, r.get_center().y), _mat.tablas, false)
		if t == "jardin":
			continue
		for i in int(z[4]):
			for side in [0, int(z[5])]:
				var k := "h:%d:%d" % [int(z[2]) + i, int(z[3]) + side]
				edges[k] = edges.get(k, []) + [id]
		for j in int(z[5]):
			for side in [0, int(z[4])]:
				var k := "v:%d:%d" % [int(z[2]) + side, int(z[3]) + j]
				edges[k] = edges.get(k, []) + [id]
	var door_set := {}
	for d in p.get("puertas", []):
		door_set["%s:%d:%d" % [d[0], int(d[1]), int(d[2])]] = true
	# las celdas de balcón también abren hueco
	var wall_h := WALL_H if level < 2 else 3.3
	for k in edges:
		var parts: PackedStringArray = k.split(":")
		var horiz := parts[0] == "h"
		var cx := int(parts[1])
		var cy := int(parts[2])
		var ids: Array = edges[k]
		var a := Vector3((float(o[0]) + cx) * CELL, y, (float(o[1]) + cy) * CELL)
		var exterior := _unique(ids).size() == 1
		var room_a: Dictionary = rooms[ids[0]]
		var is_door := door_set.has(k)
		var window: bool = exterior and level >= 0 and level < 2 and not is_door and ((cx + cy) % 2 == 1) and room_a.type != "tunel"
		_wall_unit(a, horiz, wall_h, _mat[room_a.paper], exterior, is_door, window, level, _unique(ids))

func _unique(a: Array) -> Array:
	var out: Array = []
	for v in a:
		if not v in out:
			out.append(v)
	return out

func _split_holes(r: Rect2, holes: Array) -> Array:
	var out: Array = [r]
	for h in holes:
		var hr: Rect2 = h
		var nxt: Array = []
		for q in out:
			var qr: Rect2 = q
			if not qr.intersects(hr):
				nxt.append(qr)
				continue
			var i := qr.intersection(hr)
			if i.position.y > qr.position.y:
				nxt.append(Rect2(qr.position.x, qr.position.y, qr.size.x, i.position.y - qr.position.y))
			if i.end.y < qr.end.y:
				nxt.append(Rect2(qr.position.x, i.end.y, qr.size.x, qr.end.y - i.end.y))
			if i.position.x > qr.position.x:
				nxt.append(Rect2(qr.position.x, i.position.y, i.position.x - qr.position.x, i.size.y))
			if i.end.x < qr.end.x:
				nxt.append(Rect2(i.end.x, i.position.y, qr.end.x - i.end.x, i.size.y))
		out = nxt
	return out

func _wall_unit(a: Vector3, horiz: bool, h: float, mat: Material, exterior: bool, is_door: bool, window: bool, level: int, ids: Array) -> void:
	var len := CELL
	var center := a + (Vector3(len * 0.5, 0, 0) if horiz else Vector3(0, 0, len * 0.5))
	var along := Vector3(1, 0, 0) if horiz else Vector3(0, 0, 1)
	var thick := WT if not exterior else 0.45
	var pieces: Array = []
	if is_door:
		var gap := 1.5
		var dintel := 2.5
		if exterior and level == 0 and _es_entrada(center):
			gap = 2.1
			dintel = h
		pieces = [[0.0, (len - gap) * 0.5, 0.0, h], [(len + gap) * 0.5, len, 0.0, h], [(len - gap) * 0.5, (len + gap) * 0.5, dintel, h]]
	elif window:
		# hueco de 1,6 × 2,0 m: exactamente el del cristal y el marco (sin franjas de muro dentro del recerco)
		pieces = [[0.0, 0.4, 0.0, h], [len - 0.4, len, 0.0, h], [0.4, len - 0.4, 0.0, 0.9], [0.4, len - 0.4, 2.9, h]]
	else:
		pieces = [[0.0, len, 0.0, h]]
	var inward := Vector3.ZERO
	if exterior:
		var r0: Dictionary = rooms[ids[0]]
		var rc: Vector2 = (r0.rect as Rect2).get_center()
		inward = Vector3(0, 0, signf(rc.y - a.z)) if horiz else Vector3(signf(rc.x - a.x), 0, 0)
	for pc in pieces:
		var l: float = pc[1] - pc[0]
		var hh: float = pc[3] - pc[2]
		if hh <= 0.01:
			continue
		var pos: Vector3 = a + along * (pc[0] + l * 0.5) + Vector3(0, pc[2] + hh * 0.5, 0)
		if exterior and level >= 0:
			var half := Vector3(l, hh, thick * 0.5) if horiz else Vector3(thick * 0.5, hh, l)
			box(half, pos + inward * thick * 0.25, mat, true)
			box(half, pos - inward * thick * 0.25, _mat.fachada, false)
			var fuera: Vector3 = a + along * (pc[0] + l * 0.5) - inward * (thick * 0.5 + 0.05)
			if level == 0 and pc[2] < 0.01:
				var zs := Vector3(l, 1.0, 0.12) if horiz else Vector3(0.12, 1.0, l)
				box(zs, fuera + Vector3(0, 0.3, 0), _mat.cimiento, false, null, false)
			if pc[2] < 0.01:
				var im := Vector3(l, 0.22, 0.1) if horiz else Vector3(0.1, 0.22, l)
				box(im, fuera + Vector3(0, -0.05 if level > 0 else 0.86, 0), _mat.moldura, false, null, false)
		else:
			box(Vector3(l, hh, thick) if horiz else Vector3(thick, hh, l), pos, mat, true)
	if level >= 0 and level < 2 and not is_door:
		var off := inward * 0.03 if exterior else Vector3.ZERO
		var rev_h := 1.1 if not window else 0.86
		var wz := Vector3(len, rev_h, thick + 0.05) if horiz else Vector3(thick + 0.05, rev_h, len)
		box(wz, center + Vector3(0, rev_h * 0.5, 0) + off, _mat.revestimiento, false, null, false)
		# paneles del revestimiento: montantes y travesaños en relieve
		for k in 4:
			var st := Vector3(0.07, rev_h - 0.3, thick + 0.085) if horiz else Vector3(thick + 0.085, rev_h - 0.3, 0.07)
			box(st, a + along * (len * k / 3.0 + (0.035 if k == 0 else (-0.035 if k == 3 else 0.0))) + Vector3(0, 0.22 + (rev_h - 0.3) * 0.5, 0) + off, _mat.madera, false, null, false)
		for hy in [0.25, rev_h - 0.08]:
			var rl := Vector3(len, 0.04, thick + 0.085) if horiz else Vector3(thick + 0.085, 0.04, len)
			box(rl, center + Vector3(0, hy, 0) + off, _mat.madera, false, null, false)
		# zócalo, guardasilla, riel de cuadros y cornisa en dos escalones
		for mol in [[0.11, 0.22, 0.1, "madera"], [rev_h + 0.03, 0.07, 0.12, "madera"], [h - 0.62, 0.045, 0.07, "madera"], [h - 0.2, 0.1, 0.16, "moldura"], [h - 0.085, 0.13, 0.3, "moldura"]]:
			if window and float(mol[0]) > 0.5 and float(mol[0]) < 3.0:
				continue
			var ms := Vector3(len, float(mol[1]), thick + float(mol[2])) if horiz else Vector3(thick + float(mol[2]), float(mol[1]), len)
			box(ms, center + Vector3(0, float(mol[0]), 0) + off, _mat[mol[3]], false, null, false)
	if is_door:
		_door(center, horiz, level, ids)
	if window:
		_window(center, horiz, thick, inward)

## Dirección de la luz de la luna (debe coincidir con la DirectionalLight del juego: rotación -38°, -55°).
const LUNA := Vector3(0.645, -0.616, -0.452)
const LUNA_H := Vector3(0.819, 0, -0.574)
var _mat_haz: StandardMaterial3D
var _mat_mancha: StandardMaterial3D

## Luz de luna que entra por una ventana: mancha con la forma de los cristales en el suelo y un haz tenue en el aire.
## Son mallas sin sombreado con mezcla aditiva: se ven igual en todos los móviles y no gastan luces.
func _haz_luna(c: Vector3, horiz: bool, inward: Vector3) -> void:
	if _mat_mancha == null:
		var img := Image.create(64, 96, false, Image.FORMAT_RGBA8)
		for y in 96:
			for x in 64:
				var u := x / 63.0
				var v := y / 95.0
				var marco := absf(u - 0.5) < 0.035 or absf(v - 0.35) < 0.03 or u < 0.05 or u > 0.95 or v < 0.04 or v > 0.96
				var borde := minf(minf(u, 1.0 - u), minf(v, 1.0 - v))
				var a := 0.0 if marco else clampf(borde * 9.0, 0.0, 1.0)
				img.set_pixel(x, y, Color(1, 1, 1, a))
		img.generate_mipmaps()
		_mat_mancha = StandardMaterial3D.new()
		_mat_mancha.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat_mancha.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat_mancha.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_mat_mancha.albedo_texture = ImageTexture.create_from_image(img)
		_mat_mancha.albedo_color = Color(0.42, 0.55, 0.9, 0.9)
		_mat_mancha.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mat_haz = StandardMaterial3D.new()
		_mat_haz.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat_haz.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat_haz.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_mat_haz.vertex_color_use_as_albedo = true
		_mat_haz.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mat_haz.disable_receive_shadows = true
	var eje: Vector3 = Vector3(1, 0, 0) if horiz else Vector3(0, 0, 1)
	var suelo := c.y + 0.015
	var esq := func(lado: float, h: float) -> Vector3:
		return c + eje * lado * 0.78 + inward * 0.05 + Vector3(0, h, 0)
	var al_suelo := func(p: Vector3) -> Vector3:
		var t := (p.y - suelo) / -LUNA.y
		return p + LUNA * t
	var w0: Vector3 = esq.call(-1.0, 0.92)
	var w1: Vector3 = esq.call(1.0, 0.92)
	var w2: Vector3 = esq.call(1.0, 2.88)
	var w3: Vector3 = esq.call(-1.0, 2.88)
	var f0: Vector3 = al_suelo.call(w0)
	var f1: Vector3 = al_suelo.call(w1)
	var f2: Vector3 = al_suelo.call(w2)
	var f3: Vector3 = al_suelo.call(w3)
	# mancha en el suelo (v = 0 abajo de la ventana)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var q := [f0, f1, f2, f3]
	var uv := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	for i in [0, 1, 2, 0, 2, 3]:
		st.set_uv(uv[i])
		st.set_normal(Vector3.UP)
		st.add_vertex(q[i])
	var mm := MeshInstance3D.new()
	mm.mesh = st.commit()
	mm.material_override = _mat_mancha
	mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mm.set_meta("dyn", true)
	_house.add_child(mm)
	# haz: cuatro caras de la ventana a la mancha, que se apagan hacia el suelo
	var sh := SurfaceTool.new()
	sh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cw := Color(0.16, 0.2, 0.32, 1.0) * 0.32
	var cf := Color(0, 0, 0, 0)
	for cara in [[w0, w1, f1, f0], [w3, w2, f2, f3], [w0, w3, f3, f0], [w1, w2, f2, f1]]:
		var cs := [cw, cw, cf, cf]
		for i in [0, 1, 2, 0, 2, 3]:
			sh.set_color(cs[i])
			sh.add_vertex(cara[i])
	var hm := MeshInstance3D.new()
	hm.mesh = sh.commit()
	hm.material_override = _mat_haz
	hm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hm.set_meta("dyn", true)
	_house.add_child(hm)

## Centros de todas las ventanas (para que cuadros y muebles altos no las tapen).
var ventanas: Array[Vector3] = []

func ventana_cerca(p: Vector3, radio: float) -> bool:
	for v in ventanas:
		if absf(v.y - p.y) < 2.0 and Vector2(v.x - p.x, v.z - p.z).length() < radio:
			return true
	return false

func _window(c: Vector3, horiz: bool, thick: float, inward: Vector3) -> void:
	ventanas.append(c)
	if level_of(c.y + 0.3) >= 0 and Vector3(LUNA_H.x, 0, LUNA_H.z).dot(inward) > 0.25:
		_haz_luna(c, horiz, inward)
	var lit := _rng.randf() < 0.04
	var glass := Vector3(1.6, 2.0, 0.04) if horiz else Vector3(0.04, 2.0, 1.6)
	box(glass, c + Vector3(0, 1.9, 0), _mat.ventana_luz if lit else _mat.cristal, true, null, false)
	var fr := Vector3(1.75, 0.1, thick + 0.1) if horiz else Vector3(thick + 0.1, 0.1, 1.75)
	box(fr, c + Vector3(0, 0.9, 0), _mat.moldura, false, null, false)
	box(fr, c + Vector3(0, 2.9, 0), _mat.moldura, false, null, false)
	# parteluces finos de una ventana de guillotina, en el plano del cristal
	var vb := Vector3(0.045, 2.0, 0.07) if horiz else Vector3(0.07, 2.0, 0.045)
	box(vb, c + Vector3(0, 1.9, 0), _mat.moldura, false, null, false)
	for hy in [1.55, 2.2]:
		var hb := Vector3(1.6, 0.045, 0.07) if horiz else Vector3(0.07, 0.045, 1.6)
		box(hb, c + Vector3(0, hy, 0), _mat.moldura, false, null, false)
	# marco interior alrededor del hueco
	var ej2: Vector3 = Vector3(1, 0, 0) if horiz else Vector3(0, 0, 1)
	for sj in [-1.0, 1.0]:
		var mj := Vector3(0.09, 2.0, 0.09) if horiz else Vector3(0.09, 2.0, 0.09)
		box(mj, c + ej2 * sj * 0.79 + Vector3(0, 1.9, 0), _mat.moldura, false, null, false)
	# por fuera: recerco de piedra clara con dintel y clave, alféizar sobre ménsulas, frontón (triangular en la
	# planta baja, cornisa recta con ménsulas arriba) y contraventanas de madera abiertas contra el muro
	var ej: Vector3 = Vector3(1, 0, 0) if horiz else Vector3(0, 0, 1)
	var fuera := -inward * (thick * 0.5 + 0.06)
	var pc: Material = _mat.piedra_clara
	for sj in [-1.0, 1.0]:
		var jb := Vector3(0.24, 2.3, 0.12) if horiz else Vector3(0.12, 2.3, 0.24)
		box(jb, c + ej * sj * 0.93 + fuera + Vector3(0, 1.9, 0), pc, false, null, false)
	var dintel := Vector3(2.1, 0.26, 0.13) if horiz else Vector3(0.13, 0.26, 2.1)
	box(dintel, c + fuera + Vector3(0, 3.13, 0), pc, false, null, false)
	var clave := Vector3(0.26, 0.42, 0.18) if horiz else Vector3(0.18, 0.42, 0.26)
	box(clave, c + fuera - inward * 0.03 + Vector3(0, 3.16, 0), pc, false, null, false)
	var al := Vector3(2.2, 0.1, 0.3) if horiz else Vector3(0.3, 0.1, 2.2)
	box(al, c - inward * (thick * 0.5 + 0.12) + Vector3(0, 0.84, 0), pc, false, null, false)
	for sj in [-0.7, 0.7]:
		var me := Vector3(0.14, 0.22, 0.18) if horiz else Vector3(0.18, 0.22, 0.14)
		box(me, c + ej * sj - inward * (thick * 0.5 + 0.1) + Vector3(0, 0.68, 0), pc, false, null, false)
	var nivel := level_of(c.y + 0.3)
	if nivel == 0:
		var fr2 := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(2.4, 0.55, 0.2)
		fr2.mesh = pm
		fr2.material_override = pc
		fr2.position = c + fuera - inward * 0.02 + Vector3(0, 3.55, 0)
		fr2.rotation.y = 0.0 if horiz else PI * 0.5
		_house.add_child(fr2)
	else:
		var cor := Vector3(2.4, 0.12, 0.32) if horiz else Vector3(0.32, 0.12, 2.4)
		box(cor, c + fuera - inward * 0.08 + Vector3(0, 3.33, 0), pc, false, null, false)
		for sj in [-1.05, 1.05]:
			var mn := Vector3(0.12, 0.3, 0.2) if horiz else Vector3(0.2, 0.3, 0.12)
			box(mn, c + ej * sj + fuera - inward * 0.04 + Vector3(0, 3.12, 0), pc, false, null, false)
	# abandono: algunas ventanas tapiadas con tablas clavadas
	if _rng.randf() < 0.22:
		for k in 3:
			var tabla := box(Vector3(2.0, 0.22, 0.04) if horiz else Vector3(0.04, 0.22, 2.0), Vector3.ZERO, _mat.madera_vieja, false, null, false)
			tabla.position = c + fuera - inward * 0.05 + Vector3(0, 1.3 + k * 0.6, 0)
			if horiz:
				tabla.rotation.z = _rng.randf_range(-0.35, 0.35)
			else:
				tabla.rotation.x = _rng.randf_range(-0.35, 0.35)
	for sj in [-1.0, 1.0]:
		var estado := _rng.randf()
		if estado < 0.12:
			continue  # contraventana que se perdió
		var hoja := Vector3(0.82, 2.15, 0.05) if horiz else Vector3(0.05, 2.15, 0.82)
		var cv := box(hoja, c + ej * sj * 1.5 + fuera + Vector3(0, 1.9, 0), _mat.contraventana, false, null, false)
		if estado < 0.3:
			# descolgada de un gozne: torcida y caída
			if horiz:
				cv.rotation.z = sj * _rng.randf_range(0.2, 0.45)
			else:
				cv.rotation.x = sj * _rng.randf_range(0.2, 0.45)
			cv.position.y -= 0.25
		# lamas de la persiana en relieve
		for k in 7:
			var lama := Vector3(0.7, 0.03, 0.035) if horiz else Vector3(0.035, 0.03, 0.7)
			box(lama, -inward * 0.03 + Vector3(0, 1.05 + k * 0.27 - 1.9, 0), _mat.contraventana, false, cv, false)
	# cortinas pesadas con pliegues, barra y galería
	var eje: Vector3 = Vector3(1, 0, 0) if horiz else Vector3(0, 0, 1)
	var dentro: Vector3 = c + inward * (thick * 0.5 + 0.13)
	for s in [-1.0, 1.0]:
		var mi := MeshInstance3D.new()
		mi.mesh = _cortina_mesh(int(s))
		mi.material_override = _mat.cortina
		mi.position = dentro + eje * s * 0.82 + Vector3(0, 0.03, 0)
		mi.rotation.y = 0.0 if horiz else PI * 0.5
		_house.add_child(mi)
	var barra := Vector3(2.5, 0.04, 0.04) if horiz else Vector3(0.04, 0.04, 2.5)
	box(barra, dentro + Vector3(0, 3.16, 0), _mat.oro, false, null, false)
	var gal := Vector3(2.4, 0.3, 0.14) if horiz else Vector3(0.14, 0.3, 2.4)
	box(gal, dentro + Vector3(0, 3.05, 0), _mat.tela_roja, false, null, false)

var _cortinas: Dictionary = {}
## Malla de una cortina recogida (0,7 m × 3,1 m) con pliegues; lado -1 o 1 cambia hacia dónde se recoge.
func _cortina_mesh(lado: int) -> ArrayMesh:
	if _cortinas.has(lado):
		return _cortinas[lado]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx := 28
	var ny := 10
	var alto := 3.1
	var pts: Array = []
	for j in ny + 1:
		var v := float(j) / ny
		var fila: Array = []
		# recogida con un lazo a 1,15 m: se estrecha ahí y cae abierta abajo
		var hy := v * alto
		var est: float = 1.0 - 0.45 * exp(-pow((hy - 1.15) / 0.45, 2.0))
		for i in nx + 1:
			var u := float(i) / nx
			var x: float = (u - 0.5) * 0.7 * est + float(lado) * (1.0 - est) * 0.3
			var z: float = sin(u * TAU * 4.5 + v * 1.3) * 0.05 * (0.55 + 0.45 * (1.0 - v)) + sin(u * 23.0) * 0.012
			fila.append(Vector3(x, hy, z))
		pts.append(fila)
	for j in ny:
		for i in nx:
			var a: Vector3 = pts[j][i]
			var b: Vector3 = pts[j][i + 1]
			var cc: Vector3 = pts[j + 1][i]
			var d: Vector3 = pts[j + 1][i + 1]
			for vtx in [a, cc, b, b, cc, d]:
				st.set_smooth_group(0)
				st.add_vertex(vtx)
	st.generate_normals()
	var am := st.commit()
	_cortinas[lado] = am
	return am

var _entrada_cache := Vector3.INF
## ¿Este punto es la puerta principal? (marca «Entrada principal» del plano exterior)
func _es_entrada(c: Vector3) -> bool:
	if _entrada_cache == Vector3.INF:
		_entrada_cache = Vector3(1e9, 0, 1e9)
		for m in plan.exterior.get("marcas", []):
			if m[0] == "puerta" and str(m[3]).begins_with("Entrada"):
				_entrada_cache = cell_to_world("exterior", float(m[1]), float(m[2]))
	return Vector2(c.x - _entrada_cache.x, c.z - _entrada_cache.z).length() < 2.6

func _door(c: Vector3, horiz: bool, level: int, ids: Array) -> void:
	if level == 0 and _es_entrada(c):
		_puerta_principal(c, horiz, ids)
		return
	var gap := 1.5
	var locked := false
	for id in ids:
		if rooms[id].type == "epicentro" and rooms[id].level == 1:
			locked = true
	var fr := Vector3(gap + 0.3, 0.18, 0.4) if horiz else Vector3(0.4, 0.18, gap + 0.3)
	box(fr, c + Vector3(0, 2.55, 0), _mat.madera, false, null, false)
	var pivot := Node3D.new()
	pivot.set_meta("dyn", true)
	_house.add_child(pivot)
	if horiz:
		pivot.position = c + Vector3(-gap * 0.5, 0, 0)
	else:
		pivot.position = c + Vector3(0, 0, -gap * 0.5)
		pivot.rotation.y = -PI * 0.5
	var mat: Material = _mat.madera if not locked else _mat.oscuro
	box(Vector3(gap - 0.04, 2.45, 0.07), Vector3(gap * 0.5, 1.225, 0), mat, false, pivot)
	for py in [0.65, 1.75]:
		box(Vector3(gap * 0.32, 0.8, 0.09), Vector3(gap * 0.27, py, 0), mat, false, pivot)
		box(Vector3(gap * 0.32, 0.8, 0.09), Vector3(gap * 0.73, py, 0), mat, false, pivot)
	box(Vector3(0.07, 0.07, 0.16), Vector3(gap - 0.18, 1.05, 0), _mat.oro, false, pivot)
	if locked:
		box(Vector3(gap * 0.9, 0.06, 0.12), Vector3(gap * 0.5, 1.2, 0.05), _mat.metal, false, pivot)
		box(Vector3(gap * 0.9, 0.06, 0.12), Vector3(gap * 0.5, 1.45, 0.05), _mat.metal, false, pivot)
	var body := AnimatableBody3D.new()
	body.sync_to_physics = false
	body.collision_layer = 2  # capa de puertas: no cuenta para la navegación de Elena (las abre ella)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(gap, 2.45, 0.12)
	cs.shape = bs
	cs.position = Vector3(gap * 0.5, 1.225, 0)
	body.add_child(cs)
	pivot.add_child(body)
	var snd := AudioStreamPlayer3D.new()
	snd.unit_size = 4.0
	snd.max_distance = 30.0
	pivot.add_child(snd)
	var start_open := (not locked) and _rng.randf() < 0.65
	var d := {"pivot": pivot, "shape": cs, "pos": c, "open": start_open, "locked": locked, "ang": 0.0, "target": 0.0,
		"base": pivot.rotation.y, "snd": snd, "level": level}
	if start_open:
		d.ang = 1.6
		d.target = 1.6
		cs.disabled = true
		pivot.rotation.y = d.base + d.ang
	doors.append(d)

func door_near(p: Vector3, dist := 2.3) -> Dictionary:
	var best := {}
	var bd := dist
	for d in doors:
		if absf(p.y - d.pos.y) > 1.6:
			continue
		var dd: float = Vector2(p.x - d.pos.x, p.z - d.pos.z).length()
		if dd < bd:
			bd = dd
			best = d
	return best

func set_door(d: Dictionary, open: bool, force := false) -> void:
	if d.is_empty() or (d.locked and open):
		return
	d.open = open
	d.target = (1.6 if open else 0.0)
	d.shape.disabled = open
	d["speed"] = 9.0 if force else 3.2

## Detalles que hacen que la casa parezca una mansión: esquinas con sillares alternos (cadenas de esquina),
## cornisa grande con ménsulas bajo el tejado e impostas entre pisos, todo en piedra clara.
func _ornatos_fachada() -> void:
	var r := house_rect
	var pc: Material = _mat.piedra_clara
	var cara := 0.26
	var alto_total := lvl_y(2) + 3.4
	var esquinas := [[r.position, Vector2(1, 1)], [Vector2(r.end.x, r.position.y), Vector2(-1, 1)], [Vector2(r.position.x, r.end.y), Vector2(1, -1)], [r.end, Vector2(-1, -1)]]
	for e in esquinas:
		var p: Vector2 = e[0]
		var d: Vector2 = e[1]
		var k := 0
		var y := 0.55
		while y < alto_total:
			var largo := 0.75 if k % 2 == 0 else 0.45
			var bx := box(Vector3(largo, 0.4, 0.42), Vector3(p.x + d.x * (largo * 0.5 - cara), y + 0.2, p.y - d.y * cara + d.y * 0.21 - d.y * 0.21), pc, false, self, false)
			bx.position = Vector3(p.x + d.x * (largo * 0.5 - cara - 0.02), y + 0.2, p.y - d.y * (cara + 0.02) + d.y * 0.2)
			var bz := box(Vector3(0.42, 0.4, 0.45 if k % 2 == 0 else 0.75), Vector3.ZERO, pc, false, self, false)
			bz.position = Vector3(p.x - d.x * (cara + 0.02) + d.x * 0.2, y + 0.2, p.y + d.y * ((0.45 if k % 2 == 0 else 0.75) * 0.5 - cara - 0.02))
			y += 0.43
			k += 1
	# cornisa con ménsulas bajo el alero
	var yc := lvl_y(2) + 3.2
	for lado in 4:
		var horiz := lado < 2
		var l := r.size.x if horiz else r.size.y
		var cpos := Vector3(r.get_center().x, yc, (r.position.y if lado == 0 else r.end.y)) if horiz else Vector3((r.position.x if lado == 2 else r.end.x), yc, r.get_center().y)
		var fuera := Vector3(0, 0, -1 if lado == 0 else 1) if horiz else Vector3(-1 if lado == 2 else 1, 0, 0)
		var banda := Vector3(l + 0.9, 0.22, 0.5) if horiz else Vector3(0.5, 0.22, l + 0.9)
		box(banda, cpos + fuera * 0.4 + Vector3(0, 0.12, 0), pc, false, self, false)
		var friso := Vector3(l + 0.6, 0.35, 0.2) if horiz else Vector3(0.2, 0.35, l + 0.6)
		box(friso, cpos + fuera * 0.3 + Vector3(0, -0.15, 0), pc, false, self, false)
		var n := int(l / 0.9)
		for k in n:
			var t := -l * 0.5 + 0.45 + k * (l - 0.9) / maxf(n - 1, 1)
			var mpos := cpos + (Vector3(t, 0, 0) if horiz else Vector3(0, 0, t)) + fuera * 0.42 + Vector3(0, -0.12, 0)
			var men := Vector3(0.14, 0.32, 0.34) if horiz else Vector3(0.34, 0.32, 0.14)
			box(men, mpos, pc, false, self, false)
		# impostas entre pisos (bandas de piedra que marcan cada planta)
		for lv in [1, 2]:
			var imp := Vector3(l + 0.5, 0.2, 0.16) if horiz else Vector3(0.16, 0.2, l + 0.5)
			box(imp, Vector3(cpos.x, lvl_y(lv) - 0.05, cpos.z) + fuera * 0.3, pc, false, self, false)

## Puerta principal de la mansión: dos hojas de nogal tallado de 3,2 m con cuarterones en relieve, aldabón de
## león, pomos y placas de latón; montante de abanico acristalado encima; portada de piedra con pilastras,
## capiteles, entablamento y frontón partido con clave; escalinata de piedra y dos faroles a los lados.
## Se abre como las demás (las dos hojas a la vez).
func _puerta_principal(c: Vector3, horiz: bool, ids: Array) -> void:
	var gap := 2.1
	var alto := 3.2
	var ej := Vector3(1, 0, 0) if horiz else Vector3(0, 0, 1)
	var r0: Dictionary = rooms[ids[0]]
	var rc: Vector2 = (r0.rect as Rect2).get_center()
	var dentro := Vector3(0, 0, signf(rc.y - c.z)) if horiz else Vector3(signf(rc.x - c.x), 0, 0)
	var fuera := -dentro
	var cara := fuera * 0.3
	var yaw := atan2(fuera.x, fuera.z)
	var pc: Material = _mat.piedra_clara
	var nogal: Material = _mat.madera
	var p0 := c + cara
	# --- portada de piedra ---
	for s2 in [-1.0, 1.0]:
		var pil := box(Vector3(0.42, alto + 0.35, 0.22), Vector3.ZERO, pc, false, self, false)
		pil.position = p0 + ej * s2 * (gap * 0.5 + 0.3) + Vector3(0, (alto + 0.35) * 0.5, 0)
		pil.rotation.y = yaw
		for k in 3:
			var est := box(Vector3(0.05, alto - 0.4, 0.05), Vector3.ZERO, _mat.moldura, false, self, false)
			est.position = p0 + ej * s2 * (gap * 0.5 + 0.3 + (k - 1) * 0.11) + fuera * 0.115 + Vector3(0, alto * 0.5 + 0.1, 0)
			est.rotation.y = yaw
		var base := box(Vector3(0.55, 0.45, 0.3), Vector3.ZERO, pc, false, self, false)
		base.position = p0 + ej * s2 * (gap * 0.5 + 0.3) + Vector3(0, 0.225, 0)
		base.rotation.y = yaw
		var cap := box(Vector3(0.6, 0.25, 0.32), Vector3.ZERO, pc, false, self, false)
		cap.position = p0 + ej * s2 * (gap * 0.5 + 0.3) + Vector3(0, alto + 0.42, 0)
		cap.rotation.y = yaw
	var arq := box(Vector3(gap + 1.6, 0.4, 0.34), Vector3.ZERO, pc, false, self, false)
	arq.position = p0 + fuera * 0.03 + Vector3(0, alto + 0.75, 0)
	arq.rotation.y = yaw
	var cor := box(Vector3(gap + 1.9, 0.14, 0.5), Vector3.ZERO, pc, false, self, false)
	cor.position = p0 + fuera * 0.08 + Vector3(0, alto + 1.0, 0)
	cor.rotation.y = yaw
	for s2 in [-1.0, 1.0]:
		var fr := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(1.2, 0.7, 0.36)
		pm.left_to_right = 1.0 if s2 < 0 else 0.0
		fr.mesh = pm
		fr.material_override = pc
		fr.position = p0 + ej * s2 * (gap * 0.5 + 0.35) + fuera * 0.05 + Vector3(0, alto + 1.42, 0)
		fr.rotation.y = yaw
		add_child(fr)
	var urna := cyl(0.12, 0.2, 0.55, p0 + fuera * 0.05 + Vector3(0, alto + 1.36, 0), pc, self, 12)
	cyl(0.1, 0.1, 0.18, urna.position + Vector3(0, 0.36, 0), pc, self, 10)
	# montante de abanico: medio óvalo acristalado con radios de madera, sobre un tablero que cierra el hueco
	var tablero := box(Vector3(gap, WALL_H - alto, 0.08), Vector3.ZERO, nogal, false, self, false)
	tablero.position = c + dentro * 0.1 + Vector3(0, (WALL_H + alto) * 0.5, 0)
	tablero.rotation.y = yaw
	var semi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = gap * 0.5
	cm.bottom_radius = gap * 0.5
	cm.height = 0.04
	cm.radial_segments = 32
	semi.mesh = cm
	semi.material_override = _mat.ventana_luz
	semi.basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, PI * 0.5) * Basis.from_scale(Vector3(1.0, 1.0, 0.72))
	semi.position = c + fuera * 0.02 + Vector3(0, alto, 0)
	add_child(semi)
	for k in 7:
		var a := PI * (k + 0.5) / 7.0
		var radio := box(Vector3(0.035, gap * 0.36, 0.05), Vector3.ZERO, nogal, false, self, false)
		radio.basis = Basis(fuera, -(a - PI * 0.5)) * Basis(Vector3.UP, yaw)
		radio.position = c + fuera * 0.05 + Vector3(0, alto, 0) + (ej * cos(a) + Vector3(0, sin(a) * 0.72, 0)) * gap * 0.25
	var aro := box(Vector3(gap + 0.1, 0.1, 0.12), Vector3.ZERO, nogal, false, self, false)
	aro.position = c + fuera * 0.05 + Vector3(0, alto, 0)
	aro.rotation.y = yaw
	# muro de piedra que cierra encima del montante (el hueco del muro es más alto que la puerta)
	# --- escalinata ---
	for k in 3:
		var esc := box(Vector3(gap + 2.0 + k * 0.4, 0.16, 0.42 + k * 0.38), Vector3.ZERO, pc, true, self, false)
		esc.position = c + fuera * (0.45 + k * 0.19) + Vector3(0, 0.25 - k * 0.08 - 0.08, 0)
		esc.rotation.y = yaw
	# --- faroles ---
	for s2 in [-1.0, 1.0]:
		_prop("Lantern_01", p0 + ej * s2 * (gap * 0.5 + 0.95) + fuera * 0.25 + Vector3(0, 2.0, 0), yaw, 1.6, false, self)
		var brazo := box(Vector3(0.05, 0.05, 0.35), Vector3.ZERO, _mat.metal, false, self, false)
		brazo.position = p0 + ej * s2 * (gap * 0.5 + 0.95) + fuera * 0.1 + Vector3(0, 2.55, 0)
		brazo.rotation.y = yaw
		var lz := OmniLight3D.new()
		lz.light_color = Color(1.0, 0.68, 0.38)
		lz.light_energy = 0.7
		lz.omni_range = 5.0
		lz.position = p0 + ej * s2 * (gap * 0.5 + 0.95) + fuera * 0.4 + Vector3(0, 2.4, 0)
		add_child(lz)
	# --- las dos hojas (cada una en su gozne) ---
	var hojas: Array = []
	for s2 in [-1.0, 1.0]:
		var piv := Node3D.new()
		piv.set_meta("dyn", true)
		_house.add_child(piv)
		piv.position = c + ej * s2 * gap * 0.5
		var hacia: Vector3 = -s2 * ej
		piv.rotation.y = atan2(-hacia.z, hacia.x)
		var w := gap * 0.5 - 0.02
		var lado := 1.0
		box(Vector3(w, alto - 0.05, 0.09), Vector3(-s2 * 0 + w * 0.5 * lado * (1.0), alto * 0.5, 0), nogal, false, piv)
		# cuarterones en relieve: alto arriba, mediano en medio y bajo abajo, con molduras
		for pz in [[0.45, 0.55], [1.25, 0.75], [2.35, 1.2]]:
			box(Vector3(w - 0.22, float(pz[1]), 0.13), Vector3(w * 0.5, float(pz[0]), 0), nogal, false, piv)
			box(Vector3(w - 0.32, float(pz[1]) - 0.1, 0.15), Vector3(w * 0.5, float(pz[0]), 0), nogal, false, piv)
		box(Vector3(w, 0.18, 0.12), Vector3(w * 0.5, 0.09, 0), _mat.oro, false, piv)
		box(Vector3(0.06, 0.22, 0.15), Vector3(w - 0.12, 1.15, 0), _mat.oro, false, piv)
		for zz in [0.08, -0.08]:
			cyl(0.045, 0.045, 0.08, Vector3(w - 0.12, 1.05, zz), _mat.oro, piv, 10).rotation.x = PI * 0.5
		hojas.append(piv)
	# arañazos profundos en la madera, como de garras, a la altura de una persona
	var marcas := _tex_aranazos()
	var mar := StandardMaterial3D.new()
	mar.albedo_texture = marcas
	mar.albedo_color = Color(0.1, 0.05, 0.03)
	mar.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mar.roughness = 0.9
	for hj in hojas:
		var piv3: Node3D = hj
		var zf2 := signf((piv3.basis.inverse() * fuera).z)
		var qm := QuadMesh.new()
		qm.size = Vector2(0.5, 1.1)
		var ar := MeshInstance3D.new()
		ar.mesh = qm
		ar.material_override = mar
		ar.position = Vector3((gap * 0.5 - 0.02) * 0.5 + randf_range(-0.1, 0.1), 1.25, 0.081 * zf2)
		ar.rotation.y = 0.0 if zf2 > 0 else PI
		ar.rotation.z = randf_range(-0.25, 0.25)
		piv3.add_child(ar)
	# aldabones de león en cada hoja (van con la hoja al abrir)
	for hj in hojas:
		var piv2: Node3D = hj
		var zf := signf((piv2.basis.inverse() * fuera).z)
		var w2 := gap * 0.5 - 0.02
		_prop("vict_lion_door_knocker", Vector3(w2 * 0.5, 1.55, 0.08 * zf), PI if zf < 0 else 0.0, 1.0, false, piv2)
	# hueco del muro por encima de la puerta principal (cierra hasta el dintel)
	var body := AnimatableBody3D.new()
	body.sync_to_physics = false
	body.collision_layer = 2
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(gap, alto, 0.12)
	cs.shape = bs
	cs.position = Vector3(0, alto * 0.5, 0)
	body.add_child(cs)
	var cuerpo := Node3D.new()
	cuerpo.set_meta("dyn", true)
	cuerpo.position = c
	cuerpo.rotation.y = yaw
	_house.add_child(cuerpo)
	cuerpo.add_child(body)
	var snd := AudioStreamPlayer3D.new()
	snd.unit_size = 4.0
	snd.max_distance = 30.0
	cuerpo.add_child(snd)
	var d := {"pivot": hojas[0], "pivot2": hojas[1], "shape": cs, "pos": c, "open": false, "locked": false, "ang": 0.0, "target": 0.0,
		"base": hojas[0].rotation.y, "base2": hojas[1].rotation.y, "snd": snd, "level": 0, "principal": true}
	doors.append(d)

## Un siglo de abandono por fuera: hiedra trepando por las esquinas y la torre, ventanas tapiadas con tablas,
## contraventanas descolgadas o perdidas, arañazos en la puerta principal y una luz roja que tiembla en el ático.
var ventanas_ext: Array = []
var _luz_atico: OmniLight3D
func _abandono_exterior() -> void:
	var r := house_rect
	var rng := RandomNumberGenerator.new()
	rng.seed = 666
	# --- hiedra: tallos que suben con quiebros y se ramifican, cubiertos de hojas ---
	var mh := StandardMaterial3D.new()
	mh.albedo_texture = load("res://zarek/texturas/hiedra.png")
	mh.albedo_color = Color(0.22, 0.3, 0.18)
	mh.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mh.alpha_scissor_threshold = 0.4
	mh.cull_mode = BaseMaterial3D.CULL_DISABLED
	mh.roughness = 0.7
	var q := QuadMesh.new()
	q.size = Vector2(0.55, 0.7)
	q.material = mh
	var hojas: Array[Transform3D] = []
	var arranques: Array = []
	for e in [[r.position, Vector3(-1, 0, -1)], [Vector2(r.end.x, r.position.y), Vector3(1, 0, -1)], [Vector2(r.position.x, r.end.y), Vector3(-1, 0, 1)], [r.end, Vector3(1, 0, 1)]]:
		var p2: Vector2 = e[0]
		var d: Vector3 = e[1]
		for k in 3:
			var sobre_x := k % 2 == 0
			var off := rng.randf_range(0.3, 3.5)
			var pos := Vector3(p2.x - d.x * (off if sobre_x else -0.27), 0, p2.y - d.z * (-0.27 if sobre_x else off))
			arranques.append([pos, Vector3(0, 0, d.z) if sobre_x else Vector3(d.x, 0, 0)])
	for k in 10:
		var lado := rng.randi_range(0, 3)
		var horiz := lado < 2
		var u := rng.randf_range(2.0, (r.size.x if horiz else r.size.y) - 2.0)
		var n := Vector3(0, 0, -1 if lado == 0 else 1) if horiz else Vector3(-1 if lado == 2 else 1, 0, 0)
		var pos := Vector3(r.position.x + u, 0, (r.position.y - 0.27) if lado == 0 else (r.end.y + 0.27)) if horiz else Vector3((r.position.x - 0.27) if lado == 2 else (r.end.x + 0.27), 0, r.position.y + u)
		arranques.append([pos, n])
	for a in arranques:
		_tallo(a[0], a[1], rng.randf_range(5.0, lvl_y(2) + 3.0), 0, rng, hojas)
	_mm_trozos(q, hojas, quality >= 2, 50.0)
	# --- luz roja temblorosa en una ventana del ático ---
	_luz_atico = OmniLight3D.new()
	_luz_atico.light_color = Color(0.9, 0.12, 0.05)
	_luz_atico.light_energy = 1.2
	_luz_atico.omni_range = 4.0
	_luz_atico.position = Vector3(r.get_center().x - r.size.x * 0.22, lvl_y(2) + 3.45 + 2.8, r.end.y - 0.3)
	add_child(_luz_atico)

## Textura de arañazos: cuatro surcos paralelos que bajan torciéndose, con astillas en los bordes.
func _tex_aranazos() -> ImageTexture:
	var img := Image.create(128, 256, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	for g in 2:
		var x0 := rng.randf_range(20, 70) + g * 30
		for k in 4:
			var x := x0 + k * 9.0
			for y in range(rng.randi_range(10, 40), rng.randi_range(190, 250)):
				x += sin(y * 0.05 + k) * 0.25 + rng.randf_range(-0.3, 0.3)
				var ancho := 1.5 + sin(PI * y / 256.0) * 1.8
				for dx in range(-3, 4):
					var xi := int(x) + dx
					if xi >= 0 and xi < 128 and absf(dx) <= ancho:
						var a := 1.0 - absf(dx) / (ancho + 0.5)
						var vieja := img.get_pixel(xi, y)
						img.set_pixel(xi, y, Color(0.6, 0.5, 0.4, maxf(vieja.a, a)))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

## Un tallo de hiedra pegado al muro (normal n): sube haciendo eses, a veces se abre en dos, y deja hojas.
func _tallo(p: Vector3, n: Vector3, alto: float, prof: int, rng: RandomNumberGenerator, hojas: Array[Transform3D]) -> void:
	var lado := Vector3(-n.z, 0, n.x)
	var y := p.y
	var x := 0.0
	while y < alto:
		y += rng.randf_range(0.12, 0.22)
		x += rng.randf_range(-0.14, 0.14)
		var c := p + lado * x + Vector3(0, y - p.y, 0) + n * rng.randf_range(0.0, 0.08)
		for k in 2:
			var b := Basis.looking_at(-n, Vector3.UP).rotated(n, rng.randf() * TAU)
			b = b.rotated(lado, rng.randf_range(-0.5, 0.5))
			var s := rng.randf_range(0.6, 1.2) * (1.0 - float(prof) * 0.15)
			hojas.append(Transform3D(b.scaled(Vector3(s, s, s)), c + lado * rng.randf_range(-0.25, 0.25) + Vector3(0, rng.randf_range(-0.15, 0.15), 0)))
		if prof < 2 and rng.randf() < 0.05:
			_tallo(c, n, minf(alto, y + rng.randf_range(1.0, 3.5)), prof + 1, rng, hojas)
			x += rng.randf_range(-0.6, 0.6)

# ---------------- tejado y torre ----------------
func _roof() -> void:
	var r := house_rect
	var y := lvl_y(2) + 3.45
	var c := r.get_center()
	var main := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(r.size.y + 1.5, 12.5, r.size.x + 1.5)
	main.mesh = pm
	main.material_override = _mat.tejado
	main.position = Vector3(c.x, y + 6.25, c.y)
	main.rotation.y = PI * 0.5
	add_child(main)
	var cross := MeshInstance3D.new()
	var pm2 := PrismMesh.new()
	pm2.size = Vector3(18.0, 9.0, r.size.y + 3.0)
	cross.mesh = pm2
	cross.material_override = _mat.tejado
	cross.rotation.y = 0.0
	cross.position = Vector3(c.x + 6.0, y + 4.5, c.y)
	cross.rotation.y = PI * 0.5
	add_child(cross)
	box(Vector3(r.size.x + 1.5, 0.3, r.size.y + 1.5), Vector3(c.x, y + 0.15, c.y), _mat.tejado, false, self)
	box(Vector3(r.size.x + 1.5, 0.3, 0.3), Vector3(c.x, y + 12.5, c.y), _mat.metal, false, self)
	# crestería de hierro sobre la cumbrera
	for k in int(r.size.x / 0.6):
		box(Vector3(0.03, 0.45, 0.03), Vector3(r.position.x + 0.3 + k * 0.6, y + 12.85, c.y), _mat.metal, false, self, false)
	# muro del ático (fachada entre el primer piso y el tejado)
	for s in [[r.position, Vector2(r.end.x, r.position.y)], [Vector2(r.position.x, r.end.y), r.end], [r.position, Vector2(r.position.x, r.end.y)], [Vector2(r.end.x, r.position.y), r.end]]:
		var a: Vector2 = s[0]
		var b: Vector2 = s[1]
		var l := a.distance_to(b)
		var m := (a + b) * 0.5
		box(Vector3(l, 3.5, 0.4) if absf(a.y - b.y) < 0.01 else Vector3(0.4, 3.5, l), Vector3(m.x, lvl_y(2) + 1.7, m.y), _mat.fachada, false, self)
	# hastiales delanteros con ventana redonda
	for sx in [-r.size.x * 0.22, r.size.x * 0.2]:
		var g := MeshInstance3D.new()
		var gp := PrismMesh.new()
		gp.size = Vector3(13.0, 7.0, 4.0)
		g.mesh = gp
		g.material_override = _mat.fachada
		g.position = Vector3(c.x + sx, y + 3.5, r.end.y - 1.0)
		add_child(g)
		var gr := MeshInstance3D.new()
		var gr_m := PrismMesh.new()
		gr_m.size = Vector3(14.5, 7.8, 5.0)
		gr.mesh = gr_m
		gr.material_override = _mat.tejado
		gr.position = Vector3(c.x + sx, y + 3.9, r.end.y - 1.6)
		add_child(gr)
		var roja := StandardMaterial3D.new()
		roja.albedo_color = Color(0.05, 0.0, 0.0)
		roja.emission_enabled = true
		roja.emission = Color(0.7, 0.06, 0.02)
		roja.emission_energy_multiplier = 0.8
		var ow := cyl(0.9, 0.9, 0.1, Vector3(c.x + sx, y + 2.8, r.end.y + 1.05), roja if sx < 0 else _mat.vidrio, self, 14)
		ow.rotation.x = PI * 0.5
	for cp in [Vector2(r.position.x + 8, c.y - 6), Vector2(r.end.x - 10, c.y + 4), Vector2(c.x - 3, c.y + 6)]:
		box(Vector3(1.6, 12.0, 1.6), Vector3(cp.x, y + 8.0, cp.y), _mat.piedra, false, self)
		box(Vector3(2.0, 0.3, 2.0), Vector3(cp.x, y + 14.1, cp.y), _mat.piedra, false, self)
		for k in 2:
			cyl(0.22, 0.25, 0.6, Vector3(cp.x - 0.35 + k * 0.7, y + 14.55, cp.y), _mat.cimiento, self, 8)
	# torre redonda con techo cónico (esquina delantera oeste)
	var t0 := cell_to_world("baja", 0, 9)
	# tambor de la torre: toca la pared de la sala de música sin entrar en ella y sobresale hacia el oeste y el sur
	var rt := 4.2
	var tc := t0 + Vector3(3.0, 0, 5.0)
	var th := lvl_y(3) + 1.0
	# tambor de la torre: mapeado por UV (no triplanar: en una superficie curva el triplanar hace bandas)
	var tambor := cyl(rt, rt, th, tc + Vector3(0, th * 0.5 - 0.02, 0), _mat.fachada_torre, self, 48)
	tambor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cyl(0.0, rt + 1.0, 9.0, tc + Vector3(0, th + 4.5, 0), _mat.tejado, self, 24)
	cyl(0.05, 0.05, 3.0, tc + Vector3(0, th + 10.0, 0), _mat.metal, self, 6)
	for lv in 3:
		for k in 6:
			var a := TAU * k / 6.0 + 0.3
			var wp := tc + Vector3(cos(a) * (rt + 0.05), lvl_y(lv) + 1.9, sin(a) * (rt + 0.05))
			var w := box(Vector3(0.1, 2.0, 1.1), wp, _mat.ventana_luz if (k == 2 and lv == 2) else _mat.vidrio, false, self)
			w.rotation.y = -a

# ---------------- exterior ----------------
func _exterior() -> void:
	var ex: Dictionary = plan.exterior
	var W := float(ex.w) * CELL
	var H := float(ex.h) * CELL
	# el suelo del bosque no pasa por debajo de la casa (si no, tapa la escalera del sótano)
	# cauces de agua: el suelo no pasa por encima (el agua tiene fondo y orillas de verdad)
	var cauces: Array = [house_rect]
	for z in ex.zonas:
		if String(z[0]) in ["Arroyo", "Estanque"]:
			cauces.append(Rect2(float(z[2]) * CELL, float(z[3]) * CELL, float(z[4]) * CELL, float(z[5]) * CELL).grow(1.2))
	for gr in _split_holes(Rect2(0, 0, W, H), cauces):
		var grr: Rect2 = gr
		var ground := box(Vector3(grr.size.x, 0.4, grr.size.y), Vector3(grr.get_center().x, -0.2, grr.get_center().y), _mat.bosque, true, self, false)
		ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for z in ex.zonas:
		var name: String = z[0]
		var t: String = z[1]
		var r := Rect2(float(z[2]) * CELL, float(z[3]) * CELL, float(z[4]) * CELL, float(z[5]) * CELL)
		if name.begins_with("Terrenos"):
			grounds_rect = r
			for q in _split_holes(r, [house_rect]):
				var qr: Rect2 = q
				box(Vector3(qr.size.x, 0.05, qr.size.y), Vector3(qr.get_center().x, 0.01, qr.get_center().y), _mat.cesped, false, self, false)
			_stone_wall(r)
		elif t == "camino":
			for q in _split_holes(r, cauces):
				var qr: Rect2 = q
				box(Vector3(qr.size.x, 0.05, qr.size.y), Vector3(qr.get_center().x, 0.03, qr.get_center().y), _mat.tierra, false, self, false)
		elif t == "agua":
			if name.begins_with("Fuente"):
				_fountain(r)
			elif name.begins_with("Pozo"):
				_well(r)
			else:
				var es_rio := name == "Arroyo"
				var sup := MeshInstance3D.new()
				var pl := PlaneMesh.new()
				pl.size = Vector2(r.size.x, r.size.y)
				pl.subdivide_width = int(r.size.x / 2.0)
				pl.subdivide_depth = 4
				sup.mesh = pl
				sup.material_override = _mat_agua(es_rio)
				sup.position = Vector3(r.get_center().x, -0.28, r.get_center().y)
				sup.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				sup.set_meta("dyn", true)
				add_child(sup)
				_cauce(r.grow(1.2), es_rio)
				_orillas(r.grow(1.2), es_rio)
				_sonidos_agua(r, "rio" if es_rio else "rio", 18.0 if es_rio else 12.0, -10.0)
				if es_rio:
					_stream_banks(r)
		elif name == "Laberinto de setos":
			_maze(r)
		elif t == "edificio":
			if name.begins_with("MANSIÓN") or name == "Torre":
				continue
			_shed(name, r)
		elif name == "Porche":
			_porch(r)
	_trees(W, H)

func _zone(name: String) -> Rect2:
	for z in plan.exterior.zonas:
		if z[0] == name:
			return Rect2(float(z[2]) * CELL, float(z[3]) * CELL, float(z[4]) * CELL, float(z[5]) * CELL)
	return Rect2()

func _stone_wall(r: Rect2) -> void:
	var gz := _zone("Portón")
	var gate_x0 := gz.position.x
	var gate_x1 := gz.end.x
	var hgt := 2.4
	var segs := [[r.position, Vector2(r.end.x, r.position.y)], [Vector2(r.position.x, r.end.y), r.end],
		[r.position, Vector2(r.position.x, r.end.y)], [Vector2(r.end.x, r.position.y), r.end]]
	for s in segs:
		var a: Vector2 = s[0]
		var b: Vector2 = s[1]
		if absf(a.y - b.y) < 0.01 and absf(a.y - r.end.y) < 0.01:
			_wall_seg(a, Vector2(gate_x0, a.y), hgt)
			_wall_seg(Vector2(gate_x1, a.y), b, hgt)
			for gx in [gate_x0, gate_x1]:
				box(Vector3(1.0, 3.6, 1.0), Vector3(gx, 1.8, a.y), _mat.piedra, true, self)
				cyl(0.0, 0.5, 0.9, Vector3(gx, 4.05, a.y), _mat.piedra, self, 8)
			for side in [-1.0, 1.0]:
				var gp := Node3D.new()
				add_child(gp)
				gp.position = Vector3(gate_x0 if side < 0 else gate_x1, 0, a.y)
				gp.rotation.y = side * 1.9
				for k in 9:
					box(Vector3(0.06, 2.8, 0.06), Vector3(-side * (0.3 + k * 0.95), 1.4, 0), _mat.metal, false, gp)
				box(Vector3(8.6, 0.08, 0.08), Vector3(-side * 4.2, 2.6, 0), _mat.metal, false, gp)
				box(Vector3(8.6, 0.08, 0.08), Vector3(-side * 4.2, 0.4, 0), _mat.metal, false, gp)
		else:
			_wall_seg(a, b, hgt)

func _wall_seg(a: Vector2, b: Vector2, hgt: float) -> void:
	var l := a.distance_to(b)
	if l < 0.1:
		return
	var c := (a + b) * 0.5
	var horiz := absf(a.y - b.y) < 0.01
	box(Vector3(l, hgt, 0.6) if horiz else Vector3(0.6, hgt, l), Vector3(c.x, hgt * 0.5, c.y), _mat.piedra, true, self)
	box(Vector3(l, 0.15, 0.8) if horiz else Vector3(0.8, 0.15, l), Vector3(c.x, hgt + 0.07, c.y), _mat.piedra, false, self)

func _static_cyl(r: float, h: float, pos: Vector3) -> void:
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = r
	sh.height = h
	cs.shape = sh
	sb.add_child(cs)
	sb.position = pos
	add_child(sb)

## Fuente del jardín delantero: fuente de mármol de tres tazas con pila festoneada (modelo real, CC-BY),
## con agua de verdad en cada taza, láminas de agua cayendo de una a otra, el surtidor de arriba, salpicaduras
## y el sonido del agua.
func _fountain(r: Rect2) -> void:
	var c := Vector3(r.get_center().x, 0, r.get_center().y)
	var f := _prop("fuente_festoneada", c, 0.0, 1.0, false)
	if f == null:
		cyl(6.0, 6.3, 0.8, c + Vector3(0, 0.4, 0), _mat.marmol, self, 24)
		_static_cyl(6.3, 0.8, c + Vector3(0, 0.4, 0))
		return
	_static_cyl(3.2, 0.9, c + Vector3(0, 0.45, 0))
	_static_cyl(0.7, 4.0, c + Vector3(0, 2.0, 0))
	var agua := _mat_agua(false)
	agua.set_shader_parameter("espuma_orilla", 0.06)
	agua.set_shader_parameter("claridad", 0.8)
	agua.set_shader_parameter("color_cerca", Color(0.06, 0.08, 0.075))
	var niveles: Dictionary = {}
	for mi in f.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		for si in m3.mesh.get_surface_count():
			var mat := m3.mesh.surface_get_material(si)
			if mat is BaseMaterial3D and (mat as BaseMaterial3D).albedo_color.a < 0.95:
				m3.set_surface_override_material(si, agua)
				m3.set_meta("dyn", true)
				# alturas y radios de cada taza (para colocar las cascadas)
				var vs: PackedVector3Array = m3.mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]
				for v in vs:
					var w := m3.transform * v
					var k := int(round(w.y * 10.0))
					var rr := Vector2(w.x, w.z).length()
					niveles[k] = maxf(float(niveles.get(k, 0.0)), rr)
	var ks: Array = niveles.keys()
	ks.sort()
	if _ruido_chorro == null:
		_ruido_chorro = NoiseTexture2D.new()
		_ruido_chorro.width = 256
		_ruido_chorro.height = 256
		_ruido_chorro.seamless = true
		var fn := FastNoiseLite.new()
		fn.frequency = 0.04
		fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		_ruido_chorro.noise = fn
	var mch := ShaderMaterial.new()
	mch.shader = load("res://zarek/chorro.gdshader")
	mch.set_shader_parameter("ruido", _ruido_chorro)
	# de cada taza (salvo la pila de abajo) cae una cortina de agua hasta el nivel de la siguiente
	for i in range(ks.size() - 1, 0, -1):
		var y_arriba := float(ks[i]) / 10.0
		var y_abajo := float(ks[i - 1]) / 10.0
		var rad: float = niveles[ks[i]]
		if rad > 2.8 or y_arriba - y_abajo < 0.3:
			continue
		var alto := y_arriba - y_abajo + 0.02
		var cm := CylinderMesh.new()
		cm.top_radius = rad + 0.06
		cm.bottom_radius = rad + 0.22
		cm.height = alto
		cm.cap_top = false
		cm.cap_bottom = false
		cm.radial_segments = 40
		var cortina := MeshInstance3D.new()
		cortina.mesh = cm
		cortina.material_override = mch
		cortina.position = c + Vector3(0, y_abajo + alto * 0.5, 0)
		cortina.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cortina.set_meta("dyn", true)
		add_child(cortina)
		# salpicaduras donde cae
		var sp := CPUParticles3D.new()
		sp.amount = 40
		sp.lifetime = 0.7
		sp.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
		sp.emission_ring_axis = Vector3.UP
		sp.emission_ring_radius = rad + 0.22
		sp.emission_ring_inner_radius = rad + 0.1
		sp.emission_ring_height = 0.02
		sp.direction = Vector3.UP
		sp.spread = 35.0
		sp.initial_velocity_min = 0.3
		sp.initial_velocity_max = 0.8
		sp.gravity = Vector3(0, -4.0, 0)
		sp.scale_amount_min = 0.5
		sp.scale_amount_max = 1.2
		sp.mesh = _gota_mesh()
		sp.position = c + Vector3(0, y_abajo + 0.03, 0)
		add_child(sp)
	# surtidor de arriba
	if ks.size() > 0:
		var top := float(ks[ks.size() - 1]) / 10.0
		var ch := CPUParticles3D.new()
		ch.amount = 90
		ch.lifetime = 0.9
		ch.direction = Vector3.UP
		ch.spread = 6.0
		ch.initial_velocity_min = 2.4
		ch.initial_velocity_max = 2.8
		ch.gravity = Vector3(0, -9.8, 0)
		ch.scale_amount_min = 0.6
		ch.scale_amount_max = 1.0
		ch.mesh = _gota_mesh()
		ch.position = c + Vector3(0, top + 0.45, 0)
		add_child(ch)
	var son := AudioStreamPlayer3D.new()
	son.stream = AetherSynth.make("fuente")
	son.unit_size = 3.0
	son.max_distance = 22.0
	son.volume_db = -6.0
	son.autoplay = true
	son.position = c + Vector3(0, 1.5, 0)
	add_child(son)

var _ruido_chorro: NoiseTexture2D
var _gota: Mesh
func _gota_mesh() -> Mesh:
	if _gota == null:
		var q := QuadMesh.new()
		q.size = Vector2(0.035, 0.07)
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.75, 0.82, 0.88, 0.55)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.roughness = 0.05
		m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		q.material = m
		_gota = q
	return _gota

## Cauce hundido: fondo de barro y piedras a -0,9 m y orillas en pendiente (se puede salir andando).
func _cauce(r: Rect2, es_rio: bool) -> void:
	var fondo := -0.95
	var talud := 1.4
	var largo_x := r.size.x >= r.size.y
	var interior := r.grow(-talud)
	box(Vector3(maxf(interior.size.x, 0.5), 0.3, maxf(interior.size.y, 0.5)), Vector3(r.get_center().x, fondo - 0.15, r.get_center().y), _mat.barro, true, self, false)
	# cuatro taludes (o dos en el río largo, con los extremos fuera del mapa)
	var ang := atan2(-fondo, talud)
	var lt := sqrt(talud * talud + fondo * fondo)
	for lado in 4:
		var horiz := lado < 2
		if es_rio and largo_x and not horiz:
			continue
		var l := r.size.x if horiz else r.size.y
		var t := box(Vector3(l if horiz else lt, 0.12, lt if horiz else l), Vector3.ZERO, _mat.bosque, true, self, false)
		var sgn := -1.0 if lado % 2 == 0 else 1.0
		if horiz:
			t.position = Vector3(r.get_center().x, fondo * 0.5, (r.position.y + talud * 0.5) if sgn < 0 else (r.end.y - talud * 0.5))
			t.rotation.x = ang * (1.0 if sgn < 0 else -1.0)
		else:
			t.position = Vector3((r.position.x + talud * 0.5) if sgn < 0 else (r.end.x - talud * 0.5), fondo * 0.5, r.get_center().y)
			t.rotation.z = ang * (-1.0 if sgn < 0 else 1.0)
	# cantos rodados en el fondo
	var n := int(r.size.x * r.size.y / 16.0)
	for k in n:
		var pc := Vector3(_rng.randf_range(interior.position.x, interior.end.x), fondo - 0.1, _rng.randf_range(interior.position.y, interior.end.y))
		_prop("boulder_01", pc, _rng.randf() * TAU, _rng.randf_range(0.15, 0.4), false)
	# algunas piedras grandes con musgo asomando en las orillas
	for k in int(maxf(r.size.x, r.size.y) / 25.0):
		var u := _rng.randf()
		var lado2 := -1.0 if _rng.randf() < 0.5 else 1.0
		var pr := Vector3(lerpf(r.position.x, r.end.x, u), -0.5, r.get_center().y + lado2 * (r.size.y * 0.5 - 0.6)) if es_rio else Vector3(r.get_center().x + lado2 * r.size.x * 0.4, -0.5, lerpf(r.position.y, r.end.y, u))
		_prop("rock_moss_set_02", pr, _rng.randf() * TAU, _rng.randf_range(0.25, 0.4), false)

## Plantas de un GLB repartidas con MultiMesh (con viento si es vegetación).
## Reparte instancias en trozos de 16 m: cada trozo se recorta fuera de cámara, elige su nivel de detalle (LOD)
## según su distancia y desaparece más allá de «hasta» metros (la niebla lo tapa). Un solo MultiMesh gigante
## obligaba a dibujar todo el bosque con el detalle máximo.
func _mm_trozos(malla: Mesh, xs: Array, sombra: bool, hasta: float, desde := 0.0) -> void:
	var trozos := {}
	for x in xs:
		var o: Vector3 = (x as Transform3D).origin
		var k := Vector2i(floori(o.x / 16.0), floori(o.z / 16.0))
		if not trozos.has(k):
			trozos[k] = []
		(trozos[k] as Array).append(x)
	for k in trozos:
		var lista: Array = trozos[k]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = malla
		mm.instance_count = lista.size()
		for i in lista.size():
			mm.set_instance_transform(i, lista[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if sombra else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_begin = desde
		mmi.visibility_range_begin_margin = 4.0 if desde > 0.0 else 0.0
		mmi.visibility_range_end = hasta
		mmi.visibility_range_end_margin = 4.0
		add_child(mmi)

## Distancia a la que deja de dibujarse una planta u objeto disperso, según su tamaño.
func _alcance(nombre: String) -> float:
	if nombre.begins_with("veg_") and not nombre.contains("fern") and not nombre.contains("cattail"):
		return 14.0
	if nombre.begins_with("grass") or nombre in ["dandelion_01", "celandine_01", "bark_debris_01", "dry_branches_medium_01", "moss_01", "nettle_plant"]:
		return 22.0
	if nombre.contains("fern") or nombre.contains("shrub") or nombre.contains("cattail") or nombre.contains("root"):
		return 30.0
	return 45.0

func _multi_planta(nombre: String, xs: Array) -> void:
	var path := "res://zarek/muebles/%s.glb" % nombre
	if not ResourceLoader.exists(path):
		path = "res://zarek/objetos/%s.glb" % nombre
	if xs.is_empty() or not ResourceLoader.exists(path):
		return
	var raiz: Node3D = (load(path) as PackedScene).instantiate()
	for mi in raiz.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		var xf := _xf_rel(m3, raiz)
		var malla: Mesh = _con_viento(m3.mesh, float(VEG_VIENTO[nombre][0]), float(VEG_VIENTO[nombre][1])) if VEG_VIENTO.has(nombre) else m3.mesh
		var xs2: Array = []
		for x in xs:
			xs2.append((x as Transform3D) * xf)
		_mm_trozos(malla, xs2, false, _alcance(nombre))
	raiz.free()

## Orillas con vida: helechos, hierba alta y ortigas en lo alto del talud, y piedras medio hundidas en el agua.
func _orillas(r: Rect2, es_rio: bool) -> void:
	var plantas := {"fern_02": [], "grass_medium_01": [], "grass_medium_02": [], "nettle_plant": [], "shrub_03": [], "veg_cattail": [], "veg_cattail_plant": [], "veg_3d_fern_01": []}
	var claves: Array = plantas.keys()
	var largo := maxf(r.size.x, r.size.y)
	var paso := 0.7
	var k := 0.0
	while k < largo:
		for lado in [-1.0, 1.0]:
			var u := k + _rng.randf_range(0.0, paso)
			var off := _rng.randf_range(-0.2, 0.8)
			var p: Vector3
			if r.size.x >= r.size.y:
				p = Vector3(r.position.x + u, 0.0, (r.position.y - off) if lado < 0 else (r.end.y + off))
			else:
				p = Vector3((r.position.x - off) if lado < 0 else (r.end.x + off), 0.0, r.position.y + u)
			var nm: String = claves[_rng.randi_range(0, claves.size() - 1)]
			var sc := _rng.randf_range(0.8, 1.5)
			(plantas[nm] as Array).append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(sc, sc, sc)), p))
		k += paso
	for nm in plantas:
		_multi_planta(nm, plantas[nm])
	# piedras en la línea del agua
	var np := int(largo / 3.0)
	for i in np:
		var u := _rng.randf()
		var lado := -1.0 if _rng.randf() < 0.5 else 1.0
		var hund := _rng.randf_range(0.2, 0.9)
		var p: Vector3
		if r.size.x >= r.size.y:
			p = Vector3(lerpf(r.position.x, r.end.x, u), -0.75, r.get_center().y + lado * (r.size.y * 0.5 - hund))
		else:
			p = Vector3(r.get_center().x + lado * (r.size.x * 0.5 - hund), -0.75, lerpf(r.position.y, r.end.y, u))
		_prop("boulder_01", p, _rng.randf() * TAU, _rng.randf_range(0.45, 1.1), false)

var _tex_olas: Array = []
## Material de agua (agua.gdshader) con olas de ruido: río con corriente o agua quieta (pilas, estanque).
func _mat_agua(es_rio: bool) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://zarek/agua.gdshader")
	m.set_shader_parameter("olas", load("res://zarek/texturas/agua/water1_normal_bump.png"))
	m.set_shader_parameter("espuma_ruido", load("res://zarek/texturas/agua/foam_noise.png"))
	if es_rio:
		m.set_shader_parameter("corriente", Vector2(1.0, 0.0))
		m.set_shader_parameter("fuerza", 1.4)
		m.set_shader_parameter("velocidad", 0.7)
		m.set_shader_parameter("escala", 0.2)
	else:
		m.set_shader_parameter("corriente", Vector2(0.6, 0.4))
		m.set_shader_parameter("fuerza", 0.12)
		m.set_shader_parameter("velocidad", 0.12)
		m.set_shader_parameter("escala", 0.3)
		m.set_shader_parameter("espuma", 0.8)
		m.set_shader_parameter("relieve", 0.5)
	return m

## Rumor de agua repartido a lo largo de una zona (varios emisores 3D en bucle).
func _sonidos_agua(r: Rect2, tipo: String, cada: float, db: float) -> void:
	var largo := maxf(r.size.x, r.size.y)
	var n := maxi(1, int(largo / cada))
	for k in n:
		var sp := AudioStreamPlayer3D.new()
		sp.stream = AetherSynth.make(tipo)
		sp.unit_size = 3.0
		sp.max_distance = cada * 1.2
		sp.volume_db = db
		sp.autoplay = true
		var u := (k + 0.5) / n
		sp.position = Vector3(lerpf(r.position.x, r.end.x, u) if r.size.x >= r.size.y else r.get_center().x, 0.3, r.get_center().y if r.size.x >= r.size.y else lerpf(r.position.y, r.end.y, u))
		add_child(sp)

func _well(r: Rect2) -> void:
	var c := Vector3(r.get_center().x, 0, r.get_center().y)
	cyl(1.6, 1.7, 1.0, c + Vector3(0, 0.5, 0), _mat.piedra, self, 14)
	cyl(1.3, 1.3, 0.05, c + Vector3(0, 0.98, 0), _mat.oscuro, self, 14)
	for s in [-1.0, 1.0]:
		box(Vector3(0.18, 2.6, 0.18), c + Vector3(s * 1.5, 1.3, 0), _mat.madera_vieja, false, self)
	box(Vector3(3.4, 0.15, 0.15), c + Vector3(0, 2.6, 0), _mat.madera_vieja, false, self)
	var p := PrismMesh.new()
	p.size = Vector3(4.0, 1.2, 3.4)
	var roof := MeshInstance3D.new()
	roof.mesh = p
	roof.material_override = _mat.tejado
	roof.position = c + Vector3(0, 3.3, 0)
	add_child(roof)
	_static_cyl(1.7, 1.0, c + Vector3(0, 0.5, 0))

func _stream_banks(r: Rect2) -> void:
	var x := r.position.x
	while x < r.end.x:
		for s in [r.position.y - 0.3, r.end.y + 0.3]:
			if _rng.randf() < 0.5:
				_prop("boulder_01", Vector3(x + _rng.randf() * 3, -0.55, s + _rng.randf_range(-0.6, 0.6)), _rng.randf() * TAU, _rng.randf_range(0.35, 0.75), false)
		x += 4.0
	var bx := _zone("Puente viejo").get_center().x
	var bz := r.get_center().y
	var largo := r.size.y + 6.0
	var mv: Material = _mat.madera_vieja
	# vigas maestras sobre las que van las tablas, apoyadas en postes metidos en las orillas
	for s2 in [-1.4, 1.4]:
		box(Vector3(0.22, 0.3, largo), Vector3(bx + s2, 0.12, bz), mv, false, self)
	for zz in [bz - largo * 0.5 + 0.3, bz + largo * 0.5 - 0.3, bz - r.size.y * 0.5 - 0.2, bz + r.size.y * 0.5 + 0.2]:
		for s2 in [-1.4, 1.4]:
			cyl(0.13, 0.15, 1.2, Vector3(bx + s2, -0.35, zz), mv, self, 8)
	# tablas sueltas, gastadas, alguna torcida o rota y una que falta
	var nt := int(largo / 0.27)
	for k in nt:
		var z := bz - largo * 0.5 + 0.135 + k * 0.27
		if k == int(nt * 0.43):
			continue
		var tabla := box(Vector3(3.6 + _rng.randf_range(-0.15, 0.1), 0.055, 0.245), Vector3(bx + _rng.randf_range(-0.06, 0.06), 0.3 + _rng.randf_range(-0.01, 0.015), z), mv, false, self)
		tabla.rotation = Vector3(_rng.randf_range(-0.02, 0.02), _rng.randf_range(-0.03, 0.03), _rng.randf_range(-0.015, 0.015))
		if k == int(nt * 0.7):
			tabla.scale.x = 0.55
			tabla.position.x -= 0.8
			tabla.rotation.z = 0.12
	# suelo transitable del puente (una sola caja invisible)
	var piso := box(Vector3(3.6, 0.1, largo), Vector3(bx, 0.28, bz), mv, true, self)
	piso.visible = false
	piso.set_meta("dyn", true)
	# barandillas: postes, pasamanos y tornapuntas en diagonal
	for s2 in [-1.0, 1.0]:
		box(Vector3(0.1, 0.12, largo), Vector3(bx + s2 * 1.75, 1.25, bz), mv, false, self)
		box(Vector3(0.08, 0.08, largo), Vector3(bx + s2 * 1.75, 0.75, bz), mv, false, self)
		for k in 6:
			var zp := bz - largo * 0.5 + 0.2 + k * (largo - 0.4) / 5.0
			box(Vector3(0.13, 1.1, 0.13), Vector3(bx + s2 * 1.75, 0.82, zp), mv, false, self)
			if k < 5:
				var tp := box(Vector3(0.06, 0.06, (largo - 0.4) / 5.0 * 1.05), Vector3(bx + s2 * 1.75, 0.95, zp + (largo - 0.4) / 10.0), mv, false, self)
				tp.rotation.x = 0.32 * (1.0 if k % 2 == 0 else -1.0)

func _maze(r: Rect2) -> void:
	var h := 2.6
	for k in 5:
		var inset := 2.0 + k * 3.2
		var rr := r.grow(-inset)
		if rr.size.x < 2 or rr.size.y < 2:
			break
		var gapx := rr.position.x + rr.size.x * (0.2 + 0.6 * float(k % 2))
		var sides := [[rr.position, Vector2(rr.end.x, rr.position.y)], [Vector2(rr.position.x, rr.end.y), rr.end],
			[rr.position, Vector2(rr.position.x, rr.end.y)], [Vector2(rr.end.x, rr.position.y), rr.end]]
		for i in 4:
			var a: Vector2 = sides[i][0]
			var b: Vector2 = sides[i][1]
			if i == (k % 2):
				_hedge(a, Vector2(gapx - 1.2, a.y), h)
				_hedge(Vector2(gapx + 1.2, a.y), b, h)
			else:
				_hedge(a, b, h)

func _hedge(a: Vector2, b: Vector2, h: float) -> void:
	var l := a.distance_to(b)
	if l < 0.3:
		return
	var c := (a + b) * 0.5
	box(Vector3(l, h, 1.0) if absf(a.y - b.y) < 0.01 else Vector3(1.0, h, l), Vector3(c.x, h * 0.5, c.y), _mat.seto, true, self)

func _shed(name: String, r: Rect2) -> void:
	var c := Vector3(r.get_center().x, 0, r.get_center().y)
	var hh := 3.6
	var glass := name == "Invernadero"
	var wm: Material = _mat.vidrio if glass else (_mat.fachada if name == "Cochera" else _mat.madera_vieja)
	var thick := 0.3
	var sides := [[Vector2(r.position.x, r.position.y), Vector2(r.end.x, r.position.y)], [Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.end.y)],
		[Vector2(r.position.x, r.position.y), Vector2(r.position.x, r.end.y)], [Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.end.y)]]
	var open_side := 2 if glass else 1
	for i in 4:
		var a: Vector2 = sides[i][0]
		var b: Vector2 = sides[i][1]
		var horiz := absf(a.y - b.y) < 0.01
		var l := a.distance_to(b)
		var mid := (a + b) * 0.5
		if i == open_side:
			var gap := 2.2
			var part := (l - gap) * 0.5
			for s in [-1.0, 1.0]:
				var pc: Vector2 = mid + (Vector2(1, 0) if horiz else Vector2(0, 1)) * s * (gap * 0.5 + part * 0.5)
				box(Vector3(part, hh, thick) if horiz else Vector3(thick, hh, part), Vector3(pc.x, hh * 0.5, pc.y), wm, true, self)
			box(Vector3(gap, hh - 2.6, thick) if horiz else Vector3(thick, hh - 2.6, gap), Vector3(mid.x, 2.6 + (hh - 2.6) * 0.5, mid.y), wm, false, self)
			continue
		box(Vector3(l, hh, thick) if horiz else Vector3(thick, hh, l), Vector3(mid.x, hh * 0.5, mid.y), wm, true, self)
		if glass:
			for k in int(l / 1.5):
				var fp := a + (b - a).normalized() * (k * 1.5)
				box(Vector3(0.08, hh, 0.08), Vector3(fp.x, hh * 0.5, fp.y), _mat.metal, false, self)
	var pm := PrismMesh.new()
	pm.size = Vector3(r.size.x + 0.8, 2.2, r.size.y + 0.8)
	var roof := MeshInstance3D.new()
	roof.mesh = pm
	roof.material_override = _mat.vidrio if glass else _mat.tejado
	roof.position = c + Vector3(0, hh + 1.1, 0)
	add_child(roof)
	box(Vector3(r.size.x, 0.1, r.size.y), c + Vector3(0, 0.05, 0), _mat.madera if not glass else _mat.piedra, false, self, false)
	if glass:
		for k in 10:
			var pp := c + Vector3(_rng.randf_range(-r.size.x * 0.35, r.size.x * 0.35), 0, _rng.randf_range(-r.size.y * 0.35, r.size.y * 0.35))
			cyl(0.25, 0.3, 0.5, pp + Vector3(0, 0.25, 0), _mat.tierra, self, 8)
			cyl(0.0, 0.35, 0.9, pp + Vector3(0, 0.95, 0), _mat.tela_verde, self, 6)
	if name == "Cochera":
		box(Vector3(2.0, 1.2, 4.6), c + Vector3(0, 0.6, 0), _mat.sabana, true, self)
	var l := OmniLight3D.new()
	l.light_color = Color(0.6, 0.7, 1.0)
	l.light_energy = 0.25
	l.omni_range = 7.0
	l.position = c + Vector3(0, 2.5, 0)
	add_child(l)

func _porch(r: Rect2) -> void:
	var c := Vector3(r.get_center().x, 0, r.get_center().y)
	box(Vector3(r.size.x, 0.2, r.size.y), c + Vector3(0, 0.0, 0), _mat.madera, true, self, false)
	box(Vector3(r.size.x + 0.6, 0.25, r.size.y + 0.6), c + Vector3(0, 3.7, 0), _mat.tejado, false, self)
	var n := int(r.size.x / 3.0)
	for k in n + 1:
		var px := r.position.x + k * 3.0
		cyl(0.16, 0.18, 3.6, Vector3(px, 1.8, r.end.y - 0.2), _mat.moldura, self, 10)
		if k < n:
			box(Vector3(2.8, 0.25, 0.08), Vector3(px + 1.5, 3.45, r.end.y - 0.2), _mat.moldura, false, self)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.7, 0.4)
	l.light_energy = 1.6
	l.omni_range = 10.0
	l.position = Vector3(c.x, 3.2, r.position.y + 0.8)
	add_child(l)
	cyl(0.12, 0.12, 0.35, l.position, _mat.ventana_luz, self, 8)

func _trees(W: float, H: float) -> void:
	var avoid: Array = []
	for z in plan.exterior.zonas:
		var name: String = z[0]
		if name.begins_with("Bosque"):
			continue
		var r := Rect2(float(z[2]) * CELL, float(z[3]) * CELL, float(z[4]) * CELL, float(z[5]) * CELL)
		avoid.append(r.grow(1.0 if name.begins_with("Terrenos") else 2.5))
	var xforms: Array[Transform3D] = []
	var count := 2200 if quality >= 2 else (1400 if quality == 1 else 800)
	var tries := 0
	while xforms.size() < count and tries < count * 8:
		tries += 1
		var p := Vector2(_rng.randf_range(2, W - 2), _rng.randf_range(2, H - 2))
		var bad := false
		for r in avoid:
			if (r as Rect2).has_point(p):
				bad = true
				break
		if bad:
			continue
		var s := _rng.randf_range(0.8, 1.45)
		xforms.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s * _rng.randf_range(0.9, 1.3), s)), Vector3(p.x, 0, p.y)))
	# árboles realistas (Ez-Tree) cerca y abetos sencillos a lo lejos, repartidos en parcelas de 24 m para que
	# solo se dibuje con detalle el bosque que rodea al jugador (la niebla tapa el resto)
	var pinos := ["pino_grande_1", "pino_grande_2", "pino_grande_3", "pino_mediano_1", "pino_mediano_2", "pino_joven", "muerto_roble", "muerto_fresno", "muerto_roble_2",
		"fresno_joven", "alamo_joven", "roble_joven", "roble_mediano", "fresno_mediano", "muerto_alamo", "muerto_joven"]
	var peso := [14, 14, 14, 12, 12, 9, 4, 4, 5, 6, 4, 6, 6, 6, 3, 4]
	var mallas: Array = []
	var medios: Array = []
	for nm in pinos:
		mallas.append(_malla_glb("res://zarek/arboles/%s.glb" % nm))
		medios.append(_arbol_medio(mallas[-1]) if mallas[-1] != null else null)
	var lejos: Array = []
	for v in 3:
		lejos.append(_abeto_mesh(100 + v, 0.85 + v * 0.12))
	var PARC := 24.0
	var parcelas: Dictionary = {}
	var total_peso := 0
	for w in peso:
		total_peso += w
	for i in xforms.size():
		var t: Transform3D = xforms[i]
		var tira := _rng.randi_range(0, total_peso - 1)
		var v := 0
		while tira >= int(peso[v]):
			tira -= int(peso[v])
			v += 1
		var s := _rng.randf_range(0.85, 1.12)
		var tt := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s * _rng.randf_range(0.95, 1.08), s)), t.origin)
		var clave := Vector2i(int(t.origin.x / PARC), int(t.origin.z / PARC))
		if not parcelas.has(clave):
			parcelas[clave] = {}
		var pc: Dictionary = parcelas[clave]
		if not pc.has(v):
			pc[v] = []
		pc[v].append(tt)
	for clave in parcelas:
		var pc: Dictionary = parcelas[clave]
		var lejos_xs: Array = [[], [], []]
		for v in pc:
			var lista: Array = pc[v]
			if mallas[v] != null:
				var muerto: bool = String(pinos[v]).begins_with("muerto")
				var fx := 0.012 if muerto else (0.025 if v < 6 else 0.035)
				var tb := 0.0 if muerto else 0.035
				_multi_arbol(_con_viento(mallas[v], fx, tb), lista, 0.0, 22.0, true)
				_multi_arbol(_con_viento(medios[v], fx, tb), lista, 20.0, 68.0 if quality >= 2 else 46.0, true)
			if v < 6:
				for k in lista.size():
					lejos_xs[k % 3].append(lista[k])
		for k in 3:
			if lejos_xs[k].size() > 0:
				_multi_arbol(_con_viento(lejos[k], 0.02, 0.0), lejos_xs[k], 60.0 if quality >= 2 else 40.0, 0.0, false)
	# setas al pie de los árboles (en corros de 2-6) y helechos grandes entre los troncos
	var setas := ["veg_boletus_edulis_mushroom", "veg_chanterelle", "veg_tricholoma_murrillianum_", "veg_shaggy_parasol_mushroom_", "veg_mushroom", "veg_mushroom_on_tree_baked_l"]
	var por_seta: Dictionary = {}
	for k in int(260 * (1.0 if quality >= 2 else 0.6)):
		var base: Transform3D = xforms[_rng.randi_range(0, xforms.size() - 1)]
		var sn: String = setas[_rng.randi_range(0, setas.size() - 1)]
		if not por_seta.has(sn):
			por_seta[sn] = []
		var a := _rng.randf() * TAU
		var c0 := base.origin + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(0.6, 1.4)
		for j in (1 if sn.contains("tree") or sn == "veg_mushroom" else _rng.randi_range(2, 6)):
			var sc := _rng.randf_range(0.7, 1.3)
			(por_seta[sn] as Array).append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(sc, sc, sc)), c0 + Vector3(_rng.randf_range(-0.25, 0.25), -0.01, _rng.randf_range(-0.25, 0.25))))
	for sn in por_seta:
		_multi_planta(sn, por_seta[sn])
	var helechos: Array = []
	for k in int(700 * (1.0 if quality >= 2 else 0.6)):
		var p := Vector2(_rng.randf_range(2, W - 2), _rng.randf_range(2, H - 2))
		var mal := false
		for r in avoid:
			if (r as Rect2).has_point(p):
				mal = true
				break
		if not mal:
			var sc := _rng.randf_range(0.7, 1.4)
			helechos.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(sc, sc, sc)), Vector3(p.x, -0.03, p.y)))
	_multi_planta("veg_3d_fern_01", helechos)
	# arbustos bajo los árboles
	var arb := [_malla_glb("res://zarek/arboles/arbusto_1.glb"), _malla_glb("res://zarek/arboles/arbusto_2.glb"), _malla_glb("res://zarek/arboles/arbusto_3.glb")]
	var arb_xs: Array = [[], [], []]
	var na := int(900 * (1.0 if quality >= 2 else 0.6))
	var intentos := 0
	while arb_xs[0].size() + arb_xs[1].size() + arb_xs[2].size() < na and intentos < na * 6:
		intentos += 1
		var p := Vector2(_rng.randf_range(2, W - 2), _rng.randf_range(2, H - 2))
		var mal := false
		for r in avoid:
			if (r as Rect2).has_point(p):
				mal = true
				break
		if mal:
			continue
		var sa := _rng.randf_range(0.7, 1.3)
		arb_xs[_rng.randi_range(0, 2)].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(sa, sa, sa)), Vector3(p.x, -0.05, p.y)))
	for k in 3:
		if arb[k] != null:
			var porp: Dictionary = {}
			for t in arb_xs[k]:
				var cl := Vector2i(int(t.origin.x / PARC), int(t.origin.z / PARC))
				if not porp.has(cl):
					porp[cl] = []
				porp[cl].append(t)
			for cl in porp:
				_multi_arbol(_con_viento(arb[k], 0.12, 0.03), porp[cl], 0.0, 45.0, false)
	_sotobosque(W, H, avoid)
	_jardin_salvaje()
	# colisión de troncos con un solo cuerpo
	var sb := StaticBody3D.new()
	add_child(sb)
	var sh := CylinderShape3D.new()
	sh.radius = 0.45
	sh.height = 4.0
	for t in xforms:
		var cs := CollisionShape3D.new()
		cs.shape = sh
		cs.position = t.origin + Vector3(0, 2.0, 0)
		sb.add_child(cs)
	for z in plan.exterior.zonas:
		var name: String = z[0]
		if name.begins_with("Árbol") or name.begins_with("Claro del columpio"):
			var c := Vector3((float(z[2]) + float(z[4]) * 0.5) * CELL, 0, (float(z[3]) + float(z[5]) * 0.5) * CELL)
			_dead_tree(c, name.begins_with("Claro"))

## Un GLB de árbol en una sola malla (ramas + hojas como superficies), con las hojas en recorte alfa
## (sin transparencia real: barato en móvil y sin problemas de orden).
func _malla_glb(path: String) -> ArrayMesh:
	if not ResourceLoader.exists(path):
		return null
	var ps: PackedScene = load(path)
	if ps == null:
		return null
	var raiz: Node3D = ps.instantiate()
	var am := ArrayMesh.new()
	for mi in raiz.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		var xf := _xf_rel(m3, raiz)
		for si in m3.mesh.get_surface_count():
			var arr: Array = m3.mesh.surface_get_arrays(si)
			if xf != Transform3D.IDENTITY:
				var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				for k in vs.size():
					vs[k] = xf * vs[k]
				arr[Mesh.ARRAY_VERTEX] = vs
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			# guarda un nivel de detalle reducido de la malla original (para el árbol de media distancia)
			var sd: Dictionary = RenderingServer.mesh_get_surface(m3.mesh.get_rid(), si)
			var lods: Array = sd.get("lods", [])
			var n_ix: int = (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() if arr[Mesh.ARRAY_INDEX] != null else 0
			var mejor := PackedInt32Array()
			for l in lods:
				var bytes: PackedByteArray = l.get("index_data", PackedByteArray())
				var ancho := 2 if (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() <= 65535 else 4
				var cnt := bytes.size() / ancho
				if cnt >= n_ix / 5 and (mejor.is_empty() or cnt < mejor.size()):
					mejor = PackedInt32Array()
					mejor.resize(cnt)
					for q in cnt:
						mejor[q] = bytes.decode_u16(q * 2) if ancho == 2 else bytes.decode_u32(q * 4)
			if not mejor.is_empty():
				am.set_meta("lod_%d" % (am.get_surface_count() - 1), mejor)
			var mat := m3.mesh.surface_get_material(si)
			if mat is BaseMaterial3D:
				var bm: BaseMaterial3D = (mat as BaseMaterial3D).duplicate()
				if bm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or bm.albedo_texture != null and String(bm.resource_name).begins_with("hojas"):
					bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
					bm.alpha_scissor_threshold = 0.35
					bm.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE
					bm.cull_mode = BaseMaterial3D.CULL_DISABLED
					bm.backlight_enabled = true
					bm.backlight = Color(0.1, 0.16, 0.08)
				am.surface_set_material(am.get_surface_count() - 1, bm)
	raiz.free()
	return am

## Árbol para media distancia: un 30 % de las tarjetas de hojas (más grandes, para tapar lo mismo) y la
## corteza con su nivel de detalle reducido. De ~10.000 triángulos pasa a ~3.000.
func _arbol_medio(am: ArrayMesh) -> ArrayMesh:
	var out := ArrayMesh.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for si in am.get_surface_count():
		var arr: Array = am.surface_get_arrays(si)
		var mat := am.surface_get_material(si)
		var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var hojas := mat is BaseMaterial3D and (mat as BaseMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED
		if hojas and ix.size() % 6 == 0 and ix.size() > 0:
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var nix := PackedInt32Array()
			for g in range(0, ix.size(), 6):
				if rng.randf() > 0.3:
					continue
				var c := Vector3.ZERO
				var us: Array = []
				for k in 6:
					if not (ix[g + k] in us):
						us.append(ix[g + k])
				for u in us:
					c += vs[u]
				c /= float(us.size())
				for u in us:
					vs[u] = c + (vs[u] - c) * 1.6
				for k in 6:
					nix.append(ix[g + k])
			arr[Mesh.ARRAY_VERTEX] = vs
			arr[Mesh.ARRAY_INDEX] = nix
		elif am.has_meta("lod_%d" % si):
			arr[Mesh.ARRAY_INDEX] = am.get_meta("lod_%d" % si)
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		out.surface_set_material(si, mat)
	return out

var _shader_veg: Shader
var _cache_viento: Dictionary = {}
## Copia de una malla de planta con sus materiales cambiados por el de viento (vegetacion.gdshader).
## flex: cuánto se dobla la punta (fracción de la altura); temblor: vibración de hojas en metros.
func _con_viento(malla: Mesh, flex: float, temblor: float) -> Mesh:
	if malla == null:
		return null
	var clave := "%d_%.3f_%.3f" % [malla.get_instance_id(), flex, temblor]
	if _cache_viento.has(clave):
		return _cache_viento[clave]
	if _shader_veg == null:
		_shader_veg = load("res://zarek/vegetacion.gdshader")
	var copia: Mesh = malla.duplicate()
	var alto := maxf(malla.get_aabb().end.y, 0.05)
	for si in copia.get_surface_count():
		var orig := malla.surface_get_material(si)
		var sm := ShaderMaterial.new()
		sm.shader = _shader_veg
		sm.set_shader_parameter("altura", alto)
		var es_tronco := false
		if orig is BaseMaterial3D:
			var bm := orig as BaseMaterial3D
			sm.set_shader_parameter("color", bm.albedo_color)
			if bm.albedo_texture:
				sm.set_shader_parameter("albedo_tex", bm.albedo_texture)
				sm.set_shader_parameter("usa_albedo", true)
			if bm.normal_enabled and bm.normal_texture:
				sm.set_shader_parameter("normal_tex", bm.normal_texture)
				sm.set_shader_parameter("usa_normal", true)
			if bm.roughness_texture:
				sm.set_shader_parameter("rough_tex", bm.roughness_texture)
				sm.set_shader_parameter("usa_rough", true)
			sm.set_shader_parameter("rugosidad", bm.roughness)
			if bm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				sm.set_shader_parameter("corte", maxf(bm.alpha_scissor_threshold, 0.3))
			else:
				es_tronco = String(bm.resource_name).contains("corteza") or String(bm.resource_name).contains("bark") or String(bm.resource_name).contains("trunk")
			if bm.backlight_enabled:
				sm.set_shader_parameter("trasluz", Vector3(bm.backlight.r, bm.backlight.g, bm.backlight.b))
			elif bm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				sm.set_shader_parameter("trasluz", Vector3(0.08, 0.12, 0.06))
		sm.set_shader_parameter("flex", flex)
		sm.set_shader_parameter("temblor", 0.0 if es_tronco else temblor)
		copia.surface_set_material(si, sm)
	_cache_viento[clave] = copia
	return copia

func _multi_arbol(malla: Mesh, xs: Array, desde: float, hasta: float, sombra: bool) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = malla
	mm.instance_count = xs.size()
	for i in xs.size():
		mm.set_instance_transform(i, xs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if sombra else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.visibility_range_begin = desde
	mmi.visibility_range_end = hasta
	mmi.visibility_range_begin_margin = 6.0 if desde > 0.0 else 0.0
	mmi.visibility_range_end_margin = 6.0 if hasta > 0.0 else 0.0
	mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	add_child(mmi)

var _mat_rama: StandardMaterial3D
## Abeto de unos 12 m: tronco con corteza real y verticilos de ramas (tarjetas con textura de rama y alfa).
func _abeto_mesh(semilla: int, caida: float) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla
	if _mat_rama == null:
		_mat_rama = StandardMaterial3D.new()
		_mat_rama.albedo_texture = load("res://zarek/texturas/abeto/rama.png")
		_mat_rama.albedo_color = Color(0.78, 0.86, 0.8)
		_mat_rama.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		_mat_rama.alpha_scissor_threshold = 0.5
		_mat_rama.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE_AND_TO_ONE
		_mat_rama.alpha_antialiasing_edge = 0.3
		_mat_rama.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mat_rama.roughness = 0.92
		_mat_rama.backlight_enabled = true
		_mat_rama.backlight = Color(0.12, 0.2, 0.1)
		_mat_rama.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var mesh := ArrayMesh.new()
	# tronco
	var cm := CylinderMesh.new()
	cm.top_radius = 0.04
	cm.bottom_radius = 0.3
	cm.height = 12.0
	cm.radial_segments = 8
	cm.rings = 2
	var arr := cm.get_mesh_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		verts[i].y += 6.0
	arr[Mesh.ARRAY_VERTEX] = verts
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	mesh.surface_set_material(0, _mat.corteza)
	# ramas
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var up := Vector3.UP
	var y := 1.9 + rng.randf() * 0.4
	var giro := rng.randf() * TAU
	while y < 11.4:
		var t := y / 12.0
		var n := 4 if t < 0.8 else 3
		giro += 0.9 + rng.randf() * 0.5
		for k in n:
			var th := giro + TAU * k / n + rng.randf_range(-0.25, 0.25)
			var d := Vector3(cos(th), 0, sin(th))
			var largo := (pow(1.0 - t, 0.85) * 3.4 + 0.5) * rng.randf_range(0.85, 1.12)
			var ancho := largo * 0.62
			var phi := deg_to_rad(lerpf(30.0, 8.0, t) * caida + rng.randf_range(-6.0, 6.0))
			var eje := (d * cos(phi) - up * sin(phi)).normalized()
			var lado := up.cross(d).normalized()
			var r0 := lerpf(0.26, 0.05, t)
			var base := Vector3(0, y, 0) + d * (r0 * 0.5)
			for capa in 2:
				var w := lado.rotated(eje, 0.0 if capa == 0 else 1.25)
				var nrm := (d * 0.6 + up * 0.8).normalized()
				var q := [base - w * ancho * 0.5, base + w * ancho * 0.5, base + eje * largo + w * ancho * 0.5, base + eje * largo - w * ancho * 0.5]
				var uv := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
				for idx in [0, 1, 2, 0, 2, 3]:
					st.set_normal(nrm)
					st.set_uv(uv[idx])
					st.add_vertex(q[idx])
		y += rng.randf_range(0.42, 0.55)
	# punta: tres tarjetas verticales cruzadas
	for k in 3:
		var a := TAU * k / 6.0
		var w := Vector3(cos(a), 0, sin(a))
		var q := [Vector3(0, 10.3, 0) - w * 0.55, Vector3(0, 10.3, 0) + w * 0.55, Vector3(0, 12.3, 0) + w * 0.55, Vector3(0, 12.3, 0) - w * 0.55]
		var uv := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		for idx in [0, 1, 2, 0, 2, 3]:
			st.set_normal((w.cross(up)).normalized() * 0.3 + up * 0.7)
			st.set_uv(uv[idx])
			st.add_vertex(q[idx])
	var ramas := st.commit()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, ramas.surface_get_arrays(0))
	mesh.surface_set_material(1, _mat_rama)
	return mesh

## Suelo del bosque: helechos, rocas con musgo, troncos caídos, tocones, corteza, raíces y matorral (Poly Haven, CC0).
func _sotobosque(W: float, H: float, avoid: Array) -> void:
	var cuantos := 1.0 if quality >= 2 else (0.6 if quality == 1 else 0.35)
	var lista := [["fern_02", 700, 0.8, 1.5], ["shrub_03", 260, 0.7, 1.3], ["shrub_04", 200, 0.7, 1.2], ["rock_moss_set_02", 60, 0.35, 0.7],
		["boulder_01", 45, 0.8, 2.0], ["dead_tree_trunk", 30, 0.9, 1.3], ["dead_tree_trunk_02", 30, 0.9, 1.3], ["tree_stump_02", 70, 0.8, 1.4],
		["bark_debris_01", 220, 0.8, 1.6], ["root_cluster_02", 30, 0.6, 1.0], ["dry_branches_medium_01", 180, 0.8, 1.4], ["moss_01", 160, 0.8, 1.6]]
	for it in lista:
		var nombre: String = it[0]
		var path := "res://zarek/muebles/%s.glb" % nombre
		if not ResourceLoader.exists(path):
			continue
		var ps: PackedScene = load(path)
		if ps == null:
			continue
		var raiz: Node3D = ps.instantiate()
		var partes: Array = []
		for mi in raiz.find_children("*", "MeshInstance3D", true, false):
			var m3 := mi as MeshInstance3D
			partes.append([m3.mesh, _xf_rel(m3, raiz)])
		raiz.free()
		var xs: Array[Transform3D] = []
		var n := int(float(it[1]) * cuantos)
		var intentos := 0
		while xs.size() < n and intentos < n * 6:
			intentos += 1
			var p := Vector2(_rng.randf_range(2, W - 2), _rng.randf_range(2, H - 2))
			var mal := false
			for r in avoid:
				if (r as Rect2).has_point(p):
					mal = true
					break
			if mal:
				continue
			var sc := _rng.randf_range(float(it[2]), float(it[3]))
			xs.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(sc, sc, sc)), Vector3(p.x, -0.02, p.y)))
		for pt in partes:
			var malla: Mesh = _con_viento(pt[0], float(VEG_VIENTO[nombre][0]), float(VEG_VIENTO[nombre][1])) if VEG_VIENTO.has(nombre) else pt[0]
			var xs2: Array = []
			for x in xs:
				xs2.append(x * (pt[1] as Transform3D))
			_mm_trozos(malla, xs2, nombre in ["boulder_01", "dead_tree_trunk", "dead_tree_trunk_02", "tree_stump_02"], _alcance(nombre))

## Los jardines de la mansión llevan años sin cuidar: hierba alta, matorral, ortigas y flores silvestres.
func _jardin_salvaje() -> void:
	var zonas: Array = []
	var fuera: Array = []
	for z in plan.exterior.zonas:
		var r := Rect2(float(z[2]) * CELL, float(z[3]) * CELL, float(z[4]) * CELL, float(z[5]) * CELL)
		if z[1] == "jardin":
			zonas.append(r)
		elif z[1] in ["edificio", "agua", "camino"]:
			fuera.append(r.grow(0.8))
	var cuantos := 1.0 if quality >= 2 else (0.6 if quality == 1 else 0.35)
	var lista := [["grass_medium_01", 1400, 0.9, 1.6], ["grass_medium_02", 1200, 0.9, 1.6], ["shrub_02", 160, 0.7, 1.2], ["nettle_plant", 300, 0.8, 1.3],
		["dandelion_01", 260, 0.9, 1.3], ["celandine_01", 200, 0.9, 1.3], ["fern_02", 120, 0.7, 1.1], ["dry_branches_medium_01", 90, 0.8, 1.3], ["bark_debris_01", 60, 0.8, 1.2]]
	for it in lista:
		var nombre: String = it[0]
		var path := "res://zarek/muebles/%s.glb" % nombre
		if not ResourceLoader.exists(path):
			continue
		var ps: PackedScene = load(path)
		if ps == null:
			continue
		var raiz: Node3D = ps.instantiate()
		var partes: Array = []
		for mi in raiz.find_children("*", "MeshInstance3D", true, false):
			partes.append([(mi as MeshInstance3D).mesh, _xf_rel(mi, raiz)])
		raiz.free()
		var xs: Array[Transform3D] = []
		var n := int(float(it[1]) * cuantos)
		var intentos := 0
		while xs.size() < n and intentos < n * 8:
			intentos += 1
			var zr: Rect2 = zonas[_rng.randi_range(0, zonas.size() - 1)]
			var p := Vector2(_rng.randf_range(zr.position.x, zr.end.x), _rng.randf_range(zr.position.y, zr.end.y))
			var mal := house_rect.grow(0.3).has_point(p)
			for r in fuera:
				if mal:
					break
				mal = (r as Rect2).has_point(p)
			if mal:
				continue
			var sc := _rng.randf_range(float(it[2]), float(it[3]))
			xs.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(sc, sc, sc)), Vector3(p.x, 0.0, p.y)))
		for pt in partes:
			var malla: Mesh = _con_viento(pt[0], float(VEG_VIENTO[nombre][0]), float(VEG_VIENTO[nombre][1])) if VEG_VIENTO.has(nombre) else pt[0]
			var xs2: Array = []
			for x in xs:
				xs2.append(x * (pt[1] as Transform3D))
			_mm_trozos(malla, xs2, false, _alcance(nombre))

## Transformación de un nodo relativa a un antecesor (sin estar en el árbol de escena).
func _xf_rel(n: Node3D, raiz: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var q: Node = n
	while q and q != raiz:
		if q is Node3D:
			t = (q as Node3D).transform * t
		q = q.get_parent()
	return t

func _dead_tree(c: Vector3, with_swing: bool) -> void:
	cyl(0.35, 0.6, 7.0, c + Vector3(0, 3.5, 0), _mat.corteza, self, 8)
	_static_cyl(0.6, 4.0, c + Vector3(0, 2.0, 0))
	for k in 6:
		var b := cyl(0.06, 0.18, 3.5, c + Vector3(cos(k * 1.05) * 1.2, 4.5 + k * 0.5, sin(k * 1.05) * 1.2), _mat.corteza, self, 6)
		b.rotation = Vector3(_rng.randf_range(0.6, 1.2), k * 1.05, 0)
	if with_swing:
		swing = Node3D.new()
		swing.set_meta("dyn", true)
		swing.position = c + Vector3(1.6, 5.4, 0)
		add_child(swing)
		for s in [-0.35, 0.35]:
			box(Vector3(0.03, 4.3, 0.03), Vector3(s, -2.15, 0), _mat.metal, false, swing)
		box(Vector3(0.9, 0.06, 0.35), Vector3(0, -4.3, 0), _mat.madera, false, swing)

# ---------------- marcas del plano ----------------
func _markers() -> void:
	for key in ["exterior", "sotano", "baja", "alta", "atico"]:
		var p: Dictionary = plan[key]
		for m in p.get("marcas", []):
			var k: String = m[0]
			var pos := cell_to_world(key, float(m[1]), float(m[2]))
			match k:
				"inicio":
					start_pos = pos + Vector3(0, 0, -2.0)
					_car(pos + Vector3(3.0, 0, 1.0))
				"sello":
					_seal(pos)
				"armario":
					_wardrobe(pos)
				"lampara":
					_lamp(pos)
				"chimenea":
					_fireplace(pos)
				"radio":
					radio_pos = pos + Vector3(0, 1.0, 0)
					_fonografo(pos)
				"caja":
					musicbox_pos = pos + Vector3(0, 1.0, 0)
					if _prop("painted_wooden_nightstand", pos, 0.3, 1.2) != null:
						_prop("jugu_music_box_prop", pos + Vector3(0, 0.616 * 1.2, 0), 0.3, 1.6, false)
					else:
						box(Vector3(0.8, 0.8, 0.5), pos + Vector3(0, 0.4, 0), _mat.madera)
						box(Vector3(0.35, 0.2, 0.25), pos + Vector3(0, 0.9, 0), _mat.oro, false)
				"circulo":
					circle_pos = pos
					_salt_circle(pos)
				"piano":
					_piano(pos)
				"puerta":
					if str(m[3]).begins_with("Entrada"):
						front_door = pos
	var spots := [["baja", 2.0, 2.6, "pila"], ["baja", 13.8, 11.4, "sal"], ["alta", 13.0, 11.0, "pila"], ["sotano", 10.5, 10.5, "pila"],
		["exterior", 70.0, 77.5, "sal"], ["exterior", 26.5, 17.0, "pila"], ["atico", 10.0, 6.0, "sal"], ["alta", 1.5, 6.5, "sal"]]
	for s in spots:
		_pickup(cell_to_world(s[0], s[1], s[2]), s[3])

func _car(p: Vector3) -> void:
	var n := Node3D.new()
	n.set_meta("dyn", true)
	n.position = p
	n.rotation.y = 0.35
	add_child(n)
	var body := _plain(Color(0.2, 0.24, 0.22), 0.4, 0.6)
	box(Vector3(1.8, 0.8, 4.4), Vector3(0, 0.75, 0), body, true, n)
	box(Vector3(1.6, 0.7, 2.2), Vector3(0, 1.45, 0.2), body, false, n)
	box(Vector3(1.55, 0.55, 0.05), Vector3(0, 1.45, -0.9), _mat.vidrio, false, n)
	for w in [Vector3(-0.9, 0.35, 1.4), Vector3(0.9, 0.35, 1.4), Vector3(-0.9, 0.35, -1.4), Vector3(0.9, 0.35, -1.4)]:
		var wh := cyl(0.36, 0.36, 0.25, w, _mat.oscuro, n, 12)
		wh.rotation.z = PI * 0.5
	var hood := box(Vector3(1.7, 0.05, 1.3), Vector3(0, 1.35, -1.6), body, false, n)
	hood.rotation.x = -0.9
	var lights := Node3D.new()
	lights.name = "intermitentes"
	n.add_child(lights)
	for s in [-0.7, 0.7]:
		var ol := OmniLight3D.new()
		ol.light_color = Color(1.0, 0.55, 0.1)
		ol.light_energy = 1.4
		ol.omni_range = 8.0
		ol.position = Vector3(s, 0.9, -2.3)
		lights.add_child(ol)
	var head := SpotLight3D.new()
	head.light_color = Color(1.0, 0.95, 0.8)
	head.light_energy = 3.0
	head.spot_range = 22.0
	head.spot_angle = 28.0
	head.position = Vector3(0, 0.8, -2.3)
	n.add_child(head)
	set_meta("car", n)

func _seal(pos: Vector3) -> void:
	# el sello descansa sobre un velador de época, junto a una vela
	var alto := 0.9
	var mesa := _prop("side_table_tall_01", pos, 0.4, 1.15)
	if mesa:
		alto = 0.761 * 1.15
		_prop("wooden_candlestick", pos + Vector3(0.12, alto, 0.08), 0.0, 0.8, false)
	else:
		box(Vector3(0.8, 0.9, 0.6), pos + Vector3(0, 0.45, 0), _mat.madera)
	var n := Node3D.new()
	n.set_meta("dyn", true)
	n.position = pos + Vector3(-0.05, alto + 0.2, 0)
	add_child(n)
	var disc := cyl(0.17, 0.17, 0.035, Vector3.ZERO, _mat.sello, n, 20)
	disc.rotation.x = PI * 0.5
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.7, 0.3)
	l.omni_range = 3.5
	l.light_energy = 0.8
	n.add_child(l)
	seals.append({"node": n, "pos": pos, "taken": false})

func _wall_dir(pos: Vector3) -> Vector3:
	var best := Vector3(0, 0, -1)
	var bd := 1e9
	var id := room_at(pos)
	if id >= 0:
		var r: Rect2 = rooms[id].rect
		var ds := {Vector3(-1, 0, 0): pos.x - r.position.x, Vector3(1, 0, 0): r.end.x - pos.x, Vector3(0, 0, -1): pos.z - r.position.y, Vector3(0, 0, 1): r.end.y - pos.z}
		for k in ds:
			if ds[k] < bd:
				bd = ds[k]
				best = k
	return best

func _snap_to_wall(pos: Vector3, depth: float) -> Array:
	var back := _wall_dir(pos)
	var id := room_at(pos)
	var p := pos
	if id >= 0:
		var r: Rect2 = rooms[id].rect
		if back.x != 0:
			p.x = (r.position.x + depth) if back.x < 0 else (r.end.x - depth)
		else:
			p.z = (r.position.y + depth) if back.z < 0 else (r.end.y - depth)
	return [p, back]

func _wardrobe(pos: Vector3) -> void:
	var sw := _snap_to_wall(pos, 0.6)
	var wpos: Vector3 = sw[0]
	var back: Vector3 = sw[1]
	if room_at(pos) < 0:
		wpos = pos
	var n := Node3D.new()
	n.position = wpos
	n.rotation.y = atan2(-back.x, -back.z)
	add_child(n)
	# cuerpo hueco (por dentro se ve el armario de verdad cuando te escondes); el choque sigue siendo un bloque
	var macizo := box(Vector3(1.6, 2.5, 0.85), Vector3(0, 1.25, 0), _mat.madera, true, n)
	macizo.visible = false
	macizo.set_meta("dyn", true)
	box(Vector3(1.6, 2.5, 0.04), Vector3(0, 1.25, -0.405), _mat.madera, false, n)
	box(Vector3(0.04, 2.5, 0.85), Vector3(-0.78, 1.25, 0), _mat.madera, false, n)
	box(Vector3(0.04, 2.5, 0.85), Vector3(0.78, 1.25, 0), _mat.madera, false, n)
	box(Vector3(1.6, 0.06, 0.85), Vector3(0, 0.03, 0), _mat.madera, false, n)
	box(Vector3(1.6, 0.04, 0.85), Vector3(0, 2.48, 0), _mat.madera, false, n)
	# fondo interior (el trasero queda metido en el muro)
	box(Vector3(1.52, 2.4, 0.02), Vector3(0, 1.25, -0.24), _mat.madera, false, n)
	box(Vector3(1.52, 0.03, 0.3), Vector3(0, 2.15, -0.09), _mat.madera, false, n)
	_ropa_armario(n)
	box(Vector3(0.76, 2.2, 0.05), Vector3(-0.39, 1.2, 0.44), _mat.madera, false, n)
	box(Vector3(0.76, 2.2, 0.05), Vector3(0.39, 1.2, 0.44), _mat.madera, false, n)
	box(Vector3(1.75, 0.18, 0.95), Vector3(0, 2.55, 0), _mat.madera, false, n)
	box(Vector3(0.9, 0.35, 0.08), Vector3(0, 2.8, 0.38), _mat.madera, false, n)
	box(Vector3(0.04, 0.2, 0.06), Vector3(-0.06, 1.25, 0.48), _mat.oro, false, n)
	box(Vector3(0.04, 0.2, 0.06), Vector3(0.06, 1.25, 0.48), _mat.oro, false, n)
	var front := -back
	wardrobes.append({"pos": wpos + front * 1.05, "inside": wpos + front * 0.05, "yaw": atan2(-front.x, -front.z)})

## Dentro del armario: barra con perchas y prendas colgadas a los lados (deja el centro libre para esconderse),
## una sombrerera o sombrero en la balda y zapatos en el suelo.
const ROPA_COLGADA := ["ropa_robe", "ropa_black_dress", "ropa_dress_plain2", "ropa_1830s_frock_coat_unbuttoned", "ropa_a_fashionable_waistcoat", "ropa_gray_sweater", "ropa_heavy_worn_jacket", "ropa_victorian_vampire"]
func _ropa_armario(n: Node3D) -> void:
	_load_props_info()
	var barra := cyl(0.012, 0.012, 1.5, Vector3(0, 2.0, 0), _mat.metal, n, 8)
	barra.rotation.z = PI * 0.5
	var xs := [-0.66, -0.52, -0.38, 0.38, 0.52, 0.66]
	for x in xs:
		if _rng.randf() < 0.18:
			continue
		var nombre: String = ROPA_COLGADA[_rng.randi_range(0, ROPA_COLGADA.size() - 1)]
		if not _props_info.has(nombre):
			continue
		var t := _prop_size(nombre)
		var esc := minf(1.0, 1.45 / maxf(t.y, 0.1))
		var ancho := minf(1.0, 0.7 / maxf(t.x * esc, 0.1))
		var pr := _prop(nombre, Vector3(x + _rng.randf_range(-0.02, 0.02), 1.96 - t.y * esc, 0.0), PI * 0.5 + _rng.randf_range(-0.08, 0.08), esc, false, n)
		if pr:
			pr.scale = Vector3(esc * ancho, esc, esc * 0.6)
		var pe := _prop("ropa_wood_clothes_hanger", Vector3(x, 1.86, 0.0), PI * 0.5, 0.9, false, n)
	for k in 2:
		if _rng.randf() < 0.6:
			var zap: String = ["ropa_old_shoes", "ropa_old_dirty_boots", "ropa_kirza_boots", "ropa_worn_rieker_women_leather_sh", "ropa_old_oxford_shoe"][_rng.randi_range(0, 4)]
			_prop(zap, Vector3(-0.5 + k * 1.0, 0.06, -0.1), _rng.randf_range(-0.3, 0.3), 1.0, false, n)
	var arriba: String = ["ropa_bowler_hat", "obj_top_hat_2", "ropa_sunday_hat", "ropa_frosted_sheets"][_rng.randi_range(0, 3)]
	if _props_info.has(arriba):
		var ta := _prop_size(arriba)
		_prop(arriba, Vector3(_rng.randf_range(-0.4, 0.4), 2.165, -0.09), _rng.randf() * TAU, minf(1.0, 0.45 / maxf(ta.x, ta.z)), false, n)

func wardrobe_near(p: Vector3, dist := 1.6) -> Dictionary:
	for wd in wardrobes:
		if absf(p.y - wd.pos.y) < 1.5 and Vector2(p.x - wd.pos.x, p.z - wd.pos.z).length() < dist:
			return wd
	return {}

func _lamp(pos: Vector3) -> void:
	var id := room_at(pos)
	var top := pos.y + (WALL_H if level_of(pos.y) < 2 else 3.3)
	var n := Node3D.new()
	n.position = Vector3(pos.x, top, pos.z)
	add_child(n)
	var bm := _plain(Color(1, 0.9, 0.7), 0.4)
	bm.emission_enabled = true
	bm.emission = Color(1, 0.7, 0.4)
	bm.emission_energy_multiplier = 0.0
	var sotano := level_of(pos.y + 0.3) < 0
	var real: Node3D = null
	if sotano:
		# en el sótano: farol de aceite colgado de una cadena
		box(Vector3(0.02, 1.0, 0.02), Vector3(0, -0.5, 0), _mat.hierro, false, n, false)
		real = _prop("wooden_lantern_01", Vector3(0, -1.5, 0), 0.0, 1.0, false, n)
		if real:
			real.set_meta("dyn", true)
		var llama := cyl(0.012, 0.02, 0.06, Vector3(0, -1.25, 0), bm, n, 5)
		llama.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	else:
		real = _prop("pian_medieval_chandelier", Vector3(0, -1.75, 0), 0.0, 1.25, false, n)
	if sotano:
		pass
	elif real:
		real.set_meta("dyn", true)
		for mi in real.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		box(Vector3(0.025, 0.7, 0.025), Vector3(0, -0.35, 0), _mat.metal, false, n, false)
		cyl(0.3, 0.42, 0.05, Vector3(0, -0.025, 0), _mat.moldura, n, 20)
		for k in 8:
			var a := TAU * k / 8.0
			var fl := cyl(0.006, 0.016, 0.06, Vector3(cos(a) * 0.46, -0.98, sin(a) * 0.46), bm, n, 5)
			fl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	else:
		box(Vector3(0.03, 0.8, 0.03), Vector3(0, -0.4, 0), _mat.metal, false, n)
		for k in 6:
			var a := TAU * k / 6.0
			var cc := cyl(0.03, 0.03, 0.14, Vector3(cos(a) * 0.45, -0.85, sin(a) * 0.45), bm, n, 6)
			cc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var light := OmniLight3D.new()
	light.position.y = -1.15
	light.light_color = Color(1.0, 0.8, 0.56)
	var r: Rect2 = rooms[id].rect if id >= 0 else Rect2(pos.x - 6, pos.z - 6, 12, 12)
	light.omni_range = clampf(maxf(r.size.x, r.size.y) * 0.8, 8.0, 18.0)
	light.omni_attenuation = 1.7
	light.light_energy = 2.6
	light.visible = false
	n.add_child(light)
	var l := {"node": n, "light": light, "bulb": bm, "pos": pos, "room": id, "on": false, "broken": false, "base": 2.4, "flicker": 0.0}
	lamps.append(l)
	if id >= 0:
		rooms[id]["lamps"] = rooms[id].get("lamps", []) + [l]

func lamp_near(p: Vector3, dist := 2.2) -> Dictionary:
	for l in lamps:
		if absf(p.y - l.pos.y) < 1.5 and Vector2(p.x - l.pos.x, p.z - l.pos.z).length() < dist:
			return l
	return {}

func set_lamp(l: Dictionary, on: bool) -> void:
	if l.is_empty() or l.broken:
		return
	l.on = on
	l.light.visible = on
	l.bulb.emission_energy_multiplier = 3.0 if on else 0.0

func break_lamp(l: Dictionary) -> void:
	set_lamp(l, false)
	l.broken = true

func flicker_lamp(l: Dictionary, sec: float) -> void:
	if l.on and not l.broken:
		l.flicker = sec

func is_lit(p: Vector3) -> bool:
	var id := room_at(p)
	if id < 0:
		return false
	for l in rooms[id].get("lamps", []):
		if l.on and not l.broken:
			return true
	return false

func _fireplace(pos: Vector3) -> void:
	var sw := _snap_to_wall(pos, 0.45)
	var fpos: Vector3 = sw[0]
	var back: Vector3 = sw[1]
	var n := Node3D.new()
	n.position = fpos
	n.rotation.y = atan2(-back.x, -back.z)
	add_child(n)
	chimeneas.append({"pos": fpos, "back": back})
	var real := _prop("pian_victorian_fire_place__free", Vector3(0, 0, -0.1), 0.0, 1.1, true, n)
	_tenir(real, Color(0.72, 0.66, 0.62))
	if real == null:
		box(Vector3(2.2, 1.4, 0.7), Vector3(0, 0.7, 0), _mat.marmol, true, n)
		box(Vector3(1.2, 0.9, 0.72), Vector3(0, 0.5, 0.02), _mat.oscuro, false, n)
		box(Vector3(2.5, 0.12, 0.85), Vector3(0, 1.45, 0.05), _mat.marmol, false, n)
	# retrato grande sobre la chimenea
	if _prop("fancy_picture_frame_02", Vector3(0, 2.35, -0.19), 0.0, 1.7, false, n) == null:
		box(Vector3(1.0, 1.2, 0.06), Vector3(0, 2.3, -0.3), _mat.oro, false, n)
	for k in 3:
		var lg := cyl(0.055, 0.06, 0.55, Vector3(-0.08 + k * 0.08, 0.1 + (0.07 if k == 1 else 0.0), 0.12), _mat.corteza, n, 8)
		lg.rotation = Vector3(0, 0.3 * (k - 1), PI * 0.5)
	box(Vector3(0.6, 0.03, 0.3), Vector3(0, 0.05, 0.12), _mat.fuego, false, n, false)
	n.add_child(_llamas())
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.45, 0.15)
	l.omni_range = 8.0
	l.light_energy = 1.3
	l.position = Vector3(0, 0.6, 0.9)
	l.set_meta("e", 1.3)
	n.add_child(l)
	fires.append(l)

## Llamas de chimenea con partículas aditivas.
func _llamas() -> CPUParticles3D:
	var ps := CPUParticles3D.new()
	ps.amount = 70
	ps.lifetime = 0.7
	ps.position = Vector3(0, 0.14, 0.12)
	ps.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ps.emission_box_extents = Vector3(0.24, 0.02, 0.08)
	ps.direction = Vector3(0, 1, 0)
	ps.spread = 12.0
	ps.gravity = Vector3(0, 0.6, 0)
	ps.initial_velocity_min = 0.25
	ps.initial_velocity_max = 0.55
	ps.scale_amount_min = 0.6
	ps.scale_amount_max = 1.2
	var cv := Curve.new()
	cv.add_point(Vector2(0, 0.5)); cv.add_point(Vector2(0.3, 1.0)); cv.add_point(Vector2(1, 0.0))
	ps.scale_amount_curve = cv
	var gr := Gradient.new()
	gr.set_color(0, Color(1.0, 0.85, 0.4, 1.0))
	gr.set_color(1, Color(0.8, 0.15, 0.02, 0.0))
	ps.color_ramp = gr
	var qm := QuadMesh.new()
	qm.size = Vector2(0.16, 0.22)
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	fm.vertex_color_use_as_albedo = true
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	var tex := GradientTexture2D.new()
	var g2 := Gradient.new()
	g2.set_color(0, Color(1, 1, 1, 1)); g2.set_color(1, Color(1, 1, 1, 0))
	tex.gradient = g2
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.6); tex.fill_to = Vector2(0.5, 0.05)
	fm.albedo_texture = tex
	qm.material = fm
	ps.mesh = qm
	ps.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return ps

func _salt_circle(pos: Vector3) -> void:
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.9
	tm.outer_radius = 2.05
	ring.mesh = tm
	ring.material_override = _mat.sal
	ring.scale = Vector3(1, 0.08, 1)
	ring.position = pos + Vector3(0, 0.02, 0)
	add_child(ring)
	for i in 5:
		var line := box(Vector3(0.05, 0.01, 3.6), pos + Vector3(0, 0.02, 0), _mat.sal, false, self, false)
		line.rotation.y = TAU * i / 5.0
	for i in 6:
		var a := TAU * i / 6.0
		var cp := pos + Vector3(cos(a) * 2.4, 0, sin(a) * 2.4)
		cyl(0.04, 0.05, 0.3, cp + Vector3(0, 0.15, 0), _mat.moldura, self, 6)
		cyl(0.0, 0.025, 0.07, cp + Vector3(0, 0.34, 0), _mat.fuego, self, 6)
	var l := OmniLight3D.new()
	l.position = pos + Vector3(0, 0.6, 0)
	l.light_color = Color(1, 0.5, 0.25)
	l.omni_range = 7.0
	l.light_energy = 1.0
	l.set_meta("e", 1.0)
	add_child(l)
	fires.append(l)
	box(Vector3(1.2, 0.5, 2.2), pos + Vector3(0, 0.25, -6.0), _mat.metal)
	box(Vector3(1.1, 0.12, 2.0), pos + Vector3(0, 0.56, -6.0), _mat.sabana, false)

## Fonógrafo de bocina sobre un aparador (hacia 1900): es la «radio» que se enciende sola.
func _fonografo(pos: Vector3) -> void:
	var n := Node3D.new()
	n.position = pos
	add_child(n)
	var mueble := _prop("painted_wooden_cabinet", Vector3.ZERO, 0.0, 0.85, true, n)
	_tenir(mueble, Color(0.42, 0.3, 0.22))
	var top := 1.0 if mueble else 0.8
	if mueble == null:
		box(Vector3(1.0, 0.8, 0.55), Vector3(0, 0.4, 0), _mat.madera, true, n)
	box(Vector3(0.34, 0.16, 0.26), Vector3(0, top + 0.08, 0), _mat.madera, false, n)
	cyl(0.12, 0.12, 0.012, Vector3(0, top + 0.166, 0), _mat.oscuro, n, 24)
	box(Vector3(0.03, 0.03, 0.2), Vector3(0.1, top + 0.2, -0.05), _mat.oro, false, n)
	var laton := _plain(Color(0.5, 0.36, 0.17), 0.45, 0.9)
	var horn := cyl(0.3, 0.025, 0.62, Vector3.ZERO, laton, n, 24)
	horn.position = Vector3(0.12, top + 0.48, 0.12)
	horn.rotation = Vector3(0.75, 0.0, -0.55)
	var aro := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.28
	tm.outer_radius = 0.31
	aro.mesh = tm
	aro.material_override = laton
	horn.add_child(aro)
	aro.position.y = 0.31

## Piano de cola real con su banqueta (el teclado mira al sur) y partituras por el suelo.
func _piano(pos: Vector3) -> void:
	if _prop("pian_old_wooden_grand_piano", pos, 0.0, 1.05) == null:
		box(Vector3(1.5, 1.0, 2.0), pos + Vector3(0, 0.5, 0), _mat.oscuro)
		return
	_prop("pian_piano_stool_3d_scan", pos + Vector3(0.1, 0, 1.55), 0.3, 0.9)
	_prop("pian_candelabra", pos + Vector3(-0.45, 1.05, -0.3), 0.0, 0.3, false)

func _pickup(pos: Vector3, kind: String) -> void:
	var n := Node3D.new()
	n.set_meta("dyn", true)
	n.position = pos
	add_child(n)
	var alto := 0.8
	if _prop("side_table_01", Vector3.ZERO, _rng.randf() * TAU, 1.0, true, n) != null:
		alto = 0.551
	else:
		box(Vector3(0.6, 0.8, 0.45), Vector3(0, 0.4, 0), _mat.madera, true, n)
	var mi: MeshInstance3D
	if kind == "pila":
		# pila de la linterna del jugador: cuerpo negro con etiqueta verde apagada y polo de cobre
		var m := _plain(Color(0.06, 0.07, 0.06), 0.35, 0.3)
		m.emission_enabled = true
		m.emission = Color(0.1, 0.35, 0.15)
		m.emission_energy_multiplier = 0.25
		mi = cyl(0.017, 0.017, 0.06, Vector3(0, alto + 0.018, 0), m, n, 12)
		mi.rotation.z = PI * 0.5
		var polo := cyl(0.006, 0.006, 0.006, Vector3(0.033, 0, 0), _mat.oro, mi, 8)
		polo.rotation.z = 0.0
		for k in 2:
			var otra := cyl(0.017, 0.017, 0.06, Vector3(0.05 + k * 0.04, alto + 0.03, 0.06), m, n, 12)
			otra.rotation.x = PI * 0.5 * float(k == 0)
	else:
		# sal gorda en un tarro de cristal con tapa de corcho
		mi = cyl(0.06, 0.06, 0.15, Vector3(0, alto + 0.075, 0), _mat.sal, n, 14)
		cyl(0.065, 0.065, 0.17, Vector3(0, alto + 0.085, 0), _mat.cristal, n, 14)
		cyl(0.045, 0.05, 0.03, Vector3(0, alto + 0.185, 0), _mat.madera_clara, n, 10)
	pickups.append({"node": n, "pos": pos, "kind": kind, "taken": false, "item": mi})

# ---------------- pasos especiales ----------------
func _portals() -> void:
	var links := [
		[["baja", 1.5, 10.5], ["alta", 1.2, 10.8], "subir por la escalera de caracol", "bajar por la escalera de caracol"],
		[["alta", 2.0, 10.0], ["atico", 1.5, 10.5], "subir al mirador de la torre", "bajar de la torre"],
		[["alta", 17.4, 8.5], ["atico", 15.5, 7.5], "subir al ático", "bajar del ático"],
		[["baja", 5.0, 3.2], ["sotano", 13.0, 2.5], "empujar el librero (pasadizo)", "volver por el pasadizo"],
		[["exterior", 30.5, 36.5], ["sotano", 1.5, 6.5], "bajar por el pozo", "subir por la escalera del pozo"],
		[["exterior", 58.0, 47.0], ["sotano", 29.0, 17.0], "bajar al túnel", "subir a la superficie"],
	]
	for l in links:
		var a := cell_to_world(l[0][0], l[0][1], l[0][2])
		var b := cell_to_world(l[1][0], l[1][1], l[1][2])
		var txt: String = l[2]
		var vis: Array[Vector3] = []
		for p in [a, b]:
			if "librero" in txt and p == a:
				vis.append(_librero_secreto(p))
			elif "pasadizo" in txt or "pozo" in txt or "túnel" in txt:
				vis.append(_escalera_mano(p))
			else:
				# una sola escalera de caracol por torre: si ya hay una a menos de 1,6 m, se usa esa
				var hay := false
				for cc in _caracoles:
					if Vector2(cc.x - p.x, cc.z - p.z).length() < 1.6 and absf(cc.y - p.y) < 1.0:
						hay = true
				if not hay:
					_caracol(p)
					_caracoles.append(p)
				vis.append(p)  # el punto de uso sigue siendo el suyo (subir y bajar no se pisan)
		# el punto de uso queda junto a lo que se ve (librero o escalera), un paso por delante de la pared
		var ua: Vector3 = a.lerp(vis[0], 0.7)
		var ub: Vector3 = b.lerp(vis[1], 0.7)
		portals.append({"pos": ua, "to": b, "text": l[2]})
		portals.append({"pos": ub, "to": a, "text": l[3]})

var _caracoles: Array[Vector3] = []
var chimeneas: Array = []

## Escalera de caracol de hierro con peldaños de madera (subidas a la torre y al ático).
func _caracol(p: Vector3) -> void:
	cyl(0.07, 0.09, 3.6, p + Vector3(0, 1.8, 0), _mat.metal, self, 10)
	for k in 12:
		var st := box(Vector3(0.95, 0.05, 0.32), p + Vector3(0, 0.25 + k * 0.3, 0), _mat.madera, false, self)
		st.rotation.y = k * 0.52
		var bal := cyl(0.012, 0.012, 0.9, p + Vector3(cos(-k * 0.52) * 0.9, 0.7 + k * 0.3, sin(-k * 0.52) * 0.9), _mat.metal, self, 5)
		bal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

## Escalera de mano contra la pared (pozo, túnel, salida del pasadizo).
func _escalera_mano(p: Vector3) -> Vector3:
	var sw := _snap_to_wall(p, 0.25)
	var base: Vector3 = sw[0]
	var back: Vector3 = sw[1]
	var lado := Vector3(-back.z, 0, back.x)
	for s in [-0.25, 0.25]:
		box(Vector3(0.06, 3.4, 0.06), base + lado * s + Vector3(0, 1.7, 0), _mat.madera, false, self)
	for k in 10:
		var pel := box(Vector3(0.5, 0.04, 0.04), base + Vector3(0, 0.3 + k * 0.32, 0), _mat.madera, false, self)
		pel.rotation.y = atan2(lado.x, lado.z) + PI * 0.5
	return base

## La estantería que gira: entreabierta, deja ver la oscuridad del pasadizo detrás.
func _librero_secreto(p: Vector3) -> Vector3:
	var sw := _snap_to_wall(p, 0.2)
	var pos: Vector3 = sw[0]
	var back: Vector3 = sw[1]
	var yaw := atan2(-back.x, -back.z)
	box(Vector3(1.2, 2.3, 0.05) if absf(back.z) > 0.5 else Vector3(0.05, 2.3, 1.2), pos + back * 0.16 + Vector3(0, 1.15, 0), _mat.oscuro, false, self, false)
	var lib := _prop("vict_antique_wooden_bookcase___ga", pos - back * 0.05, yaw + 0.35, 0.8, false, self)
	if lib == null:
		box(Vector3(1.4, 2.1, 0.32), pos + Vector3(0, 1.05, 0), _mat.madera, false, self)
	return pos

func portal_near(p: Vector3, dist := 1.7) -> Dictionary:
	for pt in portals:
		if absf(p.y - pt.pos.y) < 1.6 and Vector2(p.x - pt.pos.x, p.z - pt.pos.z).length() < dist:
			return pt
	return {}

# ---------------- decorado victoriano ----------------
func _decorate() -> void:
	var deco := ZarekDecorado.new(self)
	for r in rooms:
		deco.vestir(r)
	for r in rooms:
		var t: String = r.type
		var rect: Rect2 = r.rect
		var y: float = r.y
		var name: String = r.name
		var c := Vector3(rect.get_center().x, y, rect.get_center().y)
		if t in ["jardin", "agua"]:
			continue
		if t in ["tunel", "roca"]:
			_tunnel_props(r)
			continue
		if name == "Salón con chimenea":
			# sala de muestra: alfombra bajo los sofás y retratos; el resto lo pone ZarekDecorado
			_alfombra(Vector3(rect.position.x + 3.5, y, rect.position.y + 3.6), 4.0, 5.2, 0.0)
			_alfombra(Vector3(rect.position.x + 9.2, y, rect.position.y + 2.9), 2.4, 3.2, PI * 0.5)
			_artesonado(r)
			_polvo(r)
			_oclusion(r)
			continue
		if t in ["sala", "dormitorio", "epicentro"] and rect.size.x > 6 and rect.size.y > 6 and not name.begins_with("Vestíbulo"):
			var ax := minf(rect.size.x * 0.55, 6.0)
			var az := minf(rect.size.y * 0.55, 8.0)
			if ax > az:
				_alfombra(c, az, ax, PI * 0.5)
			else:
				_alfombra(c, ax, az, 0.0)
		# acabado común de todas las salas interiores: esquinas en sombra, polvo en el aire y vigas en las grandes
		if t != "jardin" and t != "agua":
			_manchas(r)
		if level_of(y) >= 0 and t != "jardin":
			_oclusion(r)
			_polvo(r, 60 if t in ["pasillo", "servicio"] else 110)
			if t == "sala" and rect.size.x >= 9 and rect.size.y >= 9 and not ("vestíbulo" in name.to_lower()) and level_of(y) < 2:
				_artesonado(r)
		var lname := name.to_lower()
		if name in SALAS_A_MANO:
			pass
		elif "baile" in lname:
			for k in 6:
				_chair_real(c + Vector3((-0.35 + (k % 3) * 0.35) * rect.size.x, 0, (-0.35 + (k / 3) * 0.7) * rect.size.y), _rng.randf() * TAU, "ArmChair_01" if k % 2 == 0 else "Rockingchair_01")
			_prop("vintage_grandfather_clock_01", Vector3(rect.position.x + 0.6, y, rect.position.y + 0.5), 0.0)
			_prop("gothic_statue", Vector3(rect.end.x - 2.0, y, rect.position.y + 2.0), -PI * 0.75, 0.9)
		elif "biblioteca" in lname and name != "Biblioteca":
			_shelves_around(r, 0.6)
		elif "comedor" in lname and name != "Comedor formal":
			if _prop("dining_table", c + Vector3(0, 0, -1.2), PI * 0.5) != null:
				_prop("dining_table", c + Vector3(0, 0, 1.2), PI * 0.5)
				for k in 4:
					_prop("dining_chair_02", c + Vector3(-1.05, 0, -2.4 + k * 1.6), PI * 0.5)
					_prop("dining_chair_02", c + Vector3(1.05, 0, -2.4 + k * 1.6), -PI * 0.5)
				_prop("brass_candleholders", c + Vector3(0, 0.88, 0), PI * 0.5, 0.8, false)
				_prop("GothicCabinet_01", Vector3(rect.position.x + 0.7, y, c.z), PI * 0.5)
			else:
				box(Vector3(2.0, 0.08, 9.0), c + Vector3(0, 0.82, 0), _mat.madera, true)
				box(Vector3(1.6, 0.78, 8.6), c + Vector3(0, 0.39, 0), _mat.madera, false)
		elif lname == "cocina":
			pass  # la monta ZarekDecorado._cocina
		elif t == "dormitorio":
			var cama := "GothicBed_01" if ("padres" in lname or "principal" in lname) else "old_bed_frame"
			var bp := Vector3(rect.position.x + 1.2, y, c.z)
			if _prop(cama, bp, PI * 0.5) != null:
				_prop("ClassicNightstand_01", bp + Vector3(-0.85, 0, -1.4), PI * 0.5)
				_prop("vintage_oil_lamp", bp + Vector3(-0.85, 0.7, -1.4), 0.0, 0.6, false)
				_prop("GothicCommode_01", Vector3(rect.end.x - 0.4, y, c.z + 1.5), -PI * 0.5)
				_prop("ornate_mirror_01", Vector3(rect.end.x - 0.05, y + 1.6, c.z + 1.5), -PI * 0.5, 1.0, false)
				_prop("vintage_suitcase", Vector3(rect.end.x - 1.2, y, rect.position.y + 1.0), 0.3)
			else:
				_bed(Vector3(rect.position.x + 2.4, y, c.z), 0.0)
			_shelves_around(r, 0.12)
		elif "estudio" in lname:
			if _prop("WoodenTable_01", c, 0.0) != null:
				_prop("book_encyclopedia_set_01", c + Vector3(-0.4, 0.55, 0), 0.2, 1.0, false)
				_prop("vintage_oil_lamp", c + Vector3(0.6, 0.55, 0.1), 0.0, 0.6, false)
				_prop("Rockingchair_01", c + Vector3(0, 0, 1.3), PI)
			else:
				box(Vector3(2.2, 0.08, 1.1), c + Vector3(0, 0.8, 0), _mat.madera, true)
			_shelves_around(r, 0.35)
		elif "billar" in lname:
			box(Vector3(2.6, 0.85, 4.6), c + Vector3(0, 0.42, 0), _mat.madera, true)
			box(Vector3(2.3, 0.04, 4.3), c + Vector3(0, 0.87, 0), _mat.tela_verde, false)
		elif t == "sotano" or "ático" in lname:
			_crates(r)
			if "ático" in lname:
				for k in 6:
					var sp := Vector3(_rng.randf_range(rect.position.x + 2, rect.end.x - 2), y, _rng.randf_range(rect.position.y + 2, rect.end.y - 2))
					box(Vector3(0.8, 1.6, 0.8), sp + Vector3(0, 0.8, 0), _mat.sabana, true)
		if t == "sala" and not ("baile" in lname or "comedor" in lname or "biblioteca" in lname or "billar" in lname) and rect.size.x > 7 and rect.size.y > 7 and not (name in SALAS_A_MANO):
			var cc := c + Vector3(0, 0, 1.0)
			if _prop("Sofa_01", cc + Vector3(0, 0, 1.6), PI) != null:
				_prop("ArmChair_01", cc + Vector3(-1.9, 0, 0), PI * 0.5)
				_prop("ArmChair_01", cc + Vector3(1.9, 0, 0), -PI * 0.5)
				_prop("gothic_coffee_table", cc, 0.0, 0.6)
				_prop("chess_set", cc + Vector3(0, 0.34, 0), 0.4, 0.8, false)
				_prop("side_table_01", Vector3(rect.end.x - 0.6, y, rect.position.y + 0.6), 0.0)
				_prop("marble_bust_01", Vector3(rect.end.x - 0.6, y + 0.55, rect.position.y + 0.6), PI * 0.8, 1.0, false)
		if t in ["sala", "dormitorio", "pasillo"] and level_of(y) >= 0 and not (name in SALAS_A_MANO):
			_portraits(r)
		if t in ["sala", "dormitorio"] and rect.size.x > 6 and not ("baile" in lname) and not ("vestíbulo" in lname) and not (name in SALAS_A_MANO):
			for k in 2:
				var sp := Vector3(_rng.randf_range(rect.position.x + 2, rect.end.x - 2), y, _rng.randf_range(rect.position.y + 2, rect.end.y - 2))
				if door_near(sp, 3.6).is_empty() and portal_near(sp, 2.5).is_empty() and not _sobre_escalera(sp, 1.2) and sp.distance_to(cell_to_world("baja", 9.0, 11.2)) > 3.0:
					var cubierto := _prop(["ArmChair_01", "Sofa_01", "GothicCommode_01"][_rng.randi_range(0, 2)], sp, _rng.randf() * TAU)
					if cubierto:
						# sábana polvorienta encima del mueble
						for mi in cubierto.find_children("*", "MeshInstance3D", true, false):
							(mi as MeshInstance3D).material_override = _mat.sabana
		# aplique tenue en salas sin lámpara (nunca negro total)
		if not r.has("lamps"):
			var lp := OmniLight3D.new()
			lp.light_color = Color(1.0, 0.6, 0.32)
			lp.omni_range = clampf(maxf(rect.size.x, rect.size.y) * 0.65, 6.0, 12.0)
			lp.light_energy = 0.6 if t != "sotano" else 0.4
			lp.position = Vector3(rect.position.x + 0.5, y + 2.4, c.z)
			_house.add_child(lp)
			cyl(0.06, 0.1, 0.3, lp.position, _mat.ventana_luz, null, 8)

# ---------------- muebles reales (Poly Haven, CC0) ----------------
var _props := {}
var _props_info := {}
## Coloca un mueble de res://zarek/muebles/<nombre>.glb (origen en la base, frente hacia +Z).
## Distancia de dibujo de un objeto según su tamaño: una taza no se ve a 20 m, un armario sí.
func _alcance_prop(nombre: String, escala: float) -> float:
	if not _props_info.has(nombre):
		return 30.0
	var t: Array = _props_info[nombre].tam
	var lado := maxf(float(t[0]), maxf(float(t[1]), float(t[2]))) * escala
	if lado < 0.35:
		return 9.0
	if lado < 0.9:
		return 16.0
	if lado < 2.0:
		return 28.0
	return 60.0

## Oclusores: cada muro, suelo y techo macizo tapa lo que hay detrás, así desde fuera no se dibujan las
## habitaciones y desde una habitación no se dibuja el resto de la casa.
func _oclusores() -> void:
	var n := 0
	for c in _house.find_children("*", "CollisionShape3D", true, false):
		var cs := c as CollisionShape3D
		if not (cs.shape is BoxShape3D) or cs.disabled:
			continue
		var cuerpo := cs.get_parent()
		if not (cuerpo is StaticBody3D) or _is_dyn(cuerpo):
			continue
		var sz: Vector3 = (cs.shape as BoxShape3D).size
		var g: Vector3 = cs.global_transform.basis.get_scale()
		sz = sz * g.abs()
		var dims := [sz.x, sz.y, sz.z]
		dims.sort()
		if dims[0] > 0.7 or dims[1] < 1.6 or dims[2] < 1.6:
			continue
		var oc := OccluderInstance3D.new()
		var bo := BoxOccluder3D.new()
		bo.size = (cs.shape as BoxShape3D).size * 0.97
		oc.occluder = bo
		cs.add_child(oc)
		n += 1
	print("ZAREK oclusores: ", n)

func _prop(nombre: String, p: Vector3, yaw := 0.0, escala := 1.0, choca := true, parent: Node3D = null) -> Node3D:
	_load_props_info()
	var path := "res://zarek/muebles/%s.glb" % nombre
	if not ResourceLoader.exists(path):
		path = "res://zarek/objetos/%s.glb" % nombre
	if not _props.has(nombre):
		_props[nombre] = load(path) if ResourceLoader.exists(path) else null
	var ps: PackedScene = _props[nombre]
	if ps == null:
		return null
	# nada que choque puede quedar sobre una escalera o su rellano (bloquearía el paso)
	if choca and _huella_en_escalera(p, _prop_size(nombre) * escala, yaw):
		return null
	# botellas: de vidrio de verdad, con física y rompibles (una fila de botellas da varias sueltas)
	if parent == null and BOTELLAS.has(nombre):
		var cuantas: int = BOTELLAS[nombre]
		var primera: Node3D = null
		for k in cuantas:
			var b := ZarekBotella.azar(_rng)
			var off := Vector3((k - (cuantas - 1) * 0.5) * 0.105, 0, 0).rotated(Vector3.UP, yaw)
			b.position = p + off + Vector3(0, 0.002, 0)
			b.rotation.y = _rng.randf() * TAU
			_house.add_child(b)
			b.sleeping = true
			if primera == null:
				primera = b
		return primera
	var n: Node3D = ps.instantiate()
	if GIRO.has(nombre):
		var w := Node3D.new()
		n.rotation.y = GIRO[nombre]
		w.add_child(n)
		n = w
	n.position = p
	n.rotation.y = yaw
	n.scale = Vector3.ONE * escala
	# objetos sueltos con física: se empujan, se vuelcan y suenan
	var masa := _masa_fisica(nombre) if parent == null else 0.0
	if masa > 0.0 and _props_info.has(nombre):
		var rb := ZarekObjetoFisico.new()
		rb.mass = maxf(0.1, masa * escala)
		for clave in ["vase", "porcelain", "teapot", "tea_set", "cup", "plate", "jar", "perfume", "jug", "bowl", "ceramic", "goblet", "wine_glass", "clock"]:
			if nombre.contains(clave) and not nombre.contains("brass") and not nombre.contains("metal") and not nombre.contains("wooden"):
				rb.rompible = true
		if _es_metal(nombre):
			rb.sonido = "tintineo"
		rb.position = p
		rb.rotation.y = yaw
		n.position = Vector3.ZERO
		n.rotation = Vector3.ZERO
		rb.add_child(n)
		var tt: Array = _props_info[nombre].tam
		var rcs := CollisionShape3D.new()
		var rbs := BoxShape3D.new()
		rbs.size = Vector3(maxf(float(tt[0]), 0.04), maxf(float(tt[1]), 0.03), maxf(float(tt[2]), 0.04)) * escala
		rcs.shape = rbs
		rcs.position.y = rbs.size.y * 0.5
		rb.add_child(rcs)
		if lvl_y(level_of(p.y + 0.3)) + 0.3 > p.y:
			rb.add_child(_sombra(Vector2(float(tt[0]), float(tt[2])) * 1.35 * escala))
		_house.add_child(rb)
		rb.sleeping = true
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if rb.mass > 2.0 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			(mi as MeshInstance3D).visibility_range_end = _alcance_prop(nombre, escala)
			(mi as MeshInstance3D).visibility_range_end_margin = 2.0
		return rb
	(parent if parent else _house).add_child(n)
	var alcance := _alcance_prop(nombre, escala)
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if alcance > 20.0 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		(mi as MeshInstance3D).visibility_range_end = alcance
		(mi as MeshInstance3D).visibility_range_end_margin = 2.0
	if choca and _props_info.has(nombre) and lvl_y(level_of(p.y + 0.3)) + 0.3 > p.y:
		var tt: Array = _props_info[nombre].tam
		n.add_child(_sombra(Vector2(float(tt[0]), float(tt[2])) * 1.35))
	if choca and _props_info.has(nombre):
		var t: Array = _props_info[nombre].tam
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(float(t[0]), float(t[1]), float(t[2])) * escala
		cs.shape = bs
		cs.position.y = float(t[1]) * escala * 0.5
		sb.add_child(cs)
		n.add_child(sb)
	return n

func _load_props_info() -> void:
	if not _props_info.is_empty():
		return
	for f in ["res://zarek/muebles/muebles.json", "res://zarek/objetos/objetos.json"]:
		if FileAccess.file_exists(f):
			var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(f))
			_props_info.merge(d)

var _stairs_cache: Array[Rect2] = []
func _sobre_escalera(p: Vector3, radio := 0.5) -> bool:
	if _stairs_cache.is_empty():
		_stairs_cache = stair_rects()
	for sr in _stairs_cache:
		if sr.grow(radio).has_point(Vector2(p.x, p.z)):
			return true
	return false

## ¿La huella rectangular del mueble (girado) pisa una escalera o su rellano?
func _huella_en_escalera(p: Vector3, t: Vector3, yaw: float) -> bool:
	if _stairs_cache.is_empty():
		_stairs_cache = stair_rects()
	var c := absf(cos(yaw))
	var sn := absf(sin(yaw))
	var ex := t.x * c + t.z * sn
	var ez := t.x * sn + t.z * c
	var h := Rect2(p.x - ex * 0.5, p.z - ez * 0.5, ex, ez)
	for sr in _stairs_cache:
		if sr.intersects(h):
			return true
	return false

func _prop_size(nombre: String) -> Vector3:
	_load_props_info()
	if not _props_info.has(nombre):
		return Vector3.ONE
	var t: Array = _props_info[nombre].tam
	return Vector3(float(t[0]), float(t[1]), float(t[2]))

func _chair_real(p: Vector3, yaw: float, tipo := "") -> void:
	var opciones := ["dining_chair_02", "ArmChair_01", "Rockingchair_01"]
	if tipo == "":
		tipo = opciones[_rng.randi_range(0, opciones.size() - 1)]
	if _prop(tipo, p, yaw) == null:
		_chair(p, yaw)

func _chair(p: Vector3, yaw: float) -> void:
	var n := Node3D.new()
	n.position = p
	n.rotation.y = yaw
	_house.add_child(n)
	box(Vector3(0.5, 0.07, 0.5), Vector3(0, 0.48, 0), _mat.tela_roja, false, n)
	box(Vector3(0.5, 0.7, 0.06), Vector3(0, 0.85, 0.22), _mat.madera, false, n)
	for lx in [-0.2, 0.2]:
		for lz in [-0.2, 0.2]:
			box(Vector3(0.05, 0.46, 0.05), Vector3(lx, 0.23, lz), _mat.madera, false, n)

func _bed(p: Vector3, yaw: float) -> void:
	var n := Node3D.new()
	n.position = p
	n.rotation.y = yaw
	_house.add_child(n)
	box(Vector3(2.2, 0.55, 2.0), Vector3(0, 0.3, 0), _mat.madera, true, n)
	box(Vector3(2.1, 0.2, 1.9), Vector3(0, 0.65, 0), _mat.sabana, false, n)
	box(Vector3(0.12, 1.8, 2.0), Vector3(-1.1, 0.9, 0), _mat.madera, false, n)
	for cz in [-0.95, 0.95]:
		cyl(0.05, 0.05, 2.4, Vector3(1.05, 1.2, cz), _mat.madera, n, 6)
		cyl(0.05, 0.05, 2.4, Vector3(-1.05, 1.2, cz), _mat.madera, n, 6)
	box(Vector3(2.2, 0.06, 2.0), Vector3(0, 2.4, 0), _mat.tela_roja, false, n)

func _shelves_around(r: Dictionary, density: float) -> void:
	var rect: Rect2 = r.rect
	var y: float = r.y
	for side in 4:
		var along := rect.size.x if side < 2 else rect.size.y
		var k := 1.5
		while k < along - 1.5:
			if _rng.randf() < density:
				var p: Vector3
				var yaw := 0.0
				match side:
					0:
						p = Vector3(rect.position.x + k, y, rect.position.y + 0.4)
						yaw = 0.0
					1:
						p = Vector3(rect.position.x + k, y, rect.end.y - 0.4)
						yaw = PI
					2:
						p = Vector3(rect.position.x + 0.4, y, rect.position.y + k)
						yaw = -PI * 0.5
					_:
						p = Vector3(rect.end.x - 0.4, y, rect.position.y + k)
						yaw = PI * 0.5
				if door_near(p, 2.2).is_empty() and wardrobe_near(p, 2.0).is_empty() and portal_near(p, 2.2).is_empty() and lamp_near(p, 0.1).is_empty():
					_bookshelf(p, yaw)
			k += 1.8

func _bookshelf(p: Vector3, yaw: float) -> void:
	if _prop("wooden_bookshelf_worn", p - Vector3(0, 0, 0), yaw) != null:
		return
	var n := Node3D.new()
	n.position = p
	n.rotation.y = yaw
	_house.add_child(n)
	box(Vector3(1.6, 2.6, 0.45), Vector3(0, 1.3, 0), _mat.madera, true, n)
	var colors := [Color(0.4, 0.1, 0.08), Color(0.12, 0.2, 0.12), Color(0.15, 0.12, 0.3), Color(0.45, 0.32, 0.15), Color(0.2, 0.1, 0.06)]
	for sy in 5:
		var x := -0.7
		while x < 0.66:
			var bw := _rng.randf_range(0.08, 0.16)
			var bh := _rng.randf_range(0.26, 0.4)
			var col: Color = colors[_rng.randi_range(0, colors.size() - 1)]
			box(Vector3(bw, bh, 0.3), Vector3(x + bw * 0.5, 0.25 + sy * 0.5 + bh * 0.5, 0.12), _book_mat(col), false, n, false)
			x += bw + 0.01

var _books := {}
func _book_mat(c: Color) -> Material:
	var k := c.to_html()
	if not _books.has(k):
		_books[k] = _plain(c, 0.85)
	return _books[k]

func _portraits(r: Dictionary) -> void:
	var rect: Rect2 = r.rect
	var y: float = r.y
	var face := _plain(Color(0.16, 0.12, 0.1), 0.9)
	for k in 3:
		var side := _rng.randi_range(0, 3)
		var t := _rng.randf_range(0.2, 0.8)
		var p: Vector3
		var size := Vector3(1.0, 1.3, 0.06)
		match side:
			0: p = Vector3(rect.position.x + rect.size.x * t, y + 2.3, rect.position.y + 0.27)
			1: p = Vector3(rect.position.x + rect.size.x * t, y + 2.3, rect.end.y - 0.27)
			2:
				p = Vector3(rect.position.x + 0.27, y + 2.3, rect.position.y + rect.size.y * t)
				size = Vector3(0.06, 1.3, 1.0)
			_:
				p = Vector3(rect.end.x - 0.27, y + 2.3, rect.position.y + rect.size.y * t)
				size = Vector3(0.06, 1.3, 1.0)
		if not door_near(p - Vector3(0, 2.3, 0), 1.9).is_empty() or ventana_cerca(p - Vector3(0, 2.3, 0), 1.3):
			continue
		var yaw: float = [0.0, PI, PI * 0.5, -PI * 0.5][side]
		var marcos := ["fancy_picture_frame_01", "fancy_picture_frame_02", "fancy_picture_frame_01", "ornate_mirror_01"]
		var mk: String = marcos[_rng.randi_range(0, marcos.size() - 1)]
		var off := Vector3.ZERO
		if _prop(mk, p - Vector3(0, 0.5, 0) + off, yaw, 1.6 if mk != "ornate_mirror_01" else 1.3, false) == null:
			box(size, p, _mat.oro, false, null, false)
			var inner := size * (Vector3(0.82, 0.85, 1.4) if size.x > 0.5 else Vector3(1.4, 0.85, 0.82))
			box(inner, p, face, false, null, false)

var _tex_mancha: Array[Texture2D] = []
## Manchas de humedad con cerco, moho y suciedad: texturas propias que se multiplican sobre paredes, techo y suelo.
func _mancha_tex(tipo: int) -> Texture2D:
	if _tex_mancha.is_empty():
		for k in 3:
			var img := Image.create(128, 128, false, Image.FORMAT_RGB8)
			var nz := FastNoiseLite.new()
			nz.seed = 70 + k
			nz.frequency = 0.035
			nz.fractal_octaves = 5
			var fino := FastNoiseLite.new()
			fino.seed = 90 + k
			fino.frequency = 0.15
			var tinte: Color = [Color(0.62, 0.52, 0.36), Color(0.42, 0.46, 0.36), Color(0.5, 0.45, 0.4)][k]
			for y in 128:
				for x in 128:
					var d := Vector2(x - 64, (y - 64) * (1.4 if k == 0 else 1.0)).length() / 64.0
					var forma := nz.get_noise_2d(x, y) * 0.55 + 0.62 - d
					var m := clampf(forma * 4.0, 0.0, 1.0)
					var cerco := clampf(1.0 - absf(forma) * 18.0, 0.0, 1.0) * 0.6 if k == 0 else 0.0
					var v := m * (0.55 + fino.get_noise_2d(x, y) * 0.35) + cerco
					img.set_pixel(x, y, Color(1, 1, 1).lerp(tinte, clampf(v, 0.0, 1.0)))
			img.generate_mipmaps()
			_tex_mancha.append(ImageTexture.create_from_image(img))
	return _tex_mancha[tipo]

var _mat_suciedad: Dictionary = {}
func _mancha(pos: Vector3, normal: Vector3, tam: Vector2, tipo: int) -> void:
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = tam
	mi.mesh = qm
	if not _mat_suciedad.has(tipo):
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_MUL
		mat.albedo_texture = _mancha_tex(tipo)
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mat_suciedad[tipo] = mat
	mi.material_override = _mat_suciedad[tipo]
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_house.add_child(mi)
	mi.position = pos + normal * 0.012
	if absf(normal.y) > 0.9:
		mi.rotation = Vector3(-PI * 0.5 * signf(normal.y), _rng.randf() * TAU, 0)
	else:
		mi.look_at_from_position(mi.position, mi.position - normal, Vector3.UP)
		mi.rotate_object_local(Vector3.FORWARD, _rng.randf_range(-0.3, 0.3))

## Humedad que baja del techo por las paredes, moho en las esquinas y suciedad en el suelo.
func _manchas(r: Dictionary) -> void:
	var rect: Rect2 = r.rect
	var y := float(r.y)
	var alto := WALL_H if level_of(y + 0.3) < 2 else 3.3
	var caras := [[Vector3(rect.position.x + 0.14, 0, 0), Vector3(1, 0, 0), true], [Vector3(rect.end.x - 0.14, 0, 0), Vector3(-1, 0, 0), true],
		[Vector3(0, 0, rect.position.y + 0.14), Vector3(0, 0, 1), false], [Vector3(0, 0, rect.end.y - 0.14), Vector3(0, 0, -1), false]]
	var n := clampi(int(rect.size.x * rect.size.y / 18.0), 2, 9)
	for k in n:
		var c: Array = caras[_rng.randi_range(0, 3)]
		var base: Vector3 = c[0]
		var t := _rng.randf()
		var p := Vector3(base.x if c[2] else lerpf(rect.position.x + 0.8, rect.end.x - 0.8, t), 0, base.z if not c[2] else lerpf(rect.position.y + 0.8, rect.end.y - 0.8, t))
		var arriba := _rng.randf() < 0.65
		var h := _rng.randf_range(0.7, 1.6)
		p.y = y + (alto - h * 0.5 - 0.15 if arriba else h * 0.5 + 0.05)
		if not door_near(Vector3(p.x, y, p.z), 1.2).is_empty() or ventana_cerca(Vector3(p.x, y, p.z), 1.1):
			continue
		_mancha(p, c[1], Vector2(_rng.randf_range(0.8, 2.0), h), 0 if arriba else 1)
	# techo y suelo
	for k in clampi(n / 2, 1, 4):
		var p := Vector3(_rng.randf_range(rect.position.x + 1, rect.end.x - 1), y + alto - 0.125, _rng.randf_range(rect.position.y + 1, rect.end.y - 1))
		var sz := _rng.randf_range(0.9, 2.4)
		_mancha(p, Vector3.DOWN, Vector2(sz, sz * _rng.randf_range(0.6, 1.0)), 0)
	for k in clampi(n / 2, 1, 4):
		var p := Vector3(_rng.randf_range(rect.position.x + 0.6, rect.end.x - 0.6), y + 0.004, _rng.randf_range(rect.position.y + 0.6, rect.end.y - 0.6))
		var sz := _rng.randf_range(0.8, 2.0)
		_mancha(p, Vector3.UP, Vector2(sz, sz), 2)

## Alfombra persa (plano con textura) de sx × sz metros.
func _alfombra(c: Vector3, sx: float, sz: float, yaw: float) -> void:
	var ex := sz if absf(sin(yaw)) > 0.7 else sx
	var ez := sx if absf(sin(yaw)) > 0.7 else sz
	var huella := Rect2(c.x - ex * 0.5, c.z - ez * 0.5, ex, ez)
	for h in _hole.get(level_of(c.y + 0.3), []):
		if (h as Rect2).grow(0.3).intersects(huella):
			# se recorta la alfombra al lado más grande que queda libre del hueco
			var hr: Rect2 = h
			var trozos := [Rect2(huella.position, Vector2(hr.position.x - 0.3 - huella.position.x, huella.size.y)),
				Rect2(Vector2(hr.end.x + 0.3, huella.position.y), Vector2(huella.end.x - hr.end.x - 0.3, huella.size.y)),
				Rect2(huella.position, Vector2(huella.size.x, hr.position.y - 0.3 - huella.position.y)),
				Rect2(Vector2(huella.position.x, hr.end.y + 0.3), Vector2(huella.size.x, huella.end.y - hr.end.y - 0.3))]
			var mejor := Rect2()
			for tr in trozos:
				if tr.size.x > 1.0 and tr.size.y > 1.0 and tr.get_area() > mejor.get_area():
					mejor = tr
			if mejor.get_area() < 2.0:
				return
			_alfombra(Vector3(mejor.get_center().x, c.y, mejor.get_center().y), mejor.size.x, mejor.size.y, 0.0)
			return
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(sx, sz)
	mi.mesh = pm
	mi.material_override = _mat.persa
	mi.position = c + Vector3(0, 0.012, 0)
	mi.rotation.y = yaw
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_house.add_child(mi)

## Techo artesonado: vigas de madera oscura en retícula y rosetón de yeso sobre la araña.
func _artesonado(r: Dictionary) -> void:
	var rect: Rect2 = r.rect
	var top: float = float(r.y) + WALL_H - 0.11
	var nx := int(round(rect.size.x / 2.4))
	var nz := int(round(rect.size.y / 2.4))
	for i in range(1, nx):
		box(Vector3(0.2, 0.2, rect.size.y - 0.3), Vector3(rect.position.x + rect.size.x * i / nx, top - 0.1, rect.get_center().y), _mat.madera, false, null, false)
	for j in range(1, nz):
		box(Vector3(rect.size.x - 0.3, 0.16, 0.16), Vector3(rect.get_center().x, top - 0.08, rect.position.y + rect.size.y * j / nz), _mat.madera, false, null, false)

## Polvo en suspensión que se ve al cruzar la luz.
func _polvo(r: Dictionary, cuanto := 220) -> void:
	var rect: Rect2 = r.rect
	var ps := CPUParticles3D.new()
	ps.amount = cuanto
	ps.lifetime = 14.0
	ps.preprocess = 14.0
	ps.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ps.emission_box_extents = Vector3(rect.size.x * 0.5 - 0.3, 1.5, rect.size.y * 0.5 - 0.3)
	ps.gravity = Vector3(0, -0.004, 0)
	ps.direction = Vector3(1, 0.2, 0.3)
	ps.spread = 180.0
	ps.initial_velocity_min = 0.01
	ps.initial_velocity_max = 0.05
	var qm := QuadMesh.new()
	qm.size = Vector2(0.009, 0.009)
	var pmat := StandardMaterial3D.new()
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	pmat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	pmat.albedo_color = Color(1.0, 0.95, 0.85, 0.3)
	pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pmat.roughness = 1.0
	qm.material = pmat
	ps.mesh = qm
	ps.position = Vector3(rect.get_center().x, float(r.y) + 1.7, rect.get_center().y)
	ps.set_meta("dyn", true)
	_house.add_child(ps)

var _sombra_mat: StandardMaterial3D
## Mancha de sombra suave en el suelo (oclusión de contacto barata, sirve en móvil).
func _sombra(tam: Vector2) -> MeshInstance3D:
	if _sombra_mat == null:
		_sombra_mat = StandardMaterial3D.new()
		_sombra_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_sombra_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_sombra_mat.albedo_color = Color(0, 0, 0, 0.72)
		var tex := GradientTexture2D.new()
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1)); g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.45, Color(1, 1, 1, 0.75))
		tex.gradient = g
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5); tex.fill_to = Vector2(0.5, 0.0)
		_sombra_mat.albedo_texture = tex
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = tam
	mi.mesh = pm
	mi.material_override = _sombra_mat
	mi.position.y = 0.018
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = 14.0
	mi.set_meta("dyn", true)
	return mi

## Oscurece las uniones pared-suelo y pared-techo (las esquinas reciben menos luz en la vida real).
func _oclusion(r: Dictionary) -> void:
	var rect: Rect2 = r.rect
	var y := float(r.y)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1)); g.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0, 0); tex.fill_to = Vector2(0, 1)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0, 0, 0, 0.55)
	mat.albedo_texture = tex
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var lados := [[Vector2(rect.position.x, rect.get_center().y), rect.size.y, -PI * 0.5], [Vector2(rect.end.x, rect.get_center().y), rect.size.y, PI * 0.5],
		[Vector2(rect.get_center().x, rect.position.y), rect.size.x, 0.0], [Vector2(rect.get_center().x, rect.end.y), rect.size.x, PI]]
	for l in lados:
		for alto in [[0.02, 0.7, false], [WALL_H - 0.13, 0.9, true]]:
			var mi := MeshInstance3D.new()
			var pm := PlaneMesh.new()
			pm.size = Vector2(float(l[1]), float(alto[1]))
			pm.flip_faces = alto[2]
			mi.mesh = pm
			mi.material_override = mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var c: Vector2 = l[0]
			var dir := Vector2(0, 1).rotated(-float(l[2]))
			var pos := c + dir * (0.15 + float(alto[1]) * 0.5)
			mi.position = Vector3(pos.x, y + float(alto[0]), pos.y)
			mi.rotation.y = float(l[2])
			_house.add_child(mi)

## Haz de luz de luna que entra por una ventana (solo en las salas de muestra: cada luz cuesta en móvil).
func _luz_luna(p: Vector3, dentro: Vector3) -> void:
	var sl := SpotLight3D.new()
	sl.light_color = Color(0.55, 0.66, 1.0)
	sl.light_energy = 3.0
	sl.spot_range = 10.0
	sl.spot_angle = 24.0
	sl.spot_attenuation = 0.6
	sl.shadow_enabled = true
	_house.add_child(sl)
	sl.look_at_from_position(p - dentro * 1.4 + Vector3(0, 2.75, 0), p + dentro * 2.6, Vector3.UP)

func _tenir(n: Node3D, tinte: Color) -> void:
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

func _crates(r: Dictionary) -> void:
	var rect: Rect2 = r.rect
	var y: float = r.y
	for k in int(rect.size.x * rect.size.y / 45.0):
		var p := Vector3(_rng.randf_range(rect.position.x + 1, rect.end.x - 1), y, _rng.randf_range(rect.position.y + 1, rect.end.y - 1))
		if not door_near(p, 2.5).is_empty() or not portal_near(p, 2.5).is_empty():
			continue
		var en_escalera := false
		for sr in stair_rects():
			if sr.has_point(Vector2(p.x, p.z)):
				en_escalera = true
		if en_escalera:
			continue
		var cosas := ["terr_old_and_dusty_multi_crate_st", "vintage_suitcase", "treasure_chest", "terr_old_and_dusty_multi_crate_st"]
		if "cava" in String(r.name).to_lower():
			cosas = ["terr_old_and_dusty_multi_crate_st"]
		if _prop(cosas[_rng.randi_range(0, cosas.size() - 1)], p, _rng.randf() * TAU) == null:
			var s := _rng.randf_range(0.5, 1.0)
			var b := box(Vector3(s, s, s), p + Vector3(0, s * 0.5, 0), _mat.madera, true)
			b.rotation.y = _rng.randf() * TAU

func _tunnel_props(r: Dictionary) -> void:
	var rect: Rect2 = r.rect
	var y: float = r.y
	var vertical := rect.size.y > rect.size.x
	var n := maxi(1, int(maxf(rect.size.x, rect.size.y) / 6.0))
	for k in n:
		var t := (k + 0.5) / n
		var p := Vector3(rect.position.x + rect.size.x * (0.5 if vertical else t), y, rect.position.y + rect.size.y * (t if vertical else 0.5))
		if vertical:
			box(Vector3(rect.size.x, 0.3, 0.3), p + Vector3(0, 3.7, 0), _mat.madera, false)
		else:
			box(Vector3(0.3, 0.3, rect.size.y), p + Vector3(0, 3.7, 0), _mat.madera, false)
		if k % 2 == 0:
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.55, 0.25)
			l.light_energy = 0.45
			l.omni_range = 7.0
			l.position = p + Vector3(0, 2.5, 0)
			l.set_meta("e", 0.45)
			_house.add_child(l)
			fires.append(l)

# ---------------- unir la geometría estática (menos llamadas de dibujo) ----------------
func _is_dyn(n: Node) -> bool:
	var q := n
	while q and q != self:
		if q.has_meta("dyn"):
			return true
		q = q.get_parent()
	return false

## Materiales iguales creados por separado (p. ej. uno por ventana) se cuentan como uno solo, para que la
## fusión junte sus piezas en una sola llamada de dibujo.
var _canon: Dictionary = {}
func _canon_mat(mat: Material) -> Material:
	if not (mat is StandardMaterial3D):
		return mat
	var m := mat as StandardMaterial3D
	var firma := [m.albedo_color, m.albedo_texture, m.normal_enabled, m.normal_texture, m.normal_scale, m.roughness, m.roughness_texture, m.metallic,
		m.transparency, m.shading_mode, m.blend_mode, m.cull_mode, m.uv1_scale, m.uv1_offset, m.uv1_triplanar, m.uv1_world_triplanar,
		m.emission_enabled, m.emission, m.emission_energy_multiplier, m.vertex_color_use_as_albedo, m.alpha_scissor_threshold,
		m.texture_filter, m.render_priority, m.no_depth_test, m.disable_receive_shadows, m.depth_draw_mode, m.ao_enabled, m.ao_texture,
		m.heightmap_enabled, m.rim_enabled, m.clearcoat_enabled, m.backlight_enabled, m.specular_mode, m.diffuse_mode, m.billboard_mode]
	var h := str(firma).hash()
	if not _canon.has(h):
		_canon[h] = mat
	return _canon[h]

func _merge_static() -> void:
	var groups := {}
	var nodes: Array = []
	# se fusionan todas las piezas hechas por código que no se mueven (muros, molduras, marcos, contraventanas,
	# tablas, telarañas...): por material, planta y celda de 24 m. Los modelos importados no (tienen LOD propio).
	for mi in find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if _is_dyn(m) or m.mesh == null or m.owner != null or m.visibility_range_end > 0.0:
			continue
		if not (m.mesh is PrimitiveMesh or m.mesh is ArrayMesh) or (m.mesh is ArrayMesh and (m.mesh as ArrayMesh).get_blend_shape_count() > 0) or m.skeleton != NodePath("") and m.get_node_or_null(m.skeleton) is Skeleton3D:
			continue
		var movil := false
		var q: Node = m.get_parent()
		while q and q != self:
			if q is RigidBody3D or q is AnimatableBody3D or q is CharacterBody3D or q is VehicleBody3D or q.get_script() != null:
				movil = true
				break
			q = q.get_parent()
		if movil:
			continue
		var gp := m.global_position
		var sup: Array = []
		for si in m.mesh.get_surface_count():
			var mat: Material = m.material_override if m.material_override else m.get_active_material(si)
			if mat == null or (m.mesh is ArrayMesh and (m.mesh as ArrayMesh).surface_get_primitive_type(si) != Mesh.PRIMITIVE_TRIANGLES):
				sup.clear()
				break
			sup.append([si, mat])
		if sup.is_empty():
			continue
		for par in sup:
			var mat: Material = _canon_mat(par[1])
			var key := "%d|%d|%d|%d|%d" % [mat.get_instance_id(), level_of(gp.y + 0.3), int(gp.x / 24.0), int(gp.z / 24.0), m.cast_shadow]
			if not groups.has(key):
				groups[key] = {"mat": mat, "items": [], "shadow": m.cast_shadow}
			groups[key].items.append([m, par[0]])
		nodes.append(m)
	if OS.get_environment("DEBUG_FUSION") != "":
		var pm := {}
		for key in groups:
			var mt: Material = groups[key].mat
			var nm := "%s" % [mt.resource_name if mt.resource_name != "" else (str(mt.albedo_color) if mt is StandardMaterial3D else mt.get_class())]
			pm[nm] = pm.get(nm, 0) + 1
		var kk := pm.keys()
		kk.sort_custom(func(a, b): return pm[a] > pm[b])
		print("FUSION grupos=", groups.size(), " materiales=", pm.size())
		var ids := {}
		var celdas := {}
		for key in groups:
			ids[key.get_slice("|", 0)] = 1
			celdas[key.get_slice("|", 1) + "|" + key.get_slice("|", 2) + "|" + key.get_slice("|", 3) + "|" + key.get_slice("|", 4)] = 1
		print("FUSION ids_material=", ids.size(), " celdas=", celdas.size(), " ", celdas.keys().slice(0, 40))
		for k in kk.slice(0, 25):
			print("FUSION ", k, " ", pm[k])
	for key in groups:
		var g: Dictionary = groups[key]
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for it in g.items:
			st.append_from(it[0].mesh, it[1], it[0].global_transform)
		var am := st.commit()
		var out := MeshInstance3D.new()
		out.mesh = am
		out.material_override = g.mat
		out.cast_shadow = g.shadow
		_house.add_child(out)
	var fusionados := {}
	for m in nodes:
		fusionados[m] = true
	for m in nodes:
		var mi := m as MeshInstance3D
		for c in mi.get_children():
			if fusionados.has(c):
				continue
			if c is Node3D:
				var xf: Transform3D = c.global_transform
				mi.remove_child(c)
				_house.add_child(c)
				c.global_transform = xf
			else:
				mi.remove_child(c)
				_house.add_child(c)
		mi.queue_free()

# ---------------- navegación de Elena ----------------
func bake_nav() -> void:
	var nm := NavigationMesh.new()
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	nm.cell_size = 0.25
	nm.cell_height = 0.25
	nm.agent_height = 1.7
	nm.agent_radius = 0.4
	nm.agent_max_climb = 0.5
	nm.geometry_collision_mask = 1
	nm.agent_max_slope = 45.0
	nm.filter_baking_aabb = AABB(Vector3(house_rect.position.x - 32, lvl_y(-1) - 1.0, house_rect.position.y - 6),
		Vector3(house_rect.size.x + 64, lvl_y(3), house_rect.size.y + 34))
	nav_region.navigation_mesh = nm
	nav_region.bake_finished.connect(func():
		nav_ready = true
		print("ZAREK: navmesh polígonos ", nav_region.navigation_mesh.get_polygon_count()))
	nav_region.bake_navigation_mesh(true)

func path(from: Vector3, to: Vector3) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if not nav_ready:
		out.append(to)
		return out
	var map := get_world_3d().navigation_map
	var pts := NavigationServer3D.map_get_path(map, from, to, true)
	for p in pts:
		out.append(p)
	if out.size() > 0:
		out.remove_at(0)
	return out

func random_floor(far_from := Vector3(-9999, 0, -9999), min_dist := 0.0, exclude_room := -1, level := -99) -> Vector3:
	for i in 300:
		var r: Dictionary = rooms[_rng.randi_range(0, rooms.size() - 1)]
		if r.type in ["jardin", "agua", "roca"] or r.id == exclude_room:
			continue
		if level != -99 and r.level != level:
			continue
		var rect: Rect2 = r.rect
		var p := Vector3(_rng.randf_range(rect.position.x + 1.0, rect.end.x - 1.0), r.y, _rng.randf_range(rect.position.y + 1.0, rect.end.y - 1.0))
		if p.distance_to(far_from) >= min_dist:
			return p
	return front_door + Vector3(0, 0, -4)

func _process(delta: float) -> void:
	if _luz_atico:
		var tt := Time.get_ticks_msec() / 1000.0
		_luz_atico.light_energy = 0.9 + 0.5 * sin(tt * 7.3) * sin(tt * 2.1) + (0.6 if fmod(tt, 9.0) < 0.15 else 0.0)
	for d in doors:
		if absf(d.ang - d.target) > 0.001:
			d.ang = move_toward(d.ang, d.target, delta * float(d.get("speed", 3.0)))
			d.pivot.rotation.y = d.base + d.ang
			if d.has("pivot2"):
				d.pivot2.rotation.y = d.base2 - d.ang
	var t := Time.get_ticks_msec() / 1000.0
	for s in seals:
		if not s.taken:
			s.node.rotation.y = t * 0.8
	for i in fires.size():
		var l: OmniLight3D = fires[i]
		l.light_energy = l.get_meta("e") * (0.8 + 0.2 * sin(t * 11.0 + i * 1.7) * sin(t * 6.3 + i))
	for l in lamps:
		if l.on and not l.broken and l.flicker > 0.0:
			l.flicker -= delta
			l.light.light_energy = l.base * (0.15 if randf() < 0.5 else 1.0)
			if l.flicker <= 0.0:
				l.light.light_energy = l.base
	if swing:
		swing.rotation.x = sin(t * 1.3) * 0.35
	if has_meta("car"):
		var car: Node3D = get_meta("car")
		car.get_node("intermitentes").visible = fmod(t, 1.0) < 0.5
