@icon("res://addons/aether/icons/aether.svg")
class_name AetherKit
extends Node2D
## Base de los juegos completos de Aether (disparos, puzle, defensa, carreras,
## lucha, cartas…): puntuación, récord guardado, textos en pantalla y la
## pantalla final con REINTENTAR. Cada género hereda de aquí.

signal game_over(won: bool, score: int)
signal score_changed(score: int)

## Nombre con el que se guarda el récord.
@export var game_id := ""

var score := 0
var best := 0
var over := false
var hud: CanvasLayer
var _top: Label
var _top_right: Label
var _big: Label
var _end: Control

func _kit_setup(default_id: String) -> void:
	if game_id == "":
		game_id = default_id
	best = int(Aether.save.get_value(game_id + "_record", 0))
	hud = CanvasLayer.new()
	hud.layer = 40
	add_child(hud)
	_top = _mk_label(30, Color(1, 1, 1))
	_top.position = Vector2(24, 14)
	_top.size = Vector2(700, 50)
	hud.add_child(_top)
	_top_right = _mk_label(26, Color(1, 0.85, 0.4))
	_top_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_top_right.position = Vector2(-524, 14)
	_top_right.size = Vector2(500, 50)
	_top_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud.add_child(_top_right)
	_big = _mk_label(64, Color(1, 0.92, 0.6))
	_big.set_anchors_preset(Control.PRESET_FULL_RECT)
	_big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_big.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_big.modulate.a = 0.0
	hud.add_child(_big)

func _mk_label(size: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 10)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func view() -> Vector2:
	return get_viewport_rect().size

## Texto arriba a la izquierda.
func set_top(t: String) -> void:
	if _top:
		_top.text = t

## Texto arriba a la derecha.
func set_top_right(t: String) -> void:
	if _top_right:
		_top_right.text = t

## Cartel grande en el centro.
func big(t: String, dur := 1.4) -> void:
	if _big == null:
		return
	_big.text = t
	_big.pivot_offset = view() * 0.5
	_big.scale = Vector2(1.4, 1.4)
	var tw := _big.create_tween()
	tw.tween_property(_big, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(_big, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(dur)
	tw.tween_property(_big, "modulate:a", 0.0, 0.4)

func add_score(n: int) -> void:
	score += n
	score_changed.emit(score)

## Termina la partida: guarda el récord y muestra REINTENTAR.
func end_game(won: bool, text := "") -> void:
	if over:
		return
	over = true
	if score > best:
		best = score
		Aether.save.set_value(game_id + "_record", best)
	Aether.sfx("win" if won else "hurt", 0.8)
	if won:
		Aether.flash(Color(1, 0.95, 0.7), 0.5)
	game_over.emit(won, score)
	_end = ColorRect.new()
	(_end as ColorRect).color = Color(0, 0, 0, 0.6)
	_end.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.add_child(_end)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = view() * 0.5 - Vector2(260, 160)
	box.size = Vector2(520, 320)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	_end.add_child(box)
	var t1 := _mk_label(60, Color(1, 0.9, 0.5) if won else Color(1, 0.45, 0.45))
	t1.text = text if text != "" else Aether.t("¡VICTORIA!" if won else "FIN DEL JUEGO")
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t1)
	var t2 := _mk_label(30, Color(1, 1, 1))
	t2.text = "%s %d   ·   %s %d" % [Aether.t("Puntos"), score, Aether.t("Récord"), best]
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t2)
	var b := Button.new()
	b.text = Aether.t("REINTENTAR")
	b.custom_minimum_size = Vector2(320, 80)
	b.add_theme_font_size_override("font_size", 34)
	b.pressed.connect(_restart)
	box.add_child(b)
	_end.modulate.a = 0.0
	_end.create_tween().tween_property(_end, "modulate:a", 1.0, 0.4)

func _restart() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().reload_current_scene()

## Comprobación automática de la pieza (la usan las pruebas del motor).
func selftest() -> bool:
	return true
