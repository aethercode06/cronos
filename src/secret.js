// =====================================================================
//  GRIETAS DEL TIEMPO: una fase secreta por mundo (v2.3)
//  En la FASE 2 de cada mundo hay una grieta escondida en lo alto.
//  Se ve tenue; en la dimensión violeta brilla. Al tocarla entras en
//  una fase corta llena de gemas. Al salir vuelves donde estabas.
// =====================================================================
let SECRET = null, secHinted = false;
ACH.push(['secreto1', 'Viajero de grietas', 'Supera tu primera Grieta del Tiempo'], ['secreto18', 'Cartógrafo del tiempo', 'Supera las 18 Grietas del Tiempo']);
function secCount() { return SAVE.sec ? Object.keys(SAVE.sec).length : 0; }
const _buildStageSec = buildStage;
buildStage = function (wi, act) {
  const L = _buildStageSec(wi, act);
  if (act !== 1 || (typeof TOWER_ON !== 'undefined' && TOWER_ON) || !L.goal) return L;
  const W = L.width || 4000; let best = null;
  for (const s of L.plats) if (s.float && s.k === 'solid' && s.x > W * .3 && s.x < W * .78 && s.w >= 32 && (!best || s.y < best.y)) best = s;
  if (!best) for (const s of L.plats) if (s.ground && s.x > W * .4 && s.w > 120) { best = s; break; }
  if (best) L.rift = { x: best.x + best.w / 2 - 18, y: best.y - 56, w: 36, h: 52, ph: 0 };
  return L;
};
function enterRift() {
  const w = curWorld;
  SECRET = { w, ret: { level, p: Object.assign({}, p), act: curAct, score, stageScore0, levelTime, tRun: typeof tRun !== 'undefined' ? tRun : null, dim, cam: { x: cam.x, y: cam.y } } };
  sfx('portal', .8); flash = .5; flashCol = '200,120,255';
  TOWER_ON = true; TOWER_SEED = 90001 + w * 977; TOWER_N = 5; TOWER_TRIAL = false;
  try { startStage(w, 1, false); } finally { TOWER_ON = false; }
  // fase llena de gemas: una fila sobre cada plataforma flotante
  const L = level; L.secret = true; L.rift = null;
  for (const s of L.plats) if (s.float && s.w >= 48) for (let x = s.x + 14; x < s.x + s.w - 10; x += 30) L.gems.push({ x, y: s.y - 26, taken: false, ph: Math.random() * 6 });
  for (const e of L.enemies) e.hp = Math.max(1, e.hp - 1);
  dlg = null; loreT = 0; score = SECRET.ret.score; stageScore0 = score;
  banner('GRIETA DEL TIEMPO', WORLDS[w].name + '  ·  ¡recoge todo lo que puedas!', '#c890ff', 2.6);
}
function leaveRift(won) {
  const S = SECRET; if (!S) return; SECRET = null;
  const R = S.ret, got = level.gems.filter(g => g.taken).length;
  if (won) {
    SAVE.sec = SAVE.sec || {}; const first = !SAVE.sec[S.w]; SAVE.sec[S.w] = 1;
    SAVE.bank = (SAVE.bank || 0) + got + (first ? 30 : 0); achGive('secreto1'); if (secCount() >= 18) achGive('secreto18'); persist();
  }
  level = R.level; Object.assign(p, R.p); curAct = R.act; levelTime = R.levelTime; stageScore0 = R.stageScore0;
  if (won) score += got * 10; else score = R.score;
  dim = R.dim; boss = null; arenaLock = false; bossIntro = 0; projs = []; waves = []; warns = []; fx = []; parts = []; echo = null; dlg = null;
  if (typeof tRun !== 'undefined') tRun = R.tRun;
  p.dead = false; p.deadT = 0; p.inv = 1.5; p.vx = 0; p.vy = 0; if (!won) p.hp = Math.max(25, Math.round(R.p.hp * .6));
  if (level.rift) level.rift.used = true;
  setView(EXW(), EXH); try { resetLive(); spawnLife(); spawnSwarms(); spawnGiants(); } catch (e) {}
  updateCamera(0, true); state = 'playing'; fade = 1; playMusic(WORLDS[curWorld].music); try { startAmbience(curWorld); } catch (e) {}
  if (won) { banner('¡GRIETA SUPERADA!', '+' + got + ' gemas' + (SAVE.sec && secCount() ? '   ·   Grietas: ' + secCount() + ' / 18' : ''), '#c890ff', 2.6); sfx('relic', .8); }
  else banner('LA GRIETA SE CERRÓ', 'Vuelves a la fase con menos vida', '#ff7a9a', 2.2);
}
const _stageClearSec = stageClear;
stageClear = function () { if (SECRET) { if (state === 'playing') leaveRift(true); return; } _stageClearSec(); };
const _updEnemiesSec = updateEnemies;
updateEnemies = function (dt) {
  _updEnemiesSec(dt);
  const R = level.rift;
  if (R && !R.used && !SECRET && !p.dead) {
    R.ph += dt; const cx = R.x + R.w / 2, d = Math.hypot(p.x + p.w / 2 - cx, p.y + p.h / 2 - (R.y + R.h / 2));
    if (d < 320 && !secHinted && !(SAVE.fh && SAVE.fh.rift) && !ticSay && !dlg) { secHinted = true; SAVE.fh = SAVE.fh || {}; SAVE.fh.rift = 1; persist(); tSay('Siento una grieta del tiempo cerca… en la dimensión violeta brilla más. ¡Búscala arriba!', 4.5); }
    if (overlap(p, R)) enterRift();
  }
};
// salir de la fase (mapa, título, reintentar) cierra la grieta sin restaurar nada
const _toMapSec = toMap; toMap = function () { SECRET = null; _toMapSec(); };
const _toTitleSec = toTitle; toTitle = function () { SECRET = null; _toTitleSec(); };
const _retrySec = retry; retry = function () { if (SECRET) { leaveRift(false); return; } _retrySec(); };
const _drawProjsSec = drawProjs;
drawProjs = function () {
  _drawProjsSec();
  const R = level && level.rift; if (!R || R.used || SECRET || !onScreen(R.x, R.w)) return;
  const cx = R.x + R.w / 2, cy = R.y + R.h / 2, on = dim === 1, a = on ? 1 : 0.32 + Math.sin(time * 2) * 0.06;
  glowAt(cx, cy, on ? 60 : 34, 'rgba(190,110,255,.8)', a * .9);
  bx.save(); bx.globalAlpha = a; bx.translate(Math.round(cx), Math.round(cy));
  for (let i = 0; i < 3; i++) { bx.strokeStyle = i === 1 ? '#ffffff' : '#c890ff'; bx.lineWidth = i === 1 ? 1.5 : 2.5; bx.beginPath(); bx.ellipse(0, 0, 9 + i * 4 + Math.sin(time * 3 + i) * 1.5, 20 + i * 4, Math.sin(time + i) * .2, time * (1 + i * .5), time * (1 + i * .5) + 4.6); bx.stroke(); }
  bx.restore();
  if (on && Math.random() < .3) parts.push({ x: cx + rnd(-14, 14), y: cy + rnd(-20, 20), vx: rnd(-20, 20), vy: rnd(-40, -10), life: .6, max: .6, c: '#d8b0ff', s: 2, g: -40 });
};
// contador de grietas en el mapa
const _drawSec = draw;
draw = function () {
  if (SECRET && p && p.dead && (state === 'gameover' || p.deadT < 0.8)) leaveRift(false);
  _drawSec();
  if (state === 'map') { const n = secCount(); pill(18, H - 40, 168, 26, 'rgba(60,30,100,.85)', 'rgba(110,50,170,.85)'); txt('✦ Grietas del Tiempo: ' + n + '/18', 102, H - 27, 11, '#ecd8ff', null, 0, 'center', UIF, 800); }
  if (SECRET && state === 'playing') txt('✦ GRIETA DEL TIEMPO ✦', W / 2, 94, 13, '#e0c0ff', null, 0, 'center', UIF, 900);
};
