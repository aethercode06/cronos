// =====================================================================
//  ENGANCHE (v3.0): que juegues una partida y quieras seguir
//  1) Reintento instantáneo: al caer vuelves al punto de control en
//     menos de un segundo, con «Llegaste al 72 %» para picarte.
//  2) Reto diario: la misma fase para todos cada día, récord de tiempo.
//  3) Cofre diario con racha de días seguidos (crece hasta 7 días).
//  4) Tres misiones diarias con premio en fragmentos.
//  5) Récord de tiempo por fase y aviso de «¡NUEVO RÉCORD!».
// =====================================================================
const tr = s => { try { return (typeof TRM !== 'undefined' && TRM && TRM.get(s)) || s; } catch (e) { return s; } };
const dayNum = () => Math.floor((Date.now() - new Date().getTimezoneOffset() * 60000) / 86400000);
SAVE.dly = Object.assign({ streak: 0, last: -9, best: {}, done: -9, dstreak: 0, dlast: -9 }, SAVE.dly || {});
SAVE.mis = SAVE.mis || { day: -1, list: [] };
SAVE.bt = SAVE.bt || {};
// ---------------- misiones diarias ----------------
const MIS_POOL = [
  ['kill', 'Derrota a {n} enemigos', [25, 40, 60], 30],
  ['clear', 'Supera {n} fases', [2, 3, 4], 40],
  ['boss', 'Derrota a un guardián', [1], 60],
  ['nodmg', 'Supera una fase sin recibir daño', [1], 60],
  ['crit', 'Haz {n} golpes críticos a guardianes', [4, 8], 40],
  ['seal', 'Abre {n} barreras de emboscada', [2, 4], 35],
  ['gems', 'Recoge {n} fragmentos', [50, 90], 30],
  ['daily', 'Completa el reto diario', [1], 50],
  ['combo', 'Consigue un combo de {n}', [15, 25], 35]
];
function misEnsure() {
  const d = dayNum(); if (SAVE.mis.day === d) return;
  const r = seeded(d * 7919 + 101), pool = MIS_POOL.slice(), list = [];
  while (list.length < 3 && pool.length) {
    const m = pool.splice(Math.floor(r() * pool.length), 1)[0], oi = Math.floor(r() * m[2].length);
    list.push({ k: m[0], txt: m[1], n: m[2][oi], rw: Math.round(m[3] * (1 + oi * 0.5)), p: 0, ok: false });
  }
  SAVE.mis = { day: d, list }; try { persist(); } catch (e) {}
}
const misText = m => tr(m.txt).replace('{n}', m.n);
const streakTxt = n => n === 1 ? tr('Racha de 1 día') : tr('Racha de {n} días').replace('{n}', n);
const mtoasts = [];
function misAdd(k, v, isMax) {
  misEnsure();
  for (const m of SAVE.mis.list) {
    if (m.k !== k || m.ok) continue;
    m.p = isMax ? Math.max(m.p, v) : m.p + (v === undefined ? 1 : v);
    if (m.p >= m.n) { m.p = m.n; m.ok = true; SAVE.bank = (SAVE.bank || 0) + m.rw; mtoasts.push({ t: 0, head: 'MISIÓN CUMPLIDA', body: misText(m), rw: m.rw }); sfx('relic', .5, 1.1); try { persist(); } catch (e) {} }
  }
}
// ---------------- cofre diario y racha ----------------
const chestReady = () => SAVE.dly.last !== dayNum();
function claimChest() {
  const d = dayNum(); if (SAVE.dly.last === d) return;
  SAVE.dly.streak = SAVE.dly.last === d - 1 ? SAVE.dly.streak + 1 : 1; SAVE.dly.last = d;
  const g = 15 + 5 * Math.min(SAVE.dly.streak, 7);
  SAVE.bank = (SAVE.bank || 0) + g; persist();
  mtoasts.push({ t: 0, head: 'COFRE DIARIO', body: streakTxt(SAVE.dly.streak), rw: g });
  sfx('relic', .7); sfx('gem', .6); flash = .2; flashCol = '255,220,120';
}
// ---------------- reto diario ----------------
let DAILY = null, dailyRes = null;
function dailyPlan() {
  const d = dayNum(), r = seeded(d * 104729 + 7), ws = towerWorlds();
  let wi = ws[Math.floor(r() * ws.length)], act = r() < .5 ? 0 : 1; if (wi === 0) act = 1;
  return { d, wi, act, seed: d * 7907 + 3 };
}
function startDaily() {
  const P = dailyPlan();
  try { endTower(); } catch (e) {}
  DAILY = { d: P.d, deaths: 0 }; dailyRes = null; score = 0;
  TOWER_ON = true; TOWER_SEED = P.seed; TOWER_N = 9; TOWER_TRIAL = false;
  try { startStage(P.wi, P.act, false); } finally { TOWER_ON = false; }
  stageScore0 = 0; levelTime = 0; p.rewindUsed = true; dlg = null; loreT = 0;
  banner('RETO DIARIO', tr('La misma fase para todos hoy · ¡bate tu récord!'), '#ff8a3d', 2.6);
}
const _stageClearH = stageClear;
stageClear = function () {
  if (state !== 'playing') return _stageClearH();
  const g = level.gems.filter(x => x.taken).length;
  misAdd('clear'); misAdd('gems', g); if (!stageHurt) misAdd('nodmg'); if (curAct === 2 && !DAILY) misAdd('boss');
  if (DAILY) {
    const t = levelTime + DAILY.deaths * 5, d = DAILY.d, prev = SAVE.dly.best[d];
    const first = SAVE.dly.done !== d;
    if (first) { SAVE.dly.dstreak = SAVE.dly.dlast === d - 1 ? SAVE.dly.dstreak + 1 : 1; SAVE.dly.dlast = d; SAVE.dly.done = d; SAVE.bank = (SAVE.bank || 0) + 40 + g; misAdd('daily'); }
    const rec = !prev || t < prev; if (rec) SAVE.dly.best[d] = t;
    for (const k in SAVE.dly.best) if (+k < d - 7) delete SAVE.dly.best[k];
    dailyRes = { t, time: levelTime, deaths: DAILY.deaths, rec, prev, first, g };
    persist(); stopAmbience(); slowT = 0; fade = 1; echo = null; dlg = null;
    state = 'dailyDone'; sfx('portal', .8); sfx('win', .8); playMusic('menu');
    return;
  }
  // récord de tiempo de la fase
  const s = sIdx(curWorld, curAct), bt = SAVE.bt[s];
  clearRec = (!bt || levelTime < bt) ? { t: levelTime, prev: bt } : null;
  if (clearRec) SAVE.bt[s] = levelTime;
  _stageClearH();
};
let clearRec = null, stageHurt = false;
const _startStageH = startStage;
startStage = function (wi, act, fresh) { stageHurt = false; sealsOpened = 0; _startStageH(wi, act, fresh); };
const _hurtH = hurt;
hurt = function (dmg, srcX) { const r = _hurtH(dmg, srcX); if (r) stageHurt = true; return r; };
const _hazH = hazardRespawn;
hazardRespawn = function (d) { stageHurt = true; return _hazH(d); };
// enemigos derrotados y golpes críticos
const _dmgEnemyH = damageEnemy;
damageEnemy = function (e, hb) { const was = e.dead; _dmgEnemyH(e, hb); if (!was && e.dead) misAdd('kill'); };
const _hitBossH = hitBoss;
hitBoss = function (hb, fromAbove) {
  const b = boss; let crit = false;
  try { crit = b && (b.type >= 8 ? bossHitRule(b) : bossWeak(b)) >= 1.6; } catch (e) {}
  const hp0 = b ? b.hp : 0; _hitBossH(hb, fromAbove);
  if (crit && b && b.hp < hp0) misAdd('crit');
};
// ---------------- reintento instantáneo ----------------
let sealsOpened = 0, deathN = 0;
const _updateH = update;
update = function (dt) {
  _updateH(dt);
  if (state === 'playing' && p) {
    if (p.dead && p.deadT > 0.6) p.deadT = 0.6;           // caída más corta
    if (p.combo >= 10) misAdd('combo', p.combo, true);
    if (level && level.seals) { const n = level.seals.filter(z => z.st === 2).length; if (n > sealsOpened) { misAdd('seal', n - sealsOpened); sealsOpened = n; } }
  }
  // al caer: de vuelta al punto de control al instante (no en la Torre, el Boss Rush ni las Grietas)
  if (state === 'gameover' && !TOWER && !RUSH && !SECRET) {
    const goal = level.goal ? level.goal.x : level.arena ? level.arena.x1 : level.width, pct = Math.round(clamp(p.x / goal, 0, 1) * 100);
    deathN++; if (DAILY) DAILY.deaths++;
    if (typeof loseLife === 'function' && loseLife()) return;   // sin vidas: la fase empieza de nuevo (stakes.js)
    reviveCheckpoint(); fade = 0.55;
    const sub = DAILY ? tr('+5 s por caída · ¡sigue!') : pct >= 30 ? tr('Llegaste al {n} % · ¡tú puedes!').replace('{n}', pct) : tr('¡Otra vez!');
    banner(tr('INTENTO {n}').replace('{n}', stageDeaths + 1) + (typeof livesLeft === 'function' && livesLeft() < 90 ? '   ♥ ' + livesLeft() : ''), sub, '#ffd34d', 1.3);
  }
};
// salir del reto al ir al mapa o al título
for (const fn of ['toMap', 'toTitle', 'beginStage']) {
  const o = window[fn]; if (typeof o !== 'function') continue;
  window[fn] = function () { DAILY = null; return o.apply(this, arguments); };
}
try { toMap = window.toMap; toTitle = window.toTitle; beginStage = window.beginStage; } catch (e) {}
const _retryH = retry;
retry = function () { if (DAILY) { startDaily(); return; } _retryH(); };
// ---------------- botones ----------------
const _uiButtonsH = uiButtons;
uiButtons = function () {
  const B = _uiButtonsH(), ox = Math.round((W - 960) / 2);
  if (state === 'title' && SAVE.intro) {
    const st = SAVE.dly.dstreak && SAVE.dly.dlast >= dayNum() - 1 ? '  🔥' + SAVE.dly.dstreak : '';
    B.push({ x: ox + 612, y: 340, w: 210, h: 46, t: tr('RETO DIARIO') + st, ic: 'time', c: '#ff8a3d', c2: '#ff4d6d', sel: SAVE.dly.done !== dayNum(), small: true, fn: () => { goFull(); sfx('select'); startDaily(); } });
    misEnsure(); const done = SAVE.mis.list.filter(m => m.ok).length;
    B.push({ x: ox + 138, y: 340, w: 210, h: 46, t: tr('MISIONES') + ' ' + done + '/3', ic: 'flag', c: '#3df5a0', small: true, fn: () => { sfx('click'); misPrev = state; state = 'misiones'; } });
    if (chestReady()) B.push({ x: W - 400, y: 14, w: 160, h: 34, t: '🎁 ' + tr('COFRE'), c: '#ffcf4a', c2: '#ff8a3d', sel: true, small: true, fn: claimChest });
  }
  if (state === 'misiones') return [{ x: ox + 380, y: 452, w: 200, h: 44, t: 'VOLVER', ic: 'left', c: '#35e2ff', fn: () => { state = misPrev || 'title'; } }];
  if (state === 'dailyDone') return [
    { x: ox + 230, y: 402, w: 240, h: 48, t: tr('OTRA VEZ'), ic: 'time', c: '#ffcf4a', c2: '#ff8a3d', sel: true, fn: startDaily },
    { x: ox + 490, y: 402, w: 240, h: 48, t: 'MAPA', ic: 'flag', c: '#35e2ff', c2: '#7a5cff', fn: toMap }];
  return B;
};
let misPrev = 'title';
const _onKeyH = onKey;
onKey = function (c) {
  if (state === 'misiones') { if (c === 'Escape' || c === 'Enter') state = misPrev || 'title'; return; }
  if (state === 'dailyDone') { if (c === 'Enter' || c === 'Space') startDaily(); else if (c === 'Escape') toMap(); return; }
  _onKeyH(c);
};
// ---------------- dibujo ----------------
function drawMisiones() {
  ctx.fillStyle = 'rgba(6,4,16,.72)'; ctx.fillRect(0, 0, W, H);
  const ox = Math.round((W - 960) / 2), py = Math.round((H - 440) / 2);
  ctx.save(); ctx.translate(ox, 0); glass(200, py, 560, 400, 24, '#3df5a0', true);
  txt('MISIONES DE HOY', 480, py + 46, 26, '#c8ffe4', null, 0, 'center', LOGOF, 900);
  txt(tr('Se renuevan cada día · premio en fragmentos'), 480, py + 74, 12, 'rgba(255,255,255,.7)', null, 0, 'center', UIF, 600);
  misEnsure();
  SAVE.mis.list.forEach((m, i) => {
    const y = py + 104 + i * 72;
    rrect(230, y, 500, 60, 14); ctx.fillStyle = m.ok ? 'rgba(61,245,160,.14)' : 'rgba(255,255,255,.05)'; ctx.fill();
    txt(misText(m), 250, y + 22, 15, m.ok ? '#9dffd0' : '#ffffff', null, 0, 'left', UIF, 800);
    txt((m.ok ? '✓ ' : '') + '◆ ' + m.rw, 712, y + 22, 14, '#ffe27a', null, 0, 'right', UIF, 800);
    rrect(250, y + 36, 460, 10, 5); ctx.fillStyle = 'rgba(255,255,255,.12)'; ctx.fill();
    rrect(250, y + 36, Math.max(10, 460 * m.p / m.n), 10, 5); ctx.fillStyle = m.ok ? '#3df5a0' : '#35e2ff'; ctx.fill();
    txt(m.p + ' / ' + m.n, 712, y + 46, 11, 'rgba(255,255,255,.75)', null, 0, 'right', UIF, 700);
  });
  const st = SAVE.dly.streak && SAVE.dly.last >= dayNum() - 1 ? SAVE.dly.streak : 0;
  txt('🔥 ' + streakTxt(st) + (chestReady() ? '  ·  ' + tr('¡Tu cofre de hoy te espera en el título!') : ''), 480, py + 336, 13, '#ffd34d', null, 0, 'center', UIF, 700);
  ctx.restore();
}
function drawDailyDone() {
  ctx.fillStyle = 'rgba(6,4,16,.66)'; ctx.fillRect(0, 0, W, H);
  const R = dailyRes, ox = Math.round((W - 960) / 2), py = Math.round((H - 420) / 2);
  ctx.save(); ctx.translate(ox, 0); glass(210, py, 540, 380, 24, '#ff8a3d', true);
  ctx.save(); ctx.shadowColor = 'rgba(255,140,60,.7)'; ctx.shadowBlur = 22; txt('RETO DIARIO SUPERADO', 480, py + 52, 24, '#ffd0a0', null, 0, 'center', LOGOF, 900); ctx.restore();
  txt(fmtMS(R.t), 480, py + 122, 54, '#ffffff', null, 0, 'center', UIF, 900);
  txt(tr('Tiempo') + ' ' + fmtMS(R.time) + '  ·  ' + tr('Caídas') + ' ' + R.deaths + ' (+' + R.deaths * 5 + ' s)', 480, py + 160, 13, 'rgba(255,255,255,.8)', null, 0, 'center', UIF, 700);
  if (R.rec && R.prev) { ctx.save(); ctx.globalAlpha = .75 + Math.sin(time * 6) * .25; txt('¡NUEVO RÉCORD!', 480, py + 200, 22, '#ffe27a', null, 0, 'center', UIF, 900); ctx.restore(); }
  else if (R.prev) txt(tr('Récord de hoy') + ': ' + fmtMS(R.prev), 480, py + 200, 15, '#ffe27a', null, 0, 'center', UIF, 800);
  if (R.first) txt('+' + (40 + R.g) + ' ◆  ·  🔥 ' + streakTxt(SAVE.dly.dstreak), 480, py + 236, 15, '#9dffd0', null, 0, 'center', UIF, 800);
  txt(tr('Mañana habrá una fase nueva'), 480, py + 268, 12, 'rgba(255,255,255,.6)', null, 0, 'center', UIF, 600);
  ctx.restore();
  for (const b of uiButtons()) drawButton(b);
}
function drawMToasts(dt) {
  if (!mtoasts.length) return;
  const T = mtoasts[0]; T.t += dt;
  const k = T.t < .35 ? T.t / .35 : T.t > 3 ? Math.max(0, 1 - (T.t - 3) / .35) : 1, e = 1 - Math.pow(1 - k, 3);
  const w = 400, h = 60, x = (W - w) / 2, y = H - e * (h + 18);
  ctx.save(); ctx.globalAlpha = Math.min(1, k * 1.4);
  glass(x, y, w, h, 16, '#3df5a0', true);
  txt(T.head, x + 20, y + 20, 11, '#3df5a0', null, 0, 'left', UIF, 800);
  txt(T.body, x + 20, y + 41, 15, '#ffffff', null, 0, 'left', UIF, 800);
  txt('+' + T.rw + ' ◆', x + w - 18, y + 33, 18, '#ffe27a', null, 0, 'right', UIF, 900);
  ctx.restore();
  if (T.t > 3.4) mtoasts.shift();
}
// la voz de «game over» ya no suena en cada caída (ahora se reintenta al instante)
const _sfxH = sfx;
sfx = function (k, v, r) { if (k === 'v_gameover' && !TOWER && !RUSH && !SECRET) return; return _sfxH(k, v, r); };
const _drawOverlayH = drawOverlay;
drawOverlay = function () {
  if (state === 'dailyDone' && dailyRes) { drawDailyDone(); return; }
  _drawOverlayH();
};
const _drawH = draw;
draw = function () {
  if (state === 'misiones') { state = misPrev || 'title'; try { _drawH(); } finally { state = 'misiones'; } drawMisiones(); for (const b of uiButtons()) drawButton(b); drawMToasts(1 / 60); return; }
  _drawH();
  if (state === 'clear' && clearRec && clearRec.prev) { ctx.save(); ctx.globalAlpha = .8 + Math.sin(time * 6) * .2; txt('¡NUEVO RÉCORD!  ' + fmtMS(clearRec.t), W / 2, 66, 18, '#ffe27a', null, 0, 'center', UIF, 900); ctx.restore(); }
  if (state === 'playing' && DAILY) txt(tr('RETO DIARIO') + '  ' + fmtMS(levelTime + DAILY.deaths * 5), W / 2, 22, 13, '#ffd0a0', null, 0, 'center', UIF, 900);
  if (state === 'title' && SAVE.intro && chestReady()) { const ox = W - 400; ctx.save(); ctx.globalAlpha = .5 + Math.sin(time * 5) * .5; ctx.strokeStyle = '#ffe27a'; ctx.lineWidth = 2; rrect(ox - 3, 11, 166, 40, 20); ctx.stroke(); ctx.restore(); }
  drawMToasts(1 / 60);
};
misEnsure();
