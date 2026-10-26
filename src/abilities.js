// =====================================================================
//  DEFENSA Y HABILIDADES
//  · GUARDIA (desde el principio): escudo del tiempo frontal con aguante.
//  · Reliquias: al vencer al guardián de cada mundo, Kael gana una habilidad.
// =====================================================================
const ABIL = [
  { k: 'carga', n: 'Golpe Cargado', d: 'Mantén ESPADA y suéltala para lanzar una onda de luz que atraviesa a los enemigos.', how: 'Mantén ESPADA y suelta', c: '#ffd34d' },
  { k: 'parada', n: 'Parada Perfecta', d: 'Cúbrete justo antes del golpe: no gastas escudo, devuelves los disparos y contraatacas.', how: 'GUARDIA justo a tiempo', c: '#7fe9ff' },
  { k: 'fantasma', n: 'Dash Fantasma', d: 'Tu DASH atraviesa a los enemigos y les hace daño.', how: 'DASH contra un enemigo', c: '#9ab8ff' },
  { k: 'sismo', n: 'Golpe Sísmico', d: 'En el aire, pulsa GUARDIA para caer en picado y liberar una onda sísmica.', how: 'GUARDIA en el aire', c: '#ffb040' },
  { k: 'iman', n: 'Imán del Cronista', d: 'Las gemas y cerezas lejanas vuelan hacia ti.', how: 'Siempre activo', c: '#ff9af0' },
  { k: 'triple', n: 'Triple Salto', d: 'Puedes saltar una tercera vez en el aire.', how: 'SALTO tres veces', c: '#bff4ff' },
  { k: 'corazon', n: 'Corazón de Cristal', d: '+40 de vida máxima. Si nadie te golpea, recuperas vida poco a poco.', how: 'Siempre activo', c: '#ff5a7a' },
  { k: 'planeo', n: 'Capa Planeadora', d: 'Mantén SALTO mientras caes para planear con tu capa.', how: 'Mantén SALTO al caer', c: '#ffd34d' },
  { k: 'ojo', n: 'Ojo del Cronista', d: 'Una brújula te señala la reliquia escondida y los cofres de cada fase.', how: 'Siempre activo', c: '#c890ff' },
  { k: 'luz', n: 'Espada de Luz', d: 'El tercer golpe del combo lanza una media luna de luz.', how: 'Combo de 3 golpes', c: '#fff0a0' },
  { k: 'rebobinar', n: 'Segunda Oportunidad', d: 'Una vez por fase, si caes derrotado, el tiempo retrocede y vuelves con media vida.', how: 'Siempre activo', c: '#7fe9ff' }
];
const ABIL_GUARD = { n: 'Escudo del Tiempo', d: 'Mantén GUARDIA para bloquear los ataques de frente. Cada bloqueo gasta escudo; si se agota, la guardia se rompe.', how: 'Mantén GUARDIA', c: '#ffb84a' };
function abIdx(k) { return ABIL.findIndex(a => a.k === k); }
function hasAb(k) { const i = abIdx(k); if (i < 0) return false; const st = SAVE.st[sIdx(i, 2)]; return !!(st && st.done); }
function abCount() { let n = 0; for (let i = 0; i < ABIL.length; i++) if (hasAb(ABIL[i].k)) n++; return n; }

// ---------- controles ----------
TB.guard = [358, 446, 74, 1]; TL.guard = 'GUARDIA';
let guardAct = false, guardPrev = false, guardPressed = false, atkPrevHeld = false;
const _readInput = readInput;
readInput = function () {
  _readInput();
  guardPrev = guardAct;
  guardAct = !!(keys.KeyF || keys.KeyU || keys.KeyI || (touchMode && state === 'playing' && touchDown('guard')));
  guardPressed = guardAct && !guardPrev;
};

// ---------- jugador ----------
function abInit() {
  if (p && p._ab && !SAVE.guardTip && levelTime > 5 && !dlg) { SAVE.guardTip = 1; persist(); tSay('Si algo te ataca, mantén GUARDIA para cubrirte con el escudo del tiempo.', 4.5); }
  if (!p || p._ab) return; p._ab = 1; p.gst = 100; p.guardT = 9; p.lastHurt = -9; p.chargeT = 0; if (hasAb('corazon')) { p.maxHp += 40; p.hp += 40; } }
const _updPlayer = updatePlayer;
updatePlayer = function (dt) {
  abInit();
  if (p.dead) return _updPlayer(dt);
  // guardia, picado y carga (antes de la física)
  if (p.guardBreak > 0) p.guardBreak -= dt;
  const canGuard = p.stun <= 0 && p.dashT <= 0 && !p.hook && !(p.guardBreak > 0) && !p.plunge;
  if (guardPressed && !p.onGround && hasAb('sismo') && !p.hook && p.dashT <= 0 && !p.inWater) { p.plunge = true; p.guard = false; p.vy = 300; sfx('dash', .5, .7); }
  else p.guard = guardAct && canGuard;
  if (guardPressed) p.guardT = 0; else p.guardT += dt;
  if (p.guard) { act.attack = false; pressed.attack = false; act.dash = false; pressed.dash = false; p.chargeT = 0; }
  // triple salto
  if (hasAb('triple') && pressed.jump && !p.onGround && p.coyote <= 0 && !p.wall && !p.hook && p.jumps >= 2 && !p.triple && !p.inWater && p.dashT <= 0) {
    p.triple = true; p.vy = -JUMP * 0.86; p.sq = 1.16; pressed.jump = false; p.buf = 0; p.noCut = false;
    sfx('dj', .5, 1.25); burst(p.x + p.w / 2, p.y + p.h, '#ffe9a0', 12, 140, 0, .4, 2); ring(p.x + p.w / 2, p.y + p.h, 3, 22, .3, 'rgba(255,233,160,.8)', 1.5, .35);
  }
  // golpe cargado
  const held = act.attack && !p.guard;
  if (hasAb('carga') && held) { p.chargeT += dt; if (p.chargeT > 0.3 && Math.random() < .6) parts.push({ x: p.x + p.w / 2 - p.face * 10 + rnd(-6, 6), y: p.y + rnd(10, 40), vx: p.face * rnd(10, 40), vy: rnd(-40, 0), life: .4, max: .4, c: '#ffd34d', s: 1, g: -20 }); if (p.chargeT > 0.6 && !p.chargeReady) { p.chargeReady = true; sfx('relic', .3, 2); impactFlash(p.x + p.w / 2, p.y + 24, 26, '#ffe9a0', .15); } }
  else if (p.chargeT > 0) { if (p.chargeReady) releaseCharge(); p.chargeT = 0; p.chargeReady = false; }
  const x0 = p.x, wasDash = p.dashT > 0, atk0 = p.atkT;
  _updPlayer(dt);
  // guardia: casi quieto
  if (p.guard && p.onGround) p.x = x0 + (p.x - x0) * 0.2;
  if (!p.guard) p.gst = Math.min(100, (p.gst || 0) + dt * 28);
  if (p.blockT > 0) p.blockT -= dt;
  // picado sísmico
  if (p.plunge) { p.vy = 980; p.vx = 0; if (p.onGround || p.inWater) { p.plunge = false; seismic(); } }
  if (p.slamT > 0) p.slamT -= dt;
  if (p.onGround) p.triple = false;
  // planeo
  p.gliding = hasAb('planeo') && !p.onGround && act.jump && p.vy > 0 && !p.wall && !p.hook && !p.inWater && !p.plunge && p.dashT <= 0;
  if (p.gliding) { p.vy = Math.min(p.vy, 75); if (Math.random() < .3) parts.push({ x: p.x + p.w / 2 - p.face * 14, y: p.y + rnd(14, 30), vx: -p.face * 30, vy: rnd(0, 20), life: .5, max: .5, c: '#ffe9a0', s: 1, g: 0 }); }
  // dash fantasma
  if (p.dashT > 0 && !wasDash) p.hitSet = new Set();
  if (p.dashT > 0 && hasAb('fantasma')) { if (hitEnemyBox({ x: p.x - 6, y: p.y, w: p.w + 12, h: p.h })) { hitStop = Math.max(hitStop, .03); } }
  // espada de luz: el tercer golpe lanza una media luna
  if (hasAb('luz') && p.atkT > 0 && atk0 <= 0 && p.atkN === 2) fireWave(1.4, 0.5, 0.85);
  // imán
  if (hasAb('iman')) {
    const px = p.x + p.w / 2, py = p.y + p.h / 2;
    for (const g of level.gems) if (!g.taken) { const dx = px - g.x, dy = py - g.y, d = Math.hypot(dx, dy); if (d < 230 && d > 1) { g.x += dx / d * 380 * dt; g.y += dy / d * 380 * dt; } }
    for (const c of level.cherries) if (!c.taken) { const dx = px - c.x, dy = py - c.y, d = Math.hypot(dx, dy); if (d < 200 && d > 1) { c.x += dx / d * 300 * dt; c.y += dy / d * 300 * dt; } }
  }
  // corazón de cristal
  if (hasAb('corazon') && time - p.lastHurt > 4 && p.hp < p.maxHp) p.hp = Math.min(p.maxHp, p.hp + 4 * dt);
  if (p.releaseT > 0) p.releaseT -= dt;
};
function releaseCharge() {
  p.releaseT = 0.28; p.chargeReady = false; fireWave(3, 1, 1.25); sfx('swing', .8, .7); sfx('relic', .4, 1.4); shake = Math.max(shake, 4); hitStop = Math.max(hitStop, .05);
}
function fireWave(dmg, life, scale) {
  const x = p.x + p.w / 2 + p.face * 26, y = p.y + 26;
  projs.push({ type: 'lightwave', friendly: true, x, y, vx: p.face * 560, vy: 0, life, hw: 14 * scale, hh: 24 * scale, dmg: 0, fdmg: dmg, sc: scale, hit: new Set() });
  impactFlash(x, y, 26 * scale, '#fff0a0', .12);
}
function seismic() {
  const x = p.x + p.w / 2, y = p.y + p.h;
  p.slamT = 0.3; shake = Math.max(shake, 10); hitStop = Math.max(hitStop, .08); sfx('boom', .6, 1.2); sfx('stomp', .7); vib(30);
  ring(x, y - 2, 6, 90, .45, 'rgba(255,190,100,.9)', 3, .9, 0.25); ring(x, y - 2, 4, 60, .35, 'rgba(255,255,220,.9)', 2, .9, 0.25);
  dust(x - 20, y, 10, -1); dust(x + 20, y, 10, 1); burst(x, y - 4, '#ffb040', 20, 260, 500, .6, 2);
  for (let i = 0; i < 14; i++) parts.push({ x: x + rnd(-40, 40), y: y - 2, vx: rnd(-160, 160), vy: rnd(-300, -120), life: .7, max: .7, c: '#6a5040', s: 2, g: 700 });
  const box = { x: x - 95, y: y - 50, w: 190, h: 60 }; p.hitSet = new Set(); p.atkN = 2;
  hitEnemyBox(box); hitLive(box); hitCrystals(box);
  if (boss && !boss.dying && bossIntro <= 0 && overlap(box, boss)) hitBoss(box, true);
  lightAt(x, y - 10, 160, 'rgba(255,190,110,1)', .8);
}
// proyectiles amigos (ondas de luz y disparos devueltos)
function friendlyProj(q) {
  const r = { x: q.x - q.hw, y: q.y - q.hh, w: q.hw * 2, h: q.hh * 2 }; q.hit = q.hit || new Set(); let hit = false;
  for (const e of level.enemies) if (!e.dead && !q.hit.has(e) && overlap(r, e) && enemyHittable(e)) {
    q.hit.add(e); const n = Math.max(1, Math.round(q.fdmg || 2));
    for (let i = 0; i < n && !e.dead; i++) { p.hitSet = new Set(); damageEnemy(e, r); }
    hit = true;
  }
  if (boss && !boss.dying && bossIntro <= 0 && !q.hit.has(boss) && overlap(r, boss)) { q.hit.add(boss); const hs = p.hitSet; hitBoss(r); p.hitSet = hs; hit = true; }
  if (q.type !== 'lightwave' && hit) q.life = 0;
  hitLive(r);
}
// ---------- bloquear ----------
function frontOf(srcX) { return srcX === undefined || (srcX - (p.x + p.w / 2)) * p.face > -8; }
function blockHit(dmg, srcX, proj) {
  const perfect = hasAb('parada') && p.guardT < 0.22, sx = p.x + p.w / 2 + p.face * 16, sy = p.y + 26;
  p.blockT = 0.22; p.inv = Math.max(p.inv, 0.3);
  if (perfect) {
    hitStop = Math.max(hitStop, .16); sfx('shield', .7, 1.3); sfx('clang', .6, 1.5); vib(25);
    impactFlash(sx, sy, 34, '#bff4ff', .2); ring(sx, sy, 4, 46, .35, 'rgba(160,240,255,.9)', 2.5); burst(sx, sy, '#bff4ff', 16, 240, 200, .45, 1);
    addFloat(sx, p.y - 14, '¡PARADA!', '#bff4ff', 16); p.gst = Math.min(100, p.gst + 20);
    if (!proj) { let best = null, bd = 90; for (const e of level.enemies) if (!e.dead) { const d = Math.abs(e.x + e.w / 2 - sx); if (d < bd && Math.abs(e.y + e.h / 2 - sy) < 70) { bd = d; best = e; } } if (best) { p.hitSet = new Set(); p.atkN = 2; damageEnemy(best, { x: best.x, y: best.y, w: best.w, h: best.h }); } }
    return 'parry';
  }
  p.gst -= dmg * 2.4; p.vx = -p.face * 200;
  sfx('clang', .6); burst(sx, sy, '#ffd890', 10, 180, 200, .35, 1); impactFlash(sx, sy, 20, '#ffd890', .12); ring(sx, sy, 3, 26, .25, 'rgba(255,220,150,.8)', 1.5);
  if (p.gst <= 0) { p.gst = 0; p.guardBreak = 1.4; p.guard = false; sfx('crumble', .6); addFloat(sx, p.y - 14, '¡GUARDIA ROTA!', '#ff8a5a', 15); p.inv = 0; _hurtBase(dmg * 0.5, srcX); return 'break'; }
  return 'block';
}
const _hurtBase = hurt;
hurt = function (dmg, srcX) {
  if (p.inv > 0 || p.dead) return false;
  if (p.guard && frontOf(srcX)) { blockHit(dmg, srcX); return true; }
  p.lastHurt = time;
  return _hurtBase(dmg, srcX);
};
// bloquear/devolver proyectiles (lo llama updateProjs)
function guardProj(q) {
  if (!p.guard || !frontOf(q.x) || q.type === 'breath' || q.type === 'laser') return false;
  const res = blockHit(q.dmg || 12, q.x, true);
  if (res === 'parry') { q.friendly = true; q.fdmg = 2; q.vx = Math.abs(q.vx) > 40 ? -q.vx * 1.3 : p.face * 420; q.vy = q.vy * -0.3; q.life = 1.4; q.grav = 0; q.hit = new Set(); return 'reflect'; }
  return 'block';
}
// segunda oportunidad
const _killBase = kill;
kill = function () {
  if (hasAb('rebobinar') && !p.rewindUsed && p.y < level.deathY + 400) {
    p.rewindUsed = true; const s = p.safe || p.respawn;
    p.hp = Math.round(p.maxHp * 0.5); p.x = s.x; p.y = s.y; p.vx = 0; p.vy = 0; p.inv = 2.5; p.stun = 0; p.dead = false;
    flash = 0.35; flashCol = '120,220,255'; sfx('slow', .8, 1.2); sfx('relic', .6, .8); hitStop = .25;
    ring(p.x + p.w / 2, p.y + 28, 6, 80, .6, 'rgba(140,230,255,.9)', 3); burst(p.x + p.w / 2, p.y + 28, '#bff4ff', 30, 220, 0, .8, 2);
    addFloat(p.x + p.w / 2, p.y - 16, 'SEGUNDA OPORTUNIDAD', '#7fe9ff', 16); tSay('¡Uf! El tiempo te ha dado otra oportunidad.', 2.6);
    return;
  }
  _killBase();
};
// ---------- poses del héroe ----------
const _hdAnimBase = hdAnim;
hdAnim = function () {
  if (!p.dead) {
    if (p.plunge && SPR.KH_plunge) return ['KH_plunge', 0];
    if (p.slamT > 0 && SPR.KH_slam) return ['KH_slam', 0];
    if (p.guard && SPR.KH_guard) return [p.blockT > 0 ? 'KH_guardHit' : 'KH_guard', 0];
    if (p.releaseT > 0 && SPR.KH_release) return ['KH_release', 0];
    if (p.chargeT > 0.3 && p.atkT <= 0 && SPR.KH_charge) return ['KH_charge', 0];
    if (p.gliding && SPR.KH_glide) return ['KH_glide', 0];
  }
  return _hdAnimBase();
};
// ---------- dibujo en el mundo ----------
function drawAbilWorld() {
  if (!p || p.dead) return;
  const cx = p.x + p.w / 2, cy = p.y + 26;
  bx.globalCompositeOperation = 'lighter';
  // escudo del tiempo
  if (p.guard) {
    const sx = cx + p.face * 15, k = p.blockT > 0 ? 1 : 0.6 + Math.sin(time * 8) * 0.08, gs = (p.gst || 0) / 100;
    const col = p.blockT > 0 && hasAb('parada') && p.guardT < 0.4 ? '160,240,255' : '255,214,140';
    bx.save(); bx.translate(sx, cy); bx.scale(p.face, 1);
    bx.globalAlpha = 0.75 * k; bx.drawImage(ptexC('glow', 'rgb(' + col + ')'), -22, -36, 40, 72);
    bx.strokeStyle = 'rgba(' + col + ',' + (0.95 * k) + ')'; bx.lineWidth = 2.4; bx.beginPath(); bx.ellipse(0, 0, 11, 28, 0, -Math.PI / 2, Math.PI / 2); bx.stroke();
    bx.lineWidth = 0.8; bx.globalAlpha = 0.7 * k; bx.beginPath(); bx.ellipse(-2, 0, 6, 20, 0, -Math.PI / 2, Math.PI / 2); bx.stroke();
    for (let i = 0; i < 6; i++) { const a = -Math.PI / 2 + ((i / 6 + time * 0.3) % 1) * Math.PI, rx = Math.cos(a) * 9, ry = Math.sin(a) * 26; bx.globalAlpha = 0.9 * k; bx.drawImage(ptexC('spark', 'rgb(' + col + ')', true), rx - 2.5, ry - 2.5, 5, 5); }
    bx.globalAlpha = 0.6 * k * gs; bx.fillStyle = 'rgba(' + col + ',.25)'; bx.beginPath(); bx.ellipse(0, 0, 9, 26 * gs, 0, -Math.PI / 2, Math.PI / 2); bx.fill();
    bx.restore(); lightAt(sx, cy, 70, 'rgba(' + col + ',1)', .3 * k);
  }
  // carga
  if (p.chargeT > 0.3) { const a = clamp((p.chargeT - 0.3) / 0.3, 0, 1), sx = cx - p.face * 18; bx.globalAlpha = 0.4 + a * 0.5; bx.drawImage(ptexC('glow', '#ffd34d'), sx - 14 - a * 8, cy - 14 - a * 8, 28 + a * 16, 28 + a * 16); if (p.chargeReady) { bx.globalAlpha = 0.8 + Math.sin(time * 30) * 0.2; bx.drawImage(ptexC('spark', '#fff0a0', true), sx - 10, cy - 10, 20, 20); } lightAt(sx, cy, 60 + a * 50, 'rgba(255,220,120,1)', .3 + a * .4); }
  // ondas de luz
  for (const q of projs) if (q.type === 'lightwave') {
    const s = q.sc || 1, dir = Math.sign(q.vx) || 1, al = clamp(q.life * 3, 0, 1);
    bx.save(); bx.translate(q.x, q.y); bx.scale(dir, 1);
    bx.globalAlpha = al * 0.55; bx.drawImage(ptexC('glow', '#ffe9a0'), -26 * s, -32 * s, 52 * s, 64 * s);
    bx.globalAlpha = al; bx.strokeStyle = '#fff6d0'; bx.lineWidth = 3 * s; bx.beginPath(); bx.arc(-10 * s, 0, 22 * s, -1.1, 1.1); bx.stroke();
    bx.strokeStyle = 'rgba(255,210,110,.8)'; bx.lineWidth = 6 * s; bx.globalAlpha = al * 0.5; bx.beginPath(); bx.arc(-14 * s, 0, 20 * s, -1.0, 1.0); bx.stroke();
    bx.restore(); lightAt(q.x, q.y, 90 * s, 'rgba(255,230,150,1)', .5 * al);
    if (Math.random() < .7) parts.push({ x: q.x - dir * 8, y: q.y + rnd(-20, 20) * s, vx: -dir * rnd(20, 80), vy: rnd(-20, 20), life: .35, max: .35, c: '#ffe9a0', s: 1, g: 0 });
  }
  // devueltos: halo cian
  for (const q of projs) if (q.friendly && q.type !== 'lightwave') { bx.globalAlpha = .6; bx.drawImage(ptexC('glow', '#9ff0ff'), q.x - 14, q.y - 14, 28, 28); }
  bx.globalCompositeOperation = 'source-over'; bx.globalAlpha = 1;
}
// ---------- interfaz: barra de escudo, brújula del Ojo ----------
function drawAbilHUD() {
  if (!p || state !== 'playing' || p.dead) return;
  // barra de escudo sobre Kael (sólo si no está llena o está cubriéndose)
  if ((p.gst || 100) < 99 || p.guard) {
    const [x, y] = w2s(p.x + p.w / 2, p.y - 6), w = 46, g = (p.gst || 0) / 100;
    ctx.save(); ctx.globalAlpha = .9; rrect(x - w / 2, y - 6, w, 6, 3); ctx.fillStyle = 'rgba(10,8,24,.7)'; ctx.fill();
    rrect(x - w / 2 + 1, y - 5, (w - 2) * g, 4, 2); ctx.fillStyle = p.guardBreak > 0 ? '#ff6a5a' : '#ffc860'; ctx.fill(); ctx.restore();
  }
  // brújula del Ojo del Cronista
  if (hasAb('ojo') && level) {
    const tg = []; if (level.relic && !level.relic.taken) tg.push([level.relic.x, level.relic.y, '#c890ff']);
    if (level.live) for (const o of level.live.o) if (o.k === 'chest' && !o.st) tg.push([o.x, o.y - 10, '#ffd34d']);
    for (const t of tg) {
      const [sx, sy] = w2s(t[0], t[1]); if (sx > 20 && sx < W - 20 && sy > 20 && sy < H - 20) continue;
      const cx = W / 2, cy = H / 2, a = Math.atan2(sy - cy, sx - cx), r = Math.min(W, H) / 2 - 34, ex = cx + Math.cos(a) * r * (W / H) * 0.9, ey = cy + Math.sin(a) * r;
      const x = clamp(ex, 30, W - 30), y = clamp(ey, 70, H - 30);
      ctx.save(); ctx.translate(x, y); ctx.rotate(a); ctx.globalAlpha = .75 + Math.sin(time * 5) * .2; ctx.fillStyle = t[2];
      ctx.beginPath(); ctx.moveTo(12, 0); ctx.lineTo(-6, -8); ctx.lineTo(-2, 0); ctx.lineTo(-6, 8); ctx.closePath(); ctx.fill(); ctx.restore();
    }
  }
}
// ---------- tarjeta de habilidad nueva y menú ----------
let abilCard = null;
const _finishFrag = finishFragment;
finishFragment = function () {
  const w = frag.w; SAVE.abSeen = SAVE.abSeen || {};
  if (ABIL[w] && !SAVE.abSeen[w]) {
    SAVE.abSeen[w] = 1; persist(); const f = frag; frag = null;
    abilCard = { i: w, t: 0, next: () => { frag = f; _finishFrag(); } }; state = 'ability'; fade = 1; sfx('relic', .9, .8); sfx('win', .6, 1.2);
    return;
  }
  _finishFrag();
};
function abilAdvance() { if (!abilCard || abilCard.t < 1) return; const c = abilCard; abilCard = null; if (c.next) c.next(); else state = c.back || 'paused'; sfx('click', .5); }
function openAbilMenu() { abilCard = { menu: true, t: 1, back: state }; state = 'ability'; }
function drawAbilityCard() {
  const c = abilCard; if (!c) { state = 'map'; return; }
  c.t += 1 / 60;
  ctx.fillStyle = '#07060f'; ctx.fillRect(0, 0, W, H);
  const g = ctx.createRadialGradient(W / 2, H * .42, 10, W / 2, H * .42, W * .6); g.addColorStop(0, 'rgba(90,60,160,.55)'); g.addColorStop(1, 'rgba(0,0,0,0)'); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  if (!c.menu) {
    const A = ABIL[c.i], k = clamp(c.t / 0.8, 0, 1), e = 1 - Math.pow(1 - k, 3), ic = SPR['AB_' + c.i];
    // rayos detrás del icono
    ctx.save(); ctx.translate(W / 2, H * .38); ctx.rotate(time * .2); ctx.globalCompositeOperation = 'lighter';
    for (let i = 0; i < 12; i++) { ctx.rotate(Math.PI / 6); ctx.fillStyle = hexA(A.c, .08 * e); ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(-30, -H); ctx.lineTo(30, -H); ctx.fill(); }
    ctx.restore();
    const s = 150 * (0.6 + e * 0.4) + Math.sin(time * 3) * 4;
    ctx.save(); ctx.shadowColor = A.c; ctx.shadowBlur = 40 * e; ctx.globalAlpha = e; if (ic && ic.width) { ctx.imageSmoothingEnabled = true; ctx.drawImage(ic, W / 2 - s / 2, H * .38 - s / 2, s, s); } ctx.restore();
    ctx.globalAlpha = e;
    txt('¡NUEVA HABILIDAD!', W / 2, H * .38 - 110, 18, '#ffd34d', null, 0, 'center', UIF, 800);
    txt(A.n.toUpperCase(), W / 2, H * .38 + 108, 30, '#ffffff', null, 0, 'center', UIF, 900);
    const lines = wrapText(A.d, Math.min(640, W - 80), 17); lines.forEach((l, i) => txt(l, W / 2, H * .38 + 142 + i * 24, 17, 'rgba(255,255,255,.85)', null, 0, 'center', UIF, 500));
    txt('CÓMO SE USA: ' + A.how.toUpperCase(), W / 2, H * .38 + 152 + lines.length * 24, 14, A.c, null, 0, 'center', UIF, 800);
    ctx.globalAlpha = c.t > 1 ? .55 + Math.sin(time * 4) * .3 : 0; txt('Toca para continuar', W / 2, H - 26, 14, '#ffffff', null, 0, 'center', UIF, 600); ctx.globalAlpha = 1;
    if (Math.random() < .4) { /* chispas de la interfaz */ }
    return;
  }
  // menú de habilidades
  txt('HABILIDADES DE KAEL', W / 2, 46, 24, '#ffd34d', null, 0, 'center', UIF, 900);
  txt(abCount() + ' / ' + ABIL.length + ' reliquias  ·  vence al guardián de cada mundo para conseguir la siguiente', W / 2, 72, 13, 'rgba(255,255,255,.7)', null, 0, 'center', UIF, 600);
  const all = [{ ...ABIL_GUARD, i: 11, own: true }].concat(ABIL.map((a, i) => ({ ...a, i, own: hasAb(a.k) })));
  const cols = 4, cw = Math.min(220, (W - 60) / cols), ch = 92, x0 = W / 2 - cw * cols / 2, y0 = 92;
  all.forEach((a, j) => {
    const x = x0 + (j % cols) * cw, y = y0 + Math.floor(j / cols) * ch, ic = SPR['AB_' + a.i];
    rrect(x + 4, y + 4, cw - 8, ch - 8, 12); ctx.fillStyle = a.own ? 'rgba(30,24,60,.85)' : 'rgba(20,18,30,.6)'; ctx.fill(); ctx.strokeStyle = a.own ? hexA(a.c, .6) : 'rgba(255,255,255,.08)'; ctx.lineWidth = 1.2; ctx.stroke();
    ctx.save(); ctx.globalAlpha = a.own ? 1 : .25; if (ic && ic.width) { ctx.imageSmoothingEnabled = true; ctx.drawImage(ic, x + 10, y + 14, 60, 60); } ctx.restore();
    if (!a.own) icon('lock', x + 40, y + 44, 18, 'rgba(255,255,255,.6)');
    txt(a.own ? a.n : '???', x + 78, y + 30, 13, a.own ? '#ffffff' : 'rgba(255,255,255,.4)', null, 0, 'left', UIF, 800);
    const desc = a.own ? a.how : (a.i < 11 ? 'Guardián del mundo ' + (WPOS(a.i) + 1) : '');
    wrapText(desc, cw - 90, 11).slice(0, 3).forEach((l, i) => txt(l, x + 78, y + 48 + i * 14, 11, a.own ? hexA(a.c, .95) : 'rgba(255,255,255,.35)', null, 0, 'left', UIF, 600));
  });
  ctx.globalAlpha = .55 + Math.sin(time * 4) * .3; txt('Toca para volver', W / 2, H - 18, 13, '#ffffff', null, 0, 'center', UIF, 600); ctx.globalAlpha = 1;
}
