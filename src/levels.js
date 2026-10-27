// =====================================================================
//  NIVELES CON IDENTIDAD (v3.2)
//  Antes los 18 mundos mezclaban casi los mismos bloques (huecos de
//  64 px, escaleras, un enemigo): cambiaba el dibujo, no el juego.
//  Ahora:
//  · Tramos nuevos que exigen saltar bien: plataformas sobre el vacío,
//    hueco que solo se cruza con dash, plataformas móviles, cadenas que
//    se derrumban, subidas verticales, pasillos con enemigos y púas,
//    viento sobre el vacío, anclas, láseres, cintas en contra, hielo,
//    plataformas de dimensión sobre el vacío.
//  · Cada mundo tiene su mecánica protagonista y su propia mezcla.
//  · Los tramos se endurecen con el avance (huecos más largos, más
//    enemigos, plataformas más pequeñas).
//  · Momento especial en 5 mundos: ¡PERSECUCIÓN! (sombra, fuego,
//    vacío, derrumbe, tormenta) que te obliga a correr sin parar.
//  Física de referencia: salto ~200 px, doble salto ~375 px, +dash ~130 px.
// =====================================================================
const EXTRA_RATE = { pits: 2.5, dashgap: 3, movepits: 3, crumblechain: 3, climb: 2.5, gauntlet: 2, windpit: 3, anchorpit: 3.5, laserrun: 3.5, conveyorpit: 3, icerun: 2.5, shiftpit: 3, chase: 4.5 };
function EXTRA_CH(h) {
  const { L, r, WD, wi, act, G, P, pillar, M, BR, PH_, CONV, SPK, LZ, ICI, LAVA, ZONE, gem, row, arc, E, hint } = h;
  const g = clamp(WPOS(wi) / (ORDER.length - 1), 0, 1) * 0.85 + act * 0.07;
  const R = (a, b) => a + r() * (b - a);
  return {
    // plataformas pequeñas sobre el vacío
    pits(x) {
      G(x, 128); let cx = x + 128; const n = 3 + (g > .45 ? 1 : 0);
      for (let i = 0; i < n; i++) {
        const gap = Math.round(R(120, 150) + 80 * g), w = Math.round(96 - 28 * g), y = 440 - (i % 2) * Math.round(40 + 40 * g);
        P(cx + gap, y, w); gem(cx + gap / 2, y - 50);
        if (i % 2 === 1 && g > .15) E('a', cx + gap + w / 2, y - 120);
        cx += gap + w;
      }
      const end = Math.round(130 + 60 * g); G(cx + end, 160); return cx + end + 160 - x;
    },
    // hueco largo: doble salto + dash
    dashgap(x) {
      G(x, 192); const gap = Math.round(290 + 100 * g);
      arc(x + 200, 380, 6, gap / 6, 70); if (g > .5) E('a', x + 192 + gap / 2, 300);
      G(x + 192 + gap, 192); hint(x + 40, 'dash'); return 384 + gap;
    },
    // plataformas que se mueven sobre el vacío
    movepits(x) {
      G(x, 128); const sp = 0.9 + 0.5 * g;
      M(x + 170, 430, 80, x + 370, 430, sp); M(x + 480, 400, 80, x + 480, 270, sp);
      arc(x + 190, 390, 4, 50, 30); gem(x + 520, 240);
      if (g > .3) E('a', x + 420, 300);
      G(x + 650, 128); return 778;
    },
    // cadena de plataformas que se derrumban
    crumblechain(x) {
      G(x, 128); const n = 5, sp = Math.round(145 + 35 * g);
      for (let i = 0; i < n; i++) { const px = x + 128 + 40 + i * sp; BR(px, 440 - (i % 2) * 40, 64); gem(px + 32, 400 - (i % 2) * 40); }
      if (WD.lavaPits) LAVA(x + 128, n * sp + 40);
      if (g > .4) E('a', x + 128 + sp * 2.5, 320);
      G(x + 128 + 40 + n * sp, 128); return 128 + 40 + n * sp + 128;
    },
    // subida vertical por encima de un muro
    climb(x) {
      G(x, 448);
      P(x + 60, 400, 112); P(x + 220, 320, 112); P(x + 60, 240, 112); P(x + 220, 160, 112); P(x + 380, 112, 176);
      pillar(x + 430, 150, 480, 24);
      E('g', x + 270, 320, 90); if (g > .3) E('a', x + 150, 190); if (g > .6) E('g', x + 110, 240, 90);
      row(x + 400, 80, 4, 36); gem(x + 115, 210);
      G(x + 448, 192); return 640;
    },
    // pasillo con enemigos y púas
    gauntlet(x) {
      G(x, 896); SPK(x + 200, 32 + Math.round(16 * g)); SPK(x + 540, 48);
      E('g', x + 340, 480, 160); E('g', x + 720, 480, 160); E('a', x + 460, 330);
      if (g > .5) E('g', x + 620, 480, 100); if (g > .75) E('a', x + 780, 300);
      arc(x + 180, 400, 4, 30, 40); arc(x + 520, 390, 4, 30, 50); return 896;
    },
    // viento que empuja hacia atrás sobre el vacío
    windpit(x) {
      G(x, 160); const gap = Math.round(250 + 60 * g);
      P(x + 160 + gap / 2 - 40, 420, 80);
      ZONE('wind', x + 160, 180, gap, 300, -(1000 + 500 * g), 0);
      arc(x + 180, 390, 5, gap / 5, 40); G(x + 160 + gap, 160); hint(x + 40, 'gust'); return 320 + gap;
    },
    // anclas sobre un gran vacío
    anchorpit(x) {
      G(x, 160); L.anchors.push({ x: x + 300, y: 290 }, { x: x + 530, y: 260 }, { x: x + 760, y: 290 });
      if (g > .5) E('a', x + 640, 360);
      arc(x + 300, 380, 7, 75, 40); G(x + 920, 192); return 1112;
    },
    // plataformas bajo láseres
    laserrun(x) {
      G(x, 128);
      P(x + 175, 420, 96); P(x + 335, 380, 96); P(x + 495, 420, 96);
      LZ(x + 175, 330, 96, 0); LZ(x + 335, 290, 96, 1.1); LZ(x + 495, 330, 96, 2.2);
      row(x + 200, 390, 3, 160); if (g > .4) E('a', x + 420, 250);
      G(x + 655, 128); return 783;
    },
    // cintas en contra entre vacíos
    conveyorpit(x) {
      G(x, 128); const gap = Math.round(150 + 40 * g);
      CONV(x + 128, 256, -1); CONV(x + 384 + gap, 256, -1);
      E('g', x + 260, 480, 80); if (g > .4) E('a', x + 384 + gap / 2, 330);
      row(x + 180, 440, 4, 50); G(x + 640 + gap * 2, 128); return 768 + gap * 2;
    },
    // hielo resbaladizo con huecos y estalactitas
    icerun(x) {
      G(x, 384); const gap = Math.round(160 + 60 * g);
      G(x + 384 + gap, 256); for (const ix of [x + 420 + gap, x + 500 + gap]) ICI(ix, 300);
      E('g', x + 200, 480, 140); if (g > .3) E('g', x + 470 + gap, 480, 80);
      G(x + 640 + gap * 2, 256); arc(x + 384, 380, 4, gap / 4, 50); return 896 + gap * 2;
    },
    // plataformas de dimensión sobre el vacío: hay que cambiar en el aire
    shiftpit(x) {
      G(x, 128); const gap = Math.round(100 + 40 * g);
      PH_(x + 128 + gap, 420, 96, 16, 0); PH_(x + 224 + gap * 2, 380, 96, 16, 1); PH_(x + 320 + gap * 3, 420, 96, 16, 0);
      arc(x + 150, 370, 6, gap / 1.5, 30); if (g > .4) E('a', x + 300 + gap * 2, 300);
      G(x + 416 + gap * 4, 128); hint(x + 40, 'shiftgap'); return 544 + gap * 4;
    },
    // ¡PERSECUCIÓN!: corre sin parar
    chase(x) {
      let cx = x; const parts = [[384], [256], [320], [256], [384], [288]];
      G(cx, 384); cx += 384;
      for (let i = 1; i < parts.length; i++) {
        const gap = Math.round(R(96, 140) + 40 * g); cx += gap; G(cx, parts[i][0]);
        if (i % 2 === 0) SPK(cx + 110, 32); else pillar(cx + 140, 430, 480, 24);
        row(cx + 40, 420, 3, 40); cx += parts[i][0];
      }
      (L.chases = L.chases || []).push({ x0: x + 60, x1: cx - 40, st: 0, wx: 0 });
      return cx - x;
    }
  };
}
// mecánica protagonista y mezcla de cada mundo
const WORLD_PLAN = {
  0: [['spring', 'bouncefield', 'pits', 'movepits', 'mover', 'elevator', 'climb'], ['spring', 'pits', 'spikes']],
  1: [['shiftgap', 'shiftwall', 'shiftpit', 'lasers', 'gauntlet', 'crumble', 'dashgap'], ['shiftpit', 'shiftwall', 'chase']],
  2: [['lavapit', 'firejets', 'crumblechain', 'crumble', 'climb', 'dashgap', 'gauntlet'], ['crumblechain', 'lavapit', 'firejets']],
  3: [['updraft', 'gust', 'windpit', 'bouncefield', 'pits', 'climb', 'spring'], ['windpit', 'updraft', 'gust']],
  4: [['graves', 'ghosts', 'gauntlet', 'shiftwall', 'pits', 'climb', 'crumble'], ['gauntlet', 'ghosts', 'graves']],
  5: [['icicles', 'icerun', 'pits', 'crumblechain', 'dashgap', 'climb', 'movepits'], ['icerun', 'icicles', 'crumblechain']],
  6: [['firejets', 'lavapit', 'crumblechain', 'gauntlet', 'shiftwall', 'dashgap', 'climb'], ['firejets', 'crumblechain', 'chase']],
  7: [['lowgrav', 'gears', 'laserrun', 'lasers', 'movepits', 'conveyorpit', 'shiftgap'], ['gears', 'laserrun', 'lowgrav']],
  8: [['water', 'current', 'movepits', 'pits', 'crumble', 'dashgap', 'gauntlet'], ['water', 'current', 'movepits']],
  9: [['quicksand', 'sandfall', 'echo', 'dashgap', 'gauntlet', 'pits', 'crumblechain'], ['quicksand', 'echo', 'dashgap']],
  10: [['anchors', 'anchors2', 'clouds', 'anchorpit', 'windpit', 'updraft', 'pits'], ['anchorpit', 'clouds', 'anchors2']],
  11: [['dashgap', 'movepits', 'crumblechain', 'laserrun', 'windpit', 'anchorpit', 'shiftpit', 'gauntlet', 'water'], ['anchorpit', 'shiftpit', 'chase']],
  12: [['water', 'gauntlet', 'pits', 'movepits', 'graves', 'ghosts', 'crumble'], ['water', 'gauntlet', 'pits']],
  13: [['gauntlet', 'shiftwall', 'climb', 'dashgap', 'lasers', 'crumblechain', 'firejets'], ['gauntlet', 'climb', 'chase']],
  14: [['conveyorpit', 'conveyor', 'elevator', 'icicles', 'climb', 'crumblechain', 'movepits'], ['conveyorpit', 'elevator', 'climb']],
  15: [['graves', 'ghosts', 'gauntlet', 'pits', 'climb', 'bouncefield', 'shiftwall'], ['graves', 'ghosts', 'climb']],
  16: [['shiftwall', 'shiftpit', 'shiftgap', 'climb', 'gauntlet', 'echo', 'pits'], ['shiftpit', 'climb', 'shiftwall']],
  17: [['gust', 'windpit', 'anchors', 'anchorpit', 'updraft', 'climb', 'dashgap'], ['windpit', 'anchorpit', 'chase']]
};
for (const w in WORLD_PLAN) { WORLDS[w].pool = WORLD_PLAN[w][0]; WORLDS[w].sig = WORLD_PLAN[w][1]; }
// ---------------- persecución ----------------
const CHASE_LOOK = { 1: ['rgba(40,10,60,', '#b070ff', 'LA SOMBRA TE PERSIGUE'], 6: ['rgba(120,20,0,', '#ff7a30', 'EL FUEGO TE PERSIGUE'], 11: ['rgba(20,0,40,', '#ff6ad5', 'EL VACÍO TE PERSIGUE'],
  13: ['rgba(30,30,50,', '#8fb4ff', 'EL CASTILLO SE DERRUMBA'], 17: ['rgba(20,30,70,', '#bfe6ff', 'LA TORMENTA TE PERSIGUE'] };
function chaseLook() { return CHASE_LOOK[curWorld] || CHASE_LOOK[1]; }
const _updateC = update;
update = function (dt) {
  _updateC(dt);
  if (state !== 'playing' || !level || !level.chases) return;
  for (const c of level.chases) {
    if (c.st === 0 && !p.dead && p.x > c.x0 && p.x < c.x1 - 200) {
      c.st = 1; c.wx = c.x0 - 260; c.sp = 200;
      banner(tr('¡CORRE!'), tr(chaseLook()[2]), chaseLook()[1], 1.8); sfx('roar', .7, .7); shake = Math.max(shake, 8);
    }
    if (c.st !== 1) continue;
    if (p.dead) { c.st = 0; continue; }                         // al caer, la persecución vuelve a empezar
    c.sp = Math.min(255, c.sp + dt * 22); c.wx += c.sp * dt;
    if (Math.random() < .5) parts.push({ x: c.wx + rnd(-10, 10), y: rnd(cam.y, cam.y + VH), vx: rnd(20, 80), vy: rnd(-40, 40), life: .6, max: .6, c: chaseLook()[1], s: 2, g: 0 });
    if (Math.abs(c.wx - p.x) < 300) shake = Math.max(shake, 2);
    if (p.x < c.wx && p.inv <= 0) {
      if (diffIdx >= 1) { p.hp = 0; kill(); } else { hurt(25, c.wx - 100); p.x = c.wx + 30; }
    }
    if (c.wx >= c.x1) { c.st = 2; burst(c.x1, p.y, chaseLook()[1], 30, 260, 0, .8, 2); sfx('relic', .5); addFloat(p.x + p.w / 2, p.y - 30, tr('¡A SALVO!'), '#3df5a0', 20); }
  }
};
const _drawWorldC = drawWorld;
drawWorld = function () {
  _drawWorldC.apply(this, arguments);
  if (!level || !level.chases) return;
  for (const c of level.chases) {
    if (c.st !== 1) continue;
    const L = chaseLook(), x = c.wx - cam.x;
    if (x < -40) continue;
    bx.save();
    const gr = bx.createLinearGradient(c.wx - 260, 0, c.wx + 12, 0);
    gr.addColorStop(0, L[0] + '0.97)'); gr.addColorStop(0.75, L[0] + '0.85)'); gr.addColorStop(1, L[0] + '0)');
    bx.fillStyle = gr; bx.fillRect(c.wx - 260, cam.y - 20, 272, VH + 40);
    bx.fillStyle = L[1]; bx.globalAlpha = .7;
    for (let y = Math.floor(cam.y / 14) * 14; y < cam.y + VH; y += 14) bx.fillRect(Math.round(c.wx + Math.sin(time * 9 + y * .3) * 6), y, 3, 9);
    bx.restore();
  }
};

