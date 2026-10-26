// =====================================================================
//  FLUIDEZ (v2.4)
//  1) Ritmo de fotogramas estable: el reloj del juego avanza en pasos
//     exactos de la frecuencia de la pantalla (quita los tirones de
//     Android) y, en pantallas de 120 Hz que no llegan, fija 60 estables.
//  2) Calidad automática más lista: detecta teléfonos modestos al
//     arrancar, reacciona antes y recupera calidad si sobra potencia.
// =====================================================================
const PACE = { vt: 0, lastNow: 0, T: 1 / 60, iv: [], lock: false, odd: false, miss: 0, n: 0, evalT: 0, tested: false, upT: 0, ups: 0 };
// teléfonos modestos: empezar con efectos medios y resolución normal
const LOWEND = (navigator.hardwareConcurrency || 8) <= 4 || (navigator.deviceMemory || 8) <= 3;
let glScale = 1;
function applyGLScale(s) {
  glScale = s; const g = document.getElementById('gl'); if (!g) return;
  const w = Math.round(W * RES * s), h = Math.round(H * RES * s); if (g.width !== w || g.height !== h) { g.width = w; g.height = h; }
}
const _resizeP = resize; resize = function () { _resizeP(); if (glScale !== 1) applyGLScale(glScale); };
// el juego ya arrancó el WebGL al cargar: aplicar ahora el modo para teléfonos modestos
if (LOWEND) { try { if (QR > 2) setQR(2); } catch (e) {} if (glOK) { glQ = 1; applyGLScale(0.8); } }
// el muestreo original solo baja la calidad; aquí además se puede recuperar
const _perfSampleP = perfSample;
perfSample = function (dt) {
  const q0 = glQ; _perfSampleP(dt);
  if (glQ < q0 && glQ === 1) applyGLScale(0.8);
  if (!glOK || state !== 'playing') return;
  PACE.upT += dt; PACE.n++; PACE.miss += dt;
  if (PACE.upT > 6) {
    const avg = PACE.miss / PACE.n; PACE.upT = PACE.miss = PACE.n = 0;
    if (glQ === 1 && !LOWEND && PACE.ups < 1 && avg < PACE.T * 1.08 + 0.001) { glQ = 2; applyGLScale(1); PACE.ups++; }
  }
};
const _frameP = frame;
frame = function (now) {
  // 60 Hz fijos en pantallas rápidas que no mantienen 120: se salta un aviso de cada dos
  if (PACE.lock) { PACE.odd = !PACE.odd; if (PACE.odd) { requestAnimationFrame(frame); return; } }
  if (!PACE.lastNow) { PACE.lastNow = now; PACE.vt = now; }
  let r = now - PACE.lastNow; PACE.lastNow = now;
  // estimar la frecuencia real de la pantalla (mediana de los intervalos)
  if (!PACE.lock && r > 4 && r < 40) { PACE.iv.push(r); if (PACE.iv.length > 90) PACE.iv.shift(); if (PACE.iv.length >= 30 && PACE.iv.length % 15 === 0) { const s = PACE.iv.slice().sort((a, b) => a - b), m = s[s.length >> 1]; PACE.T = m / 1000; } }
  // ajustar el intervalo a un múltiplo exacto del refresco si está cerca (quita el temblor)
  const base = PACE.T * 1000 * (PACE.lock ? 2 : 1), k = Math.max(1, Math.round(r / base));
  if (Math.abs(r - k * base) < base * 0.25 && k <= 4) r = k * base;
  PACE.vt += r;
  // en juego: si la pantalla va a más de 100 Hz y se pierden muchos fotogramas, fijar 60
  if (state === 'playing' && !PACE.tested && PACE.T < 0.0095) {
    PACE.evalT += r / 1000; if (r > base * 1.5) PACE.missF = (PACE.missF || 0) + 1; PACE.allF = (PACE.allF || 0) + 1;
    if (PACE.evalT > 2.5) { PACE.tested = true; if (PACE.missF / PACE.allF > 0.12) PACE.lock = true; }
  }
  _frameP(PACE.vt);
};
// cada fase vuelve a comprobar si aguanta la frecuencia alta
const _startStageP = startStage;
startStage = function (wi, act, fresh) { _startStageP(wi, act, fresh); PACE.tested = false; PACE.evalT = 0; PACE.missF = 0; PACE.allF = 0; PACE.lock = false; PACE.odd = false; };
