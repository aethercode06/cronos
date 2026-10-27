// =====================================================================
//  RIESGO DE VERDAD (v3.1): sin dificultad no hay emoción
//  · Vidas por fase: Normal 3, Difícil 2, Pesadilla 1 (Fácil ilimitadas).
//    Sin vidas, la fase empieza de nuevo desde el principio.
//  · Caer a un vacío o a la lava mata (Normal en adelante), como en Mario.
//  · Menos puntos de control: 2 por fase en Normal, 1 en Difícil y Pesadilla.
//  · Cada 50 fragmentos recogidos en una fase: +1 vida (máx. 5).
// =====================================================================
const LIVES_BY = [99, 3, 2, 1];
let lives = 3, livesGemMark = 0, livesFresh = true;
const stakesOn = () => diffIdx >= 1 && !TOWER && !RUSH;
function livesLeft() { return stakesOn() ? lives : 99; }
function loseLife() {
  if (!stakesOn() || SECRET) return false;
  lives--;
  if (lives > 0) return false;
  // sin vidas: la fase entera otra vez
  const w = curWorld, a = curAct, d = DAILY;
  score = stageScore0; livesFresh = true;
  if (d) { startDaily(); DAILY.deaths = d.deaths; } else startStage(w, a, false);
  fade = 1; sfx('lose', .8);
  banner(tr('¡SIN VIDAS!'), tr('La fase empieza de nuevo'), '#ff4d6d', 2.2);
  return true;
}
// al entrar en una fase (no al reaparecer): vidas completas
const _startStageK = startStage;
startStage = function (wi, act, fresh) { _startStageK(wi, act, fresh); lives = LIVES_BY[diffIdx] || 3; livesGemMark = 0; };
// vacíos y lava: muerte en Normal y superiores (las púas siguen quitando vida)
const _hazK = hazardRespawn;
hazardRespawn = function (dmg) {
  if (stakesOn() && !SECRET && dmg >= 20 && !p.dead) { p.hp = 0; sfx('hurt'); shake = 10; kill(); return; }
  return _hazK(dmg);
};
// menos puntos de control
const _buildStageK = buildStage;
buildStage = function (wi, act) {
  const L = _buildStageK(wi, act);
  if (diffIdx < 1 || TOWER_ON || (wi === 2 && act === 2) || !L.checks || L.checks.length < 2) return L;
  const end = L.goal ? L.goal.x : L.arena ? L.arena.x1 : L.width, keep = new Set();
  const targets = diffIdx === 1 ? [0.4, 0.75] : [0.55];
  for (const t of targets) { let best = null, bd = 1e9; for (const c of L.checks) { const d = Math.abs(c.x - end * t); if (d < bd && !keep.has(c)) { bd = d; best = c; } } if (best) keep.add(best); }
  if (L.arena) { let best = null, bd = 1e9; for (const c of L.checks) { const d = Math.abs(c.x - L.arena.x1); if (d < bd) { bd = d; best = c; } } if (best) keep.add(best); }
  L.checks = L.checks.filter(c => keep.has(c));
  return L;
};
// +1 vida cada 50 fragmentos de la fase
const _updateK = update;
update = function (dt) {
  _updateK(dt);
  if (state !== 'playing' || !level || !stakesOn()) return;
  const g = level.gems.filter(x => x.taken).length;
  if (g >= livesGemMark + 50) { livesGemMark += 50; if (lives < 5) { lives++; addFloat(p.x + p.w / 2, p.y - 30, tr('¡+1 VIDA!'), '#ff7ab0', 20); sfx('relic', .7, 1.3); } }
};
// corazones en pantalla
const _drawK = draw;
draw = function () {
  _drawK();
  if (state !== 'playing' || !stakesOn() || bossIntro > 0) return;
  const n = lives, x0 = 26, y0 = tallOn ? 118 : 114;
  ctx.save();
  for (let i = 0; i < Math.min(n, 5); i++) {
    const x = x0 + i * 22, y = y0, pul = n === 1 ? 1 + Math.sin(time * 8) * 0.12 : 1;
    ctx.save(); ctx.translate(x, y); ctx.scale(pul, pul);
    ctx.fillStyle = n === 1 ? '#ff3050' : '#ff5470'; ctx.strokeStyle = 'rgba(0,0,0,.6)'; ctx.lineWidth = 2;
    ctx.beginPath(); ctx.moveTo(0, 6); ctx.bezierCurveTo(-11, -2, -6, -11, 0, -5); ctx.bezierCurveTo(6, -11, 11, -2, 0, 6); ctx.closePath(); ctx.stroke(); ctx.fill();
    ctx.restore();
  }
  ctx.restore();
};
// ---------------- Kael ya no es casi invencible (v3.4) ----------------
// (el daño recibido sube en DIFFS de data.js: Normal ×1,5, Difícil ×2,1, Pesadilla ×2,5)
// menos invencibilidad tras un golpe
const _hurtK = hurt;
hurt = function (dmg, srcX) { const r = _hurtK(dmg, srcX); if (r && diffIdx >= 1 && p.inv > 0.6) p.inv = 0.6; return r; };
// la Segunda Oportunidad deja a Kael con solo el 25 % de vida
const _killK = kill;
kill = function () { _killK(); if (diffIdx >= 1 && !p.dead && p.rewindUsed && p.hp > p.maxHp * 0.25) p.hp = Math.round(p.maxHp * 0.25); };
// el escudo se gasta más rápido al bloquear (la parada perfecta no)
const _blockHitK = blockHit;
blockHit = function (dmg, srcX, proj) {
  const perfect = hasAb('parada') && p.guardT < 0.22;
  if (!perfect && diffIdx >= 1) p.gst = (p.gst || 0) - dmg * (diffIdx >= 2 ? 2.2 : 1.6);
  return _blockHitK(dmg, srcX, proj);
};
