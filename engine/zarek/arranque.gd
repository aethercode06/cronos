extends Control
## Arranque de La Sombra de Zarek: antes de cargar el juego mira si hay una actualización (un «parche» de pocos MB
## con el código y los archivos que han cambiado desde que se hizo el APK) y la aplica. Así no hace falta instalar
## un APK nuevo para cada cambio: basta con cerrar y volver a abrir el juego.
## - parche.json (release «zarek-parche»): {"base": n.º del APK para el que vale, "version": n.º del parche, "url"}
## - El parche se guarda en user:// y se vuelve a cargar en cada arranque, también sin internet.
## - Si el APK es otro (base distinta), el parche viejo se borra.
## Este script no puede usar nada del juego (se carga antes que el parche).

const URL_INFO := "https://github.com/aethercode06/cronos/releases/download/zarek-parche/parche.json"
const PARCHE := "user://parche.pck"
const INFO := "user://parche_info.json"
const JUEGO := "res://zarek/zarek.tscn"

var _txt: Label
var _barra: ProgressBar
var _http: HTTPRequest
var _bajando := false

func _process(_d: float) -> void:
	if _bajando and _http.get_body_size() > 0:
		_barra.value = 100.0 * _http.get_downloaded_bytes() / _http.get_body_size()

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_txt = Label.new()
	_txt.set_anchors_preset(Control.PRESET_CENTER)
	_txt.position = Vector2(-400, -30)
	_txt.size = Vector2(800, 40)
	_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_txt.add_theme_font_size_override("font_size", 24)
	_txt.add_theme_color_override("font_color", Color(0.75, 0.7, 0.62))
	add_child(_txt)
	_barra = ProgressBar.new()
	_barra.set_anchors_preset(Control.PRESET_CENTER)
	_barra.position = Vector2(-220, 24)
	_barra.size = Vector2(440, 14)
	_barra.show_percentage = false
	_barra.visible = false
	add_child(_barra)
	_http = HTTPRequest.new()
	_http.timeout = 8.0
	_http.max_redirects = 10
	add_child(_http)
	_comprobar.call_deferred()

func _base() -> String:
	return str(ProjectSettings.get_setting("application/config/version", ""))

func _leer_info() -> Dictionary:
	if not FileAccess.file_exists(INFO):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(INFO))
	return d if d is Dictionary else {}

func _comprobar() -> void:
	var base := _base()
	var info := _leer_info()
	# APK distinto al del parche guardado: el parche viejo ya no vale
	if info.get("base", "") != base and FileAccess.file_exists(PARCHE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PARCHE))
		info = {}
	if base != "" and OS.get_name() == "Android":
		_txt.text = "Buscando actualizaciones…"
		_http.request(URL_INFO + "?t=%d" % Time.get_unix_time_from_system())
		var r: Array = await _http.request_completed
		if int(r[0]) == HTTPRequest.RESULT_SUCCESS and int(r[1]) == 200:
			var j = JSON.parse_string((r[3] as PackedByteArray).get_string_from_utf8())
			if j is Dictionary and str(j.get("base", "")) == base and int(j.get("version", 0)) > int(info.get("version", 0)):
				await _bajar(j)
				info = _leer_info()
	if FileAccess.file_exists(PARCHE) and info.get("base", "") == base:
		if ProjectSettings.load_resource_pack(PARCHE, true):
			print("ZAREK parche ", info.get("version", 0), " aplicado")
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PARCHE))
	get_tree().change_scene_to_file(JUEGO)

func _bajar(j: Dictionary) -> void:
	_txt.text = "Descargando actualización %d…" % int(j.version)
	_barra.visible = true
	var tmp := "user://parche_nuevo.pck"
	_http.download_file = tmp
	_http.timeout = 120.0
	_bajando = true
	_http.request(str(j.url))
	await _http.request_completed
	_bajando = false
	_http.download_file = ""
	var tam := 0
	if FileAccess.file_exists(tmp):
		var fa := FileAccess.open(tmp, FileAccess.READ)
		tam = fa.get_length()
		fa.close()
	var ok: bool = tam > 1000 and (int(j.get("tam", 0)) <= 0 or tam == int(j.tam))
	if ok:
		var dir := DirAccess.open("user://")
		if dir.file_exists("parche.pck"):
			dir.remove("parche.pck")
		dir.rename("parche_nuevo.pck", "parche.pck")
		var f := FileAccess.open(INFO, FileAccess.WRITE)
		f.store_string(JSON.stringify({"base": str(j.base), "version": int(j.version)}))
		f.close()
		_txt.text = "Actualización %d instalada." % int(j.version)
	else:
		_txt.text = "No se pudo descargar la actualización. Se intentará la próxima vez."
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
	await get_tree().create_timer(0.6).timeout
