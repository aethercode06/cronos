"use strict";
/* =====================================================================
   CHRONOS & THE SHIFT  —  Aether Code
   Motor 2D propio (HTML5 Canvas + WebGL)
   Arte original (Kael, Tic, Lyra, criaturas, jefes 9-12, fondos pintados e
   ilustraciones de la historia): creado para Aether Code con Higgsfield.
   Arte CC0 adicional: Evil Wizard, Monsters Creatures Fantasy, Fire Worm (Luiz Melo);
   Sunny Land, Warped City, Gothicvania, Mountain Dusk, Demon (ansimuz);
   Colorized Boss Sprites (OpenGameArt). Audio CC0: Kenney, Ninja Adventure.
   ===================================================================== */

// ---------------- Lienzo ----------------
const cv = document.getElementById('c');
const ctx = cv.getContext('2d', { alpha: true });
let W = 960, H = 540; const RES = 2;
cv.width = W * RES; cv.height = H * RES;
// Opciones del jugador (se guardan en el teléfono)
let OPT = { mus: 0.8, sfx: 0.9, vib: true, shake: true, ctrl: 'botones', size: 1, alpha: 0.7, full: true };
try { const o = JSON.parse(localStorage.getItem('chronos_opts') || 'null'); if (o) OPT = Object.assign(OPT, o); } catch (e) {}
function saveOpts() { try { localStorage.setItem('chronos_opts', JSON.stringify(OPT)); } catch (e) {} applyOpts(); }
function applyOpts() { if (typeof master !== 'undefined' && master) master.gain.value = 0.85 * OPT.sfx; if (typeof curMusic !== 'undefined' && curMusic) curMusic.volume = (curMusicId === 'menu' ? 0.5 : musicVol) * OPT.mus; layoutTouch(); }
function vib(p) { if (OPT.vib && navigator.vibrate) try { navigator.vibrate(p); } catch (e) {} }
const EXW = () => Math.round(W / 2 / 2) * 2, EXH = 270, ARH = 420, ARW = () => Math.round(W * ARH / 540 / 2) * 2, MENUW = () => Math.round(W / 1.5 / 2) * 2;
function resize() {
  const land = window.innerWidth >= window.innerHeight;
  const nw = land ? clamp(Math.round(540 * window.innerWidth / window.innerHeight / 2) * 2, 960, 1280) : 960;
  if (nw !== W) {
    W = nw; cv.width = W * RES; cv.height = H * RES;
    const g = document.getElementById('gl'); if (g) { g.width = W * RES; g.height = H * RES; }
    if (typeof vignette !== 'undefined') vignette = null;
    if (typeof state !== 'undefined' && typeof setView === 'function' && (state === 'playing' || state === 'paused')) { setView(arenaLock ? ARW() : EXW(), arenaLock ? ARH : EXH); }
    else if (typeof setView === 'function') setView(MENUW(), 360);
  }
  layoutTouch();
  const s = Math.min(window.innerWidth / W, window.innerHeight / H);
  for (const el of [cv, document.getElementById('gl')]) {
    el.style.width = Math.floor(W * s) + 'px'; el.style.height = Math.floor(H * s) + 'px';
    el.style.left = Math.floor((window.innerWidth - W * s) / 2) + 'px'; el.style.top = Math.max(0, Math.floor((window.innerHeight - H * s) / 2)) + 'px';
  }
}
window.addEventListener('resize', resize);
const buf = document.createElement('canvas');
const bx = buf.getContext('2d');
let VW = 640, VH = 360;
function setView(w, h) {
  if (VW === w && VH === h && buf.width === w + 2) return; VW = w; VH = h;
  buf.width = w + 2; buf.height = h + 2; bx.imageSmoothingEnabled = false;
  if (typeof lightBuf !== 'undefined') { lightBuf.width = w + 2; lightBuf.height = h + 2; }
}
buf.width = 642; buf.height = 362; bx.imageSmoothingEnabled = false;

// ---------------- Utilidades ----------------
const clamp = (v, a, b) => v < a ? a : v > b ? b : v;
const lerp = (a, b, t) => a + (b - a) * t;
const approach = (v, t, d) => v < t ? Math.min(v + d, t) : Math.max(v - d, t);
const rnd = (a, b) => a + Math.random() * (b - a);
const overlap = (a, b) => a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
function seeded(s) { let v = s % 2147483647; if (v <= 0) v += 2147483646; return () => { v = v * 16807 % 2147483647; return (v - 1) / 2147483646; }; }
const UIF = '"Exo2","Segoe UI",Roboto,sans-serif', LOGOF = '"Orbitron","Exo2",sans-serif', PIXF = '"UI",monospace';
function txt(t, x, y, size, fill, stroke, lw, align, fnt, wt) {
  ctx.font = (wt || (fnt === LOGOF ? 900 : 700)) + ' ' + size + 'px ' + (fnt || UIF); ctx.textAlign = align || 'center'; ctx.textBaseline = 'middle';
  if (stroke) { ctx.lineJoin = 'round'; ctx.lineWidth = lw || Math.max(3, size * 0.22); ctx.strokeStyle = stroke; ctx.strokeText(t, x, y); }
  ctx.fillStyle = fill; ctx.fillText(t, x, y);
}
function mkCanvas(w, h) { const c = document.createElement('canvas'); c.width = Math.max(1, w | 0); c.height = Math.max(1, h | 0); const x = c.getContext('2d'); x.imageSmoothingEnabled = false; return [c, x]; }
function wrapText(t, maxW, size) {
  ctx.font = '500 ' + size + 'px ' + UIF; const words = t.split(' '), lines = []; let cur = '';
  for (const w of words) { const n = cur ? cur + ' ' + w : w; if (ctx.measureText(n).width > maxW && cur) { lines.push(cur); cur = w; } else cur = n; }
  if (cur) lines.push(cur); return lines;
}

// ---------------- Recursos ----------------
const SPR = {}, FLIP = {}, WHITE = {};
let loadedN = 0, totalN = 0, ready = false, fontsReady = false;
function loadAssets() {
  if (typeof IMG2 !== 'undefined') { Object.assign(IMG, IMG2); Object.assign(META, META2); }
  if (typeof IMG3 !== 'undefined') { Object.assign(IMG, IMG3); Object.assign(META, META3); }
  if (typeof IMG4 !== 'undefined') { Object.assign(IMG, IMG4); Object.assign(META, META4); }
  if (typeof IMG5 !== 'undefined') { Object.assign(IMG, IMG5); Object.assign(META, META5); }
  if (typeof IMG6 !== 'undefined') { Object.assign(IMG, IMG6); Object.assign(META, META6); }
  if (typeof IMG7 !== 'undefined') { Object.assign(IMG, IMG7); Object.assign(META, META7); }
  if (typeof IMG8 !== 'undefined') { Object.assign(IMG, IMG8); Object.assign(META, META8); }
  if (typeof IMG9 !== 'undefined') { Object.assign(IMG, IMG9); Object.assign(META, META9); }
  if (typeof IMG10 !== 'undefined') { Object.assign(IMG, IMG10); Object.assign(META, META10); }
  if (typeof IMG11 !== 'undefined') { Object.assign(IMG, IMG11); Object.assign(META, META11); }
  const ks = Object.keys(IMG); totalN = ks.length + 1;
  for (const k of ks) {
    const im = new Image();
    im.onload = im.onerror = () => { loadedN++; if (loadedN === totalN) ready = true; };
    im.src = IMG[k]; SPR[k] = im; if (META[k] && META[k].d) applyDensity(k);
  }
  const done = () => { loadedN++; fontsReady = true; if (loadedN === totalN) ready = true; };
  try {
    const f1 = new FontFace('UI', 'url(' + FONTS.ui + ')'), f2 = new FontFace('LOGO', 'url(' + FONTS.logo + ')');
    const f3 = new FontFace('Exo2', 'url(' + FONTS2.exo + ')', { weight: '100 900' }), f4 = new FontFace('Orbitron', 'url(' + FONTS2.orb + ')', { weight: '400 900' });
    Promise.all([f1.load(), f2.load(), f3.load(), f4.load()]).then(fs => { fs.forEach(f => document.fonts.add(f)); done(); }).catch(done);
  } catch (e) { done(); }
}
function meta(k) { return META[k] || { fw: SPR[k].width, fh: SPR[k].height, n: 1, ax: SPR[k].width / 2, ay: SPR[k].height }; }
function flipped(k) {
  if (FLIP[k]) return FLIP[k];
  const im = SPR[k], m = meta(k), [c, x] = dmk(im);
  for (let i = 0; i < m.n; i++) { x.save(); x.translate((i + 1) * m.fw, 0); x.scale(-1, 1); x.drawImage(im, i * m.fw, 0, m.fw, m.fh, 0, 0, m.fw, m.fh); x.restore(); }
  return (FLIP[k] = c);
}
function whiteOf(k, flip) {
  const id = k + (flip ? '|f' : '');
  if (WHITE[id]) return WHITE[id];
  const src = flip ? flipped(k) : SPR[k], [c, x] = dmk(src);
  x.drawImage(src, 0, 0); x.globalCompositeOperation = 'source-in'; x.fillStyle = '#fff'; x.fillRect(0, 0, c.width, c.height);
  return (WHITE[id] = c);
}
const TINT = {};
function tintOf(k, col, a) {
  const id = k + col + a; if (TINT[id]) return TINT[id];
  const src = SPR[k], [c, x] = dmk(src);
  x.drawImage(src, 0, 0); x.globalCompositeOperation = 'source-atop'; x.globalAlpha = a; x.fillStyle = col; x.fillRect(0, 0, c.width, c.height);
  const img = new Image(); return (TINT[id] = c);
}
function spr(k, frame, x, y, flip, scale, white, alpha) {
  const m = meta(k), s = scale || 1, n = m.n || 1, f = ((frame % n) + n) % n;
  const src = white ? whiteOf(k, flip) : flip ? flipped(k) : SPR[k];
  const fi = flip ? n - 1 - f : f, ax = flip ? m.fw - m.ax : m.ax;
  if (alpha !== undefined) bx.globalAlpha = alpha;
  bx.drawImage(src, fi * m.fw, 0, m.fw, m.fh, Math.round(x - ax * s), Math.round(y - m.ay * s), Math.round(m.fw * s), Math.round(m.fh * s));
  if (alpha !== undefined) bx.globalAlpha = 1;
}
const GLOW = {};
function glowSpr(color) {
  if (GLOW[color]) return GLOW[color];
  const [c, x] = mkCanvas(64, 64), g = x.createRadialGradient(32, 32, 0, 32, 32, 32);
  g.addColorStop(0, color); g.addColorStop(1, 'rgba(0,0,0,0)'); x.fillStyle = g; x.fillRect(0, 0, 64, 64);
  return (GLOW[color] = c);
}
function glowAt(x, y, r, color, a) {
  if (r <= 0) return;
  bx.globalCompositeOperation = 'lighter'; bx.globalAlpha = a === undefined ? 1 : clamp(a, 0, 1);
  bx.drawImage(glowSpr(color), Math.round(x - r), Math.round(y - r), Math.round(r * 2), Math.round(r * 2));
  bx.globalAlpha = 1; bx.globalCompositeOperation = 'source-over';
  if (typeof lightAt === 'function') lightAt(x, y, r * 2.2, color, (a === undefined ? 1 : a) * 0.5);
}

// ---------------- Audio ----------------
let AC = null, master = null;
const BUF = {};
let musicOn = true, curMusic = null, curMusicId = null, wantMusic = 'menu';
try { musicOn = localStorage.getItem('chronos_music') !== '0'; } catch (e) {}
const MUSIC = {};
function initAudio() {
  if (AC) { if (AC.state === 'suspended') AC.resume(); if (curMusic && musicOn && curMusic.paused) curMusic.play().catch(() => {}); else if (!curMusic) playMusic(wantMusic); return; }
  try {
    AC = new (window.AudioContext || window.webkitAudioContext)();
    master = AC.createGain(); master.gain.value = 0.85 * OPT.sfx; master.connect(AC.destination);
    for (const k in SND) {
      const bin = atob(SND[k].split(',')[1]), u = new Uint8Array(bin.length);
      for (let i = 0; i < bin.length; i++) u[i] = bin.charCodeAt(i);
      AC.decodeAudioData(u.buffer, b => { BUF[k] = b; }, () => {});
    }
  } catch (e) { AC = null; }
  playMusic(wantMusic);
}
const lastPlay = {};
function sfx(k, vol, rate) {
  if (!AC || !BUF[k]) return;
  const now = AC.currentTime;
  if (lastPlay[k] && now - lastPlay[k] < 0.045) return;
  lastPlay[k] = now;
  try {
    const s = AC.createBufferSource(); s.buffer = BUF[k];
    s.playbackRate.value = (rate || 1) * (k.startsWith('v_') ? 1 : rnd(0.95, 1.05)) * (typeof slowT !== 'undefined' && slowT > 0 && !k.startsWith('v_') ? 0.8 : 1);
    const g = AC.createGain(); g.gain.value = vol === undefined ? 1 : vol;
    s.connect(g); g.connect(master); s.start();
  } catch (e) {}
}
let musicVol = 0.42;
function playMusic(id) {
  wantMusic = id;
  if (curMusicId === id && curMusic && !curMusic.paused) return;
  if (curMusic) curMusic.pause();
  curMusic = null; curMusicId = null;
  if (!id || !musicOn || !AC) return;
  let a = MUSIC[id];
  if (!a) { a = new Audio(MUS[id]); a.loop = true; MUSIC[id] = a; }
  a.volume = (id === 'menu' ? 0.5 : musicVol) * OPT.mus; a.currentTime = 0; a.playbackRate = 1;
  a.play().catch(() => {});
  curMusic = a; curMusicId = id;
}
function toggleMusic() {
  musicOn = !musicOn;
  try { localStorage.setItem('chronos_music', musicOn ? '1' : '0'); } catch (e) {}
  if (!musicOn && curMusic) { curMusic.pause(); curMusic = null; curMusicId = null; } else playMusic(wantMusic);
}
document.addEventListener('visibilitychange', () => { if (document.hidden && curMusic) curMusic.pause(); else if (!document.hidden && curMusic && musicOn) curMusic.play().catch(() => {}); });

// ---------------- Entrada ----------------
const keys = {};
window.addEventListener('keydown', e => {
  initAudio(); keys[e.code] = true;
  if (['Space', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Tab'].includes(e.code)) e.preventDefault();
  if (!e.repeat) onKey(e.code);
});
window.addEventListener('keyup', e => { keys[e.code] = false; });
window.addEventListener('blur', () => { for (const k in keys) keys[k] = false; if (state === 'playing') pauseGame(); });
// Botones táctiles: [x desde la izquierda o desde la derecha (r), y, tamaño]
const TB = { left: [24, 414, 98, 0], right: [136, 414, 98, 0], dash: [264, 440, 80, 1], attack: [168, 440, 80, 1], jump: [26, 404, 112, 1], shift: [222, 350, 72, 1], time: [134, 340, 72, 1], eco: [310, 360, 66, 1] };
const TL = { left: '◀', right: '▶', dash: 'DASH', attack: 'ESPADA', jump: 'SALTO', shift: 'SHIFT', time: 'TIEMPO', eco: 'ECO' };
const touchBtn = {};
const pauseBtn = { x: 904, y: 14, w: 42, h: 42 };
const musicBtn = { x: 904, y: 14, w: 42, h: 42 };
const optBtn = { x: 852, y: 14, w: 42, h: 42 };
function layoutTouch() {
  for (const k in TB) {
    const [a, y, s0, right] = TB[k], s = s0 * OPT.size, cx0 = right ? W - a - s0 / 2 : a + s0 / 2, cy0 = y + s0 / 2;
    const cy = Math.min(cy0, H - s / 2 - 8);
    touchBtn[k] = { x: cx0 - s / 2, y: cy - s / 2, w: s, h: s, label: TL[k] };
  }
  pauseBtn.x = W - 56; musicBtn.x = W - 56; optBtn.x = W - 106;
}
const ptrs = new Map();
let touchMode = ('ontouchstart' in window) || (navigator.maxTouchPoints || 0) > 0;
let mouseAttack = false;
const inRect = (pt, r) => pt.x >= r.x && pt.x <= r.x + r.w && pt.y >= r.y && pt.y <= r.y + r.h;
function toLogical(e) { const r = cv.getBoundingClientRect(); return { x: (e.clientX - r.left) * W / r.width, y: (e.clientY - r.top) * H / r.height }; }
function inAnyTouchBtn(pt) { for (const k in touchBtn) { if (OPT.ctrl === 'joystick' && (k === 'left' || k === 'right')) continue; if (k === 'eco' && !(typeof ecoAvailable === 'function' && ecoAvailable())) continue; if (inRect(pt, touchBtn[k])) return true; } return false; }
// Joystick flotante (opcional): aparece donde apoyas el pulgar izquierdo
const stick = { id: null, bx: 0, by: 0, x: 0, y: 0 };
function stickDir() { if (stick.id === null) return [0, 0]; const dx = stick.x - stick.bx, dy = stick.y - stick.by; return [Math.abs(dx) > 16 ? Math.sign(dx) : 0, dy > 34 ? 1 : 0]; }
function touchDown(name) {
  const b = touchBtn[name];
  if (OPT.ctrl === 'joystick' && (name === 'left' || name === 'right')) { const d = stickDir()[0]; return name === 'left' ? d < 0 : d > 0; }
  for (const pt of ptrs.values()) {
    if (pt.stick) continue;
    if (name === 'left' && pt.x < 129 && pt.y > 330) return true;
    if (name === 'right' && pt.x >= 129 && pt.x < 300 && pt.y > 330) return true;
    if (name !== 'left' && name !== 'right') { const cx = b.x + b.w / 2, cy = b.y + b.h / 2; if (Math.hypot(pt.x - cx, pt.y - cy) < b.w * 0.6) return true; }
  }
  return false;
}
cv.addEventListener('pointerdown', e => {
  initAudio(); e.preventDefault();
  try { cv.setPointerCapture(e.pointerId); } catch (er) {}
  if (e.pointerType === 'touch') touchMode = true;
  const pt = toLogical(e), rec = { x: pt.x, y: pt.y };
  if (OPT.ctrl === 'joystick' && state === 'playing' && e.pointerType === 'touch' && pt.x < W * 0.42 && pt.y > 120 && stick.id === null && !inAnyTouchBtn(pt)) { stick.id = e.pointerId; stick.bx = stick.x = pt.x; stick.by = stick.y = pt.y; rec.stick = true; }
  ptrs.set(e.pointerId, rec);
  handleTap(pt.x, pt.y, e.pointerType);
});
cv.addEventListener('pointermove', e => { const o = ptrs.get(e.pointerId); if (o) { const pt = toLogical(e); o.x = pt.x; o.y = pt.y; if (o.stick) { stick.x = pt.x; stick.y = pt.y; const dx = stick.x - stick.bx, dy = stick.y - stick.by, d = Math.hypot(dx, dy); if (d > 60) { stick.bx += dx * (1 - 60 / d); stick.by += dy * (1 - 60 / d); } } } });
function ptrUp(e) { const o = ptrs.get(e.pointerId); if (o && o.stick) stick.id = null; ptrs.delete(e.pointerId); if (e.pointerType === 'mouse') mouseAttack = false; }
cv.addEventListener('pointerup', ptrUp); cv.addEventListener('pointercancel', ptrUp);
cv.addEventListener('contextmenu', e => e.preventDefault());
const ACTS = ['left', 'right', 'down', 'jump', 'dash', 'attack', 'shift', 'time', 'eco'];
const act = {}, prevAct = {}, pressed = {};
for (const k of ACTS) { act[k] = prevAct[k] = pressed[k] = false; }
function readInput() {
  for (const k of ACTS) prevAct[k] = act[k];
  const t = touchMode && state === 'playing';
  act.left = !!(keys.ArrowLeft || keys.KeyA || (t && touchDown('left')));
  act.right = !!(keys.ArrowRight || keys.KeyD || (t && touchDown('right')));
  act.down = !!(keys.ArrowDown || keys.KeyS || (t && OPT.ctrl === 'joystick' && stickDir()[1] > 0));
  act.jump = !!(keys.Space || keys.KeyW || keys.ArrowUp || (t && touchDown('jump')));
  act.dash = !!(keys.ShiftLeft || keys.ShiftRight || keys.KeyK || (t && touchDown('dash')));
  act.attack = !!(keys.KeyZ || keys.KeyJ || mouseAttack || (t && touchDown('attack')));
  act.shift = !!(keys.KeyX || keys.KeyL || (t && touchDown('shift')));
  act.time = !!(keys.KeyC || keys.KeyV || (t && touchDown('time')));
  act.eco = !!(keys.KeyE || keys.KeyQ || (t && ecoAvailable() && touchDown('eco')));
  for (const k of ACTS) pressed[k] = act[k] && !prevAct[k];
}
