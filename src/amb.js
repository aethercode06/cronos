// =====================================================================
//  AMBIENTE SONORO PROCEDURAL POR MUNDO
// =====================================================================
let ambNodes = [], ambBus = null, ambWorld = -1, noiseB = null;
function noiseBuf() {
  if (noiseB) return noiseB;
  noiseB = AC.createBuffer(1, AC.sampleRate * 2, AC.sampleRate);
  const d = noiseB.getChannelData(0); let b = 0;
  for (let i = 0; i < d.length; i++) { const w = Math.random() * 2 - 1; b = (b + 0.02 * w) / 1.02; d[i] = w * 0.5 + b * 3; }
  return noiseB;
}
function ambLayer(type, freq, q, gain, lfo) {
  const src = AC.createBufferSource(); src.buffer = noiseBuf(); src.loop = true;
  const f = AC.createBiquadFilter(); f.type = type; f.frequency.value = freq; f.Q.value = q;
  const g = AC.createGain(); g.gain.value = gain;
  src.connect(f); f.connect(g); g.connect(ambBus); src.start();
  ambNodes.push(src);
  if (lfo) { const o = AC.createOscillator(), og = AC.createGain(); o.frequency.value = lfo[0]; og.gain.value = lfo[1]; o.connect(og); og.connect(f.frequency); o.start(); ambNodes.push(o); }
}
function ambTone(freq, gain) { const o = AC.createOscillator(), g = AC.createGain(); o.type = 'sine'; o.frequency.value = freq; g.gain.value = gain; o.connect(g); g.connect(ambBus); o.start(); ambNodes.push(o); }
function startAmbience(wi) {
  wi = ({ 14: 5, 15: 4, 16: 1, 17: 9 })[wi] ?? wi;
  if (!AC) { ambWorld = -2 - wi; return; }
  stopAmbience(); ambWorld = wi;
  ambBus = AC.createGain(); ambBus.gain.value = 0; ambBus.connect(master);
  ambBus.gain.setTargetAtTime(0.55, AC.currentTime, 1.2);
  if (wi === 0) { ambLayer('bandpass', 500, 0.7, 0.05, [0.08, 180]); }
  else if (wi === 1) { ambLayer('bandpass', 380, 1.2, 0.08, [0.05, 240]); ambLayer('lowpass', 120, 0.7, 0.12); ambTone(73, 0.012); }
  else if (wi === 2) { ambLayer('lowpass', 110, 0.8, 0.4); ambLayer('bandpass', 900, 1, 0.02, [0.2, 300]); }
  else if (wi === 3) { ambLayer('bandpass', 420, 0.9, 0.07, [0.06, 220]); }
  else if (wi === 4) { ambLayer('bandpass', 350, 1.4, 0.09, [0.05, 260]); ambLayer('lowpass', 90, 0.7, 0.15); }
  else if (wi === 5) { ambLayer('bandpass', 700, 3, 0.07, [0.09, 400]); ambLayer('highpass', 3000, 0.5, 0.015); }
  else if (wi === 6) { ambLayer('lowpass', 95, 0.8, 0.45); ambLayer('bandpass', 300, 1, 0.03, [0.1, 120]); }
  else if (wi === 8) { ambLayer('lowpass', 260, 0.9, 0.22, [0.07, 90]); ambLayer('bandpass', 1400, 3, 0.012, [0.2, 600]); }
  else if (wi === 9) { ambLayer('bandpass', 900, 0.8, 0.07, [0.05, 500]); ambLayer('highpass', 4000, 0.4, 0.02); }
  else if (wi === 10) { ambLayer('bandpass', 600, 0.7, 0.06, [0.04, 300]); ambTone(392, 0.004); ambTone(587, 0.003); }
  else { ambTone(220, 0.008); ambTone(329.6, 0.006); ambLayer('bandpass', 1200, 4, 0.01, [0.03, 500]); }
}
function stopAmbience() {
  for (const n of ambNodes) { try { n.stop(); } catch (e) {} }
  ambNodes = []; if (ambBus) { try { ambBus.disconnect(); } catch (e) {} } ambBus = null; ambWorld = -1;
}
function ambGain(on) { if (ambBus && AC) ambBus.gain.setTargetAtTime(on ? 0.55 : 0, AC.currentTime, 0.2); }
function blip(f0, f1, dur, gain, type, delay) {
  if (!AC || !ambBus) return;
  const t = AC.currentTime + (delay || 0), o = AC.createOscillator(), g = AC.createGain();
  o.type = type || 'sine'; o.frequency.setValueAtTime(f0, t); o.frequency.exponentialRampToValueAtTime(f1, t + dur);
  g.gain.setValueAtTime(0.0001, t); g.gain.exponentialRampToValueAtTime(gain, t + dur * 0.2); g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
  o.connect(g); g.connect(ambBus); o.start(t); o.stop(t + dur + 0.05);
}
function crackle(gain) {
  if (!AC || !ambBus) return;
  const s = AC.createBufferSource(), g = AC.createGain(), f = AC.createBiquadFilter(); s.buffer = noiseBuf(); f.type = 'highpass'; f.frequency.value = 1500;
  const t = AC.currentTime; g.gain.setValueAtTime(gain, t); g.gain.exponentialRampToValueAtTime(0.0001, t + 0.04);
  s.connect(f); f.connect(g); g.connect(ambBus); s.start(t, Math.random()); s.stop(t + 0.05);
}
let tickT = 0;
function ambTick(dt) {
  if (!AC) return;
  if (ambWorld <= -2) startAmbience(-2 - ambWorld);
  if (!ambBus || state !== 'playing') return;
  const wi = ambWorld;
  if ((wi === 0 || wi === 3) && Math.random() < dt * (wi === 0 ? 0.6 : 0.25)) { const f = rnd(1800, 3200), n = 2 + Math.floor(Math.random() * 3); for (let i = 0; i < n; i++) blip(f, f * rnd(1.2, 1.6), 0.07, 0.03, 'sine', i * 0.11); }
  if (wi === 3 && Math.random() < dt * 2) blip(4200, 4300, 0.03, 0.006, 'square');
  if ((wi === 2 || wi === 6) && Math.random() < dt * 6) crackle(rnd(0.02, 0.08));
  if (wi === 4 && Math.random() < dt * 0.08) { blip(420, 380, 0.35, 0.05); blip(380, 340, 0.5, 0.05, 'sine', 0.45); }
  if (wi === 5 && Math.random() < dt * 0.15) blip(rnd(2500, 3500), rnd(1800, 2400), 0.4, 0.008, 'triangle');
  if (wi === 1 && Math.random() < dt * 0.03) { blip(196, 194, 2.2, 0.02, 'sine'); blip(392, 390, 1.6, 0.008, 'sine'); }
  if (wi === 8 && Math.random() < dt * 1.2) blip(rnd(300, 700), rnd(900, 1400), 0.12, 0.02, 'sine');
  if (wi === 10 && Math.random() < dt * 0.3) blip(rnd(1200, 2200), rnd(2400, 3000), 0.5, 0.006, 'triangle');
  if (wi === 7 || wi === 11) { tickT -= dt; if (tickT <= 0) { tickT = 0.5; blip(slowT > 0 ? 900 : 1500, 1400, 0.03, 0.03, 'square'); } }
}
