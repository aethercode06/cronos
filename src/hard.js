// =====================================================================
//  FASES EXIGENTES (v3.5) — «los niveles siguen extremadamente fáciles»
//  Lo que las hacía fáciles:
//  · Pocas criaturas: 1 por tramo, casi siempre esquivables de un salto.
//  · Las reliquias rompían el juego: la Capa Planeadora planeaba sin
//    límite (cruzaba cualquier vacío), el Corazón de Cristal curaba
//    4 de vida por segundo y daba +40, el triple salto era casi tan
//    fuerte como el primero. Cuanto más avanzabas, más fácil era.
//  · Suelo largo y plano sin peligro: solo había que correr.
//  Ahora (Normal y superiores; Fácil no cambia):
//  · Más criaturas cuanto más avanzas: patrullas en el suelo, guardianes
//    sobre las plataformas donde tienes que aterrizar y voladores sobre
//    los vacíos.
//  · Púas en el suelo largo, más cuanto más avanzas.
//  · Reliquias equilibradas: planeo de 0,8 s por salto, Corazón de
//    Cristal +20 y cura lenta solo hasta la mitad, triple salto más corto.
//  · Puntos de control sin curación y cerezas que curan menos (logic.js).
// =====================================================================
const HARD_AIR = { flyer: 1, diver: 1, ghost: 1, dropper: 1, bomber: 1, bob: 1, book: 1 };
const HARD_PATROL = { walker: 1, chaser: 1, rammer: 1, shield: 1, brute: 1, splitter: 1, jumper: 1 };
const HARD_SKIP = { trial: 1, ambush: 1, tutorial: 1, chase: 1, flat: 0 };
function hardClone(t, x, groundY, minX, maxX) {
  const e = Object.assign({}, t, { x, x0: x, dead: false, hit: 0, ai: null, alert: 0, aggro: 0, aggroSent: false, kx: 0, vy: 0, t: Math.random() * 5, dir: Math.random() < .5 ? -1 : 1, hard: 1 });
  if (groundY != null) { e.y = groundY - e.h; e.y0 = e.y; if (e.gy != null) e.gy = groundY; }
  if (minX != null) { e.minX = minX; e.maxX = maxX; }
  return e;
}
const _buildStageH = buildStage;
buildStage = function (wi, act) {
  const L = _buildStageH(wi, act);
  try { if (diffIdx >= 1 && act < 2 && !TOWER_ON && L.segs && L.goal) hardPopulate(L, wi, act); } catch (e) {}
  return L;
};
function hardPopulate(L, wi, act) {
  const r = seeded(4242 + wi * 61 + act * 13), g = clamp(WPOS(wi) / (ORDER.length - 1), 0, 1) * 0.85 + act * 0.1;
  const k = diffIdx >= 2 ? 1.3 : 0.4;   // v3.6: Normal más suave (el usuario: «ahora está muy difícil»)
  const base = L.enemies.filter(e => !e.mini && !e.boss);
  const ground = base.filter(e => !HARD_AIR[e.b] && e.v !== 'book');
  const patrol = base.filter(e => HARD_PATROL[e.b] || HARD_PATROL[e.b0]);
  const air = base.filter(e => HARD_AIR[e.b] && e.b !== 'book' && e.b !== 'bob');
  const pick = a => a[Math.floor(r() * a.length)];
  const goalX = L.goal.x - 380, startX = 700;
  const busy = x => L.checks.some(c => Math.abs(c.x - x) < 90) || L.doors.some(d => Math.abs(d.x - x) < 120) || L.plates.some(q => Math.abs(q.x - x) < 90)
    || (L.seals || []).some(z => x > z.x1 - 120 && x < z.bar + 140) || (L.rift && Math.abs(L.rift.x - x) < 120);
  const segAt = x => { let s = null; for (const q of L.segs) if (q.x <= x) s = q; return s; };
  const ok = x => x > startX && x < goalX && !busy(x) && !(segAt(x) && HARD_SKIP[segAt(x).k]);
  const add = [];
  // 1) patrullas en el suelo largo
  const gstep = (560 - 330 * g) / k;
  for (const s of L.plats) {
    if (s.k !== 'solid' || !s.ground || s.pillar || s.ceil || s.w < 256) continue;
    for (let x = s.x + 120 + r() * 80; x < s.x + s.w - 120; x += gstep + r() * 160) {
      if (!ok(x) || !ground.length) continue;
      if (L.enemies.concat(add).some(e => Math.abs(e.x - x) < 130 && Math.abs(e.y - s.y) < 200)) continue;
      const t = pick(ground);
      add.push(hardClone(t, Math.round(x), s.y, Math.max(s.x + 8, x - 110), Math.min(s.x + s.w - 8 - t.w, x + 110)));
    }
  }
  // 2) guardianes sobre las plataformas donde hay que aterrizar
  for (const s of L.plats) {
    if (!(s.k === 'solid' && s.float) || s.w < 64 || !patrol.length) continue;
    const cx = s.x + s.w / 2;
    if (!ok(cx) || r() > (0.25 + 0.5 * g) * k) continue;
    const t = pick(patrol.filter(e => e.w <= s.w - 10).concat([]));
    if (!t) continue;
    if (L.enemies.concat(add).some(e => Math.abs(e.x - cx) < 100 && Math.abs(e.y - s.y) < 120)) continue;
    add.push(hardClone(t, Math.round(cx - t.w / 2), s.y, s.x + 2, s.x + s.w - 2 - t.w));
  }
  // 3) voladores sobre los vacíos
  const gr = L.plats.filter(s => s.k === 'solid' && s.ground && !s.pillar && !s.ceil).sort((a, b) => a.x - b.x);
  for (let i = 1; i < gr.length && air.length; i++) {
    const a = gr[i - 1], b = gr[i], gap = b.x - (a.x + a.w);
    if (gap < 110) continue;
    const cx = a.x + a.w + gap / 2;
    if (!ok(cx) || r() > (0.3 + 0.5 * g) * k) continue;
    if (L.enemies.concat(add).some(e => Math.abs(e.x - cx) < 120 && HARD_AIR[e.b])) continue;
    const t = pick(air), y = 300 + r() * 50;
    const e = hardClone(t, Math.round(cx), null);
    e.y = e.y0 = y; e.x0 = e.x;
    add.push(e);
  }
  // 4) púas en el suelo largo
  const sstep = (1000 - 550 * g) / k;
  for (const s of L.plats) {
    if (s.k !== 'solid' || !s.ground || s.pillar || s.ceil || s.conv || s.w < 320) continue;
    for (let x = s.x + 140 + r() * 120; x < s.x + s.w - 160; x += sstep + r() * 260) {
      const w = 32 + 16 * Math.floor(r() * (1 + 2 * g));
      if (!ok(x) || !ok(x + w)) continue;
      if (L.hazards.some(h => Math.abs(h.x - x) < 160) || L.enemies.concat(add).some(e => e.x > x - 50 && e.x < x + w + 50 && Math.abs(e.y + e.h - s.y) < 10)) continue;
      if (L.gems.some(q => q.x > x - 10 && q.x < x + w + 10 && q.y > s.y - 40)) continue;
      L.hazards.push({ k: 'spike', x: Math.round(x), y: s.y - 12, w, h: 12 });
      L.decor = L.decor.filter(d => d.x < x - 30 || d.x > x + w + 30 || Math.abs(d.y - s.y) > 20);
    }
  }
  for (const e of add) L.enemies.push(e);
  L.hardAdded = add.length;
}
// ---------------- reliquias equilibradas ----------------
const _abInitH = abInit;
abInit = function () {
  const was = p && p._ab;
  _abInitH();
  if (!was && p && p._ab && diffIdx >= 1 && hasAb('corazon')) { p.maxHp -= 20; p.hp = Math.min(p.hp, p.maxHp); }
};
const _updPlayerH = updatePlayer;
updatePlayer = function (dt) {
  if (diffIdx < 1 || !p || p.dead) return _updPlayerH(dt);
  const hp0 = p.hp, tri0 = p.triple, j = act.jump;
  // planeo limitado: 0,8 s por salto
  if (p.onGround || p.inWater || p.hook) p.glideT = 0;
  const noGlide = (p.glideT || 0) > 0.8 && !p.onGround && p.vy > 0;
  if (noGlide) act.jump = false;
  _updPlayerH(dt);
  act.jump = j;
  if (p.gliding) p.glideT = (p.glideT || 0) + dt;
  // triple salto más corto
  if (p.triple && !tri0) p.vy = -JUMP * 0.68;
  // Corazón de Cristal: cura lenta, solo tras 8 s sin golpes y hasta la mitad
  if (hasAb('corazon') && !p.dead && p.hp > hp0 && p.hp - hp0 <= 4 * dt + 0.001) {
    p.hp = (time - p.lastHurt > 8 && hp0 < p.maxHp * 0.5) ? Math.min(p.maxHp * 0.5, hp0 + 1.2 * dt) : hp0;
  }
};
