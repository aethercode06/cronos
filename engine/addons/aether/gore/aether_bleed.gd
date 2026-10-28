@icon("res://addons/aether/icons/hazard.svg")
class_name AetherBleed
extends Node
## Ponlo dentro de un personaje (2D o 3D): deja un rastro de gotas mientras
## sangra, y salpica al recibir daño si el personaje avisa con hp_changed.

## Gotas por segundo mientras sangra.
@export var drops_per_second := 2.0
## Sangra siempre (si no, solo unos segundos después de cada golpe).
@export var always := false
## Segundos que sangra tras un golpe.
@export var after_hit := 4.0

var _bleed := 0.0
var _acc := 0.0
var _last_hp := -1.0

func _ready() -> void:
	var p := get_parent()
	if p and p.has_signal("hp_changed"):
		p.hp_changed.connect(_on_hp)

func _on_hp(hp: float, _max: float) -> void:
	if _last_hp >= 0.0 and hp < _last_hp:
		_bleed = after_hit
		var p := get_parent()
		if p is Node3D:
			AetherGore.spray_3d(p, (p as Node3D).global_position + Vector3(0, 1.2, 0), Vector3(randf_range(-1, 1), 0.3, randf_range(-1, 1)))
		elif p is Node2D:
			AetherGore.spray_2d(p.get_parent(), (p as Node2D).global_position + Vector2(0, -40), Vector2(randf_range(-1, 1), -0.3))
	_last_hp = hp

func _process(delta: float) -> void:
	_bleed = max(0.0, _bleed - delta)
	if not always and _bleed <= 0.0:
		return
	_acc += delta * drops_per_second
	while _acc >= 1.0:
		_acc -= 1.0
		var p := get_parent()
		if p is Node3D:
			var g := (p as Node3D).global_position
			var hit := (p as Node3D).get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(g + Vector3(0, 0.5, 0), g + Vector3(0, -3, 0)))
			if not hit.is_empty():
				AetherGore.splat_3d(p.get_tree().current_scene, hit.position + Vector3(randf_range(-0.2, 0.2), 0, randf_range(-0.2, 0.2)), hit.normal, randf_range(0.12, 0.3))
		elif p is Node2D:
			AetherGore.splat_2d(p.get_parent(), (p as Node2D).global_position + Vector2(randf_range(-10, 10), randf_range(10, 20)), randf_range(0.12, 0.25))
