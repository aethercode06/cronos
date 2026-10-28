@icon("res://addons/aether/icons/camera.svg")
class_name AetherCamera
extends Camera2D
## Cámara de Aether Engine: sigue al objetivo con anticipación,
## tiembla de forma suave (ruido) y hace «zoom de impacto».

@export var target: Node2D
@export var look_ahead := 140.0
@export var follow_speed := 6.0
@export var base_zoom := 1.0

var _trauma := 0.0
var _punch := 0.0
var _noise := FastNoiseLite.new()
var _t := 0.0
var _ahead := 0.0
var lock_rect := Rect2()          # zona fija (arena de jefe); vacía = libre

func _ready() -> void:
	_noise.frequency = 2.2
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	Aether.camera = self
	position_smoothing_enabled = false
	zoom = Vector2.ONE * base_zoom

func shake(amount: float, zoom_punch := 0.0) -> void:
	_trauma = min(1.0, _trauma + amount / 30.0)
	_punch = max(_punch, zoom_punch)

func snap() -> void:
	if target:
		global_position = target.global_position + Vector2(0, -80)

func _process(delta: float) -> void:
	_t += delta
	if target:
		var vel: Vector2 = target.get("velocity") if target.get("velocity") != null else Vector2.ZERO
		var face: float = target.get("face") if target.get("face") != null else 1.0
		_ahead = lerp(_ahead, face * look_ahead + vel.x * 0.12, 1.0 - exp(-delta * 2.5))
		var want := target.global_position + Vector2(_ahead, -90)
		if lock_rect.size.x > 0:
			var half := get_viewport_rect().size / (2.0 * zoom)
			want.x = clamp(want.x, lock_rect.position.x + half.x, lock_rect.end.x - half.x)
			if lock_rect.size.x < half.x * 2.0:
				want.x = lock_rect.get_center().x
			want.y = clamp(want.y, lock_rect.position.y + half.y, lock_rect.end.y - half.y)
		global_position = global_position.lerp(want, 1.0 - exp(-delta * follow_speed))
	# temblor con ruido (más natural que aleatorio puro)
	_trauma = max(0.0, _trauma - delta * 1.6)
	var s := _trauma * _trauma
	offset = Vector2(_noise.get_noise_2d(_t * 60.0, 0.0), _noise.get_noise_2d(0.0, _t * 60.0)) * 34.0 * s
	rotation = _noise.get_noise_2d(_t * 40.0, 99.0) * 0.035 * s
	_punch = max(0.0, _punch - delta * 0.5)
	zoom = Vector2.ONE * (base_zoom + _punch)
