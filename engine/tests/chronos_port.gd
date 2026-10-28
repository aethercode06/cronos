extends Node
## Prueba de Chronos en Aether: juega sola la 1-1, recorre las 54 fases un momento
## y vence a tres guardianes distintos (sapo, volador y de suelo).

var game: CrGame
var f := 0
var phase := 0
var stage_i := 0
var max_x := 0.0
var bosses := [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]
var boss_i := 0

func _ready() -> void:
	var sc: Node = load("res://chronos/chronos.tscn").instantiate()
	game = sc.get_node("Juego")
	game.autoplay = true
	game.no_story = true
	add_child(sc)
	var mp: Node = load("res://chronos/mapa.tscn").instantiate()
	add_child(mp)
	mp.queue_free()

func _process(_d: float) -> void:
	f += 1
	if phase == 0:
		if game.state == "clear" or f > 7000:
			print("CHRONOS: 1-1 recorrido = %d%% estado = %s tiempo = %.1f s" % [int(100.0 * game.p.x / game.level.width), game.state, game.time])
			phase = 1
			f = 0
			_next_stage()
	elif phase == 1:
		max_x = max(max_x, game.p.x)
		if f > 240:
			print("CHRONOS: mundo %d fase %d ancho %d enemigos %d avance %d px" % [game.wi, game.act + 1, game.level.width, game.level.enemies.size(), int(max_x)])
			stage_i += 1
			f = 0
			if stage_i >= 54:
				phase = 2
				game.autoplay = false
				_boss_start()
			else:
				_next_stage()
	elif phase == 2:
		if f == 5:
			var A: Dictionary = game.level.arena
			game.p.x = A.x1 + 120
			game.p.y = A.floor - 48
		if f > 10 and not game.boss.is_empty() and game.boss_intro <= 0.0 and not game.boss.dying:
			game.p.atkN = 0
			game.p.hitSet = []
			if game.boss.has("vulnT"):
				game.boss.vulnT = 5.0
			if game.boss.st == "guard":
				game.boss.st = "walk"
			if int(game.boss.type) == 8:
				game.boss.st = "stuck"
				game.boss.t = 0.0
			game.dim = 1
			if f % 3 == 0:
				game._hit_boss({"x": game.boss.x, "y": game.boss.y, "w": 10.0, "h": 10.0})
		if game.state == "clear" or f > 4000:
			print("CHRONOS: guardián del mundo %d vencido = %s" % [game.wi, game.state == "clear"])
			if game.state != "clear":
				get_tree().quit(1)
				return
			boss_i += 1
			if boss_i >= bosses.size():
				phase = 3
				f = 0
				return
			_boss_start()

	elif phase == 3:
		_modes_test()

var _modes_done := false
func _modes_test() -> void:
	if _modes_done:
		return
	_modes_done = true
	var ok := true
	game.start_mode("torre")
	await get_tree().create_timer(0.3).timeout
	game._mode_clear()
	await get_tree().process_frame
	print("CHRONOS: torre piso = ", game.tower.floor, " mundo ", game.wi)
	ok = ok and int(game.tower.floor) == 2
	game.start_mode("rush")
	await get_tree().process_frame
	game._mode_clear()
	print("CHRONOS: rush guardián = ", game.rush.i, " mundo ", game.wi, " arena ", game.arena_lock or game.p.x > game.level.arena.x1)
	ok = ok and int(game.rush.i) == 1
	game.start_mode("diario")
	await get_tree().create_timer(0.3).timeout
	print("CHRONOS: diario mundo ", game.wi, " fase ", game.act)
	game.mode = "historia"
	game.start_stage(1, 0)
	await get_tree().process_frame
	var had_rift: bool = game.level.get("rift") is Dictionary and not game.level.rift.is_empty()
	game._enter_rift()
	await get_tree().create_timer(0.3).timeout
	var gems_in: int = game.level.gems.size()
	game._leave_rift(true)
	print("CHRONOS: grieta = ", had_rift, " gemas dentro = ", gems_in, " vuelta al modo ", game.mode)
	ok = ok and had_rift and game.mode == "historia"
	# historia: diálogo con espera y escena ilustrada
	game.no_story = false
	var st: CrStory = game.story
	var fin := [false]
	st.say([["TIC", "Hola"], ["KAEL", "Adiós"]], true, func() -> void: fin[0] = true)
	for k in 6:
		st._advance()
	var cut_done := [false]
	st.play_cut("intro", func() -> void: cut_done[0] = true)
	for k in 60:
		if cut_done[0]:
			break
		st._advance_cut()
	print("CHRONOS: historia diálogo = ", fin[0], " escena = ", cut_done[0])
	ok = ok and fin[0] and cut_done[0]
	if ok:
		print("CHRONOS PORT OK")
		get_tree().quit(0)
	else:
		get_tree().quit(1)

func _next_stage() -> void:
	var order: Array = CrGame.data().order
	max_x = 0.0
	game.start_stage(stage_i % 3, int(order[stage_i / 3]))

func _boss_start() -> void:
	f = 0
	game.start_stage(2, bosses[boss_i])
