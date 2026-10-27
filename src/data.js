// =====================================================================
//  DATOS: mundos, enemigos, historia y generador de niveles por bloques
// =====================================================================
const DIFFS = [
  { name: 'FÁCIL',   hp: 150, dmg: .6,  spd: .85, boss: .8,   aggr: .9,  lava: 8,  c: '#5ef08a', extra: 0 },
  { name: 'NORMAL',  hp: 100, dmg: 1,   spd: 1,   boss: 1.15,  aggr: 1.15,  lava: 12, c: '#ffd34d', extra: 0 },
  { name: 'DIFÍCIL', hp: 80,  dmg: 1.6, spd: 1.3, boss: 1.5, aggr: 1.45,lava: 16, c: '#ff5470', extra: 1 },
  { name: 'PESADILLA', hp: 70, dmg: 2, spd: 1.42, boss: 1.75, aggr: 1.65, lava: 19, c: '#c45cff', extra: 1, nm: 1 }
];
// Tipos de enemigo: b = comportamiento, face = hacia dónde mira el sprite original
const ENEMY = {
  opossum:   { b: 'walker',  anim: 'opossum', w: 32, h: 22, hp: 2, face: -1, spd: 70, death: 'poof' },
  frog:      { b: 'jumper',  anim: 'frog_idle', jump: 'frog_jump', w: 28, h: 24, hp: 2, face: -1, death: 'poof' },
  eagle:     { b: 'flyer',   anim: 'eagle', w: 30, h: 30, hp: 1, face: -1, shot: 'orb', death: 'poof' },
  turret:    { b: 'shooter', anim: 'turret', w: 24, h: 22, hp: 2, face: 1, shot: 'bolt', still: true, death: 'boom' },
  drone:     { b: 'flyer',   anim: 'drone', w: 38, h: 34, hp: 2, face: 0, shot: 'bolt', death: 'boom', oy: 10 },
  cyhound:   { b: 'chaser',  anim: 'hound_neon', w: 44, h: 26, hp: 3, face: -1, spd: 80, run: 300, death: 'boom' },
  firerat:   { b: 'walker',  anim: 'rat_fire', w: 32, h: 22, hp: 2, face: -1, spd: 80, death: 'flame_death' },
  worm:      { b: 'shooter', anim: 'worm_walk', atk: 'worm_atk', w: 34, h: 28, hp: 3, face: 1, shot: 'wormball', spd: 30, death: 'flame_death' },
  fireeagle: { b: 'flyer',   anim: 'eagle_fire', w: 30, h: 30, hp: 1, face: -1, shot: 'orb', death: 'flame_death' },
  goblin:    { b: 'bomber',  anim: 'gob_run', atk: 'gob_atk', w: 24, h: 34, hp: 3, face: 1, spd: 90, run: 220, death: 'poof' },
  mushroom:  { b: 'shooter', anim: 'mush', w: 26, h: 30, hp: 3, face: 1, shot: 'spore', still: true, death: 'poof', animAlways: true },
  eye:       { b: 'diver',   anim: 'eye', w: 30, h: 22, hp: 2, face: 1, death: 'poof' },
  gskel:     { b: 'riser',   anim: 'gskel_walk', rise: 'gskel_rise', w: 22, h: 44, hp: 3, face: -1, spd: 60, death: 'flame_death' },
  hound:     { b: 'chaser',  anim: 'hound', w: 44, h: 26, hp: 3, face: -1, spd: 80, run: 300, death: 'flame_death' },
  ghost:     { b: 'ghost',   anim: 'ghost', w: 26, h: 46, hp: 2, face: 1, death: 'poof' },
  iceskel:   { b: 'riser',   anim: 'gskel_ice_walk', rise: 'gskel_ice_rise', w: 22, h: 44, hp: 3, face: -1, spd: 60, death: 'poof' },
  icehound:  { b: 'chaser',  anim: 'hound_ice', w: 44, h: 26, hp: 3, face: -1, spd: 80, run: 320, death: 'poof' },
  iceeye:    { b: 'diver',   anim: 'eye_ice', w: 30, h: 22, hp: 2, face: 1, death: 'poof' },
  infworm:   { b: 'shooter', anim: 'worm_walk', atk: 'worm_atk', w: 34, h: 28, hp: 4, face: 1, shot: 'wormball', spd: 40, death: 'flame_death' },
  infhound:  { b: 'chaser',  anim: 'hound_ember', w: 44, h: 26, hp: 3, face: -1, spd: 90, run: 340, death: 'flame_death' },
  infghost:  { b: 'ghost',   anim: 'ghost_fire', w: 26, h: 46, hp: 3, face: 1, death: 'flame_death' },
  shieldskel:{ b: 'shield',  anim: 'skel_v_walk', shield: 'skel_v_shield', atk: 'skel_v_atk', w: 26, h: 46, hp: 4, face: 1, spd: 50, death: 'poof' },
  goldskel:  { b: 'riser',   anim: 'gskel_gold_walk', rise: 'gskel_gold_rise', w: 22, h: 44, hp: 3, face: -1, spd: 70, death: 'poof' },
  goldeye:   { b: 'diver',   anim: 'eye_gold', w: 30, h: 22, hp: 2, face: 1, death: 'poof' },
  cdrone:    { b: 'flyer',   anim: 'drone', w: 38, h: 34, hp: 2, face: 0, shot: 'bolt', death: 'boom', oy: 10 },
  // --- Criaturas nuevas (arte Higgsfield, animación procedural) ---
  crab:      { b: 'walker',  anim: 'cr_crab', stat: 'walk', w: 40, h: 26, hp: 3, face: 1, spd: 55, death: 'poof', glow: 'rgba(255,80,180,.35)' },
  angler:    { b: 'flyer',   anim: 'cr_angler', stat: 'swim', w: 40, h: 30, hp: 2, face: 1, shot: 'orb', death: 'poof', glow: 'rgba(80,230,255,.55)', lure: [52, 8] },
  jelly:     { b: 'bob',     anim: 'cr_jelly', stat: 'jelly', w: 24, h: 40, hp: 1, face: 0, death: 'poof', glow: 'rgba(230,110,255,.55)' },
  scarab:    { b: 'chaser',  anim: 'cr_scarab', stat: 'walk', w: 40, h: 26, hp: 3, face: 1, spd: 60, run: 260, death: 'poof', glow: 'rgba(60,240,220,.25)' },
  mummy:     { b: 'riser',   anim: 'cr_mummy', stat: 'walk', w: 22, h: 46, hp: 3, face: 1, spd: 55, death: 'poof', glow: 'rgba(255,190,80,.35)' },
  vulture:   { b: 'diver',   anim: 'cr_vulture', stat: 'fly', w: 36, h: 24, hp: 2, face: 1, death: 'poof' },
  seraph:    { b: 'flyer',   anim: 'cr_seraph', stat: 'float', w: 30, h: 44, hp: 3, face: 1, shot: 'bolt', death: 'poof', glow: 'rgba(255,230,150,.5)' },
  golem:     { b: 'jumper',  anim: 'cr_golem', stat: 'hop', w: 34, h: 40, hp: 4, face: 1, death: 'poof', glow: 'rgba(160,220,255,.3)' },
  voidling:  { b: 'chaser',  anim: 'cr_voidling', stat: 'walk', w: 26, h: 40, hp: 3, face: 1, spd: 70, run: 330, death: 'poof', glow: 'rgba(200,60,255,.5)' }
};
const WORLDS = [
  { name: 'JUNGLA FLOTANTE', sub: 'Resortes y lianas', c: '#7dea5a', tiles: 'T_jungle', music: 'w0', bg: 0, weather: 'leaves', critter: 'bird',
    g: ['opossum', 'opossum', 'frog'], a: ['eagle'], spk: 'spk_jungle', mplat: 'p_platform-long',
    pool: ['flat', 'gap', 'stairs', 'mover', 'elevator', 'spring', 'spikes', 'bouncefield'], sig: ['spring', 'wallclimb', 'spikes'],
    deco: [['p_tree', 1], ['p_bush', 3], ['p_rock', 2], ['p_shrooms', 2], ['d_grass1', 4], ['d_grass2', 4], ['d_plant1', 2], ['d_plant2', 2]],
    boss: { type: 0, name: 'GRAN SAPO ANCESTRAL', hint: '¡Salta las ondas de choque!' },
    lore: 'El Reloj del Origen se ha roto y sus fragmentos han desgarrado la realidad. Kael, el último Guardián del Tiempo, despierta en la Jungla Flotante.' },
  { name: 'VELMORA, CIUDAD MALDITA', sub: 'Catedrales y dimensiones', c: '#d0506a', tiles: 'T_cemetery', music: 'w1', bg: 1, weather: 'rain', critter: 'crow',
    g: ['turret', 'cyhound'], a: ['drone'], spk: 'spk_cem', mplat: 'gv_mplat',
    pool: ['flat', 'gap', 'lasers', 'crumble', 'shiftgap', 'shiftwall', 'mover', 'spikes', 'stairs'], sig: ['shiftgap', 'lasers', 'crumble'],
    deco: [['gv_statue', 1], ['gv_stone-1', 3], ['gv_pillar-broken', 2], ['gv_tree-1', 1]],
    boss: { type: 1, name: 'GÁRGOLA DE LA CATEDRAL', hint: 'Esquiva sus rayos malditos y golpéala cuando caiga' },
    lore: 'Un fragmento cayó sobre Velmora, la ciudad de las mil campanas, y la maldijo para siempre. Aquí despiertas el poder del SHIFT: cambia de dimensión para hacer aparecer y desaparecer plataformas.' },
  { name: 'CALDERO VOLCÁNICO', sub: 'Lava y fuego', c: '#ff8f3a', tiles: 'T_volcano', music: 'w2', bg: 2, weather: 'embers', critter: null, lavaPits: true,
    g: ['firerat', 'worm'], a: ['fireeagle'], spk: 'spk_inf', mplat: 'p_platform_v',
    pool: ['flat', 'lavapit', 'firejets', 'crumble', 'stairs', 'mover', 'shiftgap'], sig: ['lavapit', 'firejets'],
    deco: [['p_rock_v', 3], ['p_skulls', 3], ['p_spike-skull', 2], ['d_torch', 2]],
    boss: { type: 2, name: 'HECHICERO DE MAGMA', hint: 'Golpea las 3 palancas para romper su escudo' },
    lore: 'El calor del núcleo funde el tiempo mismo. La lava sube y el Hechicero de Magma custodia el tercer fragmento.' },
  { name: 'BOSQUE DEL CREPÚSCULO', sub: 'Vientos y hongos', c: '#ffb070', tiles: 'T_dusk', music: 'w3', bg: 3, weather: 'fireflies', critter: 'bird',
    g: ['goblin', 'mushroom'], a: ['eye'], spk: 'spk_jungle', mplat: 'p_platform-long',
    pool: ['flat', 'updraft', 'gust', 'bouncefield', 'stairs', 'gap', 'spring', 'shiftgap'], sig: ['updraft', 'gust'],
    deco: [['p_tree', 2], ['p_bush', 3], ['p_shrooms', 4], ['p_rock', 2], ['d_plant1', 2]],
    boss: { type: 3, name: 'OJO ABISAL', hint: 'Esquiva sus embestidas y golpéalo al bajar' },
    lore: 'En el bosque donde el sol nunca termina de ponerse, los vientos del tiempo soplan con fuerza. Algo te observa desde las alturas.' },
  { name: 'CEMENTERIO MALDITO', sub: 'Espectros y tumbas', c: '#c070ff', tiles: 'T_cemetery', music: 'w4', bg: 4, weather: 'fog', critter: 'crow',
    g: ['gskel', 'hound'], a: ['ghost'], spk: 'spk_cem', mplat: 'gv_mplat',
    pool: ['graves', 'ghosts', 'spikes', 'gap', 'shiftwall', 'crumble', 'mover', 'flat'], sig: ['ghosts', 'graves'],
    deco: [['gv_statue', 1], ['gv_stone-1', 3], ['gv_stone-2', 3], ['gv_stone-4', 2], ['gv_bush-small', 2], ['gv_tree-1', 1], ['gv_pillar-broken', 1]],
    boss: { type: 4, name: 'CABALLERO ESQUELETO', hint: 'Su escudo bloquea de frente: atácalo por la espalda' },
    lore: 'Los muertos se levantan cuando el tiempo se detiene. Los espectros solo son tangibles en la otra dimensión: usa el SHIFT para golpearlos.' },
  { name: 'CRIPTA HELADA', sub: 'Hielo y estalactitas', c: '#9fe3ff', tiles: 'T_ice', music: 'w5', bg: 5, weather: 'snow', critter: 'crow', ice: true,
    g: ['iceskel', 'icehound'], a: ['iceeye'], spk: 'spk_ice', mplat: 'gv_mplat',
    pool: ['icicles', 'crumble', 'gap', 'spikes', 'stairs', 'mover', 'shiftgap', 'flat'], sig: ['icicles'],
    deco: [['gvi_stone-1', 3], ['gvi_stone-2', 2], ['gvi_pillar', 1], ['gvi_pillar-broken', 2], ['gvi_statue', 1], ['gvi_tree-1', 1]],
    boss: { type: 5, name: 'BESTIA DE ESCARCHA', hint: 'Esquiva sus cargas y las estalactitas' },
    lore: 'Bajo el hielo eterno, cada paso resbala. Cuidado con las estalactitas: caen cuando pasas debajo.' },
  { name: 'ABISMO INFERNAL', sub: 'Llamas y almas', c: '#ff4a3a', tiles: 'T_inferno', music: 'w6', bg: 6, weather: 'embers', critter: null, lavaPits: true,
    g: ['infworm', 'infhound'], a: ['infghost'], spk: 'spk_inf', mplat: 'gv_mplat',
    pool: ['lavapit', 'firejets', 'shiftwall', 'shiftgap', 'crumble', 'spikes', 'stairs', 'ghosts'], sig: ['firejets', 'lavapit', 'shiftwall'],
    deco: [['gvf_pillar', 2], ['gvf_pillar-broken', 2], ['gvf_statue', 1], ['gvf_stone-1', 2], ['d_torch', 3]],
    boss: { type: 6, name: 'DEMONIO DEL ABISMO', hint: 'Aléjate de su aliento y atácalo cuando descienda' },
    lore: 'El penúltimo fragmento arde en el corazón del abismo. El Demonio que lo custodia ha devorado siglos enteros.' },
  { name: 'CIUDADELA DEL TIEMPO', sub: 'Gravedad cero', c: '#ffd34d', tiles: 'T_chrono', music: 'w7', bg: 7, weather: 'clocks', critter: null,
    g: ['shieldskel', 'goldskel'], a: ['goldeye', 'cdrone'], spk: 'spk_cyber', mplat: 'w_platform',
    pool: ['lowgrav', 'gears', 'shiftgap', 'shiftwall', 'conveyor', 'lasers', 'spikes', 'firejets', 'stairs'], sig: ['lowgrav', 'gears', 'shiftgap'],
    deco: [['w_antenna', 1], ['w_control-box-1', 2], ['w_control-box-2', 2], ['w_monitorface', 2, 1]],
    boss: { type: 7, name: 'KAEL SOMBRÍO', hint: 'Tu reflejo conoce tus movimientos. Anticípate.' },
    lore: 'En la Ciudadela, fuera del tiempo, te espera tu propio reflejo: el Kael que eligió romper el Reloj. Solo uno puede salir de aquí.' },
  { name: 'ARRECIFE ABISAL', sub: 'Nado y corrientes', c: '#3ff0d0', tiles: 'T_reef', music: 'w5', rate: 0.92, bg: 8, weather: 'bubbles', critter: null,
    g: ['crab'], a: ['angler', 'jelly'], spk: 'spk_ice', mplat: 'gv_mplat',
    pool: ['water', 'current', 'gap', 'stairs', 'mover', 'spikes', 'shiftgap', 'crumble'], sig: ['water', 'current'],
    deco: [['gvi_stone-1', 2], ['gvi_stone-2', 2], ['gvi_pillar-broken', 2], ['gvi_statue', 1]],
    boss: { type: 8, name: 'LEVIATÁN DE CORAL', hint: 'Cuando muerda el suelo, ¡golpea su señuelo!' },
    lore: 'Un fragmento se hundió en una ciudad sumergida. Bajo el agua el tiempo fluye despacio: pulsa SALTO para nadar.' },
  { name: 'DESIERTO ETERNO', sub: 'Eco temporal y arenas', c: '#ffc24a', tiles: 'T_sand', music: 'w2', rate: 0.9, bg: 9, weather: 'sand', critter: null,
    g: ['scarab', 'mummy'], a: ['vulture'], spk: 'spk_inf', mplat: 'p_platform_v',
    pool: ['echo', 'quicksand', 'sandfall', 'gap', 'stairs', 'crumble', 'spikes', 'mover', 'firejets'], sig: ['echo', 'quicksand', 'echo'],
    deco: [['p_skulls', 2], ['p_rock_v', 2], ['gvf_pillar-broken', 2], ['gvf_statue', 1]],
    boss: { type: 9, name: 'ESFINGE DEL RELOJ', hint: 'Pisa las dos placas a la vez (tú y tu ECO) para romper su escudo' },
    lore: 'Arena que cae hacia el cielo y ruinas de relojes colosales. Aquí necesitarás estar en dos lugares a la vez: usa el ECO.' },
  { name: 'TEMPLO CELESTE', sub: 'Anclas y nubes', c: '#bfe6ff', tiles: 'T_marble', music: 'w3', rate: 1.05, bg: 10, weather: 'clouds', critter: 'bird',
    g: ['golem'], a: ['seraph'], spk: 'spk_ice', mplat: 'w_platform',
    pool: ['anchors', 'anchors2', 'clouds', 'updraft', 'gap', 'stairs', 'lowgrav', 'echo', 'mover'], sig: ['anchors', 'anchors2', 'clouds'],
    deco: [['gvi_pillar', 2], ['gvi_statue', 1], ['gvi_pillar-broken', 2], ['gvi_stone-1', 2]],
    boss: { type: 10, name: 'SERAFÍN INVERTIDO', hint: 'Cuando el cielo se invierta, mantén la calma: tus controles no cambian' },
    lore: 'Templos colgando de las nubes y cascadas que suben. Engánchate a los anillos dorados acercándote en el aire.' },
  { name: 'NEXO DE CHRONOS', sub: 'Todos los mundos', c: '#ff6ad5', tiles: 'T_void', music: 'w7', rate: 0.94, bg: 11, weather: 'void', critter: null,
    g: ['voidling', 'shieldskel', 'crab'], a: ['seraph', 'goldeye', 'jelly'], spk: 'spk_cyber', mplat: 'w_platform',
    pool: ['anchors', 'echo', 'water', 'shiftgap', 'lasers', 'firejets', 'lowgrav', 'clouds', 'quicksand', 'gears', 'shiftwall'], sig: ['anchors', 'echo', 'shiftgap', 'water'],
    deco: [['w_antenna', 1], ['gvf_pillar-broken', 2], ['gvi_statue', 1], ['w_monitorface', 1, 1]],
    boss: { type: 11, name: 'EL DEVORADOR DE HORAS', hint: 'Cuando se agote y baje, ¡ataca su ojo!' },
    lore: 'El corazón roto del tiempo. Aquí todos los mundos se mezclan. El último fragmento… y el Devorador.' },
  { name: 'PANTANO DE LAS BRUJAS', sub: 'Ciénagas y maleficios', c: '#8fe36a', tiles: 'T_jungle', music: 'w4', rate: 0.9, bg: 12, weather: 'fog', critter: 'crow',
    g: ['frog', 'mushroom', 'gskel'], a: ['ghost', 'eye'], spk: 'spk_jungle', mplat: 'gv_mplat',
    pool: ['water', 'graves', 'ghosts', 'crumble', 'gap', 'spring', 'stairs', 'mover', 'spikes', 'updraft'], sig: ['water', 'ghosts', 'graves'],
    deco: [['gv_tree-1', 2], ['gv_stone-1', 2], ['gv_bush-small', 3]],
    boss: { type: 10, skin: 'boss_witch', name: 'LA BRUJA MADRE', hint: 'Esquiva sus picados y golpéala cuando quede aturdida en el suelo' },
    lore: 'Más allá de las nubes, un fragmento se pudre en el Pantano de las Brujas. La niebla susurra tu nombre… y algo en el agua responde.' },
  { name: 'CIUDADELA DEL REY CAÍDO', sub: 'Tronos rotos y cadenas', c: '#8fb4ff', tiles: 'T_cemetery', music: 'w6', rate: 0.88, bg: 13, weather: 'embers', critter: 'crow',
    g: ['shieldskel', 'hound', 'gskel'], a: ['infghost', 'goldeye'], spk: 'spk_inf', mplat: 'gv_mplat',
    pool: ['crumble', 'spikes', 'firejets', 'shiftwall', 'shiftgap', 'mover', 'stairs', 'gap', 'graves', 'anchors'], sig: ['shiftwall', 'firejets', 'crumble'],
    deco: [['gvf_pillar', 2], ['gvf_pillar-broken', 2], ['gvf_statue', 1], ['d_torch', 2]],
    boss: { type: 8, skin: 'boss_king', name: 'EL REY CAÍDO', hint: 'Cuando clave su espada en el suelo y quede atrapado, ¡golpéalo!' },
    lore: 'El último reino antes del Nexo. Su rey juró proteger el tiempo y acabó encadenado a él. Su trono vacío aún arde con fuego de almas.' },
  // --- Mundos 15-18 (v1.9): arte recoloreado a partir de mundos existentes ---
  { name: 'MINAS DE CRISTAL', sub: 'Cristales y vagonetas', c: '#c48cff', tiles: 'T_ice', music: 'w5', rate: 0.95, bg: 14, weather: 'fireflies', critter: null,
    g: ['golem', 'iceskel'], a: ['iceeye'], spk: 'spk_ice', mplat: 'gv_mplat',
    pool: ['icicles', 'mover', 'elevator', 'conveyor', 'crumble', 'gap', 'spikes', 'shiftgap', 'stairs'], sig: ['mover', 'icicles', 'conveyor'],
    deco: [['gvi_stone-1', 3], ['gvi_stone-2', 2], ['gvi_pillar-broken', 2]],
    boss: { type: 9, skin: 'boss_golemc', sfl: 1, name: 'GÓLEM DE CRISTAL', hint: 'Pisa las dos placas a la vez (tú y tu ECO) para romper su coraza' },
    lore: 'Bajo las montañas, un fragmento cayó en las Minas de Cristal y cada piedra empezó a recordar. Las vagonetas aún ruedan solas por raíles que nadie vigila.' },
  { name: 'BOSQUE DE HUESOS', sub: 'Osarios y espectros', c: '#a8e0c8', tiles: 'T_cemetery', music: 'w4', rate: 0.92, bg: 15, weather: 'fog', critter: 'crow',
    g: ['gskel', 'hound'], a: ['ghost', 'eye'], spk: 'spk_cem', mplat: 'gv_mplat',
    pool: ['graves', 'ghosts', 'bouncefield', 'spring', 'crumble', 'gap', 'stairs', 'mover', 'spikes', 'shiftwall'], sig: ['graves', 'bouncefield', 'ghosts'],
    deco: [['gv_tree-1', 2], ['gv_stone-1', 3], ['gv_stone-2', 2], ['gv_bush-small', 2]],
    boss: { type: 8, skin: 'boss_stag', sfl: 1, name: 'CIERVO ESPECTRAL', hint: 'Cuando clave sus astas en el suelo y quede atrapado, ¡golpéalo!' },
    lore: 'Un bosque cuyos árboles crecieron de los huesos de un ejército olvidado. Entre las raíces vaga un ciervo de luz pálida que perdió el camino… y la razón.' },
  { name: 'BIBLIOTECA PROHIBIDA', sub: 'Libros y dimensiones', c: '#ffc070', tiles: 'T_cemetery', music: 'w1', rate: 0.9, bg: 16, weather: 'embers', critter: null,
    g: ['shieldskel', 'gskel'], a: ['ghost', 'eye'], spk: 'spk_cem', mplat: 'gv_mplat',
    pool: ['shiftwall', 'shiftgap', 'echo', 'crumble', 'mover', 'elevator', 'stairs', 'gap', 'spikes', 'firejets'], sig: ['shiftwall', 'echo', 'shiftgap'],
    deco: [['gv_statue', 1], ['gv_pillar-broken', 2], ['gv_stone-1', 2], ['d_torch', 2]],
    boss: { type: 2, skin: 'boss_archi', name: 'EL ARCHIVERO SIN ROSTRO', hint: 'Golpea las 3 palancas para romper su escudo' },
    lore: 'La Biblioteca Prohibida guarda cada instante que la Orden quiso olvidar. Los libros vuelan solos y su guardián ya no recuerda su propio rostro.' },
  { name: 'TORRE DE LAS TORMENTAS', sub: 'Rayos y vendavales', c: '#8fa8ff', tiles: 'T_marble', music: 'w6', rate: 0.95, bg: 17, weather: 'rain', critter: null,
    g: ['golem'], a: ['seraph', 'eye'], spk: 'spk_ice', mplat: 'w_platform',
    pool: ['anchors', 'anchors2', 'clouds', 'updraft', 'gust', 'gap', 'stairs', 'mover', 'lowgrav'], sig: ['gust', 'anchors', 'updraft'],
    deco: [['gvi_pillar', 2], ['gvi_statue', 1], ['gvi_pillar-broken', 2], ['gvi_stone-1', 2]],
    boss: { type: 10, skin: 'boss_dragon', sfl: 1, name: 'DRAGÓN DE LA TORMENTA', hint: 'Esquiva sus picados y golpéalo cuando quede aturdido en el suelo' },
    lore: 'La última torre antes del reino caído se alza en el ojo de una tormenta eterna. Allí arriba, un dragón ruge con la voz del trueno.' }
];
// Mundo "parecido" para detalles de ambiente (pasos, nubes, partículas)
const WBASE = { 14: 5, 15: 4, 16: 1, 17: 10 };
function VWI(w) { return WBASE[w] ?? w; }
const HINTS = {
  move: 'Muévete con las flechas y salta los huecos con SALTO',
  sword: 'Pulsa ESPADA para atacar. Encadena golpes para hacer COMBOS',
  doublejump: 'Pulsa SALTO otra vez en el aire para el DOBLE SALTO',
  spring: 'Los hongos saltarines te impulsan muy alto',
  mover: 'Súbete a la plataforma móvil y espera el momento justo',
  dash: 'Usa DASH para cruzar huecos largos (eres invencible mientras dura)',
  relic: 'Cada fase esconde un RELOJ DE ARENA secreto. ¡Explora!',
  wallclimb: 'Deslízate por la pared y pulsa SALTO para rebotar hacia arriba',
  shiftgap: 'Pulsa SHIFT para cambiar de dimensión: aparecen otras plataformas',
  shiftwall: 'Los muros de otra dimensión se atraviesan con SHIFT',
  spikes: 'Ataca en el aire sobre pinchos o enemigos para rebotar',
  ghosts: 'Los espectros solo se pueden golpear en la dimensión violeta (SHIFT)',
  updraft: 'Las corrientes de aire te elevan: déjate llevar',
  lowgrav: 'Zona de gravedad reducida: tus saltos llegan mucho más alto',
  icicles: 'Las estalactitas caen cuando pasas por debajo',
  conveyor: 'Las cintas te arrastran: corre en contra',
  lavapit: 'Los bloques agrietados se desmoronan al pisarlos',
  firejets: 'Observa el ritmo de las llamas antes de cruzar',
  gust: 'Las ráfagas de viento te empujan hacia atrás',
  water: 'En el agua pulsa SALTO varias veces para nadar hacia arriba',
  current: 'Las corrientes te arrastran: nada en contra o aprovéchalas',
  echo: 'Pulsa ECO, camina hasta la placa y vuelve a pulsar ECO: tu eco la mantendrá pulsada',
  quicksand: 'La arena movediza te frena y te hunde: ¡salta sin parar!',
  anchors: 'Acércate en el aire a un anillo dorado y pulsa SALTO para engancharte. Vuelve a pulsar para soltarte',
  clouds: 'Las nubes se deshacen al pisarlas',
  sandfall: 'La arena del tiempo cae hacia arriba: déjate llevar'
};
const GY = 480;

// ---------------- Generador de niveles ----------------
// Torre del Tiempo: fases más cortas, semilla distinta en cada piso
let TOWER_ON = false, TOWER_N = 6, TOWER_SEED = 0, TOWER_TRIAL = false;
function buildStage(wi, act) {
  const D = DIFFS[diffIdx], WD = WORLDS[wi];
  const L = { wi, act, plats: [], enemies: [], gems: [], cherries: [], checks: [], levers: [], decor: [], zones: [], hazards: [], hints: [], critters: [],
              anchors: [], plates: [], doors: [], crystals: [], relic: null, goal: null, lava: null, lavaStrips: [], top: 0, bottom: 540, deathY: 720, start: { x: 70, y: GY - PH } };
  const r = seeded(1000 + wi * 97 + act * 31 + 7 + (TOWER_ON ? TOWER_SEED : 0));
  const solid = (x, y, w, h, extra) => { const s = Object.assign({ k: 'solid', x, y, w: Math.round(w / 16) * 16, h }, extra || {}); L.plats.push(s); return s; };
  const G = (x, w, top) => solid(x, top || GY, w, (top ? GY - top : 0) + 176, { ground: true });
  const P = (x, y, w) => solid(x, y, Math.max(32, w), 16, { float: true });
  const pillar = (x, y1, y2, w) => solid(x, y1, w || 24, y2 - y1, { ground: true, pillar: true });
  const M = (x, y, w, bx_, by, spd) => L.plats.push({ k: 'move', x, y, w: Math.max(32, Math.round(w / 32) * 32), h: 16, ax: x, ay: y, bx: bx_, by, spd, t: r() * 6, dx: 0, dy: 0 });
  const SPRING = (x, y) => L.plats.push({ k: 'bounce', x: x - 20, y: (y || GY) - 12, w: 40, h: 14, sq: 0 });
  const LZ = (x, y, w, ph) => L.plats.push({ k: 'laser', x, y, w, h: 8, phase: ph, on: true, warn: false });
  const BO = (x, w) => L.plats.push({ k: 'boost', x, y: GY - 4, w, h: 4, dir: 1 });
  const BR = (x, y, w) => L.plats.push({ k: 'break', x, y, w: Math.round(w / 16) * 16, h: 16, st: 0, t: 0, oy: 0, vy: 0 });
  const PH_ = (x, y, w, h, ph) => L.plats.push({ k: 'phase', x, y, w, h, ph });
  const CONV = (x, w, dir) => { const s = G(x, w); s.conv = dir; return s; };
  const SPK = (x, w, y) => L.hazards.push({ k: 'spike', x, y: (y || GY) - 12, w, h: 12 });
  const JET = (x, ph) => L.hazards.push({ k: 'jet', x: x - 10, y: GY - 70, w: 20, h: 70, ph, on: false });
  const ICI = (x, y) => L.hazards.push({ k: 'icicle', x: x - 6, y, w: 12, h: 18, st: 0, t: 0, vy: 0, y0: y });
  const LAVA = (x, w) => L.lavaStrips.push({ x, y: GY + 26, w });
  const ZONE = (k, x, y, w, h, fx, fy) => L.zones.push({ k, x, y, w, h, fx: fx || 0, fy: fy || 0 });
  const gem = (x, y) => L.gems.push({ x, y, taken: false, ph: r() * 6 });
  const row = (x, y, c, dx) => { for (let i = 0; i < c; i++) gem(x + i * dx, y); };
  const arc = (x, y, c, dx, hgt) => { for (let i = 0; i < c; i++) gem(x + i * dx, y - Math.sin(i / (c - 1 || 1) * Math.PI) * (hgt || 30)); };
  const CH = (x, y) => L.cherries.push({ x, y, taken: false, ph: r() * 6 });
  const relicSpots = [];
  const RS = (x, y) => relicSpots.push({ x, y });
  const pick = a => a[Math.floor(r() * a.length)];
  const E = (slot, x, y, range) => {
    const id = pick(slot === 'a' ? WD.a : WD.g), d = ENEMY[id];
    const e = { id, d, b: d.b, x, y: slot === 'a' ? y : (y || GY) - d.h, w: d.w, h: d.h, hp: d.hp + (act ? 1 : 0) * (d.hp > 2 ? 1 : 0), hit: 0, t: r() * 5,
      dir: -1, minX: x - (range || 100) / 2, maxX: x + (range || 100) / 2 - d.w, cd: 1 + r() * 2, dead: false, st: 0, x0: x, y0: y, fire: 0, alert: 0, vy: 0, rise: 0 };
    if (d.b === 'riser') { e.st = 'buried'; }
    L.enemies.push(e); return e;
  };
  const fixE = (e, id) => { const dd = ENEMY[id]; e.id = id; e.d = dd; e.b = dd.b; e.w = dd.w; e.h = dd.h; e.hp = dd.hp; e.y0 = e.y; return e; };
  const hint = (x, k) => { if (HINTS[k] && !L.hints.some(h => h.k === k)) L.hints.push({ x, k, text: HINTS[k], shown: false }); };

  const CH_ = {
    flat(x) { G(x, 512); if (r() < .6) G(x + 40 + Math.floor(r() * 3) * 16, 80 + Math.floor(r() * 3) * 16, GY - 32); if ([4, 5, 6, 8, 11].includes(wi) && r() < .7) solid(x + 40, GY - 340, 432, 60, { ceil: true }); E('g', x + 300, GY, 220); if (r() < .5 + D.extra * .3) E('a', x + 200, 330, 0); arc(x + 160, 440, 5, 40, 40); return 512; },
    gap(x) { G(x, 160); P(x + 224, 420, 80); G(x + 368, 160); arc(x + 170, 380, 5, 45, 50); E('a', x + 260, 300); return 528; },
    stairs(x) {
      G(x, 128); const st = [[160, 420, 96], [296, 360, 96], [432, 300, 128], [600, 360, 96], [736, 420, 96]];
      for (const s of st) P(x + s[0], s[1], s[2]);
      G(x + 864, 128); row(x + 450, 270, 3, 40); E('a', x + 500, 220); if (r() < .4) CH(x + 640, 330); return 992;
    },
    mover(x) { G(x, 128); M(x + 150, 430, 96, x + 330, 430, 1.2); G(x + 480, 128); arc(x + 170, 390, 5, 50, 30); E('a', x + 330, 300); return 608; },
    elevator(x) { G(x, 192); M(x + 40, 466, 96, x + 40, 286, 1.0); G(x + 160, 192, 300); G(x + 352, 224); row(x + 190, 270, 3, 45); RS(x + 300, 270); E('g', x + 450, GY, 120); return 576; },
    spring(x) { G(x, 512); SPRING(x + 140); P(x + 210, 230, 176); row(x + 240, 200, 4, 40); RS(x + 400, 200); E('g', x + 400, GY, 160); return 512; },
    spikes(x) { G(x, 576); SPK(x + 190, 96); SPK(x + 400, 64); arc(x + 190, 410, 3, 40, 20); E('g', x + 330, GY, 80); hint(x + 100, 'spikes'); return 576; },
    wallclimb(x) {
      G(x, 288); pillar(x + 192, 200, 396, 24); G(x + 288, 192, 200); G(x + 480, 224);
      row(x + 310, 170, 4, 40); RS(x + 460, 165); hint(x + 60, 'wallclimb'); E('g', x + 600, GY, 120); return 704;
    },
    shiftgap(x) { G(x, 128); PH_(x + 168, 420, 80, 16, 0); PH_(x + 300, 376, 80, 16, 1); PH_(x + 432, 420, 80, 16, 0); G(x + 576, 128); arc(x + 190, 360, 5, 70, 30); hint(x + 40, 'shiftgap'); return 704; },
    shiftwall(x) { G(x, 640); PH_(x + 260, 260, 32, 220, 1); PH_(x + 430, 260, 32, 220, 0); row(x + 300, 440, 3, 40); E('g', x + 560, GY, 100); hint(x + 100, 'shiftwall'); return 640; },
    lasers(x) { G(x, 128); LZ(x + 168, 420, 96, 0); LZ(x + 308, 366, 96, 1.1); LZ(x + 448, 420, 96, 2.2); G(x + 592, 128); row(x + 200, 380, 3, 140); E('a', x + 380, 260); return 720; },
    boost(x) { G(x, 448); BO(x + 220, 140); G(x + 704, 192); arc(x + 470, 380, 5, 50, 60); E('g', x + 120, GY, 100); return 896; },
    conveyor(x) { G(x, 128); CONV(x + 128, 384, -1); G(x + 512, 128); row(x + 180, 440, 5, 60); E('g', x + 330, GY, 140); hint(x + 60, 'conveyor'); return 640; },
    lavapit(x) { G(x, 128); BR(x + 176, 436, 64); BR(x + 304, 404, 64); BR(x + 432, 436, 64); G(x + 560, 128); LAVA(x + 128, 432); row(x + 196, 396, 3, 128); hint(x + 40, 'lavapit'); return 688; },
    firejets(x) { G(x, 640); JET(x + 190, 0); JET(x + 340, 0.9); JET(x + 490, 1.8); row(x + 230, 420, 3, 150); E('a', x + 340, 300); hint(x + 60, 'firejets'); return 640; },
    crumble(x) { G(x, 128); for (let i = 0; i < 4; i++) BR(x + 160 + i * 96, 436 - (i % 2) * 30, 64); G(x + 544, 128); if (WD.lavaPits) LAVA(x + 128, 416); row(x + 180, 390, 4, 96); return 672; },
    updraft(x) { G(x, 128); ZONE('wind', x + 150, 150, 140, 330, 0, -2400); P(x + 300, 220, 160); G(x + 512, 192); row(x + 200, 340, 3, 0.1); for (let i = 0; i < 4; i++) gem(x + 220, 360 - i * 50); RS(x + 420, 190); hint(x + 40, 'updraft'); return 704; },
    gust(x) { G(x, 640); ZONE('wind', x + 128, 300, 400, 180, -900, 0); row(x + 200, 440, 6, 50); E('a', x + 330, 330); E('g', x + 520, GY, 80); hint(x + 60, 'gust'); return 640; },
    bouncefield(x) { G(x, 128); P(x + 176, 440, 48); SPRING(x + 200, 440); P(x + 352, 440, 48); SPRING(x + 376, 440); P(x + 230, 220, 112); G(x + 528, 128); row(x + 250, 190, 3, 35); RS(x + 290, 160); return 656; },
    graves(x) { G(x, 640); E('g', x + 240, GY, 160); E('g', x + 470, GY, 160); SPK(x + 360, 48); arc(x + 300, 430, 4, 40, 30); return 640; },
    ghosts(x) { G(x, 576); E('a', x + 260, 400); E('a', x + 440, 380); PH_(x + 220, 340, 96, 16, 1); row(x + 236, 310, 3, 32); hint(x + 60, 'ghosts'); return 576; },
    icicles(x) { G(x, 640); P(x + 160, 290, 128); P(x + 400, 290, 128); for (const ix of [x + 180, x + 224, x + 268, x + 420, x + 464, x + 508]) ICI(ix, 306); row(x + 180, 260, 4, 30); E('g', x + 560, GY, 100); hint(x + 60, 'icicles'); return 640; },
    lowgrav(x) { G(x, 128); ZONE('lowgrav', x + 128, 60, 512, 420); P(x + 200, 330, 64); P(x + 360, 230, 64); P(x + 520, 330, 64); G(x + 640, 128); row(x + 360, 200, 3, 22); RS(x + 392, 120); E('a', x + 450, 260); hint(x + 40, 'lowgrav'); return 768; },
    water(x) {
      G(x, 128); solid(x + 128, GY + 170, 576, 120, { ground: true });
      ZONE('water', x + 128, GY - 10, 576, 180); G(x + 704, 160);
      for (let i = 0; i < 5; i++) gem(x + 200 + i * 100, GY + 100 + Math.sin(i) * 40);
      fixE(E('a', x + 330, GY + 70), 'jelly');
      if (r() < .6) { const e = E('a', x + 520, GY + 60); fixE(e, 'jelly'); }
      RS(x + 420, GY + 150); hint(x + 40, 'water'); return 864;
    },
    current(x) {
      G(x, 128); solid(x + 128, GY + 170, 640, 120, { ground: true });
      ZONE('water', x + 128, GY - 10, 640, 180, -700, 0); G(x + 768, 160);
      row(x + 220, GY + 100, 6, 80); const e = E('a', x + 450, GY + 70); fixE(e, 'jelly'); E('g', x + 860, GY, 80);
      hint(x + 40, 'current'); return 928;
    },
    echo(x) {
      G(x, 1024); const pl = { x: x + 150, y: GY - 6, w: 52, h: 6, on: false };
      L.plates.push(pl); const door = { k: 'door', x: x + 640, y: GY - 320, w: 28, h: 320, open: 0, plate: pl };
      L.plats.push(door); L.doors.push(door);
      row(x + 300, 440, 4, 60); row(x + 720, 440, 3, 40); E('g', x + 860, GY, 120); hint(x + 30, 'echo'); return 1024;
    },
    quicksand(x) { G(x, 160); const s = G(x + 160, 512); s.sand = true; ZONE('sand', x + 160, GY - 30, 512, 34); P(x + 300, 380, 96); G(x + 672, 160); row(x + 220, 420, 6, 70); E('a', x + 420, 300); hint(x + 40, 'quicksand'); return 832; },
    sandfall(x) { G(x, 128); ZONE('wind', x + 150, 150, 140, 330, 0, -2400); P(x + 300, 220, 160); G(x + 512, 192); for (let i = 0; i < 4; i++) gem(x + 220, 380 - i * 55); RS(x + 400, 190); hint(x + 40, 'sandfall'); E('g', x + 600, GY, 60); return 712; },
    anchors(x) {
      G(x, 160); L.anchors.push({ x: x + 300, y: 300 }, { x: x + 560, y: 280 }); G(x + 780, 192);
      arc(x + 300, 400, 6, 50, 50); RS(x + 600, 150); E('a', x + 470, 200); hint(x + 40, 'anchors'); return 972;
    },
    anchors2(x) {
      G(x, 160); L.anchors.push({ x: x + 290, y: 300 }, { x: x + 540, y: 270 }, { x: x + 790, y: 300 }); P(x + 520, 400, 48); G(x + 1020, 192);
      arc(x + 290, 390, 10, 56, 50); E('a', x + 680, 190); return 1212;
    },
    clouds(x) { G(x, 128); for (let i = 0; i < 5; i++) { const b = BR(x + 170 + i * 104, 430 - (i % 2) * 40 - (i === 2 ? 60 : 0), 64); } G(x + 704, 128); row(x + 190, 380, 5, 104); E('a', x + 420, 260); hint(x + 40, 'clouds'); return 832; },
    trial(x) {
      // Cámara del Desafío: las puertas se cierran y llegan oleadas de enemigos
      G(x, 1152);
      const pa = { on: true }, pb = { on: true };
      const da = { k: 'door', x: x + 72, y: GY - 380, w: 28, h: 380, open: 1, tg: 1, plate: pa, trial: true };
      const db = { k: 'door', x: x + 1052, y: GY - 380, w: 28, h: 380, open: 1, tg: 1, plate: pb, trial: true };
      L.plats.push(da, db); L.doors.push(da, db);
      P(x + 280, 400, 128); P(x + 744, 400, 128); P(x + 512, 296, 128);
      const t = { x1: x + 100, x2: x + 1052, st: 0, wave: 0, t: 0, plates: [pa, pb], waves: [], live: [], cx: x + 576 };
      const nW = 2 + (act ? 1 : 0) + (D.extra ? 1 : 0);
      for (let w = 0; w < nW; w++) {
        const list = [], n = 2 + w;
        for (let i = 0; i < n; i++) {
          const air = WD.a && WD.a.length && i % 2 === 1;
          const ex = x + 220 + ((i * 271 + w * 157) % 720);
          const e = E(air ? 'a' : 'g', ex, air ? 260 + (i * 37) % 90 : GY, 220); L.enemies.pop(); list.push(e);
        }
        t.waves.push(list);
      }
      (L.trials = L.trials || []).push(t);
      row(x + 300, 370, 3, 40); row(x + 764, 370, 3, 40);
      return 1152;
    },
    ambush(x) {
      // zona de emboscada (v2.7): suelo amplio y una barrera al final; la lógica está en gates.js
      G(x, 768); P(x + 300, 372, 112); arc(x + 160, 440, 4, 40, 25);
      (L.sealSpots = L.sealSpots || []).push({ x, w: 768 }); return 768;
    },
    gears(x) { G(x, 128); M(x + 150, 450, 64, x + 150, 300, 1.3); M(x + 260, 300, 96, x + 400, 300, 1.0); M(x + 520, 300, 64, x + 520, 450, 1.3); G(x + 640, 128); row(x + 280, 260, 4, 40); E('a', x + 380, 220); return 768; }
  };

  let x = 0;
  if (wi === 0 && act === 0) {
    // ===== MUNDO 1-1: TUTORIAL DISEÑADO A MANO =====
    G(0, 576); row(200, 440, 4, 40); hint(40, 'move');
    G(704, 512); E('g', 960, GY, 220); arc(760, 400, 3, 40, 20); hint(620, 'sword');           // hueco corto + primer enemigo
    G(1216, 288, 400); row(1240, 370, 3, 40);                                                     // escalón bajo
    G(1504, 256, 300); row(1530, 270, 4, 40); hint(1150, 'doublejump');                          // escalón alto: doble salto
    G(1760, 640); L.checks.push({ x: 1800, y: GY - 40, w: 24, h: 40, on: false });
    SPRING(1960); P(2020, 236, 176); row(2045, 205, 4, 38); CH(2180, 205); hint(1880, 'spring'); // resorte a la plataforma alta
    P(2100, 120, 64); RS(2132, 90); E('a', 2260, 330);                                            // reloj secreto encima
    G(2400, 160); M(2600, 430, 96, 2780, 430, 1.1); arc(2610, 380, 5, 50, 30); hint(2420, 'mover'); // plataforma móvil
    G(2960, 384); E('g', 3150, GY, 200);
    L.checks.push({ x: 3000, y: GY - 40, w: 24, h: 40, on: false });
    G(3632, 512); arc(3380, 380, 5, 50, 70); hint(3200, 'dash');                                 // hueco largo: dash
    SPK(3880, 96); arc(3870, 420, 3, 40, 10); hint(3700, 'spikes'); E('g', 4050, GY, 80);        // pinchos: rebote con la espada
    const wc = 4144; G(wc, 288); pillar(wc + 192, 200, 396, 24); G(wc + 288, 192, 200); G(wc + 480, 224); row(wc + 310, 170, 4, 40); hint(wc + 40, 'wallclimb');
    L.checks.push({ x: wc + 500, y: GY - 40, w: 24, h: 40, on: false });
    const st = wc + 704; P(st + 80, 420, 96); P(st + 230, 360, 96); P(st + 380, 300, 128); P(st + 560, 360, 96); P(st + 700, 420, 96); row(st + 400, 270, 3, 40); E('a', st + 420, 220);
    G(st + 840, 640); E('g', st + 1100, GY, 200); CH(st + 900, 440);
    x = st + 1480; G(x, 448); L.goal = { x: x + 260, y: GY - 64, w: 40, h: 64 }; row(x + 80, 440, 3, 40); x += 448;
    L.arena = null; L.width = x; L.seq = ['tutorial'];
  } else if (wi === 2 && act === 2) {
    // Mundo 3, fase 2: ascenso artesanal con lava subiendo
    G(0, 528, null); L.plats[L.plats.length - 1].h = 272; row(150, 445, 3, 50);
    BR(600, 420, 96); gem(648, 392); BR(760, 360, 96); gem(808, 332);
    P(896, 300, 224); L.checks.push({ x: 920, y: 260, w: 24, h: 40, on: false }); E('g', 1050, 300, 130); row(950, 270, 3, 50);
    BR(1184, 240, 96); gem(1232, 212); BR(1344, 180, 96); gem(1392, 152);
    P(1472, 120, 272); L.checks.push({ x: 1500, y: 80, w: 24, h: 40, on: false }); row(1540, 90, 4, 50); E('a', 1620, 20); CH(1720, 90);
    BR(1792, 60, 96); gem(1840, 32);
    M(1952, 40, 128, 1952, -130, 1.0); gem(2015, -100);
    P(2144, -130, 240); L.checks.push({ x: 2160, y: -170, w: 24, h: 40, on: false }); E('g', 2300, -130, 140); row(2170, -160, 3, 50);
    BR(2432, -190, 96); gem(2480, -218); BR(2592, -250, 96); gem(2640, -278); BR(2752, -310, 96); gem(2800, -338);
    P(2896, -370, 208); row(2930, -400, 3, 50); E('a', 3000, -480); CH(3070, -400); RS(3020, -560); P(2980, -530, 64);
    BR(3152, -420, 96); gem(3200, -448);
    solid(3296, -480, 1760, 64, { ground: true });
    L.arena = { x1: 3800, x2: 4760, floor: -480 };
    L.top = -1020; L.deathY = 1200; L.lava = { y: 700, rise: D.lava, stop: -440 };
    x = 4800;
  } else {
    G(0, 352); x = 352; L.decorStart = 0;
    const n = TOWER_ON ? TOWER_N : Math.min(WD.pool.length * 2, act === 0 ? 12 : act === 1 ? 14 : 7);
    const seq = [];
    const sig = WD.sig.slice();
    if (wi === 0) sig.push('wallclimb');
    if (act === 1) { sig.push(pick(WD.pool)); sig.push(pick(WD.pool)); }
    if (act === 2) sig.length = Math.min(sig.length, 2);
    for (const s of sig) if (CH_[s]) seq.push(s);
    while (seq.length < n) { const c = pick(WD.pool); if (seq[seq.length - 1] !== c) seq.push(c); }
    // Curva de dificultad: de más fácil a más difícil, sin repetir el mismo bloque seguido ni más de dos veces
    const RATE = { flat: 0, gap: 1, spring: 1, stairs: 2, mover: 2, elevator: 2, spikes: 2, bouncefield: 2, shiftwall: 2, boost: 2, conveyor: 2, updraft: 2, gust: 2, graves: 2, lowgrav: 2, wallclimb: 3, shiftgap: 3, lasers: 3, lavapit: 3, firejets: 3, crumble: 3, ghosts: 3, icicles: 3, gears: 3,
      water: 1, current: 2, echo: 2, quicksand: 1, sandfall: 2, anchors: 2, anchors2: 3, clouds: 2 };
    const cnt = {}; const uniq = []; for (const s of seq) { cnt[s] = (cnt[s] || 0) + 1; if (cnt[s] <= 2) uniq.push(s); }
    while (uniq.length < n) { const c = pick(WD.pool); if ((cnt[c] || 0) < 2) { cnt[c] = (cnt[c] || 0) + 1; uniq.push(c); } }
    const keyed = uniq.map(s => [s, (RATE[s] || 1) + r() * 1.6 + act * 0.3]).sort((a, b) => a[1] - b[1]).map(a => a[0]);
    for (let i = 1; i < keyed.length; i++) if (keyed[i] === keyed[i - 1]) { const j = keyed.findIndex((s, k) => k > i && s !== keyed[i]); if (j > 0) [keyed[i], keyed[j]] = [keyed[j], keyed[i]]; }
    seq.length = 0; seq.push(...keyed);
    seq.unshift('flat');
    if (act < 2 && seq.length > 5 && (!TOWER_ON || TOWER_TRIAL)) seq.splice(Math.floor(seq.length * 0.62), 0, 'trial');
    // barreras de emboscada: más cuanto más avanzado el mundo (gates.js)
    if (!TOWER_ON && typeof sealPlan === 'function' && !(wi === 2 && act === 2)) {
      const nS = sealPlan(wi, act).n, F = act === 2 ? [0.5] : nS === 1 ? [0.35] : nS === 2 ? [0.3, 0.88] : [0.22, 0.45, 0.88];
      for (let k = F.length - 1; k >= 0; k--) {
        let i = Math.max(2, Math.round(seq.length * F[k]));
        while (i < seq.length && (seq[i] === 'trial' || seq[i - 1] === 'trial')) i++;
        seq.splice(Math.min(i, seq.length), 0, 'ambush');
      }
    }
    for (let i = 0; i < seq.length; i++) {
      if (i > 0 && (i % 2 === 0 || seq[i] === 'trial') && !L.checks.some(c => c.x === x + 40)) L.checks.push({ x: x + 40, y: GY - 40, w: 24, h: 40, on: false });
      x += CH_[seq[i]](x);
      if (i === Math.floor(seq.length / 3) || i === Math.floor(seq.length * 2 / 3)) CH(x - 60, 440);
    }
    L.seq = seq;
    if (act < 2) {
      G(x, 448); L.goal = { x: x + 260, y: GY - 64, w: 40, h: 64 }; row(x + 80, 440, 3, 40); x += 448;
      L.arena = null; L.width = x;
    } else {
      L.checks.push({ x: x + 40, y: GY - 40, w: 24, h: 40, on: false }); CH(x + 120, 440);
      const ax = x + 160; G(x, 160 + 960 + 260); L.arena = { x1: ax, x2: ax + 960, floor: GY }; x = ax + 960;
      const A = L.arena;
      if (WD.boss.type === 3) { P(A.x1 + 140, 330, 128); P(A.x2 - 268, 330, 128); }
      if (WD.boss.type === 6) { P(A.x1 + 120, 320, 144); P(A.x2 - 264, 320, 144); }
      if (WD.boss.type === 7) { PH_(A.x1 + 140, 340, 128, 16, 0); PH_(A.x2 - 268, 340, 128, 16, 1); PH_(A.x1 + 416, 250, 128, 16, 1); }
      if (WD.boss.type === 10) { P(A.x1 + 120, 330, 128); P(A.x2 - 248, 330, 128); L.anchors.push({ x: (A.x1 + A.x2) / 2, y: 190 }); }
      if (WD.boss.type === 11) { P(A.x1 + 130, 320, 112); P(A.x2 - 242, 320, 112); }
    }
  }
  if (L.arena) L.width = L.arena.x2 + 200;
  if (!L.width) L.width = x;
  if (WD.boss.type === 9 && L.arena) { const A = L.arena; L.plates.push({ x: A.x1 + 110, y: A.floor - 6, w: 52, h: 6, on: false, boss: true }, { x: A.x2 - 170, y: A.floor - 6, w: 52, h: 6, on: false, boss: true }); }
  if (WD.boss.type === 2 && act === 2 && wi !== 2 && L.arena) { const A = L.arena, cx = (A.x1 + A.x2) / 2; P(A.x1 + 150, A.floor - 140, 144); P(cx - 72, A.floor - 250, 144); P(A.x2 - 294, A.floor - 140, 144);
    L.levers.push({ x: A.x1 + 70, y: A.floor - 30, w: 40, h: 30, on: false }, { x: cx - 20, y: A.floor - 280, w: 40, h: 30, on: false }, { x: A.x2 - 242, y: A.floor - 170, w: 40, h: 30, on: false }); }
  else if (WD.boss.type === 2 && act === 2) { const A = L.arena; P(3952, -640, 160); P(4208, -780, 144); P(4448, -640, 160); L.levers.push({ x: 3830, y: -510, w: 40, h: 30, on: false }, { x: 4260, y: -810, w: 40, h: 30, on: false }, { x: 4510, y: -670, w: 40, h: 30, on: false }); }
  // Reliquia secreta (reloj de arena)
  if (relicSpots.length) { const s = relicSpots[Math.floor(r() * relicSpots.length)]; L.relic = { x: s.x, y: s.y, taken: false }; }
  else L.relic = { x: (L.goal ? L.goal.x - 120 : 600), y: 300, taken: false };
  placeButterfly(L, r); placeCrystals(L, r); placeLive(L);
  // Decoración: arte pintado del mundo si existe; si no, el decorado clásico
  const PR = worldProps(wi);
  if (PR) {
    for (const s of L.plats) {
      if (s.k !== 'solid' || s.pillar || s.conv || s.ceil || s.y > GY + 20) continue;
      const step = s.float ? 999 : 150;
      for (let dx = s.x + 30 + r() * 60; dx < s.x + s.w - 30; dx += step + r() * 170) {
        if (L.arena && dx > L.arena.x1 - 40 && dx < L.arena.x2) continue;
        if (L.hazards.some(h => (h.k === 'spike' || h.k === 'jet') && Math.abs(h.x + h.w / 2 - dx) < h.w / 2 + 30)) continue;
        if (L.plates.some(q => Math.abs(q.x - dx) < 80) || L.doors.some(q => Math.abs(q.x - dx) < 90)) continue;
        const k = PR[Math.floor(r() * PR.length)], m = META[k];
        if (s.float && m.fh > 60) continue;
        if (m.fw > s.w - 20) continue;
        L.decor.push({ k, x: Math.round(dx), y: s.y + 3, flip: r() < 0.5, ph: r() * 10, sway: 0, big: m.fh > 90 });
      }
    }
  }
  const bag = []; if (!PR) for (const d of WD.deco) for (let i = 0; i < d[1]; i++) bag.push(d);
  if (bag.length) for (const s of L.plats) {
    if (s.k !== 'solid' || s.w < 96 || s.pillar || s.conv) continue;
    for (let dx = s.x + 24 + r() * 40; dx < s.x + s.w - 30; dx += 70 + r() * 110) {
      if (L.arena && dx > L.arena.x1 - 40 && dx < L.arena.x2) continue;
      if (L.hazards.some(h => h.k === 'spike' && Math.abs(h.x + h.w / 2 - dx) < h.w / 2 + 20)) continue;
      const d = bag[Math.floor(r() * bag.length)];
      if ((d[0] === 'p_tree' || d[0].includes('tree') || d[0].includes('statue')) && (s.float || dx > s.x + s.w - 90)) continue;
      L.decor.push({ k: d[0], anim: d[2], x: Math.round(dx), y: s.y, flip: r() < 0.5, ph: r() * 10, sway: 0 });
    }
  }
  // Fauna ambiental (se espanta al acercarte)
  if (WD.critter) for (const s of L.plats) if (s.k === 'solid' && !s.float && s.w > 200 && r() < 0.55) {
    const n = 2 + Math.floor(r() * 3), cx = s.x + 60 + r() * (s.w - 120);
    for (let i = 0; i < n; i++) L.critters.push({ x: cx + i * 9 - n * 4, y: s.y, vx: 0, vy: 0, fly: false, t: r() * 5, kind: WD.critter, gone: false, face: r() < .5 ? -1 : 1 });
  }
  // Más enemigos en difícil
  if (D.extra) for (const e of L.enemies.slice()) if (r() < 0.3 && e.b !== 'riser') { const c = Object.assign({}, e, { x: e.x + 60, x0: e.x0 + 60, minX: e.minX + 30, maxX: e.maxX + 30 }); L.enemies.push(c); }
  const painted = paintedOK(wi);
  for (const s of L.plats) if (s.k === 'solid') { if (painted) s.cache2 = renderPlat2(s, wi); else s.cache = renderPlat(s, WD.tiles); }
  return L;
}
function renderPlat(s, tk) {
  const T = SPR[tk], ord = META[tk].order, idx = k => ord.indexOf(k) * 16;
  const h = s.float ? 16 : Math.min(s.h, 320), [c, x] = mkCanvas(s.w, h);
  const cols = Math.ceil(s.w / 16), rows = Math.ceil(h / 16);
  for (let j = 0; j < rows; j++) for (let i = 0; i < cols; i++) {
    const px = i === cols - 1 ? s.w - 16 : i * 16;
    let k;
    if (s.float) k = cols === 1 ? 'pm' : i === 0 ? 'pl' : i === cols - 1 ? 'pr' : 'pm';
    else { const side = i === 0 ? 'l' : i === cols - 1 ? 'r' : ''; k = j === 0 ? (side === 'l' ? 'tl' : side === 'r' ? 'tr' : 't') : (side || 'c'); }
    x.drawImage(T, idx(k), 0, 16, 16, px, j * 16, 16, 16);
  }
  if (!s.float && h > 16) {
    const g = x.createLinearGradient(0, 16, 0, h); g.addColorStop(0, 'rgba(0,0,0,0)'); g.addColorStop(1, 'rgba(0,0,0,.6)');
    x.fillStyle = g; x.fillRect(0, 16, s.w, h - 16);
  }
  if (s.conv) { x.fillStyle = '#1c1830'; x.fillRect(0, 0, s.w, 5); }
  return c;
}
