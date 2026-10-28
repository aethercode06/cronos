extends Node
## Carga todos los scripts del motor para que Godot muestre cada error con su línea.

func _ready() -> void:
	var bad := 0
	for f in _all("res://addons"):
		var s = load(f)
		if s == null or (s is GDScript and not s.can_instantiate() and not f.contains("editor/")):
			print("AETHER: script con error ", f)
			bad += 1
	print("AETHER: scripts revisados, errores = ", bad)
	get_tree().quit(0)

func _all(dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for sub in d.get_directories():
		out.append_array(_all(dir.path_join(sub)))
	return out
