extends Node2D
## Prueba de Aether Engine: Mundo 1 de Chronos (Jungla Flotante) y el
## Gran Sapo Ancestral. Todo el nivel se monta por código a partir de una
## lista de tramos, así es fácil de editar (o de generar con Claude).

const FLOOR := 600.0
const S3 := 0.667           # escala de los dibujos «d:3» de Chronos
const FrogBoss := preload("res://demo/chronos_w1/frog_boss.gd")

# tramos de suelo: [x, ancho, altura del suelo]
const GROUND := [
	[-400, 1700, 600], [1460, 520, 600], [2140, 700, 540], [3000, 380, 600],
	[3560, 900, 600], [4600, 600, 560], [5360, 2300, 600],
]
# plataformas flotantes: [x, ancho, y]
const PLATFORMS := [[1310, 150, 470], [2020, 110, 430], [2860, 120, 470], [3400, 140, 450], [4480, 140, 440], [5180, 150, 470], [3900, 200, 420]]
# criaturas: [tipo, x, y]
const ENEMIES := [["opossum", 900], ["opossum", 1700], ["frog", 2400], ["eagle", 2700], ["opossum", 3800], ["frog", 4150], ["eagle", 4300], ["opossum", 4800]]
const PROPS := [[200, 0], [700, 3], [1100, 5], [1600, 1], [2300, 6], [2650, 2], [3700, 0], [4100, 4], [4750, 5], [5500, 0], [5800, 3]]

var player: PlatformerPlayer
var cam: AetherCamera
var hud: AetherHUD
var boss: AetherBoss
var arena := Rect2(5560, -400, 2000, 1000)
var _boss_started := false
var _arena_walls: Array[StaticBody2D] = []
var _won := false

func _ready() -> void:
	_build_environment()
	_build_background()
	for g in GROUND:
		_ground(g[0], g[1], g[2])
	for p in PLATFORMS:
		_platform(p[0], p[1], p[2])
	for pr in PROPS:
		_prop(pr[0], pr[1])
	player = PlatformerPlayer.new()
	player.position = Vector2(80, FLOOR)
	add_child(player)
	for e in ENEMIES:
		_enemy(e[0], e[1])
	cam = AetherCamera.new()
	cam.target = player
	add_child(cam)
	cam.make_current()
	cam.snap()
	cam.limit_left = -300
	cam.limit_bottom = 900
	hud = AetherHUD.new()
	add_child(hud)
	add_child(AetherTouchControls.new())
	Aether.player_died.connect(_on_player_died)
	_spawn_boss()
	_weather()
	Aether.music("w0")
	hud.banner("MUNDO 1 · JUNGLA FLOTANTE", "Aether Engine · prueba", 2.2)

# ---------------- ambiente: luz, brillo y color ----------------
func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_strength = 1.0
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	env.adjustment_contrast = 1.05
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var cm := CanvasModulate.new()
	cm.color = Color(0.93, 0.95, 0.9)
	add_child(cm)

func _build_background() -> void:
	var tex := Aether.tex("pbg0")
	var k := 1250.0 / tex.get_height()
	var par := Parallax2D.new()
	par.scroll_scale = Vector2(0.25, 0.1)
	par.repeat_size = Vector2(tex.get_width() * k, 0)
	par.repeat_times = 3
	par.z_index = -20
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.scale = Vector2.ONE * k
	s.position = Vector2(-600, -560)
	par.add_child(s)
	add_child(par)
	# niebla del abismo bajo el suelo (los vacíos ya no se ven negros)
	var abyss := Polygon2D.new()
	abyss.polygon = PackedVector2Array([Vector2(-2000, 520), Vector2(9000, 520), Vector2(9000, 1800), Vector2(-2000, 1800)])
	abyss.vertex_colors = PackedColorArray([Color(0.55, 0.7, 0.6, 0.0), Color(0.55, 0.7, 0.6, 0.0), Color(0.05, 0.12, 0.1, 1.0), Color(0.05, 0.12, 0.1, 1.0)])
	abyss.z_index = -10
	add_child(abyss)
	# rayos de luz suaves
	for i in 6:
		var r := Sprite2D.new()
		r.texture = FX.soft()
		r.modulate = Color(1.0, 0.9, 0.55, 0.16)
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		r.material = mat
		r.scale = Vector2(3.0, 22.0)
		r.rotation = -0.35
		r.position = Vector2(400 + i * 1250, 100)
		r.z_index = -5
		add_child(r)

# ---------------- terreno ----------------
func _ground(x: float, w: float, top: float) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, 900)
	cs.shape = rect
	cs.position = Vector2(x + w * 0.5, top + 450)
	body.add_child(cs)
	add_child(body)
	_textured(x, top, w, 900.0, "tx0", false)
	_edge(x, top, w)

func _platform(x: float, w: float, y: float) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, 24)
	cs.shape = rect
	cs.one_way_collision = true
	cs.position = Vector2(x + w * 0.5, y + 12)
	body.add_child(cs)
	add_child(body)
	_textured(x, y, w, 46.0, "tx0", true)
	_edge(x, y, w)

func _textured(x: float, y: float, w: float, h: float, key: String, rounded: bool) -> void:
	var tex := Aether.tex(key)
	var poly := Polygon2D.new()
	poly.texture = tex
	poly.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var pts := PackedVector2Array([Vector2(x, y + 10), Vector2(x + w, y + 10), Vector2(x + w, y + h), Vector2(x, y + h)])
	if rounded:
		pts = PackedVector2Array([Vector2(x, y + 10), Vector2(x + w, y + 10), Vector2(x + w - 16, y + h), Vector2(x + 16, y + h)])
	poly.polygon = pts
	var uv := PackedVector2Array()
	for p in pts:
		uv.append(p / S3)
	poly.uv = uv
	poly.z_index = -2
	add_child(poly)
	# sombra hacia abajo
	var shade := Polygon2D.new()
	shade.polygon = pts
	shade.vertex_colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.75), Color(0, 0, 0, 0.75)])
	shade.z_index = -2
	add_child(shade)

func _edge(x: float, y: float, w: float) -> void:
	var tex := Aether.tex("ed0")
	var m: Dictionary = Aether.sheet("ed0")
	var gy: float = float(m.get("gy", 9)) * 3.0 * S3
	var h := tex.get_height() * S3
	var poly := Polygon2D.new()
	poly.texture = tex
	poly.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var pts := PackedVector2Array([Vector2(x - 8, y - gy), Vector2(x + w + 8, y - gy), Vector2(x + w + 8, y - gy + h), Vector2(x - 8, y - gy + h)])
	poly.polygon = pts
	var uv := PackedVector2Array()
	for p in pts:
		uv.append(Vector2((p.x - x) / S3, (p.y - (y - gy)) / S3))
	poly.uv = uv
	poly.z_index = -1
	add_child(poly)

func _ground_top(x: float) -> float:
	for g in GROUND:
		if x >= g[0] and x <= g[0] + g[1]:
			return g[2]
	return FLOOR

func _prop(x: float, i: int) -> void:
	var key := "pr0_%d" % i
	var s := SheetSprite.new()
	s.unit_scale = S3
	s.play(key, 1.0)
	s.position = Vector2(x, _ground_top(x) + 4)
	s.z_index = -3
	s.modulate = Color(0.92, 0.95, 0.9)
	add_child(s)

# ---------------- criaturas ----------------
func _enemy(kind: String, x: float) -> void:
	var e := AetherEnemy.new()
	match kind:
		"opossum":
			e.kind = "walker"; e.sheet_move = "opossum"; e.hp = 3; e.speed = 150; e.body_size = Vector2(64, 46)
		"frog":
			e.kind = "jumper"; e.sheet_move = "frog_idle"; e.sheet_alt = "frog_jump"; e.hp = 3; e.body_size = Vector2(46, 56)
		"eagle":
			e.kind = "flyer"; e.sheet_move = "eagle"; e.hp = 2; e.patrol = 160; e.body_size = Vector2(60, 70)
	var y := _ground_top(x) if kind != "eagle" else 330.0
	e.position = Vector2(x, y)
	add_child(e)

# ---------------- jefe ----------------
func _spawn_boss() -> void:
	boss = FrogBoss.new()
	boss.position = Vector2(arena.position.x + 1450, FLOOR)
	boss.arena = Rect2(arena.position.x, FLOOR - 1000, 1900, 1000)
	add_child(boss)
	boss.hp_changed.connect(func(h, m): hud.set_boss_hp(h, m))
	boss.defeated.connect(_on_boss_defeated)

func _physics_process(_delta: float) -> void:
	if not _boss_started and player and player.global_position.x > arena.position.x + 260:
		_start_boss()

func _start_boss() -> void:
	_boss_started = true
	player.checkpoint = Vector2(arena.position.x + 300, FLOOR)
	cam.lock_rect = Rect2(arena.position.x, FLOOR - 900, 1900, 1100)
	for wx in [arena.position.x + 20, arena.position.x + 1880]:
		var wall := StaticBody2D.new()
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(40, 2400)
		cs.shape = r
		wall.position = Vector2(wx, FLOOR - 1100)
		wall.add_child(cs)
		add_child(wall)
		_arena_walls.append(wall)
	Aether.music("boss")
	Aether.sfx("v_fight", 0.9)
	hud.show_boss(boss.boss_name)
	boss.active = true
	boss.set_state("intro")

func _on_boss_defeated() -> void:
	_won = true
	Aether.music("")
	hud.banner("¡GUARDIÁN DERROTADO!", "Hecho con Aether Engine", 6.0)
	for w in _arena_walls:
		w.queue_free()
	FX.burst(self, boss.global_position + Vector2(0, -200), Color(2.6, 2.2, 0.8), 60, 700, 1.2, 16, 300)

func _on_player_died() -> void:
	await get_tree().create_timer(1.4, true, false, true).timeout
	player.respawn()
	cam.snap()
	if boss and not boss.dying and _boss_started:
		boss.set_state("idle")

# ---------------- clima: hojas que caen ----------------
func _weather() -> void:
	var p := CPUParticles2D.new()
	p.texture = FX.dot()
	p.amount = 60
	p.lifetime = 6.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(900, 10)
	p.direction = Vector2(-0.4, 1)
	p.spread = 20
	p.initial_velocity_min = 40
	p.initial_velocity_max = 90
	p.gravity = Vector2(0, 30)
	p.angular_velocity_min = -180
	p.angular_velocity_max = 180
	p.scale_amount_min = 0.12
	p.scale_amount_max = 0.24
	p.color = Color(0.7, 1.0, 0.45, 0.8)
	p.position = Vector2(0, -470)
	p.z_index = 10
	cam.add_child(p)
