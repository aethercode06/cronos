class_name AetherLogicSchema
extends RefCounted
## Catálogo de bloques de la lógica sin código de Aether Engine.
## Cada bloque: texto en español con {parámetros} y la lista de parámetros
## [nombre, tipo, valor por defecto]. Tipos: number, text, var, action, sound,
## music, scene, node, op, color.

const TRIGGERS := {
	"inicio": {"label": "Al empezar", "params": []},
	"cada": {"label": "Cada {seg} segundos", "params": [["seg", "number", 1.0]]},
	"tras": {"label": "A los {seg} segundos de empezar", "params": [["seg", "number", 3.0]]},
	"accion": {"label": "Al pulsar {accion}", "params": [["accion", "action", "jump"]]},
	"entra": {"label": "Cuando el jugador entra en la zona", "params": []},
	"sale": {"label": "Cuando el jugador sale de la zona", "params": []},
	"recoge": {"label": "Cuando se recoge {var}", "params": [["var", "var", "monedas"]]},
	"variable": {"label": "Cuando {var} llega a {valor}", "params": [["var", "var", "monedas"], ["valor", "number", 10.0]]},
	"enemigo": {"label": "Cuando se vence a un enemigo", "params": []},
	"jefe": {"label": "Cuando se vence al jefe", "params": []},
	"cae": {"label": "Cuando el jugador cae", "params": []},
}

const CONDITIONS := {
	"var_cmp": {"label": "Si {var} {op} {valor}", "params": [["var", "var", "monedas"], ["op", "op", ">="], ["valor", "number", 1.0]]},
	"azar": {"label": "Con un {pct} % de probabilidad", "params": [["pct", "number", 50.0]]},
	"vida": {"label": "Si la vida del jugador es menor que {valor}", "params": [["valor", "number", 50.0]]},
	"suelo": {"label": "Si el jugador está en el suelo", "params": []},
	"logro": {"label": "Si ya tiene el logro {id}", "params": [["id", "text", "logro1"]]},
	"no_logro": {"label": "Si aún no tiene el logro {id}", "params": [["id", "text", "logro1"]]},
	"tiene": {"label": "Si tiene {cantidad} de {objeto}", "params": [["cantidad", "number", 1.0], ["objeto", "text", "llave"]]},
	"no_tiene": {"label": "Si no tiene {objeto}", "params": [["objeto", "text", "llave"]]},
}

const ACTIONS := {
	"sumar": {"label": "Sumar {cantidad} a {var}", "params": [["cantidad", "number", 1.0], ["var", "var", "monedas"]]},
	"poner": {"label": "Poner {var} = {valor}", "params": [["var", "var", "monedas"], ["valor", "number", 0.0]]},
	"aviso": {"label": "Mostrar aviso «{texto}»", "params": [["texto", "text", "¡Bien hecho!"]]},
	"cartel": {"label": "Mostrar cartel «{texto}»", "params": [["texto", "text", "¡VICTORIA!"]]},
	"sonido": {"label": "Sonar {sonido}", "params": [["sonido", "sound", "gem"]]},
	"musica": {"label": "Poner la música {musica}", "params": [["musica", "music", "w0"]]},
	"curar": {"label": "Curar al jugador {cantidad}", "params": [["cantidad", "number", 20.0]]},
	"danar": {"label": "Dañar al jugador {cantidad}", "params": [["cantidad", "number", 10.0]]},
	"crear": {"label": "Crear {escena} aquí", "params": [["escena", "scene", ""]]},
	"eliminar": {"label": "Eliminar {nodo}", "params": [["nodo", "node", ""]]},
	"mostrar": {"label": "Mostrar u ocultar {nodo}", "params": [["nodo", "node", ""]]},
	"llevar": {"label": "Llevar al jugador a {nodo}", "params": [["nodo", "node", ""]]},
	"control": {"label": "Guardar punto de control aquí", "params": []},
	"escena": {"label": "Ir a la escena {escena}", "params": [["escena", "scene", ""]]},
	"temblor": {"label": "Temblor de cámara de {fuerza}", "params": [["fuerza", "number", 12.0]]},
	"destello": {"label": "Destello de color {color}", "params": [["color", "color", "#ffffff"]]},
	"lenta": {"label": "Cámara lenta durante {seg} s", "params": [["seg", "number", 1.0]]},
	"logro": {"label": "Dar el logro {id}", "params": [["id", "text", "logro1"]]},
	"guardar": {"label": "Guardar la partida", "params": []},
	"esperar": {"label": "Esperar {seg} s", "params": [["seg", "number", 1.0]]},
	"dialogo": {"label": "Mostrar el diálogo {nodo}", "params": [["nodo", "node", ""]]},
	"efecto": {"label": "Lanzar el efecto {nodo}", "params": [["nodo", "node", ""]]},
	"tienda": {"label": "Abrir la tienda {nodo}", "params": [["nodo", "node", ""]]},
	"dar": {"label": "Dar {cantidad} de {objeto}", "params": [["cantidad", "number", 1.0], ["objeto", "text", "llave"]]},
	"quitar": {"label": "Quitar {cantidad} de {objeto}", "params": [["cantidad", "number", 1.0], ["objeto", "text", "llave"]]},
	"ganar": {"label": "¡Fase superada! e ir a {escena}", "params": [["escena", "scene", ""]]},
	"anuncio": {"label": "Anuncio con premio: sumar {cantidad} a {var}", "params": [["cantidad", "number", 50.0], ["var", "var", "monedas"]]},
}

const OPS := ["=", "!=", ">", "<", ">=", "<="]
const ACTIONS_INPUT := ["jump", "attack", "dash", "guard", "left", "right", "up", "down"]
const SOUNDS := ["gem", "jump", "hit", "hurt", "boom", "kill", "win", "heal", "check", "dash", "swing", "clang", "roar", "bounce", "stomp", "shield"]
const MUSIC := ["w0", "boss", ""]

static func table(kind: String) -> Dictionary:
	match kind:
		"trigger": return TRIGGERS
		"condition": return CONDITIONS
	return ACTIONS

## Frase legible de un bloque: «Sumar 10 a monedas».
static func describe(kind: String, id: String, params: Dictionary) -> String:
	var t: Dictionary = table(kind).get(id, {})
	var s: String = t.get("label", id)
	for p in t.get("params", []):
		var v = params.get(p[0], p[2])
		var txt := str(v)
		if v is float and float(v) == floor(float(v)):
			txt = str(int(v))
		if p[1] == "node" or p[1] == "scene":
			txt = String(v).get_file() if String(v) != "" else "(elige)"
		s = s.replace("{" + p[0] + "}", txt)
	return s

static func defaults(kind: String, id: String) -> Dictionary:
	var d := {}
	for p in table(kind).get(id, {}).get("params", []):
		d[p[0]] = p[2]
	return d
