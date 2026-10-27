// =====================================================================
//  COMBATE CONTRA JEFES (v2.6)
//  1) Ya no se puede vencer a un jefe dándole espadazos desde arriba
//     sin parar: el golpe aéreo hace la mitad, tiene un respiro entre
//     golpes y al tercero seguido (o si te quedas encima) te sacude.
//  2) Cada jefe tiene su momento débil: ahí recibe daño crítico; fuera
//     de él, su armadura reduce mucho el daño. Hay que aprender su patrón.
//  3) Movimiento con vida: inclinación al correr, bote al andar,
//     estirarse al saltar, aplastarse al caer, tensión antes de atacar,
//     retroceso al recibir un golpe y tambaleo cuando está aturdido.
//  4) Dificultad progresiva del primer mundo al último.
// =====================================================================
const BOSS_HINT = {
  pogo: 'Saltarle encima sin parar no funciona: busca su momento débil.',
  hard: 'Así apenas le haces daño. Espera a que quede aturdido o expuesto.',
  crit: '¡Eso es! Ese es su punto débil.',
  stag: 'Es un espíritu: solo puedes herirlo desde la dimensión violeta (SHIFT).'
};
function bossHint(k) { SAVE.fh = SAVE.fh || {}; if (SAVE.fh['b_' + k] || ticSay) return; SAVE.fh['b_' + k] = 1; try { persist(); } catch (e) {} tSay(BOSS_HINT[k], 3.6); }
// multiplicador de daño según el estado del jefe (su momento débil)
function bossWeak(b) {
  const s = b.st;
  switch (b.type) {
    case 0: return s === 'idle' && b.t < 0.8 ? 1.7 : s === 'air' ? 0.3 : 1;             // sapo: justo después de caer
    case 1: return s === 'down' ? 1.8 : 0.3;                                            // gárgola: cuando cae al suelo
    case 2: return b.vulnT > 0 ? 1.3 : 0.8;                                               // hechicero: escudo de palancas
    case 3: return s === 'stun' ? 1.8 : 0.4;                                            // ojo: aturdido tras la embestida
    case 4: { const behind = (p.x + p.w / 2 - (b.x + b.w / 2)) * b.face < 0; return behind ? 1.4 : s === 'windup' ? 0.4 : 0.7; } // caballero: por la espalda
    case 5: return s === 'stagger' ? 1.8 : s === 'charge' ? 0.3 : 0.6;                 // bestia: aturdida contra la pared
    case 6: return s === 'rest' ? 1.8 : 0.3;                                            // demonio: cuando descansa en el suelo
    case 7: return s === 'recover' ? 1.7 : 0.6;                                           // Kael sombrío: tras su ataque
  }
  return 1;
}
bossHitRule = function (b) {
  if (b.type === 8) {
    if (b.skin === 'boss_king') { const behind = (p.x + p.w / 2 - (b.x + b.w / 2)) * b.face < 0; return b.st === 'stuck' ? (behind ? 2 : 1) : b.st === 'spit' ? 0.5 : 0; }
    return b.st === 'stuck' ? 1.8 : b.st === 'spit' ? 0.6 : 0;
  }
  if (b.type === 9) return b.vulnT > 0 ? 1.7 : 0;
  if (b.type === 10) return b.st === 'stun' ? 1.8 : 0.3;
  return b.st === 'tired' ? 1.8 : 0.3;
};
hitBoss = function (hb, fromAbove) {
  p.hitSet.add(boss);
  const b = boss, behind = (p.x + p.w / 2 - (b.x + b.w / 2)) * b.face < 0, fx = (x, y, c) => burst(x, y, c, 8, 160, 0, .3, 2);
  if (b.type === 2 && b.vulnT <= 0) { fx(hb.x + hb.w / 2, hb.y + hb.h / 2, '#35e2ff'); sfx('clang', .7); addFloat(b.x + b.w / 2, b.y - 10, 'ESCUDO', '#35e2ff'); return; }
  if (b.type === 4 && b.st === 'guard' && !behind && !fromAbove) { fx(hb.x + hb.w / 2, hb.y + hb.h / 2, '#ffffff'); sfx('clang', .8); p.vx = -p.face * 260; addFloat(b.x + b.w / 2, b.y - 10, '¡BLOQUEO!', '#ffffff'); return; }
  if (b.skin === 'boss_stag' && dim !== 1) { fx(hb.x + hb.w / 2, hb.y + hb.h / 2, '#bfe8ff'); sfx('ghost', .6); addFloat(b.x + b.w / 2, b.y - 10, 'ESPECTRAL', '#bfe8ff'); bossHint('stag'); return; }
  let mult = b.type >= 8 ? bossHitRule(b) : bossWeak(b);
  if (mult <= 0) { fx(hb.x + hb.w / 2, hb.y + hb.h / 2, '#35e2ff'); sfx('clang', .7); addFloat(b.x + b.w / 2, b.y - 10, b.type === 9 ? 'ESCUDO' : 'INMUNE', '#35e2ff'); bossHint('hard'); return; }
  // golpes desde arriba: mitad de daño, un respiro entre golpes y al tercero seguido te sacude
  if (fromAbove && !(p.slamT > 0.25)) {
    if (b.pogoCD > 0) return;
    b.pogoCD = 0.75; b.pogoN = (b.pogoT > 0 ? (b.pogoN || 0) : 0) + 1; b.pogoT = 2.6;
    if (b.pogoN >= 3 && mult < 1.6) { bossShake(b); return; }
    mult *= mult >= 1.6 ? 0.6 : 0.4;
  }
  const dmg = mult * swordDmg() * (p.atkN === 2 ? 1.6 : 1);
  b.hp -= dmg; b.hit = 0.12; zoomPunch(0.025 * Math.min(1.6, mult)); vib(22); addScore(Math.round(25 * mult)); addTime(4); addCombo(); hitStop = mult >= 1.6 ? 0.1 : 0.06;
  slashFx(hb); sfx('hit'); shake = Math.max(shake, mult >= 1.6 ? 9 : 5);
  if (mult >= 1.6) { addFloat(b.x + b.w / 2, b.y - 14, '¡CRÍTICO!', '#ffd34d', 18); bossHint('crit'); }
  else if (mult <= 0.4) { addFloat(b.x + b.w / 2, b.y - 10, 'DURO', '#a8b4c8', 13); sfx('clang', .35, 1.3); bossHint('hard'); }
  if (b.hp <= 0.01) { b.hp = 0; b.dying = true; b.dieT = 2.8; b.anim = 0; projs = []; waves = []; warns = []; sfx('boom'); sfx('kill'); shake = 20; hitStop = 0.3; flash = 0.3; flashCol = '255,255,255'; playMusic(null); slowT = 0; zoomPunch(0.09); vib([60, 40, 160]); }
};
// el jefe se sacude al jugador de encima
function bossShake(b) {
  const bcx = b.x + b.w / 2, dir = Math.sign(p.x + p.w / 2 - bcx) || 1;
  b.pogoN = 0; b.headT = 0; b.pogoCD = 1.2;
  shake = Math.max(shake, 12); sfx('roar', .7, .8); burst(bcx, b.y, '#ffffff', 18, 260, 300, .5, 3);
  hurt(12, bcx); p.vy = -640; p.vx = dir * 420; p.hook = null;
  addFloat(bcx, b.y - 18, '¡TE SACUDE!', '#ff8a7a', 18); bossHint('pogo');
}
const _updateBossF = updateBoss;
updateBoss = function (dt) {
  _updateBossF(dt);
  const b = boss; if (!b || b.done || b.dying) return;
  if (b.pogoCD > 0) b.pogoCD -= dt; if (b.pogoT > 0) b.pogoT -= dt; else b.pogoN = 0;
  // quedarse encima del jefe tampoco vale (salvo cuando está aturdido o expuesto)
  const above = !p.dead && p.x + p.w > b.x + 6 && p.x < b.x + b.w - 6 && p.y + p.h <= b.y + 12 && p.y + p.h > b.y - 70;
  const weak = (b.type >= 8 ? bossHitRule(b) : bossWeak(b)) >= 1.6;
  b.headT = above && !weak && bossIntro <= 0 ? (b.headT || 0) + dt : Math.max(0, (b.headT || 0) - dt * 2);
  if (b.headT > 1.1) bossShake(b);
  // desesperación: por debajo del 30 % de vida, ondas de choque y caídas del techo (no en Fácil)
  if (diffIdx > 0 && bossIntro <= 0 && b.hp <= b.max * 0.3 && level.arena) {
    const A = level.arena, bcx = b.x + b.w / 2, ag = DIFFS[diffIdx].aggr;
    if (!b.desp) { b.desp = true; b.despT = 1.6; shake = Math.max(shake, 12); sfx('roar', .8, .7); addFloat(bcx, b.y - 24, '¡DESESPERADO!', '#ff3050', 20); flash = .2; flashCol = '255,40,70'; }
    b.despT -= dt;
    if (b.despT <= 0) {
      b.despN = (b.despN || 0) + 1; b.despT = (diffIdx >= 2 ? 3.0 : 3.8) / Math.sqrt(ag);
      if (b.despN % 2) { const sp = 300 * Math.sqrt(ag); waves.push({ x: bcx - 40, y: A.floor, dir: -1, spd: sp, t: 0, col: '#ff6070' }, { x: bcx + 40, y: A.floor, dir: 1, spd: sp, t: 0, col: '#ff6070' }); sfx('stomp', .7); shake = Math.max(shake, 8); }
      else { const pcx = p.x + p.w / 2, n = diffIdx >= 2 ? 4 : 3; for (let i = 0; i < n; i++) warns.push({ x: i === 0 ? pcx : rnd(A.x1 + 40, A.x2 - 40), t: 0.85 + i * 0.18 }); sfx('alert', .6); }
    }
  }
};
// ---------------- movimiento procedural de los jefes ----------------
const BM_TENSE = /T$|wind|aim|tele|prep|charge|In$/, BM_DAZED = /stun|stuck|rest|tired|down|stagger|recover/;
const _drawBossM = drawBoss;
drawBoss = function () {
  const b = boss;
  if (!b || b.done || !level || !level.arena) return _drawBossM();
  const dt = Math.min(0.05, b._lt === undefined ? 0 : Math.max(0, time - b._lt)); b._lt = time;
  const A = level.arena, cx = b.x + b.w / 2, by = b.y + b.h;
  const vx = dt > 0 && b._px !== undefined ? (b.x - b._px) / dt : 0, vy = dt > 0 && b._py !== undefined ? (b.y - b._py) / dt : 0; b._px = b.x; b._py = b.y;
  const ground = by >= A.floor - 3, st = String(b.st || '');
  const M = b._m || (b._m = { sx: 1, sy: 1, rot: 0, ox: 0, oy: 0, ph: 0, land: 0, wasAir: false });
  let sx = 1, sy = 1, rot = 0, ox = 0, oy = 0;
  if (!b.dying) {
    // respiración
    sy += Math.sin(time * 2.2 + b.type) * 0.012;
    if (ground) {
      const sp = Math.abs(vx);
      if (sp > 25) { M.ph += (5.5 + sp * 0.03) * dt; oy = -Math.abs(Math.sin(M.ph)) * Math.min(5, 1.5 + sp / 160); sy += Math.sin(M.ph * 2) * 0.025; rot = clamp(vx / 500, -1, 1) * 0.08; }
      if (M.wasAir) M.land = 0.2; M.wasAir = false;
    } else {
      M.wasAir = true;
      if (Math.abs(vy) > 60) { const k = clamp(-vy / 1400, -0.12, 0.14); sy += k; sx -= k * 0.7; }
      rot = clamp(vx / 1200, -1, 1) * 0.1;
    }
    if (M.land > 0) { M.land -= dt; const k = M.land / 0.2; sy -= 0.16 * k; sx += 0.14 * k; }
    if (BM_TENSE.test(st)) { sy -= 0.05; sx += 0.04; ox = Math.sin(time * 48) * 1.2; }
    if (BM_DAZED.test(st)) { rot += Math.sin(time * 6) * 0.06; sy -= 0.03; }
    if (b.hit > 0) { const k = b.hit / 0.12; ox -= (b.face || 1) * 4 * k; sx += 0.06 * k; sy -= 0.05 * k; }
  }
  // suavizado (muelle) para que nada salte de golpe
  const f = Math.min(1, dt * 16);
  M.sx += (sx - M.sx) * f; M.sy += (sy - M.sy) * f; M.rot += (rot - M.rot) * f; M.ox += (ox - M.ox) * f; M.oy += (oy - M.oy) * f;
  bx.save(); bx.translate(cx + M.ox, by + M.oy); bx.rotate(M.rot); bx.scale(M.sx, M.sy); bx.translate(-cx, -by);
  _drawBossM();
  bx.restore();
};
// ---------------- dificultad progresiva ----------------
const DIFF_BASE = DIFFS.map(d => Object.assign({}, d));
function applyCurve(wi) {
  const n = ORDER.length - 1, g = clamp(WPOS(wi) / n, 0, 1);
  DIFFS.forEach((d, i) => { const B = DIFF_BASE[i]; d.spd = B.spd * (1 + 0.2 * g); d.aggr = Math.min(1.9, B.aggr * (1 + 0.4 * g)); d.dmg = B.dmg * (1 + 0.45 * g); d.boss = B.boss * (1 + 0.6 * g); });
  return g;
}
const _startStageC = startStage;
startStage = function (wi, act, fresh) { applyCurve(wi); _startStageC(wi, act, fresh); };
const _buildStageC = buildStage;
buildStage = function (wi, act) {
  const L = _buildStageC(wi, act), g = clamp(WPOS(wi) / (ORDER.length - 1), 0, 1), extra = (g >= 0.15 ? 1 : 0) + Math.floor(g * 2.2);
  if (extra) for (const e of L.enemies) e.hp += extra;
  return L;
};
