// =====================================================================
//  PANTALLA VERTICAL U HORIZONTAL (v2.9)
//  Opción «Pantalla»: Horizontal (como siempre), Vertical o Automática.
//  En vertical el juego ocupa TODA la pantalla de arriba abajo: la
//  cámara muestra un mundo más alto que ancho y los controles van
//  encima, en la parte de abajo, semitransparentes.
//  En Android la orientación se fija con @capacitor/screen-orientation.
// =====================================================================
if (!OPT.orient) OPT.orient = 'h';
const ORIENT_NAME = { h: 'Horizontal', v: 'Vertical', a: 'Automática' };
function applyOrient() {
  const o = OPT.orient, SO = window.Capacitor && Capacitor.Plugins && Capacitor.Plugins.ScreenOrientation;
  try {
    if (SO) { if (o === 'a') SO.unlock(); else SO.lock({ orientation: o === 'v' ? 'portrait' : 'landscape' }); return; }
    if (screen.orientation) { if (o === 'a') screen.orientation.unlock(); else screen.orientation.lock(o === 'v' ? 'portrait' : 'landscape').catch(() => {}); }
  } catch (e) {}
}
goFull = function () {
  if (!OPT.full) return;
  try { const el = document.documentElement; if (!document.fullscreenElement && el.requestFullscreen) el.requestFullscreen({ navigationUI: 'hide' }).then(applyOrient).catch(() => {}); } catch (e) {}
};
setTimeout(applyOrient, 300);
// fila en Opciones
const _optRowsS = optRows;
optRows = function () {
  const R = _optRowsS(), seq = ['h', 'v', 'a'];
  const mv = d => () => { OPT.orient = seq[(seq.indexOf(OPT.orient) + d + 3) % 3]; saveOpts(); applyOrient(); };
  R.splice(3, 0, ['Pantalla', ORIENT_NAME[OPT.orient], mv(-1), mv(1)]);
  return R;
};
// ---------------- modo vertical a pantalla completa ----------------
let tallOn = false, safeTop = 0;
const safeProbe = document.createElement('div'); safeProbe.style.cssText = 'position:absolute;top:0;left:0;width:1px;height:env(safe-area-inset-top,0px);pointer-events:none;visibility:hidden';
document.body.appendChild(safeProbe);
const isPortrait = () => window.innerHeight > window.innerWidth * 1.05;
const tallWanted = () => isPortrait() && state === 'playing';
const TALL_VW = 240;
const tallView = () => { const vh = Math.min(560, Math.round(TALL_VW * H / W / 2) * 2); return [Math.round(vh * W / H / 2) * 2, vh]; };
const _setViewS = setView;
setView = function (w, h) { if (tallOn) { const v = tallView(); return _setViewS(v[0], v[1]); } return _setViewS(w, h); };
// botones grandes en la parte de abajo de la pantalla
function layoutTall() {
  const k = W / 960, m = 40 * k, by = H - m;
  const S = (n, x, y, sz) => { touchBtn[n] = { x: x - sz * k / 2, y: y - sz * k / 2, w: sz * k, h: sz * k, label: TL[n] }; };
  S('left', 125 * k, by - 140 * k, 210); S('right', 345 * k, by - 140 * k, 210);
  S('jump', W - 140 * k, by - 160 * k, 240); S('attack', W - 385 * k, by - 85 * k, 200); S('dash', W - 330 * k, by - 330 * k, 170);
  const abil = ['eco', 'guard', 'time', 'shift'].filter(n => TL[n]);
  abil.forEach((n, i) => S(n, W - 120 * k - i * 165 * k, by - 560 * k, 140));
}
const _layoutTouchS = layoutTouch;
layoutTouch = function () { _layoutTouchS(); if (tallOn) layoutTall(); };
const _resizeS = resize;
resize = function () {
  const was = tallOn;
  tallOn = false; if (H !== 540) { H = 540; W = 0; } _resizeS();
  tallOn = tallWanted();
  if (!tallOn) { if (was) { setView(arenaLock ? ARW() : EXW(), arenaLock ? ARH : EXH); } return; }
  safeTop = safeProbe.getBoundingClientRect().height || 0;
  const cw = window.innerWidth, chh = Math.max(200, window.innerHeight - safeTop);
  W = 720; H = Math.round(W * chh / cw / 2) * 2;
  cv.width = W * RES; cv.height = H * RES;
  const g = document.getElementById('gl'); if (g) { g.width = W * RES; g.height = H * RES; }
  if (typeof vignette !== 'undefined') vignette = null;
  try { if (glScale !== 1) applyGLScale(glScale); } catch (e) {}
  setView(0, 0);
  for (const el of [cv, g]) { if (!el) continue; el.style.width = cw + 'px'; el.style.height = chh + 'px'; el.style.left = '0px'; el.style.top = safeTop + 'px'; }
  layoutTouch();
  if (level && p) updateCamera(0, true);
};
// cámara: en vertical se ve más mundo por arriba y por debajo, con el suelo hacia el centro
const _updateCameraS = updateCamera;
updateCamera = function (dt, snap) {
  const y0 = cam.y, x0 = cam.x;
  _updateCameraS(dt, snap);
  if (!tallOn || !level) return;
  if (arenaLock && level.arena) {
    // en vertical la vista es estrecha: seguir a Kael y solo inclinarse un poco hacia el jefe
    const A = level.arena, pcx = p.x + p.w / 2, near = boss && !boss.done ? lerp(pcx, boss.x + boss.w / 2, bossIntro > 0 ? 0.7 : 0.18) : pcx;
    let tx = clamp(near - VW / 2, A.x1 - 40, A.x2 + 40 - VW);
    if (bossIntro <= 0) tx = clamp(tx, pcx - VW + 50, pcx - 50);
    cam.x = snap ? tx : lerp(x0, tx, Math.min(1, dt * 7));
  }
  const ty = clamp(p.y + p.h / 2 - VH * 0.55, level.top - 220, level.bottom + 200 - VH);
  cam.y = snap ? ty : lerp(y0, ty, Math.min(1, dt * 5));
};
const _touchDownS = touchDown;
touchDown = function (name) {
  if (!tallOn) return _touchDownS(name);
  if (OPT.ctrl === 'joystick' && (name === 'left' || name === 'right')) { const d = stickDir()[0]; return name === 'left' ? d < 0 : d > 0; }
  const b = touchBtn[name]; if (!b) return false;
  for (const pt of ptrs.values()) {
    if (pt.stick) continue;
    if (name === 'left' || name === 'right') { if (pt.x > b.x - 15 && pt.x < b.x + b.w + 15 && pt.y > b.y - 50 && pt.y < b.y + b.h + 50) return true; }
    else if (Math.hypot(pt.x - (b.x + b.w / 2), pt.y - (b.y + b.h / 2)) < b.w * 0.6) return true;
  }
  return false;
};
// las flechas y los nombres de los botones, a la medida de los botones grandes
const _drawTouchS = drawTouch;
drawTouch = function () {
  _drawTouchS();
  if (!tallOn || !touchMode || state !== 'playing') return;
  ctx.save(); ctx.globalAlpha = OPT.alpha; ctx.fillStyle = 'rgba(255,255,255,.85)';
  for (const k of ['left', 'right']) {
    if (OPT.ctrl === 'joystick') break;
    const b = touchBtn[k], cx = b.x + b.w / 2, cy = b.y + b.h / 2, s = k === 'left' ? -1 : 1, r = b.w * 0.18;
    ctx.beginPath(); ctx.moveTo(cx + s * r, cy); ctx.lineTo(cx - s * r * 0.65, cy - r); ctx.lineTo(cx - s * r * 0.65, cy + r); ctx.closePath(); ctx.fill();
  }
  ctx.restore();
};
// cambiar de diseño al entrar o salir de una partida, o al girar el teléfono
let tallLast = null;
const _frameS = frame;
frame = function (now) {
  const want = tallWanted();
  if (want !== tallLast) { tallLast = want; resize(); }
  _frameS(now);
};
window.addEventListener('orientationchange', () => setTimeout(resize, 250));
