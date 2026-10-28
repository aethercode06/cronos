@tool
extends ScrollContainer
## Panel «GitHub»: sincroniza el proyecto con un repositorio de GitHub.
## Así puedes trabajar con Claude (Claude Code o la app) sobre el mismo proyecto
## sin pagar API: «Subir» manda tus cambios, «Recibir» trae los que hizo Claude.

const STATE := "user://aether_github.json"
const SKIP := [".godot/", ".import/", "publicar/build", ".git/"]

var _repo: LineEdit
var _branch: LineEdit
var _folder: LineEdit
var _token: LineEdit
var _out: Label
var _http: HTTPRequest
var _busy := false
var _auto: CheckBox
var _last_sha := ""
var _poll := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(240, 300)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(v)
	_label(v, "GITHUB · trabajar con Claude gratis", 15, Color(0.4, 0.88, 1.0))
	_label(v, "Guarda tu proyecto en GitHub. Claude puede cambiarlo allí (por ejemplo desde Claude Code) y tú recibes los cambios con un toque.", 13, Color(1, 1, 1))
	_repo = _field(v, "Repositorio (usuario/nombre)", "aethercode06/mi-juego")
	_branch = _field(v, "Rama", "main")
	_folder = _field(v, "Carpeta del proyecto dentro del repositorio (vacío = raíz)", "")
	_token = _field(v, "Token de GitHub (para repositorios privados y para subir)", "ghp_…")
	_token.secret = true
	_button(v, "⬇ Recibir cambios de GitHub", _pull)
	_button(v, "⬆ Subir mis cambios a GitHub", _push)
	_auto = CheckBox.new()
	_auto.text = "Recibir solo los cambios de Claude (en directo)"
	_auto.toggled.connect(func(on: bool) -> void:
		_poll = 0.0
		_out.text = "En directo: los cambios que Claude haga en GitHub aparecerán aquí solos." if on else "")
	v.add_child(_auto)
	_out = Label.new()
	_out.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_out.add_theme_color_override("font_color", Color(0.5, 1, 0.6))
	v.add_child(_out)
	_label(v, "Token: en github.com → Settings → Developer settings → Fine-grained tokens → acceso a tu repositorio con permiso «Contents: Read and write».", 12, Color(0.7, 0.7, 0.8))
	_http = HTTPRequest.new()
	_http.timeout = 120
	_http.max_redirects = 8
	add_child(_http)
	var st := _state()
	_repo.text = st.get("repo", "")
	_branch.text = st.get("branch", "main")
	_folder.text = st.get("folder", "")
	var es := EditorInterface.get_editor_settings()
	if es.has_setting("aether/github_token"):
		_token.text = es.get_setting("aether/github_token")

func _label(v: VBoxContainer, t: String, size: int, col: Color) -> void:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 200
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	v.add_child(l)

func _field(v: VBoxContainer, label: String, placeholder: String) -> LineEdit:
	_label(v, label, 13, Color(1, 1, 1))
	var e := LineEdit.new()
	e.placeholder_text = placeholder
	v.add_child(e)
	return e

func _button(v: VBoxContainer, t: String, f: Callable) -> void:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size.y = 44
	b.pressed.connect(f)
	v.add_child(b)

func _state() -> Dictionary:
	if not FileAccess.file_exists(STATE):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(STATE))
	return d if d is Dictionary else {}

func _save_state(hashes: Dictionary) -> void:
	var st := {"repo": _repo.text.strip_edges(), "branch": _branch.text.strip_edges(), "folder": _folder.text.strip_edges().trim_suffix("/"), "hashes": hashes}
	var f := FileAccess.open(STATE, FileAccess.WRITE)
	f.store_string(JSON.stringify(st))
	EditorInterface.get_editor_settings().set_setting("aether/github_token", _token.text.strip_edges())

func _headers() -> PackedStringArray:
	var h := PackedStringArray(["Accept: application/vnd.github+json", "User-Agent: AetherEngine"])
	if _token.text.strip_edges() != "":
		h.append("Authorization: Bearer " + _token.text.strip_edges())
	return h

func _req(url: String, method := HTTPClient.METHOD_GET, body := "") -> Array:
	var err := _http.request(url, _headers(), method, body)
	if err != OK:
		return [0, PackedByteArray()]
	var r: Array = await _http.request_completed
	return [r[1], r[3]]

func _json(data: PackedByteArray):
	return JSON.parse_string(data.get_string_from_utf8())

# ---------------- archivos del proyecto ----------------
static func project_files(dir := "res://") -> PackedStringArray:
	var out := PackedStringArray()
	var d := DirAccess.open(dir)
	if d == null:
		return out
	d.include_hidden = false
	for f in d.get_files():
		var p := dir.path_join(f)
		if f.ends_with(".import") or f.ends_with(".uid") and false:
			pass
		out.append(p)
	for sub in d.get_directories():
		var p := dir.path_join(sub)
		var rel := p.trim_prefix("res://") + "/"
		var skip := false
		for s in SKIP:
			if rel.begins_with(s):
				skip = true
		if not skip:
			out.append_array(project_files(p))
	return out

func _rel(p: String) -> String:
	return p.trim_prefix("res://")

# ---------------- recibir ----------------
func _pull() -> void:
	if _busy:
		return
	var repo := _repo.text.strip_edges()
	if repo.count("/") != 1:
		_out.text = "Escribe el repositorio como usuario/nombre."
		return
	_busy = true
	_out.text = "Descargando…"
	var r := await _req("https://api.github.com/repos/%s/zipball/%s" % [repo, _branch.text.strip_edges()])
	if int(r[0]) != 200:
		_out.text = "No se pudo descargar (código %d). ¿Repositorio privado sin token?" % int(r[0])
		_busy = false
		return
	var tmp := "user://aether_sync.zip"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	f.store_buffer(r[1])
	f.close()
	var zr := ZIPReader.new()
	if zr.open(tmp) != OK:
		_out.text = "El archivo descargado no es válido."
		_busy = false
		return
	var folder := _folder.text.strip_edges().trim_suffix("/")
	var n := 0
	var hashes := {}
	for path in zr.get_files():
		if path.ends_with("/"):
			continue
		var inner := path.substr(path.find("/") + 1)   # quita «usuario-repo-sha/»
		if folder != "":
			if not inner.begins_with(folder + "/"):
				continue
			inner = inner.substr(folder.length() + 1)
		var skip := false
		for s in SKIP:
			if inner.begins_with(s):
				skip = true
		if skip or inner == "":
			continue
		var data := zr.read_file(path)
		var dest := "res://" + inner
		DirAccess.make_dir_recursive_absolute(dest.get_base_dir())
		var old := FileAccess.get_file_as_bytes(dest) if FileAccess.file_exists(dest) else PackedByteArray()
		if old != data:
			var w := FileAccess.open(dest, FileAccess.WRITE)
			if w:
				w.store_buffer(data)
				w.close()
				n += 1
		hashes[inner] = _md5(data)
	zr.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
	_save_state(hashes)
	EditorInterface.get_resource_filesystem().scan()
	_out.text = "Recibidos %d archivos cambiados. Si cambió un script abierto, vuelve a abrirlo." % n
	_busy = false

static func _md5(data: PackedByteArray) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	ctx.update(data)
	return ctx.finish().hex_encode()

# ---------------- subir ----------------
func _push() -> void:
	if _busy:
		return
	var repo := _repo.text.strip_edges()
	if repo.count("/") != 1 or _token.text.strip_edges() == "":
		_out.text = "Para subir hacen falta el repositorio y un token con permiso de escritura."
		return
	_busy = true
	EditorInterface.save_all_scenes()
	var api := "https://api.github.com/repos/" + repo
	var branch := _branch.text.strip_edges()
	var folder := _folder.text.strip_edges().trim_suffix("/")
	var old: Dictionary = _state().get("hashes", {})
	var changed: Array = []
	var hashes := {}
	for p in project_files():
		var rel := _rel(p)
		var data := FileAccess.get_file_as_bytes(p)
		var h := _md5(data)
		hashes[rel] = h
		if old.get(rel, "") != h:
			changed.append([rel, data])
	if changed.is_empty():
		_out.text = "No hay cambios que subir."
		_busy = false
		return
	_out.text = "Subiendo %d archivos…" % changed.size()
	var r := await _req(api + "/git/ref/heads/" + branch)
	var base_sha := ""
	var base_tree := ""
	if int(r[0]) == 200:
		base_sha = _json(r[1])["object"]["sha"]
		r = await _req(api + "/git/commits/" + base_sha)
		base_tree = _json(r[1])["tree"]["sha"]
	var tree: Array = []
	var i := 0
	for c in changed:
		i += 1
		_out.text = "Subiendo %d / %d: %s" % [i, changed.size(), c[0]]
		r = await _req(api + "/git/blobs", HTTPClient.METHOD_POST, JSON.stringify({"content": Marshalls.raw_to_base64(c[1]), "encoding": "base64"}))
		if int(r[0]) != 201:
			_out.text = "Error al subir %s (código %d). Revisa el token." % [c[0], int(r[0])]
			_busy = false
			return
		var path: String = c[0] if folder == "" else folder + "/" + c[0]
		tree.append({"path": path, "mode": "100644", "type": "blob", "sha": _json(r[1])["sha"]})
	var tb := {"tree": tree}
	if base_tree != "":
		tb["base_tree"] = base_tree
	r = await _req(api + "/git/trees", HTTPClient.METHOD_POST, JSON.stringify(tb))
	var tree_sha: String = _json(r[1])["sha"]
	var cb := {"message": "Aether Engine: cambios desde el editor", "tree": tree_sha, "parents": [base_sha] if base_sha != "" else []}
	r = await _req(api + "/git/commits", HTTPClient.METHOD_POST, JSON.stringify(cb))
	var commit_sha: String = _json(r[1])["sha"]
	if base_sha != "":
		r = await _req(api + "/git/refs/heads/" + branch, HTTPClient.METHOD_PATCH, JSON.stringify({"sha": commit_sha}))
	else:
		r = await _req(api + "/git/refs", HTTPClient.METHOD_POST, JSON.stringify({"ref": "refs/heads/" + branch, "sha": commit_sha}))
	if int(r[0]) in [200, 201]:
		_save_state(hashes)
		_out.text = "Subidos %d archivos a %s. Ya puedes decirle a Claude que trabaje en el proyecto." % [changed.size(), repo]
	else:
		_out.text = "No se pudo actualizar la rama (código %d)." % int(r[0])
	_busy = false

# ---------------- en directo ----------------
func _process(delta: float) -> void:
	if _auto == null or not _auto.button_pressed or _busy:
		return
	_poll -= delta
	if _poll > 0.0:
		return
	_poll = 15.0 if _token.text.strip_edges() != "" else 60.0
	_check_new()

func _check_new() -> void:
	var repo := _repo.text.strip_edges()
	if repo.count("/") != 1:
		return
	_busy = true
	var r := await _req("https://api.github.com/repos/%s/commits/%s" % [repo, _branch.text.strip_edges()])
	_busy = false
	if int(r[0]) != 200:
		return
	var d = _json(r[1])
	if not d is Dictionary:
		return
	var sha: String = d.get("sha", "")
	if _last_sha == "":
		_last_sha = sha
		return
	if sha != _last_sha:
		_last_sha = sha
		var msg: String = d.get("commit", {}).get("message", "")
		await _pull()
		_out.text = "Nuevo cambio de Claude recibido: " + msg.get_slice("\n", 0)
