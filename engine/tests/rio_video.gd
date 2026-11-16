extends Node3D
## Clip corto del río (para ver la corriente en movimiento): godot --write-movie /tmp/rio.avi --fixed-fps 24 res://tests/rio_video.tscn
var cam: Camera3D
var t := 0.0
var a: Vector3
func _ready() -> void:
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.42, 0.38, 0.34); env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; env.tonemap_exposure = 1.35; env.tonemap_white = 6.0
	env.fog_enabled = true; env.fog_light_color = Color(0.12, 0.135, 0.18); env.fog_density = 0.02; env.fog_height = 1.4; env.fog_height_density = 0.1
	var sky := Sky.new(); var sm := ProceduralSkyMaterial.new(); sm.sky_top_color = Color(0.02, 0.03, 0.06); sm.sky_horizon_color = Color(0.06, 0.07, 0.1); sky.sky_material = sm
	env.sky = sky; env.background_mode = Environment.BG_SKY
	we.environment = env; add_child(we)
	var moon := DirectionalLight3D.new(); moon.light_color = Color(0.55, 0.65, 0.95); moon.light_energy = 0.45; moon.rotation_degrees = Vector3(-38, -55, 0); add_child(moon)
	var m := ZarekMansion.new(); add_child(m); m.build(1)
	a = m.cell_to_world("exterior", 31.0, 83.0) + Vector3(-12.0, 0, 0)
	cam = Camera3D.new(); cam.fov = 65.0; add_child(cam)
	var fl := SpotLight3D.new(); fl.light_color = Color(1, 0.9, 0.72); fl.light_energy = 5.0; fl.spot_range = 22.0; fl.spot_angle = 35.0; cam.add_child(fl)
	m.salto_pez(a + Vector3(4, 0, 0))
func _process(d: float) -> void:
	t += d
	cam.look_at_from_position(a + Vector3(-5.0 + t * 0.3, 2.0, -0.4), a + Vector3(4.0 + t * 0.3, -0.35, 0.3))
	if t > 5.0:
		get_tree().quit()
