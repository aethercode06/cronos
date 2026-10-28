@tool
@icon("res://addons/aether/icons/hazard.svg")
class_name AetherZone
extends Area2D
## Zona invisible: cuando el jugador entra o sale, se lanzan sus eventos
## (meta, trampa, puerta, diálogo, punto de control…). Se ve en el editor.

## Tamaño de la zona.
@export var size := Vector2(160, 200):
	set(v):
		size = v
		_shape()
		queue_redraw()
## Color en el editor.
@export var editor_color := Color(0.2, 0.9, 1.0, 0.25)
## Eventos de la zona (usa «Cuando el jugador entra en la zona»).
@export var events: Array[AetherEvent] = []

var runner: AetherLogicRunner
var _cs: CollisionShape2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	_shape()
	if Engine.is_editor_hint():
		return
	runner = AetherLogicRunner.new(self, events)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	runner.start.call_deferred()

func _on_enter(b: Node) -> void:
	if b.is_in_group("player"):
		runner.fire("entra")

func _on_exit(b: Node) -> void:
	if b.is_in_group("player"):
		runner.fire("sale")

func _shape() -> void:
	if not is_inside_tree():
		return
	if _cs == null:
		_cs = CollisionShape2D.new()
		add_child(_cs)
	var r := RectangleShape2D.new()
	r.size = size
	_cs.shape = r
	_cs.position = Vector2(0, -size.y * 0.5)

func _process(delta: float) -> void:
	if runner:
		runner.tick(delta)

func _exit_tree() -> void:
	if runner:
		runner.dispose()

func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2(-size.x * 0.5, -size.y), size), editor_color)
		draw_rect(Rect2(Vector2(-size.x * 0.5, -size.y), size), Color(editor_color.r, editor_color.g, editor_color.b, 0.9), false, 2.0)
