// =====================================================================
//  MULTIIDIOMA: español, inglés, portugués, francés, alemán, italiano,
//  japonés, coreano y chino. Los datos (historia, mundos, habilidades…)
//  se traducen en su sitio; los textos de la interfaz, al dibujarse.
// =====================================================================
const LANGS = [['es', 'Español'], ['en', 'English'], ['pt', 'Português'], ['fr', 'Français'], ['de', 'Deutsch'], ['it', 'Italiano'], ['ja', '日本語'], ['ko', '한국어'], ['zh', '简体中文']];
let LANG = OPT.lang || 'es';
let TRM = null, TRF = [], TRC = new Map();
const CJK = () => LANG === 'ja' || LANG === 'zh';
const HAS_LAT = /[A-Za-zÁÉÍÓÚÑáéíóúñ¡¿]/;
function buildTR() {
  TRC.clear(); TRF = [];
  if (LANG === 'es' || !I18N[LANG]) { TRM = null; return; }
  const T = I18N[LANG]; TRM = new Map();
  for (let i = 0; i < I18N_ES.length; i++) {
    const s = I18N_ES[i], t = T[i]; TRM.set(s, t);
    // fragmentos para textos compuestos ("Puntos: " + n …)
    if (s !== t && (s.length >= 5 || /[\s:·¡!¿?]/.test(s)) && s.trim().length >= 3) TRF.push([s, t]);
  }
  TRF.sort((a, b) => b[0].length - a[0].length);
  // nombres propios y logotipo: nunca se traducen
  for (const k of ['CHRONOS', '& THE SHIFT', 'CHRONOS & THE SHIFT', 'AETHER CODE', 'KAEL', 'TIC', 'LYRA']) TRM.set(k, k);
}
function TR(s) {
  if (!TRM || typeof s !== 'string' || s.length < 2 || !HAS_LAT.test(s)) return s;
  const e = TRM.get(s); if (e !== undefined) return e;
  const c = TRC.get(s); if (c !== undefined) return c;
  let r = s;
  for (const [a, b] of TRF) if (r.indexOf(a) >= 0) r = r.split(a).join(b);
  if (TRC.size > 3000) TRC.clear();
  TRC.set(s, r); return r;
}
// ---- datos del juego: se guardan los originales para poder cambiar de idioma ----
const I18N_SLOTS = [];
(function collect() {
  const keys = new Set(I18N_ES), seen = new Set();
  const names = { WHO, CUTS, FRAGL, TICL, BOSSL, DIFFS, WORLDS, HINTS, TICQ, LYRA_WHISPERS, LIVE_HINT, UPG, ABIL, ABIL_GUARD, ACH, TL };
  const walk = (o, d) => {
    if (!o || typeof o !== 'object' || d > 8 || seen.has(o)) return; seen.add(o);
    if (o instanceof HTMLElement || o instanceof Image) return;
    for (const k of Object.keys(o)) { const v = o[k]; if (typeof v === 'string') { if (keys.has(v)) I18N_SLOTS.push([o, k, v]); } else walk(v, d + 1); }
  };
  for (const n in names) walk(names[n], 0);
})();
function applyDataLang() { for (const [o, k, es] of I18N_SLOTS) o[k] = TRM ? (TRM.get(es) ?? es) : es; }
function setLang(l) {
  LANG = l; OPT.lang = l; buildTR(); applyDataLang();
  try { localStorage.setItem('chronos_opts', JSON.stringify(OPT)); } catch (e) {}
  try { layoutTouch(); } catch (e) {}
  try { for (const k in THUMB) delete THUMB[k]; } catch (e) {}
  document.documentElement.lang = l;
}
// ---- dibujo de texto: todo pasa por aquí ----
const C2D = CanvasRenderingContext2D.prototype;
const _fillText = C2D.fillText, _strokeText = C2D.strokeText, _measureText = C2D.measureText;
C2D.fillText = function (t, x, y, m) { return m === undefined ? _fillText.call(this, TR(t), x, y) : _fillText.call(this, TR(t), x, y, m); };
C2D.strokeText = function (t, x, y, m) { return m === undefined ? _strokeText.call(this, TR(t), x, y) : _strokeText.call(this, TR(t), x, y, m); };
C2D.measureText = function (t) { return _measureText.call(this, TR(t)); };
// ajuste de líneas: traducir antes de partir; japonés y chino se parten por caracteres
const _wrapText18 = wrapText;
wrapText = function (t, maxW, size) {
  t = TR(t);
  if (!CJK()) return _wrapText18(t, maxW, size);
  ctx.font = '500 ' + size + 'px ' + UIF;
  const lines = []; let cur = '';
  for (const ch of t) {
    const n = cur + ch;
    if (_measureText.call(ctx, n).width > maxW && cur && !'、。，．！？）」』…・ー'.includes(ch)) { lines.push(cur); cur = ch.trim(); }
    else cur = n;
  }
  if (cur) lines.push(cur);
  return lines;
};
// ---- botones: el texto se encoge si el idioma lo hace más largo ----
const _drawButton18 = drawButton;
drawButton = function (b) {
  if (b.t) {
    const base = b.big ? 24 : b.small ? 13 : 16; ctx.save(); ctx.font = '800 ' + base + 'px ' + UIF;
    const iw = b.ic ? base * 1.1 + 8 : 0, tw = ctx.measureText(b.t).width; ctx.restore();
    if (tw + iw > b.w - 20) {
      const k = Math.max(0.55, (b.w - 20 - iw) / tw), _txt = txt;
      txt = function (s, x, y, size, ...r) { return _txt(s, x, y, size * k, ...r); };
      try { _drawButton18(b); } finally { txt = _txt; }
      return;
    }
  }
  _drawButton18(b);
};

// ---- pantalla de elección de idioma (primer arranque) ----
let langSel = 0, langFrom = 'title';
function guessLang() { const n = (navigator.language || 'es').slice(0, 2).toLowerCase(); const i = LANGS.findIndex(l => l[0] === n); return i < 0 ? 1 : i; }
function openLang(from) { langFrom = from || 'title'; langSel = Math.max(0, LANGS.findIndex(l => l[0] === LANG)); state = 'lang'; fade = .5; }
function langButtons() {
  const B = [], ox = Math.round((W - 960) / 2);
  LANGS.forEach((l, i) => { const c = i % 3, r = Math.floor(i / 3); B.push({ x: ox + 190 + c * 200, y: 176 + r * 74, w: 180, h: 56, l: l[0], name: l[1], i }); });
  return B;
}
function chooseLang(i) { setLang(LANGS[i][0]); sfx('select'); state = langFrom === 'options' ? 'options' : 'title'; fade = 1; }
function drawLang() {
  ctx.fillStyle = '#07060f'; ctx.fillRect(0, 0, W, H);
  const k = SPR.keyart; if (k && k.width) { ctx.save(); ctx.globalAlpha = .28; const s = Math.max(W / k.width, H / k.height); ctx.drawImage(k, (W - k.width * s) / 2, (H - k.height * s) / 2, k.width * s, k.height * s); ctx.restore(); }
  const g = ctx.createRadialGradient(W / 2, H / 2, 40, W / 2, H / 2, W * .7); g.addColorStop(0, 'rgba(10,6,24,.35)'); g.addColorStop(1, 'rgba(4,2,10,.92)'); ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);
  const T = I18N[LANGS[langSel][0]], idx = I18N_ES.indexOf('Elige tu idioma'), idx2 = I18N_ES.indexOf('Puedes cambiarlo cuando quieras en Opciones');
  const tt = LANGS[langSel][0] === 'es' ? I18N_ES[idx] : T[idx], st = LANGS[langSel][0] === 'es' ? I18N_ES[idx2] : T[idx2];
  const keep = TRM; TRM = null;   // aquí el texto ya está en el idioma resaltado
  ctx.save(); ctx.shadowColor = 'rgba(255,190,90,.7)'; ctx.shadowBlur = 18; txt(tt, W / 2, 92, 30, '#ffd88a', null, 0, 'center', LOGOF, 900); ctx.restore();
  txt(st, W / 2, 132, 14, 'rgba(255,255,255,.7)', null, 0, 'center', UIF, 600);
  for (const b of langButtons()) {
    const on = b.i === langSel;
    if (on) { ctx.save(); ctx.shadowColor = 'rgba(255,200,100,.8)'; ctx.shadowBlur = 18; pill(b.x, b.y, b.w, b.h, '#ffcf4a', '#ff8a3d'); ctx.restore(); }
    else { rrect(b.x, b.y, b.w, b.h, b.h / 2); ctx.fillStyle = 'rgba(20,18,44,.8)'; ctx.fill(); ctx.strokeStyle = 'rgba(255,255,255,.25)'; ctx.lineWidth = 1.2; ctx.stroke(); }
    txt(b.name, b.x + b.w / 2, b.y + b.h / 2 + 1, 19, on ? '#15102a' : '#ffffff', null, 0, 'center', UIF, 800);
  }
  TRM = keep;
}
const _draw18 = draw;
draw = function () {
  // el mapa de luz debe medir lo mismo que la escena (al arrancar quedaba en 300×150 y el título salía rayado)
  if (typeof lightBuf !== 'undefined' && (lightBuf.width !== VW + 2 || lightBuf.height !== VH + 2)) { lightBuf.width = VW + 2; lightBuf.height = VH + 2; }
  if (state === 'title' && !OPT.lang) { openLang('title'); langSel = guessLang(); }
  if (state === 'lang') { drawLang(); if (fade > 0) { ctx.fillStyle = 'rgba(0,0,0,' + fade + ')'; ctx.fillRect(0, 0, W, H); } try { drawToasts(1 / 60); } catch (e) {} return; }
  _draw18();
};
const _handleTap18 = handleTap;
handleTap = function (x, y, type) {
  if (state === 'lang') { for (const b of langButtons()) if (inRect({ x, y }, b)) { langSel = b.i; chooseLang(b.i); return; } return; }
  _handleTap18(x, y, type);
};
const _onKey18 = onKey;
onKey = function (c) {
  if (state === 'lang') {
    if (c === 'ArrowLeft') langSel = (langSel + LANGS.length - 1) % LANGS.length;
    else if (c === 'ArrowRight') langSel = (langSel + 1) % LANGS.length;
    else if (c === 'ArrowUp') langSel = (langSel + LANGS.length - 3) % LANGS.length;
    else if (c === 'ArrowDown') langSel = (langSel + 3) % LANGS.length;
    else if (c === 'Enter' || c === 'Space' || c === 'KeyZ') { chooseLang(langSel); return; }
    else if ((c === 'Escape') && OPT.lang) { state = langFrom === 'options' ? 'options' : 'title'; return; }
    sfx('click', .5); return;
  }
  _onKey18(c);
};
// ---- fila "Idioma" en Opciones ----
const _optRows18 = optRows;
optRows = function () {
  const R = _optRows18(), cur = Math.max(0, LANGS.findIndex(l => l[0] === LANG));
  R.unshift(['Idioma', LANGS[cur][1], () => setLang(LANGS[(cur + LANGS.length - 1) % LANGS.length][0]), () => setLang(LANGS[(cur + 1) % LANGS.length][0])]);
  return R;
};
const _backAction18 = backAction;
backAction = function () { if (state === 'lang') { if (OPT.lang) state = langFrom === 'options' ? 'options' : 'title'; return; } _backAction18(); };
// arranque
buildTR(); applyDataLang();
// el búfer de escena se creó antes de conocer la densidad (QR): se ajusta ya
try { setView(VW, VH, true); } catch (e) {}
