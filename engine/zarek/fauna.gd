class_name ZarekFauna
extends Node3D
## Bichos de la casa: ratas que corretean pegadas a las paredes y huyen de ti y de la linterna, gusanos que se
## arrastran en el sótano y la cocina (y se aplastan si los pisas) y un gato negro que vive en la casa: deambula,
## se sienta a mirarte, te sigue de lejos, ronronea si te acercas despacio, y bufa y huye cuando Elena está cerca.
## Modelos animados de Objaverse (CC-BY, créditos en objetos/creditos.json).

## modelo, largo real (m), giro para que mire a +Z, nombre de la animación al andar (vacío = la primera)
const MODELOS := {
	"rata": [["an_rata_4", 0.26, 0.0], ["an_rata_4", 0.24, 0.0], ["an_rata_4", 0.25, 0.0], ["an_rata_negra", 0.26, 0.0]],
	"gato": [["gato_real", 0.62, 0.0]],
	"gusano": [["an_gusano2", 0.12, PI]],
	"larva": [["an_larva2", 0.02, 0.0]]}
## el gato tiene un segundo cuerpo para cuando está sentado (se lava y mira): se cambia según se mueva o no
const GATO_SENTADO := ["", 0.0, 0.0]
const SALAS_RATAS := ["Cocina", "Despensa", "Antecocina", "Pasillo del sótano", "Cava de vinos", "Sala de calderas", "Archivo",
	"Galería de servicio", "Ático (vigas, baúles, muñecos tapados)", "Pasillo", "Comedor formal", "Cuarto de huéspedes"]
const SALAS_GUSANOS := ["Cava de vinos", "Despensa", "Sala de calderas", "Pozo", "Cocina", "Pasillo del sótano", "Comedor formal"]

var mansion: ZarekMansion
var juego: Node
var animales: Array = []
var cuenco := Vector3.INF
var cuenco_mira := Vector3.ZERO
var gato: ZarekAnimal
const MAX_RATAS := 14

func _cuantos(tipo: String) -> int:
	var n := 0
	for a in animales:
		if a.tipo == tipo:
			n += 1
	return n

func poblar(m: ZarekMansion, j: Node) -> void:
	mansion = m
	juego = j
	var rng := RandomNumberGenerator.new()
	rng.seed = 74
	for nombre in SALAS_RATAS:
		var r := m._sala_por_nombre(nombre)
		if r.is_empty():
			continue
		for k in rng.randi_range(1, 2):
			if _cuantos("rata") < MAX_RATAS:
				_crear("rata", _punto(r, rng), rng)
	for nombre in SALAS_GUSANOS:
		var r := m._sala_por_nombre(nombre)
		if r.is_empty():
			continue
		# un grupito alrededor de algo podrido (una mancha oscura en el suelo)
		var c := _punto(r, rng)
		_podrido(c, rng)
		for k in rng.randi_range(3, 5):
			_crear("gusano" if rng.randf() < 0.6 else "larva", c + Vector3(rng.randf_range(-0.35, 0.35), 0, rng.randf_range(-0.35, 0.35)), rng)
	_cuencos(m, rng)
	var inicio := m._sala_por_nombre("Biblioteca")
	if inicio.is_empty():
		inicio = m.rooms[0]
	_crear("gato", _punto(inicio, rng), rng)
	print("ZAREK fauna ", animales.size())

func _punto(r: Dictionary, rng: RandomNumberGenerator) -> Vector3:
	var rc: Rect2 = r.rect
	for k in 12:
		var p := Vector3(rng.randf_range(rc.position.x + 0.5, rc.end.x - 0.5), float(r.y) + 0.05, rng.randf_range(rc.position.y + 0.5, rc.end.y - 0.5))
		var q := NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, p)
		if q.distance_to(p) < 0.6:
			return q
	return Vector3(rc.get_center().x, float(r.y) + 0.05, rc.get_center().y)

## Los cuencos del gato (comida y agua) junto a una pared de la cocina.
func _cuencos(m: ZarekMansion, rng: RandomNumberGenerator) -> void:
	var r := m._sala_por_nombre("Cocina")
	if r.is_empty():
		return
	var rc: Rect2 = r.rect
	for intento in 20:
		var p := Vector3(rng.randf_range(rc.position.x + 0.8, rc.end.x - 0.8), float(r.y), rc.end.y - 0.35)
		if not m.door_near(p, 1.3).is_empty():
			continue
		var cerca := NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, p + Vector3(0, 0, -0.35))
		if cerca.distance_to(p + Vector3(0, 0, -0.35)) > 0.5:
			continue
		var barro := StandardMaterial3D.new()
		barro.albedo_color = Color(0.55, 0.5, 0.42)
		barro.roughness = 0.4
		var agua := StandardMaterial3D.new()
		agua.albedo_color = Color(0.05, 0.06, 0.06)
		agua.roughness = 0.05
		var comida := StandardMaterial3D.new()
		comida.albedo_color = Color(0.3, 0.2, 0.12)
		for k in 2:
			var c := p + Vector3(k * 0.24 - 0.12, 0, 0)
			m.cyl(0.085, 0.06, 0.05, c + Vector3(0, 0.025, 0), barro, self, 16)
			m.cyl(0.07, 0.07, 0.005, c + Vector3(0, 0.042, 0), agua if k == 0 else comida, self, 16)
		cuenco = cerca
		cuenco_mira = p
		return

## Sitio donde dormir: junto a una chimenea o al pie de una cama, en la misma planta y lo más cerca posible.
var _sitios: Array = []
func sitio_dormir(desde: Vector3) -> Vector3:
	if _sitios.is_empty():
		for n in mansion._house.get_children():
			if n is Node3D and (n as Node3D).scene_file_path != "":
				var f := (n as Node3D).scene_file_path.get_file().to_lower()
				if f.contains("fireplace") or f.contains("caminetto") or f.contains("bed") or f.contains("rug"):
					var p := (n as Node3D).global_position + (n as Node3D).global_transform.basis.z * 0.9
					var q := NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, p)
					if q.distance_to(p) < 0.8:
						_sitios.append(q)
	var mejor := Vector3.INF
	var md := 1e9
	for q: Vector3 in _sitios:
		if absf(q.y - desde.y) < 1.5:
			var d := q.distance_to(desde)
			if d < md:
				md = d
				mejor = q
	return mejor

## Una ventana cercana para sentarse a mirar: [dónde sentarse, hacia dónde mirar].
func ventana_cerca(desde: Vector3) -> Array:
	var opciones: Array = []
	for v: Vector3 in mansion.ventanas:
		if absf(v.y - desde.y) < 1.5 and v.distance_to(desde) < 14.0:
			opciones.append(v)
	if opciones.is_empty():
		return []
	var v: Vector3 = opciones[randi() % opciones.size()]
	var id := mansion.room_at(v + Vector3(0, 0.5, 0))
	if id < 0:
		return []
	var c: Vector2 = (mansion.rooms[id].rect as Rect2).get_center()
	var dentro := (Vector3(c.x, v.y, c.y) - v)
	dentro.y = 0
	var p := v + dentro.normalized() * 0.7
	p = NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, p)
	return [p, v + Vector3(0, 0.6, 0)]

## Un ruido fuerte: los bichos cercanos reaccionan.
func ruido(pos: Vector3, fuerte := 1.0) -> void:
	if is_instance_valid(gato):
		gato.oir_ruido(pos, fuerte)

func _podrido(c: Vector3, rng: RandomNumberGenerator) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(0.9, 0.7)
	mi.mesh = pm
	var mt := StandardMaterial3D.new()
	mt.albedo_color = Color(0.12, 0.09, 0.05, 0.85)
	mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mt.albedo_texture = ZarekAbandono._disco()
	mt.roughness = 0.4
	mi.material_override = mt
	mi.position = c + Vector3(0, 0.006, 0)
	mi.rotation.y = rng.randf() * TAU
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

func _crear(tipo: String, p: Vector3, rng: RandomNumberGenerator) -> void:
	var opciones: Array = MODELOS[tipo]
	var elegido: Array = []
	for o in opciones:
		if ResourceLoader.exists("res://zarek/fauna/%s.glb" % o[0]):
			elegido.append(o)
	if elegido.is_empty():
		return
	var cfg: Array = elegido[rng.randi() % elegido.size()]
	var a := ZarekAnimal.new()
	a.tipo = tipo
	a.fauna = self
	add_child(a)
	a.global_position = p
	a.rotation.y = rng.randf() * TAU
	a.montar(cfg[0], float(cfg[1]), float(cfg[2]))
	animales.append(a)
	if tipo == "gato":
		gato = a

## Niveles de detalle para que vaya fluido aunque haya muchos bichos (cada 0,2 s):
##  cerca y a la vista -> vivo (física, inteligencia y animación);
##  a media distancia o fuera de la pantalla -> congelado (se ve, pero no gasta: ni huesos ni física);
##  lejos -> ni se dibuja.
var _t_lod := 0.0
func _physics_process(delta: float) -> void:
	_t_lod -= delta
	if _t_lod > 0.0:
		return
	_t_lod = 0.2
	var jug: Node3D = juego.player if juego and "player" in juego else null
	if jug == null:
		return
	var cam := get_viewport().get_camera_3d()
	var pp := jug.global_position
	for a in animales:
		if not is_instance_valid(a):
			continue
		var n := a as Node3D
		var d := n.global_position.distance_to(pp)
		var tipo: String = a.tipo
		var vivo_hasta := 14.0 if tipo == "gato" else (9.0 if tipo == "rata" else 5.0)
		var ver_hasta := 30.0 if tipo == "gato" else (16.0 if tipo == "rata" else 9.0)
		var en_pantalla := cam == null or cam.is_position_in_frustum(n.global_position + Vector3(0, 0.1, 0)) or d < 2.5
		# el gato vive siempre (tiene sus necesidades y recorre la casa aunque no lo veas)
		var vivo := tipo == "gato" or (d < vivo_hasta and (en_pantalla or d < 4.0))
		n.process_mode = Node.PROCESS_MODE_INHERIT if vivo else Node.PROCESS_MODE_DISABLED
		n.visible = d < ver_hasta
