extends Node
## Prueba de las plantillas: abre cada una, la juega unos segundos y comprueba
## que no hay errores. Con --shots guarda una captura de cada una.

const LIST := ["res://plantillas/plataformas.tscn", "res://plantillas/arena_jefe.tscn", "res://plantillas/corredor.tscn", "res://plantillas/aventura_3d.tscn", "res://plantillas/titulo.tscn",
	"res://plantillas/disparos.tscn", "res://plantillas/puzle.tscn", "res://plantillas/defensa_torres.tscn", "res://plantillas/carreras.tscn", "res://plantillas/carreras_3d.tscn",
	"res://plantillas/lucha.tscn", "res://plantillas/cartas.tscn", "res://plantillas/rpg.tscn", "res://plantillas/terror.tscn"]
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
	process_mode = Node.PROCESS_MODE_ALWAYS
	await _logic_test()
	await _genre_test()
	_next()

## Juegos por género: cada uno se monta y se juega solo un momento (selftest).
func _genre_test() -> void:
	var ok := true
	for sc in [AetherShooter, AetherMatch3, AetherTowerDefense, AetherRacer, AetherFighter, AetherCards]:
		var g = sc.new()
		add_child(g)
		await get_tree().process_frame
		await get_tree().process_frame
		var r: bool = g.selftest()
		print("AETHER: genero ", g.get_script().get_global_name(), " = ", r)
		ok = ok and r
		g.queue_free()
		await get_tree().process_frame
	# vista desde arriba: mapa, jugador, criaturas, personaje que habla
	var rpg: Node = load("res://plantillas/rpg.tscn").instantiate()
	add_child(rpg)
	for i in 5:
		await get_tree().process_frame
	var map: AetherMap = rpg.get_node("Mapa")
	var foes := 0
	var npcs: Array = []
	var pl: AetherTopDownPlayer = null
	for c in map.get_children():
		if c is AetherChaser:
			foes += 1
		elif c is AetherNPC:
			npcs.append(c)
		elif c is AetherTopDownPlayer:
			pl = c
	print("AETHER: mapa criaturas = ", foes, " personajes = ", npcs.size(), " jugador = ", pl != null)
	ok = ok and foes > 0 and npcs.size() > 0 and pl != null
	if npcs.size() > 0:
		var n: AetherNPC = npcs[0]
		n.talk()
		await get_tree().process_frame
		var k := 0
		while n._dlg != null and k < 10:
			n._dlg._next()
			k += 1
		get_tree().paused = false
		print("AETHER: dialogo terminado = ", n._dlg == null)
		ok = ok and n._dlg == null
	if pl:
		var p0 := pl.global_position
		Input.action_press("right")
		for i in 30:
			await get_tree().physics_frame
		Input.action_release("right")
		print("AETHER: jugador se mueve = ", pl.global_position.x > p0.x)
		ok = ok and pl.global_position.x > p0.x
	rpg.queue_free()
	await get_tree().process_frame
	# coche 3D con física
	var car_scene: Node = load("res://plantillas/carreras_3d.tscn").instantiate()
	add_child(car_scene)
	var car: AetherCar3D = car_scene.get_node("Coche")
	Input.action_press("up")
	for i in 180:
		await get_tree().physics_frame
	Input.action_release("up")
	print("AETHER: coche km/h = ", int(car.speed_kmh()))
	# kit de gore en 3D y 2D
	AetherGore.spray_3d(car_scene, car.global_position + Vector3(0, 1, 0), Vector3.FORWARD)
	AetherGore.pool_3d(car_scene, Vector3(0, 0.2, -95))
	var n2 := Node2D.new()
	add_child(n2)
	AetherGore.spray_2d(n2, Vector2(300, 300), Vector2.RIGHT)
	await get_tree().process_frame
	print("AETHER: gore texturas = ", AetherGore.textures().size(), " manchas 2D = ", n2.get_child_count())
	ok = ok and AetherGore.textures().size() == 4 and n2.get_child_count() > 0
	n2.queue_free()
	ok = ok and car.speed_kmh() > 5.0
	car_scene.queue_free()
	await get_tree().process_frame
	Aether.player = null
	if ok:
		print("AETHER: GENEROS OK")

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
	get_tree().paused = false
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
	if "3d" in LIST[i]:
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
