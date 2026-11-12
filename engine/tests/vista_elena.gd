extends Node3D
## Captura de Elena con cada expresión (prueba visual): godot --path . res://tests/vista_elena.tscn -- <carpeta>
var e: ZarekElena
var cam: Camera3D
var paso := 0
var t := 0.0
var out := "user://"
const PLAN := [["mirada", "idle", 0.0], ["sonrisa", "idle", 0.0], ["poseida", "idle", 0.0], ["grito", "attack", 0.0], ["grito", "attack", 35.0], ["furia", "run", 0.0]]

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.03, 0.03, 0.035)
	env.environment.ambient_light_color = Color(0.5, 0.5, 0.55); env.environment.ambient_light_energy = 0.5
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(env)
	var l := SpotLight3D.new(); l.position = Vector3(0.6, 2.2, -1.6); l.light_energy = 6.0; l.spot_range = 8.0; l.spot_angle = 35.0
	add_child(l); l.look_at(Vector3(0, 1.55, 0))
	e = ZarekElena.new(); e.only_visual = true; add_child(e)
	cam = Camera3D.new(); add_child(cam); cam.fov = 35.0
	print("ELENA modelo:", e.model != null, " piel:", e.piel != null, " mandibula:", e.jaw_bone)

func _process(delta: float) -> void:
	t += delta
	if paso >= PLAN.size():
		print("VISTA ELENA OK"); get_tree().quit(); return
	var p: Array = PLAN[paso]
	e.play_anim(p[1])
	e.set_expr(p[0])
	if p[0] == "grito": e.state = ZarekElena.S.CHASE
	var ang := deg_to_rad(p[2])
	cam.position = Vector3(sin(ang) * 1.0, 1.62, -cos(ang) * 1.0)
	cam.look_at(Vector3(0, 1.58, 0))
	if t > 1.2:
		var img := get_viewport().get_texture().get_image()
		img.save_png("%s/elena_%d_%s.png" % [out, paso, p[0]])
		paso += 1; t = 0.0
