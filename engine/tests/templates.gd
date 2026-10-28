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
	await _logic_test()
	_next()

## Lógica sin código: al empezar suma 5 monedas; al llegar a 5 da una llave.
func _logic_test() -> void:
	var lg := AetherLogic.new()
	lg.start_vars = {"monedas": 0}
	var e1 := AetherEvent.new()
	e1.trigger = "inicio"
	e1.actions.append(AetherStep.make("sumar", {"cantidad": 5.0, "var": "monedas"}))
	var e2 := AetherEvent.new()
	e2.trigger = "variable"
	e2.trigger_params = {"var": "monedas", "valor": 5.0}
	e2.conditions.append(AetherStep.make("azar", {"pct": 100.0}))
	e2.actions.append(AetherStep.make("dar", {"cantidad": 1.0, "objeto": "llave_prueba"}))
	e2.actions.append(AetherStep.make("esperar", {"seg": 0.1}))
	e2.actions.append(AetherStep.make("aviso", {"texto": "ok"}))
	var arr: Array[AetherEvent] = [e1, e2]
	lg.events = arr
	add_child(lg)
	await get_tree().create_timer(0.5).timeout
	print("AETHER: logica monedas = ", Aether.get_var("monedas"), " llave = ", Aether.inventory.has("llave_prueba"))
	if Aether.get_var("monedas") == 5.0 and Aether.inventory.has("llave_prueba"):
		print("AETHER: LOGICA OK")
	Aether.inventory.take("llave_prueba")
	lg.queue_free()
	await get_tree().process_frame
	# piezas de sistemas
	for sc in [AetherDialog, AetherShop, AetherQuests, AetherDaily, AetherEffect]:
		var n = sc.new()
		add_child(n)
		await get_tree().process_frame
		if n.has_method("open"):
			n.open()
			n.close_shop()
		if n is AetherDialog:
			n.play("Tic: Hola\nKael: Adiós")
			n._next(); n._next()
		if n is AetherEffect:
			n.play()
		n.queue_free()
	get_tree().paused = false
	print("AETHER: sistemas OK")

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
