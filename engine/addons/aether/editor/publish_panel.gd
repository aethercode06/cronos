@tool
extends ScrollContainer
## Panel «Publicar»: deja el juego listo para Google Play sin tocar menús
## complicados: nombre, paquete, versión, icono, orientación, comprobaciones,
## ficha de la tienda, política de privacidad, tráiler y archivo de GitHub
## para crear el AAB firmado (Google Play pide AAB).

const PRESETS := "res://export_presets.cfg"

var _name: LineEdit
var _pkg: LineEdit
var _ver: LineEdit
var _code: SpinBox
var _orient: OptionButton
var _icon_path := ""
var _icon_lbl: Label
var _checks: VBoxContainer
var _short: LineEdit
var _long: TextEdit
var _mail: LineEdit
var _ads: CheckBox
var _iap: CheckBox
var _out: Label

func _ready() -> void:
	custom_minimum_size = Vector2(240, 300)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(v)
	_title(v, "1 · Datos del juego")
	_name = _field(v, "Nombre del juego", "Mi juego")
	_pkg = _field(v, "Paquete (único en Google Play)", "com.miempresa.mijuego")
	_ver = _field(v, "Versión que ve la gente", "1.0")
	var h := HBoxContainer.new()
	var l := Label.new()
	l.text = "Número de versión"
	h.add_child(l)
	_code = SpinBox.new()
	_code.min_value = 1
	_code.max_value = 2100000000
	h.add_child(_code)
	var plus := Button.new()
	plus.text = "+1"
	plus.pressed.connect(func() -> void: _code.value += 1)
	h.add_child(plus)
	v.add_child(h)
	_orient = OptionButton.new()
	for o in ["Horizontal", "Vertical", "Automática (gira)"]:
		_orient.add_item(o)
	v.add_child(_orient)
	_icon_lbl = Label.new()
	_icon_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_icon_lbl)
	_btn(v, "Elegir icono (PNG cuadrado, 512×512)", _pick_icon)
	_btn(v, "Usar la escena abierta como inicio del juego", _set_main)
	_btn(v, "GUARDAR DATOS", _save)
	_title(v, "2 · Comprobar")
	_checks = VBoxContainer.new()
	v.add_child(_checks)
	_btn(v, "Comprobar otra vez", _run_checks)
	_title(v, "3 · Ficha de Google Play")
	_short = _field(v, "Descripción corta (máx. 80 letras)", "Un juego de acción épico.")
	var ll := Label.new()
	ll.text = "Descripción completa"
	v.add_child(ll)
	_long = TextEdit.new()
	_long.custom_minimum_size = Vector2(200, 140)
	_long.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_long.text = "Describe tu juego: qué hace el jugador, qué lo hace especial y qué encontrará (niveles, jefes, modos…)."
	v.add_child(_long)
	_mail = _field(v, "Correo de contacto", "")
	_ads = CheckBox.new()
	_ads.text = "Mi juego muestra anuncios"
	v.add_child(_ads)
	_iap = CheckBox.new()
	_iap.text = "Mi juego tiene compras"
	v.add_child(_iap)
	_btn(v, "Crear ficha y política de privacidad", _make_listing)
	_title(v, "4 · Capturas y tráiler")
	_text(v, "Capturas: mientras pruebas el juego, toca la pantalla con 3 dedos (o pulsa F12). Se guardan en Imágenes/Aether.")
	_btn(v, "Grabar tráiler (vídeo) al jugar", _record_trailer)
	_title(v, "5 · Subir a Google Play")
	_text(v, "• Para probar: Proyecto → Exportar → Android → Exportar proyecto (APK).\n• Google Play pide un AAB firmado con TU clave de subida. El teléfono no puede crear AAB, pero GitHub sí, gratis: pulsa el botón y sigue los pasos del archivo que se crea.")
	_btn(v, "Crear archivo de GitHub para Google Play", _make_github)
	_out = Label.new()
	_out.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_out.add_theme_color_override("font_color", Color(0.5, 1, 0.6))
	v.add_child(_out)
	_load()
	_run_checks()

func _title(v: VBoxContainer, t: String) -> void:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(0.4, 0.88, 1.0))
	v.add_child(l)

func _text(v: VBoxContainer, t: String) -> void:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 200
	v.add_child(l)

func _field(v: VBoxContainer, label: String, placeholder: String) -> LineEdit:
	var l := Label.new()
	l.text = label
	v.add_child(l)
	var e := LineEdit.new()
	e.placeholder_text = placeholder
	v.add_child(e)
	return e

func _btn(v: VBoxContainer, t: String, f: Callable) -> void:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size.y = 40
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.pressed.connect(f)
	v.add_child(b)

# ---------------- datos ----------------
func _cfg() -> ConfigFile:
	var c := ConfigFile.new()
	c.load(PRESETS)
	return c

static func _android_sections(c: ConfigFile) -> PackedStringArray:
	var out := PackedStringArray()
	for s in c.get_sections():
		if s.begins_with("preset.") and not s.ends_with(".options") and c.get_value(s, "platform", "") == "Android":
			out.append(s)
	return out

func _load() -> void:
	_name.text = str(ProjectSettings.get_setting("application/config/name", ""))
	_icon_path = str(ProjectSettings.get_setting("application/config/icon", ""))
	var c := _cfg()
	var secs := _android_sections(c)
	if secs.size() > 0:
		var o := secs[0] + ".options"
		_pkg.text = str(c.get_value(o, "package/unique_name", ""))
		_ver.text = str(c.get_value(o, "version/name", "1.0"))
		_code.value = int(c.get_value(o, "version/code", 1))
	var ori := int(ProjectSettings.get_setting("display/window/handheld/orientation", 4))
	_orient.select(1 if ori in [1, 3, 5] else (2 if ori == 6 else 0))
	_icon_lbl.text = "Icono: " + (_icon_path if _icon_path != "" else "(ninguno)")

func _pick_icon() -> void:
	var d := EditorFileDialog.new()
	d.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	d.access = EditorFileDialog.ACCESS_RESOURCES
	d.add_filter("*.png, *.webp, *.svg", "Imágenes")
	d.file_selected.connect(func(p: String) -> void:
		_icon_path = p
		_icon_lbl.text = "Icono: " + p
		d.queue_free())
	EditorInterface.get_base_control().add_child(d)
	d.popup_file_dialog()

func _set_main() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if root == null or root.scene_file_path == "":
		_out.text = "Abre y guarda una escena primero."
		return
	ProjectSettings.set_setting("application/run/main_scene", root.scene_file_path)
	ProjectSettings.save()
	_out.text = "Inicio del juego: " + root.scene_file_path
	_run_checks()

static func valid_package(p: String) -> bool:
	var re := RegEx.new()
	re.compile("^[a-z][a-z0-9_]*(\\.[a-z][a-z0-9_]*)+$")
	return re.search(p) != null

func _save() -> void:
	if not valid_package(_pkg.text):
		_out.text = "El paquete debe ser como com.miempresa.mijuego (minúsculas, sin espacios ni tildes)."
		return
	ProjectSettings.set_setting("application/config/name", _name.text)
	if _icon_path != "":
		ProjectSettings.set_setting("application/config/icon", _icon_path)
	ProjectSettings.set_setting("display/window/handheld/orientation", [4, 5, 6][_orient.selected])
	ProjectSettings.save()
	var c := _cfg()
	var secs := _android_sections(c)
	if secs.is_empty():
		_out.text = "No hay ajustes de Android: abre Proyecto → Exportar → Añadir… → Android una vez y vuelve."
		return
	for s in secs:
		var o := s + ".options"
		c.set_value(o, "package/unique_name", _pkg.text)
		c.set_value(o, "package/name", _name.text)
		c.set_value(o, "version/name", _ver.text)
		c.set_value(o, "version/code", int(_code.value))
		if _icon_path != "" and _icon_path.ends_with(".png"):
			c.set_value(o, "launcher_icons/main_192x192", _icon_path)
			c.set_value(o, "launcher_icons/adaptive_foreground_432x432", _icon_path)
	_ensure_aab(c, secs[0])
	c.save(PRESETS)
	_out.text = "Guardado. El editor se reiniciará para aplicar los ajustes de exportación."
	_run_checks()
	await get_tree().create_timer(1.5).timeout
	EditorInterface.restart_editor(true)

## Crea (si falta) el ajuste «Android AAB» que usa GitHub para Google Play.
static func _ensure_aab(c: ConfigFile, base: String) -> void:
	for s in _android_sections(c):
		if c.get_value(s, "name", "") == "Android AAB":
			var o := s + ".options"
			for k in ["package/unique_name", "package/name", "version/name", "version/code", "launcher_icons/main_192x192", "launcher_icons/adaptive_foreground_432x432"]:
				c.set_value(o, k, c.get_value(base + ".options", k, ""))
			return
	var i := 0
	while c.has_section("preset.%d" % i):
		i += 1
	var ns := "preset.%d" % i
	for k in c.get_section_keys(base):
		c.set_value(ns, k, c.get_value(base, k))
	c.set_value(ns, "name", "Android AAB")
	c.set_value(ns, "runnable", false)
	c.set_value(ns, "export_path", "../build/juego.aab")
	for k in c.get_section_keys(base + ".options"):
		c.set_value(ns + ".options", k, c.get_value(base + ".options", k))
	c.set_value(ns + ".options", "gradle_build/use_gradle_build", true)
	c.set_value(ns + ".options", "gradle_build/export_format", 1)
	c.set_value(ns + ".options", "package/signed", true)
	c.set_value(ns + ".options", "architectures/armeabi-v7a", true)
	c.set_value(ns + ".options", "architectures/arm64-v8a", true)

# ---------------- comprobaciones ----------------
## Devuelve [texto, correcto] por cada comprobación.
static func checks() -> Array:
	var out: Array = []
	var nm := str(ProjectSettings.get_setting("application/config/name", ""))
	out.append(["Nombre del juego: " + nm, nm != "" and not nm.begins_with("Aether Engine")])
	var main := str(ProjectSettings.get_setting("application/run/main_scene", ""))
	out.append(["Escena de inicio: " + (main if main != "" else "falta"), main != "" and ResourceLoader.exists(main)])
	var icon := str(ProjectSettings.get_setting("application/config/icon", ""))
	out.append(["Icono propio", icon != "" and icon != "res://icon.svg"])
	var c := ConfigFile.new()
	c.load(PRESETS)
	var pkg := ""
	var has_android := false
	var has_aab := false
	for s in c.get_sections():
		if s.begins_with("preset.") and not s.ends_with(".options") and c.get_value(s, "platform", "") == "Android":
			has_android = true
			pkg = str(c.get_value(s + ".options", "package/unique_name", ""))
			if c.get_value(s, "name", "") == "Android AAB":
				has_aab = true
	out.append(["Ajustes de Android", has_android])
	out.append(["Paquete: " + pkg, valid_package(pkg) and not pkg.begins_with("com.aethercode.aetherengine") and not pkg.begins_with("com.example")])
	out.append(["Ajuste AAB para Google Play", has_aab])
	out.append(["Ficha y privacidad creadas", FileAccess.file_exists("res://publicar/ficha_google_play.txt")])
	out.append(["Archivo de GitHub creado", FileAccess.file_exists("res://publicar/google_play.yml")])
	return out

func _run_checks() -> void:
	for ch in _checks.get_children():
		ch.queue_free()
	var ok := 0
	var all := checks()
	for c in all:
		var l := Label.new()
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.text = ("✔ " if c[1] else "✖ ") + c[0]
		l.add_theme_color_override("font_color", Color(0.5, 1, 0.6) if c[1] else Color(1, 0.55, 0.45))
		_checks.add_child(l)
		if c[1]:
			ok += 1
	var t := Label.new()
	t.text = "%d de %d listos" % [ok, all.size()]
	_checks.add_child(t)

# ---------------- ficha y privacidad ----------------
func _make_listing() -> void:
	var r := make_listing(_name.text, _short.text, _long.text, _mail.text, _ads.button_pressed, _iap.button_pressed)
	_out.text = r
	_run_checks()

static func make_listing(game: String, short: String, long: String, mail: String, ads: bool, iap: bool) -> String:
	DirAccess.make_dir_recursive_absolute("res://publicar")
	if short.length() > 80:
		short = short.substr(0, 80)
	var f := FileAccess.open("res://publicar/ficha_google_play.txt", FileAccess.WRITE)
	f.store_string("""FICHA DE GOOGLE PLAY · %s

Nombre (máx. 30): %s
Descripción breve (máx. 80): %s

Descripción completa (máx. 4000):
%s

Correo de contacto: %s
Categoría: Juegos
Anuncios: %s
Compras en la aplicación: %s

LISTA PARA GOOGLE PLAY CONSOLE
[ ] Icono 512×512 PNG
[ ] Imagen destacada 1024×500
[ ] 2-8 capturas del juego (toca con 3 dedos mientras juegas)
[ ] Política de privacidad publicada (archivo privacidad.html de esta carpeta; súbelo a GitHub Pages o a tu web)
[ ] Clasificación de contenido (cuestionario de la consola)
[ ] Seguridad de los datos: %s
[ ] Público objetivo y si es para niños
[ ] AAB firmado con tu clave de subida (archivo google_play.yml)
""" % [game, game.substr(0, 30), short, long, mail, "Sí" if ads else "No", "Sí" if iap else "No",
		"el juego guarda la partida solo en el teléfono" + (" · AdMob recoge el identificador de publicidad" if ads else "") + (" · Google Play gestiona los pagos" if iap else "")])
	f.close()
	var p := FileAccess.open("res://publicar/privacidad.html", FileAccess.WRITE)
	p.store_string("""<!doctype html><html lang="es"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Privacidad · %s</title>
<style>body{font-family:sans-serif;max-width:720px;margin:auto;padding:24px;line-height:1.6;background:#111;color:#eee}h1{color:#6cf}</style></head><body>
<h1>Política de privacidad de %s</h1>
<p>%s no pide registro y no recoge datos personales. La partida se guarda solo en tu dispositivo.</p>
%s%s
<p>Contacto: %s</p>
</body></html>""" % [game, game, game,
		"<p>Este juego muestra anuncios de Google AdMob, que puede usar el identificador de publicidad del dispositivo para mostrar anuncios. Más información: https://policies.google.com/privacy</p>" if ads else "",
		"<p>Las compras se gestionan con Google Play; el juego no recibe tus datos de pago.</p>" if iap else "", mail])
	p.close()
	return "Creados res://publicar/ficha_google_play.txt y privacidad.html."

# ---------------- tráiler ----------------
func _record_trailer() -> void:
	var dir := OS.get_system_dir(OS.SYSTEM_DIR_MOVIES)
	if dir == "":
		dir = ProjectSettings.globalize_path("user://")
	dir = dir.path_join("Aether")
	DirAccess.make_dir_recursive_absolute(dir)
	var file := dir.path_join("trailer_%d.avi" % int(Time.get_unix_time_from_system()))
	ProjectSettings.set_setting("editor/movie_writer/movie_file", file)
	ProjectSettings.set_setting("editor/movie_writer/fps", 30)
	ProjectSettings.save()
	if EditorInterface.has_method("set_movie_maker_enabled"):
		EditorInterface.call("set_movie_maker_enabled", true)
	EditorInterface.play_main_scene()
	_out.text = "Grabando mientras juegas. Al cerrar el juego el vídeo queda en:\n" + file + "\n(Para TikTok, conviértelo a MP4 con cualquier editor de vídeo.)"

# ---------------- GitHub → AAB ----------------
func _make_github() -> void:
	_out.text = make_github()
	_run_checks()

static func make_github() -> String:
	DirAccess.make_dir_recursive_absolute("res://publicar")
	var f := FileAccess.open("res://publicar/google_play.yml", FileAccess.WRITE)
	f.store_string(GITHUB_YML)
	f.close()
	var g := FileAccess.open("res://publicar/COMO_PUBLICAR.txt", FileAccess.WRITE)
	g.store_string(GITHUB_HELP)
	g.close()
	return "Creados res://publicar/google_play.yml y COMO_PUBLICAR.txt. Léelo: explica cómo subir el proyecto a GitHub y obtener el AAB."

const GITHUB_HELP := """CÓMO OBTENER EL AAB PARA GOOGLE PLAY (gratis, desde el teléfono)

1. Crea un repositorio PRIVADO en GitHub y sube la carpeta del proyecto.
   (Privado es obligatorio: la clave de subida no la debe ver nadie más.)
2. Copia publicar/google_play.yml a la carpeta .github/workflows/ del repositorio.
3. Clave de subida (MUY IMPORTANTE, guárdala para siempre: sin ella no podrás actualizar el juego):
   - En GitHub → Actions → «Google Play (AAB)» → Run workflow con «crear_clave» activado.
     Crea la clave y la deja en el artefacto «clave-de-subida» durante 1 día: descárgala YA y guárdala
     en un sitio seguro (Google Drive privado, por ejemplo). Si la pierdes no podrás actualizar el juego.
   - En Settings → Secrets and variables → Actions crea:
       KEYSTORE_BASE64  (el texto del archivo clave.txt del artefacto)
       KEYSTORE_USER    (upload)
       KEYSTORE_PASS    (la contraseña que elegiste al ejecutar)
4. Ejecuta de nuevo «Google Play (AAB)» sin marcar «crear_clave»: el AAB firmado aparece en Artifacts.
5. En Google Play Console → Crear app → Producción o Prueba interna → sube el AAB.
"""

const GITHUB_YML := """name: Google Play (AAB)
on:
  workflow_dispatch:
    inputs:
      crear_clave:
        description: 'Crear una clave de subida nueva (solo la primera vez)'
        type: boolean
        default: false
      contrasena:
        description: 'Contraseña para la clave nueva (mín. 6 letras)'
        default: ''
env:
  GODOT_VERSION: 4.7.2
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { distribution: temurin, java-version: 17 }
      - name: Crear clave de subida
        if: ${{ inputs.crear_clave }}
        run: |
          echo "::add-mask::${{ inputs.contrasena }}"
          keytool -genkeypair -v -keystore clave.keystore -alias upload -keyalg RSA -keysize 2048 -validity 10000 \\
            -storepass "${{ inputs.contrasena }}" -keypass "${{ inputs.contrasena }}" -dname "CN=Aether, O=Aether, C=US"
          base64 -w0 clave.keystore > clave.txt
      - uses: actions/upload-artifact@v4
        if: ${{ inputs.crear_clave }}
        with: { name: clave-de-subida, path: 'clave.*', retention-days: 1 }
      - name: Descargar Godot
        if: ${{ !inputs.crear_clave }}
        run: |
          V=$GODOT_VERSION
          wget -q https://github.com/godotengine/godot/releases/download/${V}-stable/Godot_v${V}-stable_linux.x86_64.zip
          wget -q https://github.com/godotengine/godot/releases/download/${V}-stable/Godot_v${V}-stable_export_templates.tpz
          unzip -q Godot_v${V}-stable_linux.x86_64.zip && sudo mv Godot_v${V}-stable_linux.x86_64 /usr/local/bin/godot
          mkdir -p ~/.local/share/godot/export_templates/${V}.stable
          unzip -q Godot_v${V}-stable_export_templates.tpz && mv templates/* ~/.local/share/godot/export_templates/${V}.stable/
          mkdir -p ~/.config/godot
          printf '[gd_resource type="EditorSettings" format=3]\\n\\n[resource]\\nexport/android/android_sdk_path = "%s"\\nexport/android/java_sdk_path = "%s"\\n' "$ANDROID_SDK_ROOT" "$JAVA_HOME" > ~/.config/godot/editor_settings-4.tres
          cp ~/.config/godot/editor_settings-4.tres ~/.config/godot/editor_settings-${V%.*}.tres
      - name: Exportar AAB firmado
        if: ${{ !inputs.crear_clave }}
        run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > $RUNNER_TEMP/clave.keystore
          export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=$RUNNER_TEMP/clave.keystore
          export GODOT_ANDROID_KEYSTORE_RELEASE_USER="${{ secrets.KEYSTORE_USER }}"
          export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="${{ secrets.KEYSTORE_PASS }}"
          PROJ=$(dirname $(find . -name project.godot -not -path './.git/*' | head -1))
          mkdir -p build
          godot --headless --path "$PROJ" --import || true
          godot --headless --path "$PROJ" --install-android-build-template || true
          godot --headless --path "$PROJ" --export-release "Android AAB" "$GITHUB_WORKSPACE/build/juego.aab"
          ls -la build
      - uses: actions/upload-artifact@v4
        if: ${{ !inputs.crear_clave }}
        with: { name: juego-aab, path: build/juego.aab }
"""

## Prepara el ajuste AAB sin abrir el panel (lo usan las pruebas y GitHub).
static func prepare_aab() -> bool:
	var c := ConfigFile.new()
	if c.load(PRESETS) != OK:
		return false
	var secs := _android_sections(c)
	if secs.is_empty():
		return false
	_ensure_aab(c, secs[0])
	return c.save(PRESETS) == OK
