class_name ZarekSecretos
extends RefCounted
## Los secretos de la mansión Varela: fotos, cartas y cintas escondidas en los cajones de la casa. Cada noche
## aparecen unos pocos (primero los que aún no tienes) y se guardan para siempre aunque mueras. Juntos cuentan lo
## que las notas no dicen: cómo Zarek entró en Elena, cómo caza Damián (clavos, la luz en la ventana), qué hace el
## mordisco de la madre y cómo se la mata. Con los 24, cualquier final añade el epílogo con toda la verdad.

const TOTAL := 24
const CLAVE := "zarek_secretos"

## [id, tipo, título, texto]
const LISTA := [
	["f1", "foto", "Foto · La boda, 1976",
		"La madre y el padre en la gran escalera, recién casados.\nAl dorso: «Por fin la casa tiene una familia que la cuide»."],
	["f2", "foto", "Foto · La entrada de la cueva, 1986",
		"La madre, de pie dentro de la cueva, sin linterna. Sonríe hacia la oscuridad.\nAl dorso, con la letra del padre: «Dice que la roca le canta. Ya no duerme»."],
	["f3", "foto", "Foto · Damián y su madre, 1987",
		"Damián, con 9 años, abraza a su madre en el salón. Las cortinas están cerradas a mediodía.\nAl dorso: «Mamá ya no sale de día»."],
	["f4", "foto", "Foto · El décimo cumpleaños de Damián, 1988",
		"Una tarta con diez velas. Damián solo, sentado a la mesa. El hacha apoyada en su silla.\nAlguien tuvo que hacer la foto."],
	["f5", "foto", "Foto · Excursionistas, 2003",
		"Cuatro amigos posando en el camino de Valdeoscuro. Tres caras están rayadas con un clavo.\nLa cuarta ha sido recortada con cuidado."],
	["f6", "foto", "Foto · Un coche en el atajo, 2011",
		"Un coche parado en el camino, con dos ruedas reventadas. Una mujer camina hacia la casa con una linterna, tomada desde una ventana.\nAl dorso: «Vino sola. Siempre vienen solos»."],
	["f7", "foto", "Polaroid · Esta noche",
		"Una Polaroid todavía húmeda: tú, llegando a la finca con la linterna, vista desde una ventana de la casa.\nAl dorso: «La hermana. Ya viene»."],
	["f8", "foto", "Foto · La pared de la cochera",
		"Decenas de matrículas clavadas en la pared de la cochera, algunas de otros países.\nDebajo, en el suelo, un montón de gatos de coche y ruedas de repuesto."],
	["c1", "carta", "Carta del padre al médico del pueblo · 1987",
		"Doctor: venga cuanto antes. Mi mujer ya no come. Ayer mordió al perro. Oye latidos debajo del suelo y dice que la roca la llama.\nNo deje que nadie del pueblo sepa que viene."],
	["c2", "carta", "Informe del médico · octubre de 1987",
		"La paciente no tolera la luz: la piel se le levanta como papel quemado. Rechaza todo alimento salvo la carne cruda.\nRecomiendo internarla. El marido se niega. El niño no se separa de ella."],
	["c3", "carta", "Carta del fundador · 1874",
		"A mis descendientes: construí esta casa encima de la roca para guardarla, no para servirla.\nSi algún Varela le entrega su cuerpo, quemadlo. Solo el fuego lo devuelve a la piedra."],
	["c4", "carta", "Despido de la cocinera · agosto de 1987",
		"Señora: la señora de la casa prescinde de sus servicios desde hoy. No hace falta que vuelva.\nDebajo, a lápiz, la cocinera escribió: «Me pidió la carne sin cocinar. Para ella. No para el perro»."],
	["c5", "carta", "Carta de una madre · 2019",
		"Mi hijo me llamó a las dos de la mañana: se le habían pinchado las ruedas en un atajo del bosque y veía una casa con luz.\nDijo que iba a pedir ayuda. Fue la última vez que le oí."],
	["c6", "carta", "Parte de la Guardia Civil · 2019",
		"Coche del desaparecido: dos neumáticos reventados por clavos de herrar (31 clavos en 200 metros de camino). Maletero forzado; faltan la rueda de repuesto y el gato.\nSe suspende la búsqueda."],
	["c7", "carta", "Lista de la compra de Damián",
		"Clavos de herrar (muchos, para el atajo). Bombillas para la ventana. Cadenas. Candados nuevos.\nVelas para mamá: que no se le apaguen nunca, así está tranquila."],
	["c8", "carta", "Arañado por dentro de un maletero",
		"Letras torcidas arañadas en el metal, de dentro hacia fuera:\n«NO VAYAS A LA CASA DE LA LUZ»."],
	["k1", "cinta", "Cinta 1 · Grabación del padre, 1987",
		"(Golpes. Una mujer canta una nana muy bajito.)\nEL PADRE: ¿Cariño? Suelta al perro. Suéltalo… Dios mío.\n(La nana sigue. Alguien mastica.)"],
	["k2", "cinta", "Cinta 2 · Sesión con el médico",
		"MÉDICO: ¿Qué le dice la roca, señora?\nLA MADRE: Que tiene hambre.\nMÉDICO: ¿Y usted?\nLA MADRE: Yo ya soy la roca, doctor."],
	["k3", "cinta", "Cinta 3 · Damián, 9 años",
		"DAMIÁN: Papá quiere quemar a mamá con gasolina. No le voy a dejar.\nMamá dice que si la quiero, le traiga de comer. Yo la quiero mucho."],
	["k4", "cinta", "Cinta 4 · Radio de un excursionista, 2019",
		"EL EXCURSIONISTA: Hay una casa entre los árboles. Alguien me llama… con la voz de mi madre. Voy a acercarme.\n(Pasos. Una puerta. Silencio. Luego, una nana.)"],
	["k5", "cinta", "Cinta 5 · Damián, adulto",
		"DAMIÁN: Ya casi no pasa nadie por el atajo. Pero los que pasan siempre ven la luz.\nY siempre vienen solos. Los cuelgo abajo, vivos. Mamá los quiere frescos."],
	["k6", "cinta", "Cinta 6 · Un excursionista, 2003",
		"(Jadeos) Me ha mordido algo detrás de la reja… solo un poco. Me solté.\nDesde entonces tengo un hambre… no puedo parar de… (Ruido de masticar. Silencio.)"],
	["k7", "cinta", "Cinta 7 · Sin etiqueta",
		"(Solo latidos, lentos, muy graves, como si vinieran de debajo de la tierra.)\nAl final, una mujer tararea una nana. Cerca. Muy cerca del micrófono."],
	["k8", "cinta", "Cinta 8 · La madre, desde la capilla",
		"LA MADRE: (Muy cerca del micrófono) Damián… esta noche viene una. La oigo en el camino.\nQue no se escape. Y si se escapa… que se lleve un poco de mí."],
]

const ICONO := {"foto": "Foto", "carta": "Carta", "cinta": "Cinta"}

static func dato(id: String) -> Array:
	for s in LISTA:
		if s[0] == id:
			return s
	return []

static func encontrados() -> Array:
	return Aether.save.get_value(CLAVE, [])

static func cuantos() -> int:
	return encontrados().size()

## Lo guarda en el momento (aunque luego mueras). Devuelve true si es nuevo.
static func guardar(id: String) -> bool:
	var e: Array = encontrados()
	if id in e:
		return false
	e.append(id)
	Aether.save.set_value(CLAVE, e)
	return true

## Los secretos que esconde esta noche: primero los que faltan; si ya los tienes todos, unos al azar.
static func para_la_noche(rng: RandomNumberGenerator, n: int) -> Array:
	var faltan: Array = []
	var tienes: Array = []
	var e := encontrados()
	for s in LISTA:
		(tienes if s[0] in e else faltan).append(s[0])
	for arr in [faltan, tienes]:
		for i in range(arr.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var t0 = arr[i]
			arr[i] = arr[j]
			arr[j] = t0
	var out: Array = []
	out.append_array(faltan.slice(0, n))
	if out.size() < n:
		out.append_array(tienes.slice(0, n - out.size()))
	return out
