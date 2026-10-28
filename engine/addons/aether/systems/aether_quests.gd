@icon("res://addons/aether/icons/ui.svg")
class_name AetherQuests
extends CanvasLayer
## Misiones con progreso: una por línea en «quests»:
##   Título | variable | objetivo | premio (monedas)
## Ej.: «Recoge 20 gemas | gemas | 20 | 50». Se completan solas y dan el premio.

@export_multiline var quests := "Recoge 10 monedas | monedas | 10 | 20\nVence a 5 enemigos | enemigos | 5 | 30"
## Variable del premio.
@export var reward_var := "monedas"
## Mostrar la lista en pantalla (esquina izquierda).
@export var show_list := true

var _done := {}
var _label: Label
var _kills := 0

func _ready() -> void:
	layer = 52
	_done = Aether.save.get_value("misiones_hechas", {})
	_label = Label.new()
	_label.position = Vector2(30, 170)
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_label.add_theme_constant_override("outline_size", 6)
	_label.visible = show_list
	add_child(_label)
	Aether.var_changed.connect(func(_n, _v): _check())
	Aether.enemy_killed.connect(func():
		Aether.add_var("enemigos", 1))
	_check()

func _parse() -> Array:
	var out := []
	for l in quests.split("\n"):
		var p := l.split("|")
		if p.size() >= 3:
			out.append([p[0].strip_edges(), p[1].strip_edges(), float(p[2]), float(p[3]) if p.size() > 3 else 0.0])
	return out

func _check() -> void:
	var txt := ""
	for q in _parse():
		var v := Aether.get_var(q[1])
		var done: bool = _done.has(q[0])
		if not done and v >= q[2]:
			_done[q[0]] = true
			Aether.save.set_value("misiones_hechas", _done)
			Aether.toast(Aether.t("¡MISIÓN CUMPLIDA!") + " " + Aether.t(q[0]) + ("  +%d" % int(q[3]) if q[3] > 0 else ""), 3.0)
			Aether.sfx("win", 0.7, 1.2)
			if q[3] > 0:
				Aether.add_var.call_deferred(reward_var, q[3])
			done = true
		txt += ("✔ " if done else "• ") + Aether.t(q[0]) + ("" if done else "  %d/%d" % [int(min(v, q[2])), int(q[2])]) + "\n"
	_label.text = txt
