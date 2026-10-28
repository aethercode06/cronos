@icon("res://addons/aether/icons/ui.svg")
class_name AetherHUD
extends CanvasLayer
## Interfaz de Aether Engine: vida del jugador con retrato, barra del jefe
## con su nombre y carteles grandes («¡GUARDIÁN DERROTADO!»).

var _hp_fill: ColorRect
var _hp_back: ColorRect
var _hp_ghost: ColorRect
var _boss_box: Control
var _boss_fill: ColorRect
var _boss_ghost: ColorRect
var _boss_name: Label
var _banner: Label
var _sub: Label
var _hp_k := 1.0
var _hp_ghost_k := 1.0
var _boss_k := 1.0
var _boss_ghost_k := 1.0

func _ready() -> void:
	layer = 50
	add_to_group("aether_hud")
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	# vida de Kael
	var panel := ColorRect.new()
	panel.color = Color(0.03, 0.03, 0.08, 0.7)
	panel.position = Vector2(24, 22)
	panel.size = Vector2(420, 92)
	root.add_child(panel)
	var face := TextureRect.new()
	face.texture = Aether.tex("pt_kael")
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.position = Vector2(30, 26)
	face.size = Vector2(84, 84)
	root.add_child(face)
	var name := _label("KAEL", 26, Color(1, 1, 1))
	name.position = Vector2(126, 28)
	root.add_child(name)
	_hp_back = ColorRect.new()
	_hp_back.color = Color(0.12, 0.1, 0.16)
	_hp_back.position = Vector2(128, 70)
	_hp_back.size = Vector2(300, 22)
	root.add_child(_hp_back)
	_hp_ghost = ColorRect.new()
	_hp_ghost.color = Color(1.0, 0.85, 0.85)
	_hp_ghost.position = _hp_back.position
	_hp_ghost.size = _hp_back.size
	root.add_child(_hp_ghost)
	_hp_fill = ColorRect.new()
	_hp_fill.color = Color(0.24, 0.96, 0.63)
	_hp_fill.position = _hp_back.position
	_hp_fill.size = _hp_back.size
	root.add_child(_hp_fill)
	# barra del jefe
	_boss_box = Control.new()
	_boss_box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_box.visible = false
	root.add_child(_boss_box)
	_boss_name = _label("", 28, Color(1, 0.9, 0.7))
	_boss_name.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_boss_name.position.y = 120
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_box.add_child(_boss_name)
	var bb := ColorRect.new()
	bb.color = Color(0.1, 0.06, 0.08, 0.85)
	bb.set_anchors_preset(Control.PRESET_CENTER_TOP)
	bb.position = Vector2(-340, 162)
	bb.size = Vector2(680, 20)
	_boss_box.add_child(bb)
	_boss_ghost = ColorRect.new()
	_boss_ghost.color = Color(1, 0.9, 0.8)
	_boss_ghost.position = Vector2(0, 0)
	_boss_ghost.size = bb.size
	bb.add_child(_boss_ghost)
	_boss_fill = ColorRect.new()
	_boss_fill.color = Color(0.95, 0.25, 0.3)
	_boss_fill.size = bb.size
	bb.add_child(_boss_fill)
	# cartel grande
	_banner = _label("", 72, Color(1, 0.9, 0.55))
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.size = Vector2(1200, 100)
	_banner.position = Vector2(-600, -120)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.modulate.a = 0
	root.add_child(_banner)
	_sub = _label("", 30, Color(1, 1, 1))
	_sub.set_anchors_preset(Control.PRESET_CENTER)
	_sub.size = Vector2(1200, 50)
	_sub.position = Vector2(-600, -20)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.modulate.a = 0
	root.add_child(_sub)

func _label(t: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 10)
	return l

func set_hp(hp: float, max_hp: float) -> void:
	_hp_k = clamp(hp / max_hp, 0.0, 1.0)

func show_boss(name: String) -> void:
	_boss_name.text = name
	_boss_box.visible = true
	_boss_box.modulate.a = 0
	create_tween().tween_property(_boss_box, "modulate:a", 1.0, 0.6)
	banner(name, Aether.t("¡PREPÁRATE!"))

func set_boss_hp(hp: float, max_hp: float) -> void:
	_boss_k = clamp(hp / max_hp, 0.0, 1.0)
	if hp <= 0:
		create_tween().tween_property(_boss_box, "modulate:a", 0.0, 0.8)

func banner(t: String, sub := "", dur := 2.4) -> void:
	_banner.text = t
	_sub.text = sub
	for l in [_banner, _sub]:
		var tw: Tween = l.create_tween()
		l.scale = Vector2.ONE
		tw.tween_property(l, "modulate:a", 1.0, 0.25)
		tw.tween_interval(dur)
		tw.tween_property(l, "modulate:a", 0.0, 0.5)

var _bound: Node = null
var _boss_bound: Node = null

func _process(delta: float) -> void:
	# se conecta solo al jugador activo (no hace falta programar nada)
	if Aether.player and _bound != Aether.player and Aether.player.has_signal("hp_changed"):
		_bound = Aether.player
		_bound.hp_changed.connect(set_hp)
	# barra del jefe automática
	if _boss_bound == null:
		for b in get_tree().get_nodes_in_group("boss"):
			if b.get("active"):
				_boss_bound = b
				show_boss(b.boss_name)
				b.hp_changed.connect(set_boss_hp)
				break
	_hp_fill.size.x = 300.0 * _hp_k
	_hp_ghost_k = max(_hp_k, _hp_ghost_k - delta * 0.6)
	_hp_ghost.size.x = 300.0 * _hp_ghost_k
	_hp_fill.color = Color(0.24, 0.96, 0.63) if _hp_k > 0.35 else Color(1.0, 0.3, 0.35)
	_boss_fill.size.x = 680.0 * _boss_k
	_boss_ghost_k = max(_boss_k, _boss_ghost_k - delta * 0.35)
	_boss_ghost.size.x = 680.0 * _boss_ghost_k
