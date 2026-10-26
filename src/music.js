// =====================================================================
//  BANDA SONORA ORIGINAL DE AETHER CODE, COMPUESTA POR CÓDIGO
//  Cada mundo tiene su tema (tonalidad, tempo, instrumentos y melodía
//  propios). Se genera en el teléfono la primera vez que suena y se
//  guarda en memoria. Opciones > Banda sonora: Original / Clásica.
// =====================================================================
if (OPT.ost === undefined) OPT.ost = 'orig';
const SC = { aeolian: [0, 2, 3, 5, 7, 8, 10], dorian: [0, 2, 3, 5, 7, 9, 10], phrygian: [0, 1, 3, 5, 7, 8, 10], harm: [0, 2, 3, 5, 7, 8, 11], hijaz: [0, 1, 4, 5, 7, 8, 10], lydian: [0, 2, 4, 6, 7, 9, 11], ionian: [0, 2, 4, 5, 7, 9, 11], penta: [0, 3, 5, 7, 10, 12, 15] };
// tema por mundo: r = nota base (MIDI), s = escala, bpm, p/pB = grados de los acordes (8 compases), lead/arp/bass/drums = estilos
const SONGS = {
  g0: { r: 50, s: 'dorian', bpm: 112, p: [0, 3, 4, 0, 5, 3, 4, 4], pB: [5, 3, 0, 4, 5, 6, 4, 4], lead: 'flute', arp: 'marimba', bass: 'bounce', drums: 'jungle', pad: 'warm', seed: 11 },
  g1: { r: 48, s: 'harm', bpm: 92, p: [0, 5, 3, 4, 0, 5, 1, 4], pB: [5, 3, 0, 4, 5, 3, 4, 4], lead: 'violin', arp: 'harpsi', bass: 'pulse', drums: 'toll', pad: 'choir', seed: 23 },
  g2: { r: 52, s: 'phrygian', bpm: 124, p: [0, 1, 0, 6, 0, 1, 5, 6], pB: [3, 1, 0, 6, 3, 4, 1, 0], lead: 'brass', arp: 'saw', bass: 'drive', drums: 'war', pad: 'dark', seed: 37 },
  g3: { r: 45, s: 'aeolian', bpm: 96, p: [0, 5, 2, 6, 0, 5, 3, 4], pB: [3, 0, 5, 6, 3, 4, 6, 4], lead: 'flute', arp: 'harp', bass: 'soft', drums: 'soft', pad: 'warm', seed: 41 },
  g4: { r: 50, s: 'harm', bpm: 84, p: [0, 3, 4, 0, 5, 3, 1, 4], pB: [3, 0, 5, 4, 3, 1, 4, 4], lead: 'musicbox', arp: 'bell', bass: 'soft', drums: 'ghost', pad: 'choir', seed: 53 },
  g5: { r: 54, s: 'aeolian', bpm: 90, p: [0, 5, 3, 4, 0, 5, 6, 4], pB: [5, 6, 0, 4, 3, 5, 6, 4], lead: 'glass', arp: 'bell', bass: 'soft', drums: 'ice', pad: 'cold', seed: 67 },
  g6: { r: 48, s: 'hijaz', bpm: 132, p: [0, 1, 0, 6, 0, 1, 3, 1], pB: [3, 1, 0, 6, 5, 1, 0, 1], lead: 'brass', arp: 'saw', bass: 'drive', drums: 'war', pad: 'dark', seed: 71 },
  g7: { r: 55, s: 'lydian', bpm: 108, p: [0, 1, 4, 0, 5, 1, 3, 4], pB: [3, 4, 0, 5, 3, 1, 4, 4], lead: 'violin', arp: 'clock', bass: 'pulse', drums: 'clock', pad: 'warm', seed: 83 },
  g8: { r: 51, s: 'dorian', bpm: 88, p: [0, 3, 0, 4, 5, 3, 6, 4], pB: [3, 4, 5, 0, 3, 6, 4, 4], lead: 'glass', arp: 'water', bass: 'soft', drums: 'soft', pad: 'cold', seed: 97 },
  g9: { r: 50, s: 'hijaz', bpm: 104, p: [0, 1, 0, 6, 3, 1, 0, 1], pB: [3, 4, 1, 0, 6, 1, 0, 1], lead: 'oud', arp: 'pluck', bass: 'bounce', drums: 'darbuka', pad: 'warm', seed: 101 },
  g10: { r: 53, s: 'lydian', bpm: 100, p: [0, 1, 4, 5, 0, 1, 3, 4], pB: [5, 3, 1, 4, 5, 3, 4, 4], lead: 'glass', arp: 'harp', bass: 'soft', drums: 'none', pad: 'choir', seed: 113 },
  g11: { r: 47, s: 'aeolian', bpm: 120, p: [0, 5, 6, 4, 0, 5, 3, 4], pB: [5, 6, 0, 4, 3, 1, 4, 4], lead: 'brass', arp: 'saw', bass: 'drive', drums: 'epic', pad: 'dark', seed: 127 },
  g12: { r: 43, s: 'harm', bpm: 92, p: [0, 3, 0, 4, 5, 3, 1, 4], pB: [3, 0, 4, 0, 5, 1, 4, 4], lead: 'reed', arp: 'pluck', bass: 'wonky', drums: 'ghost', pad: 'dark', seed: 131 },
  g13: { r: 48, s: 'aeolian', bpm: 80, p: [0, 5, 3, 4, 0, 5, 6, 4], pB: [3, 0, 5, 4, 3, 6, 4, 4], lead: 'brass', arp: 'harpsi', bass: 'pulse', drums: 'march', pad: 'choir', seed: 139 },
  g14: { r: 45, s: 'penta', bpm: 110, p: [0, 3, 4, 0, 0, 3, 2, 4], pB: [3, 4, 0, 2, 3, 4, 2, 4], lead: 'oud', arp: 'anvil', bass: 'bounce', drums: 'mine', pad: 'cold', seed: 149 },
  g15: { r: 52, s: 'aeolian', bpm: 86, p: [0, 5, 3, 6, 0, 5, 3, 4], pB: [5, 3, 0, 6, 5, 6, 4, 4], lead: 'violin', arp: 'xylo', bass: 'soft', drums: 'bones', pad: 'choir', seed: 157 },
  g16: { r: 46, s: 'dorian', bpm: 96, p: [0, 3, 6, 4, 0, 3, 1, 4], pB: [3, 6, 0, 4, 5, 3, 4, 4], lead: 'musicbox', arp: 'harpsi', bass: 'pulse', drums: 'soft', pad: 'warm', seed: 163 },
  g17: { r: 50, s: 'aeolian', bpm: 128, p: [0, 5, 6, 4, 0, 5, 3, 6], pB: [5, 6, 0, 4, 3, 6, 4, 4], lead: 'violin', arp: 'saw', bass: 'drive', drums: 'epic', pad: 'dark', seed: 173 },
  gmenu: { r: 45, s: 'aeolian', bpm: 88, p: [0, 5, 2, 6, 0, 5, 3, 4], pB: [5, 3, 0, 6, 5, 6, 4, 4], lead: 'violin', arp: 'harp', bass: 'soft', drums: 'soft', pad: 'choir', seed: 7 },
  gboss: { r: 52, s: 'harm', bpm: 144, p: [0, 0, 5, 4, 0, 0, 1, 4], pB: [5, 3, 1, 4, 5, 6, 4, 4], lead: 'brass', arp: 'saw', bass: 'drive', drums: 'boss', pad: 'dark', seed: 211 },
  gfinal: { r: 49, s: 'phrygian', bpm: 152, p: [0, 1, 0, 6, 0, 1, 5, 4], pB: [3, 1, 0, 6, 5, 1, 6, 4], lead: 'brass', arp: 'saw', bass: 'drive', drums: 'boss', pad: 'choir', seed: 223 }
};
const GEN = {}, GEN_BUSY = {}, GEN_ORDER = [];
const mtof = m => 440 * Math.pow(2, (m - 69) / 12);
// sintetizador propio: genera las muestras directamente (rápido) dentro de un Worker para no frenar el juego
function SYNTH(S, SC, seedv) {
  const SR = 22050, spb = 60 / S.bpm, bar = spb * 4, bars = 16, L = bar * bars, T = 2.6, N = Math.ceil((L + T) * SR), NL = Math.floor(L * SR);
  const DRY = new Float32Array(N), REV = new Float32Array(N), DEL = new Float32Array(N);
  let sv = seedv % 2147483647; if (sv <= 0) sv += 2147483646; const r = () => { sv = sv * 16807 % 2147483647; return (sv - 1) / 2147483646; };
  const clamp = (v, a, b) => v < a ? a : v > b ? b : v, mtof = m => 440 * Math.pow(2, (m - 69) / 12), scale = SC[S.s];
  const deg = (d, oct) => { const n = scale.length, o = Math.floor(d / n), i = ((d % n) + n) % n; return S.r + scale[i] + 12 * (o + (oct || 0)); };
  const TAU = Math.PI * 2;
  function biq(type, f, q) {
    const w = TAU * Math.min(f, SR * .45) / SR, cs = Math.cos(w), al = Math.sin(w) / (2 * (q || .707)); let b0, b1, b2, a0, a1, a2;
    if (type === 'lowpass') { b0 = (1 - cs) / 2; b1 = 1 - cs; b2 = b0; } else if (type === 'highpass') { b0 = (1 + cs) / 2; b1 = -(1 + cs); b2 = b0; } else { b0 = al; b1 = 0; b2 = -al; }
    a0 = 1 + al; a1 = -2 * cs; a2 = 1 - al; return [b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0];
  }
  function tone(t, dur, f, o) {
    o = o || {};
    const a = o.a || .005, rl = o.rl || .08, v = o.v || .2, dec = o.dec || 0, svl = Math.max(.0005, v * (o.sus || .001));
    const hold = dec ? Math.max(dur, a + dec) : Math.max(a, dur), end = hold + rl;
    const i0 = Math.floor(t * SR), n = Math.floor(end * SR); if (i0 >= N) return;
    const waves = o.w || ['triangle'], nw = waves.length, ph = new Float64Array(nw), mul = [], mix = [], dt = [];
    for (let k = 0; k < nw; k++) { mul[k] = o.mul && o.mul[k] ? o.mul[k] : 1; mix[k] = o.mix && o.mix[k] !== undefined ? o.mix[k] : 1 / nw; dt[k] = Math.pow(2, ((k - (nw - 1) / 2) * (o.det || 0)) / 1200); ph[k] = r(); }
    let co = o.lp ? biq('lowpass', o.lp, o.q) : o.hp ? biq('highpass', o.hp, .7) : null, x1 = 0, x2 = 0, y1 = 0, y2 = 0;
    const dry = o.dry === undefined ? 1 : o.dry, rv = o.rev || 0, de = o.del || 0, relStart = hold * SR;
    let env = 0, relFrom = 0;
    const lnDec = dec ? Math.log(svl / v) / (dec * SR) : 0, lnRel = Math.log(.0005) / (rl * SR);
    for (let j = 0; j < n && i0 + j < N; j++) {
      const tt = j / SR;
      if (j < a * SR) env = v * j / (a * SR);
      else if (j < relStart) env = dec ? (j < (a + dec) * SR ? v * Math.exp(lnDec * (j - a * SR)) : svl) : v;
      else { if (relFrom === 0) relFrom = env || .0001; env = relFrom * Math.exp(lnRel * (j - relStart)); }
      let fr = f; if (o.slide) fr *= Math.pow(o.slide, Math.min(tt, o.slideT || .1) / (o.slideT || .1));
      if (o.vib) fr *= 1 + Math.sin(TAU * 5.2 * tt) * o.vib * Math.min(1, tt / Math.min(dur || .35, .35));
      let x = 0;
      for (let k = 0; k < nw; k++) {
        ph[k] += fr * mul[k] * dt[k] / SR; ph[k] -= Math.floor(ph[k]); const p = ph[k], w = waves[k];
        x += mix[k] * (w === 'sine' ? Math.sin(TAU * p) : w === 'triangle' ? 4 * Math.abs(p - .5) - 1 : w === 'sawtooth' ? 2 * p - 1 : (p < .5 ? 1 : -1));
      }
      if (co) {
        if (o.lpEnv && (j & 31) === 0) co = biq('lowpass', o.lp * Math.pow(o.lpEnv, Math.min(1, tt / (o.lpT || .3))), o.q);
        const y = co[0] * x + co[1] * x1 + co[2] * x2 - co[3] * y1 - co[4] * y2; x2 = x1; x1 = x; y2 = y1; y1 = y; x = y;
      }
      x *= env; const i = i0 + j; DRY[i] += x * dry; if (rv) REV[i] += x * rv; if (de) DEL[i] += x * de;
    }
  }
  function hit(t, o) {
    const i0 = Math.floor(t * SR), d = o.d || .05, n = Math.floor((d + .02) * SR), co = biq(o.type || 'highpass', o.f || 7000, o.q || .8), v = o.v || .1, ln = Math.log(.0005 / v) / (d * SR), rv = o.rev || 0;
    let x1 = 0, x2 = 0, y1 = 0, y2 = 0;
    for (let j = 0; j < n && i0 + j < N; j++) { const x = Math.random() * 2 - 1, y = co[0] * x + co[1] * x1 + co[2] * x2 - co[3] * y1 - co[4] * y2; x2 = x1; x1 = x; y2 = y1; y1 = y; const s = y * v * Math.exp(ln * j); DRY[i0 + j] += s; if (rv) REV[i0 + j] += s * rv; }
  }
  const kick = (t, v) => tone(t, .02, 120, { w: ['sine'], v: (v || .55) * 1.3, slide: .3, slideT: .12, dec: .28, rl: .05 });
  const snare = (t, v) => { hit(t, { type: 'bandpass', f: 1800, q: .6, v: (v || .3) * 1.4, d: .16, rev: .25 }); tone(t, .02, 190, { w: ['triangle'], v: (v || .3) * .5, slide: .6, dec: .1, rl: .03 }); };
  const hat = (t, v, open) => hit(t, { f: 8000, v: (v || .05) * 1.3, d: open ? .14 : .035 });
  const tom = (t, f, v) => tone(t, .02, f, { w: ['sine'], v: v || .35, slide: .55, slideT: .2, dec: .3, rl: .05, rev: .15 });
  const INST = {
    flute: (t, d, f) => tone(t, d, f, { w: ['sine', 'triangle'], mix: [.7, .3], a: .04, v: .16, vib: .006, rl: .2, rev: .35, del: .25 }),
    violin: (t, d, f) => tone(t, d, f, { w: ['sawtooth', 'sawtooth'], det: 8, a: .07, v: .11, vib: .008, lp: 2600, rl: .25, rev: .45, del: .15 }),
    brass: (t, d, f) => tone(t, d, f, { w: ['sawtooth', 'square'], mix: [.6, .4], det: 5, a: .03, v: .12, lp: 1400, lpEnv: 2.2, lpT: .12, q: 1.5, rl: .15, rev: .3, del: .1 }),
    musicbox: (t, d, f) => tone(t, .02, f * 2, { w: ['sine', 'sine'], mul: [1, 4.01], mix: [.8, .2], v: .16, dec: 1.1, rl: .3, rev: .5, del: .3 }),
    glass: (t, d, f) => tone(t, d, f * 2, { w: ['sine', 'sine'], mul: [1, 2.76], mix: [.75, .25], a: .01, v: .13, dec: 1.4, sus: .2, rl: .4, rev: .6, del: .35 }),
    oud: (t, d, f) => tone(t, .02, f, { w: ['sawtooth', 'triangle'], v: .15, lp: 3000, lpEnv: .25, lpT: .3, dec: .5, rl: .1, rev: .3, del: .2 }),
    reed: (t, d, f) => tone(t, d, f, { w: ['square', 'sawtooth'], mix: [.6, .4], a: .03, v: .09, vib: .01, lp: 1100, q: 2, rl: .12, rev: .3 }),
    marimba: (t, d, f) => tone(t, .02, f, { w: ['sine', 'sine'], mul: [1, 3.9], mix: [.85, .15], v: .15, dec: .3, rl: .05, rev: .2, del: .15 }),
    harpsi: (t, d, f) => tone(t, .02, f, { w: ['sawtooth', 'square'], v: .07, hp: 400, dec: .45, rl: .05, rev: .25, del: .2 }),
    saw: (t, d, f) => tone(t, .02, f, { w: ['sawtooth', 'sawtooth'], det: 12, v: .07, lp: 2400, lpEnv: .2, lpT: .18, q: 3, dec: .25, rl: .05, rev: .2, del: .3 }),
    harp: (t, d, f) => tone(t, .02, f, { w: ['triangle', 'sine'], mul: [1, 2], mix: [.8, .2], v: .12, dec: .9, rl: .2, rev: .4, del: .25 }),
    bell: (t, d, f) => tone(t, .02, f * 2, { w: ['sine', 'sine'], mul: [1, 3.5], mix: [.7, .3], v: .09, dec: 1.2, rl: .3, rev: .55, del: .3 }),
    clock: (t, d, f) => tone(t, .01, f * 2, { w: ['square'], v: .05, hp: 1200, dec: .08, rl: .02, rev: .2, del: .4 }),
    water: (t, d, f) => tone(t, .02, f * 2, { w: ['sine'], v: .1, slide: 1.06, slideT: .05, dec: .5, rl: .2, rev: .5, del: .45 }),
    pluck: (t, d, f) => tone(t, .02, f, { w: ['triangle', 'sawtooth'], mix: [.7, .3], v: .1, lp: 2200, lpEnv: .2, lpT: .2, dec: .35, rl: .05, rev: .2, del: .2 }),
    anvil: (t, d, f) => tone(t, .01, f * 2, { w: ['square', 'sine'], mul: [1, 2.7], v: .06, dec: .35, rl: .05, rev: .3, del: .2 }),
    xylo: (t, d, f) => { tone(t, .01, f * 2, { w: ['sine'], v: .13, dec: .18, rl: .03, rev: .2, del: .15 }); hit(t, { f: 3000, v: .02, d: .02 }); }
  };
  const PADS = {
    warm: (t, d, fs) => fs.forEach(f => tone(t, d, f, { w: ['sawtooth', 'triangle'], det: 10, a: .6, v: .035, lp: 900, rl: .8, rev: .5, dry: .7 })),
    choir: (t, d, fs) => fs.forEach(f => tone(t, d, f, { w: ['sawtooth', 'sawtooth', 'triangle'], det: 14, a: .8, v: .03, vib: .004, lp: 1300, q: 2.5, rl: 1, rev: .7, dry: .6 })),
    dark: (t, d, fs) => fs.forEach(f => tone(t, d, f, { w: ['sawtooth', 'sawtooth'], det: 18, a: .5, v: .035, lp: 650, q: 1.5, rl: .8, rev: .5, dry: .7 })),
    cold: (t, d, fs) => fs.forEach(f => tone(t, d, f * 2, { w: ['triangle', 'sine'], det: 6, a: 1, v: .03, rl: 1.2, rev: .8, dry: .5 }))
  };
  const chordOf = (dg, oct) => [deg(dg, oct), deg(dg + 2, oct), deg(dg + 4, oct)];
  const RH = [[0, 4, 6, 8, 12], [0, 3, 6, 8, 10, 12], [0, 2, 4, 8, 11, 12, 14], [0, 6, 8, 12, 14], [0, 4, 8, 10, 12], [0, 2, 3, 4, 8, 12]];
  function motif() {
    const rh1 = RH[Math.floor(r() * RH.length)], rh2 = RH[Math.floor(r() * RH.length)], steps = [];
    let d = Math.floor(r() * 3) * 2;
    for (const [bi, rh] of [[0, rh1], [1, rh2]]) rh.forEach((s, i) => { const mv = r(); d += mv < .35 ? 1 : mv < .7 ? -1 : mv < .82 ? 2 : mv < .92 ? -2 : 0; d = clamp(d, -2, 9); const nx = i + 1 < rh.length ? rh[i + 1] : 16; steps.push({ s: bi * 16 + s, len: nx - s, d }); });
    steps[steps.length - 1].len = Math.max(steps[steps.length - 1].len, 4);
    return steps;
  }
  const mA = motif(), mB = motif(), mC = motif();
  const sixteenth = spb / 4, swing = S.drums === 'jungle' || S.drums === 'darbuka' ? .12 : 0;
  const at = (barI, st) => barI * bar + st * sixteenth + (st % 2 ? sixteenth * swing : 0);
  const playMotif = (m, b0, prog, shift, sparse) => {
    for (const n of m) {
      if (sparse && n.len < 2 && r() < .4) continue;
      const bi = b0 + Math.floor(n.s / 16), st = n.s % 16, chord = prog[bi % 8];
      let dd = n.d + shift;
      if (st === 0) { const tones = [chord, chord + 2, chord + 4, chord + 7]; dd = tones.reduce((a, b) => Math.abs(b - dd) < Math.abs(a - dd) ? b : a, tones[0]); }
      INST[S.lead](at(bi, st), n.len * sixteenth * .92, mtof(deg(dd, 1)));
    }
  };
  for (let sec = 0; sec < 2; sec++) {
    const prog = sec ? S.pB : S.p, b0 = sec * 8;
    for (let b = 0; b < 8; b++) PADS[S.pad](at(b0 + b, 0), bar * .98, chordOf(prog[b], -1).map(mtof));
    const ms = sec ? [mC, mC, mA, mB] : [mA, mA, mB, mA], sh = sec ? [2, 3, 0, 1] : [0, 1, 0, -1];
    ms.forEach((m, i) => playMotif(m, b0 + i * 2, prog, sh[i], i === 1));
    for (let b = 0; b < 8; b++) {
      const bi = b0 + b, ch = prog[b];
      const arpN = S.arp === 'bell' || S.arp === 'water' || S.arp === 'harp' ? 8 : 16, tones = [ch, ch + 2, ch + 4, ch + 7, ch + 4, ch + 2];
      for (let k = 0; k < arpN; k++) { if (S.arp === 'clock' && k % 2) continue; INST[S.arp](at(bi, k * (16 / arpN)), sixteenth * (16 / arpN), mtof(deg(tones[k % tones.length], 0))); }
      const bf = mtof(deg(ch, -2)), bpat = { bounce: [0, 6, 8, 14], pulse: [0, 4, 8, 12], drive: [0, 2, 4, 6, 8, 10, 12, 14], soft: [0, 8], wonky: [0, 3, 8, 11] }[S.bass];
      for (const st of bpat) tone(at(bi, st), sixteenth * (S.bass === 'soft' ? 7 : S.bass === 'drive' ? 1.6 : 3), st === 8 && S.bass === 'bounce' ? bf * 1.5 : bf * (S.bass === 'wonky' && st === 11 ? 1.059 : 1),
        { w: S.bass === 'drive' ? ['sawtooth', 'square'] : ['triangle', 'sine'], v: S.bass === 'drive' ? .14 : .22, lp: S.bass === 'drive' ? 900 : 700, lpEnv: .5, lpT: .15, dec: .25, sus: .4, rl: .06 });
      const D = S.drums, last = b === 7;
      for (let st = 0; st < 16; st++) {
        const t = at(bi, st);
        if (D === 'none') { if (st === 0 && b % 2 === 0) hit(t, { type: 'bandpass', f: 600, v: .05, d: .5, rev: .6 }); continue; }
        if (D === 'jungle') { if (st === 0 || st === 10) kick(t, .45); if (st === 4 || st === 12) snare(t, .18); if (st % 2 === 0) hat(t, .035 + (st % 4 ? 0 : .015)); if (st === 7 || st === 15) hit(t, { type: 'bandpass', f: 2500, v: .05, d: .06 }); }
        else if (D === 'war' || D === 'epic' || D === 'boss') { if (st % 4 === 0 || (D !== 'epic' && st === 10)) kick(t, .55); if (st === 4 || st === 12) snare(t, .32); if (D === 'boss' ? true : st % 2 === 0) hat(t, .04); if (last && st >= 12) tom(t, 140 - (st - 12) * 18, .4); if (D === 'war' && (st === 6 || st === 14)) tom(t, 90, .3); }
        else if (D === 'soft') { if (st === 0 || st === 8) kick(t, .3); if (st === 12) snare(t, .1); if (st % 4 === 2) hat(t, .025); }
        else if (D === 'ghost') { if (st === 0) kick(t, .35); if (st === 10) hit(t, { type: 'bandpass', f: 900, v: .08, d: .3, rev: .5 }); if (st % 4 === 2) hat(t, .02); }
        else if (D === 'ice') { if (st === 0 || st === 9) kick(t, .3); if (st % 4 === 2) hit(t, { f: 9000, v: .03, d: .02, rev: .4 }); if (st === 12) snare(t, .12); }
        else if (D === 'toll') { if (st === 0) { kick(t, .35); if (b % 2 === 0) tone(t, .02, mtof(deg(0, -1)), { w: ['sine', 'sine'], mul: [1, 2.4], v: .12, dec: 2.2, rl: .5, rev: .7 }); } if (st === 8) snare(t, .14); if (st % 4 === 2) hat(t, .025); }
        else if (D === 'clock') { if (st % 4 === 0) hit(t, { type: 'bandpass', f: 3500, q: 4, v: .09, d: .03 }); if (st % 4 === 2) hit(t, { type: 'bandpass', f: 2400, q: 4, v: .06, d: .03 }); if (st === 0 || st === 8) kick(t, .35); if (st === 12) snare(t, .16); }
        else if (D === 'darbuka') { if (st === 0 || st === 6) tom(t, 110, .45); if (st === 4 || st === 10 || st === 12) hit(t, { type: 'bandpass', f: 1500, q: 2, v: .12, d: .08 }); if (st % 2) hit(t, { f: 6000, v: .02, d: .02 }); }
        else if (D === 'march') { if (st === 0 || st === 8) kick(t, .45); if (st === 4 || st === 12 || st === 14) snare(t, st === 14 ? .12 : .22); }
        else if (D === 'mine') { if (st === 0 || st === 8) kick(t, .4); if (st === 4 || st === 12) tone(t, .01, 1800, { w: ['square', 'sine'], mul: [1, 2.7], v: .05, dec: .25, rl: .05, rev: .3 }); if (st % 2 === 0) hat(t, .03); }
        else if (D === 'bones') { if (st === 0 || st === 10) kick(t, .35); if (st === 4 || st === 7 || st === 12) tone(t, .01, 900 + (st * 37 % 5) * 120, { w: ['sine'], v: .08, dec: .08, rl: .02 }); if (st % 4 === 2) hat(t, .02); }
      }
    }
  }
  // eco con realimentación (también alimenta la reverb)
  const Dn = Math.floor(spb * .75 * SR), dly = new Float32Array(N);
  for (let i = 0; i < N; i++) { const y = DEL[i] + (i >= Dn ? dly[i - Dn] * .32 : 0); dly[i] = y; }
  for (let i = 0; i < N; i++) { DRY[i] += dly[i] * .25; REV[i] += dly[i] * .25; }
  // reverb tipo Freeverb
  const sc = SR / 44100, combs = [1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617].map(n => ({ b: new Float32Array(Math.floor(n * sc)), i: 0, f: 0 })), aps = [556, 441, 341, 225].map(n => ({ b: new Float32Array(Math.floor(n * sc)), i: 0 }));
  const out = new Float32Array(N);
  for (let i = 0; i < N; i++) {
    const x = REV[i] * .015; let s = 0;
    for (const c of combs) { const y = c.b[c.i]; c.f = y * .75 + c.f * .25; c.b[c.i] = x + c.f * .84; if (++c.i >= c.b.length) c.i = 0; s += y; }
    for (const a of aps) { const bo = a.b[a.i]; const y = -s + bo; a.b[a.i] = s + bo * .5; if (++a.i >= a.b.length) a.i = 0; s = y; }
    out[i] = DRY[i] * .9 + s * .32 * 3;
  }
  // bucle sin corte: la cola del final se suma al principio
  const o = new Float32Array(NL); for (let i = 0; i < NL; i++) o[i] = out[i] + (i + NL < N ? out[i + NL] : 0);
  let pk = 0; for (let i = 0; i < NL; i++) pk = Math.max(pk, Math.abs(o[i]));
  const k = pk > 0 ? 1.25 / pk : 1, nrm = Math.tanh(1.25);
  const buf = new ArrayBuffer(44 + NL * 2), wav = new DataView(buf);
  const ws = (p, s) => { for (let i = 0; i < s.length; i++) wav.setUint8(p + i, s.charCodeAt(i)); };
  ws(0, 'RIFF'); wav.setUint32(4, 36 + NL * 2, true); ws(8, 'WAVEfmt '); wav.setUint32(16, 16, true); wav.setUint16(20, 1, true); wav.setUint16(22, 1, true);
  wav.setUint32(24, SR, true); wav.setUint32(28, SR * 2, true); wav.setUint16(32, 2, true); wav.setUint16(34, 16, true); ws(36, 'data'); wav.setUint32(40, NL * 2, true);
  for (let i = 0; i < NL; i++) wav.setInt16(44 + i * 2, Math.tanh(o[i] * k) / nrm * .9 * 32767, true);
  return buf;
}
let synthWorker = null, synthCB = {};
function getWorker() {
  if (synthWorker !== null) return synthWorker;
  try {
    const src = SYNTH.toString() + '\nonmessage=e=>{const b=SYNTH(e.data.S,e.data.SC,e.data.seed);postMessage({id:e.data.id,b},[b]);};';
    synthWorker = new Worker(URL.createObjectURL(new Blob([src], { type: 'text/javascript' })));
    synthWorker.onmessage = e => { const f = synthCB[e.data.id]; delete synthCB[e.data.id]; if (f) f(e.data.b); };
    synthWorker.onerror = () => { synthWorker = false; for (const id in synthCB) { const f = synthCB[id]; delete synthCB[id]; const S = SONGS[id]; f(SYNTH(S, SC, S.seed * 7919 + 13)); } };
  } catch (e) { synthWorker = false; }
  return synthWorker;
}
function genSong(id) {
  const S = SONGS[id]; if (!S || GEN[id] || GEN_BUSY[id]) return;
  GEN_BUSY[id] = 1;
  const done = buf => {
    GEN[id] = URL.createObjectURL(new Blob([buf], { type: 'audio/wav' })); MUS[id] = GEN[id]; GEN_ORDER.push(id); delete GEN_BUSY[id];
    while (GEN_ORDER.length > 8) { const old = GEN_ORDER.shift(); if (old !== curMusicId && old !== musicWanted) { try { URL.revokeObjectURL(GEN[old]); } catch (e) {} delete GEN[old]; delete MUS[old]; delete MUSIC[old]; } else { GEN_ORDER.push(old); break; } }
    if (musicWanted === id) { musicWanted = null; _playMusicG(id); }
  };
  const w = getWorker();
  if (w) { synthCB[id] = done; w.postMessage({ id, S, SC, seed: S.seed * 7919 + 13 }); }
  else setTimeout(() => { try { done(SYNTH(S, SC, S.seed * 7919 + 13)); } catch (e) { delete GEN_BUSY[id]; } }, 0);
}
function genIdFor(id) {
  if (!id || OPT.ost !== 'orig') return null;
  if (SONGS[id]) return id;
  if (id === 'menu') return 'gmenu';
  if (id === 'boss') return 'gboss';
  if (id === 'final') return 'gfinal';
  if (/^w\d$/.test(id) && typeof curWorld === 'number') return 'g' + curWorld;
  return null;
}
let musicWanted = null;
const _playMusicG = playMusic;
playMusic = function (id) {
  const g = genIdFor(id);
  if (!g || !SONGS[g]) { musicWanted = null; if (id && SONGS[id]) id = id === 'gboss' ? 'boss' : id === 'gfinal' ? 'final' : /^g\d+$/.test(id) ? WORLDS[+id.slice(1)].music : 'menu'; return _playMusicG(id); }
  if (GEN[g]) { musicWanted = null; return _playMusicG(g); }
  // mientras se compone, silencio breve; en cuanto esté, empieza
  wantMusic = id; musicWanted = g;
  if (curMusic) { curMusic.pause(); curMusic = null; curMusicId = null; }
  if (AC && musicOn) genSong(g);
};
// opción en el menú
const _optRowsG = optRows;
optRows = function () {
  const R = _optRowsG();
  const sw = () => { OPT.ost = OPT.ost === 'orig' ? 'clasica' : 'orig'; const w = wantMusic; curMusicId = null; playMusic(w); };
  R.splice(2, 0, ['Banda sonora', OPT.ost === 'orig' ? 'Original' : 'Clásica', sw, sw]);
  return R;
};
// componer de antemano el tema del menú y del mundo siguiente cuando el audio arranca
const _initAudioG = initAudio;
initAudio = function () { _initAudioG(); if (AC && OPT.ost === 'orig') { genSong('gmenu'); try { genSong('g' + ORDER[Math.min(ORDER.length - 1, Math.floor(SAVE.unl / 3))]); } catch (e) {} } };
// al entrar en una fase, preparar también el tema del guardián
const _startStageG = startStage;
startStage = function (wi, act, fresh) { _startStageG(wi, act, fresh); if (AC && OPT.ost === 'orig') { genSong('g' + wi); genSong(wi >= 6 ? 'gfinal' : 'gboss'); } };
