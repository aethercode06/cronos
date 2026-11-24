extends Node3D
## ¿Se ve Damián con el renderizador del teléfono (Vulkan «mobile»)? Lo pone delante de la cámara con una luz.
func _ready() -> void:
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.15, 0.15, 0.18)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(0.3, 0.3, 0.3)
	add_child(env)
	var sol := DirectionalLight3D.new(); sol.rotation = Vector3(-0.6, 0.4, 0); add_child(sol)
	var e: Node3D = load("res://zarek/modelos/damian.glb").instantiate()
	add_child(e)
	e.rotation.y = 0.0
	var ap: AnimationPlayer = e.find_children("*", "AnimationPlayer", true, false)[0]
	print("ANIMS ", ap.get_animation_list())
	ap.play("hacha_caminar")
	for mi in e.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		print("MALLA ", m.name, " aabb=", m.get_aabb(), " capas=", m.layers, " mat=", m.get_active_material(0))
	var cam := Camera3D.new(); add_child(cam); cam.position = Vector3(0, 1.2, 3.2); cam.look_at(Vector3(0, 1.0, 0))
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/damian_vista.png")
	print("VISTA OK")
	get_tree().quit()
