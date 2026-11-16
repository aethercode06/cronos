extends Node3D
## Miniaturas: cada objeto solo, encuadrado de frente (+Z) y un poco desde arriba; imprime su tamaño real.
## godot --path . res://tests/miniaturas.tscn -- <carpeta_salida> <nombres...>
func _aabb(n: Node) -> AABB:
	var r := AABB()
	var first := true
	for c in n.find_children("*", "MeshInstance3D", true, false):
		var mi: MeshInstance3D = c
		var b: AABB = mi.global_transform * mi.get_aabb()
		if first: r = b; first = false
		else: r = r.merge(b)
	return r

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.33, 0.34, 0.37)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(1, 1, 1); env.environment.ambient_light_energy = 0.7
	add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-40, 25, 0); add_child(sun)
	var cam := Camera3D.new(); add_child(cam); cam.fov = 35
	for i in range(1, a.size()):
		var nm: String = a[i]
		var p := "res://zarek/objetos/%s.glb" % nm
		if not ResourceLoader.exists(p): p = "res://zarek/muebles/%s.glb" % nm
		if not ResourceLoader.exists(p): p = "res://zarek/arboles/%s.glb" % nm
		var ps: PackedScene = load(p) if ResourceLoader.exists(p) else null
		if ps == null: print("ROTO ", nm); continue
		var n: Node3D = ps.instantiate(); add_child(n)
		await get_tree().process_frame
		var b := _aabb(n)
		var c := b.get_center()
		var r: float = max(b.size.length() * 0.5, 0.02)
		var d: float = r / sin(deg_to_rad(cam.fov * 0.5)) * 1.05
		var dir := Vector3(1, 0.35, 0) if OS.get_environment("MINI_X") != "" else Vector3(0, 0.35, 1)
		cam.position = c + dir.normalized() * d
		cam.near = d * 0.02; cam.far = d * 4.0
		cam.look_at(c)
		await get_tree().process_frame
		await get_tree().process_frame
		get_viewport().get_texture().get_image().save_jpg("%s/%s.jpg" % [a[0], nm], 0.85)
		print("TAM %s %.2f %.2f %.2f" % [nm, b.size.x, b.size.y, b.size.z])
		n.queue_free()
	get_tree().quit()
