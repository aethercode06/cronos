// =====================================================================
//  SISTEMAS NUEVOS: mejoras, ECO temporal, placas, anclas, Tic,
//  jefes 9-12, fondos pintados, escenas, taller y mapa de 12 mundos
// =====================================================================
const UPG = [
  { k: 'hp', n: 'Corazón de bronce', d: '+20 de vida máxima', cost: [30, 70, 130], c: '#3df5a0' },
  { k: 'sword', n: 'Filo del minutero', d: '+50% de daño con la espada', cost: [50, 120], c: '#ff6a8a' },
  { k: 'dash', n: 'Muelle comprimido', d: 'El DASH recarga más rápido', cost: [40, 90], c: '#35e2ff' },
  { k: 'time', n: 'Arena dorada', d: 'El poder del TIEMPO se carga antes', cost: [40, 90], c: '#ffd34d' },
  { k: 'magnet', n: 'Imán de Tic', d: 'Las gemas cercanas vuelan hacia ti', cost: [60], c: '#ff9af0' }
];
function UP(k) { return (SAVE.up && SAVE.up[k]) || 0; }
function dashMax() { return 0.7 - 0.15 * UP('dash'); }
function swordDmg() { return 1 + 0.5 * UP('sword'); }
function ecoAvailable() { return curWorld >= 9; }
let invertT = 0;

// ---------------- ECO temporal ----------------
let echo = null;
function ecoPress() {
  if (!ecoAvailable()) return;
  if (echo && echo.rec) { startEchoPlay(); return; }
  echo = { rec: true, frames: [], t: 0, i: 0, hold: 0, x: p.x, y: p.y };
  sfx('slow', .6, 1.6); addFloat(p.x + p.w / 2, p.y - 16, 'GRABANDO ECO…', '#7fe9ff', 15);
  burst(p.x + p.w / 2, p.y + p.h / 2, '#7fe9ff', 14, 140, 0, .5, 2);
}
function startEchoPlay() {
  if (!echo || echo.frames.length < 4) { echo = null; return; }
  echo.rec = false; echo.i = 0; echo.hold = 9; sfx('shift', .7, 1.4);
  addFloat(p.x + p.w / 2, p.y - 16, '¡ECO EN MARCHA!', '#7fe9ff', 15);
}
function updateEcho(dt) {
  if (!echo) return;
  if (echo.rec) {
    const [k, f] = playerAnim(); echo.frames.push({ x: p.x, y: p.y, k, f, face: p.wall ? -p.wall : p.face });
    echo.t += dt; if (echo.t >= 5) startEchoPlay();
  } else {
    if (echo.i < echo.frames.length - 1) echo.i++;
    else { echo.hold -= dt; if (echo.hold <= 0) { burst(echoBox().x + 11, echoBox().y + 24, '#7fe9ff', 12, 120, 0, .5, 2); echo = null; } }
  }
}
function echoBox() { const f = echo.frames[echo.rec ? 0 : echo.i]; return { x: f.x, y: f.y, w: PW, h: PH }; }
function drawEcho() {
  if (!echo) return;
  if (echo.rec) {
    const f = echo.frames[0]; if (!f) return;
    bx.globalAlpha = 0.35 + Math.sin(time * 10) * 0.1; bx.strokeStyle = '#7fe9ff'; bx.lineWidth = 1;
    bx.beginPath(); bx.arc(f.x + PW / 2, f.y + PH / 2, 18 + Math.sin(time * 6) * 2, 0, 6.3); bx.stroke(); bx.globalAlpha = 1;
    // estela de la grabación
    for (let i = 0; i < echo.frames.length; i += 10) { const q = echo.frames[i]; bx.fillStyle = 'rgba(127,233,255,.35)'; bx.fillRect(Math.round(q.x + PW / 2), Math.round(q.y + PH - 2), 2, 2); }
    return;
  }
  const f = echo.frames[echo.i], a = echo.hold < 1.5 ? echo.hold / 1.5 : 1;
  glowAt(f.x + PW / 2, f.y + PH / 2, 30, 'rgba(90,220,255,.55)', .7 * a);
  const m = meta(f.k), n = m.n, fr = ((f.f % n) + n) % n, fl = f.face < 0, src = tintOf2(f.k, fl);
  const fi = fl ? n - 1 - fr : fr, ax = fl ? m.fw - m.ax : m.ax;
  bx.globalAlpha = 0.72 * a; bx.drawImage(src, fi * m.fw, 0, m.fw, m.fh, Math.round(f.x + PW / 2 - ax), Math.round(f.y + PH + 2 - m.ay), m.fw, m.fh); bx.globalAlpha = 1;
}
const TINT2 = {};
function tintOf2(k, fl) {
  const id = k + (fl ? 'f' : ''); if (TINT2[id]) return TINT2[id];
  const src = fl ? flipped(k) : SPR[k], [c, x] = dmk(src);
  x.drawImage(src, 0, 0); x.globalCompositeOperation = 'source-atop'; x.fillStyle = 'rgba(80,220,255,.62)'; x.fillRect(0, 0, c.width, c.height);
  return (TINT2[id] = c);
}

// ---------------- Placas y puertas ----------------
function updatePlates(dt) {
  for (const pl of level.plates) {
    const was = pl.on, feet = (b) => b.x + b.w > pl.x + 4 && b.x < pl.x + pl.w - 4 && Math.abs(b.y + b.h - (pl.y + pl.h)) < 10;
    pl.on = feet(p) || (echo && !echo.rec && feet(echoBox()));
    if (pl.on && !was) { sfx('lever', .5, 1.3); burst(pl.x + pl.w / 2, pl.y, '#7fe9ff', 8, 100, 200, .4, 2); }
    if (!pl.on && was) sfx('clang', .25, .8);
  }
  for (const d of level.doors) {
    const t = d.plate.on ? 1 : 0; if (t !== d.tg) { d.tg = t; if (t && Math.abs(d.x - p.x) < 700) sfx('crumble', .4, 1.4); }
    d.open = approach(d.open, t, dt * 6);
  }
  if (boss && boss.type === 9 && !boss.dying && boss.vulnT <= 0) {
    const bp = level.plates.filter(q => q.boss);
    if (bp.length === 2 && bp.every(q => q.on)) { boss.vulnT = 6; shake = 12; sfx('shield'); hitStop = 0.12; flash = 0.2; flashCol = '255,220,120'; addFloat(boss.x + boss.w / 2, boss.y - 24, '¡ESCUDO ROTO!', '#ffd34d', 24); }
  }
}
function drawPlates() {
  for (const pl of level.plates) {
    if (!onScreen(pl.x, pl.w)) continue;
    bx.fillStyle = '#2a2236'; bx.fillRect(pl.x - 2, pl.y + 1, pl.w + 4, pl.h);
    bx.fillStyle = pl.on ? '#7fe9ff' : '#b08a40'; bx.fillRect(pl.x, pl.y + (pl.on ? 3 : 0), pl.w, pl.on ? 3 : 5);
    glowAt(pl.x + pl.w / 2, pl.y, 26, pl.on ? 'rgba(90,230,255,.7)' : 'rgba(255,200,90,.4)', .5 + Math.sin(time * 4) * .15);
    if (!pl.on) { const y = pl.y - 22 + Math.round(Math.sin(time * 4) * 3); bx.fillStyle = 'rgba(127,233,255,.8)'; bx.fillRect(pl.x + pl.w / 2 - 1, y, 3, 8); bx.fillRect(pl.x + pl.w / 2 - 4, y + 5, 9, 2); bx.fillRect(pl.x + pl.w / 2 - 2, y + 7, 5, 2); }
  }
}
function drawDoor(d) {
  if (!onScreen(d.x, d.w)) return;
  const hh = Math.round(d.h * (1 - d.open)); if (hh <= 0) return;
  const y = d.y + d.h - hh;
  bx.fillStyle = '#3a2a1a'; bx.fillRect(d.x, y, d.w, hh);
  bx.fillStyle = '#c89a40'; for (let yy = y + 6; yy < d.y + d.h; yy += 18) { bx.fillRect(d.x + 3, yy, d.w - 6, 2); bx.fillRect(d.x + d.w / 2 - 1, yy + 4, 2, 8); }
  bx.fillStyle = '#ffd34d'; bx.fillRect(d.x, y, 2, hh); bx.fillRect(d.x + d.w - 2, y, 2, hh);
  glowAt(d.x + d.w / 2, y + 20, 30, 'rgba(255,200,90,.35)', .6);
}

// ---------------- Anclas (gancho de balanceo) ----------------
function nearAnchor() {
  let best = null, bd = 160;
  if (p.hookCD > 0 && time < p.hookCD) return null;
  for (const a of level.anchors) {
    if (a === p.lastHook && time < (p.hookCD2 || 0)) continue; const d = Math.hypot(a.x - (p.x + p.w / 2), a.y - (p.y + p.h / 2)); if (d < bd) { bd = d; best = a; } }
  return best;
}
function attachHook(a) {
  const cx = p.x + p.w / 2, cy = p.y + p.h / 2, dx = cx - a.x, dy = cy - a.y, len = clamp(Math.hypot(dx, dy), 70, 140);
  const ang = Math.atan2(dx, dy), tv = p.vx * Math.cos(ang) - p.vy * Math.sin(ang);
  p.hook = { a, len, ang, av: clamp(tv / len, -6, 6) }; p.buf = 0; p.dashT = 0; p.jumps = 1;
  sfx('lever', .5, 1.6); burst(a.x, a.y, '#ffd34d', 10, 120, 0, .4, 2);
}
function updateHook(dt, dir) {
  const h = p.hook, g = GRAV * 0.9;
  h.av += (-(g / h.len) * Math.sin(h.ang) + dir * 3.2) * dt; h.av *= (1 - 0.15 * dt); h.av = clamp(h.av, -7, 7);
  h.ang += h.av * dt;
  const cx = h.a.x + Math.sin(h.ang) * h.len, cy = h.a.y + Math.cos(h.ang) * h.len;
  p.vx = Math.cos(h.ang) * h.len * h.av; p.vy = -Math.sin(h.ang) * h.len * h.av;
  p.x = cx - p.w / 2; p.y = cy - p.h / 2; p.onGround = false; p.ground = null; p.wall = 0;
  if (dir) p.face = dir; else if (Math.abs(p.vx) > 40) p.face = Math.sign(p.vx);
  if (pressed.jump) { p.lastHook = h.a; p.hookCD = time + 0.15; p.hookCD2 = time + 0.6; p.buf = 0; p.hook = null; p.vy = Math.min(p.vy, 0) - 300; p.vx *= 1.15; p.jumps = 1; p.noCut = true; sfx('jump', .5, 1.2); burst(cx, cy, '#ffd34d', 8, 120, 0, .3, 2); return; }
  for (const s of level.plats) if (isSolid(s) && overlap(p, s)) { p.hook = null; p.vy = 0; break; }
}
function drawAnchors() {
  for (const a of level.anchors) {
    if (!onScreen(a.x - 20, 40)) continue;
    const near = !p.hook && !p.onGround && Math.hypot(a.x - (p.x + p.w / 2), a.y - (p.y + p.h / 2)) < 160;
    glowAt(a.x, a.y, near ? 34 : 22, 'rgba(255,210,90,.6)', .6 + Math.sin(time * 5) * .2);
    bx.strokeStyle = '#ffd34d'; bx.lineWidth = 3; bx.beginPath(); bx.arc(a.x, a.y, 9, 0, 6.3); bx.stroke();
    bx.strokeStyle = '#fff4c0'; bx.lineWidth = 1; bx.beginPath(); bx.arc(a.x, a.y, 9, time * 2, time * 2 + 1.6); bx.stroke();
    for (let i = 0; i < 4; i++) { const t = time * 1.5 + i * 1.57; bx.fillStyle = '#ffe9a0'; bx.fillRect(Math.round(a.x + Math.cos(t) * 14), Math.round(a.y + Math.sin(t) * 14), 2, 2); }
    if (near) { bx.globalAlpha = .7 + Math.sin(time * 10) * .3; bx.strokeStyle = '#ffffff'; bx.lineWidth = 1; bx.beginPath(); bx.arc(a.x, a.y, 15, 0, 6.3); bx.stroke(); bx.globalAlpha = 1; }
  }
  if (p.hook) {
    const a = p.hook.a, cx = p.x + p.w / 2, cy = p.y + 14;
    bx.strokeStyle = 'rgba(255,220,120,.9)'; bx.lineWidth = 2; bx.beginPath(); bx.moveTo(a.x, a.y); bx.lineTo(cx, cy); bx.stroke();
    glowAt((a.x + cx) / 2, (a.y + cy) / 2, 20, 'rgba(255,210,90,.4)', .5);
  }
}

// ---------------- Tic, el compañero ----------------
let tic = { x: 0, y: 0, vx: 0, vy: 0, face: 1, blink: 0 };
function resetTic() { tic.x = p.x - 30; tic.y = p.y - 30; tic.vx = tic.vy = 0; }
function updateTic(dt) {
  let tx = p.x + p.w / 2 - p.face * 26, ty = p.y - 18 + Math.sin(time * 3) * 5;
  if (!boss && level && level.gems) { let best = null, bd = 120; for (const g of level.gems) { if (g.taken) continue; const d = Math.hypot(g.x - tic.x, g.y - tic.y); if (d < bd && Math.hypot(g.x - p.x, g.y - p.y) < 170) { bd = d; best = g; } } if (best) { tx = best.x; ty = best.y; } }
  tic.vx += (tx - tic.x) * 14 * dt; tic.vy += (ty - tic.y) * 14 * dt; tic.vx *= 1 - 5 * dt; tic.vy *= 1 - 5 * dt;
  tic.x += tic.vx * dt; tic.y += tic.vy * dt; tic.face = Math.abs(tic.vx) > 20 ? Math.sign(tic.vx) : p.face;
  if (Math.random() < dt * 0.4) tic.blink = 0.12; if (tic.blink > 0) tic.blink -= dt;
}
function drawTic() {
  if (!SPR.cr_tic || p.dead || (SPR.TicHD && SPR.TicHD.width)) return;
  const m = meta('cr_tic'), flap = Math.sin(time * 16), sy = 1 + flap * 0.08, x = Math.round(tic.x), y = Math.round(tic.y);
  glowAt(x, y, 16, 'rgba(255,200,110,.35)', .5);
  bx.save(); bx.translate(x, y); bx.scale(tic.face < 0 ? -1 : 1, sy); bx.rotate(clamp(tic.vx * 0.002, -0.3, 0.3));
  if (SPR.an_tic && SPR.an_tic.width) { const am = meta('an_tic'), f = Math.floor(time * 12) % am.n; bx.scale(1, 1 / sy); bx.drawImage(SPR.an_tic, f * am.fw, 0, am.fw, am.fh, -am.fw / 2, -am.fh / 2, am.fw, am.fh); }
  else bx.drawImage(SPR.cr_tic, -m.fw / 2, -m.fh / 2);
  bx.restore();
  lightAt(x, y, 70, 'rgba(255,220,160,1)', .25);
}

// ---------------- Criaturas con arte estático: animación procedural ----------------
function drawStatic(e) {
  const d = e.d, ak = 'an_' + d.anim.slice(3), anim = SPR[ak] && SPR[ak].width, k = anim ? ak : d.anim; if (!SPR[k]) return;
  const m = meta(k), cx = e.x + e.w / 2, by = e.y + e.h, wh = e.hit > 0, fl = d.face === 0 ? false : e.dir !== d.face;
  let ox = 0, oy = 0, sx = 1, sy = 1, rot = 0, alpha = 1;
  if (d.stat === 'walk') { const ph = e.t * (e.b === 'chaser' && e.saw ? 16 : 10); oy = -Math.abs(Math.sin(ph)) * 2; rot = Math.sin(ph) * 0.05; sy = 1 + Math.sin(ph * 2) * 0.03; }
  else if (d.stat === 'swim') { rot = Math.sin(e.t * 3) * 0.08; sx = 1 + Math.sin(e.t * 6) * 0.04; }
  else if (d.stat === 'jelly') { sy = 1 + Math.sin(e.t * 3) * 0.1; sx = 1 - Math.sin(e.t * 3) * 0.06; alpha = 0.88; }
  else if (d.stat === 'fly') { rot = e.st === 'dive' ? (e.vy > 0 ? 0.5 : -0.3) * (fl ? -1 : 1) : Math.sin(e.t * 2) * 0.1; sy = 1 + Math.sin(e.t * 14) * 0.12; }
  else if (d.stat === 'float') { oy = Math.sin(e.t * 2.5) * 3; sy = 1 + Math.sin(e.t * 2.5) * 0.03; }
  else if (d.stat === 'hop') { if (e.air) { sy = e.vy < 0 ? 1.12 : 0.95; sx = 1 / sy; } else { sy = 1 - Math.abs(Math.sin(e.t * 3)) * 0.06; sx = 1 + (1 - sy) * .6; } }
  if (e.b === 'riser' && e.st === 'rising') { const k2 = clamp(e.rise / 0.8, 0, 1); bx.save(); bx.beginPath(); bx.rect(cx - 60, by - 200, 120, 200); bx.clip(); oy = (1 - k2) * m.fh; }
  if (d.glow) glowAt(cx, e.y + e.h * 0.45, Math.max(e.w, e.h) * 0.8, d.glow, .6);
  if (d.lure) { const lx_ = cx + (fl ? -1 : 1) * (d.lure[0] - m.fw / 2) * 0.9, ly = by - m.fh + d.lure[1] + Math.sin(e.t * 3) * 2; glowAt(lx_, ly, 14, 'rgba(120,250,255,.9)', .9); }
  const src = wh ? whiteOf(k, fl) : fl ? flipped(k) : SPR[k];
  if (anim) { sx = 1 + (sx - 1) * .3; sy = 1 + (sy - 1) * .3; rot *= .5; }
  const n = m.n || 1, fr = anim ? Math.floor(e.t * (e.b === 'chaser' && e.saw ? 14 : 9)) % n : 0, fi = fl ? n - 1 - fr : fr, axx = fl ? m.fw - m.ax : m.ax;
  bx.save(); bx.globalAlpha = alpha; bx.translate(Math.round(cx + ox), Math.round(by + oy)); bx.rotate(rot); bx.scale(sx, sy);
  bx.drawImage(src, fi * m.fw, 0, m.fw, m.fh, -axx, -m.ay, m.fw, m.fh); bx.restore();
  if (e.b === 'riser' && e.st === 'rising') { bx.restore(); dust(cx, by, 1); }
  if (e.b === 'riser' && e.st === 'buried') return;
}

// ---------------- Jefes 9-12 ----------------
function spawnBossX(t, A) {
  const cx = (A.x1 + A.x2) / 2;
  if (t === 8) return { w: 150, h: 96, x: A.x2 + 60, y: A.floor - 260, st: 'wait', cd: 1, side: 1, n: 0, vx: 0, vy: 0, ty: 0 };
  if (t === 9) return { w: 140, h: 120, x: cx + 120, y: A.floor - 120, st: 'idle', cd: 1.6, n: 0, vulnT: 0, side: 1 };
  if (t === 10) return { w: 70, h: 120, x: cx - 35, y: A.floor - 330, st: 'float', cd: 1.5, n: 0, vx: 0, vy: 0, invCD: 9 };
  return { w: 170, h: 150, x: cx - 85, y: A.floor - 345, st: 'float', cd: 2, n: 0, vx: 0, vy: 0, summoned: false };
}
function bossHitRule(b) {
  if (b.type === 8) return b.st === 'stuck' ? 2 : b.st === 'spit' ? 1 : 0;
  if (b.type === 9) return b.vulnT > 0 ? 2 : 0;
  if (b.type === 10) return b.st === 'stun' ? 2 : 1;
  return b.st === 'tired' ? 2 : 1;
}
function updateBossX(b, dt, A, ag, pcx, pcy, bcx) {
  const D = DIFFS[diffIdx]; let contact = true;
  if (b.type === 8) {
    // LEVIATÁN DE CORAL: embestidas horizontales, burbujas y mordisco al suelo
    if (b.st === 'wait') { contact = false; b.cd -= dt; if (b.cd <= 0) { b.n++; const m = b.n % 3; b.st = m === 0 ? 'biteT' : m === 1 ? 'lungeT' : 'spitIn'; b.t = 0; b.ty = clamp(pcy - b.h / 2, A.floor - 300, A.floor - b.h); b.side = Math.random() < .5 ? 1 : -1; } }
    else if (b.st === 'lungeT') {
      contact = false; b.x = b.side > 0 ? A.x2 + 40 : A.x1 - b.w - 40; b.y = b.ty; b.face = -b.side;
      if (b.t > 0.75 / Math.sqrt(ag)) { b.st = 'lunge'; b.t = 0; b.vx = -b.side * 620 * ag; sfx('roar', .7, .7); }
    } else if (b.st === 'lunge') {
      b.x += b.vx * dt; if (Math.random() < .6) parts.push({ x: b.x + b.w / 2 - b.vx * 0.1, y: b.y + rnd(0, b.h), vx: -b.vx * .2, vy: rnd(-30, 30), life: .6, max: .6, c: '#bff4ff', s: 2, g: -60 });
      if ((b.vx < 0 && b.x + b.w < A.x1 - 60) || (b.vx > 0 && b.x > A.x2 + 60)) { b.st = 'wait'; b.cd = 0.5 / ag; }
    } else if (b.st === 'spitIn') {
      const tx = b.side > 0 ? A.x2 - b.w - 20 : A.x1 + 20; b.face = b.side > 0 ? -1 : 1; b.x = lerp(b.x, tx, dt * 3); b.y = lerp(b.y, A.floor - 300, dt * 3);
      if (b.t > 0.8) { b.st = 'spit'; b.t = 0; b.shots = 0; }
    } else if (b.st === 'spit') {
      b.face = pcx < bcx ? -1 : 1;
      if (b.t > 0.45) { b.t = 0; b.shots++; const sx = bcx + b.face * 60, sy = b.y + 40; for (let i = -1; i <= 1; i++) { const a = Math.atan2(pcy - sy, pcx - sx) + i * 0.3; projs.push({ x: sx, y: sy, vx: Math.cos(a) * 200 * D.spd, vy: Math.sin(a) * 200 * D.spd, hw: 7, hh: 7, type: 'bubble', dmg: 12, life: 4 }); } sfx('bounce', .5, .6); }
      if (b.shots >= 3) { b.st = 'leave'; b.t = 0; }
    } else if (b.st === 'leave') { b.x += (b.side > 0 ? 1 : -1) * 500 * dt; if (b.t > 0.8) { b.st = 'wait'; b.cd = 0.4; } }
    else if (b.st === 'biteT') {
      contact = false; const tx = clamp(pcx - b.w / 2, A.x1 + 10, A.x2 - b.w - 10); b.x = lerp(b.x, tx, dt * 4); b.y = lerp(b.y, A.floor - 430, dt * 4); b.face = -1;
      if (b.t > 1.0 / Math.sqrt(ag)) { b.st = 'bite'; b.t = 0; b.vy = 300; sfx('roar', .9, .5); }
      if (Math.random() < .4) warnLine(bcx);
    } else if (b.st === 'bite') {
      b.vy += 2600 * dt; b.y += b.vy * dt;
      if (b.y + b.h >= A.floor) { b.y = A.floor - b.h; b.st = 'stuck'; b.t = 0; shake = 18; sfx('stomp'); sfx('boom', .6); dust(bcx, A.floor, 16); waves.push({ x: bcx - 70, y: A.floor, dir: -1, spd: 300 * ag, t: 0, col: '#cfefff' }); waves.push({ x: bcx + 70, y: A.floor, dir: 1, spd: 300 * ag, t: 0, col: '#cfefff' }); }
    } else if (b.st === 'stuck') { contact = false; if (b.t > 2.4 / Math.sqrt(ag)) { b.st = 'leave'; b.side = pcx < bcx ? 1 : -1; b.t = 0; b.y -= 4; } }
  } else if (b.type === 9) {
    // ESFINGE DEL RELOJ: escudo que solo cae con las dos placas pisadas a la vez
    b.face = pcx < bcx ? -1 : 1;
    if (b.vulnT > 0) { b.vulnT -= dt; if (b.vulnT <= 0) { sfx('shield', .6, .7); addFloat(bcx, b.y - 24, 'ESCUDO RESTAURADO', '#ffc24a', 20); } }
    b.cd -= dt;
    if (b.st === 'idle' && b.cd <= 0) {
      b.n++; b.cd = (b.vulnT > 0 ? 2.4 : 1.7) / ag; b.atkA = 0.6; const m = b.n % 4;
      if (m === 1) { waves.push({ x: bcx - 60, y: A.floor, dir: -1, spd: 320 * ag, t: 0, col: '#ffd890' }); waves.push({ x: bcx + 60, y: A.floor, dir: 1, spd: 320 * ag, t: 0, col: '#ffd890' }); sfx('stomp'); shake = 10; }
      else if (m === 2) { const c = diffIdx === 2 ? 6 : 4; for (let i = 0; i < c; i++) warns.push({ x: i === 0 ? pcx : rnd(A.x1 + 40, A.x2 - 40), t: 0.8 + i * 0.16, kind: 'sand' }); sfx('alert', .6); }
      else if (m === 3) { const y = clamp(pcy, A.floor - 200, A.floor - 20); b.beamY = y; b.st = 'beamT'; b.t = 0; sfx('alert', .7); }
      else { b.st = 'tp'; b.t = 0; }
    } else if (b.st === 'beamT') { if (b.t > 0.7 / Math.sqrt(ag)) { b.st = 'idle'; for (let i = 0; i < 3; i++) projs.push({ x: bcx + b.face * 40, y: b.beamY, vx: b.face * (520 + i * 60) * ag, vy: 0, hw: 26, hh: 4, type: 'laser', dmg: 14, life: 3 }); sfx('shoot', .7, .7); } }
    else if (b.st === 'tp') {
      if (b.t > 0.4 && !b.tpd) { b.tpd = true; burst(bcx, b.y + b.h / 2, '#ffd890', 30, 240, 300, .8, 3); b.x = (bcx > (A.x1 + A.x2) / 2 ? (A.x1 + A.x2) / 2 - 220 : (A.x1 + A.x2) / 2 + 80); sfx('shift', .7, .6); }
      if (b.t > 0.8) { b.tpd = false; b.st = 'idle'; b.cd = 0.6; }
    }
    contact = b.st !== 'tp';
  } else if (b.type === 10) {
    // SERAFÍN INVERTIDO: anillos boomerang, lluvia de plumas, picado y cielo invertido
    b.invCD -= dt;
    if (b.invCD <= 0) { b.invCD = 14 / ag; invertT = 6; flash = 0.3; flashCol = '255,255,255'; sfx('shift', 1, .5); addFloat(bcx, b.y - 20, '¡EL CIELO SE INVIERTE!', '#bfe6ff', 20); }
    if (b.st === 'float') {
      b.face = pcx < bcx ? -1 : 1;
      const tx = clamp(pcx - b.w / 2 + Math.sin(b.t * 0.7) * 200, A.x1 + 20, A.x2 - b.w - 20), ty = A.floor - 290 + Math.sin(b.t * 1.8) * 16;
      b.x = lerp(b.x, tx, dt * 1.2); b.y = lerp(b.y, ty, dt * 1.6); b.cd -= dt;
      if (b.cd <= 0) {
        b.n++; b.cd = 1.5 / ag; const m = b.n % 3;
        if (m === 1) { for (const s of [-1, 1]) projs.push({ x: bcx, y: b.y + 50, vx: s * 420 * D.spd, vy: 40 * s, hw: 10, hh: 10, type: 'ring', dmg: 14, life: 3.2, ox: bcx, back: false }); sfx('swing', .8, .7); }
        else if (m === 2) { const c = diffIdx === 2 ? 7 : 5; for (let i = 0; i < c; i++) warns.push({ x: rnd(A.x1 + 30, A.x2 - 30), t: 0.6 + i * 0.12, kind: 'feather' }); if (Math.random() < .5) warns.push({ x: pcx, t: 0.7, kind: 'feather' }); sfx('alert', .5); }
        else { b.st = 'diveT'; b.t = 0; sfx('alert', .7, 1.3); }
      }
    } else if (b.st === 'diveT') { b.x += Math.sin(b.t * 60) * 1.4; if (b.t > 0.55 / Math.sqrt(ag)) { b.st = 'dive'; b.t = 0; b.tx = clamp(pcx - b.w / 2, A.x1 + 10, A.x2 - b.w - 10); sfx('dash', .9, .7); } }
    else if (b.st === 'dive') { b.x = lerp(b.x, b.tx, dt * 8); b.y += 900 * ag * dt; if (b.y + b.h >= A.floor) { b.y = A.floor - b.h; b.st = 'stun'; b.t = 0; shake = 14; sfx('stomp'); dust(bcx, A.floor, 14); waves.push({ x: bcx - 40, y: A.floor, dir: -1, spd: 280 * ag, t: 0, col: '#ffffff' }); waves.push({ x: bcx + 40, y: A.floor, dir: 1, spd: 280 * ag, t: 0, col: '#ffffff' }); } }
    else if (b.st === 'stun') { contact = false; if (b.t > 1.9) { b.st = 'float'; b.t = 0; b.cd = 1; } }
    for (const q of projs) if (q.type === 'ring') { const t = 3.2 - q.life; if (t > 0.8 && !q.back) { q.back = true; } if (q.back) { const dx = bcx - q.x, dy = b.y + 50 - q.y, d = Math.hypot(dx, dy) || 1; q.vx += dx / d * 1200 * dt; q.vy += dy / d * 1200 * dt; const v = Math.hypot(q.vx, q.vy); if (v > 480) { q.vx *= 480 / v; q.vy *= 480 / v; } if (d < 30) q.life = 0; } }
  } else {
    // EL DEVORADOR DE HORAS: todos los ataques de los guardianes anteriores
    b.face = pcx < bcx ? -1 : 1;
    if (b.st === 'float') {
      const tx = clamp(pcx - b.w / 2, A.x1 + 40, A.x2 - b.w - 40), ty = A.floor - 345 + Math.sin(b.t * 1.3) * 14;
      b.x = lerp(b.x, tx, dt * 0.8); b.y = lerp(b.y, ty, dt * 2); b.cd -= dt;
      if (b.cd <= 0) {
        b.n++; b.cd = 1.6 / ag; b.atkA = 0.5; const m = b.n % 5;
        if (m === 1) { waves.push({ x: A.x1 + 20, y: A.floor, dir: 1, spd: 330 * ag, t: 0, col: '#d070ff' }); waves.push({ x: A.x2 - 20, y: A.floor, dir: -1, spd: 330 * ag, t: 0, col: '#d070ff' }); sfx('stomp'); shake = 10; }
        else if (m === 2) { for (let i = 0; i < 3; i++) projs.push({ x: bcx, y: clamp(pcy, A.floor - 220, A.floor - 20) - 40 + i * 40, vx: b.face * (380 + i * 70) * ag, vy: 0, hw: 26, hh: 4, type: 'laser', dmg: 14, life: 4 }); sfx('shoot', .8, .6); }
        else if (m === 3) { const c = diffIdx === 2 ? 6 : 4; for (let i = 0; i < c; i++) warns.push({ x: i === 0 ? pcx : rnd(A.x1 + 40, A.x2 - 40), t: 0.8 + i * 0.15 }); sfx('alert', .6); }
        else if (m === 4) { const n = diffIdx === 2 ? 4 : 3; for (let i = 0; i < n; i++) projs.push({ x: bcx, y: b.y + b.h - 20, vx: (i - (n - 1) / 2) * 160, vy: -200, hw: 8, hh: 8, type: 'clock', dmg: 14, life: 3.5 }); sfx('slow', .6, 1.4); }
        else { b.st = 'tiredT'; b.t = 0; sfx('roar', 1, .4); addFloat(bcx, b.y + b.h + 10, '¡SE AGOTA!', '#ffd34d', 20); }
      }
    } else if (b.st === 'tiredT') { b.y = Math.min(A.floor - b.h, b.y + 260 * dt); if (b.y >= A.floor - b.h) { b.st = 'tired'; b.t = 0; shake = 14; sfx('stomp'); dust(bcx, A.floor, 18); } }
    else if (b.st === 'tired') { contact = false; if (b.t > 2.8 / Math.sqrt(ag)) { b.st = 'float'; b.t = 0; b.cd = 1; } }
  }
  return contact;
}
function warnLine(x) { if (Math.random() < .15) parts.push({ x: x + rnd(-40, 40), y: level.arena.floor - 2, vx: 0, vy: -60, life: .4, max: .4, c: '#ff5470', s: 2, g: 0 }); }
// el arte nuevo de algunos guardianes mira a la derecha
function SFL(b) { return !!(b.skin && WORLDS[curWorld] && WORLDS[curWorld].boss.sfl && b.skin === WORLDS[curWorld].boss.skin); }
const BOSSX = { 8: 'boss_lev', 9: 'boss_sph', 10: 'boss_ser', 11: 'boss_devo' };
function drawBossX(b, wh, blink) {
  const ak = 'an_' + BOSSX[b.type], k = b.skin && SPR[b.skin] && SPR[b.skin].width ? b.skin : SPR[ak] && SPR[ak].width ? ak : BOSSX[b.type]; if (!SPR[k]) return;
  const m = meta(k), cx = b.x + b.w / 2, by = b.y + b.h, src = wh || blink ? whiteOf(k, false) : SPR[k], bf = (m.n || 1) > 1 ? Math.floor(time * 9) % m.n : 0;
  let sx = 1, sy = 1, rot = 0, oy = 0, flip = false;
  if (b.type === 8) {
    flip = SFL(b) ? b.face < 0 : b.face > 0; rot = b.st === 'lunge' ? Math.sin(time * 10) * 0.06 : b.st === 'bite' ? -0.5 * (flip ? -1 : 1) : b.st === 'stuck' ? -0.35 * (flip ? -1 : 1) : Math.sin(time * 2) * 0.05;
    sy = 1 + Math.sin(time * 3) * 0.03; glowAt(cx, b.y + b.h / 2, 120, 'rgba(60,220,255,.25)', .7);
    if (b.st === 'lungeT') { bx.globalAlpha = .35 + .35 * Math.sin(time * 30); bx.fillStyle = '#ff3d5a'; for (let x = level.arena.x1; x < level.arena.x2; x += 18) bx.fillRect(x, Math.round(b.y + b.h / 2), 10, 2); bx.globalAlpha = 1; }
    if (b.st === 'stuck') { glowAt(cx - (flip ? -1 : 1) * 70, b.y + 20, 30, 'rgba(120,250,255,.9)', .9); for (let i = 0; i < 3; i++) { const a = time * 5 + i * 2.1; bx.fillStyle = '#ffe066'; bx.fillRect(Math.round(cx + Math.cos(a) * 40), Math.round(b.y - 10 + Math.sin(a) * 6), 3, 3); } }
  } else if (b.type === 9) {
    flip = SFL(b) ? b.face < 0 : b.face > 0; sy = 1 + Math.sin(time * 2) * 0.015; glowAt(cx, b.y + 30, 110, 'rgba(255,200,90,.3)', .7);
    if (b.st === 'tp') { const k2 = b.t < 0.4 ? 1 - b.t / 0.4 : (b.t - 0.4) / 0.4; sx = k2; sy = 1 + (1 - k2) * 0.5; }
    if (b.st === 'beamT') { glowAt(cx + b.face * 40, b.y + 30, 30, 'rgba(255,90,60,.9)', .9); bx.globalAlpha = .4 + .4 * Math.sin(time * 30); bx.fillStyle = '#ff3d5a'; for (let x = level.arena.x1; x < level.arena.x2; x += 16) bx.fillRect(x, Math.round(b.beamY) - 1, 10, 2); bx.globalAlpha = 1; }
  } else if (b.type === 10) {
    if (SFL(b)) flip = p.x + p.w / 2 < cx;
    oy = b.st === 'float' ? Math.sin(time * 2.5) * 4 : 0; sy = 1 + Math.sin(time * 5) * 0.03; glowAt(cx, b.y + 40, 120, 'rgba(255,240,190,.35)', .8);
    if (b.st === 'diveT') glowAt(cx, b.y + 40, 60, 'rgba(255,80,80,.7)', .8);
    if (b.st === 'stun') for (let i = 0; i < 3; i++) { const a = time * 5 + i * 2.1; bx.fillStyle = '#ffe066'; bx.fillRect(Math.round(cx + Math.cos(a) * 34), Math.round(b.y - 10 + Math.sin(a) * 6), 3, 3); }
  } else {
    const pulse = 1 + Math.sin(time * 3) * 0.04; sx = pulse; sy = pulse; oy = 0;
    glowAt(cx, b.y + b.h / 2, 200, 'rgba(180,40,255,.35)', .9); glowAt(cx, b.y + b.h / 2, 90, 'rgba(255,40,90,.35)', .8);
    // tentáculos
    bx.strokeStyle = 'rgba(30,10,40,.9)'; bx.lineWidth = 6;
    for (let i = 0; i < 6; i++) { const a0 = (i / 6) * Math.PI + Math.PI * 0.08; bx.beginPath(); let x = cx + Math.cos(a0) * 50, y = b.y + b.h * 0.7; bx.moveTo(x, y); for (let j = 1; j < 8; j++) { x += Math.cos(a0 + Math.sin(time * 2 + i + j * .5) * .6) * 14; y += 12; bx.lineTo(x, y); } bx.stroke(); }
    if (b.st === 'tired') for (let i = 0; i < 3; i++) { const a = time * 5 + i * 2.1; bx.fillStyle = '#ffe066'; bx.fillRect(Math.round(cx + Math.cos(a) * 60), Math.round(b.y - 10 + Math.sin(a) * 8), 4, 4); }
  }
  bx.save(); bx.translate(Math.round(cx), Math.round(by + oy)); bx.rotate(rot); bx.scale(flip ? -sx : sx, sy);
  bx.drawImage(src, bf * m.fw, 0, m.fw, m.fh, -m.ax, -m.ay, m.fw, m.fh); bx.restore();
  if (b.type === 9 && b.vulnT <= 0 && !b.dying) shieldBubble(cx, b.y + b.h / 2, 92);
}

// ---------------- Fondos pintados ----------------
const PBGM = {};
function pbgMirror(n) {
  const id = n + '_' + VH; if (PBGM[id]) return PBGM[id];
  const im = SPR['pbg' + n]; if (!im || !im.width) return null;
  // copia pre-escalada a la altura de la vista y espejada para que el mosaico no tenga cortes
  const s = (VH * 1.14) / im.height, w = Math.round(im.width * s), h = Math.round(im.height * s);
  const [c, x] = qmk(w * 2, h); x.imageSmoothingEnabled = true; x.imageSmoothingQuality = 'high';
  x.filter = 'blur(' + (0.9 * QR).toFixed(1) + 'px)';
  x.drawImage(im, 0, 0, w, h); x.save(); x.translate(w * 2, 0); x.scale(-1, 1); x.drawImage(im, 0, 0, w, h); x.restore(); x.filter = 'none';
  return (PBGM[id] = c);
}
function paintBG(n, par) {
  const img = pbgMirror(n); if (!img) return false;
  const w = img._ww, h = img._wh;
  const vy = clamp((cam.y - (level ? level.top : 0)) / 600, -1, 1);
  const y = Math.round(-(h - VH) * (0.5 + vy * 0.4));
  let x = -(((cam.x * (par || 0.05)) % w) + w) % w;
  for (; x < VW + 2; x += w) bx.drawImage(img, Math.round(x * QR) / QR, y, w, h);
  // atenuar y dar profundidad para que el primer plano y los personajes destaquen
  const DIM = [.16, .3, .28, .22, .3, .3, .32, .3, .34, .32, .58, .34, .16, .2, .1, .28, .26, .26], dd = DIM[curWorld] || .32, tint = WORLDS[curWorld].c;
  const g = bx.createLinearGradient(0, 0, 0, VH); g.addColorStop(0, 'rgba(6,6,18,' + (dd * .7) + ')'); g.addColorStop(1, 'rgba(6,6,18,' + Math.min(.7, dd * 1.5) + ')');
  bx.fillStyle = g; bx.fillRect(0, 0, VW + 2, VH + 2);
  bx.globalAlpha = .06; bx.fillStyle = tint; bx.fillRect(0, 0, VW + 2, VH + 2); bx.globalAlpha = 1;
  return true;
}
function drawBGNew(n) {
  paintBG(n, 0.06);
  if (lightning > 0 && Math.floor(lightning * 20) % 2 === 0 && n >= 12) { bx.fillStyle = n === 17 ? 'rgba(200,215,255,.3)' : 'rgba(220,200,255,.2)'; bx.fillRect(0, 0, VW + 2, VH + 2); }
  if (n === 8) {
    // rayos de luz y peces
    bx.globalCompositeOperation = 'lighter';
    for (let i = 0; i < 4; i++) { const x = ((i * 260 - cam.x * 0.1) % (VW + 300) + VW + 300) % (VW + 300) - 150, a = 0.06 + Math.sin(time * .7 + i) * 0.03; const g = bx.createLinearGradient(x, 0, x + 120, VH); g.addColorStop(0, 'rgba(180,255,255,' + a + ')'); g.addColorStop(1, 'rgba(180,255,255,0)'); bx.fillStyle = g; bx.beginPath(); bx.moveTo(x, 0); bx.lineTo(x + 50, 0); bx.lineTo(x + 170, VH); bx.lineTo(x + 90, VH); bx.fill(); }
    bx.globalCompositeOperation = 'source-over';
    const per = 20, t = (time % per) / per, fy = 80 + Math.sin(time * .3) * 30; bx.fillStyle = 'rgba(10,40,60,.6)';
    for (let i = 0; i < 12; i++) { const x = VW + 60 - t * (VW + 200) + (i % 4) * 12 + Math.sin(time * 3 + i) * 3, y = fy + Math.floor(i / 4) * 9 + (i % 4) * 2; bx.fillRect(Math.round(x), Math.round(y), 5, 2); bx.fillRect(Math.round(x) + 5, Math.round(y) - 1, 2, 4); }
  } else if (n === 9) {
    bx.fillStyle = 'rgba(255,220,150,.08)'; for (let y = VH - 80; y < VH; y += 4) bx.fillRect(Math.round(Math.sin(y * .3 + time * 4) * 3), y, VW + 2, 1);
  } else if (n === 10) {
    const img = fogTex('255,255,255'); bx.globalAlpha = .22;
    for (let i = 0; i < 2; i++) { const w = 512 * 1.6, y = 60 + i * 120; let x = -(((cam.x * (0.15 + i * .1) + time * (8 + i * 6)) % w) + w) % w; for (; x < VW + 2; x += w) bx.drawImage(img, Math.round(x), y, Math.round(w), 150); }
    bx.globalAlpha = 1;
  } else if (n === 11) {
    bx.globalCompositeOperation = 'lighter';
    if (Math.floor(time * 3) % 7 === 0) { bx.strokeStyle = 'rgba(255,255,255,.25)'; bx.lineWidth = 1; bx.beginPath(); let x = (time * 97) % VW, y = 0; bx.moveTo(x, y); while (y < VH * .6) { x += rnd(-20, 20); y += rnd(10, 30); bx.lineTo(x, y); } bx.stroke(); }
    bx.globalCompositeOperation = 'source-over';
  }
}
function drawZonesX(z) {
  if (z.k === 'water') {
    const t = time; bx.fillStyle = 'rgba(40,150,200,.28)'; bx.fillRect(z.x, z.y + 6, z.w, z.h - 6);
    bx.fillStyle = 'rgba(160,240,255,.55)'; for (let x = z.x; x < z.x + z.w; x += 4) bx.fillRect(x, Math.round(z.y + 4 + Math.sin(x * .08 + t * 3) * 2), 4, 2);
    for (let i = 0; i < 10; i++) { const bxx = z.x + (i * 83) % z.w, byy = z.y + z.h - ((t * 40 + i * 47) % z.h); bx.fillStyle = 'rgba(220,255,255,.5)'; bx.fillRect(Math.round(bxx + Math.sin(t * 3 + i) * 3), Math.round(byy), 2, 2); }
    if (z.fx) { bx.fillStyle = 'rgba(255,255,255,.3)'; for (let i = 0; i < 12; i++) { const sx = z.x + ((i * 61 - t * 200) % z.w + z.w) % z.w, sy = z.y + 20 + (i * 37) % (z.h - 30); bx.fillRect(Math.round(sx), Math.round(sy), 12, 1); } }
    lightAt(z.x + z.w / 2, z.y + 30, z.w * .7, 'rgba(80,200,255,1)', .25);
  } else if (z.k === 'sand') {
    bx.fillStyle = '#d8a850'; bx.fillRect(z.x, z.y + 22, z.w, 12);
    bx.fillStyle = '#f0c870'; for (let x = z.x; x < z.x + z.w; x += 6) bx.fillRect(x, Math.round(z.y + 21 + Math.sin(x * .2 + time * 2) * 1.5), 6, 2);
    for (let i = 0; i < 6; i++) { const cx = z.x + ((i * 97 + time * 15) % z.w); bx.fillStyle = 'rgba(120,80,30,.5)'; bx.fillRect(Math.round(cx), z.y + 26, 8, 1); }
  }
}

// ---------------- Dibujo de escenas y diálogos (capa HUD) ----------------
function portrait(key, cx, cy, r, col) {
  ctx.save(); ctx.beginPath(); ctx.arc(cx, cy, r, 0, 6.3); const g = ctx.createRadialGradient(cx, cy - r * .3, 4, cx, cy, r); g.addColorStop(0, hexA(col, .45)); g.addColorStop(1, 'rgba(10,8,24,.95)'); ctx.fillStyle = g; ctx.fill(); ctx.clip();
  if (SPR[key]) { ctx.imageSmoothingEnabled = true; ctx.drawImage(SPR[key], cx - r * 1.1, cy - r * 1.05, r * 2.2, r * 2.2); }
  ctx.restore(); ctx.save(); ctx.beginPath(); ctx.arc(cx, cy, r, 0, 6.3); ctx.strokeStyle = col; ctx.lineWidth = 2.5; ctx.shadowColor = col; ctx.shadowBlur = 12; ctx.stroke(); ctx.restore();
}
function whoOf(id) { if (id === 'BOSS') return { n: boss ? boss.name : '', c: WORLDS[curWorld].c, pt: null }; return WHO[id] || WHO.NARR; }
function bossPortraitKey() { if (boss && boss.skin) return boss.skin; const P = ['frog_boss_idle_s4', 'boss_ship', 'WZ_idle_s2', 'eye_s2', 'skel_idle_s2', 'hound_ice_s2', 'demon_idle', 'pt_sombrio', 'boss_lev', 'boss_sph', 'boss_ser', 'pt_devo']; return P[boss ? boss.type : 0]; }
function drawDialogBox(line, shown, y, tapHint) {
  const w = whoOf(line[0]), x0 = Math.round((W - 760) / 2), text = line[1].slice(0, Math.floor(shown));
  const hasP = w.pt || line[0] === 'BOSS';
  glass(x0, y, 760, 96, 18, w.c, true);
  if (hasP) {
    const key = line[0] === 'BOSS' ? bossPortraitKey() : w.pt;
    if (line[0] === 'BOSS' && SPR[key]) { ctx.save(); ctx.beginPath(); ctx.arc(x0 + 54, y + 48, 38, 0, 6.3); ctx.fillStyle = 'rgba(10,8,24,.95)'; ctx.fill(); ctx.clip(); const m = meta(key), s = Math.min(2.4 * 38 / m.fh, 2.4 * 38 / m.fw); ctx.imageSmoothingEnabled = false; ctx.drawImage(SPR[key], 0, 0, m.fw, m.fh, x0 + 54 - m.fw * s / 2, y + 52 - m.fh * s / 2, m.fw * s, m.fh * s); ctx.restore(); ctx.beginPath(); ctx.arc(x0 + 54, y + 48, 38, 0, 6.3); ctx.strokeStyle = w.c; ctx.lineWidth = 2.5; ctx.stroke(); }
    else portrait(key, x0 + 54, y + 48, 38, w.c);
  }
  const tx = hasP ? x0 + 106 : x0 + 30;
  if (w.n) shadowTxt(w.n, tx, y + 20, 13, w.c, 'left', LOGOF, 800);
  const lines = wrapText(text, hasP ? 620 : 700, 16);
  lines.slice(0, 3).forEach((l, i) => txt(l, tx, y + (w.n ? 44 : 32) + i * 21, 16, line[0] === 'NARR' ? '#fff3d6' : '#ffffff', null, 0, 'left', UIF, line[0] === 'NARR' ? 500 : 600));
  if (tapHint && shown >= line[1].length) { ctx.globalAlpha = .5 + Math.sin(time * 5) * .4; ctx.save(); ctx.translate(x0 + 735, y + 78); ctx.rotate(Math.PI / 2); icon('right', 0, 0, 12, '#ffffff'); ctx.restore(); ctx.globalAlpha = 1; }
}
function drawCut() {
  ctx.setTransform(RES, 0, 0, RES, 0, 0);
  ctx.fillStyle = '#000'; ctx.fillRect(0, 0, W, H);
  if (!cut) return;
  const s = cut.sc[Math.min(cut.i, cut.sc.length - 1)], im = SPR[s.img];
  if (im && im.width) {
    const k = clamp(cut.t / 12, 0, 1), pz = s.pan, z = lerp(pz[2], pz[3], k), iw = W * z * 1.02, ih = iw * im.height / im.width;
    const ox = (W - iw) * (pz[0] + (1 - pz[0] * 2) * k * 0.5), oy = (H - ih) * (0.5 + (pz[1] - 0.05) * (k - 0.5));
    ctx.imageSmoothingEnabled = true; ctx.drawImage(im, ox, Math.min(0, oy), iw, Math.max(ih, H));
  }
  const g = ctx.createLinearGradient(0, H * .45, 0, H); g.addColorStop(0, 'rgba(0,0,0,0)'); g.addColorStop(1, 'rgba(0,0,0,.85)'); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  ctx.fillStyle = '#000'; ctx.fillRect(0, 0, W, 26); ctx.fillRect(0, H - 14, W, 14);
  const line = s.lines[cut.li]; if (line) drawDialogBox(line, cut.shown, H - 128, true);
  if (cut.fadeIn > 0) { ctx.fillStyle = 'rgba(0,0,0,' + cut.fadeIn + ')'; ctx.fillRect(0, 0, W, H); }
  // botón saltar
  pill(W - 132, 34, 112, 30, 'rgba(20,18,44,.75)'); txt('SALTAR ▶▶', W - 76, 49.5, 12, 'rgba(255,255,255,.85)', null, 0, 'center', UIF, 800);
}
function drawDlgHUD() {
  if (!dlg) return;
  const l = dlg.lines[dlg.i]; if (!l) return;
  drawDialogBox(l, dlg.shown, dlg.hold ? 92 : 104, dlg.hold);
}
// Pantalla de fragmento recuperado (recuerdos de Lyra)
let frag = null;
function startFragment(w) {
  frag = { w, lines: FRAGL[w] || [], i: 0, shown: 0, t: 0 };
  state = 'fragment'; fade = 1; playMusic('menu');
}
function fragAdvance() {
  if (!frag) return;
  const l = frag.lines[frag.i];
  if (l && frag.shown < l[1].length) { frag.shown = l[1].length; return; }
  frag.i++; frag.shown = 0; sfx('click', .5);
  if (frag.i >= frag.lines.length) finishFragment();
}
function finishFragment() {
  const w = frag.w; frag = null;
  if (w === 7) playCut('mid', () => { state = 'clear'; fade = 1; });
  else if (w === 11) playCut('ending', () => { state = 'victory'; fade = 1; SAVE.done = 1; persist(); sfx('v_youwin'); sfx('win', .8); });
  else { state = 'clear'; fade = 1; }
}
function drawFragment() {
  ctx.setTransform(RES, 0, 0, RES, 0, 0);
  ctx.fillStyle = '#05040e'; ctx.fillRect(0, 0, W, H);
  if (!frag) return;
  frag.t += 1 / 60;
  const pb = SPR['pbg' + frag.w]; if (pb && pb.width) { ctx.globalAlpha = .45; ctx.imageSmoothingEnabled = true; ctx.drawImage(pb, (W - pb.width * H / pb.height) / 2, 0, pb.width * H / pb.height, H); ctx.globalAlpha = 1; }
  const g = ctx.createRadialGradient(W / 2, 200, 10, W / 2, 200, 420); g.addColorStop(0, 'rgba(255,220,140,.25)'); g.addColorStop(1, 'rgba(5,4,14,.9)'); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  // fragmento girando
  const cx = W / 2, cy = 150, r = 34 + Math.sin(frag.t * 3) * 3;
  ctx.save(); ctx.translate(cx, cy); ctx.rotate(frag.t * .8); ctx.shadowColor = '#ffd34d'; ctx.shadowBlur = 40;
  ctx.beginPath(); for (let i = 0; i < 6; i++) { const a = i / 6 * 6.283; ctx.lineTo(Math.cos(a) * r * (i % 2 ? .6 : 1), Math.sin(a) * r * (i % 2 ? .6 : 1)); } ctx.closePath();
  const fg = ctx.createLinearGradient(-r, -r, r, r); fg.addColorStop(0, '#fff6c8'); fg.addColorStop(1, '#ffb030'); ctx.fillStyle = fg; ctx.fill(); ctx.restore();
  for (let i = 0; i < 14; i++) { const a = i / 14 * 6.283 - Math.PI / 2, on = i <= WPOS(frag.w); ctx.beginPath(); ctx.arc(cx + Math.cos(a) * 70, cy + Math.sin(a) * 70, on ? 5 : 3, 0, 6.3); ctx.fillStyle = on ? '#ffd34d' : 'rgba(255,255,255,.2)'; ctx.fill(); }
  ctx.save(); ctx.shadowColor = 'rgba(255,211,77,.8)'; ctx.shadowBlur = 20; txt('FRAGMENTO ' + (frag.w + 1) + ' / 12', W / 2, 252, 30, '#ffffff', null, 0, 'center', LOGOF, 900); ctx.restore();
  txt('Recuperado de ' + WORLDS[frag.w].name, W / 2, 284, 14, 'rgba(255,255,255,.7)', null, 0, 'center', UIF, 600);
  const l = frag.lines[frag.i];
  if (l) { frag.shown = Math.min(l[1].length, frag.shown + 0.8); drawDialogBox(l, frag.shown, 330, true); }
  else txt('Toca para continuar', W / 2, 380, 14, 'rgba(255,255,255,.6)', null, 0, 'center', UIF, 600);
}

// ---------------- Taller de Tic ----------------
function bank() { return SAVE.bank || 0; }
function buyUp(u) {
  const lv = UP(u.k); if (lv >= u.cost.length) return;
  const c = u.cost[lv]; if (bank() < c) { sfx('clang', .5); return; }
  SAVE.bank = bank() - c; SAVE.up = SAVE.up || {}; SAVE.up[u.k] = lv + 1; persist(); sfx('relic', .8); flash = 0.15; flashCol = '255,220,120';
}
function drawShop() {
  ctx.fillStyle = 'rgba(6,4,16,.72)'; ctx.fillRect(0, 0, W, H);
  const ox = Math.round((W - 960) / 2);
  ctx.save(); ctx.translate(ox, 0);
  glass(120, 30, 720, 486, 24, '#ffc861', true);
  portrait('pt_tic', 178, 86, 36, '#ffc861');
  ctx.save(); ctx.shadowColor = 'rgba(255,200,100,.7)'; ctx.shadowBlur = 18; txt('TALLER DE TIC', 230, 74, 24, '#ffffff', null, 0, 'left', LOGOF, 900); ctx.restore();
  txt('«Dame gemas y te ajusto los engranajes. Sin garantía.»', 230, 102, 13, '#ffe7b0', null, 0, 'left', UIF, 500);
  const gm = META.gem; ctx.drawImage(SPR.gem, 0, 0, gm.fw, gm.fh, 690, 66, gm.fw * 2, gm.fh * 2); txt(bank() + '', 726, 80, 22, '#ffffff', null, 0, 'left', UIF, 800);
  UPG.forEach((u, i) => {
    const y = 140 + i * 66, lv = UP(u.k), max = lv >= u.cost.length;
    rrect(146, y, 668, 56, 14); ctx.fillStyle = 'rgba(255,255,255,.04)'; ctx.fill();
    txt(u.n, 166, y + 18, 16, u.c, null, 0, 'left', UIF, 800); txt(u.d, 166, y + 39, 12, 'rgba(255,255,255,.7)', null, 0, 'left', UIF, 500);
    for (let j = 0; j < u.cost.length; j++) { ctx.beginPath(); ctx.arc(480 + j * 18, y + 28, 6, 0, 6.3); ctx.fillStyle = j < lv ? u.c : 'rgba(255,255,255,.15)'; ctx.fill(); }
  });
  ctx.restore();
  for (const b of uiButtons()) drawButton(b);
}

// ---------------- Mapa de 12 mundos (2 páginas) ----------------
let mapPage = 0;
function mapCard(w) { const ox = Math.round((W - 960) / 2), i = w % 6; return { x: ox + 24 + (i % 3) * 306, y: 72 + Math.floor(i / 3) * 222 }; }
function drawMap2() {
  const g0 = ctx.createLinearGradient(0, 0, 0, H); g0.addColorStop(0, 'rgba(8,6,24,.84)'); g0.addColorStop(1, 'rgba(8,6,24,.72)'); ctx.fillStyle = g0; ctx.fillRect(0, 0, W, H);
  ctx.save(); ctx.shadowColor = 'rgba(80,200,255,.7)'; ctx.shadowBlur = 18; txt('MAPA DEL TIEMPO', W / 2 - 120, 36, 22, '#ffffff', null, 0, 'center', LOGOF, 900); ctx.restore();
  let frags = 0; for (let w = 0; w < WORLDS.length; w++) { const st = SAVE.st[sIdx(w, 2)]; if (st && st.done) frags++; }
  txt('◈ ' + frags + '/' + WORLDS.length + ' fragmentos', W / 2 - 120, 58, 11, '#ffd34d', null, 0, 'center', UIF, 700);
  for (let pos = mapPage * 6; pos < Math.min(ORDER.length, mapPage * 6 + 6); pos++) {
    const w = ORDER[pos], WD = WORLDS[w], { x: cx, y: cy } = mapCard(pos), lock = sIdx(w, 0) > SAVE.unl;
    glass(cx, cy, 290, 208, 18, lock ? null : WD.c, true);
    ctx.save(); rrect(cx + 8, cy + 8, 274, 112, 12); ctx.clip(); ctx.globalAlpha = lock ? 0.22 : 1; ctx.imageSmoothingEnabled = true;
    const th = SPR['pbg' + w]; if (th && th.width) { const s = 112 / th.height * 1.25; ctx.drawImage(th, cx + 8 + 137 - th.width * s * 0.5 + Math.sin(time * .2 + w) * 20, cy + 8 - 14, th.width * s, th.height * s); }
    const bk = bossPortraitKeyW(w); if (bk && SPR[bk]) { const m = meta(bk), sc = Math.min(78 / m.fh, 120 / m.fw, w === 0 ? 0.6 : 3); ctx.imageSmoothingEnabled = false; ctx.drawImage(SPR[bk], 0, 0, m.fw, m.fh, Math.round(cx + 210 - m.fw * sc / 2), Math.round(cy + 116 - m.fh * sc), m.fw * sc, m.fh * sc); }
    const gg = ctx.createLinearGradient(0, cy + 60, 0, cy + 120); gg.addColorStop(0, 'rgba(0,0,0,0)'); gg.addColorStop(1, 'rgba(0,0,0,.55)'); ctx.fillStyle = gg; ctx.fillRect(cx + 8, cy + 8, 274, 112);
    ctx.restore();
    ctx.strokeStyle = 'rgba(255,255,255,.18)'; ctx.lineWidth = 1; rrect(cx + 8, cy + 8, 274, 112, 12); ctx.stroke();
    if (lock) icon('lock', cx + 145, cy + 62, 30, 'rgba(255,255,255,.7)');
    txt('MUNDO ' + (WPOS(w) + 1), cx + 16, cy + 104, 11, lock ? 'rgba(255,255,255,.3)' : WD.c, null, 0, 'left', UIF, 900);
    txt(WD.name, cx + 16, cy + 136, 14, lock ? 'rgba(255,255,255,.35)' : '#ffffff', null, 0, 'left', UIF, 800);
    if (!lock) {
      let gems = 0, tot = 0, rel = 0;
      for (let a = 0; a < 3; a++) { const st = SAVE.st[sIdx(w, a)]; if (st) { gems += st.gems; tot += st.total; rel += st.relic ? 1 : 0; } }
      txt(tot ? ('◆ ' + gems + '/' + tot + '   ⌛ ' + rel + '/3') : WD.sub, cx + 16, cy + 154, 10, tot ? '#ffe27a' : 'rgba(255,255,255,.55)', null, 0, 'left', UIF, 600);
      if (SAVE.st[sIdx(w, 2)] && SAVE.st[sIdx(w, 2)].done) { ctx.save(); ctx.translate(cx + 266, cy + 136); ctx.rotate(time); ctx.fillStyle = '#ffd34d'; ctx.beginPath(); for (let i = 0; i < 6; i++) { const a = i / 6 * 6.283; ctx.lineTo(Math.cos(a) * (i % 2 ? 5 : 9), Math.sin(a) * (i % 2 ? 5 : 9)); } ctx.fill(); ctx.restore(); }
    }
  }
  for (const b of uiButtons()) drawButton(b);
}
function bossPortraitKeyW(w) { const P = ['frog_boss_idle', 'boss_ship', 'WZ_idle_s2', 'eye_s2', 'skel_idle_s2', 'hound_ice_s2', 'demon_idle', 'S_idle', 'boss_lev', 'boss_sph', 'boss_ser', 'boss_devo', 'boss_witch', 'boss_king', 'boss_golemc', 'boss_stag', 'boss_archi', 'boss_dragon']; return P[w]; }
function mapButtons(B) {
  B.push({ x: 18, y: 16, w: 118, h: 40, t: 'VOLVER', ic: 'left', c: '#35e2ff', fn: toTitle });
  B.push({ x: W - 506, y: 18, w: 126, h: 36, t: 'TALLER', ic: 'time', c: '#ffc861', small: true, fn: () => { state = 'shop'; } });
  DIFFS.forEach((d, i) => B.push({ x: W - 368 + i * 118, y: 18, w: 110, h: 36, t: d.name, c: d.c, sel: diffIdx === i, small: true, seg: true, fn: () => { diffIdx = i; } }));
  const ox = Math.round((W - 960) / 2);
  B.push({ x: Math.max(4, ox - 40), y: 250, w: 40, h: 60, t: '', ic: 'left', c: '#35e2ff', lock: mapPage === 0, fn: () => { if (mapPage > 0) mapPage--; } });
  B.push({ x: Math.min(W - 44, ox + 960), y: 250, w: 40, h: 60, t: '', ic: 'right', c: '#35e2ff', lock: mapPage === 2, fn: () => { if (mapPage < 2) mapPage++; } });
  for (let pos = mapPage * 6; pos < Math.min(ORDER.length, mapPage * 6 + 6); pos++) {
    const w = ORDER[pos], { x: cx, y: cy } = mapCard(pos);
    for (let a = 0; a < 3; a++) {
      const s = sIdx(w, a), lock = s > SAVE.unl;
      B.push({ x: cx + 8 + a * 92, y: cy + 166, w: 86, h: 32, t: a === 2 ? 'JEFE' : 'FASE ' + (a + 1), ic: lock ? 'lock' : a === 2 ? 'skull' : 'flag', c: WORLDS[w].c, sel: !lock && s === SAVE.unl, lock, small: true, stage: s, fn: lock ? () => sfx('clang', .4) : () => beginStage(w, a) });
    }
  }
}
function beginStage(w, a) {
  if (w === 0 && a === 0 && !SAVE.intro) { playCut('intro', () => { SAVE.intro = 1; persist(); startStage(0, 0, true); }); return; }
  startStage(w, a, true);
}
