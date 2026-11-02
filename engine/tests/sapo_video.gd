extends Node
## Vídeo de prueba: combate contra el Gran Sapo animado en Blender, con los efectos nuevos.
## Ejecutar con --write-movie para grabar. Kael ataca solo; el jefe salta, aterriza y muere.

var game: CrGame
var f := 0

func _ready() -> void:
	var sc: Node = load("res://chronos/chronos.tscn").instantiate()
	game = sc.get_node("Juego")
	game.no_story = true
	add_child(sc)
	game.start_stage(2, 0)

func _process(_d: float) -> void:
	f += 1
	if game.boss.is_empty():
		if f > 900:
			get_tree().quit()
		return
	var A: Dictionary = game.level.arena
	if f == 3:
		game.p.x = A.x1 + 140
		game.p.y = A.floor - 48
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
	if near and f % 9 == 0:
		Input.action_press("attack")
	else:
		Input.action_release("attack")
	# la prueba no debe perder: vida llena
	game.p.hp = max(game.p.hp, 60.0)
	if f > 1500 and not b.dying:
		b.hp = 0.5
	if f > 1900 or b.get("done", false) and f > 400:
		get_tree().quit()
