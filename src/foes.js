// =====================================================================
//  ENEMIGOS CON COMPORTAMIENTOS PROPIOS POR MUNDO (v2.1)
//  Reutilizan el arte que ya existe; cambia cómo se mueven y atacan.
//  Todos avisan antes de atacar (dificultad justa).
// =====================================================================
const FOE_HINT = {
  rammer: 'Ese sabueso se agacha antes de embestir. Salta por encima y golpéalo mientras se recupera.',
  sniper: 'Torreta con mira: cuando veas la línea roja, ¡muévete!',
  dropper: 'Mira la sombra en el suelo: ahí va a caer lo que suelte.',
  burrower: 'Algo se mueve bajo la arena. Cuando tiemble el suelo, ¡salta!',
  ambusher: 'Ojo: aquí no todo lo que parece decorado lo es.',
  reviver: 'Estos huesos se recomponen. Remátalos en la dimensión violeta (SHIFT) y no volverán.',
  book: 'Los libros de aquí muerden. Un golpe y se cierran para siempre.',
  strike: 'Si ves una columna de luz en el suelo, apártate: el rayo cae justo ahí.',
  pulse: 'Las medusas brillan antes de soltar una descarga. Espera a que se apaguen.',
  splitter: 'Las ratas de fuego se parten en dos al morir. No te confíes.',
  spread: 'Los serafines disparan en abanico. Esquiva por arriba o por abajo.'
};
ENEMY.book = { b: 'book', anim: 'pr16_5', w: 26, h: 20, hp: 1, face: 1, death: 'poof' };
let strikes = [], strikeT = 4, foeHinted = {};
function foeHint(k, x) {
  SAVE.fh = SAVE.fh || {};
  if (SAVE.fh[k] || foeHinted[k] || ticSay || dlg) return;
  if (x !== undefined && Math.abs(x - (p.x + p.w / 2)) > 420) return;
  foeHinted[k] = 1; SAVE.fh[k] = 1; try { persist(); } catch (e) {} tSay(FOE_HINT[k], 4);
}
// qué variantes aparecen en cada mundo: [id original, variante, probabilidad]
const FOE_PLAN = {
  1: [['cyhound', 'rammer', .7], ['turret', 'sniper', .7]],
  2: [['firerat', 'splitter', .8]],
  3: [['mushroom', 'ambusher', .7], ['eye', 'dropper', .35]],
  4: [['hound', 'rammer', .6], ['gskel', 'reviver', .6]],
  5: [['icehound', 'rammer', .7], ['iceeye', 'dropper', .7]],
  6: [['infhound', 'rammer', .7], ['infworm', 'splitter', 0]],
  7: [['goldeye', 'dropper', .5], ['shieldskel', 'reviver', 0]],
  8: [['jelly', 'pulse', .7]],
  9: [['scarab', 'burrower', .7], ['vulture', 'dropper', .6]],
  10: [['seraph', 'spread', .7], ['golem', 'ambusher', .3]],
  11: [['jelly', 'pulse', .6], ['seraph', 'spread', .6]],
  12: [['mushroom', 'ambusher', .8], ['gskel', 'reviver', .5]],
  13: [['hound', 'rammer', .6], ['gskel', 'reviver', .6]],
  14: [['golem', 'ambusher', .7], ['iceeye', 'dropper', .5]],
  15: [['gskel', 'reviver', .8], ['hound', 'rammer', .6]],
  16: [['ghost', 'book', .6], ['eye', 'book', .8], ['gskel', 'reviver', .5]],
  17: [['eye', 'dropper', .35], ['seraph', 'spread', .6]]
};
function foeGround(e) { const g = groundBelow(e.x + e.w / 2, e.y + e.h, 40); return g ? g.y : e.y + e.h; }
const _buildStageF = buildStage;
buildStage = function (wi, act) {
  const L = _buildStageF(wi, act), plan = FOE_PLAN[wi];
  if (!plan || (typeof TOWER_ON !== 'undefined' && TOWER_ON && !TOWER_TRIAL && false)) return L;
  const r = seeded(7777 + wi * 131 + act * 17);
  for (const e of L.enemies) {
    for (const [id, v, pr] of plan) {
      if (e.id !== id || r() >= pr) continue;
      e.v = v;
      if (v === 'rammer') { e.b = 'rammer'; e.st = 'walk'; }
      else if (v === 'sniper') { e.b = 'sniper'; e.st = 'idle'; e.cd = 1.5 + r(); }
      else if (v === 'dropper') { e.b = 'dropper'; e.st = 'hover'; e.cd = 1 + r(); }
      else if (v === 'burrower') { e.b = 'burrower'; e.st = 'under'; e.gy = e.y + e.h; e.cd = 1.2; }
      else if (v === 'ambusher') { e.b0 = e.b; e.b = 'dormant'; e.st = 'dormant'; }
      else if (v === 'book') { const d = ENEMY.book; Object.assign(e, { id: 'book', d, b: 'book', w: d.w, h: d.h, hp: 1, st: 'idle', y0: e.y, x0: e.x }); }
      // reviver, pulse, splitter y spread conservan su movimiento original
      break;
    }
  }
  return L;
};
// enemigos que no se pueden golpear mientras están escondidos
const _hittableF = enemyHittable;
enemyHittable = function (e) {
  if (e.b === 'burrower' && (e.st === 'under' || e.st === 'tele')) return false;
  if (e.b === 'dormant' || e.b === 'revive') return false;
  return _hittableF(e);
};
// muertes especiales: se recomponen o se parten
const _damageF = damageEnemy;
damageEnemy = function (e, hb) {
  _damageF(e, hb);
  if (!e.dead) { if (e.b === 'rammer' && e.st === 'aim') { e.st = 'stun'; e.tt = 0.6; } return; }
  if (e.v === 'reviver' && !e.revived) {
    if (dim === 1) { addFloat(e.x + e.w / 2, e.y - 14, '¡DESTRUIDO!', '#d8a0ff', 13); return; }
    e.dead = false; e.revived = true; e.b0 = 'riser'; e.b = 'revive'; e.tt = 2.2; e.hp = e.d.hp; e.gy = e.y + e.h;
    addFloat(e.x + e.w / 2, e.y - 14, 'SE RECOMPONE…', '#e8dcc0', 13); foeHint('reviver');
  } else if (e.v === 'splitter' && !e.mini) {
    foeHint('splitter');
    for (const s of [-1, 1]) { const m = Object.assign({}, e, { dead: false, mini: true, v: 'mini', b: 'walker', hp: 1, w: 20, h: 14, x: e.x + e.w / 2 - 10 + s * 8, y: e.y + e.h - 14, dir: s, minX: e.x - 120, maxX: e.x + 120, kx: s * 180, hit: 0.2, t: Math.random() * 3 }); level.enemies.push(m); try { p.hitSet.add(m); } catch (er) {} }
  }
};
// abanico de disparos
const _shootF = shoot;
shoot = function (e, kind, tx, ty, sp) {
  const n0 = projs.length; _shootF(e, kind, tx, ty, sp);
  if (e.v === 'spread' && projs.length > n0) {
    const q = projs[projs.length - 1], a = Math.atan2(q.vy, q.vx), v = Math.hypot(q.vx, q.vy);
    for (const da of [-0.32, 0.32]) projs.push(Object.assign({}, q, { vx: Math.cos(a + da) * v, vy: Math.sin(a + da) * v }));
    foeHint('spread', e.x);
  }
};
const _updEnemiesF = updateEnemies;
updateEnemies = function (dt) {
  _updEnemiesF(dt);
  const D = DIFFS[diffIdx], pcx = p.x + p.w / 2, pcy = p.y + p.h / 2;
  for (const e of level.enemies) {
    if (e.dead || !e.v) continue;
    if (Math.abs(e.x - cam.x - VW / 2) > 900) continue;
    const cx = e.x + e.w / 2, dx = pcx - cx, dy = pcy - (e.y + e.h / 2), adx = Math.abs(dx), d = e.d;
    if (e.b === 'rammer') {
      if (e.st === 'walk') {
        if (e.hit <= 0) { const nx = e.x + e.dir * (d.spd || 70) * D.spd * dt, fx_ = e.dir > 0 ? nx + e.w + 2 : nx - 2; if (groundBelow(fx_, e.y + e.h, 14) && nx > e.minX && nx < e.maxX) e.x = nx; else e.dir *= -1; }
        e.cd = (e.cd || 0) - dt;
        if (adx < 320 && Math.abs(dy) < 60 && e.cd <= 0 && !p.dead) { e.dir = dx > 0 ? 1 : -1; e.st = 'aim'; e.tt = 0.65 / Math.max(.7, D.aggr); e.alert = e.tt; sfx('roar', .35, 1.4); foeHint('rammer', cx); }
      } else if (e.st === 'aim') {
        e.tt -= dt; if (Math.random() < .5) dust(cx - e.dir * 12, e.y + e.h, 1, -e.dir);
        if (e.tt <= 0) { e.st = 'run'; e.run = 0; sfx('dash', .35, 1.2); }
      } else if (e.st === 'run') {
        const sp = (curWorld === 5 ? 480 : 400) * D.spd, nx = e.x + e.dir * sp * dt, fx_ = e.dir > 0 ? nx + e.w + 2 : nx - 2;
        e.run += sp * dt;
        let wall = false; for (const s of level.plats) if (s.k === 'solid' && !s.float && overlap({ x: nx, y: e.y + 2, w: e.w, h: e.h - 6 }, s)) { wall = true; break; }
        if (!groundBelow(fx_, e.y + e.h, 14) || wall || e.run > (curWorld === 5 ? 520 : 380)) { e.st = 'stun'; e.tt = 1.1; if (wall) { shake = Math.max(shake, 4); sfx('stomp', .4); } }
        else { e.x = nx; if (Math.random() < .6) dust(cx - e.dir * 14, e.y + e.h, 1, -e.dir); }
        if ((e.id === 'infhound' || curWorld === 6) && (e.trail = (e.trail || 0) + sp * dt) > 34) { e.trail = 0; projs.push({ x: cx - e.dir * 16, y: e.y + e.h - 8, vx: 0, vy: 0, hw: 6, hh: 6, type: 'fire', dmg: 8, life: 1.1 }); }
      } else if (e.st === 'stun') { e.tt -= dt; if (e.tt <= 0) { e.st = 'walk'; e.cd = 1.2; } }
    } else if (e.b === 'sniper') {
      e.dir = dx > 0 ? 1 : -1;
      if (e.st === 'idle') { e.cd -= dt; if (e.cd <= 0 && Math.hypot(dx, dy) < 540 && !p.dead) { e.st = 'aim'; e.tt = 1.15 / Math.max(.7, D.aggr); sfx('alert', .3, 1.4); foeHint('sniper', cx); } }
      else if (e.st === 'aim') {
        e.tt -= dt; if (e.tt > 0.35) { e.tx = pcx; e.ty = pcy; }
        if (e.tt <= 0) {
          const ox = cx + e.dir * 10, oy = e.y + 8, ddx = e.tx - ox, ddy = e.ty - oy, dd = Math.hypot(ddx, ddy) || 1, v = 720 * D.spd;
          projs.push({ x: ox, y: oy, vx: ddx / dd * v, vy: ddy / dd * v, hw: 6, hh: 4, type: 'bolt', dmg: 14, life: 2 });
          sfx('shoot', .45, .8); e.fire = 0.4; e.st = 'idle'; e.cd = rnd(2, 2.8) / D.aggr;
        }
      }
    } else if (e.b === 'dropper') {
      if (e.y0 === undefined) e.y0 = e.y;
      if (e.st === 'hover') {
        const tx = clamp(pcx, e.x0 - 260, e.x0 + 260) - e.w / 2; e.x += clamp(tx - e.x, -1, 1) * 95 * D.spd * dt; e.y = e.y0 + Math.sin(e.t * 2) * 8; e.dir = dx > 0 ? 1 : -1;
        e.cd -= dt;
        if (e.cd <= 0 && adx < 24 && pcy > e.y && !p.dead) { e.st = 'drop'; e.tt = 0.55; e.alert = 0.55; foeHint('dropper', cx); }
      } else if (e.st === 'drop') {
        e.tt -= dt; e.x += Math.sin(e.t * 50) * .4;
        if (e.tt <= 0) {
          const kind = curWorld === 5 || curWorld === 14 ? 'icicle' : curWorld === 9 ? 'sandblock' : 'orb';
          projs.push({ x: cx, y: e.y + e.h, vx: 0, vy: 60, grav: 900, hw: kind === 'sandblock' ? 9 : 5, hh: 8, type: kind, dmg: 14, life: 3 });
          sfx(kind === 'icicle' ? 'ice' : 'swing', .4); e.st = 'hover'; e.cd = rnd(1.8, 2.6) / D.aggr;
        }
      }
    } else if (e.b === 'burrower') {
      if (e.st === 'under') {
        e.y = e.gy + 60; e.dir = dx > 0 ? 1 : -1;
        const nx = e.x + e.dir * 105 * D.spd * dt; if (groundBelow(nx + e.w / 2, e.gy, 8) && nx > e.minX - 200 && nx < e.maxX + 200) e.x = nx;
        if (Math.random() < .35) parts.push({ x: cx + rnd(-8, 8), y: e.gy - 2, vx: rnd(-30, 30), vy: rnd(-90, -30), life: .4, max: .4, c: Math.random() < .5 ? '#e0b060' : '#8a6a30', s: 2, g: 400 });
        e.cd -= dt; if (e.cd <= 0 && adx < 26 && Math.abs(pcy - e.gy) < 90 && !p.dead) { e.st = 'tele'; e.tt = 0.6; sfx('crumble', .45); foeHint('burrower', cx); }
      } else if (e.st === 'tele') {
        e.tt -= dt; if (Math.random() < .8) parts.push({ x: cx + rnd(-14, 14), y: e.gy - 2, vx: rnd(-50, 50), vy: rnd(-200, -80), life: .5, max: .5, c: '#e0b060', s: 3, g: 500 });
        if (e.tt <= 0) { e.st = 'up'; e.y = e.gy - e.h; e.vy = -420; shake = Math.max(shake, 4); sfx('stomp', .5); burst(cx, e.gy, '#e0b060', 16, 180, 500, .6, 3); }
      } else if (e.st === 'up') {
        e.vy += 1400 * dt; e.y += e.vy * dt; if (e.y + e.h >= e.gy) { e.y = e.gy - e.h; e.st = 'surface'; e.tt = 2.6; }
      } else if (e.st === 'surface') {
        e.tt -= dt; e.dir = dx > 0 ? 1 : -1;
        if (e.tt <= 0) { e.st = 'under'; e.cd = 1.4; burst(cx, e.gy, '#e0b060', 10, 120, 400, .5, 2); }
      }
    } else if (e.b === 'dormant') {
      if (adx < 115 && Math.abs(dy) < 90) {
        e.b = e.b0; e.st = 0; e.cd = 0.2; e.alert = 0.4; foeHint('ambusher', cx);
        burst(cx, e.y + e.h / 2, curWorld === 14 ? '#c48cff' : '#c070a0', 18, 200, 300, .6, 3); sfx(curWorld === 14 ? 'ice' : 'crumble', .5);
        if (e.b === 'shooter') for (const vx of [-150, 0, 150]) projs.push({ x: cx, y: e.y + 6, vx: vx * D.spd, vy: -330, grav: 700, hw: 6, hh: 6, type: 'spore', dmg: 12, life: 3 });
      }
    } else if (e.b === 'revive') {
      e.tt -= dt; e.y = e.gy + 80;
      if (e.tt <= 0) { e.b = 'riser'; e.st = 'buried'; e.y = e.gy - e.h; }
    } else if (e.b === 'book') {
      if (e.st === 'idle') { e.x = e.x0 + Math.sin(e.t * 1.3) * 20; e.y = e.y0 + Math.sin(e.t * 2.6) * 10; if (Math.hypot(dx, dy) < 300 && !p.dead) { e.st = 'chase'; e.tt = 4; e.vx = 0; e.vy = 0; sfx('swing', .3, 1.6); foeHint('book', cx); } }
      else if (e.st === 'chase') {
        const dd = Math.hypot(dx, dy) || 1; e.vx += dx / dd * 300 * dt; e.vy += dy / dd * 300 * dt; const v = Math.hypot(e.vx, e.vy), mx = 150 * D.spd; if (v > mx) { e.vx *= mx / v; e.vy *= mx / v; }
        e.x += e.vx * dt; e.y += e.vy * dt + Math.sin(e.t * 14) * 0.6; e.dir = e.vx > 0 ? 1 : -1; e.tt -= dt;
        if (e.tt <= 0 || Math.hypot(e.x - e.x0, e.y - e.y0) > 700) { e.st = 'rest'; e.tt = 1.2; }
      } else if (e.st === 'rest') { e.tt -= dt; e.vx *= 0.95; e.vy *= 0.95; e.x += e.vx * dt; e.y += e.vy * dt; if (e.tt <= 0) e.st = 'chase', e.tt = 3; }
    }
    if (e.v === 'pulse') {
      e.pc = (e.pc === undefined ? 1.5 + Math.random() * 2 : e.pc) - dt;
      if (e.pc <= 0 && !e.pq && Math.hypot(dx, dy) < 260) { e.pq = 0.8; sfx('alert', .2, 1.8); foeHint('pulse', cx); }
      if (e.pq) { e.pq -= dt; if (e.pq <= 0) { e.pq = 0; e.pc = 3.4 / D.aggr; e.pr = 0.35; sfx('shield', .4, 1.5); if (Math.hypot(dx, dy) < 66 && !p.dead) hurt(12, cx); } }
      if (e.pr) e.pr = Math.max(0, e.pr - dt);
    }
  }
  // rayos con aviso en la Torre de las Tormentas
  if (curWorld === 17 && !arenaLock && !boss && !p.dead && !(typeof TOWER !== 'undefined' && TOWER)) {
    strikeT -= dt;
    if (strikeT <= 0 && !dlg) {
      strikeT = rnd(3.6, 6) / D.aggr; const x = pcx + p.vx * 0.55, g = groundBelow(x, p.y, 600);
      if (g) { strikes.push({ x, gy: g.y, t: 1.1, hit: 0 }); sfx('wind', .25, 1.4); foeHint('strike'); }
    }
  }
  for (let i = strikes.length - 1; i >= 0; i--) {
    const s = strikes[i]; s.t -= dt;
    if (s.t <= 0 && !s.hit) {
      s.hit = 0.25; flash = Math.max(flash, 0.18); flashCol = '200,220,255'; shake = Math.max(shake, 6); sfx('boom', .5, 1.3);
      burst(s.x, s.gy, '#cfe0ff', 18, 240, 300, .5, 2);
      if (Math.abs(pcx - s.x) < 22 && p.y < s.gy + 4) hurt(16, s.x);
    }
    if (s.hit) { s.hit -= dt; if (s.hit <= 0) strikes.splice(i, 1); }
  }
};
const _startStageF = startStage;
startStage = function (wi, act, fresh) { strikes = []; strikeT = 4; _startStageF(wi, act, fresh); };
// ---------------- dibujo ----------------
const _drawEnemyF = drawEnemy;
drawEnemy = function (e) {
  const cx = e.x + e.w / 2, by = e.y + e.h, d = e.d, flip = d.face === 0 ? false : (e.dir !== d.face), wh = e.hit > 0;
  if (e.b === 'burrower' && (e.st === 'under' || e.st === 'tele')) {
    bx.fillStyle = 'rgba(120,90,40,.55)'; const w = e.st === 'tele' ? 26 + Math.sin(time * 40) * 3 : 18; bx.fillRect(Math.round(cx - w / 2), e.gy - 3, Math.round(w), 3);
    if (e.st === 'tele') glowAt(cx, e.gy - 6, 30, 'rgba(255,200,90,.55)', .8);
    return;
  }
  if (e.b === 'revive') { bx.fillStyle = '#d8d0c0'; for (let i = 0; i < 4; i++) bx.fillRect(Math.round(cx - 10 + i * 6), e.gy - 3 - (i % 2) * 2, 4, 2); glowAt(cx, e.gy - 4, 16, 'rgba(255,240,200,.35)', .5 + Math.sin(time * 8) * .2); return; }
  if (e.b === 'dormant') {
    if (curWorld === 14 || curWorld === 10) { if (SPR.pr14_2 && SPR.pr14_2.width) spr('pr14_2', 0, cx, by + 1, false, 0.55); else _drawEnemyF(e); return; }
    bx.save(); bx.globalAlpha = 0.95; spr(d.anim, 0, cx, by + 1, flip, 1, false); bx.restore(); return;
  }
  if (e.b === 'book') {
    if (SPR.pr16_5 && SPR.pr16_5.width) { glowAt(cx, e.y + e.h / 2, 22, 'rgba(160,120,255,.45)', .6); bx.save(); bx.translate(Math.round(cx), Math.round(by)); bx.rotate(Math.sin(e.t * 12) * 0.12); spr('pr16_5', 0, 0, 0, e.dir < 0, 0.42, wh); bx.restore(); }
    else { bx.fillStyle = '#6a3a20'; bx.fillRect(Math.round(e.x), Math.round(e.y), e.w, e.h); }
    return;
  }
  if (e.mini) { spr(d.anim, Math.floor(e.t * 14), cx, by + 1, flip, 0.62, wh); return; }
  if (e.b === 'rammer' && e.st === 'aim') { bx.save(); bx.translate(Math.round(Math.sin(time * 60) * 1.5), 0); _drawEnemyF(e); bx.restore(); glowAt(cx, e.y + e.h / 2, 26, 'rgba(255,60,60,.55)', .8); return; }
  _drawEnemyF(e);
  if (e.b === 'rammer' && e.st === 'stun') for (let i = 0; i < 3; i++) { const a = time * 6 + i * 2.1; bx.fillStyle = '#ffe066'; bx.fillRect(Math.round(cx + Math.cos(a) * 12), Math.round(e.y - 6 + Math.sin(a) * 3), 2, 2); }
  if (e.v === 'pulse') {
    if (e.pq) glowAt(cx, e.y + e.h / 2, 26 + (0.8 - e.pq) * 40, 'rgba(120,240,255,.7)', .5 + (0.8 - e.pq));
    if (e.pr) { const r = 66 * (1 - e.pr / 0.35) + 10; bx.strokeStyle = 'rgba(170,250,255,' + (e.pr / 0.35) + ')'; bx.lineWidth = 3; bx.beginPath(); bx.arc(cx, e.y + e.h / 2, r, 0, 6.3); bx.stroke(); }
  }
};
const _drawProjsF = drawProjs;
drawProjs = function () {
  // mira de las torretas
  for (const e of level.enemies) if (!e.dead && e.b === 'sniper' && e.st === 'aim' && e.tx !== undefined && onScreen(e.x, e.w)) {
    const ox = e.x + e.w / 2 + e.dir * 10, oy = e.y + 8, lock = e.tt <= 0.35, a = lock ? .5 + .5 * Math.abs(Math.sin(time * 30)) : .35;
    bx.strokeStyle = 'rgba(255,40,70,' + a + ')'; bx.lineWidth = lock ? 2 : 1; bx.beginPath(); bx.moveTo(ox, oy);
    const dx = e.tx - ox, dy = e.ty - oy, dd = Math.hypot(dx, dy) || 1; bx.lineTo(ox + dx / dd * 600, oy + dy / dd * 600); bx.stroke();
    glowAt(ox, oy, 10, 'rgba(255,40,70,.8)', a);
  }
  // sombra de lo que va a caer
  for (const e of level.enemies) if (!e.dead && e.b === 'dropper' && onScreen(e.x, e.w)) {
    const g = groundBelow(e.x + e.w / 2, e.y + e.h, 500); if (!g) continue;
    const w = e.st === 'drop' ? 22 + Math.sin(time * 30) * 3 : 12; bx.fillStyle = e.st === 'drop' ? 'rgba(255,60,60,.5)' : 'rgba(0,0,0,.3)'; bx.fillRect(Math.round(e.x + e.w / 2 - w / 2), g.y - 2, Math.round(w), 2);
  }
  _drawProjsF();
  // rayos
  for (const s of strikes) {
    if (!s.hit) {
      const a = (0.25 + 0.5 * (1 - s.t / 1.1)) * (0.6 + 0.4 * Math.abs(Math.sin(time * 18)));
      bx.fillStyle = 'rgba(170,200,255,' + a * 0.45 + ')'; bx.fillRect(Math.round(s.x) - 14, cam.y, 28, s.gy - cam.y);
      bx.fillStyle = 'rgba(230,240,255,' + a * 0.6 + ')'; bx.fillRect(Math.round(s.x) - 2, cam.y, 4, s.gy - cam.y);
      glowAt(s.x, s.gy - 6, 34, 'rgba(180,210,255,.9)', a);
      bx.fillStyle = 'rgba(230,240,255,' + Math.min(1, a * 1.5) + ')'; bx.fillRect(Math.round(s.x) - 20, s.gy - 4, 40, 4);
    } else {
      glowAt(s.x, s.gy - 60, 70, 'rgba(180,210,255,.8)', 1);
      bx.fillStyle = '#ffffff'; let x = s.x, y = cam.y; bx.beginPath(); bx.moveTo(x, y);
      while (y < s.gy) { y += 24; x = s.x + Math.sin(y * 0.13 + s.gy) * 9; bx.lineTo(x, Math.min(y, s.gy)); }
      bx.lineWidth = 4; bx.strokeStyle = 'rgba(200,225,255,.9)'; bx.stroke(); bx.lineWidth = 1.5; bx.strokeStyle = '#ffffff'; bx.stroke();
    }
  }
};
// (las sombras de contacto las dibuja drawContactShadows en hdrender.js)
// ---------------- vida en las animaciones de los enemigos (v2.4) ----------------
// balanceo al andar, aplastamiento al recibir un golpe y al aterrizar; no cambia sus cajas de colisión
const SQ_B = { walker: 1, chaser: 1, rammer: 1, shield: 1, riser: 1, jumper: 1, bomber: 1, shooter: 1, burrower: 1 };
const _drawEnemyQ = drawEnemy;
drawEnemy = function (e) {
  if (!SQ_B[e.b] || e.d.stat || e.mini || (e.b === 'riser' && e.st !== 'walk') || (e.b === 'burrower' && e.st !== 'surface' && e.st !== 'up')) return _drawEnemyQ(e);
  const cx = e.x + e.w / 2, by = e.y + e.h;
  let sx = 1, sy = 1, oy = 0;
  const moving = e.b !== 'shooter' || !e.d.still;
  if (moving && !e.air && e.b !== 'jumper') { const ph = e.t * (e.b === 'rammer' && e.st === 'run' ? 22 : 11); oy = Math.abs(Math.sin(ph)) > 0.7 ? -1 : 0; }
  if (e.air) { sy = e.vy < 0 ? 1.1 : 0.96; sx = 1 / sy; }
  if (e.wasAir && !e.air) e.landT = 0.14; e.wasAir = !!e.air;
  if (e.landT > 0) { e.landT -= 1 / 60; const k = e.landT / 0.14; sy *= 1 - 0.2 * k; sx *= 1 + 0.16 * k; }
  if (e.hit > 0) { const k = e.hit / 0.15; sx *= 1 + 0.14 * k; sy *= 1 - 0.1 * k; }
  if (sx === 1 && sy === 1 && oy === 0) return _drawEnemyQ(e);
  bx.save(); bx.translate(cx, by + oy); bx.scale(sx, sy); bx.translate(-cx, -by); _drawEnemyQ(e); bx.restore();
};
