// =====================================================================
//  ESTRELLAS POR FASE  y  TORRE DEL TIEMPO (modo infinito)
// =====================================================================
// ---------------- estrellas ----------------
function stagePar(L, act) { return act === 2 ? (diffIdx === 0 ? 100 : 80) : Math.round((L.width || 4000) / 150 + 15); }
function fmtMS(t) { t = Math.max(0, Math.floor(t)); return Math.floor(t / 60) + ':' + String(t % 60).padStart(2, '0'); }
function starsOf(s) { const st = SAVE.st[s]; return st && st.stars ? st.stars : (st && st.done ? 1 : 0); }
function starsTotal() { let n = 0; for (let s = 0; s <= LAST; s++) n += starsOf(s); return n; }
let lastStars = null;
const _stageClear19 = stageClear;
stageClear = function () {
  if (state !== 'playing') return;
  if (TOWER) { towerNext(); return; }
  const L = level, act = curAct, t = levelTime, par = stagePar(L, act), s = sIdx(curWorld, curAct);
  const g = L.gems.filter(x => x.taken).length, tot = L.gems.length;
  const c2 = act === 2 ? stageDeaths === 0 : (tot ? g / tot >= 0.8 : true), c3 = t <= par;
  _stageClear19();
  const st = SAVE.st[s]; if (!st) return;
  const prev = st.starMask || 1, mask = 1 | (c2 ? 2 : 0) | (c3 ? 4 : 0) | prev;
  st.starMask = mask; st.stars = (mask & 1 ? 1 : 0) + (mask & 2 ? 1 : 0) + (mask & 4 ? 1 : 0);
  lastStars = { got: [true, c2, c3], par, t, act, newBest: mask !== prev, t0: performance.now() };
  persist(); achCheck();
  const n = starsTotal(); if (n >= 42) achGive('est42'); if (n >= ORDER.length * 9) achGive('est126');
};
function drawStar5(cx, cy, r, fill, stroke) {
  ctx.beginPath(); for (let i = 0; i < 10; i++) { const a = -Math.PI / 2 + i * Math.PI / 5, rr = i % 2 ? r * .45 : r; ctx.lineTo(cx + Math.cos(a) * rr, cy + Math.sin(a) * rr); }
  ctx.closePath(); if (fill) { ctx.fillStyle = fill; ctx.fill(); } if (stroke) { ctx.strokeStyle = stroke; ctx.lineWidth = 1.5; ctx.stroke(); }
}
function drawClearStars() {
  const S = lastStars; if (!S || state !== 'clear' || TOWER) return;
  const ox = Math.round((W - 960) / 2), py = Math.round((H - 410) / 2), e = (performance.now() - S.t0) / 1000;
  const lab = [S.act === 2 ? 'Superada' : 'Superada', S.act === 2 ? 'Sin caer' : 'Fragmentos ≥ 80 %', 'Tiempo ≤ ' + fmtMS(S.par)];
  for (let i = 0; i < 3; i++) {
    const x = ox + 480 + (i - 1) * 120, y = py + 226, k = Math.min(1, Math.max(0, (e - 0.25 - i * 0.28) / 0.3)), sc = k < 1 ? 0.6 + k * 0.7 : 1.3 - Math.min(0.3, (e - 0.55 - i * 0.28) * 1.2);
    ctx.save(); ctx.translate(x, y); ctx.scale(Math.max(.01, sc), Math.max(.01, sc));
    if (S.got[i] && k > 0) { ctx.shadowColor = 'rgba(255,210,90,.9)'; ctx.shadowBlur = 20 * k; drawStar5(0, 0, 22, '#ffd34d', '#fff2b0'); }
    else drawStar5(0, 0, 22, 'rgba(255,255,255,.08)', 'rgba(255,255,255,.3)');
    ctx.restore();
    txt(lab[i], x, y + 36, 11, S.got[i] ? '#ffe9a8' : 'rgba(255,255,255,.45)', null, 0, 'center', UIF, 700);
    if (k > 0 && k < 0.15 && S.got[i] && !S['s' + i]) { S['s' + i] = 1; sfx('gem', .6, 1 + i * .15); }
  }
}
// estrellas pequeñas bajo cada botón de fase del mapa y total en la cabecera
function drawMapStars() {
  if (state !== 'map') return;
  for (let pos = mapPage * 6; pos < Math.min(ORDER.length, mapPage * 6 + 6); pos++) {
    const w = ORDER[pos], { x: cx, y: cy } = mapCard(pos);
    for (let a = 0; a < 3; a++) {
      const s = sIdx(w, a); if (s > SAVE.unl) continue; const n = starsOf(s), bx0 = cx + 8 + a * 92 + 43;
      for (let i = 0; i < 3; i++) drawStar5(bx0 + (i - 1) * 11, cy + 203, 4.2, i < n ? '#ffd34d' : 'rgba(255,255,255,.18)');
    }
  }
  drawStar5(156, 36, 7, '#ffd34d'); txt(starsTotal() + '/' + ((LAST + 1) * 3), 168, 37, 12, '#ffe27a', null, 0, 'left', UIF, 800);
}

// ---------------- Torre del Tiempo ----------------
let TOWER = null, towerMsgT = 0;
function towerUnlocked() { const st = SAVE.st[sIdx(0, 2)]; return !!(st && st.done); }
function towerWorlds() { const out = []; for (let pos = 0; pos < ORDER.length; pos++) if (pos * 3 <= SAVE.unl) out.push(ORDER[pos]); return out.length ? out : [0]; }
function startTower() {
  TOWER = { floor: 0, hp: null, score: 0, seed: Math.floor(Math.random() * 1e6) };
  score = 0; stageScore0 = 0; towerFloor(true);
}
function towerFloor(first) {
  const T = TOWER; T.floor++;
  const ws = towerWorlds(), boss = T.floor % 10 === 0;
  let wi = ws[Math.floor(Math.random() * ws.length)], act = boss ? 2 : (Math.random() < .5 ? 0 : 1);
  if (act === 0 && wi === 0) act = 1; if (boss && wi === 2) wi = ws.find(w => w !== 2) ?? 0;
  TOWER_ON = true; TOWER_SEED = T.seed + T.floor * 7919; TOWER_N = boss ? 2 : Math.min(10, 4 + Math.floor(T.floor / 3)); TOWER_TRIAL = !boss && T.floor % 5 === 0;
  const hp = T.hp;
  try { startStage(wi, act, false); } finally { TOWER_ON = false; }
  stageScore0 = score;
  // los enemigos se endurecen con cada piso
  const k = 1 + T.floor * 0.07;
  for (const e of level.enemies) e.hp = Math.ceil(e.hp * k);
  if (level.trials) for (const t of level.trials) for (const wv of t.waves) for (const e of wv) e.hp = Math.ceil(e.hp * k);
  if (hp !== null) { p.hp = Math.min(p.maxHp, hp + 25); addFloat(p.x + p.w / 2, p.y - 24, '+25 vida', '#ff7ab0', 15); }
  p.rewindUsed = true;   // la Segunda Oportunidad no vale en la Torre
  dlg = null; loreT = 0;
  banner('TORRE DEL TIEMPO', (boss ? '¡GUARDIÁN DE LA TORRE!  ·  ' : '') + 'PISO ' + T.floor + '  ·  ' + WORLDS[wi].name, boss ? '#ff5470' : '#b89cff', 2.6);
}
function towerNext() {
  const T = TOWER; if (!T) return;
  T.hp = p.hp; addScore(500 + T.floor * 100);
  SAVE.bank = (SAVE.bank || 0) + level.gems.filter(x => x.taken).length;
  if (T.floor > (SAVE.towerBest || 0)) SAVE.towerBest = T.floor;
  if (T.floor >= 10) achGive('torre10'); if (T.floor >= 25) achGive('torre25');
  saveBest(); persist(); sfx('portal', .7); sfx('win', .5); flash = .3; flashCol = '190,160,255';
  if (boss && boss.done) boss = null;
  towerFloor(false);
}
function endTower() { TOWER = null; TOWER_ON = false; }
const _toMap19 = toMap; toMap = function () { endTower(); _toMap19(); };
const _toTitle19 = toTitle; toTitle = function () { endTower(); _toTitle19(); };
const _beginStage19 = beginStage; beginStage = function (w, a) { endTower(); _beginStage19(w, a); };
const _retry19 = retry; retry = function () { if (TOWER) { startTower(); return; } _retry19(); };
// en la Torre no hay puntos de control al caer
const _uiButtons19 = uiButtons;
uiButtons = function () {
  const B = _uiButtons19();
  if (state === 'gameover' && TOWER) {
    const ox = Math.round((W - 960) / 2);
    return [{ x: ox + 350, y: 330, w: 260, h: 48, t: 'REINTENTAR TORRE', ic: 'time', c: '#b89cff', c2: '#7a5cff', sel: true, fn: startTower },
            { x: ox + 350, y: 390, w: 260, h: 48, t: 'MAPA', ic: 'flag', c: '#35e2ff', c2: '#7a5cff', fn: toMap }];
  }
  if (state === 'title') {
    const ok = towerUnlocked(), ox = Math.round((W - 960) / 2), row = B.filter(q => q.y === 406);
    row.forEach((q, i) => { q.x = ox + 162 + i * 162; q.w = 150; });
    B.push({ x: ox + 162 + row.length * 162, y: 406, w: 150, h: 40, t: 'TORRE', ic: ok ? 'flag' : 'lock', c: '#b89cff', small: true,
      fn: ok ? () => { goFull(); sfx('select'); startTower(); } : () => { sfx('clang', .4); towerMsgT = 2.6; } });
  }
  return B;
};
const _drawOverlay19 = drawOverlay;
drawOverlay = function () {
  if (state === 'gameover' && TOWER) {
    ctx.fillStyle = 'rgba(6,4,16,.6)'; ctx.fillRect(0, 0, W, H);
    const ox = Math.round((W - 960) / 2), py = Math.round((H - 410) / 2);
    ctx.save(); ctx.translate(ox, 0); glass(220, py, 520, 410, 24, '#b89cff', true);
    ctx.save(); ctx.shadowColor = 'rgba(180,150,255,.7)'; ctx.shadowBlur = 22; txt('TORRE DEL TIEMPO', 480, py + 52, 26, '#d8c8ff', null, 0, 'center', LOGOF, 900); ctx.restore();
    txt('Piso alcanzado: ' + TOWER.floor, 480, py + 112, 22, '#ffffff', null, 0, 'center', UIF, 800);
    txt('Récord de la Torre: piso ' + (SAVE.towerBest || 0), 480, py + 146, 14, '#ffe27a', null, 0, 'center', UIF, 700);
    txt('Puntos: ' + score, 480, py + 172, 14, 'rgba(255,255,255,.85)', null, 0, 'center', UIF, 600);
    ctx.restore();
    for (const b of uiButtons()) drawButton(b);
    return;
  }
  _drawOverlay19();
};
// el banner del mapa también se ve fuera de las fases
const _draw19 = draw;
draw = function () {
  _draw19();
  if (state === 'clear') drawClearStars();
  if (state === 'map') drawMapStars();
  if (state === 'title') {
    if (SAVE.towerBest) txt('Récord de la Torre: piso ' + SAVE.towerBest, W / 2, 462, 11, 'rgba(210,190,255,.9)', null, 0, 'center', UIF, 700);
    if (towerMsgT > 0) { towerMsgT -= 1 / 60; const ox = Math.round((W - 960) / 2); pill(ox + 250, 456, 460, 30, '#3a2a6a', '#5a3a9a'); txt('Vence al primer guardián para abrir la Torre', W / 2, 471, 13, '#ffffff', null, 0, 'center', UIF, 700); }
  }
  if (TOWER && state === 'playing') txt('PISO ' + TOWER.floor, W / 2, 22, 13, '#d8c8ff', null, 0, 'center', UIF, 900);
};
// la Torre se guarda en los logros
ACH.push(['est42', 'Coleccionista de estrellas', 'Consigue 42 estrellas'], ['est126', 'Perfección temporal', 'Consigue las 162 estrellas'],
  ['torre10', 'Escalador del tiempo', 'Llega al piso 10 de la Torre'], ['torre25', 'Señor de la Torre', 'Llega al piso 25 de la Torre']);
