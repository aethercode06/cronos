// =====================================================================
//  CELEBRACIÓN AL SUPERAR UNA FASE (v3.1)
//  Antes tocabas la meta y aparecía un menú. Ahora es un momento:
//  1) Salto a la meta: cuanto más alto entres en el portal, más puntos
//     (como el mástil de Mario): ¡META! / ¡GRAN SALTO! / ¡SALTO PERFECTO!
//  2) Cámara lenta, destello, fanfarria y fuegos artificiales (más
//     cuanto mejor el salto) con Kael celebrando.
//  3) En la pantalla de fase superada los puntos se suman contando,
//     las estrellas caen una a una y llueve confeti; con 3 estrellas,
//     «¡PERFECTO!».
// =====================================================================
let FIN = null, finConf = [], finTally = null;
const FW_COL = ['#ffd34d', '#ff5470', '#35e2ff', '#3df5a0', '#d070ff', '#ffffff'];
function firework(x, y) {
  const c1 = FW_COL[Math.floor(Math.random() * FW_COL.length)], c2 = FW_COL[Math.floor(Math.random() * FW_COL.length)];
  for (let i = 0; i < 46; i++) { const a = i / 46 * 6.283, v = rnd(140, 260); parts.push({ x, y, vx: Math.cos(a) * v, vy: Math.sin(a) * v, life: rnd(.8, 1.3), max: 1.3, c: i % 2 ? c1 : c2, s: 2, g: 180 }); }
  ring(x, y, 6, 70, .5, hexA(c1, .9), 3); lightAt(x, y, 120, 'rgba(255,230,180,1)', .7);
  sfx('boom', .35, 1.5 + Math.random() * .3); vib(15);
}
const _stageClearFin = stageClear;
stageClear = function () {
  if (FIN) return;
  if (state !== 'playing' || !level.goal || TOWER || SECRET || curAct === 2) return _stageClearFin();
  const g = level.goal, h = (g.y + g.h) - (p.y + p.h);
  const tier = h > 38 ? 2 : h > 16 ? 1 : 0, bonus = [500, 2000, 5000][tier];
  FIN = { t: 0, tier, bonus, fw: [1, 3, 6][tier], fwT: 0.55, gx: g.x + g.w / 2, gy: g.y };
  addScore(bonus);
  hitStop = 0.28; flash = .45; flashCol = '255,245,210'; shake = Math.max(shake, 10); zoomPunch(0.07); vib([40, 30, 80]);
  ring(FIN.gx, g.y + g.h / 2, 8, 160, .7, 'rgba(255,220,120,.95)', 4); burst(FIN.gx, g.y + g.h / 2, '#ffe080', 40, 300, 80, 1, 2);
  playMusic(null); sfx('relic', .9); sfx('win', .9); sfx('portal', .6);
  p.inv = 9; p.vx = 0;
};
const _updateFin = update;
update = function (dt) {
  if (FIN && state === 'playing') for (const k of ACTS) { act[k] = false; pressed[k] = false; }
  _updateFin(dt);
  if (!FIN || state !== 'playing') return;
  FIN.t += dt;
  // Kael celebra: se queda en la meta y da un saltito
  p.vx = 0;
  if (FIN.t > .35 && !FIN.hop && p.onGround) { FIN.hop = true; p.vy = -380; p.face = 1; sfx('jump', .5, 1.2); }
  // fuegos artificiales
  FIN.fwT -= dt;
  if (FIN.fw > 0 && FIN.fwT <= 0) { FIN.fw--; FIN.fwT = 0.32; firework(FIN.gx + rnd(-110, 110), FIN.gy - rnd(60, 150)); }
  if (FIN.t > 2.5 && FIN.fw <= 0) { const F = FIN; FIN = null; finTally = { t0: performance.now(), from: stageScore0, perfect: F.tier === 2 }; finConf = []; _stageClearFin(); }
};
// textos grandes durante la celebración
function drawFinText() {
  if (!FIN || state !== 'playing') return;
  const t = FIN.t, k = Math.min(1, t / .35), sc = k < 1 ? 0.4 + k * 0.75 : 1.15 - Math.min(.15, (t - .35) * .6);
  ctx.save(); ctx.translate(W / 2, H * 0.36); ctx.scale(sc, sc);
  ctx.shadowColor = 'rgba(255,200,80,.9)'; ctx.shadowBlur = 26;
  txt('¡FASE SUPERADA!', 0, 0, 46, '#ffffff', 'rgba(60,30,0,.85)', 6, 'center', LOGOF, 900);
  ctx.restore();
  if (t > .45) {
    const k2 = Math.min(1, (t - .45) / .25), lab = ['¡META!', '¡GRAN SALTO!', '¡SALTO PERFECTO!'][FIN.tier], col = ['#9fe3ff', '#3df5a0', '#ffd34d'][FIN.tier];
    ctx.save(); ctx.globalAlpha = k2; ctx.translate(W / 2, H * 0.36 + 56); ctx.scale(0.7 + k2 * 0.3, 0.7 + k2 * 0.3);
    txt(tr(lab) + '  +' + FIN.bonus, 0, 0, 24, col, 'rgba(0,0,0,.8)', 5, 'center', UIF, 900);
    ctx.restore();
  }
}
// confeti y puntos contando en la pantalla de fase superada
function drawClearFX() {
  if (state !== 'clear' || !finTally) return;
  const e = (performance.now() - finTally.t0) / 1000;
  if (e < 3.2 && finConf.length < 140 && Math.random() < .9) for (let i = 0; i < 3; i++) finConf.push({ x: Math.random() * W, y: -10, vx: rnd(-40, 40), vy: rnd(80, 200), r: Math.random() * 6.28, vr: rnd(-6, 6), c: FW_COL[Math.floor(Math.random() * FW_COL.length)], s: rnd(4, 8) });
  ctx.save();
  for (const c of finConf) { c.x += c.vx / 60; c.y += c.vy / 60; c.r += c.vr / 60; c.vx += Math.sin(c.y / 30) * 2; ctx.save(); ctx.translate(c.x, c.y); ctx.rotate(c.r); ctx.fillStyle = c.c; ctx.fillRect(-c.s / 2, -c.s / 4, c.s, c.s / 2); ctx.restore(); }
  ctx.restore();
  finConf = finConf.filter(c => c.y < H + 20);
  // puntos sumándose
  const k = Math.min(1, e / 1.3), shown = Math.round(finTally.from + (score - finTally.from) * (1 - Math.pow(1 - k, 2)));
  if (k < 1 && Math.floor(e * 20) !== finTally.tick) { finTally.tick = Math.floor(e * 20); sfx('gem', .18, 1.4 + k * .6); }
  const ox = Math.round((W - 960) / 2), py = Math.round((H - 410) / 2);
  txt(tr('PUNTOS') + '  ' + shown, ox + 480, py + 284, 22, k < 1 ? '#ffffff' : '#ffe27a', null, 0, 'center', UIF, 900);
  // ¡PERFECTO! con las tres estrellas
  const S = typeof lastStars !== 'undefined' ? lastStars : null;
  if (S && S.got && S.got.every(Boolean) && e > 1.3) {
    const k3 = Math.min(1, (e - 1.3) / .3);
    if (!finTally.pf) { finTally.pf = 1; sfx('relic', .8, 1.2); flash = .2; flashCol = '255,230,150'; }
    ctx.save(); ctx.globalAlpha = k3; ctx.translate(ox + 480, py + 26); ctx.scale(0.6 + k3 * 0.4, 0.6 + k3 * 0.4); ctx.rotate(-0.06);
    ctx.shadowColor = 'rgba(255,210,90,.9)'; ctx.shadowBlur = 20; txt('¡PERFECTO!', 0, 0, 30, '#ffd34d', 'rgba(60,30,0,.9)', 5, 'center', LOGOF, 900);
    ctx.restore();
  }
}
const _drawFin = draw;
draw = function () { _drawFin(); drawFinText(); drawClearFX(); };
// al reiniciar o salir, sin celebración pendiente
const _startStageFin = startStage;
startStage = function (wi, act, fresh) { FIN = null; finTally = null; finConf = []; _startStageFin(wi, act, fresh); };
