class_name ZarekElectricidad
extends RefCounted
## La instalación eléctrica de la mansión:
## - un interruptor de baquelita junto a la puerta de cada sala con lámparas (enciende o apaga toda la sala);
## - el cuadro eléctrico del sótano (sala de calderas): fusibles de porcelana y un interruptor general de palanca;
## - apagones: si alguien baja la palanca, toda la casa se queda a oscuras hasta que vuelvas a subirla.
## Las bombillas fundidas no se encienden aunque haya corriente.

var m: ZarekMansion
var corriente := true
var interruptores: Array = []   # {pos, room, nodo, palanca, on}
var cuadro := {}                # {pos, nodo, palanca, puerta}
var _rng := RandomNumberGenerator.new()

func instalar(mansion: ZarekMansion) -> void:
	m = mansion
	_rng.seed = 4040
	_interruptores()
	_cuadro()
	print("ZAREK electricidad: %d interruptores, cuadro %s" % [interruptores.size(), "sí" if not cuadro.is_empty() else "no"])

# ---------------- interruptores ----------------
func _interruptores() -> void:
	var hecho := {}
	for d in m.doors:
		if not d.has("ids"):
			continue
		for id in d.ids:
			var rid := int(id)
			if rid < 0 or hecho.has(rid) or rid >= m.rooms.size():
				continue
			var r: Dictionary = m.rooms[rid]
			if (r.get("lamps", []) as Array).is_empty():
				continue
			var p := _junto_a_puerta(d, rid)
			if p.is_empty():
				continue
			hecho[rid] = true
			_poner_interruptor(p.pos, p.fuera, rid)

## Punto de la pared al lado de la puerta, por dentro de la sala, a la altura de la mano.
func _junto_a_puerta(d: Dictionary, rid: int) -> Dictionary:
	var c: Vector3 = d.pos
	var horiz: bool = d.horiz
	var gap: float = float(d.get("gap", 1.5))
	var normal := Vector3(0, 0, 1) if horiz else Vector3(1, 0, 0)
	var a_lo_largo := Vector3(1, 0, 0) if horiz else Vector3(0, 0, 1)
	var dentro := normal
	if m.room_at(c + normal * 0.6 + Vector3(0, 0.3, 0)) != rid:
		dentro = -normal
		if m.room_at(c + dentro * 0.6 + Vector3(0, 0.3, 0)) != rid:
			return {}
	for lado in [1.0, -1.0]:
		var p: Vector3 = c + a_lo_largo * lado * (gap * 0.5 + 0.3) + dentro * (ZarekMansion.WT * 0.5 + 0.012)
		# que siga habiendo pared ahí (no otra puerta ni una esquina abierta)
		if m.room_at(p + dentro * 0.4 + Vector3(0, 0.3, 0)) != rid:
			continue
		if m.room_at(p - dentro * 0.4 + Vector3(0, 0.3, 0)) == rid:
			continue
		return {"pos": Vector3(p.x, float(m.rooms[rid].y) + 1.25, p.z), "fuera": dentro}
	return {}

func _poner_interruptor(p: Vector3, fuera: Vector3, rid: int) -> void:
	var n := Node3D.new()
	n.position = p
	n.rotation.y = atan2(fuera.x, fuera.z)
	n.set_meta("dyn", true)
	m._house.add_child(n)
	# placa de baquelita marrón con dos tornillos y la palanquita de porcelana
	var placa := m.box(Vector3(0.085, 0.13, 0.012), Vector3(0, 0, 0.006), _mat_baquelita(), false, n, false)
	placa.set_meta("dyn", true)
	for y in [-0.045, 0.045]:
		m.cyl(0.006, 0.006, 0.004, Vector3(0, y, 0.013), m._mat.laton_viejo, n, 6).rotation.x = PI * 0.5
	var base := m.cyl(0.016, 0.016, 0.01, Vector3(0, 0, 0.016), _mat_baquelita(), n, 10)
	base.rotation.x = PI * 0.5
	var palanca := Node3D.new()
	palanca.position = Vector3(0, 0, 0.02)
	n.add_child(palanca)
	var pal := m.cyl(0.006, 0.0045, 0.03, Vector3(0, 0.015, 0), _mat_porcelana(), palanca, 6)
	pal.set_meta("dyn", true)
	# mugre alrededor del interruptor (manos sucias)
	ZarekTerror._calco(m, "humedad_2", p + fuera * 0.004, fuera, Vector2(0.22, 0.26), _rng.randf() * TAU)
	var on := false
	for l in m.rooms[rid].get("lamps", []):
		if not l.broken:
			on = true
	var it := {"pos": p, "room": rid, "nodo": n, "palanca": palanca, "on": on}
	_palanca(it)
	interruptores.append(it)

var _mb: StandardMaterial3D
var _mp: StandardMaterial3D
func _mat_baquelita() -> StandardMaterial3D:
	if _mb == null:
		_mb = m._plain(Color(0.16, 0.09, 0.05), 0.35, 0.0)
	return _mb
func _mat_porcelana() -> StandardMaterial3D:
	if _mp == null:
		_mp = m._plain(Color(0.86, 0.82, 0.72), 0.25, 0.0)
	return _mp

func _palanca(it: Dictionary) -> void:
	(it.palanca as Node3D).rotation.x = -0.5 if it.on else 0.5

func interruptor_cerca(p: Vector3, dist := 1.4) -> Dictionary:
	var mejor := {}
	var bd := dist
	for it in interruptores:
		var d := (it.pos as Vector3).distance_to(p + Vector3(0, 1.0, 0))
		if d < bd:
			bd = d
			mejor = it
	return mejor

## Pulsa el interruptor: cambia la sala entera (si hay corriente; las fundidas siguen apagadas).
func pulsar(it: Dictionary) -> bool:
	it.on = not it.on
	_palanca(it)
	_aplicar_sala(int(it.room))
	return corriente

func apagar_sala(rid: int) -> void:
	for it in interruptores:
		if int(it.room) == rid and it.on:
			it.on = false
			_palanca(it)
	_aplicar_sala(rid)

func sala_encendida(rid: int) -> bool:
	for it in interruptores:
		if int(it.room) == rid:
			return it.on
	return true

func _aplicar_sala(rid: int) -> void:
	var on := corriente and sala_encendida(rid)
	for l in m.rooms[rid].get("lamps", []):
		m.set_lamp(l, on)

func cortar() -> void:
	corriente = false
	if not cuadro.is_empty():
		(cuadro.palanca as Node3D).rotation.x = 0.9
	for l in m.lamps:
		m.set_lamp(l, false)

func devolver() -> void:
	corriente = true
	if not cuadro.is_empty():
		(cuadro.palanca as Node3D).rotation.x = -0.9
	for i in m.rooms.size():
		if not (m.rooms[i].get("lamps", []) as Array).is_empty():
			_aplicar_sala(i)

# ---------------- cuadro eléctrico ----------------
func _cuadro() -> void:
	var r := m._sala_por_nombre("Sala de calderas")
	if r.is_empty():
		r = m._sala_por_nombre("Pasillo del sótano")
	if r.is_empty():
		return
	var rc: Rect2 = r.rect
	var y := float(r.y)
	# en la pared más larga libre de puertas, cerca de una esquina
	var cand := [
		[Vector3(rc.position.x + 1.2, y, rc.position.y + 0.02), Vector3(0, 0, 1)],
		[Vector3(rc.end.x - 1.2, y, rc.position.y + 0.02), Vector3(0, 0, 1)],
		[Vector3(rc.position.x + 0.02, y, rc.position.y + 1.4), Vector3(1, 0, 0)],
		[Vector3(rc.end.x - 0.02, y, rc.end.y - 1.4), Vector3(-1, 0, 0)],
		[Vector3(rc.position.x + 1.2, y, rc.end.y - 0.02), Vector3(0, 0, -1)]]
	for c in cand:
		var p: Vector3 = c[0]
		var fuera: Vector3 = c[1]
		if not m.door_near(p, 1.6).is_empty():
			continue
		p += fuera * (ZarekMansion.WT * 0.5 - 0.1)
		_poner_cuadro(p, fuera)
		return

func _poner_cuadro(p: Vector3, fuera: Vector3) -> void:
	var n := Node3D.new()
	n.position = p + Vector3(0, 1.35, 0)
	n.rotation.y = atan2(fuera.x, fuera.z)
	n.set_meta("dyn", true)
	m._house.add_child(n)
	var chapa := m._plain(Color(0.2, 0.22, 0.2), 0.55, 0.6)
	var oxido := m._plain(Color(0.32, 0.18, 0.1), 0.85, 0.2)
	# armario de chapa (fondo y laterales) con la puerta abierta colgando de una bisagra
	m.box(Vector3(0.62, 0.8, 0.04), Vector3(0, 0, 0.02), chapa, false, n, false)
	for sx in [-1.0, 1.0]:
		m.box(Vector3(0.025, 0.8, 0.16), Vector3(sx * 0.3, 0, 0.08), chapa, false, n, false)
	for sy in [-1.0, 1.0]:
		m.box(Vector3(0.62, 0.025, 0.16), Vector3(0, sy * 0.39, 0.08), chapa, false, n, false)
	var puerta := Node3D.new()
	puerta.position = Vector3(-0.31, 0, 0.16)
	puerta.rotation.y = -1.9
	n.add_child(puerta)
	m.box(Vector3(0.6, 0.78, 0.02), Vector3(0.3, 0, 0), chapa, false, puerta, false)
	m.box(Vector3(0.12, 0.12, 0.022), Vector3(0.45, 0.25, 0.0), oxido, false, puerta, false)
	# rayo de peligro pintado
	var aviso := m._plain(Color(0.75, 0.6, 0.1), 0.6)
	m.box(Vector3(0.1, 0.1, 0.004), Vector3(0.3, 0.15, 0.012), aviso, false, puerta, false).rotation.z = PI * 0.25
	# dos filas de fusibles de porcelana con su tapón
	for fila in 2:
		for k in 5:
			var fp := Vector3(-0.2 + k * 0.08, 0.2 - fila * 0.16, 0.06)
			m.box(Vector3(0.05, 0.1, 0.035), fp, _mat_porcelana(), false, n, false)
			var tap := m.cyl(0.016, 0.016, 0.02, fp + Vector3(0, 0, 0.025), m._plain(Color(0.1, 0.1, 0.1) if (fila + k) % 3 else Color(0.5, 0.12, 0.08), 0.5), n, 8)
			tap.rotation.x = PI * 0.5
	# interruptor general de cuchillas con su palanca larga
	m.box(Vector3(0.24, 0.2, 0.03), Vector3(0, -0.22, 0.05), _mat_porcelana(), false, n, false)
	var palanca := Node3D.new()
	palanca.position = Vector3(0, -0.22, 0.09)
	n.add_child(palanca)
	m.box(Vector3(0.16, 0.012, 0.012), Vector3(0, 0.0, 0.0), m._mat.metal, false, palanca, false)
	for sx in [-0.06, 0.06]:
		m.box(Vector3(0.012, 0.18, 0.012), Vector3(sx, 0.09, 0.0), m._mat.metal, false, palanca, false)
	m.box(Vector3(0.18, 0.035, 0.035), Vector3(0, 0.18, 0.0), m._plain(Color(0.08, 0.06, 0.05), 0.4), false, palanca, false)
	palanca.rotation.x = -0.9
	# cables que bajan y suben por la pared
	for k in 4:
		var cx := -0.22 + k * 0.15
		m.cyl(0.01, 0.01, 1.3, Vector3(cx, 1.05, 0.03), m._plain(Color(0.06, 0.05, 0.04), 0.6), n, 5)
		m.cyl(0.01, 0.01, 0.9, Vector3(cx + 0.03, -0.85, 0.03), m._plain(Color(0.06, 0.05, 0.04), 0.6), n, 5)
	# bombillita roja de aviso
	var piloto := m._plain(Color(0.6, 0.05, 0.03), 0.3)
	piloto.emission_enabled = true
	piloto.emission = Color(1, 0.1, 0.05)
	piloto.emission_energy_multiplier = 2.0
	m.cyl(0.015, 0.015, 0.02, Vector3(0.2, -0.3, 0.07), piloto, n, 8).rotation.x = PI * 0.5
	var zumbido := AudioStreamPlayer3D.new()
	zumbido.stream = AetherSynth.make("zumbido")
	zumbido.volume_db = -20.0
	zumbido.unit_size = 1.5
	zumbido.max_distance = 7.0
	n.add_child(zumbido)
	cuadro = {"pos": n.global_position if n.is_inside_tree() else p + Vector3(0, 1.35, 0), "nodo": n, "palanca": palanca, "piloto": piloto, "zumbido": zumbido}

func cuadro_cerca(p: Vector3, dist := 1.8) -> bool:
	return not cuadro.is_empty() and (cuadro.pos as Vector3).distance_to(p + Vector3(0, 1.2, 0)) < dist
