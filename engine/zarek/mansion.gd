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
var wardrobes: Array = []  # {pos, inside, yaw, tipo ('' armario, 'cama')}
var cristales: Array = []  # cristales rotos en el suelo (crujen al pisar)
var charcos: Array = []  # charcos (chapotean)
var seals: Array = []      # {node, pos, taken}
## Semilla de la partida: 0 = sitios fijos del plano (pruebas); otra = los objetos de la trampa, las pilas,
## las bengalas y los tablones cambian de sitio en cada partida.
var partida_seed := 0
var _sello_marcas: Array[Vector3] = []
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
const SALAS_A_MANO := ["Salón con chimenea", "Comedor formal", "Cocina", "Vestíbulo y gran escalera", "Biblioteca", "Estudio del padre", "Dormitorio de los padres", "Cuarto de Damián", "Cuarto de niños", "Sala de música", "Salón de baile",
	"Sala de fumar y billar", "Sala de las mañanas", "Tocador de la madre", "Cuarto del hermano", "Baño", "Cuarto de huéspedes azul", "Sala de costura", "Cuarto de la institutriz", "Galería de retratos", "Cuarto de huéspedes", "Cuarto de lectura", "Pasillo principal", "Pasillo",
	"Despensa", "Antecocina", "Guardarropa", "Cuarto de servicio", "Cuarto de plancha",
	"Pasillo del sótano", "Galería de servicio", "Archivo", "Sala de calderas", "Cava de vinos", "Capilla de la madre",
	"Ático (vigas, baúles, muñecos tapados)", "Escondite de Damián niño", "Torre", "Mirador de la torre"]
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
	return str(rooms[id].name).to_lower()

func inside_house(p: Vector3) -> bool:
	return room_at(p) >= 0

# ---------------- construcción ----------------
func build(q := 2) -> void:
	for paso in _pasos_build(q):
		(paso as Callable).call()

## Igual que build() pero cediendo un fotograma entre paso y paso: la pantalla de carga sigue viva (Android
## destruye la superficie si el juego se queda un minuto sin dibujar, como pasaba en el emulador).
## `progreso` recibe un número de 0 a 1.
func build_por_pasos(q := 2, progreso: Callable = Callable()) -> void:
	var pasos := _pasos_build(q)
	# la física se pausa mientras se construye: así la casa sale igual que construida de una vez (las consultas
	# de colisión del decorado no ven aún los cuerpos recién creados) y no se gasta tiempo moviéndolos
	PhysicsServer3D.set_active(false)
	for k in pasos.size():
		(pasos[k] as Callable).call()
		if progreso.is_valid():
			progreso.call(float(k + 1) / pasos.size())
		await get_tree().process_frame
	PhysicsServer3D.set_active(true)

func _pasos_build(q: int) -> Array:
	var t0 := Time.get_ticks_msec()
	return [
		func():
			quality = q
			_rng.seed = 1874
			var f := FileAccess.open(PLAN, FileAccess.READ)
			plan = JSON.parse_string(f.get_as_text())
			_materials()
			_tiempo("materiales", t0)
			nav_region = NavigationRegion3D.new()
			add_child(nav_region)
			_house = Node3D.new()
			nav_region.add_child(_house)
			_stairs_plan(),
		func(): _level("sotano"),
		func(): _level("baja"),
		func(): _level("alta"),
		func(): _level("atico"),
		func():
			_build_stairs()
			_roof()
			_portico()
			_decoracion_victoriana()
			_tablas_rotas()
			_miradores()
			_techo_rico()
			_frente_balcon()
			_ornatos_fachada()
			_abandono_exterior()
			_tiempo("casa", t0),
		func():
			_exterior()
			_entorno_casa()
			_tiempo("exterior", t0),
		func():
			_markers()
			if OS.get_environment("SIN_LUCES") == "": _iluminar_salas()
			_portals(),
		func():
			_decorate()
			_tiempo("decorado", t0),
		func(): _merge_static(),
		func():
			_optimizar()
			_tiempo("fusion", t0),
	]

func _tiempo(paso: String, t0: int) -> void:
	print("ZAREK paso %s hasta %d ms" % [paso, Time.get_ticks_msec() - t0])

func _optimizar() -> void:
	_oclusores()
	if OS.get_name() == "Android":
		_rugosidad_minima()
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
		# muebles y objetos importados: según su tamaño, dejan de dibujarse de lejos (y los pequeños no dan sombra:
		# la sombra de una taza no se ve y cuesta lo mismo que la de un armario)
		if gi.owner != null and gi.visibility_range_end <= 0.0 and OS.get_environment("SIN_ALCANCE") == "":
			var raiz := gi.owner as Node3D
			if raiz and raiz.scene_file_path != "":
				var t := _prop_size(raiz.scene_file_path.get_file().get_basename()) * raiz.scale.abs().x
				var lado := maxf(t.x, maxf(t.y, t.z))
				if lado > 0.0 and lado < 2.2:
					gi.visibility_range_end = 9.0 if lado < 0.35 else (16.0 if lado < 0.9 else 26.0)
					gi.visibility_range_end_margin = 1.5
				if lado > 0.0 and lado < 0.3:
					gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if gi.owner != null and en_casa:
			gi.layers = 2
		elif not en_casa and (gi.owner != null or gi is MultiMeshInstance3D):
			gi.layers = 4
	for l in find_children("*", "Light3D", true, false):
		if not (l is DirectionalLight3D):
			(l as Light3D).distance_fade_enabled = true
			# las bombillas pequeñas se apagan antes con la distancia (menos luces por objeto en el móvil)
			(l as Light3D).distance_fade_begin = 14.0 if (l is OmniLight3D and (l as OmniLight3D).omni_range < 8.0) else 22.0
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
				if OS.get_name() == "Android":
					m.set_shader_parameter("max_pasos", 4.0)
					m.set_shader_parameter("dist_relieve", 7.0)
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
	var papers := [Color(0.27, 0.29, 0.25), Color(0.17, 0.24, 0.2), Color(0.2, 0.22, 0.28), Color(0.44, 0.38, 0.28)]
	for i in papers.size():
		_mat["papel%d" % i] = _papel(_rayas(papers[i], 30 + i), Color(1.15, 1.15, 1.15))
	# papeles propios de cada sala (tools/papeles/papeles.py): la textura ya viene envejecida
	for nom in ZarekHistoria.PAPEL.values():
		var ruta := "res://zarek/texturas/papeles/%s.jpg" % nom
		if not _mat.has("p_" + nom) and ResourceLoader.exists(ruta):
			var pm := _papel(Image.create(4, 4, false, Image.FORMAT_RGB8), Color(1.05, 1.05, 1.05))
			pm.albedo_texture = load(ruta)
			pm.normal_scale = 0.6
			pm.uv1_scale = Vector3(0.5, 0.5, 0.5)
			_mat["p_" + nom] = pm
	_mat["cortina"] = _pbr("Fabric085", 1.6, Color(0.16, 0.22, 0.2), 1.0, 1.4)
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
	for nom in ["verde", "azul", "oro"]:
		var ruta := "res://zarek/texturas/alfombra_%s.jpg" % nom
		if ResourceLoader.exists(ruta):
			var am: StandardMaterial3D = persa.duplicate()
			am.albedo_texture = load(ruta)
			_mat["persa_" + nom] = am
	_mat["revestimiento"] = _pbr("Wood094", 0.6, Color(0.42, 0.4, 0.4), 0.7)
	_mat["parquet"] = _pbr("WoodFloor070", 0.45, Color(0.6, 0.66, 0.95), 0.8)
	_mat["baldosa"] = _pbr("Tiles140", 0.5, Color(1, 1, 1), 0.9)
	# suelos propios (ambientCG, CC0): damero de mármol, baldosa hidráulica, baldosa de piedra gastada, tablones viejos
	_mat["s_damero"] = _pbr("Tiles074", 0.4, Color(0.85, 0.85, 0.85), 0.6)
	_mat["s_hidraulica"] = _pbr("Tiles081", 0.5, Color(0.8, 0.8, 0.78), 0.8)
	_mat["s_cocina"] = _pbr("Tiles141", 0.45, Color(0.85, 0.84, 0.8), 0.9)
	_mat["s_tablones"] = _pbr("Wood080", 0.4, Color(0.75, 0.72, 0.68), 1.0)
	_mat["piedra"] = _pbr("Bricks108A", 0.4, Color(0.8, 0.78, 0.75), 1.0, 1.2)
	_mat["yeso"] = _pbr("Plaster007", 0.35, Color(0.85, 0.8, 0.72), 1.0)
	_mat["techo"] = _pbr("PaintedPlaster017", 0.3, Color(0.86, 0.8, 0.68), 1.0, 0.8)
	var laton := StandardMaterial3D.new()
	laton.albedo_color = Color(0.62, 0.48, 0.24)
	laton.metallic = 0.9
	laton.roughness = 0.38
	laton.metallic_specular = 0.6
	_mat["laton_viejo"] = laton
	_mat["fachada"] = _fachada_mat("TablasPintadas", 1.0 / 3.0, Color(1.0, 1.0, 1.0))
	_mat["fachada"].set_shader_parameter("suciedad", 1.5)
	_mat["fachada"].set_shader_parameter("alto_base", 2.6)
	var torre := ShaderMaterial.new()
	torre.shader = load("res://zarek/torre.gdshader")
	torre.set_shader_parameter("albedo_tex", load("res://zarek/texturas/TablasPintadas/color.jpg"))
	torre.set_shader_parameter("normal_tex", load("res://zarek/texturas/TablasPintadas/normal.jpg"))
	torre.set_shader_parameter("rough_tex", load("res://zarek/texturas/TablasPintadas/rough.jpg"))
	torre.set_shader_parameter("color", Vector3(0.7, 0.7, 0.7))
	_mat["fachada_torre"] = torre
	# molduras exteriores (marcos, cornisas, esquineras, pórtico): madera pintada de crema, sucia y gastada
	_mat["piedra_clara"] = _fachada_mat("Plaster007", 0.5, Color(0.5, 0.48, 0.44))
	_mat["piedra_clara"].set_shader_parameter("suciedad", 1.6)
	_mat["contraventana"] = _pbr("Wood049", 0.8, Color(0.16, 0.2, 0.17), 0.7)
	_mat["tejado"] = _fachada_mat("RoofingTiles013A", 0.5, Color(0.62, 0.64, 0.66))
	_mat["tejado"].set_shader_parameter("suciedad", 1.6)
	_mat["tejado"].set_shader_parameter("rugosidad_min", 0.82)
	_mat["tejado"].set_shader_parameter("especular", 0.15)
	_mat["cesped"] = _suelo("Ground037", "ScatteredLeaves009", "Ground110", 0.25, Color(0.5, 0.52, 0.42), Color(0.66, 0.62, 0.56), Color(0.75, 0.72, 0.68), 0.3, 0.2)
	_mat["bosque"] = _suelo("ScatteredLeaves009", "Ground085", "Ground037", 0.25, Color(0.7, 0.68, 0.62), Color(0.55, 0.5, 0.45), Color(0.48, 0.52, 0.4), 0.32, 0.28)
	_mat["tierra"] = _suelo("Ground110", "Ground085", "ScatteredLeaves009", 0.35, Color(0.85, 0.82, 0.78), Color(0.62, 0.56, 0.5), Color(0.66, 0.62, 0.56), 0.35, 0.15)
	_mat["agua"] = _plain(Color(0.03, 0.05, 0.07), 0.05, 0.3)
	_mat["barro"] = _pbr("Ground085", 0.35, Color(0.35, 0.3, 0.26), 0.6)
	_mat["ladrillo"] = _pbr("Bricks094", 0.55, Color(0.5, 0.4, 0.37), 1.0)
	_mat["terracota"] = _plain(Color(0.42, 0.22, 0.15), 0.9)
	_mat["madera_vieja"] = _pbr("Wood049", 0.5, Color(0.62, 0.57, 0.52), 0.9, 1.2)
	_mat["madera"] = _pbr("Wood066", 0.55, Color(0.66, 0.74, 1.0), 0.75)
	_mat["madera_clara"] = _pbr("WoodFloor043", 0.4, Color(0.9, 0.85, 0.8), 0.9)
	_mat["moldura"] = _pbr("Plaster007", 0.8, Color(0.78, 0.73, 0.64), 0.7)
	_mat["cimiento"] = _pbr("Bricks106A", 0.4, Color(0.46, 0.43, 0.39), 1.0)
	_mat["marco_ventana"] = _pbr("Plaster007", 0.8, Color(0.4, 0.38, 0.34), 1.0, 0.6)
	# sótano: muros de sillería ennegrecida, suelo de losas, túneles en roca viva, hierro oxidado
	_mat["muro_sotano"] = _pbr("Bricks106A", 0.42, Color(0.5, 0.46, 0.42), 1.0, 1.3)
	_mat["losa"] = _pbr("Rock030", 0.3, Color(0.75, 0.72, 0.68), 1.0, 1.2)
	_mat["roca"] = _pbr("Rock030", 0.35, Color(0.78, 0.74, 0.68), 1.0, 1.3)  # sin vetas horizontales: en los túneles largos hacían rayas en perspectiva
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
	var vela_m := _plain(Color(0.25, 0.12, 0.05), 0.4)
	vela_m.emission_enabled = true
	vela_m.emission = Color(1.0, 0.5, 0.18)
	vela_m.emission_energy_multiplier = 0.45
	_mat["vela"] = vela_m
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

## Escaleras de caracol: [planta de abajo, x, y (celdas), planta de arriba]. Se ven enteras: suben por un
## hueco en el techo de la planta de abajo y llegan a un rellano con barandilla en la de arriba.
const CARACOLES := [["baja", 1.5, 10.5, "alta"], ["alta", 1.5, 10.5, "atico"], ["alta", 17.4, 8.5, "atico"]]

func _caracol_centro(c: Array) -> Vector3:
	return cell_to_world(c[0], c[1], c[2])

func _stairs_plan() -> void:
	for c in CARACOLES:
		var p := _caracol_centro(c)
		var nivel := int(plan[c[3]].nivel)
		if not _hole.has(nivel):
			_hole[nivel] = []
		_hole[nivel].append(Rect2(p.x - 1.2, p.z - 1.2, 2.4, 2.4))
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
	# escaleras de caracol: su sitio abajo y el hueco con rellano arriba
	for c in CARACOLES:
		var p := _caracol_centro(c)
		out.append(Rect2(p.x - 1.9, p.z - 1.9, 3.8, 3.8))
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
		if ZarekHistoria.PAPEL.has(name) and _mat.has("p_" + String(ZarekHistoria.PAPEL[name])):
			paper = "p_" + String(ZarekHistoria.PAPEL[name])
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
			fmat = _mat.s_tablones
		if ZarekHistoria.SUELO.has(name):
			fmat = _mat[ZarekHistoria.SUELO[name]]
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
	# ventanas: hueco cada cuatro celdas de muro exterior (antes cada dos); las salas que se quedarían sin
	# ninguna recuperan la del centro de sus candidatas
	var ventana_ok := {}
	var cand_sala := {}
	for k in edges:
		var pk: PackedStringArray = k.split(":")
		var ids0: Array = edges[k]
		if _unique(ids0).size() == 1 and level >= 0 and level < 2 and not door_set.has(k) and (int(pk[1]) + int(pk[2])) % 2 == 1 and rooms[ids0[0]].type != "tunel":
			cand_sala[ids0[0]] = cand_sala.get(ids0[0], []) + [k]
			if (int(pk[1]) + int(pk[2])) % 4 == 1:
				ventana_ok[k] = true
	for sala in cand_sala:
		var cs: Array = cand_sala[sala]
		var alguna := false
		for k in cs:
			if ventana_ok.has(k):
				alguna = true
		if not alguna:
			cs.sort()
			ventana_ok[cs[cs.size() / 2]] = true
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
		var window: bool = ventana_ok.has(k)
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
				box(im, fuera + Vector3(0, -0.05 if level > 0 else 0.86, 0), _mat.piedra_clara, false, null, false)
		elif _unique(ids).size() >= 2:
			# muro entre dos salas: cada cara con el papel de su propia sala (antes las dos caras llevaban el de
			# una sola, y en la otra sala aparecía el papel de la vecina)
			var u := _unique(ids)
			var r0: Dictionary = rooms[u[0]]
			var r1: Dictionary = rooms[u[1]]
			var c0: Vector2 = (r0.rect as Rect2).get_center()
			var n0 := Vector3(0, 0, signf(c0.y - center.z)) if horiz else Vector3(signf(c0.x - center.x), 0, 0)
			var half := Vector3(l, hh, thick * 0.5) if horiz else Vector3(thick * 0.5, hh, l)
			box(half, pos + n0 * thick * 0.25, _mat[r0.paper], true)
			box(half, pos - n0 * thick * 0.25, _mat[r1.paper], false)
		else:
			box(Vector3(l, hh, thick) if horiz else Vector3(thick, hh, l), pos, mat, true)
	if level >= 0 and level < 2 and not is_door:
		# revestimiento interior: en los muros exteriores solo por la cara de dentro (antes atravesaba el muro y
		# asomaba por la fachada como una barandilla y una cornisa claras)
		var grosor := func(e: float) -> float: return (thick * 0.5 + e * 0.5) if exterior else thick + e
		var desp := func(e: float) -> Vector3: return inward * (thick * 0.25 + e * 0.25 + 0.005) if exterior else Vector3.ZERO
		var rev_h := 1.1 if not window else 0.86
		var wz := Vector3(len, rev_h, grosor.call(0.05)) if horiz else Vector3(grosor.call(0.05), rev_h, len)
		box(wz, center + Vector3(0, rev_h * 0.5, 0) + desp.call(0.05), _mat.revestimiento, false, null, false)
		# paneles del revestimiento: montantes y travesaños en relieve
		for k in 4:
			var st := Vector3(0.07, rev_h - 0.3, grosor.call(0.085)) if horiz else Vector3(grosor.call(0.085), rev_h - 0.3, 0.07)
			box(st, a + along * (len * k / 3.0 + (0.035 if k == 0 else (-0.035 if k == 3 else 0.0))) + Vector3(0, 0.22 + (rev_h - 0.3) * 0.5, 0) + desp.call(0.085), _mat.madera, false, null, false)
		for hy in [0.25, rev_h - 0.08]:
			var rl := Vector3(len, 0.04, grosor.call(0.085)) if horiz else Vector3(grosor.call(0.085), 0.04, len)
			box(rl, center + Vector3(0, hy, 0) + desp.call(0.085), _mat.madera, false, null, false)
		# zócalo, guardasilla, riel de cuadros y cornisa en dos escalones
		for mol in [[0.11, 0.22, 0.1, "madera"], [rev_h + 0.03, 0.07, 0.12, "madera"], [h - 0.62, 0.045, 0.07, "madera"], [h - 0.2, 0.1, 0.16, "moldura"], [h - 0.085, 0.13, 0.3, "moldura"]]:
			if window and float(mol[0]) > 0.5 and float(mol[0]) < 3.0:
				continue
			var e := float(mol[2])
			var ms := Vector3(len, float(mol[1]), grosor.call(e)) if horiz else Vector3(grosor.call(e), float(mol[1]), len)
			box(ms, center + Vector3(0, float(mol[0]), 0) + desp.call(e), _mat[mol[3]], false, null, false)
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
		_mat_mancha.albedo_color = Color(0.3, 0.36, 0.5, 0.32)
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

var crujidos: Array = []      # tablones rotos que crujen al pisarlos (ZarekTerror)
var montaplatos: Array = []
var velas_capilla: Array = []
var ventanas_info: Array = []  # {c, horiz, inward}: para tapiar algunas con tablas
func _window(c: Vector3, horiz: bool, thick: float, inward: Vector3) -> void:
	ventanas.append(c)
	ventanas_info.append({"c": c, "horiz": horiz, "inward": inward, "thick": thick})
	if level_of(c.y + 0.3) >= 0 and Vector3(LUNA_H.x, 0, LUNA_H.z).dot(inward) > 0.25:
		_haz_luna(c, horiz, inward)
	var lit := _rng.randf() < 0.04
	var glass := Vector3(1.6, 2.0, 0.04) if horiz else Vector3(0.04, 2.0, 1.6)
	box(glass, c + Vector3(0, 1.9, 0), _mat.ventana_luz if lit else _mat.cristal, true, null, false)
	var fr := Vector3(1.75, 0.1, thick + 0.1) if horiz else Vector3(thick + 0.1, 0.1, 1.75)
	box(fr, c + Vector3(0, 0.9, 0), _mat.marco_ventana, false, null, false)
	box(fr, c + Vector3(0, 2.9, 0), _mat.marco_ventana, false, null, false)
	# parteluces finos de una ventana de guillotina, en el plano del cristal
	var vb := Vector3(0.045, 2.0, 0.07) if horiz else Vector3(0.07, 2.0, 0.045)
	box(vb, c + Vector3(0, 1.9, 0), _mat.marco_ventana, false, null, false)
	for hy in [1.55, 2.2]:
		var hb := Vector3(1.6, 0.045, 0.07) if horiz else Vector3(0.07, 0.045, 1.6)
		box(hb, c + Vector3(0, hy, 0), _mat.marco_ventana, false, null, false)
	# marco interior alrededor del hueco
	var ej2: Vector3 = Vector3(1, 0, 0) if horiz else Vector3(0, 0, 1)
	for sj in [-1.0, 1.0]:
		var mj := Vector3(0.09, 2.0, 0.09) if horiz else Vector3(0.09, 2.0, 0.09)
		box(mj, c + ej2 * sj * 0.79 + Vector3(0, 1.9, 0), _mat.marco_ventana, false, null, false)
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
	# cortinas reales con pliegues (Objaverse, CC-BY): pesadas de terciopelo del color de la sala, o de tela
	# floral vieja en algunos dormitorios, y a veces un visillo de tul detrás que tamiza la luz de la luna
	var sala := room_at(dentro + Vector3(0, 0.5, 0))
	var nombre_sala := String(rooms[sala].name) if sala >= 0 else ""
	var t_sala := String(rooms[sala].type) if sala >= 0 else ""
	var giro := 0.0 if horiz else PI * 0.5
	var floral := t_sala == "dormitorio" and (sala % 3) == 0
	var hecho := false
	if floral:
		for s2 in [-1.0, 1.0]:
			var pf := _prop("cortina_floral", dentro + eje * s2 * 0.8, giro, 1.0, false)
			if pf:
				pf.scale = Vector3(0.3, 1.07, 0.6)
				hecho = true
		if hecho:
			box(Vector3(2.5, 0.035, 0.035) if horiz else Vector3(0.035, 0.035, 2.5), dentro + Vector3(0, 3.12, 0), _mat.laton_viejo, false, null, false)
	else:
		var pg := _prop("cortina_gris", dentro, giro, 1.0, false)
		if pg:
			pg.scale = Vector3(0.78, 1.07, 0.6)
			var tela := _tela_cortina(String(ZarekHistoria.CORTINA.get(nombre_sala, ["salvia", "botella", "marino", "mostaza", "gris", "crema"][(sala if sala >= 0 else 0) % 6])))
			for g in pg.find_children("*", "MeshInstance3D", true, false):
				(g as MeshInstance3D).material_override = tela
			hecho = true
	# (los visillos de tul rotos se veían como papel recortado: quitados)
	if false and (sala % 2) == 0:
		var tul := _prop("cortina_tul", dentro - inward * 0.07, giro, 1.0, false)
		if tul:
			tul.scale = Vector3(1.6, 1.07, 1.0)
			if not _mat.has("tul"):
				var mt := _plain(Color(0.9, 0.88, 0.82, 0.38), 0.9)
				mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mt.cull_mode = BaseMaterial3D.CULL_DISABLED
				_mat["tul"] = mt
			for g in tul.find_children("*", "MeshInstance3D", true, false):
				(g as MeshInstance3D).material_override = _mat.tul
				(g as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not hecho:
		for s3 in [-1.0, 1.0]:
			var mi := MeshInstance3D.new()
			mi.mesh = _cortina_mesh(int(s3))
			mi.material_override = _mat.cortina
			mi.position = dentro + eje * s3 * 0.82 + Vector3(0, 0.03, 0)
			mi.rotation.y = giro
			_house.add_child(mi)

## Terciopelo de cortina de un color (tela con relieve, sin depender de las UV del modelo).
const COLOR_CORTINA := {"salvia": Color(0.170, 0.200, 0.160), "botella": Color(0.060, 0.110, 0.080), "marino": Color(0.060, 0.075, 0.130),
	"mostaza": Color(0.250, 0.200, 0.090), "gris": Color(0.160, 0.160, 0.165), "crema": Color(0.310, 0.285, 0.230), "granate": Color(0.160, 0.040, 0.045)}
func _tela_cortina(nombre: String) -> StandardMaterial3D:
	if not _mat.has("cort_" + nombre):
		var m: StandardMaterial3D = (_mat.cortina as StandardMaterial3D).duplicate()
		# la textura de terciopelo original es roja: se queda solo su relieve y el color lo pone la sala
		m.albedo_texture = null
		m.roughness = 0.85
		m.albedo_color = COLOR_CORTINA.get(nombre, COLOR_CORTINA.gris)
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(1.6, 1.6, 1.6)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mat["cort_" + nombre] = m
	return _mat["cort_" + nombre]

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
	# herrajes de latón de verdad a las dos caras: picaporte o pomo (según la puerta) y bocallave debajo
	var con_pomo := _rng.randf() < 0.45
	for cara in [1.0, -1.0]:
		var giro: float = 0.0 if cara > 0.0 else PI
		var z: float = 0.036 * cara
		var tirador := _prop("pomo_laton" if con_pomo else "picaporte_laton", Vector3(gap - 0.105, 1.02, z), giro, 1.45, false, pivot)
		if tirador and con_pomo:
			tirador.rotation = Vector3(PI * 0.5 * cara, 0.0, 0.0)
			tirador.position = Vector3(gap - 0.105, 1.05, z)
		var boca := _prop("bocallave_laton", Vector3(gap - 0.105, 0.86, z), giro, 1.45, false, pivot)
		# el ojo de la cerradura es un hueco oscuro hacia dentro de la puerta (no se ve la madera); la placa se aplana
		# a 4 mm (el modelo era muy grueso y el agujero parecía un túnel)
		if boca:
			boca.scale = Vector3(boca.scale.x, boca.scale.y, boca.scale.z * 0.3)
			boca.position.z = 0.0365 * cara
			if _mat_hueco == null:
				_mat_hueco = StandardMaterial3D.new()
				_mat_hueco.albedo_color = Color(0.0, 0.0, 0.0)
				_mat_hueco.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			# centro real de la placa (el origen del modelo no está en su centro)
			var cb := Vector3.ZERO
			var nb := 0
			for mi in boca.find_children("*", "MeshInstance3D", true, false):
				var t3: Transform3D = Transform3D.IDENTITY
				var q: Node = mi
				while q and q != boca.get_parent():
					t3 = (q as Node3D).transform * t3
					q = q.get_parent()
				cb += t3 * (mi as MeshInstance3D).get_aabb().get_center()
				nb += 1
			if nb > 0:
				cb /= nb
			var hueco := box(Vector3(0.042, 0.075, 0.004), Vector3(cb.x, cb.y, 0.0356 * cara), _mat_hueco, false, pivot, false)
			hueco.set_meta("dyn", true)
		for pieza in [tirador, boca]:
			if pieza:
				for mi in (pieza as Node3D).find_children("*", "MeshInstance3D", true, false):
					(mi as MeshInstance3D).material_override = _mat.laton_viejo
	if locked:
		# cerrada con cadenas y un candado viejo
		box(Vector3(gap * 0.9, 0.06, 0.12), Vector3(gap * 0.5, 1.2, 0.05), _mat.metal, false, pivot)
		box(Vector3(gap * 0.9, 0.06, 0.12), Vector3(gap * 0.5, 1.45, 0.05), _mat.metal, false, pivot)
		_prop("candado_viejo", Vector3(gap * 0.5, 1.22, 0.12), 0.0, 1.4, false, pivot)
	# toda la hoja (madera, paneles, herrajes) en una malla por material: de ~12 llamadas de dibujo a 3
	_fusionar_hijos(pivot)
	# la hoja cerrada tapa lo que hay al otro lado: el teléfono no dibuja la sala de detrás
	var oc := OccluderInstance3D.new()
	var bo := BoxOccluder3D.new()
	bo.size = Vector3(gap - 0.1, 2.35, 0.04)
	oc.occluder = bo
	oc.position = Vector3(gap * 0.5, 1.2, 0)
	pivot.add_child(oc)
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
		"base": pivot.rotation.y, "snd": snd, "level": level, "horiz": horiz, "ids": ids, "gap": gap}
	if start_open:
		d.ang = 1.6
		d.target = 1.6
		cs.disabled = true
		pivot.rotation.y = d.base + d.ang
	doors.append(d)

## Junta todas las mallas de un nodo (y de sus modelos) en una malla por material, en el espacio del nodo.
## Para piezas que se mueven juntas (la hoja de una puerta con sus herrajes).
func _fusionar_hijos(raiz: Node3D) -> void:
	var grupos := {}
	var quitar: Array = []
	for c in raiz.find_children("*", "MeshInstance3D", true, false):
		var mi := c as MeshInstance3D
		if mi.mesh == null:
			continue
		var t := Transform3D.IDENTITY
		var q: Node = mi
		while q and q != raiz:
			t = (q as Node3D).transform * t
			q = q.get_parent()
		for si in mi.mesh.get_surface_count():
			var mat: Material = mi.material_override if mi.material_override else mi.get_active_material(si)
			if mat == null:
				continue
			if not grupos.has(mat):
				var st := SurfaceTool.new()
				grupos[mat] = st
			(grupos[mat] as SurfaceTool).append_from(mi.mesh, si, t)
		# se quita el modelo entero (su raíz es hija directa de la puerta) o la pieza suelta
		var r: Node = mi
		while r.get_parent() != raiz:
			r = r.get_parent()
		if not r in quitar:
			quitar.append(r)
	for r in quitar:
		raiz.remove_child(r)
		r.free()
	for mat in grupos:
		var nm := MeshInstance3D.new()
		nm.mesh = (grupos[mat] as SurfaceTool).commit()
		nm.material_override = mat
		raiz.add_child(nm)

## Atranca una puerta cerrada con tablones clavados por los dos lados: aguanta `fuerza` segundos de golpes.
func atrancar(d: Dictionary, fuerza := 6.0) -> void:
	if d.is_empty() or d.open:
		return
	d["barricada"] = fuerza
	var n := Node3D.new()
	n.position = d.pos
	n.rotation.y = float(d.base)
	_house.add_child(n)
	for lado in [-1.0, 1.0]:
		for k in 3:
			var t := box(Vector3(1.45, 0.13, 0.035), Vector3(0, 0.6 + k * 0.55, lado * 0.11), _mat.madera_vieja, false, n, false)
			t.rotation.z = (0.18 if k % 2 == 0 else -0.14) * lado
	d["tablas"] = n

func desatrancar(d: Dictionary) -> void:
	d["barricada"] = 0.0
	if d.has("mueble"):
		# el mueble que Sofía empujó contra la puerta sale despedido
		var rb := d.mueble as RigidBody3D
		if is_instance_valid(rb):
			rb.freeze = false
			rb.apply_central_impulse(Vector3(randf_range(-1, 1), 1.0, randf_range(-1, 1)) * rb.mass * 2.0)
		d.erase("mueble")
	if d.has("tablas") and is_instance_valid(d.tablas):
		(d.tablas as Node3D).queue_free()
	d.erase("tablas")

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

## Puertas con peso: no giran a velocidad fija, se mueven como un muelle amortiguado (arrancan despacio,
## llegan con un leve rebote y se asientan). `force` = de una patada: muy rápida y rebota contra la pared.
## Entreabierta (0,45 rad) sigue teniendo colisión: deja una rendija para asomarse, no para pasar.
const PUERTA_RENDIJA := 0.45
func set_door(d: Dictionary, open: bool, force := false) -> void:
	if d.is_empty() or (d.locked and open) or (open and float(d.get("barricada", 0.0)) > 0.0):
		return
	d.open = open
	d["entre"] = false
	d.target = (1.6 if open else 0.0)
	d.shape.disabled = open
	d["speed"] = 9.0 if force else 3.2
	d["rigidez"] = 70.0 if force else 9.0
	d["freno"] = 7.0 if force else 5.2
	if force:
		d["vel"] = 7.0

## Abre una rendija (despacio, con el crujido de las bisagras).
func entreabrir(d: Dictionary) -> void:
	if d.is_empty() or d.locked or float(d.get("barricada", 0.0)) > 0.0:
		return
	d.open = false
	d["entre"] = true
	d.target = PUERTA_RENDIJA
	d.shape.disabled = false
	d["rigidez"] = 4.5
	d["freno"] = 4.2

## Detalles que hacen que la casa parezca una mansión: esquinas con sillares alternos (cadenas de esquina),
## cornisa grande con ménsulas bajo el tejado e impostas entre pisos, todo en piedra clara.
func _ornatos_fachada() -> void:
	var r := house_rect
	var pc: Material = _mat.piedra_clara
	var cara := 0.26
	var alto_total := lvl_y(2) + 3.4
	var esquinas := [[r.position, Vector2(1, 1)], [Vector2(r.end.x, r.position.y), Vector2(-1, 1)], [Vector2(r.position.x, r.end.y), Vector2(1, -1)], [r.end, Vector2(-1, -1)]]
	# esquineras: tablas verticales pintadas que cubren cada esquina
	for e in esquinas:
		var p: Vector2 = e[0]
		var d: Vector2 = e[1]
		box(Vector3(0.32, alto_total - 0.5, 0.07), Vector3(p.x + d.x * (0.16 - cara), 0.5 + (alto_total - 0.5) * 0.5, p.y - d.y * (cara + 0.035)), pc, false, self, false)
		box(Vector3(0.07, alto_total - 0.5, 0.32), Vector3(p.x - d.x * (cara + 0.035), 0.5 + (alto_total - 0.5) * 0.5, p.y + d.y * (0.16 - cara)), pc, false, self, false)
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
	_portada = c
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
	_luz_atico.light_color = Color(1.0, 0.55, 0.25)
	_luz_atico.light_energy = 1.2
	_luz_atico.omni_range = 4.0
	_luz_atico.position = Vector3(r.get_center().x - r.size.x * 0.22 + 0.85, lvl_y(2) + 3.45 + 2.0, r.end.y + 1.5)
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
	var nb := int(r.size.x / 0.3)
	for k in nb:
		var alto_b := 0.55 if k % 3 == 0 else 0.38
		box(Vector3(0.025, alto_b, 0.025), Vector3(r.position.x + 0.15 + k * 0.3, y + 12.65 + alto_b * 0.5, c.y), _mat.metal, false, self, false)
	for hy in [12.72, 13.0]:
		box(Vector3(r.size.x, 0.035, 0.035), Vector3(c.x, y + hy, c.y), _mat.metal, false, self, false)
	for ex in [r.position.x - 0.6, r.end.x + 0.6]:
		cyl(0.03, 0.06, 1.6, Vector3(ex, y + 13.45, c.y), _mat.metal, self, 6)
		cyl(0.1, 0.1, 0.16, Vector3(ex, y + 13.6, c.y), _mat.metal, self, 8)
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
		# dos ventanas de guillotina del ático (antes un óculo redondo, que hacía parecer la casa una iglesia)
		for vx in [-0.85, 0.85]:
			var wp := Vector3(c.x + sx + vx, y + 1.2, r.end.y + 1.04)
			var vela: bool = sx < 0 and vx > 0  # en una ventana del ático tiembla la luz de una vela
			box(Vector3(0.95, 1.55, 0.04), wp + Vector3(0, 0.78, 0), _mat.vela if vela else _mat.vidrio, false, self, false)
			box(Vector3(0.04, 1.55, 0.06), wp + Vector3(0, 0.78, 0.03), _mat.marco_ventana, false, self, false)
			box(Vector3(0.95, 0.04, 0.06), wp + Vector3(0, 0.95, 0.03), _mat.marco_ventana, false, self, false)
			for s2 in [-1.0, 1.0]:
				box(Vector3(0.12, 1.75, 0.08), wp + Vector3(s2 * 0.53, 0.78, 0.05), _mat.piedra_clara, false, self, false)
			box(Vector3(1.25, 0.1, 0.18), wp + Vector3(0, -0.04, 0.08), _mat.piedra_clara, false, self, false)
			box(Vector3(1.3, 0.16, 0.14), wp + Vector3(0, 1.66, 0.07), _mat.piedra_clara, false, self, false)
	for cp in [Vector2(c.x + 9, c.y + 3)]:  # una sola chimenea, en el faldón delantero
		box(Vector3(1.6, 10.6, 1.1), Vector3(cp.x, y + 7.3, cp.y), _mat.ladrillo, false, self)
		box(Vector3(1.8, 0.16, 1.3), Vector3(cp.x, y + 11.9, cp.y), _mat.cimiento, false, self, false)
		box(Vector3(1.9, 0.28, 1.4), Vector3(cp.x, y + 12.7, cp.y), _mat.cimiento, false, self, false)
		for k in 3:
			cyl(0.13, 0.17, 0.5, Vector3(cp.x - 0.48 + k * 0.48, y + 13.09, cp.y), _mat.terracota, self, 8)
	# torre redonda con techo cónico (esquina delantera oeste)
	var t0 := cell_to_world("baja", 0, 9)
	# tambor de la torre: toca la pared de la sala de música sin entrar en ella y sobresale hacia el oeste y el sur
	var rt := 4.2
	var tc := t0 + Vector3(3.0, 0, 5.0)
	var th := lvl_y(3) + 1.0
	# tambor de la torre: mapeado por UV (no triplanar: en una superficie curva el triplanar hace bandas)
	(_mat.fachada_torre as ShaderMaterial).set_shader_parameter("casa", Vector4(house_rect.position.x, house_rect.position.y, house_rect.size.x, house_rect.size.y))
	var tambor := cyl(rt, rt, th, tc + Vector3(0, th * 0.5 - 0.02, 0), _mat.fachada_torre, self, 48)
	tambor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cyl(0.0, rt + 1.0, 9.0, tc + Vector3(0, th + 4.5, 0), _mat.tejado, self, 24)
	cyl(0.04, 0.06, 0.9, tc + Vector3(0, th + 9.2, 0), _mat.metal, self, 6)
	for lv in 3:
		for k in 6:
			var a := TAU * k / 6.0 + 0.3
			var wp := tc + Vector3(cos(a) * (rt + 0.05), lvl_y(lv) + 1.9, sin(a) * (rt + 0.05))
			if house_rect.grow(-0.12).has_point(Vector2(wp.x, wp.z)):
				continue  # ventana que caería dentro de una sala
			var nd := Node3D.new()
			nd.position = wp
			nd.rotation.y = -a
			add_child(nd)
			box(Vector3(0.1, 2.0, 1.1), Vector3.ZERO, _mat.vela if (k == 2 and lv == 2) else _mat.vidrio, false, nd, false)
			box(Vector3(0.12, 2.0, 0.04), Vector3(0.02, 0, 0), _mat.marco_ventana, false, nd, false)
			box(Vector3(0.12, 0.04, 1.1), Vector3(0.02, 0.25, 0), _mat.marco_ventana, false, nd, false)
			for s2 in [-1.0, 1.0]:
				box(Vector3(0.14, 2.25, 0.12), Vector3(0.04, 0, s2 * 0.61), _mat.piedra_clara, false, nd, false)
			box(Vector3(0.26, 0.1, 1.45), Vector3(0.08, -1.05, 0), _mat.piedra_clara, false, nd, false)
			box(Vector3(0.26, 0.16, 1.5), Vector3(0.08, 1.15, 0), _mat.piedra_clara, false, nd, false)
			for s2 in [-1.0, 1.0]:
				box(Vector3(0.16, 0.22, 0.08), Vector3(0.08, 1.0, s2 * 0.66), _mat.piedra_clara, false, nd, false)

## Decoración victoriana de madera tallada («gingerbread»): hastiales con tejas en escama, tablas de alero
## caladas con colgantes, cercha decorativa y pináculo en cada vértice, aro en los óculos; friso de
## dentículos bajo la cornisa; en la torre, banda de escamas, ménsulas bajo el alero y remate con bola; en
## el pórtico, friso de husillos y ménsulas curvas. Todo sin colisión.
func _decoracion_victoriana() -> void:
	var r := house_rect
	var c := r.get_center()
	var y := lvl_y(2) + 3.45
	var tr: Material = _mat.piedra_clara
	var escamas := _fachada_mat("Escamas", 0.5, Color(0.95, 0.95, 0.95))
	escamas.set_shader_parameter("suciedad", 0.9)
	# --- hastiales delanteros ---
	for sx in [-r.size.x * 0.22, r.size.x * 0.2]:
		var gx: float = c.x + sx
		var zf := r.end.y + 1.0
		# tejas en escama en la parte alta del hastial (la de abajo sigue de tablas)
		var h := 5.2
		var esc := MeshInstance3D.new()
		var em := PrismMesh.new()
		em.size = Vector3(13.0 * h / 7.0, h, 0.04)
		esc.mesh = em
		esc.material_override = escamas
		esc.position = Vector3(gx, y + 7.0 - h * 0.5, zf + 0.03)
		esc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(esc)
		# moldura horizontal donde empiezan las escamas
		box(Vector3(13.0 * h / 7.0 + 0.3, 0.16, 0.12), Vector3(gx, y + 7.0 - h, zf + 0.07), tr, false, self, false)
		# tablas de alero caladas a lo largo de los dos faldones, con colgantes torneados
		var ang := atan2(7.8, 7.25)
		var largo := sqrt(7.8 * 7.8 + 7.25 * 7.25)
		for lado in [-1.0, 1.0]:
			var mid := Vector3(gx + lado * 7.25 * 0.5, y + 3.9 - 0.32, r.end.y + 1.12)
			var tabla := box(Vector3(largo, 0.42, 0.07), mid, tr, false, self, false)
			tabla.rotation.z = -lado * ang
			var n := int(largo / 0.55)
			for k in range(1, n):
				var t := float(k) / n
				var p := Vector3(gx + lado * 7.25 * (1.0 - t), y + 7.8 * t - 0.6, r.end.y + 1.12)
				cyl(0.035, 0.05, 0.3, p, tr, self, 6)
				cyl(0.06, 0.06, 0.07, p + Vector3(0, -0.17, 0), tr, self, 8)
			# remate tallado en el pie del faldón
			box(Vector3(0.35, 0.8, 0.1), Vector3(gx + lado * 7.1, y - 0.2, r.end.y + 1.12), tr, false, self, false)
		# cercha decorativa en el vértice: pendolón, tirante, tornapuntas y abanico de listones
		var ap := Vector3(gx, y + 7.8 - 0.35, r.end.y + 1.14)
		box(Vector3(0.16, 2.0, 0.12), ap + Vector3(0, -1.0, 0), tr, false, self, false)
		cyl(0.09, 0.05, 0.4, ap + Vector3(0, -2.2, 0), tr, self, 8)
		var ancho_t := 2.0 * 2.0 * 7.25 / 7.8
		box(Vector3(ancho_t, 0.14, 0.12), ap + Vector3(0, -1.85, 0), tr, false, self, false)
		# pináculo con aguja sobre el vértice
		var cima := Vector3(gx, y + 7.8 + 0.05, r.end.y + 0.9)
		box(Vector3(0.18, 0.4, 0.18), cima + Vector3(0, 0.2, 0), tr, false, self, false)
	# --- friso de dentículos bajo la cornisa de toda la casa ---
	var yd := lvl_y(2) + 3.2 - 0.4
	for lado in 4:
		var horiz := lado < 2
		var l := r.size.x if horiz else r.size.y
		var n := int(l / 0.32)
		for k in n:
			var t := -l * 0.5 + 0.16 + k * 0.32
			var p := Vector3(c.x + t, yd, (r.position.y - 0.33) if lado == 0 else (r.end.y + 0.33)) if horiz else Vector3((r.position.x - 0.33) if lado == 2 else (r.end.x + 0.33), yd, c.y + t)
			box(Vector3(0.14, 0.16, 0.12) if horiz else Vector3(0.12, 0.16, 0.14), p, tr, false, self, false)
	# --- torre: banda de escamas en lo alto, moldura, ménsulas bajo el alero y remate con bola ---
	var t0 := cell_to_world("baja", 0, 9)
	var tc := t0 + Vector3(3.0, 0, 5.0)
	var rt := 4.2
	var th := lvl_y(3) + 1.0
	var esc_t := ShaderMaterial.new()
	esc_t.shader = load("res://zarek/torre.gdshader")
	esc_t.set_shader_parameter("albedo_tex", load("res://zarek/texturas/Escamas/color.jpg"))
	esc_t.set_shader_parameter("normal_tex", load("res://zarek/texturas/Escamas/normal.jpg"))
	esc_t.set_shader_parameter("rough_tex", load("res://zarek/texturas/Escamas/rough.jpg"))
	esc_t.set_shader_parameter("color", Vector3(0.85, 0.85, 0.85))
	esc_t.set_shader_parameter("uv_escala", Vector2(TAU * rt / 2.0, 1.8 / 1.25))
	esc_t.set_shader_parameter("casa", Vector4(r.position.x, r.position.y, r.size.x, r.size.y))
	var banda := cyl(rt + 0.04, rt + 0.04, 1.8, tc + Vector3(0, th - 0.9, 0), esc_t, self, 48)
	banda.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for hy in [th - 1.85, th - 0.05]:
		var mold := cyl(rt + 0.13, rt + 0.13, 0.16, tc + Vector3(0, hy, 0), tr, self, 48)
		mold.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for k in 20:
		var a := TAU * k / 20.0
		var p := tc + Vector3(cos(a) * (rt + 0.35), th - 0.3, sin(a) * (rt + 0.35))
		if r.grow(-0.3).has_point(Vector2(p.x, p.z)):
			continue
		var men := box(Vector3(0.62, 0.42, 0.12), p, tr, false, self, false)
		men.rotation.y = -a
	cyl(0.22, 0.22, 0.4, tc + Vector3(0, th + 9.0 + 0.1, 0), _mat.metal, self, 10).scale = Vector3(1, 1.1, 1)

## Tablas arrancadas y colgando en la fachada: huecos negros donde faltan tablas y alguna tabla suelta,
## torcida y medio caída, lejos de las ventanas. Solo decorado.
func _tablas_rotas() -> void:
	var r := house_rect
	var rng := RandomNumberGenerator.new()
	rng.seed = 1987
	var fach: Material = _mat.fachada
	var torre := Rect2(r.position.x - 1.5, cell_to_world("baja", 0, 9).z - 1.5, 3 * CELL + 3.0, 3 * CELL + 4.5)
	for lado in 4:
		var horiz := lado < 2
		var l := r.size.x if horiz else r.size.y
		var fuera := Vector3(0, 0, -1 if lado == 0 else 1) if horiz else Vector3(-1 if lado == 2 else 1, 0, 0)
		var ej := Vector3(1, 0, 0) if horiz else Vector3(0, 0, 1)
		var origen := Vector3(r.position.x, 0, r.position.y if lado == 0 else r.end.y) if horiz else Vector3(r.position.x if lado == 2 else r.end.x, 0, r.position.y)
		var puestos := 0
		var intentos := 0
		while puestos < int(l / 2.6) and intentos < 300:
			intentos += 1
			var u := rng.randf_range(1.0, l - 1.0)
			var yy := rng.randf_range(0.9, lvl_y(2) - 0.6)
			var p := origen + ej * u + Vector3(0, yy, 0)
			if torre.has_point(Vector2(p.x, p.z)):
				continue
			var mal := false
			for w in ventanas_info:
				var cw: Vector3 = w.c
				if absf(cw.y - lvl_y(level_of(yy))) < 0.5 and Vector2(cw.x - p.x, cw.z - p.z).length() < 1.6:
					mal = true
			if absf(yy - lvl_y(1)) < 0.5:
				mal = true  # impostas
			if mal:
				continue
			puestos += 1
			var ancho := rng.randf_range(0.8, 2.2)
			var alto := 0.19 * rng.randi_range(1, 4)
			var cara := p + fuera * 0.14
			var hueco := box(Vector3(ancho, alto, 0.02) if horiz else Vector3(0.02, alto, ancho), cara, _mat.oscuro, false, self, false)
			hueco.set_meta("rota", true)
			# trozos de las tablas que faltan: una colgando torcida, a veces otra astillada en el borde
			var tabla := box(Vector3(ancho * rng.randf_range(0.6, 1.1), 0.18, 0.035) if horiz else Vector3(0.035, 0.18, ancho * rng.randf_range(0.6, 1.1)), cara + fuera * 0.05 - Vector3(0, alto * 0.5 + 0.12, 0) + ej * rng.randf_range(-0.2, 0.2), fach, false, self, false)
			var giro := rng.randf_range(0.25, 0.7) * (1 if rng.randf() < 0.5 else -1)
			if horiz:
				tabla.rotation.z = giro
			else:
				tabla.rotation.x = giro
			if rng.randf() < 0.5:
				box(Vector3(0.25, 0.18, 0.04) if horiz else Vector3(0.04, 0.18, 0.25), cara + fuera * 0.03 + ej * (ancho * 0.5 + 0.1) + Vector3(0, alto * 0.5 - 0.09, 0), fach, false, self, false)

## Prisma vertical de planta poligonal (lista de puntos xz en orden, sentido horario visto desde arriba):
## caras laterales hacia fuera y, si se pide, tapa arriba y abajo.
func _prisma(pts: Array, y0: float, y1: float, mat: Material, tapas := true) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in pts.size() - 1:
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[k + 1]
		var a0 := Vector3(a.x, y0, a.y); var b0 := Vector3(b.x, y0, b.y)
		var a1 := Vector3(a.x, y1, a.y); var b1 := Vector3(b.x, y1, b.y)
		for v in [a0, b0, b1, a0, b1, a1]:
			st.set_uv(Vector2(v.x + v.z, v.y))
			st.add_vertex(v)
	if tapas:
		for k in range(1, pts.size() - 2):
			var p0: Vector2 = pts[0]; var p1: Vector2 = pts[k]; var p2: Vector2 = pts[k + 1]
			for v in [Vector3(p0.x, y1, p0.y), Vector3(p1.x, y1, p1.y), Vector3(p2.x, y1, p2.y)]:
				st.set_uv(Vector2(v.x + v.z, v.y))
				st.add_vertex(v)
			for v in [Vector3(p0.x, y0, p0.y), Vector3(p2.x, y0, p2.y), Vector3(p1.x, y0, p1.y)]:
				st.set_uv(Vector2(v.x + v.z, v.y))
				st.add_vertex(v)
	st.generate_normals()
	st.generate_tangents()  # mismo formato que las cajas: así la fusión de mallas las junta bien
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	add_child(mi)
	return mi

## Mirador saliente de tres caras bajo cada hastial (estilo Reina Ana): nace sobre el tejadillo de la veranda
## con ménsulas talladas y colgantes; columnillas torneadas en los cantos; paneles en relieve bajo cada
## ventana; ventanas altas con montante superior y guardapolvo con ménsulas; banda de escamas entre plantas;
## cornisa con dentículos y ménsulas; y un tejadillo de pizarra en faldones con crestería de hierro.
func _mirador_en(p0: Vector3, yaw: float, y0: float, mensulas: bool) -> void:
	var antes := get_child_count()
	var tr: Material = _mat.piedra_clara
	var esc := _fachada_mat("Escamas", 0.5, Color(0.95, 0.95, 0.95))
	var panel := _pbr("Wood049", 0.8, Color(0.22, 0.21, 0.2), 1.0, 0.8)
	var zf := 0.12
	var y1 := lvl_y(2) + 2.55      # cornisa del mirador; encima va su tejadillo, bajo el hastial
	var ab := 2.3                  # medio ancho junto al muro
	var af := 1.35                 # medio ancho del frente
	var sal := 1.0                 # cuánto sale
	var ang_l := atan2(-(ab - af), sal)
	var gx := 0.0
	var pts := [Vector2(gx - ab, zf), Vector2(gx - af, zf + sal), Vector2(gx + af, zf + sal), Vector2(gx + ab, zf)]
	var crece := func(g: float) -> Array:
		return [Vector2(gx - ab - g, zf), Vector2(gx - af - g * 0.6, zf + sal + g), Vector2(gx + af + g * 0.6, zf + sal + g), Vector2(gx + ab + g, zf)]
	_prisma(_al_reves(pts), y0, y1, _mat.fachada)
	# zócalo moldurado, banda de escamas entre plantas y cornisa en tres escalones
	_prisma(_al_reves(crece.call(0.14)), y0 - 0.12, y0 + 0.2, tr)
	_prisma(_al_reves(crece.call(0.06)), y0 + 0.2, y0 + 0.3, tr)
	_prisma(_al_reves(crece.call(0.1)), lvl_y(2) - 0.4, lvl_y(2) - 0.28, tr)
	_prisma(_al_reves(crece.call(0.03)), lvl_y(2) - 0.28, lvl_y(2) + 0.22, esc)
	_prisma(_al_reves(crece.call(0.1)), lvl_y(2) + 0.22, lvl_y(2) + 0.34, tr)
	_prisma(_al_reves(crece.call(0.05)), y1 - 0.45, y1 - 0.3, tr)
	_prisma(_al_reves(crece.call(0.14)), y1 - 0.12, y1, tr)
	_prisma(_al_reves(crece.call(0.26)), y1, y1 + 0.12, tr)
	# dentículos y ménsulas bajo la cornisa, a lo largo de las tres caras
	for k in 3:
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[k + 1]
		var l := a.distance_to(b)
		var giro: float = [ang_l, 0.0, -ang_l][k]
		var fuera := Vector2(-(b.y - a.y), b.x - a.x).normalized()
		var nd := int(l / 0.2)
		for j in nd:
			var q := a.lerp(b, (j + 0.5) / nd) + fuera * 0.08
			var d := box(Vector3(0.08, 0.1, 0.12), Vector3(q.x, y1 - 0.2, q.y), tr, false, self, false)
			d.rotation.y = giro
		for j in 3:
			var q := a.lerp(b, (j + 0.5) / 3.0) + fuera * 0.14
			var m := box(Vector3(0.1, 0.32, 0.22), Vector3(q.x, y1 - 0.2, q.y), tr, false, self, false)
			m.rotation.y = giro
	# ménsulas talladas con colgante bajo el mirador (si nace en alto)
	for k in (4 if mensulas else 0):
		var u := lerpf(-af + 0.15, af - 0.15, k / 3.0)
		var men := box(Vector3(0.16, 0.7, 0.85), Vector3(gx + u, y0 - 0.38, zf + sal - 0.42), tr, false, self, false)
		men.rotation.x = -0.32
		box(Vector3(0.2, 0.12, 0.2), Vector3(gx + u, y0 - 0.12, zf + sal - 0.05), tr, false, self, false)
		cyl(0.07, 0.03, 0.32, Vector3(gx + u, y0 - 0.34, zf + sal - 0.05), tr, self, 8)
	# columnillas torneadas en los cuatro cantos, con basa y capitel
	for p in pts:
		var pp: Vector2 = p
		var cp := Vector3(pp.x, 0, pp.y + 0.03)
		for tramo in [[y0 + 0.3, lvl_y(2) - 0.4], [lvl_y(2) + 0.34, y1 - 0.45]]:
			var ya: float = tramo[0]
			var yb: float = tramo[1]
			cyl(0.06, 0.07, yb - ya - 0.3, cp + Vector3(0, (ya + yb) * 0.5, 0), tr, self, 8)
			cyl(0.1, 0.1, 0.15, cp + Vector3(0, ya + 0.08, 0), tr, self, 8)
			cyl(0.11, 0.07, 0.15, cp + Vector3(0, yb - 0.08, 0), tr, self, 8)
			cyl(0.09, 0.09, 0.06, cp + Vector3(0, (ya + yb) * 0.5, 0), tr, self, 8)
	# ventanas: frente y caras inclinadas, en el primer piso y en el ático
	var caras := [[Vector2(gx, zf + sal), 0.0, 1.05], [(pts[0] + pts[1]) * 0.5, ang_l, 0.62], [(pts[2] + pts[3]) * 0.5, -ang_l, 0.62]]
	var niveles := [0, 1, 2] if y0 < 1.0 else [1, 2]
	for lv in niveles:
		var yv := lvl_y(lv) + (1.0 if lv == 1 else 0.7)
		var hv := 2.3 if lv == 1 else 1.35
		for cf in caras:
			var p2: Vector2 = cf[0]
			var nd2 := Node3D.new()
			nd2.position = Vector3(p2.x, yv, p2.y)
			nd2.rotation.y = cf[1]
			add_child(nd2)
			var w: float = cf[2]
			# panel en relieve bajo la ventana
			if lv == niveles[0]:
				box(Vector3(w, 0.55, 0.03), Vector3(0, -0.42, 0.02), panel, false, nd2, false)
				box(Vector3(w + 0.1, 0.06, 0.06), Vector3(0, -0.13, 0.04), tr, false, nd2, false)
				box(Vector3(w + 0.1, 0.06, 0.06), Vector3(0, -0.72, 0.04), tr, false, nd2, false)
				box(Vector3(w * 0.6, 0.25, 0.04), Vector3(0, -0.42, 0.04), tr, false, nd2, false)
			# cristal con montante arriba (vidrios pequeños) y guillotina
			box(Vector3(w, hv, 0.04), Vector3(0, hv * 0.5, 0.02), _mat.vidrio, false, nd2, false)
			box(Vector3(0.035, hv * 0.78, 0.06), Vector3(0, hv * 0.39, 0.04), _mat.marco_ventana, false, nd2, false)
			for hy in [hv * 0.42, hv * 0.78]:
				box(Vector3(w, 0.04, 0.06), Vector3(0, hy, 0.04), _mat.marco_ventana, false, nd2, false)
			for k in 3:
				box(Vector3(0.025, hv * 0.22, 0.06), Vector3(lerpf(-w * 0.5, w * 0.5, (k + 1) / 4.0), hv * 0.89, 0.04), _mat.marco_ventana, false, nd2, false)
			for s in [-1.0, 1.0]:
				box(Vector3(0.09, hv + 0.1, 0.08), Vector3(s * (w * 0.5 + 0.045), hv * 0.5, 0.05), tr, false, nd2, false)
			box(Vector3(w + 0.26, 0.08, 0.16), Vector3(0, -0.04, 0.08), tr, false, nd2, false)
			# guardapolvo con ménsulas
			box(Vector3(w + 0.34, 0.12, 0.22), Vector3(0, hv + 0.14, 0.1), tr, false, nd2, false)
			box(Vector3(w + 0.2, 0.08, 0.12), Vector3(0, hv + 0.04, 0.06), tr, false, nd2, false)
			for s in [-1.0, 1.0]:
				box(Vector3(0.07, 0.2, 0.14), Vector3(s * (w * 0.5 + 0.1), hv + 0.0, 0.08), tr, false, nd2, false)
	# tejadillo de pizarra en faldones contra la fachada, con crestería
	var base: Array = crece.call(0.3)
	var tope := [Vector2(gx - ab + 0.3, zf), Vector2(gx - af + 0.35, zf + 0.35), Vector2(gx + af - 0.35, zf + 0.35), Vector2(gx + ab - 0.3, zf)]
	_tejadillo(_al_reves(base), _al_reves(tope), y1 + 0.12, y1 + 1.05)
	for k in 3:
		var a: Vector2 = tope[k]
		var b: Vector2 = tope[k + 1]
		var l := a.distance_to(b)
		var n := maxi(int(l / 0.18), 1)
		for j in n + 1:
			var q := a.lerp(b, float(j) / n)
			box(Vector3(0.02, 0.3 if j % 2 == 0 else 0.2, 0.02), Vector3(q.x, y1 + 1.2, q.y), _mat.metal, false, self, false)
		var mm := (a + b) * 0.5
		var rail := box(Vector3(l, 0.025, 0.025), Vector3(mm.x, y1 + 1.33, mm.y), _mat.metal, false, self, false)
		rail.rotation.y = -atan2(b.y - a.y, b.x - a.x)
	if not mensulas:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(ab * 2.0, y1, sal + 0.12)
		cs.shape = bs
		sb.add_child(cs)
		sb.position = Vector3(0, y1 * 0.5, (sal + 0.12) * 0.5)
		add_child(sb)
	# todo lo construido (en el origen, mirando a +z) se lleva a la fachada que toque: se aplica la colocación a
	# cada pieza directamente (sin nodo intermedio, para que la fusión de mallas las junte bien)
	var colocar := Transform3D(Basis(Vector3.UP, yaw), p0)
	for k in range(antes, get_child_count()):
		var n := get_child(k)
		if n is Node3D:
			(n as Node3D).transform = colocar * (n as Node3D).transform
		# las mallas hechas a mano (cuerpo, bandas, tejadillo) no entran en la fusión: giradas salían invisibles
		if n is MeshInstance3D and (n as MeshInstance3D).mesh is ArrayMesh:
			n.set_meta("dyn", true)
	var fuera := Vector3(sin(yaw), 0, cos(yaw))
	var lat := Vector3(cos(yaw), 0, -sin(yaw))
	var ctr := p0 + fuera * 0.7
	huellas_miradores.append(Rect2(Vector2(ctr.x, ctr.z) - Vector2(absf(lat.x) * 2.6 + absf(fuera.x) * 0.9, absf(lat.z) * 2.6 + absf(fuera.z) * 0.9), Vector2(absf(lat.x) * 5.2 + absf(fuera.x) * 1.8, absf(lat.z) * 5.2 + absf(fuera.z) * 1.8)))

var huellas_miradores: Array[Rect2] = []

## Miradores: dos en el frente (sobre la veranda, bajo los hastiales), dos detrás y uno en cada costado
## (estos nacen del suelo).
func _miradores() -> void:
	var r := house_rect
	var c := r.get_center()
	for sx in [-r.size.x * 0.22, r.size.x * 0.2]:
		_mirador_en(Vector3(c.x + sx, 0, r.end.y), 0.0, lvl_y(1) - 0.15, true)
		_mirador_en(Vector3(c.x + sx, 0, r.position.y), PI, 0.3, false)
	_mirador_en(Vector3(r.position.x, 0, r.position.y + 9.0), -PI * 0.5, 0.3, false)
	_mirador_en(Vector3(r.end.x, 0, r.position.y + 10.0), PI * 0.5, 0.3, false)

func _al_reves(a: Array) -> Array:
	var b := a.duplicate()
	b.reverse()
	return b

## Faldones de un tejadillo entre un contorno abajo y otro arriba (mismo número de puntos), abierto por detrás.
func _tejadillo(abajo: Array, arriba: Array, y0: float, y1: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in abajo.size() - 1:
		var a0 := Vector3(abajo[k].x, y0, abajo[k].y)
		var b0 := Vector3(abajo[k + 1].x, y0, abajo[k + 1].y)
		var a1 := Vector3(arriba[k].x, y1, arriba[k].y)
		var b1 := Vector3(arriba[k + 1].x, y1, arriba[k + 1].y)
		for v in [a0, b0, b1, a0, b1, a1]:
			st.set_uv(Vector2(v.x + v.z, v.y))
			st.add_vertex(v)
	# remate plano arriba
	for k in range(1, arriba.size() - 2):
		for v in [Vector3(arriba[0].x, y1, arriba[0].y), Vector3(arriba[k + 1].x, y1, arriba[k + 1].y), Vector3(arriba[k].x, y1, arriba[k].y)]:
			st.set_uv(Vector2(v.x + v.z, v.y))
			st.add_vertex(v)
	st.generate_normals()
	st.generate_tangents()  # mismo formato que las cajas: así la fusión de mallas las junta bien
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _mat.tejado
	add_child(mi)

## Chimeneas exteriores de ladrillo pegadas a los muros de los dos extremos: suben desde el suelo y pasan por
## encima del tejado, con pecho escalonado y remate de piedra.
func _chimeneas_laterales() -> void:
	var r := house_rect
	var c := r.get_center()
	var cima := lvl_y(2) + 3.45 + 13.6
	for lado in [-1.0, 1.0]:
		var x: float = (r.position.x - 0.55) if lado < 0 else (r.end.x + 0.55)
		var z := c.y - 4.5
		box(Vector3(1.1, 7.0, 2.6), Vector3(x, 3.5, z), _mat.ladrillo, true, self)
		var pecho := box(Vector3(1.1, 1.2, 2.6), Vector3(x - lado * 0.0, 7.4, z), _mat.ladrillo, false, self)
		pecho.scale = Vector3(1, 1, 0.8)
		box(Vector3(1.0, cima - 7.6, 1.5), Vector3(x, 7.6 + (cima - 7.6) * 0.5, z), _mat.ladrillo, false, self)
		for hy in [lvl_y(1), lvl_y(2), cima - 1.0]:
			box(Vector3(1.2, 0.16, 1.7), Vector3(x, hy, z), _mat.cimiento, false, self, false)
		box(Vector3(1.3, 0.28, 1.8), Vector3(x, cima + 0.1, z), _mat.cimiento, false, self, false)
		for k in 3:
			cyl(0.13, 0.17, 0.55, Vector3(x, cima + 0.5, z - 0.45 + k * 0.45), _mat.terracota, self, 8)

## Cuerpo central que sobresale sobre la entrada: balcón volado sobre la veranda con arquería de madera
## tallada y barandilla; encima, un cuerpo saliente con ventana palladiana (arco de medio punto entre dos
## ventanas estrechas) y un gran hastial propio, más alto que los otros dos, con escamas, tablas caladas y
## cercha; y en lo alto del tejado, un mirador cuadrado acristalado con tejado a cuatro aguas y crestería.
func _frente_balcon() -> void:
	var r := house_rect
	var c := r.get_center()
	var tr: Material = _mat.piedra_clara
	var esc := _fachada_mat("Escamas", 0.5, Color(0.95, 0.95, 0.95))
	var x7 := cell_to_world("alta", 7, 0).x
	var x11 := cell_to_world("alta", 11, 0).x
	var cx := (x7 + x11) * 0.5
	var sal := 2.1                       # cuánto sobresale el cuerpo central
	var zf := r.end.y + sal
	var yb := lvl_y(1)                   # suelo del balcón
	var alto := 3.0
	var ye := yb + alto + 0.45           # arranque del cuerpo de arriba
	var y_alero := lvl_y(2) + 3.45
	# --- suelo del balcón volado (sobre la veranda), con canto moldurado y ménsulas debajo ---
	box(Vector3(x11 - x7 + 0.4, 0.22, sal + 0.1), Vector3(cx, yb - 0.11, r.end.y + sal * 0.5), _mat.madera_vieja, true, self, false)
	box(Vector3(x11 - x7 + 0.6, 0.14, 0.2), Vector3(cx, yb - 0.08, zf + 0.05), tr, false, self, false)
	for k in 6:
		var x := lerpf(x7 + 0.3, x11 - 0.3, k / 5.0)
		var m := box(Vector3(0.14, 0.45, 0.7), Vector3(x, yb - 0.4, zf - 0.35), tr, false, self, false)
		m.rotation.x = -0.4
	# --- arquería: cuatro columnas torneadas en el borde, arcos rebajados y friso calado ---
	var xs: Array[float] = []
	for k in 4:
		xs.append(lerpf(x7 + 0.15, x11 - 0.15, k / 3.0))
	var zc := zf - 0.15
	for x in xs:
		box(Vector3(0.36, 0.25, 0.36), Vector3(x, yb + 0.12, zc), tr, false, self, false)
		cyl(0.11, 0.13, alto - 0.6, Vector3(x, yb + 0.25 + (alto - 0.6) * 0.5, zc), tr, self, 10)
		for hy in [1.0, 2.0]:
			cyl(0.16, 0.16, 0.1, Vector3(x, yb + hy, zc), tr, self, 10)
		cyl(0.21, 0.13, 0.16, Vector3(x, yb + alto - 0.28, zc), tr, self, 10)
		box(Vector3(0.34, 0.12, 0.34), Vector3(x, yb + alto - 0.14, zc), tr, false, self, false)
		_static_cyl(0.15, alto, Vector3(x, yb + alto * 0.5, zc))
	for k in 3:
		var a: float = xs[k] + 0.2
		var b: float = xs[k + 1] - 0.2
		var m := (a + b) * 0.5
		var semi := (b - a) * 0.5
		for j in 10:
			var t0 := PI * j / 10.0
			var t1 := PI * (j + 1) / 10.0
			var p0 := Vector2(m - cos(t0) * semi, yb + alto - 0.1 + sin(t0) * 0.38)
			var p1 := Vector2(m - cos(t1) * semi, yb + alto - 0.1 + sin(t1) * 0.38)
			var seg := box(Vector3(p0.distance_to(p1) + 0.03, 0.12, 0.12), Vector3((p0.x + p1.x) * 0.5, (p0.y + p1.y) * 0.5, zc), tr, false, self, false)
			seg.rotation.z = atan2(p1.y - p0.y, p1.x - p0.x)
		var nh := int((b - a) / 0.13)
		for j in nh:
			var x := lerpf(a, b, (j + 0.5) / nh)
			var ay := yb + alto - 0.1 + sin(acos(clampf((x - m) / semi, -1, 1))) * 0.38
			var top := ye - 0.05
			if top - ay > 0.08:
				cyl(0.016, 0.016, top - ay, Vector3(x, (top + ay) * 0.5, zc), tr, self, 4)
	# --- barandilla del balcón: frente y costados ---
	var tramos := []
	for k in 3:
		tramos.append([Vector3(xs[k] + 0.2, yb, zc), Vector3(xs[k + 1] - 0.2, yb, zc)])
	tramos.append([Vector3(x7 + 0.15, yb, r.end.y + 0.15), Vector3(x7 + 0.15, yb, zc - 0.2)])
	tramos.append([Vector3(x11 - 0.15, yb, r.end.y + 0.15), Vector3(x11 - 0.15, yb, zc - 0.2)])
	for t in tramos:
		var a: Vector3 = t[0]
		var b: Vector3 = t[1]
		var l := a.distance_to(b)
		var m := (a + b) * 0.5
		var horiz := absf(a.z - b.z) < 0.01
		box(Vector3(l, 0.08, 0.12) if horiz else Vector3(0.12, 0.08, l), m + Vector3(0, 0.95, 0), tr, false, self, false)
		box(Vector3(l, 0.07, 0.1) if horiz else Vector3(0.1, 0.07, l), m + Vector3(0, 0.2, 0), tr, false, self, false)
		var nb := int(l / 0.15)
		for k in nb:
			var q := a.lerp(b, (k + 0.5) / nb)
			cyl(0.025, 0.04, 0.72, q + Vector3(0, 0.57, 0), tr, self, 6)
		_choque(Vector3(l, 1.4, 0.15) if horiz else Vector3(0.15, 1.4, l), m + Vector3(0, 0.7, 0))
	# --- cuerpo saliente de arriba, sobre la arquería, con ventana palladiana ---
	var ancho := x11 - x7 + 0.3
	box(Vector3(ancho, y_alero - ye, sal), Vector3(cx, (ye + y_alero) * 0.5, r.end.y + sal * 0.5), _mat.fachada, false, self)
	box(Vector3(ancho + 0.3, 0.26, sal + 0.15), Vector3(cx, ye - 0.05, r.end.y + sal * 0.5 + 0.05), tr, false, self, false)
	box(Vector3(ancho + 0.3, 0.2, sal + 0.15), Vector3(cx, y_alero - 0.1, r.end.y + sal * 0.5 + 0.05), tr, false, self, false)
	for s in [-1.0, 1.0]:
		box(Vector3(0.22, y_alero - ye, 0.22), Vector3(cx + s * ancho * 0.5, (ye + y_alero) * 0.5, zf), tr, false, self, false)
	var yv := ye + 0.75
	var hv := 2.2
	var vf := zf + 0.02
	# ventana central de medio punto
	box(Vector3(1.5, hv, 0.04), Vector3(cx, yv + hv * 0.5, vf), _mat.vidrio, false, self, false)
	var arco_v := cyl(0.75, 0.75, 0.04, Vector3(cx, yv + hv, vf), _mat.vidrio, self, 20)
	arco_v.rotation.x = PI * 0.5
	for j in 12:
		var t0 := PI * j / 12.0
		var t1 := PI * (j + 1) / 12.0
		var p0 := Vector2(cx - cos(t0) * 0.85, yv + hv + sin(t0) * 0.85)
		var p1 := Vector2(cx - cos(t1) * 0.85, yv + hv + sin(t1) * 0.85)
		var seg := box(Vector3(p0.distance_to(p1) + 0.03, 0.16, 0.12), Vector3((p0.x + p1.x) * 0.5, (p0.y + p1.y) * 0.5, vf + 0.04), tr, false, self, false)
		seg.rotation.z = atan2(p1.y - p0.y, p1.x - p0.x)
	box(Vector3(0.22, 0.32, 0.14), Vector3(cx, yv + hv + 0.88, vf + 0.06), tr, false, self, false)  # clave
	box(Vector3(0.04, hv + 0.7, 0.06), Vector3(cx, yv + (hv + 0.7) * 0.5, vf + 0.03), _mat.marco_ventana, false, self, false)
	box(Vector3(1.5, 0.04, 0.06), Vector3(cx, yv + hv * 0.55, vf + 0.03), _mat.marco_ventana, false, self, false)
	box(Vector3(1.5, 0.05, 0.06), Vector3(cx, yv + hv, vf + 0.03), _mat.marco_ventana, false, self, false)
	# ventanas estrechas a los lados y pilastras
	for s in [-1.0, 1.0]:
		var vx: float = cx + s * 1.55
		box(Vector3(0.65, hv * 0.85, 0.04), Vector3(vx, yv + hv * 0.425, vf), _mat.vidrio, false, self, false)
		box(Vector3(0.65, 0.04, 0.06), Vector3(vx, yv + hv * 0.5, vf + 0.03), _mat.marco_ventana, false, self, false)
		box(Vector3(0.95, 0.14, 0.18), Vector3(vx, yv + hv * 0.85 + 0.07, vf + 0.06), tr, false, self, false)
		for p in [-1.0, 1.0]:
			box(Vector3(0.14, hv + 0.2, 0.12), Vector3(cx + s * (0.83 + (0.0 if p * s < 0 else 1.13)), yv + (hv + 0.2) * 0.5 - 0.1, vf + 0.05), tr, false, self, false)
	box(Vector3(3.9, 0.12, 0.24), Vector3(cx, yv - 0.08, vf + 0.1), tr, false, self, false)
	# --- gran hastial central, más alto y adelantado ---
	var gw := 7.4
	var gh := 6.6
	var gz := zf - 1.6
	var hast := MeshInstance3D.new()
	var hm := PrismMesh.new()
	hm.size = Vector3(gw, gh, 3.2)
	hast.mesh = hm
	hast.material_override = _mat.fachada
	hast.position = Vector3(cx, y_alero + gh * 0.5, gz)
	add_child(hast)
	var es := MeshInstance3D.new()
	var em := PrismMesh.new()
	em.size = Vector3(gw * 0.75, gh * 0.75, 0.04)
	es.mesh = em
	es.material_override = esc
	es.position = Vector3(cx, y_alero + gh - gh * 0.375, gz + 1.62)
	add_child(es)
	box(Vector3(gw * 0.75 + 0.3, 0.16, 0.12), Vector3(cx, y_alero + gh * 0.25, gz + 1.66), tr, false, self, false)
	var tj := MeshInstance3D.new()
	var tm := PrismMesh.new()
	tm.size = Vector3(gw + 1.1, gh + 0.55, 3.7)
	tj.mesh = tm
	tj.material_override = _mat.tejado
	tj.position = Vector3(cx, y_alero + (gh + 0.55) * 0.5 - 0.05, gz - 0.35)
	add_child(tj)
	var ang := atan2(gh + 0.55, (gw + 1.1) * 0.5)
	var largo := sqrt(pow(gh + 0.55, 2) + pow((gw + 1.1) * 0.5, 2))
	for s in [-1.0, 1.0]:
		var tb := box(Vector3(largo, 0.4, 0.07), Vector3(cx + s * (gw + 1.1) * 0.25, y_alero + (gh + 0.55) * 0.5 - 0.3, gz + 1.7), tr, false, self, false)
		tb.rotation.z = -s * ang
		var n := int(largo / 0.5)
		for k in range(1, n):
			var t := float(k) / n
			var p := Vector3(cx + s * (gw + 1.1) * 0.5 * (1.0 - t), y_alero + (gh + 0.55) * t - 0.6, gz + 1.7)
			cyl(0.035, 0.05, 0.28, p, tr, self, 6)
	# ventana del ático en el hastial y cercha en el vértice
	var wy := y_alero + 1.6
	box(Vector3(1.0, 1.5, 0.04), Vector3(cx, wy + 0.75, gz + 1.63), _mat.vidrio, false, self, false)
	box(Vector3(0.04, 1.5, 0.06), Vector3(cx, wy + 0.75, gz + 1.66), _mat.marco_ventana, false, self, false)
	for s in [-1.0, 1.0]:
		box(Vector3(0.13, 1.7, 0.08), Vector3(cx + s * 0.57, wy + 0.75, gz + 1.68), tr, false, self, false)
	box(Vector3(1.35, 0.1, 0.18), Vector3(cx, wy - 0.05, gz + 1.7), tr, false, self, false)
	box(Vector3(1.4, 0.16, 0.14), Vector3(cx, wy + 1.62, gz + 1.69), tr, false, self, false)
	var ap := Vector3(cx, y_alero + gh + 0.2, gz + 1.72)
	box(Vector3(0.16, 1.8, 0.12), ap + Vector3(0, -0.9, 0), tr, false, self, false)
	box(Vector3(1.9, 0.14, 0.12), ap + Vector3(0, -1.65, 0), tr, false, self, false)
	cyl(0.09, 0.05, 0.35, ap + Vector3(0, -1.95, 0), tr, self, 8)
	box(Vector3(0.2, 0.45, 0.2), Vector3(cx, y_alero + gh + 0.8, gz + 1.5), tr, false, self, false)
	# --- mirador cuadrado en lo alto del tejado (sobre la cumbrera) ---
	var ycum := lvl_y(2) + 3.45 + 12.5
	var mc := Vector3(cx, ycum - 0.3, c.y)
	var lado := 3.4
	var hm2 := 2.6
	box(Vector3(lado, hm2, lado), mc + Vector3(0, hm2 * 0.5, 0), _mat.fachada, false, self)
	box(Vector3(lado + 0.3, 0.25, lado + 0.3), mc + Vector3(0, 0.1, 0), tr, false, self, false)
	box(Vector3(lado + 0.45, 0.22, lado + 0.45), mc + Vector3(0, hm2 + 0.05, 0), tr, false, self, false)
	for k in 4:
		var giro := PI * 0.5 * k
		var fuera := Vector3(sin(giro), 0, cos(giro))
		var lat := Vector3(cos(giro), 0, -sin(giro))
		for s in [-0.75, 0.75]:
			var p: Vector3 = mc + fuera * (lado * 0.5 + 0.02) + lat * s + Vector3(0, 1.35, 0)
			var v := box(Vector3(0.6, 1.5, 0.04), p, _mat.vidrio, false, self, false)
			v.rotation.y = giro
			var f := box(Vector3(0.6, 0.04, 0.06), p + Vector3(0, 0.15, 0) + fuera * 0.02, _mat.marco_ventana, false, self, false)
			f.rotation.y = giro
		for s in [-1.0, 0.0, 1.0]:
			var pp := box(Vector3(0.14, hm2 - 0.3, 0.1), mc + fuera * (lado * 0.5 + 0.04) + lat * s * 1.55 + Vector3(0, hm2 * 0.5, 0), tr, false, self, false)
			pp.rotation.y = giro
	cyl(0.0, lado * 0.82, 2.4, mc + Vector3(0, hm2 + 1.35, 0), _mat.tejado, self, 4).rotation.y = PI * 0.25
	cyl(0.08, 0.08, 0.2, mc + Vector3(0, hm2 + 2.6, 0), _mat.metal, self, 8)
	cyl(0.02, 0.04, 0.6, mc + Vector3(0, hm2 + 2.95, 0), _mat.metal, self, 6)

## Alrededores de la casa: arbustos crecidos, ortigas y helechos pegados a los cimientos y delante de la
## veranda, hierba alta y matojos por el jardín abandonado, árboles muertos, tocones, farolas de gas a los
## lados del camino de entrada (solo una encendida, temblando), dos estatuas y un banco viejo.
func _entorno_casa() -> void:
	var r := house_rect
	var rng := RandomNumberGenerator.new()
	rng.seed = 1888
	var cx := _portada.x if _portada != Vector3.INF else r.get_center().x
	var veranda := Rect2(cell_to_world("baja", 3, 0).x + 0.6, r.end.y, r.end.x - 3.1 - cell_to_world("baja", 3, 0).x - 0.6, 2.8)
	var torre := Rect2(r.position.x - 1.3, cell_to_world("baja", 0, 9).z - 1.3, 3 * CELL + 2.6, 3 * CELL + 2.6)
	# zonas que no se tocan: caminos, agua, edificios y la propia casa
	var evitar: Array[Rect2] = [r.grow(0.35), veranda.grow(0.3), Rect2(cx - 2.6, r.end.y, 5.2, 40.0)]
	for z in plan.exterior.zonas:
		var t: String = z[1]
		var nm: String = z[0]
		if nm.begins_with("Bosque") or nm.begins_with("Terrenos"):
			continue
		if t in ["camino", "agua", "edificio"] or nm.begins_with("Fuente") or nm.begins_with("Pozo"):
			evitar.append(Rect2(float(z[2]) * CELL, float(z[3]) * CELL, float(z[4]) * CELL, float(z[5]) * CELL).grow(0.6))
	var libre := func(p: Vector2) -> bool:
		if not grounds_rect.grow(-1.0).has_point(p):
			return false
		for e in evitar:
			if e.has_point(p):
				return false
		return true
	var plantas := {"shrub_01": [], "shrub_02": [], "shrub_03": [], "shrub_04": [], "nettle_plant": [], "fern_02": [], "grass_medium_01": [], "dry_branches_medium_01": []}
	var pon := func(nm: String, p: Vector2, s0: float, s1: float) -> void:
		var sc := rng.randf_range(s0, s1)
		plantas[nm].append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(sc, sc, sc)), Vector3(p.x, -0.02, p.y)))
	var arbustos := ["shrub_01", "shrub_02", "shrub_03", "shrub_04"]
	# 1) franja pegada a los cimientos, en los cuatro lados (y delante de la veranda)
	var franjas := [[Vector2(r.position.x, r.position.y - 1.0), Vector2(r.end.x, r.position.y - 1.0)],
		[Vector2(r.position.x - 1.0, r.position.y), Vector2(r.position.x - 1.0, r.end.y)],
		[Vector2(r.end.x + 1.0, r.position.y), Vector2(r.end.x + 1.0, r.end.y)],
		[Vector2(veranda.position.x, veranda.end.y + 1.0), Vector2(veranda.end.x, veranda.end.y + 1.0)]]
	for f in franjas:
		var a: Vector2 = f[0]
		var b: Vector2 = f[1]
		var l := a.distance_to(b)
		var u := 0.6
		while u < l:
			var p := a.lerp(b, u / l) + Vector2(rng.randf_range(-0.4, 0.4), rng.randf_range(-0.4, 0.4))
			u += rng.randf_range(1.0, 2.2)
			if absf(p.x - cx) < 2.6 and (p.y > r.end.y or p.y < r.position.y):
				continue  # la entrada y la puerta trasera
			if torre.has_point(p):
				continue
			var en_mirador := false
			for hm in huellas_miradores:
				if hm.grow(0.2).has_point(p):
					en_mirador = true
			if en_mirador:
				continue
			var cual := rng.randf()
			if cual < 0.55:
				pon.call(arbustos[rng.randi_range(0, 3)], p, 1.7, 2.8)
			elif cual < 0.75:
				pon.call("nettle_plant", p, 1.5, 2.3)
			else:
				pon.call("fern_02", p, 1.6, 2.5)
			for k in 2:
				pon.call("grass_medium_01", p + Vector2(rng.randf_range(-0.8, 0.8), rng.randf_range(-0.8, 0.8)), 1.5, 2.6)
	# alrededor de la torre: arbustos siguiendo el círculo
	var tc := cell_to_world("baja", 0, 9) + Vector3(3.0, 0, 5.0)
	for k in 9:
		var ang := PI * 0.35 + PI * 1.1 * k / 8.0
		var p := Vector2(tc.x, tc.z) + Vector2(cos(ang), sin(ang)) * rng.randf_range(5.0, 5.6)
		if not r.grow(0.3).has_point(p):
			pon.call(arbustos[rng.randi_range(0, 3)], p, 1.8, 2.8)
	# 2) jardín abandonado: matas de hierba alta, ortigas y ramas secas por todo el terreno
	var n := 0
	var intentos := 0
	var total := 520 if quality >= 2 else 320
	while n < total and intentos < total * 6:
		intentos += 1
		var p := Vector2(rng.randf_range(grounds_rect.position.x, grounds_rect.end.x), rng.randf_range(grounds_rect.position.y, grounds_rect.end.y))
		if not libre.call(p):
			continue
		n += 1
		var cual := rng.randf()
		if cual < 0.7:
			pon.call("grass_medium_01", p, 1.5, 2.8)
		elif cual < 0.85:
			pon.call("nettle_plant", p, 1.4, 2.2)
		elif cual < 0.93:
			pon.call(arbustos[rng.randi_range(0, 3)], p, 1.4, 2.4)
		else:
			pon.call("dry_branches_medium_01", p, 0.8, 1.3)
	for nm in plantas:
		_multi_planta(nm, plantas[nm])
	# 3) árboles muertos y tocones cerca de la casa
	var muertos := ["muerto_roble", "muerto_fresno", "muerto_roble_2", "muerto_alamo"]
	var sitios := [Vector2(r.position.x - 7.0, r.end.y + 9.0), Vector2(r.end.x + 7.5, r.end.y + 7.0), Vector2(r.position.x - 6.0, r.position.y + 6.0), Vector2(cx + 13.0, r.end.y + 16.0), Vector2(r.end.x + 6.0, r.position.y + 4.0)]
	for k in sitios.size():
		var p: Vector2 = sitios[k]
		if not libre.call(p):
			continue
		var malla := _malla_glb("res://zarek/arboles/%s.glb" % muertos[k % muertos.size()])
		if malla == null:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = malla
		var sc := rng.randf_range(1.1, 1.5)
		mi.transform = Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(sc, sc, sc)), Vector3(p.x, -0.05, p.y))
		add_child(mi)
		_static_cyl(0.4, 4.0, Vector3(p.x, 2.0, p.y))
	for p in [Vector2(cx - 9.0, r.end.y + 12.0), Vector2(cx + 8.0, r.end.y + 5.5), Vector2(r.position.x - 3.5, r.end.y + 4.0)]:
		if libre.call(p):
			_prop("tree_stump_0%d" % rng.randi_range(1, 2), Vector3(p.x, 0, p.y), rng.randf() * TAU, 1.2)
	# 4) farolas de gas a los dos lados del camino de entrada; solo una sigue encendida
	var enc := 0
	for k in 3:
		for s in [-1.0, 1.0]:
			var p := Vector3(cx + s * 3.3, 0, r.end.y + 6.0 + k * 8.0)
			if not grounds_rect.has_point(Vector2(p.x, p.z)):
				continue
			var f := _prop("street_lamp_01", p, (PI * 0.5) * -s, 1.0)
			if f != null and enc == 0 and k == 1 and s > 0:
				enc += 1
				var luz := OmniLight3D.new()
				luz.light_color = Color(1.0, 0.68, 0.35)
				luz.light_energy = 1.1
				luz.omni_range = 7.0
				luz.position = p + Vector3(0, 3.0, 0)
				add_child(luz)
				_luz_farola = luz
	# 5) dos estatuas a los lados del camino y un banco viejo junto a la torre
	for s in [-1.0, 1.0]:
		var p := Vector3(cx + s * 5.5, 0, r.end.y + 12.0)
		if libre.call(Vector2(p.x, p.z)):
			_prop("gothic_statue", p, 0.0, 1.0)
	var pb := Vector2(tc.x - 2.0, tc.z + 7.0)
	if libre.call(pb):
		_prop("painted_wooden_bench", Vector3(pb.x, 0, pb.y), PI * 0.15, 1.0)

var _luz_farola: OmniLight3D

## Tejado más rico: dos hastiales también en la fachada de atrás (iguales a los de delante), hastiales
## acabados en los dos extremos del tejado (pared con escamas, ventanas, tablas caladas y cercha) y bandas
## de pizarra en escama a lo largo de los faldones, como en los tejados victorianos de pizarra de colores.
func _techo_rico() -> void:
	var r := house_rect
	var c := r.get_center()
	var y := lvl_y(2) + 3.45
	var tr: Material = _mat.piedra_clara
	var esc := _fachada_mat("Escamas", 0.5, Color(0.95, 0.95, 0.95))
	var esc_tejado := _fachada_mat("Escamas", 0.45, Color(0.6, 0.62, 0.68))
	esc_tejado.set_shader_parameter("suciedad", 1.3)
	esc_tejado.set_shader_parameter("rugosidad_min", 0.85)
	esc_tejado.set_shader_parameter("especular", 0.15)
	# --- hastiales de atrás ---
	var zb := r.position.y
	for sx in [-r.size.x * 0.22, r.size.x * 0.2]:
		var gx: float = c.x + sx
		var g := MeshInstance3D.new()
		var gp := PrismMesh.new()
		gp.size = Vector3(13.0, 7.0, 4.0)
		g.mesh = gp
		g.material_override = _mat.fachada
		g.position = Vector3(gx, y + 3.5, zb + 1.0)
		add_child(g)
		var gr := MeshInstance3D.new()
		var grm := PrismMesh.new()
		grm.size = Vector3(14.5, 7.8, 5.0)
		gr.mesh = grm
		gr.material_override = _mat.tejado
		gr.position = Vector3(gx, y + 3.9, zb + 1.6)
		add_child(gr)
		_adorno_hastial(Vector3(gx, y, zb - 1.0), PI, 13.0, 7.0, 7.25, 7.8, esc)
	# --- hastiales en los dos extremos del tejado principal ---
	var ancho := r.size.y + 1.5
	for lado in [-1.0, 1.0]:
		var x: float = (r.position.x - 0.78) if lado < 0 else (r.end.x + 0.78)
		var w := MeshInstance3D.new()
		var wm := PrismMesh.new()
		wm.size = Vector3(ancho - 2.4, 12.5 - 1.4, 0.08)
		w.mesh = wm
		w.material_override = _mat.fachada
		w.position = Vector3(x, y + (12.5 - 1.4) * 0.5 + 0.05, c.y)
		w.rotation.y = PI * 0.5
		add_child(w)
		_adorno_hastial(Vector3(x, y, c.y), lado * PI * 0.5, ancho - 2.4, 12.5 - 1.4, ancho * 0.5, 12.5, esc, true)
	# --- bandas de pizarra en escama en los dos faldones largos ---
	var mitad := r.size.y * 0.5 + 0.75
	var ang := atan2(12.5, mitad)
	var largo := sqrt(mitad * mitad + 12.5 * 12.5)
	for frente in [1.0, -1.0]:
		for t in [0.22, 0.5, 0.74]:
			var zc: float = c.y + frente * mitad * (1.0 - t)
			var yc: float = y + 12.5 * t
			var nrm := Vector3(0, cos(ang), frente * sin(ang))
			var banda := box(Vector3(r.size.x + 1.4, 0.02, largo * 0.09), Vector3(c.x, yc, zc) + nrm * 0.04, esc_tejado, false, self, false)
			banda.rotation.x = frente * ang

## Adornos de un hastial: escamas en la parte alta, moldura, dos ventanas del ático, tablas de alero caladas
## con colgantes, cercha en el vértice y remate. `p`: centro de la base del hastial en su cara exterior;
## `giro`: hacia dónde mira (0 = +z); `w`/`h`: triángulo de pared; `semi`/`alto`: faldones del tejado.
func _adorno_hastial(p: Vector3, giro: float, w: float, h: float, semi: float, alto: float, esc: Material, grande := false) -> void:
	var tr: Material = _mat.piedra_clara
	var nd := Node3D.new()
	nd.position = p
	nd.rotation.y = giro
	add_child(nd)
	var he := h * 0.72
	var es := MeshInstance3D.new()
	var em := PrismMesh.new()
	em.size = Vector3(w * he / h, he, 0.04)
	es.mesh = em
	es.material_override = esc
	es.position = Vector3(0, h - he * 0.5, 0.05)
	nd.add_child(es)
	box(Vector3(w * he / h + 0.3, 0.16, 0.12), Vector3(0, h - he, 0.08), tr, false, nd, false)
	# ventanas del ático
	var wy := 1.3 if not grande else 1.8
	for vx in ([-0.85, 0.85] if not grande else [-2.2, -0.75, 0.75, 2.2]):
		var c := Vector3(vx, wy, 0.06)
		box(Vector3(0.95, 1.55, 0.04), c + Vector3(0, 0.78, 0), _mat.vidrio, false, nd, false)
		box(Vector3(0.04, 1.55, 0.06), c + Vector3(0, 0.78, 0.03), _mat.marco_ventana, false, nd, false)
		box(Vector3(0.95, 0.04, 0.06), c + Vector3(0, 0.95, 0.03), _mat.marco_ventana, false, nd, false)
		for s in [-1.0, 1.0]:
			box(Vector3(0.12, 1.75, 0.08), c + Vector3(s * 0.53, 0.78, 0.05), tr, false, nd, false)
		box(Vector3(1.25, 0.1, 0.18), c + Vector3(0, -0.04, 0.08), tr, false, nd, false)
		box(Vector3(1.3, 0.16, 0.14), c + Vector3(0, 1.66, 0.07), tr, false, nd, false)
	# tablas de alero caladas con colgantes
	var ang := atan2(alto, semi)
	var largo := sqrt(alto * alto + semi * semi)
	for s in [-1.0, 1.0]:
		var tb := box(Vector3(largo, 0.42, 0.07), Vector3(s * semi * 0.5, alto * 0.5 - 0.32, 0.14), tr, false, nd, false)
		tb.rotation.z = -s * ang
		var n := int(largo / 0.55)
		for k in range(1, n):
			var t := float(k) / n
			cyl(0.035, 0.05, 0.3, Vector3(s * semi * (1.0 - t), alto * t - 0.6, 0.14), tr, nd, 6)
		box(Vector3(0.35, 0.8, 0.1), Vector3(s * (semi - 0.15), -0.2, 0.14), tr, false, nd, false)
	# cercha en el vértice y remate
	var ap := Vector3(0, alto - 0.35, 0.16)
	box(Vector3(0.16, 2.0, 0.12), ap + Vector3(0, -1.0, 0), tr, false, nd, false)
	box(Vector3(2.0 * 2.0 * semi / alto, 0.14, 0.12), ap + Vector3(0, -1.85, 0), tr, false, nd, false)
	cyl(0.09, 0.05, 0.4, ap + Vector3(0, -2.2, 0), tr, nd, 8)
	box(Vector3(0.18, 0.4, 0.18), Vector3(0, alto + 0.25, -0.1), tr, false, nd, false)

var _portada := Vector3.INF  # centro de la puerta principal (lo fija _puerta_principal)

## Material con el shader de la torre (mapeado por UV y recortado dentro de la casa) para piezas curvas que
## se meten en las esquinas de la casa sin asomar en las salas.
func _mat_curvo(carpeta: String, color: Vector3, uv: Vector2) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://zarek/torre.gdshader")
	var base := "res://zarek/texturas/%s/" % carpeta
	m.set_shader_parameter("albedo_tex", load(base + "color.jpg"))
	m.set_shader_parameter("normal_tex", load(base + "normal.jpg"))
	m.set_shader_parameter("rough_tex", load(base + "rough.jpg"))
	m.set_shader_parameter("color", color)
	m.set_shader_parameter("uv_escala", uv)
	m.set_shader_parameter("casa", Vector4(house_rect.position.x, house_rect.position.y, house_rect.size.x, house_rect.size.y))
	return m

## Pared invisible de colisión (barandillas por las que no se debe saltar).
func _choque(size: Vector3, pos: Vector3) -> void:
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	sb.add_child(cs)
	sb.position = pos
	add_child(sb)

## Veranda victoriana a lo largo de la fachada principal (de la torre al torreón): suelo de tablas, columnas
## torneadas con ménsulas caladas, friso de husillos, tejadillo de pizarra, barandilla de balaustres y, sobre la
## escalinata de la entrada, un frontón con escamas y pináculo. Columnas y barandilla tienen colisión.
func _portico() -> void:
	var r := house_rect
	var tr: Material = _mat.piedra_clara
	var cx := _portada.x if _portada != Vector3.INF else r.get_center().x
	var x0 := cell_to_world("baja", 3, 0).x + 0.6     # justo después de la torre
	var x1 := r.end.x - 3.1                            # antes del torreón de la esquina
	var fondo := 2.8
	var z0 := r.end.y
	var z1 := r.end.y + fondo
	var zc := z1 - 0.25
	var alto := 3.35
	# suelo de tablas sobre un zócalo de piedra
	box(Vector3(x1 - x0, 0.12, fondo), Vector3((x0 + x1) * 0.5, 0.06, (z0 + z1) * 0.5), _mat.madera_vieja, true, self, false)
	box(Vector3(x1 - x0 + 0.1, 0.1, 0.14), Vector3((x0 + x1) * 0.5, 0.05, z1 + 0.02), _mat.cimiento, false, self, false)
	# escalones anchos delante de la entrada
	for k in 2:
		box(Vector3(4.2 - k * 0.4, 0.06, 0.4), Vector3(cx, 0.03 + k * 0.0, z1 + 0.25 + (1 - k) * 0.35), _mat.cimiento, true, self, false)
	# columnas: cada 2,4 m, dejando libre el paso de la entrada
	var xs: Array[float] = []
	var n := int((x1 - x0) / 2.4)
	for k in n + 1:
		var x := lerpf(x0 + 0.2, x1 - 0.2, float(k) / n)
		if absf(x - cx) < 2.7:
			continue  # la entrada lleva su propio par de columnas
		xs.append(x)
	for x in xs:
		box(Vector3(0.36, 0.3, 0.36), Vector3(x, 0.27, zc), tr, false, self, false)
		cyl(0.11, 0.13, alto - 0.75, Vector3(x, 0.42 + (alto - 0.75) * 0.5, zc), tr, self, 10)
		for hy in [1.1, 2.3]:
			cyl(0.16, 0.16, 0.12, Vector3(x, hy, zc), tr, self, 10)
		cyl(0.2, 0.13, 0.16, Vector3(x, alto - 0.24, zc), tr, self, 10)
		box(Vector3(0.34, 0.12, 0.34), Vector3(x, alto - 0.1, zc), tr, false, self, false)
		_static_cyl(0.15, alto, Vector3(x, alto * 0.5, zc))
		# ménsulas caladas a los dos lados del capitel
		for s in [-1.0, 1.0]:
			var m1 := box(Vector3(0.62, 0.08, 0.06), Vector3(x + s * 0.24, alto - 0.42, zc), tr, false, self, false)
			m1.rotation.z = s * 0.7
			box(Vector3(0.06, 0.4, 0.06), Vector3(x + s * 0.42, alto - 0.26, zc), tr, false, self, false)
	# vigas, friso de husillos y tejadillo
	box(Vector3(x1 - x0 + 0.3, 0.24, 0.2), Vector3((x0 + x1) * 0.5, alto + 0.08, zc), tr, false, self, false)
	box(Vector3(x1 - x0, 0.06, 0.08), Vector3((x0 + x1) * 0.5, alto - 0.5, zc), tr, false, self, false)
	var nh := int((x1 - x0) / 0.14)
	for k in nh:
		var x := lerpf(x0, x1, (k + 0.5) / nh)
		var hus := cyl(0.018, 0.018, 0.42, Vector3(x, alto - 0.26, zc), tr, self, 5)
		hus.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var techo := box(Vector3(x1 - x0 + 0.6, 0.14, fondo + 0.7), Vector3((x0 + x1) * 0.5, alto + 0.45, (z0 + z1) * 0.5 + 0.2), _mat.tejado, false, self)
	techo.rotation.x = 0.16
	var cielo := box(Vector3(x1 - x0, 0.04, fondo), Vector3((x0 + x1) * 0.5, alto + 0.22, (z0 + z1) * 0.5), _mat.madera_clara, false, self, false)
	cielo.rotation.x = 0.16
	box(Vector3(x1 - x0 + 0.6, 0.22, 0.06), Vector3((x0 + x1) * 0.5, alto + 0.04, z1 + 0.6), tr, false, self, false)
	# barandilla de balaustres entre columnas (con hueco en la entrada) y por los dos costados
	var tramos: Array = []
	var bordes: Array[float] = [x0]
	bordes.append_array(xs)
	bordes.append(x1)
	for k in bordes.size() - 1:
		var a: float = bordes[k]
		var b: float = bordes[k + 1]
		if a < cx and b > cx:
			continue  # la entrada
		tramos.append([Vector3(a + 0.18, 0, zc), Vector3(b - 0.18, 0, zc)])
	tramos.append([Vector3(x0, 0, z0 + 0.2), Vector3(x0, 0, zc)])
	tramos.append([Vector3(x1, 0, z0 + 0.2), Vector3(x1, 0, zc)])
	for t in tramos:
		var a: Vector3 = t[0]
		var b: Vector3 = t[1]
		var l := a.distance_to(b)
		if l < 0.3:
			continue
		var m := (a + b) * 0.5
		var horiz := absf(a.z - b.z) < 0.01
		box(Vector3(l, 0.07, 0.1) if horiz else Vector3(0.1, 0.07, l), m + Vector3(0, 0.95, 0), tr, false, self, false)
		box(Vector3(l, 0.06, 0.08) if horiz else Vector3(0.08, 0.06, l), m + Vector3(0, 0.25, 0), tr, false, self, false)
		var nb := int(l / 0.16)
		for k in nb:
			var q := a.lerp(b, (k + 0.5) / nb)
			var bal := cyl(0.025, 0.035, 0.68, q + Vector3(0, 0.6, 0), tr, self, 6)
			bal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_choque(Vector3(l, 1.4, 0.15) if horiz else Vector3(0.15, 1.4, l), m + Vector3(0, 0.7, 0))
	for s in [-1.0, 1.0]:
		var x: float = cx + s * 1.5
		box(Vector3(0.4, 0.3, 0.4), Vector3(x, 0.27, zc), tr, false, self, false)
		cyl(0.13, 0.15, alto - 0.75, Vector3(x, 0.42 + (alto - 0.75) * 0.5, zc), tr, self, 10)
		cyl(0.22, 0.15, 0.16, Vector3(x, alto - 0.24, zc), tr, self, 10)
		_static_cyl(0.16, alto, Vector3(x, alto * 0.5, zc))
	# farolillo colgado sobre la entrada
	cyl(0.012, 0.012, 0.5, Vector3(cx, alto - 0.15, z1 - 0.9), _mat.metal, self, 4)
	cyl(0.1, 0.14, 0.3, Vector3(cx, alto - 0.55, z1 - 0.9), _mat.ventana_luz, self, 6)
	_torreon()

## Torreón de esquina (este): torre redonda volada desde el primer piso sobre una ménsula de piedra, con
## ventanas altas, banda de escamas y un chapitel cónico muy esbelto con pináculo.
func _torreon() -> void:
	var r := house_rect
	var tr: Material = _mat.piedra_clara
	var rc := 2.3
	var cen := Vector3(r.end.x + 0.5, 0, r.end.y + 0.5)
	var y0 := lvl_y(1) - 0.2
	var y1 := lvl_y(2) + 3.45 + 1.2
	var tablas := _mat_curvo("TablasPintadas", Vector3(0.7, 0.7, 0.7), Vector2(TAU * rc / 3.0, (y1 - y0) / 3.0))
	var moldura := _mat_curvo("Plaster007", Vector3(0.46, 0.44, 0.4), Vector2(4.0, 1.0))
	var esc := _mat_curvo("Escamas", Vector3(0.85, 0.85, 0.85), Vector2(TAU * rc / 2.0, 2.2 / 1.25))
	var cuerpo := cyl(rc, rc, y1 - y0, cen + Vector3(0, (y0 + y1) * 0.5, 0), tablas, self, 32)
	cuerpo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# ménsula: cono invertido con anillos que lo sostiene sobre la planta baja
	# ménsula escalonada: anillos que se estrechan hacia abajo y acaban en un colgante torneado
	var radios := [rc + 0.15, rc - 0.25, rc - 0.75, rc - 1.3, rc - 1.75]
	for k in radios.size():
		var rk: float = radios[k]
		cyl(rk, rk, 0.2, cen + Vector3(0, y0 - 0.1 - k * 0.32, 0), moldura, self, 32)
		if k < radios.size() - 1:
			cyl(rk - 0.05, float(radios[k + 1]), 0.12, cen + Vector3(0, y0 - 0.26 - k * 0.32, 0), moldura, self, 32)
	cyl(0.22, 0.32, 0.25, cen + Vector3(0, y0 - 1.75, 0), moldura, self, 12)
	cyl(0.04, 0.2, 0.45, cen + Vector3(0, y0 - 2.08, 0), moldura, self, 12)
	# banda de escamas arriba, molduras y ménsulas bajo el alero
	cyl(rc + 0.04, rc + 0.04, 2.2, cen + Vector3(0, y1 - 1.1, 0), esc, self, 32)
	for hy in [lvl_y(2) - 0.05, y1 - 2.25, y1 - 0.05]:
		cyl(rc + 0.12, rc + 0.12, 0.16, cen + Vector3(0, hy, 0), moldura, self, 32)
	# ventanas en la parte que mira afuera (primer piso y ático)
	for lv in [1, 2]:
		for k in 8:
			var a := TAU * k / 8.0 + PI / 8.0
			var p := cen + Vector3(cos(a) * (rc + 0.03), lvl_y(lv) + 1.75, sin(a) * (rc + 0.03))
			if r.grow(0.2).has_point(Vector2(p.x, p.z)):
				continue
			var nd := Node3D.new()
			nd.position = p
			nd.rotation.y = -a + PI * 0.5
			add_child(nd)
			box(Vector3(0.7, 1.7 if lv == 1 else 1.3, 0.05), Vector3.ZERO, _mat.vidrio, false, nd, false)
			box(Vector3(0.04, 1.7 if lv == 1 else 1.3, 0.07), Vector3(0, 0, 0.02), _mat.moldura, false, nd, false)
			for s in [-1.0, 1.0]:
				box(Vector3(0.1, 1.95 if lv == 1 else 1.5, 0.1), Vector3(s * 0.4, 0, 0.04), tr, false, nd, false)
			box(Vector3(0.95, 0.12, 0.16), Vector3(0, (1.0 if lv == 1 else 0.8), 0.06), tr, false, nd, false)
			box(Vector3(0.9, 0.08, 0.18), Vector3(0, -(0.9 if lv == 1 else 0.7), 0.08), tr, false, nd, false)
	# chapitel cónico con ménsulas, remate y aguja
	for k in 14:
		var a := TAU * k / 14.0
		var p := cen + Vector3(cos(a) * (rc + 0.25), y1 - 0.25, sin(a) * (rc + 0.25))
		if r.grow(-0.2).has_point(Vector2(p.x, p.z)):
			continue
		var men := box(Vector3(0.45, 0.3, 0.1), p, tr, false, self, false)
		men.rotation.y = -a
	cyl(0.0, rc + 0.6, 5.0, cen + Vector3(0, y1 + 2.5, 0), _mat.tejado, self, 28)
	cyl(0.1, 0.1, 0.22, cen + Vector3(0, y1 + 5.0, 0), _mat.metal, self, 10)

# ---------------- exterior ----------------
func _exterior() -> void:
	var ex: Dictionary = plan.exterior
	var W := float(ex.w) * CELL
	var H := float(ex.h) * CELL
	# el bosque se extiende 86 m por cada lado (unas 3 veces la superficie del plano) y el arroyo lo cruza entero
	var E := 36.0 * CELL
	bosque_rect = Rect2(-E, -E, W + 2.0 * E, H + 2.0 * E)
	if not ex.has("_ampliado"):
		ex["_ampliado"] = true
		for z in ex.zonas:
			if String(z[0]).begins_with("Bosque"):
				z[2] = -36; z[3] = -36; z[4] = int(ex.w) + 72; z[5] = int(ex.h) + 72
			elif String(z[0]) == "Arroyo":
				z[2] = -36; z[4] = int(ex.w) + 72
	# el suelo del bosque no pasa por debajo de la casa (si no, tapa la escalera del sótano)
	# cauces de agua: el suelo no pasa por encima (el agua tiene fondo y orillas de verdad)
	var cauces: Array = [house_rect]
	for z in ex.zonas:
		if String(z[0]) in ["Arroyo", "Estanque"]:
			cauces.append(Rect2(float(z[2]) * CELL, float(z[3]) * CELL, float(z[4]) * CELL, float(z[5]) * CELL).grow(1.2))
	for gr in _split_holes(bosque_rect, cauces):
		var grr: Rect2 = gr
		var ground := box(Vector3(grr.size.x, 0.4, grr.size.y), Vector3(grr.get_center().x, -0.2, grr.get_center().y), _mat.bosque, true, self, false)
		ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for z in ex.zonas:
		var name: String = z[0]
		var t: String = z[1]
		var r := Rect2(float(z[2]) * CELL, float(z[3]) * CELL, float(z[4]) * CELL, float(z[5]) * CELL)
		if name.begins_with("Terrenos"):
			grounds_rect = r
			for q in _split_holes(r, cauces):  # sin tapar la casa ni el estanque
				var qr: Rect2 = q
				box(Vector3(qr.size.x, 0.05, qr.size.y), Vector3(qr.get_center().x, 0.01, qr.get_center().y), _mat.cesped, false, self, false)
			_stone_wall(r)
		elif t == "camino":
			if name.begins_with("Huerto"):
				_huerto(r)
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
				# el río: la superficie es más ancha que el cauce; la orilla irregular la corta el propio terreno
				pl.size = Vector2(r.size.x, r.size.y + (2.0 if es_rio else 0.0))
				pl.subdivide_width = int(r.size.x / 2.0)
				pl.subdivide_depth = 4
				sup.mesh = pl
				sup.material_override = _mat_agua(es_rio)
				sup.position = Vector3(r.get_center().x, -0.28, r.get_center().y)
				sup.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				sup.set_meta("dyn", true)
				add_child(sup)
				if es_rio:
					_cauce_natural(r.grow(1.2))
					_hojas_rio(r)
					_vida_rio(r)
					_orillas_rio(r.grow(1.2))
					(sup.material_override as ShaderMaterial).set_shader_parameter("borde", 0.32)
				else:
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
	_fronteras()
	var tz := Time.get_ticks_msec()
	_trees(W, H)
	print("ZAREK   bosque %d ms" % (Time.get_ticks_msec() - tz))

func _zone(name: String) -> Rect2:
	for z in plan.exterior.zonas:
		if z[0] == name:
			return Rect2(float(z[2]) * CELL, float(z[3]) * CELL, float(z[4]) * CELL, float(z[5]) * CELL)
	return Rect2()

## El portón de la finca: sus dos hojas (ZarekHuida las cierra con una cadena al entrar en la casa).
var porton_hojas: Array = []
var porton_pos := Vector3.ZERO
var porton_ancho := 6.0
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
			porton_pos = Vector3((gate_x0 + gate_x1) * 0.5, 0, a.y)
			porton_ancho = gate_x1 - gate_x0
			for side in [-1.0, 1.0]:
				var gp := Node3D.new()
				add_child(gp)
				gp.position = Vector3(gate_x0 if side < 0 else gate_x1, 0, a.y)
				gp.rotation.y = side * 1.9
				gp.set_meta("abierta", side * 1.9)
				porton_hojas.append(gp)
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
	# de cada taza (salvo la pila de abajo) cae una cortina de agua hasta el nivel de la siguiente; el agua de abajo
	# hace anillos y espuma donde cae
	var radios_caida: Array = []
	for i in range(ks.size() - 1, 0, -1):
		if float(niveles[ks[i]]) <= 2.8 and (float(ks[i]) - float(ks[i - 1])) / 10.0 >= 0.3:
			radios_caida.append(float(niveles[ks[i]]) + 0.2)
	while radios_caida.size() < 4:
		radios_caida.append(0.0)
	agua.set_shader_parameter("ondas_centro", Vector2(c.x, c.z))
	agua.set_shader_parameter("ondas_radios", Vector4(radios_caida[0], radios_caida[1], radios_caida[2], radios_caida[3]))
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
		m.roughness = 0.3
		m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		q.material = m
		_gota = q
	return _gota

## Cauce hundido: fondo de barro y piedras a -0,9 m y orillas en pendiente (se puede salir andando).
# ---------------- río natural ----------------
var _rio_nz: Array = []
## Centro y medio ancho del agua del río en una x (orillas que serpentean y cambian de ancho).
func _rio_forma(r: Rect2, x: float) -> Vector2:
	if _rio_nz.is_empty():
		for k in 3:
			var n := FastNoiseLite.new()
			n.seed = 300 + k
			n.frequency = 0.035 + k * 0.02
			_rio_nz.append(n)
	var c: float = r.get_center().y + (_rio_nz[0] as FastNoiseLite).get_noise_1d(x) * 0.9
	var hw: float = r.size.y * 0.5 - 1.7 + (_rio_nz[1] as FastNoiseLite).get_noise_1d(x) * 0.7
	return Vector2(c, hw)

## Cauce de río natural: una sola malla de terreno con orillas redondeadas que serpentean, fondo hondo en el
## centro y bancos de barro; el agua (a −0,28) la corta el terreno, así la orilla no es una línea recta.
func _cauce_natural(r: Rect2) -> void:
	var fondo := -0.95
	var paso := 1.0
	var nx := int(r.size.x / paso) + 1
	var nz := 18
	var ruido := FastNoiseLite.new()
	ruido.seed = 77
	ruido.frequency = 0.4
	var pts := []
	for ix in nx + 1:
		var x := r.position.x + minf(ix * paso, r.size.x)
		var f := _rio_forma(r, x)
		var fila := []
		for iz in nz + 1:
			var v := float(iz) / nz
			var z := lerpf(r.position.y, r.end.y, v)
			var y := 0.0
			if iz > 0 and iz < nz:
				# distancia al centro relativa al ancho del agua + talud de 1,3 m
				var t := absf(z - f.x) / (f.y + 1.3)
				var perfil := 1.0 - smoothstep(0.55, 1.0, t)
				y = fondo * pow(perfil, 0.7) + ruido.get_noise_2d(x, z) * 0.06 * perfil
				# al borde del hueco del suelo vuelve a 0 sin escalón
				var borde := minf(z - r.position.y, r.end.y - z)
				y *= smoothstep(0.0, 0.6, borde)
			fila.append(Vector3(x, y, z))
		pts.append(fila)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ix in nx:
		for iz in nz:
			var a: Vector3 = pts[ix][iz]
			var b: Vector3 = pts[ix + 1][iz]
			var c: Vector3 = pts[ix][iz + 1]
			var d: Vector3 = pts[ix + 1][iz + 1]
			st.add_vertex(a); st.add_vertex(b); st.add_vertex(c)
			st.add_vertex(b); st.add_vertex(d); st.add_vertex(c)
	st.generate_normals()
	var malla := st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = malla
	mi.material_override = _mat.barro
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta("dyn", true)
	add_child(mi)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = malla.create_trimesh_shape()
	sb.add_child(cs)
	add_child(sb)
	# cantos rodados en el fondo
	for k in int(r.size.x / 3.0):
		var x := _rng.randf_range(r.position.x, r.end.x)
		var f := _rio_forma(r, x)
		var z := f.x + _rng.randf_range(-f.y, f.y) * 0.8
		_prop("boulder_01", Vector3(x, fondo - 0.08, z), _rng.randf() * TAU, _rng.randf_range(0.15, 0.4), false)

## Orillas del río: vegetación espesa siguiendo la orilla irregular (juncos y hierba en el agua somera, helechos,
## ortigas y arbustos arriba) y rocas medio hundidas en la línea del agua.
func _orillas_rio(r: Rect2) -> void:
	var cerca := {"veg_cattail_plant": [], "grass_medium_01": [], "grass_medium_02": []}
	var arriba := {"fern_02": [], "veg_3d_fern_01": [], "nettle_plant": [], "shrub_03": [], "grass_medium_01": [], "dandelion_01": [], "celandine_01": []}
	var rocas: Array = []
	var musgo: Array = []
	var x := r.position.x
	var puente_x := _zone("Puente viejo").get_center().x
	while x < r.end.x:
		var f := _rio_forma(r, x)
		if absf(x - puente_x) < 2.8:
			x += 0.55
			continue
		for lado in [-1.0, 1.0]:
			# en el agua somera y la misma orilla: juncos y hierba
			for k in 2:
				var d := f.y + _rng.randf_range(-0.15, 0.6)
				var nm: String = (cerca.keys() as Array)[_rng.randi_range(0, cerca.size() - 1)]
				var sc := _rng.randf_range(0.8, 1.4)
				var yy := -0.3 if d < f.y + 0.2 else -0.15
				(cerca[nm] as Array).append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(sc, sc, sc)), Vector3(x + _rng.randf_range(-0.3, 0.3), yy, f.x + lado * d)))
			# arriba del talud
			for k in 2:
				var d2 := f.y + _rng.randf_range(1.2, 3.2)
				var nm2: String = (arriba.keys() as Array)[_rng.randi_range(0, arriba.size() - 1)]
				var sc2 := _rng.randf_range(0.8, 1.5)
				(arriba[nm2] as Array).append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(sc2, sc2, sc2)), Vector3(x + _rng.randf_range(-0.3, 0.3), -0.02, f.x + lado * d2)))
			if _rng.randf() < 0.35:
				var sr := _rng.randf_range(0.35, 1.0)
				rocas.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(sr, sr * _rng.randf_range(0.6, 1.0), sr)), Vector3(x, -0.55, f.x + lado * (f.y + _rng.randf_range(-0.4, 0.4)))))
			if _rng.randf() < 0.08:
				var sm := _rng.randf_range(0.25, 0.4)
				musgo.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(sm, sm, sm)), Vector3(x, -0.4, f.x + lado * (f.y + 0.6))))
		x += 0.55
	for nm in cerca:
		_multi_planta(nm, cerca[nm])
	for nm in arriba:
		_multi_planta(nm, arriba[nm])
	_multi_planta("boulder_01", rocas)
	_multi_planta("rock_moss_set_02", musgo)

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
		var k := Vector2i(floori(o.x / 28.0), floori(o.z / 28.0))
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

var bosque_rect := Rect2()
## Cuánto más grande es el bosque que el plano original (para repartir la misma densidad de árboles y plantas).
func _escala_bosque() -> float:
	var W := float(plan.exterior.w) * CELL
	var H := float(plan.exterior.h) * CELL
	return clampf(bosque_rect.get_area() / (W * H), 1.0, 4.0) if bosque_rect.get_area() > 0.0 else 1.0

## Los límites del mundo tienen sentido: al norte y al oeste montañas de roca demasiado empinadas para subir,
## al este un acantilado, y al sur un barranco sin fondo (caer es mortal). Arriba de todo, árboles gigantes.
func _fronteras() -> void:
	var F := bosque_rect
	var roca := _pbr("Rock022", 0.12, Color(0.55, 0.56, 0.5))
	var roca2 := _pbr("Rock030", 0.1, Color(0.5, 0.5, 0.48))
	roca.cull_mode = BaseMaterial3D.CULL_DISABLED
	roca2.cull_mode = BaseMaterial3D.CULL_DISABLED
	# norte: montaña
	_ladera(Vector3(F.position.x - 30, 0, F.position.y), Vector3(F.end.x + 30, 0, F.position.y), Vector3(0, 0, -1), 42.0, 58.0, roca, 11)
	# oeste: montaña
	_ladera(Vector3(F.position.x, 0, F.end.y + 30), Vector3(F.position.x, 0, F.position.y - 30), Vector3(-1, 0, 0), 38.0, 56.0, roca, 12)
	# este: acantilado casi vertical
	_ladera(Vector3(F.end.x, 0, F.position.y - 30), Vector3(F.end.x, 0, F.end.y + 30), Vector3(1, 0, 0), 34.0, 74.0, roca2, 13)
	# sur: barranco de 34 m de ancho y 60 de hondo; la otra orilla es otro bosque inalcanzable
	var z0 := F.end.y
	var ancho := F.size.x + 60.0
	var cx := F.get_center().x
	_ladera(Vector3(F.end.x + 30, -60, z0), Vector3(F.position.x - 30, -60, z0), Vector3(0, 0, 1), 60.0, 84.0, roca2, 14, true)
	_ladera(Vector3(F.position.x - 30, -60, z0 + 34.0), Vector3(F.end.x + 30, -60, z0 + 34.0), Vector3(0, 0, 1), 60.0, 82.0, roca, 15)
	var otra := box(Vector3(ancho, 0.4, 60.0), Vector3(cx, -0.2, z0 + 34.0 + 32.0), _mat.bosque, false, self, false)
	otra.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var fondo := StandardMaterial3D.new()
	fondo.albedo_color = Color(0.01, 0.012, 0.012)
	fondo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	box(Vector3(ancho, 1.0, 50.0), Vector3(cx, -61.0, z0 + 17.0), fondo, true, self, false)
	# rocas sueltas al pie de las montañas
	var rocas: Array = []
	for ld in [[Vector2(F.position.x, F.position.y), Vector2(F.end.x, F.position.y), Vector2(0, 1)],
			[Vector2(F.position.x, F.end.y), Vector2(F.end.x, F.end.y), Vector2(0, -1)],
			[Vector2(F.position.x, F.position.y), Vector2(F.position.x, F.end.y), Vector2(1, 0)],
			[Vector2(F.end.x, F.position.y), Vector2(F.end.x, F.end.y), Vector2(-1, 0)]]:
		var a0: Vector2 = ld[0]
		var a1: Vector2 = ld[1]
		var largo := a0.distance_to(a1)
		var u := 0.0
		while u < largo:
			var q: Vector2 = a0.lerp(a1, u / largo) + (ld[2] as Vector2) * _rng.randf_range(-1.0, 2.5)
			var sc := _rng.randf_range(1.2, 3.2)
			rocas.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(sc, sc * _rng.randf_range(0.7, 1.3), sc)), Vector3(q.x, -0.3, q.y)))
			u += _rng.randf_range(2.5, 6.0)
	_multi_planta("boulder_01", rocas)

## Ladera de roca entre a y b que sube hacia «afuera»: alto en metros y pendiente en grados (más de 45 no se
## puede subir). Malla con ruido para que parezca roca natural y colisión exacta. «hacia_abajo» la invierte (pared
## que baja desde el suelo, para el barranco).
func _ladera(a: Vector3, b: Vector3, afuera: Vector3, alto: float, grados: float, mat: Material, semilla: int, hacia_abajo := false) -> void:
	var nz := FastNoiseLite.new()
	nz.seed = semilla
	nz.frequency = 0.06
	nz.fractal_octaves = 4
	var largo := a.distance_to(b)
	var nu := int(largo / 3.0) + 1
	var nv := 14
	var fondo_h := alto / tan(deg_to_rad(grados))
	var pts := []
	for iv in nv + 1:
		var fila := []
		var v := float(iv) / nv
		for iu in nu + 1:
			var p0 := a.lerp(b, float(iu) / nu)
			var p := p0 + afuera * (v * fondo_h) + Vector3.UP * (v * alto)
			if hacia_abajo:
				p = p0 + afuera * (-v * fondo_h * 0.2) + Vector3.UP * (v * alto)
			var amp := 1.6 * sin(v * PI) + (0.0 if iv == 0 else 0.4)
			p += afuera * nz.get_noise_2d(p0.x + p0.z, v * 40.0) * amp * 2.0
			p.y += nz.get_noise_2d(p0.x - p0.z + 500.0, v * 40.0) * amp
			if iv == nv and not hacia_abajo:
				p.y += absf(nz.get_noise_1d(p0.x + p0.z)) * 8.0
			fila.append(p)
		pts.append(fila)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iv in nv:
		for iu in nu:
			var q00: Vector3 = pts[iv][iu]
			var q10: Vector3 = pts[iv][iu + 1]
			var q01: Vector3 = pts[iv + 1][iu]
			var q11: Vector3 = pts[iv + 1][iu + 1]
			st.add_vertex(q00); st.add_vertex(q01); st.add_vertex(q10)
			st.add_vertex(q10); st.add_vertex(q01); st.add_vertex(q11)
	st.generate_normals()
	var malla := st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = malla
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta("dyn", true)
	add_child(mi)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var forma := malla.create_trimesh_shape()
	(forma as ConcavePolygonShape3D).backface_collision = true
	cs.shape = forma
	sb.add_child(cs)
	add_child(sb)

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
		m.set_shader_parameter("fuerza", 1.1)
		m.set_shader_parameter("velocidad", 0.55)
		m.set_shader_parameter("escala", 0.32)
		m.set_shader_parameter("relieve", 1.8)
		m.set_shader_parameter("espuma", 1.2)
	else:
		m.set_shader_parameter("corriente", Vector2(0.6, 0.4))
		m.set_shader_parameter("fuerza", 0.12)
		m.set_shader_parameter("velocidad", 0.12)
		m.set_shader_parameter("escala", 0.3)
		m.set_shader_parameter("espuma", 0.8)
		m.set_shader_parameter("relieve", 0.5)
	return m

var rio_rect := Rect2()
## Vida en el río: ranas que croan en las orillas y luciérnagas sobre el agua.
func _vida_rio(r: Rect2) -> void:
	rio_rect = r
	var x := r.position.x + 6.0
	while x < r.end.x:
		var f := _rio_forma(r.grow(1.2), x)
		var son := AudioStreamPlayer3D.new()
		son.stream = AetherSynth._frog()
		son.unit_size = 3.0
		son.max_distance = 26.0
		son.volume_db = -8.0
		son.pitch_scale = _rng.randf_range(0.85, 1.2)
		son.autoplay = true
		son.position = Vector3(x, 0.0, f.x + (f.y + 0.5) * (-1.0 if _rng.randf() < 0.5 else 1.0))
		add_child(son)
		x += _rng.randf_range(14.0, 24.0)
	var lu := CPUParticles3D.new()
	lu.amount = 90
	lu.lifetime = 6.0
	lu.preprocess = 6.0
	lu.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	lu.emission_box_extents = Vector3(r.size.x * 0.5, 0.6, r.size.y * 0.5 + 2.0)
	lu.gravity = Vector3(0, 0.02, 0)
	lu.direction = Vector3(1, 0, 0)
	lu.spread = 180.0
	lu.initial_velocity_min = 0.05
	lu.initial_velocity_max = 0.25
	lu.scale_amount_min = 0.6
	lu.scale_amount_max = 1.2
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.0))
	g.set_color(1, Color(1, 1, 1, 0.0))
	g.add_point(0.25, Color(1, 1, 1, 1.0))
	g.add_point(0.5, Color(1, 1, 1, 0.2))
	g.add_point(0.75, Color(1, 1, 1, 1.0))
	lu.color_ramp = g
	var q := QuadMesh.new()
	q.size = Vector2(0.035, 0.035)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(0.85, 1.0, 0.4)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var tx := GradientTexture2D.new()
	var g2 := Gradient.new()
	g2.set_color(0, Color(1, 1, 1, 1)); g2.set_color(1, Color(1, 1, 1, 0))
	tx.gradient = g2
	tx.fill = GradientTexture2D.FILL_RADIAL
	tx.fill_from = Vector2(0.5, 0.5); tx.fill_to = Vector2(0.5, 0.0)
	mat.albedo_texture = tx
	q.material = mat
	lu.mesh = q
	lu.position = Vector3(r.get_center().x, 0.7, r.get_center().y)
	lu.visibility_aabb = AABB(Vector3(-r.size.x * 0.5, -1, -r.size.y), Vector3(r.size.x, 3, r.size.y * 2))
	add_child(lu)

## Un pez salta en el río cerca de «cerca»: gotas, anillo que se abre en el agua y chapoteo.
func salto_pez(cerca: Vector3) -> void:
	if rio_rect.size == Vector2.ZERO:
		return
	var x := clampf(cerca.x + _rng.randf_range(-9.0, 9.0), rio_rect.position.x + 2.0, rio_rect.end.x - 2.0)
	var f := _rio_forma(rio_rect.grow(1.2), x)
	var p := Vector3(x, -0.27, f.x + _rng.randf_range(-f.y, f.y) * 0.6)
	var gotas := CPUParticles3D.new()
	gotas.one_shot = true
	gotas.emitting = true
	gotas.amount = 24
	gotas.lifetime = 0.8
	gotas.explosiveness = 0.95
	gotas.direction = Vector3.UP
	gotas.spread = 40.0
	gotas.initial_velocity_min = 1.0
	gotas.initial_velocity_max = 2.2
	gotas.gravity = Vector3(0, -9.8, 0)
	gotas.scale_amount_min = 0.6
	gotas.scale_amount_max = 1.2
	gotas.mesh = _gota_mesh()
	gotas.position = p
	add_child(gotas)
	var anillo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(1, 1)
	anillo.mesh = pm
	var sm := ShaderMaterial.new()
	sm.shader = _shader_anillo()
	anillo.material_override = sm
	anillo.position = p + Vector3(0, 0.01, 0)
	anillo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(anillo)
	var son := AudioStreamPlayer3D.new()
	son.stream = AetherSynth.make("chapoteo")
	son.unit_size = 4.0
	son.max_distance = 30.0
	son.position = p
	add_child(son)
	son.play()
	var tw := create_tween()
	tw.tween_method(func(v: float): sm.set_shader_parameter("t", v); anillo.scale = Vector3.ONE * (0.3 + v * 3.2), 0.0, 1.0, 2.4)
	tw.tween_callback(func(): anillo.queue_free(); gotas.queue_free(); son.queue_free())

var _sh_anillo: Shader
func _shader_anillo() -> Shader:
	if _sh_anillo == null:
		_sh_anillo = Shader.new()
		_sh_anillo.code = """shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform float t = 0.0;
void fragment() {
	float d = length(UV - 0.5) * 2.0;
	float aro = exp(-pow((d - 0.8) * 9.0, 2.0)) + 0.5 * exp(-pow((d - 0.55) * 12.0, 2.0));
	ALBEDO = vec3(0.55, 0.62, 0.7);
	ALPHA = aro * (1.0 - t) * 0.6;
}
"""
	return _sh_anillo

## Hojas secas y ramitas que bajan flotando por el río (se ve la corriente y el agua deja de parecer un suelo).
func _hojas_rio(r: Rect2) -> void:
	var tramos := int(r.size.x / 30.0) + 1
	for i in tramos:
		var p := CPUParticles3D.new()
		p.amount = 26
		p.lifetime = 30.0
		p.preprocess = 30.0
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = Vector3(15.0, 0.0, r.size.y * 0.42)
		p.direction = Vector3(1, 0, 0)
		p.spread = 6.0
		p.gravity = Vector3.ZERO
		p.initial_velocity_min = 0.35
		p.initial_velocity_max = 0.7
		p.angle_min = 0.0
		p.angle_max = 360.0
		p.angular_velocity_min = -12.0
		p.angular_velocity_max = 12.0
		p.scale_amount_min = 0.6
		p.scale_amount_max = 1.3
		p.particle_flag_rotate_y = true
		p.local_coords = false
		var q := PlaneMesh.new()
		q.size = Vector2(0.09, 0.06)
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = _textura_hoja_rio()
		mat.albedo_color = Color(0.5, 0.36, 0.22)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		mat.alpha_scissor_threshold = 0.4
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.roughness = 0.6
		q.material = mat
		p.mesh = q
		p.position = Vector3(r.position.x + 15.0 + i * 30.0, -0.26, r.get_center().y)
		p.visibility_aabb = AABB(Vector3(-30, -1, -r.size.y), Vector3(60, 2, r.size.y * 2))
		add_child(p)

var _hoja_rio_tex: ImageTexture
func _textura_hoja_rio() -> ImageTexture:
	if _hoja_rio_tex:
		return _hoja_rio_tex
	var img := Image.create(32, 24, false, Image.FORMAT_RGBA8)
	for y in 24:
		for x in 32:
			var u := (x - 16.0) / 15.0
			var v := (y - 12.0) / 10.0
			var dentro := u * u + v * v * (1.0 + absf(u) * 0.8) < 1.0
			var tono := 0.8 + 0.2 * sin(x * 0.9) * cos(y * 0.7)
			img.set_pixel(x, y, Color(tono, tono * 0.85, tono * 0.6, 1.0 if dentro else 0.0))
	img.generate_mipmaps()
	_hoja_rio_tex = ImageTexture.create_from_image(img)
	return _hoja_rio_tex

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
	# el pozo de piedra de verdad (Objaverse, CC-BY); si no está, el de siempre hecho con cajas
	if _prop("t_pozo_piedra", c, 0.6, 1.0, false, self) != null:
		_static_cyl(1.5, 1.0, c + Vector3(0, 0.5, 0))
		return
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
	# rampas en las dos puntas: el piso del puente está a 0,33 m y el jugador no sube escalones así
	var alto := 0.33
	var lr := 1.7
	var ang := atan2(alto, lr)
	for lado in ([] if OS.get_environment("SIN_RAMPAS") != "" else [-1.0, 1.0]):
		var z_fin: float = bz + lado * largo * 0.5
		var centro := Vector3(bx, alto * 0.5, z_fin + lado * lr * 0.5)
		var b := Basis(Vector3(1, 0, 0), ang * lado)
		var normal := b * Vector3.UP
		var rampa := box(Vector3(3.6, 0.1, lr / cos(ang) + 0.1), centro - normal * 0.05, mv, true, self)
		rampa.visible = false
		rampa.set_meta("dyn", true)
		rampa.transform = Transform3D(b, centro - normal * 0.05)
		# a la vista: dos tablones inclinados que bajan a la orilla
		for s2 in [-0.9, 0.9]:
			var t := box(Vector3(1.6, 0.05, lr / cos(ang) + 0.1), Vector3.ZERO, mv, false, self)
			t.transform = Transform3D(b, centro + Vector3(s2, 0.0, 0.0) + normal * 0.005)
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
	if name == "Invernadero":
		_invernadero(r)
		return
	var c := Vector3(r.get_center().x, 0, r.get_center().y)
	var hh := 3.2 if name != "Cochera" else 3.8
	var wm: Material = _mat.fachada
	var tr: Material = _mat.piedra_clara
	var thick := 0.3
	var largo_x := r.size.x >= r.size.y   # la cumbrera va a lo largo del lado más largo
	# zócalo de piedra
	for k in 4:
		var horiz := k < 2
		var l := r.size.x if horiz else r.size.y
		var p := Vector3(c.x, 0.3, r.position.y if k == 0 else r.end.y) if horiz else Vector3(r.position.x if k == 2 else r.end.x, 0.3, c.z)
		box(Vector3(l + 0.2, 0.6, thick + 0.1) if horiz else Vector3(thick + 0.1, 0.6, l + 0.2), p, _mat.cimiento, false, self, false)
	# muros: la puerta en el lado sur (hacia la casa o el camino); ventanas en los lados largos
	var sides := [[Vector2(r.position.x, r.position.y), Vector2(r.end.x, r.position.y)], [Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.end.y)],
		[Vector2(r.position.x, r.position.y), Vector2(r.position.x, r.end.y)], [Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.end.y)]]
	var open_side := 1
	var gap := 2.0 if name != "Cochera" else 3.6
	for i in 4:
		var a: Vector2 = sides[i][0]
		var b: Vector2 = sides[i][1]
		var horiz := absf(a.y - b.y) < 0.01
		var l := a.distance_to(b)
		var mid := (a + b) * 0.5
		var ej := Vector2(1, 0) if horiz else Vector2(0, 1)
		var fuera := Vector3(0, 0, -1 if i == 0 else 1) if horiz else Vector3(-1 if i == 2 else 1, 0, 0)
		if i == open_side:
			var part := (l - gap) * 0.5
			for s in [-1.0, 1.0]:
				var pc: Vector2 = mid + ej * s * (gap * 0.5 + part * 0.5)
				box(Vector3(part, hh, thick) if horiz else Vector3(thick, hh, part), Vector3(pc.x, hh * 0.5, pc.y), wm, true, self)
			box(Vector3(gap, hh - 2.5, thick) if horiz else Vector3(thick, hh - 2.5, gap), Vector3(mid.x, 2.5 + (hh - 2.5) * 0.5, mid.y), wm, false, self)
			# marco de la puerta y una hoja medio abierta, colgando de una bisagra
			var m3 := Vector3(mid.x, 0, mid.y)
			for s in [-1.0, 1.0]:
				box(Vector3(0.16, 2.6, 0.12) if horiz else Vector3(0.12, 2.6, 0.16), m3 + Vector3(ej.x, 0, ej.y) * s * (gap * 0.5 + 0.08) + fuera * (thick * 0.5 + 0.04) + Vector3(0, 1.3, 0), tr, false, self, false)
			box(Vector3(gap + 0.4, 0.18, 0.14) if horiz else Vector3(0.14, 0.18, gap + 0.4), m3 + fuera * (thick * 0.5 + 0.05) + Vector3(0, 2.6, 0), tr, false, self, false)
			var hoja := box(Vector3(gap * 0.5 - 0.05, 2.4, 0.06) if horiz else Vector3(0.06, 2.4, gap * 0.5 - 0.05), Vector3.ZERO, _mat.tablas, false, self, false)
			var bis := m3 + Vector3(ej.x, 0, ej.y) * (-gap * 0.5) + fuera * (thick * 0.5 + 0.1)
			var giro := 1.1
			var dirh := (Vector3(ej.x, 0, ej.y) * cos(giro) + fuera * sin(giro)).normalized()
			hoja.position = bis + dirh * (gap * 0.25) + Vector3(0, 1.25, 0)
			hoja.rotation.y = atan2(-dirh.z, dirh.x) if horiz else atan2(-dirh.z, dirh.x) - PI * 0.5
			if gap > 3.0:
				var hoja2 := box(Vector3(gap * 0.5 - 0.05, 2.4, 0.06) if horiz else Vector3(0.06, 2.4, gap * 0.5 - 0.05), m3 + Vector3(ej.x, 0, ej.y) * (gap * 0.25) + Vector3(0, 1.25, 0), _mat.tablas, true, self, false)
				hoja2.rotation.z = 0.04
			continue
		box(Vector3(l, hh, thick) if horiz else Vector3(thick, hh, l), Vector3(mid.x, hh * 0.5, mid.y), wm, true, self)
		# ventanas pequeñas con marco y cristal sucio (una por cada 4 m), alguna tapiada
		var nv := int(l / 4.0)
		for k in nv:
			var t := (k + 0.5) / nv
			var wp := a.lerp(b, t)
			var cw := Vector3(wp.x, 1.7, wp.y) + fuera * (thick * 0.5 + 0.02)
			var tapiada := _rng.randf() < 0.35
			box(Vector3(1.0, 0.9, 0.04) if horiz else Vector3(0.04, 0.9, 1.0), cw, _mat.oscuro if tapiada else _mat.vidrio, false, self, false)
			for s in [-1.0, 1.0]:
				box(Vector3(0.1, 1.1, 0.08) if horiz else Vector3(0.08, 1.1, 0.1), cw + Vector3(ej.x, 0, ej.y) * s * 0.55, tr, false, self, false)
			box(Vector3(1.25, 0.1, 0.16) if horiz else Vector3(0.16, 0.1, 1.25), cw + Vector3(0, -0.5, 0) + fuera * 0.05, tr, false, self, false)
			box(Vector3(1.25, 0.12, 0.12) if horiz else Vector3(0.12, 0.12, 1.25), cw + Vector3(0, 0.52, 0), tr, false, self, false)
			if tapiada:
				for tb in 3:
					var t2 := box(Vector3(1.3, 0.16, 0.04) if horiz else Vector3(0.04, 0.16, 1.3), cw + fuera * 0.04 + Vector3(0, -0.3 + tb * 0.3, 0), _mat.tablas, false, self, false)
					t2.rotation.z = (tb - 1) * 0.12 if horiz else 0.0
					t2.rotation.x = 0.0 if horiz else (tb - 1) * 0.12
	# esquineras
	for q in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		box(Vector3(0.36, hh, 0.36), Vector3(q.x, hh * 0.5, q.y), tr, false, self, false)
	# tejado a dos aguas con hastiales de tablas, alero y tabla de remate
	var lx := r.size.x if largo_x else r.size.y
	var ly := r.size.y if largo_x else r.size.x
	var alto_t := ly * 0.42
	var hast := MeshInstance3D.new()
	var hm := PrismMesh.new()
	hm.size = Vector3(ly, alto_t, lx)
	hast.mesh = hm
	hast.material_override = wm
	hast.position = c + Vector3(0, hh + alto_t * 0.5, 0)
	hast.rotation.y = PI * 0.5 if largo_x else 0.0
	add_child(hast)
	var semi := ly * 0.5 + 0.5
	var ang := atan2(alto_t + 0.25, semi)
	var faldon := sqrt(semi * semi + pow(alto_t + 0.25, 2))
	for s in [-1.0, 1.0]:
		var f := box(Vector3(lx + 0.9, 0.12, faldon), Vector3.ZERO, _mat.tejado, false, self)
		var dir_c := Vector3(0, 0, 1) if largo_x else Vector3(1, 0, 0)
		f.position = c + Vector3(0, hh + (alto_t + 0.25) * 0.5 - 0.1, 0) + dir_c * s * (semi * 0.5)
		if largo_x:
			f.rotation.x = s * ang
		else:
			f.rotation.z = -s * ang
		f.position += Vector3(0, 0.06, 0)
	for s in [-1.0, 1.0]:
		var ext: Vector3 = c + (Vector3(1, 0, 0) if largo_x else Vector3(0, 0, 1)) * s * (lx * 0.5 + 0.35)
		for k in [-1.0, 1.0]:
			var tb := box(Vector3(0.06, 0.28, faldon) if largo_x else Vector3(faldon, 0.28, 0.06), Vector3.ZERO, tr, false, self, false)
			var dir_c2 := Vector3(0, 0, 1) if largo_x else Vector3(1, 0, 0)
			tb.position = ext + Vector3(0, hh + (alto_t + 0.25) * 0.5 - 0.15, 0) + dir_c2 * k * (semi * 0.5)
			if largo_x:
				tb.rotation.x = k * ang
			else:
				tb.rotation.z = -k * ang
	box(Vector3(lx + 1.0, 0.14, 0.14) if largo_x else Vector3(0.14, 0.14, lx + 1.0), c + Vector3(0, hh + alto_t + 0.3, 0), _mat.metal, false, self, false)
	box(Vector3(r.size.x, 0.1, r.size.y), c + Vector3(0, 0.05, 0), _mat.madera_vieja, false, self, false)
	if name == "Cochera":
		box(Vector3(2.0, 1.2, 4.6), c + Vector3(0, 0.6, 0), _mat.sabana, true, self)
	var l := OmniLight3D.new()
	l.light_color = Color(0.6, 0.7, 1.0)
	l.light_energy = 0.25
	l.omni_range = 7.0
	l.position = c + Vector3(0, 2.5, 0)
	add_child(l)

## Invernadero victoriano en ruinas: zócalo de ladrillo, estructura de hierro, paneles de cristal sucio (alguno
## roto), tejado de cristal a dos aguas con crestería, mesas de cultivo y plantas secas.
func _invernadero(r: Rect2) -> void:
	var c := Vector3(r.get_center().x, 0, r.get_center().y)
	var hh := 3.0
	var hierro: Material = _mat.hierro
	var cristal := _plain(Color(0.35, 0.4, 0.38, 0.35), 0.25, 0.1)
	cristal.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cristal.cull_mode = BaseMaterial3D.CULL_DISABLED
	var lados := [[Vector2(r.position.x, r.position.y), Vector2(r.end.x, r.position.y)], [Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.end.y)],
		[Vector2(r.position.x, r.position.y), Vector2(r.position.x, r.end.y)], [Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.end.y)]]
	for i in 4:
		var a: Vector2 = lados[i][0]
		var b: Vector2 = lados[i][1]
		var horiz := absf(a.y - b.y) < 0.01
		var l := a.distance_to(b)
		var mid := (a + b) * 0.5
		var puerta := i == 2
		# zócalo de ladrillo (con el hueco de la puerta)
		if puerta:
			for s in [-1.0, 1.0]:
				var pc: Vector2 = mid + Vector2(0, 1) * s * (l * 0.25 + 0.6)
				box(Vector3(0.3, 0.8, l * 0.5 - 1.2), Vector3(pc.x, 0.4, pc.y), _mat.ladrillo, true, self)
		else:
			box(Vector3(l, 0.8, 0.3) if horiz else Vector3(0.3, 0.8, l), Vector3(mid.x, 0.4, mid.y), _mat.ladrillo, true, self)
		# montantes de hierro y paneles de cristal
		var n := int(l / 1.2)
		for k in n + 1:
			var p := a.lerp(b, float(k) / n)
			box(Vector3(0.07, hh, 0.07), Vector3(p.x, hh * 0.5, p.y), hierro, false, self, false)
			if k < n:
				var q := a.lerp(b, (k + 0.5) / n)
				if puerta and absf((q - mid).length()) < 1.0:
					continue
				if _rng.randf() > 0.18:  # algunos cristales rotos
					box(Vector3(l / n - 0.08, hh - 0.85, 0.02) if horiz else Vector3(0.02, hh - 0.85, l / n - 0.08), Vector3(q.x, 0.8 + (hh - 0.8) * 0.5, q.y), cristal, false, self, false)
		box(Vector3(l, 0.08, 0.08) if horiz else Vector3(0.08, 0.08, l), Vector3(mid.x, hh, mid.y), hierro, false, self, false)
		box(Vector3(l, 0.06, 0.06) if horiz else Vector3(0.06, 0.06, l), Vector3(mid.x, 1.9, mid.y), hierro, false, self, false)
		# los cristales no detienen al jugador del todo: una pared invisible por encima del zócalo
		if not puerta:
			_choque(Vector3(l, hh, 0.2) if horiz else Vector3(0.2, hh, l), Vector3(mid.x, hh * 0.5, mid.y))
		else:
			for s in [-1.0, 1.0]:
				var pc: Vector2 = mid + Vector2(0, 1) * s * (l * 0.25 + 0.6)
				_choque(Vector3(0.2, hh, l * 0.5 - 1.2), Vector3(pc.x, hh * 0.5, pc.y))
	# tejado de cristal a dos aguas (cumbrera a lo largo de x)
	var semi := r.size.y * 0.5
	var alto := 2.2
	var ang := atan2(alto, semi)
	var faldon := sqrt(semi * semi + alto * alto)
	for s in [-1.0, 1.0]:
		var f := box(Vector3(r.size.x, 0.03, faldon), c + Vector3(0, hh + alto * 0.5, s * semi * 0.5), cristal, false, self, false)
		f.rotation.x = s * ang
		var nc := int(r.size.x / 1.2)
		for k in nc + 1:
			var x := r.position.x + r.size.x * float(k) / nc
			var cab := box(Vector3(0.06, 0.06, faldon), Vector3(x, hh + alto * 0.5, c.z + s * semi * 0.5), hierro, false, self, false)
			cab.rotation.x = s * ang
	# hastiales de cristal y cumbrera con crestería
	for s in [-1.0, 1.0]:
		var g := MeshInstance3D.new()
		var gm := PrismMesh.new()
		gm.size = Vector3(r.size.y, alto, 0.02)
		g.mesh = gm
		g.material_override = cristal
		g.position = Vector3(r.position.x if s < 0 else r.end.x, hh + alto * 0.5, c.z)
		g.rotation.y = PI * 0.5
		add_child(g)
	box(Vector3(r.size.x + 0.2, 0.1, 0.1), c + Vector3(0, hh + alto, 0), hierro, false, self, false)
	for k in int(r.size.x / 0.3):
		box(Vector3(0.02, 0.35, 0.02), Vector3(r.position.x + 0.15 + k * 0.3, hh + alto + 0.2, c.z), hierro, false, self, false)
	# suelo de baldosa, mesas de cultivo con macetas y plantas secas
	box(Vector3(r.size.x, 0.08, r.size.y), c + Vector3(0, 0.04, 0), _mat.s_hidraulica, false, self, false)
	for s in [-1.0, 1.0]:
		var mz: float = c.z + s * (semi - 1.2)
		box(Vector3(r.size.x - 3.0, 0.08, 1.2), Vector3(c.x + 0.6, 0.9, mz), _mat.madera_vieja, true, self)
		for k in 4:
			box(Vector3(0.1, 0.9, 0.1), Vector3(c.x + 0.6 + (k - 1.5) * (r.size.x - 3.2) / 3.0, 0.45, mz), _mat.madera_vieja, false, self, false)
		var nm := int((r.size.x - 3.5) / 0.7)
		for k in nm:
			var mp := Vector3(r.position.x + 2.3 + k * 0.7, 1.05, mz + _rng.randf_range(-0.3, 0.3))
			if _rng.randf() < 0.15:
				var caida := cyl(0.14, 0.1, 0.22, mp + Vector3(0, -0.9, 0.7 * s), _mat.terracota, self, 8)
				caida.rotation.z = PI * 0.5
				continue
			cyl(0.14, 0.1, 0.22, mp, _mat.terracota, self, 8)
	var secos: Array = []
	for k in 30:
		var p := Vector2(_rng.randf_range(r.position.x + 1.5, r.end.x - 1.0), _rng.randf_range(r.position.y + 1.0, r.end.y - 1.0))
		var sc := _rng.randf_range(0.6, 1.1)
		secos.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(sc, sc, sc)), Vector3(p.x, 0.08, p.y)))
	_multi_planta("dry_branches_medium_01", secos)

## Huerto abandonado: surcos de tierra con plantas secas, valla de estacas medio caída y un espantapájaros.
func _huerto(r: Rect2) -> void:
	var nf := int(r.size.y / 1.4)
	var secos: Array = []
	var hierba: Array = []
	for k in nf:
		var z := r.position.y + 0.9 + k * 1.4
		var surco := box(Vector3(r.size.x - 1.6, 0.22, 0.55), Vector3(r.get_center().x, 0.06, z), _mat.barro, false, self, false)
		surco.rotation.y = _rng.randf_range(-0.02, 0.02)
		var n := int((r.size.x - 2.0) / 0.6)
		for j in n:
			if _rng.randf() < 0.35:
				continue
			var p := Vector3(r.position.x + 1.2 + j * 0.6 + _rng.randf_range(-0.15, 0.15), 0.15, z)
			var sc := _rng.randf_range(0.4, 0.8)
			secos.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(sc, sc, sc)), p))
			if _rng.randf() < 0.3:
				hierba.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(sc * 1.6, sc * 1.6, sc * 1.6)), p + Vector3(0, -0.1, 0.5)))
	_multi_planta("dry_branches_medium_01", secos)
	_multi_planta("grass_medium_01", hierba)
	# valla de estacas
	var lados := [[Vector2(r.position.x, r.position.y), Vector2(r.end.x, r.position.y)], [Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.end.y)],
		[Vector2(r.position.x, r.position.y), Vector2(r.position.x, r.end.y)], [Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.end.y)]]
	for ld in lados:
		var a: Vector2 = ld[0]
		var b: Vector2 = ld[1]
		var l := a.distance_to(b)
		var n := int(l / 0.35)
		for k in n:
			if _rng.randf() < 0.12:
				continue
			var p := a.lerp(b, (k + 0.5) / n)
			var e := box(Vector3(0.08, 1.0, 0.04), Vector3(p.x, 0.5, p.y), _mat.madera_vieja, false, self, false)
			e.rotation = Vector3(_rng.randf_range(-0.15, 0.15), atan2(b.y - a.y, b.x - a.x) * -1.0, _rng.randf_range(-0.15, 0.15))
		var m := (a + b) * 0.5
		var rail := box(Vector3(l, 0.06, 0.04), Vector3(m.x, 0.75, m.y), _mat.madera_vieja, false, self, false)
		rail.rotation.y = -atan2(b.y - a.y, b.x - a.x)
	# espantapájaros: cruz de madera, saco por cabeza, abrigo raído
	var ec := Vector3(r.get_center().x + 1.5, 0, r.get_center().y)
	box(Vector3(0.1, 2.4, 0.1), ec + Vector3(0, 1.2, 0), _mat.madera_vieja, true, self)
	box(Vector3(1.6, 0.08, 0.08), ec + Vector3(0, 1.85, 0), _mat.madera_vieja, false, self, false)
	box(Vector3(0.7, 0.9, 0.3), ec + Vector3(0, 1.55, 0), _mat.tela_roja if false else _pbr("Fabric028", 1.2, Color(0.25, 0.22, 0.18), 1.0), false, self, false)
	for s in [-1.0, 1.0]:
		var manga := box(Vector3(0.6, 0.2, 0.22), ec + Vector3(s * 0.6, 1.82, 0), _pbr("Fabric028", 1.2, Color(0.25, 0.22, 0.18), 1.0), false, self, false)
		manga.rotation.z = s * -0.1
	var cabeza := cyl(0.2, 0.22, 0.42, ec + Vector3(0, 2.25, 0), _mat.sabana, self, 10)
	cabeza.rotation.z = 0.15
	cyl(0.36, 0.36, 0.04, ec + Vector3(0.03, 2.47, 0), _mat.madera_vieja, self, 12)
	cyl(0.18, 0.2, 0.22, ec + Vector3(0.03, 2.58, 0), _mat.madera_vieja, self, 10)

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
	var count := int((2200 if quality >= 2 else (1400 if quality == 1 else 800)) * _escala_bosque())
	var tries := 0
	while xforms.size() < count and tries < count * 8:
		tries += 1
		var p := Vector2(_rng.randf_range(bosque_rect.position.x + 4.0, bosque_rect.end.x - 4.0), _rng.randf_range(bosque_rect.position.y + 4.0, bosque_rect.end.y - 4.0))
		var bad := false
		for r in avoid:
			if (r as Rect2).has_point(p):
				bad = true
				break
		if bad:
			continue
		var s := _rng.randf_range(0.8, 1.45)
		xforms.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s * _rng.randf_range(0.9, 1.3), s)), Vector3(p.x, 0, p.y)))
	# árboles gigantes muy juntos a lo largo del borde: el bosque se cierra (no se ve el final del mapa)
	var F := bosque_rect
	var lados := [[Vector2(F.position.x, F.position.y), Vector2(F.end.x, F.position.y), Vector2(0, 1)],
		[Vector2(F.position.x, F.end.y), Vector2(F.end.x, F.end.y), Vector2(0, -1)],
		[Vector2(F.position.x, F.position.y), Vector2(F.position.x, F.end.y), Vector2(1, 0)],
		[Vector2(F.end.x, F.position.y), Vector2(F.end.x, F.end.y), Vector2(-1, 0)]]
	for ld in lados:
		var a0: Vector2 = ld[0]
		var a1: Vector2 = ld[1]
		var dentro: Vector2 = ld[2]
		var largo := a0.distance_to(a1)
		var u := 0.0
		while u < largo:
			for fila in 2:
				var q := a0.lerp(a1, u / largo) + dentro * _rng.randf_range(2.0 + fila * 5.0, 6.0 + fila * 6.0)
				var sg := _rng.randf_range(1.6, 2.5)
				xforms.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(sg, sg * _rng.randf_range(0.95, 1.2), sg)), Vector3(q.x, 0, q.y)))
			u += _rng.randf_range(3.0, 5.5)
	# el bosque sigue al otro lado del barranco (no se puede llegar)
	for k in int(260 * _escala_bosque() / 3.0):
		var q := Vector2(_rng.randf_range(F.position.x, F.end.x), _rng.randf_range(F.end.y + 38.0, F.end.y + 90.0))
		var sg := _rng.randf_range(1.0, 2.0)
		xforms.append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(sg, sg, sg)), Vector3(q.x, 0, q.y)))
	# árboles realistas (Ez-Tree) cerca y abetos sencillos a lo lejos, repartidos en parcelas de 24 m para que
	# solo se dibuje con detalle el bosque que rodea al jugador (la niebla tapa el resto)
	var pinos := ["pino_grande_1", "pino_grande_2", "pino_grande_3", "pino_mediano_1", "pino_mediano_2", "pino_joven", "muerto_roble", "muerto_fresno", "muerto_roble_2",
		"fresno_joven", "alamo_joven", "roble_joven", "roble_mediano", "fresno_mediano", "muerto_alamo", "muerto_joven"]
	var peso := [14, 14, 14, 12, 12, 9, 4, 4, 5, 6, 4, 6, 6, 6, 3, 4]
	var mallas: Array = []
	var t_ar := Time.get_ticks_msec()
	var medios: Array = []
	for nm in pinos:
		mallas.append(_malla_glb("res://zarek/arboles/%s.glb" % nm))
		medios.append(_arbol_medio(mallas[-1]) if mallas[-1] != null else null)
	print("ZAREK     mallas de arboles %d ms" % (Time.get_ticks_msec() - t_ar))
	var lejos: Array = []
	for v in 3:
		lejos.append(_abeto_mesh(100 + v, 0.85 + v * 0.12))
	var PARC := 16.0
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
				_multi_arbol(_con_viento(mallas[v], fx, tb), lista, 0.0, 22.0 if quality >= 2 else 16.0, true)
				# media distancia: árbol aligerado; más lejos, impostor (imagen del árbol en dos planos cruzados) que se
				# crea al terminar de cargar. Si no se puede crear (sin pantalla), el árbol aligerado llega hasta el final.
				var mm_medio := _multi_arbol(_con_viento(medios[v], fx, tb), lista, 20.0 if quality >= 2 else 14.0, 68.0 if quality >= 2 else 46.0, quality >= 2)
				_imp_pendientes.append({"v": v, "malla": mallas[v], "xs": lista, "medio": mm_medio})
			if v < 6:
				for k in lista.size():
					lejos_xs[k % 3].append(lista[k])
		for k in 3:
			if lejos_xs[k].size() > 0:
				_multi_arbol(_con_viento(lejos[k], 0.02, 0.0), lejos_xs[k], 60.0 if quality >= 2 else 40.0, 0.0, false)
	# setas al pie de los árboles (en corros de 2-6) y helechos grandes entre los troncos
	var setas := ["veg_boletus_edulis_mushroom", "veg_chanterelle", "veg_tricholoma_murrillianum_", "veg_shaggy_parasol_mushroom_", "veg_mushroom", "veg_mushroom_on_tree_baked_l"]
	var por_seta: Dictionary = {}
	for k in int(260 * (1.0 if quality >= 2 else 0.6) * _escala_bosque()):
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
	for k in int(700 * (1.0 if quality >= 2 else 0.6) * _escala_bosque()):
		var p := Vector2(_rng.randf_range(bosque_rect.position.x + 4.0, bosque_rect.end.x - 4.0), _rng.randf_range(bosque_rect.position.y + 4.0, bosque_rect.end.y - 4.0))
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
	var na := int(900 * (1.0 if quality >= 2 else 0.6) * _escala_bosque())
	var intentos := 0
	while arb_xs[0].size() + arb_xs[1].size() + arb_xs[2].size() < na and intentos < na * 6:
		intentos += 1
		var p := Vector2(_rng.randf_range(bosque_rect.position.x + 4.0, bosque_rect.end.x - 4.0), _rng.randf_range(bosque_rect.position.y + 4.0, bosque_rect.end.y - 4.0))
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
	print("ZAREK     arboles+setas+helechos listos")
	var t1 := Time.get_ticks_msec()
	_sotobosque(W, H, avoid)
	print("ZAREK     sotobosque %d ms" % (Time.get_ticks_msec() - t1))
	t1 = Time.get_ticks_msec()
	_jardin_salvaje()
	print("ZAREK     jardin %d ms" % (Time.get_ticks_msec() - t1))
	# colisión de troncos con un solo cuerpo
	# (las formas se añaden antes de meter el cuerpo en la escena: añadirlas una a una con el cuerpo ya dentro
	# rehace el cuerpo entero cada vez y tardaba segundos)
	var sb := StaticBody3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.45
	sh.height = 4.0
	for t in xforms:
		var cs := CollisionShape3D.new()
		cs.shape = sh
		cs.position = t.origin + Vector3(0, 2.0, 0)
		sb.add_child(cs)
	add_child(sb)
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

func _multi_arbol(malla: Mesh, xs: Array, desde: float, hasta: float, sombra: bool) -> MultiMeshInstance3D:
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
	return mmi

var _imp_pendientes: Array = []
var _imp_cache: Dictionary = {}
## Impostores de los árboles lejanos: cada tipo de árbol se fotografía de frente y de lado (cámara ortográfica,
## fondo transparente, luz plana) y lejos se dibuja con esas dos imágenes en dos planos cruzados. Un árbol de
## ~10.000 triángulos y hojas superpuestas pasa a 4 triángulos: es lo que más pesaba en el bosque del teléfono.
func crear_impostores() -> void:
	if _imp_pendientes.is_empty() or DisplayServer.get_name() == "headless":
		return
	var t0 := Time.get_ticks_msec()
	var corte := 30.0 if quality >= 2 else 26.0
	for pend in _imp_pendientes:
		var v: int = pend.v
		if not _imp_cache.has(v):
			_imp_cache[v] = await _foto_impostor(pend.malla)
		var imp: Mesh = _imp_cache[v]
		if imp == null:
			continue
		var medio: MultiMeshInstance3D = pend.medio
		var fin := medio.visibility_range_end
		medio.visibility_range_end = corte
		medio.visibility_range_end_margin = 3.0
		var mmi := _multi_arbol(imp, pend.xs, corte - 2.0, fin, false)
		mmi.visibility_range_begin_margin = 3.0
	print("ZAREK impostores: %d tipos en %d ms" % [_imp_cache.size(), Time.get_ticks_msec() - t0])

func _foto_impostor(malla: Mesh) -> Mesh:
	if malla == null:
		return null
	var ab := malla.get_aabb()
	var alto := ab.size.y
	var ancho := maxf(ab.size.x, ab.size.z)
	var res := Vector2i(256, int(clampf(256.0 * alto / maxf(ancho, 0.1), 256.0, 512.0)))
	var imagenes: Array[Image] = []
	for lado in 2:
		var sv := SubViewport.new()
		sv.size = res
		sv.transparent_bg = true
		sv.own_world_3d = true
		sv.render_target_update_mode = SubViewport.UPDATE_ONCE
		add_child(sv)
		var mi := MeshInstance3D.new()
		mi.mesh = malla
		mi.rotation.y = lado * PI * 0.5
		sv.add_child(mi)
		var cam := Camera3D.new()
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = alto * 1.02
		cam.keep_aspect = Camera3D.KEEP_HEIGHT
		cam.position = Vector3(0, ab.position.y + alto * 0.5, 50.0)
		var env := Environment.new()
		env.background_mode = Environment.BG_CLEAR_COLOR
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(1, 1, 1)
		env.ambient_light_energy = 1.0
		cam.environment = env
		sv.add_child(cam)
		var luz := DirectionalLight3D.new()
		luz.rotation_degrees = Vector3(-35, 20, 0)
		luz.light_energy = 0.4
		sv.add_child(luz)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := sv.get_texture().get_image()
		sv.queue_free()
		if img == null or img.is_empty():
			return null
		img.convert(Image.FORMAT_RGBA8)
		if OS.get_environment("GUARDAR_IMPOSTORES") != "":
			img.save_png("%s/imp_%d_%d.png" % [OS.get_environment("GUARDAR_IMPOSTORES"), malla.get_instance_id() % 1000, lado])
		img.generate_mipmaps()
		imagenes.append(img)
	# dos planos cruzados con su foto cada uno
	var st := SurfaceTool.new()
	var am := ArrayMesh.new()
	var w := alto * float(res.x) / float(res.y) * 0.5
	for lado in 2:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var eje := Vector3(1, 0, 0) if lado == 0 else Vector3(0, 0, -1)
		var y0 := ab.position.y
		var y1 := ab.position.y + alto
		var q := [eje * -w + Vector3(0, y0, 0), eje * w + Vector3(0, y0, 0), eje * w + Vector3(0, y1, 0), eje * -w + Vector3(0, y1, 0)]
		var uv := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		st.set_normal(Vector3.UP.lerp(eje.cross(Vector3.UP), 0.5).normalized())
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_uv(uv[k])
			st.add_vertex(q[k])
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = ImageTexture.create_from_image(imagenes[lado])
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		mat.alpha_scissor_threshold = 0.45
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.roughness = 0.95
		mat.albedo_color = Color(0.82, 0.86, 0.8)
		st.set_material(mat)
		st.commit(am)
	return am

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
		var n := int(float(it[1]) * cuantos * _escala_bosque())
		var intentos := 0
		while xs.size() < n and intentos < n * 6:
			intentos += 1
			var p := Vector2(_rng.randf_range(bosque_rect.position.x + 4.0, bosque_rect.end.x - 4.0), _rng.randf_range(bosque_rect.position.y + 4.0, bosque_rect.end.y - 4.0))
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
	# roble muerto de verdad (antes un tronco hecho con cilindros); el columpio cuelga de una rama horizontal
	var malla := _malla_glb("res://zarek/arboles/%s.glb" % ("muerto_roble" if with_swing else "muerto_roble_2"))
	if malla != null:
		var mi := MeshInstance3D.new()
		mi.mesh = malla
		mi.transform = Transform3D(Basis(Vector3.UP, 0.4).scaled(Vector3(2.0, 2.0, 2.0)), c)
		add_child(mi)
	else:
		cyl(0.35, 0.6, 7.0, c + Vector3(0, 3.5, 0), _mat.corteza, self, 8)
	_static_cyl(0.6, 4.0, c + Vector3(0, 2.0, 0))
	if with_swing:
		var rama := cyl(0.1, 0.16, 3.2, c + Vector3(1.4, 5.5, 0), _mat.corteza, self, 8)
		rama.rotation.z = PI * 0.5 - 0.08
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
					_sello_marcas.append(pos)
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
	var azar := RandomNumberGenerator.new()
	azar.seed = partida_seed
	var spots := [["baja", 2.0, 2.6, "pila"], ["baja", 13.8, 11.4, "sal"], ["alta", 13.0, 11.0, "pila"], ["sotano", 10.5, 10.5, "pila"],
		["exterior", 70.0, 77.5, "sal"], ["exterior", 26.5, 17.0, "pila"], ["atico", 10.0, 6.0, "sal"], ["alta", 1.5, 6.5, "sal"]]
	if partida_seed != 0:
		# cada partida reparte de otra forma pilas y bengalas entre los mismos sitios
		var tipos := spots.map(func(x): return x[3])
		for i in range(tipos.size() - 1, 0, -1):
			var j := azar.randi_range(0, i)
			var t0: String = tipos[i]
			tipos[i] = tipos[j]
			tipos[j] = t0
		for i in spots.size():
			spots[i][3] = tipos[i]
	for s in spots:
		_pickup(cell_to_world(s[0], s[1], s[2]), s[3])

var car_pos := Vector3.ZERO
var electricidad: ZarekElectricidad
func _car(p: Vector3) -> void:
	car_pos = p
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

## Los objetos de la noche (ZarekHuida.objetos): lo que piden las salidas abiertas (llave del cuarto de Damián y
## gasolina para su camioneta; cizalla para el portón, rueda y gato para tu coche; cuerda con garfio para el muro).
const NOMBRE_OBJETO := {"cizalla": "la cizalla", "gasolina": "la lata de gasolina", "llave": "la llave del cuarto de Damián",
	"rueda": "la rueda de repuesto", "gato": "el gato del coche", "cuerda": "la cuerda", "garfio": "el garfio de hierro",
	"bateria": "la batería de la camioneta"}
var objetos_noche: Array = []

## Dónde tiene sentido cada objeto: la gasolina y la cizalla con las herramientas; la llave de repuesto de su
## cuarto en el llavero de la familia; tu rueda y tu gato (los robó de tu maletero) donde Damián guarda lo que les
## quita a sus víctimas; la cuerda con garfio en el desván o con los aperos.
const SITIOS_POR_OBJETO := {
	"gasolina": ["Sala de calderas", "Salida a la cochera", "Galería de servicio", "Cuarto de servicio"],
	"cizalla": ["Sala de calderas", "Galería de servicio", "Salida a la cochera", "Cava de vinos", "Cuarto de servicio"],
	"llave": ["Dormitorio de los padres", "Estudio del padre", "Tocador de la madre", "Cuarto de servicio", "Guardarropa"],
	"rueda": ["Salida a la cochera", "Galería de servicio", "Ático (vigas, baúles, muñecos tapados)", "Guardarropa"],
	"gato": ["Salida a la cochera", "Galería de servicio", "Ático (vigas, baúles, muñecos tapados)", "Cuarto de servicio", "Despensa"],
	"cuerda": ["Ático (vigas, baúles, muñecos tapados)", "Escondite de Damián niño", "Cuarto de plancha", "Galería de servicio"],
	"garfio": ["Sala de calderas", "Cava de vinos", "Salida a la cochera", "Cuarto de servicio"],
	"bateria": ["Salida a la cochera", "Sala de calderas", "Galería de servicio"]}
## Salas de reserva (y para los tablones).
const SITIOS_OBJETOS := ["Cocina", "Biblioteca", "Estudio del padre", "Sala de calderas", "Cuarto del hermano", "Despensa",
	"Cuarto de huéspedes", "Sala de música", "Comedor formal", "Cava de vinos", "Dormitorio de los padres", "Salón con chimenea"]
func _repartir_objetos() -> void:
	var azar := RandomNumberGenerator.new()
	azar.seed = partida_seed
	var sitios: Array[Vector3] = []
	sitios.append_array(_sello_marcas)
	ZarekTerror._rng.seed = partida_seed + 5
	for nombre in SITIOS_OBJETOS:
		var r := _sala_por_nombre(nombre)
		if r.is_empty():
			continue
		var p := ZarekTerror._sitio_libre(self, r, 0.7)
		if p != Vector3.INF:
			sitios.append(p)
	if partida_seed != 0:
		for i in range(sitios.size() - 1, 0, -1):
			var j := azar.randi_range(0, i)
			var t0 := sitios[i]
			sitios[i] = sitios[j]
			sitios[j] = t0
	objetos_noche = ZarekHuida.objetos(partida_seed)
	# cada objeto en un sitio que tenga sentido (cambia de sala cada noche, nunca dos en la misma)
	var usados: Array[int] = []
	ZarekTerror._rng.seed = partida_seed + 11
	for tipo in objetos_noche:
		var salas: Array = (SITIOS_POR_OBJETO.get(tipo, []) as Array).duplicate()
		if partida_seed != 0:
			for i in range(salas.size() - 1, 0, -1):
				var k := azar.randi_range(0, i)
				var t1 = salas[i]
				salas[i] = salas[k]
				salas[k] = t1
		var puesto := false
		for nombre in salas:
			var r := _sala_por_nombre(nombre)
			if r.is_empty() or int(r.id) in usados:
				continue
			var p := ZarekTerror._sitio_libre(self, r, 0.7)
			if p == Vector3.INF:
				continue
			usados.append(int(r.id))
			_seal(p, tipo)
			puesto = true
			break
		if not puesto:
			# todas sus salas ya tienen otro objeto: se repite sala antes que ponerlo donde no tiene sentido
			for nombre in salas:
				var r2 := _sala_por_nombre(nombre)
				if r2.is_empty():
					continue
				var p2 := ZarekTerror._sitio_libre(self, r2, 0.7)
				if p2 != Vector3.INF:
					_seal(p2, tipo)
					puesto = true
					break
		if not puesto:
			for p in sitios:
				if not room_at(p) in usados:
					usados.append(room_at(p))
					_seal(p, tipo)
					break
	# las llaves de su camioneta: en su cuarto, entre los trofeos (si esa salida está abierta esta noche)
	var rd := _sala_por_nombre("Cuarto de Damián")
	if not rd.is_empty() and ZarekHuida.salida_bloqueada(partida_seed) != "camioneta":
		ZarekTerror._rng.seed = partida_seed + 77
		var pl := ZarekTerror._sitio_libre(self, rd, 0.6)
		if pl != Vector3.INF and pl.distance_to(circle_pos) > 2.2:
			_pickup(pl, "llaves")
	# tablones con clavos para atrancar puertas (los que sobran)
	var n_tab := 0
	for p in sitios:
		if n_tab >= 3:
			break
		var libre := true
		for sl in seals:
			if (sl.pos as Vector3).distance_to(p) < 2.0:
				libre = false
		if libre:
			_pickup(p, "tablon")
			n_tab += 1

func _seal(pos: Vector3, tipo: String) -> void:
	var alto := 0.9
	var mesa := _prop("side_table_tall_01", pos, 0.4, 1.15)
	if mesa:
		alto = 0.761 * 1.15
	else:
		box(Vector3(0.8, 0.9, 0.6), pos + Vector3(0, 0.45, 0), _mat.madera)
	var n := Node3D.new()
	n.set_meta("dyn", true)
	n.position = pos + Vector3(-0.05, alto, 0)
	add_child(n)
	match tipo:
		"cizalla":
			# cizalla grande: dos mangos largos de hierro con puños de goma y las mandíbulas cortas
			var goma := _plain(Color(0.45, 0.08, 0.05), 0.7)
			for s2 in [-1.0, 1.0]:
				var mango := box(Vector3(0.62, 0.025, 0.025), Vector3(0.05, 0.02, s2 * 0.035), _mat.hierro, false, n, false)
				mango.rotation.y = s2 * 0.08
				box(Vector3(0.2, 0.035, 0.035), Vector3(0.28, 0.02, s2 * 0.06), goma, false, n, false)
				var boca := box(Vector3(0.12, 0.03, 0.04), Vector3(-0.31, 0.02, s2 * 0.012), _mat.metal, false, n, false)
				boca.rotation.y = -s2 * 0.2
			cyl(0.02, 0.02, 0.05, Vector3(-0.24, 0.02, 0), _mat.metal, n, 8)
		"rueda":
			# rueda de repuesto apoyada contra la mesa (en el suelo, de canto)
			var neu := MeshInstance3D.new()
			var tm := TorusMesh.new()
			tm.inner_radius = 0.2
			tm.outer_radius = 0.33
			tm.rings = 20
			tm.ring_segments = 10
			neu.mesh = tm
			neu.material_override = _plain(Color(0.05, 0.05, 0.05), 0.9)
			neu.position = Vector3(0, -alto + 0.34, 0.45)
			neu.rotation.x = PI * 0.5 - 0.15
			n.add_child(neu)
			var llanta := cyl(0.2, 0.2, 0.16, Vector3.ZERO, _mat.metal, neu, 16)
			llanta.rotation.x = 0.0
		"cuerda":
			# rollo de cuerda gruesa con un garfio de hierro de tres puntas
			var cuerda_m := _plain(Color(0.42, 0.34, 0.22), 0.95)
			for k in 4:
				var anillo := MeshInstance3D.new()
				var tm2 := TorusMesh.new()
				tm2.inner_radius = 0.1 + k * 0.012
				tm2.outer_radius = 0.125 + k * 0.012
				tm2.rings = 14
				tm2.ring_segments = 5
				anillo.mesh = tm2
				anillo.material_override = cuerda_m
				anillo.position = Vector3(0, 0.02 + k * 0.02, 0)
				n.add_child(anillo)
		"garfio":
			# garfio de hierro forjado de tres puntas, oxidado
			var vara2 := cyl(0.014, 0.014, 0.3, Vector3(0, 0.03, 0), _mat.hierro, n, 6)
			vara2.rotation.z = PI * 0.5
			for k in 3:
				var una2 := box(Vector3(0.12, 0.018, 0.018), Vector3(0.17, 0.03, 0), _mat.hierro, false, n, false)
				una2.rotation.y = (k - 1) * 0.9
				una2.rotation.z = 0.6
			cyl(0.025, 0.025, 0.01, Vector3(-0.16, 0.03, 0), _mat.hierro, n, 8).rotation.z = PI * 0.5
		"bateria":
			# batería de coche: caja negra, tapa gris, dos bornes
			box(Vector3(0.26, 0.19, 0.17), Vector3(0, 0.095, 0), _plain(Color(0.06, 0.06, 0.06), 0.5), false, n, false)
			box(Vector3(0.27, 0.025, 0.18), Vector3(0, 0.2, 0), _plain(Color(0.3, 0.3, 0.28), 0.6), false, n, false)
			cyl(0.015, 0.015, 0.03, Vector3(-0.08, 0.225, 0.04), _plain(Color(0.6, 0.1, 0.05), 0.4), n, 8)
			cyl(0.015, 0.015, 0.03, Vector3(0.08, 0.225, 0.04), _mat.oscuro, n, 8)
		"gato":
			# gato de tijera: base, brazos en rombo y el husillo
			box(Vector3(0.3, 0.02, 0.09), Vector3(0, 0.01, 0), _mat.hierro, false, n, false)
			for s2 in [-1.0, 1.0]:
				for s3 in [-1.0, 1.0]:
					var br := box(Vector3(0.13, 0.015, 0.05), Vector3(s2 * 0.06, 0.06 + (s3 + 1.0) * 0.035, 0), _mat.hierro, false, n, false)
					br.rotation.z = s2 * s3 * 0.6
			box(Vector3(0.12, 0.02, 0.08), Vector3(0, 0.17, 0), _mat.hierro, false, n, false)
			var hus := cyl(0.008, 0.008, 0.36, Vector3(0, 0.095, 0), _mat.metal, n, 6)
			hus.rotation.z = PI * 0.5
		"gasolina":
			# lata de gasolina roja, abollada y oxidada, con asa y boquilla
			var roja := _plain(Color(0.45, 0.06, 0.04), 0.5, 0.6)
			box(Vector3(0.3, 0.38, 0.16), Vector3(0, 0.19, 0), roja, false, n, false)
			for s2 in [-1.0, 1.0]:
				box(Vector3(0.03, 0.03, 0.12), Vector3(s2 * 0.07, 0.4, 0), roja, false, n, false)
			box(Vector3(0.17, 0.03, 0.03), Vector3(0, 0.42, 0), roja, false, n, false)
			var boq := cyl(0.02, 0.025, 0.08, Vector3(0.12, 0.42, 0), _mat.metal, n, 8)
			boq.rotation.z = -0.5
		"llave":
			var ll := _prop("llave_antigua", Vector3.ZERO, 0.3, 1.6, false, n)
			if ll == null:
				box(Vector3(0.14, 0.01, 0.03), Vector3(0, 0.01, 0), _mat.oro, false, n, false)
			# etiqueta de cartón atada con cordel: «CUARTO D.»
			box(Vector3(0.06, 0.003, 0.04), Vector3(0.1, 0.005, 0.03), _mat.sabana, false, n, false)
	seals.append({"node": n, "pos": pos, "taken": false, "tipo": tipo})

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
		# la prenda girada: su ancho va hacia el fondo del armario y su grosor hacia los lados; las dos medidas se
		# limitan para que no se salga por las paredes (antes asomaba una tela blanca por el costado)
		var ancho := minf(1.0, 0.56 / maxf(t.x * esc, 0.1))
		var grosor := minf(0.6, 2.0 * (0.72 - absf(x)) / maxf(t.z * esc, 0.05))
		var pr := _prop(nombre, Vector3(x, 1.96 - t.y * esc, 0.07), PI * 0.5, esc, false, n)
		if pr:
			pr.scale = Vector3(esc * ancho, esc, esc * grosor)
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
	var l := {"node": n, "light": light, "bulb": bm, "pos": pos, "room": id, "on": false, "broken": false, "base": 2.4, "flicker": 0.0, "modo": "fija", "e": 1.0, "obj": 1.0, "t": 0.0, "rafaga": 0}
	lamps.append(l)
	if id >= 0:
		rooms[id]["lamps"] = rooms[id].get("lamps", []) + [l]

# ---------------- luz eléctrica: bombillas de filamento, apliques y lámparas colgantes ----------------
## Bombillas de filamento de carbón de principios de siglo (unos 2700 K). Cada sala o tramo de pasillo tiene un
## modo: «fija» (luz estable), «parpadea» (la mayoría: caídas breves, ráfagas y apagones con el zumbido de la
## corriente) o «apagada» (bombillas fundidas: salas y tramos oscuros).
## Bombilla incandescente vieja (~2400 K): luz naranja cálida, no blanca.
const COLOR_BOMBILLA := Color(1.0, 0.72, 0.44)
static var _tex_halo: ImageTexture
## Bombilla Edison real (modelo con cristal, casquillo y filamento) colgando boca abajo en `pos`. Devuelve el
## nodo y añade a `mats` los materiales que brillan (filamento y cristal) para encenderlos con la corriente.
func _bombilla_real(padre: Node3D, pos: Vector3, mats: Array) -> Node3D:
	const RUTA := "res://zarek/objetos/e_bombilla_edison.glb"
	if not ResourceLoader.exists(RUTA):
		return null
	var b: Node3D = (load(RUTA) as PackedScene).instantiate()
	b.rotation.x = PI
	b.position = pos
	b.set_meta("dyn", true)
	padre.add_child(b)
	for mi in b.find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		m3.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for k in m3.get_surface_override_material_count():
			var mt := m3.mesh.surface_get_material(k)
			if not (mt is StandardMaterial3D):
				continue
			var nm := String(mt.resource_name).to_lower()
			var c := (mt as StandardMaterial3D).duplicate() as StandardMaterial3D
			if nm.begins_with("glow"):
				c.emission_enabled = true
				c.emission = Color(1.0, 0.55, 0.2)
				c.emission_energy_multiplier = 0.0
				c.set_meta("brillo", 9.0)
			elif nm.begins_with("glass"):
				c.emission_enabled = true
				c.emission = Color(1.0, 0.7, 0.4)
				c.emission_energy_multiplier = 0.0
				c.set_meta("brillo", 0.7)
			else:
				continue
			m3.set_surface_override_material(k, c)
			mats.append(c)
	return b

## Brillo del filamento y del cristal de las bombillas reales de una lámpara (0 apagada, 1 encendida).
func _brillo(l: Dictionary, e: float) -> void:
	for c in l.get("cristales", []):
		(c as StandardMaterial3D).emission_energy_multiplier = float((c as StandardMaterial3D).get_meta("brillo", 1.0)) * e * e
## Halo alrededor de una bombilla encendida (se ve brillar aunque el móvil no tenga resplandor).
func _halo(padre: Node3D, pos: Vector3, tam: float) -> MeshInstance3D:
	if _tex_halo == null:
		var s := 64
		var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
		for y in s:
			for x in s:
				var d := Vector2(x - s * 0.5 + 0.5, y - s * 0.5 + 0.5).length() / (s * 0.5)
				var a := clampf(1.0 - d, 0.0, 1.0)
				a = a * a * (0.35 + 0.65 * a * a)
				img.set_pixel(x, y, Color(1, 1, 1, a))
		_tex_halo = ImageTexture.create_from_image(img)
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(tam, tam)
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = _tex_halo
	m.albedo_color = Color(1.0, 0.68, 0.38, 0.75)
	m.no_depth_test = false
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	mi.visible = false
	mi.set_meta("dyn", true)
	padre.add_child(mi)
	return mi
var _malla_bombilla: Mesh
var _malla_filamento: Mesh
var _mat_vidrio_bombilla: StandardMaterial3D
var _mat_esmalte: StandardMaterial3D
var _mat_tulipa: StandardMaterial3D

## Monta un modelo de lámpara (objetos/luz_*.glb) dentro de n y devuelve su caja en el espacio de n. Si es de
## pared, se gira para que su lado plano quede contra la pared (local −Z) y se apoya en ella.
const LUZ_PARED := {"aplique_antiguo": 0.0, "aplique_brazo": PI, "aplique_cristal": PI * 0.5, "aplique_doble": PI, "aplique_retro": PI * 0.5}
func _modelo_luz(nombre: String, n: Node3D, pared: bool) -> AABB:
	var real := _prop("luz_" + nombre, Vector3.ZERO, float(LUZ_PARED.get(nombre, 0.0)), 1.8 if nombre == "colgante_esmalte" else 1.0, false, n)
	if real == null:
		return AABB(Vector3(-0.1, -0.2, 0), Vector3(0.2, 0.2, 0.2))
	var ab := AABB()
	var primero := true
	var inv := n.global_transform.affine_inverse()
	for mi in real.find_children("*", "MeshInstance3D", true, false):
		var g := (mi as MeshInstance3D)
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var caja: AABB = (inv * g.global_transform) * g.get_aabb()
		ab = caja if primero else ab.merge(caja)
		primero = false
	# de pared: el centro a la altura del nodo y el fondo tocando la pared; colgante: la parte de arriba en el cable
	var mover := Vector3(-ab.get_center().x, -ab.get_center().y, -ab.position.z) if pared else Vector3(-ab.get_center().x, -ab.end.y, -ab.get_center().z)
	real.position += mover
	ab.position += mover
	return ab

func _bombilla(padre: Node3D, pos: Vector3, compartido: StandardMaterial3D = null, solo_nucleo := false) -> StandardMaterial3D:
	if _malla_bombilla == null:
		var sm := SphereMesh.new()
		sm.radius = 0.034
		sm.height = 0.085
		sm.radial_segments = 12
		sm.rings = 6
		_malla_bombilla = sm
		var fm := CylinderMesh.new()
		fm.top_radius = 0.004
		fm.bottom_radius = 0.004
		fm.height = 0.045
		fm.radial_segments = 4
		_malla_filamento = fm
		_mat_vidrio_bombilla = _plain(Color(1.0, 0.92, 0.8, 0.35), 0.1)
		_mat_vidrio_bombilla.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat_esmalte = _plain(Color(0.16, 0.22, 0.18), 0.35, 0.2)
		_mat_tulipa = _plain(Color(0.95, 0.88, 0.75, 0.82), 0.3)
		_mat_tulipa.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat_tulipa.cull_mode = BaseMaterial3D.CULL_DISABLED
	if solo_nucleo:
		# solo el resplandor del filamento dentro de una pantalla o tulipa del modelo
		var fil0 := compartido
		if fil0 == null:
			fil0 = _plain(Color(1, 0.8, 0.5), 0.5)
			fil0.emission_enabled = true
			fil0.emission = Color(1.0, 0.6, 0.25)
			fil0.emission_energy_multiplier = 0.0
		var nucleo := MeshInstance3D.new()
		nucleo.mesh = _malla_bombilla
		nucleo.scale = Vector3(0.5, 0.65, 0.5)
		nucleo.material_override = fil0
		nucleo.position = pos
		nucleo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		nucleo.set_meta("dyn", true)
		padre.add_child(nucleo)
		return fil0
	# casquillo de latón, ampolla de cristal y el filamento incandescente (su brillo sigue a la luz)
	cyl(0.016, 0.016, 0.035, pos + Vector3(0, 0.055, 0), _mat.laton_viejo if _mat.has("laton_viejo") else _mat.oro, padre, 8)
	var vidrio := MeshInstance3D.new()
	vidrio.mesh = _malla_bombilla
	vidrio.material_override = _mat_vidrio_bombilla
	vidrio.position = pos
	vidrio.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(vidrio)
	var fil := _plain(Color(1, 0.8, 0.5), 0.5)
	fil.emission_enabled = true
	fil.emission = Color(1.0, 0.6, 0.25)
	fil.emission_energy_multiplier = 0.0
	# halo: la ampolla entera brilla un poco
	var halo := MeshInstance3D.new()
	halo.mesh = _malla_bombilla
	halo.scale = Vector3(0.45, 0.6, 0.45)
	halo.material_override = fil
	halo.position = pos
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	padre.add_child(halo)
	halo.set_meta("dyn", true)
	return fil

## Crea una luz eléctrica. tipo: "colgante" (pantalla de esmalte), "desnuda" (bombilla colgando del cable),
## "aplique" (brazo de latón y tulipa en la pared; dir = hacia dónde mira, fuera de la pared).
func _luz_electrica(pos: Vector3, tipo: String, dir := Vector3.ZERO, alcance := 7.0) -> Dictionary:
	var id := room_at(pos + Vector3(0, 0.3, 0))
	var n := Node3D.new()
	var centro_luz := Vector3.ZERO
	var fil: StandardMaterial3D
	var modelo := String(ZarekHistoria.LAMPARA.get(String(rooms[id].name) if id >= 0 else "", ""))
	var t_sala := String(rooms[id].type) if id >= 0 else ""
	if tipo == "aplique":
		n.position = Vector3(pos.x, pos.y + 2.0, pos.z)
		n.rotation.y = atan2(dir.x, dir.z)
		add_child(n)
		if modelo == "" or not modelo.begins_with("aplique"):
			if t_sala in ["dormitorio", "epicentro"]:
				modelo = ["aplique_doble", "aplique_antiguo"][_rng.randi() % 2]
			elif t_sala in ["servicio", "sotano"]:
				modelo = ["aplique_cristal", "aplique_retro"][_rng.randi() % 2]
			else:
				modelo = ["aplique_antiguo", "aplique_brazo", "aplique_retro"][_rng.randi() % 3]
		var ab := _modelo_luz(modelo, n, true)
		var c := ab.get_center()
		if modelo == "aplique_doble":
			fil = _bombilla(n, Vector3(-ab.size.x * 0.33, c.y + 0.02, c.z + 0.05), null, true)
			_bombilla(n, Vector3(ab.size.x * 0.33, c.y + 0.02, c.z + 0.05), fil, true)
		else:
			fil = _bombilla(n, Vector3(0, c.y + 0.03, c.z + 0.02), null, true)
		centro_luz = Vector3(0, c.y + 0.05, ab.end.z + 0.08)
	else:
		var techo := pos.y + (WALL_H if level_of(pos.y + 0.3) < 2 else 3.3)
		var cable := 0.5 + _rng.randf() * 0.5 if tipo == "colgante" else 0.8 + _rng.randf() * 0.6
		n.position = Vector3(pos.x, techo, pos.z)
		add_child(n)
		cyl(0.035, 0.035, 0.03, Vector3(0, -0.015, 0), _mat.oscuro, n, 10)
		cyl(0.004, 0.004, cable, Vector3(0, -cable * 0.5, 0), _mat.oscuro, n, 4)
		if tipo == "colgante":
			if modelo == "" or not modelo.begins_with("colgante"):
				modelo = "colgante_jaula" if t_sala in ["servicio", "sotano"] or int(rooms[id].level if id >= 0 else 0) >= 2 else "colgante_industrial"
			var cuelga := Node3D.new()
			cuelga.position = Vector3(0, -cable, 0)
			n.add_child(cuelga)
			var ab := _modelo_luz(modelo, cuelga, false)
			fil = _bombilla(cuelga, Vector3(0, ab.position.y + ab.size.y * (0.22 if modelo == "colgante_jaula" else 0.12), 0), null, true)
			centro_luz = Vector3(0, -cable + ab.position.y + ab.size.y * 0.1, 0)
		else:
			# bombilla Edison de verdad colgando del cable: casquillo, cristal y filamento que se pone al rojo
			var cristales: Array = []
			var b := _bombilla_real(n, Vector3(0, -cable, 0), cristales)
			if b == null:
				b = _prop("luz_bombilla_edison", Vector3(0, -cable - 0.135, 0), 0.0, 1.1, false, n)
				if b:
					b.rotation.x = PI
					b.position.y = -cable
			fil = _bombilla(n, Vector3(0, -cable - 0.09, 0), null, true)
			centro_luz = Vector3(0, -cable - 0.1, 0)
			n.set_meta("cristales", cristales)
	var light := OmniLight3D.new()
	light.position = centro_luz
	light.light_color = COLOR_BOMBILLA
	# caída física (casi cuadrática): charco de luz cerca de la lámpara y penumbra en los rincones
	light.omni_range = alcance * 1.3
	light.omni_attenuation = 1.9
	light.light_energy = 2.6 if tipo == "aplique" else (3.4 if tipo == "colgante" else 2.8)
	light.light_size = 0.05
	light.light_specular = 0.45
	var halo := _halo(n, centro_luz, 0.55 if tipo == "aplique" else 0.75)
	light.visible = false
	n.add_child(light)
	var l := {"node": n, "light": light, "bulb": fil, "pos": pos, "room": id, "on": false, "broken": false, "halo": halo, "tipo": tipo,
		"cristales": n.get_meta("cristales", []),
		"base": light.light_energy, "flicker": 0.0, "modo": "fija", "e": 1.0, "obj": 1.0, "t": _rng.randf() * 4.0, "rafaga": 0}
	lamps.append(l)
	if id >= 0:
		rooms[id]["lamps"] = rooms[id].get("lamps", []) + [l]
	return l

## ¿Hay pared en ese borde de la sala (no puerta, ni hueco hacia la misma sala)?
func _sep_pared(p: Vector3, fuera: Vector3) -> float:
	return (WT * 0.5 + 0.04) if room_at(p + fuera * 0.4 + Vector3(0, 0.5, 0)) >= 0 else 0.27

func _pared_libre(r: Dictionary, p: Vector3, fuera: Vector3) -> bool:
	if not door_near(p, 1.25).is_empty():
		return false
	var otra := room_at(p + fuera * 0.4 + Vector3(0, 0.5, 0))
	return otra != int(r.id)

func _iluminar_salas() -> void:
	for r in rooms:
		var t := String(r.type)
		if t in ["jardin", "tunel", "roca", "agua", "camino", "edificio"] or int(r.level) < -1:
			continue
		var nombre := String(r.name)
		if nombre.begins_with("MANSI") or nombre.begins_with("Terrenos"):
			continue
		var rc: Rect2 = r.rect
		var y := float(r.y)
		var nuevas: Array = []
		var es_pasillo := t == "pasillo" or nombre.begins_with("Pasillo") or nombre.begins_with("Galería")
		if es_pasillo:
			# apliques alternando paredes cada ~5,5 m a lo largo del pasillo
			var largo_x := rc.size.x >= rc.size.y
			var largo := rc.size.x if largo_x else rc.size.y
			var n := maxi(2, int(largo / 5.5))
			for i in n:
				var f := (i + 0.5) / n
				var lado := i % 2
				var p: Vector3
				var fuera: Vector3
				if largo_x:
					p = Vector3(rc.position.x + rc.size.x * f, y, rc.position.y if lado == 0 else rc.end.y)
					fuera = Vector3(0, 0, -1 if lado == 0 else 1)
				else:
					p = Vector3(rc.position.x if lado == 0 else rc.end.x, y, rc.position.y + rc.size.y * f)
					fuera = Vector3(-1 if lado == 0 else 1, 0, 0)
				var hecho := false
				for desliza in [0.0, 0.9, -0.9, 1.8, -1.8]:
					var q := p + (Vector3(desliza, 0, 0) if largo_x else Vector3(0, 0, desliza))
					for intento in 2:
						var qq := q
						var ff := fuera
						if intento == 1:
							ff = -fuera
							qq = q - fuera * (rc.size.y if largo_x else rc.size.x)
						if _pared_libre(r, qq, ff):
							nuevas.append(_luz_electrica(qq - ff * _sep_pared(qq, ff), "aplique", -ff, 6.5))
							hecho = true
							break
					if hecho:
						break
		elif r.get("lamps", []).is_empty():
			var c := rc.get_center()
			var tipo := "colgante"
			if t in ["servicio", "sotano", "bano", "cocina"] or int(r.level) >= 2:
				tipo = "desnuda" if _rng.randf() < 0.8 else "colgante"
			elif _rng.randf() < 0.3:
				tipo = "desnuda"
			var alc := clampf(maxf(rc.size.x, rc.size.y) * 0.75, 5.5, 10.0)
			if t == "dormitorio" or t == "epicentro":
				# dos apliques a los lados del centro de la pared más larga
				var largo_x := rc.size.x >= rc.size.y
				for k in [-1, 1]:
					var p := Vector3(c.x + (k * rc.size.x * 0.22 if largo_x else 0.0), y, c.y + (0.0 if largo_x else k * rc.size.y * 0.22))
					var fuera := Vector3(0, 0, -1) if largo_x else Vector3(-1, 0, 0)
					var q := Vector3(p.x if largo_x else rc.position.x, y, rc.position.y if largo_x else p.z)
					if _pared_libre(r, q, fuera):
						nuevas.append(_luz_electrica(q - fuera * _sep_pared(q, fuera), "aplique", -fuera, alc * 0.8))
			if nuevas.is_empty():
				nuevas.append(_luz_electrica(Vector3(c.x + 0.3, y, c.y + 0.3), tipo, Vector3.ZERO, alc))
		# modo de cada luz: lo fija la historia o, si no, el azar (la mayoría parpadean)
		var modo_sala := String(ZarekHistoria.LUZ_MODO.get(nombre, ""))
		var todas: Array = r.get("lamps", [])
		for i in todas.size():
			var l: Dictionary = todas[i]
			var modo := modo_sala
			if modo == "tramos":
				modo = ["fija", "parpadea", "apagada", "parpadea"][int(i / 2) % 4]
			elif modo == "":
				var dado := _rng.randf()
				modo = "parpadea" if dado < 0.35 else ("fija" if dado < 0.55 else "apagada")
			elif modo == "parpadea" and _rng.randf() < 0.15:
				modo = "apagada"
			l.modo = modo
			if modo == "apagada":
				l.broken = true
			if ZarekHistoria.LUZ.has(nombre):
				(l.light as OmniLight3D).light_color = ZarekHistoria.LUZ[nombre]
			if modo == "parpadea":
				var zum := AudioStreamPlayer3D.new()
				zum.stream = AetherSynth.make("zumbido")
				zum.volume_db = -26.0
				zum.unit_size = 1.2
				zum.max_distance = 7.0
				zum.autoplay = true
				zum.position = (l.light as OmniLight3D).position
				(l.node as Node3D).add_child(zum)
				l["zumbido"] = zum

## Parpadeo realista de una bombilla vieja: casi siempre encendida, con caídas breves, ráfagas de cortes y algún
## apagón de un par de segundos; el filamento tarda unas centésimas en enfriarse y calentarse.
func _parpadeo(l: Dictionary, delta: float) -> void:
	l.t -= delta
	if l.t <= 0.0:
		if l.rafaga > 0:
			l.rafaga -= 1
			l.obj = 0.05 if l.obj > 0.5 else 1.0
			l.t = randf_range(0.03, 0.12)
		else:
			var dado := randf()
			if l.obj < 0.5:
				l.obj = 1.0
				l.t = randf_range(1.5, 7.0)
			elif dado < 0.45:
				l.obj = randf_range(0.2, 0.6)
				l.t = randf_range(0.05, 0.25)
			elif dado < 0.85:
				l.rafaga = randi_range(3, 9)
				l.t = 0.0
			else:
				l.obj = 0.0
				l.t = randf_range(0.6, 2.5)
	var tau := 0.035 if l.obj < l.e else 0.06
	l.e = lerpf(float(l.e), float(l.obj), 1.0 - exp(-delta / tau))
	var e: float = l.e
	(l.light as OmniLight3D).light_energy = float(l.base) * e
	(l.bulb as StandardMaterial3D).emission_energy_multiplier = 4.0 * e * e
	_brillo(l, e)
	if l.has("halo") and is_instance_valid(l.halo):
		(l.halo as MeshInstance3D).visible = e > 0.08
		((l.halo as MeshInstance3D).material_override as StandardMaterial3D).albedo_color.a = 0.75 * e
	if l.has("zumbido"):
		(l.zumbido as AudioStreamPlayer3D).volume_db = -26.0 + 10.0 * (1.0 - e) * float(e > 0.05)

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
	l.bulb.emission_energy_multiplier = 3.5 if on else 0.0
	_brillo(l, 1.0 if on else 0.0)
	if l.has("halo") and is_instance_valid(l.halo):
		(l.halo as MeshInstance3D).visible = on
	if l.has("zumbido"):
		(l.zumbido as AudioStreamPlayer3D).playing = on

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

## Donde duerme Damián (antes el círculo de sal): un colchón asqueroso en el suelo, una manta, un cubo y
## velas. Aquí se prepara la trampa; el centro (radio 1,9) queda libre para moverse.
func _salt_circle(pos: Vector3) -> void:
	var tela := StandardMaterial3D.new()
	tela.albedo_texture = load("res://zarek/terror/tela_sangre.png")
	tela.roughness = 0.95
	var lado := _plain(Color(0.2, 0.15, 0.11), 0.95)
	var base := box(Vector3(1.04, 0.15, 2.04), pos + Vector3(0, 0.075, 0), lado, false, self, false)
	base.rotation.y = 0.15
	var colchon := box(Vector3(0.98, 0.04, 1.98), pos + Vector3(0, 0.165, 0), _pbr("Fabric028", 1.0, Color(0.62, 0.56, 0.46), 1.0), false, self, false)
	colchon.rotation.y = 0.15
	var mancha := ZarekTerror._calco(self, "sangre_charco_2", pos + Vector3(0.1, 0.186, -0.3), Vector3.UP, Vector2(0.9, 0.9), 0.7)
	mancha.set_meta("dyn", true)
	ZarekTerror._calco(self, "sangre_salpicadura_1", pos + Vector3(-0.2, 0.186, 0.5), Vector3.UP, Vector2(0.6, 0.6), 2.0).set_meta("dyn", true)
	var manta := box(Vector3(0.9, 0.05, 1.0), pos + Vector3(0.05, 0.2, 0.4), _pbr("Fabric028", 1.0, Color(0.25, 0.22, 0.18), 1.0), false, self, false)
	manta.rotation = Vector3(0.0, 0.4, 0.05)
	box(Vector3(0.45, 0.14, 0.3), pos + Vector3(-0.05, 0.25, -0.75), _mat.sabana, false, self, false)  # almohada
	for i in 6:
		var a := TAU * i / 6.0 + 0.4
		var cp := pos + Vector3(cos(a) * 2.4, 0, sin(a) * 2.4)
		cyl(0.04, 0.05, 0.22, cp + Vector3(0, 0.11, 0), _mat.moldura, self, 6)
		cyl(0.0, 0.025, 0.07, cp + Vector3(0, 0.26, 0), _mat.fuego, self, 6)
	var l := OmniLight3D.new()
	l.position = pos + Vector3(0, 0.6, 0)
	l.light_color = Color(1, 0.5, 0.25)
	l.omni_range = 6.0
	l.light_energy = 0.6
	l.set_meta("e", 0.6)
	add_child(l)
	fires.append(l)

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
	elif kind == "llaves":
		# llavero del coche alquilado con su etiqueta
		mi = box(Vector3(0.05, 0.008, 0.025), Vector3(0, alto + 0.005, 0), _mat.metal, false, n, false)
		cyl(0.018, 0.018, 0.006, Vector3(0.04, 0.0, 0.0), _mat.laton_viejo, mi, 12)
		box(Vector3(0.07, 0.004, 0.035), Vector3(0.09, 0.0, 0.01), _plain(Color(0.75, 0.7, 0.55), 0.8), false, mi, false)
	elif kind == "tablon":
		# tablones de madera con clavos y un martillo
		mi = box(Vector3(0.9, 0.03, 0.14), Vector3(0, alto + 0.016, 0), _mat.madera_vieja, false, n, false)
		box(Vector3(0.85, 0.03, 0.13), Vector3(0.02, 0.03, 0.03), _mat.madera_vieja, false, mi, false).rotation.y = 0.2
		box(Vector3(0.03, 0.03, 0.28), Vector3(-0.2, 0.06, 0.1), _mat.madera, false, mi, false)
		box(Vector3(0.1, 0.035, 0.035), Vector3(-0.2, 0.06, 0.24), _mat.hierro, false, mi, false)
	else:
		# bengalas de carretera (las que llevaban las víctimas): dos tubos rojos con capuchón
		var rojo := _plain(Color(0.6, 0.05, 0.03), 0.5)
		mi = cyl(0.018, 0.018, 0.24, Vector3(0, alto + 0.018, 0), rojo, n, 10)
		mi.rotation.z = PI * 0.5
		cyl(0.02, 0.02, 0.04, Vector3(0.13, alto + 0.018, 0), _mat.oscuro, mi if false else n, 10).rotation.z = PI * 0.5
		var otra := cyl(0.018, 0.018, 0.24, Vector3(0.02, alto + 0.018, 0.05), rojo, n, 10)
		otra.rotation = Vector3(0, 0.3, PI * 0.5)
	pickups.append({"node": n, "pos": pos, "kind": kind, "taken": false, "item": mi})

# ---------------- pasos especiales ----------------
func _portals() -> void:
	# escaleras de caracol: una sola escalera entera por tramo; arriba se llega al borde del hueco
	var textos := [["subir por la escalera de caracol", "bajar por la escalera de caracol"], ["subir al mirador de la torre", "bajar de la torre"], ["subir al ático", "bajar del ático"]]
	for i in CARACOLES.size():
		var c: Array = CARACOLES[i]
		var abajo := _caracol_centro(c)
		var y_arriba := lvl_y(int(plan[c[3]].nivel))
		_caracol(abajo, y_arriba - abajo.y)
		# punto de llegada arriba: junto al hueco, hacia el interior de la sala de arriba
		var sala := room_at(Vector3(abajo.x, y_arriba + 0.5, abajo.z))
		var hacia := Vector3(1, 0, 0)
		if sala >= 0:
			var cr: Vector2 = (rooms[sala].rect as Rect2).get_center()
			hacia = Vector3(cr.x - abajo.x, 0, cr.y - abajo.z).normalized()
		var llegada := Vector3(abajo.x, y_arriba, abajo.z) + hacia * 1.8
		_barandilla_hueco(Vector3(abajo.x, y_arriba, abajo.z), hacia)
		portals.append({"pos": abajo + Vector3(0, 0, 0) - hacia * 0.0 + hacia * 1.1, "to": llegada, "text": textos[i][0]})
		portals.append({"pos": llegada, "to": abajo + hacia * 1.3, "text": textos[i][1]})
	var links := [
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
var _mat_hueco: StandardMaterial3D
var chimeneas: Array = []

## Escalera de caracol de hierro con peldaños de madera: sube «alto» metros (hasta el suelo de la planta de
## arriba, a través del hueco del techo), con pasamanos en espiral.
func _caracol(p: Vector3, alto := LEVEL_H) -> void:
	var n := int(round(alto / 0.27))
	var sube := alto / n
	var giro := TAU * 1.05 / n
	cyl(0.08, 0.1, alto + 0.1, p + Vector3(0, alto * 0.5, 0), _mat.metal, self, 12)
	var mano_prev := Vector3.ZERO
	for k in n:
		var ang := k * giro
		var y := (k + 1) * sube
		var dir := Vector3(cos(ang), 0, sin(ang))
		# peldaño en abanico: más ancho por fuera
		var st := box(Vector3(0.98, 0.05, 0.3), p + dir * 0.55 + Vector3(0, y - 0.025, 0), _mat.madera, false, self)
		st.rotation.y = -ang
		var tab := box(Vector3(0.9, 0.012, 0.36), p + dir * 0.58 + Vector3(0, y + 0.005, 0), _mat.madera_clara, false, self, false)
		tab.rotation.y = -ang
		# balaustre y tramo de pasamanos
		var bp := p + dir * 1.02 + Vector3(0, y, 0)
		var bal := cyl(0.012, 0.012, 0.92, bp + Vector3(0, 0.46, 0), _mat.metal, self, 5)
		bal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mano := bp + Vector3(0, 0.93, 0)
		if k > 0:
			var seg := cyl(0.018, 0.018, mano.distance_to(mano_prev), (mano + mano_prev) * 0.5, _mat.metal, self, 6)
			seg.look_at_from_position(seg.position, mano, Vector3.UP if absf((mano - mano_prev).normalized().y) < 0.99 else Vector3.RIGHT)
			seg.rotate_object_local(Vector3.RIGHT, PI * 0.5)
			seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mano_prev = mano

## Barandilla de madera alrededor del hueco de una escalera de caracol en la planta de arriba, con el lado que da a
## «hacia» abierto (por ahí se sale de la escalera). Paredes invisibles para no caer por el hueco.
func _barandilla_hueco(c: Vector3, hacia: Vector3) -> void:
	var lados := [[Vector3(-1.2, 0, -1.2), Vector3(1.2, 0, -1.2), Vector3(0, 0, -1)], [Vector3(1.2, 0, -1.2), Vector3(1.2, 0, 1.2), Vector3(1, 0, 0)],
		[Vector3(1.2, 0, 1.2), Vector3(-1.2, 0, 1.2), Vector3(0, 0, 1)], [Vector3(-1.2, 0, 1.2), Vector3(-1.2, 0, -1.2), Vector3(-1, 0, 0)]]
	var abierto := 0
	var mejor := -2.0
	for i in 4:
		var d: float = (lados[i][2] as Vector3).dot(hacia)
		if d > mejor:
			mejor = d
			abierto = i
	for i in 4:
		var p0: Vector3 = c + lados[i][0]
		var p1: Vector3 = c + lados[i][1]
		var lg := p0.distance_to(p1)
		var md := (p0 + p1) * 0.5
		var horiz := absf(p1.x - p0.x) > 0.01
		# canto del suelo alrededor del hueco
		box(Vector3(lg, 0.2, 0.06) if horiz else Vector3(0.06, 0.2, lg), md + Vector3(0, -0.1, 0), _mat.madera, false, null, false)
		if i == abierto:
			continue
		box(Vector3(lg, 0.07, 0.09) if horiz else Vector3(0.09, 0.07, lg), md + Vector3(0, 0.98, 0), _mat.madera, false)
		var nb := int(lg / 0.22)
		for k in nb:
			var bal := cyl(0.016, 0.024, 0.92, p0.lerp(p1, (k + 0.5) / nb) + Vector3(0, 0.49, 0), _mat.madera, null, 6)
			bal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var col := box(Vector3(lg, 1.1, 0.1) if horiz else Vector3(0.1, 1.1, lg), md + Vector3(0, 0.55, 0), _mat.madera, true)
		col.visible = false
		col.set_meta("dyn", true)

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
	ZarekEscondites.aplicar(self, deco)
	_pinturas_distintas()
	_identidad_salas()
	ZarekAbandono.aplicar(self)
	ZarekTerror.aplicar(self)
	ZarekGore.aplicar(self)
	_repartir_objetos()
	if OS.get_environment("SIN_RUINA") == "":
		ZarekRuina.aplicar(self)
	if OS.get_environment("SIN_DIVISIONES") == "":
		ZarekDivisiones.aplicar(self)
	electricidad = ZarekElectricidad.new()
	electricidad.instalar(self)
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

## En la GPU del móvil (media precisión) un material casi espejo desborda el brillo especular: manchas blancas
## con puntos negros. Se sube la rugosidad mínima a 0,15 en todos los materiales.
func _rugosidad_minima() -> void:
	var vistos := {}
	for g in find_children("*", "GeometryInstance3D", true, false):
		var gi := g as GeometryInstance3D
		var mats: Array = []
		if gi.material_override:
			mats.append(gi.material_override)
		var malla: Mesh = null
		if gi is MeshInstance3D:
			malla = (gi as MeshInstance3D).mesh
			for si in (gi as MeshInstance3D).get_surface_override_material_count():
				mats.append((gi as MeshInstance3D).get_surface_override_material(si))
		elif gi is MultiMeshInstance3D and (gi as MultiMeshInstance3D).multimesh:
			malla = (gi as MultiMeshInstance3D).multimesh.mesh
		elif gi is CPUParticles3D:
			malla = (gi as CPUParticles3D).mesh
		if malla:
			for si in malla.get_surface_count():
				mats.append(malla.surface_get_material(si))
		for mt in mats:
			if mt is StandardMaterial3D and not vistos.has(mt):
				vistos[mt] = true
				var sm := mt as StandardMaterial3D
				if sm.roughness < 0.15 and sm.roughness_texture == null:
					sm.roughness = 0.15
				if sm.clearcoat_enabled:
					sm.clearcoat_roughness = maxf(sm.clearcoat_roughness, 0.15)

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
			rb.sonido = "impacto_metal" if ZarekSonido.hay("impacto_metal") else "tintineo"
		elif rb.rompible:
			rb.sonido = "impacto_ceramica" if ZarekSonido.hay("impacto_ceramica") else "tintineo"
		elif nombre.contains("book") or nombre.contains("bible") or nombre.contains("paper") or nombre.contains("letter") or nombre.contains("scroll") or nombre.contains("map"):
			rb.sonido = "impacto_libro" if ZarekSonido.hay("impacto_libro") else "golpe_madera"
		elif nombre.contains("teddy") or nombre.contains("pillow") or nombre.contains("shawl") or nombre.contains("sack") or nombre.contains("dress") or nombre.contains("hat") or nombre.contains("towel") or nombre.contains("glove"):
			rb.sonido = "impacto_tela" if ZarekSonido.hay("impacto_tela") else "golpe_madera"
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
func _alfombra_mat(nombre: String) -> bool:
	if _mat.has("alf_" + nombre):
		return true
	var ruta := "res://zarek/texturas/alfombras/%s.jpg" % nombre
	if not ResourceLoader.exists(ruta):
		return false
	var m: StandardMaterial3D = _mat.persa.duplicate()
	m.albedo_texture = load(ruta)
	m.albedo_color = Color(0.92, 0.9, 0.88)
	m.uv1_scale = Vector3(3, 2, 1)
	m.uv1_offset = Vector3.ZERO
	m.uv1_triplanar = false
	_mat["alf_" + nombre] = m
	return true

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
	mi.material_override = _mat.persa
	var sala := room_at(c + Vector3(0, 0.3, 0))
	var aspecto := 1.0
	if sala >= 0:
		var var_a := String(ZarekHistoria.ALFOMBRA.get(String(rooms[sala].name), ["azul", "oro", "", "verde"][sala % 4]))
		# alfombras reales escaneadas (Objaverse, CC-BY): azul = persa azul marino, oro = medallón beige,
		# "" = persa descolorida y gastada; verde = la persa de siempre teñida
		var real := {"azul": "cuatro_c", "oro": "nana", "": "gastada", "verde": "nana", "rojo": "cuatro_d", "granate": "cuatro_b"}
		if real.has(var_a) and _alfombra_mat(real[var_a]):
			mi.material_override = _mat["alf_" + String(real[var_a])]
			var tx: Texture2D = (mi.material_override as StandardMaterial3D).albedo_texture
			aspecto = float(tx.get_width()) / float(tx.get_height())
		elif _mat.has("persa_" + var_a):
			mi.material_override = _mat["persa_" + var_a]
	# el lado largo de la foto va con el lado largo de la alfombra; un poco de grosor y bordes
	var girar := (sx > sz) != (aspecto > 1.0) and absf(aspecto - 1.0) > 0.15
	var bm := BoxMesh.new()
	bm.size = Vector3(sz, 0.012, sx) if girar else Vector3(sx, 0.012, sz)
	mi.mesh = bm
	if girar:
		yaw += PI * 0.5
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

## Modelos pequeños y repetidos que se pueden fusionar por material como las piezas hechas por código
## (telarañas, perchas, libros…): cientos de llamadas de dibujo menos.
## (solo los que no hace falta asentar después de la física: los de encima de mesas y estantes se quedan sueltos)
const FUSIONABLES := ["terr_cobwebs", "ropa_wood_clothes_hanger"]
func _merge_static() -> void:
	if OS.get_environment("SIN_FUSION") != "":
		return
	var groups := {}
	var nodes: Array = []
	# se fusionan todas las piezas hechas por código que no se mueven (muros, molduras, marcos, contraventanas,
	# tablas, telarañas...): por material, planta y celda de 24 m. Los modelos importados no (tienen LOD propio).
	for mi in find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var fusionable := m.owner != null and (m.owner as Node).scene_file_path.get_file().get_basename() in FUSIONABLES
		if _is_dyn(m) or m.mesh == null or (m.owner != null and not fusionable) or (m.visibility_range_end > 0.0 and not fusionable):
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
			# celdas más pequeñas dentro de la casa y una por planta: cada malla fusionada recibe solo las luces
			# cercanas (el renderizador móvil admite 8 por objeto)
			var tam := 28.0 if house_rect.grow(2.0).has_point(Vector2(gp.x, gp.z)) else 40.0
			var key := "%d|%d|%d|%d" % [mat.get_instance_id(), int(floor(gp.x / tam)) * 4 + clampi(level_of(gp.y + 0.3) + 1, 0, 3), int(floor(gp.z / tam)), m.cast_shadow]
			# (prueba: por sala; resultó peor que por celdas, se deja apagado)
			if OS.get_environment("FUSION_SALA") != "":
				var sala := room_at(gp + Vector3(0, 0.3, 0)) if (m.mesh.get_aabb().size * m.global_transform.basis.get_scale().abs()).length() < 6.0 else -1
				if sala >= 0:
					key = "%d|s%d|%d" % [mat.get_instance_id(), sala, m.cast_shadow]
			if fusionable:
				key += "|f"
			if not groups.has(key):
				groups[key] = {"mat": mat, "items": [], "shadow": m.cast_shadow, "capa": 2 if fusionable else 1}
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
		out.layers = g.capa
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

# ---------------- identidad de cada sala e historia ----------------
var notas: Array = []
func _sala_por_nombre(nombre: String) -> Dictionary:
	for r in rooms:
		if String(r.name) == nombre:
			return r
	return {}

## Luz propia de cada sala, su sonido de fondo y las notas de la historia (hojas sueltas en el suelo, cerca del
## centro y lejos de muebles grandes y puertas).
func _identidad_salas() -> void:
	for r in rooms:
		var nombre := String(r.name)
		if ZarekHistoria.LUZ.has(nombre):
			for l in r.get("lamps", []):
				(l.light as OmniLight3D).light_color = ZarekHistoria.LUZ[nombre]
		if ZarekHistoria.SONIDO.has(nombre):
			var cfg: Array = ZarekHistoria.SONIDO[nombre]
			var son := AudioStreamPlayer3D.new()
			# grabación real si la hay (reloj, latido, viento, nana); si no, el sonido hecho por código
			if ZarekSonido.variantes(cfg[0]).size() == 1 and ZarekSonido.uno(cfg[0]) is AudioStreamOggVorbis:
				var og := (ZarekSonido.uno(cfg[0]) as AudioStreamOggVorbis).duplicate() as AudioStreamOggVorbis
				og.loop = true
				son.stream = og
			else:
				son.stream = (AetherSynth.make(cfg[0]) as AudioStreamWAV).duplicate()
			if son.stream is AudioStreamWAV:
				(son.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
				(son.stream as AudioStreamWAV).loop_end = (son.stream as AudioStreamWAV).data.size() / 2
			son.volume_db = float(cfg[1])
			son.unit_size = 3.0
			son.max_distance = maxf((r.rect as Rect2).size.length() * 0.7, 8.0)
			son.autoplay = true
			var rc: Rect2 = r.rect
			son.position = Vector3(rc.get_center().x, float(r.y) + 2.0, rc.get_center().y)
			_house.add_child(son)
	for nt in ZarekHistoria.NOTAS:
		var r := _sala_por_nombre(nt[0])
		if r.is_empty():
			continue
		var rc: Rect2 = r.rect
		var p := Vector3.ZERO
		var hecho := false
		for intento in 30:
			p = Vector3(_rng.randf_range(rc.position.x + 0.8, rc.end.x - 0.8), float(r.y), _rng.randf_range(rc.position.y + 0.8, rc.end.y - 0.8))
			if door_near(p, 1.4).is_empty() and not _huella_en_escalera(p, Vector3(0.6, 0.1, 0.6), 0.0):
				hecho = true
				break
		if not hecho:
			p = Vector3(rc.get_center().x, float(r.y), rc.get_center().y)
		var hoja := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(0.21, 0.29)
		hoja.mesh = pm
		hoja.material_override = _mat_papel()
		hoja.position = p + Vector3(0, 0.012, 0)
		hoja.rotation.y = _rng.randf() * TAU
		hoja.set_meta("dyn", true)
		_house.add_child(hoja)
		# un brillo tenue para encontrarla con la linterna
		notas.append({"pos": p, "titulo": nt[1], "texto": nt[2], "nodo": hoja, "leida": false, "sala": nt[0]})

var _hoja_mat: StandardMaterial3D
func _mat_papel() -> StandardMaterial3D:
	if _hoja_mat == null:
		_hoja_mat = StandardMaterial3D.new()
		var img := Image.create(64, 88, false, Image.FORMAT_RGB8)
		var nz := FastNoiseLite.new()
		nz.frequency = 0.08
		for y in 88:
			for x in 64:
				var v := 0.78 + nz.get_noise_2d(x, y) * 0.08
				var linea := (y > 10 and y < 80 and (y % 6) == 0 and x > 6 and x < 58 - (y * 7) % 13)
				img.set_pixel(x, y, Color(v * 0.95, v * 0.88, v * 0.72) * (0.55 if linea else 1.0))
		img.generate_mipmaps()
		_hoja_mat.albedo_texture = ImageTexture.create_from_image(img)
		_hoja_mat.roughness = 0.9
		_hoja_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_hoja_mat.emission_enabled = true
		_hoja_mat.emission = Color(0.08, 0.07, 0.05)
	return _hoja_mat

func nota_cerca(p: Vector3, dist := 1.3) -> Dictionary:
	for n in notas:
		if absf(p.y - (n.pos as Vector3).y) < 1.5 and Vector2(p.x - n.pos.x, p.z - n.pos.z).length() < dist:
			return n
	return {}

# ---------------- pinturas ----------------
## Cada cuadro lleva una pintura distinta (retratos, paisajes, bodegones… de los siglos XVII-XIX, dominio público;
## zarek/pinturas/creditos.json), elegida con la misma orientación que el lienzo y recortada para llenarlo, con
## el barniz amarillento de los cuadros viejos.
func _pinturas_distintas() -> void:
	var lista: Array = JSON.parse_string(FileAccess.open("res://zarek/pinturas/creditos.json", FileAccess.READ).get_as_text())
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var orden: Array = range(lista.size())
	for i in range(orden.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = orden[i]; orden[i] = orden[j]; orden[j] = t
	var usadas := {}
	var cache := {}
	var k := 0
	for c in find_children("*", "Node3D", true, false):
		var n := c as Node3D
		if not n.scene_file_path.contains("picture_frame") and not n.scene_file_path.contains("portrait") and not n.scene_file_path.contains("biblical"):
			continue
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var m3 := mi as MeshInstance3D
			for si in m3.mesh.get_surface_count():
				var arr := m3.mesh.surface_get_arrays(si)
				var ix = arr[Mesh.ARRAY_INDEX]
				var ntri: int = (ix.size() / 3) if ix != null else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
				var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var ab := AABB(vs[0], Vector3.ZERO)
				for v in vs:
					ab = ab.expand(v)
				var dims := [ab.size.x, ab.size.y, ab.size.z]
				dims.sort()
				if ntri > 4 or dims[0] > 0.005 or dims[1] < 0.15:
					continue
				# aspecto del lienzo (ancho/alto) y de las pinturas: se elige la siguiente con la misma orientación
				var ancho := maxf(ab.size.x, ab.size.z)
				var aspecto := ancho / maxf(ab.size.y, 0.01)
				var elegida := -1
				for intento in orden.size():
					var idx: int = orden[(k + intento) % orden.size()]
					var p: Dictionary = lista[idx]
					var asp := float(p.ancho) / float(p.alto)
					if (asp > 1.0) == (aspecto > 1.0) and not usadas.has(idx):
						elegida = idx
						break
				if elegida < 0:
					elegida = orden[k % orden.size()]
				usadas[elegida] = true
				if usadas.size() >= lista.size():
					usadas.clear()
				k += 1
				var pd: Dictionary = lista[elegida]
				var tex: Texture2D = cache.get(pd.archivo, null)
				if tex == null:
					tex = load("res://zarek/pinturas/" + String(pd.archivo))
					cache[pd.archivo] = tex
				var mat := StandardMaterial3D.new()
				mat.albedo_texture = tex
				mat.albedo_color = Color(0.82, 0.76, 0.64)
				mat.roughness = 0.5
				var orig := m3.mesh.surface_get_material(si)
				if orig is BaseMaterial3D and (orig as BaseMaterial3D).normal_texture:
					mat.normal_enabled = true
					mat.normal_texture = (orig as BaseMaterial3D).normal_texture
					mat.normal_scale = 0.5
				# recorte centrado para llenar el lienzo sin deformar
				var asp_img := float(pd.ancho) / float(pd.alto)
				if asp_img > aspecto:
					var f := aspecto / asp_img
					mat.uv1_scale = Vector3(f, 1, 1)
					mat.uv1_offset = Vector3((1.0 - f) * 0.5, 0, 0)
				else:
					var f2 := asp_img / aspecto
					mat.uv1_scale = Vector3(1, f2, 1)
					mat.uv1_offset = Vector3(0, (1.0 - f2) * 0.5, 0)
				m3.set_surface_override_material(si, mat)
	print("ZAREK pinturas: %d lienzos con %d pinturas" % [k, lista.size()])

# ---------------- asentar objetos (después de la primera vuelta de física) ----------------
const COLGADOS := ["chandelier", "lamp", "lantern", "curtain", "cortina", "frame", "picture", "mirror", "head", "clock", "towel", "hanger",
	"rail", "cobweb", "shelf", "shelves", "percha", "crucifix", "sconce", "bell", "cage", "ropa_", "hanging", "wall", "biblical", "portrait",
	"knocker", "bed", "torment", "painting", "icon"]

func _caja_mallas(n: Node3D) -> AABB:
	var ab := AABB()
	var primero := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		ab = b if primero else ab.merge(b)
		primero = false
	return ab

## Baja hasta su apoyo los objetos que quedaron flotando (p. ej. cosas de una mesa que no se pudo poner) y pega a la
## pared los cuadros y espejos separados; quita los cuadros que no tienen pared detrás. Devuelve cuántos tocó.
func asentar() -> Dictionary:
	var esp := get_world_3d().direct_space_state
	var hr := house_rect.grow(1.0)
	var bajados := 0
	var pegados := 0
	var quitados := 0
	for c in find_children("*", "Node3D", true, false):
		var n := c as Node3D
		if not is_instance_valid(n) or n.is_queued_for_deletion():
			continue
		var es_glb := n.scene_file_path != ""
		var es_rb := n is RigidBody3D
		if not (es_glb or es_rb) or (es_glb and n.get_parent() is RigidBody3D):
			continue
		if not hr.has_point(Vector2(n.global_position.x, n.global_position.z)):
			continue
		var nombre := n.scene_file_path.get_file().to_lower()
		if es_rb and n.get_child_count() > 0:
			nombre = n.get_child(0).scene_file_path.get_file().to_lower()
		var ab := _caja_mallas(n)
		if ab.size == Vector3.ZERO:
			continue
		var ex: Array[RID] = []
		for co in n.find_children("*", "CollisionObject3D", true, false):
			ex.append((co as CollisionObject3D).get_rid())
		if es_rb:
			ex.append((n as RigidBody3D).get_rid())
		var colgado := false
		for k in COLGADOS:
			if nombre.contains(k):
				colgado = true
		if colgado:
			if not (nombre.contains("frame") or nombre.contains("picture") or nombre.contains("mirror") or nombre.contains("portrait") or nombre.contains("biblical")):
				continue
			if nombre.contains("bed"):
				continue
			# el cuadro mira hacia su +Z: detrás (−Z) tiene que estar la pared
			var centro := ab.get_center()
			var mejor := 99.0
			var dir_mejor := Vector3.ZERO
			for d in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
				var q := PhysicsRayQueryParameters3D.create(centro, centro + d * 1.3)
				q.exclude = ex
				q.collision_mask = 1
				var h := esp.intersect_ray(q)
				if h and centro.distance_to(h.position) < mejor:
					mejor = centro.distance_to(h.position)
					dir_mejor = d
			var grosor := (ab.size.x if absf(dir_mejor.x) > 0.5 else ab.size.z) * 0.5
			if mejor > 1.25:
				n.queue_free()
				quitados += 1
			elif mejor - grosor > 0.035:
				n.global_position += dir_mejor * (mejor - grosor - 0.012)
				pegados += 1
			continue
		# objetos apoyados: lo de debajo tiene que estar a menos de 3 cm
		var hueco := 99.0
		for pt in [ab.get_center(), ab.position + Vector3(ab.size.x * 0.3, 0, ab.size.z * 0.3), ab.position + Vector3(ab.size.x * 0.7, 0, ab.size.z * 0.7)]:
			var desde := Vector3(pt.x, ab.position.y + 0.04, pt.z)
			var q := PhysicsRayQueryParameters3D.create(desde, desde - Vector3(0, 1.0, 0))
			q.exclude = ex
			var h := esp.intersect_ray(q)
			if h:
				hueco = minf(hueco, ab.position.y - h.position.y)
		# más de 95 cm sin nada debajo suele ser una repisa decorativa sin colisión: se deja
		if hueco > 0.03 and hueco < 0.95:
			n.global_position.y -= hueco - 0.003
			bajados += 1
	print("ZAREK asentar: bajados %d, cuadros pegados %d, quitados %d" % [bajados, pegados, quitados])
	return {"bajados": bajados, "pegados": pegados, "quitados": quitados}

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
	# escaleras de mano, trampillas y pasadizos son «pasos» para Sofía: Damián también los usa (enlaces de navegación)
	for pt in portals:
		var lk := NavigationLink3D.new()
		lk.bidirectional = false
		lk.start_position = pt.pos
		lk.end_position = pt.to
		add_child(lk)
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
	if _luz_farola:
		var tf := Time.get_ticks_msec() / 1000.0
		_luz_farola.light_energy = 1.0 + 0.25 * sin(tf * 11.0) * sin(tf * 3.7) - (0.9 if fmod(tf, 6.3) < 0.12 else 0.0)
	for d in doors:
		if absf(d.ang - d.target) > 0.001 or absf(float(d.get("vel", 0.0))) > 0.001:
			# muelle amortiguado: la hoja pesa, arranca despacio y se asienta con un leve vaivén
			var k: float = float(d.get("rigidez", 9.0))
			var fr: float = float(d.get("freno", 5.2))
			var v: float = float(d.get("vel", 0.0))
			v += ((d.target - d.ang) * k - v * fr) * delta
			v = clampf(v, -8.0, 8.0)
			d["vel"] = v
			d.ang += v * delta
			d.ang = clampf(d.ang, -0.05, 1.75)
			if absf(d.ang - d.target) < 0.002 and absf(v) < 0.01:
				d.ang = d.target
				d["vel"] = 0.0
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
		if l.on and not l.broken and l.modo == "parpadea" and l.flicker <= 0.0:
			_parpadeo(l, delta)
			continue
		if l.on and not l.broken and l.flicker > 0.0:
			l.flicker -= delta
			var k := 0.15 if randf() < 0.5 else 1.0
			l.light.light_energy = l.base * k
			_brillo(l, k)
			if l.has("halo") and is_instance_valid(l.halo):
				(l.halo as MeshInstance3D).visible = k > 0.5
			if l.flicker <= 0.0:
				l.light.light_energy = l.base
	if swing:
		swing.rotation.x = sin(t * 1.3) * 0.35
	if has_meta("car"):
		var car: Node3D = get_meta("car")
		car.get_node("intermitentes").visible = fmod(t, 1.0) < 0.5
