extends Node
## Prueba automática (sin pantalla): carga la fase, juega un poco, entra en la
## arena, derrota al Gran Sapo y comprueba que todo funcionó.
## Con --shots también guarda capturas (necesita pantalla, p. ej. xvfb).

var level: Node
var frame := 0
var phase := "run"
var shots := false
var shot_dir := ""
var ok_boss := false
var log_lines: Array[String] = []

func _ready() -> void:
	shots = "--shots" in OS.get_cmdline_user_args()
	shot_dir = ProjectSettings.globalize_path("res://").path_join("../engine_shots")
	DirAccess.make_dir_recursive_absolute(shot_dir)
	var scene: PackedScene = load("res://demo/main.tscn")
	level = scene.instantiate()
	add_child.call_deferred(level)
	Aether.boss_defeated.connect(func(): ok_boss = true)
	print("AETHER: escena cargada")

func _shot(name: String) -> void:
	if not shots:
		return
	var img := get_viewport().get_texture().get_image()
	if img:
		img.save_png(shot_dir.path_join(name + ".png"))
		print("AETHER: captura ", name)

func _press(a: String, on: bool) -> void:
	if on:
		Input.action_press(a)
	else:
		Input.action_release(a)

func _process(_delta: float) -> void:
	if not level.is_inside_tree() or level.player == null:
		return
	frame += 1
	var pl = level.player
	var boss = level.boss
	match phase:
		"run":
			# corre, salta y ataca por la primera parte del nivel
			_press("right", true)
			_press("jump", frame % 50 < 14)
			_press("attack", frame % 16 < 3)
			if frame == 90: _shot("01_inicio")
			if frame == 200: _shot("02_combate")
			if frame > 360:
				_press("right", false); _press("jump", false); _press("attack", false)
				pl.global_position = Vector2(level.arena.position.x + 320, 580)
				pl.velocity = Vector2.ZERO
				phase = "arena"
				frame = 0
		"arena":
			if frame == 5:
				pl.hp = pl.max_hp
			if frame == 40: _shot("03_jefe_intro")
			if frame == 160:
				boss.set_state("tongue_prep")
			if frame == 200: _shot("04_lengua")
			if frame == 260:
				boss.set_state("leap_prep")
			if frame == 330: _shot("05_salto")
			if frame > 400 and frame % 20 == 0 and not boss.dying:
				pl.hp = pl.max_hp
				boss.weak = true
				boss.take_hit(6.0, pl, true)
			if boss.dying and phase == "arena":
				phase = "die"
				frame = 0
			if frame > 2400:
				print("AETHER: ERROR el jefe no cayó")
				get_tree().quit(1)
		"die":
			if frame == 20: _shot("06_derrota")
			if frame == 90: _shot("07_derrota2")
			if (ok_boss and frame > 300) or frame > 8000:
				_shot("08_final")
				print("AETHER: jefe derrotado = ", ok_boss)
				print("AETHER: SMOKE OK" if ok_boss else "AETHER: ERROR sin señal de derrota")
				get_tree().quit(0 if ok_boss else 1)
