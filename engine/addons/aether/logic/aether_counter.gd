@icon("res://addons/aether/icons/ui.svg")
class_name AetherCounter
extends CanvasLayer
## Muestra una variable en pantalla («◆ 25»). Se actualiza sola y da un saltito.

## Variable a mostrar.
@export var var_name := "monedas"
## Texto delante del número.
@export var prefix := "◆ "
## Texto detrás (ej. « / 50»).
@export var suffix := ""
## Esquina: arriba-derecha, arriba-centro, arriba-izquierda (debajo de la vida).
@export_enum("arriba_derecha", "arriba_centro", "arriba_izquierda") var corner := "arriba_derecha"
## Color del texto.
@export var color := Color(1.0, 0.86, 0.4)

var _l: Label

func _ready() -> void:
	layer = 51
	_l = Label.new()
	_l.add_theme_font_size_override("font_size", 38)
	_l.add_theme_color_override("font_color", color)
	_l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_l.add_theme_constant_override("outline_size", 10)
	_l.size = Vector2(320, 56)
	match corner:
		"arriba_derecha":
			_l.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			_l.position = Vector2(-460, 28)
			_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		"arriba_centro":
			_l.set_anchors_preset(Control.PRESET_CENTER_TOP)
			_l.position = Vector2(-160, 24)
			_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_:
			_l.position = Vector2(30, 130)
	_l.pivot_offset = Vector2(160, 28)
	add_child(_l)
	Aether.var_changed.connect(_on_var)
	_refresh()

func _on_var(n: String, _v: float) -> void:
	if n == var_name:
		_refresh()
		_l.scale = Vector2.ONE * 1.25
		create_tween().tween_property(_l, "scale", Vector2.ONE, 0.18)

func _refresh() -> void:
	var v := Aether.get_var(var_name)
	_l.text = prefix + (str(int(v)) if v == floor(v) else str(v)) + suffix
