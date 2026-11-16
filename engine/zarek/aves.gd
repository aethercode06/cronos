extends Node3D
class_name ZarekAves
## Fauna nocturna del bosque (modelos reales de Sketchfab, CC-BY, vía Objaverse):
## - Búhos y lechuzas posados por el bosque, quietos, que giran despacio hacia el jugador cuando se acerca.
## - Búhos en vuelo bajo y silencioso entre los árboles: largas curvas, algún aleteo y mucho planeo.
## - En el árbol viejo (antes «de los cuervos») una lechuza sale volando hacia el jugador y chilla.
## - Murciélagos revoloteando rápido alrededor del tejado de la mansión y del estanque.
## - Polillas alrededor de las luces del porche.
## Ululatos lejanos de vez en cuando (sonido 3D desde un búho real).
var jugador: Node3D
var juego: Node
var nido := Vector3.ZERO
var _rng := RandomNumberGenerator.new()
var _posados: Array = []    # {nodo, yaw0}
var _voladores: Array = []  # {nodo, anim, c, r, h, vel, fase, aleta}
var _murcis: Array = []     # {nodo, c, fase, vel, r, h}
var _polillas: Array = []
var _susto: Dictionary = {}
var _susto_hecho := false
var _t_canto := 8.0

func setup(p_jugador: Node3D, p_juego: Node, p_nido: Vector3, bosque: Rect2, evitar: Array, tejado: Vector3, estanque: Vector3, porche: Vector3) -> void:
	jugador = p_jugador
	juego = p_juego
	nido = p_nido
	_rng.seed = 1874
	# posados: cada uno con su tocón o rama (ya viene en el modelo)
	var posados := ["ave_common_barn_owl", "ave_eastern_screech_owl", "ave_snowy_owl", "ave_great_horned_owl"]
	var colocados := 0
	var intentos := 0
	while colocados < 10 and intentos < 400:
		intentos += 1
		var p := Vector3(_rng.randf_range(bosque.position.x + 8, bosque.end.x - 8), 0, _rng.randf_range(bosque.position.y + 8, bosque.end.y - 8))
		var mal := false
		for r in evitar:
			if (r as Rect2).has_point(Vector2(p.x, p.z)):
				mal = true
				break
		if mal:
			continue
		var n := _instancia("res://zarek/objetos/%s.glb" % posados[colocados % posados.size()])
		if n == null:
			break
		n.position = p
		n.rotation.y = _rng.randf() * TAU
		_posados.append({"nodo": n, "yaw0": n.rotation.y})
		colocados += 1
	# uno en el árbol viejo, que será el que salga volando
	var vigia := _instancia("res://zarek/objetos/ave_common_barn_owl.glb")
	if vigia:
		vigia.position = nido + Vector3(1.2, 0, 0.8)
		_posados.append({"nodo": vigia, "yaw0": 0.0, "vigia": true})
	# en vuelo: búhos nivales animados (aleteo real) y búhos pardos planeando
	for k in 4:
		var animado := k % 2 == 0
		var n := _instancia("res://zarek/animales/ave_day_20_snowy_owl.glb" if animado else "res://zarek/objetos/ave_owl.glb")
		if n == null:
			continue
		if animado:
			n.scale = Vector3.ONE * (1.25 / 3.58)
		var c := Vector3(_rng.randf_range(bosque.position.x + 20, bosque.end.x - 20), 0, _rng.randf_range(bosque.position.y + 20, bosque.end.y - 20))
		_voladores.append({"nodo": n, "anim": _anim(n, 0.8), "c": c, "r": _rng.randf_range(16.0, 30.0), "h": _rng.randf_range(4.5, 8.5), "vel": _rng.randf_range(0.12, 0.2) * (1.0 if k < 2 else -1.0), "fase": _rng.randf() * TAU, "aleta": 0.0})
	# murciélagos alrededor del tejado y del estanque
	for grupo in [[tejado, 9], [estanque, 7]]:
		for k in int(grupo[1]):
			var arch := "res://zarek/animales/ave_bat_flying.glb" if k % 3 != 0 else "res://zarek/animales/ave_bat_animated_character.glb"
			var n := _instancia(arch)
			if n == null:
				continue
			n.scale = Vector3.ONE * ((0.34 / 31.42) if arch.ends_with("bat_flying.glb") else (0.32 / 18.43))
			_anim(n, _rng.randf_range(2.2, 3.0))
			_murcis.append({"nodo": n, "c": grupo[0], "fase": _rng.randf() * TAU, "vel": _rng.randf_range(1.3, 2.2), "r": _rng.randf_range(3.0, 9.0), "h": _rng.randf_range(2.5, 6.0)})
	# polillas en las luces del porche
	for k in 6:
		var n := _instancia("res://zarek/objetos/ave_moth_number_1.glb")
		if n:
			_polillas.append({"nodo": n, "c": porche + Vector3(_rng.randf_range(-6, 6), 0, 0), "fase": _rng.randf() * TAU})

func _instancia(path: String) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var ps: PackedScene = load(path)
	if ps == null:
		return null
	var n: Node3D = ps.instantiate()
	add_child(n)
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return n

func _anim(n: Node3D, vel: float) -> AnimationPlayer:
	var ap: AnimationPlayer = n.find_child("AnimationPlayer", true, false)
	if ap == null:
		var lista := n.find_children("*", "AnimationPlayer", true, false)
		if lista.is_empty():
			return null
		ap = lista[0]
	var nombres := ap.get_animation_list()
	if nombres.is_empty():
		return null
	var a := ap.get_animation(nombres[0])
	a.loop_mode = Animation.LOOP_LINEAR
	ap.play(nombres[0])
	ap.speed_scale = vel
	ap.seek(randf() * a.length)
	return ap

func _process(delta: float) -> void:
	if jugador == null:
		return
	var t := Time.get_ticks_msec() / 1000.0
	var jp := jugador.global_position
	var fuera: bool = juego == null or not juego.mansion.inside_house(jp)
	visible = fuera
	if not fuera:
		return
	# posados: giran hacia el jugador cuando está cerca (como hacen los búhos), y vuelven poco a poco
	for po in _posados:
		var n: Node3D = po.nodo
		if not n.visible:
			continue
		var d := Vector2(jp.x - n.position.x, jp.z - n.position.z)
		var objetivo: float = po.yaw0
		if d.length() < 14.0:
			objetivo = atan2(d.x, d.y)
		n.rotation.y = lerp_angle(n.rotation.y, objetivo, minf(1.0, delta * 0.9))
	# vuelo: lemniscatas amplias y lentas, a poca altura entre los troncos
	for v in _voladores:
		var n: Node3D = v.nodo
		v.fase += v.vel * delta
		var f: float = v.fase
		var p := Vector3(v.c.x + sin(f) * v.r, v.h + sin(f * 2.3) * 1.2, v.c.z + sin(f) * cos(f) * v.r * 0.9)
		var dir := p - n.position
		n.position = p
		if dir.length() > 0.0001:
			n.rotation.y = lerp_angle(n.rotation.y, atan2(dir.x, dir.z), minf(1.0, delta * 3.0))
			n.rotation.z = lerpf(n.rotation.z, clampf(-angle_difference(n.rotation.y, atan2(dir.x, dir.z)) * 2.0, -0.4, 0.4), delta * 2.0)
		# aletea a ratos y planea el resto (la animación se para con las alas abiertas)
		var ap: AnimationPlayer = v.anim
		if ap:
			v.aleta = fmod(v.aleta + delta, 7.0)
			ap.speed_scale = 0.9 if v.aleta < 2.2 else 0.0
	# la lechuza del árbol viejo: al acercarse el jugador sale volando hacia él, chilla y se pierde en el bosque
	if not _susto_hecho and Vector2(jp.x - nido.x, jp.z - nido.z).length() < 10.0:
		_susto_hecho = true
		for po in _posados:
			if po.has("vigia"):
				(po.nodo as Node3D).visible = false
		var lechuza := _instancia("res://zarek/animales/ave_day_20_snowy_owl.glb")
		if lechuza:
			lechuza.scale = Vector3.ONE * (1.25 / 3.58)
			lechuza.position = nido + Vector3(1.2, 0.5, 0.8)
			_anim(lechuza, 1.6)
			var hacia := (jp + Vector3(0, 1.9, 0)) - lechuza.position
			_susto = {"nodo": lechuza, "t": 0.0, "dir": hacia.normalized(), "lejos": Vector3(-hacia.x, 0, -hacia.z).normalized()}
		if juego:
			juego.sound_at("lechuza", nido + Vector3(0, 1.5, 0), 9.0)
			juego.sound_at("aleteo", nido + Vector3(0, 1, 0), 2.0)
	if not _susto.is_empty():
		var n: Node3D = _susto.nodo
		_susto.t += delta
		var vel: Vector3 = _susto.dir * 9.0
		if _susto.t > 0.9:
			# pasa rozando por encima de la cabeza y se aleja subiendo
			vel = (_susto.dir * 0.4 + _susto.lejos * -0.2 + Vector3(0, 0.35, 0)).normalized() * 8.0
		n.position += vel * delta
		n.rotation.y = atan2(vel.x, vel.z)
		if _susto.t > 7.0:
			n.queue_free()
			_susto = {}
	# murciélagos: vuelo nervioso, cambios bruscos de dirección
	for m in _murcis:
		var n: Node3D = m.nodo
		m.fase += m.vel * delta
		var f: float = m.fase
		var p := Vector3(m.c.x + cos(f) * m.r + sin(f * 3.7) * 1.4, m.c.y + m.h + sin(f * 2.9) * 1.1, m.c.z + sin(f * 1.3) * m.r + cos(f * 4.1) * 1.2)
		var dir := p - n.position
		n.position = p
		if dir.length() > 0.0001:
			n.rotation.y = atan2(dir.x, dir.z)
	# polillas: vueltas cortas y erráticas cerca de la luz
	for pl in _polillas:
		var n: Node3D = pl.nodo
		pl.fase += delta * 3.0
		var f: float = pl.fase
		n.position = pl.c + Vector3(sin(f * 1.7) * 0.5 + sin(f * 5.3) * 0.12, 2.6 + sin(f * 2.3) * 0.35, cos(f * 1.3) * 0.5)
		n.rotation.y = f * 2.0
	# cantos de búho lejanos desde alguno de verdad
	_t_canto -= delta
	if _t_canto <= 0.0 and juego != null:
		_t_canto = _rng.randf_range(9.0, 22.0)
		var mejor := Vector3.ZERO
		var dmin := 1e9
		for po in _posados:
			var d := (po.nodo as Node3D).position.distance_to(jp)
			if d > 12.0 and d < dmin:
				dmin = d
				mejor = (po.nodo as Node3D).position
		if dmin < 60.0:
			juego.sound_at("ululato" if _rng.randf() < 0.8 else "lechuza", mejor + Vector3(0, 0.6, 0), 4.0)
