class_name ZarekJuego
extends Node3D
## La Sombra de Zarek — Noche I (Aether Engine).
## Una noche corta (10-15 min): reunir los 4 objetos de la trampa en la
## mansión, sobrevivir a Elena y expulsar a Zarek con el ritual del Epicentro.

const SEALS_NEEDED := 4
const RITUAL_TIME := 10.0

var autotest := false
var shots := false
var mansion: ZarekMansion
var player: AetherPlayerFP
var elena: ZarekElena
var ghost: ZarekElena
var sustos: ZarekSustos
## Muebles que se pueden registrar y cosas que hacen ruido (ZarekRegistro).
var muebles_reg: Array = []
## Rejugabilidad: suceso de la noche, salas cerradas con llave y secretos (ZarekNoches, ZarekSecretos).
var suceso := "normal"
var salas_cerradas: Array = []
var llaves_salas: Array[String] = []
var secretos_noche: Array[String] = []
var luna: DirectionalLight3D
var _t_trueno := 20.0
var _trueno_tapa := 0.0
var snd_lluvia: AudioStreamPlayer
var archivo_box: Control
var tension: ZarekTension
var defensa: ZarekDefensa
var diario: ZarekDiario
var btn_diario: Button
var _reg_hold: Dictionary = {}
var _t_reg := 0.0
var _t_ruido_obj := {}
var touch: AetherTouchFP
var flash_node: Node3D
var flash: SpotLight3D
var env: Environment

var state := "titulo"
var lives := 3
var sanity := 100.0
var battery := 100.0
var salt := 2
var tablones := 0
## Dificultad: 0 fácil (5 vidas, más bengalas, él más lento), 1 normal, 2 pesadilla (1 vida, más rápido,
## no le asusta la luz y los objetos siempre cambian de sitio).
var dif := 1
var tiene_llaves := false
const FINALES := {"trampa": "La trampa", "verdadero": "La verdad de los Varela", "huida": "La huida", "oculto": "La hija de la roca"}
var _puerta_hold: Dictionary = {}
var _t_hold := 0.0
var seals := 0
var flash_on := true
var hidden_in: Dictionary = {}
var slit_cama: ColorRect
var barra_aliento: ProgressBar
## Aguantar la respiración escondida: aliento 1 = lleno. Si se acaba, Sofía jadea y él la oye.
var aliento := 1.0
var _aguantando := false
var _t_revisar := 0.0
var _t_oir_resp := 0.0
var _t_fono := 0.0
var _revisando: Dictionary = {}
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
var post_mat: ShaderMaterial
var llevado: RigidBody3D = null   # objeto que el jugador lleva en la mano
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
var _t_fps := 0.0
var _t_pez := 5.0

func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	set_process_unhandled_input(false)
	var args := OS.get_cmdline_user_args()
	if "--prueba" in args:
		autotest = true
	if "--capturas" in args:
		shots = true
	_inputs()
	# pantalla de carga: se ve desde el primer fotograma mientras se construye la mansión
	var carga := CanvasLayer.new()
	carga.layer = 100
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	carga.add_child(fondo)
	var lc := Label.new()
	lc.text = "LA SOMBRA DE ZAREK\n\nCargando…"
	lc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lc.set_anchors_preset(Control.PRESET_FULL_RECT)
	lc.add_theme_font_size_override("font_size", 34)
	lc.add_theme_color_override("font_color", Color(0.75, 0.68, 0.6))
	carga.add_child(lc)
	add_child(carga)
	# deja que la pantalla de carga llegue a verse antes de bloquear el hilo construyendo la casa
	for i in 4:
		await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	var t_carga := Time.get_ticks_msec()
	_environment()
	mansion = ZarekMansion.new()
	if not autotest and not shots:
		mansion.partida_seed = randi() % 2000000000 + 1
	add_child(mansion)
	# en el teléfono, densidad media de bosque y objetos (la alta va a tirones)
	await mansion.build_por_pasos(mini(Aether.quality, 1) if OS.get_name() == "Android" else Aether.quality,
		func(p: float): lc.text = "LA SOMBRA DE ZAREK\n\nCargando…  %d %%" % int(p * 90.0))
	mansion.bake_nav()
	lc.text = "LA SOMBRA DE ZAREK\n\nCargando…  95 %"
	await get_tree().process_frame
	# con la física ya en marcha, los objetos que quedaron en el aire bajan a su sitio
	await get_tree().physics_frame
	await get_tree().physics_frame
	mansion.asentar()
	await mansion.crear_impostores()
	for l in mansion.lamps:
		mansion.set_lamp(l, true)
	respawn_pos = mansion.cell_to_world("baja", 9.0, 11.2)
	player = AetherPlayerFP.new()
	add_child(player)
	player.collision_mask = 3 | 8  # suelo/paredes + puertas + objetos con física
	add_to_group("zarek_oyentes")
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
	var ex0 := mansion.cell_to_world("exterior", 0.0, 0.0)
	var ex1 := mansion.cell_to_world("exterior", 90.0, 104.0)
	var evitar: Array = []
	for z in mansion.plan.exterior.zonas:
		if not String(z[0]).begins_with("Bosque"):
			var a := mansion.cell_to_world("exterior", float(z[2]), float(z[3]))
			evitar.append(Rect2(a.x, a.z, float(z[4]) * ZarekMansion.CELL, float(z[5]) * ZarekMansion.CELL).grow(3.0))
	var hr: Rect2 = mansion.house_rect
	aves = ZarekAves.new()
	add_child(aves)
	aves.setup(player, self, mansion.cell_to_world("exterior", 79.0, 21.0), Rect2(ex0.x, ex0.z, ex1.x - ex0.x, ex1.z - ex0.z), evitar,
		Vector3(hr.get_center().x, 10.0, hr.get_center().y), mansion.cell_to_world("exterior", 36.5, 19.5), mansion.cell_to_world("exterior", 44.0, 43.0))
	ghost = ZarekElena.new()
	ghost.only_visual = true
	add_child(ghost)
	ghost.visible = false
	muebles_reg = ZarekRegistro.preparar(mansion)
	suceso = ZarekNoches.elegir_suceso(mansion.partida_seed)
	salas_cerradas = ZarekNoches.preparar(mansion, muebles_reg, mansion.partida_seed, 2, 6 if suceso == "luna_roja" else 4)
	defensa = ZarekDefensa.new()
	defensa.j = self
	add_child(defensa)
	defensa.preparar(mansion, muebles_reg, mansion.partida_seed)
	tension = ZarekTension.new()
	tension.j = self
	tension.activo = not autotest
	add_child(tension)
	sustos = ZarekSustos.new()
	add_child(sustos)
	sustos.setup(self)
	_audio()
	_ui()
	touch = AetherTouchFP.new()
	touch.player = player
	touch.buttons = [
		["usar", "USAR", Vector2(-150, -175), 86.0],
		["linterna", "LUZ", Vector2(-330, -115), 62.0],
		["sal", "BENGALA", Vector2(-300, -290), 58.0],
		["agachar", "AGACHAR", Vector2(-120, -330), 58.0],
		["disparar", "DISPARAR", Vector2(-470, -150), 60.0],
	]
	add_child(touch)
	carga.queue_free()
	print("ZAREK CARGA %d ms (calidad %d, %s, %s)" % [Time.get_ticks_msec() - t_carga, Aether.quality, OS.get_name(), RenderingServer.get_current_rendering_method()])
	set_process(true)
	_poblar_fauna()
	set_physics_process(true)
	set_process_input(true)
	set_process_unhandled_input(true)
	if autotest or shots:
		start_game(true)
	else:
		_show_title()

# ---------------- preparación ----------------
func _inputs() -> void:
	var map := {"usar": [KEY_E, KEY_ENTER], "linterna": [KEY_F], "sal": [KEY_Q], "pausa": [KEY_ESCAPE, KEY_P], "agachar": [KEY_C, KEY_CTRL], "disparar": [KEY_R], "diario": [KEY_TAB, KEY_M]}
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
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.65
	env.tonemap_white = 10.0
	env.fog_enabled = true
	env.fog_light_color = Color(0.07, 0.065, 0.07)
	env.fog_density = 0.016
	env.fog_sky_affect = 0.0
	env.glow_enabled = Aether.glow_ok() and OS.get_name() != "Android"
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
	# gráficos altos (renderizador Forward+ en móviles potentes y ordenador): sombras de contacto (SSAO),
	# reflejos en pantalla (agua, suelos encerados), luz indirecta en pantalla y niebla volumétrica con haces
	# de luz de la luna y de la linterna
	var fplus := RenderingServer.get_current_rendering_method() == "forward_plus"
	if fplus:
		env.tonemap_mode = Environment.TONE_MAPPER_AGX
		env.tonemap_exposure = 1.7
		env.ssao_enabled = true
		env.ssao_radius = 1.4
		env.ssao_intensity = 2.2
		env.ssao_power = 1.6
		env.ssil_enabled = OS.get_name() != "Android"
		env.ssil_intensity = 0.8
		env.ssr_enabled = true
		env.ssr_max_steps = 48
		env.ssr_fade_in = 0.1
		env.ssr_fade_out = 2.5
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.018
		env.volumetric_fog_albedo = Color(0.55, 0.6, 0.68)
		env.volumetric_fog_emission = Color(0.0, 0.0, 0.0)
		env.volumetric_fog_anisotropy = 0.55
		env.volumetric_fog_length = 48.0
		env.volumetric_fog_detail_spread = 2.0
		env.volumetric_fog_ambient_inject = 0.15
		env.fog_density = 0.008
	we.environment = env
	add_child(we)
	var moon := DirectionalLight3D.new()
	luna = moon
	moon.light_color = Color(0.55, 0.65, 0.95)
	moon.light_energy = 0.45
	moon.rotation_degrees = Vector3(-38, -55, 0)
	# en el teléfono la luna no proyecta sombras (cuesta un pase entero); las da la linterna, que es lo que da miedo
	moon.shadow_enabled = OS.get_name() != "Android"
	moon.directional_shadow_max_distance = 32.0 if OS.get_name() == "Android" else 60.0
	moon.shadow_bias = 0.06
	moon.shadow_normal_bias = 2.5
	moon.shadow_caster_mask = 0xFFFFF & ~2
	# en el teléfono, dos cascadas en vez de cuatro (cada cascada vuelve a dibujar todo lo que hace sombra)
	if OS.get_name() == "Android":
		moon.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(moon)

var flash_foco: SpotLight3D
var _rebote: OmniLight3D
var _polvo: GPUParticles3D
## Linterna de bombilla con reflector (años 70): dos luces como una linterna de verdad: el FOCO, un cono estrecho
## con el centro brillante y las sombras; y el HALO, el cono ancho y tenue de la luz que se escapa por los lados
## (sin sombras: así las sombras solo se calculan en el cono estrecho y el teléfono va mucho más ligero).
## (Se probó una textura proyectada con los anillos del reflector, pero no es fiable en todos los móviles.)
## Además: luz que rebota en lo que alumbras (la pared ilumina un poco la sala) y polvo flotando en el haz.
func _flashlight() -> void:
	flash_node = Node3D.new()
	add_child(flash_node)
	flash = SpotLight3D.new()
	flash.light_color = Color(1.0, 0.88, 0.7)
	flash.light_energy = 6.0
	flash.spot_range = 32.0
	flash.spot_angle = 40.0
	flash.spot_angle_attenuation = 1.4
	flash.spot_attenuation = 0.55
	flash.shadow_enabled = false
	flash.light_specular = 0.35
	flash_node.add_child(flash)
	flash_foco = SpotLight3D.new()
	flash_foco.name = "foco"
	flash_foco.light_color = flash.light_color
	flash_foco.light_energy = 6.0
	flash_foco.spot_range = 32.0
	flash_foco.spot_angle = 22.0
	flash_foco.spot_angle_attenuation = 1.1
	flash_foco.spot_attenuation = 0.55
	flash_foco.shadow_enabled = true
	flash_foco.shadow_bias = 0.04
	flash_foco.shadow_blur = 1.6
	flash_node.add_child(flash_foco)
	# halo cercano muy suave (la mano y lo que tienes delante)
	var near := OmniLight3D.new()
	near.light_color = Color(1.0, 0.88, 0.7)
	near.omni_range = 3.0
	near.light_energy = 0.45
	near.name = "cerca"
	flash_node.add_child(near)
	# la mano de Sofía con la linterna (brazos «FREE FPS Arms with glove» y «Retro Style Flashlight», CC-BY):
	# el modelo tiene el origen en el cristal y el haz hacia +Z; va en la capa 20 para que no haga sombra
	var ps: PackedScene = load("res://zarek/modelos/sofia_mano.glb")
	if ps:
		mano_fp = ps.instantiate()
		# la linterna apunta al frente; el brazo baja hacia la esquina de abajo a la derecha
		mano_fp.rotation = Vector3(-0.5, PI - 0.1, 0.3)
		flash_node.add_child(mano_fp)
		for g in mano_fp.find_children("*", "GeometryInstance3D", true, false):
			(g as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			(g as GeometryInstance3D).layers = 1 << 19
		# un poco de luz solo para la mano: que se vea aunque la casa esté a oscuras
		var lm := OmniLight3D.new()
		lm.light_cull_mask = 1 << 19
		lm.omni_range = 0.9
		lm.light_energy = 0.7
		lm.light_color = Color(1.0, 0.86, 0.7)
		lm.position = Vector3(-0.15, 0.2, 0.15)
		lm.light_specular = 0.2
		mano_fp.add_child(lm)
	# luz que rebota: un poco de luz cálida sale de donde da el haz y alumbra lo de alrededor
	_rebote = OmniLight3D.new()
	_rebote.light_color = Color(1.0, 0.85, 0.68)
	_rebote.omni_range = 5.0
	_rebote.omni_attenuation = 1.6
	_rebote.light_energy = 0.0
	_rebote.light_specular = 0.0
	add_child(_rebote)
	# polvo en el aire: motas que solo se ven donde las alumbra la linterna
	_polvo = GPUParticles3D.new()
	_polvo.amount = 70 if OS.get_name() == "Android" else 140
	_polvo.lifetime = 9.0
	_polvo.preprocess = 9.0
	_polvo.local_coords = false
	_polvo.visibility_aabb = AABB(Vector3(-3, -3, -6), Vector3(6, 6, 7))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(1.6, 1.2, 2.2)
	pm.gravity = Vector3(0, -0.006, 0)
	pm.initial_velocity_min = 0.0
	pm.initial_velocity_max = 0.03
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.05
	pm.turbulence_noise_scale = 1.5
	pm.turbulence_influence_min = 0.02
	pm.turbulence_influence_max = 0.06
	pm.scale_min = 0.5
	pm.scale_max = 1.3
	var curva := Curve.new()
	curva.add_point(Vector2(0, 0)); curva.add_point(Vector2(0.15, 1)); curva.add_point(Vector2(0.85, 1)); curva.add_point(Vector2(1, 0))
	var ct := CurveTexture.new()
	ct.curve = curva
	pm.scale_curve = ct
	_polvo.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.006, 0.006)
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color(0.9, 0.85, 0.75, 0.75)
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mm.roughness = 1.0
	mm.metallic_specular = 0.0
	mm.disable_receive_shadows = true
	q.material = mm
	_polvo.draw_pass_1 = q
	_polvo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_polvo)

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
	snd_breath = _player_snd(AetherSynth.make("aliento"), -60.0, true)
	_musica_a = _player_snd(null, -60.0)
	_musica_b = _player_snd(null, -60.0)
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

func _s(kind: String) -> AudioStream:
	# sonidos reales con variantes al azar (zarek/sonidos); si no hay, los hechos por código
	if ZarekSonido.hay(kind):
		return ZarekSonido.uno(kind)
	if not _cache.has(kind):
		_cache[kind] = AetherSynth.make(kind)
	return _cache[kind]

## Sonido en un punto del espacio (golpes detrás de una pared, susurros…).
func sound_at(kind: String, pos: Vector3, db := 0.0) -> void:
	if fauna and kind in ["portazo", "golpes", "golpe_madera", "campana", "piano"]:
		fauna.ruido(pos, 1.0 if db > -6.0 else 0.6)
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

var lbl_fps: Label
## Resolución adaptable (en el teléfono): si los fps bajan de 52 se dibuja el 3D un poco más pequeño;
## si van sobrados un rato, se recupera. Un juego de terror a tirones no da miedo.
var _escala_base := 0.0
var _t_escala := 0.0
var _fps_acum := 0.0
var _fps_n := 0
var _fps_bien := 0.0
func _escala_adaptable(delta: float) -> void:
	if _escala_base <= 0.0 or not (state in ["juego", "escondido", "ritual"]):
		return
	_fps_acum += 1.0 / maxf(delta, 0.001)
	_fps_n += 1
	_t_escala += delta
	if _t_escala < 2.0:
		return
	var fps := _fps_acum / float(_fps_n)
	_t_escala = 0.0
	_fps_acum = 0.0
	_fps_n = 0
	var vp := get_viewport()
	if fps < 52.0 and vp.scaling_3d_scale > 0.5:
		vp.scaling_3d_scale = maxf(0.5, vp.scaling_3d_scale - 0.05)
		_fps_bien = 0.0
		print("ZAREK escala 3D %.2f (fps %d)" % [vp.scaling_3d_scale, int(fps)])
	elif fps > 58.0:
		_fps_bien += 2.0
		if _fps_bien >= 8.0 and vp.scaling_3d_scale < _escala_base - 0.01:
			vp.scaling_3d_scale = minf(_escala_base, vp.scaling_3d_scale + 0.05)
			_fps_bien = 0.0
	else:
		_fps_bien = 0.0
func _ui() -> void:
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	if OS.get_name() == "Android":
		Engine.max_fps = 60
		# resolución 3D por altura de pantalla: ~720 líneas (el S23 Ultra tiene 1440: dibujar a 965 era un 80 %
		# más de píxeles); la interfaz sigue a resolución completa
		var alto := float(DisplayServer.screen_get_size().y)
		var ancho := float(DisplayServer.screen_get_size().x)
		var lado_corto := minf(alto, ancho)
		if lado_corto > 0.0:
			get_viewport().scaling_3d_scale = clampf(720.0 / lado_corto, 0.45, 0.8)
			_escala_base = get_viewport().scaling_3d_scale
	# contador de fps (arriba a la izquierda, pequeño): para medir en el teléfono de verdad
	var capa_fps := CanvasLayer.new()
	capa_fps.layer = 90
	add_child(capa_fps)
	lbl_fps = Label.new()
	lbl_fps.position = Vector2(14, 8)
	lbl_fps.add_theme_font_size_override("font_size", 18)
	lbl_fps.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6, 0.8))
	lbl_fps.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lbl_fps.add_theme_constant_override("outline_size", 4)
	lbl_fps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa_fps.add_child(lbl_fps)
	# 2× MSAA: bordes limpios y agujas de los abetos sin dientes (barato en GPU móviles de teselas)
	# en el teléfono, suavizado FXAA (barato) en vez de MSAA: con tantas hojas recortadas el MSAA cuesta mucho
	if OS.get_name() == "Android":
		get_viewport().msaa_3d = Viewport.MSAA_DISABLED
		get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	else:
		get_viewport().msaa_3d = Viewport.MSAA_2X
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
	post_mat = pm
	if OS.get_name() == "Android":
		pm.set_shader_parameter("brillo", 1.35)
		pm.set_shader_parameter("vineta", 0.38)
		pm.set_shader_parameter("contraste", 1.08)
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
	# debajo de la cama: el somier tapa la parte de arriba; solo se ve una franja a ras de suelo
	slit_cama = ColorRect.new()
	slit_cama.color = Color(0.02, 0.015, 0.01, 0.98)
	slit_cama.anchor_right = 1.0
	slit_cama.anchor_bottom = 0.58
	slit_cama.visible = false
	ui.add_child(slit_cama)
	barra_aliento = ProgressBar.new()
	barra_aliento.show_percentage = false
	barra_aliento.max_value = 1.0
	barra_aliento.anchor_left = 0.35
	barra_aliento.anchor_right = 0.65
	barra_aliento.anchor_top = 0.82
	barra_aliento.anchor_bottom = 0.84
	var fg := StyleBoxFlat.new()
	fg.bg_color = Color(0.75, 0.82, 0.9, 0.85)
	var bgs := StyleBoxFlat.new()
	bgs.bg_color = Color(0, 0, 0, 0.5)
	barra_aliento.add_theme_stylebox_override("fill", fg)
	barra_aliento.add_theme_stylebox_override("background", bgs)
	barra_aliento.visible = false
	ui.add_child(barra_aliento)
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
	title_box = _menu_box(["LA SOMBRA DE ZAREK", _resumen_titulo()], [["JUGAR", _jugar.bind(1)], ["FÁCIL", _jugar.bind(0)], ["PESADILLA", _jugar.bind(2)], ["ARCHIVO", _abrir_archivo]], "Usa auriculares. Juega a oscuras.")
	# en el título se ve la mansión detrás: fondo más claro y botones más compactos
	(title_box.get_child(0) as ColorRect).color = Color(0, 0, 0, 0.5)
	var vbt := title_box.get_child(1) as VBoxContainer
	vbt.add_theme_constant_override("separation", 9)
	for b in vbt.get_children():
		if b is Button:
			(b as Button).custom_minimum_size = Vector2(300, 52)
	end_box = _menu_box(["", ""], [["JUGAR DE NUEVO", _restart], ["MENÚ", _to_title]], "")
	lbl_end_t = end_box.get_meta("t")
	lbl_end_s = end_box.get_meta("s")
	pause_box = _menu_box(["PAUSA", ""], [["CONTINUAR", _resume], ["DIARIO Y MAPA", func():
		pause_box.visible = false
		diario.abrir()], ["REINICIAR", _restart]], "")
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
	# el diario: objetivos, pistas y mapa (pausa el juego)
	diario = ZarekDiario.new()
	diario.j = self
	ui.add_child(diario)
	btn_diario = Button.new()
	btn_diario.text = "DIARIO"
	btn_diario.add_theme_font_size_override("font_size", 22)
	btn_diario.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7, 0.8))
	var sbd := StyleBoxFlat.new()
	sbd.bg_color = Color(0.1, 0.06, 0.03, 0.55)
	sbd.border_color = Color(0.6, 0.45, 0.25, 0.7)
	sbd.set_border_width_all(2)
	sbd.set_corner_radius_all(6)
	btn_diario.add_theme_stylebox_override("normal", sbd)
	btn_diario.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn_diario.position = Vector2(-240, 14)
	btn_diario.size = Vector2(140, 52)
	btn_diario.pressed.connect(func(): diario.abrir())
	ui.add_child(btn_diario)
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
	if btn_diario:
		btn_diario.visible = v
	top.visible = v
	lbl_obj.visible = v
	lbl_prompt.visible = v
	touch.visible = v

var _t_titulo := 0.0
func _show_title() -> void:
	state = "titulo"
	_hud_visible(false)
	title_box.visible = true
	player.frozen = true
	_black_target = 0.25
	# de fondo, la mansión de noche vista desde el camino, con la cámara moviéndose muy despacio
	player.global_position = mansion.cell_to_world("exterior", 44.0, 63.0)
	player.velocity = Vector3.ZERO
	flash.visible = true

func message(text: String, sec := 4.0) -> void:
	lbl_msg.text = text
	lbl_msg.modulate.a = 1.0
	_msg_t = sec

func _update_hud() -> void:
	lbl_lives.text = "♥ ".repeat(lives).strip_edges()
	bar_san.value = sanity
	bar_bat.value = battery
	lbl_salt.text = "Bengalas: %d   Tablones: %d   Trampa: %d/%d   Secretos: %d/%d" % [salt, tablones, seals, SEALS_NEEDED, ZarekSecretos.cuantos(), ZarekSecretos.TOTAL]
	if not llaves_salas.is_empty():
		lbl_salt.text += "\nLlaves: " + ", ".join(llaves_salas)
	if defensa:
		var dfn: Array[String] = []
		if defensa.arma != "":
			dfn.append(String(ZarekDefensa.ARMAS[defensa.arma].nombre).capitalize())
		if defensa.cepos > 0:
			dfn.append("Trampas: %d" % defensa.cepos)
		if defensa.escopeta:
			dfn.append("Escopeta (%d)" % defensa.cartuchos)
		if not dfn.is_empty():
			lbl_salt.text += "\nDefensa: " + " · ".join(dfn)
		touch.set_visible_button("disparar", defensa.escopeta and defensa.cartuchos > 0 and state == "juego")
	if not entered:
		var dist := int(player.global_position.distance_to(mansion.front_door))
		lbl_obj.text = "Llega a la mansión Varela (%d m)" % dist
	elif seals < SEALS_NEEDED:
		var near := _nearest_seal()
		var where := ""
		if not near.is_empty() and diario:
			where = "\n%s: %s" % [ZarekDiario.nombre_objeto(near).capitalize(), diario.pista(near).replace("[b]", "").replace("[/b]", "")]
		lbl_obj.text = "Reúne lo necesario para la trampa (%d/%d) · DIARIO: pistas y mapa%s" % [seals, SEALS_NEEDED, where]
	elif state == "ritual" or ritual > 0.0:
		lbl_obj.text = "Prepara la trampa junto a su colchón"
	else:
		lbl_obj.text = "Ve al cuarto de Damián y prepara la trampa junto a su colchón"

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
func _resumen_titulo() -> String:
	var hechos: Array = Aether.save.get_value("zarek_finales", [])
	var t := "Noche I · La casa Varela\nEsta noche: " + String(ZarekNoches.SUCESOS[suceso][0]).substr(0, 1) + String(ZarekNoches.SUCESOS[suceso][0]).substr(1).to_lower()
	t += "\nSecretos de la familia: %d/%d" % [ZarekSecretos.cuantos(), ZarekSecretos.TOTAL]
	if not hechos.is_empty():
		t += "\nFinales: %d/%d" % [hechos.size(), FINALES.size()]
		var mejor: float = Aether.save.get_value("zarek_mejor", 0.0)
		if mejor > 0.0:
			t += " · Mejor tiempo: " + _fmt(mejor)
		var rg := String(Aether.save.get_value("zarek_rango", ""))
		if rg != "":
			t += " · Mejor rango: " + rg
	return t

func _jugar(d: int) -> void:
	dif = d
	lives = [5, 3, 1][d]
	salt = [3, 2, 1][d]
	elena.rapidez = [0.85, 1.0, 1.15][d]
	if d == 2:
		elena.aggro = 2
	start_game(false)

func _final(clave: String) -> void:
	var hechos: Array = Aether.save.get_value("zarek_finales", [])
	if not clave in hechos:
		hechos.append(clave)
		Aether.save.set_value("zarek_finales", hechos)
	if clave != "huida":
		var mejor: float = Aether.save.get_value("zarek_mejor", 0.0)
		if mejor <= 0.0 or play_time < mejor:
			Aether.save.set_value("zarek_mejor", play_time)

## Final de la huida: con las llaves, al coche. Sofía se salva… y deja a todos los demás atrás.
func _huida() -> void:
	state = "final"
	player.frozen = true
	elena.can_catch = false
	elena.vanish(999.0)
	sound_at("coche_puerta" if ZarekSonido.hay("coche_puerta") else "golpe_madera", mansion.car_pos + Vector3(0, 1, 0), 0.0)
	_black_target = 1.0
	await get_tree().create_timer(1.4).timeout
	message("El motor tosió… y arrancó.\nNo miré atrás. Ni siquiera cuando la oí gritar mi nombre desde el sótano.", 5.0)
	await get_tree().create_timer(5.2).timeout
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hud_visible(false)
	lbl_end_t.text = "FINAL: LA HUIDA"
	lbl_end_s.text = "Tiempo: %s\nUna semana después, otra carta salió de la mansión Varela.\nIba dirigida a alguien que no sabe nada. (Final %d/%d)" % [_fmt(play_time), Aether.save.get_value("zarek_finales", []).size() + (0 if "huida" in Aether.save.get_value("zarek_finales", []) else 1), FINALES.size()]
	end_box.visible = true
	_final("huida")

func start_game(quick := false) -> void:
	title_box.visible = false
	_hud_visible(true)
	state = "intro"
	player.frozen = true
	flash_on = true
	if not quick and not autotest and not shots:
		player.global_position = mansion.start_pos
		player.velocity = Vector3.ZERO
		player.set_look(0.0, 0.0)
	if quick:
		state = "juego"
		player.frozen = false
		_black_target = 0.0
		black.color.a = 0.0
		_empezar_suceso()
		return
	if not DisplayServer.is_touchscreen_available():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_black_target = 1.0
	await get_tree().create_timer(0.6).timeout
	var lines := [
		"Me llamo Sofía. Hace una semana me llegó una carta:\nsoy la última heredera de los Varela.",
		"Tenía que firmar el inventario de la finca, en el bosque de Valdeoscuro.\nA las 3:00 el coche se apagó en medio del camino.",
		"Desde 1988 han desaparecido 43 personas en este bosque.\nNunca encontraron ningún cuerpo.",
	]
	for l in lines:
		message(l, 3.6)
		await get_tree().create_timer(3.9).timeout
	_black_target = 0.0
	message("", 0.1)
	await get_tree().create_timer(1.2).timeout
	state = "juego"
	player.frozen = false
	_empezar_suceso()
	await get_tree().create_timer(0.6).timeout
	var sc: Array = ZarekNoches.SUCESOS[suceso]
	message(String(sc[0]) + "\n" + String(sc[1]), 4.5)
	await get_tree().create_timer(4.8).timeout
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

## Ruidos del mundo (botellas rotas, muebles que caen): Elena los oye si está cerca.
func oir_ruido(pos: Vector3, fuerza: float) -> void:
	if elena:
		elena.hear(pos, fuerza)

var _pos_segura := Vector3.ZERO
var _t_segura := 0.0
func _physics_process(_delta: float) -> void:
	# red de seguridad: si por cualquier hueco el jugador cae al vacío, vuelve al último sitio firme
	if player and state in ["juego", "ritual", "intro"]:
		_t_segura += _delta
		if player.is_on_floor() and _t_segura > 0.5:
			_t_segura = 0.0
			_pos_segura = player.global_position
		if player.global_position.y < -12.0:
			# caída al barranco: golpe de miedo y vuelta al último sitio firme (un poco hacia dentro)
			var vuelta := _pos_segura if _pos_segura != Vector3.ZERO else respawn_pos
			var centro := Vector3(mansion.bosque_rect.get_center().x, vuelta.y, mansion.bosque_rect.get_center().y)
			player.global_position = vuelta + (centro - vuelta).normalized() * 3.0
			player.velocity = Vector3.ZERO
			sanity = maxf(0.0, sanity - 25.0)
			message("Caíste al barranco… algo te devolvió arriba.", 3.0)
	# el objeto cogido sigue a la mano (delante de la cámara) con física: choca, se frena y puede caerse
	if is_instance_valid(llevado):
		var cam := player.camera
		var meta := cam.global_position - cam.global_transform.basis.z * 1.0 - cam.global_transform.basis.y * 0.2
		var dif := meta - llevado.global_position
		if dif.length() > 2.0 or not hidden_in.is_empty():
			llevado.gravity_scale = 1.0
			llevado.angular_damp = 0.0
			player.remove_collision_exception_with(llevado)
			llevado = null
		else:
			llevado.linear_velocity = dif * 14.0 / maxf(1.0, llevado.mass * 0.15)
	if player == null:
		return
	# el jugador empuja lo que toca
	for i in player.get_slide_collision_count():
		var col := player.get_slide_collision(i)
		var rb := col.get_collider() as RigidBody3D
		if rb and not rb.freeze:
			var empuje := -col.get_normal()
			empuje.y = 0.0
			rb.apply_impulse(empuje.normalized() * clampf(4.5 / maxf(rb.mass, 0.5), 0.15, 2.2) * rb.mass * 0.35, col.get_position() - rb.global_position)
	# Elena, al correr, arrolla sillas y botellas
	if elena and elena.visible and elena.state == ZarekElena.S.CHASE:
		var sq := PhysicsShapeQueryParameters3D.new()
		var esf := SphereShape3D.new()
		esf.radius = 0.55
		sq.shape = esf
		sq.transform = Transform3D(Basis(), elena.global_position + Vector3(0, 0.6, 0))
		sq.collision_mask = 8
		for h in get_world_3d().direct_space_state.intersect_shape(sq, 8):
			var b := h.collider as RigidBody3D
			if b and not b.freeze:
				var dir := (b.global_position - elena.global_position)
				dir.y = 0.0
				b.apply_central_impulse((dir.normalized() * 3.0 + Vector3(0, 1.0, 0)) * b.mass * 0.6)

## Sombras solo en las bombillas más cercanas al jugador (las demás iluminan sin sombra): así cada sala tiene
## sombras de verdad sin el coste de decenas de luces con sombra.
var _t_sombras := 0.0
var _con_sombra: Array = []
var fauna: ZarekFauna
## Ratas, gusanos y el gato negro: se crean cuando el mapa de navegación está listo.
func _poblar_fauna() -> void:
	for k in 600:
		if mansion.nav_ready:
			break
		await get_tree().process_frame
	# el mapa de navegación tiene que haberse sincronizado al menos una vez antes de consultarlo
	var mapa := mansion.get_world_3d().navigation_map
	for k in 300:
		if NavigationServer3D.map_get_iteration_id(mapa) > 0:
			break
		await get_tree().physics_frame
	fauna = ZarekFauna.new()
	add_child(fauna)
	fauna.poblar(mansion, self)

func _sombras_cercanas(delta: float) -> void:
	_t_sombras -= delta
	if _t_sombras > 0.0 or player == null:
		return
	_t_sombras = 0.3
	var n := 1 if OS.get_name() == "Android" else 3
	var pp := player.global_position
	var cerca: Array = []
	for l in mansion.lamps:
		if l.on and not l.broken and absf(float(l.pos.y) - pp.y) < 2.5:
			var d := Vector2(pp.x - l.pos.x, pp.z - l.pos.z).length()
			if d < 11.0:
				cerca.append([d, l.light])
	cerca.sort_custom(func(a, b): return a[0] < b[0])
	var nuevas: Array = []
	for i in mini(n, cerca.size()):
		nuevas.append(cerca[i][1])
	for li in _con_sombra:
		if is_instance_valid(li) and not li in nuevas:
			(li as OmniLight3D).shadow_enabled = false
	for li in nuevas:
		(li as OmniLight3D).shadow_enabled = true
		(li as OmniLight3D).shadow_bias = 0.06
		if OS.get_name() == "Android":
			# dos pasadas de sombra en vez de seis (cubo)
			(li as OmniLight3D).omni_shadow_mode = OmniLight3D.SHADOW_DUAL_PARABOLOID
	_con_sombra = nuevas

func _process(delta: float) -> void:
	_sombras_cercanas(delta)
	# fundido negro y mensajes
	black.color.a = move_toward(black.color.a, _black_target, delta * 1.2)
	if _msg_t > 0.0:
		_msg_t -= delta
		if _msg_t < 0.8:
			lbl_msg.modulate.a = maxf(0.0, _msg_t / 0.8)
	vig_mat.set_shader_parameter("t", fmod(Time.get_ticks_msec() / 1000.0, 100.0))
	# medición de rendimiento en el registro (logcat en Android): fps, llamadas de dibujo y triángulos
	_t_fps += delta
	if lbl_fps and Engine.get_process_frames() % 15 == 0:
		# fps · tiempo del procesador y de la gráfica por fotograma · llamadas de dibujo: dice qué frena
		var vp := get_viewport().get_viewport_rid()
		lbl_fps.text = "%d FPS · CPU %.1f · GPU %.1f ms · %d dib" % [Engine.get_frames_per_second(),
			RenderingServer.viewport_get_measured_render_time_cpu(vp) + RenderingServer.get_frame_setup_time_cpu(),
			RenderingServer.viewport_get_measured_render_time_gpu(vp),
			int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))]
	if _t_fps >= 5.0:
		_t_fps = 0.0
		print("ZAREK FPS %d draws %d prims %d mem %d MB estado %s pos %s" % [Engine.get_frames_per_second(),
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
			int(Performance.get_monitor(Performance.MEMORY_STATIC) / 1e6), state, player.global_position.snapped(Vector3.ONE) if player else Vector3.ZERO])
	_eventos_sala(delta)
	_escala_adaptable(delta)
	if defensa:
		defensa.tick(delta)
	if state == "titulo" and player:
		_t_titulo += delta
		player.set_look(sin(_t_titulo * 0.07) * 0.12, 0.13 + sin(_t_titulo * 0.05) * 0.03)
	# de vez en cuando salta un pez en el río si el jugador anda cerca
	if mansion and player and mansion.rio_rect.size != Vector2.ZERO:
		_t_pez -= delta
		var dz := absf(player.global_position.z - mansion.rio_rect.get_center().y)
		if _t_pez <= 0.0 and dz < 22.0 and player.global_position.y > -1.0:
			_t_pez = randf_range(6.0, 15.0)
			mansion.salto_pez(player.global_position)
	# la linterna solo calcula sombras de lo que está del mismo lado de las paredes que el jugador
	if flash and player:
		var en_casa := mansion.house_rect.grow(0.3).has_point(Vector2(player.global_position.x, player.global_position.z))
		flash_foco.shadow_caster_mask = (0xFFFFF & ~4) if en_casa else (0xFFFFF & ~2)
		if _polvo:
			_polvo.emitting = en_casa
			_polvo.visible = en_casa or _polvo.emitting
	_update_flash(delta)
	_update_niebla(delta)
	_update_viento(delta)
	if state in ["juego", "escondido", "ritual"]:
		_play(delta)
		_suceso_tick(delta)
		tension.tick(delta)
		_consejos_tick(delta)
	_update_hud()
	_update_audio(delta)

var niebla: ZarekNiebla
var aves: ZarekAves
var _fuera := 1.0
## Fuera de la casa: niebla espesa azulada de luna, más densa a ras de suelo, y bancos de niebla que se mueven.
## Dentro: la niebla fina de siempre. Se pasa de una a otra poco a poco al cruzar la puerta.
func _update_niebla(delta: float) -> void:
	if env == null or player == null:
		return
	var dentro := mansion != null and mansion.inside_house(player.global_position)
	_fuera = move_toward(_fuera, 0.0 if dentro else 1.0, delta * 0.5)
	# cerca de los límites del bosque la niebla se espesa (montañas y barranco se pierden en ella)
	var borde := 1.0
	if mansion and mansion.bosque_rect.get_area() > 0.0:
		var p2 := Vector2(player.global_position.x, player.global_position.z)
		var F: Rect2 = mansion.bosque_rect
		var d := minf(minf(p2.x - F.position.x, F.end.x - p2.x), minf(p2.y - F.position.y, F.end.y - p2.y))
		borde = 1.0 + (1.0 - clampf(d / 40.0, 0.0, 1.0)) * 1.4
	env.fog_density = lerpf(0.016, 0.05 * borde, _fuera)
	# dentro de la casa la luz de ambiente baja mucho: lo que alumbra son las lámparas (charcos de luz cálida)
	# y la linterna; los rincones quedan en penumbra. Fuera manda la luna.
	env.ambient_light_energy = lerpf(0.32, 0.85, _fuera)
	env.ambient_light_color = Color(0.3, 0.29, 0.33).lerp(Color(0.42, 0.38, 0.34), _fuera)
	env.fog_light_color = Color(0.07, 0.065, 0.07).lerp(Color(0.12, 0.135, 0.18), _fuera)
	env.fog_height = 1.4
	env.fog_height_density = lerpf(0.0, 0.32, _fuera)
	env.fog_sky_affect = lerpf(0.0, 0.85, _fuera)
	if env.volumetric_fog_enabled:
		# con niebla volumética la de profundidad es más fina (si no, se suman y todo queda gris)
		env.volumetric_fog_density = lerpf(0.008, 0.03, _fuera)
		env.fog_density = lerpf(0.005, 0.022, _fuera)
		env.fog_height_density = lerpf(0.0, 0.18, _fuera)
	if suceso == "niebla":
		# la niebla ha entrado en la casa: dentro casi tan espesa como fuera
		env.fog_density = maxf(env.fog_density, lerpf(0.075, 0.05, _fuera))
		env.fog_light_color = Color(0.12, 0.12, 0.13)
		env.fog_height_density = maxf(env.fog_height_density, 0.2)
	if niebla == null:
		niebla = ZarekNiebla.new()
		add_child(niebla)
		niebla.objetivo = player
	niebla.fuerza = _fuera

## Viento: brisa constante que cambia de dirección poco a poco y rachas cada 6-18 s que doblan los árboles,
## suben el sonido del viento, arrastran hojas secas y a veces hacen crujir un tronco cercano.
var _viento_dir := 0.6
var _racha := 0.0
var _racha_obj := 0.0
var _t_racha := 5.0
var hojas_caen: CPUParticles3D
func _update_viento(delta: float) -> void:
	_viento_dir += sin(Time.get_ticks_msec() / 23000.0) * delta * 0.05
	_t_racha -= delta
	if _t_racha <= 0.0:
		if _racha_obj > 0.1:
			_racha_obj = 0.0
			_t_racha = randf_range(6.0, 18.0)
		else:
			_racha_obj = randf_range(0.5, 1.0)
			_t_racha = randf_range(2.5, 5.0)
			if _fuera > 0.5 and randf() < 0.5 and player:
				var lado := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
				sound_at("crujido", player.global_position + lado * randf_range(6.0, 12.0) + Vector3(0, 4, 0), -6.0)
	_racha = move_toward(_racha, _racha_obj, delta * (0.45 if _racha_obj > _racha else 0.25))
	var d := Vector2(cos(_viento_dir), sin(_viento_dir))
	var fuerza := 0.35 + 0.1 * sin(Time.get_ticks_msec() / 7000.0)
	RenderingServer.global_shader_parameter_set("viento", Vector4(d.x, d.y, fuerza, _racha))
	if snd_wind:
		snd_wind.volume_db = lerpf(-30.0, lerpf(-16.0, -6.0, _racha), _fuera)
		snd_wind.pitch_scale = 0.9 + _racha * 0.25
	# hojas secas arrastradas por el viento alrededor del jugador (solo fuera)
	if hojas_caen == null and player:
		hojas_caen = CPUParticles3D.new()
		hojas_caen.top_level = true
		hojas_caen.amount = 70
		hojas_caen.lifetime = 8.0
		hojas_caen.preprocess = 8.0
		hojas_caen.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		hojas_caen.emission_box_extents = Vector3(16, 2, 16)
		hojas_caen.direction = Vector3(0, -1, 0)
		hojas_caen.spread = 30.0
		hojas_caen.initial_velocity_min = 0.2
		hojas_caen.initial_velocity_max = 0.6
		hojas_caen.angle_min = 0.0
		hojas_caen.angle_max = 360.0
		hojas_caen.angular_velocity_min = -220.0
		hojas_caen.angular_velocity_max = 220.0
		hojas_caen.scale_amount_min = 0.6
		hojas_caen.scale_amount_max = 1.2
		var q := QuadMesh.new()
		q.size = Vector2(0.07, 0.05)
		var m := StandardMaterial3D.new()
		m.albedo_texture = _textura_hoja()
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.4
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.albedo_color = Color(0.55, 0.42, 0.3)
		q.material = m
		hojas_caen.mesh = q
		add_child(hojas_caen)
	if hojas_caen:
		hojas_caen.global_position = player.global_position + Vector3(0, 6.0, 0)
		hojas_caen.emitting = _fuera > 0.5
		hojas_caen.visible = _fuera > 0.1
		var arrastre := (1.2 + _racha * 4.5)
		hojas_caen.gravity = Vector3(d.x * arrastre, -0.9 + _racha * 0.4, d.y * arrastre)

func _textura_hoja() -> ImageTexture:
	var img := Image.create(32, 24, false, Image.FORMAT_RGBA8)
	for y in 24:
		for x in 32:
			var u := (x - 16.0) / 16.0
			var v := (y - 12.0) / 12.0
			var dentro := u * u + v * v * (1.0 + absf(u)) < 0.85
			var nervio := absf(v) < 0.08
			var t := randf_range(0.75, 1.05) * (0.8 if nervio else 1.0)
			img.set_pixel(x, y, Color(t, t * 0.92, t * 0.8, 1.0 if dentro else 0.0))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

var _color_linterna := Color.WHITE
var _alcance_linterna := 0.0
var _t_mano := 0.0
var mano_fp: Node3D
var _mano_bob := 0.0
func _update_flash(delta: float) -> void:
	if _alcance_linterna == 0.0:
		_color_linterna = flash.light_color
		_alcance_linterna = flash.spot_range
	var cam := player.camera
	# el cristal de la linterna, delante y abajo a la derecha (la mano y el brazo quedan detrás, en pantalla)
	var corre := player.running and player.moving > 0.5
	_mano_bob += delta * (11.5 if corre else 7.5) * clampf(player.moving, 0.0, 1.0)
	var bamb := Vector3(cos(_mano_bob * 0.5) * 0.012, absf(sin(_mano_bob * 0.5)) * -0.014, 0.0) * (2.2 if corre else 1.0) * clampf(player.moving, 0.0, 1.0)
	var baja := 0.05 if corre else 0.0
	flash_node.global_position = cam.global_position + cam.global_transform.basis * (Vector3(0.17, -0.19 - baja, -0.48) + bamb)
	if mano_fp:
		mano_fp.visible = hidden_in.is_empty() and state != "titulo"
	# la mano no es una cámara: la linterna va con un poco de retraso y un temblor muy leve
	_t_mano += delta
	var temblor := Quaternion(Vector3(1, 0, 0), sin(_t_mano * 1.7) * 0.004 + sin(_t_mano * 4.3) * 0.0015) * Quaternion(Vector3(0, 1, 0), sin(_t_mano * 1.3 + 1.0) * 0.005)
	var target := cam.global_transform.basis.get_rotation_quaternion() * temblor
	flash_node.quaternion = flash_node.quaternion.slerp(target, minf(1.0, delta * 11.0))
	if _polvo:
		_polvo.global_position = flash_node.global_position - flash_node.global_transform.basis.z * 2.4
	var on := flash_on and battery > 0.0 and hidden_in.is_empty()
	# como una linterna de bombilla con pilas de carbón: con la pila llena da luz blanca; por debajo del 40 % se
	# va apagando poco a poco y amarilleando, y al final tiembla
	var carga := clampf(battery / 40.0, 0.0, 1.0)
	var e := 7.0 * lerpf(0.3, 1.0, carga)
	flash.light_color = Color(1.0, 0.62, 0.32).lerp(_color_linterna, carga)
	flash.spot_range = lerpf(9.0, _alcance_linterna, carga)
	if battery < 8.0:
		e *= 0.6 + 0.4 * float(randf() > 0.06)
	# parpadea cuando Elena está cerca
	if elena.visible and elena.global_position.distance_to(player.global_position) < 9.0:
		_flicker_t -= delta
		if _flicker_t <= 0.0:
			_flicker_t = randf_range(0.04, 0.25)
			flash.set_meta("off", randf() < 0.45)
		if flash.get_meta("off", false):
			e *= 0.08
	flash.visible = on
	flash.light_energy = e * 0.55
	flash_foco.visible = on
	flash_foco.light_energy = e * 0.85
	flash_foco.light_color = flash.light_color
	flash_foco.spot_range = flash.spot_range
	flash_node.get_node("cerca").visible = on
	# rebote: donde da el centro del haz sale un poco de luz (más cuanto más cerca está la superficie)
	if _rebote:
		var dir := -flash_node.global_transform.basis.z
		var desde := flash_node.global_position
		var q := PhysicsRayQueryParameters3D.create(desde, desde + dir * flash.spot_range)
		q.exclude = [player.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(q) if on else {}
		if hit.is_empty():
			_rebote.light_energy = move_toward(_rebote.light_energy, 0.0, delta * 3.0)
		else:
			var d: float = desde.distance_to(hit.position)
			_rebote.global_position = (hit.position as Vector3) + (hit.normal as Vector3) * 0.45
			var objetivo := e / 7.0 * 0.8 * clampf(1.0 - d / 16.0, 0.0, 1.0)
			_rebote.light_energy = lerpf(_rebote.light_energy, objetivo, minf(1.0, delta * 8.0))
			_rebote.light_color = flash.light_color
	elena.flashlight_on = on

func _play(delta: float) -> void:
	play_time += delta
	var pp := player.global_position
	var lit := mansion.is_lit(pp)
	var on := flash_on and battery > 0.0 and hidden_in.is_empty()
	if on:
		battery = maxf(0.0, battery - delta * 0.065)  # unos 25 minutos con la pila llena
		if battery < 40.0 and battery + delta * 0.065 >= 40.0:
			message("La luz de la linterna empieza a amarillear.", 2.5)
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
		message("El miedo me ha hecho gritar. Ahora sabe dónde estoy.", 3.0)
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
	if post_mat:
		post_mat.set_shader_parameter("miedo", clampf((100.0 - sanity) / 100.0 * 0.7 + _danger * 0.6, 0.0, 1.0))
	# Elena: escondite
	elena.player_hidden = not hidden_in.is_empty()
	_respirar(delta, pp)
	_fonografo_tick(delta)
	_events(pp)
	# vistazo de guion al principio
	if _intro_glimpse > 0.0 and state == "juego":
		_intro_glimpse -= delta
		if _intro_glimpse <= 0.0:
			_glimpse(true)
	_director(delta)
	_casa_viva(delta)
	_hallucinations(delta)
	_ghost_update(delta)
	_interact_prompt()
	if Input.is_action_just_pressed("usar"):
		_use()
	if Input.is_action_just_pressed("linterna") and hidden_in.is_empty() and state == "juego":
		flash_on = not flash_on
		_click()
	if Input.is_action_just_pressed("sal"):
		_throw_salt()
	if Input.is_action_just_pressed("disparar") and hidden_in.is_empty():
		defensa.disparar()
	if Input.is_action_just_pressed("diario"):
		diario.abrir()
	diario.tick(delta, false)
	# objetos de la trampa que ves de cerca: quedan apuntados en el diario y el mapa
	_t_ver_obj -= delta
	if _t_ver_obj <= 0.0:
		_t_ver_obj = 0.4
		for so in mansion.seals:
			if not so.taken and not so.get("visto", false) and pp.distance_to(so.pos) < 9.0 and absf(pp.y - (so.pos as Vector3).y) < 2.0 and _in_view((so.pos as Vector3) + Vector3(0, 0.9, 0)):
				so["visto"] = true
				message("Ahí está %s. (Apuntado en el DIARIO)" % ZarekDiario.nombre_objeto(so), 2.5)
	_puerta_tick(delta)
	if Input.is_action_just_pressed("agachar") and hidden_in.is_empty():
		player.crouching = not player.crouching
		message("Agachada: más lenta, pero casi no hago ruido." if player.crouching else "", 1.5 if player.crouching else 0.01)
	_electricidad(delta)
	_registro_tick(delta)
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
					pass

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

var _t_crujido := 0
var _t_ver_obj := 0.0
func _on_step(noise: float) -> void:
	if state != "juego" and state != "ritual":
		return
	var pp0 := player.global_position
	_paso_sofia(pp0, noise)
	for q in mansion.cristales:
		if absf((q as Vector3).y - pp0.y) < 1.2 and Vector2(q.x - pp0.x, q.z - pp0.z).length() < 0.75:
			sound_at("vidrio", q + Vector3(0, 0.1, 0), -6.0 + noise * 6.0)
			noise = maxf(noise * 2.2, 9.0)
			break
	for q in mansion.charcos:
		if absf((q as Vector3).y - pp0.y) < 1.2 and Vector2(q.x - pp0.x, q.z - pp0.z).length() < 0.8:
			sound_at("chapoteo", q + Vector3(0, 0.1, 0), -8.0 + noise * 4.0)
			noise = maxf(noise * 1.6, 6.0)
			break
	if _trueno_tapa > 0.0:
		noise *= 0.2
	elena.hear(player.global_position, noise)
	# tablones rotos: crujen fuerte al pisarlos (y Elena lo oye)
	var pp := player.global_position
	for c in mansion.crujidos:
		var q := c as Vector3
		if absf(q.y - pp.y) < 1.2 and Vector2(q.x - pp.x, q.z - pp.z).length() < 0.75:
			if Time.get_ticks_msec() - _t_crujido > 900:
				_t_crujido = Time.get_ticks_msec()
				sound_at("tablon", q + Vector3(0, 0.2, 0), 2.0)
				elena.hear(q, maxf(noise, 0.7))
			break

## Pasos de Sofía según el suelo: madera, baldosa o piedra dentro; hierba o grava fuera; agua en los charcos.
var _snd_paso: AudioStreamPlayer
func _paso_sofia(pp: Vector3, noise: float) -> void:
	if _snd_paso == null:
		_snd_paso = _player_snd(null, -12.0)
	var sup := "madera"
	var tono := 1.0
	var r := mansion.room_at(pp)
	if r < 0 or not mansion.inside_house(pp) and pp.y > -0.5:
		sup = "grava" if _en_camino(pp) else "hierba"
	else:
		var t := String(mansion.rooms[r].type)
		var n := String(mansion.rooms[r].name)
		if pp.y < -0.5 or t in ["tunel", "roca", "sotano"]:
			sup = "baldosa"
			tono = 0.85
		elif t in ["cocina", "bano", "servicio"] or n.begins_with("Vestíbulo") or n.begins_with("Baño") or n.begins_with("Cocina") or n.begins_with("Antecocina") or n.begins_with("Despensa"):
			sup = "baldosa"
		elif t in ["sala", "dormitorio", "epicentro"] and ZarekSonido.hay("paso_alfombra"):
			# en el centro de salones y dormitorios está la alfombra: pasos ahogados
			var rc: Rect2 = mansion.rooms[r].rect
			if rc.grow(-minf(rc.size.x, rc.size.y) * 0.22).has_point(Vector2(pp.x, pp.z)):
				sup = "alfombra"
		# en las escaleras (entre dos plantas) crujen los peldaños
		var sobre_planta := fposmod(pp.y, ZarekMansion.LEVEL_H)
		if sobre_planta > 0.35 and sobre_planta < ZarekMansion.LEVEL_H - 0.35 and ZarekSonido.hay("paso_escalera"):
			sup = "escalera"
	for q in mansion.charcos:
		if absf((q as Vector3).y - pp.y) < 1.2 and Vector2(q.x - pp.x, q.z - pp.z).length() < 0.8:
			sup = "agua"
	if not ZarekSonido.hay("paso_" + sup):
		return
	_snd_paso.stream = ZarekSonido.uno("paso_" + sup)
	_snd_paso.pitch_scale = tono * randf_range(0.93, 1.07)
	_snd_paso.volume_db = -16.0 + clampf(noise, 0.0, 8.0) * 1.2
	_snd_paso.play()

var _caminos: Array[Rect2] = []
func _en_camino(pp: Vector3) -> bool:
	if _caminos.is_empty():
		for z in mansion.plan.exterior.zonas:
			if String(z[1]) == "camino":
				_caminos.append(Rect2(float(z[2]) * ZarekMansion.CELL, float(z[3]) * ZarekMansion.CELL, float(z[4]) * ZarekMansion.CELL, float(z[5]) * ZarekMansion.CELL))
		if _caminos.is_empty():
			_caminos.append(Rect2(-1e6, -1e6, 0, 0))
	for c in _caminos:
		if c.has_point(Vector2(pp.x, pp.z)):
			return true
	return false

## La casa suena viva: la madre gime y arrastra las cadenas en la capilla del sótano, alguien corta carne en el
## matadero, la sangre gotea. Se oyen de lejos (a través de los suelos) y ponen nervioso aunque no pase nada.
var _t_madre := 20.0
var _t_carne := 35.0
var _sala_capilla := {}
var _sala_matadero := {}
func _casa_viva(delta: float) -> void:
	if _sala_capilla.is_empty():
		_sala_capilla = mansion._sala_por_nombre("Capilla de la madre")
		_sala_matadero = mansion._sala_por_nombre("Galería de servicio")
	var pp := player.global_position
	_t_madre -= delta
	if _t_madre <= 0.0 and not _sala_capilla.is_empty():
		_t_madre = randf_range(25.0, 55.0)
		var rc: Rect2 = _sala_capilla.rect
		var c := Vector3(rc.get_center().x, float(_sala_capilla.y) + 1.2, rc.end.y - 2.0)
		var d := c.distance_to(pp)
		if d < 45.0:
			var voz := "elena_voz" if ZarekSonido.hay("elena_voz") and randf() < 0.4 else "madre_gime"
			ZarekSonido.en(self, voz, c, 4.0 if d < 15.0 else 8.0, 50.0, randf_range(0.9, 1.05) if voz == "madre_gime" else 1.0)
			if randf() < 0.7:
				sound_at("cadenas" if ZarekSonido.hay("cadenas") else "tintineo", c + Vector3(0.5, -0.8, 0), 2.0)
	_t_carne -= delta
	if _t_carne <= 0.0 and not _sala_matadero.is_empty():
		_t_carne = randf_range(40.0, 80.0)
		var rc2: Rect2 = _sala_matadero.rect
		var c2 := Vector3(rc2.get_center().x, float(_sala_matadero.y) + 1.0, rc2.get_center().y)
		if c2.distance_to(pp) < 35.0 and ZarekSonido.hay("carne"):
			ZarekSonido.en(self, "carne", c2, 0.0, 30.0)

func _click() -> void:
	snd_ui.stream = _s("paso")
	snd_ui.volume_db = -10.0
	snd_ui.play()

# ---------------- interacción ----------------
func _target() -> Dictionary:
	var pp := player.global_position
	if not hidden_in.is_empty():
		if _aliento_visible():
			return {"kind": "salir", "text": "¡ESTÁ CERCA! Mantén LUZ para contener la respiración · USAR: salir"}
		return {"kind": "salir", "text": "USAR: salir" + (" de debajo de la cama" if hidden_in.get("tipo", "") == "cama" else " del armario")}
	if is_instance_valid(llevado):
		return {"kind": "lanzar", "text": "USAR: lanzar"}
	for s in mansion.seals:
		if not s.taken and Vector2(pp.x - s.pos.x, pp.z - s.pos.z).length() < 1.7:
			return {"kind": "sello", "obj": s, "text": "USAR: tomar " + String(ZarekMansion.NOMBRE_OBJETO.get(s.get("tipo", ""), "el objeto"))}
	if fauna and is_instance_valid(fauna.gato) and fauna.gato.process_mode != Node.PROCESS_MODE_DISABLED \
			and fauna.gato.global_position.distance_to(pp + player.forward() * 0.6) < 1.1 and fauna.gato.estado != ZarekAnimal.E.HUYE:
		return {"kind": "gato", "text": "USAR: acariciar al gato"}
	var nota := mansion.nota_cerca(pp + player.forward() * 0.5, 1.2)
	if not nota.is_empty():
		return {"kind": "nota", "obj": nota, "text": "USAR: leer «" + String(nota.titulo).get_slice(" · ", 0) + "»"}
	var arma_s := defensa.arma_cerca(pp) if defensa else {}
	if not arma_s.is_empty():
		return {"kind": "arma_suelo", "obj": arma_s, "text": "USAR: coger " + String(ZarekDefensa.ARMAS[arma_s.tipo].nombre)}
	for k in mansion.pickups:
		if not k.taken and Vector2(pp.x - k.pos.x, pp.z - k.pos.z).length() < 1.6:
			return {"kind": "pick", "obj": k, "text": "USAR: tomar " + {"pila": "las pilas", "tablon": "los tablones", "llaves": "las llaves del coche"}.get(k.kind, "las bengalas")}
	if seals >= SEALS_NEEDED and _in_circle(pp):
		return {"kind": "ritual", "text": "MANTÉN USAR: preparar la trampa"}
	if entered and mansion.car_pos != Vector3.ZERO and Vector2(pp.x - mansion.car_pos.x, pp.z - mansion.car_pos.z).length() < 3.0:
		if tiene_llaves:
			return {"kind": "huir", "text": "USAR: huir en el coche (final)"}
		return {"kind": "nada", "text": "El coche no arranca sin las llaves. ¿Dónde las dejé…?"}
	var pt := mansion.portal_near(pp, 1.7)
	if not pt.is_empty():
		return {"kind": "portal", "obj": pt, "text": "USAR: " + str(pt.text)}
	var wd := mansion.wardrobe_near(pp, 1.2)
	if Vector2(pp.x - mansion.radio_pos.x, pp.z - mansion.radio_pos.z).length() < 1.6 and absf(pp.y - mansion.radio_pos.y) < 2.0:
		if _t_fono > 0.0:
			return {"kind": "nada", "text": "El fonógrafo está sonando…"}
		if _t_fono < 0.0:
			return {"kind": "nada", "text": "La manivela está floja. Tengo que esperar."}
		return {"kind": "fonografo", "text": "USAR: poner el disco (lo atraerá aquí)"}
	if not wd.is_empty():
		return {"kind": "armario", "obj": wd, "text": "USAR: esconderse " + ("debajo de la cama" if wd.get("tipo", "") == "cama" else "en el armario")}
	var d := mansion.door_near(pp + player.forward() * 0.6, 1.7)
	if not d.is_empty():
		if d.locked and String(d.get("llave", "")) != "":
			if String(d.llave) in llaves_salas:
				return {"kind": "abrir_llave", "obj": d, "text": "USAR: abrir con la llave de «%s»" % d.llave}
			return {"kind": "cerrada", "obj": d, "text": "USAR: probar el pomo (cerrada con llave)"}
		if d.locked:
			return {"kind": "cerrada", "obj": d, "text": "USAR: probar el pomo (cerrada)"}
		if float(d.get("barricada", 0.0)) > 0.0:
			return {"kind": "atrancada", "obj": d, "text": "USAR: quitar los tablones"}
		if not d.open and tablones > 0:
			return {"kind": "puerta", "obj": d, "text": "USAR: abrir · MANTÉN USAR: atrancar (tablones: %d)" % tablones}
		if d.get("entre", false):
			return {"kind": "puerta", "obj": d, "text": "USAR: abrir del todo (entreabierta)"}
		return {"kind": "puerta", "obj": d, "text": "USAR: " + ("cerrar la puerta" if d.open else "entreabrir la puerta")}
	var el: ZarekElectricidad = mansion.electricidad
	if el and el.cuadro_cerca(pp):
		if not el.corriente:
			return {"kind": "cuadro", "text": "MANTÉN USAR: subir la palanca general del cuadro eléctrico"}
		return {"kind": "nada", "text": "El cuadro eléctrico de la casa. Zumba y huele a quemado."}
	var mr := ZarekRegistro.cerca(muebles_reg, pp, player.look_dir())
	if not mr.is_empty():
		if String(mr.tipo) != "" and not mr.hecho:
			return {"kind": "registrar", "obj": mr, "text": "MANTÉN USAR: registrar " + {"cajon": "los cajones", "puerta": "el armario", "tapa": "el baúl"}.get(String(mr.tipo), "")}
		if String(mr.ruido) != "":
			return {"kind": "ruido_obj", "obj": mr, "text": "USAR: " + {"grifo": "abrir el grifo", "cisterna": "tirar de la cadena", "piano": "tocar una tecla del piano"}.get(String(mr.ruido), "") + " (hace ruido)"}
	if el:
		var it := el.interruptor_cerca(pp)
		if not it.is_empty():
			return {"kind": "interruptor", "obj": it, "text": "USAR: " + ("apagar" if it.on else "encender") + " la luz de la sala"}
	var l := mansion.lamp_near(pp, 1.8)
	if not l.is_empty() and not l.broken:
		return {"kind": "lampara", "obj": l, "text": "USAR: " + ("apagar" if l.on else "encender") + " la lámpara"}
	if not l.is_empty() and l.broken:
		return {"kind": "nada", "text": "La bombilla está rota."}
	# objetos sueltos al alcance de la mano: se pueden coger y lanzar
	var cam := player.camera
	var q := PhysicsRayQueryParameters3D.create(cam.global_position, cam.global_position - cam.global_transform.basis.z * 2.2, 1 | 2 | 8)
	q.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty() and hit.collider is RigidBody3D and (hit.collider as RigidBody3D).mass < 14.0:
		return {"kind": "coger", "obj": hit.collider, "text": "USAR: coger (y lanzárselo)"}
	if defensa and defensa.cepos > 0 and state == "juego" and mansion.inside_house(pp):
		return {"kind": "poner_cepo", "text": "USAR: poner una trampa de caza aquí (%d)" % defensa.cepos}
	return {}

# ---------------- notas y salas ----------------
var panel_nota: PanelContainer
var lbl_nota: Label
var _t_nota := 0.0
var notas_leidas := 0
func _leer_nota(n: Dictionary) -> void:
	if panel_nota == null:
		var capa := CanvasLayer.new()
		capa.layer = 60
		add_child(capa)
		panel_nota = PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.86, 0.8, 0.66, 0.96)
		sb.border_color = Color(0.35, 0.28, 0.18)
		sb.set_border_width_all(3)
		sb.set_content_margin_all(28)
		panel_nota.add_theme_stylebox_override("panel", sb)
		panel_nota.set_anchors_preset(Control.PRESET_CENTER)
		panel_nota.custom_minimum_size = Vector2(760, 0)
		panel_nota.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl_nota = Label.new()
		lbl_nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_nota.custom_minimum_size = Vector2(700, 0)
		lbl_nota.add_theme_font_size_override("font_size", 26)
		lbl_nota.add_theme_color_override("font_color", Color(0.15, 0.1, 0.06))
		panel_nota.add_child(lbl_nota)
		capa.add_child(panel_nota)
	if panel_nota.visible and _t_nota > 0.0:
		panel_nota.visible = false
		_t_nota = 0.0
		return
	lbl_nota.text = String(n.titulo).to_upper() + "\n\n" + String(n.texto)
	panel_nota.visible = true
	panel_nota.reset_size()
	panel_nota.position = (get_viewport().get_visible_rect().size - panel_nota.size) * 0.5
	_t_nota = 14.0
	if not n.leida:
		n.leida = true
		notas_leidas += 1
		message("Nota %d de %d" % [notas_leidas, mansion.notas.size()], 2.0)
	snd_ui.stream = _s("crujido")
	snd_ui.volume_db = -14.0
	snd_ui.play()

var _salas_vistas := {}
var _sala_actual := -1
func _eventos_sala(delta: float) -> void:
	if _t_nota > 0.0:
		_t_nota -= delta
		if _t_nota <= 0.0 and panel_nota:
			panel_nota.visible = false
	if state != "juego":
		return
	var id := mansion.room_at(player.global_position)
	if id == _sala_actual:
		return
	_sala_actual = id
	if id < 0 or _salas_vistas.has(id):
		return
	_salas_vistas[id] = true
	var nombre := String(mansion.rooms[id].name)
	if ZarekHistoria.EVENTO.has(nombre):
		var ev: Array = ZarekHistoria.EVENTO[nombre]
		var rc: Rect2 = mansion.rooms[id].rect
		var donde := Vector3(rc.get_center().x + randf_range(-1.5, 1.5), float(mansion.rooms[id].y) + 1.2, rc.get_center().y + randf_range(-1.5, 1.5))
		get_tree().create_timer(randf_range(1.2, 3.0)).timeout.connect(func():
			if _sala_actual == id:
				sound_at(ev[0], donde, -2.0)
				message(ev[1], 3.0)
				sanity = maxf(0.0, sanity - 4.0))

func _interact_prompt() -> void:
	var t := _target()
	lbl_prompt.text = str(t.get("text", ""))
	match str(t.get("kind", "")):
		"armario":
			_consejo("esconder", "Pulsa USAR para esconderte.\nSi se acerca mientras estás dentro, MANTÉN LUZ para contener la respiración (sin pasarte: acabarás jadeando).")
		"registrar":
			_consejo("registrar", "MANTÉN USAR para registrar muebles: hay pilas, bengalas, llaves de salas cerradas… y secretos de la familia que se guardan para siempre.")
		"puerta":
			_consejo("puerta", "Un toque de USAR entreabre la puerta para asomarte. Otro la abre del todo.\nCon tablones, MANTÉN USAR para atrancarla.")
		"fonografo":
			_consejo("fonografo", "El fonógrafo lo atrae hasta aquí. Ponlo y vete a otra parte… pero no abuses: aprende.")

## Consejos la primera vez que pasa algo (una sola vez en todas las partidas), abajo a la izquierda.
var lbl_consejo: Label
var _t_consejo := 0.0
func _consejo(clave: String, texto: String) -> void:
	if autotest or shots:
		return
	var vistos: Array = Aether.save.get_value("zarek_consejos", [])
	if clave in vistos or _t_consejo > 0.0:
		return
	vistos.append(clave)
	Aether.save.set_value("zarek_consejos", vistos)
	if lbl_consejo == null:
		lbl_consejo = _label("", 20, Color(0.95, 0.9, 0.78))
		lbl_consejo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_consejo.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		lbl_consejo.position = Vector2(26, -250)
		lbl_consejo.size = Vector2(560, 120)
		lbl_consejo.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		lbl_consejo.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		lbl_consejo.add_theme_constant_override("outline_size", 6)
		lbl_consejo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(lbl_consejo)
	lbl_consejo.text = "◆ " + texto
	lbl_consejo.modulate.a = 1.0
	_t_consejo = 8.0

func _consejos_tick(delta: float) -> void:
	if _t_consejo > 0.0:
		_t_consejo -= delta
		if lbl_consejo:
			lbl_consejo.modulate.a = clampf(_t_consejo / 1.0, 0.0, 1.0)
	if not entered:
		return
	_consejo("diario", "Pulsa DIARIO (arriba a la derecha) para ver qué tienes que hacer, las pistas de los objetos y el mapa de la casa.")
	_consejo("agachar", "AGACHAR: vas más lenta pero casi no haces ruido. Damián te oye antes de verte.")
	if elena.visible and elena.state == ZarekElena.S.CHASE:
		_consejo("persecucion", "¡CORRE! Cierra puertas detrás de ti, rómpele la línea de visión y escóndete cuando no te vea.")
	elif salt > 0 and elena.visible and elena.global_position.distance_to(player.global_position) < 7.0:
		_consejo("bengala", "Si está a punto de alcanzarte, una BENGALA lo aparta unos segundos.")

func _use() -> void:
	var t := _target()
	match str(t.get("kind", "")):
		"salir":
			_exit_wardrobe(true)
		"fonografo":
			_poner_fonografo()
		"huir":
			_huida()
		"nota":
			_leer_nota(t.obj)
		"gato":
			if fauna.gato.acariciar():
				sanity = minf(100.0, sanity + 6.0)
				message("El gato ronronea. Te sientes un poco mejor.", 2.5)
			else:
				message("El gato todavía no se fía de ti.", 2.0)
		"sello":
			_take_seal(t.obj)
		"pick":
			var k: Dictionary = t.obj
			k.taken = true
			_a_la_mano(k.item)
			if k.kind == "pila":
				battery = minf(100.0, battery + 50.0)
				message("Pilas nuevas para la linterna.", 2.0)
			elif k.kind == "llaves":
				tiene_llaves = true
				message("Las llaves de mi coche… las tenía él. Podría huir.\n(Pero si me voy, Damián seguirá cazando.)", 4.0)
			elif k.kind == "tablon":
				tablones += 1
				message("Tablones y clavos. Puedo atrancar una puerta (mantén USAR en una puerta cerrada).", 3.5)
			else:
				salt += 1
				message("Una bengala. Su luz lo ciega.", 2.0)
			snd_ui.stream = _s("recoger")
			snd_ui.volume_db = -8.0
			snd_ui.play()
		"armario":
			_enter_wardrobe(t.obj)
		"puerta":
			if not t.obj.open and tablones > 0:
				# cerrada y con tablones: un toque la abre, mantener la atranca (se resuelve en _puerta_tick)
				_puerta_hold = t.obj
				_t_hold = 0.0
			else:
				_mover_puerta(t.obj)
		"atrancada":
			mansion.desatrancar(t.obj)
			tablones += 1
			sound_at("golpe_madera", t.obj.pos + Vector3(0, 1.2, 0), -4.0)
			message("Quité los tablones.", 1.5)
		"arma_suelo":
			message(defensa.coger_del_suelo(t.obj), 3.0)
			sound_at("recoger", player.global_position, -6.0)
			_consejo("arma", "Con un arma, si Damián te atrapa podrás FORCEJEAR: machaca USAR para clavársela. Solo sirve una vez.")
		"poner_cepo":
			var fw := player.look_dir()
			fw.y = 0.0
			defensa.poner_trampa(player.global_position + fw.normalized() * 1.0, atan2(fw.x, fw.z))
			message("Trampa puesta. Ahora tiene que pasar por aquí…", 2.0)
		"cerrada":
			# el pomo gira y la puerta traquetea contra el cerrojo
			sound_at("pomo_cerrado", t.obj.pos + Vector3(0, 1.1, 0), -2.0)
			var dd: Dictionary = t.obj
			dd["vel"] = 0.6
			dd["rigidez"] = 60.0
			dd["freno"] = 9.0
			player.shake(0.8)
			if String(dd.get("llave", "")) != "":
				message("Cerrada con llave. En la placa del pomo pone «%s».\nLa llave tiene que estar en algún cajón de la casa." % dd.llave, 3.0)
			else:
				message("Cerrada por dentro. Es su cuarto: no podré entrar\nhasta tener los 4 objetos de la trampa.", 3.0)
		"abrir_llave":
			var dl: Dictionary = t.obj
			dl.locked = false
			sound_at("llaves", dl.pos + Vector3(0, 1.1, 0), -2.0)
			mansion.set_door(dl, true)
			message("La llave encaja. Nadie ha entrado aquí en años…", 2.5)
		"portal":
			_use_portal(t.obj)
		"lampara":
			if mansion.electricidad and not mansion.electricidad.corriente:
				message("No hay corriente en toda la casa.\nEl cuadro eléctrico está en el sótano.", 2.5)
			else:
				mansion.set_lamp(t.obj, not t.obj.on)
			_click()
		"interruptor":
			var hay: bool = mansion.electricidad.pulsar(t.obj)
			_click()
			sound_at("interruptor", (t.obj.pos as Vector3), -6.0)
			if not hay and t.obj.on:
				message("Clic… nada. No hay corriente.\nAlguien ha bajado la palanca del cuadro del sótano.", 3.0)
		"cuadro":
			_cuadro_hold = true
			_t_cuadro = 0.0
		"registrar":
			_reg_hold = t.obj
			_t_reg = 0.0
			sound_at("cajon_abrir", (t.obj.pos as Vector3) + Vector3(0, 0.6, 0), -10.0)
		"ruido_obj":
			var ro: Dictionary = t.obj
			var k := str(ro.pos)
			if Time.get_ticks_msec() - int(_t_ruido_obj.get(k, -99999)) > 15000:
				_t_ruido_obj[k] = Time.get_ticks_msec()
				var rp: Vector3 = (ro.pos as Vector3) + Vector3(0, 0.8, 0)
				sound_at(String(ro.ruido), rp, 0.0)
				elena.hear(rp, 8.0)
				message({"grifo": "El grifo escupe agua marrón con un golpe de tuberías…", "cisterna": "La cisterna ruge por toda la casa.", "piano": "La tecla suena desafinada… y el eco recorre la casa."}.get(String(ro.ruido), ""), 2.5)
		"coger":
			llevado = t.obj
			llevado.sleeping = false
			llevado.gravity_scale = 0.0
			llevado.angular_damp = 6.0
			player.add_collision_exception_with(llevado)
		"lanzar":
			var cam := player.camera
			llevado.gravity_scale = 1.0
			llevado.angular_damp = 0.0
			llevado.linear_velocity = -cam.global_transform.basis.z * clampf(9.0 - llevado.mass * 0.5, 3.0, 9.0) + Vector3(0, 1.2, 0)
			llevado.angular_velocity = Vector3(randf_range(-4, 4), randf_range(-4, 4), randf_range(-4, 4))
			var lanzado := llevado
			llevado = null
			defensa.lanzado(lanzado)
			get_tree().create_timer(0.4).timeout.connect(func(): if is_instance_valid(lanzado): player.remove_collision_exception_with(lanzado))

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

## Al coger algo, el objeto vuela hasta la mano en vez de desaparecer de golpe.
func _a_la_mano(n: Node3D) -> void:
	if n == null or not is_instance_valid(n):
		return
	if autotest:
		n.visible = false
		return
	var desde := n.global_position
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_method(func(k: float):
		if is_instance_valid(n):
			n.global_position = desde.lerp(flash_node.global_position + Vector3(0, -0.15, 0), k), 0.0, 1.0, 0.32)
	tw.tween_property(n, "scale", n.scale * 0.25, 0.32)
	tw.chain().tween_callback(func(): n.visible = false)

func _take_seal(s: Dictionary) -> void:
	s.taken = true
	if diario:
		diario.tick(0.0, true)
	_a_la_mano(s.node)
	seals += 1
	elena.aggro = seals + (2 if dif == 2 else 0)
	snd_ui.stream = _s("campana")
	snd_ui.volume_db = -6.0
	snd_ui.play()
	player.shake(4.0)
	match seals:
		1:
			message(_obj_msg(s) + "\nEn algún lugar empezó a sonar una radio: «…ayuda… por favor…»", 4.0)
			snd_box.play()
			if elena.state == ZarekElena.S.DORMANT:
				elena.timer = minf(elena.timer, 4.0)
		2:
			message(_obj_msg(s) + "\nHa notado que falta algo. Ya no espera en la oscuridad.", 4.5)
			snd_radio.play()
			for l in mansion.lamps:
				mansion.flicker_lamp(l, 1.5)
			sound_behind("susurro", 2.0, 2.0)
		3:
			message(_obj_msg(s) + "\nSabe lo que estoy haciendo.", 3.0)
			sound_behind("risa", 4.0, 0.0)
			_corte_luz(3.5)
		4:
			_blackout()

func _obj_msg(s: Dictionary) -> String:
	var n := String(ZarekMansion.NOMBRE_OBJETO.get(s.get("tipo", ""), "otro objeto"))
	return "Tengo " + n + "."

func _blackout() -> void:
	message("Ya lo tengo todo.\nHa cortado la luz de la casa. Sabe que estoy aquí.", 4.5)
	for l in mansion.lamps:
		mansion.break_lamp(l)
	snd_box.stop()
	snd_radio.stop()
	player.shake(14.0)
	Aether.flash(Color(0.6, 0, 0), 0.4)
	sound_behind("grito", 6.0, 3.0)
	for d in mansion.doors:
		if d.locked and String(d.get("llave", "")) == "":
			d.locked = false
			mansion.set_door(d, true, true)
			d.snd.stream = _s("portazo")
			d.snd.play()
	if elena.state == ZarekElena.S.DORMANT:
		elena.wake_far()
	elena.hear(player.global_position, 999.0)

## Toque en una puerta cerrada: se abre. Mantener 1,4 s: se clava con tablones (gasta uno).
func _puerta_tick(delta: float) -> void:
	if _puerta_hold.is_empty():
		return
	var d := _puerta_hold
	if Input.is_action_pressed("usar") and d.pos.distance_to(player.global_position) < 2.4:
		_t_hold += delta
		bar_rit.visible = true
		bar_rit.value = _t_hold / 1.4 * 100.0
		if _t_hold >= 1.4:
			_puerta_hold = {}
			bar_rit.visible = false
			tablones -= 1
			mansion.atrancar(d, 7.0)
			sound_at("golpe_madera", d.pos + Vector3(0, 1.2, 0), 2.0)
			elena.hear(player.global_position, 9.0)
			message("Puerta atrancada. Aguantará un poco… no mucho.", 2.5)
		return
	_puerta_hold = {}
	bar_rit.visible = false
	if _t_hold < 0.4:
		_mover_puerta(d)

## ---------------- electricidad: cortes de luz, el cuadro del sótano y Damián apagando salas ----------------
var _cuadro_hold := false
var _t_cuadro := 0.0
var _t_corte_azar := randf_range(420.0, 720.0)
var _t_apagar := 1.0
func _corte_luz(espera := 0.0) -> void:
	if mansion.electricidad == null or not mansion.electricidad.corriente:
		return
	if espera > 0.0:
		await get_tree().create_timer(espera).timeout
	if not mansion.electricidad.corriente:
		return
	for l in mansion.lamps:
		if l.on:
			mansion.flicker_lamp(l, 0.6)
	await get_tree().create_timer(0.6).timeout
	mansion.electricidad.cortar()
	var c: Dictionary = mansion.electricidad.cuadro
	if not c.is_empty():
		sound_at("golpe_madera", (c.pos as Vector3), 2.0)
	sound_behind("zumbido", 1.0, -6.0)
	message("Se fue la luz en toda la casa.\nHan bajado la palanca del cuadro eléctrico… está en el sótano.", 4.0)
	sanity = maxf(0.0, sanity - 8.0)

const NADA_CAJON := ["Nada. Polillas muertas.", "Cartas viejas de pésame, de 1987.", "Un puñado de dientes. Dientes humanos.", "Recortes de periódico: «DESAPARECE OTRO EXCURSIONISTA».",
	"Una muñeca sin ojos.", "Pelo. Mechones de pelo de distintos colores, atados con cuerda.", "Cubiertos de plata, todos doblados.", "Carteras vacías. Muchas.",
	"Una caja de cerillas húmedas.", "Rosarios rotos.", "Fotos de familia con una cara arrancada en todas."]
func _registro_tick(delta: float) -> void:
	if _reg_hold.is_empty():
		return
	var x := _reg_hold
	if Input.is_action_pressed("usar") and (x.pos as Vector3).distance_to(player.global_position) < 2.6:
		_t_reg += delta
		bar_rit.visible = true
		bar_rit.value = _t_reg / 1.1 * 100.0
		if _t_reg >= 1.1:
			_reg_hold = {}
			bar_rit.visible = false
			ZarekRegistro.abrir(mansion, x)
			sound_at("cajon_abrir" if String(x.tipo) == "cajon" else ("armario" if ZarekSonido.hay("armario") else "puerta_rendija"), (x.pos as Vector3) + Vector3(0, 0.6, 0), -4.0)
			elena.hear(player.global_position, 3.0)
			match String(x.botin):
				"pila":
					battery = minf(100.0, battery + 50.0)
					message("Pilas. Todavía funcionan.", 2.0)
					sound_at("recoger", player.global_position, -6.0)
				"bengala":
					salt += 1
					message("Una bengala de carretera.", 2.0)
					sound_at("recoger", player.global_position, -6.0)
				"tablon":
					tablones += 1
					message("Clavos y un martillo. Puedo atrancar una puerta más.", 2.5)
				var b when String(b).begins_with("llave:"):
					var sala := String(b).trim_prefix("llave:")
					llaves_salas.append(sala)
					sound_at("llaves", player.global_position, -4.0)
					message("Una llave vieja con una etiqueta: «%s»." % sala, 3.0)
				var b when String(b).begins_with("secreto:"):
					_secreto(String(b).trim_prefix("secreto:"))
				"nota":
					message("Una polaroid: yo, de niña, en brazos de mamá… delante de esta casa.\nNunca me dijo que había estado aquí.", 4.5)
					sanity = maxf(0.0, sanity - 6.0)
				_:
					var dm: String = defensa.botin(String(x.botin)) if String(x.botin) != "" else ""
					if dm != "":
						message(dm, 3.5)
						sound_at("recoger", player.global_position, -6.0)
						if defensa.arma != "":
							_consejo("arma", "Con un arma, si Damián te atrapa podrás FORCEJEAR: machaca USAR para clavársela. Solo sirve una vez.")
						if defensa.escopeta:
							_consejo("escopeta", "DISPARAR (botón nuevo): apunta bien. No lo mata, lo derriba… y el disparo se oye en toda la casa.")
					else:
						message(NADA_CAJON[randi() % NADA_CAJON.size()], 2.5)
		return
	_reg_hold = {}
	bar_rit.visible = false

func _electricidad(delta: float) -> void:
	var el: ZarekElectricidad = mansion.electricidad
	if el == null:
		return
	# subir la palanca general: 2 s manteniendo USAR, chispas y ruido (te puede oír)
	if _cuadro_hold:
		if Input.is_action_pressed("usar") and el.cuadro_cerca(player.global_position, 2.2):
			_t_cuadro += delta
			bar_rit.visible = true
			bar_rit.value = _t_cuadro / 2.0 * 100.0
			if _t_cuadro >= 2.0:
				_cuadro_hold = false
				bar_rit.visible = false
				el.devolver()
				var cp: Vector3 = el.cuadro.pos
				sound_at("golpe_madera", cp, 0.0)
				sound_at("zumbido", cp, 0.0)
				fx_chispas(cp + Vector3(0, -0.2, 0.15))
				elena.hear(player.global_position, 9.0)
				message("La luz volvió… pero el golpe de la palanca se oyó en toda la casa.", 3.0)
		else:
			_cuadro_hold = false
			bar_rit.visible = false
	# a veces, él vuelve a cortar la luz (una vez por partida, además del corte del tercer objeto)
	if el.corriente and state == "juego" and entered:
		_t_corte_azar -= delta
		if _t_corte_azar <= 0.0:
			_t_corte_azar = 1e9
			_corte_luz()
	# Damián apaga la luz de las salas por las que pasa (le gusta la oscuridad)
	_t_apagar -= delta
	if _t_apagar <= 0.0:
		_t_apagar = 1.5
		if elena.visible and elena.state in [ZarekElena.S.WANDER, ZarekElena.S.SEARCH] and el.corriente:
			var er := mansion.room_at(elena.global_position)
			if er >= 0 and el.sala_encendida(er) and not (mansion.rooms[er].get("lamps", []) as Array).is_empty() and randf() < 0.12:
				el.apagar_sala(er)
				sound_at("interruptor", elena.global_position + Vector3(0, 1.3, 0), 0.0)

## Chispas pequeñas (cuadro eléctrico).
func fx_chispas(p: Vector3) -> void:
	var c := CPUParticles3D.new()
	c.one_shot = true
	c.emitting = true
	c.amount = 24
	c.lifetime = 0.5
	c.explosiveness = 0.95
	c.direction = Vector3(0, 0.3, 1)
	c.spread = 70.0
	c.initial_velocity_min = 1.5
	c.initial_velocity_max = 3.5
	c.gravity = Vector3(0, -9.8, 0)
	var q := QuadMesh.new()
	q.size = Vector2(0.02, 0.02)
	var mt := StandardMaterial3D.new()
	mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mt.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mt.albedo_color = Color(1.0, 0.8, 0.4)
	q.material = mt
	c.mesh = q
	add_child(c)
	c.global_position = p
	get_tree().create_timer(1.5).timeout.connect(c.queue_free)

## Cerrada → el pomo hace clic y se entreabre despacio (rendija para mirar). Entreabierta → se abre del todo.
## Abierta → se cierra con cuidado y encaja el pestillo. Cada paso suena distinto y hace menos ruido que un portazo.
func _mover_puerta(d: Dictionary) -> void:
	var cerca: Vector3 = d.pos + Vector3(0, 1.1, 0)
	if d.open:
		mansion.set_door(d, false)
		d["rigidez"] = 6.0
		sound_at("puerta_cerrar", cerca, -6.0)
		elena.hear(player.global_position, 3.0)
	elif d.get("entre", false):
		mansion.set_door(d, true)
		d["rigidez"] = 5.0
		d["freno"] = 4.4
		sound_at("puerta_crujido", cerca, -4.0)
		elena.hear(player.global_position, 4.0)
	else:
		sound_at("pomo", cerca, -6.0)
		mansion.entreabrir(d)
		sound_at("puerta_rendija", cerca, -8.0)
		elena.hear(player.global_position, 2.0)
		player.shake(0.6)

func _aliento_visible() -> bool:
	return not hidden_in.is_empty() and elena.visible and elena.state != ZarekElena.S.DORMANT \
		and elena.global_position.distance_to(player.global_position) < 7.0

## Escondida: con él cerca hay que contener la respiración (LUZ mantenido). Si respira cerca, la oye; si
## aguanta demasiado, jadea. Mientras busca, a veces revisa el escondite más cercano: si la pilla
## respirando, la saca; si aguanta, se va.
func _respirar(delta: float, pp: Vector3) -> void:
	if hidden_in.is_empty():
		barra_aliento.visible = false
		_revisando = {}
		return
	var cerca := _aliento_visible()
	var ed := elena.global_position.distance_to(pp)
	_aguantando = cerca and Input.is_action_pressed("linterna")
	if _aguantando:
		aliento -= delta / 7.5
		if aliento <= 0.0:
			aliento = 0.35
			_aguantando = false
			sound_at("aliento", pp + Vector3(0, 0.5, 0), 4.0)
			message("No pude más… jadeé.", 2.0)
			if ed < 8.0:
				_pillada_escondida()
				return
	else:
		aliento = minf(1.0, aliento + delta / 3.5)
		if cerca and ed < 3.2:
			_t_oir_resp += delta
			if _t_oir_resp > 1.2:
				_t_oir_resp = 0.0
				if randf() < 0.45:
					sound_at("aliento", pp + Vector3(0, 0.5, 0), -2.0)
					_pillada_escondida()
					return
		else:
			_t_oir_resp = 0.0
	barra_aliento.visible = cerca or aliento < 1.0
	barra_aliento.value = aliento
	if _aguantando and aliento < 0.3:
		player.shake(1.5)
	# te vio entrar: va directo al escondite
	if _hide_seen and elena.state == ZarekElena.S.CHASE:
		_revisando = hidden_in
	# buscando cerca: a veces revisa el escondite
	if _revisando.is_empty() and elena.state in [ZarekElena.S.SEARCH, ZarekElena.S.INVESTIGATE] and ed < 9.0:
		_t_revisar -= delta
		if _t_revisar <= 0.0:
			var conoce := _conoce_escondite(hidden_in)
			_t_revisar = randf_range(6.0, 12.0) * (1.0 - conoce)
			if randf() < 0.4 + 0.1 * elena.aggro + conoce:
				_revisando = hidden_in
				message("Viene directo hacia aquí… conoce este escondite." if conoce >= 0.24 else "Viene hacia aquí…", 1.8)
	if not _revisando.is_empty():
		var wp: Vector3 = _revisando.pos
		elena.last_seen = wp
		if elena.path.is_empty() or elena.state == ZarekElena.S.WANDER:
			if elena.state != ZarekElena.S.CHASE:
				elena.set_state(ZarekElena.S.INVESTIGATE, 12.0)
			elena.path = mansion.path(elena.global_position, wp)
		if Vector2(elena.global_position.x - wp.x, elena.global_position.z - wp.z).length() < 1.3:
			if _hide_seen or not _aguantando:
				_pillada_escondida()
			else:
				# aguantó: abre, mira y se va
				sound_at("crujido", wp + Vector3(0, 1, 0), 0.0)
				_revisando = {}
				_hide_seen = false
				elena.set_state(ZarekElena.S.WANDER)
				elena.path = []
				sanity = maxf(0.0, sanity - 10.0)
				message("Se quedó mirando… y se fue.", 2.5)

func _pillada_escondida() -> void:
	_revisando = {}
	_exit_wardrobe(false)
	_on_caught()

## Fonógrafo: pone un disco viejo que suena por toda la planta y lo atrae hasta él durante un rato.
var _fono_ignora := false
func _poner_fonografo() -> void:
	# cuantas más veces le has engañado con el disco (en todas las noches), más fácil es que no caiga
	var h := _habitos()
	var usos := int(h.get("fono", 0))
	h["fono"] = usos + 1
	Aether.save.set_value("zarek_habitos", h)
	_fono_ignora = randf() < clampf((usos - 2) * 0.1, 0.0, 0.55)
	_t_fono = 25.0
	snd_radio.stream = _s("caja_musica")
	snd_radio.volume_db = 2.0
	snd_radio.max_distance = 40.0
	snd_radio.play()
	message("El disco empieza a sonar. Vendrá a ver qué es… escóndete.", 3.0)

func _fonografo_tick(delta: float) -> void:
	if _t_fono < 0.0:
		_t_fono = minf(0.0, _t_fono + delta)
	if _t_fono <= 0.0:
		return
	_t_fono -= delta
	if _fono_ignora:
		# ya no se cree el truco: va a buscar a quien ha puesto el disco
		if _t_fono < 19.0 and _t_fono + delta >= 19.0 and elena.state != ZarekElena.S.DORMANT:
			elena.hear(player.global_position, 8.0)
			message("No ha ido al fonógrafo…\nConoce el truco del disco. Viene a buscarme.", 3.0)
	elif elena.state != ZarekElena.S.CHASE and elena.state != ZarekElena.S.DORMANT:
		elena.player_hidden = false
		elena.hear(mansion.radio_pos, 999.0)
		elena.player_hidden = not hidden_in.is_empty()
	if _t_fono <= 0.0:
		snd_radio.stop()
		snd_radio.stream = _s("estatica")
		snd_radio.volume_db = -4.0
		snd_radio.max_distance = 22.0
		_t_fono = -60.0  # no se puede volver a poner en un minuto

func _enter_wardrobe(wd: Dictionary) -> void:
	hidden_in = wd
	_hide_seen = elena.state == ZarekElena.S.CHASE and elena.sees_player and elena.global_position.distance_to(player.global_position) < 9.0
	player.global_position = wd.inside
	player.set_look(wd.yaw, 0.0)
	aliento = 1.0
	_t_revisar = randf_range(4.0, 9.0) * (1.0 - _conoce_escondite(wd))
	if _conoce_escondite(wd) >= 0.36 and randf() < 0.5:
		message("Ya me he escondido aquí muchas veces…\n¿Y si él lo sabe?", 2.5)
	_anotar_escondite(wd)
	var cama: bool = wd.get("tipo", "") == "cama"
	player.altura_fija = true
	player.head.position.y = 0.2 if cama else player.eye_height
	player.speed_mult = 0.0
	player.velocity = Vector3.ZERO
	for c in player.get_children():
		if c is CollisionShape3D:
			c.disabled = true
	slit_l.visible = not cama
	slit_r.visible = not cama
	slit_cama.visible = cama
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
	slit_cama.visible = false
	player.head.position.y = player.eye_height
	player.altura_fija = false
	_aguantando = false
	player.speed_mult = 1.0
	state = "juego"
	if normal:
		sound_at("crujido", player.global_position + Vector3(0, 1, 0), -4.0)

func _throw_salt() -> void:
	if salt <= 0:
		message("No me quedan bengalas.", 1.5)
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
		message("La bengala lo cegó. Ha huido.", 2.2)
	else:
		message("La bengala se apaga en el suelo. No había nadie.", 2.0)

# ---------------- atrapado / muerte ----------------
func _on_caught() -> void:
	if state in ["atrapado", "final", "muerte", "forcejeo"] or (autotest and get_meta("no_catch", false)):
		return
	# con un arma en la mano, todavía se puede pelear
	if defensa and defensa.puede_forcejear():
		state = "forcejeo"
		elena.can_catch = false
		player.frozen = true
		var to := elena.global_position - player.global_position
		player.set_look(atan2(-to.x, -to.z), 0.05)
		elena.global_position = player.global_position + Vector3(to.x, 0, to.z).normalized() * 0.9
		elena.look_at(Vector3(player.global_position.x, elena.global_position.y, player.global_position.z), Vector3.UP)
		elena.aturdir(2.6, "golpe")
		snd_ui.stream = _s("damian_rugido")
		snd_ui.volume_db = 2.0
		snd_ui.play()
		player.shake(14.0)
		defensa.empezar_forcejeo()
		return
	_morir_atrapada()

func _morir_atrapada() -> void:
	if state in ["atrapado", "final", "muerte"]:
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
	# el hachazo: Sofía cae de lado al suelo y la vista se queda mirándole desde abajo
	await get_tree().create_timer(0.55).timeout
	sound_at("damian_hacha" if ZarekSonido.hay("damian_hacha") else "golpe_madera", player.global_position + Vector3(0, 1.4, 0), 2.0)
	sound_at("carne" if ZarekSonido.hay("carne") else "aplastar", player.global_position + Vector3(0, 1.2, 0), 0.0)
	player.altura_fija = true
	var cae := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	cae.tween_property(player.head, "position:y", 0.25, 0.45)
	cae.tween_property(player.head, "rotation:z", 1.35, 0.45)
	cae.tween_property(player.head, "rotation:x", 0.35, 0.45)
	await get_tree().create_timer(0.45).timeout
	player.shake(10.0)
	await get_tree().create_timer(0.3).timeout
	_black_target = 1.0
	black.color.a = 1.0
	vig_mat.set_shader_parameter("red", 0.0)
	lives -= 1
	await get_tree().create_timer(1.2).timeout
	if lives <= 0:
		_lose()
		return
	player.head.rotation = Vector3.ZERO
	player.head.position.y = player.eye_height
	player.altura_fija = false
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
	lbl_end_t.text = "AHORA ERES LA CENA"
	lbl_end_s.text = "Objetos de la trampa: %d/%d · Tiempo: %s" % [seals, SEALS_NEEDED, _fmt(play_time)]
	end_box.visible = true
	snd_heart.volume_db = -60.0

func _ritual_start() -> void:
	message("Coloco el cepo junto al colchón, la gasolina en la puerta, el sedante en su agua…", 3.5)
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
	message("La trampa se cerró. Lo he encerrado.\nY desde el sótano, una voz de mujer: «Sofía… sácame de aquí…»", 5.0)
	await get_tree().create_timer(5.2).timeout
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hud_visible(false)
	var verdad := notas_leidas >= mansion.notas.size() and mansion.notas.size() > 0
	var oculto := ZarekSecretos.cuantos() >= ZarekSecretos.TOTAL
	if oculto:
		lbl_end_t.text = "FINAL OCULTO: LA HIJA DE LA ROCA"
		lbl_end_s.text = "Tiempo: %s\nLo he visto y escuchado todo. Inés no era mi madre: nací en esta casa en octubre de 1987.\nLa trampa se cierra sobre Damián, mi hermano. Pero no huyo. Bajo a la capilla.\nElla me sonríe. Y por primera vez en mi vida… tengo hambre de verdad." % _fmt(play_time)
	elif verdad:
		lbl_end_t.text = "FINAL VERDADERO"
		lbl_end_s.text = "Tiempo: %s · Veces atrapada: %d\nLo leí todo. Mi madre no huyó de esta casa: huyó de su hermana.\nY la mujer del sótano no pide ayuda… pide comida. Continuará." % [_fmt(play_time), deaths]
	else:
		lbl_end_t.text = "NOCHE I SUPERADA"
		lbl_end_s.text = "Tiempo: %s · Veces atrapada: %d · Notas: %d/%d\nLa carta no la escribió ningún abogado. Te estaban esperando… Continuará.\n(Lee todas las notas para el final verdadero)" % [_fmt(play_time), deaths, notas_leidas, mansion.notas.size()]
	if dif == 2:
		lbl_end_s.text += "\n☠ PESADILLA SUPERADA"
		Aether.save.set_value("zarek_pesadilla", true)
	lbl_end_s.text += "\nSecretos encontrados esta noche: %d · Archivo: %d/%d" % [secretos_noche.size(), ZarekSecretos.cuantos(), ZarekSecretos.TOTAL]
	lbl_end_s.text += "\n" + _rango()
	end_box.visible = true
	if oculto:
		_final("oculto")
	_final("verdadero" if verdad else "trampa")
	if verdad:
		_final("trampa")
	Aether.save.set_value("zarek_noche1", true)

## Rango de la noche: rapidez, veces atrapada, secretos y notas. Se guarda el mejor (motivo para repetir).
const RANGOS := [[92, "S", "Sombra"], [78, "A", "Fantasma"], [60, "B", "Superviviente"], [0, "C", "Presa"]]
func _rango() -> String:
	var p := 100.0 - deaths * 18.0 - maxf(0.0, (play_time - 540.0) / 20.0) + secretos_noche.size() * 3.0
	p += 6.0 if notas_leidas >= mansion.notas.size() else 0.0
	p += [-8.0, 0.0, 10.0][dif]
	var r: Array = RANGOS[RANGOS.size() - 1]
	for x in RANGOS:
		if p >= float(x[0]):
			r = x
			break
	var mejor := String(Aether.save.get_value("zarek_rango", ""))
	var orden := "SABC"
	var nuevo := mejor == "" or orden.find(String(r[1])) < orden.find(mejor)
	if nuevo:
		Aether.save.set_value("zarek_rango", r[1])
	return "RANGO %s · %s%s" % [r[1], r[2], "  ¡NUEVO RÉCORD!" if nuevo and mejor != "" else ""]

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
	# en el respiro la casa se calma: sustos más espaciados y suaves (el silencio también da miedo)
	if tension and tension.fase == "respiro":
		_scare_t *= 1.6
		pool = ["susurro", "risa", "golpes"]
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
## Música y ambientes que cambian según dónde estás (casa, sótano, túneles, título) y la persecución por encima.
var _musica_a: AudioStreamPlayer
var _musica_b: AudioStreamPlayer
var _musica_tema := ""
const MUSICA_DB := {"titulo": -8.0, "amb_casa": -14.0, "amb_sotano": -12.0, "amb_tunel": -12.0, "persecucion": -5.0, "": -60.0}
func _tema_musica() -> String:
	if state == "titulo":
		return "titulo"
	if state in ["muerte", "final"] or player == null:
		return ""
	if elena and elena.state == ZarekElena.S.CHASE and elena.visible:
		return "persecucion"
	var pp := player.global_position
	if not mansion.inside_house(pp) and pp.y > -0.5:
		return ""
	var r := mansion.room_at(pp)
	var tipo := String(mansion.rooms[r].type) if r >= 0 else ""
	if tipo in ["tunel", "roca", "agua"]:
		return "amb_tunel"
	if pp.y < -0.5:
		return "amb_sotano"
	return "amb_casa"

func _update_musica(delta: float) -> void:
	if _musica_a == null:
		return
	var t := _tema_musica()
	if t != _musica_tema and (t == "" or ZarekSonido.hay(t)):
		# el que suena pasa a B (se apaga) y el nuevo entra por A
		var tmp := _musica_b
		_musica_b = _musica_a
		_musica_a = tmp
		_musica_tema = t
		if t != "":
			var st: AudioStream = ZarekSonido.uno(t)
			if st is AudioStreamOggVorbis:
				(st as AudioStreamOggVorbis).loop = true
			_musica_a.stream = st
			_musica_a.volume_db = -40.0
			_musica_a.play()
	var objetivo: float = MUSICA_DB.get(_musica_tema, -60.0)
	var vel := 12.0 if _musica_tema == "persecucion" else 5.0
	if _musica_a.playing:
		_musica_a.volume_db = move_toward(_musica_a.volume_db, objetivo, delta * vel * 3.0)
	if _musica_b.playing:
		_musica_b.volume_db = move_toward(_musica_b.volume_db, -60.0, delta * vel * 2.0)
		if _musica_b.volume_db <= -59.0:
			_musica_b.stop()

func _update_audio(delta: float) -> void:
	_update_musica(delta)
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

# ---------------- la noche: suceso, secretos y archivo ----------------
func _empezar_suceso() -> void:
	match suceso:
		"tormenta":
			snd_lluvia = AudioStreamPlayer.new()
			var lluvia := "lluvia" if ZarekSonido.hay("lluvia") else "viento"
			snd_lluvia.stream = ZarekSonido.uno(lluvia)
			if snd_lluvia.stream is AudioStreamOggVorbis:
				(snd_lluvia.stream as AudioStreamOggVorbis).loop = true
			elif snd_lluvia.stream is AudioStreamWAV:
				(snd_lluvia.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
				(snd_lluvia.stream as AudioStreamWAV).loop_end = (snd_lluvia.stream as AudioStreamWAV).data.size() / 2
			snd_lluvia.volume_db = -10.0
			add_child(snd_lluvia)
			snd_lluvia.play()
			_t_trueno = randf_range(10.0, 20.0)
		"niebla":
			elena.vista = 0.6
		"apagon":
			if mansion.electricidad:
				mansion.electricidad.cortar()
		"luna_roja":
			elena.rapidez *= 1.12
			if luna:
				luna.light_color = Color(0.95, 0.35, 0.28)
				luna.light_energy *= 1.15

func _suceso_tick(delta: float) -> void:
	_trueno_tapa = maxf(0.0, _trueno_tapa - delta)
	if suceso != "tormenta":
		return
	var dentro := mansion.inside_house(player.global_position)
	if snd_lluvia:
		snd_lluvia.volume_db = lerpf(snd_lluvia.volume_db, -14.0 if dentro else -6.0, minf(1.0, delta * 2.0))
		# dentro se oye la lluvia contra el tejado y las ventanas (otra grabación)
		var quiero := "lluvia_dentro" if dentro and ZarekSonido.hay("lluvia_dentro") else "lluvia"
		if snd_lluvia.get_meta("cual", "lluvia") != quiero:
			snd_lluvia.set_meta("cual", quiero)
			var st := ZarekSonido.uno(quiero)
			if st is AudioStreamOggVorbis:
				(st as AudioStreamOggVorbis).loop = true
			snd_lluvia.stream = st
			snd_lluvia.play()
	_t_trueno -= delta
	if _t_trueno <= 0.0:
		_t_trueno = randf_range(14.0, 35.0)
		_trueno()

## Un rayo: destello (más fuerte fuera o junto a una ventana), trueno un momento después, y durante unos
## segundos el ruido tapa los pasos de Sofía.
func _trueno() -> void:
	var dentro := mansion.inside_house(player.global_position)
	Aether.flash(Color(0.8, 0.85, 1.0), 0.18 if dentro else 0.35)
	if luna:
		var e := luna.light_energy
		luna.light_energy = e * 6.0
		var tw := create_tween()
		tw.tween_property(luna, "light_energy", e, 0.5)
	await get_tree().create_timer(randf_range(0.3, 1.2)).timeout
	snd_ui.stream = ZarekSonido.uno("trueno") if ZarekSonido.hay("trueno") else AetherSynth.make("golpe_madera")
	snd_ui.volume_db = -2.0 if dentro else 2.0
	snd_ui.play()
	player.shake(2.5)
	_trueno_tapa = 3.5
	# a veces la tormenta hace saltar los plomos
	if randf() < 0.12:
		_corte_luz(0.4)

## Un secreto de la familia encontrado: se guarda al momento (aunque luego te atrapen).
func _secreto(id: String) -> void:
	var s := ZarekSecretos.dato(id)
	if s.is_empty():
		return
	var nuevo := ZarekSecretos.guardar(id)
	if not id in secretos_noche:
		secretos_noche.append(id)
	sound_at("pagina" if ZarekSonido.hay("pagina") else "recoger", player.global_position, -4.0)
	_leer_nota({"titulo": s[2], "texto": s[3], "leida": true})
	_poner_cinta(id)
	var n := ZarekSecretos.cuantos()
	if nuevo:
		message("SECRETO %d/%d · %s guardado en el archivo" % [n, ZarekSecretos.TOTAL, ZarekSecretos.ICONO[s[1]]], 3.5)
	else:
		message("Esto ya lo había visto en otra noche…", 2.0)
	sanity = maxf(0.0, sanity - 4.0)

## Las cintas se oyen (voces hechas con Kokoro, con efecto de cinta vieja) a la vez que se leen.
var snd_cinta: AudioStreamPlayer
func _poner_cinta(id: String) -> void:
	if not ZarekSonido.hay("cinta_" + id):
		return
	if snd_cinta == null:
		snd_cinta = AudioStreamPlayer.new()
		snd_cinta.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(snd_cinta)
	snd_cinta.stream = ZarekSonido.uno("cinta_" + id)
	snd_cinta.volume_db = 0.0
	snd_cinta.play()
	if state in ["juego", "escondido"] and elena:
		elena.hear(player.global_position, 4.0)  # la grabadora suena: algo de ruido

## Archivo: los secretos encontrados en todas las noches, para volver a leerlos.
func _abrir_archivo() -> void:
	if archivo_box:
		archivo_box.queue_free()
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.01, 0.01, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var hb := HBoxContainer.new()
	hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	hb.offset_left = 40
	hb.offset_right = -40
	hb.offset_top = 30
	hb.offset_bottom = -30
	hb.add_theme_constant_override("separation", 30)
	root.add_child(hb)
	var izq := VBoxContainer.new()
	izq.custom_minimum_size = Vector2(380, 0)
	izq.add_theme_constant_override("separation", 8)
	hb.add_child(izq)
	var tit := _label("ARCHIVO · %d/%d" % [ZarekSecretos.cuantos(), ZarekSecretos.TOTAL], 32, Color(0.82, 0.12, 0.12))
	izq.add_child(tit)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	izq.add_child(sc)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(lista)
	var texto := _label("Fotos, cartas y cintas escondidas en los cajones de la casa. Cada noche aparecen unas pocas, primero las que te faltan.\n\nLo que encuentras se guarda aunque te atrapen.", 22, Color(0.85, 0.8, 0.7))
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texto.size_flags_vertical = Control.SIZE_EXPAND_FILL
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(texto)
	var tengo := ZarekSecretos.encontrados()
	for s in ZarekSecretos.LISTA:
		var b := Button.new()
		var ok: bool = s[0] in tengo
		b.text = String(s[2]) if ok else "%s · ???" % ZarekSecretos.ICONO[s[1]]
		b.disabled = not ok
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 18)
		b.custom_minimum_size = Vector2(360, 44)
		b.clip_text = true
		if ok:
			b.pressed.connect(func():
				texto.text = String(s[2]).to_upper() + "\n\n" + String(s[3])
				if s[1] == "cinta":
					_poner_cinta(String(s[0]))
				elif snd_cinta:
					snd_cinta.stop())
		lista.add_child(b)
	var volver := Button.new()
	volver.text = "VOLVER"
	volver.custom_minimum_size = Vector2(200, 56)
	volver.add_theme_font_size_override("font_size", 24)
	volver.pressed.connect(func():
		if snd_cinta:
			snd_cinta.stop()
		root.queue_free()
		archivo_box = null)
	izq.add_child(volver)
	ui.add_child(root)
	archivo_box = root

## Lo que Damián recuerda de otras noches: dónde te escondes y si le engañas con el fonógrafo.
static func _clave_escondite(wd: Dictionary) -> String:
	var p: Vector3 = wd.pos
	return "%d_%d_%d" % [roundi(p.x), roundi(p.y), roundi(p.z)]

func _habitos() -> Dictionary:
	return Aether.save.get_value("zarek_habitos", {"esc": {}, "fono": 0})

func _anotar_escondite(wd: Dictionary) -> void:
	var h := _habitos()
	var esc: Dictionary = h.get("esc", {})
	var k := _clave_escondite(wd)
	esc[k] = int(esc.get(k, 0)) + 1
	h["esc"] = esc
	Aether.save.set_value("zarek_habitos", h)

## Cuánto conoce un escondite (0-1): sube con cada vez que te has escondido ahí, en esta noche y en otras.
func _conoce_escondite(wd: Dictionary) -> float:
	var veces := int((_habitos().get("esc", {}) as Dictionary).get(_clave_escondite(wd), 0))
	return clampf((veces - 1) * 0.12, 0.0, 0.5)
