// =====================================================================
//  RENDER EN ALTA RESOLUCIÓN
//  El mundo se sigue describiendo en "píxeles del mundo", pero el búfer
//  de escena se dibuja a QR× resolución y las imágenes pintadas llevan
//  una densidad (_d) para conservar todo su detalle.
// =====================================================================
let QR = ((window.devicePixelRatio || 1) >= 2.5 && Math.max(innerWidth, innerHeight) >= 700) ? 3 : 2;
// --- drawImage consciente de la densidad ---
const _DI = CanvasRenderingContext2D.prototype.drawImage;
CanvasRenderingContext2D.prototype.drawImage = function (img, a, b, c, d, e, f, g, h) {
  const k = img && img._d, n = arguments.length;
  if (!k) { if (n === 3) return _DI.call(this, img, a, b); if (n === 5) return _DI.call(this, img, a, b, c, d); return _DI.call(this, img, a, b, c, d, e, f, g, h); }
  const sm = this.imageSmoothingEnabled; this.imageSmoothingEnabled = true;
  if (n === 3) _DI.call(this, img, a, b, img._ww, img._wh);
  else if (n === 5) _DI.call(this, img, a, b, c, d);
  else _DI.call(this, img, a * k, b * k, c * k, d * k, e, f, g, h);
  this.imageSmoothingEnabled = sm;
};
// lienzo derivado con la misma densidad que su imagen de origen
function dmk(im, w, h) {
  const k = im && im._d;
  const ww = w !== undefined ? w : (k ? im._ww : im.width), wh = h !== undefined ? h : (k ? im._wh : im.height);
  if (!k) return mkCanvas(ww, wh);
  const [c, x] = mkCanvas(Math.round(ww * k), Math.round(wh * k));
  x.setTransform(k, 0, 0, k, 0, 0); x.imageSmoothingEnabled = true; c._d = k; c._ww = ww; c._wh = wh;
  return [c, x];
}
// lienzo HD para cachés del escenario (terreno, fondos)
function qmk(ww, wh) {
  const [c, x] = mkCanvas(Math.ceil(ww * QR), Math.ceil(wh * QR));
  x.setTransform(QR, 0, 0, QR, 0, 0); c._d = QR; c._ww = ww; c._wh = wh; return [c, x];
}
// lienzo del terreno: algo menos denso a QR 3 para no agotar la memoria gráfica del teléfono
function qmkT(ww, wh) {
  const d = Math.min(QR, 2.5);
  const [c, x] = mkCanvas(Math.ceil(ww * d), Math.ceil(wh * d));
  x.setTransform(d, 0, 0, d, 0, 0); c._d = d; c._ww = ww; c._wh = wh; return [c, x];
}
// las imágenes con densidad informan su tamaño "del mundo"
function applyDensity(k) {
  const im = SPR[k], m = META[k]; if (!im || !m || !m.d || im._d) return;
  const fix = () => { if (!im.naturalWidth) return; im._d = m.d; im._ww = Math.round(im.naturalWidth / m.d); im._wh = Math.round(im.naturalHeight / m.d); im.width = im._ww; im.height = im._wh; };
  if (im.complete && im.naturalWidth) fix(); else im.addEventListener('load', fix);
}
// --- el búfer de escena trabaja a QR× ---
const _bxST = bx.setTransform.bind(bx);
bx.setTransform = function (a, b, c, d, e, f) { if (typeof a === 'object') return _bxST(a); _bxST(a * QR, b * QR, c * QR, d * QR, e * QR, f * QR); };
setView = function (w, h, force) {
  if (!force && VW === w && VH === h && buf.width === Math.round((w + 2) * QR)) return; VW = w; VH = h;
  buf.width = Math.round((w + 2) * QR); buf.height = Math.round((h + 2) * QR); bx.imageSmoothingEnabled = false; bx.imageSmoothingQuality = 'high';
  if (typeof lightBuf !== 'undefined') { lightBuf.width = w + 2; lightBuf.height = h + 2; }
  bx.setTransform(1, 0, 0, 1, 0, 0);
};
// relleno de los bordes del búfer (antes se copiaba la última fila/columna)
function edgeFill() {
  _DI.call(bx, buf, (VW - 1) * QR, 0, QR, VH * QR, VW, 0, 2, VH);
  _DI.call(bx, buf, 0, (VH - 1) * QR, (VW + 2) * QR, QR, 0, VH, VW + 2, 2);
}
// bajar la resolución si el teléfono no mantiene la fluidez
let qrT = 0, qrN = 0, qrS = 0;
function qrSample(dt) {
  if (QR <= 2 || state !== 'playing') return;
  qrS += dt; qrN++; qrT += dt;
  if (qrT > 4) { const avg = qrS / qrN; qrT = qrS = qrN = 0; if (avg > 0.022) setQR(2); }
}
function setQR(q) {
  QR = q; for (const k in PBGM) delete PBGM[k]; for (const k in BLK) delete BLK[k];
  setView(VW, VH, true);
  if (level && level.plats) for (const s of level.plats) if (s.k === 'solid' && s.cache2) s.cache2 = renderPlat2(s, level.wi);
}
// ---------------- sombras de contacto ----------------
function contactShadow(x, y, w, a) {
  if (w <= 0) return;
  const g = glowSpr('rgba(0,0,0,1)');
  bx.globalAlpha = clamp(a, 0, 1); bx.drawImage(g, Math.round(x - w), Math.round(y - w * 0.18), Math.round(w * 2), Math.max(2, Math.round(w * 0.36))); bx.globalAlpha = 1;
}
// suelo bajo un punto (para proyectar sombras)
function groundBelow(x, y, maxd) {
  let best = null;
  for (const s of level.plats) { if (!(s.k === 'solid' || s.k === 'move' || s.k === 'break' || s.k === 'bounce')) continue; if (x < s.x || x > s.x + s.w) continue; if (s.y >= y - 2 && s.y - y < (maxd || 160) && (!best || s.y < best)) best = s.y; }
  return best;
}
function drawContactShadows() {
  if (!level) return;
  const sh = (x, y, w, a) => { const gy = groundBelow(x, y, 200); if (gy === null) return; const d = gy - y; contactShadow(x, gy + 1, w * (1 + d / 260), a * clamp(1 - d / 200, 0, 1)); };
  if (p && !p.dead) sh(p.x + p.w / 2, p.y + p.h, 13, 0.55);
  for (const e of level.enemies) if (!e.dead && onScreen(e.x, e.w)) sh(e.x + e.w / 2, e.y + e.h, e.w * 0.45, 0.45);
  if (level.live) {
    for (const c of level.live.c) if (!c.gone && onScreen(c.x - 20, 40) && !LIVE_AIR[c.k] && c.k !== 'bird') sh(c.x, c.y, c.k === 'stag' ? 22 : 7, 0.4);
    for (const o of level.live.o) if (o.st !== 2 && onScreen(o.x - 20, 40)) contactShadow(o.x, o.y + 1, o.k === 'chest' || o.k[0] === 'W' ? 12 : 9, 0.38);
  }
  if (boss && !boss.done && level.arena) sh(boss.x + boss.w / 2, boss.y + boss.h, boss.w * 0.5, 0.5);
}
