@icon("res://addons/aether/icons/ui.svg")
class_name AetherNPC
extends Node2D
## Personaje con quien hablar: acércate y pulsa ATAQUE (o tócalo).
## Escribe lo que dice en «lines» (Nombre: texto, una por línea).

@export var npc_name := "Aldeano"
@export_multiline var lines := "Aldeano: ¡Hola, viajero!\nAldeano: Cuidado con el bosque."
## Variable que suma al terminar de hablar (vacío = nada). Útil para misiones.
@export var gives_var := ""
@export var texture: Texture2D
@export var art_scale := 0.5
@export var color := Color(0.95, 0.8, 0.4)

var _dlg: AetherDialog
var _near := false
var _cool := 0

func _ready() -> void:
	add_to_group("aether_npc")

func _process(_d: float) -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	var pl = Aether.player
	_near = pl != null and pl is Node2D and (pl as Node2D).global_position.distance_to(global_position) < 110
	if _near and Input.is_action_just_pressed("attack") and _dlg == null and Time.get_ticks_msec() > _cool:
		talk()

func talk() -> void:
	_dlg = AetherDialog.new()
	_dlg.lines = lines
	add_child(_dlg)
	var pl = Aether.player
	if pl and "talking" in pl:
		pl.talking = true
	_dlg.finished.connect(_done)
	_dlg.play()

func _done() -> void:
	var pl = Aether.player
	if pl and "talking" in pl:
		pl.talking = false
	if gives_var != "":
		Aether.add_var(gives_var, 1)
		gives_var = ""
	if _dlg:
		_dlg.queue_free()
	_dlg = null
	_cool = Time.get_ticks_msec() + 600

func _draw() -> void:
	draw_circle(Vector2(0, 18), 22, Color(0, 0, 0, 0.3))
	if texture:
		var s := texture.get_size() * art_scale
		draw_texture_rect(texture, Rect2(-s.x * 0.5, -s.y + 20, s.x, s.y), false)
	else:
		draw_circle(Vector2(0, -6), 22, color)
		draw_circle(Vector2(-7, -10), 4, Color(0.1, 0.1, 0.1))
		draw_circle(Vector2(7, -10), 4, Color(0.1, 0.1, 0.1))
	if _near:
		draw_string(ThemeDB.fallback_font, Vector2(-60, -60), Aether.t("ATAQUE: hablar"), HORIZONTAL_ALIGNMENT_CENTER, 120, 18, Color(1, 1, 1))
	else:
		draw_string(ThemeDB.fallback_font, Vector2(-10, -46), "!", HORIZONTAL_ALIGNMENT_CENTER, 20, 34, Color(1, 0.85, 0.3))
