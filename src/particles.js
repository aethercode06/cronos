// =====================================================================
//  PARTÍCULAS DE ALTA CALIDAD
//  Texturas suaves generadas en tiempo real, mezcla aditiva para la luz,
//  estelas según la velocidad, humo que crece, chispas en estrella,
//  hojas/pétalos/copos que giran, ondas de choque e impactos.
// =====================================================================
const PTEX = {};
function ptex(kind) {
  if (PTEX[kind]) return PTEX[kind];
  const S = 64, [c, x] = mkCanvas(S, S); x.imageSmoothingEnabled = true;
  const rg = (r0, r1, stops) => { const g = x.createRadialGradient(S / 2, S / 2, r0, S / 2, S / 2, r1); stops.forEach(s => g.addColorStop(s[0], s[1])); return g; };
  if (kind === 'dot') { x.fillStyle = rg(0, 32, [[0, 'rgba(255,255,255,1)'], [0.35, 'rgba(255,255,255,.85)'], [0.7, 'rgba(255,255,255,.25)'], [1, 'rgba(255,255,255,0)']]); x.fillRect(0, 0, S, S); }
  else if (kind === 'glow') { x.fillStyle = rg(0, 32, [[0, 'rgba(255,255,255,.9)'], [0.2, 'rgba(255,255,255,.45)'], [1, 'rgba(255,255,255,0)']]); x.fillRect(0, 0, S, S); }
  else if (kind === 'spark') {
    x.fillStyle = rg(0, 32, [[0, 'rgba(255,255,255,.8)'], [0.25, 'rgba(255,255,255,.2)'], [1, 'rgba(255,255,255,0)']]); x.fillRect(0, 0, S, S);
    x.fillStyle = '#fff'; x.translate(32, 32);
    for (let i = 0; i < 4; i++) { x.rotate(Math.PI / 2); x.beginPath(); x.moveTo(0, -30); x.lineTo(3, -3); x.lineTo(0, 0); x.lineTo(-3, -3); x.fill(); }
    x.rotate(Math.PI / 4); x.globalAlpha = .5; for (let i = 0; i < 4; i++) { x.rotate(Math.PI / 2); x.beginPath(); x.moveTo(0, -16); x.lineTo(2, -2); x.lineTo(-2, -2); x.fill(); }
  }
  else if (kind === 'streak') { const g = x.createLinearGradient(0, 0, S, 0); g.addColorStop(0, 'rgba(255,255,255,0)'); g.addColorStop(0.75, 'rgba(255,255,255,.9)'); g.addColorStop(1, 'rgba(255,255,255,1)'); x.fillStyle = g; x.beginPath(); x.ellipse(32, 32, 31, 7, 0, 0, Math.PI * 2); x.fill(); x.globalCompositeOperation = 'destination-in'; x.fillStyle = rg(0, 34, [[0, '#fff'], [0.8, 'rgba(255,255,255,.9)'], [1, 'rgba(255,255,255,0)']]); x.fillRect(0, 0, S, S); }
  else if (kind === 'smoke') {
    const r = seeded(7);
    for (let i = 0; i < 9; i++) { const cx = 32 + (r() - .5) * 26, cy = 32 + (r() - .5) * 22, rr = 10 + r() * 12; const g = x.createRadialGradient(cx, cy, 0, cx, cy, rr); g.addColorStop(0, 'rgba(255,255,255,.55)'); g.addColorStop(1, 'rgba(255,255,255,0)'); x.fillStyle = g; x.fillRect(0, 0, S, S); }
  }
  else if (kind === 'leaf') { x.translate(32, 32); x.fillStyle = '#fff'; x.beginPath(); x.moveTo(-26, 0); x.quadraticCurveTo(-4, -18, 26, 0); x.quadraticCurveTo(-4, 18, -26, 0); x.fill(); x.strokeStyle = 'rgba(0,0,0,.35)'; x.lineWidth = 2; x.beginPath(); x.moveTo(-24, 0); x.lineTo(22, 0); x.stroke(); }
  else if (kind === 'petal') { x.translate(32, 32); x.fillStyle = '#fff'; x.beginPath(); x.moveTo(0, -24); x.bezierCurveTo(20, -18, 16, 18, 0, 26); x.bezierCurveTo(-16, 18, -20, -18, 0, -24); x.fill(); x.fillStyle = 'rgba(0,0,0,.18)'; x.beginPath(); x.ellipse(0, 6, 5, 14, 0, 0, Math.PI * 2); x.fill(); }
  else if (kind === 'flake') { x.translate(32, 32); x.strokeStyle = '#fff'; x.lineWidth = 3.5; x.lineCap = 'round'; for (let i = 0; i < 6; i++) { x.rotate(Math.PI / 3); x.beginPath(); x.moveTo(0, 0); x.lineTo(0, -26); x.moveTo(0, -14); x.lineTo(7, -21); x.moveTo(0, -14); x.lineTo(-7, -21); x.stroke(); } x.fillStyle = rg(0, 14, [[0, 'rgba(255,255,255,.9)'], [1, 'rgba(255,255,255,0)']]); x.setTransform(1, 0, 0, 1, 0, 0); x.fillRect(0, 0, S, S); }
  else if (kind === 'bubble') { x.strokeStyle = 'rgba(255,255,255,.85)'; x.lineWidth = 3; x.beginPath(); x.arc(32, 32, 26, 0, Math.PI * 2); x.stroke(); x.fillStyle = rg(0, 30, [[0, 'rgba(255,255,255,0)'], [0.8, 'rgba(255,255,255,.08)'], [1, 'rgba(255,255,255,.25)']]); x.fillRect(0, 0, S, S); x.fillStyle = 'rgba(255,255,255,.9)'; x.beginPath(); x.ellipse(22, 20, 7, 4, -0.6, 0, Math.PI * 2); x.fill(); }
  else if (kind === 'shard') { x.translate(32, 32); x.fillStyle = '#fff'; x.beginPath(); x.moveTo(-14, -20); x.lineTo(22, -6); x.lineTo(6, 22); x.lineTo(-18, 8); x.closePath(); x.fill(); x.fillStyle = 'rgba(0,0,0,.3)'; x.beginPath(); x.moveTo(6, 22); x.lineTo(-18, 8); x.lineTo(2, 2); x.fill(); x.fillStyle = 'rgba(255,255,255,.6)'; x.beginPath(); x.moveTo(-14, -20); x.lineTo(22, -6); x.lineTo(2, 2); x.fill(); }
  c._d = 1; c._ww = S; c._wh = S;
  return (PTEX[kind] = c);
}
// versión coloreada (con núcleo blanco para las luces)
const PTC = {};
function ptexC(kind, col, hot) {
  const id = kind + col + (hot ? 'h' : ''); if (PTC[id]) return PTC[id];
  const t = ptex(kind), [c, x] = mkCanvas(64, 64); x.imageSmoothingEnabled = true;
  x.drawImage(t, 0, 0); x.globalCompositeOperation = 'source-atop'; x.fillStyle = col; x.fillRect(0, 0, 64, 64);
  if (hot) { x.globalCompositeOperation = 'lighter'; const g = x.createRadialGradient(32, 32, 0, 32, 32, 12); g.addColorStop(0, 'rgba(255,255,255,.9)'); g.addColorStop(1, 'rgba(255,255,255,0)'); x.fillStyle = g; x.fillRect(0, 0, 64, 64); }
  c._d = 1; c._ww = 64; c._wh = 64;
  return (PTC[id] = c);
}
function colLum(col) { const c = parseCol(col); return c[0] * .3 + c[1] * .55 + c[2] * .15; }
function colSat(col) { const c = parseCol(col); return Math.max(...c) - Math.min(...c); }
// dibuja una textura centrada, rotada y escalada (ancho w, alto h en píxeles del mundo)
function pdraw(img, x, y, w, h, rot, a) {
  bx.globalAlpha = a;
  if (rot) { bx.save(); bx.translate(x, y); bx.rotate(rot); bx.drawImage(img, -w / 2, -h / 2, w, h); bx.restore(); }
  else bx.drawImage(img, x - w / 2, y - h / 2, w, h);
  bx.globalAlpha = 1;
}
// clasificación de cada partícula según cómo se creó
function pclass(q) {
  if (q.k) return q.k;
  if (q.lf) return (q.k = Math.random() < .5 ? 'leaf' : 'petal');
  if (q.dust) return (q.k = 'smoke');
  const L = colLum(q.c), S2 = colSat(q.c);
  if (L < 0.42 && S2 < 0.5) return (q.k = 'shard');          // escombros oscuros
  if (q.g < 0) return (q.k = q.c === '#cfffff' || q.c === '#bff4ff' ? 'bubble' : 'ember');
  if (q.c === '#ffffff' && curWorld === 5 && q.g < 120) return (q.k = 'flake');
  return (q.k = 'spark');
}
drawParticles = function () {
  const add = [], norm = [];
  for (const q of parts) { if (q.x < cam.x - 40 || q.x > cam.x + VW + 40 || q.y < cam.y - 60 || q.y > cam.y + VH + 60) continue; const k = pclass(q); (k === 'smoke' || k === 'shard' || k === 'leaf' || k === 'petal' || k === 'bubble' || k === 'flake' ? norm : add).push(q); }
  // humo, escombros, hojas
  for (const q of norm) {
    const t = clamp(q.life / q.max, 0, 1), k = q.k;
    if (k === 'smoke') { const r = q.s * (1.4 + (1 - t) * 2.2); pdraw(ptexC('smoke', q.c), q.x, q.y, r * 2, r * 2, (q.ph || (q.ph = Math.random() * 6)) + (1 - t) * 0.8, t * (colLum(q.c) > 0.7 ? 0.26 : 0.4)); }
    else if (k === 'shard') { const r = q.s * 1.8; q.rot = (q.rot || Math.random() * 6) + 0.25; pdraw(ptexC('shard', q.c), q.x, q.y, r * 2, r * 2, q.rot, Math.min(1, t * 2)); }
    else if (k === 'leaf' || k === 'petal') { q.rot = (q.rot || Math.random() * 6) + (q.vx > 0 ? .12 : -.12); const r = q.s * 2.2; pdraw(ptexC(k, q.c), q.x, q.y, r * 2, r * 2 * (0.4 + Math.abs(Math.sin(time * 6 + q.rot)) * 0.6), q.rot, Math.min(1, t * 2)); }
    else if (k === 'bubble') { const r = q.s * 1.8 + 1; pdraw(ptex('bubble'), q.x + Math.sin(time * 4 + q.y * .1) * 1.2, q.y, r * 2, r * 2, 0, Math.min(1, t * 2) * .8); }
    else if (k === 'flake') { q.rot = (q.rot || Math.random() * 6) + .03; const r = q.s * 1.8 + 1; pdraw(ptex('flake'), q.x, q.y, r * 2, r * 2, q.rot, Math.min(1, t * 2)); }
  }
  // luz: chispas con estela y brasas
  bx.globalCompositeOperation = 'lighter';
  for (const q of add) {
    const t = clamp(q.life / q.max, 0, 1), sp = Math.hypot(q.vx, q.vy), a = Math.min(1, t * 1.6);
    if (q.k === 'ember') {
      const r = q.s * (1.5 + t), fl = 0.75 + Math.sin(time * 18 + q.x) * 0.25;
      pdraw(ptexC('glow', q.c), q.x, q.y, r * 4, r * 4, 0, a * 0.3 * fl);
      pdraw(ptexC('dot', q.c, true), q.x, q.y, r * 1.6, r * 1.6, 0, a * fl);
    } else if (sp > 70) {
      const len = clamp(sp * 0.045, 3, 16) * (0.6 + t * 0.4), w = q.s * 1.4;
      pdraw(ptexC('streak', q.c, true), q.x - q.vx * 0.012, q.y - q.vy * 0.012, len, w * 1.6, Math.atan2(q.vy, q.vx), a);
      pdraw(ptexC('glow', q.c), q.x, q.y, w * 3, w * 3, 0, a * 0.2);
    } else {
      const r = q.s * (0.9 + t * 0.8), tw = 0.6 + 0.4 * Math.sin(time * 20 + q.x * 3);
      pdraw(ptexC(q.s >= 2 && (q.x * 7 | 0) % 3 === 0 ? 'spark' : 'dot', q.c, true), q.x, q.y, r * 2.3, r * 2.3, (q.x * 13) % 6, a * tw);
      pdraw(ptexC('glow', q.c), q.x, q.y, r * 4, r * 4, 0, a * 0.15);
    }
  }
  // ondas de choque
  for (const R of rings) {
    const t = 1 - R.life / R.max, r = R.r0 + (R.r1 - R.r0) * (1 - Math.pow(1 - t, 3));
    bx.globalAlpha = (1 - t) * R.a * 0.7; bx.strokeStyle = R.c; bx.lineWidth = Math.max(0.5, R.w * (1 - t)); bx.beginPath(); bx.ellipse(R.x, R.y, r, r * (R.flat || 1), 0, 0, Math.PI * 2); bx.stroke();
    bx.globalAlpha = (1 - t) * R.a * 0.2; bx.lineWidth = R.w * 2.2 * (1 - t); bx.stroke();
  }
  // destellos de impacto
  for (const F of flashes) { const t = F.life / F.max; pdraw(ptexC('spark', F.c, true), F.x, F.y, F.r * (1.3 - t * .3), F.r * (1.3 - t * .3), F.rot, t * 0.9); pdraw(ptexC('glow', F.c), F.x, F.y, F.r * 1.6, F.r * 1.6, 0, t * 0.35); }
  bx.globalCompositeOperation = 'source-over'; bx.globalAlpha = 1;
  // efectos de sprite que no se reemplazan
  for (const e of fx) { if (FX_PROC[e.k]) { if (!e.done) { e.done = 1; FX_PROC[e.k](e.x, e.y); } continue; } spr(e.k, Math.floor(e.t * e.fps), e.x, e.y, e.flip, e.s); }
};
let rings = [], flashes = [];
function ring(x, y, r0, r1, life, c, w, a, flat) { rings.push({ x, y, r0, r1, life, max: life, c, w: w || 2, a: a === undefined ? 0.9 : a, flat }); }
function impactFlash(x, y, r, c, life) { flashes.push({ x, y, r, c, life: life || 0.12, max: life || 0.12, rot: Math.random() * 6 }); }
function smokePuff(x, y, n, col, sz, up) { for (let i = 0; i < n; i++) parts.push({ x: x + rnd(-6, 6), y: y + rnd(-6, 4), vx: rnd(-50, 50), vy: rnd(-60, -10) - (up || 0), life: rnd(.5, .9), max: .9, c: col, s: sz || 3, g: -30, dust: true }); }
const _updParts = updateParticles;
updateParticles = function (dt) {
  _updParts(dt);
  for (let i = rings.length - 1; i >= 0; i--) { rings[i].life -= dt; if (rings[i].life <= 0) rings.splice(i, 1); }
  for (let i = flashes.length - 1; i >= 0; i--) { flashes[i].life -= dt; if (flashes[i].life <= 0) flashes.splice(i, 1); }
};
// efectos procedurales que sustituyen a los sprites pixelados
const FX_PROC = {
  poof: (x, y) => { smokePuff(x, y - 10, 8, '#a8a0b8', 2); burst(x, y - 12, '#ffffff', 8, 140, 200, .4, 1); ring(x, y - 10, 4, 20, .3, 'rgba(255,255,255,.6)', 1); },
  boom: (x, y) => { impactFlash(x, y - 14, 30, '#ffd060', .16); smokePuff(x, y - 14, 10, '#4a3e3c', 3, 20); burst(x, y - 14, '#ffb040', 22, 260, 300, .6, 2); burst(x, y - 14, '#ff6a1a', 10, 160, -40, .9, 2); ring(x, y - 14, 6, 40, .4, 'rgba(255,200,120,.7)', 2); lightAt(x, y - 14, 140, 'rgba(255,170,80,1)', .7); shake = Math.max(shake, 3); },
  flame_death: (x, y) => { impactFlash(x, y - 10, 22, '#ff9040', .14); burst(x, y - 10, '#ffb040', 16, 180, -60, .9, 2); burst(x, y - 10, '#ff5a20', 10, 120, -30, 1.1, 2); smokePuff(x, y - 12, 6, '#3a2c2c', 2, 30); ring(x, y - 6, 4, 26, .3, 'rgba(255,150,60,.6)', 1.4); },
  shothit: (x, y) => { impactFlash(x, y - 6, 22, '#9ff0ff', .1); burst(x, y - 6, '#9ff0ff', 10, 180, 200, .35, 1); ring(x, y - 6, 2, 16, .25, 'rgba(160,240,255,.9)', 1.5); },
  sparkle: (x, y) => { impactFlash(x, y - 16, 20, '#ffe9a0', .2); for (let i = 0; i < 8; i++) { const a = i / 8 * Math.PI * 2; parts.push({ x, y: y - 16, vx: Math.cos(a) * 90, vy: Math.sin(a) * 90, life: .4, max: .4, c: i % 2 ? '#ffd34d' : '#ff9ad8', s: 1, g: 0 }); } ring(x, y - 16, 2, 16, .3, 'rgba(255,230,150,.6)', 1); },
  worm_boom: (x, y) => { FX_PROC.flame_death(x, y - 10); },
  bomb_boom: (x, y) => { FX_PROC.boom(x, y - 14); }
};
// impacto al golpear con la espada
if (typeof damageEnemy === 'function') {
  const _dmg = damageEnemy;
  damageEnemy = function (e, hb) {
    const hp0 = e.hp; _dmg(e, hb);
    if (e.hp < hp0) {
      const x = e.x + e.w / 2 - p.face * e.w * 0.25, y = e.y + e.h * 0.45, big = p.atkN === 2;
      impactFlash(x, y, big ? 26 : 18, '#fff4d0', big ? .14 : .1);
      for (let i = 0; i < (big ? 14 : 8); i++) { const a = (Math.random() - .5) * 1.6 + (p.face > 0 ? 0 : Math.PI); const v = rnd(160, 340); parts.push({ x, y, vx: Math.cos(a) * v, vy: Math.sin(a) * v - 40, life: rnd(.18, .35), max: .35, c: i % 3 ? '#fff4c0' : '#ffd060', s: 1, g: 400 }); }
      ring(x, y, 3, big ? 28 : 18, .22, 'rgba(255,240,200,.7)', big ? 1.8 : 1.2);
      lightAt(x, y, 80, 'rgba(255,240,200,1)', .5);
    }
  };
}

// ---------------- clima con texturas ----------------
drawWeather = function (back) {
  const w = WORLDS[curWorld].weather;
  const addMode = w === 'embers' || w === 'fireflies' || w === 'void' || w === 'clocks';
  if (addMode) bx.globalCompositeOperation = 'lighter';
  for (const a of amb) {
    const x = a.x * VW / 960, y = a.y * VH / 540, s = a.s;
    if (w === 'leaves') { if (s > 1) pdraw(ptexC('leaf', a.ph > 3 ? '#9be35a' : '#5fb04a'), x, y, 7, 4 + Math.abs(Math.sin(time * 3 + a.ph)) * 3, Math.sin(time * 1.5 + a.ph) * 2, .95); else { const b = Math.sin(time * 2 + a.ph); if (b > .2) { bx.globalCompositeOperation = 'lighter'; pdraw(ptexC('dot', '#ffff9a', true), x, y, 3, 3, 0, b); pdraw(ptexC('glow', '#ffee80'), x, y, 9, 9, 0, b * .4); bx.globalCompositeOperation = 'source-over'; } } }
    else if (w === 'rain') pdraw(ptexC('streak', 'rgba(170,210,255,1)'), x, y, 9, 1.2, Math.PI / 2 + 0.15, .4);
    else if (w === 'embers') { const fl = .6 + Math.sin(time * 9 + a.ph * 3) * .4; pdraw(ptexC('dot', s > 1 ? '#ffd040' : '#ff7a2a', true), x, y, s * 2, s * 2, 0, fl); pdraw(ptexC('glow', '#ff8a30'), x, y, s * 6, s * 6, 0, fl * .35); }
    else if (w === 'fireflies') { const b = Math.sin(time * 2 + a.ph); if (b > -0.2) { pdraw(ptexC('dot', '#ffe9a0', true), x, y, s * 2, s * 2, 0, b); pdraw(ptexC('glow', '#ffd060'), x, y, s * 9, s * 9, 0, b * .5); } }
    else if (w === 'fog') { bx.globalAlpha = .06; bx.drawImage(ptexC('smoke', '#c8aaff'), x - 50, y - 12, 120 + s * 30, 34); bx.globalAlpha = 1; }
    else if (w === 'snow') pdraw(s > 1 ? ptex('flake') : ptex('dot'), x, y, s * 2.2 + 1, s * 2.2 + 1, time * .5 + a.ph, .9);
    else if (w === 'bubbles') pdraw(ptex('bubble'), x, y, s > 1 ? 6 : 3, s > 1 ? 6 : 3, 0, .6);
    else if (w === 'sand') pdraw(ptexC('streak', s > 1 ? 'rgba(255,220,150,1)' : 'rgba(230,180,110,1)'), x, y, 6 + s * 2, 1.4, 0, .6);
    else if (w === 'clouds') { if (s > 1) { bx.globalAlpha = .09; bx.drawImage(ptex('smoke'), x - 40, y - 10, 100, 30); bx.globalAlpha = 1; } else if (Math.sin(time * 2 + a.ph) > .4) { bx.globalCompositeOperation = 'lighter'; pdraw(ptexC('spark', '#fff4c0', true), x, y, 4, 4, time, .8); bx.globalCompositeOperation = 'source-over'; } }
    else if (w === 'void') { pdraw(ptexC(s > 1 ? 'spark' : 'dot', s > 1 ? '#ff6edc' : '#8ce6ff', true), x, y, s * 3, s * 3, time + a.ph, .8); if (s > 1) pdraw(ptexC('glow', '#ff6edc'), x, y, 10, 10, 0, .35); }
    else if (w === 'clocks') { pdraw(ptexC(s > 1 ? 'spark' : 'dot', s > 1 ? '#ffd34d' : '#c8a0ff', true), x, y, s * 3, s * 3, time * .7 + a.ph, .8); if (s > 1) pdraw(ptexC('glow', '#ffd34d'), x, y, 9, 9, 0, .3); }
  }
  bx.globalCompositeOperation = 'source-over'; bx.globalAlpha = 1;
};
// ---------------- vida ambiental con texturas ----------------
const _drawLifeBase = drawLife;
drawLife = function () {
  const keep = { butterfly: 1, bird: 1, bat: 1, fish: 1, drone: 1, beetle: 1 };
  for (const a of life) {
    if (keep[a.k] || !onScreen(a.x - 6, 12)) continue;
    const x = a.x, y = a.y, k = a.k;
    if (k === 'firefly' || k === 'wisp' || k === 'soul') {
      const b = Math.sin(a.t * 3 + a.ph); if (b < -0.3) continue; const c = k === 'soul' ? '#78c8ff' : k === 'wisp' ? '#dc96ff' : '#ffe678';
      bx.globalCompositeOperation = 'lighter'; pdraw(ptexC('dot', c, true), x, y, 3, 3, 0, .5 + b * .5); pdraw(ptexC('glow', c), x, y, 12, 12, 0, (.5 + b * .5) * .45); bx.globalCompositeOperation = 'source-over';
    } else if (k === 'ember' || k === 'spark' || k === 'shard' || k === 'gearbit') {
      const c = k === 'shard' ? '#ff6ad5' : k === 'spark' ? '#7fe9ff' : k === 'gearbit' ? '#ffd34d' : '#ff9a3a', fl = .6 + Math.sin(a.t * 10 + a.ph) * .4;
      bx.globalCompositeOperation = 'lighter'; pdraw(ptexC(k === 'shard' || k === 'gearbit' ? 'spark' : 'dot', c, true), x, y, 3, 3, a.t, fl); pdraw(ptexC('glow', c), x, y, 9, 9, 0, fl * .35); bx.globalCompositeOperation = 'source-over';
    } else if (k === 'bubble') pdraw(ptex('bubble'), x, y, a.ph > 3 ? 6 : 4, a.ph > 3 ? 6 : 4, 0, .7);
    else if (k === 'flake') pdraw(ptex('flake'), x, y, 4, 4, a.t * .6 + a.ph, .95);
    else if (k === 'ash' || k === 'dust') pdraw(ptexC('dot', k === 'dust' ? '#ffdc96' : '#5a5050'), x, y, 2.5, 2.5, 0, .6);
    else if (k === 'petal') pdraw(ptexC('petal', '#ffb0d0'), x, y, 5, 5 * (0.4 + Math.abs(Math.sin(a.t * 3 + a.ph)) * 0.6), a.t * 1.5 + a.ph, .95);
    else if (k === 'feather') pdraw(ptexC('leaf', '#fffaf0'), x, y, 7, 3 + Math.abs(Math.sin(a.t * 2 + a.ph)) * 2, Math.sin(a.t + a.ph) * 1.2 + 1.2, .95);
  }
  // los que conservan su forma (mariposas, pájaros, peces...)
  const saved = life; life = saved.filter(a => keep[a.k]); _drawLifeBase(); life = saved;
};
// enjambres de luciérnagas con texturas suaves
drawSwarms = function () {
  const c = 'rgb(' + SWARM_C[curWorld] + ')';
  bx.globalCompositeOperation = 'lighter';
  for (const S of swarms) {
    if (!onScreen(S.x - 60, 120)) continue;
    let mx = 0, my = 0, n = 0;
    for (const q of S.f) {
      const b = 0.5 + 0.5 * Math.sin(time * 4 * q.sp + q.ph * 3); if (b < 0.12) continue;
      pdraw(ptexC('dot', c, true), q.x, q.y, 2.6, 2.6, 0, 0.5 + b * 0.5); pdraw(ptexC('glow', c), q.x, q.y, 11, 11, 0, b * 0.45);
      mx += q.x; my += q.y; n++;
    }
    if (n) lightAt(mx / n, my / n, 70, 'rgba(' + SWARM_C[curWorld] + ',1)', 0.22);
  }
  bx.globalCompositeOperation = 'source-over'; bx.globalAlpha = 1;
};
