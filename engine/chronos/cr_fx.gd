class_name CrFx
extends Node2D
## Mejora visual de Chronos en Aether: luces 2D reales (Kael, lava, fuego,
## cristales, proyectiles, portal), ambiente por mundo, brillo (glow), clima con
## partículas, niebla en capas y efectos de pantalla (violeta, calor, agua,
## tiempo lento, viñeta).

## Ambiente de cada mundo: [luz ambiente, intensidad de brillo]
const MOOD := {
	0: [Color(0.95, 0.95, 0.92), 0.6], 1: [Color(0.62, 0.6, 0.75), 0.9], 2: [Color(0.75, 0.6, 0.55), 1.0], 3: [Color(0.85, 0.75, 0.7), 0.8],
	4: [Color(0.55, 0.55, 0.7), 0.9], 5: [Color(0.75, 0.85, 0.95), 0.8], 6: [Color(0.62, 0.45, 0.45), 1.1], 7: [Color(0.8, 0.75, 0.65), 0.9],
	8: [Color(0.55, 0.75, 0.85), 0.9], 9: [Color(0.95, 0.88, 0.75), 0.6], 10: [Color(0.95, 0.95, 1.0), 0.7], 11: [Color(0.55, 0.45, 0.7), 1.1],
	12: [Color(0.6, 0.7, 0.6), 0.9], 13: [Color(0.55, 0.58, 0.7), 1.0], 14: [Color(0.6, 0.55, 0.75), 1.1], 15: [Color(0.6, 0.68, 0.66), 0.9],
	16: [Color(0.68, 0.6, 0.55), 1.0], 17: [Color(0.55, 0.6, 0.78), 1.0],
}
const MAX_LIGHTS := 14

var g: CrGame
var _ambient: CanvasModulate
var _env: WorldEnvironment
var _kael_light: PointLight2D
var _lights: Array[PointLight2D] = []
var _light_tex: Texture2D
var _weather: CPUParticles2D
var _post: ColorRect
var _post_mat: ShaderMaterial
var _fog: Node2D
var _wi := -1

func _ready() -> void:
	g = get_parent()
	_light_tex = _radial(128)
	_ambient = CanvasModulate.new()
	add_child(_ambient)
	_env = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = Aether.glow_ok()
	env.glow_intensity = 0.8
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 1.05
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.set_glow_level(1, 1.0)
	env.set_glow_level(3, 0.6)
	_env.environment = env
	add_child(_env)
	_kael_light = _new_light(Color(0.75, 0.92, 1.0), 0.9, 2.4)
	for i in MAX_LIGHTS:
		_lights.append(_new_light(Color.WHITE, 0.0, 1.0))
	_weather = CPUParticles2D.new()
	_weather.amount = 120
	_weather.lifetime = 4.0
	_weather.preprocess = 4.0
	_weather.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_weather.local_coords = false
	_weather.z_index = 8
	add_child(_weather)
	_fog = Node2D.new()
	_fog.z_index = -2
	_fog.draw.connect(_draw_fog)
	add_child(_fog)
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	_post = ColorRect.new()
	_post.set_anchors_preset(Control.PRESET_FULL_RECT)
	_post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_post_mat = ShaderMaterial.new()
	_post_mat.shader = load("res://chronos/fx/pantalla.gdshader")
	_post.material = _post_mat
	layer.add_child(_post)
	_post.visible = Aether.quality >= 1

func _radial(sz: int) -> Texture2D:
	var gt := GradientTexture2D.new()
	gt.width = sz
	gt.height = sz
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	var gr := Gradient.new()
	gr.set_color(0, Color(1, 1, 1, 1))
	gr.set_color(1, Color(1, 1, 1, 0))
	gr.add_point(0.4, Color(1, 1, 1, 0.45))
	gt.gradient = gr
	return gt

func _new_light(col: Color, energy: float, scale_k: float) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = _light_tex
	l.color = col
	l.energy = energy
	l.texture_scale = scale_k
	l.blend_mode = Light2D.BLEND_MODE_ADD
	add_child(l)
	return l

func _set_world(wi: int) -> void:
	_wi = wi
	var m: Array = MOOD.get(wi, [Color.WHITE, 0.8])
	_ambient.color = m[0]
	if g._bg:
		g._bg.modulate = (m[0] as Color).lightened(0.25)
	_env.environment.glow_intensity = m[1]
	var wcol := Color.from_string(str(g.WD.get("c", "#ffffff")), Color.WHITE)
	var w: String = str(g.WD.get("weather", ""))
	var p := _weather
	p.emitting = true
	p.direction = Vector2(0, 1)
	p.spread = 15.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 40.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = Color(1, 1, 1, 0.6)
	p.amount = 120
	match w:
		"rain":
			p.direction = Vector2(-0.25, 1)
			p.initial_velocity_min = 380.0
			p.initial_velocity_max = 480.0
			p.color = Color(0.7, 0.8, 1.0, 0.45)
			p.scale_amount_min = 1.0
			p.scale_amount_max = 1.5
			p.amount = 260
		"snow":
			p.initial_velocity_min = 25.0
			p.initial_velocity_max = 55.0
			p.spread = 40.0
			p.color = Color(1, 1, 1, 0.8)
		"embers":
			p.direction = Vector2(0.1, -1)
			p.initial_velocity_min = 25.0
			p.initial_velocity_max = 60.0
			p.color = Color(2.2, 1.0, 0.35, 0.9)
			p.amount = 90
		"leaves":
			p.direction = Vector2(0.6, 1)
			p.spread = 35.0
			p.color = Color(0.55, 0.85, 0.35, 0.8)
			p.scale_amount_max = 3.0
			p.amount = 50
		"fireflies":
			p.direction = Vector2(0, -1)
			p.spread = 180.0
			p.initial_velocity_min = 5.0
			p.initial_velocity_max = 18.0
			p.color = Color(wcol.r * 2.2, wcol.g * 2.2, wcol.b * 1.5, 0.9)
			p.amount = 45
		"bubbles":
			p.direction = Vector2(0, -1)
			p.initial_velocity_min = 30.0
			p.initial_velocity_max = 60.0
			p.color = Color(0.75, 1.0, 1.0, 0.5)
			p.scale_amount_max = 3.0
		"sand":
			p.direction = Vector2(-1, 0.15)
			p.initial_velocity_min = 140.0
			p.initial_velocity_max = 220.0
			p.color = Color(0.95, 0.8, 0.5, 0.55)
			p.amount = 160
		"clocks", "void", "clouds":
			p.direction = Vector2(0, -1)
			p.spread = 180.0
			p.initial_velocity_min = 4.0
			p.initial_velocity_max = 14.0
			p.color = Color(wcol.r * 1.8, wcol.g * 1.8, wcol.b * 1.8, 0.7)
			p.amount = 50
		_:
			p.amount = 30
			p.color = Color(1, 1, 1, 0.25)
	if Aether.quality <= 0:
		p.amount = max(10, int(p.amount * 0.4))

func _process(_delta: float) -> void:
	if g.level.is_empty() or g.p.is_empty():
		return
	if g.wi != _wi:
		_set_world(g.wi)
	var cam: Vector2 = g.cam
	var vw: float = g.VW
	var vh: float = g.VH
	# clima: el emisor cubre la vista
	_weather.position = cam + Vector2(vw * 0.5, -20 if _weather.direction.y > 0 else vh + 20)
	_weather.emission_rect_extents = Vector2(vw * 0.7, 10)
	if _weather.direction.y < 0 and str(g.WD.get("weather", "")) in ["fireflies", "clocks", "void", "clouds"]:
		_weather.position = cam + Vector2(vw * 0.5, vh * 0.5)
		_weather.emission_rect_extents = Vector2(vw * 0.6, vh * 0.5)
	if str(g.WD.get("weather", "")) == "sand":
		_weather.position = cam + Vector2(vw + 20, vh * 0.5)
		_weather.emission_rect_extents = Vector2(10, vh * 0.5)
	# Kael ilumina a su alrededor (más fuerte al atacar)
	var pc := Vector2(g.p.x + g.p.w / 2, g.p.y + g.p.h / 2)
	_kael_light.position = pc + Vector2(g.p.face * 14, 0)
	_kael_light.energy = (0.7 + (0.6 if g.p.atkT > 0.0 else 0.0)) * (0.0 if g.p.dead else 1.0)
	_kael_light.color = Color(0.85, 0.6, 1.0) if g.dim == 1 else Color(0.75, 0.92, 1.0)
	# luces de lo que brilla cerca de la vista
	var emit: Array = []
	var view := Rect2(cam - Vector2(80, 80), Vector2(vw + 160, vh + 160))
	for l in g.level.lavaStrips:
		var x: float = clamp(pc.x, l.x, l.x + l.w)
		emit.append([Vector2(x, l.y), Color(1, 0.45, 0.15), 1.2, 3.5])
	for h in g.level.hazards:
		if h.k == "jet" and h.get("on", false):
			emit.append([Vector2(h.x + 10, h.y + 30), Color(1, 0.55, 0.2), 1.1, 2.0])
	for q in g.projs:
		if str(q.type) in ["fire", "hfire", "orb", "eyeball", "laser", "clock", "ring"]:
			emit.append([Vector2(q.x, q.y), Color(1, 0.55, 0.3) if str(q.type) in ["fire", "hfire"] else Color(0.95, 0.6, 1.0), 0.8, 1.0])
	for s in g.level.plats:
		if s.k == "laser" and s.get("on", false):
			emit.append([Vector2(s.x + s.w / 2, s.y), Color(1, 0.25, 0.3), 0.7, 1.4])
		elif s.k == "phase" and int(s.ph) == g.dim:
			emit.append([Vector2(s.x + s.w / 2, s.y + 8), Color(0.3, 0.9, 1) if int(s.ph) == 0 else Color(0.8, 0.45, 1), 0.35, 1.2])
	var gl: Dictionary = g.level.goal
	if not gl.is_empty():
		emit.append([Vector2(gl.x + gl.w / 2, gl.y + gl.h / 2), Color(0.5, 0.95, 1), 1.0, 2.5])
	var rf = g.level.get("rift")
	if rf is Dictionary and not rf.is_empty():
		emit.append([Vector2(rf.x + rf.w / 2, rf.y + rf.h / 2), Color(0.8, 0.5, 1), 1.0, 2.0])
	for c in g.level.checks:
		if c.on:
			emit.append([Vector2(c.x + 12, c.y + 8), Color(0.6, 1, 0.7), 0.6, 1.2])
	if not g.boss.is_empty() and not g.boss.done:
		emit.append([Vector2(g.boss.x + g.boss.w / 2, g.boss.y + g.boss.h / 2), Color.from_string(str(g.WD.get("c", "#ffffff")), Color.WHITE), 0.6, 3.0])
	var vis: Array = emit.filter(func(e2): return view.has_point(e2[0]))
	vis.sort_custom(func(a, b): return a[0].distance_squared_to(pc) < b[0].distance_squared_to(pc))
	for i in _lights.size():
		var L := _lights[i]
		if i < vis.size():
			L.position = vis[i][0]
			L.color = vis[i][1]
			L.energy = vis[i][2] * (0.85 + randf() * 0.15)
			L.texture_scale = vis[i][3]
			L.visible = true
		else:
			L.visible = false
	# efectos de pantalla
	if _post.visible:
		var in_water := false
		for z in g.level.zones:
			if z.k == "water" and CrGame.ov(g.p, z):
				in_water = true
		_post_mat.set_shader_parameter("violeta", move_toward(float(_post_mat.get_shader_parameter("violeta")), 1.0 if g.dim == 1 else 0.0, _delta * 4.0))
		_post_mat.set_shader_parameter("calor", 1.0 if g.wi in [2, 6] else 0.0)
		_post_mat.set_shader_parameter("agua", 1.0 if in_water else 0.0)
		_post_mat.set_shader_parameter("tiempo_lento", 1.0 if g.slow_t > 0.0 else 0.0)
	_fog.queue_redraw()

func _draw_fog() -> void:
	var w: String = str(g.WD.get("weather", ""))
	if not w in ["fog", "rain", "clouds", "void", "snow"] or g.level.is_empty():
		return
	var cam: Vector2 = g.cam
	var t := Time.get_ticks_msec() / 1000.0
	var col := Color(0.85, 0.9, 1.0, 0.07) if w != "void" else Color(0.8, 0.4, 1.0, 0.07)
	for k in 3:
		var y: float = cam.y + g.VH * (0.45 + k * 0.18)
		var x0: float = cam.x - 200 + fmod(t * (8.0 + k * 6.0), 400.0)
		for i in 6:
			_fog.draw_circle(Vector2(x0 + i * 180.0, y + sin(t * 0.5 + i + k) * 10.0), 110.0 + k * 20.0, col)
