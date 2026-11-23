class_name ZarekHistoria
extends RefCounted
## La historia de la casa Varela contada en notas repartidas por las salas, y la identidad de cada sala:
## color de su luz, su sonido de fondo y lo que pasa la primera vez que entras.
##
## 1874: Aurelio Varela construye la casa sobre una cueva con una roca negra que «late»: dentro duerme Zarek.
## 1987: Elena Varela, la heredera, baja a la cueva y Zarek entra en ella; solo puede comer carne humana. Su
## marido Julián intenta matarla y su hijo Damián, de 9 años, lo mata con un hacha y encadena a su madre en la
## capilla del sótano con cuatro candados. Inés, la hermana menor de Elena, huye embarazada. Desde 1988 han
## desaparecido 43 personas en el bosque: Damián las atrae y alimenta a su madre. Hoy la protagonista, Sofía (la
## hija de Inés), recibe la carta de un «abogado»: la escribió Damián. La madre necesita sangre Varela.

const NOTAS := [
	["Vestíbulo y gran escalera", "Carta del abogado Ramiro Castell",
		"Estimada señorita Sofía:\nComo última heredera de la familia Varela, debe presentarse en la finca de Valdeoscuro para firmar el inventario. La esperaremos en la casa. Venga sola y de noche: así se evitan los curiosos del pueblo.\nLa familia la espera desde hace mucho tiempo."],
	["Estudio del padre", "Diario de Julián Varela · octubre de 1987",
		"Elena bajó otra vez a la cueva. Ya no come nada de lo que le pongo. Ayer la encontré en la cocina con el perro… Dios mío, con el perro.\nDamián la defiende. Dice que mamá solo tiene hambre. Esta noche termino con esto."],
	["Biblioteca", "Página arrancada de un libro antiguo",
		"…Zarek, hijo de la roca madre, no tiene cuerpo propio. Toma uno y le da un hambre que nada sacia salvo la carne de los hombres. Solo la sangre de la misma estirpe que lo encerró puede romper del todo el pacto con la piedra y dejarlo libre por el mundo."],
	["Cuarto de niños", "Dibujo infantil · firmado «Damián, 9 años»",
		"Un niño con un hacha y, detrás, una mujer con cadenas y una boca enorme.\nDebajo, con letra torcida: «YO CUIDO A MAMÁ. MAMÁ TIENE HAMBRE. PAPÁ ERA MALO»."],
	["Cuarto de la institutriz", "Diario de Marta, la institutriz · 1987",
		"El niño baja al sótano todas las noches con un plato tapado. La cocinera dice que no es comida de su cocina. Hoy olía a carne cruda y tenía las manos rojas hasta los codos.\nMañana me voy. No vuelvo."],
	["Tocador de la madre", "Carta de Inés a su hermana · sin enviar",
		"Elena: me voy esta noche. Estoy embarazada y no quiero que mi hija crezca en esta casa ni cerca de esa cueva. No me busques. Si algún día te curas, te escribiré.\nPerdóname.\nInés"],
	["Cuarto del hermano", "Cartel de SE BUSCA · 2019",
		"SE BUSCA: Andrés Ortega, 34 años. Visto por última vez en la ruta de Valdeoscuro. Llevaba mochila roja y una radio.\nAlguien ha tachado la cara con un rotulador y ha escrito encima: «RICO»."],
	["Cuarto de Damián", "Cuaderno de Damián",
		"Comida para mamá: ||||| ||||| ||||| ||||| ||||| ||||| ||||| ||||| |||\nMamá dice que ya no quiere más excursionistas. Quiere a la de su sangre.\nLa señora Sofía viene el martes. Mamá dice que con ella se acaba el hambre para siempre."],
	["Archivo", "Informe de la Guardia Civil · 1988",
		"Mansión Varela. Hallado el cuerpo de Julián Varela con heridas de hacha. Ni rastro de la esposa, Elena, ni del hijo, Damián (9). Se da por muertos a ambos. El pozo y el sótano no se inspeccionan por peligro de derrumbe."],
	["Cámara de la roca madre", "Inscripción en la piedra · 1874",
		"AQVÍ DVERME EL HIJO DE LA ROCA. LA SANGRE VARELA LO ENCERRÓ. SOLO LA SANGRE VARELA LO PVEDE SOLTAR.\n— Aurelio Varela, fundador"],
	["Comedor formal", "Nota en una servilleta",
		"«Mamá come primero. Luego yo. Lo que sobra, a los perros del bosque.»\nEn el mantel hay una lista de nombres. Los últimos están sin tachar."],
	["Capilla de la madre", "Libro de rezos de Elena · 1987",
		"Cuatro candados. Damián lleva las llaves colgadas del cuello y nunca se las quita. Dice que es por mi bien.\nTengo tanta hambre. Hijo mío, tráeme a alguien. Tráeme a alguien que sea nuestro."],
	["Sala de música", "Partitura con anotaciones",
		"«Nana para Damián», compuesta por Elena. Las últimas líneas están escritas con otra letra, apretada y torcida, y las notas repiten la misma palabra: HAMBRE."],
]

## Color de la luz de cada sala (las lámparas de esa sala lo usan).
const LUZ := {
	"Cocina": Color(0.75, 0.88, 0.90), "Despensa": Color(0.70, 0.85, 0.88), "Antecocina": Color(0.78, 0.88, 0.90),
	"Cuarto de Damián": Color(1.0, 0.35, 0.25), "Escondite de Damián niño": Color(1.0, 0.4, 0.3),
	"Biblioteca": Color(1.00, 0.80, 0.59), "Estudio del padre": Color(1.00, 0.79, 0.58), "Cuarto de lectura": Color(1.00, 0.81, 0.60),
	"Cuarto de niños": Color(1.00, 0.88, 0.73), "Baño": Color(0.85, 0.93, 0.85), "Galería de retratos": Color(1.00, 0.84, 0.68),
	"Salón de baile": Color(1.00, 0.86, 0.70), "Sala de música": Color(0.95, 0.85, 0.75), "Cava de vinos": Color(1.00, 0.75, 0.57),
	"Sala de calderas": Color(1.00, 0.73, 0.55), "Archivo": Color(0.90, 0.90, 0.80), "Cuarto de huéspedes azul": Color(0.70, 0.85, 0.90),
	"Tocador de la madre": Color(1.00, 0.82, 0.78), "Sala de costura": Color(1.00, 0.88, 0.75)}

## Sonido de fondo de cada sala (sonido sintetizado en bucle, volumen dB).
const SONIDO := {
	"Estudio del padre": ["tictac", -14.0], "Cuarto de niños": ["caja_musica", -20.0], "Baño": ["goteo", -12.0],
	"Ático (vigas, baúles, muñecos tapados)": ["crujido", -18.0], "Sala de calderas": ["drone", -10.0], "Cava de vinos": ["goteo", -14.0],
	"Biblioteca": ["tictac", -20.0], "Cocina": ["goteo", -18.0], "Cuarto de Damián": ["susurro", -18.0],
	"Galería de retratos": ["viento", -22.0], "Cámara de la roca madre": ["latido", -10.0], "Capilla de la madre": ["susurro", -16.0]}

## Lo que pasa la primera vez que entras en algunas salas: [sonido, texto en pantalla].
const EVENTO := {
	"Sala de música": ["piano", "Una tecla del piano suena sola."],
	"Salón de baile": ["caja_musica", "El fonógrafo empieza a girar sin nadie."],
	"Cuarto de niños": ["risa", "Algo ha reído detrás del caballito."],
	"Estudio del padre": ["campana", "El reloj da las tres. Se paró la noche del hacha, en 1987."],
	"Sala de costura": ["golpes", "La máquina de coser da tres puntadas sola."],
	"Galería de retratos": ["susurro", "Los ojos de un retrato te siguen."],
	"Comedor formal": ["tintineo", "Las copas de la mesa vibran."],
	"Biblioteca": ["golpe_madera", "Un libro cae de la estantería."],
	"Capilla de la madre": ["susurro", "Detrás de la reja, algo arrastra unas cadenas y respira."]}

## Papel pintado de cada sala (texturas/papeles/<nombre>.jpg).
const PAPEL := {
	"Salón de baile": "damasco_crema", "Cuarto de Damián": "damasco_rojo", "Biblioteca": "damasco_verde",
	"Galería de retratos": "damasco_crema", "Tocador de la madre": "floral_rosa", "Cuarto de huéspedes azul": "floral_azul",
	"Comedor formal": "rombos_ocre", "Dormitorio de los padres": "lirios_azul", "Sala de música": "enredadera",
	"Sala de costura": "enredadera", "Cuarto de niños": "estrellas_ninos", "Estudio del padre": "tartan",
	"Sala de fumar y billar": "tartan", "Vestíbulo y gran escalera": "medallones_oro", "Cuarto de la institutriz": "floral_palido",
	"Cuarto del hermano": "floral_palido", "Salón con chimenea": "damasco_crema"}

## Alfombra de cada sala ("" = la persa roja; verde, azul u oro); las demás salas la reciben por turno.
const ALFOMBRA := {
	"Salón de baile": "azul", "Cuarto de Damián": "", "Biblioteca": "verde", "Estudio del padre": "verde",
	"Comedor formal": "azul", "Cuarto de niños": "oro", "Dormitorio de los padres": "azul", "Tocador de la madre": "azul",
	"Galería de retratos": "verde", "Vestíbulo y gran escalera": "verde"}

## Cómo está la luz eléctrica de cada sala: «fija», «parpadea», «apagada» (bombillas fundidas) o «tramos» (en los
## pasillos largos: un tramo con luz, otro parpadeando, otro a oscuras…). Las que no salen aquí se sortean
## (la mayoría parpadean).
const LUZ_MODO := {
	"Pasillo principal": "tramos", "Pasillo": "tramos", "Pasillo del sótano": "parpadea", "Galería de servicio": "apagada",
	"Galería de retratos": "parpadea", "Vestíbulo y gran escalera": "fija", "Cocina": "parpadea", "Salón de baile": "fija",
	"Biblioteca": "fija", "Cuarto de Damián": "apagada", "Cuarto de niños": "apagada", "Baño": "parpadea",
	"Escalera de servicio": "apagada", "Sala de calderas": "parpadea", "Ático (vigas, baúles, muñecos tapados)": "parpadea",
	"Estudio del padre": "fija", "Sala de música": "parpadea", "Comedor formal": "parpadea", "Capilla de la madre": "apagada"}

## Lámpara eléctrica concreta de algunas salas (modelos objetos/luz_*.glb); las demás se eligen por tipo de sala.
const LAMPARA := {
	"Cocina": "colgante_esmalte", "Sala de calderas": "colgante_jaula", "Cava de vinos": "colgante_jaula",
	"Pasillo del sótano": "aplique_retro", "Archivo": "colgante_jaula", "Baño": "aplique_cristal", "Despensa": "colgante_esmalte",
	"Cuarto de plancha": "colgante_esmalte", "Pasillo principal": "aplique_antiguo", "Pasillo": "aplique_brazo",
	"Galería de retratos": "aplique_antiguo", "Galería de servicio": "aplique_retro"}

## Color de las cortinas de cada sala (las demás, por turno: salvia, botella, marino, mostaza, gris, crema).
const CORTINA := {
	"Salón de baile": "botella", "Biblioteca": "botella", "Estudio del padre": "salvia", "Comedor formal": "mostaza",
	"Dormitorio de los padres": "marino", "Tocador de la madre": "crema", "Cuarto de niños": "crema", "Galería de retratos": "gris",
	"Vestíbulo y gran escalera": "marino", "Cuarto de Damián": "granate", "Sala de música": "salvia"}

## Suelo propio de algunas salas (el resto: parquet, baldosa de servicio, losa o tablones según el tipo).
const SUELO := {
	"Vestíbulo y gran escalera": "s_damero", "Baño": "s_hidraulica", "Baño de servicio": "s_hidraulica",
	"Cocina": "s_cocina", "Despensa": "s_cocina", "Antecocina": "s_cocina", "Cuarto de plancha": "s_cocina",
	"Lavandería": "s_cocina", "Salón de baile": "parquet", "Comedor formal": "parquet"}
