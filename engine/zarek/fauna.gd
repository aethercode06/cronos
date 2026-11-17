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
		var vivo := d < vivo_hasta and (en_pantalla or tipo == "gato" or d < 4.0)
		n.process_mode = Node.PROCESS_MODE_INHERIT if vivo else Node.PROCESS_MODE_DISABLED
		n.visible = d < ver_hasta
