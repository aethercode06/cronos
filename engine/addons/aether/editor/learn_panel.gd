@tool
extends ScrollContainer
## Panel «Aprender»: lecciones paso a paso dentro del editor. Cada paso
## explica qué hacer y, cuando se puede, tiene un botón «Hazlo por mí».

var plugin: EditorPlugin
var _list: VBoxContainer
var _lesson := -1
var _step := 0
var _done := {}

const CFG := "user://aether_aprender.cfg"

## [título, [[texto, acción, argumento], …]]
const LESSONS := [
	["1 · Tu primer juego en 5 minutos", [
		["Vamos a crear una fase de plataformas completa: suelos, enemigos, vida, controles y pausa.", "plantilla", "plataformas"],
		["Pulsa ▶ (arriba a la derecha) para jugar. Muévete con los botones de la pantalla. Cierra el juego para volver.", "jugar", ""],
		["Selecciona al Jugador: en el Inspector (derecha) cambia «Run Speed» o «Jump Velocity». ¡Juega otra vez y nota la diferencia!", "seleccionar", "Jugador"],
		["Añade un enemigo nuevo y arrástralo con el dedo a donde quieras.", "pieza", "Enemigo"],
		["Guarda la escena (Escena → Guardar). ¡Ya tienes tu primer nivel!", "guardar", ""],
	]],
	["2 · Lógica sin programar", [
		["La lógica se hace con frases CUANDO → SI → HACER. Añade «Lógica de la escena».", "pieza", "Logica"],
		["Con la Lógica seleccionada, abre el panel «Eventos» (izquierda) y pulsa «+ Nuevo evento».", "", ""],
		["En CUANDO elige «Cuando una variable llega a…», variable monedas, valor 5.", "", ""],
		["En HACER añade «Mostrar aviso» con el texto «¡5 monedas!» y «Sonido» gem.", "", ""],
		["Añade monedas (Objeto recogible) y juega: al coger 5 sale el aviso.", "pieza", "Moneda"],
	]],
	["3 · Juegos completos por género", [
		["Aether trae juegos ya hechos que solo tienes que cambiar: disparos, puzle, defensa de torres, carreras, lucha, cartas, RPG y terror.", "", ""],
		["Abre el de disparos y juega.", "plantilla", "disparos"],
		["Selecciona «Juego»: en el Inspector cambia la nave, los enemigos, la vida y las oleadas para ganar.", "seleccionar", "Juego"],
		["Prueba el de cartas: las cartas y los enemigos se escriben como texto en el Inspector, sin programar.", "plantilla", "cartas"],
	]],
	["4 · Niveles dibujados con letras (RPG y terror)", [
		["Abre el RPG.", "plantilla", "rpg"],
		["Selecciona «Mapa». En «Map» cada letra es algo: # pared, P jugador, M monstruo, N personaje, $ moneda, K llave, E salida, T árbol…", "seleccionar", "Mapa"],
		["Cambia letras y mira cómo cambia el nivel al momento. Escribe lo que dicen los personajes en «Npc Lines».", "", ""],
		["Activa «Horror» y tendrás oscuridad, linterna y acechadores (S) que solo se mueven cuando no los miras.", "", ""],
	]],
	["5 · Tus propios personajes", [
		["Con hojas de animación: en el Jugador, «Anim Set» → Nuevo AetherAnimSet y añade animaciones (idle, run, jump, attack1…).", "", ""],
		["Por piezas: añade un «Personaje por piezas» y crea una pieza por imagen (cabeza, brazo…). Se anima solo: andar, golpe, cubrirse…", "pieza", "PersonajePorPiezas"],
	]],
	["6 · Mundos 3D", [
		["Abre la aventura 3D.", "plantilla", "aventura_3d"],
		["Selecciona «Ambiente» y cambia «Preset» a noche o mazmorra.", "seleccionar", "Ambiente"],
		["Abre las carreras 3D: un coche con física real, rampa y conos.", "plantilla", "carreras_3d"],
	]],
	["7 · Publicar en Google Play", [
		["Abre el panel «Publicar» (abajo a la derecha).", "", ""],
		["Escribe nombre, paquete (com.tuempresa.tujuego), versión, elige icono y pulsa «Guardar datos».", "", ""],
		["Crea la ficha y la política de privacidad. Haz capturas tocando con 3 dedos mientras juegas.", "", ""],
		["Crea el archivo de GitHub y sigue COMO_PUBLICAR.txt para obtener el AAB firmado.", "", ""],
	]],
	["8 · Ayuda de Claude (opcional)", [
		["Todo funciona sin IA. Si quieres ayuda, en el panel «Claude (opcional)» pega tu clave de Anthropic.", "", ""],
		["Pide cosas como «pon 5 monedas y una meta» o «haz que el jefe sea más rápido». Nada cambia hasta que pulsas «Aplicar», y se puede deshacer.", "", ""],
	]],
]

func _ready() -> void:
	custom_minimum_size = Vector2(240, 300)
	var c := ConfigFile.new()
	if c.load(CFG) == OK:
		_done = c.get_value("aprender", "hechas", {})
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_list)
	_show_index()

func _clear() -> void:
	for ch in _list.get_children():
		ch.queue_free()

func _label(t: String, size := 14, col := Color(1, 1, 1)) -> void:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 200
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	_list.add_child(l)

func _button(t: String, f: Callable) -> void:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size.y = 40
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.pressed.connect(f)
	_list.add_child(b)

func _show_index() -> void:
	_clear()
	_label("APRENDE AETHER", 16, Color(0.4, 0.88, 1.0))
	_label("Lecciones cortas: sigue los pasos y en unos minutos estarás creando.")
	for i in LESSONS.size():
		_button(("✔ " if _done.has(i) else "") + LESSONS[i][0], _open.bind(i))

func _open(i: int) -> void:
	_lesson = i
	_step = 0
	_show_step()

func _show_step() -> void:
	_clear()
	var lesson: Array = LESSONS[_lesson]
	var steps: Array = lesson[1]
	var st: Array = steps[_step]
	_label(lesson[0], 15, Color(0.4, 0.88, 1.0))
	_label("Paso %d de %d" % [_step + 1, steps.size()], 13, Color(0.7, 0.7, 0.8))
	_label(st[0], 16)
	if st[1] != "":
		_button("✨ Hazlo por mí", _do.bind(st[1], st[2]))
	var h := HBoxContainer.new()
	_list.add_child(h)
	var back := Button.new()
	back.text = "◀ Atrás"
	back.custom_minimum_size = Vector2(90, 40)
	back.pressed.connect(_prev)
	h.add_child(back)
	var nx := Button.new()
	nx.text = "Siguiente ▶" if _step < steps.size() - 1 else "¡Terminado! ✔"
	nx.custom_minimum_size = Vector2(120, 40)
	nx.pressed.connect(_next)
	h.add_child(nx)
	_button("Volver a las lecciones", _show_index)

func _prev() -> void:
	if _step > 0:
		_step -= 1
		_show_step()
	else:
		_show_index()

func _next() -> void:
	var steps: Array = LESSONS[_lesson][1]
	if _step < steps.size() - 1:
		_step += 1
		_show_step()
		return
	_done[_lesson] = true
	var c := ConfigFile.new()
	c.set_value("aprender", "hechas", _done)
	c.save(CFG)
	_show_index()

func _do(kind: String, arg: String) -> void:
	if plugin == null:
		return
	match kind:
		"plantilla":
			plugin.call("_from_template", "res://plantillas/%s.tscn" % arg, arg)
		"jugar":
			EditorInterface.play_current_scene()
		"guardar":
			EditorInterface.save_scene()
		"pieza":
			plugin.call("add_piece", arg)
		"seleccionar":
			var root := EditorInterface.get_edited_scene_root()
			if root:
				var n := root.find_child(arg, true, false)
				if n:
					EditorInterface.get_selection().clear()
					EditorInterface.get_selection().add_node(n)
					EditorInterface.edit_node(n)
