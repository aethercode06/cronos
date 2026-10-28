@tool
extends VBoxContainer
## Conexión OPCIONAL con Claude. Sin clave, este panel no hace nada y el motor
## funciona completo sin IA. Con tu clave, Claude ve la escena abierta y puede:
## crear piezas, ajustarlas, borrarlas, crear eventos sin código, abrir
## plantillas, escribir scripts, guardar y probar el juego.
## Nada se toca hasta que pulsas «Aplicar», y todo se puede deshacer (Ctrl+Z).

const API := "https://api.anthropic.com/v1/messages"
const MODELS := ["claude-sonnet-5-5", "claude-opus-5-5", "claude-haiku-5-5"]

## Piezas que Claude puede crear: nombre → [script, tipo base]
const PIECES := {
	"Jugador": ["res://addons/aether/player/platformer_player.gd", "CharacterBody2D"],
	"Enemigo": ["res://addons/aether/enemy/enemy.gd", "CharacterBody2D"],
	"Suelo": ["res://addons/aether/world/aether_ground.gd", "StaticBody2D"],
	"Camara": ["res://addons/aether/core/aether_camera.gd", "Camera2D"],
	"Interfaz": ["res://addons/aether/ui/hud.gd", "CanvasLayer"],
	"Controles": ["res://addons/aether/ui/touch_controls.gd", "CanvasLayer"],
	"Menu": ["res://addons/aether/ui/aether_menu.gd", "CanvasLayer"],
	"Logica": ["res://addons/aether/logic/aether_logic.gd", "Node"],
	"Zona": ["res://addons/aether/logic/aether_zone.gd", "Area2D"],
	"Moneda": ["res://addons/aether/logic/aether_pickup.gd", "Area2D"],
	"Contador": ["res://addons/aether/logic/aether_counter.gd", "CanvasLayer"],
	"Dialogo": ["res://addons/aether/systems/aether_dialog.gd", "CanvasLayer"],
	"Tienda": ["res://addons/aether/systems/aether_shop.gd", "CanvasLayer"],
	"Misiones": ["res://addons/aether/systems/aether_quests.gd", "CanvasLayer"],
	"RegaloDiario": ["res://addons/aether/systems/aether_daily.gd", "CanvasLayer"],
	"Efecto": ["res://addons/aether/fx/aether_effect.gd", "Node2D"],
	"PersonajePorPiezas": ["res://addons/aether/rig/aether_rig.gd", "Node2D"],
	"Jugador3D": ["res://addons/aether/three_d/aether_player_3d.gd", "CharacterBody3D"],
	"Enemigo3D": ["res://addons/aether/three_d/aether_enemy_3d.gd", "CharacterBody3D"],
	"Camara3D": ["res://addons/aether/three_d/aether_camera_3d.gd", "Node3D"],
	"Ambiente3D": ["res://addons/aether/three_d/aether_world_3d.gd", "Node3D"],
	"Joystick": ["res://addons/aether/ui/aether_joystick.gd", "CanvasLayer"],
	"JugadorVistaArriba": ["res://addons/aether/topdown/aether_topdown_player.gd", "CharacterBody2D"],
	"CriaturaVistaArriba": ["res://addons/aether/topdown/aether_chaser.gd", "CharacterBody2D"],
	"Personaje": ["res://addons/aether/topdown/aether_npc.gd", "Node2D"],
	"MapaDeLetras": ["res://addons/aether/topdown/aether_map.gd", "Node2D"],
	"Linterna": ["res://addons/aether/topdown/aether_flashlight.gd", "PointLight2D"],
	"Sangre": ["res://addons/aether/gore/aether_bleed.gd", "Node"],
	"PersonajeAnimado3D": ["res://addons/aether/three_d/aether_animated_3d.gd", "Node3D"],
	"Coche3D": ["res://addons/aether/three_d/aether_car_3d.gd", "VehicleBody3D"],
	"JuegoDisparos": ["res://addons/aether/genres/aether_shooter.gd", "Node2D"],
	"JuegoPuzle": ["res://addons/aether/genres/aether_match3.gd", "Node2D"],
	"JuegoDefensaTorres": ["res://addons/aether/genres/aether_tower_defense.gd", "Node2D"],
	"JuegoCarreras": ["res://addons/aether/genres/aether_racer.gd", "Node2D"],
	"JuegoLucha": ["res://addons/aether/genres/aether_fighter.gd", "Node2D"],
	"JuegoCartas": ["res://addons/aether/genres/aether_cards.gd", "Node2D"],
}
const TEMPLATES := ["plataformas", "arena_jefe", "corredor", "aventura_3d", "titulo", "disparos", "puzle", "defensa_torres", "carreras", "carreras_3d", "lucha", "cartas", "rpg", "terror"]

var plugin: EditorPlugin
var key_edit: LineEdit
var model_pick: OptionButton
var prompt: TextEdit
var send_btn: Button
var apply_btn: Button
var out: RichTextLabel
var http: HTTPRequest
var pending_files := {}
var pending_actions: Array = []
var history: Array = []

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var info := Label.new()
	info.text = "Opcional. Conecta con Claude usando tu clave de Anthropic: verá tu escena y podrá crear y cambiar cosas por ti. Sin clave, el motor funciona igual."
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(info)
	key_edit = LineEdit.new()
	key_edit.placeholder_text = "Clave de API (sk-ant-…)"
	key_edit.secret = true
	var es := EditorInterface.get_editor_settings()
	if es.has_setting("aether/claude_api_key"):
		key_edit.text = es.get_setting("aether/claude_api_key")
	key_edit.text_changed.connect(func(t): EditorInterface.get_editor_settings().set_setting("aether/claude_api_key", t))
	add_child(key_edit)
	model_pick = OptionButton.new()
	for m in MODELS:
		model_pick.add_item(m)
	add_child(model_pick)
	prompt = TextEdit.new()
	prompt.placeholder_text = "Ej.: «Pon 5 monedas y una meta al final», «Haz que el jugador salte más», «Crea un jefe que lance fuego»"
	prompt.custom_minimum_size.y = 90
	prompt.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	add_child(prompt)
	var row := HBoxContainer.new()
	send_btn = Button.new()
	send_btn.text = "Enviar"
	send_btn.custom_minimum_size.y = 40
	send_btn.pressed.connect(_send)
	row.add_child(send_btn)
	apply_btn = Button.new()
	apply_btn.text = "Aplicar"
	apply_btn.custom_minimum_size.y = 40
	apply_btn.disabled = true
	apply_btn.pressed.connect(_apply)
	row.add_child(apply_btn)
	var clear := Button.new()
	clear.text = "Nueva charla"
	clear.pressed.connect(func():
		history.clear()
		out.text = "")
	row.add_child(clear)
	add_child(row)
	out = RichTextLabel.new()
	out.bbcode_enabled = true
	out.size_flags_vertical = Control.SIZE_EXPAND_FILL
	out.custom_minimum_size.y = 180
	out.selection_enabled = true
	add_child(out)
	http = HTTPRequest.new()
	http.timeout = 240
	http.request_completed.connect(_on_done)
	add_child(http)

# ---------------- lo que Claude sabe del motor ----------------
func _system() -> String:
	var trig := ", ".join(PackedStringArray(AetherLogicSchema.TRIGGERS.keys()))
	var cond := ", ".join(PackedStringArray(AetherLogicSchema.CONDITIONS.keys()))
	var acts := ", ".join(PackedStringArray(AetherLogicSchema.ACTIONS.keys()))
	var params := ""
	for k in AetherLogicSchema.ACTIONS:
		params += "%s(%s) " % [k, ",".join(PackedStringArray(AetherLogicSchema.ACTIONS[k].params.map(func(p): return p[0])))]
	return """Eres el asistente integrado en Aether Engine (motor de Aether Code sobre Godot 4.7, GDScript, juegos para Android).
Hablas en español, breve y claro, a alguien que puede estar aprendiendo. Explica en 1-3 frases qué vas a hacer.
Puedes MANEJAR EL EDITOR escribiendo un bloque así (JSON válido):
```aether
{"acciones": [ ... ]}
```
Acciones:
- {"tipo":"crear","pieza":"<pieza>","nombre":"Rana","padre":".","pos":[x,y] o [x,y,z],"props":{...}}
  Piezas: %s
- {"tipo":"ajustar","nodo":"<ruta desde la raíz, ej. Jugador>","props":{"move_speed":700}}
- {"tipo":"borrar","nodo":"<ruta>"}
- {"tipo":"evento","nodo":"<ruta de una Logica o Zona>","cuando":"<id>","cuando_params":{},"si":[{"tipo":"<id>","params":{}}],"hacer":[{"tipo":"<id>","params":{}}],"una_vez":false}
  CUANDO: %s · SI: %s · HACER: %s
  Parámetros de HACER: %s
- {"tipo":"plantilla","nombre":"<%s>"}  (crea una escena nueva desde plantilla y la abre)
- {"tipo":"abrir","ruta":"res://..."} · {"tipo":"guardar"} · {"tipo":"jugar"}
Valores: Vector2 como [x,y], Vector3 como [x,y,z], colores como "#rrggbb", texturas como ruta "res://...".
En 2D el suelo suele estar en y=600 y la x crece hacia la derecha. Pon los objetos sobre el suelo (y≈560-600).
Para scripts nuevos usa bloques ```archivo res://ruta.gd``` con el archivo completo. En GDScript no uses ':=' con max/min/lerp/clamp.
Te paso la escena abierta en cada mensaje.""" % [", ".join(PackedStringArray(PIECES.keys())), trig, cond, acts, params, "|".join(PackedStringArray(TEMPLATES))]

func _scene_summary() -> String:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		return "(No hay ninguna escena abierta.)"
	var lines := ["Escena abierta: %s" % root.scene_file_path]
	var stack: Array = [[root, 0]]
	var n := 0
	while stack.size() > 0 and n < 160:
		var it: Array = stack.pop_front()
		var node: Node = it[0]
		n += 1
		var cls := node.get_class()
		var sc: Script = node.get_script()
		if sc and sc.get_global_name() != "":
			cls = sc.get_global_name()
		var line := "%s%s (%s)" % ["  ".repeat(it[1]), root.get_path_to(node), cls]
		if node is Node2D or node is Node3D:
			line += " pos=%s" % str(node.position)
		var props := []
		if sc:
			for p in node.get_property_list():
				if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and p.usage & PROPERTY_USAGE_STORAGE and props.size() < 8:
					var val = node.get(p.name)
					if val is float or val is int or val is bool or val is String or val is Vector2:
						props.append("%s=%s" % [p.name, str(val).left(40)])
		if props.size() > 0:
			line += " {" + ", ".join(PackedStringArray(props)) + "}"
		lines.append(line)
		for c in node.get_children():
			if c.owner == root or c.owner == null and node == root:
				stack.append([c, it[1] + 1])
	return "\n".join(PackedStringArray(lines))

# ---------------- conversación ----------------
func _send() -> void:
	var key := key_edit.text.strip_edges()
	if key == "":
		out.text = "Sin clave no se usa Claude. Puedes seguir creando a mano con las piezas de Aether."
		return
	var q := prompt.text.strip_edges()
	if q == "":
		return
	history.append({"role": "user", "content": q + "\n\n[ESCENA]\n" + _scene_summary()})
	while history.size() > 16:
		history.pop_front()
	var body := {"model": MODELS[model_pick.selected], "max_tokens": 8000, "system": _system(), "messages": history}
	var headers := ["content-type: application/json", "x-api-key: " + key, "anthropic-version: 2023-06-01"]
	send_btn.disabled = true
	out.text = "Pensando…"
	prompt.text = ""
	http.request(API, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func _on_done(result: int, code: int, _h: PackedStringArray, data: PackedByteArray) -> void:
	send_btn.disabled = false
	var txt := data.get_string_from_utf8()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		out.text = "No se pudo conectar (%d / %d). Revisa la clave y la conexión.\n%s" % [result, code, txt.left(400)]
		history.pop_back()
		return
	var d = JSON.parse_string(txt)
	var answer := ""
	if d is Dictionary and d.has("content"):
		for c in d["content"]:
			if c.get("type", "") == "text":
				answer += c["text"]
	history.append({"role": "assistant", "content": answer})
	pending_files.clear()
	pending_actions.clear()
	var re := RegEx.new()
	re.compile("```archivo\\s+(res://\\S+)\\n([\\s\\S]*?)```")
	for m in re.search_all(answer):
		pending_files[m.get_string(1)] = m.get_string(2)
	var ra := RegEx.new()
	ra.compile("```aether\\s*\\n([\\s\\S]*?)```")
	for m in ra.search_all(answer):
		var j = JSON.parse_string(m.get_string(1))
		if j is Dictionary and j.has("acciones"):
			pending_actions.append_array(j["acciones"])
	var shown := ra.sub(re.sub(answer, "[archivo propuesto]", true), "", true).strip_edges()
	var note := ""
	if not pending_files.is_empty():
		note += "\n\n[b]Archivos:[/b] " + ", ".join(PackedStringArray(pending_files.keys()))
	if not pending_actions.is_empty():
		note += "\n[b]Cambios en el editor:[/b]"
		for a in pending_actions:
			note += "\n • " + _describe(a)
	if note != "":
		note += "\n\nPulsa [b]Aplicar[/b] para hacerlo (se puede deshacer)."
	apply_btn.disabled = pending_files.is_empty() and pending_actions.is_empty()
	out.text = shown + note

func _describe(a: Dictionary) -> String:
	match String(a.get("tipo", "")):
		"crear": return "Crear %s «%s»" % [a.get("pieza", "?"), a.get("nombre", a.get("pieza", ""))]
		"ajustar": return "Ajustar %s: %s" % [a.get("nodo", "?"), str(a.get("props", {})).left(80)]
		"borrar": return "Borrar %s" % a.get("nodo", "?")
		"evento": return "Evento en %s: CUANDO %s" % [a.get("nodo", "?"), AetherLogicSchema.describe("trigger", String(a.get("cuando", "")), a.get("cuando_params", {}))]
		"plantilla": return "Nueva escena desde la plantilla %s" % a.get("nombre", "?")
		"abrir": return "Abrir %s" % a.get("ruta", "?")
		"guardar": return "Guardar la escena"
		"jugar": return "Probar el juego"
	return str(a).left(80)

# ---------------- aplicar ----------------
func _apply() -> void:
	apply_btn.disabled = true
	for path in pending_files:
		DirAccess.make_dir_recursive_absolute(String(path).get_base_dir())
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f:
			f.store_string(pending_files[path])
			f.close()
	if not pending_files.is_empty():
		EditorInterface.get_resource_filesystem().scan()
		await get_tree().create_timer(0.6).timeout
	var report := []
	for a in pending_actions:
		var r = await _run(a)
		report.append(("✔ " if r == "" else "✖ ") + _describe(a) + ("" if r == "" else " — " + str(r)))
	out.text += "\n\n" + "\n".join(PackedStringArray(report))
	pending_files.clear()
	pending_actions.clear()

func _ur() -> EditorUndoRedoManager:
	return plugin.get_undo_redo() if plugin else null

func _run(a: Dictionary) -> String:
	var root := EditorInterface.get_edited_scene_root()
	var t := String(a.get("tipo", ""))
	if t == "plantilla":
		var nm := String(a.get("nombre", "plataformas"))
		if not nm in TEMPLATES:
			return "plantilla desconocida"
		DirAccess.make_dir_recursive_absolute("res://mis_juegos")
		var i := 1
		while FileAccess.file_exists("res://mis_juegos/%s_%d.tscn" % [nm, i]):
			i += 1
		var dest := "res://mis_juegos/%s_%d.tscn" % [nm, i]
		DirAccess.copy_absolute(ProjectSettings.globalize_path("res://plantillas/%s.tscn" % nm), ProjectSettings.globalize_path(dest))
		EditorInterface.get_resource_filesystem().scan()
		await get_tree().create_timer(0.6).timeout
		EditorInterface.open_scene_from_path(dest)
		await get_tree().create_timer(0.4).timeout
		return ""
	if t == "abrir":
		EditorInterface.open_scene_from_path(String(a.get("ruta", "")))
		await get_tree().create_timer(0.4).timeout
		return ""
	if root == null:
		return "no hay escena abierta"
	match t:
		"guardar":
			EditorInterface.save_scene()
			return ""
		"jugar":
			EditorInterface.play_current_scene()
			return ""
		"crear":
			var piece := String(a.get("pieza", ""))
			if not PIECES.has(piece):
				return "pieza desconocida"
			var parent: Node = root.get_node_or_null(NodePath(String(a.get("padre", ".")))) if String(a.get("padre", ".")) != "." else root
			if parent == null:
				parent = root
			var n: Node = ClassDB.instantiate(PIECES[piece][1])
			n.set_script(load(PIECES[piece][0]))
			n.name = String(a.get("nombre", piece))
			var pos = a.get("pos", null)
			if pos is Array:
				if n is Node2D and pos.size() >= 2:
					n.position = Vector2(pos[0], pos[1])
				elif n is Node3D and pos.size() >= 3:
					n.position = Vector3(pos[0], pos[1], pos[2])
			for k in a.get("props", {}):
				_set_prop(n, k, a["props"][k])
			var ur := _ur()
			ur.create_action("Claude: crear " + n.name)
			ur.add_do_method(parent, "add_child", n, true)
			ur.add_do_method(n, "set_owner", root)
			ur.add_do_reference(n)
			ur.add_undo_method(parent, "remove_child", n)
			ur.commit_action()
			return ""
		"ajustar":
			var node := root.get_node_or_null(NodePath(String(a.get("nodo", ""))))
			if node == null:
				return "no encuentro el nodo"
			var ur2 := _ur()
			ur2.create_action("Claude: ajustar " + node.name)
			for k in a.get("props", {}):
				var nv = _conv(node, k, a["props"][k])
				ur2.add_do_property(node, k, nv)
				ur2.add_undo_property(node, k, node.get(k))
			ur2.commit_action()
			return ""
		"borrar":
			var node2 := root.get_node_or_null(NodePath(String(a.get("nodo", ""))))
			if node2 == null or node2 == root:
				return "no encuentro el nodo"
			var par := node2.get_parent()
			var ur3 := _ur()
			ur3.create_action("Claude: borrar " + node2.name)
			ur3.add_do_method(par, "remove_child", node2)
			ur3.add_undo_method(par, "add_child", node2, true)
			ur3.add_undo_method(node2, "set_owner", root)
			ur3.add_undo_reference(node2)
			ur3.commit_action()
			return ""
		"evento":
			var host := root.get_node_or_null(NodePath(String(a.get("nodo", ""))))
			if host == null or not ("events" in host):
				return "no hay una Lógica o Zona con ese nombre"
			var ev := AetherEvent.new()
			ev.trigger = String(a.get("cuando", "inicio"))
			ev.trigger_params = AetherLogicSchema.defaults("trigger", ev.trigger)
			ev.trigger_params.merge(a.get("cuando_params", {}), true)
			for c in a.get("si", []):
				var st := AetherStep.make(String(c.get("tipo", "")), AetherLogicSchema.defaults("condition", String(c.get("tipo", ""))))
				st.params.merge(c.get("params", {}), true)
				ev.conditions.append(st)
			for h in a.get("hacer", []):
				var st2 := AetherStep.make(String(h.get("tipo", "")), AetherLogicSchema.defaults("action", String(h.get("tipo", ""))))
				st2.params.merge(h.get("params", {}), true)
				ev.actions.append(st2)
			ev.once = bool(a.get("una_vez", false))
			var old: Array[AetherEvent] = host.events.duplicate()
			var nu: Array[AetherEvent] = host.events.duplicate()
			nu.append(ev)
			var ur4 := _ur()
			ur4.create_action("Claude: evento en " + host.name)
			ur4.add_do_property(host, "events", nu)
			ur4.add_undo_property(host, "events", old)
			ur4.commit_action()
			return ""
	return "acción desconocida"

func _set_prop(n: Node, k: String, v) -> void:
	n.set(k, _conv(n, k, v))

## Convierte el valor JSON al tipo de la propiedad (Vector2, Color, textura…).
func _conv(n: Object, k: String, v):
	for p in n.get_property_list():
		if p.name != k:
			continue
		match int(p.type):
			TYPE_VECTOR2:
				if v is Array and v.size() >= 2: return Vector2(v[0], v[1])
			TYPE_VECTOR3:
				if v is Array and v.size() >= 3: return Vector3(v[0], v[1], v[2])
			TYPE_COLOR:
				if v is String: return Color.from_string(v, Color.WHITE)
				if v is Array and v.size() >= 3: return Color(v[0], v[1], v[2], v[3] if v.size() > 3 else 1.0)
			TYPE_INT:
				return int(v)
			TYPE_FLOAT:
				return float(v)
			TYPE_NODE_PATH:
				return NodePath(str(v))
			TYPE_OBJECT:
				if v is String and ResourceLoader.exists(v): return load(v)
		break
	return v
