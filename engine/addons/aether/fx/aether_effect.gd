@tool
@icon("res://addons/aether/icons/anim.svg")
class_name AetherEffect
extends Node2D
## Efectos de estilo anime con un toque. Elige uno en «preset».
## - De un golpe (golpe, magia, explosión, curación, rayo): se lanzan con play()
##   o con el evento «Efecto especial».
## - Continuos (fuego, portal, nieve, lluvia, hojas, chispas, aura): siempre activos.

@export_enum("golpe", "magia", "explosion", "curacion", "rayo", "fuego", "portal", "nieve", "lluvia", "hojas", "chispas", "aura") var preset := "golpe":
	set(v):
		preset = v
		_setup()
## Color principal (los valores > 1 brillan).
@export var color := Color(2.0, 1.6, 0.8)
## Tamaño.
@export_range(0.2, 5.0) var size := 1.0
## Lanzar al empezar (para los de un golpe).
@export var play_on_start := false

var _cont: CPUParticles2D
const LOOPS := ["fuego", "portal", "nieve", "lluvia", "hojas", "chispas", "aura"]

func _ready() -> void:
	_setup()
	if play_on_start and not Engine.is_editor_hint():
		play.call_deferred()

func _setup() -> void:
	if not is_inside_tree():
		return
	if _cont:
		_cont.queue_free()
		_cont = null
	if not preset in LOOPS:
		return
	var p := CPUParticles2D.new()
	p.texture = FX.dot()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	p.color = color
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = g
	match preset:
		"fuego":
			p.amount = 60; p.lifetime = 0.9; p.direction = Vector2.UP; p.spread = 18
			p.initial_velocity_min = 60 * size; p.initial_velocity_max = 140 * size; p.gravity = Vector2(0, -120)
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE; p.emission_sphere_radius = 18 * size
			p.scale_amount_min = 0.35 * size; p.scale_amount_max = 0.7 * size
		"portal":
			p.amount = 80; p.lifetime = 1.4; p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
			p.emission_sphere_radius = 70 * size
			p.radial_accel_min = -60; p.radial_accel_max = -40; p.orbit_velocity_min = 0.4; p.orbit_velocity_max = 0.6; p.gravity = Vector2.ZERO
			p.scale_amount_min = 0.15 * size; p.scale_amount_max = 0.3 * size
		"nieve", "lluvia", "hojas":
			p.amount = 120 if preset != "hojas" else 50; p.lifetime = 5.0
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE; p.emission_rect_extents = Vector2(900 * size, 10)
			p.direction = Vector2(-0.2, 1); p.spread = 10
			p.initial_velocity_min = 40 if preset != "lluvia" else 900; p.initial_velocity_max = 90 if preset != "lluvia" else 1200
			p.gravity = Vector2(0, 30); p.scale_amount_min = 0.06; p.scale_amount_max = 0.14 if preset != "lluvia" else 0.08
			if preset == "lluvia":
				p.lifetime = 1.0
			p.material = null
		"chispas":
			p.amount = 30; p.lifetime = 1.6; p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE; p.emission_sphere_radius = 80 * size
			p.gravity = Vector2(0, -20); p.initial_velocity_min = 5; p.initial_velocity_max = 25; p.scale_amount_min = 0.06; p.scale_amount_max = 0.14
		"aura":
			p.amount = 40; p.lifetime = 1.0; p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE; p.emission_sphere_radius = 50 * size
			p.gravity = Vector2(0, -160); p.initial_velocity_min = 0; p.initial_velocity_max = 20; p.scale_amount_min = 0.2 * size; p.scale_amount_max = 0.4 * size
	add_child(p)
	_cont = p
	p.emitting = true

## Lanza el efecto (los de un golpe).
func play() -> void:
	var par := get_parent()
	var c := color
	var k := size
	match preset:
		"golpe":
			FX.burst(par, global_position, c, 18, 600 * k, 0.35, 10 * k, 900)
			FX.ring(par, global_position, Color(c.r, c.g, c.b, 0.9), 140 * k, 0.25)
			FX.glow(par, global_position, Color(c.r, c.g, c.b, 0.7), 90 * k, 0.15)
			Aether.hitstop(0.06)
			Aether.shake(6 * k, 0.02)
			Aether.sfx("hit", 0.8)
		"magia":
			for i in 3:
				FX.ring(par, global_position, Color(c.r, c.g, c.b, 0.8 - i * 0.2), (120 + i * 70) * k, 0.45 + i * 0.1)
			FX.burst(par, global_position, c, 40, 380 * k, 0.8, 9 * k, -100)
			FX.glow(par, global_position, Color(c.r, c.g, c.b, 0.8), 160 * k, 0.5)
			Aether.sfx("heal", 0.7, 1.3)
		"explosion":
			FX.burst(par, global_position, Color(2.6, 1.6, 0.6), 60, 900 * k, 0.8, 16 * k, 500)
			FX.burst(par, global_position, Color(0.3, 0.3, 0.3, 0.8), 30, 300 * k, 1.2, 30 * k, -80)
			FX.ring(par, global_position, Color(2.4, 1.8, 1.0, 1.0), 360 * k, 0.4)
			FX.glow(par, global_position, Color(2.0, 1.4, 0.6, 1.0), 260 * k, 0.4)
			Aether.flash(Color(1, 0.8, 0.5), 0.35)
			Aether.shake(22 * k, 0.06)
			Aether.hitstop(0.12)
			Aether.sfx("boom", 1.0)
		"curacion":
			FX.burst(par, global_position, Color(0.6, 2.4, 1.0), 30, 200 * k, 1.0, 10 * k, -250)
			FX.ring(par, global_position, Color(0.5, 2.0, 1.0, 0.8), 120 * k, 0.5)
			Aether.sfx("heal", 0.8)
		"rayo":
			var line := Line2D.new()
			line.width = 10 * k
			line.default_color = Color(2.2, 2.4, 3.0)
			var mat := CanvasItemMaterial.new()
			mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			line.material = mat
			var y := -900.0
			while y < 0:
				line.add_point(Vector2(randf_range(-40, 40) * k, y))
				y += 90
			line.add_point(Vector2.ZERO)
			line.position = global_position
			par.add_child(line)
			var tw := line.create_tween()
			tw.tween_property(line, "modulate:a", 0.0, 0.3)
			tw.tween_callback(line.queue_free)
			FX.burst(par, global_position, Color(2, 2.2, 3), 30, 600 * k, 0.4, 9 * k, 600)
			Aether.flash(Color(0.8, 0.9, 1.0), 0.45)
			Aether.shake(16 * k, 0.04)
			Aether.sfx("boom", 0.8, 1.4)
		_:
			if _cont:
				_cont.restart()
