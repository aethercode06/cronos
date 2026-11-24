class_name ZarekDiario
extends Control
## El diario de Sofía (botón DIARIO o tecla TAB/M): pausa el juego y deja claro qué hay que hacer.
## - OBJETIVOS: salir viva: las salidas de la noche y lo que falta en cada una, las pistas de cada objeto, la furia
##   de la madre, qué pasa si te atrapa, lo que llevas y cómo se consigue cada final.
## - MAPA: plano de cada planta dibujado a mano; las salas que has pisado tienen nombre, las demás son siluetas.
##   Marca dónde estás, el cuarto de Damián, las escaleras, las salas cerradas con llave y los objetos que has
##   visto (o de los que tienes un presentimiento).
## Las pistas no dan la sala exacta: dicen la planta y el tipo de sala. Al ver el objeto, o tras 5 minutos sin
## encontrar nada, el diario apunta la sala exacta (para que nadie se quede atascado).

const PLANTAS := [[-1, "SÓTANO"], [0, "PLANTA BAJA"], [1, "PLANTA ALTA"], [2, "ÁTICO"]]
const NOMBRE_PLANTA := {-1: "el sótano", 0: "la planta baja", 1: "la planta alta", 2: "el ático"}
const TIPO_SALA := {"sala": "uno de los salones", "servicio": "una zona del servicio", "dormitorio": "un dormitorio",
	"sotano": "una de sus salas", "pasillo": "un pasillo", "tunel": "los túneles", "epicentro": "un cuarto de Damián",
	"roca": "la cueva", "agua": "el pozo"}
const REVELAR := 180.0  # segundos sin encontrar nada hasta que el diario apunta la sala exacta

var j: Node  # ZarekJuego
var _texto: RichTextLabel
var _mapa: Mapa
var _pestana := "objetivos"
var _planta := 0
var _botones_planta: HBoxContainer
var _sin_avance := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.055, 0.04, 0.97)
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var raiz := VBoxContainer.new()
	add_child(raiz)
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.offset_left = 36
	raiz.offset_right = -36
	raiz.offset_top = 20
	raiz.offset_bottom = -20
	raiz.add_theme_constant_override("separation", 10)
	var arriba := HBoxContainer.new()
	arriba.add_theme_constant_override("separation", 14)
	raiz.add_child(arriba)
	for p in [["OBJETIVOS", "objetivos"], ["MAPA", "mapa"]]:
		var b := _boton(p[0], 210)
		b.pressed.connect(func(): _pestana = p[1]; refrescar())
		arriba.add_child(b)
	var hueco := Control.new()
	hueco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arriba.add_child(hueco)
	var cerrar := _boton("VOLVER", 180)
	cerrar.pressed.connect(cerrar_diario)
	arriba.add_child(cerrar)
	_botones_planta = HBoxContainer.new()
	_botones_planta.add_theme_constant_override("separation", 10)
	raiz.add_child(_botones_planta)
	for p in PLANTAS:
		var b := _boton(p[1], 190)
		b.pressed.connect(func(): _planta = p[0]; refrescar())
		_botones_planta.add_child(b)
	_texto = RichTextLabel.new()
	_texto.bbcode_enabled = true
	_texto.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_texto.add_theme_font_size_override("normal_font_size", 21)
	_texto.add_theme_font_size_override("bold_font_size", 23)
	_texto.add_theme_color_override("default_color", Color(0.9, 0.85, 0.74))
	_texto.scroll_active = true
	raiz.add_child(_texto)
	_mapa = Mapa.new()
	_mapa.d = self
	_mapa.size_flags_vertical = Control.SIZE_EXPAND_FILL
	raiz.add_child(_mapa)

func _boton(t: String, w: float) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(w, 50)
	b.add_theme_font_size_override("font_size", 21)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.09, 0.05, 0.95)
	sb.border_color = Color(0.55, 0.38, 0.2)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(5)
	b.add_theme_stylebox_override("normal", sb)
	var sh := sb.duplicate()
	sh.bg_color = Color(0.32, 0.16, 0.07, 0.95)
	b.add_theme_stylebox_override("hover", sh)
	b.add_theme_stylebox_override("pressed", sh)
	return b

func abrir(pestana := "") -> void:
	if pestana != "":
		_pestana = pestana
	var lv: int = j.mansion.level_of(j.player.global_position.y + 0.5)
	_planta = clampi(lv, -1, 2)
	visible = true
	j._hud_visible(false)
	j.get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	refrescar()

func cerrar_diario() -> void:
	visible = false
	j.get_tree().paused = false
	if j.state in ["juego", "escondido", "ritual"]:
		j._hud_visible(true)
	if not DisplayServer.is_touchscreen_available() and j.state in ["juego", "escondido"]:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func refrescar() -> void:
	var es_mapa := _pestana == "mapa"
	_texto.visible = not es_mapa
	_mapa.visible = es_mapa
	_botones_planta.visible = es_mapa
	if es_mapa:
		_mapa.queue_redraw()
	else:
		_texto.text = texto_objetivos()

## Avance del tiempo sin encontrar objetos (lo llama el juego cada fotograma).
func tick(delta: float, encontrado: bool) -> void:
	if encontrado:
		_sin_avance = 0.0
		return
	_sin_avance += delta
	if _sin_avance >= REVELAR:
		_sin_avance = 0.0
		for s in j.mansion.seals:
			if not s.taken and not s.get("visto", false) and not s.get("revelado", false):
				s["revelado"] = true
				j.message("Tengo un presentimiento: %s está en %s.\n(Apuntado en el DIARIO)" % [nombre_objeto(s), j.mansion.room_name(s.pos)], 4.0)
				break

static func nombre_objeto(s: Dictionary) -> String:
	return String(ZarekMansion.NOMBRE_OBJETO.get(s.get("tipo", ""), "un objeto"))

## Pista de dónde está un objeto: la planta y el tipo de sala; exacta si ya lo viste o lo presentiste.
func pista(s: Dictionary) -> String:
	var m: ZarekMansion = j.mansion
	if s.get("visto", false) or s.get("revelado", false):
		return "está en [b]%s[/b]" % m.room_name(s.pos)
	var rid := m.room_at(s.pos)
	if rid < 0:
		return "en algún sitio fuera de la casa, en %s" % m.room_name(s.pos)
	var r: Dictionary = m.rooms[rid]
	return "en %s, en %s" % [NOMBRE_PLANTA.get(int(r.level), "la casa"), TIPO_SALA.get(String(r.type), "alguna sala")]

func _check(ok: bool) -> String:
	return "[color=#7fd17f]✔[/color]" if ok else "[color=#a08060]○[/color]"

func texto_objetivos() -> String:
	var m: ZarekMansion = j.mansion
	var t := ""
	var sc: Array = ZarekNoches.SUCESOS[j.suceso]
	t += "[b]%s[/b] — %s\n\n" % [sc[0], sc[1]]
	var rs: ZarekHuida = j.huida
	t += "[b]SALIR VIVA DE LA FINCA[/b]\n"
	t += "%s Soltarme la cadena del tobillo (algo fino y duro para forzar el candado).\n" % _check(not rs.encadenada)
	t += "%s Salir del cuarto donde me encerró (forzar la cerradura: hace ruido).\n" % _check(not rs.en_celda)
	t += "%s Escapar por una de las salidas de esta noche:\n" % _check(j.state == "final")
	for r in ZarekHuida.SALIDAS:
		if r == rs.salida_cerrada:
			t += "      [color=#a06050]✖ %s — bloqueada: %s[/color]\n" % [ZarekHuida.NOMBRE_SALIDA[r].capitalize(), ZarekHuida.BLOQUEO[r]]
			continue
		var f := rs.faltan(r)
		t += "      %s %s%s\n" % [_check(f.is_empty()), ZarekHuida.NOMBRE_SALIDA[r].capitalize(), "" if f.is_empty() else " — falta: " + ", ".join(f)]
	t += "      Lo largo (cortar la cadena, cambiar la rueda, trepar, rociar) se hace con [b]MANTÉN USAR[/b], y hace ruido.\n"
	t += "\n[b]OBJETOS DE LA NOCHE[/b] (%d/%d)\n" % [j.seals, m.seals.size()]
	for s in m.seals:
		if s.taken:
			t += "      %s %s\n" % [_check(true), nombre_objeto(s)]
		else:
			t += "      %s %s — %s\n" % [_check(false), nombre_objeto(s), pista(s)]
	var it: ZarekInteraccion = j.inter
	t += "\n[b]LA CASA (lo que puedo usar)[/b]\n"
	t += "%s La caja fuerte del padre, en su estudio: 4 cifras, día y mes. Las notas dicen qué fecha.\n" % _check(it.caja_abierta)
	t += "%s El reloj de pie del vestíbulo: alguien movió las agujas. «A las tres se abre».\n" % _check(it.reloj_abierto)
	t += "%s Los fusibles del sótano: él los quitó. Con ellos en el cuadro, el sótano tiene luz.\n" % _check(it.fusibles_puestos)
	t += "%s La nana de la madre al piano (hay que leer la partitura): la calma, pero Damián lo oye.\n" % _check(it.nana_leida)
	t += "Fabricar: botella + trapo + gasolina = cóctel incendiario (se lanza con BENGALA). Latas con cordel en una puerta abierta: suenan si alguien la cruza. Palanca: arranca las tablas de una ventana tapiada de abajo.\n"
	t += "Sigilo: quieta junto a una puerta cerrada, escucho. Agachada + USAR, miro por la cerradura. Un grifo abierto tapa mis pasos un rato.\n"
	var llevo: Array[String] = []
	if it.botellas > 0: llevo.append("Botellas: %d" % it.botellas)
	if it.trapos > 0: llevo.append("Trapos: %d" % it.trapos)
	if it.cocteles > 0: llevo.append("Cócteles: %d" % it.cocteles)
	if it.latas > 0: llevo.append("Latas: %d" % it.latas)
	if it.palanca: llevo.append("Palanca")
	if it.fusibles: llevo.append("Fusibles")
	if it.llavero: llevo.append("Llavero del padre")
	if not llevo.is_empty():
		t += "Llevo: " + " · ".join(llevo) + "\n"
	t += "\n[b]LA MADRE (furia: %d %%)[/b]\n" % int(rs.furia)
	if rs.madre_muerta:
		t += "%s Ardió en la capilla. Zarek ha muerto con ella.\n\n" % _check(true)
	elif rs.madre_suelta:
		t += "Está suelta. Es más rápida que Damián y si me toca no hay forcejeo. [b]Solo la luz la detiene[/b]: la linterna, las salas iluminadas, las bengalas.\n"
		t += "Para acabar con ella: rociar la capilla con gasolina, atraerla dentro y lanzar una bengala.\n\n"
	else:
		t += "Encadenada en la capilla del sótano, pero la casa es suya: mueve cosas, cierra puertas, apaga luces. Si hago ruido abajo, grita y Damián acude.\n"
		t += "Su furia sube con mis errores: ruido en el sótano, correr, romper cosas, que Damián me atrape, gritar de miedo, entrar en su capilla. Baja si soy sigilosa. [b]Al 100 %% rompe las cadenas.[/b]\n"
		t += "Para acabar con ella: rociar la capilla con gasolina y lanzar una bengala dentro.\n\n"
	t += "[b]SI ME ATRAPA[/b]\n"
	t += "Me quedan fuerzas para [b]%d[/b] %s. Damián no me mata: me deja inconsciente y me cuelga en el matadero del sótano, junto a la capilla, para su madre. La última vez me bajará a la capilla.\n" % [j.lives, "vez" if j.lives == 1 else "veces"]
	t += "Si me atrapa la madre, me muerde: me suelto, pero llevo su mordisco%s.\n" % (" [color=#d05050](ya me ha mordido)[/color]" if j.huida.mordida else "")
	t += "Con un arma en la mano puedo forcejear (machacar USAR) en vez de perder una vida.\n"
	t += "Me oye antes de verme: agachada hago menos ruido. Me ve mejor con la linterna encendida.\n\n"
	t += "[b]LO QUE LLEVO[/b]\n"
	var cosas: Array[String] = ["Linterna %d %%" % int(j.battery), "Bengalas: %d" % j.salt, "Tablones: %d" % j.tablones]
	if j.defensa:
		if j.defensa.arma != "":
			cosas.append(String(ZarekDefensa.ARMAS[j.defensa.arma].nombre).capitalize())
		if j.defensa.cepos > 0:
			cosas.append("Trampas de caza: %d" % j.defensa.cepos)
		if j.defensa.escopeta:
			cosas.append("Escopeta (%d cartuchos)" % j.defensa.cartuchos)
	for ll in j.llaves_salas:
		cosas.append("Llave de «%s»" % ll)
	t += " · ".join(cosas) + "\n"
	var cerradas: Array[String] = []
	for c in j.salas_cerradas:
		if (c.puerta as Dictionary).locked:
			cerradas.append(String(c.nombre) + (" (tengo la llave)" if String(c.nombre) in j.llaves_salas else ""))
	if not cerradas.is_empty():
		t += "Salas cerradas con llave esta noche: %s. Las llaves están en algún cajón.\n" % ", ".join(cerradas)
	t += "\n[b]FINALES[/b]\n"
	var hechos: Array = Aether.save.get_value("zarek_finales", [])
	t += "%s Escapé — sal viva por cualquier salida.\n" % _check("escapar" in hechos)
	t += "%s El fuego — quema a la madre en su capilla (gasolina + bengala) y escapa.\n" % _check("verdadero" in hechos)
	t += "%s Hambre — ¿qué pasa si escapas llevando su mordisco… y ella sigue viva?\n" % _check("oculto" in hechos)
	t += "Con los 24 secretos del ARCHIVO (%d/24), cualquier final añade el epílogo con toda la verdad.\n" % ZarekSecretos.cuantos()
	return t


## Plano de una planta: salas como rectángulos (con nombre si ya has entrado), marcas y tu posición.
class Mapa extends Control:
	var d: ZarekDiario

	func _draw() -> void:
		var j: Node = d.j
		var m: ZarekMansion = j.mansion
		var lv := d._planta
		var salas: Array = m.rooms.filter(func(r): return int(r.level) == lv and r.type != "jardin")
		if salas.is_empty():
			return
		var caja: Rect2 = salas[0].rect
		for r in salas:
			caja = caja.merge(r.rect)
		var margen := 30.0
		var esc := minf((size.x - margen * 2) / caja.size.x, (size.y - margen * 2) / caja.size.y)
		var off := Vector2(margen, margen) + (size - Vector2(margen, margen) * 2 - caja.size * esc) * 0.5
		var a_pantalla := func(p: Vector2) -> Vector2: return off + (p - caja.position) * esc
		var fuente := get_theme_default_font()
		var cerradas := {}
		for c in j.salas_cerradas:
			if (c.puerta as Dictionary).locked:
				cerradas[c.id] = true
		for r in salas:
			var rc: Rect2 = r.rect
			var pr := Rect2(a_pantalla.call(rc.position), rc.size * esc)
			var vista: bool = j._salas_vistas.has(r.id)
			var col := Color(0.32, 0.26, 0.19) if vista else Color(0.12, 0.1, 0.08)
			if r.type == "epicentro":
				col = Color(0.42, 0.1, 0.08) if vista else col
			draw_rect(pr, col)
			draw_rect(pr, Color(0.62, 0.5, 0.36), false, 2.0)
			var nombre := String(r.name)
			if vista or (r.type == "epicentro" and lv == 1) or "Escalera" in nombre or "Vestíbulo" in nombre:
				var fs := 13 if pr.size.x < 120 else 15
				var txt := nombre.get_slice(" (", 0)
				if "Escalera" in nombre or "Vestíbulo" in nombre:
					txt = "⇅ " + txt
				if r.type == "epicentro" and lv == 1:
					txt = "☠ " + txt
				draw_string(fuente, pr.position + Vector2(5, fs + 3), txt, HORIZONTAL_ALIGNMENT_LEFT, pr.size.x - 8, fs, Color(0.95, 0.9, 0.8))
			else:
				draw_string(fuente, pr.get_center() - Vector2(5, -6), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.5, 0.42, 0.32))
			if cerradas.has(r.id):
				draw_string(fuente, pr.end - Vector2(46, 8), "LLAVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.8, 0.3))
		# objetos de la trampa vistos o presentidos
		for s in m.seals:
			var sp: Vector3 = s.pos
			if s.taken or m.level_of(sp.y + 0.5) != lv or not (s.get("visto", false) or s.get("revelado", false)):
				continue
			var q: Vector2 = a_pantalla.call(Vector2(sp.x, sp.z))
			draw_circle(q, 9.0, Color(1.0, 0.82, 0.2))
			draw_string(fuente, q + Vector2(12, 5), ZarekDiario.nombre_objeto(s), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.9, 0.5))
		# cuadro eléctrico
		var el: ZarekElectricidad = m.electricidad
		if el and not el.cuadro.is_empty() and m.level_of((el.cuadro.pos as Vector3).y + 0.5) == lv and j._salas_vistas.has(m.room_at(el.cuadro.pos)):
			var qe: Vector2 = a_pantalla.call(Vector2(el.cuadro.pos.x, el.cuadro.pos.z))
			draw_string(fuente, qe - Vector2(6, -6), "⚡", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.6, 0.85, 1.0))
		# tú
		var pp: Vector3 = j.player.global_position
		if m.level_of(pp.y + 0.5) == lv:
			var q2: Vector2 = a_pantalla.call(Vector2(pp.x, pp.z))
			var f: Vector3 = j.player.look_dir()
			var dir := Vector2(f.x, f.z).normalized()
			var lado := Vector2(-dir.y, dir.x)
			draw_colored_polygon(PackedVector2Array([q2 + dir * 14.0, q2 - dir * 8.0 + lado * 8.0, q2 - dir * 8.0 - lado * 8.0]), Color(0.95, 0.2, 0.15))
		var titulo := ""
		for p in ZarekDiario.PLANTAS:
			if p[0] == lv:
				titulo = p[1]
		draw_string(fuente, Vector2(10, size.y - 8), titulo + "   ·   ⇅ escaleras   ☠ cuarto de Damián   ● objeto visto   ⚡ cuadro eléctrico   LLAVE sala cerrada", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.75, 0.68, 0.55))
