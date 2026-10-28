extends Node
## Prueba de Chronos en Aether: genera las 3 fases, juega solo la 1-1 y vence al Gran Sapo.

var game: CrGame
var f := 0
var phase := 0

func _ready() -> void:
	for a in 3:
		var L := CrLevel.new().build(0, a, 1)
		print("CHRONOS: fase 1-%d ancho = %d plataformas = %d enemigos = %d gemas = %d" % [a + 1, L.width, L.plats.size(), L.enemies.size(), L.gems.size()])
	var sc: Node = load("res://chronos/chronos.tscn").instantiate()
	game = sc.get_node("Juego")
	game.autoplay = true
	add_child(sc)

func _process(_d: float) -> void:
	f += 1
	if phase == 0:
		if game.state == "clear" or f > 7000:
			print("CHRONOS: 1-1 recorrido = %d%% estado = %s tiempo = %.1f s" % [int(100.0 * game.p.x / game.level.width), game.state, game.time])
			phase = 1
			game.autoplay = false
			game.start_stage(2)
			f = 0
	elif phase == 1:
		if f == 5:
			var A: Dictionary = game.level.arena
			game.p.x = A.x1 + 120
			game.p.y = A.floor - 48
		if f > 10 and not game.boss.is_empty() and game.boss_intro <= 0.0 and not game.boss.dying:
			game.p.atkN = 0
			game.p.hitSet = []
			game._hit_boss({"x": game.boss.x, "y": game.boss.y, "w": 10.0, "h": 10.0})
		if game.state == "clear" or f > 2000:
			print("CHRONOS: jefe vencido = ", game.state == "clear", " vida máx jefe = ", game.boss.get("max", 0))
			if game.state == "clear":
				print("CHRONOS PORT OK")
			get_tree().quit(0)
