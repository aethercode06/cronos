// =====================================================================
//  MEZCLA DE SONIDO (v2.9)
//  Encima de la música sonaban sonidos generados por código que no
//  iban a su ritmo ni en su tono: zumbidos continuos, campanas, un
//  tic-tac de reloj cada medio segundo y música sintetizada guardada
//  desde la versión 2.2. Además, en algunos mundos la música compuesta
//  se reproducía más lenta (88-95 %) y se deformaba.
//  Ahora: una sola música limpia, ambiente solo de fondo (viento,
//  fuego, agua) y más bajo, sin notas que choquen con la música.
// =====================================================================
// la banda sonora compuesta pasa a ser la de todos (una sola vez); quien
// quiera la sintetizada puede volver a elegirla en Opciones
if (!OPT.mix29) { OPT.mix29 = 1; OPT.ost = 'clasica'; try { saveOpts(); } catch (e) {} }
// el ambiente ya no toca notas: sin zumbidos ni tonos fijos
ambTone = function () {};
// ambiente más bajo y sin sonidos con tono propio (campanas, tic-tac, destellos)
const AMB_VOL = 0.32;
const _startAmbienceM = startAmbience;
startAmbience = function (wi) {
  _startAmbienceM(wi);
  if (ambBus && AC) { ambBus.gain.cancelScheduledValues(AC.currentTime); ambBus.gain.setTargetAtTime(musicOn && OPT.mus > 0 ? AMB_VOL : 0.55, AC.currentTime, 1.2); }
};
ambGain = function (on) { if (ambBus && AC) ambBus.gain.setTargetAtTime(on ? (musicOn && OPT.mus > 0 ? AMB_VOL : 0.55) : 0, AC.currentTime, 0.2); };
ambTick = function (dt) {
  if (!AC) return;
  if (ambWorld <= -2) startAmbience(-2 - ambWorld);
  if (!ambBus || state !== 'playing') return;
  const wi = ambWorld;
  // solo sonidos de la naturaleza, cortos y suaves
  if ((wi === 0 || wi === 3) && Math.random() < dt * (wi === 0 ? 0.35 : 0.15)) { const f = rnd(2200, 3200), n = 2 + Math.floor(Math.random() * 2); for (let i = 0; i < n; i++) blip(f, f * rnd(1.2, 1.5), 0.06, 0.015, 'sine', i * 0.11); }
  if ((wi === 2 || wi === 6) && Math.random() < dt * 5) crackle(rnd(0.015, 0.05));
  if (wi === 8 && Math.random() < dt * 0.8) blip(rnd(300, 600), rnd(800, 1200), 0.1, 0.01, 'sine');
};
// la música compuesta siempre a su velocidad normal (los mundos tenían 0,88-0,95)
const _startStageM = startStage;
startStage = function (wi, act, fresh) { _startStageM(wi, act, fresh); if (curMusic && slowT <= 0) curMusic.playbackRate = 1; };
// nunca dos músicas a la vez: al cambiar de tema se paran todas las demás
const _playMusicM = playMusic;
playMusic = function (id) {
  _playMusicM(id);
  for (const k in MUSIC) { const a = MUSIC[k]; if (a && a !== curMusic && !a.paused) { try { a.pause(); } catch (e) {} } }
};
// el ralentizado del tiempo baja el tono de forma natural, sin deformar
const _applyMusicRate = () => { if (curMusic && 'preservesPitch' in curMusic) curMusic.preservesPitch = false; };
const _updateM = update;
update = function (dt) { _updateM(dt); if (curMusic && curMusic.playbackRate !== 1) _applyMusicRate(); };
