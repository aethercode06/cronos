extends Node
## Aether Engine — núcleo (autoload «Aether»).
## Servicios comunes para todos los juegos de Aether Code:
## controles, parón de impacto, cámara lenta, temblor, destellos, sonido,
## música y hojas de animación.

signal player_died
signal boss_defeated

const SFX_DIR := "res://assets/chronos/audio/"

var camera: Node = null           # cámara activa (AetherCamera)
var player: Node = null           # jugador activo
var meta := {}                    # datos de las hojas de animación (meta.json)
var _tex_cache := {}
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_next := 0
var _music: AudioStreamPlayer
var _stop_until := 0.0
var _slow_until := 0.0
var _slow_scale := 1.0
var _flash_rect: ColorRect
var _flash_a := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	_load_meta()
	for i in 12:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -8.0
	add_child(_music)
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_flash_rect = ColorRect.new()
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = Color(1, 1, 1, 0)
	layer.add_child(_flash_rect)

# ---------------- controles (teclado, mando y táctil) ----------------
func _setup_input() -> void:
	var map := {
		"left": [KEY_LEFT, KEY_A], "right": [KEY_RIGHT, KEY_D], "up": [KEY_UP, KEY_W], "down": [KEY_DOWN, KEY_S],
		"jump": [KEY_SPACE, KEY_K], "attack": [KEY_Z, KEY_J], "dash": [KEY_SHIFT, KEY_L], "guard": [KEY_X, KEY_I],
	}
	var pad := {"jump": JOY_BUTTON_A, "attack": JOY_BUTTON_X, "dash": JOY_BUTTON_RIGHT_SHOULDER, "guard": JOY_BUTTON_LEFT_SHOULDER,
		"left": JOY_BUTTON_DPAD_LEFT, "right": JOY_BUTTON_DPAD_RIGHT, "up": JOY_BUTTON_DPAD_UP, "down": JOY_BUTTON_DPAD_DOWN}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.3)
		for k in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
		if pad.has(action):
			var jb := InputEventJoypadButton.new()
			jb.button_index = pad[action]
			InputMap.action_add_event(action, jb)
	for pair in [["left", -1.0], ["right", 1.0]]:
		var jm := InputEventJoypadMotion.new()
		jm.axis = JOY_AXIS_LEFT_X
		jm.axis_value = pair[1]
		InputMap.action_add_event(pair[0], jm)

# ---------------- hojas de animación ----------------
func _load_meta() -> void:
	var f := FileAccess.open("res://assets/chronos/meta.json", FileAccess.READ)
	if f:
		var d = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			meta = d

func tex(key: String) -> Texture2D:
	if _tex_cache.has(key):
		return _tex_cache[key]
	var file: String = meta.get(key, {}).get("file", key + ".webp")
	var t: Texture2D = load("res://assets/chronos/" + file)
	_tex_cache[key] = t
	return t

func sheet(key: String) -> Dictionary:
	return meta.get(key, {})

# ---------------- sensaciones de impacto ----------------
## Parón de impacto: congela la acción un instante para que el golpe «pese».
func hitstop(sec: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	_stop_until = max(_stop_until, now + sec)
	_apply_time()

## Cámara lenta durante unos segundos (tiempo real).
func slowmo(scale: float, sec: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	_slow_scale = scale
	_slow_until = now + sec
	_apply_time()

func _apply_time() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var s := 1.0
	if now < _slow_until:
		s = _slow_scale
	if now < _stop_until:
		s = 0.03
	Engine.time_scale = s

func shake(amount: float, zoom_punch := 0.0) -> void:
	if camera and camera.has_method("shake"):
		camera.shake(amount, zoom_punch)

func flash(col := Color(1, 1, 1), a := 0.5) -> void:
	_flash_rect.color = Color(col.r, col.g, col.b, a)
	_flash_a = a

func _process(delta: float) -> void:
	_apply_time()
	var real_dt := delta / max(Engine.time_scale, 0.001)
	if _flash_a > 0.0:
		_flash_a = max(0.0, _flash_a - real_dt * 2.5)
		_flash_rect.color.a = _flash_a

# ---------------- sonido ----------------
func sfx(name: String, vol := 1.0, pitch := 1.0) -> void:
	var path := SFX_DIR + name + ".mp3"
	if not ResourceLoader.exists(path):
		return
	var p := _sfx_pool[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx_pool.size()
	p.stream = load(path)
	p.volume_db = linear_to_db(clamp(vol, 0.01, 2.0))
	p.pitch_scale = pitch * randf_range(0.95, 1.05)
	p.play()

func music(name: String) -> void:
	var path := SFX_DIR + name + ".mp3"
	if name == "" or not ResourceLoader.exists(path):
		_music.stop()
		return
	var st: AudioStream = load(path)
	if st is AudioStreamMP3:
		st.loop = true
	if _music.stream == st and _music.playing:
		return
	_music.stream = st
	_music.play()
