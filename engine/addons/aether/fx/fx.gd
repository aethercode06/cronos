class_name FX
extends RefCounted
## Efectos visuales de Aether Engine: chispas, polvo, ondas expansivas,
## textos flotantes y estelas. Los colores con valores > 1 brillan (HDR 2D).

static var _dot: Texture2D
static var _ring: Texture2D
static var _soft: Texture2D

static func _make_tex(kind: String) -> Texture2D:
	var size := 64
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size, size) * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c) / (size * 0.5)
			var a := 0.0
			match kind:
				"dot": a = clamp(1.0 - d, 0.0, 1.0)
				"soft": a = pow(clamp(1.0 - d, 0.0, 1.0), 2.2)
				"ring": a = clamp(1.0 - abs(d - 0.82) / 0.14, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

static func dot() -> Texture2D:
	if _dot == null: _dot = _make_tex("dot")
	return _dot

static func soft() -> Texture2D:
	if _soft == null: _soft = _make_tex("soft")
	return _soft

static func ring_tex() -> Texture2D:
	if _ring == null: _ring = _make_tex("ring")
	return _ring

static func _add(parent: Node, n: Node) -> void:
	if parent and parent.is_inside_tree():
		parent.add_child(n)

## Ráfaga de partículas (chispas de golpe, polvo, explosión).
static func burst(parent: Node, pos: Vector2, col: Color, amount := 24, speed := 420.0, life := 0.45, size := 10.0, gravity := 600.0, spread := 180.0, dir := Vector2.UP) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.texture = dot()
	p.amount = amount
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = life
	p.direction = dir
	p.spread = spread
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, gravity)
	p.damping_min = speed * 0.6
	p.damping_max = speed * 1.2
	p.scale_amount_min = size / 64.0 * 0.5
	p.scale_amount_max = size / 64.0
	var g := Gradient.new()
	g.set_color(0, col)
	g.set_color(1, Color(col.r, col.g, col.b, 0.0))
	p.color_ramp = g
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0.2))
	p.scale_amount_curve = curve
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	_add(parent, p)
	if not p.is_inside_tree():
		p.free()
		return
	p.emitting = true
	p.get_tree().create_timer(life + 0.3, false).timeout.connect(p.queue_free)

## Onda expansiva (anillo que crece y se desvanece).
static func ring(parent: Node, pos: Vector2, col: Color, r1 := 220.0, dur := 0.35) -> void:
	var s := Sprite2D.new()
	s.texture = ring_tex()
	s.position = pos
	s.modulate = col
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	s.material = mat
	s.scale = Vector2.ONE * 0.2
	_add(parent, s)
	var tw := s.create_tween().set_parallel(true)
	tw.tween_property(s, "scale", Vector2.ONE * (r1 / 32.0), dur).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "modulate:a", 0.0, dur)
	tw.chain().tween_callback(s.queue_free)

## Destello de luz suave (halo).
static func glow(parent: Node, pos: Vector2, col: Color, radius := 120.0, dur := 0.25) -> void:
	var s := Sprite2D.new()
	s.texture = soft()
	s.position = pos
	s.modulate = col
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	s.material = mat
	s.scale = Vector2.ONE * (radius / 32.0)
	_add(parent, s)
	var tw := s.create_tween()
	tw.tween_property(s, "modulate:a", 0.0, dur)
	tw.tween_callback(s.queue_free)

## Texto flotante («¡CRÍTICO!», daño…).
static func float_text(parent: Node, pos: Vector2, text: String, col := Color(1, 1, 1), size := 30) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos - Vector2(120, 20)
	l.size = Vector2(240, 40)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 8)
	l.z_index = 50
	l.pivot_offset = Vector2(120, 20)
	l.scale = Vector2.ONE * 0.4
	_add(parent, l)
	var tw := l.create_tween()
	tw.tween_property(l, "scale", Vector2.ONE * 1.1, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "scale", Vector2.ONE, 0.08)
	tw.parallel().tween_property(l, "position:y", l.position.y - 50, 0.7)
	tw.tween_property(l, "modulate:a", 0.0, 0.25)
	tw.tween_callback(l.queue_free)

## Estela de espada (media luna brillante).
static func slash(parent: Node, pos: Vector2, face: float, col := Color(2.2, 1.9, 1.2), radius := 95.0, arc_from := -70.0, arc_to := 60.0) -> void:
	var line := Line2D.new()
	line.position = pos
	line.width = 26.0
	var wc := Curve.new()
	wc.add_point(Vector2(0, 0.05))
	wc.add_point(Vector2(0.6, 1.0))
	wc.add_point(Vector2(1, 0.2))
	line.width_curve = wc
	var g := Gradient.new()
	g.set_color(0, Color(col.r, col.g, col.b, 0.0))
	g.set_color(1, col)
	line.gradient = g
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	line.material = mat
	for i in 14:
		var a := deg_to_rad(lerp(arc_from, arc_to, i / 13.0))
		line.add_point(Vector2(cos(a) * radius * face, sin(a) * radius * 0.8))
	line.z_index = 20
	_add(parent, line)
	var tw := line.create_tween()
	tw.tween_property(line, "modulate:a", 0.0, 0.16)
	tw.tween_callback(line.queue_free)
