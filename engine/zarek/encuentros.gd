class_name ZarekEncuentros
extends Node
## Encuentros con Damián preparados por el director cuando lleva un rato sin pasar nada (para que la casa no se
## quede vacía y él se VEA, no solo se oiga). Nunca te atrapan sin darte un instante para reaccionar:
## - CRUCE: al fondo de lo que miras, Damián cruza el pasillo o la sala con el hacha arrastrando. Si sigues a la
##   vista cuando termina de cruzar, te ve.
## - TRAS LA PUERTA: abres una puerta y está ahí, a dos pasos. Ruge, te deja un segundo y va a por ti.
## - DETRÁS DE TI: si te quedas quieta, oyes su respiración detrás. Si te giras, está ahí.
## - AL VERTE: cada vez que empieza a perseguirte, golpe de sonido, la cámara tiembla y late el corazón.

var j: Node  # ZarekJuego
var _t := 70.0          # hasta el próximo encuentro
var _quieta := 0.0
var _detras := {}       # encuentro «detrás de ti» en marcha
var _t_puerta := 0.0    # espera entre sustos de puerta
var hechos := {}        # para el diagnóstico

func _ready() -> void:
	_t = randf_range(20.0, 35.0)  # al salir de la celda, enseguida se le ve: el jugador tiene que saber quién es

func conectar() -> void:
	var e: ZarekElena = j.elena
	if not e.te_vio.is_connected(_al_verte):
		e.te_vio.connect(_al_verte)

func _libre() -> bool:
	var e: ZarekElena = j.elena
	return j.state == "juego" and j.entered and not j.huida.en_celda and e.es_damian \
		and e.state != ZarekElena.S.CHASE and e.aturdido <= 0.0 and e.quieto <= 0.0 and not j.autotest and j.hidden_in.is_empty()

func _contar(k: String) -> void:
	hechos[k] = int(hechos.get(k, 0)) + 1

func tick(delta: float) -> void:
	if j == null or j.elena == null:
		return
	_t_puerta = maxf(0.0, _t_puerta - delta)
	_detras_tick(delta)
	if not _libre():
		return
	var e: ZarekElena = j.elena
	var pp: Vector3 = j.player.global_position
	# quieta mucho rato a oscuras: él viene por detrás
	var hv := Vector2(j.player.velocity.x, j.player.velocity.z).length()
	_quieta = _quieta + delta if hv < 0.2 else 0.0
	_t -= delta
	if _t > 0.0:
		return
	# si ya está cerca y a la vista, no hace falta preparar nada
	if e.visible and e.global_position.distance_to(pp) < 9.0 and absf(e.global_position.y - pp.y) < 2.5:
		_t = 20.0
		return
	var hecho := false
	if _quieta > 5.0:
		hecho = _empezar_detras()
	if not hecho:
		hecho = _cruce()
	if not hecho and randf() < 0.5:
		hecho = _empezar_detras()
	_t = randf_range(45.0, 75.0) if hecho else 8.0

# ---------------- cruce ----------------
func _cruce() -> bool:
	var e: ZarekElena = j.elena
	var cam: Camera3D = j.player.camera
	var ojo := cam.global_position
	var fw: Vector3 = j.player.look_dir()
	fw.y = 0
	if fw.length() < 0.1:
		return false
	fw = fw.normalized()
	var esp: PhysicsDirectSpaceState3D = j.player.get_world_3d().direct_space_state
	# ¿hasta dónde se ve al frente?
	var q := PhysicsRayQueryParameters3D.create(ojo, ojo + fw * 18.0, 1)
	q.exclude = [j.player.get_rid()]
	var hit := esp.intersect_ray(q)
	var lejos: float = ojo.distance_to(hit.position) if hit.has("position") else 18.0
	if lejos < 4.0:
		return false
	var dist := clampf(lejos - 1.0, 4.0, 14.0)
	var centro := Vector3(ojo.x, j.player.global_position.y, ojo.z) + fw * dist
	var lado := Vector3(-fw.z, 0, fw.x)
	var m: ZarekMansion = j.mansion
	# de un lado al otro, por suelo de verdad
	var a := centro - lado * 2.6
	var b := centro + lado * 2.6
	if m.room_at(a + Vector3(0, 0.4, 0)) < 0 or m.room_at(b + Vector3(0, 0.4, 0)) < 0 or m.room_at(centro + Vector3(0, 0.4, 0)) < 0:
		lado = -lado
		a = centro - lado * 1.4
		b = centro + lado * 1.4
		if m.room_at(a + Vector3(0, 0.4, 0)) < 0 or m.room_at(b + Vector3(0, 0.4, 0)) < 0:
			return false
	var ruta := m.path(a, b)
	if ruta.is_empty():
		return false
	e.visible = true
	e.global_position = a
	e.set_state(ZarekElena.S.WANDER)
	e.path = ruta
	e.ciego = 3.2  # va a lo suyo: si sigues a la vista cuando termina, te ve
	e.look_at(Vector3(b.x, e.global_position.y, b.z), Vector3.UP)
	j.sound_at("damian_hacha", a + Vector3(0, 0.3, 0), -6.0)
	j.sound_at("damian_resp", a + Vector3(0, 1.6, 0), -8.0)
	j._consejo("cruce", "Si le ves pasar sin que te vea: no corras (te oiría). Agáchate, apártate de su vista y busca dónde esconderte.")
	_contar("cruce")
	return true

# ---------------- tras la puerta ----------------
## Lo llama juego.gd al abrir del todo una puerta cerrada.
func al_abrir_puerta(d: Dictionary) -> void:
	if not _libre() or _t_puerta > 0.0 or randf() > 0.14:
		return
	var e: ZarekElena = j.elena
	var m: ZarekMansion = j.mansion
	var pp: Vector3 = j.player.global_position
	var dp: Vector3 = d.pos
	var otro := Vector3(dp.x - pp.x, 0, dp.z - pp.z).normalized()
	var donde := Vector3(dp.x, pp.y, dp.z) + otro * 1.7
	var sala_d := m.room_at(donde + Vector3(0, 0.4, 0))
	if sala_d < 0 or sala_d == m.room_at(pp + Vector3(0, 0.4, 0)):
		return
	_t_puerta = 240.0
	_t = maxf(_t, 50.0)
	e.visible = true
	e.global_position = donde
	e.look_at(Vector3(pp.x, donde.y, pp.z), Vector3.UP)
	e.set_state(ZarekElena.S.WANDER)
	e.path = []
	e.quieto = 0.9  # un segundo de cara a cara antes de lanzarse
	j.sound_at("susto", pp + Vector3(0, 1.5, 0), 2.0)
	j.sound_at("damian_rugido", donde + Vector3(0, 1.6, 0), 4.0)
	j.player.shake(10.0)
	Aether.flash(Color(0.4, 0.0, 0.0), 0.18)
	j.sanity = maxf(0.0, j.sanity - 8.0)
	await get_tree().create_timer(0.9).timeout
	# te da con la puerta en las narices (portazo) y la abre a patadas un momento después: tiempo justo para correr
	if is_instance_valid(e) and e.state != ZarekElena.S.DORMANT:
		m.set_door(d, false, true)
		d.snd.stream = ZarekSonido.uno("portazo")
		d.snd.play()
		j.player.shake(6.0)
		e.quieto = 1.3
		await get_tree().create_timer(1.3).timeout
		if is_instance_valid(e):
			m.set_door(d, true, true)
			e.last_seen = j.player.global_position
			e._start_chase()
			j.player.adrenalina = 3.5
	_contar("puerta")

# ---------------- detrás de ti ----------------
func _empezar_detras() -> bool:
	var e: ZarekElena = j.elena
	var m: ZarekMansion = j.mansion
	var pp: Vector3 = j.player.global_position
	var atras: Vector3 = -j.player.look_dir()
	atras.y = 0
	atras = atras.normalized()
	var donde := pp + atras * 3.2
	if m.room_at(donde + Vector3(0, 0.4, 0)) != m.room_at(pp + Vector3(0, 0.4, 0)):
		donde = pp + atras * 2.0
		if m.room_at(donde + Vector3(0, 0.4, 0)) != m.room_at(pp + Vector3(0, 0.4, 0)):
			return false
	var q := PhysicsRayQueryParameters3D.create(pp + Vector3(0, 1.5, 0), donde + Vector3(0, 1.5, 0), 1)
	if not j.player.get_world_3d().direct_space_state.intersect_ray(q).is_empty():
		return false
	e.visible = true
	e.global_position = donde
	e.look_at(Vector3(pp.x, donde.y, pp.z), Vector3.UP)
	e.set_state(ZarekElena.S.WANDER)
	e.path = []
	e.quieto = 4.5  # quieto, respirando detrás de ti
	e.ciego = 4.5
	j.sound_at("damian_resp", donde + Vector3(0, 1.7, 0), 0.0)
	_detras = {"t": 0.0, "pos": donde, "yaw0": j.player._yaw}
	_contar("detras")
	return true

func _detras_tick(delta: float) -> void:
	if _detras.is_empty():
		return
	var e: ZarekElena = j.elena
	_detras.t = float(_detras.t) + delta
	var pp: Vector3 = j.player.global_position
	var to: Vector3 = (_detras.pos as Vector3) - pp
	to.y = 0
	var lo_mira: bool = j.player.look_dir().normalized().dot(to.normalized()) > 0.6
	if lo_mira and float(_detras.t) > 0.3:
		# te giras y está ahí
		_detras = {}
		j.sound_at("susto", pp + Vector3(0, 1.5, 0), 3.0)
		j.player.shake(12.0)
		Aether.flash(Color(0.45, 0.0, 0.0), 0.2)
		j.sanity = maxf(0.0, j.sanity - 10.0)
		e.quieto = 1.1
		e.ciego = 0.0
		j.player.adrenalina = 4.0
		await get_tree().create_timer(1.1).timeout
		if is_instance_valid(e):
			e.last_seen = j.player.global_position
			e._start_chase()
	elif float(_detras.t) > 4.0 or not j.hidden_in.is_empty() or pp.distance_to(_detras.pos) > 7.0:
		# no te has girado: se va despacio (lo oyes alejarse)
		_detras = {}
		e.quieto = 0.0
		e.ciego = 2.0
		e.set_state(ZarekElena.S.WANDER)
		e.path = j.mansion.path(e.global_position, j.mansion.random_floor(pp, 12.0))
		j.sound_at("damian_paso", e.global_position, -4.0)

# ---------------- al verte ----------------
func _al_verte() -> void:
	if j.state != "juego":
		return
	j.sound_at("susto", j.player.global_position + Vector3(0, 1.5, 0), 0.0)
	j.player.shake(7.0)
	Aether.flash(Color(0.35, 0.0, 0.0), 0.12)
	j.player.adrenalina = 3.5
	j._consejo("persecucion", "¡Te ha visto! CORRE (empuja el joystick hasta el borde), rompe su línea de visión y escóndete. En una persecución, cerrar puertas tras de ti le frena.")
