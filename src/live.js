// ================= MUNDO VIVO: objetos interactivos y criaturas =================
// Objetos: setas que rebotan, vasijas que se rompen, cofres, faroles, flores campana,
// runas del tiempo, helechos tímidos y flores curativas. Criaturas que reaccionan a Kael.
const LIVE_CRE = [
  ['frog', 'bunny', 'bird', 'moth'],          // 0 selva
  ['spirit', 'moth', 'bird'],                 // 1 Velmora, ciudad maldita
  ['sala', 'spirit'],                         // 2 volcán
  ['bunny', 'frog', 'moth', 'bird'],          // 3 crepúsculo
  ['spirit', 'moth', 'mouse'],                // 4 cementerio
  ['bunny', 'fox', 'bird'],                   // 5 hielo
  ['sala', 'spirit'],                         // 6 infierno
  ['mouse', 'bird', 'moth'],                  // 7 relojería
  ['frog', 'spirit', 'fish'],                 // 8 océano
  ['fox', 'sala', 'bird'],                    // 9 desierto
  ['bird', 'bunny', 'moth', 'spirit'],        // 10 cielo
  ['spirit', 'moth', 'fox'],                   // 11 núcleo
  ['frog', 'spirit', 'moth'],                 // 12 pantano
  ['spirit', 'moth', 'mouse'],                // 13 ciudadela del rey caído
  ['mouse', 'spirit', 'moth'],                // 14 minas de cristal
  ['spirit', 'moth', 'fox'],                  // 15 bosque de huesos
  ['mouse', 'moth', 'spirit'],                // 16 biblioteca prohibida
  ['bird', 'spirit']                          // 17 torre de las tormentas
];
const LIVE_STAG = [0, 3, 5, 10, 11];
const LIVE_AIR = { moth: 1, spirit: 1, fish: 1 };
const LIVE_SPD = { frog: 95, bunny: 160, fox: 175, mouse: 140, sala: 115 };
const LIVE_HINT = { shroom: '¡Salta sobre esa seta! Rebota muchísimo.', urn: 'Esas vasijas suenan a gemas… ¡rómpelas!', vase: 'Esas vasijas suenan a gemas… ¡rómpelas!', lamp: 'Un farol apagado. Tócalo y dale luz.', bell: 'Flores campana… ¡tócalas todas, cantan!', rune: 'Una runa del tiempo. Písala, Kael.', heal: 'Esa flor cura. Guárdala para cuando estés herido.', chest: '¡Un cofre allí arriba!' };
const liveHinted = {};
const BELL_NOTES = [1, 1.122, 1.26, 1.498, 1.682, 2];
let liveStats = { lamps: 0, lit: 0, bells: 0, rang: 0, bonusLamp: false, bonusBell: false };

function placeLive(L) {
  const r = seeded(L.wi * 7919 + L.act * 131 + 17 + (typeof liveSeed !== 'undefined' ? liveSeed : 0));
  const WL = !!(SPR['LW' + L.wi + '_glow'] && SPR['LW' + L.wi + '_glow'].width);
  const O = [], C = [];
  L.live = { o: O, c: C };
  const w = L.wi, kinds = LIVE_CRE[w] || ['bird'];
  const busy = x => (L.arena && x > L.arena.x1 - 80 && x < L.arena.x2 + 40) || x < 260 || (L.goal && Math.abs(L.goal.x - x) < 90)
    || L.hazards.some(h => Math.abs(h.x + h.w / 2 - x) < h.w / 2 + 40) || (L.plates || []).some(q => Math.abs(q.x - x) < 70)
    || (L.doors || []).some(q => Math.abs(q.x - x) < 80) || L.checks.some(c => Math.abs(c.x - x) < 50)
    || L.levers.some(l => Math.abs(l.x - x) < 50) || (L.crystals || []).some(c => Math.abs(c.x - x) < 40)
    || O.some(o => Math.abs(o.x - x) < 40);
  const roofOver = (x, y, hgt) => L.plats.some(q => q.k === 'solid' && x > q.x - 8 && x < q.x + q.w + 8 && q.y + q.h < y - 4 && q.y + q.h > y - hgt);
  const ground = L.plats.filter(s => s.k === 'solid' && !s.float && !s.ceil && !s.pillar && !s.conv && s.w >= 150);
  let heals = 0;
  for (const s of ground) {
    for (let x = s.x + 50 + r() * 90; x < s.x + s.w - 40; x += 100 + r() * 135) {
      if (busy(x)) continue;
      const q = r();
      let k = q < 0.24 ? 'urn' : q < 0.4 ? 'bell' : q < 0.53 ? 'lamp' : q < 0.64 ? 'rune' : q < 0.78 ? 'fern' : q < 0.92 ? 'shroom' : 'heal';
      if (k === 'urn' && r() < 0.4) k = 'vase';
      if (k === 'heal' && heals >= 2) k = 'fern';
      if (k === 'shroom' && roofOver(x, s.y, 260)) k = 'urn';
      if (k === 'lamp' && roofOver(x, s.y, 50)) k = 'bell';
      if (WL && r() < 0.5) { const q2 = r(); k = q2 < 0.24 ? 'Wglow' : q2 < 0.44 ? 'Wspring' : q2 < 0.74 ? 'Wbreak' : 'Wreact'; if (k === 'Wspring' && roofOver(x, s.y, 260)) k = 'Wbreak'; if (k === 'Wglow' && roofOver(x, s.y, 60)) k = 'Wreact'; }
      if (k === 'heal') heals++;
      O.push({ k, x: Math.round(x), y: s.y, st: 0, t: 0, cd: 0, ph: r() * 6, flip: r() < 0.5, note: 0, sq: 0, hit: 0, blend: 0 });
      // pequeñas familias de vasijas
      if ((k === 'urn' || k === 'vase') && r() < 0.5 && x + 22 < s.x + s.w - 30) O.push({ k: r() < 0.5 ? 'urn' : 'vase', x: Math.round(x + 18), y: s.y, st: 0, t: 0, cd: 0, ph: r() * 6, flip: r() < 0.5, hit: 0, blend: 0 });
    }
  }
  // cofres en plataformas elevadas (premian explorar)
  const high = L.plats.filter(s => s.k === 'solid' && s.float && s.w >= 40 && !busy(s.x + s.w / 2) && !(L.arena && s.x > L.arena.x1 - 100));
  for (let i = 0; i < 2 && high.length; i++) { const s = high.splice(Math.floor(r() * high.length), 1)[0]; O.push({ k: 'chest', x: Math.round(s.x + s.w / 2), y: s.y, st: 0, t: 0, cd: 0, ph: 0, flip: r() < 0.5, hit: 0, blend: 0 }); }
  if (!O.some(o => o.k === 'chest')) { const s = ground[Math.floor(r() * ground.length)]; if (s) { const x = s.x + s.w - 60; if (!busy(x)) O.push({ k: 'chest', x: Math.round(x), y: s.y, st: 0, t: 0, cd: 0, ph: 0, flip: true, hit: 0, blend: 0 }); } }
  let bi = 0; for (const o of O) if (o.k === 'bell') o.note = bi++ % BELL_NOTES.length;
  // criaturas
  for (const s of ground) {
    if (r() > 0.88) continue;
    const k = kinds[Math.floor(r() * kinds.length)];
    const x0 = s.x + 40 + r() * (s.w - 80); if (L.arena && x0 > L.arena.x1 - 80 && x0 < L.arena.x2 + 40) continue;
    if (k === 'fish') continue;
    const n = LIVE_AIR[k] ? 1 + Math.floor(r() * 2) : k === 'bird' ? 2 + Math.floor(r() * 3) : 1 + Math.floor(r() * 2);
    for (let i = 0; i < n; i++) {
      const x = clamp(x0 + (i - n / 2) * 16 + r() * 8, s.x + 12, s.x + s.w - 12);
      const air = !!LIVE_AIR[k];
      C.push({ k, x, y: air ? s.y - 40 - r() * 60 : s.y, hx: x, hy: air ? s.y - 40 - r() * 60 : s.y, x1: s.x + 10, x2: s.x + s.w - 10, gy: s.y,
        st: 'idle', t: r() * 5, f: 0, vx: 0, vy: 0, face: r() < .5 ? -1 : 1, ph: r() * 6, gone: false, fade: 1, wait: rnd(1, 4), gift: true });
    }
  }
  // peces en el agua
  for (const z of L.zones) if (z.k === 'water' && kinds.includes('fish')) for (let i = 0; i < 4; i++) {
    const x = z.x + 30 + r() * (z.w - 60), y = z.y + 30 + r() * Math.max(10, z.h - 70);
    C.push({ k: 'fish', x, y, hx: x, hy: y, x1: z.x + 14, x2: z.x + z.w - 14, gy: z.y, zy: z.y, st: 'swim', t: r() * 5, f: 0, vx: (r() < .5 ? -1 : 1) * 40, vy: 0, face: 1, ph: r() * 6, gone: false, fade: 1, wait: rnd(2, 6) });
  }
  // el ciervo de luz: uno por nivel en algunos mundos
  if (LIVE_STAG.includes(w) && L.act !== 2) {
    const wide = ground.filter(s => s.w >= 360 && s.x > 600 && !(L.arena && s.x > L.arena.x1 - 200));
    if (wide.length) { const s = wide[Math.floor(r() * wide.length)], x = s.x + s.w / 2; C.push({ k: 'stag', x, y: s.y, hx: x, hy: s.y, x1: s.x + 40, x2: s.x + s.w - 40, gy: s.y, st: 'walk', t: 0, f: 0, vx: 22, vy: 0, face: 1, ph: 0, gone: false, fade: 1, wait: 3, near: 0 }); }
  }
}
function resetLive() {
  const L = level.live; if (!L) return;
  liveStats = { lamps: L.o.filter(o => o.k === 'lamp' || o.k === 'Wglow').length, lit: 0, bells: L.o.filter(o => o.k === 'bell').length, rang: 0, bonusLamp: false, bonusBell: false };
}

// ---------------- interacción ----------------
function liveHH(o) { if (o.hh) return o.hh; const m = META['LW' + curWorld + '_' + o.k.slice(1)]; return (o.hh = m ? (m.ay - 3) / 4 : 24); }
function liveBox(o) {
  if (o.k[0] === 'W') { const hh = liveHH(o), wd = o.k === 'Wglow' ? 20 : o.k === 'Wspring' ? 28 : 22; return { x: o.x - wd / 2, y: o.y - hh, w: wd, h: hh }; }
  const hgt = { shroom: 28, chest: 20, urn: 16, vase: 22, lamp: 38, bell: 25, rune: 22, fern: 18, heal: 22 }[o.k] || 18;
  const wid = { shroom: 26, chest: 24, urn: 16, vase: 11, lamp: 20, bell: 16, rune: 16, fern: 22, heal: 16 }[o.k] || 16;
  return { x: o.x - wid / 2, y: o.y - hgt, w: wid, h: hgt };
}
function gemPop(x, y, n, spread) {
  for (let i = 0; i < n; i++) {
    const a = -Math.PI / 2 + (i - (n - 1) / 2) * (spread || 0.35);
    level.gems.push({ x: x + Math.cos(a) * (18 + i % 2 * 8), y: y + Math.sin(a) * (22 + (i % 3) * 7), taken: false, ph: Math.random() * 6 });
  }
}
function breakPot(o) {
  o.st = 2; o.t = 0; sfx('crumble', .5, 1.4); sfx('ice', .3, 1.9);
  const by = o.y - (o.k === 'vase' ? 10 : 7);
  burst(o.x, by, '#b97a4a', 10, 160, 380, .6, 2); burst(o.x, by, '#7fe9ff', 8, 120, 200, .6, 1);
  addScore(30); hitStop = Math.max(hitStop, 0.03);
  const q = Math.random();
  if (q < 0.55) gemPop(o.x, by - 6, 1 + Math.floor(Math.random() * 2));
  else if (q < 0.7) level.cherries.push({ x: o.x, y: by - 8, taken: false, ph: 0 });
  else if (q < 0.8) { // ¡un espíritu estaba dentro!
    const k = Math.random() < .5 ? 'spirit' : 'moth';
    level.live.c.push({ k, x: o.x, y: by, hx: o.x, hy: by - 50, x1: o.x - 200, x2: o.x + 200, gy: o.y, st: 'idle', t: 0, f: 0, vx: 0, vy: -60, face: 1, ph: Math.random() * 6, gone: false, fade: 1, wait: 2, gift: true });
    burst(o.x, by, '#bff4ff', 16, 120, -60, .9, 2); tSay('¡Había un espíritu ahí dentro!', 2.4);
  }
}
function openChest(o) {
  if (o.st) return; o.st = 1; o.t = 0; o.blend = 1;
  sfx('relic', .6, 1.2); sfx('gem', .4, 1.5); hitStop = Math.max(hitStop, 0.06); zoomPunch && zoomPunch(0.04);
  burst(o.x, o.y - 14, '#ffd34d', 26, 220, 260, .9, 2); burst(o.x, o.y - 14, '#ffffff', 10, 120, 100, .6, 1);
  gemPop(o.x, o.y - 26, 7, 0.32); addScore(300); addFloat(o.x, o.y - 40, '¡Cofre del tiempo!', '#ffd34d', 16);
  tSay(['¡Un cofre! ¡Brillitos para el taller!', '¡Tesoro! Sabía que valía la pena subir.'][Math.floor(Math.random() * 2)], 2.6);
}
function lightLamp(o) {
  if (o.st) return; o.st = 1; o.t = 0; o.blend = 1; liveStats.lit++;
  sfx('fire', .35, 1.5); sfx('check', .25, 1.6); burst(o.x + (o.flip ? -6 : 6), o.y - 24, '#ffb040', 14, 120, -40, .7, 2); addScore(40);
  if (liveStats.lamps >= 2 && liveStats.lit >= liveStats.lamps && !liveStats.bonusLamp) {
    liveStats.bonusLamp = true; gemPop(p.x + p.w / 2, p.y - 20, 5, 0.4); addScore(500);
    addFloat(p.x + p.w / 2, p.y - 40, '¡Todos los faroles encendidos!', '#ffd34d', 15); sfx('win', .35, 1.3); tSay('¡Qué bonito! El mundo brilla otra vez.', 2.8);
  }
}
function ringBell(o) {
  if (o.cd > 0) return;
  o.cd = 0.9; o.t = 0; o.blend = 1; if (o.st === 0) { o.st = 1; liveStats.rang++; addScore(20); }
  sfx('gem', .4, BELL_NOTES[o.note || 0] * 0.9); sfx('ice', .18, BELL_NOTES[o.note || 0] * 1.8);
  for (let i = 0; i < 4; i++) parts.push({ x: o.x + rnd(-6, 6), y: o.y - 18, vx: rnd(-20, 20), vy: rnd(-60, -30), life: 1.1, max: 1.1, c: i % 2 ? '#ffd34d' : '#ff9ad8', s: 2, g: -10 });
  if (liveStats.bells >= 3 && liveStats.rang >= liveStats.bells && !liveStats.bonusBell) {
    liveStats.bonusBell = true; gemPop(p.x + p.w / 2, p.y - 20, 4, 0.4); addScore(400);
    addFloat(p.x + p.w / 2, p.y - 40, '¡Melodía completa!', '#ff9ad8', 15); tSay('¡Las flores cantan para ti!', 2.6);
  }
}
function hitWBreak(o) {
  const c = 'rgb(' + WCOL[curWorld] + ')', hh = liveHH(o);
  if (o.st === 0) { o.st = 1; o.blend = 1; o.hit = 0.2; sfx('crumble', .45, 1.2); burst(o.x, o.y - hh / 2, c, 10, 140, 200, .5, 2); hitStop = Math.max(hitStop, 0.03); return; }
  o.st = 2; sfx('crumble', .6, 0.9); sfx('relic', .3, 1.6); hitStop = Math.max(hitStop, 0.05);
  burst(o.x, o.y - hh / 2, c, 24, 220, 300, .8, 2); burst(o.x, o.y - hh / 2, '#ffffff', 10, 160, 200, .5, 1);
  gemPop(o.x, o.y - hh / 2 - 6, 3 + Math.floor(Math.random() * 3), 0.4); addScore(120);
  if (Math.random() < 0.18) level.cherries.push({ x: o.x + 10, y: o.y - hh, taken: false, ph: 0 });
}
function reactW(o) {
  if (o.reacted) return; o.reacted = 1; addScore(25);
  const c = 'rgb(' + WCOL[curWorld] + ')', hh = liveHH(o); burst(o.x, o.y - hh * 0.7, c, 14, 120, -30, .9, 2);
  sfx(['heal', 'ghost', 'fire', 'gem', 'ghost', 'ice', 'fire', 'clang', 'bounce', 'gem', 'gem', 'shift', 'ghost', 'clang', 'gem', 'ghost', 'shift', 'shift'][curWorld] || 'gem', .3, 1.4);
}
function hitLive(hb) {
  const L = level.live; if (!L) return;
  for (const o of L.o) {
    if (o.st === 2) continue; const b = liveBox(o);
    if (!(hb.x < b.x + b.w && hb.x + hb.w > b.x && hb.y < b.y + b.h && hb.y + hb.h > b.y)) continue;
    if (p.hitSet.has(o)) continue; p.hitSet.add(o);
    if (o.k === 'urn' || o.k === 'vase') breakPot(o);
    else if (o.k === 'Wbreak') hitWBreak(o);
    else if (o.k === 'Wglow') lightLamp(o);
    else if (o.k === 'Wspring') { o.sq = 0.25; sfx('bounce', .3, 1.4); }
    else if (o.k === 'Wreact') reactW(o);
    else if (o.k === 'chest') openChest(o);
    else if (o.k === 'lamp') lightLamp(o);
    else if (o.k === 'bell') ringBell(o);
    else if (o.k === 'shroom') { o.sq = 0.25; sfx('bounce', .3, 1.4); burst(o.x, o.y - 16, '#7fe9ff', 6, 90, 100, .5, 2); }
    else o.hit = 0.2;
  }
  for (const c of L.c) { // las criaturas no sufren daño: se asustan y huyen
    if (c.gone || c.k === 'stag') continue;
    const cy = LIVE_AIR[c.k] ? c.y : c.y - 6;
    if (hb.x < c.x + 8 && hb.x + hb.w > c.x - 8 && hb.y < cy + 6 && hb.y + hb.h > cy - 8) scare(c, 1.4);
  }
}
function scare(c, k) {
  if (c.k === 'fish' || c.k === 'stag') return;
  const dir = Math.sign(c.x - (p.x + p.w / 2)) || 1;
  if (c.k === 'bird') { if (c.st !== 'fly') { c.st = 'fly'; c.vx = dir * rnd(110, 160); c.vy = -rnd(80, 130); c.face = dir; sfx('wind', .12, 2.2); for (let i = 0; i < 3; i++) parts.push({ x: c.x, y: c.y - 4, vx: rnd(-30, 30), vy: rnd(-30, 10), life: .6, max: .6, c: '#7fbfff', s: 1, g: 60 }); } return; }
  if (LIVE_AIR[c.k]) { c.vx = dir * 120 * k; c.vy = -60; c.t = 0; return; }
  c.st = 'flee'; c.face = dir; c.fleeT = 1.2 * k; if (c.k === 'frog' && c.hop <= 0) { c.hop = 0.45; c.vy = -170; }
  if (k > 1.2) { c.vy = -150; c.hop = c.k === 'frog' ? 0.45 : 0; addFloat(c.x, c.y - 18, '!', '#fff', 14); }
}

function updateLive(dt) {
  const L = level.live; if (!L) return;
  const px = p.x + p.w / 2, py = p.y + p.h, near = (x, w) => Math.abs(x - px) < w;
  for (const o of L.o) {
    o.t += dt; if (o.cd > 0) o.cd -= dt; if (o.sq > 0) o.sq -= dt; if (o.hit > 0) o.hit -= dt; if (o.blend > 0) o.blend = Math.max(0, o.blend - dt * 6);
    if (o.st === 2 || !near(o.x, 400)) continue;
    if (LIVE_HINT[o.k] && !liveHinted[o.k] && !o.st && near(o.x, 150) && !ticSay && !dlg && !boss) { liveHinted[o.k] = liveHinted[o.k === 'urn' ? 'vase' : o.k === 'vase' ? 'urn' : o.k] = 1; tSay(LIVE_HINT[o.k], 3); }
    const b = liveBox(o), touch = p.x < b.x + b.w && p.x + p.w > b.x && p.y < b.y + b.h && py > b.y;
    if (o.k === 'shroom') {
      const top = o.y - 27;
      const pb = p._pb === undefined ? py : p._pb;
      if (Math.abs(px - o.x) < 15 && pb <= top + 4 && py >= top - 2 && py <= o.y + 2 && (p.vy > 40 || pb < py - 0.5) && !p.hook && !p.inWater) {
        p.y = top - p.h; p.vy = -JUMP * 1.42; p.onGround = false; p.ground = null; p.jumps = 1; p.noCut = true; p.dashCD = 0; p.sq = 1.25;
        o.sq = 0.28; o.blend = 1; sfx('bounce', .7, 1.15); burst(o.x, top, '#7fe9ff', 12, 160, 260, .6, 2); burst(o.x, top, '#ffd34d', 6, 100, 200, .5, 2);
      }
    } else if (o.k === 'Wspring') {
      const top = o.y - liveHH(o) * 0.8, pb = p._pb === undefined ? py : p._pb;
      if (Math.abs(px - o.x) < 15 && pb <= top + 4 && py >= top - 2 && py <= o.y + 2 && (p.vy > 40 || pb < py - 0.5) && !p.hook && !p.inWater) {
        p.y = top - p.h; p.vy = -JUMP * 1.48; p.onGround = false; p.ground = null; p.jumps = 1; p.noCut = true; p.dashCD = 0; p.sq = 1.25;
        o.sq = 0.4; sfx('bounce', .7, 1.0); burst(o.x, top, 'rgb(' + WCOL[curWorld] + ')', 16, 180, 260, .7, 2); burst(o.x, top, '#ffffff', 6, 100, 200, .5, 1);
      }
    } else if (o.k === 'Wglow' && touch && !o.st) lightLamp(o);
    else if (o.k === 'Wreact') { const want = near(o.x, 70) && Math.abs(py - o.y) < 70 ? 1 : 0; if (want !== (o.st2 || 0)) { o.st2 = want; o.blend = 1; if (want) reactW(o); } if (o.st2 && Math.random() < dt * 4) parts.push({ x: o.x + rnd(-8, 8), y: o.y - liveHH(o) * rnd(.4, 1), vx: rnd(-10, 10), vy: -rnd(10, 30), life: 1, max: 1, c: 'rgb(' + WCOL[curWorld] + ')', s: 1, g: -5 }); }
    else if (o.k === 'chest' && touch) openChest(o);
    else if (o.k === 'lamp' && touch && !o.st) lightLamp(o);
    else if (o.k === 'bell' && touch) ringBell(o);
    else if (o.k === 'rune' && touch && o.st === 0) { o.st = 1; o.t = 0; o.blend = 1; addTime(2); sfx('slow', .3, 1.6); burst(o.x, o.y - 10, '#7fe9ff', 16, 140, 0, .8, 2); addFloat(o.x, o.y - 30, '+2s', '#7fe9ff', 14); }
    else if (o.k === 'fern') { const want = near(o.x, 30) && Math.abs(py - o.y) < 40 ? 0 : 1; if (want !== o.st2) { o.st2 = want; o.blend = 1; if (!want) sfx('step', .15, 1.8); } }
    else if (o.k === 'heal') {
      const open = o.st === 0 && near(o.x, 48) && Math.abs(py - o.y) < 50 ? 1 : 0;
      if (open !== (o.op || 0)) { o.op = open; o.blend = 1; }
      if (open && touch && p.hp < p.maxHp) { p.hp = Math.min(p.maxHp, p.hp + 30); o.st = 1; o.op = 0; o.blend = 1; sfx('heal', .6, 1.1); burst(o.x, o.y - 14, '#ff9ad8', 20, 160, -40, .9, 2); addFloat(o.x, o.y - 30, '+30', '#ff9ad8', 14); }
    }
    // el dash rompe vasijas a su paso
    if ((o.k === 'urn' || o.k === 'vase') && touch && p.dashT > 0) breakPot(o);
    if (o.k === 'Wbreak' && touch && p.dashT > 0 && !p.hitSet.has(o)) { p.hitSet.add(o); hitWBreak(o); }
    if (o.k === 'Wglow' && o.st && Math.random() < dt * 4) parts.push({ x: o.x + rnd(-5, 5), y: o.y - liveHH(o) * 0.75, vx: rnd(-8, 8), vy: -rnd(15, 35), life: .9, max: .9, c: 'rgb(' + WCOL[curWorld] + ')', s: 1, g: -10 });
    if (o.k === 'lamp' && o.st && Math.random() < dt * 3) parts.push({ x: o.x + (o.flip ? -9 : 9) + rnd(-2, 2), y: o.y - 27, vx: rnd(-8, 8), vy: -rnd(15, 30), life: .7, max: .7, c: '#ffd070', s: 1, g: -10 });
    if (o.k === 'rune' && o.st && Math.random() < dt * 2) parts.push({ x: o.x + rnd(-6, 6), y: o.y - rnd(4, 18), vx: 0, vy: -18, life: .8, max: .8, c: '#7fe9ff', s: 1, g: 0 });
  }
  p._pb = py;
  // criaturas
  for (const c of L.c) {
    if (c.gone) continue;
    c.t += dt; if (c.hop === undefined) c.hop = 0;
    const dx = c.x - px, dy = (LIVE_AIR[c.k] ? c.y : c.y - 6) - (p.y + p.h / 2), d2 = dx * dx + dy * dy;
    if (Math.abs(dx) > VW * 1.4 && c.st !== 'fly') continue;
    const k = c.k;
    if (k === 'bird') {
      if (c.st === 'fly') { c.x += c.vx * dt; c.y += c.vy * dt; c.vy -= 30 * dt; c.f = 2 + Math.floor(c.t * 14) % 6; if (c.y < cam.y - 80 || Math.abs(c.x - px) > VW * 1.5) c.gone = true; continue; }
      c.f = Math.floor(c.t * 3 + c.ph) % 2; c.wait -= dt;
      if (c.wait <= 0) { c.wait = rnd(1.5, 4); c.face = Math.random() < .5 ? -1 : 1; c.tx = clamp(c.x + c.face * rnd(6, 20), c.x1, c.x2); }
      if (c.tx !== undefined && Math.abs(c.tx - c.x) > 1) { c.x += Math.sign(c.tx - c.x) * 18 * dt; c.f = Math.floor(c.t * 8) % 2; }
      if (d2 < 110 * 110 && (Math.abs(p.vx) > 40 || d2 < 50 * 50)) { scare(c, 1); for (const o2 of L.c) if (o2 !== c && o2.k === 'bird' && o2.st !== 'fly' && Math.abs(o2.x - c.x) < 70) { scare(o2, 1); } }
      continue;
    }
    if (k === 'fish') {
      if (c.st === 'jump') { c.x += c.vx * dt; c.y += c.vy * dt; c.vy += 500 * dt; c.f = Math.floor(c.t * 16) % 8; if (c.vy > 0 && c.y > c.zy + 6) { c.st = 'swim'; burst(c.x, c.zy, '#bff4ff', 6, 90, 300, .4, 2); } continue; }
      c.x += c.vx * dt; c.y = c.hy + Math.sin(c.t * 1.4 + c.ph) * 8; c.f = Math.floor(c.t * 10) % 8; c.face = Math.sign(c.vx) || 1;
      if (c.x < c.x1 || c.x > c.x2) { c.vx = -c.vx; c.x = clamp(c.x, c.x1, c.x2); }
      if (d2 < 60 * 60) c.vx = (Math.sign(dx) || 1) * 90; else if (Math.abs(c.vx) > 45) c.vx *= 1 - dt;
      c.wait -= dt; if (c.wait <= 0) { c.wait = rnd(4, 9); if (c.hy - c.zy < 60) { c.st = 'jump'; c.vy = -rnd(220, 300); c.y = c.zy + 4; sfx('bounce', .12, 2); burst(c.x, c.zy, '#bff4ff', 6, 90, 300, .4, 2); } }
      continue;
    }
    if (k === 'stag') {
      const pn = d2 < 150 * 150;
      if (c.st === 'fade') { c.fade -= dt * 0.8; c.f = 0; if (Math.random() < .6) parts.push({ x: c.x + rnd(-24, 24), y: c.y - rnd(10, 70), vx: rnd(-20, 20), vy: -rnd(20, 50), life: 1, max: 1, c: Math.random() < .5 ? '#ffffff' : '#ffe9a0', s: 1, g: -10 }); if (c.fade <= 0) c.gone = true; continue; }
      if (pn) { c.st = 'bow'; c.near += dt; c.face = dx > 0 ? -1 : 1; c.f = c.near > 0.5 ? 1 : 0;
        if (c.near > 1.4) { c.st = 'fade'; p.hp = p.maxHp; addTime(10); addScore(1000); sfx('relic', .6, .8); sfx('heal', .5, .9); burst(c.x, c.y - 40, '#ffffff', 40, 220, -40, 1.2, 2); addFloat(c.x, c.y - 90, 'Bendición del ciervo de luz', '#bff4ff', 15); tSay('Dicen que el ciervo de luz guía a los viajeros del tiempo…', 3.4); }
      } else {
        c.near = Math.max(0, c.near - dt); c.st = 'walk'; c.x += c.face * 26 * dt; c.f = 2 + Math.floor(c.t * 7) % 6;
        if (c.x < c.x1) c.face = 1; if (c.x > c.x2) c.face = -1;
        if (Math.random() < dt * .8) parts.push({ x: c.x + rnd(-20, 20), y: c.y - rnd(20, 70), vx: 0, vy: -10, life: .9, max: .9, c: '#fff4c0', s: 1, g: 0 });
      }
      continue;
    }
    if (LIVE_AIR[k]) {
      // moths van a los faroles encendidos; los espíritus sienten curiosidad por Kael
      let tx = c.hx, ty = c.hy;
      if (k === 'moth') { const lamp = L.o.find(o => (o.k === 'lamp' || o.k === 'Wglow') && o.st === 1 && Math.abs(o.x - c.x) < 260); if (lamp) { tx = lamp.x + (lamp.flip ? -9 : 9) + Math.cos(c.t * 2 + c.ph) * 16; ty = lamp.y - 30 + Math.sin(c.t * 3 + c.ph) * 10; } }
      if (k === 'spirit' && d2 < 130 * 130 && (c.follow || 0) < 6) { c.follow = (c.follow || 0) + dt; tx = px - p.face * 22 + Math.cos(c.t * 2) * 8; ty = p.y - 10 + Math.sin(c.t * 3) * 6; }
      else if (k === 'spirit' && d2 > 220 * 220) c.follow = 0;
      tx += Math.sin(c.t * 0.9 + c.ph) * 18; ty += Math.sin(c.t * 1.7 + c.ph) * 8;
      c.vx += ((tx - c.x) * 2.2 - c.vx * 1.6) * dt; c.vy += ((ty - c.y) * 2.2 - c.vy * 1.6) * dt;
      c.x += c.vx * dt; c.y += c.vy * dt; c.f = Math.floor(c.t * (k === 'moth' ? 16 : 9) + c.ph) % 8;
      if (Math.abs(c.vx) > 6) c.face = Math.sign(c.vx);
      if (k === 'spirit' && c.gift && d2 < 18 * 18) { c.gift = false; gemPop(c.x, c.y - 4, 1); sfx('relic', .3, 2.1); burst(c.x, c.y, '#bff4ff', 12, 100, -30, .7, 2); addFloat(c.x, c.y - 16, '♥', '#bff4ff', 16); }
      if (Math.random() < dt * 4) parts.push({ x: c.x + rnd(-3, 3), y: c.y + rnd(0, 6), vx: 0, vy: 8, life: .6, max: .6, c: k === 'moth' ? '#c9a0ff' : '#bff4ff', s: 1, g: 0 });
      continue;
    }
    // criaturas de suelo
    c.vy += 900 * dt; c.y += c.vy * dt; if (c.y >= c.gy) { c.y = c.gy; c.vy = 0; }
    if (c.hop > 0) c.hop -= dt;
    if (d2 < 85 * 85 && c.st !== 'flee') scare(c, 1);
    if (c.st === 'flee') {
      c.fleeT -= dt; const sp = LIVE_SPD[k] || 120;
      if (k === 'frog') { if (c.hop <= 0 && c.y >= c.gy) { c.hop = 0.45; c.vy = -170; sfx('bounce', .08, 2.4); } c.x += c.face * (c.y < c.gy ? sp : 0) * dt; c.f = c.y < c.gy - 0.5 ? 3 + Math.min(3, Math.floor((0.45 - c.hop) / 0.45 * 4)) : 2; }
      else { c.x += c.face * sp * dt; c.f = 2 + Math.floor(c.t * 14) % 6; }
      if (c.x <= c.x1 || c.x >= c.x2) { c.x = clamp(c.x, c.x1, c.x2); if (d2 < 70 * 70 && c.y >= c.gy) { c.vy = -200; c.face = -c.face; c.x += c.face * 4; } }
      if (c.fleeT <= 0 && d2 > 100 * 100) { c.st = 'idle'; c.wait = rnd(1, 3); }
    } else {
      c.f = Math.floor(c.t * 3 + c.ph) % 2; c.wait -= dt;
      if (c.wait <= 0) { c.wait = rnd(2, 5); c.face = Math.random() < .5 ? -1 : 1; c.walk = rnd(0.3, 0.9); }
      if (c.walk > 0) { c.walk -= dt; c.x = clamp(c.x + c.face * (LIVE_SPD[k] || 100) * 0.3 * dt, c.x1, c.x2); c.f = k === 'frog' ? 2 : 2 + Math.floor(c.t * 10) % 6; if (k === 'frog' && c.y >= c.gy && c.hop <= 0) { c.hop = 0.45; c.vy = -110; } }
    }
  }
}

// ---------------- dibujo ----------------
function drawLiveWorld() {
  const L = level.live; if (!L) return;
  for (const o of L.o) {
    if (o.st === 2 || !onScreen(o.x - 20, 40)) continue;
    if (o.k === 'Wglow' && o.st) { const hh = liveHH(o), y = o.y - hh * 0.72, fl = 0.85 + Math.sin(time * 7 + o.ph) * 0.1 + Math.sin(time * 19) * 0.04; glowAt(o.x, y, 44, 'rgba(' + WCOL[curWorld] + ',.55)', fl); lightAt(o.x, y, 150, 'rgba(' + WCOL[curWorld] + ',1)', .62 * fl); continue; }
    if (o.k === 'Wreact' && o.st2) { glowAt(o.x, o.y - liveHH(o) * 0.7, 20, 'rgba(' + WCOL[curWorld] + ',.45)', .5); lightAt(o.x, o.y - liveHH(o) * 0.7, 60, 'rgba(' + WCOL[curWorld] + ',1)', .25); continue; }
    if (o.k === 'Wbreak') { glowAt(o.x, o.y - liveHH(o) * 0.5, o.st ? 22 : 12, 'rgba(' + WCOL[curWorld] + ',.4)', .4 + Math.sin(time * 3 + o.ph) * .15); continue; }
    if (o.k === 'lamp' && o.st) { const lx2 = o.x + (o.flip ? -9 : 9), fl = 0.85 + Math.sin(time * 9 + o.ph) * 0.08 + Math.sin(time * 23) * 0.04; glowAt(lx2, o.y - 27, 38, 'rgba(255,180,80,.55)', fl); lightAt(lx2, o.y - 27, 110, 'rgba(255,190,110,1)', .55 * fl); }
    else if (o.k === 'rune' && o.st) glowAt(o.x, o.y - 10, 22, 'rgba(110,230,255,.5)', .6 + Math.sin(time * 3 + o.ph) * .2);
    else if (o.k === 'heal' && o.st === 0) glowAt(o.x, o.y - 14, o.op ? 26 : 12, 'rgba(255,140,210,.5)', .5 + Math.sin(time * 2.5 + o.ph) * .15);
    else if (o.k === 'shroom') glowAt(o.x, o.y - 16, 18, 'rgba(100,240,255,.35)', .45 + Math.sin(time * 2 + o.ph) * .12);
    else if (o.k === 'chest' && o.st) { glowAt(o.x, o.y - 12, 30, 'rgba(255,210,90,.5)', .6); lightAt(o.x, o.y - 12, 70, 'rgba(255,200,90,1)', .4); }
    else if (o.k === 'bell' && o.cd > 0) glowAt(o.x + 3, o.y - 14, 18, 'rgba(255,150,220,.5)', o.cd);
  }
  for (const c of L.c) {
    if (c.gone || !onScreen(c.x - 20, 40)) continue;
    if (c.k === 'spirit') { glowAt(c.x, c.y, 16, 'rgba(150,240,255,.5)', .55); lightAt(c.x, c.y, 50, 'rgba(150,240,255,1)', .35); }
    else if (c.k === 'moth') glowAt(c.x, c.y, 10, 'rgba(200,150,255,.45)', .4);
    else if (c.k === 'stag') { glowAt(c.x, c.y - 36, 50, 'rgba(200,230,255,.35)', .5 * c.fade); lightAt(c.x, c.y - 36, 120, 'rgba(200,230,255,1)', .4 * c.fade); }
    else if (c.k === 'sala') glowAt(c.x - c.face * 9, c.y - 6, 8, 'rgba(255,140,40,.5)', .6);
    else if (c.k === 'fish') glowAt(c.x, c.y, 8, 'rgba(120,240,255,.35)', .5);
  }
}
function liveTint() { return slowT > 0 ? 'rgba(120,200,255,.22)' : dim === 1 ? 'rgba(170,90,255,.14)' : 'rgba(' + LOOK[curWorld].fog + ',.1)'; }
function drawLiveHD() {
  const L = level && level.live; if (!L || !HDOK() || state === 'cutscene') return;
  const s = W / VW * camZoom, sc = s / 4, tint0 = liveTint();
  const shadeFor = (x, y, em) => (slowT > 0 || dim === 1) ? tint0 : (hdShade(x, y, em) || tint0);
  const vis = (x, y, r) => { const [sx, sy] = w2s(x, y); return sx > -r * s && sx < W + r * s && sy > -r * s && sy < H + r * s ? [sx, sy] : null; };
  ctx.save();
  for (const o of L.o) {
    if (o.st === 2) continue; const k = o.k[0] === 'W' ? 'LW' + curWorld + '_' + o.k.slice(1) : 'LO_' + o.k; if (!SPR[k]) continue;
    const q = vis(o.x, o.y, 50); if (!q) continue;
    let f = 0;
    if (o.k === 'shroom') f = o.sq > 0 ? 1 : 0;
    else if (o.k === 'chest' || o.k === 'lamp' || o.k === 'rune') f = o.st ? 1 : 0;
    else if (o.k === 'bell') f = o.cd > 0 ? 1 : 0;
    else if (o.k === 'fern') f = o.st2 === 0 ? 0 : 1;
    else if (o.k === 'heal') f = o.op ? 1 : 0;
    else if (o.k === 'Wglow' || o.k === 'Wbreak') f = o.st ? 1 : 0;
    else if (o.k === 'Wspring') f = o.sq > 0 ? 1 : 0;
    else if (o.k === 'Wreact') f = o.st2 ? 1 : 0;
    const tint = shadeFor(o.x, o.y - 12, (o.k === 'lamp' || o.k === 'Wglow') && o.st);
    const sh = o.hit > 0 ? Math.sin(time * 80) * 1.2 * s : 0;
    let sy = 1, sx = 1;
    if ((o.k === 'shroom' || o.k === 'Wspring') && o.sq > 0) { const u = o.sq / (o.k === 'Wspring' ? 0.4 : 0.28); sy = 1 + Math.sin(u * Math.PI * 3) * 0.12 * u; sx = 1 / sy; }
    if (o.k === 'bell' && o.cd > 0) { ctx.save(); ctx.translate(q[0], q[1]); ctx.rotate(Math.sin(o.cd * 18) * 0.12 * o.cd); drawHDFrame(k, f, 0, 0, o.flip, sc, tint, 1); ctx.restore(); continue; }
    if (o.k === 'fern' || o.k === 'heal' || o.k === 'bell' || o.k === 'Wreact') { // vaivén con el viento
      ctx.save(); ctx.translate(q[0], q[1]); ctx.transform(1, 0, Math.sin(time * 1.3 + o.ph) * 0.05 + gust * 0.08, 1, 0, 0);
      if (o.blend > 0) drawHDFrame(k, 1 - f, 0, 0, o.flip, sc, tint, o.blend);
      drawHDFrame(k, f, 0, 0, o.flip, sc, tint, 1 - o.blend * 0.5); ctx.restore(); continue;
    }
    ctx.save(); ctx.translate(q[0] + sh, q[1]); ctx.scale(sx, sy);
    if (o.blend > 0 && o.k !== 'shroom' && o.k !== 'Wspring') drawHDFrame(k, 1 - f, 0, 0, o.flip, sc, tint, o.blend);
    drawHDFrame(k, f, 0, 0, o.flip, sc, tint, o.blend > 0 && o.k !== 'shroom' && o.k !== 'Wspring' ? 1 - o.blend * 0.5 : 1);
    ctx.restore();
  }
  for (const c of L.c) {
    if (c.gone) continue; const k = 'LC_' + c.k; if (!SPR[k]) continue;
    const q = vis(c.x, c.y, c.k === 'stag' ? 90 : 30); if (!q) continue;
    let y = q[1];
    if (c.k === 'bird' && c.st !== 'fly') y -= 5 * s;
    const a = c.k === 'stag' ? 0.92 * c.fade : c.k === 'spirit' ? 0.9 : 1;
    if (c.k === 'stag' || c.k === 'spirit' || c.k === 'moth') { ctx.globalCompositeOperation = 'source-over'; }
    drawHDFrame(k, c.f, q[0], y, c.face < 0, sc, shadeFor(c.x, c.y - 6, c.k === 'stag' || c.k === 'spirit' || c.k === 'moth' || c.k === 'fish'), a);
  }
  ctx.restore();
}
