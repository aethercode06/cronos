@tool
extends VBoxContainer
## Asistente OPCIONAL: conecta el editor con Claude usando tu propia clave.
## Si no pones clave, este panel no hace nada: el motor funciona igual sin IA.
## Claude puede proponer archivos; nada se escribe hasta que pulsas «Aplicar».

const API := "https://api.anthropic.com/v1/messages"
const MODELS := ["claude-sonnet-5-5", "claude-opus-5-5", "claude-haiku-5-5"]
const SYSTEM := """Eres el asistente de Aether Engine (Godot 4.7, GDScript, juegos para Android).
Piezas disponibles: PlatformerPlayer, AetherEnemy, AetherBoss (heredar y escribir _boss_tick), AetherCamera, AetherGround,
AetherRig (personajes por piezas), AetherAnimSet/AetherAnim, FX (efectos), autoload Aether (hitstop, slowmo, shake, flash, sfx, music).
Responde en español, breve y claro, para alguien que está aprendiendo.
Cuando tengas que crear o cambiar archivos, escribe cada uno así, completo:
```archivo res://ruta/del/archivo.gd
(contenido completo)
```
No uses ':=' con max/min/lerp/clamp (pon el tipo a mano)."""

var key_edit: LineEdit
var model_pick: OptionButton
var prompt: TextEdit
var send_btn: Button
var apply_btn: Button
var out: RichTextLabel
var http: HTTPRequest
var pending_files := {}
var history: Array = []

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var info := Label.new()
	info.text = "Opcional. Pon tu clave de Anthropic para pedirle cosas a Claude. Sin clave, el motor funciona igual."
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
	prompt.placeholder_text = "Ej.: «Crea un enemigo que lance fuego» o «Haz el jugador más rápido»"
	prompt.custom_minimum_size.y = 90
	prompt.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	add_child(prompt)
	var row := HBoxContainer.new()
	send_btn = Button.new()
	send_btn.text = "Enviar"
	send_btn.pressed.connect(_send)
	row.add_child(send_btn)
	apply_btn = Button.new()
	apply_btn.text = "Aplicar archivos"
	apply_btn.disabled = true
	apply_btn.pressed.connect(_apply)
	row.add_child(apply_btn)
	add_child(row)
	out = RichTextLabel.new()
	out.size_flags_vertical = Control.SIZE_EXPAND_FILL
	out.custom_minimum_size.y = 160
	out.selection_enabled = true
	add_child(out)
	http = HTTPRequest.new()
	http.timeout = 180
	http.request_completed.connect(_on_done)
	add_child(http)

func _send() -> void:
	var key := key_edit.text.strip_edges()
	if key == "":
		out.text = "Sin clave no se usa Claude. Puedes seguir creando a mano con las piezas de Aether."
		return
	var q := prompt.text.strip_edges()
	if q == "":
		return
	var scene := EditorInterface.get_edited_scene_root()
	var ctx := ""
	if scene and scene.scene_file_path != "":
		ctx = "\n\n(Escena abierta: %s)" % scene.scene_file_path
	history.append({"role": "user", "content": q + ctx})
	var body := {"model": MODELS[model_pick.selected], "max_tokens": 8000, "system": SYSTEM, "messages": history}
	var headers := ["content-type: application/json", "x-api-key: " + key, "anthropic-version: 2023-06-01"]
	send_btn.disabled = true
	out.text = "Pensando…"
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
	var re := RegEx.new()
	re.compile("```archivo\\s+(res://\\S+)\\n([\\s\\S]*?)```")
	for m in re.search_all(answer):
		pending_files[m.get_string(1)] = m.get_string(2)
	apply_btn.disabled = pending_files.is_empty()
	var note := ""
	if not pending_files.is_empty():
		note = "\n\n[b]Archivos propuestos:[/b] " + ", ".join(PackedStringArray(pending_files.keys())) + "\nPulsa «Aplicar archivos» para guardarlos."
	out.text = answer + note

func _apply() -> void:
	for path in pending_files:
		DirAccess.make_dir_recursive_absolute(String(path).get_base_dir())
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f:
			f.store_string(pending_files[path])
			f.close()
	out.text += "\n\n✔ Guardados: " + ", ".join(PackedStringArray(pending_files.keys()))
	pending_files.clear()
	apply_btn.disabled = true
	EditorInterface.get_resource_filesystem().scan()
