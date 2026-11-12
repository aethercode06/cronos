class_name ZarekMansion
extends Node3D
## La Mansión Varela (victoriana) y el bosque que la rodea, construidos a partir
## del plano de arquitecto (res://zarek/plano/plano.json). 1 celda = 3 m.
## Plantas: sótano (-1), baja (0), primer piso (1), ático (2).

const CELL := 3.0
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
	_materials()
	nav_region = NavigationRegion3D.new()
	add_child(nav_region)
	_house = Node3D.new()
	nav_region.add_child(_house)
	_stairs_plan()
	for key in ["sotano", "baja", "alta", "atico"]:
		_level(key)
	_build_stairs()
	_roof()
	_exterior()
	_markers()
	_portals()
	_decorate()
	_merge_static()

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
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_triplanar_sharpness = 4.0
	m.uv1_scale = Vector3(escala, escala, escala)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m

## Papel tapiz victoriano: dibujo damasco + suciedad y desconchones fotográficos encima.
func _papel(img: Image, tinte: Color) -> StandardMaterial3D:
	var m := _tex_mat(img, tinte, 0.85, 0.42, 0.0)
	var base := "res://zarek/texturas/Wallpaper002C/"
	if ResourceLoader.exists(base + "color.jpg"):
		m.detail_enabled = true
		m.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
		m.detail_albedo = load(base + "color.jpg")
		m.detail_uv_layer = BaseMaterial3D.DETAIL_UV_1
		m.normal_enabled = true
		m.normal_texture = load(base + "normal.jpg")
		m.normal_scale = 0.8
		m.roughness_texture = load(base + "rough.jpg")
	return m

func _materials() -> void:
	var papers := [[Color(0.34, 0.12, 0.13), Color(0.55, 0.3, 0.22)], [Color(0.13, 0.24, 0.18), Color(0.34, 0.4, 0.26)],
		[Color(0.18, 0.18, 0.3), Color(0.4, 0.34, 0.46)], [Color(0.46, 0.37, 0.24), Color(0.66, 0.55, 0.36)]]
	for i in papers.size():
		_mat["papel%d" % i] = _papel(_damask(papers[i][0], papers[i][1], 30 + i), Color(1.2, 1.2, 1.2))
	_mat["revestimiento"] = _pbr("Wood094", 0.6, Color(0.45, 0.3, 0.22), 0.8)
	_mat["parquet"] = _pbr("WoodFloor070", 0.45, Color(0.85, 0.78, 0.72), 0.85)
	_mat["baldosa"] = _pbr("Tiles140", 0.5, Color(1, 1, 1), 0.9)
	_mat["piedra"] = _pbr("Bricks108A", 0.4, Color(0.8, 0.78, 0.75), 1.0, 1.2)
	_mat["yeso"] = _pbr("Plaster007", 0.35, Color(0.85, 0.8, 0.72), 1.0)
	_mat["fachada"] = _pbr("Planks040", 0.5, Color(0.55, 0.62, 0.6), 0.9)
	_mat["tejado"] = _pbr("RoofingTiles013A", 0.5, Color(0.9, 0.9, 0.95), 0.9)
	_mat["cesped"] = _pbr("Ground037", 0.25, Color(0.75, 0.8, 0.7), 1.0)
	_mat["bosque"] = _pbr("ScatteredLeaves009", 0.25, Color(0.7, 0.68, 0.62), 1.0)
	_mat["tierra"] = _pbr("Ground110", 0.35, Color(0.85, 0.82, 0.78), 1.0)
	_mat["agua"] = _plain(Color(0.03, 0.05, 0.07), 0.05, 0.3)
	_mat["madera"] = _pbr("Wood094", 0.6, Color(0.42, 0.27, 0.18), 0.75)
	_mat["madera_clara"] = _pbr("WoodFloor043", 0.4, Color(0.9, 0.85, 0.8), 0.9)
	_mat["moldura"] = _pbr("Plaster007", 0.8, Color(0.92, 0.88, 0.8), 0.7)
	_mat["cimiento"] = _pbr("Bricks106A", 0.4, Color(0.8, 0.78, 0.75), 1.0)
	_mat["tablas"] = _pbr("Planks037A", 0.45, Color(1, 1, 1), 0.95)
	_mat["oscuro"] = _plain(Color(0.05, 0.04, 0.04), 0.8)
	_mat["tela_roja"] = _pbr("Fabric028", 1.2, Color(0.75, 0.2, 0.2), 1.0)
	_mat["tela_verde"] = _pbr("Fabric028", 1.2, Color(0.25, 0.5, 0.32), 1.0)
	_mat["sabana"] = _plain(Color(0.8, 0.78, 0.72), 1.0)
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
	{"key": "baja", "r": [16.0, 9.6, 17.0, 12.0], "low": "s", "from": -1, "to": 0},
]

func _stairs_plan() -> void:
	for s in stairs_spec:
		var a := cell_to_world(s.key, s.r[0], s.r[1])
		var b := cell_to_world(s.key, s.r[2], s.r[3])
		var top_level: int = s.to
		if not _hole.has(top_level):
			_hole[top_level] = []
		_hole[top_level].append(Rect2(a.x, a.z, b.x - a.x, b.z - a.z))

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
		for i in steps:
			var t := (i + 0.5) / steps
			var z := (b.z - run * t) if low_south else (a.z + run * t)
			var y := y0 + (y1 - y0) * (i + 1.0) / steps
			box(Vector3(w, 0.08, run / steps + 0.02), Vector3((a.x + b.x) * 0.5, y - 0.04, z), _mat.madera, false, null, true)
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
		for sx in [a.x + 0.06, b.x - 0.06]:
			var rail := box(Vector3(0.08, 0.08, length), Vector3(sx, (y0 + y1) * 0.5 + 0.95, (a.z + b.z) * 0.5), _mat.madera, false)
			rail.rotation.x = sb.rotation.x
			for k in 6:
				var t2 := k / 5.0
				var z2 := lerpf(b.z, a.z, t2) if low_south else lerpf(a.z, b.z, t2)
				box(Vector3(0.05, 0.95, 0.05), Vector3(sx, lerpf(y0, y1, t2) + 0.47, z2), _mat.madera, false)

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
		if t in ["sotano", "tunel", "roca", "agua"]:
			paper = "piedra"
		if t == "epicentro":
			paper = "papel0"
		rooms.append({"name": name, "type": t, "level": level, "rect": r, "y": y, "id": id, "paper": paper})
		if t == "epicentro" and level == 1:
			epicentro_room = id
		if level == 0 and t != "jardin":
			house_rect = r if house_rect.size == Vector2.ZERO else house_rect.merge(r)
		var fmat: Material = _mat.parquet
		if t in ["servicio", "pasillo"]:
			fmat = _mat.baldosa if level >= 0 else _mat.piedra
		if t in ["sotano", "tunel", "roca", "agua"]:
			fmat = _mat.piedra
		if t == "jardin":
			fmat = _mat.madera_clara
		for fr in _split_holes(r, _hole.get(level, [])):
			box(Vector3(fr.size.x, 0.2, fr.size.y), Vector3(fr.position.x + fr.size.x * 0.5, y - 0.1, fr.position.y + fr.size.y * 0.5), fmat, true, null, false)
		if t != "jardin" and level < 2:
			var ceil_mat: Material = _mat.yeso if level >= 0 else _mat.piedra
			for fr in _split_holes(r, _hole.get(level + 1, [])):
				box(Vector3(fr.size.x, 0.15, fr.size.y), Vector3(fr.position.x + fr.size.x * 0.5, y + WALL_H + 0.075, fr.position.y + fr.size.y * 0.5), ceil_mat, false, null, true)
		elif level == 2:
			box(Vector3(r.size.x, 0.15, r.size.y), Vector3(r.get_center().x, y + 3.3, r.get_center().y), _mat.madera, false)
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
		pieces = [[0.0, (len - gap) * 0.5, 0.0, h], [(len + gap) * 0.5, len, 0.0, h], [(len - gap) * 0.5, (len + gap) * 0.5, 2.5, h]]
	elif window:
		pieces = [[0.0, 0.7, 0.0, h], [len - 0.7, len, 0.0, h], [0.7, len - 0.7, 0.0, 0.9], [0.7, len - 0.7, 2.9, h]]
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
		var pos: Vector3 = a + along * (pc[0] + l * 0.5) + Vector3(0, pc[2] + hh * 0.5, 0)
		if exterior and level >= 0:
			var half := Vector3(l, hh, thick * 0.5) if horiz else Vector3(thick * 0.5, hh, l)
			box(half, pos + inward * thick * 0.25, mat, true)
			box(half, pos - inward * thick * 0.25, _mat.fachada, false)
		else:
			box(Vector3(l, hh, thick) if horiz else Vector3(thick, hh, l), pos, mat, true)
	if level >= 0 and level < 2 and not is_door:
		var off := inward * 0.03 if exterior else Vector3.ZERO
		if not window:
			var wz := Vector3(len, 1.1, thick + 0.05) if horiz else Vector3(thick + 0.05, 1.1, len)
			box(wz, center + Vector3(0, 0.55, 0) + off, _mat.revestimiento, false, null, false)
		var mz := Vector3(len, 0.14, thick + 0.14) if horiz else Vector3(thick + 0.14, 0.14, len)
		box(mz, center + Vector3(0, h - 0.07, 0) + off, _mat.moldura, false, null, false)
	if is_door:
		_door(center, horiz, level, ids)
	if window:
		_window(center, horiz, thick, inward)

func _window(c: Vector3, horiz: bool, thick: float, inward: Vector3) -> void:
	var lit := _rng.randf() < 0.3
	var glass := Vector3(1.6, 2.0, 0.04) if horiz else Vector3(0.04, 2.0, 1.6)
	box(glass, c + Vector3(0, 1.9, 0), _mat.ventana_luz if lit else _mat.vidrio, true, null, false)
	var fr := Vector3(1.75, 0.1, thick + 0.1) if horiz else Vector3(thick + 0.1, 0.1, 1.75)
	box(fr, c + Vector3(0, 0.9, 0), _mat.moldura, false, null, false)
	box(fr, c + Vector3(0, 2.9, 0), _mat.moldura, false, null, false)
	var vb := Vector3(0.07, 2.0, thick + 0.06) if horiz else Vector3(thick + 0.06, 2.0, 0.07)
	box(vb, c + Vector3(0, 1.9, 0), _mat.moldura, false, null, false)
	var hb := Vector3(1.6, 0.07, thick + 0.06) if horiz else Vector3(thick + 0.06, 0.07, 1.6)
	box(hb, c + Vector3(0, 2.2, 0), _mat.moldura, false, null, false)
	# frontón sobre la ventana (por fuera)
	var top := Vector3(1.9, 0.18, 0.3) if horiz else Vector3(0.3, 0.18, 1.9)
	box(top, c + Vector3(0, 3.1, 0) - inward * (thick * 0.5 + 0.12), _mat.moldura, false, null, false)
	for s in [-1.0, 1.0]:
		var side: Vector3 = (Vector3(1, 0, 0) if horiz else Vector3(0, 0, 1)) * s * 0.95
		var cs := Vector3(0.35, 2.6, 0.08) if horiz else Vector3(0.08, 2.6, 0.35)
		box(cs, c + side + inward * (thick * 0.5 + 0.08) + Vector3(0, 2.0, 0), _mat.tela_roja, false, null, false)

func _door(c: Vector3, horiz: bool, level: int, ids: Array) -> void:
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

# ---------------- tejado y torre ----------------
func _roof() -> void:
	var r := house_rect
	var y := lvl_y(2) + 3.45
	var c := r.get_center()
	var main := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(r.size.x + 1.5, 10.0, r.size.y + 1.5)
	main.mesh = pm
	main.material_override = _mat.tejado
	main.position = Vector3(c.x, y + 5.0, c.y)
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
	box(Vector3(r.size.x, 0.25, 0.25), Vector3(c.x, y + 10.0, c.y), _mat.metal, false, self)
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
		var ow := cyl(0.9, 0.9, 0.1, Vector3(c.x + sx, y + 2.8, r.end.y + 1.05), _mat.ventana_luz, self, 14)
		ow.rotation.x = PI * 0.5
	for cp in [Vector2(r.position.x + 8, c.y - 6), Vector2(r.end.x - 10, c.y + 4), Vector2(c.x - 3, c.y + 6)]:
		box(Vector3(1.6, 7.0, 1.6), Vector3(cp.x, y + 6.5, cp.y), _mat.piedra, false, self)
		box(Vector3(2.0, 0.3, 2.0), Vector3(cp.x, y + 10.1, cp.y), _mat.piedra, false, self)
	# torre redonda con techo cónico (esquina delantera oeste)
	var t0 := cell_to_world("baja", 0, 9)
	var tc := t0 + Vector3(4.5, 0, 4.5)
	var th := lvl_y(3) + 1.0
	# la torre sobresale un poco de la esquina (tambor exterior)
	tc += Vector3(-1.2, 0, 1.2)
	cyl(5.0, 5.0, th, tc + Vector3(0, th * 0.5 - 0.02, 0), _mat.fachada, self, 18)
	cyl(0.0, 6.0, 9.0, tc + Vector3(0, th + 4.5, 0), _mat.tejado, self, 18)
	cyl(0.05, 0.05, 3.0, tc + Vector3(0, th + 10.0, 0), _mat.metal, self, 6)
	for lv in 3:
		for k in 6:
			var a := TAU * k / 6.0 + 0.3
			var wp := tc + Vector3(cos(a) * 5.05, lvl_y(lv) + 1.9, sin(a) * 5.05)
			var w := box(Vector3(0.1, 2.0, 1.1), wp, _mat.ventana_luz if (k + lv) % 3 == 0 else _mat.vidrio, false, self)
			w.rotation.y = -a

# ---------------- exterior ----------------
func _exterior() -> void:
	var ex: Dictionary = plan.exterior
	var W := float(ex.w) * CELL
	var H := float(ex.h) * CELL
	# el suelo del bosque no pasa por debajo de la casa (si no, tapa la escalera del sótano)
	for gr in _split_holes(Rect2(0, 0, W, H), [house_rect]):
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
			for q in _split_holes(r, [house_rect]):
				var qr: Rect2 = q
				box(Vector3(qr.size.x, 0.05, qr.size.y), Vector3(qr.get_center().x, 0.03, qr.get_center().y), _mat.tierra, false, self, false)
		elif t == "agua":
			if name.begins_with("Fuente"):
				_fountain(r)
			elif name.begins_with("Pozo"):
				_well(r)
			else:
				box(Vector3(r.size.x, 0.05, r.size.y), Vector3(r.get_center().x, 0.04, r.get_center().y), _mat.agua, false, self, false)
				if name == "Arroyo":
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

func _fountain(r: Rect2) -> void:
	var c := Vector3(r.get_center().x, 0, r.get_center().y)
	cyl(6.0, 6.3, 0.8, c + Vector3(0, 0.4, 0), _mat.marmol, self, 24)
	_static_cyl(6.3, 0.8, c + Vector3(0, 0.4, 0))
	cyl(5.6, 5.6, 0.05, c + Vector3(0, 0.75, 0), _mat.agua, self, 24)
	cyl(0.5, 0.7, 2.4, c + Vector3(0, 1.6, 0), _mat.marmol, self, 12)
	cyl(2.0, 0.6, 0.4, c + Vector3(0, 2.9, 0), _mat.marmol, self, 16)
	cyl(0.3, 0.4, 1.2, c + Vector3(0, 3.6, 0), _mat.marmol, self, 10)

func _well(r: Rect2) -> void:
	var c := Vector3(r.get_center().x, 0, r.get_center().y)
	cyl(1.6, 1.7, 1.0, c + Vector3(0, 0.5, 0), _mat.piedra, self, 14)
	cyl(1.3, 1.3, 0.05, c + Vector3(0, 0.98, 0), _mat.oscuro, self, 14)
	for s in [-1.0, 1.0]:
		box(Vector3(0.18, 2.6, 0.18), c + Vector3(s * 1.5, 1.3, 0), _mat.madera, false, self)
	box(Vector3(3.4, 0.15, 0.15), c + Vector3(0, 2.6, 0), _mat.madera, false, self)
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
				var rock := cyl(0.2, _rng.randf_range(0.4, 0.8), _rng.randf_range(0.3, 0.6), Vector3(x + _rng.randf() * 3, 0.15, s), _mat.piedra, self, 6)
				rock.rotation.y = _rng.randf() * TAU
		x += 4.0
	var bx := _zone("Puente viejo").get_center().x
	var bz := r.get_center().y
	box(Vector3(4.0, 0.25, r.size.y + 6.0), Vector3(bx, 0.15, bz), _mat.madera, true, self)
	for s in [-1.0, 1.0]:
		box(Vector3(0.12, 0.1, r.size.y + 6.0), Vector3(bx + s * 1.9, 1.2, bz), _mat.madera, false, self)
		for k in 5:
			box(Vector3(0.12, 1.0, 0.12), Vector3(bx + s * 1.9, 0.7, bz - r.size.y * 0.5 - 3.0 + k * (r.size.y + 6.0) / 4.0), _mat.madera, false, self)

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
	var wm: Material = _mat.vidrio if glass else (_mat.fachada if name == "Cochera" else _mat.madera)
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
	var mesh := ArrayMesh.new()
	var parts := [[0.22, 0.32, 4.0, 2.0, "corteza"], [0.0, 2.6, 4.2, 5.0, "pino"], [0.0, 2.1, 3.6, 7.2, "pino"], [0.0, 1.5, 3.0, 9.2, "pino"]]
	for pr in parts:
		var cm := CylinderMesh.new()
		cm.top_radius = pr[0]
		cm.bottom_radius = pr[1]
		cm.height = pr[2]
		cm.radial_segments = 7
		cm.rings = 1
		var arr := cm.get_mesh_arrays()
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		for i in verts.size():
			verts[i].y += float(pr[3])
		arr[Mesh.ARRAY_VERTEX] = verts
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		mesh.surface_set_material(mesh.get_surface_count() - 1, _mat[pr[4]])
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mmi)
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
					box(Vector3(1.1, 0.8, 0.6), pos + Vector3(0, 0.4, 0), _mat.madera)
					box(Vector3(0.6, 0.4, 0.3), pos + Vector3(0, 1.0, 0), _mat.madera, false)
				"caja":
					musicbox_pos = pos + Vector3(0, 1.0, 0)
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
	box(Vector3(0.8, 0.9, 0.6), pos + Vector3(0, 0.45, 0), _mat.madera)
	var n := Node3D.new()
	n.set_meta("dyn", true)
	n.position = pos + Vector3(0, 1.13, 0)
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
	box(Vector3(1.6, 2.5, 0.85), Vector3(0, 1.25, 0), _mat.madera, true, n)
	box(Vector3(0.76, 2.2, 0.05), Vector3(-0.39, 1.2, 0.44), _mat.madera, false, n)
	box(Vector3(0.76, 2.2, 0.05), Vector3(0.39, 1.2, 0.44), _mat.madera, false, n)
	box(Vector3(1.75, 0.18, 0.95), Vector3(0, 2.55, 0), _mat.madera, false, n)
	box(Vector3(0.9, 0.35, 0.08), Vector3(0, 2.8, 0.38), _mat.madera, false, n)
	box(Vector3(0.04, 0.2, 0.06), Vector3(-0.06, 1.25, 0.48), _mat.oro, false, n)
	box(Vector3(0.04, 0.2, 0.06), Vector3(0.06, 1.25, 0.48), _mat.oro, false, n)
	var front := -back
	wardrobes.append({"pos": wpos + front * 1.05, "inside": wpos + front * 0.05, "yaw": atan2(-front.x, -front.z)})

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
	box(Vector3(0.03, 0.8, 0.03), Vector3(0, -0.4, 0), _mat.metal, false, n)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.42
	tm.outer_radius = 0.48
	ring.mesh = tm
	ring.material_override = _mat.oro
	ring.position.y = -0.95
	n.add_child(ring)
	var bm := _plain(Color(1, 0.9, 0.7), 0.4)
	bm.emission_enabled = true
	bm.emission = Color(1, 0.7, 0.4)
	bm.emission_energy_multiplier = 0.0
	for k in 6:
		var a := TAU * k / 6.0
		var cc := cyl(0.03, 0.03, 0.14, Vector3(cos(a) * 0.45, -0.85, sin(a) * 0.45), bm, n, 6)
		cc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var light := OmniLight3D.new()
	light.position.y = -1.0
	light.light_color = Color(1.0, 0.7, 0.42)
	var r: Rect2 = rooms[id].rect if id >= 0 else Rect2(pos.x - 6, pos.z - 6, 12, 12)
	light.omni_range = clampf(maxf(r.size.x, r.size.y) * 0.8, 8.0, 18.0)
	light.omni_attenuation = 1.1
	light.light_energy = 2.4
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
	box(Vector3(2.2, 1.4, 0.7), Vector3(0, 0.7, 0), _mat.marmol, true, n)
	box(Vector3(1.2, 0.9, 0.72), Vector3(0, 0.5, 0.02), _mat.oscuro, false, n)
	box(Vector3(2.5, 0.12, 0.85), Vector3(0, 1.45, 0.05), _mat.marmol, false, n)
	box(Vector3(1.0, 1.2, 0.06), Vector3(0, 2.3, -0.3), _mat.oro, false, n)
	box(Vector3(0.85, 1.05, 0.07), Vector3(0, 2.3, -0.28), _mat.vidrio, false, n)
	for k in 5:
		var e := box(Vector3(0.08, 0.12, 0.08), Vector3(-0.3 + k * 0.15, 0.12, 0.15), _mat.fuego, false, n, false)
		e.rotation.y = k
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.45, 0.15)
	l.omni_range = 8.0
	l.light_energy = 1.3
	l.position = Vector3(0, 0.6, 0.9)
	l.set_meta("e", 1.3)
	n.add_child(l)
	fires.append(l)

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

func _piano(pos: Vector3) -> void:
	box(Vector3(1.5, 1.0, 2.0), pos + Vector3(0, 0.5, 0), _mat.oscuro)
	var lid := box(Vector3(1.5, 0.05, 2.0), pos + Vector3(0, 1.3, -0.35), _mat.oscuro, false)
	lid.rotation.x = -0.5
	box(Vector3(1.3, 0.05, 0.25), pos + Vector3(0, 1.0, 1.05), _mat.marmol, false)

func _pickup(pos: Vector3, kind: String) -> void:
	var n := Node3D.new()
	n.set_meta("dyn", true)
	n.position = pos
	add_child(n)
	box(Vector3(0.6, 0.8, 0.45), Vector3(0, 0.4, 0), _mat.madera, true, n)
	var mi: MeshInstance3D
	if kind == "pila":
		var m := _plain(Color(0.15, 0.5, 0.2), 0.5, 0.4)
		m.emission_enabled = true
		m.emission = Color(0.2, 0.8, 0.3)
		m.emission_energy_multiplier = 0.7
		mi = cyl(0.05, 0.05, 0.2, Vector3(0, 0.88, 0), m, n, 10)
		mi.rotation.z = PI * 0.5
	else:
		mi = cyl(0.09, 0.11, 0.24, Vector3(0, 0.92, 0), _mat.sal, n, 10)
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
		portals.append({"pos": a, "to": b, "text": l[2]})
		portals.append({"pos": b, "to": a, "text": l[3]})
		for p in [a, b]:
			cyl(0.08, 0.08, 3.4, p + Vector3(0, 1.7, 0), _mat.metal, self, 8)
			for k in 7:
				var st := box(Vector3(1.0, 0.05, 0.3), p + Vector3(0, 0.3 + k * 0.48, 0), _mat.madera, false, self)
				st.rotation.y = k * 0.7

func portal_near(p: Vector3, dist := 1.7) -> Dictionary:
	for pt in portals:
		if absf(p.y - pt.pos.y) < 1.6 and Vector2(p.x - pt.pos.x, p.z - pt.pos.z).length() < dist:
			return pt
	return {}

# ---------------- decorado victoriano ----------------
func _decorate() -> void:
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
		if t in ["sala", "dormitorio", "epicentro"] and rect.size.x > 9 and rect.size.y > 9:
			box(Vector3(rect.size.x * 0.55, 0.02, rect.size.y * 0.55), c + Vector3(0, 0.01, 0), _plain(Color(0.36, 0.07, 0.08), 0.95), false, null, false)
			box(Vector3(rect.size.x * 0.5, 0.025, rect.size.y * 0.5), c + Vector3(0, 0.012, 0), _plain(Color(0.14, 0.09, 0.22), 0.95), false, null, false)
		var lname := name.to_lower()
		if "baile" in lname:
			for k in 6:
				_chair(c + Vector3(-9 + (k % 3) * 9, 0, -6 + (k / 3) * 12), _rng.randf() * TAU)
		elif "biblioteca" in lname:
			_shelves_around(r, 0.6)
		elif "comedor" in lname:
			box(Vector3(2.0, 0.08, 9.0), c + Vector3(0, 0.82, 0), _mat.madera, true)
			box(Vector3(1.6, 0.78, 8.6), c + Vector3(0, 0.39, 0), _mat.madera, false)
			for k in 6:
				_chair(c + Vector3(-1.4, 0, -3.6 + k * 1.45), PI * 0.5)
				_chair(c + Vector3(1.4, 0, -3.6 + k * 1.45), -PI * 0.5)
			for k in 3:
				cyl(0.05, 0.12, 0.6, c + Vector3(0, 1.15, -3 + k * 3), _mat.oro, null, 8)
		elif "cocina" in lname:
			box(Vector3(rect.size.x - 1.0, 0.95, 0.8), Vector3(c.x, y + 0.48, rect.position.y + 0.5), _mat.madera, true)
			box(Vector3(1.6, 1.0, 0.9), Vector3(rect.position.x + 1.3, y + 0.5, rect.end.y - 0.6), _mat.oscuro, true)
		elif t == "dormitorio":
			_bed(Vector3(rect.position.x + 2.4, y, c.z), 0.0)
			_shelves_around(r, 0.12)
		elif "estudio" in lname:
			box(Vector3(2.2, 0.08, 1.1), c + Vector3(0, 0.8, 0), _mat.madera, true)
			box(Vector3(2.0, 0.76, 0.9), c + Vector3(0, 0.38, 0), _mat.madera, false)
			_chair(c + Vector3(0, 0, 1.2), PI)
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
		if t in ["sala", "dormitorio", "pasillo"] and level_of(y) >= 0:
			_portraits(r)
		if t in ["sala", "dormitorio"] and rect.size.x > 6 and not ("baile" in lname):
			for k in 2:
				var sp := Vector3(_rng.randf_range(rect.position.x + 2, rect.end.x - 2), y, _rng.randf_range(rect.position.y + 2, rect.end.y - 2))
				if door_near(sp, 2.5).is_empty() and portal_near(sp, 2.5).is_empty():
					var sheet := box(Vector3(1.6, 0.9, 1.0), sp + Vector3(0, 0.45, 0), _mat.sabana, true)
					sheet.rotation.y = _rng.randf() * TAU
		# aplique tenue en salas sin lámpara (nunca negro total)
		if not r.has("lamps"):
			var lp := OmniLight3D.new()
			lp.light_color = Color(1.0, 0.6, 0.32)
			lp.omni_range = clampf(maxf(rect.size.x, rect.size.y) * 0.65, 6.0, 12.0)
			lp.light_energy = 0.6 if t != "sotano" else 0.4
			lp.position = Vector3(rect.position.x + 0.5, y + 2.4, c.z)
			_house.add_child(lp)
			cyl(0.06, 0.1, 0.3, lp.position, _mat.ventana_luz, null, 8)

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
			0: p = Vector3(rect.position.x + rect.size.x * t, y + 2.3, rect.position.y + 0.17)
			1: p = Vector3(rect.position.x + rect.size.x * t, y + 2.3, rect.end.y - 0.17)
			2:
				p = Vector3(rect.position.x + 0.17, y + 2.3, rect.position.y + rect.size.y * t)
				size = Vector3(0.06, 1.3, 1.0)
			_:
				p = Vector3(rect.end.x - 0.17, y + 2.3, rect.position.y + rect.size.y * t)
				size = Vector3(0.06, 1.3, 1.0)
		if not door_near(p - Vector3(0, 2.3, 0), 1.9).is_empty():
			continue
		box(size, p, _mat.oro, false, null, false)
		var inner := size * (Vector3(0.82, 0.85, 1.4) if size.x > 0.5 else Vector3(1.4, 0.85, 0.82))
		box(inner, p, face, false, null, false)

func _crates(r: Dictionary) -> void:
	var rect: Rect2 = r.rect
	var y: float = r.y
	for k in int(rect.size.x * rect.size.y / 45.0):
		var p := Vector3(_rng.randf_range(rect.position.x + 1, rect.end.x - 1), y, _rng.randf_range(rect.position.y + 1, rect.end.y - 1))
		if not door_near(p, 2.5).is_empty() or not portal_near(p, 2.5).is_empty():
			continue
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

func _merge_static() -> void:
	var groups := {}
	var nodes: Array = []
	for mi in find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if _is_dyn(m) or m.mesh == null or not (m.mesh is PrimitiveMesh) or m.material_override == null:
			continue
		var gp := m.global_position
		var key := "%d|%d|%d|%d|%d" % [m.material_override.get_instance_id(), level_of(gp.y + 0.3), int(gp.x / 36.0), int(gp.z / 36.0), m.cast_shadow]
		if not groups.has(key):
			groups[key] = {"mat": m.material_override, "items": [], "shadow": m.cast_shadow}
		groups[key].items.append(m)
		nodes.append(m)
	for key in groups:
		var g: Dictionary = groups[key]
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for m in g.items:
			st.append_from(m.mesh, 0, m.global_transform)
		var am := st.commit()
		var out := MeshInstance3D.new()
		out.mesh = am
		out.material_override = g.mat
		out.cast_shadow = g.shadow
		_house.add_child(out)
	for m in nodes:
		var mi := m as MeshInstance3D
		for c in mi.get_children():
			if c is StaticBody3D:
				var xf: Transform3D = c.global_transform
				mi.remove_child(c)
				_house.add_child(c)
				c.global_transform = xf
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
	for d in doors:
		if absf(d.ang - d.target) > 0.001:
			d.ang = move_toward(d.ang, d.target, delta * float(d.get("speed", 3.0)))
			d.pivot.rotation.y = d.base + d.ang
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
