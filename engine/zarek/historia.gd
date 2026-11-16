class_name ZarekHistoria
extends RefCounted
## La historia de la casa Varela contada en notas repartidas por las salas, y la identidad de cada sala:
## color de su luz, su sonido de fondo y lo que pasa la primera vez que entras.
##
## 1874: Aurelio Varela, fundador, construye la casa sobre una cueva donde hay una roca negra que «late». Un
## sacerdote le advierte: dentro duerme Zarek, «hijo de la roca madre». Aurelio la encierra con cuatro sellos de
## plata de la dinastía, repartidos por la casa. 1971: Don Esteban Varela, el nieto, obsesionado con el ocultismo,
## excava el sótano, encuentra la cámara y rompe un sello para «hablar con él». Zarek elige a su hija Elena, de 17
## años. En 1974, una noche de noviembre, Elena mata a toda la familia. Desde entonces nadie vive allí.

const NOTAS := [
	["Vestíbulo y gran escalera", "Recorte de periódico · 23 de noviembre de 1974",
		"TRAGEDIA EN LA MANSIÓN VARELA\nCinco muertos en una sola noche. La policía busca a la hija mayor, Elena (17), desaparecida. Los vecinos dicen que durante semanas se oyeron gritos y un piano que tocaba solo de madrugada."],
	["Estudio del padre", "Carta de Don Esteban Varela · 1971",
		"Hemos dado con la cámara bajo el pozo. El abuelo Aurelio no mentía: la roca es negra, está tibia y LATE. Hay cuatro huecos en la piedra con forma de sello. Uno ya está vacío. Esta noche intentaré hablar con lo que hay dentro."],
	["Biblioteca", "Página arrancada de un libro antiguo",
		"…Zarek, hijo de la roca madre, no tiene cuerpo propio. Busca uno joven, sin miedo todavía. Solo los cuatro sellos de plata de la dinastía Varela pueden devolverlo a la piedra, y solo si se reúnen en el círculo de sal y se dice su nombre."],
	["Cuarto de niños", "Dibujo infantil · firmado «Clara, 7 años»",
		"Un dibujo a lápiz: una niña con vestido blanco y, detrás, la misma niña con la cara negra y la boca muy grande.\nDebajo: «ELENA DE DÍA. ELENA DE NOCHE. NO ABRAS LA PUERTA CUANDO TE LLAMA»."],
	["Cuarto de la institutriz", "Diario de Marta, la institutriz",
		"12 de octubre. Elena no duerme. La encontré a las tres de la mañana de pie frente a la pared, hablando en un idioma que no es de este mundo. Cuando me vio, sonrió con unos dientes que no eran suyos. Mañana hablo con la señora."],
	["Tocador de la madre", "Carta de Isabel a un sacerdote · sin enviar",
		"Padre, le ruego que venga. Esteban se encierra en el sótano y mi Elena ya no es mi Elena. Las luces la queman: grita si alguien enciende una lámpara. He escondido uno de los sellos donde ella no pueda verlo. Dios me perdone."],
	["Cuarto del hermano", "Nota de Tomás",
		"Si alguien lee esto: la sal la frena. La luz también, al principio. Escondí otro sello abajo, en la cava, detrás de los vinos de papá. No te escondas en el armario si te ha visto entrar."],
	["EPICENTRO · cuarto de Elena", "Última página del diario de Elena",
		"Me habla desde la piedra. Dice que papá le abrió la puerta y que ahora la casa es suya. Dice que si me porto bien dejará vivir a Clara.\nNo es verdad. Nunca es verdad.\nAyúdame a echarlo. Por favor."],
	["Archivo", "Informe de excavación · 1971",
		"Pozo de servicio, 9 m de profundidad. Galería natural hacia el este. Temperatura anormal en la roca central: 37 °C. Dos obreros abandonan el trabajo sin cobrar. Uno de ellos repite un nombre: Zarek."],
	["Cámara de la roca madre", "Inscripción en la piedra · 1874",
		"AQVÍ DVERME EL HIJO DE LA ROCA. CVATRO SELLOS LO ATAN. QVIEN LOS ROMPA LE DARÁ VNA CASA.\n— Aurelio Varela, fundador"],
	["Comedor formal", "Nota en una servilleta",
		"«La cena de la última noche sigue servida. Nadie llegó al postre.»\nAlguien ha escrito con el dedo en el polvo de la mesa: ELLA SIGUE AQUÍ."],
	["Sala de música", "Partitura con anotaciones",
		"«Nana para Clara», compuesta por Elena. Las últimas líneas están escritas con otra letra, apretada y torcida, y las notas forman la misma palabra una y otra vez."],
]

## Color de la luz de cada sala (las lámparas de esa sala lo usan).
const LUZ := {
	"Cocina": Color(0.75, 0.85, 1.0), "Despensa": Color(0.7, 0.8, 0.95), "Antecocina": Color(0.78, 0.86, 1.0),
	"EPICENTRO · cuarto de Elena": Color(1.0, 0.35, 0.25), "Rincón de Elena": Color(1.0, 0.4, 0.3),
	"Biblioteca": Color(1.0, 0.7, 0.38), "Estudio del padre": Color(1.0, 0.68, 0.36), "Cuarto de lectura": Color(1.0, 0.72, 0.4),
	"Cuarto de niños": Color(1.0, 0.85, 0.65), "Baño": Color(0.85, 0.95, 0.9), "Galería de retratos": Color(1.0, 0.78, 0.55),
	"Salón de baile": Color(1.0, 0.82, 0.6), "Sala de música": Color(0.95, 0.8, 0.7), "Cava de vinos": Color(1.0, 0.6, 0.35),
	"Sala de calderas": Color(1.0, 0.55, 0.3), "Archivo": Color(0.9, 0.9, 0.8), "Cuarto de huéspedes azul": Color(0.7, 0.8, 1.0),
	"Tocador de la madre": Color(1.0, 0.75, 0.75), "Sala de costura": Color(1.0, 0.86, 0.7)}

## Sonido de fondo de cada sala (sonido sintetizado en bucle, volumen dB).
const SONIDO := {
	"Estudio del padre": ["tictac", -14.0], "Cuarto de niños": ["caja_musica", -20.0], "Baño": ["goteo", -12.0],
	"Ático (vigas, baúles, muñecos tapados)": ["crujido", -18.0], "Sala de calderas": ["drone", -10.0], "Cava de vinos": ["goteo", -14.0],
	"Biblioteca": ["tictac", -20.0], "Cocina": ["goteo", -18.0], "EPICENTRO · cuarto de Elena": ["susurro", -18.0],
	"Galería de retratos": ["viento", -22.0], "Cámara de la roca madre": ["latido", -10.0]}

## Lo que pasa la primera vez que entras en algunas salas: [sonido, texto en pantalla].
const EVENTO := {
	"Sala de música": ["piano", "Una tecla del piano suena sola."],
	"Salón de baile": ["caja_musica", "El fonógrafo empieza a girar sin nadie."],
	"Cuarto de niños": ["risa", "Algo ha reído detrás del caballito."],
	"Estudio del padre": ["campana", "El reloj da las tres. Son las tres desde 1974."],
	"Sala de costura": ["golpes", "La máquina de coser da tres puntadas sola."],
	"Galería de retratos": ["susurro", "Los ojos de un retrato te siguen."],
	"Comedor formal": ["tintineo", "Las copas de la mesa vibran."],
	"Biblioteca": ["golpe_madera", "Un libro cae de la estantería."]}

## Papel pintado de cada sala (texturas/papeles/<nombre>.jpg).
const PAPEL := {
	"Salón de baile": "damasco_rojo", "EPICENTRO · cuarto de Elena": "damasco_rojo", "Biblioteca": "damasco_verde",
	"Galería de retratos": "damasco_crema", "Tocador de la madre": "floral_rosa", "Cuarto de huéspedes azul": "floral_azul",
	"Comedor formal": "rombos_ocre", "Dormitorio de los padres": "lirios_azul", "Sala de música": "enredadera",
	"Sala de costura": "enredadera", "Cuarto de niños": "estrellas_ninos", "Estudio del padre": "tartan",
	"Sala de fumar y billar": "tartan", "Vestíbulo y gran escalera": "medallones_oro", "Cuarto de la institutriz": "floral_palido",
	"Cuarto del hermano": "floral_palido", "Salón con chimenea": "damasco_crema"}

## Alfombra de cada sala ("" = la persa roja; verde, azul u oro); las demás salas la reciben por turno.
const ALFOMBRA := {
	"Salón de baile": "oro", "EPICENTRO · cuarto de Elena": "", "Biblioteca": "", "Estudio del padre": "verde",
	"Comedor formal": "azul", "Cuarto de niños": "oro", "Dormitorio de los padres": "", "Tocador de la madre": "azul",
	"Galería de retratos": "verde", "Vestíbulo y gran escalera": ""}

## Cómo está la luz eléctrica de cada sala: «fija», «parpadea», «apagada» (bombillas fundidas) o «tramos» (en los
## pasillos largos: un tramo con luz, otro parpadeando, otro a oscuras…). Las que no salen aquí se sortean
## (la mayoría parpadean).
const LUZ_MODO := {
	"Pasillo principal": "tramos", "Pasillo": "tramos", "Pasillo del sótano": "parpadea", "Galería de servicio": "apagada",
	"Galería de retratos": "parpadea", "Vestíbulo y gran escalera": "fija", "Cocina": "parpadea", "Salón de baile": "fija",
	"Biblioteca": "fija", "EPICENTRO · cuarto de Elena": "parpadea", "Cuarto de niños": "apagada", "Baño": "parpadea",
	"Escalera de servicio": "apagada", "Sala de calderas": "parpadea", "Ático (vigas, baúles, muñecos tapados)": "parpadea",
	"Estudio del padre": "fija", "Sala de música": "parpadea", "Comedor formal": "parpadea"}

## Lámpara eléctrica concreta de algunas salas (modelos objetos/luz_*.glb); las demás se eligen por tipo de sala.
const LAMPARA := {
	"Cocina": "colgante_esmalte", "Sala de calderas": "colgante_jaula", "Cava de vinos": "colgante_jaula",
	"Pasillo del sótano": "aplique_retro", "Archivo": "colgante_jaula", "Baño": "aplique_cristal", "Despensa": "colgante_esmalte",
	"Cuarto de plancha": "colgante_esmalte", "Pasillo principal": "aplique_antiguo", "Pasillo": "aplique_brazo",
	"Galería de retratos": "aplique_antiguo", "Galería de servicio": "aplique_retro"}
