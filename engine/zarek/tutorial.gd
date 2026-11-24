class_name ZarekTutorial
extends CanvasLayer
## Los primeros minutos enseñan a jugar sin leer: en la celda, cada paso se pide con una frase corta y un
## aro que late sobre el botón (o la zona de la pantalla) que hay que usar. Solo la primera partida (o si se
## reactiva en las opciones). Los pasos salen solos de lo que la historia ya pide: mirar, moverse con la
## cadena, coger el clavo, forzar el candado, la linterna, agacharse, la cerradura y el DIARIO.

var j: Node  # ZarekJuego
var paso := -1
var _t := 0.0
var _yaw0 := 0.0
var _giro := 0.0
var _pos0 := Vector3.ZERO
var _luz_cambios := 0
var _luz_prev := true
var _diario_visto := false

var _texto: Label
var _sub: Label
var _aro: Aro
var _marca: Node3D

## [clave, texto, subtexto táctil, subtexto teclado, acción del aro]
const PASOS := [
	["mirar", "MIRA A TU ALREDEDOR", "Arrastra el dedo por la mitad derecha de la pantalla", "Mueve el ratón", "@mirar"],
	["mover", "MUÉVETE", "Pon el dedo en la mitad izquierda y deslízalo", "W A S D", "@mover"],
	["clavo", "BUSCA ALGO PARA ABRIR EL CANDADO", "Acércate a lo que brilla en el suelo y toca USAR", "Acércate y pulsa E", "usar"],
	["argolla", "FUERZA EL CANDADO", "MANTÉN pulsado USAR", "MANTÉN pulsada E", "usar"],
	["luz", "LA LINTERNA", "LUZ la apaga y la enciende. Apagada, él no te ve de lejos… ni tú a él", "F apaga y enciende", "linterna"],
	["agachar", "AGÁCHATE", "AGACHAR: pasos casi sin ruido. Úsalo siempre que esté cerca", "C para agacharte", "agachar"],
	["cerradura", "LA PUERTA ESTÁ CERRADA POR FUERA", "Ve a la puerta y MANTÉN USAR para forzar la cerradura (hace ruido)", "Ve a la puerta y MANTÉN E", "usar"],
	["diario", "TU DIARIO", "Arriba a la derecha: qué hacer, el mapa y lo que llevas", "TAB abre el diario", "@diario"],
]

func _ready() -> void:
	layer = 61
	process_mode = Node.PROCESS_MODE_ALWAYS
	_texto = Label.new()
	_texto.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_texto.position = Vector2(-500, 120)
	_texto.size = Vector2(1000, 50)
	_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texto.add_theme_font_size_override("font_size", 34)
	_texto.add_theme_color_override("font_color", Color(0.96, 0.88, 0.68))
	_texto.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_texto.add_theme_constant_override("outline_size", 8)
	_texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_texto)
	_sub = Label.new()
	_sub.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_sub.position = Vector2(-500, 168)
	_sub.size = Vector2(1000, 40)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sub.add_theme_font_size_override("font_size", 22)
	_sub.add_theme_color_override("font_color", Color(0.9, 0.86, 0.8))
	_sub.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_sub.add_theme_constant_override("outline_size", 6)
	_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sub)
	_aro = Aro.new()
	_aro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_aro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_aro)
	visible = false

static func toca(juego: Node) -> bool:
	return not Aether.save.get_value("zarek_tutorial_hecho", false)

func empezar() -> void:
	visible = true
	_ir(0)

func _ir(n: int) -> void:
	paso = n
	_t = 0.0
	if paso >= PASOS.size():
		_terminar()
		return
	var p: Array = PASOS[paso]
	var tactil: bool = DisplayServer.is_touchscreen_available()
	_texto.text = String(p[1])
	_sub.text = String(p[2] if tactil else p[3])
	_texto.modulate.a = 0.0
	_sub.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_texto, "modulate:a", 1.0, 0.4)
	tw.tween_property(_sub, "modulate:a", 1.0, 0.6)
	_aro.objetivo = _sitio(String(p[4])) if tactil or String(p[4]).begins_with("@d") else Vector2.INF
	_yaw0 = j.player._yaw
	_giro = 0.0
	_pos0 = j.player.global_position
	_luz_cambios = 0
	_luz_prev = j.flash_on
	if String(p[0]) == "clavo":
		_marcar(j.huida.clavo_pos)
	else:
		_quitar_marca()
	j.sound_at("pagina", j.player.global_position + Vector3(0, 1.4, 0), -18.0)

## Dónde late el aro: el centro de un botón táctil, una zona de la pantalla o el botón del DIARIO.
func _sitio(accion: String) -> Vector2:
	var vs: Vector2 = get_viewport().get_visible_rect().size
	match accion:
		"@mirar":
			return Vector2(vs.x * 0.68, vs.y * 0.45)
		"@mover":
			return Vector2(vs.x * 0.2, vs.y * 0.7)
		"@diario":
			if j.btn_diario:
				return j.btn_diario.get_global_rect().get_center()
			return Vector2(vs.x - 80, 40)
	for b in j.touch.buttons:
		if String(b[0]) == accion:
			var off: Vector2 = b[2]
			return Vector2(vs.x + off.x, vs.y + off.y)
	return Vector2.INF

func _marcar(p: Vector3) -> void:
	_quitar_marca()
	_marca = Node3D.new()
	j.mansion.add_child(_marca)
	_marca.global_position = p + Vector3(0, 0.05, 0)
	var luz := OmniLight3D.new()
	luz.light_color = Color(1.0, 0.85, 0.55)
	luz.omni_range = 1.1
	luz.light_energy = 1.4
	luz.shadow_enabled = false
	luz.position = Vector3(0, 0.25, 0)
	_marca.add_child(luz)

func _quitar_marca() -> void:
	if is_instance_valid(_marca):
		_marca.queue_free()
	_marca = null

func _process(delta: float) -> void:
	if paso < 0 or paso >= PASOS.size() or j == null:
		return
	_t += delta
	_aro.t += delta
	_aro.queue_redraw()
	if is_instance_valid(_marca):
		(_marca.get_child(0) as OmniLight3D).light_energy = 0.9 + 0.6 * sin(_t * 5.0)
	var hu: ZarekHuida = j.huida
	var hecho := false
	match String(PASOS[paso][0]):
		"mirar":
			_giro += absf(wrapf(j.player._yaw - _yaw0, -PI, PI))
			_yaw0 = j.player._yaw
			hecho = _giro > 2.2
		"mover":
			hecho = Vector2(j.player.global_position.x - _pos0.x, j.player.global_position.z - _pos0.z).length() > 0.8
		"clavo":
			hecho = hu.tiene_clavo
		"argolla":
			hecho = not hu.encadenada
		"luz":
			if j.flash_on != _luz_prev:
				_luz_prev = j.flash_on
				_luz_cambios += 1
			hecho = _luz_cambios >= 2 or (_t > 14.0)
			if _luz_cambios == 1 and not j.flash_on:
				_sub.text = "Ahora vuelve a encenderla"
		"agachar":
			hecho = j.player.crouching or _t > 14.0
		"cerradura":
			hecho = not hu.en_celda
		"diario":
			if j.diario and j.diario.visible:
				_diario_visto = true
			hecho = (_diario_visto and not j.diario.visible) or _t > 16.0
	# si el jugador ya va por delante (p. ej. cogió el clavo mientras miraba), salta los pasos hechos
	if not hecho and paso < 2 and hu.tiene_clavo:
		hecho = true
	if hecho:
		_aro.objetivo = Vector2.INF
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_texto, "modulate:a", 0.0, 0.3)
		tw.tween_property(_sub, "modulate:a", 0.0, 0.3)
		paso += 1
		var siguiente := paso
		paso = -1
		await get_tree().create_timer(0.7, true, false, true).timeout
		_ir(siguiente)

func _terminar() -> void:
	_quitar_marca()
	Aether.save.set_value("zarek_tutorial_hecho", true)
	_texto.text = "SAL VIVA DE LA FINCA"
	_sub.text = "Si oyes pasos pesados… escóndete. Si te ve, corre."
	_texto.modulate.a = 1.0
	_sub.modulate.a = 1.0
	_aro.objetivo = Vector2.INF
	await get_tree().create_timer(4.5).timeout
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_texto, "modulate:a", 0.0, 1.0)
	tw.tween_property(_sub, "modulate:a", 0.0, 1.0)
	await tw.finished
	visible = false
	paso = -1

## Aro que late (dos círculos que se abren) sobre el punto de la pantalla a tocar.
class Aro extends Control:
	var objetivo := Vector2.INF
	var t := 0.0
	func _draw() -> void:
		if objetivo == Vector2.INF:
			return
		for k in 2:
			var f := fmod(t * 0.9 + k * 0.5, 1.0)
			var r := 50.0 + f * 55.0
			draw_arc(objetivo, r, 0.0, TAU, 48, Color(1.0, 0.82, 0.45, (1.0 - f) * 0.85), 5.0, true)
		draw_arc(objetivo, 46.0, 0.0, TAU, 48, Color(1.0, 0.9, 0.6, 0.55 + 0.3 * sin(t * 6.0)), 3.0, true)
