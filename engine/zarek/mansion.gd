class_name ZarekMansion
extends Node3D
## La mansión Varela construida a partir de un mapa de letras (cada letra = 3 m).
##  # pared   . suelo   D puerta   X puerta del Epicentro (cerrada)
##  P inicio  S sello   W armario  L lámpara  B pila  K sal  R radio  E Epicentro

const CELL := 3.0
const H := 3.3

const MAP := [
	"#########################",
	"#.......#.......#.......#",
	"#..S....#.....W.#....S..#",
	"#...L...D...B...D...L...#",
	"#.W.....#...L...#.....W.#",
	"####D########D#####D#####",
	"#B......................#",
	"#..L.........P......L..K#",
	"#.......R...............#",
	"####D#####X#####D########",
	"#.......#.EEE.#.........#",
	"#..W....#.EEE.#...W..S..#",
	"#...S..L#.....#....L....#",
	"#K......#.....#........B#",
	"#########################",
]

## Nombre de cada habitación (por la celda de su lámpara o de su centro).
const ROOM_NAMES := {
	Vector2i(4, 3): "el cuarto de Elena",
	Vector2i(12, 4): "la biblioteca",
	Vector2i(20, 3): "el dormitorio de los padres",
	Vector2i(7, 12): "el comedor",
	Vector2i(19, 12): "el estudio del padre",
}

var w := 0
var h := 0
var astar := AStarGrid2D.new()
var region := {}          # Vector2i -> id de habitación
var region_lamp := {}     # id -> [lamp dict]
var region_name := {}     # id -> nombre
var lamps: Array = []     # {node, light, cell, region, on, broken, base}
var doors: Array = []     # {pivot, body, shape, cell, open, locked, axis}
var wardrobes: Array = [] # {pos, yaw, node, cell}
var seals: Array = []     # {node, cell, taken}
var pickups: Array = []   # {node, cell, kind, taken}
var start_pos := Vector3.ZERO
var start_yaw := 0.0
var circle_pos := Vector3.ZERO
var radio_pos := Vector3.ZERO
var epicentro_region := -1
var hall_region := -1
var candles: Array = []
var _rng := RandomNumberGenerator.new()
var quality := 2

var mat_wall: StandardMaterial3D
var mat_floor: StandardMaterial3D
var mat_ceil: StandardMaterial3D
var mat_wood: StandardMaterial3D
var mat_dark: StandardMaterial3D
var mat_cloth: StandardMaterial3D
var mat_metal: StandardMaterial3D
var mat_gold: StandardMaterial3D
var mat_salt: StandardMaterial3D
var mat_paper: StandardMaterial3D

func cell(c: Vector2i) -> String:
	if c.y < 0 or c.y >= h or c.x < 0 or c.x >= w:
		return "#"
	return MAP[c.y][c.x]

func to_world(c: Vector2i, y := 0.0) -> Vector3:
	return Vector3(c.x * CELL + CELL * 0.5, y, c.y * CELL + CELL * 0.5)

func to_cell(p: Vector3) -> Vector2i:
	return Vector2i(int(floor(p.x / CELL)), int(floor(p.z / CELL)))

func build(q := 2) -> void:
	quality = q
	_rng.seed = 1974
	h = MAP.size()
	w = MAP[0].length()
	_materials()
	_regions()
	_astar()
	_floor_ceiling()
	_walls()
	for y in h:
		for x in w:
			var c := Vector2i(x, y)
			match cell(c):
				"D", "X": _door(c, cell(c) == "X")
				"P":
					start_pos = to_world(c)
				"S": _seal(c)
				"W": _wardrobe(c)
				"L": _lamp(c)
				"B": _pickup(c, "pila")
				"K": _pickup(c, "sal")
				"R": _radio(c)
	hall_region = int(region.get(to_cell(start_pos), -1))
	_epicentro()
	_props()

# ---------------- materiales (texturas hechas por código) ----------------
func _materials() -> void:
	mat_wall = _tri_mat(_tex_wallpaper(), Color(1, 1, 1), 0.92, 0.33)
	mat_floor = _tri_mat(_tex_planks(), Color(1, 1, 1), 0.7, 0.4)
	mat_ceil = _tri_mat(_tex_plaster(), Color(0.75, 0.72, 0.68), 0.95, 0.25)
	mat_wood = _tri_mat(_tex_planks(true), Color(0.55, 0.4, 0.3), 0.6, 0.8)
	mat_dark = _plain(Color(0.06, 0.05, 0.05), 0.8)
	mat_cloth = _plain(Color(0.28, 0.08, 0.09), 0.95)
	mat_metal = _plain(Color(0.35, 0.32, 0.28), 0.4, 0.8)
	mat_gold = _plain(Color(0.95, 0.7, 0.25), 0.3, 0.9)
	mat_gold.emission_enabled = true
	mat_gold.emission = Color(1.0, 0.65, 0.2)
	mat_gold.emission_energy_multiplier = 1.6
	mat_salt = _plain(Color(0.92, 0.92, 0.88), 0.9)
	mat_salt.emission_enabled = true
	mat_salt.emission = Color(0.5, 0.5, 0.48)
	mat_salt.emission_energy_multiplier = 0.25
	mat_paper = _plain(Color(0.78, 0.72, 0.58), 0.9)

func _plain(col: Color, rough: float, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	return m

func _tri_mat(img: Image, col: Color, rough: float, scale: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.albedo_color = col
	m.roughness = rough
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(scale, scale, scale)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var nimg: Image = img.duplicate()
	nimg.convert(Image.FORMAT_RGBA8)
	nimg.bump_map_to_normal_map(3.0)
	m.normal_enabled = true
	m.normal_texture = ImageTexture.create_from_image(nimg)
	m.normal_scale = 0.6
	return m

func _noise(freq: float, seed_v: int, oct := 4) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed = seed_v
	n.frequency = freq
	n.fractal_octaves = oct
	return n

func _tex_planks(dark := false) -> Image:
	var s := 256
	var img := Image.create(s, s, true, Image.FORMAT_RGB8)
	var grain := _noise(0.02, 3)
	var stain := _noise(0.01, 9, 3)
	for y in s:
		var plank := y / 32
		var off := (plank * 97) % s
		for x in s:
			var gx := float((x + off) % s)
			var g := grain.get_noise_2d(gx * 0.15, y * 3.0) * 0.5 + 0.5
			var st := stain.get_noise_2d(x, y) * 0.5 + 0.5
			var base := 0.30 + 0.10 * float((plank * 37) % 5) / 4.0
			var v := base * (0.75 + 0.35 * g) * (0.7 + 0.4 * st)
			if y % 32 < 1 or (x + off) % 128 < 1:
				v *= 0.35
			var c := Color(v * 1.0, v * 0.68, v * 0.45) if not dark else Color(v * 0.9, v * 0.62, v * 0.42)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return img

func _tex_wallpaper() -> Image:
	var s := 256
	var img := Image.create(s, s, true, Image.FORMAT_RGB8)
	var stain := _noise(0.012, 21, 5)
	var fine := _noise(0.08, 5, 2)
	for y in s:
		for x in s:
			var u := float(x) / s
			var vv := float(y) / s
			var stripe := 0.5 + 0.5 * cos(u * TAU * 4.0)
			var dam := 0.5 + 0.5 * sin(u * TAU * 8.0) * sin(vv * TAU * 6.0 + sin(u * TAU * 8.0))
			var st := stain.get_noise_2d(x, y) * 0.5 + 0.5
			var f := fine.get_noise_2d(x, y) * 0.5 + 0.5
			var v := (0.32 + 0.08 * stripe + 0.07 * dam) * (0.55 + 0.6 * st) * (0.9 + 0.15 * f)
			# manchas de humedad que caen
			var drip := maxf(0.0, stain.get_noise_2d(x * 4.0, y * 0.4)) * 0.5
			v *= 1.0 - drip
			img.set_pixel(x, y, Color(v * 0.86, v * 0.92, v * 0.78))
	img.generate_mipmaps()
	return img

func _tex_plaster() -> Image:
	var s := 128
	var img := Image.create(s, s, true, Image.FORMAT_RGB8)
	var n := _noise(0.05, 77, 5)
	for y in s:
		for x in s:
			var v := 0.5 + 0.25 * n.get_noise_2d(x, y)
			img.set_pixel(x, y, Color(v, v * 0.97, v * 0.92))
	img.generate_mipmaps()
	return img

# ---------------- habitaciones y caminos ----------------
func _walkable(c: Vector2i) -> bool:
	return cell(c) != "#"

func _regions() -> void:
	var id := 0
	for y in h:
		for x in w:
			var c := Vector2i(x, y)
			if not _walkable(c) or region.has(c) or cell(c) in ["D", "X"]:
				continue
			var stack: Array[Vector2i] = [c]
			region[c] = id
			while stack.size() > 0:
				var cur: Vector2i = stack.pop_back()
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var n: Vector2i = cur + d
					if _walkable(n) and not region.has(n) and not (cell(n) in ["D", "X"]):
						region[n] = id
						stack.append(n)
			id += 1
	for c in region:
		if cell(c) == "E":
			epicentro_region = int(region[c])
	for c in ROOM_NAMES:
		if region.has(c):
			region_name[int(region[c])] = ROOM_NAMES[c]

func room_name(p: Vector3) -> String:
	var r := int(region.get(to_cell(p), -1))
	if r == epicentro_region:
		return "el Epicentro"
	if r == hall_region:
		return "el vestíbulo"
	return str(region_name.get(r, "la mansión"))

func _astar() -> void:
	astar.region = Rect2i(0, 0, w, h)
	astar.cell_size = Vector2(1, 1)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	for y in h:
		for x in w:
			if not _walkable(Vector2i(x, y)):
				astar.set_point_solid(Vector2i(x, y), true)

func path(from: Vector3, to: Vector3) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var a := to_cell(from)
	var b := to_cell(to)
	if not astar.is_in_boundsv(a) or not astar.is_in_boundsv(b) or astar.is_point_solid(a) or astar.is_point_solid(b):
		return out
	for c in astar.get_id_path(a, b):
		out.append(to_world(c))
	if out.size() > 0:
		out[out.size() - 1] = Vector3(to.x, 0, to.z)
	return out

func random_floor(far_from := Vector3(-999, 0, -999), min_dist := 0.0, exclude_region := -1) -> Vector3:
	for i in 200:
		var c := Vector2i(_rng.randi_range(1, w - 2), _rng.randi_range(1, h - 2))
		if not _walkable(c) or cell(c) in ["D", "X"]:
			continue
		if exclude_region >= 0 and int(region.get(c, -1)) == exclude_region:
			continue
		var p := to_world(c)
		if p.distance_to(Vector3(far_from.x, 0, far_from.z)) >= min_dist:
			return p
	return start_pos

## ¿Está iluminada esta posición por una lámpara encendida?
func is_lit(p: Vector3) -> bool:
	var r := int(region.get(to_cell(p), -1))
	for l in region_lamp.get(r, []):
		if l.on and not l.broken:
			return true
	return false

# ---------------- geometría ----------------
func _box(size: Vector3, pos: Vector3, mat: Material, collide := true, parent: Node3D = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
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

func _floor_ceiling() -> void:
	var size := Vector3(w * CELL, 0.2, h * CELL)
	var center := Vector3(w * CELL * 0.5, -0.1, h * CELL * 0.5)
	_box(size, center, mat_floor)
	var c := _box(size, center + Vector3(0, H + 0.2, 0), mat_ceil)
	c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# vigas del techo
	for y in range(1, h - 1, 2):
		_box(Vector3(w * CELL, 0.22, 0.25), Vector3(w * CELL * 0.5, H - 0.11, y * CELL + CELL * 0.5), mat_wood, false)

func _walls() -> void:
	for y in h:
		var x := 0
		while x < w:
			if cell(Vector2i(x, y)) == "#":
				var x0 := x
				while x < w and cell(Vector2i(x, y)) == "#":
					x += 1
				var n := x - x0
				var wall := _box(Vector3(n * CELL, H, CELL), Vector3((x0 + n * 0.5) * CELL, H * 0.5, y * CELL + CELL * 0.5), mat_wall)
				wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
				# zócalo de madera en las caras
				_box(Vector3(n * CELL + 0.04, 0.9, CELL + 0.04), Vector3((x0 + n * 0.5) * CELL, 0.45, y * CELL + CELL * 0.5), mat_wood, false)
			else:
				x += 1

func _door(c: Vector2i, locked: bool) -> void:
	var horiz := cell(c + Vector2i(-1, 0)) == "#" and cell(c + Vector2i(1, 0)) == "#"
	var p := to_world(c)
	var gap := 1.5
	var side := (CELL - gap) * 0.5
	var lint := H - 2.35
	if horiz:
		_box(Vector3(side, H, CELL), p + Vector3(-gap * 0.5 - side * 0.5, H * 0.5, 0), mat_wall)
		_box(Vector3(side, H, CELL), p + Vector3(gap * 0.5 + side * 0.5, H * 0.5, 0), mat_wall)
		_box(Vector3(gap, lint, CELL), p + Vector3(0, H - lint * 0.5, 0), mat_wall)
		_box(Vector3(gap + 0.3, 0.16, CELL + 0.06), p + Vector3(0, 2.35, 0), mat_wood, false)
	else:
		_box(Vector3(CELL, H, side), p + Vector3(0, H * 0.5, -gap * 0.5 - side * 0.5), mat_wall)
		_box(Vector3(CELL, H, side), p + Vector3(0, H * 0.5, gap * 0.5 + side * 0.5), mat_wall)
		_box(Vector3(CELL, lint, gap), p + Vector3(0, H - lint * 0.5, 0), mat_wall)
		_box(Vector3(CELL + 0.06, 0.16, gap + 0.3), p + Vector3(0, 2.35, 0), mat_wood, false)
	var pivot := Node3D.new()
	add_child(pivot)
	if horiz:
		pivot.position = p + Vector3(-gap * 0.5, 0, 0)
	else:
		pivot.position = p + Vector3(0, 0, -gap * 0.5)
		pivot.rotation.y = -PI * 0.5
	var leaf := _box(Vector3(gap - 0.04, 2.33, 0.07), Vector3(gap * 0.5, 1.165, 0), mat_wood if not locked else mat_dark, false, pivot)
	# paneles y pomo
	_box(Vector3(gap * 0.7, 0.8, 0.09), Vector3(gap * 0.5, 1.65, 0), mat_wood, false, pivot)
	_box(Vector3(gap * 0.7, 0.8, 0.09), Vector3(gap * 0.5, 0.65, 0), mat_wood, false, pivot)
	_box(Vector3(0.07, 0.07, 0.16), Vector3(gap - 0.18, 1.05, 0), mat_metal, false, pivot)
	if locked:
		# cadenas y símbolos
		_box(Vector3(gap * 0.9, 0.06, 0.12), Vector3(gap * 0.5, 1.2, 0.05), mat_metal, false, pivot)
		_box(Vector3(gap * 0.9, 0.06, 0.12), Vector3(gap * 0.5, 1.4, 0.05), mat_metal, false, pivot)
	var body := AnimatableBody3D.new()
	body.sync_to_physics = false
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(gap, 2.33, 0.12)
	cs.shape = bs
	cs.position = Vector3(gap * 0.5, 1.165, 0)
	body.add_child(cs)
	pivot.add_child(body)
	var snd := AudioStreamPlayer3D.new()
	snd.unit_size = 4.0
	snd.max_distance = 30.0
	pivot.add_child(snd)
	var start_open := (not locked) and _rng.randf() < 0.5
	var d := {"pivot": pivot, "leaf": leaf, "shape": cs, "cell": c, "open": start_open, "locked": locked,
		"base": pivot.rotation.y, "ang": 0.0, "target": 0.0, "snd": snd, "pos": p}
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
		var dd: float = Vector2(p.x - d.pos.x, p.z - d.pos.z).length()
		if dd < bd:
			bd = dd
			best = d
	return best

## Abre o cierra una puerta. `force` = de golpe (portazo).
func set_door(d: Dictionary, open: bool, force := false) -> void:
	if d.is_empty() or (d.locked and open):
		return
	d.open = open
	d.target = (1.6 if open else 0.0)
	d.shape.disabled = open
	d["speed"] = 9.0 if force else 3.2

func _process(delta: float) -> void:
	for d in doors:
		if absf(d.ang - d.target) > 0.001:
			d.ang = move_toward(d.ang, d.target, delta * float(d.get("speed", 3.0)))
			d.pivot.rotation.y = d.base + d.ang
	var t := Time.get_ticks_msec() / 1000.0
	for s in seals:
		if not s.taken:
			s.node.rotation.y = t * 0.8
	for i in candles.size():
		var l: OmniLight3D = candles[i]
		l.light_energy = l.get_meta("e") * (0.85 + 0.15 * sin(t * 13.0 + i * 1.7) * sin(t * 7.3 + i))
	for l in lamps:
		if l.on and not l.broken and l.has("flicker") and l.flicker > 0.0:
			l.flicker -= delta
			l.light.light_energy = l.base * (0.15 if randf() < 0.5 else 1.0)
			if l.flicker <= 0.0:
				l.light.light_energy = l.base

func _face_wall(c: Vector2i) -> Vector2i:
	for d in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
		if cell(c + d) == "#":
			return d
	return Vector2i(0, -1)

func _wardrobe(c: Vector2i) -> void:
	var d := _face_wall(c)
	var p := to_world(c)
	var n := Node3D.new()
	add_child(n)
	var back := Vector3(d.x, 0, d.y)
	n.position = p + back * (CELL * 0.5 - 0.45)
	n.rotation.y = atan2(-back.x, -back.z)
	var wm := mat_wood.duplicate()
	wm.albedo_color = Color(0.32, 0.22, 0.17)
	var body := _box(Vector3(1.5, 2.4, 0.85), Vector3(0, 1.2, 0), wm, true, n)
	body.position.z = 0.0
	# puertas con rendija
	_box(Vector3(0.72, 2.1, 0.05), Vector3(-0.37, 1.15, 0.44), wm, false, n)
	_box(Vector3(0.72, 2.1, 0.05), Vector3(0.37, 1.15, 0.44), wm, false, n)
	_box(Vector3(1.6, 0.12, 0.95), Vector3(0, 2.45, 0), wm, false, n)
	_box(Vector3(0.04, 0.2, 0.06), Vector3(-0.05, 1.2, 0.48), mat_metal, false, n)
	_box(Vector3(0.04, 0.2, 0.06), Vector3(0.05, 1.2, 0.48), mat_metal, false, n)
	var front := -back
	wardrobes.append({"node": n, "pos": n.position + front * 1.0, "inside": n.position + Vector3(0, 0, 0) + front * 0.05, "yaw": atan2(-front.x, -front.z), "cell": c})

func wardrobe_near(p: Vector3, dist := 1.8) -> Dictionary:
	for wd in wardrobes:
		if Vector2(p.x - wd.pos.x, p.z - wd.pos.z).length() < dist:
			return wd
	return {}

func _lamp(c: Vector2i) -> void:
	var p := to_world(c)
	var n := Node3D.new()
	n.position = p + Vector3(0, H, 0)
	add_child(n)
	_box(Vector3(0.03, 0.9, 0.03), Vector3(0, -0.45, 0), mat_dark, false, n)
	var shade := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.12
	cm.bottom_radius = 0.42
	cm.height = 0.32
	shade.mesh = cm
	shade.material_override = mat_cloth
	shade.position.y = -1.05
	n.add_child(shade)
	var bulb := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.08
	sm.height = 0.16
	bulb.mesh = sm
	var bm := _plain(Color(1, 0.85, 0.6), 0.5)
	bm.emission_enabled = true
	bm.emission = Color(1, 0.75, 0.45)
	bm.emission_energy_multiplier = 0.0
	bulb.material_override = bm
	bulb.position.y = -1.2
	n.add_child(bulb)
	var light := OmniLight3D.new()
	light.position.y = -1.3
	light.light_color = Color(1.0, 0.72, 0.45)
	light.omni_range = 10.0
	light.omni_attenuation = 1.4
	light.light_energy = 1.6
	light.shadow_enabled = quality >= 1
	light.visible = false
	n.add_child(light)
	# interruptor en la pared más cercana
	var r := int(region.get(c, -1))
	var l := {"node": n, "light": light, "bulb": bm, "cell": c, "region": r, "on": false, "broken": false, "base": 1.6, "flicker": 0.0, "pos": p}
	lamps.append(l)
	if not region_lamp.has(r):
		region_lamp[r] = []
	region_lamp[r].append(l)

func lamp_near(p: Vector3, dist := 2.0) -> Dictionary:
	for l in lamps:
		if Vector2(p.x - l.pos.x, p.z - l.pos.z).length() < dist:
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
	l.bulb.albedo_color = Color(0.1, 0.1, 0.1)

func flicker_lamp(l: Dictionary, sec: float) -> void:
	if l.on and not l.broken:
		l.flicker = sec

func _seal(c: Vector2i) -> void:
	var p := to_world(c)
	# mesita
	_box(Vector3(0.8, 0.85, 0.6), p + Vector3(0, 0.425, 0), mat_wood)
	var n := Node3D.new()
	n.position = p + Vector3(0, 1.08, 0)
	add_child(n)
	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.16
	cm.bottom_radius = 0.16
	cm.height = 0.035
	disc.mesh = cm
	disc.material_override = mat_gold
	disc.rotation.x = PI * 0.5
	n.add_child(disc)
	var inner := MeshInstance3D.new()
	var im := TorusMesh.new()
	im.inner_radius = 0.07
	im.outer_radius = 0.1
	inner.mesh = im
	inner.material_override = mat_dark
	inner.rotation.x = PI * 0.5
	n.add_child(inner)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.7, 0.3)
	l.omni_range = 3.2
	l.light_energy = 0.7
	n.add_child(l)
	seals.append({"node": n, "cell": c, "taken": false, "pos": p})

func _pickup(c: Vector2i, kind: String) -> void:
	var p := to_world(c)
	var n := Node3D.new()
	add_child(n)
	n.position = p + Vector3(_rng.randf_range(-0.6, 0.6), 0, _rng.randf_range(-0.6, 0.6))
	_box(Vector3(0.55, 0.75, 0.45), Vector3(0, 0.375, 0), mat_wood, true, n)
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	if kind == "pila":
		cm.top_radius = 0.05
		cm.bottom_radius = 0.05
		cm.height = 0.2
		var m := _plain(Color(0.15, 0.5, 0.2), 0.5, 0.4)
		m.emission_enabled = true
		m.emission = Color(0.2, 0.8, 0.3)
		m.emission_energy_multiplier = 0.6
		mi.material_override = m
		mi.rotation.z = PI * 0.5
	else:
		cm.top_radius = 0.09
		cm.bottom_radius = 0.11
		cm.height = 0.24
		mi.material_override = mat_salt
	mi.mesh = cm
	mi.position.y = 0.85
	n.add_child(mi)
	pickups.append({"node": n, "cell": c, "kind": kind, "taken": false, "pos": n.position})

func _radio(c: Vector2i) -> void:
	var p := to_world(c)
	_box(Vector3(1.1, 0.8, 0.6), p + Vector3(0, 0.4, 0), mat_wood)
	_box(Vector3(0.5, 0.32, 0.25), p + Vector3(0, 0.96, 0), mat_wood, false)
	var g := _box(Vector3(0.3, 0.2, 0.02), p + Vector3(-0.05, 0.96, 0.13), mat_paper, false)
	g.material_override = mat_paper
	radio_pos = p + Vector3(0, 1.0, 0)

func _epicentro() -> void:
	var sum := Vector3.ZERO
	var n := 0
	for c in region:
		if cell(c) == "E":
			sum += to_world(c)
			n += 1
	if n == 0:
		return
	circle_pos = sum / n
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.9
	tm.outer_radius = 2.05
	ring.mesh = tm
	ring.material_override = mat_salt
	ring.scale = Vector3(1, 0.08, 1)
	ring.position = circle_pos + Vector3(0, 0.02, 0)
	add_child(ring)
	# símbolos
	for i in 5:
		var a := TAU * i / 5.0
		var line := _box(Vector3(0.05, 0.01, 3.6), circle_pos + Vector3(0, 0.02, 0), mat_salt, false)
		line.rotation.y = a
	for i in 6:
		var a := TAU * i / 6.0
		var cp := circle_pos + Vector3(cos(a) * 2.4, 0, sin(a) * 2.4)
		var cm := CylinderMesh.new()
		cm.top_radius = 0.04
		cm.bottom_radius = 0.05
		cm.height = 0.3
		var cand := MeshInstance3D.new()
		cand.mesh = cm
		cand.material_override = mat_paper
		cand.position = cp + Vector3(0, 0.15, 0)
		add_child(cand)
		var fl := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.025
		sm.height = 0.07
		fl.mesh = sm
		var fm := _plain(Color(1, 0.6, 0.2), 1.0)
		fm.emission_enabled = true
		fm.emission = Color(1, 0.55, 0.15)
		fm.emission_energy_multiplier = 4.0
		fl.material_override = fm
		fl.position = cp + Vector3(0, 0.34, 0)
		add_child(fl)
	var l := OmniLight3D.new()
	l.position = circle_pos + Vector3(0, 0.6, 0)
	l.light_color = Color(1, 0.5, 0.25)
	l.omni_range = 6.5
	l.light_energy = 0.9
	l.set_meta("e", 0.9)
	add_child(l)
	candles.append(l)
	# cama de Elena con correas en el Epicentro
	_box(Vector3(1.2, 0.5, 2.2), circle_pos + Vector3(0, 0.25, -4.3), mat_metal)
	_box(Vector3(1.1, 0.12, 2.0), circle_pos + Vector3(0, 0.56, -4.3), mat_cloth, false)

# ---------------- muebles (decorado) ----------------
func _props() -> void:
	var used := {}
	for c in region:
		var ch := cell(c)
		if ch != ".":
			continue
		var r := int(region[c])
		if r == epicentro_region:
			continue
		var near_door := false
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if cell(c + Vector2i(dx, dy)) in ["D", "X", "P", "W", "S", "L"]:
					near_door = true
		if near_door:
			continue
		var wd := _face_wall(c)
		if cell(c + wd) != "#":
			continue
		if _rng.randf() > (0.42 if r != hall_region else 0.3):
			continue
		var p := to_world(c)
		var back := Vector3(wd.x, 0, wd.y)
		var yaw := atan2(-back.x, -back.z)
		var n := Node3D.new()
		add_child(n)
		n.position = p + back * (CELL * 0.5 - 0.4)
		n.rotation.y = yaw
		var k := _rng.randi_range(0, 6)
		match k:
			0, 1:
				# estantería con libros
				_box(Vector3(1.6, 2.2, 0.45), Vector3(0, 1.1, 0), mat_wood, true, n)
				for sy in 4:
					for b in 7:
						var bh := _rng.randf_range(0.22, 0.34)
						var bk := _box(Vector3(0.14, bh, 0.3), Vector3(-0.6 + b * 0.2, 0.3 + sy * 0.5 + bh * 0.5, 0.1), _plain(Color(_rng.randf_range(0.15, 0.4), _rng.randf_range(0.08, 0.2), _rng.randf_range(0.06, 0.15)), 0.9), false, n)
						bk.rotation.z = _rng.randf_range(-0.08, 0.08)
			2:
				# mesa y silla
				_box(Vector3(1.4, 0.08, 0.8), Vector3(0, 0.78, 0.2), mat_wood, true, n)
				for lx in [-0.6, 0.6]:
					for lz in [-0.15, 0.55]:
						_box(Vector3(0.07, 0.76, 0.07), Vector3(lx, 0.38, lz), mat_wood, false, n)
				var ch2 := Node3D.new()
				n.add_child(ch2)
				ch2.position = Vector3(_rng.randf_range(-0.3, 0.3), 0, 0.9)
				ch2.rotation.y = _rng.randf_range(-0.6, 0.6) + (PI if _rng.randf() < 0.3 else 0.0)
				_box(Vector3(0.45, 0.06, 0.45), Vector3(0, 0.46, 0), mat_wood, false, ch2)
				_box(Vector3(0.45, 0.55, 0.05), Vector3(0, 0.75, 0.2), mat_wood, false, ch2)
				_box(Vector3(0.18, 0.12, 0.12), Vector3(0.3, 0.88, 0.2), mat_paper, false, n)
			3:
				# cómoda con espejo oscuro
				_box(Vector3(1.3, 0.9, 0.5), Vector3(0, 0.45, 0), mat_wood, true, n)
				var mirror := _box(Vector3(0.8, 1.0, 0.03), Vector3(0, 1.55, -0.2), _plain(Color(0.08, 0.09, 0.1), 0.05, 1.0), false, n)
				mirror.name = "espejo"
			4:
				# cuadro torcido
				var fr := _box(Vector3(0.9, 1.15, 0.06), Vector3(0, 1.75, -0.32), mat_wood, false, n)
				fr.rotation.z = _rng.randf_range(-0.12, 0.12)
				_box(Vector3(0.72, 0.95, 0.02), Vector3(0, 0, 0.03), _plain(Color(0.12, 0.1, 0.09), 0.9), false, fr)
				_box(Vector3(0.2, 0.28, 0.01), Vector3(0, 0.12, 0.045), _plain(Color(0.6, 0.55, 0.48), 0.9), false, fr)
			5:
				# cajas y sábana
				_box(Vector3(0.7, 0.6, 0.6), Vector3(-0.3, 0.3, 0.05), mat_wood, true, n)
				_box(Vector3(0.5, 0.45, 0.5), Vector3(0.35, 0.225, 0.2), mat_wood, false, n)
				var sheet := _box(Vector3(1.2, 1.1, 0.8), Vector3(0, 0.55, 0), _plain(Color(0.62, 0.6, 0.55), 1.0), false, n)
				sheet.position.x = 0.0
				sheet.visible = _rng.randf() < 0.5
			6:
				# piano / aparador
				_box(Vector3(1.8, 1.2, 0.6), Vector3(0, 0.6, 0), mat_dark, true, n)
				_box(Vector3(1.6, 0.05, 0.25), Vector3(0, 0.8, 0.35), mat_paper, false, n)
		used[c] = true
