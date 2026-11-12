extends Node3D
## Captura de Elena con cada expresión (prueba visual): godot --path . res://tests/vista_elena.tscn -- <carpeta>
var e: ZarekElena
var cam: Camera3D
var lin: SpotLight3D
var paso := 0
var t := 0.0
var out := "user://"
const PLAN := [["mirada", "idle", 0.0], ["sonrisa", "idle", 0.0], ["poseida", "idle", 0.0], ["grito", "attack", 0.0], ["grito", "attack", 35.0], ["furia", "run", 0.0], ["mirada", "walk", 0.0]]

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.03, 0.03, 0.035)
	env.environment.ambient_light_color = Color(0.35, 0.38, 0.5); env.environment.ambient_light_energy = 0.25
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(env)
	# linterna del jugador (desde la cámara, como en el juego)
	lin = SpotLight3D.new(); lin.light_energy = 1.4; lin.spot_range = 20.0; lin.spot_angle = 30.0; lin.shadow_enabled = true
	add_child(lin)
	var luna := DirectionalLight3D.new(); luna.light_energy = 0.15; luna.light_color = Color(0.6, 0.7, 1.0); luna.rotation_degrees = Vector3(-40, 150, 0); add_child(luna)
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
	lin.global_transform = cam.global_transform.translated_local(Vector3(0.15, -0.1, 0))
	if paso == PLAN.size() - 1:
		cam.position = Vector3(0.4, 1.3, -2.6); cam.look_at(Vector3(0, 1.0, 0)); lin.global_transform = cam.global_transform
	if t > 1.2:
		var img := get_viewport().get_texture().get_image()
		img.save_png("%s/elena_%d_%s.png" % [out, paso, p[0]])
		paso += 1; t = 0.0
