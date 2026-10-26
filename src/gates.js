// =====================================================================
//  BARRERAS DE EMBOSCADA (v2.7)
//  Antes se podía llegar a la meta corriendo y saltando sin pelear.
//  Ahora cada fase tiene barreras de energía que se cierran al llegar:
//  aparecen enemigos y el paso solo se abre al derrotarlos a todos.
//  Su número y el de enemigos crecen del primer mundo al último.
//  Las barreras de las Cámaras del Desafío ya no se pueden saltar.
// =====================================================================
const SEAL_TXT = 'Una barrera te cierra el paso: derrota a todos los enemigos para abrirla.';
function sealPlan(wi, act) {
  const g = clamp(WPOS(wi) / (ORDER.length - 1), 0, 1), D = DIFFS[diffIdx];
  const n = act === 2 ? 1 : 1 + (g >= 0.25 ? 1 : 0) + (g >= 0.6 ? 1 : 0);
  const foes = Math.min(6, 2 + Math.floor(g * 3.2) + (D.extra ? 1 : 0) + (act === 1 ? 1 : 0));
  return { n, foes, g };
}
function sealSpots(L, n) {
  const W = L.goal ? L.goal.x : L.arena ? L.arena.x1 - 200 : L.width;
  const bad = (a, b) =>
    (L.trials || []).some(t => b > t.x1 - 220 && a < t.x2 + 220) ||
    L.doors.some(d => b > d.x - 260 && a < d.x + 260) ||
    L.zones.some(z => b > z.x - 60 && a < z.x + z.w + 60) ||
    L.hazards.some(h => b > h.x - 40 && a < h.x + h.w + 40) ||
    L.lavaStrips.some(s => b > s.x - 40 && a < s.x + s.w + 40) ||
    (L.arena && b > L.arena.x1 - 300);
  // solo importa que la zona de pelea (los ~460 px antes de la barrera) esté libre de trampas, agua o viento
  const cands = L.plats.filter(s => s.k === 'solid' && s.ground && !s.pillar && !s.conv && !s.sand && !s.ceil && s.y === GY && s.w >= 352 &&
    s.x > 700 && s.x + s.w < W - 60 && !bad(Math.max(s.x, s.x + s.w - 540), s.x + s.w)).map(s => ({ s, c: s.x + s.w / 2 }));
  const out = [];
  for (let i = 0; i < n; i++) {
    const tx = 600 + (W - 600) * (n === 1 ? 0.55 : 0.22 + 0.68 * i / (n - 1));
    let best = null, bd = 1e9;
    for (const q of cands) { if (out.some(o => Math.abs(o.c - q.c) < 1000)) continue; const d = Math.abs(q.c - tx); if (d < bd) { bd = d; best = q; } }
    if (best) out.push(best);
  }
  return out.sort((a, b) => a.c - b.c);
}
function sealFoe(id, x, y) {
  const d = ENEMY[id];
  return { id, d, b: d.b, x, y: d.b === 'flyer' || d.b === 'diver' || d.b === 'ghost' || d.b === 'dropper' ? y : GY - d.h, w: d.w, h: d.h, hp: d.hp, hit: 0, t: Math.random() * 5,
    dir: -1, minX: x - 140, maxX: x + 140 - d.w, cd: 1 + Math.random(), dead: false, st: d.b === 'riser' ? 'buried' : 0, x0: x, y0: y, fire: 0, alert: 1, vy: 0, rise: 0 };
}
function addSeals(L, wi, act) {
  if (TOWER_ON || (typeof RUSH !== 'undefined' && RUSH) || (wi === 2 && act === 2)) return;
  const P = sealPlan(wi, act), WD = WORLDS[wi], r = seeded(4242 + wi * 131 + act * 17);
  L.seals = [];
  const spots = L.sealSpots ? L.sealSpots.map(q => ({ s: { x: q.x, w: q.w } })) : sealSpots(L, 1);
  for (const { s } of spots) {
    const bar = s.x + s.w - 72;
    const plate = { on: true };
    const door = { k: 'door', x: bar, y: GY - 1700, w: 28, h: 1700, open: 1, tg: 1, plate, trial: true, seal: true };
    L.plats.push(door); L.doors.push(door);
    const foes = [];
    const gl = (WD.g || []).filter(id => ENEMY[id] && ENEMY[id].b !== 'shooter'), al = (WD.a || []).filter(id => ENEMY[id]);
    for (let i = 0; i < P.foes; i++) {
      const air = al.length && i % 3 === 2;
      const list = air ? al : gl.length ? gl : WD.g;
      foes.push({ id: list[Math.floor(r() * list.length)], x: bar - 50 - ((i * 67) % 170), y: 300 - (i % 2) * 50 });
    }
    L.seals.push({ x1: Math.max(s.x + 20, bar - 250), bar, door, plate, foes, live: [], st: 0, left: 0 });
    if (!L.checks.some(c => c.x > s.x - 700 && c.x < bar)) L.checks.push({ x: s.x + 24, y: GY - 40, w: 24, h: 40, on: false });
  }
  L.checks.sort((a, b) => a.x - b.x);
}
const _buildStageS = buildStage;
buildStage = function (wi, act) {
  const L = _buildStageS(wi, act);
  // las Cámaras del Desafío ya no se pueden saltar por encima
  for (const d of L.doors) if (d.trial && !d.seal && d.h < 1000) { d.y -= 1300; d.h += 1300; }
  try { addSeals(L, wi, act); } catch (e) { L.seals = []; }
  return L;
};
function updateSeals(dt) {
  if (!level || !level.seals || p.dead) return;
  for (const z of level.seals) {
    if (z.st === 0 && p.x + p.w > z.x1 && p.x + p.w < z.bar - 4) {
      z.st = 1; z.plate.on = false; z.live = [];
      for (const f of z.foes) {
        const e = sealFoe(f.id, f.x, f.y); level.enemies.push(e); z.live.push(e);
        addFx('poof', e.x + e.w / 2, e.y + e.h / 2, 16); ring(e.x + e.w / 2, e.y + e.h / 2, 4, 40, .4, 'rgba(255,90,70,.9)', 2);
      }
      z.left = z.live.length;
      banner('¡EMBOSCADA!', 'Derrota a los enemigos para abrir el paso', '#ff6a4a', 1.8);
      sfx('clang', .6, .7); sfx('alert', .5); shake = Math.max(shake, 6);
      SAVE.fh = SAVE.fh || {}; if (!SAVE.fh.seal) { SAVE.fh.seal = 1; try { persist(); } catch (e) {} tSay(SEAL_TXT, 4); }
    }
    if (z.st !== 1) continue;
    // si un enemigo se cae del mapa o queda muy lejos, cuenta como derrotado
    for (const e of z.live) if (!e.dead && (e.y > level.deathY || Math.abs(e.x - z.bar) > 1400)) e.dead = true;
    const left = z.live.filter(e => !e.dead).length;
    if (left < z.left && left > 0) addFloat(z.bar + 14, GY - 120, '⚔ ' + left, '#ff8a5a', 18);
    z.left = left;
    if (!left) {
      z.st = 2; z.plate.on = true; addScore(600); p.hp = Math.min(p.maxHp, p.hp + 15); addTime(10);
      for (let i = 0; i < 5; i++) level.gems.push({ x: z.bar - 200 + i * 40, y: 420 - Math.sin(i / 4 * Math.PI) * 50, taken: false, ph: i });
      banner('¡PASO ABIERTO!', '+600 puntos · +15 vida', '#ffd34d', 1.6);
      sfx('relic', .5); ring(z.bar + 14, GY - 120, 10, 200, .6, 'rgba(255,220,120,.9)', 3);
    }
  }
}
const _updateTrialsS = updateTrials;
updateTrials = function (dt) { _updateTrialsS(dt); updateSeals(dt); };
const _resetTrialsS = resetTrials;
resetTrials = function () {
  _resetTrialsS();
  if (level && level.seals) for (const z of level.seals) if (z.st === 1) { z.st = 0; for (const e of z.live) e.dead = true; z.live = []; z.plate.on = true; }
};
