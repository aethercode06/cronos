@tool
@icon("res://addons/aether/icons/aether.svg")
class_name AetherWorld3D
extends Node3D
## Ambiente 3D listo con un toque: cielo, sol con sombras, niebla, brillo
## y colores de cine. Elige un estilo en «preset».

@export_enum("dia", "atardecer", "noche", "mazmorra") var preset := "dia":
	set(v):
		preset = v
		_rebuild()
## Brillo de las luces intensas (glow).
@export_range(0.0, 2.0) var glow := 0.8:
	set(v):
		glow = v
		_rebuild()

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	if not is_inside_tree():
		return
	for c in get_children():
		if c.has_meta("aether_world"):
			c.free()
	var P := {
		"dia": [Color(0.35, 0.6, 1.0), Color(0.75, 0.85, 1.0), Color(1.0, 0.97, 0.9), 1.2, -50.0, 0.0015],
		"atardecer": [Color(0.3, 0.25, 0.55), Color(1.0, 0.6, 0.35), Color(1.0, 0.7, 0.45), 1.0, -30.0, 0.003],
		"noche": [Color(0.02, 0.03, 0.1), Color(0.1, 0.12, 0.25), Color(0.6, 0.7, 1.0), 0.35, -40.0, 0.006],
		"mazmorra": [Color(0.02, 0.01, 0.03), Color(0.08, 0.05, 0.06), Color(1.0, 0.6, 0.35), 0.25, -65.0, 0.015],
	}
	var p: Array = P.get(preset, P["dia"])
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = p[0]
	sm.sky_horizon_color = p[1]
	sm.ground_horizon_color = p[1]
	sm.ground_bottom_color = Color(0.1, 0.1, 0.12)
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = glow > 0
	env.glow_intensity = glow
	env.fog_enabled = true
	env.fog_density = p[5]
	env.fog_light_color = p[1]
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.1
	var we := WorldEnvironment.new()
	we.environment = env
	we.set_meta("aether_world", true)
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = p[2]
	sun.light_energy = p[3]
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(p[4], -35, 0)
	sun.directional_shadow_max_distance = 60.0
	sun.set_meta("aether_world", true)
	add_child(sun)
