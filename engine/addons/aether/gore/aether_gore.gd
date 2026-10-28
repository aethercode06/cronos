class_name AetherGore
extends RefCounted
## Kit de sangre y gore (2D y 3D): manchas en paredes y suelo, salpicaduras,
## charcos que crecen, goteo y heridas sobre modelos. Sin créditos: las manchas
## se generan solas. Se gradúa con Aether.gore (0 = sin sangre, 1 = poca, 2 = toda).
##   AetherGore.spray_3d(self, punto, direccion)
##   AetherGore.splat_2d(self, punto)

const MAX_DECALS := 80
static var _tex: Array[Texture2D] = []
static var _decals: Array = []

static func level() -> int:
	return Aether.gore

## Texturas de mancha generadas (4 variantes).
static func textures() -> Array[Texture2D]:
	if _tex.size() > 0:
		return _tex
	var rng := RandomNumberGenerator.new()
	rng.seed = 1974
	for v in 4:
		var s := 128
		var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var blobs: Array = []
		blobs.append([Vector2(64, 64), rng.randf_range(22, 30)])
		for i in 14 + v * 3:
			var a := rng.randf() * TAU
			var d := rng.randf_range(10, 52)
			blobs.append([Vector2(64, 64) + Vector2(cos(a), sin(a)) * d, rng.randf_range(2, 11) * (1.0 - d / 70.0) + 1.5])
		for i in 3 + v:
			var a := rng.randf() * TAU
			for k in 10:
				blobs.append([Vector2(64, 64) + Vector2(cos(a), sin(a)) * (20 + k * 4), 4.5 - k * 0.35])
		for y in s:
			for x in s:
				var p := Vector2(x, y)
				var f := 0.0
				for b in blobs:
					var r: float = b[1]
					var dd: float = p.distance_to(b[0])
					if dd < r:
						f = max(f, clamp((r - dd) / 2.0, 0.0, 1.0))
				if f > 0.0:
					var shade := 0.75 + 0.25 * sin(x * 0.3 + y * 0.21 + v)
					img.set_pixel(x, y, Color(0.55 * shade, 0.02, 0.03, f * 0.95))
		_tex.append(ImageTexture.create_from_image(img))
	return _tex

static func _pick() -> Texture2D:
	var t := textures()
	return t[randi() % t.size()]

static func _keep(n: Node) -> void:
	_decals.append(n)
	while _decals.size() > MAX_DECALS:
		var old = _decals.pop_front()
		if is_instance_valid(old):
			old.queue_free()

# ---------------- 3D ----------------
## Mancha en una superficie 3D (pared, suelo, personaje).
static func splat_3d(parent: Node, pos: Vector3, normal := Vector3.UP, size := 1.0, color := Color(1, 1, 1)) -> Decal:
	if level() <= 0 or parent == null:
		return null
	var d := Decal.new()
	d.texture_albedo = _pick()
	d.modulate = color
	d.size = Vector3(size, 0.5, size)
	d.upper_fade = 0.2
	d.lower_fade = 0.2
	d.albedo_mix = 1.0
	parent.add_child(d)
	var y := normal.normalized()
	var x := y.cross(Vector3.FORWARD if abs(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	d.global_transform = Transform3D(Basis(x, y, z).rotated(y, randf() * TAU), pos)
	_keep(d)
	return d

## Salpicadura 3D: gotas que vuelan y manchan donde caen.
static func spray_3d(parent: Node3D, pos: Vector3, dir := Vector3.FORWARD, amount := 1.0) -> void:
	if level() <= 0 or parent == null:
		return
	var n := int((6 if level() == 1 else 14) * amount)
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = n * 3
	p.lifetime = 0.8
	p.explosiveness = 0.95
	p.direction = dir.normalized()
	p.spread = 35.0
	p.initial_velocity_min = 2.5
	p.initial_velocity_max = 6.0
	p.gravity = Vector3(0, -12, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	var m := SphereMesh.new()
	m.radius = 0.035
	m.height = 0.07
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.01, 0.02)
	mat.roughness = 0.2
	m.material = mat
	p.mesh = m
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.get_tree().create_timer(1.5).timeout.connect(p.queue_free)
	var space := parent.get_world_3d().direct_space_state
	for i in n:
		var d := (dir.normalized() + Vector3(randf_range(-0.6, 0.6), randf_range(-0.4, 0.5), randf_range(-0.6, 0.6))).normalized()
		var q := PhysicsRayQueryParameters3D.create(pos, pos + d * randf_range(1.5, 4.5))
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			q = PhysicsRayQueryParameters3D.create(pos + d * randf_range(0.5, 2.0), pos + d * 2.0 + Vector3(0, -5, 0))
			hit = space.intersect_ray(q)
		if not hit.is_empty():
			splat_3d(parent.get_tree().current_scene if parent.get_tree().current_scene else parent, hit.position, hit.normal, randf_range(0.25, 0.8))

## Charco que crece despacio en el suelo.
static func pool_3d(parent: Node, pos: Vector3, max_size := 1.6, seconds := 6.0) -> void:
	var d := splat_3d(parent, pos, Vector3.UP, 0.2, Color(0.75, 0.75, 0.75))
	if d:
		d.create_tween().tween_property(d, "size", Vector3(max_size, 0.5, max_size), seconds).set_ease(Tween.EASE_OUT)

## Herida pegada a un modelo (se mueve con él).
static func wound_3d(target: Node3D, local_pos: Vector3, size := 0.35) -> void:
	if level() <= 0 or target == null:
		return
	var d := splat_3d(target, target.to_global(local_pos), (target.to_global(local_pos) - target.global_position).normalized(), size)
	if d:
		d.size.y = size * 2.0

# ---------------- 2D ----------------
## Mancha 2D (detrás de los personajes).
static func splat_2d(parent: Node, pos: Vector2, size := 1.0, color := Color(1, 1, 1)) -> Sprite2D:
	if level() <= 0 or parent == null:
		return null
	var s := Sprite2D.new()
	s.texture = _pick()
	s.modulate = color
	s.scale = Vector2.ONE * size * randf_range(0.6, 1.0)
	s.rotation = randf() * TAU
	s.z_index = -1
	parent.add_child(s)
	s.global_position = pos
	_keep(s)
	return s

## Salpicadura 2D: gotas y manchas alrededor.
static func spray_2d(parent: Node, pos: Vector2, dir := Vector2.RIGHT, amount := 1.0) -> void:
	if level() <= 0 or parent == null:
		return
	var n := int((5 if level() == 1 else 12) * amount)
	FX.burst(parent, pos, Color(0.7, 0.02, 0.04), n * 2, 380, 0.5, 8, 900, 40, dir)
	for i in n:
		var off := dir.normalized().rotated(randf_range(-0.7, 0.7)) * randf_range(10, 90)
		splat_2d(parent, pos + off, randf_range(0.15, 0.45))
