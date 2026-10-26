// =====================================================================
//  TERRENO PINTADO, DECORADO Y VIDA AMBIENTAL (arte Higgsfield)
// =====================================================================
function paintedOK(w) { const t = SPR['tx' + w], e = SPR['ed' + w]; return !!(t && t.width && e && e.width && META['ed' + w]); }
function seededJag(seed, n) { const r = seeded(seed); const a = []; for (let i = 0; i < n; i++) a.push(r()); return a; }
// Bloque de terreno pintado: textura + borde superior + sombreado + silueta irregular
function paintBlock(w, wid, hgt, opt) {
  opt = opt || {};
  const T = SPR['tx' + w], E = SPR['ed' + w], em = META['ed' + w];
  const top = em.gy + 3, below = opt.float ? 26 : 0, pad = 6;
  const cw = wid + pad * 2, ch = hgt + top + below + (opt.ceil ? em.fh : 0);
  const [c, x] = qmkT(cw, ch);
  x.imageSmoothingEnabled = true;
  const by = top, bh = hgt + below;
  // silueta
  x.save(); x.beginPath();
  if (opt.float) {
    const j = seededJag(Math.round(opt.seed || 7), 24), n = Math.max(4, Math.round(wid / 14));
    x.moveTo(pad - 2, by); x.lineTo(pad + wid + 2, by);
    for (let i = n; i >= 0; i--) { const t = i / n, xx = pad + t * wid, mid = 1 - Math.abs(t - 0.5) * 2; x.lineTo(xx, by + 10 + mid * (bh - 8) * (0.55 + j[i % 24] * 0.45)); }
  } else {
    const j = seededJag(Math.round(opt.seed || 3), 40);
    x.moveTo(pad, by); x.lineTo(pad + wid, by);
    for (let yy = by; yy <= by + bh; yy += 14) x.lineTo(pad + wid - (opt.pillar ? 0 : j[(yy / 14 | 0) % 40] * 3), yy);
    x.lineTo(pad + wid, by + bh); x.lineTo(pad, by + bh);
    for (let yy = by + bh; yy >= by; yy -= 14) x.lineTo(pad + (opt.pillar ? 0 : j[(yy / 14 + 7 | 0) % 40] * 3), yy);
  }
  x.closePath(); x.clip();
  // textura alineada con el mundo para que los bloques contiguos encajen
  const ox = -(((opt.wx || 0) % T.width) + T.width) % T.width, oy = -(((opt.wy || 0) % T.height) + T.height) % T.height;
  for (let yy = by + oy; yy < ch; yy += T.height) for (let xx = pad + ox; xx < cw; xx += T.width) x.drawImage(T, xx, yy, T.width + 0.5, T.height + 0.5);
  // sombreado: oclusión bajo el borde, oscurecer hacia abajo y en los lados
  let g = x.createLinearGradient(0, by, 0, by + Math.min(bh, 260)); g.addColorStop(0, 'rgba(0,0,0,.35)'); g.addColorStop(.12, 'rgba(0,0,0,.05)'); g.addColorStop(1, 'rgba(4,2,10,.72)');
  x.fillStyle = g; x.fillRect(0, by, cw, bh);
  g = x.createLinearGradient(pad, 0, pad + 14, 0); g.addColorStop(0, 'rgba(0,0,0,.45)'); g.addColorStop(1, 'rgba(0,0,0,0)'); x.fillStyle = g; x.fillRect(pad, by, 14, bh);
  g = x.createLinearGradient(pad + wid, 0, pad + wid - 14, 0); g.addColorStop(0, 'rgba(0,0,0,.45)'); g.addColorStop(1, 'rgba(0,0,0,0)'); x.fillStyle = g; x.fillRect(pad + wid - 14, by, 14, bh);
  x.restore();
  // borde superior en mosaico (sobresale un poco por los lados)
  const sx0 = -(((opt.wx || 0) % em.fw) + em.fw) % em.fw;
  x.save(); x.beginPath(); x.rect(0, 0, cw, ch); x.clip();
  for (let xx = pad - 4 + sx0; xx < pad + wid + 4; xx += em.fw) {
    const cl = Math.max(xx, pad - 4), cr = Math.min(xx + em.fw, pad + wid + 4);
    if (cr > cl) x.drawImage(E, cl - xx, 0, cr - cl, em.fh, cl, 0, cr - cl, em.fh);
  }
  // borde inferior para techos (invertido)
  if (opt.ceil) { x.save(); x.translate(0, ch); x.scale(1, -1); for (let xx = pad + sx0; xx < pad + wid; xx += em.fw) { const cl = Math.max(xx, pad), cr = Math.min(xx + em.fw, pad + wid); if (cr > cl) x.drawImage(E, cl - xx, 0, cr - cl, em.fh, cl, 0, cr - cl, em.fh); } x.restore(); }
  x.restore();
  return { c, ox: -pad, oy: -top, w: cw, h: ch };
}
function renderPlat2(s, w) {
  return paintBlock(w, s.w, s.float ? 18 : Math.min(s.h, 320), { float: s.float, pillar: s.pillar, ceil: s.ceil, wx: s.x, wy: s.y, seed: s.x * 7 + s.y });
}
const BLK = {};
function blockFor(w, wid, kind) {
  const id = w + '_' + wid + '_' + kind; if (BLK[id]) return BLK[id];
  return (BLK[id] = paintBlock(w, wid, 14, { float: true, seed: wid * 13 + (kind === 'move' ? 5 : 1) }));
}
function drawPainted(s) {
  const P = s.cache2, h = Math.min(P.h, Math.max(0, cam.y + VH + 40 - (s.y + P.oy)));
  if (h > 0) bx.drawImage(P.c, 0, 0, P.w, h, s.x + P.ox, s.y + P.oy, P.w, h);
  const bodyBottom = s.y + P.oy + P.h;
  if (!s.float && !s.ceil && s.y + s.h > bodyBottom && cam.y + VH > bodyBottom) { bx.fillStyle = 'rgba(4,2,10,.92)'; bx.fillRect(s.x, bodyBottom - 1, s.w, s.y + s.h - bodyBottom + 1); }
}
// Decorado generado por mundo
function worldProps(w) { const m = META['props' + w]; if (!m) return null; const a = []; for (let i = 0; i < m.n; i++) if (SPR['pr' + w + '_' + i]) a.push('pr' + w + '_' + i); return a.length ? a : null; }
// Siluetas en primer plano con el decorado del propio mundo
function fgKeys(w) { const a = worldProps(w); if (!a) return null; return a.slice().sort((p, q) => meta(q).fh - meta(p).fh).slice(0, 2); }

// ---------------- Vida ambiental extra por mundo ----------------
let life = [];
function spawnLife() {
  life = [];
  const w = curWorld, kinds = [['butterfly', 'bird'], ['bat', 'ember'], ['ember', 'ash'], ['firefly', 'petal'], ['bat', 'wisp'], ['flake', 'flake'], ['ember', 'soul'], ['spark', 'gearbit'], ['fish', 'bubble'], ['dust', 'beetle'], ['feather', 'bird'], ['shard', 'wisp'], ['firefly', 'wisp'], ['ember', 'soul']][w] || ['firefly', 'firefly'];
  for (let i = 0; i < 28; i++) life.push({ k: kinds[i % 2], x: Math.random() * level.width, y: 120 + Math.random() * 340, t: Math.random() * 10, vx: rnd(-30, 30), vy: 0, ph: Math.random() * 6 });
}
function updateLife(dt) {
  for (const a of life) {
    a.t += dt;
    if (Math.abs(a.x - (cam.x + VW / 2)) > VW * 1.6) { a.x = cam.x + VW / 2 + (Math.random() < .5 ? -1 : 1) * rnd(VW * .6, VW * 1.4); a.y = cam.y + rnd(20, VH - 40); }
    const k = a.k;
    if (k === 'butterfly' || k === 'petal' || k === 'feather') { a.x += (Math.sin(a.t * 0.7 + a.ph) * 25 + 10) * dt; a.y += Math.sin(a.t * 2.3 + a.ph) * 22 * dt + (k === 'petal' || k === 'feather' ? 12 * dt : 0); }
    else if (k === 'bird' || k === 'bat' || k === 'fish') { a.x += (a.vx > 0 ? 1 : -1) * (k === 'fish' ? 40 : 70) * dt; a.y += Math.sin(a.t * 3 + a.ph) * 10 * dt; }
    else if (k === 'ember' || k === 'soul' || k === 'spark' || k === 'bubble' || k === 'wisp' || k === 'shard') { a.y -= (k === 'bubble' ? 30 : 18) * dt; a.x += Math.sin(a.t * 1.5 + a.ph) * 12 * dt; if (a.y < cam.y - 20) a.y = cam.y + VH + 10; }
    else if (k === 'flake' || k === 'ash' || k === 'dust') { a.y += 16 * dt; a.x += (k === 'dust' ? 40 : Math.sin(a.t + a.ph) * 10) * dt; if (a.y > cam.y + VH + 10) a.y = cam.y - 10; }
    else { a.x += Math.sin(a.t * .9 + a.ph) * 20 * dt; a.y += Math.cos(a.t * 1.3 + a.ph) * 14 * dt; }
    // se alejan del jugador
    const dx = a.x - (p.x + p.w / 2), dy = a.y - (p.y + 20); if (dx * dx + dy * dy < 3600 && k !== 'ember' && k !== 'flake') { a.x += Math.sign(dx || 1) * 90 * dt; a.y -= 50 * dt; }
  }
}
function drawLife() {
  for (const a of life) {
    if (!onScreen(a.x - 6, 12)) continue;
    const x = Math.round(a.x), y = Math.round(a.y), k = a.k, f = Math.floor(a.t * 10 + a.ph) % 2;
    if (k === 'butterfly') { const c = a.ph > 3 ? '#ffd34d' : '#7fe9ff'; bx.fillStyle = c; bx.fillRect(x - 2 - f, y - 1, 2, 2 + f); bx.fillRect(x + 1 + f, y - 1, 2, 2 + f); bx.fillStyle = '#2a1a10'; bx.fillRect(x, y - 1, 1, 3); }
    else if (k === 'bird' || k === 'bat') { bx.fillStyle = k === 'bat' ? '#1a1024' : '#2a3a3a'; bx.fillRect(x - 1, y, 3, 1); bx.fillRect(x - 3, y - f, 2, 1); bx.fillRect(x + 2, y - f, 2, 1); }
    else if (k === 'fish') { bx.fillStyle = a.ph > 3 ? '#ff9ad8' : '#7fe9ff'; bx.fillRect(x, y, 5, 2); bx.fillRect(x + (a.vx > 0 ? -2 : 5), y - 1 + f, 2, 2); glowAt(x + 2, y + 1, 6, 'rgba(120,240,255,.35)', .5); }
    else if (k === 'firefly' || k === 'wisp' || k === 'soul') { const c = k === 'soul' ? 'rgba(120,200,255,.8)' : k === 'wisp' ? 'rgba(220,150,255,.8)' : 'rgba(255,230,120,.9)'; if (Math.sin(a.t * 3 + a.ph) > -0.3) { bx.fillStyle = c; bx.fillRect(x, y, 2, 2); glowAt(x + 1, y + 1, 10, c, .6); } }
    else if (k === 'ember' || k === 'spark' || k === 'shard') { bx.fillStyle = k === 'shard' ? '#ff6ad5' : k === 'spark' ? '#7fe9ff' : (f ? '#ffd040' : '#ff7a2a'); bx.fillRect(x, y, 2, 2); glowAt(x + 1, y + 1, 6, k === 'shard' ? 'rgba(255,100,220,.5)' : k === 'spark' ? 'rgba(100,230,255,.5)' : 'rgba(255,140,40,.5)', .5); }
    else if (k === 'bubble') { bx.strokeStyle = 'rgba(210,255,255,.6)'; bx.lineWidth = 1; bx.beginPath(); bx.arc(x, y, 2 + (a.ph > 3 ? 1 : 0), 0, 6.3); bx.stroke(); }
    else if (k === 'flake') { bx.fillStyle = '#ffffff'; bx.fillRect(x, y, 2, 2); }
    else if (k === 'ash' || k === 'dust') { bx.fillStyle = k === 'dust' ? 'rgba(255,220,150,.6)' : 'rgba(80,70,70,.7)'; bx.fillRect(x, y, 2, 1); }
    else if (k === 'petal') { bx.fillStyle = '#ffb0d0'; bx.fillRect(x, y, 2 + f, 2); }
    else if (k === 'feather') { bx.fillStyle = '#ffffff'; bx.fillRect(x, y, 1, 4); bx.fillStyle = '#ffe9a0'; bx.fillRect(x + 1, y + 1, 1, 2); }
    else if (k === 'beetle') { bx.fillStyle = '#ffc24a'; bx.fillRect(x, y, 3, 2); }
    else if (k === 'gearbit') { bx.fillStyle = '#ffd34d'; bx.fillRect(x, y, 2, 2); bx.fillRect(x - 1, y + 1, 4, 0.5); }
    else if (k === 'drone') { bx.fillStyle = '#2a2850'; bx.fillRect(x - 3, y, 6, 2); bx.fillStyle = f ? '#ff3d5a' : '#35e2ff'; bx.fillRect(x, y + 2, 1, 1); glowAt(x, y + 2, 6, 'rgba(255,80,120,.5)', .5); }
  }
}
// Rayos de luz volumétricos en primer plano (mundos luminosos)
function drawGodRays() {
  const w = curWorld; if (![0, 3, 8, 9, 10].includes(w)) return;
  const col = w === 8 ? '170,255,255' : w === 3 ? '255,190,160' : w === 9 ? '255,220,150' : '255,245,200';
  bx.globalCompositeOperation = 'lighter';
  for (let i = 0; i < 3; i++) {
    const x = ((i * 380 - cam.x * 0.35) % (VW + 400) + VW + 400) % (VW + 400) - 200, a = 0.05 + Math.sin(time * .5 + i * 2) * 0.025;
    const g = bx.createLinearGradient(x, 0, x + 140, VH); g.addColorStop(0, 'rgba(' + col + ',' + a + ')'); g.addColorStop(1, 'rgba(' + col + ',0)');
    bx.fillStyle = g; bx.beginPath(); bx.moveTo(x, 0); bx.lineTo(x + 60, 0); bx.lineTo(x + 200, VH); bx.lineTo(x + 110, VH); bx.fill();
  }
  bx.globalCompositeOperation = 'source-over';
}
