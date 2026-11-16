@tool
extends EditorPlugin
## Abre la escena de HORNEAR, selecciona su LightmapGI, pulsa «Bake Lightmaps» y guarda. Sale al terminar.
func _enter_tree() -> void:
	if OS.get_environment("HORNEAR") != "":
		_ir.call_deferred()

func _esperar(s: float) -> void:
	await get_tree().create_timer(s).timeout

func _boton(n: Node, texto: String) -> Button:
	if n is Button and (n as Button).text.findn(texto) >= 0:
		return n
	for c in n.get_children():
		var b := _boton(c, texto)
		if b:
			return b
	return null

func _ir() -> void:
	var t0 := Time.get_ticks_msec()
	await _esperar(4.0)
	EditorInterface.open_scene_from_path(OS.get_environment("HORNEAR"))
	await _esperar(4.0)
	var raiz := EditorInterface.get_edited_scene_root()
	var lm: LightmapGI = raiz.get_node("LightmapGI")
	EditorInterface.get_selection().clear()
	EditorInterface.get_selection().add_node(lm)
	EditorInterface.edit_node(lm)
	await _esperar(2.0)
	var b := _boton(EditorInterface.get_base_control(), "Bake Lightmap")
	print("HORNO boton: ", b)
	if b == null:
		get_tree().quit(1)
		return
	b.pressed.emit()
	await _esperar(5.0)
	for d in EditorInterface.get_base_control().get_tree().root.find_children("*", "Window", true, false):
		if (d as Window).visible and d != EditorInterface.get_base_control().get_window():
			print("HORNO ventana: ", d.get_class(), " | ", d.title, " | ", d.get("dialog_text"), " | ", d.get("current_path"))
			if d is EditorFileDialog:
				(d as EditorFileDialog).current_path = "res://tests/luz/salon.lmbake"
				(d as EditorFileDialog).file_selected.emit("res://tests/luz/salon.lmbake")
				d.hide()
	await _esperar(6.0)
	for d in EditorInterface.get_base_control().get_tree().root.find_children("*", "Window", true, false):
		if (d as Window).visible and d != EditorInterface.get_base_control().get_window():
			print("HORNO tras elegir: ", d.get_class(), " | ", d.title, " | ", d.get("dialog_text"))
	for l in EditorInterface.get_base_control().find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree() and ((l as Label).text.findn("lightmap") >= 0 or (l as Label).text.findn("bake") >= 0):
			print("HORNO texto: ", (l as Label).text)
	for i in 3600:
		await _esperar(1.0)
		if lm.light_data != null:
			break
	print("HORNO datos: ", lm.light_data, " en ", (Time.get_ticks_msec() - t0) / 1000, " s")
	EditorInterface.save_scene()
	await _esperar(2.0)
	get_tree().quit(0)
