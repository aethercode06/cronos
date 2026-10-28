@icon("res://addons/aether/icons/aether.svg")
class_name AetherRunner
extends Node2D
## Generador de corredor infinito: crea suelo, huecos, plataformas y enemigos
## por delante del jugador y borra lo que queda atrás. La dificultad sube sola.
## Muestra la distancia y guarda el récord.

## Textura del suelo.
@export var fill_texture: Texture2D
## Textura del borde del suelo.
@export var edge_texture: Texture2D
## Altura del suelo.
@export var floor_y := 600.0
## Probabilidad de enemigo por tramo (0-1).
@export_range(0.0, 1.0) var enemy_chance := 0.45

var _next_x := -400.0
var _chunks: Array[Node] = []
var _label: Label
var _best := 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_best = float(Aether.save.get_value("runner_best", 0.0))
	var layer := CanvasLayer.new()
	add_child(layer)
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_label.position = Vector2(-200, 24)
	_label.size = Vector2(400, 50)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 34)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_label.add_theme_constant_override("outline_size", 8)
	layer.add_child(_label)
	_spawn(1600.0, false)
	Aether.player_died.connect(_on_died)

func _distance() -> float:
	var pl = Aether.player
	return max(0.0, pl.global_position.x / 100.0) if pl else 0.0

func _process(_delta: float) -> void:
	var pl = Aether.player
	if pl == null:
		return
	while _next_x < pl.global_position.x + 2600:
		_spawn(_rng.randf_range(500, 1100), true)
	for c in _chunks.duplicate():
		if c.position.x + 2000 < pl.global_position.x - 1400:
			_chunks.erase(c)
			c.queue_free()
	var d := _distance()
	_label.text = "%d m   ·   %s %d m" % [int(d), Aether.t("Récord"), int(max(_best, d))]

func _spawn(width: float, allow_gap: bool) -> void:
	var lvl: float = clamp(_next_x / 30000.0, 0.0, 1.0)
	if allow_gap and _rng.randf() < 0.55:
		_next_x += _rng.randf_range(140, 220 + 160 * lvl)
	var g := AetherGround.new()
	g.position = Vector2(_next_x, floor_y + _rng.randf_range(-60, 40) * (1 if allow_gap else 0))
	g.size = Vector2(width, 700)
	g.fill_texture = fill_texture
	g.edge_texture = edge_texture
	add_child(g)
	_chunks.append(g)
	if allow_gap and _rng.randf() < enemy_chance + 0.3 * lvl:
		var e := AetherEnemy.new()
		e.position = Vector2(_next_x + width * _rng.randf_range(0.4, 0.8), g.position.y)
		add_child(e)
		_chunks.append(e)
	_next_x += width

func _on_died() -> void:
	var d := _distance()
	if d > _best:
		_best = d
		Aether.save.set_value("runner_best", d)
		Aether.toast(Aether.t("¡NUEVO RÉCORD!") + " %d m" % int(d))
	await get_tree().create_timer(1.2, true, false, true).timeout
	get_tree().reload_current_scene()
