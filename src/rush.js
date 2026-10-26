// =====================================================================
//  MODO PESADILLA (dificultad extra con premios) y BOSS RUSH
//  (los 18 guardianes seguidos, con la vida que te quede de uno a otro)
// =====================================================================
let nmMsgT = 0;
function nmUnlocked() { return PRUEBA || !!SAVE.done || bossesDoneR() >= 18; }
function bossesDoneR() { let n = 0; for (let i = 0; i < ORDER.length; i++) { const st = SAVE.st[i * 3 + 2]; if (st && st.done) n++; } return n; }
ACH.push(['pesadilla1', 'Sueño intranquilo', 'Vence a un guardián en Pesadilla'], ['pesadilla18', 'Señor de las pesadillas', 'Vence a los 18 guardianes en Pesadilla'],
  ['rush6', 'Sin respiro', 'Vence a 6 guardianes seguidos en el Boss Rush'], ['rush18', 'Leyenda del tiempo', 'Completa el Boss Rush entero']);
// en Pesadilla los enemigos aguantan un golpe más y las gemas valen el doble
const _buildStageN = buildStage;
buildStage = function (wi, act) {
  const L = _buildStageN(wi, act);
  if (DIFFS[diffIdx] && DIFFS[diffIdx].nm) for (const e of L.enemies) e.hp += 1;
  return L;
};
const _stageClearN = stageClear;
stageClear = function () {
  if (RUSH) { if (state === 'playing') rushNext(); return; }
  const nm = DIFFS[diffIdx] && DIFFS[diffIdx].nm, was = state === 'playing', w = curWorld, a = curAct;
  const g = was && level ? level.gems.filter(x => x.taken).length : 0;
  _stageClearN();
  if (nm && was && state !== 'playing') {
    SAVE.bank = (SAVE.bank || 0) + g; // el doble de gemas
    if (a === 2) { SAVE.nm = SAVE.nm || {}; SAVE.nm[w] = 1; achGive('pesadilla1'); if (Object.keys(SAVE.nm).length >= 18) achGive('pesadilla18'); }
    persist();
  }
};
// ---------------- Boss Rush ----------------
let RUSH = null, rushMsgT = 0;
function rushUnlocked() { return PRUEBA || bossesDoneR() >= 3; }
function startRush() {
  RUSH = { i: 0, hp: null, t: 0, beaten: 0 };
  score = 0; stageScore0 = 0; rushStage();
}
function rushStage() {
  const R = RUSH, w = ORDER[R.i];
  startStage(w, 2, false);
  stageScore0 = score; dlg = null; loreT = 0; p.rewindUsed = true;
  const A = level.arena;
  if (A) { p.x = A.x1 + 24; p.y = A.floor - p.h - 1; p.respawn = { x: p.x, y: p.y }; p.safe = p.respawn; updateCamera(0, true); }
  if (R.hp !== null) { p.hp = Math.min(p.maxHp, R.hp + 30); addFloat(p.x + p.w / 2, p.y - 24, '+30 vida', '#ff7ab0', 15); }
  banner('BOSS RUSH  ·  ' + (R.i + 1) + ' / ' + ORDER.length, WORLDS[w].boss.name, '#ff7a5a', 2.4);
}
function rushNext() {
  const R = RUSH; if (!R) return;
  R.beaten++; R.hp = p.hp; addScore(1000 + R.beaten * 150);
  if (R.beaten > (SAVE.rushMax || 0)) SAVE.rushMax = R.beaten;
  if (R.beaten >= 6) achGive('rush6');
  sfx('portal', .7); sfx('win', .5); flash = .3; flashCol = '255,150,110';
  if (R.i >= ORDER.length - 1) {
    achGive('rush18'); if (!SAVE.rushBest || R.t < SAVE.rushBest) SAVE.rushBest = R.t;
    saveBest(); persist(); R.done = true; boss = null; state = 'gameover'; fade = 0.6; playMusic('menu'); return;
  }
  saveBest(); persist(); if (boss && boss.done) boss = null;
  R.i++; rushStage();
}
function endRush() { RUSH = null; }
const _toMapR = toMap; toMap = function () { endRush(); _toMapR(); };
const _toTitleR = toTitle; toTitle = function () { endRush(); _toTitleR(); };
const _beginStageR = beginStage; beginStage = function (w, a) { endRush(); _beginStageR(w, a); };
const _retryR = retry; retry = function () { if (RUSH) { startRush(); return; } _retryR(); };
const _startTowerR = startTower; startTower = function () { endRush(); _startTowerR(); };
const _uiButtonsR = uiButtons;
uiButtons = function () {
  const B = _uiButtonsR(), ox = Math.round((W - 960) / 2);
  if (state === 'gameover' && RUSH) {
    return [{ x: ox + 350, y: 340, w: 260, h: 48, t: RUSH.done ? 'JUGAR OTRA VEZ' : 'REINTENTAR BOSS RUSH', ic: 'time', c: '#ff9a6a', c2: '#ff5a5a', sel: true, fn: startRush },
            { x: ox + 350, y: 400, w: 260, h: 48, t: 'TÍTULO', ic: 'left', c: '#35e2ff', c2: '#7a5cff', fn: toTitle }];
  }
  if (state === 'title') {
    const row = B.filter(q => q.y === 406), ok = rushUnlocked();
    row.push({ x: 0, y: 406, w: 150, h: 40, t: 'BOSS RUSH', ic: ok ? 'skull' : 'lock', c: '#ff9a6a', small: true,
      fn: ok ? () => { goFull(); sfx('select'); startRush(); } : () => { sfx('clang', .4); rushMsgT = 2.6; } });
    if (row.length) { const w = 146, gap = 8, x0 = ox + 480 - (row.length * w + (row.length - 1) * gap) / 2; row.forEach((q, i) => { q.x = Math.round(x0 + i * (w + gap)); q.w = w; }); }
    B.push(row[row.length - 1]);
  }
  return B;
};
const _drawOverlayR = drawOverlay;
drawOverlay = function () {
  if (state === 'gameover' && RUSH) {
    ctx.fillStyle = 'rgba(6,4,16,.62)'; ctx.fillRect(0, 0, W, H);
    const ox = Math.round((W - 960) / 2), py = Math.round((H - 410) / 2);
    ctx.save(); ctx.translate(ox, 0); glass(220, py, 520, 410, 24, '#ff9a6a', true);
    ctx.save(); ctx.shadowColor = 'rgba(255,140,100,.7)'; ctx.shadowBlur = 22; txt(RUSH.done ? '¡BOSS RUSH COMPLETADO!' : 'BOSS RUSH', 480, py + 52, 26, '#ffd0b0', null, 0, 'center', LOGOF, 900); ctx.restore();
    txt('Guardianes vencidos: ' + RUSH.beaten + ' / ' + ORDER.length, 480, py + 108, 20, '#ffffff', null, 0, 'center', UIF, 800);
    txt('Tiempo: ' + fmtMS(RUSH.t) + (SAVE.rushBest ? '   ·   Mejor tiempo: ' + fmtMS(SAVE.rushBest) : ''), 480, py + 140, 14, '#ffe27a', null, 0, 'center', UIF, 700);
    txt('Récord: ' + (SAVE.rushMax || 0) + ' guardianes   ·   Puntos: ' + score, 480, py + 166, 13, 'rgba(255,255,255,.85)', null, 0, 'center', UIF, 600);
    ctx.restore();
    for (const b of uiButtons()) drawButton(b);
    return;
  }
  _drawOverlayR();
};
let lastDrawR = performance.now();
const _drawR = draw;
draw = function () {
  const now = performance.now(), dt = Math.min(.05, (now - lastDrawR) / 1000); lastDrawR = now;
  _drawR();
  if (RUSH && dlg && dlg.hold) dlg.hold = false;
  if (RUSH && state === 'playing') { RUSH.t += dt; txt('BOSS RUSH  ' + (RUSH.i + 1) + '/' + ORDER.length + '   ·   ' + fmtMS(RUSH.t), W / 2, 94, 13, '#ffc0a0', null, 0, 'center', UIF, 900); }
  if (state === 'title') {
    if (SAVE.rushMax) txt('Boss Rush: ' + SAVE.rushMax + ' guardianes' + (SAVE.rushBest ? ' · ' + fmtMS(SAVE.rushBest) : ''), W / 2, 476, 11, 'rgba(255,200,170,.9)', null, 0, 'center', UIF, 700);
    if (rushMsgT > 0) { rushMsgT -= dt; const ox = Math.round((W - 960) / 2); pill(ox + 250, 456, 460, 30, '#5a2a1a', '#8a3a2a'); txt('Vence a 3 guardianes para abrir el Boss Rush', W / 2, 471, 13, '#ffffff', null, 0, 'center', UIF, 700); }
  }
  if (state === 'map' && nmMsgT > 0) { nmMsgT -= dt; pill(W / 2 - 250, 64, 500, 30, '#3a1a5a', '#6a2a9a'); txt('Termina la historia para desbloquear el Modo Pesadilla', W / 2, 79, 13, '#ffffff', null, 0, 'center', UIF, 700); }
};
