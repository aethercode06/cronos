extends Node3D
## Recorrido de inspección: una captura por sala (desde una esquina, a la altura de los ojos, con luz suave).
## godot --path . res://tests/recorrido.tscn -- <carpeta> [filtro]
var m: ZarekMansion
var cam: Camera3D
var luz: OmniLight3D
func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var out := a[0] if a.size() > 0 else "/tmp"
	var filtro := a[1].to_lower() if a.size() > 1 else ""
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.02, 0.02, 0.03)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.55, 0.5, 0.45); env.environment.ambient_light_energy = 0.35
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(env)
	m = ZarekMansion.new(); add_child(m); m.build(2)
	for l in m.lamps: m.set_lamp(l, true)
	cam = Camera3D.new(); cam.fov = 75.0; add_child(cam)
	luz = OmniLight3D.new(); luz.omni_range = 14.0; luz.light_energy = 1.2; luz.light_color = Color(1, 0.92, 0.8); add_child(luz)
	var i := 0
	for r in m.rooms:
		if String(r.type) in ["jardin", "agua", "roca", "tunel"]: continue
		if filtro != "" and not (filtro in String(r.name).to_lower()): continue
		var rect: Rect2 = r.rect
		var y: float = r.y
		var esq := Vector3(rect.position.x + 0.6, y + 1.65, rect.position.y + 0.6)
		cam.position = esq
		cam.look_at(Vector3(rect.get_center().x, y + 1.0, rect.get_center().y))
		luz.position = Vector3(rect.get_center().x, y + 3.0, rect.get_center().y)
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		var nm := String(r.name).to_lower().replace(" ", "_").replace("·", "").replace("(", "").replace(")", "").replace(",", "")
		img.save_jpg("%s/%02d_%s.jpg" % [out, i, nm.left(30)], 0.85)
		print("SALA ", i, " ", r.name)
		i += 1
	get_tree().quit()
