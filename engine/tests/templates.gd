extends Node
## Prueba de las plantillas: abre cada una, la juega unos segundos y comprueba
## que no hay errores. Con --shots guarda una captura de cada una.

const LIST := ["res://plantillas/plataformas.tscn", "res://plantillas/arena_jefe.tscn", "res://plantillas/corredor.tscn", "res://plantillas/aventura_3d.tscn", "res://plantillas/titulo.tscn"]
var i := -1
var cur: Node
var f := 0
var shots := false
var shot_dir := ""

func _ready() -> void:
	shots = "--shots" in OS.get_cmdline_user_args()
	shot_dir = ProjectSettings.globalize_path("res://").path_join("../engine_shots")
	DirAccess.make_dir_recursive_absolute(shot_dir)
	Aether.achievements.define("prueba", "Probador", "Abre todas las plantillas")
	Aether.save.set_value("prueba_guardado", 42)
	print("AETHER: guardado = ", Aether.save.get_value("prueba_guardado"))
	print("AETHER: idioma = ", Aether.lang.code, " · ", Aether.t("JUGAR"))
	_next()

func _next() -> void:
	for a in ["left", "right", "up", "down", "jump", "attack", "dash"]:
		Input.action_release(a)
	if cur:
		cur.queue_free()
	i += 1
	f = 0
	if i >= LIST.size():
		Aether.achievements.unlock("prueba")
		print("AETHER: TEMPLATES OK")
		get_tree().quit(0)
		return
	var ps: PackedScene = load(LIST[i])
	cur = ps.instantiate()
	add_child(cur)
	print("AETHER: abierta ", LIST[i])

func _process(_d: float) -> void:
	if i >= LIST.size() or cur == null:
		return
	f += 1
	if f % 30 < 18: Input.action_press("right") 
	else: Input.action_release("right")
	if i == 3:
		Input.action_press("up")
	if f % 45 == 0: Input.action_press("attack")
	if f % 45 == 3: Input.action_release("attack")
	if f % 70 == 0: Input.action_press("jump")
	if f % 70 == 10: Input.action_release("jump")
	if f == 150 and shots:
		var img := get_viewport().get_texture().get_image()
		img.save_png(shot_dir.path_join("plantilla_%d.png" % i))
	if f > 170:
		_next()
