@icon("res://addons/aether/icons/aether.svg")
class_name AetherFlashlight
extends PointLight2D
## Linterna para juegos de terror: ponla dentro del jugador. Apunta hacia
## donde mira, gasta batería y parpadea cuando se agota. Añade también un
## «Oscuridad» (CanvasModulate) a la escena para que todo lo demás esté negro.

## Segundos de batería (0 = infinita).
@export var battery := 90.0
## Pilas que recargan (variable de la lógica sin código).
@export var refill_var := "pilas"
@export var reach := 3.0

var charge := 1.0
var _bar: ColorRect
var _bar_bg: ColorRect

func _ready() -> void:
	texture = _cone()
	texture_scale = reach
	energy = 1.3
	shadow_enabled = true
	color = Color(1.0, 0.95, 0.8)
	if Engine.is_editor_hint():
		return
	var layer := CanvasLayer.new()
	layer.layer = 45
	add_child(layer)
	_bar_bg = ColorRect.new()
	_bar_bg.color = Color(0, 0, 0, 0.6)
	_bar_bg.position = Vector2(24, 130)
	_bar_bg.size = Vector2(200, 14)
	layer.add_child(_bar_bg)
	_bar = ColorRect.new()
	_bar.color = Color(1, 0.9, 0.4)
	_bar.position = Vector2(24, 130)
	_bar.size = Vector2(200, 14)
	layer.add_child(_bar)
	Aether.picked.connect(_on_picked)

func _cone() -> Texture2D:
	var s := 256
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var c := Vector2(s * 0.5, s * 0.5)
	for y in s:
		for x in s:
			var v := Vector2(x, y) - c
			var d := v.length() / (s * 0.5)
			var a := 0.0
			if d < 1.0:
				var ang: float = abs(v.angle())
				var cone: float = clamp(1.0 - (ang - 0.35) / 0.25, 0.0, 1.0) if v.x > 0 else 0.0
				a = max(cone * (1.0 - d), (1.0 - d / 0.22) * 0.8 if d < 0.22 else 0.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

func _on_picked(v: String) -> void:
	if v == refill_var:
		charge = 1.0
		Aether.toast(Aether.t("¡Linterna recargada!"))

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var p := get_parent()
	if p and p.get("facing") != null:
		rotation = lerp_angle(rotation, (p.get("facing") as Vector2).angle(), min(1.0, delta * 14.0))
	if battery > 0.0:
		charge = max(0.0, charge - delta / battery)
	var flick := 1.0
	if charge < 0.2:
		flick = 0.3 + randf() * 0.7 if randf() < 0.3 else 1.0
	energy = (0.25 + 1.1 * min(1.0, charge * 3.0)) * flick
	if _bar:
		_bar.size.x = 200.0 * charge
		_bar.color = Color(1, 0.9, 0.4) if charge > 0.2 else Color(1, 0.3, 0.3)
