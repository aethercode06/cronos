class_name ZarekNoches
extends RefCounted
## Cada noche la casa es distinta (con la semilla de la partida):
## - un SUCESO que cambia las reglas (tormenta, niebla dentro de la casa, apagón, luna roja… o nada);
## - unas SALAS CERRADAS CON LLAVE (salas sin salida, con la llave escondida en algún cajón de otra sala): dentro
##   hay más provisiones y secretos;
## - los SECRETOS de la familia (ZarekSecretos) repartidos por los cajones.

const SUCESOS := {
	"normal": ["NOCHE SIN LUNA", "Una noche como cualquier otra en Valdeoscuro. Eso es lo que más miedo da."],
	"tormenta": ["NOCHE DE TORMENTA", "Los truenos tapan tus pasos… y también los suyos. Muévete cuando caiga un rayo."],
	"niebla": ["NOCHE DE NIEBLA", "La niebla ha entrado en la casa. Él ve menos… y tú también."],
	"apagon": ["NOCHE DEL APAGÓN", "La casa está a oscuras desde el principio. El cuadro eléctrico está en la sala de calderas."],
	"luna_roja": ["NOCHE DE LUNA ROJA", "Damián tiene más hambre y es más rápido. Pero la casa deja ver más secretos."],
}
const ORDEN := ["normal", "tormenta", "niebla", "apagon", "luna_roja"]

## Salas que nunca se cierran (la historia pasa por ellas, tienen escaleras o son de paso).
const NUNCA := ["Escalera", "Pasillo", "Vestíbulo", "Galería", "Cuarto de Damián", "Cuarto de huéspedes", "Sala de calderas", "Capilla", "Cámara",
	"Túnel", "Recibidor", "Distribuidor", "Rellano", "Cuarto de las escaleras"]

static func elegir_suceso(seed: int) -> String:
	if seed == 0:
		return "normal"
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + 4242
	# la noche normal sale algo más a menudo
	var r := rng.randf()
	if r < 0.28:
		return "normal"
	return ORDEN[1 + int((r - 0.28) / 0.72 * 4.0) % 4]

## Cierra con llave hasta `n` salas sin salida y reparte las llaves y los secretos entre los muebles.
## Devuelve las salas cerradas: [{nombre, puerta, id}]
static func preparar(m: ZarekMansion, muebles: Array, seed: int, n_salas: int, n_secretos: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = (seed if seed != 0 else 777) + 31
	# puertas de cada sala
	var puertas_de := {}
	for d in m.doors:
		for id in d.get("ids", []):
			if int(id) < 0:
				continue
			if not puertas_de.has(id):
				puertas_de[id] = []
			puertas_de[id].append(d)
	var ocupadas := {}
	for s in m.seals:
		ocupadas[m.room_at(s.pos)] = true
	for k in m.pickups:
		if k.kind == "llaves":
			ocupadas[m.room_at(k.pos)] = true
	for pt in m.portals:
		ocupadas[m.room_at(pt.pos)] = true
		ocupadas[m.room_at(pt.to)] = true
	ocupadas[m.room_at(m.circle_pos)] = true
	ocupadas[m.room_at(m.radio_pos)] = true
	var candidatas: Array = []
	for r in m.rooms:
		if r.type == "epicentro" or r.type == "jardin" or ocupadas.has(r.id):
			continue
		if not puertas_de.has(r.id) or (puertas_de[r.id] as Array).size() != 1:
			continue
		var d: Dictionary = puertas_de[r.id][0]
		if d.locked or d.get("principal", false):
			continue
		var vetada := false
		for w in NUNCA:
			if String(r.name).begins_with(w) or w in String(r.name):
				vetada = true
		var area: float = (r.rect as Rect2).get_area()
		if vetada or area < 12.0:
			continue
		# que tenga algo que registrar dentro
		var dentro := 0
		for x in muebles:
			if x.tipo != "" and m.room_at(x.pos) == r.id:
				dentro += 1
		if dentro == 0:
			continue
		candidatas.append(r)
	for i in range(candidatas.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t0 = candidatas[i]
		candidatas[i] = candidatas[j]
		candidatas[j] = t0
	var cerradas: Array = []
	for r in candidatas:
		if cerradas.size() >= n_salas:
			break
		var d: Dictionary = puertas_de[r.id][0]
		m.set_door(d, false, true)
		d.ang = 0.0
		d.target = 0.0
		d["vel"] = 0.0
		(d.pivot as Node3D).rotation.y = d.base
		d.shape.disabled = false
		d.open = false
		d.locked = true
		d["llave"] = String(r.name)
		cerradas.append({"nombre": String(r.name), "puerta": d, "id": r.id})
	var ids_cerradas := cerradas.map(func(c): return c.id)
	# muebles dentro de las salas cerradas: provisiones seguras
	var dentro: Array = []
	var fuera: Array = []
	for x in muebles:
		if x.tipo == "":
			continue
		if m.room_at(x.pos) in ids_cerradas:
			dentro.append(x)
		else:
			fuera.append(x)
	for lista in [dentro, fuera]:
		for i in range(lista.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var t0 = lista[i]
			lista[i] = lista[j]
			lista[j] = t0
	for i in dentro.size():
		dentro[i].botin = ["pila", "bengala", "tablon"][i % 3] if i < 3 else ""
	# llaves: en cajones de fuera que no tengan nada (o lo que haya, si no queda ninguno vacío)
	var vacios := fuera.filter(func(x): return String(x.botin) == "")
	for c in cerradas:
		var x: Dictionary = vacios.pop_back() if not vacios.is_empty() else fuera[rng.randi_range(0, fuera.size() - 1)]
		x.botin = "llave:" + String(c.nombre)
	# secretos: la mitad dentro de las salas cerradas (si las hay) y el resto por la casa
	var ids := ZarekSecretos.para_la_noche(rng, n_secretos)
	var sitios: Array = []
	for x in dentro:
		if String(x.botin) == "":
			sitios.append(x)
	sitios = sitios.slice(0, ceili(ids.size() * 0.5))
	for x in vacios:
		if sitios.size() >= ids.size():
			break
		if String(x.botin) == "":
			sitios.append(x)
	for i in mini(ids.size(), sitios.size()):
		sitios[i].botin = "secreto:" + String(ids[i])
	print("ZAREK noche: %d salas cerradas %s, %d secretos" % [cerradas.size(), str(cerradas.map(func(c): return c.nombre)), mini(ids.size(), sitios.size())])
	return cerradas
