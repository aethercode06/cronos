// =====================================================================
//  CRIATURAS MÁS LISTAS (v3.3)
//  Antes: los caminantes iban y venían sin hacerte caso, los voladores
//  repetían el mismo vaivén, los disparos iban a donde estabas y cada
//  golpe los empujaba lejos sin que pudieran responder.
//  Ahora (más cuanto más avanzas; suave en Fácil):
//  · Te ven, te persiguen y atacan: aviso «!» y embestida hacia ti.
//  · Esquivan tus espadazos saltando hacia atrás (¡ESQUIVA!).
//  · Tras dos golpes seguidos aguantan el empuje y contraatacan.
//  · Los voladores te siguen desde arriba y disparan a donde vas a estar.
//  · Los saltarines calculan el salto para caerte encima.
//  · Al verte, avisan a los de alrededor.
// =====================================================================
const foeG = () => clamp((typeof WPOS === 'function' ? WPOS(curWorld) : 0) / (ORDER.length - 1), 0, 1);
const foeK = () => diffIdx === 0 ? 0.45 : diffIdx === 1 ? 1 : 1.25;
const GROUNDERS = { walker: 1, chaser: 1 };
const _updEnemiesAI = updateEnemies;
updateEnemies = function (dt) {
  const g = foeG(), K = foeK(), D = DIFFS[diffIdx], pcx = p.x + p.w / 2, pcy = p.y + p.h / 2;
  // los caminantes y perseguidores que te ven pasan a nuestro control este fotograma
  const mine = [];
  for (const e of level.enemies) {
    if (e.dead || !GROUNDERS[e.b] || Math.abs(e.x - cam.x - VW / 2) > 900) continue;
    const dx = pcx - (e.x + e.w / 2), dy = pcy - (e.y + e.h / 2);
    const range = 210 + 120 * g + (e.aggro > 0 ? 160 : 0);
    const sees = !p.dead && Math.abs(dx) < range && Math.abs(dy) < 90;
    if (sees || (e.ai && e.ai.st !== 'idle')) { mine.push([e, e.b]); e.b = 'ai_' + e.b; }
  }
  _updEnemiesAI(dt);
  for (const [e, b] of mine) { e.b = b; foeBrain(e, dt, g, K, D, pcx, pcy); }
  for (const e of level.enemies) {
    if (e.dead || Math.abs(e.x - cam.x - VW / 2) > 900) continue;
    if (e.aggro > 0) e.aggro -= dt;
    const cx = e.x + e.w / 2, dx = pcx - cx, dy = pcy - (e.y + e.h / 2);
    // voladores: te siguen por arriba
    if (e.b === 'flyer' && Math.hypot(dx, dy) < 420 + 80 * g && !p.dead) {
      const side = e.x0 < pcx ? -1 : 1, tx = pcx - e.w / 2 + side * (70 - 30 * g), ty = p.y - 100 - 20 * Math.sin(e.t);
      e.x0 = lerp(e.x0, tx, dt * (0.5 + 0.7 * g) * K); e.y0 = lerp(e.y0, clamp(ty, level.top + 20, GY - 140), dt * 0.6 * K);
    }
    // fantasmas más rápidos
    if (e.b === 'ghost' && Math.hypot(dx, dy) < 320) { const dd = Math.hypot(dx, dy) || 1; e.x += dx / dd * (25 + 45 * g) * K * D.spd * dt; e.y += dy / dd * (15 + 25 * g) * K * D.spd * dt; }
    // saltarines: calculan el salto para caerte encima
    if (e.b === 'jumper' && e.air && !e._aimed && e.vy < -300) { e._aimed = true; const vx = clamp(dx / 0.62, -270, 270) * (0.6 + 0.4 * K), lx = e.x + e.w / 2 + vx * 0.62; if (groundBelow(lx, GY - 200, 420) && groundBelow(lx - Math.sign(vx) * 20, GY - 200, 420)) e.vx = vx; }
    if (e.b === 'jumper' && !e.air) e._aimed = false;
    // buceadores: atacan más a menudo
    if (e.b === 'diver' && e.st === 'hover' && e.cd > 0) e.cd -= dt * (0.4 + 0.8 * g) * K;
    // esquivar el espadazo: salto atrás
    if ((e.b === 'walker' || e.b === 'chaser' || e.b === 'brute' || e.b === 'shield') && p.atkT > 0.18 && !e.hit && Math.abs(dx) < 62 && Math.abs(dy) < 50 && (p.face > 0) === (dx < 0)) {
      e.dodgeCD = (e.dodgeCD || 0);
      if (e.dodgeCD <= 0 && !e._dodgeRoll) {
        e._dodgeRoll = true;
        if (Math.random() < (0.08 + 0.3 * g) * K) { e.kx = (dx > 0 ? -1 : 1) * 300; e.dodgeCD = 2.2; e.alert = 0.25; addFloat(cx, e.y - 10, tr('¡ESQUIVA!'), '#bfe6ff', 13); sfx('dash', .3, 1.4); dust(cx, e.y + e.h, 5); }
      }
    }
    if (p.atkT <= 0) e._dodgeRoll = false;
    if (e.dodgeCD > 0) e.dodgeCD -= dt;
  }
};
// cerebro de los enemigos de tierra: perseguir, avisar, embestir, recuperarse
function foeBrain(e, dt, g, K, D, pcx, pcy) {
  const d = e.d, cx = e.x + e.w / 2, dx = pcx - cx, adx = Math.abs(dx);
  const ai = e.ai || (e.ai = { st: 'idle', t: 0 });
  if (ai.st === 'idle' && !e.aggroSent) {
    e.aggroSent = true;
    for (const o of level.enemies) if (o !== e && !o.dead && Math.abs(o.x - e.x) < 260 && Math.abs(o.y - e.y) < 120) o.aggro = 3;   // avisa a los de alrededor
  }
  ai.t -= dt;
  const walk = (sp, dir) => {
    if (e.hit > 0) return;
    const nx = e.x + dir * sp * D.spd * dt, fx_ = dir > 0 ? nx + e.w + 2 : nx - 2;
    if (groundBelow(fx_, e.y + e.h, 14)) e.x = nx;
  };
  if (ai.st === 'idle') {
    e.dir = dx > 0 ? 1 : -1;
    const sp = (d.run || d.spd || 70) * (e.b === 'walker' ? 1.35 + 0.4 * g : 1) * (0.75 + 0.25 * K);
    if (adx > 70) walk(sp, e.dir); else if (adx < 40) walk(sp * 0.6, -e.dir);   // guarda un poco de distancia antes de embestir
    if (adx < 78 + 20 * g && e.hit <= 0 && (e.atkCD || 0) <= 0) { ai.st = 'wind'; ai.t = (0.42 - 0.14 * g) / Math.max(.7, K); e.alert = ai.t; sfx('swing', .25, 1.5); }
    e.atkCD = (e.atkCD || 0) - dt;
    if (adx > 420 || p.dead) ai.st = 'idle', e.ai = null;
  } else if (ai.st === 'wind') {
    e.x += Math.sin(e.t * 60) * 0.5;
    if (e.hit > 0.1 && !ai.armor && Math.random() < (diffIdx === 0 ? 0.6 : 0.35 - 0.3 * g)) { ai.st = 'idle'; e.atkCD = 0.6; return; }   // a veces le cortas el ataque
    if (ai.t <= 0) { ai.st = 'lunge'; ai.t = 0.22 + 0.06 * g; ai.dir = dx > 0 ? 1 : -1; e.dir = ai.dir; sfx('dash', .3, 1.1); }
  } else if (ai.st === 'lunge') {
    walk((330 + 140 * g) * (0.7 + 0.3 * K), ai.dir);
    if (!p.dead && overlap(p, { x: e.x - 4, y: e.y, w: e.w + 8, h: e.h })) hurt(16 + Math.round(6 * g), cx);
    if (ai.t <= 0) { ai.st = 'rec'; ai.t = 0.45 - 0.15 * g; }
  } else if (ai.st === 'rec') {
    if (ai.t <= 0) { ai.st = 'idle'; e.atkCD = (1.3 - 0.5 * g) / K; }
  }
}
// aguantan el empuje tras dos golpes seguidos y contraatacan
const _damageEnemyAI = damageEnemy;
damageEnemy = function (e, hb) {
  const now = time;
  e.hitsT = (e.hitsT && now - e.hitsT < 1) ? e.hitsT : now; e.hitsN = now - e.hitsT < 1 ? (e.hitsN || 0) + 1 : 1;
  _damageEnemyAI(e, hb);
  if (e.dead || !GROUNDERS[e.b] && e.b !== 'brute') return;
  const g = foeG();
  if (e.hitsN >= 2 && diffIdx > 0) {
    e.kx = (e.kx || 0) * 0.25; e.hit = Math.min(e.hit, 0.06);
    if (!e.ai || e.ai.st === 'idle' || e.ai.st === 'rec') { e.ai = { st: 'wind', t: 0.14, armor: true }; e.alert = 0.14; }
    e.hitsN = 0;
  }
  e.aggro = 3;
};
// disparos que apuntan a donde vas a estar
const _shootAI = shoot;
shoot = function (e, kind, tx, ty, sp) {
  const g = foeG(), lead = diffIdx === 0 ? 0 : (0.35 + 0.65 * g);
  const dist = Math.hypot(tx - (e.x + e.w / 2), ty - (e.y + e.h / 2)), t = dist / ((sp || 210) * DIFFS[diffIdx].spd);
  return _shootAI(e, kind, tx + p.vx * t * lead, ty + Math.min(0, p.vy) * t * lead * 0.3, sp);
};
