class_name ZarekHistoria
extends RefCounted
## La historia de la casa Varela contada en notas repartidas por las salas, y la identidad de cada sala:
## color de su luz, su sonido de fondo y lo que pasa la primera vez que entras.
##
## 1874: Aurelio Varela construye la casa sobre una cueva con una roca negra que «late»: dentro duerme Zarek.
## 1986-87: Elena Varela baja a la cueva y Zarek entra en ella: la luz le quema, solo come carne humana, mueve las
## cosas de la casa sin tocarlas y su mordisco contagia el hambre. Su marido Julián intenta quemarla con gasolina y
## su hijo Damián, de 9 años, lo mata con un hacha y la encadena en la capilla del sótano. Desde 1988 han
## desaparecido 43 personas: Damián siembra de clavos el atajo del bosque y deja una luz encendida en una ventana;
## los conductores, sin cobertura, vienen solos a pedir ayuda. Él los guarda vivos para ella. Solo el fuego la mata.

const NOTAS := [
	["Vestíbulo y gran escalera", "Libro de visitas",
		"Un libro de visitas cubierto de polvo. Las últimas firmas son de gente que pedía ayuda:\n«Se nos han pinchado las ruedas» (2003). «¿Tienen teléfono? No hay cobertura» (2011). «Gracias por dejar la luz encendida» (2019).\nNinguna tiene fecha de salida."],
	["Estudio del padre", "Diario del padre · octubre de 1987",
		"Mi mujer bajó otra vez a la cueva. Ya no come nada de lo que le pongo. Ayer la encontré en la cocina con el perro… Dios mío, con el perro.\nDamián la defiende. Dice que mamá solo tiene hambre. Esta noche termino con esto: tengo la gasolina."],
	["Biblioteca", "Página arrancada de un libro antiguo",
		"…Zarek, hijo de la roca, no tiene cuerpo propio. Toma uno y le da un hambre que nada sacia salvo la carne de los hombres. La luz le quema la carne prestada; su mordisco deja la semilla del hambre en quien lo recibe.\nNo muere mientras su cuerpo viva: solo el fuego lo devuelve a la piedra."],
	["Cuarto de niños", "Dibujo infantil · firmado «Damián, 9 años»",
		"Un niño con un hacha y, detrás, una mujer con cadenas y una boca enorme.\nDebajo, con letra torcida: «YO CUIDO A MAMÁ. MAMÁ TIENE HAMBRE. PAPÁ ERA MALO»."],
	["Cuarto de la institutriz", "Diario de la institutriz · 1987",
		"Los platos se caen solos de los estantes. Las puertas se cierran de golpe cuando la señora está de mal humor, y ella ya no sale del sótano.\nEl niño baja todas las noches con un plato tapado. Mañana me voy. No vuelvo."],
	["Tocador de la madre", "Diario de la madre · 1986",
		"La roca me canta cuando bajo a la cueva. Dice mi nombre con la voz de mi madre.\nMi marido no lo entiende. Mañana bajaré sin linterna: la luz le duele."],
	["Cuarto del hermano", "Cartel de SE BUSCA · 2019",
		"SE BUSCA: hombre de 34 años. Su coche apareció en el atajo de Valdeoscuro con dos ruedas reventadas y el maletero forzado.\nAlguien ha tachado la cara con un rotulador y ha escrito encima: «VINO SOLO»."],
	["Cuarto de Damián", "Cuaderno de Damián",
		"Comida para mamá: ||||| ||||| ||||| ||||| ||||| ||||| ||||| ||||| |||\nClavos en el atajo. La lámpara en la ventana. Quitarles la rueda y el gato. Siempre vienen solos.\nCuando mamá tiene hambre, mueve las cosas. Si se enfada mucho, rompe las cadenas. ABAJO NO SE HACE RUIDO."],
	["Archivo", "Informe de la Guardia Civil · 1988",
		"Mansión Varela. Hallado el cuerpo del dueño de la casa con heridas de hacha y una lata de gasolina sin abrir. Ni rastro de la esposa ni del hijo, Damián (9). Se da por muertos a ambos. El sótano no se inspecciona por peligro de derrumbe."],
	["Cámara de la roca madre", "Inscripción en la piedra · 1874",
		"AQVÍ DVERME EL HIJO DE LA ROCA. NO LE DEIS CVERPO.\nTEME LA LVZ. SOLO EL FVEGO LO DEVVELVE A LA PIEDRA.\n— El fundador de la casa"],
	["Comedor formal", "Nota en una servilleta",
		"«Mamá come primero. Luego yo. Lo que sobra, a los perros del bosque.»\nEn el mantel hay una lista de matrículas de coche. Las últimas, sin tachar."],
	["Capilla de la madre", "Libro de rezos de la madre · 1987",
		"Cuatro candados. Damián lleva las llaves colgadas del cuello y nunca se las quita. Dice que es por mi bien.\nTengo tanta hambre. Hijo mío, tráeme a alguien vivo. Y apaga esas velas: me queman."],
	["Sala de música", "Partitura con anotaciones",
		"«Nana para Damián», compuesta por la madre. Las últimas líneas están escritas con otra letra, apretada y torcida, y las notas repiten la misma palabra: HAMBRE."],
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
