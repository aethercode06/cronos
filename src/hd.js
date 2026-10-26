// =====================================================================
//  KAEL Y TIC EN ALTA DEFINICIÓN (capa nítida sobre el mundo pixelado),
//  movimiento suave con subpíxel y pequeños detalles que dan vida
// =====================================================================
const HDOK = () => !!(SPR.KH_run && SPR.KH_run.width && META.KH_run);
let lastShake = { x: 0, y: 0 };
function hdAnim() {
  if (p.dead) return ['KH_death', Math.min(1, Math.floor(p.anim * 4))];
  if (p.stun > 0) return ['KH_hurt', 0];
  if (p.dashT > 0) return ['KH_dash', 0];
  if (p.atkT > 0) {
    const tot = p.atkN === 2 ? 0.38 : 0.3, t = tot - p.atkT;
    if (p.air && SPR.KH_airdown) return [act.down || p.vy > 120 ? 'KH_airdown' : 'KH_airslash', 0];
    const ak = p.atkN === 2 && SPR.KH_atk3 ? 'KH_atk3' : p.atkN ? 'KH_atk2' : 'KH_atk1', an = META[ak].n, u = clamp(t / tot, 0, 0.999) * an;
    return [ak, Math.floor(u), u % 1];
  }
  if (p.hook) return [SPR.KH_jump ? 'KH_jump' : 'KH_jumpU', SPR.KH_jump ? 3 : 0];
  if (p.wall) return ['KH_wall', 0];
  if (!p.onGround) {
    if (SPR.KH_jump) { const u = 1 + clamp((p.vy + 520) / 1040, 0, 0.999) * 4; return ['KH_jump', Math.floor(u), u % 1]; }
    return [p.vy < 0 ? 'KH_jumpU' : 'KH_fallU', 0];
  }
  if (p.landT > 0 && SPR.KH_jump) return ['KH_jump', p.landT > 0.07 ? 6 : 7];
  if (Math.abs(p.vx) > 30) { const ph = p.runPh || 0; return ['KH_run', Math.floor(ph), ph % 1]; }
  const ni = SPR.KH_idle ? META.KH_idle.n : 4, ip = (time * (ni > 8 ? 10 : 7)) % ni; return ['KH_idle', Math.floor(ip), ip % 1];
}
// Posición en pantalla (coordenadas lógicas del lienzo de interfaz) de un punto del mundo, con subpíxel
function w2s(x, y) {
  const s = W / VW;
  let sx = ((x - cam.x - lastShake.x) * s - W / 2) * camZoom + W / 2, sy = ((y - cam.y - lastShake.y) * s - H / 2) * camZoom + H / 2;
  if (invertT > 0) { const k = invertT > 5.5 ? (6 - invertT) / 0.5 : invertT < 0.5 ? invertT / 0.5 : 1, f = 1 - 2 * clamp(k, 0, 1); sy = H / 2 + (sy - H / 2) * f; }
  return [sx, sy];
}
const HDT = {};
function hdTinted(k, fl, col) {
  const id = k + (fl ? 'f' : '') + col; if (HDT[id]) return HDT[id];
  const src = fl ? flipped(k) : SPR[k], [c, x] = mkCanvas(src.width, src.height);
  x.drawImage(src, 0, 0); x.globalCompositeOperation = 'source-atop'; x.fillStyle = col; x.fillRect(0, 0, c.width, c.height);
  return (HDT[id] = c);
}
// Suavizado de animación: mezcla entre fotogramas, transición entre poses, inclinación y respiración
const HS = { k: null, f: 0, pk: null, pf: 0, bl: 0, lean: 0, br: 0 };
function drawHeroHD() {
  if (!HDOK() || !p || state === 'cutscene') return;
  const s = W / VW * camZoom * 1.1, hd = 4, dt = Math.min(0.05, HS.t ? time - HS.t : 0); HS.t = time;
  for (const t of trails) { if (t.dk) continue; const [x, y] = w2s(t.x + p.w / 2, t.y + p.h + 2); drawHDFrame('KH_dash', 0, x, y, t.face < 0, s / hd, 'rgba(255,214,120,.9)', t.life / 0.22 * 0.45); }
  const [k, f, fr] = hdAnim(); if (!SPR[k]) return;
  // transición suave entre estados (correr→saltar, atacar→quieto…)
  if (k !== HS.k) { if (HS.k && SPR[HS.k] && !p.dead) { HS.pk = HS.k; HS.pf = HS.f; HS.bl = 1; } HS.k = k; }
  HS.f = f; HS.bl = Math.max(0, HS.bl - dt / (k === 'KH_dash' || k.startsWith('KH_atk') ? 0.045 : 0.08));
  // inclinación hacia la dirección del movimiento
  const face = p.wall ? -p.wall : p.face;
  let tl = 0;
  if (p.onGround && Math.abs(p.vx) > 30) tl = clamp(p.vx / 2600, -0.09, 0.09);
  else if (!p.onGround && !p.wall && !p.hook) tl = clamp(p.vx / 4200, -0.06, 0.06) + face * clamp(p.vy / 9000, -0.05, 0.06);
  if (p.dashT > 0) tl = face * 0.1;
  HS.lean += (tl - HS.lean) * Math.min(1, dt * 14);
  if (!p.dead && p.inv > 0 && p.dashT <= 0 && Math.floor(time * 20) % 2 === 0) return;
  const [x, y0] = w2s(p.x + p.w / 2, p.y + p.h + 2);
  const idle = k === 'KH_idle', run = k === 'KH_run';
  const breath = idle ? Math.sin(time * 2.6) * 0.014 : 0;
  const bob = run ? -Math.abs(Math.sin((p.runPh || 0) / META.KH_run.n * Math.PI * 2)) * 0.5 * s : 0;
  const sq = (p.sq || 1) * (1 + breath), white = flash > 0.08 && p.stun > 0;
  const tint = slowT > 0 ? 'rgba(120,200,255,.22)' : dim === 1 ? 'rgba(170,90,255,.14)' : (hdShade(p.x + p.w / 2, p.y + p.h / 2) || 'rgba(' + LOOK[curWorld].fog + ',.08)');
  const col = white ? '#ffffff' : tint;
  ctx.save(); ctx.translate(x, y0 + bob); ctx.rotate(HS.lean); ctx.scale(1 / Math.sqrt(sq), sq);
  const fl = face < 0, sc = s / hd;
  if (HS.bl > 0 && HS.pk) drawHDFrame(HS.pk, HS.pf, 0, 0, fl, sc, col, HS.bl * 0.6, white);
  const base = HS.bl > 0 ? 1 - HS.bl * 0.35 : 1;
  drawHDFrame(k, f, 0, 0, fl, sc, col, base, white);
  // mezcla con el siguiente fotograma: el movimiento se ve continuo en vez de a saltos
  if (fr && !white && (run || idle || k === 'KH_jump' || k.startsWith('KH_atk'))) drawHDFrame(k, f + 1, 0, 0, fl, sc, col, fr * 0.55 * base, false);
  ctx.restore();
}
// poses antiguas, algo más grandes que las nuevas animaciones de vídeo
const HDK = { KH_dash: .88, KH_wall: .86, KH_hurt: .9, KH_airdown: .88, KH_airslash: .88, KH_death: .9, KH_jumpU: .9, KH_fallU: .9 };
function drawHDFrame(k, f, x, y, fl, sc, tint, alpha, white) {
  if (tint && tint.lit) { // sombreado por luces cercanas (live2.js)
    const a = alpha === undefined ? 1 : alpha;
    drawHDFrame(k, f, x, y, fl, sc, null, a);
    if (tint.dark > 0) drawHDFrame(k, f, x, y, fl, sc, tint.dc, a * tint.dark);
    if (tint.lc && tint.la > 0) { const op = ctx.globalCompositeOperation; ctx.globalCompositeOperation = 'lighter'; drawHDFrame(k, f, x, y, fl, sc, tint.lc, a * tint.la); ctx.globalCompositeOperation = op; }
    return;
  }
  const m = META[k], n = m.n || 1, fr = ((f % n) + n) % n, fi = fl ? n - 1 - fr : fr, ax = fl ? m.fw - m.ax : m.ax;
  sc *= HDK[k] || 1;
  const src = white ? hdTinted(k, fl, '#ffffff') : tint ? hdTinted(k, fl, tint) : fl ? flipped(k) : SPR[k];
  ctx.globalAlpha = alpha === undefined ? 1 : alpha; ctx.imageSmoothingEnabled = true; ctx.imageSmoothingQuality = 'high';
  ctx.drawImage(src, fi * m.fw, 0, m.fw, m.fh, x - ax * sc, y - m.ay * sc, m.fw * sc, m.fh * sc);
  ctx.globalAlpha = 1;
}
function drawTicHD() {
  if (!SPR.TicHD || !SPR.TicHD.width || !p || p.dead) return false;
  const m = META.TicHD, s = W / VW * camZoom / 4, [x, y] = w2s(tic.x, tic.y + Math.sin(time * 3) * 1.5), f = Math.floor(time * 12) % m.n;
  ctx.save(); ctx.translate(x, y); ctx.rotate(clamp(tic.vx * 0.0015, -0.25, 0.25)); if (tic.face < 0) ctx.scale(-1, 1);
  ctx.imageSmoothingEnabled = true; ctx.drawImage(SPR.TicHD, f * m.fw, 0, m.fw, m.fh, -m.ax * s, -m.ay * s, m.fw * s, m.fh * s); ctx.restore();
  return true;
}

// ---------------- Tic habla ----------------
let ticSay = null, ticIdle = 0, ticCD = 8;
const TICQ = {
  idle: ['¿Nos quedamos aquí a vivir?', 'Si te quedas quieto, el tiempo no se arregla solo…', 'Tic, tac. Tic, tac. Era una indirecta.', 'Me oxido si no nos movemos.'],
  low: ['¡Cuidado, Kael! ¡Estás muy herido!', 'Busca una cereza, ¡rápido!', 'Esa herida no me gusta nada.'],
  gem: ['¡Mira, gemas!', 'Brillitos a la vista.', 'Para el taller, ¡no las dejes!'],
  relic: ['Siento un reloj de arena escondido por aquí…', 'Algo brilla cerca. ¿Lo oyes?'],
  hit: ['¡Buen golpe!', '¡Eso le ha dolido!', '¡Combo!'],
  check: ['Un punto de control. Respira.', 'Guardado. Bueno, más o menos.'],
  w: [['¡Qué olor a selva!', 'Oigo pájaros de otra era.'], ['Mil campanas y ninguna suena. Mal presagio.', 'Esas gárgolas me están mirando. Lo sé.'], ['¡Quema, quema!', 'Mis engranajes se derriten.'], ['Qué atardecer tan bonito… y eterno.', 'Las luciérnagas me saludan.'], ['Esto da escalofríos.', 'No mires las tumbas. Bueno, ya miraste.'], ['Brrr. Mis tuercas tiritan.', 'Cuidado, resbala.'], ['Huele a azufre.', 'Ni los demonios quieren estar aquí.'], ['¡Engranajes por todas partes! Me siento en casa.', 'El tiempo aquí da vueltas.'], ['¡Glub! ¿Los búhos nadan?', 'Mira cuántos peces.'], ['Arena en todos mis engranajes…', 'Las arenas suben al cielo. Qué raro.'], ['¡Qué vistas!', 'No mires abajo.'], ['Siento a Lyra muy cerca.', 'Esto es el corazón de todo.'], ['Croac. No, no he sido yo.', 'Ese caldero huele a problemas.'], ['Cuántas cadenas…', 'Un trono vacío da más miedo que uno ocupado.']]
};
function tSay(t, d) { ticSay = { t, life: d || 2.8 }; }
function updateTicLife(dt) {
  if (ticSay) { ticSay.life -= dt; if (ticSay.life <= 0) ticSay = null; }
  ticCD -= dt;
  if (Math.abs(p.vx) < 10 && p.onGround && p.atkT <= 0) ticIdle += dt; else ticIdle = 0;
  if (dlg || boss || ticCD > 0 || ticSay) return;
  const pick = a => a[Math.floor(Math.random() * a.length)];
  if (ticIdle > 7) { tSay(pick(TICQ.idle)); ticCD = 14; ticIdle = 0; }
  else if (p.hp < p.maxHp * 0.3) { tSay(pick(TICQ.low)); ticCD = 16; }
  else if (level.relic && !level.relic.taken && Math.abs(level.relic.x - p.x) < 260) { tSay(pick(TICQ.relic)); ticCD = 25; }
  else if (Math.random() < dt * 0.04) { tSay(pick(TICQ.w[curWorld] || TICQ.idle)); ticCD = 22; }
}
function drawTicSay() {
  if (!ticSay || !p) return;
  const [x, y] = w2s(tic.x, tic.y - 14), a = Math.min(1, ticSay.life * 3);
  ctx.save(); ctx.globalAlpha = a;
  const lines = wrapText(ticSay.t, 300, 12); ctx.font = '700 12px ' + UIF;
  const lw = Math.max(...lines.map(l => ctx.measureText(l).width)), tw = lw + 24, th = 12 + lines.length * 15;
  const bx0 = clamp(x - tw / 2, 8, W - tw - 8), by0 = Math.max(8, y - 18 - th);
  rrect(bx0, by0, tw, th, 13); ctx.fillStyle = 'rgba(255,248,230,.94)'; ctx.fill(); ctx.strokeStyle = '#ffc861'; ctx.lineWidth = 1.5; ctx.stroke();
  const tx = clamp(x, bx0 + 14, bx0 + tw - 14);
  ctx.beginPath(); ctx.moveTo(tx - 5, by0 + th); ctx.lineTo(tx, by0 + th + 7); ctx.lineTo(tx + 5, by0 + th); ctx.fillStyle = 'rgba(255,248,230,.94)'; ctx.fill();
  lines.forEach((l, i) => txt(l, bx0 + tw / 2, by0 + 13.5 + i * 15, 12, '#3a2410', null, 0, 'center', UIF, 700));
  ctx.restore();
}

// ---------------- Gemas que vuelan al marcador ----------------
let gemFly = [];
function gemToHud(x, y) { const [sx, sy] = w2s(x, y); gemFly.push({ x: sx, y: sy, t: 0, x0: sx, y0: sy }); }
function drawGemFly(dt) {
  for (let i = gemFly.length - 1; i >= 0; i--) {
    const g = gemFly[i]; g.t += dt * 1.8; if (g.t >= 1) { gemFly.splice(i, 1); hudPop = 1; continue; }
    const e = g.t * g.t, tx = 372, ty = 34, cx = (g.x0 + tx) / 2, cy = Math.min(g.y0, ty) - 80;
    const x = (1 - e) * (1 - e) * g.x0 + 2 * (1 - e) * e * cx + e * e * tx, y = (1 - e) * (1 - e) * g.y0 + 2 * (1 - e) * e * cy + e * e * ty;
    ctx.save(); ctx.globalCompositeOperation = 'lighter'; const r = 10 * (1 - g.t * .5);
    const gg = ctx.createRadialGradient(x, y, 0, x, y, r); gg.addColorStop(0, 'rgba(255,200,255,.95)'); gg.addColorStop(1, 'rgba(255,90,200,0)'); ctx.fillStyle = gg; ctx.fillRect(x - r, y - r, r * 2, r * 2); ctx.restore();
  }
}

// ---------------- Mariposas de recuerdo de Lyra ----------------
const LYRA_WHISPERS = ['¿Recuerdas cuando contábamos estrellas desde la torre?', 'Siempre fuiste el valiente, aunque temblaras.', 'Me gustaba cómo te reías de tus propios chistes malos.', 'El tiempo es como un río, Kael. No se puede beber todo.', 'Prométeme que también vivirás por ti.', 'Cada amanecer es un regalo. No los gastes mirando atrás.', 'Tic siempre me cayó bien. No se lo digas.', 'Te enseñé a esgrimir con una rama. Mírate ahora.', 'Estoy orgullosa de ti, hermanito.', 'Cuando cierres los ojos, piensa en el olor del pan de mamá.', 'Las estrellas también se apagan… pero su luz sigue viajando.', 'Ya casi. Puedo oír tu corazón desde aquí.'];
function placeButterfly(L, r) {
  if (L.arena || !L.width) return;
  const cand = L.plats.filter(s => s.k === 'solid' && s.x > 900 && s.x < L.width - 800);
  if (!cand.length) return; const s = cand[Math.floor(r() * cand.length)];
  L.butterfly = { x: s.x + s.w / 2, y: s.y - 70, taken: false, t: 0 };
}
function updateButterfly(dt) {
  const b = level.butterfly; if (!b || b.taken) return;
  b.t += dt; const bx_ = b.x + Math.sin(b.t * 0.8) * 30, by_ = b.y + Math.sin(b.t * 1.7) * 14;
  if (Math.random() < .3) parts.push({ x: bx_ + rnd(-4, 4), y: by_ + rnd(-3, 3), vx: rnd(-10, 10), vy: rnd(-20, 5), life: .8, max: .8, c: Math.random() < .5 ? '#ffe9a0' : '#ffd34d', s: 1, g: -10 });
  if (Math.abs(p.x + p.w / 2 - bx_) < 24 && Math.abs(p.y + p.h / 2 - by_) < 34) {
    b.taken = true; const w = LYRA_WHISPERS[curWorld] || LYRA_WHISPERS[0];
    SAVE.mem = SAVE.mem || {}; SAVE.mem[curWorld] = 1; persist();
    burst(bx_, by_, '#ffe9a0', 30, 160, 0, 1, 2); sfx('relic', .7, 1.3); flash = 0.15; flashCol = '255,230,160'; addScore(500);
    sayLines([['LYRA', w]], false);
  }
}
function drawButterfly() {
  const b = level.butterfly; if (!b || b.taken) return;
  const x = b.x + Math.sin(b.t * 0.8) * 30, y = b.y + Math.sin(b.t * 1.7) * 14, f = Math.abs(Math.sin(b.t * 12));
  if (!onScreen(x - 10, 20)) return;
  glowAt(x, y, 24, 'rgba(255,220,120,.8)', .7 + Math.sin(time * 4) * .2);
  bx.fillStyle = '#fff4c0'; bx.fillRect(Math.round(x - 4 - f * 2), Math.round(y - 3), Math.round(3 + f * 2), 4); bx.fillRect(Math.round(x + 1), Math.round(y - 3), Math.round(3 + f * 2), 4);
  bx.fillStyle = '#ffd34d'; bx.fillRect(Math.round(x - 3 - f), Math.round(y + 1), 2, 2); bx.fillRect(Math.round(x + 2 + f), Math.round(y + 1), 2, 2);
  bx.fillStyle = '#7a4a10'; bx.fillRect(Math.round(x), Math.round(y - 3), 1, 6);
}

// ---------------- Cristales del tiempo rompibles ----------------
function placeCrystals(L, r) {
  L.crystals = [];
  if (L.arena) return;
  for (const s of L.plats) if (s.k === 'solid' && !s.float && !s.ceil && s.w >= 192 && r() < 0.22) {
    const x = s.x + 40 + r() * (s.w - 80);
    if (L.hazards.some(h => Math.abs(h.x - x) < 60) || L.plates.some(q => Math.abs(q.x - x) < 80)) continue;
    L.crystals.push({ x, y: s.y, hp: 2, hit: 0, ph: r() * 6, dead: false });
  }
}
function hitCrystals(hb) {
  for (const c of level.crystals) if (!c.dead && hb.x < c.x + 9 && hb.x + hb.w > c.x - 9 && hb.y < c.y && hb.y + hb.h > c.y - 26) {
    if (p.hitSet.has(c)) continue; p.hitSet.add(c);
    c.hp--; c.hit = 0.15; sfx('ice', .5, 1.6); burst(c.x, c.y - 12, '#bff4ff', 6, 100, 200, .3, 2);
    if (c.hp <= 0) {
      c.dead = true; sfx('relic', .5, 1.8); burst(c.x, c.y - 12, '#7fe9ff', 22, 200, 300, .7, 2); addScore(80);
      for (let i = 0; i < 5; i++) level.gems.push({ x: c.x + rnd(-30, 30), y: c.y - 24 - rnd(0, 30), taken: false, ph: Math.random() * 6 });
    }
  }
}
function drawCrystals() {
  for (const c of level.crystals) {
    if (c.dead || !onScreen(c.x - 12, 24)) continue;
    if (c.hit > 0) c.hit -= 1 / 60;
    const x = Math.round(c.x), y = c.y, sh = c.hit > 0 ? Math.round(Math.sin(time * 90) * 1.5) : 0, col = WORLDS[curWorld].c;
    glowAt(x, y - 12, 22, hexToRgba(col, .55), .6 + Math.sin(time * 3 + c.ph) * .2);
    const pts = [[-7, 0, -3, -22, 1, 0], [-1, 0, 3, -28, 7, 0], [3, 0, 8, -16, 10, 0]];
    for (const q of pts) { bx.fillStyle = c.hit > 0 ? '#ffffff' : hexToRgba(col, .85); bx.beginPath(); bx.moveTo(x + q[0] + sh, y); bx.lineTo(x + q[2] + sh, y + q[3]); bx.lineTo(x + q[4] + sh, y); bx.fill(); }
    bx.fillStyle = 'rgba(255,255,255,.7)'; bx.fillRect(x - 1 + sh, y - 20, 1, 12); bx.fillRect(x + 4 + sh, y - 12, 1, 6);
    if (Math.random() < .03) parts.push({ x: x + rnd(-6, 8), y: y - rnd(4, 26), vx: 0, vy: -12, life: .7, max: .7, c: '#ffffff', s: 1, g: 0 });
  }
}

// ---------------- Pequeños detalles vivos ----------------
let gust = 0, gustT = 6;
function updateMagic(dt) {
  gustT -= dt; if (gustT <= 0) { gustT = rnd(7, 13); gust = 1; }
  gust = Math.max(0, gust - dt * 0.35);
  // estela de partículas de tiempo al correr rápido o hacer dash
  if ((Math.abs(p.vx) > 260 || p.dashT > 0) && Math.random() < .5) parts.push({ x: p.x + p.w / 2 - p.face * 6 + rnd(-3, 3), y: p.y + rnd(10, 36), vx: -p.face * rnd(10, 40), vy: rnd(-20, 5), life: .5, max: .5, c: Math.random() < .5 ? '#ffd34d' : '#fff4c0', s: 1, g: -20 });
  // al atravesar plantas, saltan hojas, pétalos o burbujas
  if (p.onGround && Math.abs(p.vx) > 120 && Math.random() < .12 && level.decor.some(d => d.k.startsWith('pr') && !d.big && Math.abs(d.x - (p.x + p.w / 2)) < 18)) {
    const c = [['#7dea5a', '#c9ff9a'], ['#5a6a50', '#8a7a60'], ['#ffb040', '#ff6a1a'], ['#ffb0d0', '#ffd0a0'], ['#a090b0', '#c8bca8'], ['#ffffff', '#cfefff'], ['#ff8a30', '#704040'], ['#ffd34d', '#d0a0ff'], ['#bff4ff', '#ff9ad8'], ['#ffe0a0', '#e0b060'], ['#ffffff', '#ffe9a0'], ['#ff6ad5', '#7fe9ff'], ['#6a8a50', '#b0d070'], ['#a0a8c8', '#7fb0ff'], ['#d0a0ff', '#f0d0ff'], ['#c8d8d0', '#90a8a0'], ['#e0c090', '#a08060'], ['#c0c8e8', '#8090c0']][curWorld] || ['#9be35a', '#5fb04a'];
    for (let i = 0; i < 4; i++) parts.push({ x: p.x + p.w / 2 + rnd(-8, 8), y: p.y + p.h - rnd(4, 20), vx: rnd(-60, 60), vy: rnd(-120, -40), life: rnd(.6, 1.1), max: 1.1, c: c[i % 2], s: 2, g: 160, lf: 1 });
  }
  if (p.landT > 0) p.landT -= dt;
  if (Math.abs(p.vx) > 30 && p.onGround) { p.runT = (p.runT || 0) + dt; const rn = META.KH_run ? META.KH_run.n : 8; p.runPh = ((p.runPh || 0) + dt * Math.abs(p.vx) / 290 * 13 * rn / 8) % rn; } else p.runT = 0;
  updateTicLife(dt); updateButterfly(dt);
}
