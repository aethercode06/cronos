// ================= ILUMINACIÓN AVANZADA + MUNDO AÚN MÁS VIVO =================
// 1) Registro de luces: los personajes y objetos HD se iluminan con las luces cercanas.
// 2) Enjambres de luciérnagas/chispas que iluminan y se dispersan.
// 3) Criaturas gigantes en el cielo y eventos ambientales por mundo.
// 4) Rayos de luz, focos, cáusticas y resplandores para cada mundo.
let LIGHTS = [];
let liveSeed = 0;
const WCOL = ['255,210,90', '255,170,90', '255,140,50', '255,150,200', '150,160,255', '190,235,255', '110,160,255', '255,200,110', '110,255,240', '255,200,120', '255,250,220', '255,120,255', '150,255,130', '140,180,255', '210,150,255', '170,255,220', '255,200,120', '160,180,255'];
const _lightAtBase = lightAt;
lightAt = function (x, y, r, color, a) {
  if (!glOK || r <= 0) return;
  const t = lx.getTransform();
  LIGHTS.push({ x: x + t.e + camR.x, y: y + t.f + camR.y, r, c: parseCol(color), a: a === undefined ? 1 : a });
  _lightAtBase(x, y, r, color, a);
};
const _setupLightBase = setupLight;
setupLight = function () { LIGHTS.length = 0; _setupLightBase(); };
const COLC = {};
function parseCol(s) {
  if (COLC[s]) return COLC[s];
  let r = 1, g = 1, b = 1, m;
  if ((m = /rgba?\(([\d.]+),\s*([\d.]+),\s*([\d.]+)/.exec(s))) { r = +m[1] / 255; g = +m[2] / 255; b = +m[3] / 255; }
  else if (s[0] === '#') { const n = parseInt(s.slice(1), 16); r = (n >> 16) / 255; g = ((n >> 8) & 255) / 255; b = (n & 255) / 255; }
  return (COLC[s] = [r, g, b]);
}
// nivel de luz en un punto del mundo (aprox. lo que hace el shader: escena * luz * 2)
function lightLevelAt(x, y) {
  const A = parseCol(LOOK[curWorld].amb);
  let r = A[0] * 2, g = A[1] * 2, b = A[2] * 2, lr = 0, lg = 0, lb = 0;
  for (const L of LIGHTS) {
    const dx = L.x - x, dy = L.y - y, d2 = dx * dx + dy * dy; if (d2 > L.r * L.r) continue;
    const f = (1 - Math.sqrt(d2) / L.r) * L.a * 2;
    lr += L.c[0] * f; lg += L.c[1] * f; lb += L.c[2] * f;
  }
  return { r: Math.min(1.35, r + lr), g: Math.min(1.35, g + lg), b: Math.min(1.35, b + lb), lr, lg, lb };
}
// sombreado de un sprite HD: oscurece según el ambiente y añade el color de las luces cercanas
const SHADE_PAL = ['rgb(255,235,190)', 'rgb(255,175,80)', 'rgb(120,230,255)', 'rgb(255,140,220)', 'rgb(180,150,255)', 'rgb(140,255,200)', 'rgb(255,90,60)'];
function hdShade(x, y, emissive) {
  if (!glOK) return null;
  const L = lightLevelAt(x, y), lum = (L.r + L.g + L.b) / 3;
  const dark = clamp((1.02 - lum) * (emissive ? 0.35 : 0.95), 0, 0.62);
  const ls = Math.max(L.lr, L.lg, L.lb), la = clamp(ls * 0.22, 0, 0.42);
  let lc = null;
  if (la > 0.03) { let best = 1e9; for (const P of SHADE_PAL) { const c = parseCol(P), d = (c[0] - L.lr / ls) ** 2 + (c[1] - L.lg / ls) ** 2 + (c[2] - L.lb / ls) ** 2; if (d < best) { best = d; lc = P; } } }
  const A = parseCol(LOOK[curWorld].amb), dc = 'rgb(' + (A[0] * 40 | 0) + ',' + (A[1] * 34 | 0) + ',' + (A[2] * 60 | 0) + ')';
  return { lit: true, dark: Math.round(dark * 20) / 20, dc, la: Math.round(la * 20) / 20, lc };
}
// dibuja un fotograma HD con sombreado (usa la caché de tintes de hd.js)
function drawHDLit(k, f, x, y, fl, sc, sh, alpha) {
  const a = alpha === undefined ? 1 : alpha;
  if (!sh) { drawHDFrame(k, f, x, y, fl, sc, 'rgba(' + LOOK[curWorld].fog + ',.08)', a); return; }
  drawHDFrame(k, f, x, y, fl, sc, null, a);
  if (sh.dark > 0) drawHDFrame(k, f, x, y, fl, sc, sh.dc, a * sh.dark);
  if (sh.lc && sh.la > 0) { ctx.globalCompositeOperation = 'lighter'; drawHDFrame(k, f, x, y, fl, sc, sh.lc, a * sh.la); ctx.globalCompositeOperation = 'source-over'; }
}

// ---------------- enjambres de luz ----------------
let swarms = [];
const SWARM_C = ['255,220,110', '255,190,110', '255,150,60', '255,170,220', '170,140,255', '220,245,255', '255,90,60', '255,210,120', '120,255,230', '255,220,150', '255,255,235', '255,130,255', '170,255,140', '150,190,255', '210,160,255', '190,255,220', '255,210,140', '170,190,255'];
function spawnSwarms() {
  swarms = [];
  if (!level || !level.plats) return;
  const r = seeded(curWorld * 31 + curAct * 7 + liveSeed);
  for (const s of level.plats) {
    if (s.k !== 'solid' || s.float || s.w < 180 || r() > 0.55) continue;
    if (level.arena && s.x > level.arena.x1 - 100) continue;
    const cx = s.x + 40 + r() * (s.w - 80), cy = s.y - 26 - r() * 50, n = 9 + Math.floor(r() * 8), f = [];
    for (let i = 0; i < n; i++) f.push({ ox: rnd(-30, 30), oy: rnd(-18, 18), x: cx, y: cy, vx: 0, vy: 0, ph: Math.random() * 6, sp: rnd(.6, 1.4) });
    swarms.push({ x: cx, y: cy, f, scat: 0 });
  }
}
function updateSwarms(dt) {
  const px = p.x + p.w / 2, py = p.y + p.h / 2;
  for (const S of swarms) {
    if (Math.abs(S.x - px) > VW * 1.2) continue;
    const d = Math.hypot(S.x - px, S.y - py);
    if (d < 70 && (Math.abs(p.vx) > 60 || p.atkT > 0 || p.dashT > 0)) S.scat = 1.6;
    S.scat = Math.max(0, S.scat - dt);
    for (const q of S.f) {
      const t = time * q.sp + q.ph;
      let tx = S.x + q.ox + Math.sin(t * 1.3) * 14, ty = S.y + q.oy + Math.cos(t * 1.7) * 9;
      if (S.scat > 0) { const ax = q.x - px, ay = q.y - py, l = Math.hypot(ax, ay) || 1; tx = q.x + ax / l * 60; ty = q.y + ay / l * 40 - 20; }
      q.vx += ((tx - q.x) * 3 - q.vx * 2.2) * dt; q.vy += ((ty - q.y) * 3 - q.vy * 2.2) * dt;
      q.x += q.vx * dt; q.y += q.vy * dt;
    }
  }
}
function drawSwarms() {
  const c = SWARM_C[curWorld];
  for (const S of swarms) {
    if (!onScreen(S.x - 60, 120)) continue;
    let mx = 0, my = 0, n = 0;
    for (const q of S.f) {
      const b = 0.5 + 0.5 * Math.sin(time * 4 * q.sp + q.ph * 3); if (b < 0.15) continue;
      bx.fillStyle = 'rgba(' + c + ',' + (0.6 + b * 0.4) + ')'; bx.fillRect(Math.round(q.x), Math.round(q.y), 1, 1);
      glowAt(q.x, q.y, 5 + b * 3, 'rgba(' + c + ',.7)', b * 0.7); mx += q.x; my += q.y; n++;
    }
    if (n) lightAt(mx / n, my / n, 70, 'rgba(' + c + ',1)', 0.22);
  }
}

// ---------------- gigantes del cielo ----------------
const GIANT_OF = [[1], [5], [7, 1], [7], [5], [1], [7, 1], [1], [2, 3, 0], [7], [1, 7], [3, 0, 1], [5], [1], [], [5], [], [1]];
let giants = [], giantEvent = null;
function spawnGiants() {
  giants = [];
  const list = GIANT_OF[curWorld] || [0];
  list.forEach((g, i) => giants.push({ g, x: Math.random() * 800, y: 30 + i * 45 + Math.random() * 30, sp: (Math.random() < .5 ? -1 : 1) * rnd(6, 12), par: 0.06 + i * 0.03, ph: Math.random() * 6, s: 0.32 + Math.random() * 0.14 }));
}
function drawGiant(G, near) {
  const k = 'GI_' + G.g, im = SPR[k]; if (!im || !im.width) return;
  const m = META[k], s = G.s, w = m.fw * s, h = m.fh * s, span = VW + w + 200;
  let x = ((G.x + time * G.sp - cam.x * G.par) % span + span) % span - w - 100;
  const y = G.y + Math.sin(time * 0.4 + G.ph) * 8 - (cam.y - 200) * G.par * 0.5;
  bx.save(); bx.translate(Math.round(x + w / 2), Math.round(y + h / 2)); if (G.sp < 0) bx.scale(-1, 1);
  bx.rotate(Math.sin(time * 0.5 + G.ph) * 0.03); bx.scale(1, 1 + Math.sin(time * 1.1 + G.ph) * 0.02);
  bx.imageSmoothingEnabled = true;
  bx.globalAlpha = near ? 0.7 : 0.42; bx.drawImage(im, -w / 2, -h / 2, w, h);
  // la atmósfera lo empuja hacia el fondo
  bx.globalAlpha = near ? 0.25 : 0.5; bx.drawImage(darkened(k, 'rgb(' + LOOK[curWorld].fog + ')'), -w / 2, -h / 2, w, h);
  bx.globalAlpha = 1; bx.imageSmoothingEnabled = false; bx.restore();
  if (G.g === 3 || G.g === 7) glowAt(x + w / 2, y + h / 2, w * 0.5, G.g === 7 ? 'rgba(255,140,50,.35)' : 'rgba(150,230,255,.3)', .5);
}
function drawGiants() {
  if (!level || state === 'cutscene') return;
  for (const G of giants) drawGiant(G, false);
  if (giantEvent) drawGiant(giantEvent, true);
}

// ---------------- eventos ambientales ----------------
let ambEvT = 12, ambEv = null, stars = [];
const EV_OF = [['flock', 'gust', 'giant'], ['flock', 'lightning', 'ghosts', 'giant'], ['embers', 'giant', 'quake'], ['stars', 'flock', 'giant'], ['ghosts', 'lightning', 'giant'], ['stars', 'gust', 'giant'], ['embers', 'quake', 'giant'], ['chime', 'flock', 'giant'], ['bubbles', 'giant', 'flock'], ['gust', 'stars', 'giant'], ['stars', 'flock', 'giant'], ['stars', 'chime', 'giant'], ['ghosts', 'lightning', 'giant'], ['embers', 'lightning', 'quake', 'giant'], ['chime', 'quake', 'embers'], ['ghosts', 'flock', 'giant'], ['chime', 'ghosts', 'blackout'], ['lightning', 'gust', 'giant', 'lightning']];
function startAmbEvent() {
  const list = EV_OF[curWorld] || ['flock'], k = list[Math.floor(Math.random() * list.length)];
  ambEv = { k, t: 0, d: 6 };
  if (k === 'flock') { ambEv.birds = []; const dir = Math.random() < .5 ? 1 : -1, y = rnd(30, 90); const kind = SPR.LC_bird && [0, 3, 5, 7, 8, 9, 10].includes(curWorld) ? 'bird' : 'moth'; for (let i = 0; i < 9; i++) ambEv.birds.push({ x: dir > 0 ? -40 - Math.abs(i - 4) * 14 : VW + 40 + Math.abs(i - 4) * 14, y: y + Math.abs(i - 4) * 7 + i * 1.5, dir, ph: Math.random() * 6, kind }); ambEv.d = (VW + 200) / 90; }
  else if (k === 'giant') { const g = (GIANT_OF[curWorld] || [0])[0]; giantEvent = { g, x: -time * 34, y: rnd(10, 40), sp: 34, par: 0.0, ph: 0, s: 1.15 }; ambEv.d = (VW + (META['GI_' + g] || { fw: 200 }).fw * 1.15 + 200) / 34; if (Math.random() < .5) tSay(['¡Mira arriba, Kael!', 'Qué criatura tan enorme…', 'Nunca había visto algo así.'][Math.floor(Math.random() * 3)], 2.6); }
  else if (k === 'stars') { stars = []; ambEv.d = 4; }
  else if (k === 'gust') { gust = 1; ambEv.d = 3; sfx('wind', .3, 1); }
  else if (k === 'lightning') { lightning = 0.6; sfx('boom', .25, .6); ambEv.d = 1; }
  else if (k === 'quake') { shake = Math.max(shake, 4); sfx('boom', .3, .5); ambEv.d = 1.5; for (let i = 0; i < 30; i++) parts.push({ x: cam.x + Math.random() * VW, y: cam.y + rnd(-10, 40), vx: 0, vy: rnd(40, 120), life: 1.5, max: 1.5, c: '#806050', s: 2, g: 300 }); }
  else if (k === 'chime') { sfx('gem', .25, .5); sfx('gem', .2, .75); ambEv.d = 2.5; }
  else if (k === 'blackout') { ambEv.d = 1.6; sfx('click', .3, .6); }
  else if (k === 'ghosts') { ambEv.g = []; for (let i = 0; i < 5; i++) ambEv.g.push({ x: VW + 30 + i * 40, y: rnd(60, 140), ph: Math.random() * 6 }); ambEv.d = 9; }
  else if (k === 'embers' || k === 'bubbles') ambEv.d = 5;
}
function updateAmbEvents(dt) {
  if (!level || state !== 'playing' || boss) return;
  ambEvT -= dt; if (!ambEv && ambEvT <= 0) { ambEvT = rnd(18, 34); startAmbEvent(); }
  if (!ambEv) return;
  const E = ambEv; E.t += dt;
  if (E.k === 'flock') for (const b of E.birds) { b.x += b.dir * 90 * dt; b.y += Math.sin(time * 2 + b.ph) * 6 * dt; }
  if (E.k === 'stars' && Math.random() < dt * 3) stars.push({ x: rnd(0, VW), y: rnd(0, VH * 0.4), vx: rnd(-160, -260), vy: rnd(60, 110), life: 0.8 });
  for (const s of stars) { s.x += s.vx * dt; s.y += s.vy * dt; s.life -= dt; } stars = stars.filter(s => s.life > 0);
  if (E.k === 'embers' && Math.random() < dt * 30) parts.push({ x: cam.x + Math.random() * VW, y: cam.y + VH + 4, vx: rnd(-20, 20), vy: -rnd(40, 90), life: 3, max: 3, c: Math.random() < .5 ? '#ffb040' : '#ff5a20', s: 1, g: -6 });
  if (E.k === 'bubbles' && Math.random() < dt * 25) parts.push({ x: cam.x + rnd(0, VW), y: cam.y + VH + 4, vx: rnd(-6, 6), vy: -rnd(50, 90), life: 4, max: 4, c: '#cfffff', s: Math.random() < .3 ? 2 : 1, g: -4 });
  if (E.k === 'gust' && Math.random() < dt * 40) { const lc = ['#7dea5a', '#8a7a60', '#ff9040', '#ffb0d0', '#a090b0', '#ffffff', '#ff8a30', '#ffd34d', '#bff4ff', '#e8c890', '#ffffff', '#ff9ad8', '#6a8a50', '#a0a8c8', '#d0a0ff', '#c8e0d0', '#e0c090', '#a8b8e8'][curWorld] || '#9be35a'; parts.push({ x: cam.x - 4, y: cam.y + rnd(0, VH * .8), vx: rnd(160, 260), vy: rnd(-20, 30), life: 2.5, max: 2.5, c: lc, s: 2, g: 10, lf: [0, 3, 2, 9].includes(curWorld) ? 1 : 0 }); }
  if (E.k === 'ghosts') for (const g of E.g) g.x -= 28 * dt;
  if (E.k === 'giant' && giantEvent) giantEvent.x += 0;
  if (E.t > E.d) { if (E.k === 'giant') giantEvent = null; ambEv = null; }
}
function drawAmbEventsBG() {  // en el búfer del escenario, espacio de pantalla
  if (!ambEv) return;
  const E = ambEv;
  if (E.k === 'blackout') { const on = Math.floor(E.t * 14) % 3 !== 0 || E.t > 1.2; if (!on) { bx.fillStyle = 'rgba(0,0,10,.45)'; bx.fillRect(0, 0, VW + 2, VH + 2); } }
  if (E.k === 'chime') { const a = Math.max(0, 0.18 - E.t * 0.07); bx.fillStyle = 'rgba(255,220,140,' + a + ')'; bx.fillRect(0, 0, VW + 2, VH + 2); }
  if (E.k === 'ghosts') for (const g of E.g) { const x = g.x, y = g.y + Math.sin(time * 2 + g.ph) * 6; bx.globalAlpha = 0.35; if (SPR.LC_spirit) { const m = META.LC_spirit, f = Math.floor(time * 8 + g.ph) % m.n; bx.imageSmoothingEnabled = true; bx.drawImage(flipped('LC_spirit'), (m.n - 1 - f) * m.fw, 0, m.fw, m.fh, x, y, m.fw / 3, m.fh / 3); bx.imageSmoothingEnabled = false; } bx.globalAlpha = 1; }
}
function drawStarsFX() {
  for (const s of stars) { const a = Math.min(1, s.life * 2); bx.strokeStyle = 'rgba(255,255,255,' + a + ')'; bx.lineWidth = 1; bx.beginPath(); bx.moveTo(s.x, s.y); bx.lineTo(s.x - s.vx * 0.08, s.y - s.vy * 0.08); bx.stroke(); glowAt(s.x + cam.x * 0, s.y, 4, 'rgba(255,255,255,.8)', a); }
}
function drawAmbEventsHD() {  // bandadas en alta resolución
  if (!ambEv || ambEv.k !== 'flock') return;
  const s = W / VW * camZoom;
  for (const b of ambEv.birds) {
    const k = 'LC_' + b.kind; if (!SPR[k]) continue; const m = META[k];
    const f = b.kind === 'bird' ? 2 + Math.floor(time * 12 + b.ph) % 6 : Math.floor(time * 14 + b.ph) % 8;
    drawHDFrame(k, f, b.x * s, b.y * s, b.dir < 0, s / 4 * 0.8, 'rgba(' + LOOK[curWorld].fog + ',.25)', 0.9);
  }
}

// ---------------- luz ambiental de cada mundo ----------------
function drawWorldLight() {
  const w = curWorld;
  bx.globalCompositeOperation = 'lighter';
  if (w === -1) { // (antes: focos de neón)
    for (let i = 0; i < 3; i++) {
      const bxp = ((i * 300 - cam.x * 0.2) % (VW + 300) + VW + 300) % (VW + 300) - 100, ang = Math.sin(time * 0.5 + i * 2) * 0.5 - 0.1, c = i % 2 ? '90,230,255' : '255,90,220';
      bx.save(); bx.translate(bxp, VH); bx.rotate(ang);
      const g = bx.createLinearGradient(0, 0, 0, -VH * 1.2); g.addColorStop(0, 'rgba(' + c + ',.16)'); g.addColorStop(1, 'rgba(' + c + ',0)');
      bx.fillStyle = g; bx.beginPath(); bx.moveTo(-6, 0); bx.lineTo(6, 0); bx.lineTo(60, -VH * 1.2); bx.lineTo(-60, -VH * 1.2); bx.fill(); bx.restore();
    }
  } else if (w === 2 || w === 6) { // calor que sube desde abajo
    const a = 0.12 + Math.sin(time * 1.7) * 0.04 + Math.sin(time * 5.3) * 0.02, c = w === 2 ? '255,110,30' : '255,50,30';
    const g = bx.createLinearGradient(0, VH, 0, VH * 0.35); g.addColorStop(0, 'rgba(' + c + ',' + a + ')'); g.addColorStop(1, 'rgba(' + c + ',0)'); bx.fillStyle = g; bx.fillRect(0, 0, VW + 2, VH + 2);
  } else if (w === 5 || w === 11) { // aurora
    for (let i = 0; i < 3; i++) {
      bx.fillStyle = w === 5 ? 'rgba(120,255,200,.035)' : 'rgba(255,110,255,.035)';
      bx.beginPath(); bx.moveTo(0, 0);
      for (let x = 0; x <= VW + 20; x += 20) bx.lineTo(x, 40 + i * 18 + Math.sin(x * 0.01 + time * 0.6 + i) * 22 + Math.sin(x * 0.027 - time * 0.4) * 10);
      bx.lineTo(VW + 20, 0); bx.fill();
    }
  } else if (w === 4 || w === 1 || w === 13) { // luz de luna
    const g = bx.createRadialGradient(VW * 0.78, 30, 0, VW * 0.78, 30, VW * 0.7); g.addColorStop(0, 'rgba(190,170,255,.14)'); g.addColorStop(1, 'rgba(190,170,255,0)'); bx.fillStyle = g; bx.fillRect(0, 0, VW + 2, VH + 2);
  } else if (w === 7) { // pulsos dorados del gran reloj
    const a = Math.max(0, Math.sin(time * Math.PI / 2)) ** 8 * 0.1; bx.fillStyle = 'rgba(255,210,120,' + a + ')'; bx.fillRect(0, 0, VW + 2, VH + 2);
  }
  bx.globalCompositeOperation = 'source-over';
}
// rayos de luz para todos los mundos (amplía drawGodRays)
const _godRaysBase = drawGodRays;
drawGodRays = function () {
  _godRaysBase(); drawWorldLight();
  const w = curWorld; if ([0, 3, 8, 9, 10].includes(w)) return;
  const col = { 12: '170,220,150', 13: '170,190,255', 14: '200,150,255', 15: '180,230,210', 16: '255,200,120', 17: '150,170,255', 1: '170,190,230', 2: '255,150,80', 4: '200,180,255', 5: '210,240,255', 6: '255,90,60', 7: '255,210,140', 11: '255,140,255' }[w]; if (!col) return;
  bx.globalCompositeOperation = 'lighter';
  for (let i = 0; i < 3; i++) {
    const x = ((i * 420 - cam.x * 0.3) % (VW + 400) + VW + 400) % (VW + 400) - 200, a = 0.035 + Math.sin(time * .45 + i * 2) * 0.02;
    const g = bx.createLinearGradient(x, 0, x + 140, VH); g.addColorStop(0, 'rgba(' + col + ',' + a + ')'); g.addColorStop(1, 'rgba(' + col + ',0)');
    bx.fillStyle = g; bx.beginPath(); bx.moveTo(x, 0); bx.lineTo(x + 70, 0); bx.lineTo(x + 220, VH); bx.lineTo(x + 120, VH); bx.fill();
  }
  bx.globalCompositeOperation = 'source-over';
  drawStarsFX();
};
// cáusticas del océano y luz extra en el mapa de iluminación
function extraLights() {
  if (!glOK) return;
  if (curWorld === 8) for (let i = 0; i < 10; i++) { const x = cam.x + ((i * 97 + time * 18 * (i % 2 ? 1 : -1)) % (VW + 100) + VW + 100) % (VW + 100) - 50, y = cam.y + 20 + (i * 37) % 120 + Math.sin(time + i) * 10; lightAt(x, y, 50 + (i % 3) * 15, 'rgba(140,255,255,1)', 0.12 + Math.sin(time * 2 + i) * 0.05); }
  // las gemas brillan de verdad
  for (const g of level.gems) if (!g.taken && onScreen(g.x - 20, 40)) lightAt(g.x, g.y, 34, 'rgba(255,120,220,1)', 0.18);
  // destello del tajo de espada
  if (p && p.atkT > 0) lightAt(p.x + p.w / 2 + p.face * 26, p.y + 20, 90, 'rgba(255,240,200,1)', p.atkT * 1.4);
  if (p && p.dashT > 0) lightAt(p.x + p.w / 2, p.y + 24, 80, 'rgba(255,220,140,1)', 0.35);
}
