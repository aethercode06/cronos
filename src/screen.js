// =====================================================================
//  PANTALLA VERTICAL U HORIZONTAL (v2.9)
//  Opción «Pantalla»: Horizontal (como siempre), Vertical o Automática.
//  En vertical el juego ocupa todo el ancho arriba y los controles van
//  en un panel propio debajo, grandes y sin tapar la acción.
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
// ---------------- panel de controles en vertical ----------------
const pad = document.createElement('canvas'); pad.id = 'pad';
pad.style.cssText = 'position:absolute;left:0;display:none;touch-action:none;background:#07050f';
document.body.appendChild(pad);
const pctx = pad.getContext('2d');
let PDW = 960, PDH = 1200, padOn = false, safeTop = 0, padGY = 0;
const safeProbe = document.createElement('div'); safeProbe.style.cssText = 'position:absolute;top:0;left:0;width:1px;height:env(safe-area-inset-top,0px);pointer-events:none;visibility:hidden';
document.body.appendChild(safeProbe);
const isPortrait = () => window.innerHeight > window.innerWidth * 1.05;
const padWanted = () => isPortrait() && touchMode && (state === 'playing' || state === 'paused');
// botones del panel (coordenadas del panel); y en coordenadas "extendidas" (debajo del lienzo del juego)
const PADB = {};
function layoutPad() {
  const k = PDW / 960, m = 46 * k, by = PDH - m, u = Math.min(1, PDH / (1000 * k));
  const S = (n, x, y, sz) => { PADB[n] = { x: x - sz * k / 2, y: y - sz * k / 2, w: sz * k, h: sz * k, label: TL[n] }; };
  S('left', 125 * k, by - 140 * k * u, 210); S('right', 345 * k, by - 140 * k * u, 210);
  S('jump', PDW - 140 * k, by - 160 * k * u, 240); S('attack', PDW - 385 * k, by - 85 * k * u, 200); S('dash', PDW - 330 * k, by - 330 * k * u, 170);
  const ry = Math.max(90 * k, by - 560 * k * u), abil = ['eco', 'guard', 'time', 'shift'].filter(n => TL[n]);
  abil.forEach((n, i) => S(n, PDW / 2 + (i - (abil.length - 1) / 2) * 200 * k, ry, 150));
}
const _layoutTouchS = layoutTouch;
layoutTouch = function () {
  _layoutTouchS();
  if (!padOn) return;
  layoutPad();
  for (const k in PADB) { const b = PADB[k]; touchBtn[k] = { x: b.x, y: b.y + H, w: b.w, h: b.h, label: b.label }; }
};
const _resizeS = resize;
resize = function () {
  _resizeS();
  padOn = padWanted();
  if (!padOn) { pad.style.display = 'none'; return; }
  safeTop = safeProbe.getBoundingClientRect().height || 0;
  // en vertical la vista del juego es menos ancha (720) para que todo se vea más grande
  if (W !== 720) {
    W = 720; cv.width = W * RES; cv.height = H * RES;
    const g = document.getElementById('gl'); if (g) { g.width = W * RES; g.height = H * RES; }
    if (typeof vignette !== 'undefined') vignette = null;
    setView(arenaLock ? ARW() : EXW(), arenaLock ? ARH : EXH);
    try { if (glScale !== 1) applyGLScale(glScale); } catch (e) {}
  }
  const cw = window.innerWidth, ch = Math.floor(cw * H / W);
  // el panel ocupa toda la pantalla; el juego va encima, centrado sobre los controles
  const ph = Math.max(200, window.innerHeight - safeTop);
  PDW = W; PDH = Math.round(PDW * ph / cw);
  pad.width = PDW; pad.height = PDH; pad.style.width = cw + 'px'; pad.style.height = ph + 'px'; pad.style.top = safeTop + 'px'; pad.style.display = 'block';
  layoutPad();
  let ctrlTop = PDH; for (const k in PADB) ctrlTop = Math.min(ctrlTop, PADB[k].y);
  const ctrlTopCss = ctrlTop * cw / PDW, gy = Math.max(0, Math.floor((ctrlTopCss - ch) / 2 - 10));
  padGY = gy * PDW / cw;
  for (const el of [cv, document.getElementById('gl')]) { if (!el) continue; el.style.width = cw + 'px'; el.style.height = ch + 'px'; el.style.left = '0px'; el.style.top = (safeTop + gy) + 'px'; el.style.zIndex = 2; }
  layoutTouch();
};
// toques en el panel: se guardan con la y "extendida" para que touchDown funcione igual
function padPt(e) { const r = pad.getBoundingClientRect(); return { x: (e.clientX - r.left) * PDW / r.width, y: (e.clientY - r.top) * PDH / r.height + H }; }
pad.addEventListener('pointerdown', e => {
  initAudio(); e.preventDefault(); try { pad.setPointerCapture(e.pointerId); } catch (er) {}
  touchMode = true; const pt = padPt(e), rec = { x: pt.x, y: pt.y };
  const inBtn = Object.keys(touchBtn).some(k => !(OPT.ctrl === 'joystick' && (k === 'left' || k === 'right')) && inRect(pt, touchBtn[k]));
  if (OPT.ctrl === 'joystick' && pt.x < PDW * 0.5 && stick.id === null && !inBtn) { stick.id = e.pointerId; stick.bx = stick.x = pt.x; stick.by = stick.y = pt.y; rec.stick = true; }
  ptrs.set(e.pointerId, rec);
});
pad.addEventListener('pointermove', e => { const o = ptrs.get(e.pointerId); if (!o) return; const pt = padPt(e); o.x = pt.x; o.y = pt.y; if (o.stick) { stick.x = pt.x; stick.y = pt.y; } });
const padUp = e => { const o = ptrs.get(e.pointerId); if (o && o.stick) stick.id = null; ptrs.delete(e.pointerId); };
pad.addEventListener('pointerup', padUp); pad.addEventListener('pointercancel', padUp);
const _touchDownS = touchDown;
touchDown = function (name) {
  if (!padOn) return _touchDownS(name);
  if (OPT.ctrl === 'joystick' && (name === 'left' || name === 'right')) { const d = stickDir()[0]; return name === 'left' ? d < 0 : d > 0; }
  const b = touchBtn[name]; if (!b) return false;
  for (const pt of ptrs.values()) {
    if (pt.stick || pt.y < H) continue;
    if (name === 'left' || name === 'right') { if (pt.x > b.x - 20 && pt.x < b.x + b.w + 20 && pt.y > b.y - 60 && pt.y < b.y + b.h + 60) return true; }
    else if (Math.hypot(pt.x - (b.x + b.w / 2), pt.y - (b.y + b.h / 2)) < b.w * 0.62) return true;
  }
  return false;
};
// en vertical los botones no se dibujan encima del juego
const _drawTouchS = drawTouch;
drawTouch = function () { if (padOn) return; _drawTouchS(); };
function drawPad() {
  if (!padOn) return;
  const c = pctx;
  const g = c.createLinearGradient(0, 0, 0, PDH); g.addColorStop(0, '#120a24'); g.addColorStop(1, '#07050f');
  c.fillStyle = g; c.fillRect(0, 0, PDW, PDH);
  const gh = PDW * H / W; c.fillStyle = 'rgba(53,226,255,.35)'; c.fillRect(0, padGY - 3, PDW, 3); c.fillRect(0, padGY + gh, PDW, 3);
  if (state === 'paused') { c.fillStyle = 'rgba(0,0,0,.5)'; c.fillRect(0, 0, PDW, PDH); return; }
  if (OPT.ctrl === 'joystick') {
    if (stick.id !== null) {
      const bx = stick.bx, by = stick.by - H, dx = clamp(stick.x - stick.bx, -80, 80), dy = clamp(stick.y - stick.by, -80, 80);
      c.beginPath(); c.arc(bx, by, 84, 0, 6.3); c.fillStyle = 'rgba(255,255,255,.08)'; c.fill(); c.strokeStyle = 'rgba(255,255,255,.35)'; c.lineWidth = 3; c.stroke();
      c.beginPath(); c.arc(bx + dx, by + dy, 40, 0, 6.3); c.fillStyle = 'rgba(120,200,255,.55)'; c.fill();
    } else { c.save(); c.globalAlpha = .45; c.setLineDash([8, 8]); c.strokeStyle = 'rgba(255,255,255,.6)'; c.lineWidth = 3; c.beginPath(); c.arc(260, PDH - 200, 90, 0, 6.3); c.stroke(); c.restore(); }
  }
  for (const k in PADB) {
    if (OPT.ctrl === 'joystick' && (k === 'left' || k === 'right')) continue;
    if (k === 'eco' && !(typeof ecoAvailable === 'function' && ecoAvailable())) continue;
    const b = PADB[k], on = touchDown(k), cx = b.x + b.w / 2, cy = b.y + b.h / 2, rad = b.w / 2 * (on ? .93 : 1);
    let col = '#ffffff';
    if (k === 'jump') col = '#3df5a0'; else if (k === 'attack') col = '#ff4d6d'; else if (k === 'dash') col = p.dashCD > 0 ? '#6a6a8a' : '#35e2ff';
    else if (k === 'guard') col = p.guardBreak > 0 ? '#6a6a8a' : '#ffb84a';
    else if (k === 'shift') col = curWorld === 0 ? '#6a6a8a' : dim ? '#d070ff' : '#35e2ff'; else if (k === 'time') col = p.time >= 100 ? '#ffd34d' : '#8a7a50'; else if (k === 'eco') col = echo && echo.rec ? '#ff5470' : '#7fe9ff';
    c.save();
    const gr = c.createRadialGradient(cx, cy - rad * .4, rad * .1, cx, cy, rad);
    gr.addColorStop(0, hexA(col, on ? .6 : .32)); gr.addColorStop(1, hexA(col, on ? .3 : .12));
    c.beginPath(); c.arc(cx, cy, rad, 0, 6.3); c.fillStyle = gr; c.fill();
    c.lineWidth = 3; c.strokeStyle = hexA(col, on ? .95 : .6); c.stroke();
    if (k === 'time' && p.time < 100 && slowT <= 0) { c.strokeStyle = '#ffd34d'; c.lineWidth = 5; c.beginPath(); c.arc(cx, cy, rad - 7, -Math.PI / 2, -Math.PI / 2 + p.time / 100 * 6.283); c.stroke(); }
    if (k === 'dash' && p.dashCD > 0) { c.strokeStyle = '#35e2ff'; c.lineWidth = 5; c.beginPath(); c.arc(cx, cy, rad - 7, -Math.PI / 2, -Math.PI / 2 + (1 - p.dashCD / 0.7) * 6.283); c.stroke(); }
    c.fillStyle = 'rgba(255,255,255,.85)'; c.textAlign = 'center'; c.textBaseline = 'middle';
    if (k === 'left' || k === 'right') { c.beginPath(); const s = k === 'left' ? -1 : 1; c.moveTo(cx + s * 40, cy); c.lineTo(cx - s * 26, cy - 40); c.lineTo(cx - s * 26, cy + 40); c.closePath(); c.fill(); }
    else { c.font = '800 ' + Math.round(b.w * 0.17) + 'px ' + UIF; c.fillText(tr(b.label), cx, cy); }
    c.restore();
  }
}
const tr = s => { try { return (typeof TRM !== 'undefined' && TRM && TRM.get(s)) || s; } catch (e) { return s; } };
// cambiar de diseño al entrar o salir de una partida, o al girar el teléfono
let padLast = null;
const _frameS = frame;
frame = function (now) {
  const want = padWanted();
  if (want !== padLast) { padLast = want; resize(); }
  _frameS(now);
  drawPad();
};
window.addEventListener('orientationchange', () => setTimeout(resize, 250));
