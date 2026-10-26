// =====================================================================
//  MEDICIÓN DE PARTIDAS (solo en el teléfono, nada sale del dispositivo
//  salvo que el jugador comparta el informe): intentos, muertes con
//  posición y causa, abandonos, reinicios y tiempos por fase.
//  Pantalla ESTADÍSTICAS con mapa de calor de muertes por fase.
// =====================================================================
const TKEY = 'chronos_stats' + (PRUEBA ? '_p' : '');
let TSTAT = { v: 1, s: {} };
try { const o = JSON.parse(localStorage.getItem(TKEY) || 'null'); if (o && o.s) TSTAT = o; } catch (e) {}
let tRun = null, tCause = 'trampa', tSaveT = 0;
function tSave() { try { localStorage.setItem(TKEY, JSON.stringify(TSTAT)); } catch (e) {} }
function tRec(s) { return TSTAT.s[s] || (TSTAT.s[s] = { a: 0, c: 0, q: 0, r: 0, d: 0, tt: 0, tb: 0, cz: {}, p: [] }); }
function tOn() { return !(typeof TOWER_ON !== 'undefined' && TOWER_ON) && !(typeof TOWER !== 'undefined' && TOWER); }
function tClose(kind) {
  if (!tRun) return; const R = tRec(tRun.s);
  if (kind === 'q') R.q++; else if (kind === 'r') R.r++;
  tRun = null; tSave();
}
// nombre legible de lo que hirió al jugador
function tWho(srcX) {
  if (boss && !boss.done && Math.abs(boss.x + boss.w / 2 - srcX) < boss.w) return 'guardián';
  let best = null, bd = 90;
  for (const e of level.enemies) if (!e.dead) { const d = Math.abs(e.x + e.w / 2 - srcX) + Math.abs(e.y + e.h / 2 - (p.y + p.h / 2)) * .5; if (d < bd) { bd = d; best = e; } }
  if (best) return ENAME[best.id] || best.id;
  for (const q of projs) if (Math.abs(q.x - (p.x + p.w / 2)) < 60 && Math.abs(q.y - (p.y + p.h / 2)) < 60) return 'disparo';
  return 'trampa';
}
const ENAME = { opossum: 'zarigüeya', frog: 'rana', eagle: 'águila', turret: 'torreta', drone: 'dron', cyhound: 'sabueso', firerat: 'rata de fuego', worm: 'gusano', fireeagle: 'águila de fuego', goblin: 'duende bombero', mushroom: 'hongo', eye: 'ojo', gskel: 'esqueleto', hound: 'sabueso', ghost: 'espectro', iceskel: 'esqueleto de hielo', icehound: 'sabueso de hielo', iceeye: 'ojo de hielo', infworm: 'gusano infernal', infhound: 'sabueso infernal', infghost: 'espectro de fuego', shieldskel: 'esqueleto con escudo', goldskel: 'esqueleto dorado', goldeye: 'ojo dorado', cdrone: 'dron', crab: 'cangrejo', angler: 'pez linterna', jelly: 'medusa', scarab: 'escarabajo', mummy: 'momia', vulture: 'buitre', seraph: 'serafín', golem: 'gólem', voidling: 'criatura del vacío' };
const _startStageT = startStage;
startStage = function (wi, act, fresh) {
  if (tRun && tRun.s !== sIdx(wi, act)) tClose('q');
  _startStageT(wi, act, fresh);
  if (!tOn()) { tRun = null; return; }
  const s = sIdx(wi, act); tRec(s).a++; tRun = { s, d: 0 }; tSave();
};
const _hurtT = hurt;
hurt = function (dmg, srcX) { if (p && !p.dead && p.inv <= 0 && tRun) tCause = tWho(srcX === undefined ? p.x : srcX); return _hurtT(dmg, srcX); };
const _hazardT = hazardRespawn;
hazardRespawn = function (dmg) {
  if (tRun) tCause = p.y > level.deathY ? 'caída' : level.lava && p.y + p.h > level.lava.y ? 'lava' : 'trampa';
  if (tRun && p.y > level.deathY) { const R = tRec(tRun.s); R.cz['caída*'] = (R.cz['caída*'] || 0) + 1; if (R.p.length < 120) R.p.push([Math.round(p.x), Math.round(Math.min(p.y, level.deathY)), 'caída*']); }
  return _hazardT(dmg);
};
const _killT = kill;
kill = function () {
  if (tRun && !p.dead) {
    const R = tRec(tRun.s); R.d++; tRun.d++; R.cz[tCause] = (R.cz[tCause] || 0) + 1;
    if (R.p.length >= 120) R.p.shift(); R.p.push([Math.round(p.x + p.w / 2), Math.round(p.y + p.h / 2), tCause]); tSave();
  }
  tCause = 'trampa'; return _killT();
};
const _clearT = stageClear;
stageClear = function () {
  const was = state === 'playing' && tRun;
  _clearT();
  if (was && state !== 'playing') { const R = tRec(tRun.s); R.c++; R.tt += levelTime; R.tb = R.tb ? Math.min(R.tb, levelTime) : levelTime; tRun = null; tSave(); }
};
const _retryT = retry; retry = function () { tClose('r'); _retryT(); };
const _toMapT = toMap; toMap = function () { tClose('q'); _toMapT(); };
const _toTitleT = toTitle; toTitle = function () { tClose('q'); _toTitleT(); };
// el jefe vencido cuenta como fase superada aunque la pantalla de fragmento llegue después
addEventListener('pagehide', () => { if (tRun) { tRec(tRun.s).q++; tRun = null; tSave(); } });

// ---------------- informe de texto para compartir ----------------
const fmtS = s => { s = Math.round(s); return Math.floor(s / 60) + ':' + String(s % 60).padStart(2, '0'); };
function tStageName(s) { const w = ORDER[Math.floor(s / 3)]; return (Math.floor(s / 3) + 1) + '-' + (s % 3 + 1) + ' ' + WORLDS[w].name; }
function tTopCause(R) { let k = null, n = 0; for (const c in R.cz) if (R.cz[c] > n) { n = R.cz[c]; k = c; } return k ? k.replace('*', '') + ' ×' + n : '—'; }
function tReport() {
  const L = ['CHRONOS & THE SHIFT · informe de partidas' + (PRUEBA ? ' (versión de prueba)' : ''), 'Dificultad: ' + DIFFS[diffIdx].name + ' · ' + new Date().toLocaleDateString(), ''];
  const ks = Object.keys(TSTAT.s).map(Number).sort((a, b) => a - b);
  for (const s of ks) {
    const R = TSTAT.s[s]; if (!R.a) continue;
    const causes = Object.entries(R.cz).sort((a, b) => b[1] - a[1]).map(([k, v]) => k.replace('*', '') + ' ' + v).join(', ');
    L.push(tStageName(s) + ' | intentos ' + R.a + ' | superada ' + R.c + ' | muertes ' + R.d + (causes ? ' (' + causes + ')' : '') + ' | abandonos ' + R.q + ' | reinicios ' + R.r + (R.c ? ' | tiempo medio ' + fmtS(R.tt / R.c) + ' · mejor ' + fmtS(R.tb) : ''));
    if (R.p.length) L.push('   pos: ' + R.p.slice(-30).map(q => q[0] + ',' + q[1]).join(' '));
  }
  if (L.length === 3) L.push('Todavía no hay partidas registradas.');
  return L.join('\n');
}
function tShare() {
  const text = tReport();
  const done = m => { toastMsg(m); };
  try { if (navigator.share) { navigator.share({ title: 'Informe Chronos', text }).catch(() => tCopy(text, done)); return; } } catch (e) {}
  tCopy(text, done);
}
function tCopy(text, done) {
  const fallback = () => {
    let ta = document.getElementById('tele-ta');
    if (!ta) { ta = document.createElement('textarea'); ta.id = 'tele-ta'; ta.style.cssText = 'position:fixed;left:5%;top:8%;width:90%;height:70%;z-index:99;font:12px monospace;background:#120e24;color:#fff;border:2px solid #ffcf4a;border-radius:10px;padding:10px'; document.body.appendChild(ta);
      const b = document.createElement('button'); b.id = 'tele-close'; b.textContent = 'CERRAR'; b.style.cssText = 'position:fixed;left:40%;top:80%;width:20%;height:44px;z-index:99;font:bold 15px sans-serif;background:#ffcf4a;border:0;border-radius:22px'; b.onclick = () => { ta.remove(); b.remove(); }; document.body.appendChild(b); }
    ta.value = text; ta.focus(); ta.select(); done('Copia el texto y envíalo');
  };
  try { if (navigator.clipboard && navigator.clipboard.writeText) { navigator.clipboard.writeText(text).then(() => done('Informe copiado: pégalo en un mensaje'), fallback); return; } } catch (e) {}
  fallback();
}
let tMsg = '', tMsgT = 0;
function toastMsg(m) { tMsg = m; tMsgT = 3; }

// ---------------- pantalla ESTADÍSTICAS ----------------
let tPrev = 'title', tSel = -1, tGeo = null, tPage = 0;
function openStats() { tPrev = state; state = 'stats'; fade = .4; tSel = -1; tPage = 0; }
function closeStats() { if (tSel >= 0) { tSel = -1; return; } state = tPrev === 'stats' ? 'title' : tPrev; fade = .4; }
function tRows() {
  const rows = [];
  for (let s = 0; s <= LAST; s++) { const R = TSTAT.s[s]; if (R && R.a) rows.push(s); }
  rows.sort((a, b) => (TSTAT.s[b].d + TSTAT.s[b].q * 2) - (TSTAT.s[a].d + TSTAT.s[a].q * 2));
  return rows;
}
function tButtons() {
  const ox = Math.round((W - 960) / 2), B = [];
  if (tSel < 0) {
    const rows = tRows(), per = 9, pages = Math.max(1, Math.ceil(rows.length / per));
    rows.slice(tPage * per, tPage * per + per).forEach((s, i) => B.push({ x: ox + 60, y: 118 + i * 38, w: 840, h: 34, row: s }));
    if (pages > 1) { B.push({ x: ox + 60, y: 470, w: 110, h: 40, t: '', ic: 'left', c: '#35e2ff', small: true, fn: () => { tPage = (tPage + pages - 1) % pages; } }); B.push({ x: ox + 790, y: 470, w: 110, h: 40, t: '', ic: 'right', c: '#35e2ff', small: true, fn: () => { tPage = (tPage + 1) % pages; } }); }
    B.push({ x: ox + 190, y: 470, w: 180, h: 40, t: 'COMPARTIR', ic: 'flag', c: '#ffcf4a', c2: '#ff8a3d', sel: true, small: true, fn: tShare });
    B.push({ x: ox + 390, y: 470, w: 180, h: 40, t: 'VOLVER', ic: 'left', c: '#35e2ff', small: true, fn: closeStats });
    B.push({ x: ox + 590, y: 470, w: 180, h: 40, t: tConfirm > 0 ? '¿SEGURO? TOCA' : 'BORRAR DATOS', c: '#ff5470', small: true, fn: () => { if (tConfirm > 0) { TSTAT = { v: 1, s: {} }; tSave(); tConfirm = 0; toastMsg('Datos borrados'); } else tConfirm = 3; } });
  } else {
    B.push({ x: ox + 290, y: 470, w: 180, h: 40, t: 'VOLVER', ic: 'left', c: '#35e2ff', small: true, fn: () => { tSel = -1; } });
    B.push({ x: ox + 490, y: 470, w: 180, h: 40, t: 'JUGAR FASE', ic: 'right', c: '#ffcf4a', c2: '#ff8a3d', sel: true, small: true, fn: () => { const s = tSel; if (s > SAVE.unl) { toastMsg('Fase todavía bloqueada'); return; } tSel = -1; state = 'map'; beginStage(ORDER[Math.floor(s / 3)], s % 3); } });
  }
  return B;
}
let tConfirm = 0;
function drawStats(dt) {
  if (tConfirm > 0) tConfirm -= dt;
  ctx.fillStyle = '#07060f'; ctx.fillRect(0, 0, W, H);
  const gr = ctx.createRadialGradient(W / 2, H * .25, 10, W / 2, H * .3, W * .7); gr.addColorStop(0, 'rgba(60,120,200,.3)'); gr.addColorStop(1, 'rgba(0,0,0,0)'); ctx.fillStyle = gr; ctx.fillRect(0, 0, W, H);
  const ox = Math.round((W - 960) / 2);
  ctx.save(); ctx.translate(ox, 0);
  ctx.save(); ctx.shadowColor = 'rgba(90,180,255,.7)'; ctx.shadowBlur = 18; txt(tSel < 0 ? 'ESTADÍSTICAS' : tStageName(tSel), 480, 40, tSel < 0 ? 30 : 24, '#a8dcff', null, 0, 'center', LOGOF, 900); ctx.restore();
  if (tSel < 0) {
    let tot = { a: 0, d: 0, c: 0, q: 0 }; for (const k in TSTAT.s) { const R = TSTAT.s[k]; tot.a += R.a; tot.d += R.d; tot.c += R.c; tot.q += R.q; }
    txt('Intentos ' + tot.a + '  ·  Superadas ' + tot.c + '  ·  Muertes ' + tot.d + '  ·  Abandonos ' + tot.q + '   —   ordenadas de más difícil a más fácil', 480, 70, 12, 'rgba(255,255,255,.75)', null, 0, 'center', UIF, 700);
    txt('FASE', 80, 100, 11, 'rgba(255,255,255,.5)', null, 0, 'left', UIF, 800);
    [['INTENTOS', 470], ['SUPERADA', 545], ['MUERTES', 620], ['ABANDONA', 695], ['T. MEDIO', 770], ['CAUSA PRINCIPAL', 860]].forEach(c => txt(c[0], c[1], 100, 10, 'rgba(255,255,255,.5)', null, 0, 'center', UIF, 800));
    const B = tButtons(), rows = B.filter(b => b.row !== undefined);
    if (!rows.length) txt('Juega algunas fases y aquí verás dónde mueres, cuánto tardas y dónde abandonas.', 480, 250, 14, 'rgba(255,255,255,.7)', null, 0, 'center', UIF, 600);
    for (const b of rows) {
      const R = TSTAT.s[b.row], x = b.x - ox, hard = R.d + R.q * 2, heat = clamp(hard / 10, 0, 1);
      rrect(x, b.y, b.w, b.h, 9); ctx.fillStyle = 'rgba(' + Math.round(40 + heat * 160) + ',' + Math.round(40 + (1 - heat) * 60) + ',70,.35)'; ctx.fill();
      ctx.strokeStyle = 'rgba(255,255,255,.12)'; ctx.lineWidth = 1; ctx.stroke();
      const w = WORLDS[ORDER[Math.floor(b.row / 3)]];
      ctx.fillStyle = w.c; ctx.beginPath(); ctx.arc(x + 16, b.y + 17, 6, 0, 6.3); ctx.fill();
      txt(tStageName(b.row), x + 30, b.y + 18, 13, '#ffffff', null, 0, 'left', UIF, 800);
      const v = [R.a, R.c, R.d, R.q, R.c ? fmtS(R.tt / R.c) : '—'];
      v.forEach((t, i) => txt(String(t), 470 + i * 75, b.y + 18, 13, i === 2 && R.d > 4 ? '#ff8a8a' : i === 3 && R.q > 1 ? '#ffc070' : '#ffffff', null, 0, 'center', UIF, 800));
      txt(tTopCause(R), 860, b.y + 18, 12, 'rgba(255,220,170,.9)', null, 0, 'center', UIF, 700);
    }
    for (const b of B) if (b.row === undefined) drawButton(Object.assign({}, b, { x: b.x - ox }));
    txt('Toca una fase para ver en el mapa dónde mueren los jugadores', 480, 524, 11, 'rgba(170,210,255,.6)', null, 0, 'center', UIF, 600);
  } else {
    drawHeat(tSel);
    for (const b of tButtons()) drawButton(Object.assign({}, b, { x: b.x - ox }));
  }
  if (tMsgT > 0) { tMsgT -= dt; ctx.globalAlpha = Math.min(1, tMsgT * 2); glass(280, 446 - 50, 400, 40, 14, '#8fd0ff', true); txt(tMsg, 480, 446 - 30, 13, '#ffffff', null, 0, 'center', UIF, 800); ctx.globalAlpha = 1; }
  ctx.restore();
}
// mapa de la fase (plataformas) con un punto por cada muerte
function drawHeat(s) {
  if (!tGeo || tGeo.s !== s) {
    const w = ORDER[Math.floor(s / 3)], a = s % 3; let L = null;
    try { L = buildStage(w, a); } catch (e) {}
    tGeo = { s, L };
  }
  const L = tGeo.L, R = TSTAT.s[s] || { p: [], cz: {} };
  if (!L) { txt('No se pudo dibujar la fase', 480, 250, 14, '#fff', null, 0, 'center', UIF, 700); return; }
  let x1 = 1e9, x2 = -1e9, y1 = 1e9, y2 = -1e9;
  for (const q of L.plats) { x1 = Math.min(x1, q.x); x2 = Math.max(x2, q.x + q.w); y1 = Math.min(y1, q.y); y2 = Math.max(y2, Math.min(q.y + q.h, q.y + 60)); }
  for (const q of R.p) { y1 = Math.min(y1, q[1] - 30); y2 = Math.max(y2, q[1] + 10); }
  const bx0 = 30, by0 = 70, bw = 900, bh = 330, sc = Math.min(bw / (x2 - x1 + 40), bh / (y2 - y1 + 40));
  const X = v => bx0 + (bw - (x2 - x1) * sc) / 2 + (v - x1) * sc, Y = v => by0 + (bh - (y2 - y1) * sc) / 2 + (v - y1) * sc;
  rrect(bx0 - 6, by0 - 6, bw + 12, bh + 12, 12); ctx.fillStyle = 'rgba(255,255,255,.04)'; ctx.fill();
  const wc = WORLDS[ORDER[Math.floor(s / 3)]].c;
  for (const q of L.plats) { ctx.fillStyle = q.k === 'solid' ? hexA(wc, .55) : q.k === 'move' ? 'rgba(120,200,255,.6)' : q.k === 'bounce' ? 'rgba(120,255,160,.7)' : 'rgba(255,255,255,.35)'; ctx.fillRect(X(q.x), Y(q.y), Math.max(1.5, q.w * sc), Math.max(2, Math.min(q.h, 40) * sc)); }
  for (const h of L.hazards) { ctx.fillStyle = 'rgba(255,90,90,.7)'; ctx.fillRect(X(h.x), Y(h.y), Math.max(1.5, h.w * sc), Math.max(2, h.h * sc)); }
  for (const e of L.enemies) { ctx.fillStyle = 'rgba(255,200,90,.65)'; ctx.fillRect(X(e.x), Y(e.y), 3, 3); }
  if (L.arena) { ctx.strokeStyle = 'rgba(255,90,120,.6)'; ctx.setLineDash([4, 4]); ctx.strokeRect(X(L.arena.x1), Y(L.arena.floor - 300), (L.arena.x2 - L.arena.x1) * sc, 300 * sc); ctx.setLineDash([]); }
  ctx.globalCompositeOperation = 'lighter';
  for (const q of R.p) { const g = ctx.createRadialGradient(X(q[0]), Y(q[1]), 0, X(q[0]), Y(q[1]), 14); g.addColorStop(0, 'rgba(255,60,60,.75)'); g.addColorStop(1, 'rgba(255,0,0,0)'); ctx.fillStyle = g; ctx.fillRect(X(q[0]) - 14, Y(q[1]) - 14, 28, 28); }
  ctx.globalCompositeOperation = 'source-over';
  for (const q of R.p) { ctx.fillStyle = q[2] === 'caída*' ? '#ffd040' : '#ffffff'; ctx.fillRect(X(q[0]) - 1.5, Y(q[1]) - 1.5, 3, 3); }
  const causes = Object.entries(R.cz).sort((a, b) => b[1] - a[1]).slice(0, 5).map(([k, v]) => k.replace('*', '') + ' ' + v).join('   ·   ');
  txt('Intentos ' + (R.a || 0) + '  ·  Superada ' + (R.c || 0) + '  ·  Muertes ' + (R.d || 0) + '  ·  Abandonos ' + (R.q || 0) + '  ·  Reinicios ' + (R.r || 0) + (R.c ? '  ·  Tiempo medio ' + fmtS(R.tt / R.c) : ''), 480, 422, 12, '#ffffff', null, 0, 'center', UIF, 700);
  txt(causes || 'Sin muertes registradas', 480, 444, 12, 'rgba(255,210,160,.9)', null, 0, 'center', UIF, 700);
  txt('● muerte   ● caída al vacío   ▪ enemigo   ▪ trampa   ▭ arena del guardián', 480, 524, 10, 'rgba(255,255,255,.55)', null, 0, 'center', UIF, 600);
}
const _uiButtonsT = uiButtons;
uiButtons = function () {
  const B = _uiButtonsT();
  if (state === 'title') { B.push({ x: W - 228, y: 14, w: 160, h: 34, t: 'ESTADÍSTICAS', c: '#8fd0ff', small: true, fn: openStats }); }
  return B;
};
const _handleTapT = handleTap;
handleTap = function (x, y, type) {
  if (state === 'stats') {
    for (const b of tButtons()) if (inRect({ x, y }, b)) { sfx('click'); if (b.row !== undefined) { tSel = b.row; tGeo = null; } else b.fn(); return; }
    return;
  }
  _handleTapT(x, y, type);
};
const _onKeyT = onKey;
onKey = function (c) { if (state === 'stats') { if (c === 'Escape') closeStats(); return; } _onKeyT(c); };
let lastDrawT = performance.now();
const _drawT = draw;
draw = function () {
  const now = performance.now(), dt = Math.min(.05, (now - lastDrawT) / 1000); lastDrawT = now;
  if (state === 'stats') { ctx.setTransform(RES, 0, 0, RES, 0, 0); drawStats(dt); if (fade > 0) { ctx.fillStyle = 'rgba(0,0,0,' + fade + ')'; ctx.fillRect(0, 0, W, H); } try { drawToasts(dt); } catch (e) {} }
  else _drawT();
};
