@tool
extends EditorPlugin
## Panel «Aether» del editor: crear desde plantillas, añadir piezas a la escena
## con un toque, guía rápida y asistente opcional (Claude).

var dock: Control
var claude: Control

func _enter_tree() -> void:
	dock = _build_dock()
	dock.name = "Aether"
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)
	claude = preload("res://addons/aether/editor/claude_panel.gd").new()
	claude.name = "Claude (opcional)"
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, claude)

func _exit_tree() -> void:
	if dock:
		remove_control_from_docks(dock)
		dock.queue_free()
	if claude:
		remove_control_from_docks(claude)
		claude.queue_free()

func _build_dock() -> Control:
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(220, 300)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	_title(v, "AETHER ENGINE")
	_text(v, "Crea juegos sin programar: empieza con una plantilla y añade piezas con un toque.")
	_title(v, "Crear")
	_button(v, "Nueva fase de plataformas", func(): _from_template("res://plantillas/plataformas.tscn", "fase"))
	_button(v, "Nueva arena de jefe", func(): _from_template("res://plantillas/arena_jefe.tscn", "arena"))
	_button(v, "Nuevo corredor infinito", func(): _from_template("res://plantillas/corredor.tscn", "corredor"))
	_button(v, "Nueva aventura 3D", func(): _from_template("res://plantillas/aventura_3d.tscn", "aventura3d"))
	_button(v, "Nueva pantalla de título", func(): _from_template("res://plantillas/titulo.tscn", "titulo"))
	_button(v, "Abrir la prueba de Chronos", func(): EditorInterface.open_scene_from_path("res://demo/main.tscn"))
	_title(v, "Añadir a la escena")
	_button(v, "Jugador", func(): _add("res://addons/aether/player/platformer_player.gd", "Jugador", "CharacterBody2D"))
	_button(v, "Enemigo", func(): _add("res://addons/aether/enemy/enemy.gd", "Enemigo", "CharacterBody2D"))
	_button(v, "Suelo / plataforma", func(): _add("res://addons/aether/world/aether_ground.gd", "Suelo", "StaticBody2D"))
	_button(v, "Cámara épica", func(): _add("res://addons/aether/core/aether_camera.gd", "Camara", "Camera2D"))
	_button(v, "Personaje por piezas", func(): _add("res://addons/aether/rig/aether_rig.gd", "Personaje", "Node2D"))
	_button(v, "Interfaz (vida y jefe)", func(): _add("res://addons/aether/ui/hud.gd", "Interfaz", "CanvasLayer"))
	_button(v, "Controles táctiles", func(): _add("res://addons/aether/ui/touch_controls.gd", "ControlesTactiles", "CanvasLayer"))
	_button(v, "Menú de pausa", func(): _add("res://addons/aether/ui/aether_menu.gd", "MenuPausa", "CanvasLayer"))
	_title(v, "Añadir en 3D")
	_button(v, "Jugador 3D", func(): _add("res://addons/aether/three_d/aether_player_3d.gd", "Jugador3D", "CharacterBody3D"))
	_button(v, "Enemigo 3D", func(): _add("res://addons/aether/three_d/aether_enemy_3d.gd", "Enemigo3D", "CharacterBody3D"))
	_button(v, "Cámara 3D", func(): _add("res://addons/aether/three_d/aether_camera_3d.gd", "Camara3D", "Node3D"))
	_button(v, "Ambiente 3D (cielo, sol, niebla)", func(): _add("res://addons/aether/three_d/aether_world_3d.gd", "Ambiente", "Node3D"))
	_button(v, "Joystick táctil", func(): _add("res://addons/aether/ui/aether_joystick.gd", "Joystick", "CanvasLayer"))
	_title(v, "Guía rápida")
	_text(v, "1. «Nueva fase de plataformas».\n2. Pulsa ▶ (arriba a la derecha) para jugar.\n3. Selecciona cualquier pieza y cambia sus ajustes en el Inspector: velocidad, salto, vida, daño…\n4. Mueve suelos y enemigos arrastrándolos.\n5. Para tus propios personajes: crea un AetherAnimSet en el Inspector del jugador y añade sus animaciones.\n6. Exporta a Android en Proyecto → Exportar.")
	return sc

func _title(v: VBoxContainer, t: String) -> void:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(0.4, 0.88, 1.0))
	v.add_child(l)

func _text(v: VBoxContainer, t: String) -> void:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 200
	v.add_child(l)

func _button(v: VBoxContainer, t: String, f: Callable) -> void:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size.y = 40
	b.pressed.connect(f)
	v.add_child(b)

func _from_template(path: String, base: String) -> void:
	DirAccess.make_dir_recursive_absolute("res://mis_juegos")
	var i := 1
	while FileAccess.file_exists("res://mis_juegos/%s_%d.tscn" % [base, i]):
		i += 1
	var dest := "res://mis_juegos/%s_%d.tscn" % [base, i]
	DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(dest))
	EditorInterface.get_resource_filesystem().scan()
	await get_tree().create_timer(0.5).timeout
	EditorInterface.open_scene_from_path(dest)

func _add(script_path: String, node_name: String, base_type: String) -> void:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		push_warning("Aether: abre o crea una escena primero.")
		return
	var n: Node = ClassDB.instantiate(base_type)
	n.set_script(load(script_path))
	n.name = node_name
	var ur := get_undo_redo()
	ur.create_action("Aether: añadir " + node_name)
	ur.add_do_method(root, "add_child", n, true)
	ur.add_do_method(n, "set_owner", root)
	ur.add_do_reference(n)
	ur.add_undo_method(root, "remove_child", n)
	ur.commit_action()
	if n is Node2D and root is Node2D:
		var vp := EditorInterface.get_editor_viewport_2d()
		if vp:
			n.position = vp.get_final_transform().affine_inverse() * (vp.get_visible_rect().size * 0.5)
	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(n)
