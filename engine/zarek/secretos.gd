class_name ZarekSecretos
extends RefCounted
## Los secretos de la familia Varela: fotos, cartas y cintas escondidas en los cajones de la casa. Cada noche
## aparecen unos pocos (primero los que aún no tienes) y se guardan para siempre aunque mueras. Juntos cuentan
## lo que las notas no dicen: Sofía no es hija de Inés. Con los 24, la Noche I tiene un final oculto.

const TOTAL := 24
const CLAVE := "zarek_secretos"

## [id, tipo, título, texto]
const LISTA := [
	["f1", "foto", "Foto · La boda, 1976",
		"Elena y Julián en la gran escalera, recién casados. Detrás, Inés sonríe con un ramo.\nAl dorso: «Por fin la casa tiene una familia que la cuide»."],
	["f2", "foto", "Foto · La entrada de la cueva, 1986",
		"Elena, de pie dentro de la cueva, sin linterna. Sonríe hacia la oscuridad.\nAl dorso, con la letra de Julián: «Dice que la roca le canta. Ya no duerme»."],
	["f3", "foto", "Foto · Elena embarazada, primavera de 1987",
		"Elena en el jardín, con la mano sobre la barriga. Damián, de 9 años, la abraza.\nAl dorso, otra vez Julián: «¿De quién es?»."],
	["f4", "foto", "Foto · El décimo cumpleaños de Damián, 1988",
		"Una tarta con diez velas. Damián solo, sentado a la mesa. El hacha apoyada en su silla.\nAlguien tuvo que hacer la foto."],
	["f5", "foto", "Foto · Estación de tren, noviembre de 1987",
		"Inés en un andén, con un bebé envuelto en una manta bordada con una V.\nAl dorso: «Sofía. Tiene los ojos de su madre»."],
	["f6", "foto", "Foto · Excursionistas, 2003",
		"Cuatro amigos posando en el camino de Valdeoscuro. Tres caras están rayadas con un clavo.\nLa cuarta ha sido recortada con cuidado."],
	["f7", "foto", "Foto · Un colegio, 2005",
		"Una niña con mochila roja saliendo del colegio, tomada de lejos, entre árboles.\nEres tú. Al dorso: «Hermanita»."],
	["f8", "foto", "Foto · Tu casa, 2024",
		"La ventana de tu dormitorio, de noche, desde la calle. Tu luz está encendida.\nAl dorso: «Martes. Mamá está contenta»."],
	["c1", "carta", "Carta de Julián al doctor Ferrer · 1987",
		"Doctor: venga cuanto antes. Elena oye latidos debajo del suelo y el embarazo avanza demasiado deprisa: dos meses en dos semanas.\nNo deje que nadie del pueblo sepa que viene."],
	["c2", "carta", "Informe del doctor Ferrer · octubre de 1987",
		"Parto en la casa. Niña sana, 3,1 kg. La madre no quiso tenerla en brazos.\nMe pidió que se la llevaran lejos «antes de que me entre hambre». La hermana, Inés, se ofreció."],
	["c3", "carta", "Carta de Aurelio Varela · 1874",
		"A mis descendientes: construí esta casa encima de la roca para guardarla, no para servirla.\nCada generación, el primogénito bajará a cantarle. Si un Varela le entrega su cuerpo, que Dios se apiade de los demás."],
	["c4", "carta", "Despido de la cocinera · agosto de 1987",
		"Señora Remedios: la señora Varela prescinde de sus servicios desde hoy. No hace falta que vuelva.\nDebajo, a lápiz, la cocinera escribió: «Me pidió la carne sin cocinar. Para ella. No para el perro»."],
	["c5", "carta", "Carta de Inés a Elena · 1995",
		"La niña está bien. Le he dicho que soy su madre y nunca sabrá de dónde viene.\nA veces se despierta de noche con hambre y llora hasta que le doy carne cruda. Dime que eso se le pasará."],
	["c6", "carta", "Telegrama a Inés · 2010",
		"SÉ DÓNDE VIVÍS STOP MAMÁ PREGUNTA POR SU HIJA STOP NO TE LA QUEDES PARA SIEMPRE STOP D."],
	["c7", "carta", "Lista de la compra de Damián",
		"Cal viva (6 sacos). Cadenas. Candados nuevos. Sal gorda. Gasolina.\nUna cuna nueva, por si se queda."],
	["c8", "carta", "Esquela de Inés Varela · 2024",
		"«Inés Varela, 1962-2024. Su hija Sofía no la olvida.»\nAlguien ha escrito encima con rotulador rojo: «AHORA YA NO TIENE A NADIE QUE LA ESCONDA»."],
	["k1", "cinta", "Cinta 1 · Grabación de Julián, 1987",
		"(Golpes. Una mujer canta una nana muy bajito.)\nJULIÁN: ¿Elena? Elena, suelta al perro. Suéltalo… Dios mío.\n(La nana sigue. Alguien mastica.)"],
	["k2", "cinta", "Cinta 2 · Sesión con el doctor Ferrer",
		"ELENA: La roca me ha dicho que tendré una niña.\nFERRER: ¿Y qué más le ha dicho?\nELENA: Que cuando este cuerpo se gaste, la niña será su casa."],
	["k3", "cinta", "Cinta 3 · Damián, 9 años",
		"DAMIÁN: Papá dice que el bebé no es suyo. Mamá dice que es de la roca. Yo la quiero igual.\nSe va a llamar Sofía. Yo la voy a cuidar como cuido a mamá."],
	["k4", "cinta", "Cinta 4 · Radio de Andrés Ortega, 2019",
		"ANDRÉS: Hay una casa entre los árboles. Alguien me llama… con la voz de mi madre. Voy a acercarme.\n(Pasos. Una puerta. Silencio. Luego, una nana.)"],
	["k5", "cinta", "Cinta 5 · Damián, adulto",
		"DAMIÁN: Mamá está muy delgada. Ya no le sirven los de fuera. Vomita a los excursionistas.\nNecesita a la niña. A mi hermana. Le he escrito como si fuera un abogado."],
	["k6", "cinta", "Cinta 6 · Inés, 2023",
		"INÉS: Sofía, si escuchas esto, no vayas nunca a Valdeoscuro. No eres mi hija, cariño. Eres de ella.\nY si algún día tienes hambre de verdad… no se lo digas a nadie. Vete lejos de la gente."],
	["k7", "cinta", "Cinta 7 · Sin etiqueta",
		"(Solo latidos, lentos, muy graves, como si vinieran de debajo de la tierra.)\nAl final, una niña tararea la nana de Elena. Reconoces la voz: es la tuya, de pequeña."],
	["k8", "cinta", "Cinta 8 · Elena, desde la capilla",
		"ELENA: Sofía. Mi niña. Has vuelto a casa.\nNo le tengas miedo al hambre. Es la forma que tiene esta familia de quererse."],
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
