class_name ZarekJuego
extends Node3D
## La Sombra de Zarek — Noche I (Aether Engine).
## Una noche corta (10-15 min): encontrar los 4 sellos de la dinastía en la
## mansión, sobrevivir a Elena y expulsar a Zarek con el ritual del Epicentro.

const SEALS_NEEDED := 4
const RITUAL_TIME := 10.0

var autotest := false
var shots := false
var mansion: ZarekMansion
var player: AetherPlayerFP
var elena: ZarekElena
var ghost: ZarekElena
var touch: AetherTouchFP
var flash_node: Node3D
var flash: SpotLight3D
var env: Environment

var state := "titulo"
var lives := 3
var sanity := 100.0
var battery := 100.0
var salt := 2
var seals := 0
var flash_on := true
var hidden_in: Dictionary = {}
var ritual := 0.0
var play_time := 0.0
var deaths := 0
var _scare_t := 30.0
var _halluc_t := 20.0
var _ghost_t := 0.0
var _ghost_move := Vector3.ZERO
var _intro_glimpse := -1.0
var _msg_t := 0.0
var _catch_t := 0.0
var _hide_seen := false
var _danger := 0.0
var _saw_enter_t := -10.0
var _flicker_t := 0.0
var _sanity_zero_cd := 0.0
var respawn_pos := Vector3.ZERO
var entered := false
var _forest_events := {}

# sonido
var snd_drone: AudioStreamPlayer
var snd_wind: AudioStreamPlayer
var snd_heart: AudioStreamPlayer
var snd_breath: AudioStreamPlayer
var snd_ui: AudioStreamPlayer
var snd_3d: AudioStreamPlayer3D
var snd_box: AudioStreamPlayer3D
var snd_radio: AudioStreamPlayer3D
var _cache := {}

# interfaz
var ui: CanvasLayer
var lbl_obj: Label
var lbl_prompt: Label
var lbl_msg: Label
var bar_san: ProgressBar
var bar_bat: ProgressBar
var bar_rit: ProgressBar
var lbl_lives: Label
var lbl_salt: Label
var vignette: ColorRect
var vig_mat: ShaderMaterial
var black: ColorRect
var slit_l: ColorRect
var slit_r: ColorRect
var title_box: Control
var end_box: Control
var pause_box: Control
var lbl_end_t: Label
var lbl_end_s: Label
var _black_target := 0.0
var top: VBoxContainer

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if "--prueba" in args:
		autotest = true
	if "--capturas" in args:
		shots = true
	_inputs()
	_environment()
	mansion = ZarekMansion.new()
	add_child(mansion)
	mansion.build(Aether.quality)
	mansion.bake_nav()
	for l in mansion.lamps:
		mansion.set_lamp(l, true)
	respawn_pos = mansion.cell_to_world("baja", 9.0, 11.2)
	player = AetherPlayerFP.new()
	add_child(player)
	player.collision_mask = 3  # suelo/paredes + puertas
	player.global_position = mansion.start_pos
	player.set_look(0.0, 0.0)
	player.step.connect(_on_step)
	_flashlight()
	elena = ZarekElena.new()
	add_child(elena)
	elena.setup(mansion, player)
	elena.caught.connect(_on_caught)
	elena.global_position = mansion.circle_pos
	elena.set_state(ZarekElena.S.DORMANT, 99999.0)
	elena.visible = false
	ghost = ZarekElena.new()
	ghost.only_visual = true
	add_child(ghost)
	ghost.visible = false
	_audio()
	_ui()
	touch = AetherTouchFP.new()
	touch.player = player
	touch.buttons = [
		["usar", "USAR", Vector2(-150, -175), 86.0],
		["linterna", "LUZ", Vector2(-330, -115), 62.0],
		["sal", "SAL", Vector2(-300, -290), 58.0],
	]
	add_child(touch)
	if autotest or shots:
		start_game(true)
	else:
		_show_title()

# ---------------- preparación ----------------
func _inputs() -> void:
	var map := {"usar": [KEY_E, KEY_ENTER], "linterna": [KEY_F], "sal": [KEY_Q], "pausa": [KEY_ESCAPE, KEY_P]}
	for a in map:
		if not InputMap.has_action(a):
			InputMap.add_action(a)
			for k in map[a]:
				var ev := InputEventKey.new()
				ev.physical_keycode = k
				InputMap.action_add_event(a, ev)
	var pad := {"usar": JOY_BUTTON_A, "linterna": JOY_BUTTON_Y, "sal": JOY_BUTTON_X, "pausa": JOY_BUTTON_START}
	for a in pad:
		var jb := InputEventJoypadButton.new()
		jb.button_index = pad[a]
		InputMap.action_add_event(a, jb)

func _environment() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.38, 0.34)
	env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.35
	env.tonemap_white = 6.0
	env.fog_enabled = true
	env.fog_light_color = Color(0.07, 0.065, 0.07)
	env.fog_density = 0.016
	env.fog_sky_affect = 0.0
	env.glow_enabled = Aether.glow_ok()
	env.glow_intensity = 0.8
	env.glow_bloom = 0.06
	env.glow_hdr_threshold = 0.9
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.0
	env.adjustment_contrast = 1.06
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.02, 0.03, 0.06)
	sm.sky_horizon_color = Color(0.06, 0.07, 0.1)
	sm.ground_bottom_color = Color(0.0, 0.0, 0.0)
	sm.ground_horizon_color = Color(0.05, 0.05, 0.07)
	sm.sun_angle_max = 2.0
	sky.sky_material = sm
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	we.environment = env
	add_child(we)
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.65, 0.95)
	moon.light_energy = 0.45
	moon.rotation_degrees = Vector3(-38, 30, 0)
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 60.0
	add_child(moon)

func _flashlight() -> void:
	flash_node = Node3D.new()
	add_child(flash_node)
	flash = SpotLight3D.new()
	flash.light_color = Color(1.0, 0.9, 0.72)
	flash.light_energy = 6.0
	flash.spot_range = 32.0
	flash.spot_angle = 40.0
	flash.spot_angle_attenuation = 1.6
	flash.spot_attenuation = 0.8
	flash.shadow_enabled = true
	flash.shadow_bias = 0.04
	flash_node.add_child(flash)
	# halo cercano para que se vea el entorno inmediato
	var near := OmniLight3D.new()
	near.light_color = Color(1.0, 0.88, 0.7)
	near.omni_range = 4.5
	near.light_energy = 0.7
	near.name = "cerca"
	flash_node.add_child(near)

func _player_snd(stream: AudioStream, db := 0.0, loop := false) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = db
	add_child(p)
	if loop:
		p.play()
	return p

func _audio() -> void:
	snd_drone = _player_snd(_s("drone"), -13.0, true)
	snd_wind = _player_snd(_s("viento"), -20.0, true)
	snd_heart = _player_snd(_s("latido"), -60.0, true)
	snd_breath = _player_snd(_s("aliento"), -60.0, true)
	snd_ui = _player_snd(_s("recoger"), -4.0)
	snd_3d = AudioStreamPlayer3D.new()
	snd_3d.unit_size = 4.0
	snd_3d.max_distance = 30.0
	add_child(snd_3d)
	snd_box = AudioStreamPlayer3D.new()
	snd_box.stream = _s("caja_musica")
	snd_box.unit_size = 3.0
	snd_box.max_distance = 26.0
	add_child(snd_box)
	snd_box.global_position = mansion.musicbox_pos
	snd_radio = AudioStreamPlayer3D.new()
	snd_radio.stream = _s("estatica")
	snd_radio.unit_size = 2.5
	snd_radio.max_distance = 22.0
	snd_radio.volume_db = -4.0
	add_child(snd_radio)
	snd_radio.global_position = mansion.radio_pos

func _s(kind: String) -> AudioStreamWAV:
	if not _cache.has(kind):
		_cache[kind] = AetherSynth.make(kind)
	return _cache[kind]

## Sonido en un punto del espacio (golpes detrás de una pared, susurros…).
func sound_at(kind: String, pos: Vector3, db := 0.0) -> void:
	var p := AudioStreamPlayer3D.new()
	p.stream = _s(kind)
	p.unit_size = 4.0
	p.max_distance = 30.0
	p.volume_db = db
	add_child(p)
	p.global_position = pos
	p.play()
	p.finished.connect(p.queue_free)

func sound_behind(kind: String, dist := 3.0, db := 0.0) -> void:
	var back := -player.look_dir()
	back.y = 0
	sound_at(kind, player.global_position + back.normalized() * dist + Vector3(randf_range(-1, 1), 1.5, randf_range(-1, 1)), db)

# ---------------- interfaz ----------------
func _label(text: String, size: int, col := Color(0.9, 0.86, 0.78)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _bar(col: Color, w: float) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.custom_minimum_size = Vector2(w, 8)
	b.max_value = 100.0
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.5)
	var fg := StyleBoxFlat.new()
	fg.bg_color = col
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b

func _ui() -> void:
	# posprocesado de cine (debajo de la interfaz, para que el texto no lleve grano)
	var cine := CanvasLayer.new()
	cine.layer = 40
	add_child(cine)
	var cr := ColorRect.new()
	cr.set_anchors_preset(Control.PRESET_FULL_RECT)
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pm := ShaderMaterial.new()
	pm.shader = load("res://zarek/post.gdshader")
	cr.material = pm
	cine.add_child(cr)
	ui = CanvasLayer.new()
	ui.layer = 50
	add_child(ui)
	vignette = ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform float amount = 0.4;
uniform float red = 0.0;
uniform float t = 0.0;
void fragment() {
	vec2 uv = UV - 0.5;
	float d = length(uv * vec2(1.25, 1.0));
	float v = smoothstep(0.28, 0.82, d) * (0.55 + amount);
	float g = fract(sin(dot(UV * (t + 1.0), vec2(12.9898, 78.233))) * 43758.5453);
	vec3 c = mix(vec3(0.0), vec3(0.45, 0.0, 0.0), red);
	COLOR = vec4(c, clamp(v + red * 0.25 + (g - 0.5) * 0.06 * (0.4 + amount), 0.0, 1.0));
}
"""
	vig_mat = ShaderMaterial.new()
	vig_mat.shader = sh
	vignette.material = vig_mat
	ui.add_child(vignette)
	# rendija del armario
	slit_l = ColorRect.new()
	slit_l.color = Color(0, 0, 0, 0.97)
	slit_l.anchor_bottom = 1.0
	slit_l.anchor_right = 0.47
	slit_l.visible = false
	ui.add_child(slit_l)
	slit_r = ColorRect.new()
	slit_r.color = Color(0, 0, 0, 0.97)
	slit_r.anchor_left = 0.53
	slit_r.anchor_right = 1.0
	slit_r.anchor_bottom = 1.0
	slit_r.visible = false
	ui.add_child(slit_r)
	top = VBoxContainer.new()
	top.position = Vector2(26, 18)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(top)
	lbl_lives = _label("", 22, Color(0.85, 0.15, 0.15))
	top.add_child(lbl_lives)
	var r1 := HBoxContainer.new()
	r1.add_child(_label("CORDURA ", 13, Color(0.6, 0.75, 0.95)))
	bar_san = _bar(Color(0.45, 0.65, 0.95), 150)
	r1.add_child(bar_san)
	top.add_child(r1)
	var r2 := HBoxContainer.new()
	r2.add_child(_label("LINTERNA ", 13, Color(0.95, 0.85, 0.5)))
	bar_bat = _bar(Color(0.95, 0.82, 0.4), 150)
	r2.add_child(bar_bat)
	top.add_child(r2)
	lbl_salt = _label("", 14, Color(0.85, 0.85, 0.8))
	top.add_child(lbl_salt)
	lbl_obj = _label("", 18)
	lbl_obj.set_anchors_preset(Control.PRESET_CENTER_TOP)
	lbl_obj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_obj.position = Vector2(-400, 18)
	lbl_obj.size = Vector2(800, 60)
	lbl_obj.autowrap_mode = TextServer.AUTOWRAP_WORD
	ui.add_child(lbl_obj)
	lbl_prompt = _label("", 22, Color(1, 0.92, 0.75))
	lbl_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	lbl_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_prompt.position = Vector2(-300, -120)
	lbl_prompt.size = Vector2(600, 40)
	ui.add_child(lbl_prompt)
	bar_rit = _bar(Color(0.95, 0.95, 0.85), 360)
	bar_rit.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar_rit.position = Vector2(-180, -75)
	bar_rit.size = Vector2(360, 12)
	bar_rit.visible = false
	ui.add_child(bar_rit)
	lbl_msg = _label("", 26, Color(0.92, 0.88, 0.8))
	lbl_msg.set_anchors_preset(Control.PRESET_CENTER)
	lbl_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_msg.position = Vector2(-460, -120)
	lbl_msg.size = Vector2(920, 160)
	lbl_msg.autowrap_mode = TextServer.AUTOWRAP_WORD
	ui.add_child(lbl_msg)
	black = ColorRect.new()
	black.color = Color(0, 0, 0, 1)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(black)
	_black_target = 1.0
	title_box = _menu_box(["LA SOMBRA DE ZAREK", "Noche I · La casa Varela"], [["JUGAR", start_game.bind(false)]], "Usa auriculares. Juega a oscuras.")
	end_box = _menu_box(["", ""], [["JUGAR DE NUEVO", _restart], ["MENÚ", _to_title]], "")
	lbl_end_t = end_box.get_meta("t")
	lbl_end_s = end_box.get_meta("s")
	pause_box = _menu_box(["PAUSA", ""], [["CONTINUAR", _resume], ["REINICIAR", _restart]], "")
	end_box.visible = false
	pause_box.visible = false
	var pb := Button.new()
	pb.text = "II"
	pb.flat = true
	pb.add_theme_font_size_override("font_size", 30)
	pb.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75, 0.55))
	pb.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pb.position = Vector2(-90, 10)
	pb.size = Vector2(80, 64)
	pb.pressed.connect(_pause)
	ui.add_child(pb)
	ui.move_child(pb, title_box.get_index())

func _menu_box(titles: Array, buttons: Array, foot: String) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.78)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.position = Vector2(-330, -200)
	vb.size = Vector2(660, 400)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 16)
	root.add_child(vb)
	var t := _label(titles[0], 54, Color(0.82, 0.12, 0.12))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var s := _label(titles[1], 22, Color(0.85, 0.8, 0.7))
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(s)
	root.set_meta("t", t)
	root.set_meta("s", s)
	for b in buttons:
		var btn := Button.new()
		btn.text = b[0]
		btn.custom_minimum_size = Vector2(320, 64)
		btn.add_theme_font_size_override("font_size", 26)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.12, 0.03, 0.03, 0.9)
		sb.border_color = Color(0.6, 0.12, 0.1)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(6)
		btn.add_theme_stylebox_override("normal", sb)
		var sh := sb.duplicate()
		sh.bg_color = Color(0.3, 0.05, 0.05, 0.95)
		btn.add_theme_stylebox_override("hover", sh)
		btn.add_theme_stylebox_override("pressed", sh)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.pressed.connect(b[1])
		vb.add_child(btn)
	if foot != "":
		var f := _label(foot, 16, Color(0.6, 0.57, 0.5))
		f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(f)
	ui.add_child(root)
	return root

func _hud_visible(v: bool) -> void:
	top.visible = v
	lbl_obj.visible = v
	lbl_prompt.visible = v
	touch.visible = v

func _show_title() -> void:
	state = "titulo"
	_hud_visible(false)
	title_box.visible = true
	player.frozen = true
	_black_target = 0.35
	flash.visible = true

func message(text: String, sec := 4.0) -> void:
	lbl_msg.text = text
	lbl_msg.modulate.a = 1.0
	_msg_t = sec

func _update_hud() -> void:
	lbl_lives.text = "♥ ".repeat(lives).strip_edges()
	bar_san.value = sanity
	bar_bat.value = battery
	lbl_salt.text = "Sal: %d   Sellos: %d/%d" % [salt, seals, SEALS_NEEDED]
	if not entered:
		var dist := int(player.global_position.distance_to(mansion.front_door))
		lbl_obj.text = "Llega a la mansión Varela (%d m)" % dist
	elif seals < SEALS_NEEDED:
		var near := _nearest_seal()
		var where := ""
		if not near.is_empty():
			where = " · El más cercano está en " + mansion.room_name(near.pos)
		lbl_obj.text = "Encuentra los sellos de la dinastía (%d/%d)%s" % [seals, SEALS_NEEDED, where]
	elif state == "ritual" or ritual > 0.0:
		lbl_obj.text = "Recita la oración dentro del círculo de sal"
	else:
		lbl_obj.text = "Ve al Epicentro y haz el ritual dentro del círculo de sal"

func _nearest_seal() -> Dictionary:
	var best := {}
	var bd := 1e9
	for s in mansion.seals:
		if s.taken:
			continue
		var d: float = player.global_position.distance_to(s.pos)
		if d < bd:
			bd = d
			best = s
	return best

# ---------------- flujo de la partida ----------------
func start_game(quick := false) -> void:
	title_box.visible = false
	_hud_visible(true)
	state = "intro"
	player.frozen = true
	flash_on = true
	if quick:
		state = "juego"
		player.frozen = false
		_black_target = 0.0
		black.color.a = 0.0
		return
	if not DisplayServer.is_touchscreen_available():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_black_target = 1.0
	await get_tree().create_timer(0.6).timeout
	var lines := [
		"3:00 de la madrugada. El coche se apagó en medio del bosque.",
		"Al final del camino está la mansión Varela.\nAquí, en 1974, Elena mató a su familia en una sola noche.",
		"Algo vivía dentro de ella. Algo llamado Zarek.\nCuatro sellos de la dinastía pueden expulsarlo.",
	]
	for l in lines:
		message(l, 3.6)
		await get_tree().create_timer(3.9).timeout
	_black_target = 0.0
	message("", 0.1)
	await get_tree().create_timer(1.2).timeout
	state = "juego"
	player.frozen = false
	await get_tree().create_timer(0.6).timeout
	message("Tengo que llegar a la mansión.", 2.6)

func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _to_title() -> void:
	_restart()

func _resume() -> void:
	pause_box.visible = false
	get_tree().paused = false
	if not DisplayServer.is_touchscreen_available():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _pause() -> void:
	if state in ["titulo", "final", "muerte"]:
		return
	pause_box.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("pausa"):
		if get_tree().paused:
			_resume()
		else:
			_pause()
	if e is InputEventMouseButton and e.pressed and state == "juego" and not DisplayServer.is_touchscreen_available():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	# fundido negro y mensajes
	black.color.a = move_toward(black.color.a, _black_target, delta * 1.2)
	if _msg_t > 0.0:
		_msg_t -= delta
		if _msg_t < 0.8:
			lbl_msg.modulate.a = maxf(0.0, _msg_t / 0.8)
	vig_mat.set_shader_parameter("t", fmod(Time.get_ticks_msec() / 1000.0, 100.0))
	_update_flash(delta)
	if state in ["juego", "escondido", "ritual"]:
		_play(delta)
	_update_hud()
	_update_audio(delta)

func _update_flash(delta: float) -> void:
	var cam := player.camera
	flash_node.global_position = cam.global_position + cam.global_transform.basis * Vector3(0.18, -0.15, 0.0)
	var target := cam.global_transform.basis.get_rotation_quaternion()
	flash_node.quaternion = flash_node.quaternion.slerp(target, minf(1.0, delta * 14.0))
	var on := flash_on and battery > 0.0 and hidden_in.is_empty()
	var e := 6.0
	if battery < 15.0:
		e *= 0.5 + 0.5 * float(randf() > 0.08)
	# parpadea cuando Elena está cerca
	if elena.visible and elena.global_position.distance_to(player.global_position) < 9.0:
		_flicker_t -= delta
		if _flicker_t <= 0.0:
			_flicker_t = randf_range(0.04, 0.25)
			flash.set_meta("off", randf() < 0.45)
		if flash.get_meta("off", false):
			e *= 0.08
	flash.visible = on
	flash.light_energy = e
	flash_node.get_node("cerca").visible = on
	elena.flashlight_on = on

func _play(delta: float) -> void:
	play_time += delta
	var pp := player.global_position
	var lit := mansion.is_lit(pp)
	var on := flash_on and battery > 0.0 and hidden_in.is_empty()
	if on:
		battery = maxf(0.0, battery - delta * 0.75)
		if battery <= 0.0:
			message("La linterna se quedó sin pilas.", 2.5)
	# Elena a la vista
	var ed := elena.global_position.distance_to(pp)
	var see_elena := elena.visible and ed < 18.0 and _in_view(elena.global_position + Vector3(0, 1.4, 0))
	# cordura
	var ds := 0.0
	if lit:
		ds += 5.0
	elif not on:
		ds -= 1.8
	else:
		ds -= 0.25
	if see_elena:
		ds -= 7.0
	if not hidden_in.is_empty():
		ds = minf(ds, -0.4)
	sanity = clampf(sanity + ds * delta, 0.0, 100.0)
	_sanity_zero_cd -= delta
	if sanity <= 0.0 and _sanity_zero_cd <= 0.0:
		_sanity_zero_cd = 30.0
		sanity = 25.0
		message("Ella me encontró en mi propia mente.", 3.0)
		sound_behind("risa", 2.0, 2.0)
		if elena.state == ZarekElena.S.DORMANT:
			elena.wake_far()
		elena.hear(pp, 999.0)
	# peligro: para latido y viñeta
	var target_d := 0.0
	if elena.visible:
		target_d = clampf(1.0 - ed / 16.0, 0.0, 1.0)
		if elena.state == ZarekElena.S.CHASE:
			target_d = maxf(target_d, 0.7)
	_danger = lerpf(_danger, target_d, delta * 2.0)
	vig_mat.set_shader_parameter("amount", clampf((100.0 - sanity) / 100.0 * 0.6 + _danger * 0.5, 0.0, 1.0))
	# Elena: escondite
	elena.player_hidden = not hidden_in.is_empty()
	if not hidden_in.is_empty() and _hide_seen and elena.state == ZarekElena.S.CHASE:
		# te vio entrar: va al armario y lo abre
		var wp: Vector3 = hidden_in.pos
		elena.path = mansion.path(elena.global_position, wp)
		if Vector2(elena.global_position.x - wp.x, elena.global_position.z - wp.z).length() < 1.3:
			_exit_wardrobe(false)
			_on_caught()
			return
	_events(pp)
	# vistazo de guion al principio
	if _intro_glimpse > 0.0 and state == "juego":
		_intro_glimpse -= delta
		if _intro_glimpse <= 0.0:
			_glimpse(true)
	_director(delta)
	_hallucinations(delta)
	_ghost_update(delta)
	_interact_prompt()
	if Input.is_action_just_pressed("usar"):
		_use()
	if Input.is_action_just_pressed("linterna") and hidden_in.is_empty():
		flash_on = not flash_on
		_click()
	if Input.is_action_just_pressed("sal"):
		_throw_salt()
	# ritual
	if seals >= SEALS_NEEDED and _in_circle(pp):
		if Input.is_action_pressed("usar") or (autotest and state == "ritual"):
			if state != "ritual":
				state = "ritual"
				_ritual_start()
			ritual += delta
			player.speed_mult = 0.0
		else:
			player.speed_mult = 1.0
			ritual = maxf(0.0, ritual - delta * 0.3)
		bar_rit.visible = true
		bar_rit.value = ritual / RITUAL_TIME * 100.0
		if ritual >= RITUAL_TIME:
			_win()
	else:
		bar_rit.visible = false
		player.speed_mult = 1.0 if hidden_in.is_empty() else 0.0
		if state == "ritual":
			state = "juego"

func _events(pp: Vector3) -> void:
	if not entered and mansion.inside_house(pp):
		entered = true
		sound_behind("portazo", 3.0, 4.0)
		player.shake(10.0)
		message("La puerta se cerró detrás de mí.\nYa no hay vuelta atrás.", 3.5)
		elena.timer = 30.0
	# sustos del bosque: una sola vez cada uno
	var pts := {"puente": mansion.cell_to_world("exterior", 31.0, 87.0), "columpio": mansion.cell_to_world("exterior", 12.0, 61.0),
		"porton": mansion.cell_to_world("exterior", 44.0, 71.0), "cuervos": mansion.cell_to_world("exterior", 79.0, 21.0)}
	for k in pts:
		if _forest_events.has(k):
			continue
		if Vector2(pp.x - pts[k].x, pp.z - pts[k].z).length() < 9.0:
			_forest_events[k] = true
			match k:
				"puente":
					_glimpse(true)
				"columpio":
					sound_at("risa", pts[k] + Vector3(0, 2, 0), 0.0)
					message("El columpio se mueve solo…", 2.5)
				"porton":
					sound_at("crujido", pts[k] + Vector3(0, 2, 0), 4.0)
					sound_behind("susurro", 2.0, 0.0)
				"cuervos":
					sound_at("risa", pts[k] + Vector3(0, 6, 0), 2.0)

func _in_circle(pp: Vector3) -> bool:
	return absf(pp.y - mansion.circle_pos.y) < 1.5 and Vector2(pp.x - mansion.circle_pos.x, pp.z - mansion.circle_pos.z).length() < 1.9

func _in_view(p: Vector3) -> bool:
	var cam := player.camera
	if cam.is_position_behind(p):
		return false
	var sp := cam.unproject_position(p)
	var vs := get_viewport().get_visible_rect().size
	if sp.x < 0 or sp.y < 0 or sp.x > vs.x or sp.y > vs.y:
		return false
	var q := PhysicsRayQueryParameters3D.create(cam.global_position, p, 1)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()

func _on_step(noise: float) -> void:
	if state != "juego" and state != "ritual":
		return
	elena.hear(player.global_position, noise)

func _click() -> void:
	snd_ui.stream = _s("paso")
	snd_ui.volume_db = -10.0
	snd_ui.play()

# ---------------- interacción ----------------
func _target() -> Dictionary:
	var pp := player.global_position
	if not hidden_in.is_empty():
		return {"kind": "salir", "text": "USAR: salir del armario"}
	for s in mansion.seals:
		if not s.taken and Vector2(pp.x - s.pos.x, pp.z - s.pos.z).length() < 1.7:
			return {"kind": "sello", "obj": s, "text": "USAR: tomar el sello"}
	for k in mansion.pickups:
		if not k.taken and Vector2(pp.x - k.pos.x, pp.z - k.pos.z).length() < 1.6:
			return {"kind": "pick", "obj": k, "text": "USAR: tomar " + ("las pilas" if k.kind == "pila" else "la sal")}
	if seals >= SEALS_NEEDED and _in_circle(pp):
		return {"kind": "ritual", "text": "MANTÉN USAR: recitar la oración"}
	var pt := mansion.portal_near(pp, 1.7)
	if not pt.is_empty():
		return {"kind": "portal", "obj": pt, "text": "USAR: " + str(pt.text)}
	var wd := mansion.wardrobe_near(pp, 1.5)
	if not wd.is_empty():
		return {"kind": "armario", "obj": wd, "text": "USAR: esconderse en el armario"}
	var d := mansion.door_near(pp + player.forward() * 0.6, 1.7)
	if not d.is_empty():
		if d.locked:
			return {"kind": "cerrada", "obj": d, "text": "Cerrada. Algo la sella desde dentro."}
		return {"kind": "puerta", "obj": d, "text": "USAR: " + ("cerrar" if d.open else "abrir") + " la puerta"}
	var l := mansion.lamp_near(pp, 1.8)
	if not l.is_empty() and not l.broken:
		return {"kind": "lampara", "obj": l, "text": "USAR: " + ("apagar" if l.on else "encender") + " la lámpara"}
	if not l.is_empty() and l.broken:
		return {"kind": "nada", "text": "La bombilla está rota."}
	return {}

func _interact_prompt() -> void:
	var t := _target()
	lbl_prompt.text = str(t.get("text", ""))

func _use() -> void:
	var t := _target()
	match str(t.get("kind", "")):
		"salir":
			_exit_wardrobe(true)
		"sello":
			_take_seal(t.obj)
		"pick":
			var k: Dictionary = t.obj
			k.taken = true
			k.item.visible = false
			if k.kind == "pila":
				battery = minf(100.0, battery + 55.0)
				message("Pilas nuevas para la linterna.", 2.0)
			else:
				salt += 1
				message("Sal. Un puñado más contra ella.", 2.0)
			snd_ui.stream = _s("recoger")
			snd_ui.volume_db = -8.0
			snd_ui.play()
		"armario":
			_enter_wardrobe(t.obj)
		"puerta":
			mansion.set_door(t.obj, not t.obj.open)
			t.obj.snd.stream = _s("crujido")
			t.obj.snd.play()
			elena.hear(player.global_position, 5.0)
		"cerrada":
			sound_at("golpes", t.obj.pos + Vector3(0, 1.4, 0), 2.0)
		"portal":
			_use_portal(t.obj)
		"lampara":
			mansion.set_lamp(t.obj, not t.obj.on)
			_click()

func _use_portal(pt: Dictionary) -> void:
	player.frozen = true
	_black_target = 1.0
	black.color.a = 0.6
	sound_at("crujido", player.global_position + Vector3(0, 1, 0), -2.0)
	await get_tree().create_timer(0.45).timeout
	var to: Vector3 = pt.to
	player.global_position = to + Vector3(0.9, 0.05, 0.9)
	player.velocity = Vector3.ZERO
	await get_tree().create_timer(0.25).timeout
	_black_target = 0.0
	player.frozen = false
	if state == "juego":
		message(mansion.room_name(player.global_position).capitalize(), 1.8)

func _take_seal(s: Dictionary) -> void:
	s.taken = true
	s.node.visible = false
	seals += 1
	elena.aggro = seals
	snd_ui.stream = _s("campana")
	snd_ui.volume_db = -6.0
	snd_ui.play()
	player.shake(4.0)
	match seals:
		1:
			message("Primer sello.\nEn algún lugar empezó a sonar una caja de música.", 4.0)
			snd_box.play()
			if elena.state == ZarekElena.S.DORMANT:
				elena.timer = minf(elena.timer, 4.0)
		2:
			message("Segundo sello.\nEl fonógrafo se encendió solo. Elena ya no le teme a la luz.", 4.5)
			snd_radio.play()
			for l in mansion.lamps:
				mansion.flicker_lamp(l, 1.5)
			sound_behind("susurro", 2.0, 2.0)
		3:
			message("Tercer sello.\nLas luces de la casa empiezan a morir.", 4.0)
			for l in mansion.lamps:
				if l.on:
					mansion.break_lamp(l)
					sound_at("portazo", l.pos + Vector3(0, 2.0, 0), -2.0)
					break
			sound_behind("risa", 4.0, 0.0)
		4:
			_blackout()

func _blackout() -> void:
	message("El cuarto sello.\nLa casa entera se quedó a oscuras.", 4.5)
	for l in mansion.lamps:
		mansion.break_lamp(l)
	snd_box.stop()
	snd_radio.stop()
	player.shake(14.0)
	Aether.flash(Color(0.6, 0, 0), 0.4)
	sound_behind("grito", 6.0, 3.0)
	for d in mansion.doors:
		if d.locked:
			d.locked = false
			mansion.set_door(d, true, true)
			d.snd.stream = _s("portazo")
			d.snd.play()
	if elena.state == ZarekElena.S.DORMANT:
		elena.wake_far()
	elena.hear(player.global_position, 999.0)

func _enter_wardrobe(wd: Dictionary) -> void:
	hidden_in = wd
	_hide_seen = elena.state == ZarekElena.S.CHASE and elena.sees_player and elena.global_position.distance_to(player.global_position) < 9.0
	player.global_position = wd.inside
	player.set_look(wd.yaw, 0.0)
	player.speed_mult = 0.0
	player.velocity = Vector3.ZERO
	for c in player.get_children():
		if c is CollisionShape3D:
			c.disabled = true
	slit_l.visible = true
	slit_r.visible = true
	state = "escondido"
	sound_at("crujido", wd.inside + Vector3(0, 1, 0), -4.0)

func _exit_wardrobe(normal: bool) -> void:
	if hidden_in.is_empty():
		return
	player.global_position = hidden_in.pos
	for c in player.get_children():
		if c is CollisionShape3D:
			c.disabled = false
	hidden_in = {}
	slit_l.visible = false
	slit_r.visible = false
	player.speed_mult = 1.0
	state = "juego"
	if normal:
		sound_at("crujido", player.global_position + Vector3(0, 1, 0), -4.0)

func _throw_salt() -> void:
	if salt <= 0:
		message("No me queda sal.", 1.5)
		return
	salt -= 1
	Aether.flash(Color(0.9, 0.9, 0.85), 0.25)
	var ed := elena.global_position.distance_to(player.global_position)
	var to := elena.global_position - player.global_position
	to.y = 0
	var facing := player.look_dir()
	facing.y = 0
	if elena.visible and ed < 7.0 and facing.normalized().dot(to.normalized()) > 0.4:
		elena.repel(player.global_position)
		sound_at("grito", elena.global_position + Vector3(0, 1.6, 0), 2.0)
		message("La sal la quemó. Huyó.", 2.2)
	else:
		message("La sal cayó al suelo. No había nada ahí.", 2.0)

# ---------------- atrapado / muerte ----------------
func _on_caught() -> void:
	if state in ["atrapado", "final", "muerte"] or (autotest and get_meta("no_catch", false)):
		return
	state = "atrapado"
	elena.can_catch = false
	elena.set_state(ZarekElena.S.GHOST)
	elena.visible = true
	player.frozen = true
	deaths += 1
	# susto: Elena justo delante de la cara
	var cam := player.camera
	var fwd := -player.global_transform.basis.z
	elena.global_position = player.global_position + fwd * 0.62
	elena.global_position.y = player.global_position.y + (player.eye_height - elena.eye_height)
	elena.play_anim("attack", 1.6)
	elena.look_at(Vector3(player.global_position.x, elena.global_position.y, player.global_position.z), Vector3.UP)
	player.set_look(player.rotation.y, 0.05)
	flash_on = true
	snd_ui.stream = _s("grito")
	snd_ui.volume_db = 4.0
	snd_ui.play()
	player.shake(22.0)
	Aether.flash(Color(0.7, 0.0, 0.0), 0.6)
	vig_mat.set_shader_parameter("red", 1.0)
	await get_tree().create_timer(1.3).timeout
	_black_target = 1.0
	black.color.a = 1.0
	vig_mat.set_shader_parameter("red", 0.0)
	lives -= 1
	await get_tree().create_timer(1.2).timeout
	if lives <= 0:
		_lose()
		return
	if not hidden_in.is_empty():
		_exit_wardrobe(false)
	player.global_position = respawn_pos
	player.set_look(PI, 0.0)
	sanity = maxf(sanity, 60.0)
	elena.vanish(14.0)
	elena.can_catch = true
	await get_tree().create_timer(0.6).timeout
	message("Desperté en el vestíbulo.\n%s" % ("Me queda una oportunidad." if lives == 1 else "Me quedan %d oportunidades." % lives), 3.5)
	_black_target = 0.0
	player.frozen = false
	state = "juego"

func _lose() -> void:
	state = "muerte"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hud_visible(false)
	lbl_end_t.text = "ZAREK TE RECLAMÓ"
	lbl_end_s.text = "Sellos encontrados: %d/%d · Tiempo: %s" % [seals, SEALS_NEEDED, _fmt(play_time)]
	end_box.visible = true
	snd_heart.volume_db = -60.0

func _ritual_start() -> void:
	message("«Zarek, hijo de la roca madre, sal de esta casa…»", 3.5)
	if elena.state == ZarekElena.S.DORMANT:
		elena.wake_far()
	elena.hear(player.global_position, 999.0)
	elena.aggro = 4

func _win() -> void:
	state = "final"
	player.frozen = true
	elena.can_catch = false
	elena.set_state(ZarekElena.S.GHOST)
	var fwd := -player.global_transform.basis.z
	elena.global_position = player.global_position + fwd * 2.2
	elena.global_position.y = player.global_position.y
	elena.look_at(Vector3(player.global_position.x, 0.0, player.global_position.z), Vector3.UP)
	elena.play_anim("attack", 1.0)
	elena.visible = true
	snd_ui.stream = _s("grito")
	snd_ui.volume_db = 2.0
	snd_ui.play()
	player.shake(18.0)
	await get_tree().create_timer(1.1).timeout
	Aether.flash(Color(1, 1, 1), 1.0)
	elena.visible = false
	_black_target = 1.0
	await get_tree().create_timer(1.6).timeout
	message("Zarek ha sido expulsado.\nPor ahora.", 4.0)
	await get_tree().create_timer(4.2).timeout
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hud_visible(false)
	lbl_end_t.text = "NOCHE I SUPERADA"
	lbl_end_s.text = "Tiempo: %s · Veces atrapada: %d\nLa casa Varela todavía guarda secretos… Continuará." % [_fmt(play_time), deaths]
	end_box.visible = true
	Aether.save.set_value("zarek_noche1", true)

func _fmt(t: float) -> String:
	return "%d:%02d" % [int(t) / 60, int(t) % 60]

# ---------------- director de sustos ----------------
func _director(delta: float) -> void:
	if elena.state == ZarekElena.S.CHASE or state == "ritual":
		return
	_scare_t -= delta
	if _scare_t > 0.0:
		return
	_scare_t = randf_range(26.0, 48.0) - seals * 3.0
	var pp := player.global_position
	var pool := ["golpes", "susurro", "pasos", "portazo", "vistazo", "risa"]
	pool.append("apagon")
	if seals >= 1:
		pool.append("lampara")
	match pool[randi() % pool.size()]:
		"golpes":
			sound_behind("golpes", 3.2, 0.0)
		"susurro":
			sound_behind("susurro", 1.2, 0.0)
			sanity = maxf(0.0, sanity - 5.0)
		"pasos":
			_footsteps_above()
		"portazo":
			var d := mansion.door_near(pp, 12.0)
			if not d.is_empty() and d.open and not d.locked:
				mansion.set_door(d, false, true)
				d.snd.stream = _s("portazo")
				d.snd.play()
				player.shake(5.0)
			else:
				sound_behind("portazo", 8.0, -4.0)
		"vistazo":
			_glimpse(false)
		"risa":
			sound_behind("risa", 6.0, -2.0)
		"lampara":
			for l in mansion.lamps:
				if l.on:
					mansion.flicker_lamp(l, 2.2)
		"apagon":
			# una lámpara cercana se apaga sola (se puede volver a encender)
			var best := {}
			var bd := 1e9
			for l in mansion.lamps:
				if l.on and not l.broken:
					var dd: float = pp.distance_to(l.pos)
					if dd < bd:
						bd = dd
						best = l
			if not best.is_empty() and bd < 20.0:
				mansion.flicker_lamp(best, 1.2)
				await get_tree().create_timer(1.2).timeout
				mansion.set_lamp(best, false)
				sound_at("crujido", best.pos + Vector3(0, 2.5, 0), 0.0)

func _footsteps_above() -> void:
	for i in 6:
		await get_tree().create_timer(0.55).timeout
		if not is_inside_tree():
			return
		sound_at("paso", player.global_position + Vector3(randf_range(-2, 2) + i * 0.6, 3.6, randf_range(-2, 2)), 6.0)

## Elena (falsa) cruza al fondo del pasillo y desaparece.
func _glimpse(scripted: bool) -> void:
	if elena.visible and elena.global_position.distance_to(player.global_position) < 14.0:
		return
	var cam := player.camera
	var dir := player.look_dir()
	dir.y = 0
	dir = dir.normalized()
	var base := cam.global_position
	var q := PhysicsRayQueryParameters3D.create(base, base + dir * 16.0, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var dist := 16.0
	if not hit.is_empty():
		dist = base.distance_to(hit.position) - 0.8
	if dist < 5.0 and not scripted:
		sound_behind("susurro", 1.5)
		return
	dist = clampf(dist, 4.0, 13.0)
	var side := dir.cross(Vector3.UP)
	var p := base + dir * dist
	p.y = player.global_position.y
	ghost.visible = true
	ghost.global_position = p - side * 2.0
	ghost.look_at(ghost.global_position + side, Vector3.UP)
	_ghost_move = side * 5.0
	_ghost_t = 0.9
	sound_at("crujido", p + Vector3(0, 1, 0), 0.0)
	sanity = maxf(0.0, sanity - 8.0)

func _ghost_update(delta: float) -> void:
	if _ghost_t > 0.0:
		_ghost_t -= delta
		ghost.global_position += _ghost_move * delta
		if _ghost_t <= 0.0:
			ghost.visible = false

func _hallucinations(delta: float) -> void:
	if sanity > 45.0:
		return
	_halluc_t -= delta
	if _halluc_t > 0.0:
		return
	_halluc_t = randf_range(10.0, 20.0) * (0.5 + sanity / 90.0)
	if randf() < 0.55:
		_glimpse(false)
	else:
		sound_behind("susurro", 0.8, 3.0)

# ---------------- sonido dinámico ----------------
func _update_audio(delta: float) -> void:
	var low := 1.0 - sanity / 100.0
	var hv := maxf(_danger, low * 0.6)
	snd_heart.volume_db = lerpf(snd_heart.volume_db, -60.0 if hv < 0.15 else linear_to_db(hv) + 1.0, delta * 3.0)
	snd_heart.pitch_scale = 0.9 + _danger * 0.6
	var breath := 0.0
	if player.running or player.stamina < player.stamina_max * 0.4:
		breath = 0.5
	if not hidden_in.is_empty() and _danger > 0.3:
		breath = 0.7
	snd_breath.volume_db = lerpf(snd_breath.volume_db, -60.0 if breath <= 0.0 else linear_to_db(breath) - 4.0, delta * 3.0)
	snd_drone.pitch_scale = 1.0 - low * 0.12
