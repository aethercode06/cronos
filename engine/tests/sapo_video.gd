extends Node
## Vídeo de prueba: combate contra el Gran Sapo animado en Blender, con los efectos nuevos.
## Ejecutar con --write-movie para grabar. Kael ataca solo; el jefe salta, aterriza y muere.

var game: CrGame
var f := 0

func _ready() -> void:
	var sc: Node = load("res://chronos/chronos.tscn").instantiate()
	game = sc.get_node("Juego")
	game.no_story = true
	game.all_powers = true
	add_child(sc)
	var mundo := 0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mundo="):
			mundo = int(a.split("=")[1])
	game.start_stage(2, mundo)

func _process(_d: float) -> void:
	f += 1
	var A: Dictionary = game.level.arena
	if f == 3 or (game.boss.is_empty() and f % 60 == 0):
		game.p.x = A.x1 + 140
		game.p.y = A.floor - 48
	if game.boss.is_empty():
		Input.action_press("right")
		if f > 900:
			get_tree().quit()
		return
	if game.boss_intro > 0.0:
		return
	var b: Dictionary = game.boss
	var bcx: float = b.x + b.w / 2
	var pcx: float = game.p.x + game.p.w / 2
	var near: bool = abs(bcx - pcx) < 120
	# moverse hacia el sapo y atacar; esquivar con dash cuando salta encima
	if not near:
		Input.action_press("right" if bcx > pcx else "left")
		Input.action_release("left" if bcx > pcx else "right")
	else:
		Input.action_release("left")
		Input.action_release("right")
	if b.st == "air" and abs(bcx - pcx) < 90 and int(f) % 30 == 0:
		Input.action_press("dash")
	else:
		Input.action_release("dash")
	# guion de poderes: combo normal, golpe cargado, guardia al aterrizar y picado sísmico
	var cyc: int = f % 240
	Input.action_release("guard")
	if b.st == "air" and b.vy > 200 and near and cyc < 120:
		Input.action_press("guard")
	if cyc >= 120 and cyc < 165:
		Input.action_press("attack")
	elif cyc >= 165 and cyc < 175:
		Input.action_release("attack")
	elif cyc == 190 and game.p.onGround:
		Input.action_press("jump")
	elif cyc == 205:
		Input.action_release("jump")
		Input.action_press("guard")
	elif near and f % 9 == 0:
		Input.action_press("attack")
	else:
		Input.action_release("attack")
	# la prueba no debe perder: vida llena
	game.p.hp = max(game.p.hp, 60.0)
	if f > 1500 and not b.dying:
		b.hp = 0.5
	if f > 1900 or b.get("done", false) and f > 400:
		get_tree().quit()
