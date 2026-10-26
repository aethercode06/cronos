// =====================================================================
//  PULIDO v17: continuar desde el punto de control, jefes con furia,
//  Cámaras del Desafío, logros, calidad gráfica y soporte Android
// =====================================================================
SAVE.stats = Object.assign({ deaths: 0, revives: 0, trials: 0, blocks: 0, parries: 0, gems: 0, play: 0 }, SAVE.stats || {});
SAVE.ach = SAVE.ach || {};

// ---------------- continuar desde el punto de control ----------------
let stageDeaths = 0;
function reviveCheckpoint() {
  if (!p || !level) return;
  const s = p.respawn || level.start;
  SAVE.stats.revives++; stageDeaths++;
  Object.assign(p, { dead: false, deadT: 0, hp: p.maxHp, hpLag: p.maxHp, x: s.x, y: s.y, vx: 0, vy: 0, inv: 2.2, stun: 0, dashT: 0, boostT: 0,
    atkT: 0, hook: null, ground: null, onGround: false, combo: 0, comboT: 0, guard: false, guardBreak: 0, sinkT: 0, _counted: false });
  if (p.gst !== undefined) p.gst = 100;
  projs = []; waves = []; warns = []; echo = null; dlg = null; invertT = 0; slowT = 0;
  score = Math.max(stageScore0, score - 250);
  if (level.lava) level.lava.y = Math.max(level.lava.y, s.y + p.h + 320);
  resetTrials();
  if (arenaLock && boss && !boss.done && !boss.dying) { spawnBoss(); bossIntro = 1.2; }
  updateCamera(0, true);
  state = 'playing'; fade = 1;
  playMusic(arenaLock && boss && !boss.done ? (curWorld >= 6 ? 'final' : 'boss') : WORLDS[curWorld].music);
  sfx('check', .7); sfx('heal', .5);
  ring(s.x + p.w / 2, s.y + p.h / 2, 6, 70, .6, 'rgba(155,255,176,.9)', 2.5);
  burst(s.x + p.w / 2, s.y + p.h / 2, '#9bffb0', 22, 180, 60, .8, 2);
  addFloat(s.x + p.w / 2, s.y - 16, '¡DE PIE, KAEL!', '#9bffb0', 18);
  achCheck();
}
const _startStage17 = startStage;
startStage = function (wi, act, fresh) { stageDeaths = 0; _startStage17(wi, act, fresh); };

// ---------------- jefes: segunda fase (furia) y muerte épica ----------------
let bossHurt = false;
const _spawnBoss17 = spawnBoss;
spawnBoss = function () { _spawnBoss17(); bossHurt = false; };
const _updateBoss17 = updateBoss;
updateBoss = function (dt) {
  const b = boss;
  if (!b || b.done) return _updateBoss17(dt);
  const wasDying = b.dying;
  if (!b.dying && !b.enr && b.hp > 0 && b.hp <= b.max * 0.5 && bossIntro <= 0) {
    b.enr = true; b.enrT = 1.3; b.burstCD = 3.2;
    hitStop = Math.max(hitStop, .22); shake = Math.max(shake, 16); flash = .35; flashCol = '255,40,70'; vib([60, 40, 90]); zoomPunch(.04);
    sfx('roar', .9); sfx('boom', .6, .7);
    const cx = b.x + b.w / 2, cy = b.y + b.h / 2;
    ring(cx, cy, 10, 220, .7, 'rgba(255,60,80,.95)', 4); ring(cx, cy, 6, 140, .5, 'rgba(255,200,120,.9)', 2); impactFlash(cx, cy, 90, '#ff4a5e', .3);
    burst(cx, cy, '#ff3050', 36, 320, 80, 1, 2);
    banner('¡FURIA!', b.name + ' despierta su verdadero poder', '#ff3050', 2.2);
    projs = projs.filter(q => q.friendly);
  }
  if (b.enr && !b.dying) {
    if (Math.random() < .5) parts.push({ x: b.x + Math.random() * b.w, y: b.y + b.h * (0.3 + Math.random() * .7), vx: rnd(-20, 20), vy: rnd(-120, -50), life: .8, max: .8, c: Math.random() < .5 ? '#ff3050' : '#ffb040', s: 2, g: -40 });
    if (b.enrT > 0) { b.enrT -= dt; return; }
    _updateBoss17(dt * (diffIdx === 0 ? 1.1 : diffIdx === 1 ? 1.2 : 1.3));
    if (diffIdx > 0 && !b.dying && !b.done) {
      b.burstCD -= dt;
      if (b.burstCD <= 0) {
        b.burstCD = diffIdx === 2 ? 4.2 : 5.6;
        const cx = b.x + b.w / 2, cy = b.y + b.h * .45, n = diffIdx === 2 ? 12 : 9, off = Math.random() * 6.283, sp = 170 * DIFFS[diffIdx].spd;
        for (let i = 0; i < n; i++) { const a = off + i / n * 6.283; projs.push({ x: cx, y: cy, vx: Math.cos(a) * sp, vy: Math.sin(a) * sp, hw: 5, hh: 5, type: 'orb', dmg: 10, life: 3.2 }); }
        ring(cx, cy, 8, 90, .4, 'rgba(255,80,100,.9)', 3); sfx('shoot', .5, .7);
      }
    }
  } else _updateBoss17(dt);
  if (!wasDying && b.dying) {
    hitStop = Math.max(hitStop, .55); shake = Math.max(shake, 22); flash = .45; flashCol = '255,240,220'; zoomPunch(.06); vib([100, 50, 200]);
    const cx = b.x + b.w / 2, cy = b.y + b.h / 2;
    for (let i = 0; i < 4; i++) ring(cx, cy, 6 + i * 10, 160 + i * 70, .6 + i * .18, i % 2 ? 'rgba(255,220,140,.9)' : 'rgba(255,255,255,.95)', 4 - i * .6);
    impactFlash(cx, cy, 140, '#ffffff', .4); burst(cx, cy, '#ffe6a0', 60, 420, 60, 1.4, 3);
    sfx('boom', .9, .6);
    projs = projs.filter(q => q.friendly);
    if (!bossHurt) b.flawless = true;
  }
};
const _hurt17 = hurt;
hurt = function (dmg, srcX) { const r = _hurt17(dmg, srcX); if (r && arenaLock) bossHurt = true; return r; };
const _xl17 = extraLights;
extraLights = function () {
  _xl17();
  if (boss && boss.enr && !boss.done && level && level.arena) lightAt(boss.x + boss.w / 2, boss.y + boss.h / 2, 150 + Math.sin(time * 6) * 20, 'rgba(255,50,70,1)', .35);
  if (level && level.trials) for (const t of level.trials) if (t.st === 1) lightAt(t.cx, GY - 200, 380, 'rgba(255,90,60,1)', .12 + Math.sin(time * 3) * .04);
};

// ---------------- Cámaras del Desafío ----------------
function resetTrials() {
  if (!level || !level.trials) return;
  for (const t of level.trials) if (t.st === 1) { t.st = 0; t.wave = 0; t.t = 0; for (const e of t.live) e.dead = true; t.live = []; t.plates.forEach(q => { q.on = true; }); }
}
function spawnTrialWave(t) {
  for (const tpl of t.waves[t.wave]) {
    const e = Object.assign({}, tpl); e.dead = false; e.hit = 0; e.alert = 1; e.cd = 1 + Math.random();
    if (e.b === 'riser') e.st = 'buried';
    level.enemies.push(e); t.live.push(e);
    addFx('poof', e.x + e.w / 2, e.y + e.h / 2, 16); ring(e.x + e.w / 2, e.y + e.h / 2, 4, 40, .4, 'rgba(255,90,70,.9)', 2);
  }
  t.wave++; sfx('alert', .4, 1.2);
  addFloat(t.cx, GY - 330, 'OLEADA ' + t.wave + ' / ' + t.waves.length, '#ff8a5a', 18);
}
function updateTrials(dt) {
  if (!level.trials || p.dead) return;
  for (const t of level.trials) {
    if (t.st === 0 && p.x > t.x1 + 70 && p.x + p.w < t.x2 - 40 && p.y > GY - 420) {
      t.st = 1; t.wave = 0; t.t = .9; t.live = [];
      t.plates.forEach(q => { q.on = false; });
      banner('CÁMARA DEL DESAFÍO', 'Sobrevive a todas las oleadas', '#ff6a4a', 2.2);
      sfx('clang', .6, .7); sfx('alert', .6); shake = Math.max(shake, 8);
    }
    if (t.st !== 1) continue;
    if (t.live.every(e => e.dead)) {
      t.t -= dt;
      if (t.t <= 0) {
        if (t.wave < t.waves.length) { spawnTrialWave(t); t.t = 1.1; }
        else {
          t.st = 2; t.plates.forEach(q => { q.on = true; });
          SAVE.stats.trials++; persist();
          p.hp = Math.min(p.maxHp, p.hp + 40); addScore(1500);
          for (let i = 0; i < 7; i++) level.gems.push({ x: t.cx - 150 + i * 50, y: 400 - Math.sin(i / 6 * Math.PI) * 70, taken: false, ph: i });
          banner('¡DESAFÍO SUPERADO!', '+1500 puntos · +40 vida · fragmentos de recompensa', '#ffd34d', 2.6);
          sfx('relic', .7); sfx('win', .5); flash = .2; flashCol = '255,220,120';
          ring(t.cx, GY - 140, 10, 300, .8, 'rgba(255,220,120,.9)', 3); burst(t.cx, GY - 140, '#ffe080', 40, 300, 60, 1, 2);
          achCheck();
        }
      }
    }
  }
}

// ---------------- logros ----------------
const ACH = [
  ['p11', 'Primeros pasos', 'Completa la fase 1-1'],
  ['g1', 'Rompeguardianes', 'Derrota a tu primer guardián'],
  ['g7', 'Medio Reloj', 'Derrota a 7 guardianes'],
  ['g14', 'Corazón del Tiempo', 'Derrota a los 18 guardianes'],
  ['intacto', 'Intocable', 'Derrota a un guardián sin recibir daño'],
  ['dificil', 'Sin piedad', 'Derrota a un guardián en DIFÍCIL'],
  ['c25', 'Ritmo letal', 'Consigue un combo x25'],
  ['c50', 'Tormenta de acero', 'Consigue un combo x50'],
  ['rel1', 'Ojo para lo oculto', 'Encuentra un reloj de arena secreto'],
  ['rel10', 'Guardián de arena', 'Encuentra 10 relojes secretos'],
  ['gem300', 'Lluvia de fragmentos', 'Recoge 300 fragmentos de realidad'],
  ['tr1', 'Superviviente', 'Supera una Cámara del Desafío'],
  ['tr10', 'Campeón de las cámaras', 'Supera 10 Cámaras del Desafío'],
  ['blk', 'Muro viviente', 'Bloquea 50 ataques'],
  ['parry', 'Filo perfecto', 'Haz 10 paradas perfectas'],
  ['ab6', 'Arsenal del tiempo', 'Consigue 6 habilidades'],
  ['fast', 'Veloz como un segundo', 'Completa una fase en menos de 75 s'],
  ['tenaz', 'Nunca te rindes', 'Levántate 20 veces tras caer']
];
let toasts = [];
function achGive(id) {
  if (SAVE.ach[id]) return;
  SAVE.ach[id] = Date.now(); persist();
  const a = ACH.find(q => q[0] === id); if (a) { toasts.push({ a, t: 0 }); sfx('relic', .45, 1.2); }
}
function bossesDone() { let n = 0; for (let w = 0; w < ORDER.length; w++) { const st = SAVE.st[w * 3 + 2]; if (st && st.done) n++; } return n; }
function relicsFound() { let n = 0; for (const k in SAVE.st) if (SAVE.st[k] && SAVE.st[k].relic) n++; return n; }
function achCheck() {
  const S = SAVE.stats;
  if (SAVE.st[0] && SAVE.st[0].done) achGive('p11');
  const b = bossesDone(); if (b >= 1) achGive('g1'); if (b >= 7) achGive('g7'); if (b >= ORDER.length) achGive('g14');
  const r = relicsFound(); if (r >= 1) achGive('rel1'); if (r >= 10) achGive('rel10');
  if (S.gems >= 300) achGive('gem300');
  if (S.trials >= 1) achGive('tr1'); if (S.trials >= 10) achGive('tr10');
  if (S.blocks >= 50) achGive('blk'); if (S.parries >= 10) achGive('parry');
  if (S.revives >= 20) achGive('tenaz');
  if (ABIL.filter(a => hasAb(a.k)).length >= 6) achGive('ab6');
}
const _blockHit17 = blockHit;
blockHit = function (dmg, srcX, proj) { const r = _blockHit17(dmg, srcX, proj); if (r === 'parry') SAVE.stats.parries++; else if (r === 'block') SAVE.stats.blocks++; if (SAVE.stats.blocks % 10 === 0 || r === 'parry') achCheck(); return r; };
const _stageClear17 = stageClear;
stageClear = function () {
  if (state !== 'playing') return;
  const bossWin = curAct === 2 && boss && boss.done, flaw = boss && boss.flawless, t = levelTime;
  _stageClear17();
  if (bossWin && flaw) achGive('intacto');
  if (bossWin && diffIdx === 2) achGive('dificil');
  if (curAct < 2 && t < 75) achGive('fast');
  achCheck();
};
let gemSeen = 0, achTick = 0;
function achTrack(dt) {
  SAVE.stats.play += dt;
  const g = level.gems.reduce((n, q) => n + (q.taken ? 1 : 0), 0);
  if (g > gemSeen) SAVE.stats.gems += g - gemSeen; gemSeen = g;
  if (p.combo >= 25) achGive('c25'); if (p.combo >= 50) achGive('c50');
  if (p.dead && !p._counted) { p._counted = true; SAVE.stats.deaths++; }
  achTick += dt; if (achTick > 20) { achTick = 0; persist(); }
}
const _update17 = update;
update = function (dt) {
  if (level && level._g17 !== level) { level._g17 = level; gemSeen = 0; }
  _update17(dt);
  if (state === 'playing' || state === 'gameover') { updateTrials(dt); achTrack(dt); }
  if (OPT.lq && parts.length > 360) parts.splice(0, parts.length - 360);
};
function drawToasts(dt) {
  if (!toasts.length) return;
  const T = toasts[0]; T.t += dt;
  const k = T.t < .35 ? T.t / .35 : T.t > 3.4 ? Math.max(0, 1 - (T.t - 3.4) / .35) : 1, e = 1 - Math.pow(1 - k, 3);
  const w = 380, h = 60, x = (W - w) / 2, y = -h + e * (h + 16);
  ctx.save(); ctx.globalAlpha = Math.min(1, k * 1.4);
  glass(x, y, w, h, 16, '#ffc861', true);
  const cx = x + 34, cy = y + h / 2;
  const g = ctx.createRadialGradient(cx, cy, 2, cx, cy, 22); g.addColorStop(0, '#fff2b0'); g.addColorStop(.6, '#ffb840'); g.addColorStop(1, 'rgba(255,140,40,0)');
  ctx.fillStyle = g; ctx.beginPath(); ctx.arc(cx, cy, 22, 0, 6.283); ctx.fill();
  starShape(cx, cy, 11, 5, '#4a2a06');
  txt('LOGRO DESBLOQUEADO', x + 66, y + 20, 11, '#ffc861', null, 0, 'left', UIF, 800);
  txt(T.a[1], x + 66, y + 40, 17, '#ffffff', null, 0, 'left', UIF, 800);
  ctx.restore();
  if (T.t > 3.8) toasts.shift();
}
function starShape(cx, cy, r, n, col) {
  ctx.fillStyle = col; ctx.beginPath();
  for (let i = 0; i < n * 2; i++) { const a = -Math.PI / 2 + i * Math.PI / n, rr = i % 2 ? r * .45 : r; ctx.lineTo(cx + Math.cos(a) * rr, cy + Math.sin(a) * rr); }
  ctx.closePath(); ctx.fill();
}
let achPrev = 'title';
function openAch() { achPrev = state; state = 'logros'; fade = .5; achCheck(); }
function closeAch() { state = achPrev === 'logros' ? 'title' : achPrev; fade = .5; }
function fmtTime(s) { s = Math.floor(s); const h = Math.floor(s / 3600), m = Math.floor(s / 60) % 60; return h ? h + ' h ' + m + ' min' : m + ' min'; }
function drawAch() {
  ctx.fillStyle = '#07060f'; ctx.fillRect(0, 0, W, H);
  const gr = ctx.createRadialGradient(W / 2, H * .3, 10, W / 2, H * .3, W * .7); gr.addColorStop(0, 'rgba(150,100,40,.35)'); gr.addColorStop(1, 'rgba(0,0,0,0)'); ctx.fillStyle = gr; ctx.fillRect(0, 0, W, H);
  const ox = Math.round((W - 960) / 2); ctx.save(); ctx.translate(ox, 0);
  const got = ACH.filter(a => SAVE.ach[a[0]]).length;
  ctx.save(); ctx.shadowColor = 'rgba(255,190,90,.7)'; ctx.shadowBlur = 18; txt('LOGROS', 480, 44, 30, '#ffd88a', null, 0, 'center', LOGOF, 900); ctx.restore();
  txt(got + ' / ' + ACH.length + ' desbloqueados', 480, 74, 13, 'rgba(255,255,255,.75)', null, 0, 'center', UIF, 700);
  ACH.forEach((a, i) => {
    const col = i % 2, rw = i >> 1, x = 70 + col * 420, y = 92 + rw * 43, on = !!SAVE.ach[a[0]];
    rrect(x, y, 400, 38, 10); ctx.fillStyle = on ? 'rgba(255,200,100,.12)' : 'rgba(255,255,255,.04)'; ctx.fill();
    ctx.strokeStyle = on ? 'rgba(255,200,110,.55)' : 'rgba(255,255,255,.1)'; ctx.lineWidth = 1; ctx.stroke();
    if (on) { ctx.fillStyle = '#ffb840'; ctx.beginPath(); ctx.arc(x + 20, y + 19, 12, 0, 6.283); ctx.fill(); starShape(x + 20, y + 19, 7.5, 5, '#4a2a06'); }
    else icon('lock', x + 20, y + 19, 14, 'rgba(255,255,255,.35)');
    txt(a[1], x + 42, y + 13, 13, on ? '#ffffff' : 'rgba(255,255,255,.6)', null, 0, 'left', UIF, 800);
    txt(a[2], x + 42, y + 28, 11, on ? 'rgba(255,230,180,.85)' : 'rgba(255,255,255,.4)', null, 0, 'left', UIF, 500);
  });
  const S = SAVE.stats;
  txt('Guardianes: ' + bossesDone() + '/18   ·   Cámaras: ' + S.trials + '   ·   Caídas: ' + S.deaths + '   ·   Paradas: ' + S.parries + '   ·   Tiempo de juego: ' + fmtTime(S.play), 480, 492, 12, 'rgba(255,255,255,.7)', null, 0, 'center', UIF, 600);
  txt('Toca la pantalla o pulsa ESC para volver', 480, 518, 11, 'rgba(255,220,150,.6)', null, 0, 'center', UIF, 600);
  ctx.restore();
}
const _handleTap17 = handleTap;
handleTap = function (x, y, type) { if (state === 'logros') { sfx('click'); closeAch(); return; } _handleTap17(x, y, type); };
const _onKey17 = onKey;
onKey = function (c) { if (state === 'logros') { if (c === 'Escape' || c === 'Enter' || c === 'Space') closeAch(); return; } if (state === 'gameover' && (c === 'KeyR')) { retry(); return; } _onKey17(c); };
let lastDraw17 = performance.now();
const _draw17 = draw;
draw = function () {
  const now = performance.now(), dt = Math.min(.05, (now - lastDraw17) / 1000); lastDraw17 = now;
  if (state === 'logros') { drawAch(); if (fade > 0) { ctx.fillStyle = 'rgba(0,0,0,' + fade + ')'; ctx.fillRect(0, 0, W, H); } }
  else _draw17();
  drawToasts(dt);
};

// ---------------- calidad gráfica ----------------
const QR0 = QR;
function applyQuality() {
  if (OPT.lq) { if (QR > 2) setQR(2); if (glQ > 1) glQ = 1; }
  else { if (QR0 > QR) setQR(QR0); if (glOK && glQ < 2) glQ = 2; }
}
const _drawGiants17 = drawGiants; drawGiants = function () { if (!OPT.lq) _drawGiants17(); };
const _drawSwarms17 = drawSwarms; drawSwarms = function () { if (!OPT.lq) _drawSwarms17(); };
try { if (OPT.lq) applyQuality(); } catch (e) {}

// ---------------- Android / navegador: botón atrás y segundo plano ----------------
function exitApp() {
  const A = window.Capacitor && Capacitor.Plugins && Capacitor.Plugins.App;
  if (A && A.exitApp) A.exitApp();
}
function backAction() {
  if (state === 'playing') { pauseGame(); return; }
  if (state === 'paused') { resume(); return; }
  if (state === 'options') { closeOptions(); return; }
  if (state === 'logros') { closeAch(); return; }
  if (state === 'shop') { state = 'map'; return; }
  if (state === 'map') { toTitle(); return; }
  if (state === 'ability') { abilAdvance(); return; }
  if (state === 'cutscene') { endCut(); return; }
  if (state === 'fragment') { fragAdvance(); return; }
  if (state === 'gameover' || state === 'clear' || state === 'victory') { toMap(); return; }
  if (state === 'title') exitApp();
}
(function () {
  const C = window.Capacitor;
  if (C && C.Plugins && C.Plugins.App && C.Plugins.App.addListener) {
    C.Plugins.App.addListener('backButton', backAction);
    C.Plugins.App.addListener('appStateChange', s => { if (!s.isActive && state === 'playing') pauseGame(); });
  } else {
    // en el navegador o en una TWA, el botón atrás del sistema dispara popstate
    try { history.pushState({ g: 1 }, ''); window.addEventListener('popstate', () => { if (state !== 'title') { backAction(); history.pushState({ g: 1 }, ''); } }); } catch (e) {}
  }
  document.addEventListener('backbutton', e => { e.preventDefault(); backAction(); }, false);
  document.addEventListener('visibilitychange', () => { if (document.hidden && state === 'playing') pauseGame(); if (document.hidden) persist(); });
  window.addEventListener('pagehide', () => persist());
})();

// barrera rúnica de las Cámaras del Desafío
const _drawDoor17 = drawDoor;
drawDoor = function (d) {
  if (!d.trial) return _drawDoor17(d);
  if (!onScreen(d.x - 30, d.w + 60)) return;
  const a = 1 - d.open, cx = d.x + d.w / 2, by = d.y + d.h;
  // runa en el suelo, siempre visible
  bx.save(); bx.globalAlpha = .55 + Math.sin(time * 3) * .15;
  bx.strokeStyle = a > .05 ? '#ff5a4a' : '#ffb070'; bx.lineWidth = 1.5;
  bx.beginPath(); bx.ellipse(cx, by - 2, 22, 5, 0, 0, 6.283); bx.stroke();
  bx.beginPath(); bx.ellipse(cx, by - 2, 13, 3, 0, 0, 6.283); bx.stroke();
  bx.restore();
  if (a > .02) {
    const hh = d.h * a, y = by - hh;
    bx.save(); bx.globalCompositeOperation = 'lighter';
    const g = bx.createLinearGradient(d.x - 22, 0, d.x + d.w + 22, 0);
    g.addColorStop(0, 'rgba(255,40,60,0)'); g.addColorStop(.35, 'rgba(255,50,60,' + (.45 * a) + ')'); g.addColorStop(.5, 'rgba(255,120,90,' + (.9 * a) + ')'); g.addColorStop(.65, 'rgba(255,50,60,' + (.45 * a) + ')'); g.addColorStop(1, 'rgba(255,40,60,0)');
    bx.fillStyle = g; bx.fillRect(d.x - 22, y, d.w + 44, hh);
    bx.fillStyle = 'rgba(255,150,110,' + (.75 * a) + ')';
    for (let yy = y + 20; yy < by - 10; yy += 46) { const k = Math.floor(yy / 46 + time * 2) % 3; bx.fillRect(cx - 7, yy, 14, 2); if (k) bx.fillRect(cx - 1, yy - 6, 2, 14); bx.fillRect(cx - 5 + k * 3, yy + 5, 4, 2); }
    for (let i = 0; i < 6; i++) { const yy = y + ((time * 90 + i * 61) % hh); bx.fillStyle = 'rgba(255,190,140,' + (.5 * a) + ')'; bx.fillRect(cx - 1, yy, 2, 14); }
    bx.fillStyle = 'rgba(255,220,180,' + (.8 * a) + ')'; bx.fillRect(cx - .5, y, 1, hh);
    bx.restore();
    lightAt(cx, by - hh / 2, 90, 'rgba(255,60,60,1)', .35 * a);
  }
};

// ---------------- recuperación de lienzos perdidos ----------------
// Android puede descartar lienzos cuando le falta memoria gráfica (o al volver de segundo plano):
// quedan transparentes. Se detecta y se vuelven a pintar todas las cachés.
function rebuildCaches() {
  for (const D of [TINT, GLOW, FLIP, TINT2, PBGM, BLK, HDT, FOGC, FGC, PTEX, PTC, THUMB]) for (const k in D) delete D[k];
  darkCache = {}; vignette = null;
  if (level && level.plats) for (const s of level.plats) if (s.k === 'solid') {
    if (s.cache2) { s.cache2 = renderPlat2(s, level.wi); s._pr = undefined; }
    else if (s.cache) s.cache = renderPlat(s, WORLDS[level.wi].tiles);
  }
}
function cacheAlpha(s) {
  const c = s.cache2 && s.cache2.c; if (!c || !c.width) return -1;
  try { const x = c.getContext('2d'); return x.getImageData(c.width >> 1, Math.floor(c.height * 0.45), 1, 1).data[3]; } catch (e) { return -1; }
}
let cacheProbeT = 0, cacheDirty = false;
function probeCaches(dt) {
  if (cacheDirty) { cacheDirty = false; rebuildCaches(); return; }
  cacheProbeT -= dt; if (cacheProbeT > 0 || !level || !level.plats) return;
  cacheProbeT = 2.5;
  // un bloque visible que al crearse era opaco y ahora está vacío = lienzo perdido
  for (const s of level.plats) {
    if (!s.cache2 || !onScreen(s.x, s.w)) continue;
    if (s._pr === undefined) { s._pr = cacheAlpha(s) > 0; continue; }
    if (s._pr && cacheAlpha(s) === 0) { rebuildCaches(); return; }
    break;
  }
}
const _mkCanvas17 = mkCanvas;
mkCanvas = function (w, h) {
  const r = _mkCanvas17(w, h);
  try { r[0].addEventListener('contextrestored', () => { cacheDirty = true; }); } catch (e) {}
  return r;
};
document.addEventListener('visibilitychange', () => { if (!document.hidden) cacheDirty = true; });
const _update17b = update;
update = function (dt) { _update17b(dt); probeCaches(dt); };

// ---------------- MANDO (Xbox, PlayStation, genéricos) ----------------
// Disposición estándar: 0 A/✕ · 1 B/○ · 2 X/□ · 3 Y/△ · 4 LB/L1 · 5 RB/R1 · 6 LT/L2 · 7 RT/R2 · 8 SELECT · 9 START · 12-15 cruceta
let padActive = false, padPrev = {}, menuFocus = 0, navOn = false;
const PAD_KEYS = { 0: 'Space', 2: 'KeyJ', 1: 'KeyK', 7: 'KeyK', 4: 'KeyF', 6: 'KeyF', 3: 'KeyL', 5: 'KeyC', 8: 'KeyE', 10: 'KeyE' };
const NAV_ST = ['title', 'paused', 'gameover', 'clear', 'victory'];
function padState() {
  const pads = navigator.getGamepads ? navigator.getGamepads() : [];
  for (const g of pads) if (g && g.connected && g.buttons && g.buttons.length) return g;
  return null;
}
function padBtn(g, i) { const b = g.buttons[i]; return !!b && (b.pressed || b.value > 0.5); }
function pollPad() {
  const g = padState(); if (!g) { if (padActive) { for (const k of ['KeyA', 'KeyD', 'KeyS', 'KeyW'].concat(Object.values(PAD_KEYS))) keys[k] = false; padActive = false; padPrev = {}; } return; }
  const ax = g.axes[0] || 0, ay = g.axes[1] || 0;
  const cur = {
    L: padBtn(g, 14) || ax < -0.45, R: padBtn(g, 15) || ax > 0.45, U: padBtn(g, 12) || ay < -0.6, D: padBtn(g, 13) || ay > 0.6,
    START: padBtn(g, 9)
  };
  for (const i in PAD_KEYS) cur['b' + i] = padBtn(g, +i);
  const any = Object.values(cur).some(v => v);
  if (any && !padActive) { padActive = true; touchMode = false; }
  if (!padActive) { padPrev = cur; return; }
  const edge = k => cur[k] && !padPrev[k], rel = k => !cur[k] && padPrev[k];
  // movimiento (sin tocar las flechas, que en el juego también son "saltar")
  const setK = (k, on, was) => { if (on && !was) keys[k] = true; else if (!on && was) keys[k] = false; };
  setK('KeyA', cur.L, padPrev.L); setK('KeyD', cur.R, padPrev.R); setK('KeyS', cur.D, padPrev.D);
  for (const i in PAD_KEYS) {
    const k = PAD_KEYS[i], b = 'b' + i;
    if (edge(b)) { keys[k] = true; if (state === 'playing' || state === 'cutscene' || state === 'ability' || state === 'fragment') onKey(k === 'KeyJ' ? 'KeyZ' : k === 'KeyK' ? 'KeyX_' : k); }
    else if (rel(b)) { const other = Object.keys(PAD_KEYS).some(j => j !== i && PAD_KEYS[j] === k && cur['b' + j]); if (!other) keys[k] = false; }
  }
  if (edge('START')) onKey('Escape');
  if (state !== 'playing') {
    if (edge('b0') && !['cutscene', 'ability', 'fragment'].includes(state)) onKey('Enter');
    if (edge('b1')) onKey('Escape');
    if (edge('L')) onKey('ArrowLeft'); if (edge('R')) onKey('ArrowRight'); if (edge('U')) onKey('ArrowUp'); if (edge('D')) onKey('ArrowDown');
  }
  padPrev = cur;
}
const _readInput17 = readInput;
readInput = function () { try { pollPad(); } catch (e) {} _readInput17(); };
// navegación de menús con cruceta / flechas
const _uiButtons17 = uiButtons;
uiButtons = function () {
  const B = _uiButtons17();
  if (navOn && NAV_ST.includes(state) && B.length) { const f = ((menuFocus % B.length) + B.length) % B.length; B.forEach((b, i) => { b.sel = i === f; }); }
  return B;
};
const _onKey17b = onKey;
onKey = function (c) {
  if (NAV_ST.includes(state) && !(state === 'title' && c === 'KeyM')) {
    const B = _uiButtons17();
    if (c === 'ArrowUp' || c === 'ArrowLeft' || c === 'ArrowDown' || c === 'ArrowRight') {
      if (!navOn) { navOn = true; menuFocus = 0; } else menuFocus += (c === 'ArrowUp' || c === 'ArrowLeft') ? -1 : 1;
      sfx('click', .5); return;
    }
    if ((c === 'Enter' || c === 'Space') && navOn && B.length) { const b = B[((menuFocus % B.length) + B.length) % B.length]; sfx('select', .7); navOn = false; menuFocus = 0; b.fn(); return; }
  }
  if (c === 'KeyX_') return;  // dash del mando: no es una tecla de menú
  _onKey17b(c);
};
const _handleTap17b = handleTap;
handleTap = function (x, y, type) { navOn = false; _handleTap17b(x, y, type); };
// vibración del mando
const _vib17 = vib;
vib = function (pat) {
  _vib17(pat);
  if (!padActive || !OPT.vib) return;
  try { const g = padState(), d = Array.isArray(pat) ? pat.reduce((a, b) => a + b, 0) : pat; if (g && g.vibrationActuator) g.vibrationActuator.playEffect('dual-rumble', { duration: Math.min(400, d || 40), strongMagnitude: .7, weakMagnitude: .5 }); } catch (e) {}
};
window.addEventListener('gamepadconnected', () => { padActive = true; touchMode = false; if (state === 'playing') addFloat(p.x + p.w / 2, p.y - 20, 'MANDO CONECTADO', '#7fe9ff', 16); });
window.addEventListener('gamepaddisconnected', () => { if (!padState()) { padActive = false; touchMode = ('ontouchstart' in window) || (navigator.maxTouchPoints || 0) > 0; if (state === 'playing') pauseGame(); } });
