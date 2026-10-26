// =====================================================================
//  HISTORIA: escenas, diálogos, recuerdos de Lyra y voz de Tic
// =====================================================================
const WHO = {
  NARR: { n: '', c: '#ffe7a8' },
  KAEL: { n: 'KAEL', c: '#7fe9ff', pt: 'pt_kael' },
  TIC: { n: 'TIC', c: '#ffc861', pt: 'pt_tic' },
  LYRA: { n: 'LYRA', c: '#ffb0e0', pt: 'pt_lyra' },
  SOMBRIO: { n: 'KAEL SOMBRÍO', c: '#c27bff', pt: 'pt_sombrio' },
  DEVO: { n: 'EL DEVORADOR', c: '#ff5a7a', pt: 'pt_devo' }
};
const CUTS = {
  intro: [
    { img: 'cs_order', pan: [0.0, 0.08, 1.12, 1.0], lines: [
      ['NARR', 'Hace mil años, la Orden de Chronos custodiaba el Corazón del Tiempo: el reloj que mantiene unidos a todos los mundos.'],
      ['NARR', 'Kael era su aprendiz más joven. Lyra, su hermana mayor, la guardiana más brillante que la Orden había conocido.']] },
    { img: 'cs_fire', pan: [0.1, 0.0, 1.0, 1.14], lines: [
      ['NARR', 'Hasta la Noche de las Cenizas. Un incendio devoró la Torre del Reloj… y a Lyra con ella.'],
      ['KAEL', '¡No! Todavía puedo llegar… ¡solo necesito un segundo más!'],
      ['NARR', 'Kael usó el poder prohibido de la Orden: el SHIFT. Quiso volver atrás en el tiempo para salvarla.']] },
    { img: 'cs_shatter', pan: [0.05, 0.05, 1.15, 1.02], lines: [
      ['NARR', 'Pero el tiempo no se deja reescribir. El Corazón estalló en dieciocho fragmentos que cayeron en dieciocho mundos distintos.'],
      ['NARR', 'Cada fragmento corrompió a la criatura que lo encontró. Y de la grieta nació una sombra con el rostro de Kael.']] },
    { img: 'cs_wake', pan: [0.08, 0.1, 1.0, 1.12], lines: [
      ['TIC', '¡Eh! ¡Despierta, chaval! Soy Tic, búho mecánico oficial de la Orden. Modelo 3000. Bueno… el único modelo.'],
      ['TIC', 'Tengo una noticia mala y una buena. La mala: has roto el universo. La buena: ¡se puede arreglar!'],
      ['KAEL', '¿Y Lyra? ¿Dónde está Lyra?'],
      ['TIC', 'Su eco quedó atrapado entre dos segundos. Si reunimos los dieciocho fragmentos… quizá podamos encontrarla.'],
      ['KAEL', 'Entonces no hay tiempo que perder.'],
      ['TIC', 'Técnicamente, ahora mismo hay MUCHO tiempo perdido. Pero sí, vamos.']] }
  ],
  mid: [
    { img: 'cs_shadow', pan: [0.05, 0.0, 1.12, 1.0], lines: [
      ['SOMBRIO', '¿Crees que eres mejor que yo? Solo quería lo mismo que tú: tenerla de vuelta.'],
      ['SOMBRIO', 'Pero no fui yo quien rompió el Corazón. Algo nos susurró desde la grieta. Algo que se alimenta de los instantes rotos.']] },
    { img: 'cs_devourer', pan: [0.0, 0.1, 1.0, 1.15], lines: [
      ['NARR', 'EL DEVORADOR DE HORAS. Con cada segundo perdido, crece. Con cada fragmento que reúnes… despierta.'],
      ['TIC', 'Vale. Eso no venía en el manual.'],
      ['SOMBRIO', 'Los diez últimos fragmentos están más allá del tiempo. Ve, Kael. Haz lo que yo no fui capaz de hacer.'],
      ['KAEL', 'Lo haré. Por los dos.']] }
  ],
  ending: [
    { img: 'cs_final', pan: [0.05, 0.05, 1.15, 1.0], lines: [
      ['NARR', 'En el Nexo, la luz de los dieciocho fragmentos atravesó al Devorador de Horas.'],
      ['NARR', 'Y por primera vez en mil años, el Corazón del Tiempo volvió a latir.']] },
    { img: 'cs_lyra', pan: [0.0, 0.08, 1.0, 1.12], lines: [
      ['LYRA', 'Lo lograste, hermanito. Escucha… el tiempo vuelve a correr.'],
      ['KAEL', 'Puedo usar el Shift una última vez. Puedo traerte de vuelta, Lyra.'],
      ['LYRA', 'Y volverías a romperlo todo. El tiempo no se arregla, Kael. Se vive.'],
      ['LYRA', 'Estaré en cada amanecer. Te lo prometo.']] },
    { img: 'cs_dawn', pan: [0.1, 0.05, 1.0, 1.1], lines: [
      ['NARR', 'Los dieciocho mundos volvieron a girar. Y cada mañana, en la Jungla Flotante, el sol sale un segundo antes.'],
      ['NARR', 'Dicen que es Lyra, saludando.'],
      ['TIC', 'Para ser un chaval que rompió el universo, no lo has hecho nada mal.'],
      ['KAEL', 'Gracias, Tic. ¿Y ahora qué?'],
      ['TIC', 'Ahora… ¿desayuno? Llevo mil años sin aceite.']] }
  ]
};
// Recuerdos de Lyra al recuperar cada fragmento
const FRAGL = [
  [['LYRA', 'Kael… ¿recuerdas cuando me enseñaste a trepar los árboles de la jungla? Siempre llegabas primero.'], ['TIC', '¡El fragmento ha despertado tu SHIFT! Cambia de dimensión y verás plataformas que antes no estaban.']],
  [['LYRA', 'En Velmora tocaban las campanas cada vez que alguien se perdía. Hace siglos que ya no suenan.'], ['TIC', 'Uno menos. Dieciséis más y te invito a un aceite de engranajes.']],
  [['LYRA', 'El fuego no fue culpa tuya. Nunca lo fue.'], ['KAEL', '…'], ['TIC', 'Bueno. Eso ha sido intenso. Sigamos.']],
  [['LYRA', 'En el bosque del crepúsculo el sol nunca se pone. Así querías que fuera aquel día, ¿verdad?']],
  [['LYRA', 'Los muertos no deberían volver, Kael. Ni siquiera yo.'], ['TIC', '¿Ha dicho lo que creo que ha dicho?']],
  [['LYRA', 'Hace frío aquí… como el instante en el que estoy atrapada.']],
  [['LYRA', 'Él se acerca. Tu sombra. Quiere congelar el tiempo para siempre en la noche del incendio.']],
  [],
  [['LYRA', 'Bajo el mar el tiempo va más lento. Aquí casi puedo tocarte.'], ['TIC', '¡Nuevo poder: el ECO! Graba tus movimientos y tu yo del pasado los repetirá. Úsalo para pisar dos placas a la vez.']],
  [['LYRA', 'Cada grano de arena es un segundo que alguien perdió. No pierdas los tuyos buscándome.']],
  [['LYRA', 'Ya casi, hermanito. Pero prométeme algo: cuando llegue el final… déjame ir.'], ['KAEL', 'No puedo prometer eso.'], ['LYRA', 'Lo harás. Te conozco.']],
  [],
  [['LYRA', 'Las brujas decían que el tiempo se puede embotellar. Mintieron. Solo se puede compartir.'], ['TIC', 'Puaj. Tengo barro hasta en los engranajes.']],
  [['LYRA', 'Él también quiso detener el tiempo para no perder a nadie. Mira cómo acabó, hermanito.'], ['KAEL', 'No seré como él.'], ['LYRA', 'Lo sé.']],
  [['LYRA', 'De pequeños buscábamos cristales en el río. Tú siempre me regalabas el más bonito… aunque fuera un trozo de botella.'], ['TIC', 'Eso explica mucho sobre tus regalos, chaval.']],
  [['LYRA', 'El ciervo de luz guiaba a los perdidos de vuelta a casa. Ahora vuelve a ser libre… gracias a ti.'], ['KAEL', '¿Y a ti quién te guía, Lyra?'], ['LYRA', 'Tú, hermanito. Siempre tú.']],
  [['LYRA', 'En esa biblioteca estaba escrito el día del incendio. Lo sabían, Kael. La Orden lo sabía.'], ['KAEL', '¿Y no hicieron nada?'], ['TIC', '…Creo que ese libro mejor lo dejamos cerrado. Sigamos.']],
  [['LYRA', 'Cuando había tormenta te metías en mi cama y contábamos los segundos entre el rayo y el trueno.'], ['LYRA', 'Ya no tienes que contar solo, hermanito.']]
];
// Tic comenta cada fase (mundo x fase)
const TICL = [
  ['Primero lo primero: muévete, salta y no te caigas. Es más difícil de lo que parece.', 'Las lianas y los resortes son tus amigos. Las zarigüeyas, no tanto.', 'El fragmento late al final de la jungla. Y algo muy grande croa cerca.'],
  ['Velmora, la ciudad maldita. Las campanas callaron cuando cayó el fragmento.', 'Con el SHIFT puedes cambiar de dimensión. Cian y violeta: dos mundos, un Kael.', 'En lo alto de la catedral duerme una gárgola colosal. Sus rayos malditos duelen. Te lo digo por experiencia.'],
  ['Aquí hace un calor de mil demonios. Literalmente, más adelante.', 'Los bloques agrietados se rompen al pisarlos. No te quedes quieto.', 'La lava sube. ¡Sube, sube, SUBE! Y arriba espera un hechicero.'],
  ['Un bosque donde el sol nunca termina de ponerse. Precioso. Sospechoso.', 'Las corrientes de aire te elevan. Déjate llevar, como yo en las reuniones.', 'Siento que algo nos observa desde arriba. Un ojo. Muy grande.'],
  ['Un cementerio. Genial. Justo lo que mis engranajes necesitaban.', 'Los espectros solo se tocan en la dimensión violeta. ¡SHIFT y espadazo!', 'Un caballero que no sabe que su guerra terminó hace siglos. Atácale por la espalda.'],
  ['Hielo. El suelo resbala, así que frena con tiempo.', 'Las estalactitas caen cuando pasas debajo. Mira arriba de vez en cuando.', 'Escucho un rugido helado. Esquiva sus cargas y que choque contra la pared.'],
  ['El Abismo. Si oyes voces, no son mías. Bueno, a veces sí.', 'Fuego, lava y almas en pena. Lo normal de un martes.', 'El demonio guarda el penúltimo fragmento de esta parte del viaje. Cuando baje a descansar… ¡a por él!'],
  ['La Ciudadela del Tiempo, fuera de toda era. Aquí la gravedad hace lo que quiere.', 'Engranajes, láseres y dimensiones. Todo lo que has aprendido, junto.', 'Tu sombra te espera. Conoce todos tus trucos. Sé mejor que tú mismo.'],
  ['¡Agua! Dentro del agua puedes nadar: pulsa SALTO sin parar para subir.', 'Las corrientes te arrastran. Y las medusas pican. Mucho.', 'El Leviatán duerme en el fondo. Cuando muerda el suelo, ataca su señuelo.'],
  ['El Desierto Eterno. Aquí la arena cae hacia arriba. No preguntes.', 'Usa el ECO: graba tu camino hasta la placa y tu eco la mantendrá pulsada mientras cruzas.', 'La Esfinge solo se rinde ante quien está en dos lugares a la vez. ¿Te suena?'],
  ['El Templo Celeste. Los anillos dorados son ANCLAS: acércate en el aire y te engancharás.', 'Balancéate y suelta con SALTO en el momento justo. ¡Wiii!', 'El Serafín invierte el cielo y la tierra. Mantén la cabeza fría… y del revés.'],
  ['El Nexo. Aquí están todos los mundos a la vez. Y todo lo que has aprendido.', 'Ya casi. Puedo sentir a Lyra. Y algo enorme que respira entre los segundos.', 'El Devorador de Horas. Este es el final, Kael. Hagámoslo bien.'],
  ['El Pantano de las Brujas. Si oyes risitas en la niebla, no eran mías.', 'El agua está turbia y los espectros solo se tocan en la dimensión violeta. ¡SHIFT!', 'La Bruja Madre. Cuando caiga aturdida tras sus picados… ¡a por ella!'],
  ['La Ciudadela del Rey Caído. Todo aquí está encadenado. Hasta el tiempo.', 'Los caballeros siguen defendiendo un reino que ya no existe. Atácalos por la espalda.', 'El Rey Caído. Embiste como una tormenta. Cuando clave la espada en el suelo, ¡golpéalo!'],
  ['Las Minas de Cristal. Todo brilla… y casi todo lo que brilla aquí quiere morderte.', 'Las vagonetas siguen rodando sin mineros. Súbete y no mires abajo. Ah, y los cristales del techo caen.', 'El Gólem de Cristal. Su coraza solo se rompe si pisas las dos placas a la vez. Tu ECO, Kael.'],
  ['El Bosque de Huesos. Estos árboles no son de madera. No preguntes de qué son. Bueno… ya lo sabes.', 'Las tumbas se abren al pasar y los espectros solo se tocan en la dimensión violeta. ¡SHIFT!', 'El Ciervo Espectral. Antes guiaba a los viajeros perdidos. Cuando clave las astas en el suelo, ¡golpéalo!'],
  ['La Biblioteca Prohibida. Silencio, por favor. Bueno, los esqueletos no lo respetan, así que nosotros tampoco.', 'Las estanterías de otra dimensión se atraviesan con SHIFT. Y las placas… ya sabes: ECO.', 'El Archivero Sin Rostro. Rompe las tres palancas para quitarle el escudo. Y no le preguntes por su cara.'],
  ['La Torre de las Tormentas. Agárrate fuerte: aquí el viento sopla con ganas de tirarnos.', 'Los anillos dorados son tu salvación. Engánchate y deja que el vendaval haga el resto.', 'El Dragón de la Tormenta. Cuando caiga aturdido tras sus picados… ¡a por él!']
];
// Palabras de cada guardián antes del combate
const BOSSL = [
  [['BOSS', '¡CROAAAC! Este fragmento brilla… ¡y es MÍO!'], ['TIC', 'Salta sus ondas de choque. Y no le mires a los ojos. Son raros.']],
  [['BOSS', 'Mil años vigilando esta catedral… y por fin llega algo que romper.'], ['TIC', 'Cuando caiga al suelo después de disparar, ¡golpéala!']],
  [['BOSS', 'El fuego purifica, niño. Deja que purifique tu error.'], ['TIC', 'Rompe las tres palancas para quitarle el escudo.']],
  [['BOSS', 'Te he visto caer mil veces en mil futuros. Este será uno más.']],
  [['BOSS', 'Juré proteger este lugar hasta el fin de los tiempos. Y el tiempo… se ha detenido.']],
  [['BOSS', 'GRRRRRRAAAH…'], ['TIC', 'Creo que no habla. Pero muerde.']],
  [['BOSS', 'Los siglos saben dulces. Tú sabrás a eternidad.']],
  [['SOMBRIO', 'Yo soy tú. El que no se rindió. Apártate de mi camino.'], ['KAEL', 'No. Esta vez no voy a huir del pasado.']],
  [['BOSS', 'Las mareas del tiempo me obedecen. Hundiré tu luz en el abismo.']],
  [['BOSS', 'Responde, viajero: ¿qué se pierde al recuperarlo?'], ['KAEL', '…'], ['BOSS', 'Demasiado tarde.']],
  [['BOSS', 'Aquí arriba el cielo es suelo y el suelo es cielo. Tú no perteneces a ningún lugar.']],
  [['DEVO', 'DIECIOCHO INSTANTES. DIECIOCHO MUNDOS. TODO EL TIEMPO… SERÁ MÍO.'], ['KAEL', 'El tiempo no es de nadie.']],
  [['BOSS', 'Hueles a tiempo robado, niño. Mi caldero lleva siglos esperándote.'], ['TIC', 'Esquiva sus picados. ¡Y no aceptes nada que te ofrezca!']],
  [['BOSS', 'Yo también tuve a alguien a quien salvar. Mi reino entero. Y fracasé.'], ['KAEL', 'Entonces déjame terminar lo que tú no pudiste.']],
  [['BOSS', 'PIEDRA… RECUERDA… TODO. TÚ… ROMPISTE… EL TIEMPO.'], ['TIC', 'Pisa las dos placas con tu ECO. ¡Su coraza no aguanta eso!']],
  [['BOSS', '…'], ['TIC', 'No habla. Pero mira cómo baja las astas. ¡Prepárate para la embestida!']],
  [['BOSS', 'Cada vida es un libro, niño. La tuya ya tiene el final escrito. Déjame leértelo.'], ['KAEL', 'Prefiero escribirlo yo.']],
  [['BOSS', 'EL CIELO ES MÍO. EL TRUENO ES MÍO. TU ÚLTIMO SEGUNDO… TAMBIÉN.'], ['TIC', 'Esquiva sus picados. ¡Y no te quedes debajo cuando ruja!']]
];

// ---------------- Motor de escenas ----------------
let cut = null, dlg = null;
function playCut(id, then) {
  cut = { id, sc: CUTS[id], i: 0, li: 0, t: 0, shown: 0, then, fadeIn: 1 };
  if (typeof setView === 'function') setView(MENUW(), 360);
  state = 'cutscene'; stopAmbience(); playMusic(id === 'ending' ? 'menu' : 'menu');
}
function cutAdvance() {
  if (!cut) return;
  const s = cut.sc[cut.i], line = s.lines[cut.li];
  if (cut.shown < line[1].length) { cut.shown = line[1].length; return; }
  sfx('click', .5);
  cut.li++;
  if (cut.li >= s.lines.length) { cut.li = 0; cut.i++; cut.t = 0; cut.fadeIn = 1; }
  cut.shown = 0;
  if (cut.i >= cut.sc.length) endCut();
}
function endCut() { const f = cut && cut.then; cut = null; if (f) f(); }
function updateCut(dt) {
  if (!cut) return;
  cut.t += dt; cut.fadeIn = Math.max(0, cut.fadeIn - dt * 1.5);
  const line = cut.sc[cut.i].lines[cut.li];
  const before = Math.floor(cut.shown);
  cut.shown = Math.min(line[1].length, cut.shown + dt * 46);
  if (Math.floor(cut.shown) !== before && Math.floor(cut.shown) % 3 === 0) sfx('type', .05, line[0] === 'TIC' ? 2 : line[0] === 'LYRA' ? 1.5 : 1.1);
}
// Diálogo en juego (burbuja con retrato, no detiene la acción salvo en la intro del jefe)
function sayLines(lines, hold) { dlg = { lines, i: 0, shown: 0, t: 0, hold: !!hold }; }
function dlgAdvance() {
  if (!dlg) return false;
  const l = dlg.lines[dlg.i];
  if (dlg.shown < l[1].length) { dlg.shown = l[1].length; return true; }
  dlg.i++; dlg.shown = 0; dlg.t = 0;
  if (dlg.i >= dlg.lines.length) dlg = null;
  return true;
}
function updateDlg(dt) {
  if (!dlg) return;
  if (dlg.delay > 0) { dlg.delay -= dt; return; }
  const l = dlg.lines[dlg.i]; dlg.t += dt;
  const b = Math.floor(dlg.shown); dlg.shown = Math.min(l[1].length, dlg.shown + dt * 48);
  if (Math.floor(dlg.shown) !== b && Math.floor(dlg.shown) % 4 === 0) sfx('type', .04, l[0] === 'TIC' ? 2 : 1.2);
  if (!dlg.hold && dlg.shown >= l[1].length && dlg.t > 1.6 + l[1].length * 0.045) dlgAdvance();
}
