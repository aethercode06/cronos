class_name ZarekSonido
## Sonidos reales del juego (CC0/CC-BY, créditos en zarek/sonidos/creditos.txt). `uno(nombre)` devuelve el
## archivo res://zarek/sonidos/<nombre>.ogg o, si hay variantes (<nombre>_1.ogg, <nombre>_2.ogg…), una al azar
## distinta de la anterior. Si no hay archivo, el sonido hecho por código de AetherSynth.

const CARPETA := "res://zarek/sonidos/"
static var _cache := {}
static var _ultimo := {}

static func variantes(nombre: String) -> Array:
	if _cache.has(nombre):
		return _cache[nombre]
	var lista: Array = []
	if ResourceLoader.exists(CARPETA + nombre + ".ogg"):
		lista.append(load(CARPETA + nombre + ".ogg"))
	var i := 1
	while ResourceLoader.exists(CARPETA + "%s_%d.ogg" % [nombre, i]):
		lista.append(load(CARPETA + "%s_%d.ogg" % [nombre, i]))
		i += 1
	_cache[nombre] = lista
	return lista

static func hay(nombre: String) -> bool:
	return not variantes(nombre).is_empty()

static func uno(nombre: String) -> AudioStream:
	var lista := variantes(nombre)
	if lista.is_empty():
		return AetherSynth.make(nombre)
	if lista.size() == 1:
		return lista[0]
	var k := randi() % lista.size()
	if k == int(_ultimo.get(nombre, -1)):
		k = (k + 1) % lista.size()
	_ultimo[nombre] = k
	return lista[k]

## Reproduce un sonido una vez en un punto (crea un reproductor que se borra solo al terminar).
static func en(padre: Node, nombre: String, pos: Vector3, db := 0.0, alcance := 30.0, tono := 1.0) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = uno(nombre)
	p.volume_db = db
	p.max_distance = alcance
	p.unit_size = 3.0
	p.pitch_scale = tono
	padre.add_child(p)
	p.global_position = pos
	p.play()
	p.finished.connect(p.queue_free)
	return p
