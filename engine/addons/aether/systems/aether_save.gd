class_name AetherSave
extends RefCounted
## Guardado de partidas: Aether.save.set_value("nivel", 3); Aether.save.get_value("nivel", 1)
## Se guarda solo en el teléfono (user://), con varias ranuras y copia de seguridad.

var slot := 0
var data := {}

func _path(s: int) -> String:
	return "user://partida_%d.json" % s

func load_slot(s := 0) -> void:
	slot = s
	data = {}
	for p in [_path(s), _path(s) + ".bak"]:
		if FileAccess.file_exists(p):
			var f := FileAccess.open(p, FileAccess.READ)
			var d = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				data = d
				return

func save() -> void:
	var p := _path(slot)
	if FileAccess.file_exists(p):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(p), ProjectSettings.globalize_path(p + ".bak"))
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func get_value(key: String, default = null):
	return data.get(key, default)

func set_value(key: String, value, autosave := true) -> void:
	data[key] = value
	if autosave:
		save()

func add(key: String, amount := 1.0) -> float:
	var v: float = float(data.get(key, 0.0)) + amount
	set_value(key, v)
	return v

func has(key: String) -> bool:
	return data.has(key)

func erase_slot(s: int) -> void:
	for p in [_path(s), _path(s) + ".bak"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	if s == slot:
		data = {}
