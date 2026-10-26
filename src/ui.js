// =====================================================================
//  INTERFAZ MODERNA: paneles translúcidos, barras animadas, iconos
// =====================================================================
function rrect(x, y, w, h, r) { ctx.beginPath(); ctx.moveTo(x + r, y); ctx.arcTo(x + w, y, x + w, y + h, r); ctx.arcTo(x + w, y + h, x, y + h, r); ctx.arcTo(x, y + h, x, y, r); ctx.arcTo(x, y, x + w, y, r); ctx.closePath(); }
function glass(x, y, w, h, r, accent, strong) {
  ctx.save();
  rrect(x + 2, y + 5, w, h, r); ctx.fillStyle = 'rgba(0,0,0,.28)'; ctx.fill();
  rrect(x, y, w, h, r);
  const g = ctx.createLinearGradient(0, y, 0, y + h); g.addColorStop(0, strong ? 'rgba(30,26,60,.92)' : 'rgba(24,22,48,.66)'); g.addColorStop(1, strong ? 'rgba(12,10,28,.94)' : 'rgba(10,9,24,.6)');
  ctx.fillStyle = g; ctx.fill();
  ctx.lineWidth = 1.2; ctx.strokeStyle = 'rgba(255,255,255,.16)'; ctx.stroke();
  ctx.clip();
  const hl = ctx.createLinearGradient(0, y, 0, y + Math.min(30, h * .5)); hl.addColorStop(0, 'rgba(255,255,255,.10)'); hl.addColorStop(1, 'rgba(255,255,255,0)'); ctx.fillStyle = hl; ctx.fillRect(x, y, w, Math.min(30, h * .5));
  if (accent) { const ag = ctx.createLinearGradient(x, 0, x + w, 0); ag.addColorStop(0, accent); ag.addColorStop(1, 'rgba(255,255,255,0)'); ctx.fillStyle = ag; ctx.globalAlpha = .9; ctx.fillRect(x, y, w, 2.5); }
  ctx.restore();
}
function pill(x, y, w, h, c1, c2) { rrect(x, y, w, h, h / 2); const g = ctx.createLinearGradient(x, 0, x + w, 0); g.addColorStop(0, c1); g.addColorStop(1, c2 || c1); ctx.fillStyle = g; ctx.fill(); }
function shadowTxt(t, x, y, size, fill, align, fnt, wt) { txt(t, x + 1.5, y + 2, size, 'rgba(0,0,0,.55)', null, 0, align, fnt, wt); txt(t, x, y, size, fill, null, 0, align, fnt, wt); }
function hexA(hex, a) { const n = parseInt(hex.slice(1), 16); return 'rgba(' + (n >> 16) + ',' + ((n >> 8) & 255) + ',' + (n & 255) + ',' + a + ')'; }
function pxPanel(x, y, w, h, border, fill, sh) { glass(x, y, w, h, 14, border && border[0] === '#' ? border : null, true); }
// ---------- iconos vectoriales ----------
function icon(kind, cx, cy, s, col) {
  ctx.save(); ctx.translate(cx, cy); ctx.fillStyle = col; ctx.strokeStyle = col; ctx.lineWidth = s * .16; ctx.lineCap = 'round'; ctx.lineJoin = 'round';
  ctx.beginPath();
  if (kind === 'left' || kind === 'right') { const d = kind === 'left' ? -1 : 1; ctx.moveTo(d * s * .45, 0); ctx.lineTo(-d * s * .3, -s * .42); ctx.lineTo(-d * s * .3, s * .42); ctx.closePath(); ctx.fill(); }
  else if (kind === 'jump') { ctx.moveTo(-s * .38, s * .1); ctx.lineTo(0, -s * .3); ctx.lineTo(s * .38, s * .1); ctx.moveTo(-s * .38, s * .42); ctx.lineTo(0, s * .02); ctx.lineTo(s * .38, s * .42); ctx.stroke(); }
  else if (kind === 'attack') { ctx.moveTo(-s * .38, s * .38); ctx.lineTo(s * .4, -s * .4); ctx.stroke(); ctx.beginPath(); ctx.moveTo(-s * .38, s * .1); ctx.lineTo(-s * .1, s * .38); ctx.stroke(); ctx.beginPath(); ctx.arc(-s * .42, s * .42, s * .07, 0, 6.3); ctx.fill(); }
  else if (kind === 'dash') { for (const o of [-.2, .18]) { ctx.moveTo(o * s - s * .14, -s * .34); ctx.lineTo(o * s + s * .2, 0); ctx.lineTo(o * s - s * .14, s * .34); } ctx.stroke(); ctx.globalAlpha = .5; ctx.beginPath(); ctx.moveTo(-s * .5, -s * .1); ctx.lineTo(-s * .38, -s * .1); ctx.moveTo(-s * .5, s * .1); ctx.lineTo(-s * .38, s * .1); ctx.stroke(); }
  else if (kind === 'shift') { ctx.lineWidth = s * .11; ctx.strokeRect(-s * .38, -s * .38, s * .46, s * .46); ctx.globalAlpha = .9; ctx.strokeRect(-s * .08, -s * .08, s * .46, s * .46); }
  else if (kind === 'time') { ctx.lineWidth = s * .1; ctx.moveTo(-s * .3, -s * .4); ctx.lineTo(s * .3, -s * .4); ctx.lineTo(-s * .3, s * .4); ctx.lineTo(s * .3, s * .4); ctx.closePath(); ctx.stroke(); ctx.beginPath(); ctx.moveTo(-s * .14, -s * .28); ctx.lineTo(s * .14, -s * .28); ctx.lineTo(0, -s * .06); ctx.closePath(); ctx.fill(); }
  else if (kind === 'pause') { ctx.fillRect(-s * .28, -s * .32, s * .2, s * .64); ctx.fillRect(s * .08, -s * .32, s * .2, s * .64); }
  else if (kind === 'lock') { ctx.lineWidth = s * .12; ctx.arc(0, -s * .12, s * .2, Math.PI, 0); ctx.stroke(); ctx.fillRect(-s * .3, -s * .1, s * .6, s * .45); }
  else if (kind === 'music') { ctx.fillRect(-s * .05, -s * .38, s * .1, s * .62); ctx.beginPath(); ctx.ellipse(-s * .18, s * .26, s * .18, s * .13, -0.4, 0, 6.3); ctx.fill(); ctx.fillRect(-s * .05, -s * .38, s * .32, s * .1); }
  else if (kind === 'skull') { ctx.arc(0, -s * .08, s * .3, 0, 6.3); ctx.fill(); ctx.fillRect(-s * .18, s * .12, s * .36, s * .22); ctx.fillStyle = 'rgba(0,0,0,.75)'; ctx.beginPath(); ctx.arc(-s * .11, -s * .06, s * .08, 0, 6.3); ctx.arc(s * .11, -s * .06, s * .08, 0, 6.3); ctx.fill(); }
  else if (kind === 'flag') { ctx.lineWidth = s * .09; ctx.moveTo(-s * .25, s * .4); ctx.lineTo(-s * .25, -s * .4); ctx.stroke(); ctx.beginPath(); ctx.moveTo(-s * .22, -s * .4); ctx.lineTo(s * .35, -s * .22); ctx.lineTo(-s * .22, -s * .04); ctx.closePath(); ctx.fill(); }
  ctx.restore();
}
// ---------- botones ----------
let optPrev = 'title';
function goFull() {
  if (!OPT.full) return;
  try { const el = document.documentElement; if (!document.fullscreenElement && el.requestFullscreen) el.requestFullscreen({ navigationUI: 'hide' }).then(() => { try { screen.orientation.lock('landscape').catch(() => {}); } catch (e) {} }).catch(() => {}); } catch (e) {}
}
function openOptions() { optPrev = state; state = 'options'; }
function closeOptions() { state = optPrev; saveOpts(); }
function optRows() {
  const pct = v => Math.round(v * 100) + '%';
  return [
    ['Música', pct(OPT.mus), () => { OPT.mus = clamp(Math.round((OPT.mus - 0.1) * 10) / 10, 0, 1); }, () => { OPT.mus = clamp(Math.round((OPT.mus + 0.1) * 10) / 10, 0, 1); }],
    ['Efectos de sonido', pct(OPT.sfx), () => { OPT.sfx = clamp(Math.round((OPT.sfx - 0.1) * 10) / 10, 0, 1); }, () => { OPT.sfx = clamp(Math.round((OPT.sfx + 0.1) * 10) / 10, 0, 1); sfx('gem', .6); }],
    ['Vibración', OPT.vib ? 'Sí' : 'No', () => { OPT.vib = !OPT.vib; vib(30); }, () => { OPT.vib = !OPT.vib; vib(30); }],
    ['Temblor de cámara', OPT.shake ? 'Sí' : 'No', () => { OPT.shake = !OPT.shake; }, () => { OPT.shake = !OPT.shake; }],
    ['Controles', OPT.ctrl === 'joystick' ? 'Joystick' : 'Botones', () => { OPT.ctrl = OPT.ctrl === 'joystick' ? 'botones' : 'joystick'; }, () => { OPT.ctrl = OPT.ctrl === 'joystick' ? 'botones' : 'joystick'; }],
    ['Tamaño de botones', OPT.size < 0.95 ? 'Pequeño' : OPT.size > 1.05 ? 'Grande' : 'Normal', () => { OPT.size = OPT.size > 1.05 ? 1 : 0.85; }, () => { OPT.size = OPT.size < 0.95 ? 1 : 1.18; }],
    ['Opacidad de botones', pct(OPT.alpha), () => { OPT.alpha = clamp(Math.round((OPT.alpha - 0.15) * 100) / 100, 0.25, 1); }, () => { OPT.alpha = clamp(Math.round((OPT.alpha + 0.15) * 100) / 100, 0.25, 1); }],
    ['Pantalla completa', OPT.full ? 'Sí' : 'No', () => { OPT.full = !OPT.full; if (!OPT.full && document.fullscreenElement) document.exitFullscreen().catch(() => {}); else goFull(); }, () => { OPT.full = !OPT.full; if (!OPT.full && document.fullscreenElement) document.exitFullscreen().catch(() => {}); else goFull(); }],
    ['Calidad gráfica', OPT.lq ? 'Rendimiento' : 'Máxima', () => { OPT.lq = !OPT.lq; applyQuality(); }, () => { OPT.lq = !OPT.lq; applyQuality(); }]
  ];
}
function uiButtons() {
  const B = [], ox = Math.round((W - 960) / 2);
  if (state === 'options') {
    const OR = optRows(), sp = Math.min(34, Math.floor(340 / OR.length));
    OR.forEach((r, i) => {
      const y = 108 + i * sp;
      B.push({ x: ox + 560, y, w: 34, h: sp - 4, t: '', ic: 'left', c: '#35e2ff', small: true, fn: () => { r[2](); applyOpts(); } });
      B.push({ x: ox + 716, y, w: 34, h: sp - 4, t: '', ic: 'right', c: '#35e2ff', small: true, fn: () => { r[3](); applyOpts(); } });
    });
    B.push({ x: ox + 380, y: 456, w: 200, h: 44, t: 'LISTO', ic: 'right', c: '#ffcf4a', c2: '#ff8a3d', sel: true, fn: closeOptions });
  } else if (state === 'title') {
    B.push({ x: ox + 370, y: 334, w: 220, h: 58, t: SAVE.intro ? 'JUGAR' : 'NUEVA AVENTURA', ic: 'right', c: '#ffcf4a', c2: '#ff8a3d', sel: true, big: true, fn: () => { goFull(); if (!SAVE.intro) { beginStage(0, 0); return; } state = 'map'; fade = 0.6; mapSel = Math.min(LAST, SAVE.unl); mapPage = Math.floor(Math.floor(mapSel / 3) / 6); } });
    B.push({ x: ox + 235, y: 406, w: 150, h: 40, t: 'OPCIONES', c: '#35e2ff', small: true, fn: openOptions });
    B.push({ x: ox + 575, y: 406, w: 150, h: 40, t: 'LOGROS', c: '#ffc861', small: true, fn: openAch });
    B.push({ x: ox + 405, y: 406, w: 150, h: 40, t: 'HISTORIA', c: '#ffc861', small: true, fn: () => playCut('intro', () => { state = 'title'; fade = 1; playMusic('menu'); }) });
  } else if (state === 'map') {
    mapButtons(B);
  } else if (state === 'shop') {
    B.push({ x: ox + 380, y: 458, w: 200, h: 44, t: 'VOLVER', ic: 'left', c: '#35e2ff', fn: () => { state = 'map'; } });
    UPG.forEach((g, i) => { const lv = UP(g.k), max = lv >= g.cost.length, c = max ? 0 : g.cost[lv]; B.push({ x: ox + 640, y: 148 + i * 66, w: 156, h: 40, t: max ? 'MÁXIMO' : '◆ ' + c, c: g.c, sel: !max && bank() >= c, lock: max, small: true, fn: () => buyUp(g) }); });
  } else {
    let list = [];
    if (state === 'paused') list = [['CONTINUAR', resume, 'right'], ['HABILIDADES', openAbilMenu, 'time'], ['REINICIAR FASE', retry, 'time'], ['OPCIONES', openOptions, 'music'], ['MAPA', toMap, 'flag']];
    else if (state === 'gameover') list = [['CONTINUAR', reviveCheckpoint, 'right'], ['REINICIAR FASE', retry, 'time'], ['MAPA', toMap, 'flag']];
    else if (state === 'clear') list = [[curAct === 2 ? 'SIGUIENTE MUNDO' : curAct === 1 ? 'IR AL GUARDIÁN' : 'SIGUIENTE FASE', nextStage, 'right'], ['MAPA', toMap, 'flag']];
    else if (state === 'victory') list = [['VER MAPA', toMap, 'flag'], ['TÍTULO', toTitle, 'left']];
    const y0 = state === 'paused' ? 202 : state === 'gameover' ? 300 : 372;
    list.forEach((l, i) => B.push({ x: ox + 350, y: y0 + i * (state === 'paused' ? 50 : state === 'gameover' ? 56 : 60), w: 260, h: 48, t: l[0], ic: l[2], c: i === 0 ? '#ffcf4a' : '#35e2ff', c2: i === 0 ? '#ff8a3d' : '#7a5cff', sel: i === 0, fn: l[1] }));
  }
  return B;
}
function drawButton(b) {
  const pulse = b.big ? Math.sin(time * 4) * 2 : 0;
  const x = b.x - pulse, y = b.y - pulse / 2, w = b.w + pulse * 2, h = b.h + pulse;
  ctx.save();
  if (b.lock) { rrect(x, y, w, h, h / 2); ctx.fillStyle = 'rgba(255,255,255,.05)'; ctx.fill(); ctx.strokeStyle = 'rgba(255,255,255,.12)'; ctx.lineWidth = 1; ctx.stroke(); icon('lock', x + w / 2, y + h / 2, 16, 'rgba(255,255,255,.3)'); ctx.restore(); return; }
  if (b.sel) {
    if (b.big) { ctx.shadowColor = hexA(b.c, .7); ctx.shadowBlur = 24; }
    pill(x, y, w, h, b.c, b.c2 || b.c); ctx.shadowBlur = 0;
    rrect(x, y, w, h * .5, h / 2); ctx.fillStyle = 'rgba(255,255,255,.18)'; ctx.fill();
  } else { rrect(x, y, w, h, h / 2); ctx.fillStyle = 'rgba(20,18,44,.72)'; ctx.fill(); ctx.strokeStyle = b.seg ? hexA(b.c, .6) : 'rgba(255,255,255,.22)'; ctx.lineWidth = 1.2; ctx.stroke(); }
  const fc = b.sel ? '#15102a' : '#ffffff', sz = b.big ? 24 : b.small ? 13 : 16;
  ctx.font = '800 ' + sz + 'px ' + UIF; const tw = ctx.measureText(b.t).width, iw = b.ic ? sz * 1.1 : 0, gap = b.ic ? 8 : 0, sx = x + w / 2 - (tw + iw + gap) / 2;
  if (b.ic) icon(b.ic, sx + iw / 2, y + h / 2, sz * 1.05, fc);
  txt(b.t, sx + iw + gap, y + h / 2 + 1, sz, fc, null, 0, 'left', UIF, 800);
  if (b.stage !== undefined) { const st = SAVE.st[b.stage]; if (st && st.done) { ctx.fillStyle = b.sel ? '#15102a' : '#5ef08a'; ctx.beginPath(); ctx.arc(x + w - 10, y + 10, 4, 0, 6.3); ctx.fill(); } }
  ctx.restore();
}
// ---------- HUD ----------
const camR = { x: 0, y: 0 };
function worldToScreen(x, y) { const s = W / VW; return [((x - cam.x) * s - W / 2) * camZoom + W / 2, ((y - cam.y) * s - H / 2) * camZoom + H / 2]; }
let hudPop = 0, lastGems = 0, comboPop = 0, lastCombo = 0;
function bar(x, y, w, h, frac, lag, c1, c2) {
  rrect(x, y, w, h, h / 2); ctx.fillStyle = 'rgba(0,0,0,.45)'; ctx.fill();
  if (lag > frac) { rrect(x, y, Math.max(h, w * lag), h, h / 2); ctx.fillStyle = 'rgba(255,255,255,.75)'; ctx.fill(); }
  if (frac > 0) { rrect(x, y, Math.max(h, w * frac), h, h / 2); const g = ctx.createLinearGradient(x, 0, x + w, 0); g.addColorStop(0, c1); g.addColorStop(1, c2); ctx.fillStyle = g; ctx.fill();
    rrect(x + 2, y + 1, Math.max(h - 4, w * frac - 4), h * .38, h * .2); ctx.fillStyle = 'rgba(255,255,255,.3)'; ctx.fill(); }
}
function drawHUD() {
  ctx.imageSmoothingEnabled = false;
  const WD = WORLDS[curWorld];
  // Panel del héroe
  glass(14, 14, 318, 82, 18, WD.c);
  ctx.save(); ctx.beginPath(); ctx.arc(52, 55, 28, 0, 6.3); ctx.fillStyle = 'rgba(0,0,0,.5)'; ctx.fill(); ctx.clip();
  if (SPR.pt_kael) { ctx.imageSmoothingEnabled = true; ctx.drawImage(SPR.pt_kael, 20, 23, 64, 64); } ctx.restore();
  ctx.lineWidth = 2.5; ctx.strokeStyle = WD.c; ctx.beginPath(); ctx.arc(52, 55, 28, -Math.PI / 2, -Math.PI / 2 + 6.283 * clamp(p.hp / p.maxHp, 0, 1)); ctx.stroke();
  shadowTxt('KAEL', 90, 30, 15, '#ffffff', 'left', LOGOF, 800);
  txt(Math.max(0, Math.ceil(p.hp)) + ' / ' + p.maxHp, 318, 30, 12, 'rgba(255,255,255,.65)', null, 0, 'right', UIF, 600);
  const r = clamp(p.hp / p.maxHp, 0, 1), lag = clamp((p.hpLag || p.hp) / p.maxHp, 0, 1);
  bar(90, 41, 228, 12, r, lag, r > .5 ? '#3df5a0' : r > .25 ? '#ffd34d' : '#ff4d6d', r > .5 ? '#2ad0ff' : r > .25 ? '#ff8a3d' : '#ff2d8a');
  const tr = slowT > 0 ? slowT / 5.5 : p.time / 100, full = p.time >= 100;
  bar(90, 60, 140, 7, tr, 0, slowT > 0 ? '#8fe6ff' : '#ffb84a', slowT > 0 ? '#4aa8ff' : '#ffe27a');
  txt(slowT > 0 ? 'TIEMPO LENTO' : full ? 'TIEMPO LISTO' : 'TIEMPO', 236, 64, 10, full || slowT > 0 ? '#ffe27a' : 'rgba(255,255,255,.5)', null, 0, 'left', UIF, 700);
  const dr = 1 - p.dashCD / dashMax();
  bar(90, 76, 140, 7, dr, 0, '#35e2ff', '#7a8cff');
  txt('DASH', 236, 80, 10, dr >= 1 ? '#7fe9ff' : 'rgba(255,255,255,.4)', null, 0, 'left', UIF, 700);
  pill(282, 72, 40, 16, dim ? '#d070ff' : '#35e2ff', dim ? '#7a3dff' : '#2a8cff'); txt(dim ? 'DIM B' : 'DIM A', 302, 80.5, 9, '#ffffff', null, 0, 'center', UIF, 800);
  // Gemas / reliquia / puntos
  const lg = level.gems.filter(g => g.taken).length; if (lg !== lastGems) { hudPop = 1; lastGems = lg; } hudPop = Math.max(0, hudPop - 0.06);
  glass(344, 14, 214, 64, 18);
  const gm = META.gem, gs = 2 + hudPop * .6; ctx.drawImage(SPR.gem, Math.floor(time * 10) % gm.n * gm.fw, 0, gm.fw, gm.fh, 372 - gm.fw * gs / 2, 34 - gm.fh * gs / 2, gm.fw * gs, gm.fh * gs);
  shadowTxt(lg + '', 394, 34, 21 + hudPop * 4, '#ffffff', 'left', UIF, 800);
  ctx.font = '800 21px ' + UIF; const gw = ctx.measureText(lg + '').width;
  txt('/ ' + level.gems.length, 398 + gw, 35, 12, 'rgba(255,255,255,.5)', null, 0, 'left', UIF, 600);
  ctx.globalAlpha = level.relic && level.relic.taken ? 1 : 0.25; ctx.drawImage(SPR.hourglass, 524, 22, 18, 26); ctx.globalAlpha = 1;
  txt(String(score).padStart(7, '0'), 364, 62, 14, '#ffe27a', null, 0, 'left', UIF, 800);
  // Mundo y pausa
  ctx.save(); ctx.translate(W - 960, 0);
  shadowTxt('MUNDO ' + (WPOS(curWorld) + 1) + '-' + (curAct + 1), 892, 28, 16, WD.c, 'right', UIF, 900);
  txt(WD.name, 892, 46, 11, 'rgba(255,255,255,.7)', null, 0, 'right', UIF, 600);
  pill(892 - 70, 56, 70, 16, hexA(DIFFS[diffIdx].c, .25)); txt(DIFFS[diffIdx].name, 892 - 35, 64.5, 9, DIFFS[diffIdx].c, null, 0, 'center', UIF, 800);
  ctx.beginPath(); ctx.arc(904 + 21, 14 + 21, 21, 0, 6.3); ctx.fillStyle = 'rgba(20,18,44,.72)'; ctx.fill(); ctx.strokeStyle = 'rgba(255,255,255,.25)'; ctx.lineWidth = 1.2; ctx.stroke();
  icon('pause', 904 + 21, 14 + 21, 22, '#ffffff');
  // Combo
  if (p.combo !== lastCombo) { if (p.combo > lastCombo) comboPop = 1; lastCombo = p.combo; } comboPop = Math.max(0, comboPop - 0.05);
  if (p.combo >= 3) {
    const s = 1 + comboPop * .35, a = clamp(p.comboT / 0.6, 0, 1);
    ctx.save(); ctx.globalAlpha = a; ctx.translate(896, 108); ctx.scale(s, s); ctx.transform(1, 0, -0.18, 1, 0, 0);
    const g = ctx.createLinearGradient(0, -20, 0, 10); g.addColorStop(0, '#fff3a0'); g.addColorStop(1, '#ff8a3d');
    txt(p.combo + '', 2, 2, 38, 'rgba(0,0,0,.5)', null, 0, 'right', UIF, 900); txt(p.combo + '', 0, 0, 38, g, null, 0, 'right', UIF, 900);
    ctx.restore();
    ctx.globalAlpha = a; txt('COMBO  ×' + mult().toFixed(2), 892, 134, 11, '#ffffff', null, 0, 'right', UIF, 800); ctx.globalAlpha = 1;
    bar(812, 142, 80, 4, clamp(p.comboT / 2.5, 0, 1), 0, '#ffe27a', '#ff8a3d');
  }
  ctx.restore();
  ctx.save(); ctx.translate(Math.round((W - 960) / 2), 0);
  // Jefe
  if (boss && !boss.done && bossIntro <= 0) {
    const bw = 460, bxp = 480 - bw / 2, by = 112, br = boss.hp / boss.max, shield = (boss.type === 2 || boss.type === 9) && boss.vulnT <= 0;
    shadowTxt(boss.name, 480, by - 6, 15, '#ffffff', 'center', LOGOF, 800);
    boss.lag = boss.lag === undefined ? br : Math.max(br, boss.lag - 0.004);
    bar(bxp, by + 6, bw, 12, br, boss.lag, shield ? '#7fe9ff' : '#ff3d6e', shield ? '#3d8cff' : '#ff8a3d');
    if (boss.type === 9) { const bp = level.plates.filter(q => q.boss); bp.forEach((q, i) => { ctx.beginPath(); ctx.arc(471 + i * 18, by + 34, 5, 0, 6.3); ctx.fillStyle = q.on ? '#7fe9ff' : 'rgba(255,255,255,.2)'; ctx.fill(); }); }
    if (boss.type === 2) { const n = level.levers.filter(l => l.on).length; for (let i = 0; i < 3; i++) { ctx.beginPath(); ctx.arc(462 + i * 18, by + 34, 5, 0, 6.3); ctx.fillStyle = i < n ? '#5ef08a' : 'rgba(255,255,255,.2)'; ctx.fill(); } }
  }
  ctx.restore();
  if (echo && echo.rec) { const k = echo.t / 5; pill(W / 2 - 90, 100, 180, 26, 'rgba(20,60,90,.85)'); rrect(W / 2 - 86, 104, 172 * (1 - k), 18, 9); ctx.fillStyle = 'rgba(127,233,255,.5)'; ctx.fill(); txt('● GRABANDO ECO  (pulsa ECO)', W / 2, 113.5, 11, '#ffffff', null, 0, 'center', UIF, 800); }
}
function drawFloats() {
  for (const f of floats) {
    const [x, y] = worldToScreen(f.x, f.y), a = Math.min(1, f.life * 2), s = 1 + Math.max(0, f.life - 0.9) * 2;
    ctx.globalAlpha = a; txt(f.t, x + 1.5, y + 2, f.s * s, 'rgba(0,0,0,.6)', null, 0, 'center', UIF, 900); txt(f.t, x, y, f.s * s, f.c, null, 0, 'center', UIF, 900);
  }
  ctx.globalAlpha = 1;
}
function drawTouch() {
  if (!touchMode || state !== 'playing') return;
  ctx.save(); ctx.globalAlpha = OPT.alpha;
  if (OPT.ctrl === 'joystick') {
    if (stick.id !== null) {
      ctx.beginPath(); ctx.arc(stick.bx, stick.by, 56, 0, 6.3); ctx.fillStyle = 'rgba(255,255,255,.08)'; ctx.fill(); ctx.strokeStyle = 'rgba(255,255,255,.35)'; ctx.lineWidth = 2; ctx.stroke();
      const dx = clamp(stick.x - stick.bx, -56, 56), dy = clamp(stick.y - stick.by, -56, 56);
      const g = ctx.createRadialGradient(stick.bx + dx, stick.by + dy - 8, 4, stick.bx + dx, stick.by + dy, 28); g.addColorStop(0, 'rgba(255,255,255,.7)'); g.addColorStop(1, 'rgba(120,200,255,.35)');
      ctx.beginPath(); ctx.arc(stick.bx + dx, stick.by + dy, 26, 0, 6.3); ctx.fillStyle = g; ctx.fill();
    } else { ctx.globalAlpha = OPT.alpha * 0.45; ctx.beginPath(); ctx.arc(130, 450, 50, 0, 6.3); ctx.strokeStyle = 'rgba(255,255,255,.5)'; ctx.setLineDash([6, 6]); ctx.lineWidth = 2; ctx.stroke(); ctx.setLineDash([]); txt('MOVER', 130, 450, 11, 'rgba(255,255,255,.7)', null, 0, 'center', UIF, 800); ctx.globalAlpha = OPT.alpha; }
  }
  for (const k in touchBtn) {
    if (OPT.ctrl === 'joystick' && (k === 'left' || k === 'right')) continue;
    if (k === 'eco' && !ecoAvailable()) continue;
    const b = touchBtn[k], on = touchDown(k), cx = b.x + b.w / 2, cy = b.y + b.h / 2, rad = b.w / 2 * (on ? .93 : 1);
    let col = '#ffffff';
    if (k === 'jump') col = '#3df5a0'; else if (k === 'attack') col = '#ff4d6d'; else if (k === 'dash') col = p.dashCD > 0 ? '#6a6a8a' : '#35e2ff';
    else if (k === 'guard') col = p.guardBreak > 0 ? '#6a6a8a' : '#ffb84a';
    else if (k === 'shift') col = curWorld === 0 ? '#6a6a8a' : dim ? '#d070ff' : '#35e2ff'; else if (k === 'time') col = p.time >= 100 ? '#ffd34d' : '#8a7a50'; else if (k === 'eco') col = echo && echo.rec ? '#ff5470' : '#7fe9ff';
    ctx.save(); ctx.globalAlpha = OPT.alpha;
    const g = ctx.createRadialGradient(cx, cy - rad * .4, rad * .1, cx, cy, rad);
    g.addColorStop(0, hexA(col, on ? .55 : .3)); g.addColorStop(1, hexA(col, on ? .28 : .1));
    ctx.beginPath(); ctx.arc(cx, cy, rad, 0, 6.3); ctx.fillStyle = g; ctx.fill();
    ctx.lineWidth = 2; ctx.strokeStyle = hexA(col, on ? .95 : .55); ctx.stroke();
    if (k === 'time' && p.time < 100 && slowT <= 0) { ctx.strokeStyle = '#ffd34d'; ctx.lineWidth = 3; ctx.beginPath(); ctx.arc(cx, cy, rad - 4, -Math.PI / 2, -Math.PI / 2 + p.time / 100 * 6.283); ctx.stroke(); }
    if (k === 'guard' && (p.gst || 100) < 100) { ctx.strokeStyle = '#ffb84a'; ctx.lineWidth = 3; ctx.beginPath(); ctx.arc(cx, cy, rad - 4, -Math.PI / 2, -Math.PI / 2 + (p.gst || 0) / 100 * 6.283); ctx.stroke(); }
    if (k === 'dash' && p.dashCD > 0) { ctx.strokeStyle = '#35e2ff'; ctx.lineWidth = 3; ctx.beginPath(); ctx.arc(cx, cy, rad - 4, -Math.PI / 2, -Math.PI / 2 + (1 - p.dashCD / 0.7) * 6.283); ctx.stroke(); }
    ctx.globalAlpha = OPT.alpha * (on ? 1 : .85); if (k === 'eco') { ctx.strokeStyle = '#ffffff'; ctx.lineWidth = 2.5; ctx.beginPath(); ctx.arc(cx - 5, cy - 3, b.w * .16, 0, 6.3); ctx.stroke(); ctx.globalAlpha *= .5; ctx.beginPath(); ctx.arc(cx + 5, cy - 3, b.w * .16, 0, 6.3); ctx.stroke(); } else if (k === 'guard') { const r = b.w * .2, y = cy - 3; ctx.strokeStyle = '#ffffff'; ctx.lineWidth = 2.5; ctx.lineJoin = 'round'; ctx.beginPath(); ctx.moveTo(cx, y - r * 1.1); ctx.lineTo(cx + r, y - r * .6); ctx.lineTo(cx + r * .85, y + r * .3); ctx.quadraticCurveTo(cx + r * .5, y + r * .95, cx, y + r * 1.2); ctx.quadraticCurveTo(cx - r * .5, y + r * .95, cx - r * .85, y + r * .3); ctx.lineTo(cx - r, y - r * .6); ctx.closePath(); ctx.stroke(); } else icon(k, cx, cy - (b.w > 90 ? 4 : 2), b.w * .36, '#ffffff');
    if (k !== 'left' && k !== 'right') txt(b.label, cx, cy + b.w * .3, b.w < 80 ? 8 : 9, 'rgba(255,255,255,.75)', null, 0, 'center', UIF, 800);
    ctx.restore();
  }
  ctx.restore();
}
function drawBanner() {
  ctx.save(); ctx.translate(Math.round((W - 960) / 2), 0);
  const a = Math.min(1, bannerT * 2), e = 1 - Math.pow(1 - Math.min(1, (2.8 - bannerT) * 2.5), 3), sl = Math.round((1 - e) * 80);
  ctx.globalAlpha = a;
  if (bannerTxt) {
    ctx.save(); ctx.shadowColor = hexA(bannerC.length === 7 ? bannerC : '#ffffff', .7); ctx.shadowBlur = 30;
    const g = ctx.createLinearGradient(0, 160, 0, 210); g.addColorStop(0, '#ffffff'); g.addColorStop(1, bannerC);
    txt(bannerTxt, 480 - sl, 186, 50, g, null, 0, 'center', LOGOF, 900); ctx.restore();
    ctx.fillStyle = hexA(bannerC, .8); ctx.fillRect(480 - 140 * e, 216, 280 * e, 2);
  }
  shadowTxt(bannerSub, 480 + sl, bannerTxt ? 240 : 208, 22, bannerTxt ? '#ffffff' : bannerC, 'center', UIF, 700);
  ctx.globalAlpha = 1; ctx.restore();
}
function drawLore() {
  if (loreT <= 0) return;
  const a = Math.min(1, loreT * 2, (9 - loreT) * 3), text = WORLDS[curWorld].lore, shown = Math.floor(clamp((9 - loreT - 0.6) * 45, 0, text.length));
  if ((9 - loreT) < 0.6) return;
  ctx.save(); ctx.translate(Math.round((W - 960) / 2), 0);
  ctx.globalAlpha = a;
  glass(150, 116, 660, 92, 18, WORLDS[curWorld].c, true);
  ctx.save(); ctx.beginPath(); ctx.arc(196, 162, 30, 0, 6.3); ctx.fillStyle = 'rgba(0,0,0,.5)'; ctx.fill(); ctx.clip();
  const m = META.H_idle; ctx.drawImage(SPR.H_idle, m.ax - 16, m.ay - 50, 32, 32, 164, 128, 66, 66); ctx.restore();
  ctx.strokeStyle = WORLDS[curWorld].c; ctx.lineWidth = 2; ctx.beginPath(); ctx.arc(196, 162, 30, 0, 6.3); ctx.stroke();
  const lines = wrapText(text.slice(0, shown), 550, 15);
  lines.forEach((l, i) => txt(l, 242, 138 + i * 21, 15, '#ffffff', null, 0, 'left', UIF, 500));
  if (shown < text.length && Math.floor(time * 30) % 3 === 0) sfx('type', .06, 1.6);
  ctx.globalAlpha = 1; ctx.restore();
}
function drawHint() {
  if (hintT <= 0 || loreT > 0 || bannerT > 0 || (dlg && !(dlg.delay > 0))) return;
  const a = Math.min(1, hintT * 2, (5.5 - hintT) * 4);
  ctx.save(); ctx.translate(Math.round((W - 960) / 2), 0);
  ctx.globalAlpha = a;
  const lines = wrapText(hintTxt, 520, 14), h = 22 + lines.length * 20;
  glass(210, 150, 540, h, h > 44 ? 18 : h / 2, '#ffd34d', true);
  ctx.save(); ctx.translate(232, 150 + h / 2); ctx.rotate(Math.PI / 4); ctx.fillStyle = '#ffd34d'; ctx.fillRect(-5, -5, 10, 10); ctx.restore();
  lines.forEach((l, i) => txt(l, 494, 150 + h / 2 - (lines.length - 1) * 10 + i * 20, 14, '#fff3c0', null, 0, 'center', UIF, 600));
  ctx.globalAlpha = 1; ctx.restore();
}
function drawBossIntro() {
  if (!boss || bossIntro <= 0) return;
  if (dlg && dlg.hold) { ctx.fillStyle = '#000'; ctx.fillRect(0, 0, W, 70); ctx.fillRect(0, H - 70, W, 70); return; }
  const k = Math.min(1, (2.8 - bossIntro) * 3) * Math.min(1, bossIntro * 3), e = 1 - Math.pow(1 - k, 3);
  ctx.fillStyle = '#000'; ctx.fillRect(0, 0, W, Math.round(70 * e)); ctx.fillRect(0, H - Math.round(70 * e), W, Math.round(70 * e));
  ctx.globalAlpha = k; const sl = Math.round((1 - e) * 200), c = WORLDS[curWorld].c;
  const g = ctx.createLinearGradient(0, 0, 640, 0); g.addColorStop(0, 'rgba(0,0,0,.85)'); g.addColorStop(1, 'rgba(0,0,0,0)'); ctx.fillStyle = g; ctx.fillRect(0, 360, 760, 110);
  ctx.fillStyle = c; ctx.fillRect(40 - sl, 382, 4, 70);
  txt('GUARDIÁN DEL MUNDO ' + (WPOS(curWorld) + 1), 58 - sl, 394, 13, c, null, 0, 'left', UIF, 800);
  ctx.save(); ctx.shadowColor = hexA(c, .8); ctx.shadowBlur = 24; txt(boss.name, 56 - sl, 430, 34, '#ffffff', null, 0, 'left', LOGOF, 900); ctx.restore();
  const PORT = ['frog_boss_idle_s4', 'boss_ship', 'WZ_idle_s2', 'eye_s2', 'skel_idle_s2', 'hound_ice_s2', 'demon_idle', 'S_idle', 'boss_lev', 'boss_sph', 'boss_ser', 'boss_devo', 'boss_witch', 'boss_king'];
  const pk = boss.skin || hdbKey(boss.type) || PORT[boss.type], pm = meta(pk), R = 64, mx = 56 - sl + R, my = 300;
  ctx.save(); ctx.beginPath(); ctx.arc(mx, my, R, 0, 6.3); const rg = ctx.createRadialGradient(mx, my - 20, 6, mx, my, R); rg.addColorStop(0, hexA(c, .55)); rg.addColorStop(1, 'rgba(10,8,24,.92)'); ctx.fillStyle = rg; ctx.fill();
  ctx.clip(); ctx.imageSmoothingEnabled = false; const ps = Math.min(2.4 * R / pm.fh, 2.4 * R / pm.fw), flipP = !boss.skin && !hdbKey(boss.type) && (boss.type === 5 || boss.type === 6);
  ctx.translate(mx, my + R * 0.15); if (flipP) ctx.scale(-1, 1); ctx.drawImage(SPR[pk], 0, 0, pm.fw, pm.fh, -pm.fw * ps / 2, -pm.fh * ps / 2, pm.fw * ps, pm.fh * ps); ctx.restore();
  ctx.save(); ctx.beginPath(); ctx.arc(mx, my, R, 0, 6.3); ctx.strokeStyle = c; ctx.lineWidth = 3; ctx.shadowColor = c; ctx.shadowBlur = 16; ctx.stroke(); ctx.restore();
  ctx.globalAlpha = 1;
}
let vignette = null;
function drawVignette() {
  if (glOK) return;
  if (!vignette) { const [c, x] = mkCanvas(W, H), g = x.createRadialGradient(W / 2, H / 2, H * 0.42, W / 2, H / 2, H * 1.0); g.addColorStop(0, 'rgba(0,0,0,0)'); g.addColorStop(1, 'rgba(0,0,0,.5)'); x.fillStyle = g; x.fillRect(0, 0, W, H); vignette = c; }
  ctx.drawImage(vignette, 0, 0);
}
function drawOverlay() {
  ctx.fillStyle = 'rgba(6,4,16,.6)'; ctx.fillRect(0, 0, W, H);
  let title = '', col = '#fff', lines = [], pose = null;
  if (state === 'paused') { title = 'PAUSA'; col = '#35e2ff'; lines = ['Mundo ' + (WPOS(curWorld) + 1) + '-' + (curAct + 1) + ' · ' + WORLDS[curWorld].name, 'Puntos: ' + score]; }
  else if (state === 'gameover') { title = 'HAS CAÍDO'; col = '#ff4d6d'; pose = 'dead'; lines = ['Kael ha caído en ' + WORLDS[curWorld].name, (arenaLock && boss && !boss.done ? 'El guardián te espera: volverás a la entrada de la arena' : 'Volverás al último punto de control con la vida llena'), 'Puntos: ' + score + '   ·   Récord: ' + best]; }
  else if (state === 'clear') {
    title = curAct === 2 ? 'FRAGMENTO RECUPERADO' : 'FASE SUPERADA'; col = '#3df5a0'; pose = 'win';
    lines = ['Fragmentos de Realidad: ' + clearInfo.g + ' / ' + clearInfo.t + (clearInfo.relic ? '   ·   ¡Reloj secreto!' : ''), 'Tiempo ' + Math.floor(clearInfo.time / 60) + ':' + String(Math.floor(clearInfo.time % 60)).padStart(2, '0') + '   ·   Bonus +' + (clearInfo.bonus + clearInfo.hpB), 'Puntos totales: ' + score];
  } else if (state === 'victory') {
    title = 'EL RELOJ ESTÁ COMPLETO'; col = '#ffd34d'; pose = 'win';
    lines = ['El Devorador de Horas ha caído y el Corazón vuelve a latir.', 'Los dieciocho mundos giran de nuevo. Gracias por jugar.', DIFFS[diffIdx].name + '   ·   Puntos: ' + score + '   ·   Récord: ' + best];
  }
  const ph = state === 'paused' ? 400 : 410, py = Math.round((H - ph) / 2);
  ctx.save(); ctx.translate(Math.round((W - 960) / 2), 0);
  glass(220, py, 520, ph, 24, col, true);
  ctx.save(); ctx.shadowColor = hexA(col, .7); ctx.shadowBlur = 22;
  txt(title, 480, py + 52, title.length > 16 ? 24 : 34, col, null, 0, 'center', LOGOF, 900); ctx.restore();
  if (state === 'paused') lines.length = 1;
  lines.forEach((l, i) => txt(l, 480, py + 104 + i * 28, 15, i === lines.length - 1 ? '#ffe27a' : 'rgba(255,255,255,.9)', null, 0, 'center', UIF, i === lines.length - 1 ? 800 : 500));
  if (pose) {
    ctx.imageSmoothingEnabled = false;
    const k = pose === 'win' ? 'K_idle' : 'K_death', m = META[k], f = pose === 'win' ? Math.floor(time * 4) % m.n : m.n - 1;
    ctx.drawImage(SPR[k], f * m.fw, 0, m.fw, m.fh, 150 - m.ax * 2.2, py + ph - 18 - m.ay * 2.2, m.fw * 2.2, m.fh * 2.2);
  }
  ctx.restore();
  for (const b of uiButtons()) drawButton(b);
}
// ---------- Título ----------
function drawTitleBuffer() {
  if (SPR.keyart && SPR.keyart.width && state !== 'map' && state !== 'shop') {
    bx.setTransform(1, 0, 0, 1, 0, 0); const im = SPR.keyart, z = 1.06 + Math.sin(time * .1) * .03, w = (VW + 2) * z, h = w * im.height / im.width;
    bx.imageSmoothingEnabled = true; bx.drawImage(im, (VW + 2 - w) / 2 + Math.sin(time * .13) * 8, (VH + 2 - h) / 2, w, h); bx.imageSmoothingEnabled = false;
    if (glOK) { lx.setTransform(1, 0, 0, 1, 0, 0); lx.globalCompositeOperation = 'source-over'; lx.fillStyle = '#9a968a'; lx.fillRect(0, 0, lightBuf.width, lightBuf.height); }
    for (const a of amb) { a.x += Math.sin(time + a.ph) * .3; a.y -= .3; if (a.y < -10) a.y = 540; }
    curWorld = 7; drawWeather(true); curWorld = 0; return;
  }
  const mx = time * 70; cam.x = mx; cam.y = 180; curWorld = 0;
  bx.setTransform(1, 0, 0, 1, 0, 0);
  if (glOK) { lx.setTransform(1, 0, 0, 1, 0, 0); lx.globalCompositeOperation = 'source-over'; lx.fillStyle = '#7a7670'; lx.fillRect(0, 0, lightBuf.width, lightBuf.height); }
  bx.fillStyle = '#6ad6f0'; bx.fillRect(0, 0, VW + 2, VH + 2);
  tileH(SPR.bg_j_back, 0.08, VH - SPR.bg_j_back.height * 2 + 40, 2);
  tileH(SPR.bg_j_mid, 0.3, VH - 300, 1, 60);
  drawLivingBG(0);
  tileH(darkened('bg_j_mid', 'rgba(8,40,36,.62)'), 0.55, VH - 190, 1, 140);
  const T = SPR.T_jungle, o = META.T_jungle.order, gx = -Math.round(mx % 16) - 16;
  for (let x = gx; x < VW + 18; x += 16) { bx.drawImage(T, o.indexOf('t') * 16, 0, 16, 16, x, 318, 16, 16); for (let y = 334; y < VH + 2; y += 16) bx.drawImage(T, o.indexOf('c') * 16, 0, 16, 16, x, y, 16, 16); }
  const tx = -Math.round(mx % 900) + 700;
  bx.drawImage(SPR.p_tree, tx, 318 - SPR.p_tree.height); bx.drawImage(SPR.p_bush, tx + 300, 318 - SPR.p_bush.height);
  const m = META.K_run, f = Math.floor(time * 13) % m.n;
  bx.drawImage(SPR.K_run, f * m.fw, 0, m.fw, m.fh, 110 - m.ax, 320 - m.ay, m.fw, m.fh);
  if (SPR.cr_tic) { const tm = meta('cr_tic'); bx.drawImage(SPR.cr_tic, 82 - tm.fw / 2, 262 + Math.sin(time * 3) * 5 - tm.fh / 2); }
  lightAt(110, 300, 120, 'rgba(255,240,210,1)', .3);
  const o2 = META.opossum, f2 = Math.floor(time * 10) % o2.n, fl = flipped('opossum');
  bx.drawImage(fl, (o2.n - 1 - f2) * o2.fw, 0, o2.fw, o2.fh, 40 - o2.ax, 319 - o2.ay, o2.fw, o2.fh);
  const e2 = META.eagle, f3 = Math.floor(time * 10) % e2.n;
  bx.drawImage(SPR.eagle, f3 * e2.fw, 0, e2.fw, e2.fh, 520, 200 + Math.round(Math.sin(time * 2) * 10), e2.fw, e2.fh);
  const g = META.gem;
  for (let i = 0; i < 4; i++) { const gxp = 200 + i * 40 - Math.round(mx % 160), gyp = 290 + Math.round(Math.sin(time * 3 + i) * 3); glowAt(gxp + 7, gyp + 6, 12, 'rgba(255,90,200,.5)', .7); bx.drawImage(SPR.gem, (Math.floor(time * 10) + i) % g.n * g.fw, 0, g.fw, g.fh, gxp, gyp, g.fw, g.fh); }
  camR.x = cam.x; camR.y = cam.y; drawFog(false);
  for (const a of amb) { a.x += Math.sin(time + a.ph) * .3; a.y += .4; if (a.y > 540) a.y = -10; }
  drawWeather(true);
  edgeFill();
}
function drawTitle() {
  const g0 = ctx.createLinearGradient(0, 0, 0, H); g0.addColorStop(0, 'rgba(10,6,30,.6)'); g0.addColorStop(.4, 'rgba(10,6,30,.25)'); g0.addColorStop(.62, 'rgba(10,6,30,.45)'); g0.addColorStop(1, 'rgba(10,6,30,.6)'); ctx.fillStyle = g0; ctx.fillRect(0, 0, W, H);
  const ly = 112 + Math.sin(time * 1.6) * 4;
  ctx.save(); ctx.translate(Math.round((W - 960) / 2), 0);
  ctx.save();
  ctx.shadowColor = 'rgba(80,200,255,.9)'; ctx.shadowBlur = 40;
  const g = ctx.createLinearGradient(0, ly - 45, 0, ly + 40); g.addColorStop(0, '#ffffff'); g.addColorStop(.45, '#8ff0ff'); g.addColorStop(1, '#7a5cff');
  txt('CHRONOS', 480, ly, 96, g, null, 0, 'center', LOGOF, 900);
  ctx.restore();
  ctx.save(); ctx.globalCompositeOperation = 'lighter'; const sx = ((time * 0.35) % 1.6 - 0.3) * W; const sg = ctx.createLinearGradient(sx - 80, 0, sx + 80, 0); sg.addColorStop(0, 'rgba(255,255,255,0)'); sg.addColorStop(.5, 'rgba(255,255,255,.35)'); sg.addColorStop(1, 'rgba(255,255,255,0)');
  ctx.font = '900 96px ' + LOGOF; ctx.fillStyle = sg; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillText('CHRONOS', 480, ly); ctx.restore();
  ctx.font = '700 22px ' + LOGOF; ctx.letterSpacing = '10px';
  try { ctx.letterSpacing = '8px'; } catch (e) {}
  txt('& THE SHIFT', 486, ly + 66, 22, '#ffcf6a', null, 0, 'center', LOGOF, 700);
  try { ctx.letterSpacing = '0px'; } catch (e) {}
  ctx.fillStyle = 'rgba(255,207,106,.7)'; ctx.fillRect(330, ly + 84, 300, 1.5);
  shadowTxt('18 MUNDOS  ·  54 FASES  ·  18 GUARDIANES  ·  11 HABILIDADES', 480, 290, 14, 'rgba(255,255,255,.9)', 'center', UIF, 700);
  ctx.restore();
  for (const b of uiButtons()) drawButton(b);
  txt(padActive ? 'MANDO:  A saltar · X espada · B/RT dash · LB/LT guardia · Y dimensión · RB tiempo · SELECT eco · START pausa' : touchMode ? 'Mover · Salto (doble y en pared) · Dash · Espada · Shift · Tiempo' : '← → mover · ESPACIO saltar · SHIFT dash · Z espada · X dimensión · C tiempo · E eco · P pausa', W / 2, 488, 12, 'rgba(255,255,255,.75)', null, 0, 'center', UIF, 500);
  glass(14, 14, 150, 34, 17); txt('RÉCORD  ' + best, 89, 31.5, 12, '#ffe27a', null, 0, 'center', UIF, 800);
  if (PRUEBA) { pill(174, 14, 250, 34, 'rgba(255,80,60,.85)', 'rgba(255,150,40,.85)'); txt('MODO PRUEBA · TODO ABIERTO', 299, 31.5, 12, '#ffffff', null, 0, 'center', UIF, 900); }
  ctx.beginPath(); ctx.arc(musicBtn.x + 21, musicBtn.y + 21, 21, 0, 6.3); ctx.fillStyle = 'rgba(20,18,44,.72)'; ctx.fill(); ctx.strokeStyle = 'rgba(255,255,255,.25)'; ctx.lineWidth = 1.2; ctx.stroke();
  icon('music', musicBtn.x + 21, musicBtn.y + 21, 22, musicOn ? '#3df5a0' : 'rgba(255,255,255,.3)');
  txt('AETHER CODE', W - 16, 524, 11, 'rgba(255,255,255,.6)', null, 0, 'right', LOGOF, 700);
  if (window.innerHeight > window.innerWidth) { pill(W / 2 - 230, 54, 460, 34, '#ff3d8a', '#7a5cff'); txt('Gira el teléfono para jugar en horizontal', W / 2, 71, 14, '#ffffff', null, 0, 'center', UIF, 700); }
}
// ---------- Mapa con vistas previas ----------
const THUMB = {};
function worldThumb(w) {
  if (THUMB[w]) return THUMB[w];
  const sw = curWorld, sc = { x: cam.x, y: cam.y }, svw = VW, svh = VH, sa = amb;
  curWorld = w; amb = []; setView(320, 180); cam.x = 400 + w * 300; cam.y = 180;
  bx.setTransform(1, 0, 0, 1, 0, 0); drawBG();
  const T = SPR[WORLDS[w].tiles], o = META[WORLDS[w].tiles].order;
  for (let x = 0; x < 322; x += 16) { bx.drawImage(T, o.indexOf('t') * 16, 0, 16, 16, x, 150, 16, 16); bx.drawImage(T, o.indexOf('c') * 16, 0, 16, 16, x, 166, 16, 16); }
  const [c, x] = mkCanvas(320, 180); x.drawImage(buf, 0, 0, 320 * QR, 180 * QR, 0, 0, 320, 180);
  const gg = x.createLinearGradient(0, 0, 0, 180); gg.addColorStop(0, 'rgba(0,0,0,0)'); gg.addColorStop(1, 'rgba(0,0,0,.45)'); x.fillStyle = gg; x.fillRect(0, 0, 320, 180);
  setView(svw, svh); curWorld = sw; cam.x = sc.x; cam.y = sc.y; amb = sa;
  return (THUMB[w] = c);
}
const BOSS_ICON = [['frog_boss_idle', 2, false], ['boss_ship', 0.45, false], ['WZ_idle', 1, false], ['eye', 0.9, false], ['skel_idle', 0.9, false], ['hound_ice', 1, true], ['demon_idle', 0.5, true], ['DK_idle', 1, false]];
function drawMap() {
  const g0 = ctx.createLinearGradient(0, 0, 0, H); g0.addColorStop(0, 'rgba(8,6,24,.82)'); g0.addColorStop(1, 'rgba(8,6,24,.7)'); ctx.fillStyle = g0; ctx.fillRect(0, 0, W, H);
  const mox = Math.round((W - 960) / 2);
  ctx.save(); ctx.shadowColor = 'rgba(80,200,255,.7)'; ctx.shadowBlur = 18; txt('MAPA DEL TIEMPO', W / 2 - 110, 36, 24, '#ffffff', null, 0, 'center', LOGOF, 900); ctx.restore();
  for (let w = 0; w < 8; w++) {
    const WD = WORLDS[w], cx = mox + 22 + (w % 4) * 234, cy = 72 + Math.floor(w / 4) * 226, lock = sIdx(w, 0) > SAVE.unl;
    const hover = !touchMode && Math.floor(mapSel / 2) === w;
    glass(cx, cy, 218, 210, 18, lock ? null : WD.c, true);
    ctx.save(); rrect(cx + 8, cy + 8, 202, 104, 12); ctx.clip();
    ctx.imageSmoothingEnabled = false; ctx.globalAlpha = lock ? 0.25 : 1;
    ctx.drawImage(worldThumb(w), cx + 8, cy + 8, 202, 114);
    const ic = BOSS_ICON[w], m = meta(ic[0]), sc = Math.min(ic[1], 62 / m.fh, 110 / m.fw), src = ic[2] ? flipped(ic[0]) : SPR[ic[0]];
    ctx.drawImage(src, 0, 0, m.fw, m.fh, Math.round(cx + 109 - m.fw * sc / 2), Math.round(cy + 104 - m.fh * sc), m.fw * sc, m.fh * sc);
    ctx.restore();
    ctx.strokeStyle = hover ? '#ffffff' : 'rgba(255,255,255,.18)'; ctx.lineWidth = hover ? 2 : 1; rrect(cx + 8, cy + 8, 202, 104, 12); ctx.stroke();
    if (lock) icon('lock', cx + 109, cy + 60, 30, 'rgba(255,255,255,.7)');
    txt('MUNDO ' + (w + 1), cx + 14, cy + 128, 11, lock ? 'rgba(255,255,255,.3)' : WD.c, null, 0, 'left', UIF, 900);
    txt(WD.name, cx + 14, cy + 144, WD.name.length > 17 ? 12 : 14, lock ? 'rgba(255,255,255,.35)' : '#ffffff', null, 0, 'left', UIF, 800);
    if (!lock) {
      let gems = 0, tot = 0, rel = 0;
      for (let a = 0; a < 2; a++) { const st = SAVE.st[sIdx(w, a)]; if (st) { gems += st.gems; tot += st.total; rel += st.relic ? 1 : 0; } }
      txt(tot ? ('◆ ' + gems + '/' + tot + '   ⌛ ' + rel + '/2') : WD.sub, cx + 14, cy + 158, 10, tot ? '#ffe27a' : 'rgba(255,255,255,.55)', null, 0, 'left', UIF, 600);
    } else txt('Bloqueado', cx + 14, cy + 158, 10, 'rgba(255,255,255,.3)', null, 0, 'left', UIF, 600);
  }
  for (const b of uiButtons()) drawButton(b);
  if (!touchMode) { const w = Math.floor(mapSel / 2), a = mapSel % 2, x = mox + 22 + (w % 4) * 234 + 8 + a * 105, y = 72 + Math.floor(w / 4) * 226 + 168; ctx.strokeStyle = '#ffffff'; ctx.lineWidth = 2; rrect(x - 3, y - 3, 103, 40, 20); ctx.stroke(); }
}
function drawLoading() {
  ctx.setTransform(RES, 0, 0, RES, 0, 0);
  const g = ctx.createLinearGradient(0, 0, 0, H); g.addColorStop(0, '#120e2a'); g.addColorStop(1, '#05040e'); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  ctx.save(); ctx.translate(Math.round((W - 960) / 2), 0);
  txt('CHRONOS & THE SHIFT', 480, 232, 34, '#ffffff', null, 0, 'center', fontsReady ? LOGOF : UIF, 900);
  bar(330, 290, 300, 8, totalN ? loadedN / totalN : 0, 0, '#35e2ff', '#7a5cff');
  txt('Cargando 18 mundos…', 480, 324, 13, 'rgba(255,255,255,.6)', null, 0, 'center', UIF, 600);
  ctx.restore();
}
function drawOptions() {
  ctx.fillStyle = 'rgba(6,4,16,.66)'; ctx.fillRect(0, 0, W, H);
  const ox = Math.round((W - 960) / 2);
  ctx.save(); ctx.translate(ox, 0);
  glass(190, 40, 580, 470, 24, '#35e2ff', true);
  ctx.save(); ctx.shadowColor = 'rgba(80,200,255,.7)'; ctx.shadowBlur = 18; txt('OPCIONES', 480, 82, 26, '#ffffff', null, 0, 'center', LOGOF, 900); ctx.restore();
  const OR = optRows(), sp = Math.min(34, Math.floor(340 / OR.length));
  OR.forEach((r, i) => {
    const y = 108 + i * sp, fz = sp < 32 ? 14 : 15;
    if (i % 2 === 0) { rrect(212, y - 2, 536, sp - 3, 10); ctx.fillStyle = 'rgba(255,255,255,.04)'; ctx.fill(); }
    txt(r[0], 230, y + (sp - 4) / 2, fz, '#ffffff', null, 0, 'left', UIF, 600);
    txt(r[1], 655, y + (sp - 4) / 2, fz, '#7fe9ff', null, 0, 'center', UIF, 800);
  });
  ctx.restore();
  for (const b of uiButtons()) drawButton(b);
}
let INV = null;
function invertBuffer() {
  const k = invertT > 5.5 ? (6 - invertT) / 0.5 : invertT < 0.5 ? invertT / 0.5 : 1, sy = 1 - 2 * clamp(k, 0, 1);
  if (!INV || INV[0].width !== buf.width || INV[0].height !== buf.height) INV = mkCanvas(buf.width, buf.height);
  const [c, x] = INV; x.setTransform(1, 0, 0, 1, 0, 0); x.clearRect(0, 0, c.width, c.height); x.drawImage(buf, 0, 0);
  bx.setTransform(1, 0, 0, 1, 0, 0); bx.fillStyle = '#000'; bx.fillRect(0, 0, VW + 2, VH + 2);
  bx.save(); bx.translate(0, (VH + 2) / 2); bx.scale(1, Math.abs(sy) < 0.02 ? 0.02 : sy); bx.drawImage(c, 0, -(VH + 2) / 2, VW + 2, VH + 2); bx.restore();
}
// ---------- Composición final ----------
function present() {
  const ox = 1 + (cam.x - Math.floor(cam.x)), oy = 1 + (cam.y - Math.floor(cam.y));
  const menu = state === 'title' || state === 'map' || state === 'shop' || (state === 'options' && optPrev !== 'paused');
  if (glOK) { glPresent(LOOK[menu ? 0 : curWorld], menu ? 1 : ox, menu ? 1 : oy); ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.clearRect(0, 0, cv.width, cv.height); ctx.setTransform(RES, 0, 0, RES, 0, 0); return; }
  ctx.setTransform(1, 0, 0, 1, 0, 0); ctx.imageSmoothingEnabled = false;
  ctx.drawImage(buf, ox * QR, oy * QR, VW * QR, VH * QR, 0, 0, cv.width, cv.height);
  ctx.setTransform(RES, 0, 0, RES, 0, 0);
}
function setupLight() {
  if (!glOK) return;
  lx.setTransform(1, 0, 0, 1, 0, 0); lx.globalCompositeOperation = 'source-over'; lx.globalAlpha = 1;
  lx.fillStyle = LOOK[curWorld].amb; lx.fillRect(0, 0, lightBuf.width, lightBuf.height);
  if ((curWorld === 4 || curWorld === 15 || curWorld === 17) && lightning > 0 && Math.floor(lightning * 20) % 2 === 0) { lx.fillStyle = 'rgba(200,190,255,.35)'; lx.fillRect(0, 0, lightBuf.width, lightBuf.height); }
}
function draw() {
  if (state === 'loading') { drawLoading(); return; }
  if (state === 'cutscene') { drawCut(); return; }
  if (state === 'ability') { drawAbilityCard(); if (fade > 0) { ctx.fillStyle = 'rgba(0,0,0,' + fade + ')'; ctx.fillRect(0, 0, W, H); } return; }
  if (state === 'fragment') { drawFragment(); return; }
  const sceneSt = state === 'options' ? optPrev : state;
  if (sceneSt === 'title' || sceneSt === 'map' || sceneSt === 'shop') {
    if (VW !== MENUW() || VH !== 360) setView(MENUW(), 360);
    camZoom = 1;
    drawTitleBuffer(); present(); drawVignette();
    if (state === 'options') drawOptions(); else if (state === 'title') drawTitle(); else if (state === 'shop') drawShop(); else drawMap2();
    if (fade > 0) { ctx.fillStyle = 'rgba(0,0,0,' + fade + ')'; ctx.fillRect(0, 0, W, H); }
    return;
  }
  const sk = OPT.shake ? shake : 0, sx = sk > 0 ? Math.round((Math.random() - .5) * sk) : 0, sy = sk > 0 ? Math.round((Math.random() - .5) * sk) : 0;
  camR.x = Math.floor(cam.x) - 1 + sx; camR.y = Math.floor(cam.y) - 1 + sy; lastShake.x = sx; lastShake.y = sy;
  setupLight();
  bx.setTransform(1, 0, 0, 1, 0, 0);
  drawBG(); drawGiants(); drawAmbEventsBG(); drawFog(false);
  bx.setTransform(1, 0, 0, 1, -camR.x, -camR.y); if (glOK) lx.setTransform(1, 0, 0, 1, -camR.x, -camR.y);
  drawWorld();
  bx.setTransform(1, 0, 0, 1, 0, 0); if (glOK) lx.setTransform(1, 0, 0, 1, 0, 0);
  drawGodRays();
  if (curWorld === 5 || curWorld === 3) drawWeather(false);
  if (LOOK[curWorld].fogA > .2) drawFog(true);
  drawForeground();
  if (dim === 1) { bx.fillStyle = 'rgba(150,60,255,.08)'; bx.fillRect(0, 0, VW + 2, VH + 2); }
  if (slowT > 0) { bx.fillStyle = 'rgba(80,170,255,.12)'; bx.fillRect(0, 0, VW + 2, VH + 2); }
  if (shiftFx > 0) { bx.fillStyle = (dim ? 'rgba(200,100,255,' : 'rgba(60,220,255,') + shiftFx * .5 + ')'; for (let y = 0; y < VH + 2; y += 3) bx.fillRect(0, y, VW + 2, 1); }
  if (flash > 0) { bx.fillStyle = 'rgba(' + flashCol + ',' + Math.min(.5, flash * 2) + ')'; bx.fillRect(0, 0, VW + 2, VH + 2); }
  if (invertT > 0) invertBuffer();
  present();
  drawVignette();
  drawAmbEventsHD(); drawLiveHD(); drawHeroHD(); drawTicHD(); drawTicSay(); drawAbilHUD();
  drawFloats();
  drawBossIntro();
  if (bossIntro <= 0 || !boss) { drawHUD(); drawTouch(); }
  if (state === 'playing' && dlg && !(dlg.delay > 0)) drawDlgHUD();
  if (state === 'playing') drawGemFly(1 / 60);
  if (bannerT > 0 && state === 'playing' && bossIntro <= 0) drawBanner();
  if (state === 'playing') { drawLore(); drawHint(); }
  if (state === 'options') drawOptions(); else if (state !== 'playing') drawOverlay();
  if (fade > 0) { ctx.fillStyle = 'rgba(0,0,0,' + fade + ')'; ctx.fillRect(0, 0, W, H); }
}
let last = performance.now();
function frame(now) {
  let dt = (now - last) / 1000; last = now;
  if (dt > 0.05) dt = 0.05; if (dt < 0) dt = 0;
  perfSample(dt); qrSample(dt);
  if (state === 'loading' && ready) { state = 'title'; fade = 1; }
  if (state === 'cutscene') updateCut(dt);
  readInput();
  if (state === 'playing') {
    if (hitStop > 0) { hitStop -= dt; time += dt * 0.2; }
    else { let acc = dt; while (acc > 0.00001 && state === 'playing') { const s = Math.min(acc, 1 / 120); update(s); for (const k of ACTS) pressed[k] = false; acc -= s; } }
  } else { time += dt; if (fade > 0) fade = Math.max(0, fade - dt * 2.5); if (state !== 'paused') updateParticles(dt); }
  draw();
  requestAnimationFrame(frame);
}
resize();
initGL();
loadAssets();
requestAnimationFrame(frame);
