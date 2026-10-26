// =====================================================================
//  DIBUJO: fondos, mundo, personajes, efectos
// =====================================================================
function hexToRgba(h, a) { const n = parseInt(h.slice(1), 16); return 'rgba(' + (n >> 16) + ',' + ((n >> 8) & 255) + ',' + (n & 255) + ',' + a + ')'; }
function tileH(img, par, y, scale, offx) {
  if (!img) return;
  const s = scale || 1, w = img.width * s, h = img.height * s;
  let x = -Math.round(((cam.x * par + (offx || 0)) % w + w) % w);
  for (; x < VW; x += w) bx.drawImage(img, x, Math.round(y), w, h);
}
let darkCache = {};
function darkened(k, col) {
  const id = k + col; if (darkCache[id]) return darkCache[id];
  const im = SPR[k], [c, x] = dmk(im);
  x.drawImage(im, 0, 0); x.globalCompositeOperation = 'source-atop'; x.fillStyle = col; x.fillRect(0, 0, c.width, c.height);
  return (darkCache[id] = c);
}
function drawBG() {
  const n = WORLDS[curWorld].bg, vy = cam.y, big = VH > 400;
  if (n >= 8) { drawBGNew(n); drawWeather(true); edgeFill(); return; }
  bx.fillStyle = '#000'; bx.fillRect(0, 0, VW + 2, VH + 2);
  const painted = paintBG(n, 0.05);
  if (n === 0) {
    const back = SPR.bg_j_back, s = big ? 3 : 2;
    if (!painted) { bx.fillStyle = '#6ad6f0'; bx.fillRect(0, 0, VW, VH); tileH(back, 0.08, VH - back.height * s + 40 - (vy - 180) * 0.05, s); }
    if (painted) { bx.globalAlpha = .55; tileH(SPR.bg_j_mid, 0.25, VH - 230 - (vy - 180) * 0.2, 1, 60); bx.globalAlpha = 1; }
    else {
    tileH(SPR.bg_j_mid, 0.3, VH - 300 - (vy - 180) * 0.25, 1, 60);
    const ny = VH - 190 - (vy - 180) * 0.45;
    tileH(darkened('bg_j_mid', 'rgba(8,40,36,.62)'), 0.55, ny, 1, 140);
    bx.fillStyle = '#123a33'; if (ny + 368 < VH) bx.fillRect(0, ny + 368, VW, VH); }
  } else if (n === 1) { if (painted) { /* Velmora: fondo pintado */ } else {
    const sky = SPR['bg_c_skyline-a'], s = big ? 3 : 2;
    if (!painted) { bx.fillStyle = '#0b0a24'; bx.fillRect(0, 0, VW, VH); tileH(sky, 0.02, VH - sky.height * s + 60, s); }
    for (const c of cars) { const im = SPR[c.k], w = im.width * c.sc, h = im.height * c.sc; if (c.vx < 0) bx.drawImage(im, Math.round(c.x), Math.round(c.y), w, h); else { bx.save(); bx.translate(Math.round(c.x + w), Math.round(c.y)); bx.scale(-1, 1); bx.drawImage(im, 0, 0, w, h); bx.restore(); } glowAt(c.x + (c.vx > 0 ? w : 0), c.y + h * .6, 10, 'rgba(255,240,180,.6)', .7); }
    tileH(SPR['bg_c_buildings-bg'], 0.15, VH - 248 - (vy - 180) * 0.1 + 10, 2);
    tileH(SPR['bg_c_near-buildings-bg'], 0.4, VH - 209 - (vy - 180) * 0.3 + 40, 1);
    }
  } else if (n === 2) {
    const k = clamp((vy + 1000) / 1700, 0, 1);
    if (!painted) { bx.drawImage(SPR.bg_v_sky, 0, 0, VW, VH); tileH(SPR.bg_v_far, 0.06, VH - 200 + 30 + (1 - k) * -10, 1); }
    tileH(SPR.bg_v_mid, 0.18, VH - 200 + 50 - (k - .5) * 30, 1, 200);
  } else if (n === 3) {
    const s = 2;
    if (!painted) { bx.drawImage(SPR.bg_dusk_bg, 0, 0, VW, VH); tileH(SPR['bg_dusk_montain-far'], 0.05, VH - 160 * s - (vy - 180) * 0.05 + 20, s); tileH(SPR.bg_dusk_mountains, 0.12, VH - 160 * s - (vy - 180) * 0.1 + 50, s); }
    tileH(SPR.bg_dusk_trees, 0.3, VH - 160 * s - (vy - 180) * 0.25 + 70, s);
    tileH(SPR['bg_dusk_foreground-trees'], 0.5, VH - 160 * s - (vy - 180) * 0.4 + 100, s);
    bx.fillStyle = '#1b0c10'; const fy = VH - (vy - 180) * 0.4 + 100 - 2; if (fy < VH) bx.fillRect(0, fy, VW, VH);
  } else if (n === 4) {
    const s = big ? 3 : 2;
    if (!painted) { bx.fillStyle = '#2a0a2a'; bx.fillRect(0, 0, VW, VH); tileH(SPR.bg_cem_sky, 0.03, -(vy - 180) * 0.03 - 20, s); tileH(SPR.bg_cem_mountains, 0.15, VH - 179 * s * .9 - (vy - 180) * 0.12 + 40, s * .9); }
    tileH(SPR.bg_cem_graveyard, 0.35, VH - 123 * 2 - (vy - 180) * 0.3 + 40, 2);
    bx.fillStyle = '#050418'; const gy = VH - (vy - 180) * 0.3 + 38; if (gy < VH) bx.fillRect(0, gy, VW, VH);
    if (lightning > 0 && Math.floor(lightning * 20) % 2 === 0) { bx.fillStyle = 'rgba(220,200,255,.25)'; bx.fillRect(0, 0, VW, VH); }
  } else if (n === 5) {
    if (!painted) { bx.fillStyle = '#0e1a30'; bx.fillRect(0, 0, VW, VH); tileH(SPR.bg_ice_back, 0.03, VH - 384 * (big ? 1.5 : 1) + 20, big ? 1.5 : 1); }
    tileH(SPR.bg_ice_mid1, 0.25, VH - 384 - (vy - 180) * 0.2 + 60, 1);
  } else if (n === 6) {
    if (!painted) { bx.fillStyle = '#1a0606'; bx.fillRect(0, 0, VW, VH); tileH(SPR.bg_inf_back, 0.08, VH - 224 * (big ? 2.4 : 1.7), big ? 2.4 : 1.7); }
    tileH(SPR.bg_inf_pillars, 0.3, VH - 192 - (vy - 180) * 0.25 + 10, 1);
    tileH(SPR.bg_inf_ceiling, 0.4, -40 - (vy - 180) * 0.2, 1);
    glowAt(VW / 2, VH, VW * .8, 'rgba(255,70,20,.45)', .9); glowAt(VW * .2, VH * .3, VW * .3, 'rgba(255,90,40,.15)', .8);
  } else {
    if (!painted) bx.drawImage(SPR.bg_chrono_sky, 0, 0, VW, VH);
    const gears = [[0.05, 120, 80, 1, 'gear_big', .35], [0.1, 520, 260, -1.3, 'gear_big', .3], [0.15, 300, 120, 1.8, 'gear_small', .4], [0.2, 760, 90, -2, 'gear_small', .35]];
    for (const g of gears) {
      const im = SPR[g[4]], w = im.width, x = ((g[1] - cam.x * g[0]) % (VW + w * 2) + VW + w * 2) % (VW + w * 2) - w, y = g[2] - (vy - 180) * g[0];
      bx.save(); bx.globalAlpha = g[5]; bx.translate(Math.round(x + w / 2), Math.round(y + w / 2)); bx.rotate(time * 0.15 * g[3]); bx.drawImage(im, -w / 2, -w / 2); bx.restore();
    }
    // Gran reloj
    const cx = VW * .72 - (cam.x * 0.02) % 40, cy = 120 - (vy - 180) * .05, R = 70;
    bx.globalAlpha = .25; bx.strokeStyle = '#ffd34d'; bx.lineWidth = 3; bx.beginPath(); bx.arc(cx, cy, R, 0, 6.3); bx.stroke();
    for (let i = 0; i < 12; i++) { const a = i / 12 * 6.283; bx.fillStyle = '#ffd34d'; bx.fillRect(Math.round(cx + Math.cos(a) * (R - 8)) - 1, Math.round(cy + Math.sin(a) * (R - 8)) - 1, 3, 3); }
    bx.beginPath(); bx.moveTo(cx, cy); bx.lineTo(cx + Math.cos(time * .3) * 50, cy + Math.sin(time * .3) * 50); bx.moveTo(cx, cy); bx.lineTo(cx + Math.cos(time * 2) * 62, cy + Math.sin(time * 2) * 62); bx.stroke(); bx.globalAlpha = 1;
  }
  drawLivingBG(n);
  drawWeather(true);
  // rellenar el margen de 2px usado por la cámara subpíxel
  edgeFill();
}
function drawLivingBG(n) {
  // Bandadas (pájaros / murciélagos)
  if (n === 0 || n === 3 || n === 4) {
    const per = 16, k = Math.floor(time / per), t = (time % per) / per, dir = k % 2 ? 1 : -1;
    const fx = dir > 0 ? -80 + t * (VW + 160) : VW + 80 - t * (VW + 160), fy = 40 + (k * 53) % 90 + Math.sin(time * .8) * 8;
    bx.fillStyle = n === 4 ? '#140a1c' : n === 3 ? '#3a2030' : '#1f3a3a';
    for (let i = 0; i < 7; i++) {
      const bxp = Math.round(fx - dir * Math.abs(i - 3) * 9), byp = Math.round(fy + Math.abs(i - 3) * 5 + i * .5), up = Math.floor(time * (n === 4 ? 14 : 8) + i) % 2;
      bx.fillRect(bxp - 1, byp, 3, 1); bx.fillRect(bxp - 3, byp - up, 2, 1); bx.fillRect(bxp + 2, byp - up, 2, 1);
    }
  }
  // Aurora boreal
  if (n === 5) {
    bx.globalCompositeOperation = 'lighter';
    const cols = ['rgba(80,255,180,', 'rgba(80,200,255,', 'rgba(170,110,255,'];
    for (let b = 0; b < 3; b++) for (let x = 0; x < VW; x += 3) {
      const y = 40 + b * 18 + Math.sin(x * 0.012 + time * 0.4 + b) * 16 + Math.sin(x * 0.031 - time * 0.6) * 6, h = 30 + Math.sin(x * 0.02 + time + b) * 12;
      const a = (0.06 + 0.05 * Math.sin(x * 0.05 + time * 1.5 + b * 2)) * (1 - Math.abs(x / VW - .5));
      const g = bx.createLinearGradient(0, y, 0, y + h); g.addColorStop(0, cols[b] + '0)'); g.addColorStop(.4, cols[b] + a + ')'); g.addColorStop(1, cols[b] + '0)');
      bx.fillStyle = g; bx.fillRect(x, y, 3, h);
    }
    bx.globalCompositeOperation = 'source-over';
  }
  // Reflectores de la ciudad (sólo sin fondo pintado)
  if (n === 1 && !(SPR.pbg1 && SPR.pbg1.width)) {
    bx.globalCompositeOperation = 'lighter';
    for (let i = 0; i < 2; i++) {
      const ox = VW * (0.25 + i * 0.5) - (cam.x * 0.15) % 80, oy = VH, a = -Math.PI / 2 + Math.sin(time * 0.35 + i * 2) * 0.55;
      const len = VH * 1.3, w = 0.07;
      const g = bx.createLinearGradient(ox, oy, ox + Math.cos(a) * len, oy + Math.sin(a) * len); g.addColorStop(0, 'rgba(140,200,255,.16)'); g.addColorStop(1, 'rgba(140,200,255,0)');
      bx.fillStyle = g; bx.beginPath(); bx.moveTo(ox, oy); bx.lineTo(ox + Math.cos(a - w) * len, oy + Math.sin(a - w) * len); bx.lineTo(ox + Math.cos(a + w) * len, oy + Math.sin(a + w) * len); bx.closePath(); bx.fill();
    }
    bx.globalCompositeOperation = 'source-over';
  }
  // Erupciones volcánicas
  if (n === 2 || n === 6) {
    const craters = n === 2 ? [[0.22, VH - 180], [0.7, VH - 150]] : [[0.5, VH - 40]];
    for (let c = 0; c < craters.length; c++) {
      const per = 6 + c * 1.7, t = (time + c * 2.3) % per;
      if (t < 2.4) {
        const sx = VW * craters[c][0] - (cam.x * 0.06) % 60, sy = craters[c][1];
        if (t < 0.4) glowAt(sx, sy, 40 * (1 - t / 0.4) + 10, 'rgba(255,140,40,.8)', .9);
        for (let i = 0; i < 16; i++) {
          const vx = Math.sin(i * 12.9 + c) * 40, vy = 90 + (i * 37 % 60);
          const x = sx + vx * t, y = sy - vy * t + 70 * t * t;
          if (y > sy + 4) continue;
          bx.fillStyle = i % 3 ? '#ff8a30' : '#ffe070'; bx.fillRect(Math.round(x), Math.round(y), 2, 2);
        }
      }
    }
  }
  // Estrellas fugaces
  if (n === 7 || n === 4 || n === 5) {
    const per = 5.5, t = (time % per), k = Math.floor(time / per);
    if (t < 0.6) {
      const sx = ((k * 211) % VW), sy = 20 + (k * 47) % 80, x = sx + t * 300, y = sy + t * 120;
      bx.globalCompositeOperation = 'lighter';
      const g = bx.createLinearGradient(x - 40, y - 16, x, y); g.addColorStop(0, 'rgba(255,255,255,0)'); g.addColorStop(1, 'rgba(255,255,255,' + (0.8 * (1 - t / 0.6)) + ')');
      bx.strokeStyle = g; bx.lineWidth = 1.5; bx.beginPath(); bx.moveTo(x - 40, y - 16); bx.lineTo(x, y); bx.stroke();
      bx.globalCompositeOperation = 'source-over';
    }
  }
}
const FOGC = {};
function fogTex(rgb) {
  if (FOGC[rgb]) return FOGC[rgb];
  const [c, x] = mkCanvas(512, 120), r = seeded(rgb.length * 977 + 3);
  for (let i = 0; i < 40; i++) {
    const cx = r() * 512, cy = 40 + r() * 50, rr = 30 + r() * 60;
    for (const dx of [-512, 0, 512]) { const g = x.createRadialGradient(cx + dx, cy, 0, cx + dx, cy, rr); g.addColorStop(0, 'rgba(' + rgb + ',.35)'); g.addColorStop(1, 'rgba(' + rgb + ',0)'); x.fillStyle = g; x.fillRect(cx + dx - rr, cy - rr, rr * 2, rr * 2); }
  }
  return (FOGC[rgb] = c);
}
function drawFog(front) {
  const L = LOOK[curWorld], img = fogTex(L.fog), par = front ? 1.35 : 0.65, gy = (level && level.arena && arenaLock ? level.arena.floor : GY) - camR.y;
  const y = Math.round(gy - (front ? 30 : 90)), w = 512 * (front ? 1.6 : 1.2);
  let x = -(((cam.x * par + time * (front ? 12 : 6)) % w) + w) % w;
  bx.globalAlpha = L.fogA * (front ? 0.55 : 1);
  for (; x < VW + 2; x += w) bx.drawImage(img, Math.round(x), y, Math.round(w), front ? 150 : 120);
  bx.globalAlpha = 1;
}
const FGK = [['p_tree', 'p_bush'], null, ['p_rock_v', 'p_spike-skull'], ['p_tree', 'p_bush'], ['gv_tree-1', 'gv_bush-large'], null, ['gvf_statue', 'gvf_stone-1'], null];
const FGC = {};
function fgSpr(k) {
  if (FGC[k]) return FGC[k];
  const im = SPR[k], m = meta(k), s = m.fh > 80 ? 1.35 : 2.4, [c, x] = mkCanvas(m.fw * s + 16, m.fh * s + 16);
  try { x.filter = 'blur(3.5px)'; } catch (e) {}
  x.imageSmoothingEnabled = true; x.drawImage(im, 0, 0, m.fw, m.fh, 8, 8, m.fw * s, m.fh * s); x.filter = 'none';
  x.globalCompositeOperation = 'source-atop'; x.fillStyle = 'rgba(6,5,14,.9)'; x.fillRect(0, 0, c.width, c.height); x.globalCompositeOperation = 'destination-in'; const fg = x.createLinearGradient(0, 0, 0, c.height); fg.addColorStop(0, 'rgba(0,0,0,.75)'); fg.addColorStop(1, 'rgba(0,0,0,.95)'); x.fillStyle = fg; x.fillRect(0, 0, c.width, c.height);
  return (FGC[k] = c);
}
function drawForeground() {
  const ks = fgKeys(curWorld) || FGK[curWorld];
  if (arenaLock || !ks) return;
  const par = 1.45, span = 1100;
  const base = Math.floor(cam.x * par / span) - 1;
  for (let i = base; i < base + 3; i++) {
    const k = ks[((i % 2) + 2) % 2], im = fgSpr(k);
    const x = Math.round(i * span + ((i * 377) % 400) - cam.x * par), y = Math.round(VH - im.height * 0.42 - (cam.y - 180) * 0.25);
    if (x > VW || x + im.width < 0) continue;
    bx.drawImage(im, x, y);
  }
}
function drawWeather(back) {
  const w = WORLDS[curWorld].weather;
  for (const a of amb) {
    const x = (a.x * VW / 960) | 0, y = (a.y * VH / 540) | 0;
    if (w === 'leaves') { if (a.s > 1) { bx.fillStyle = a.ph > 3 ? '#9be35a' : '#5fb04a'; bx.fillRect(x, y, 3, 2); bx.fillRect(x + (Math.sin(time * 4 + a.ph) > 0 ? 1 : -1), y + 1, 2, 1); } else if (Math.sin(time * 2 + a.ph) > .4) { bx.fillStyle = '#ffff9a'; bx.fillRect(x, y, 1, 1); } }
    else if (w === 'rain') { bx.fillStyle = 'rgba(150,200,255,.35)'; bx.fillRect(x, y, 1, 6); }
    else if (w === 'embers') { bx.fillStyle = a.s > 1 ? '#ffd040' : '#ff7a2a'; if (Math.sin(time * 3 + a.ph) > -0.3) bx.fillRect(x, y, a.s, a.s); }
    else if (w === 'fireflies') { if (Math.sin(time * 2 + a.ph) > 0) { bx.fillStyle = '#ffe9a0'; bx.fillRect(x, y, a.s, a.s); if (a.s > 1) glowAt(x, y, 6, 'rgba(255,220,120,.6)', .6); } }
    else if (w === 'fog') { bx.fillStyle = 'rgba(200,170,255,.05)'; bx.fillRect(x - 40, y, 90 + a.s * 30, 14); }
    else if (w === 'snow') { bx.fillStyle = '#ffffff'; bx.fillRect(x, y, a.s, a.s); }
    else if (w === 'bubbles') { bx.strokeStyle = 'rgba(200,255,255,.45)'; bx.lineWidth = 1; if (a.s > 1) { bx.beginPath(); bx.arc(x, y, 2, 0, 6.3); bx.stroke(); } else { bx.fillStyle = 'rgba(200,255,255,.5)'; bx.fillRect(x, y, 1, 1); } }
    else if (w === 'sand') { bx.fillStyle = a.s > 1 ? 'rgba(255,220,150,.7)' : 'rgba(230,180,110,.6)'; bx.fillRect(x, y, a.s + 1, 1); }
    else if (w === 'clouds') { if (a.s > 1) { bx.fillStyle = 'rgba(255,255,255,.08)'; bx.fillRect(x - 30, y, 70, 10); } else if (Math.sin(time * 2 + a.ph) > .5) { bx.fillStyle = '#fff4c0'; bx.fillRect(x, y, 1, 1); } }
    else if (w === 'void') { bx.fillStyle = a.s > 1 ? 'rgba(255,110,220,.7)' : 'rgba(140,230,255,.6)'; bx.fillRect(x, y, a.s, a.s); if (a.s > 1 && Math.sin(time * 3 + a.ph) > .8) glowAt(x, y, 6, 'rgba(255,110,220,.5)', .5); }
    else if (w === 'clocks') { bx.fillStyle = a.s > 1 ? 'rgba(255,211,77,.7)' : 'rgba(200,160,255,.7)'; bx.fillRect(x, y, a.s, a.s); if (a.s > 1 && Math.sin(time + a.ph) > .7) glowAt(x, y, 5, 'rgba(255,211,77,.5)', .5); }
  }
}
function onScreen(x, w) { return x + w > cam.x - 64 && x < cam.x + VW + 64; }
function drawPlat(s) {
  if (!onScreen(s.x, s.w)) return;
  if (s.k === 'solid' && s.cache2) { drawPainted(s); if (s.conv) { const off = Math.floor(time * 40) % 12; bx.fillStyle = '#ffd34d'; for (let x = s.x + (s.conv > 0 ? off : 12 - off); x < s.x + s.w - 4; x += 12) { bx.fillRect(x, s.y + 1, 4, 2); } } return; }
  if (s.k === 'solid') {
    const c = s.cache, h = Math.min(c.height, Math.max(0, cam.y + VH + 16 - s.y));
    if (h > 0) bx.drawImage(c, 0, 0, s.w, h, s.x, s.y, s.w, h);
    if (!s.float && s.h > c.height && cam.y + VH > s.y + c.height) { bx.fillStyle = '#000'; bx.globalAlpha = 0.6; bx.fillRect(s.x, s.y + c.height, s.w, s.h - c.height); bx.globalAlpha = 1; }
    if (s.conv) { const off = Math.floor(time * 40) % 12; bx.fillStyle = '#ffd34d'; for (let x = s.x + (s.conv > 0 ? off : 12 - off); x < s.x + s.w - 4; x += 12) { bx.fillRect(x, s.y + 1, 4, 2); bx.fillRect(x + (s.conv > 0 ? 2 : -2) + 1, s.y + 2, 2, 2); } }
    return;
  }
  if (s.k === 'door') { drawDoor(s); return; }
  if (s.k === 'break' && VWI(curWorld) === 10) {
    if (s.st === 2 && s.oy > 300) return;
    const ox = s.st === 1 ? Math.round(Math.sin(time * 80) * 1.5) : 0, oy = s.st === 2 ? Math.round(s.oy) : 0;
    bx.globalAlpha = s.st === 2 ? Math.max(0, 1 - s.oy / 200) : s.st === 1 ? .75 : 1;
    for (let i = 0; i < s.w; i += 12) { bx.fillStyle = '#ffffff'; bx.beginPath(); bx.arc(s.x + i + 6 + ox, s.y + 8 + oy + Math.sin(time * 2 + i) * 1, 8, 0, 6.3); bx.fill(); }
    bx.fillStyle = '#d8e8ff'; bx.fillRect(s.x + ox, s.y + 10 + oy, s.w, 6); bx.globalAlpha = 1; return;
  }
  if (s.k === 'phase') {
    const on = s.ph === dim, col = s.ph ? [208, 112, 255] : [53, 226, 255];
    const rgb = 'rgba(' + col.join(',') + ',';
    if (on) {
      bx.fillStyle = rgb + '.28)'; bx.fillRect(s.x, s.y, s.w, s.h);
      bx.fillStyle = rgb + '1)'; bx.fillRect(s.x, s.y, s.w, 2); bx.fillRect(s.x, s.y + s.h - 2, s.w, 2); bx.fillRect(s.x, s.y, 2, s.h); bx.fillRect(s.x + s.w - 2, s.y, 2, s.h);
      bx.fillStyle = rgb + '.5)'; for (let y = s.y + 5; y < s.y + s.h - 3; y += 6) bx.fillRect(s.x + 3, y, s.w - 6, 1);
      glowAt(s.x + s.w / 2, s.y + s.h / 2, Math.max(s.w, s.h) * .6, rgb + '.4)', .5);
    } else {
      bx.fillStyle = rgb + '.35)';
      for (let x = s.x; x < s.x + s.w; x += 6) { bx.fillRect(x, s.y, 3, 1); bx.fillRect(x, s.y + s.h - 1, 3, 1); }
      for (let y = s.y; y < s.y + s.h; y += 6) { bx.fillRect(s.x, y, 1, 3); bx.fillRect(s.x + s.w - 1, y, 1, 3); }
    }
    return;
  }
  if (s.k === 'move' && paintedOK(curWorld)) { const P = blockFor(curWorld, s.w, 'move'); bx.drawImage(P.c, Math.round(s.x + P.ox), Math.round(s.y + P.oy)); glowAt(s.x + s.w / 2, s.y + 18, 26, hexToRgba(WORLDS[curWorld].c, .35), .5); return; }
  if (s.k === 'move') {
    const img = SPR[WORLDS[curWorld].mplat], iw = img.width, sy = Math.round(s.y), sx = Math.round(s.x);
    if (WORLDS[curWorld].mplat === 'w_platform') { bx.drawImage(img, sx + (s.w - iw * 2) / 2 | 0, sy - 2, iw * 2, Math.min(24, img.height * 2)); glowAt(sx + s.w / 2, sy + 10, 30, 'rgba(0,200,255,.5)', .6); }
    else if (WORLDS[curWorld].mplat === 'gv_mplat') bx.drawImage(img, 0, 0, iw, img.height, sx, sy - 4, s.w, img.height * s.w / iw * .5);
    else for (let x = 0; x < s.w; x += iw) bx.drawImage(img, 0, 0, Math.min(iw, s.w - x), img.height, sx + x, sy, Math.min(iw, s.w - x), img.height);
    return;
  }
  if (s.k === 'bounce') {
    const sq = s.sq > 0 ? Math.round(Math.sin(s.sq / 0.3 * Math.PI) * 4) : 0, img = SPR.spring;
    bx.drawImage(img, Math.round(s.x + s.w / 2 - img.width * 0.75), Math.round(s.y + s.h - img.height * 1.5 + sq + 2), img.width * 1.5, img.height * 1.5 - sq);
    return;
  }
  if (s.k === 'laser') {
    bx.fillStyle = '#2a2850'; bx.fillRect(s.x - 8, s.y - 6, 8, s.h + 12); bx.fillRect(s.x + s.w, s.y - 6, 8, s.h + 12);
    bx.fillStyle = s.on ? '#ff3dd6' : '#5a3a60'; bx.fillRect(s.x - 5, s.y - 2, 2, s.h + 4); bx.fillRect(s.x + s.w + 3, s.y - 2, 2, s.h + 4);
    if (s.on) { if (!(s.warn && Math.floor(time * 16) % 2 === 0)) { bx.fillStyle = '#ff2fd0'; bx.fillRect(s.x, s.y, s.w, s.h); bx.fillStyle = '#ffd6f6'; bx.fillRect(s.x, s.y + 3, s.w, 2); glowAt(s.x + s.w / 2, s.y + 4, s.w * .6, 'rgba(255,40,200,.55)', .7); } }
    else { bx.fillStyle = 'rgba(255,61,214,.35)'; for (let x = s.x; x < s.x + s.w; x += 8) bx.fillRect(x, s.y + 3, 4, 2); }
    return;
  }
  if (s.k === 'boost') {
    bx.fillStyle = '#1c1830'; bx.fillRect(s.x, s.y - 1, s.w, s.h + 2);
    const off = Math.floor(time * 60) % 12; bx.fillStyle = '#ffd34d';
    for (let x = s.x + off; x < s.x + s.w - 6; x += 12) { bx.fillRect(x, s.y - 1, 2, 6); bx.fillRect(x + 2, s.y, 2, 4); bx.fillRect(x + 4, s.y + 1, 2, 2); }
    glowAt(s.x + s.w / 2, s.y, s.w * .5, 'rgba(255,210,60,.5)', .5);
    return;
  }
  if (s.k === 'break' && paintedOK(curWorld)) {
    if (s.st === 2 && s.oy > 400) return;
    const ox = s.st === 1 ? Math.round(Math.sin(time * 80) * 1.5) : 0, oy = s.st === 2 ? Math.round(s.oy) : 0, P = blockFor(curWorld, s.w, 'break');
    if (s.st === 2) bx.globalAlpha = Math.max(0, 1 - s.oy / 300);
    bx.drawImage(P.c, s.x + P.ox + ox, s.y + P.oy + oy);
    bx.fillStyle = s.st === 1 ? '#ffb040' : 'rgba(0,0,0,.55)'; bx.fillRect(s.x + Math.round(s.w * .3) + ox, s.y + 4 + oy, 1, 10); bx.fillRect(s.x + Math.round(s.w * .65) + ox, s.y + 2 + oy, 1, 12); bx.fillRect(s.x + Math.round(s.w * .45) + ox, s.y + 9 + oy, 7, 1);
    bx.globalAlpha = 1; return;
  }
  if (s.k === 'break') {
    if (s.st === 2 && s.oy > 400) return;
    const ox = s.st === 1 ? Math.round(Math.sin(time * 80) * 1.5) : 0, oy = s.st === 2 ? Math.round(s.oy) : 0;
    if (s.st === 2) bx.globalAlpha = Math.max(0, 1 - s.oy / 300);
    const T = SPR[WORLDS[curWorld].tiles], o = META[WORLDS[curWorld].tiles].order;
    for (let x = 0; x < s.w; x += 16) bx.drawImage(T, o.indexOf(x === 0 ? 'pl' : x + 16 >= s.w ? 'pr' : 'pm') * 16, 0, 16, 16, s.x + x + ox, s.y + oy, 16, 16);
    bx.fillStyle = s.st === 1 ? '#ffb040' : 'rgba(0,0,0,.45)'; bx.fillRect(s.x + Math.round(s.w * .3) + ox, s.y + 4 + oy, 1, 8); bx.fillRect(s.x + Math.round(s.w * .65) + ox, s.y + 2 + oy, 1, 10); bx.fillRect(s.x + Math.round(s.w * .45) + ox, s.y + 9 + oy, 6, 1);
    bx.globalAlpha = 1;
  }
}
function drawHazards() {
  for (const h of level.hazards) {
    if (!onScreen(h.x, h.w)) continue;
    if (h.k === 'spike') { const im = SPR[WORLDS[curWorld].spk]; const iw = im.width, ih = im.height, sc = 12 / ih; for (let x = 0; x < h.w; x += iw * sc) bx.drawImage(im, 0, 0, Math.min(iw, (h.w - x) / sc), ih, h.x + x, h.y, Math.min(iw * sc, h.w - x), 12); }
    else if (h.k === 'jet') {
      bx.fillStyle = '#2a1a1a'; bx.fillRect(h.x - 2, GY - 6, 24, 6); bx.fillStyle = h.warn || h.on ? '#ff8a30' : '#5a3a30'; bx.fillRect(h.x + 4, GY - 4, 12, 2);
      if (h.warn) { glowAt(h.x + 10, GY - 6, 14, 'rgba(255,140,40,.6)', .5 + Math.sin(time * 30) * .3); }
      if (h.on) {
        for (let i = 0; i < 6; i++) { const yy = GY - 10 - i * 11, ww = 16 - i * 2 + Math.round(Math.sin(time * 40 + i) * 2); bx.fillStyle = i < 2 ? '#ffffff' : i < 4 ? '#ffd040' : '#ff6a1a'; bx.fillRect(Math.round(h.x + 10 - ww / 2), yy, ww, 11); }
        glowAt(h.x + 10, GY - 35, 40, 'rgba(255,120,30,.7)', .9);
      }
    } else if (h.k === 'icicle') {
      if (h.st === 3) continue;
      const ox = h.st === 1 ? Math.round(Math.sin(time * 70) * 1) : 0, x = Math.round(h.x) + ox, y = Math.round(h.y);
      bx.fillStyle = '#e8fbff'; bx.fillRect(x + 2, y, 8, 5); bx.fillStyle = '#9fdcff'; bx.fillRect(x + 3, y + 5, 6, 5); bx.fillRect(x + 4, y + 10, 4, 4); bx.fillStyle = '#6fb8e8'; bx.fillRect(x + 5, y + 14, 2, 4);
      bx.fillStyle = '#ffffff'; bx.fillRect(x + 3, y + 1, 1, 6);
    }
  }
  for (const l of level.lavaStrips) {
    if (!onScreen(l.x, l.w)) continue;
    for (let x = l.x + 30; x < l.x + l.w; x += 90) lightAt(x, l.y, 110, 'rgba(255,120,40,1)', .45);
    const L = SPR.lava, fr = Math.floor(time * 6) % 4;
    for (let x = l.x; x < l.x + l.w; x += 16) bx.drawImage(L, fr * 16, 0, Math.min(16, l.x + l.w - x), 32, x, l.y, Math.min(16, l.x + l.w - x), 32);
    bx.fillStyle = '#7a1408'; bx.fillRect(l.x, l.y + 32, l.w, 200);
    glowAt(l.x + l.w / 2, l.y, l.w * .6, 'rgba(255,100,30,.45)', .7);
  }
  for (const z of level.zones) {
    if (!onScreen(z.x, z.w)) continue;
    if (z.k === 'water' || z.k === 'sand') { drawZonesX(z); continue; }
    if (z.k === 'wind') {
      bx.fillStyle = 'rgba(255,255,255,.35)';
      for (let i = 0; i < 14; i++) {
        const sx = z.x + ((i * 53 + (z.fx ? -time * 300 * Math.sign(z.fx) : 0)) % z.w + z.w) % z.w, sy = z.y + ((i * 97 + (z.fy ? time * z.fy * 0.15 : 0)) % z.h + z.h) % z.h;
        if (z.fy) bx.fillRect(Math.round(sx), Math.round(sy), 1, 8); else bx.fillRect(Math.round(sx), Math.round(sy), 10, 1);
      }
      if (z.fy) glowAt(z.x + z.w / 2, z.y + z.h - 10, z.w * .6, 'rgba(200,255,255,.3)', .5);
    } else if (z.k === 'lowgrav') {
      bx.fillStyle = 'rgba(208,112,255,.08)'; bx.fillRect(z.x, z.y, z.w, z.h);
      bx.fillStyle = 'rgba(230,180,255,.6)';
      for (let i = 0; i < 18; i++) { const sx = z.x + (i * 71) % z.w, sy = z.y + ((i * 113 - time * 20) % z.h + z.h) % z.h; bx.fillRect(Math.round(sx), Math.round(sy), 2, 2); }
    }
  }
}
function drawDecor() {
  for (const d of level.decor) {
    if (!onScreen(d.x - 90, 180)) continue;
    const img = SPR[d.k]; if (!img) continue;
    if (d.anim) spr(d.k, Math.floor(time * 8 + d.ph), d.x, d.y, d.flip);
    else if (d.k === 'd_torch') { bx.drawImage(img, d.x - 8, d.y - 16); glowAt(d.x, d.y - 10, 26 + Math.sin(time * 10 + d.ph) * 2, 'rgba(255,140,40,.55)', .8); }
    else {
      const near = Math.abs(p.x + p.w / 2 - d.x) < 24 && Math.abs(p.y + p.h - d.y) < 8 && Math.abs(p.vx) > 40;
      if (near) d.sway = 0.5;
      const plant = d.k.startsWith('d_') || d.k.includes('bush') || d.k === 'p_shrooms' || d.k.startsWith('pr');
      if (plant) {
        if (d.sway > 0) d.sway -= 1 / 60;
        const k = (Math.sin(d.sway * 25) * d.sway * 0.5 + Math.sin(time * 1.6 + d.ph) * (0.06 + gust * 0.12)) * (d.k.startsWith('pr') ? (d.big ? 0.12 : 0.35) : 1);
        bx.save(); bx.translate(Math.round(d.x), d.y); bx.transform(1, 0, k, 1, 0, 0); bx.drawImage(d.flip ? flipped(d.k) : img, -Math.round(img.width / 2), -img.height); bx.restore();
      } else bx.drawImage(d.flip ? flipped(d.k) : img, Math.round(d.x - img.width / 2), d.y - img.height);
    }
    if (d.k === 'w_banner-neon' || d.k === 'w_banner-big' || d.k === 'w_banner-coke') glowAt(d.x, d.y - meta(d.k).fh / 2, 34, 'rgba(255,60,200,.35)', .6);
    if (d.k === 'w_monitorface') glowAt(d.x, d.y - 9, 18, 'rgba(60,240,255,.4)', .6);
  }
}
function drawCritters() {
  for (const c of level.critters) {
    if (c.gone || !onScreen(c.x, 8)) continue;
    const x = Math.round(c.x), y = Math.round(c.y), col = c.kind === 'crow' ? ['#1a1420', '#3a3040'] : curWorld === 3 ? ['#5a3020', '#c08050'] : ['#4a6ad0', '#f0d060'];
    bx.fillStyle = col[0];
    if (c.fly) { const up = Math.floor(time * 18 + c.t * 3) % 2; bx.fillRect(x - 2, y - 3, 4, 2); bx.fillRect(x - 4, y - 4 - up, 3, 1); bx.fillRect(x + 1, y - 4 - up, 3, 1); }
    else { const hop = c.hop > 0 ? 1 : 0; bx.fillRect(x - 2, y - 4 - hop, 4, 3); bx.fillRect(x + (c.face > 0 ? 2 : -3), y - 5 - hop, 2, 2); bx.fillStyle = col[1]; bx.fillRect(x + (c.face > 0 ? 4 : -4), y - 4 - hop, 1, 1); bx.fillRect(x - 1, y - 1, 1, 1); }
  }
}
function drawCheck(c) {
  if (!onScreen(c.x, c.w)) return;
  const cx = c.x + c.w / 2, by = c.y + c.h;
  bx.fillStyle = '#2a2440'; bx.fillRect(cx - 6, by - 6, 12, 6); bx.fillStyle = '#4a4070'; bx.fillRect(cx - 4, by - 8, 8, 2);
  const y = by - 26 + Math.round(Math.sin(time * 3) * 2), col = c.on ? '#7dffb0' : '#6d6a90';
  bx.fillStyle = '#1b1530'; bx.fillRect(cx - 4, y - 7, 8, 14); bx.fillRect(cx - 5, y - 5, 10, 10);
  bx.fillStyle = col; bx.fillRect(cx - 3, y - 6, 6, 12); bx.fillRect(cx - 4, y - 4, 8, 8);
  bx.fillStyle = '#ffffff'; bx.fillRect(cx - 2, y - 4, 2, 3);
  if (c.on) { glowAt(cx, y, 24, 'rgba(90,255,160,.6)', .8); if (Math.random() < .1) parts.push({ x: cx + rnd(-4, 4), y, vx: 0, vy: -30, life: .6, max: .6, c: '#9bffb0', s: 1, g: 0 }); }
}
function drawGoal() {
  const g = level.goal; if (!g || !onScreen(g.x, g.w)) return;
  const cx = g.x + g.w / 2, cy = g.y + g.h / 2;
  glowAt(cx, cy, 70, 'rgba(255,211,77,.5)', .8 + Math.sin(time * 3) * .2);
  for (let i = 0; i < 24; i++) {
    const a = time * 2 + i / 24 * 6.283, rx = 20 + Math.sin(time * 3 + i) * 2, ry = 32;
    bx.fillStyle = i % 3 ? '#ffd34d' : '#ffffff'; bx.fillRect(Math.round(cx + Math.cos(a) * rx) - 1, Math.round(cy + Math.sin(a) * ry) - 1, 3, 3);
  }
  bx.fillStyle = 'rgba(255,240,200,.35)'; bx.beginPath(); bx.ellipse(cx, cy, 16, 28, 0, 0, 6.3); bx.fill();
  if (Math.random() < .3) parts.push({ x: cx + rnd(-16, 16), y: cy + rnd(-28, 28), vx: 0, vy: -40, life: .6, max: .6, c: '#ffe066', s: 1, g: 0 });
}
function drawRelic() {
  const r = level.relic; if (!r || r.taken || !onScreen(r.x - 10, 20)) return;
  const y = r.y + Math.round(Math.sin(time * 2.5) * 3);
  glowAt(r.x, y, 22, 'rgba(255,220,120,.7)', .7 + Math.sin(time * 5) * .2);
  bx.drawImage(SPR.hourglass, Math.round(r.x - 7), y - 10);
  if (Math.random() < .15) parts.push({ x: r.x + rnd(-8, 8), y: y + rnd(-10, 10), vx: 0, vy: -20, life: .5, max: .5, c: '#fff4c0', s: 1, g: 0 });
}
function drawLever(l) {
  if (!onScreen(l.x, l.w)) return;
  const img = l.on ? SPR.lever_on : SPR.lever_off, cx = l.x + l.w / 2, by = l.y + l.h;
  bx.drawImage(img, Math.round(cx - img.width), by - img.height * 2, img.width * 2, img.height * 2);
  if (!l.on) { glowAt(cx, by - 10, 28, 'rgba(255,80,40,.6)', .5 + Math.sin(time * 6) * .3); if (boss && boss.type === 2) { const y = by - 46 + Math.round(Math.sin(time * 6) * 3); bx.fillStyle = '#ffd34d'; bx.fillRect(cx - 2, y, 4, 10); bx.fillRect(cx - 2, y + 13, 4, 4); } }
  else glowAt(cx, by - 10, 24, 'rgba(90,255,160,.5)', .6);
}
function drawGem(g) {
  if (g.taken || !onScreen(g.x - 10, 20)) return;
  const y = g.y + Math.round(Math.sin(time * 3 + g.ph) * 3);
  glowAt(g.x, y, 14, 'rgba(255,90,200,.45)', .7);
  spr('gem', Math.floor(time * 10 + g.ph), g.x, y + 7);
}
function drawCherry(c) {
  if (c.taken || !onScreen(c.x - 12, 24)) return;
  const y = c.y + Math.round(Math.sin(time * 3 + c.ph) * 3);
  glowAt(c.x, y, 14, 'rgba(255,60,90,.4)', .6);
  spr('cherry', Math.floor(time * 10 + c.ph), c.x, y + 11);
}
function drawEnemy(e) {
  const d = e.d, cx = e.x + e.w / 2, by = e.y + e.h, wh = e.hit > 0;
  const flip = d.face === 0 ? false : (e.dir !== d.face);
  if (d.stat) { if (!(e.b === 'riser' && e.st === 'buried')) { drawStatic(e); if (e.alert > 0 && e.b !== 'diver') { const y = e.y - 14 + Math.round(Math.sin(time * 20) * 1); bx.fillStyle = '#ffffff'; bx.fillRect(Math.round(cx) - 2, y - 1, 5, 12); bx.fillStyle = '#ff3d5a'; bx.fillRect(Math.round(cx) - 1, y, 3, 7); bx.fillRect(Math.round(cx) - 1, y + 8, 3, 2); } return; } }
  if (e.b === 'riser' && e.st === 'buried') { bx.fillStyle = 'rgba(0,0,0,.4)'; bx.fillRect(Math.round(cx - 10), by - 2, 20, 2); bx.fillStyle = '#d8d0c0'; if (Math.sin(time * 3 + e.t) > .6) bx.fillRect(Math.round(cx - 3), by - 4, 2, 2); return; }
  if (e.b === 'riser' && e.st === 'rising') { spr(d.rise, Math.min(5, Math.floor(e.rise / 0.8 * 6)), cx, by + 1, flip); return; }
  if (e.b === 'ghost') {
    const a = dim === 1 ? 1 : 0.28 + Math.sin(time * 4 + e.t) * .08;
    spr(d.anim, Math.floor(e.t * 8), cx, by + 4, flip, 1, wh, a);
    if (dim === 1) glowAt(cx, e.y + 20, 24, e.id === 'infghost' ? 'rgba(255,90,40,.4)' : 'rgba(170,90,255,.45)', .7);
  } else if (e.b === 'shooter') {
    const k = d.atk && e.fire > 0 ? d.atk : d.anim, n = meta(k).n;
    const f = d.atk && e.fire > 0 ? Math.floor((0.5 - e.fire) / 0.5 * n) : (d.still && !d.animAlways ? 0 : Math.floor(e.t * (d.animAlways ? 8 : 10)));
    spr(k, f, cx, by + 1, flip, 1, wh);
    if (e.id === 'turret') glowAt(cx + e.dir * 6, e.y + 8, 10, 'rgba(255,60,60,.6)', .4 + Math.sin(time * 8) * .2);
  } else if (e.b === 'jumper') spr(e.air ? d.jump : d.anim, e.air ? (e.vy < 0 ? 0 : 1) : Math.floor(e.t * 8), cx, by + 1, flip, 1, wh);
  else if (e.b === 'flyer') { spr(d.anim, Math.floor(e.t * 10), cx, by + (d.oy || 6), flip, 1, wh); if (e.id === 'drone' || e.id === 'cdrone') glowAt(cx, e.y + e.h / 2, 18, 'rgba(60,240,255,.45)', .6); }
  else if (e.b === 'diver') { spr(e.st === 'dive' ? d.anim + '_atk' : d.anim, Math.floor(e.t * 12), cx, by + 30, flip, 1, wh); if (e.st === 'tele') glowAt(cx, e.y + 10, 16, 'rgba(255,60,60,.7)', .8); }
  else if (e.b === 'bomber') spr(e.fire > 0 ? d.atk : d.anim, e.fire > 0 ? Math.floor((0.5 - e.fire) / 0.5 * 8) : Math.floor(e.t * 12), cx, by + 1, flip, 1, wh);
  else if (e.b === 'shield') {
    const k = e.fire > 0 ? 'skel_v_atk' : e.guard ? 'skel_v_shield' : 'skel_v_walk';
    spr(k, e.fire > 0 ? Math.floor((0.75 - e.fire) / 0.75 * 8) : Math.floor(e.t * 8), cx, by + 1, flip, 1, wh);
  } else spr(d.anim, Math.floor(e.t * 10), cx, by + 1, flip, 1, wh);
  if (e.alert > 0 && e.b !== 'diver') { const y = e.y - 14 + Math.round(Math.sin(time * 20) * 1); bx.fillStyle = '#ffffff'; bx.fillRect(Math.round(cx) - 2, y - 1, 5, 12); bx.fillStyle = '#ff3d5a'; bx.fillRect(Math.round(cx) - 1, y, 3, 7); bx.fillRect(Math.round(cx) - 1, y + 8, 3, 2); }
}
// ---------------- Guardianes clásicos con arte pintado (si existe) ----------------
// El arte nuevo mira a la derecha; se gira según b.face. Conserva todos los ataques y estados.
const HDB = { 0: 'hdb_frog', 2: 'hdb_wizard', 3: 'hdb_eye', 4: 'hdb_knight', 5: 'hdb_beast', 6: 'hdb_demon' };
function hdbKey(t) { const k = HDB[t]; return k && SPR[k] && SPR[k].width ? k : null; }
function stunStars(cx, y, r) { for (let i = 0; i < 3; i++) { const a = time * 5 + i * 2.1; bx.fillStyle = '#ffe066'; bx.fillRect(Math.round(cx + Math.cos(a) * r), Math.round(y + Math.sin(a) * 6), 3, 3); } }
function drawBossHD(b, k, wh, blink, cx, by) {
  const m = meta(k), src = wh || blink ? whiteOf(k, false) : SPR[k], fl = b.face < 0, mid = b.y + b.h / 2;
  let sx = 1, sy = 1, px = cx, py = by, rot = 0, center = false;
  if (b.type === 0) {
    if (b.st === 'crouch') { sy = 0.86; sx = 1.08; } else if (b.st === 'air') { sy = 1.08; sx = 0.94; rot = b.vy < 0 ? -0.08 : 0.06; } else sy = 1 + Math.sin(time * 4) * 0.02;
    py = by + 4;
  } else if (b.type === 2) {
    py = by + Math.sin(time * 2.2) * 4 - 6; rot = b.throwA > 0 ? -0.09 : Math.sin(time * 1.3) * 0.02;
    glowAt(cx, by - 60, 95, 'rgba(255,100,30,.38)', .8); glowAt(cx + (fl ? -36 : 36), by - 92, 24, 'rgba(255,170,60,.8)', .6 + Math.sin(time * 6) * .2);
  } else if (b.type === 3) {
    center = true; py = mid + Math.sin(time * 3) * 3; rot = b.st === 'dive' ? 0.25 : Math.sin(time * 2) * 0.06;
    if (b.atkA > 0) b.atkA -= 1 / 60;
    glowAt(cx, mid, 80, 'rgba(255,150,60,.28)', .6); if (b.st === 'tele') glowAt(cx, mid, 64, 'rgba(255,40,60,.75)', .85);
  } else if (b.type === 4) {
    const walk = b.st === 'walk' && !b.dying; sy = walk ? 1 + Math.abs(Math.sin(time * 8)) * 0.02 : 1;
    rot = b.st === 'windup' ? -0.1 : b.st === 'slash' ? 0.14 : b.st === 'guard' ? -0.04 : 0; py = by + 2;
    if (b.st === 'windup') glowAt(cx + b.face * 30, b.y + 40, 44, 'rgba(255,60,60,.55)', .6);
  } else if (b.type === 5) {
    const run = b.st === 'charge' || b.st === 'leap'; rot = run ? 0.06 : b.st === 'roar' ? -0.08 : 0; sy = run ? 1 + Math.sin(time * 18) * 0.03 : 1 + Math.sin(time * 3) * 0.015; py = by + 4;
    glowAt(cx, mid, 85, 'rgba(150,220,255,.3)', .6);
  } else if (b.type === 6) {
    center = true; py = mid + (b.st === 'rest' ? 10 : Math.sin(time * 2) * 6); rot = Math.sin(time * 1.5) * 0.03;
    glowAt(cx, b.y + 70, 150, 'rgba(255,70,30,.5)', .9); glowAt(cx, b.y + 40, 60, 'rgba(255,160,60,.35)', .8);
  }
  bx.save(); bx.translate(Math.round(px), Math.round(py)); if (b.dying) bx.globalAlpha = clamp(b.dieT / 2.8 + 0.15, 0, 1);
  bx.rotate(fl ? -rot : rot); bx.scale(fl ? -sx : sx, sy);
  if (center) bx.drawImage(src, 0, 0, m.fw, m.fh, -m.fw / 2, -m.fh / 2, m.fw, m.fh); else bx.drawImage(src, 0, 0, m.fw, m.fh, -m.ax, -m.ay, m.fw, m.fh);
  bx.restore();
  if (b.type === 2 && b.vulnT <= 0 && !b.dying) shieldBubble(cx, by - 74, 86);
  if (b.type === 3 && b.st === 'stun') stunStars(cx, b.y - 6, 30);
  if (b.type === 4 && b.st === 'guard') glowAt(cx + b.face * 30, b.y + 50, 44, 'rgba(200,220,255,.45)', .6);
  if (b.type === 5 && b.st === 'roar') for (let i = 0; i < 3; i++) { const r = (b.t * 200 + i * 30) % 90; bx.strokeStyle = 'rgba(200,240,255,' + (1 - r / 90) * .6 + ')'; bx.lineWidth = 2; bx.beginPath(); bx.arc(cx + b.face * 50, b.y + 20, r, 0, 6.3); bx.stroke(); }
  if (b.type === 5 && b.st === 'stagger') stunStars(cx, b.y - 4, 34);
  if (b.type === 6 && b.st === 'rest') stunStars(cx, b.y - 4, 40);
  if (b.type === 6 && b.st === 'breath') glowAt(b.face < 0 ? b.x - 90 : b.x + b.w + 90, b.y + 120, 110, 'rgba(60,220,255,.45)', .8);
}
function drawBoss() {
  if (!boss || boss.done) return;
  const b = boss, wh = b.hit > 0, A = level.arena, cx = b.x + b.w / 2, by = b.y + b.h;
  const blink = b.dying && Math.floor(time * 20) % 2 === 0;
  bx.fillStyle = 'rgba(0,0,0,.3)';
  const sw = Math.round(b.w * .55 * clamp(1 - (A.floor - by) / 300, .3, 1)); bx.fillRect(Math.round(cx - sw), A.floor - 3, sw * 2, 3);
  const hk = !b.skin && hdbKey(b.type); if (hk) { drawBossHD(b, hk, wh, blink, cx, by); return; }
  if (b.type === 0) {
    let k = 'frog_boss_idle_s4', f = 0, sy = 1;
    if (b.st === 'air') { k = 'frog_boss_jump_s4'; f = b.vy < 0 ? 0 : 1; } else if (b.st === 'crouch') sy = 0.875; else sy = 1 + Math.sin(time * 4) * 0.02;
    const m = meta(k), img = wh || blink ? whiteOf(k, b.face > 0) : b.face > 0 ? flipped(k) : SPR[k], fi = b.face > 0 ? m.n - 1 - f : f, w = m.fw, h = m.fh * sy;
    bx.drawImage(img, fi * m.fw, 0, m.fw, m.fh, Math.round(cx - w / 2), Math.round(by - h + 4), w, h);
  } else if (b.type === 1) {
    if (b.st === 'aim') { bx.globalAlpha = 0.4 + 0.4 * Math.sin(time * 30); bx.fillStyle = '#ff3d5a'; for (let x = A.x1; x < A.x2; x += 16) bx.fillRect(x, Math.round(b.aimY) - 1, 10, 2); bx.globalAlpha = 1; }
    const hover = b.st === 'down' ? 0 : Math.round(Math.sin(time * 4) * 3);
    if (b.st !== 'down') { glowAt(cx, by + hover - 60, 70, 'rgba(255,60,60,.35)', .8); glowAt(cx, by + hover - 100, 14, 'rgba(255,90,90,.8)', .9); }
    const img = wh || blink ? whiteOf('boss_ship') : b.st === 'down' ? SPR.boss_ship_hot : SPR.boss_ship;
    bx.drawImage(img, Math.round(cx - img.width / 2), Math.round(by - img.height + 10 + hover));
    glowAt(cx, by - 32 + hover, 26, b.st === 'down' ? 'rgba(255,200,60,.6)' : (b.st === 'aim' || b.st === 'fire') ? 'rgba(255,40,80,.9)' : 'rgba(60,240,255,.7)', .9);
  } else if (b.type === 2) {
    const vul = b.vulnT > 0;
    let k = 'WZ_idle', f = Math.floor(b.anim * 10);
    if (b.dying) { k = 'WZ_death'; f = Math.min(4, Math.floor((2.8 - b.dieT) * 3)); } else if (b.throwA > 0) { k = 'WZ_atk'; f = Math.min(7, Math.floor((0.6 - b.throwA) / 0.6 * 8)); } else if (wh) { k = 'WZ_hit'; f = 1; }
    const arc = b.skin === 'boss_archi' && SPR.boss_archi && SPR.boss_archi.width;
    if (arc) {
      // El Archivero Sin Rostro: arte pintado (Higgsfield), flota y se inclina al lanzar
      const m = meta('boss_archi'), src = wh || blink ? whiteOf('boss_archi', false) : SPR.boss_archi, bob = Math.sin(time * 2.2) * 4 - 8, tilt = b.throwA > 0 ? -0.09 : Math.sin(time * 1.3) * 0.02, fl = b.face < 0;
      glowAt(cx, by - 70, 100, 'rgba(80,200,255,.38)', .8); glowAt(cx + (fl ? -40 : 40), by - 95, 26, 'rgba(90,255,220,.8)', .6 + Math.sin(time * 6) * .2);
      bx.save(); bx.translate(Math.round(cx), Math.round(by + bob)); if (b.dying) bx.globalAlpha = clamp(b.dieT / 2.8, 0, 1);
      bx.rotate(fl ? -tilt : tilt); bx.scale(fl ? -1 : 1, 1); bx.drawImage(src, 0, 0, m.fw, m.fh, -m.ax, -m.ay, m.fw, m.fh); bx.restore();
      if (!vul && !b.dying) shieldBubble(cx, by - 78, 88);
    } else {
    glowAt(cx, by - 50, 90, 'rgba(255,100,30,.35)', .8);
    spr(k + '_s2', f, cx, by + 2, b.face < 0, 1, wh || blink);
    if (!vul && !b.dying) shieldBubble(cx, by - 56, 74);
    }
  } else if (b.type === 3) {
    const k = b.st === 'dive' || b.st === 'tele' || b.atkA > 0 ? 'eye_atk' : 'eye', f = Math.floor(b.anim * 12);
    if (b.atkA > 0) b.atkA -= 1 / 60;
    if (b.st === 'tele') glowAt(cx, b.y + b.h / 2, 60, 'rgba(255,40,60,.7)', .8);
    glowAt(cx, b.y + b.h / 2, 70, 'rgba(255,150,60,.25)', .6);
    spr(k + '_s2', b.st === 'stun' ? 2 : f, cx, by + 86, b.face < 0, 1.5, wh || blink);
    if (b.st === 'stun') { for (let i = 0; i < 3; i++) { const a = time * 5 + i * 2.1; bx.fillStyle = '#ffe066'; bx.fillRect(Math.round(cx + Math.cos(a) * 30), Math.round(b.y - 6 + Math.sin(a) * 6), 3, 3); } }
  } else if (b.type === 4) {
    let k = 'skel_walk', f = Math.floor(b.anim * 8);
    if (b.dying) { k = 'skel_death'; f = Math.min(3, Math.floor((2.8 - b.dieT) * 2)); }
    else if (b.st === 'guard') { k = 'skel_shield'; f = Math.min(3, Math.floor(b.t * 8)); }
    else if (b.st === 'windup') { k = 'skel_atk'; f = Math.min(3, Math.floor(b.t / 0.45 * 4)); }
    else if (b.st === 'slash') { k = 'skel_atk'; f = 4 + Math.min(3, Math.floor(b.t / 0.3 * 4)); }
    else if (wh) { k = 'skel_hit'; f = 1; }
    if (b.st === 'windup') glowAt(cx + b.face * 30, b.y + 40, 40, 'rgba(255,60,60,.5)', .6);
    spr(k + '_s2', f, cx, by + 2, b.face < 0, 1.1, wh || blink);
    if (b.st === 'guard') glowAt(cx + b.face * 30, b.y + 50, 40, 'rgba(200,220,255,.4)', .6);
  } else if (b.type === 5) {
    const k = 'hound_ice', run = b.st === 'charge' || b.st === 'leap';
    const f = run ? Math.floor(b.anim * 14) : b.st === 'roar' || b.st === 'leapT' ? 0 : b.st === 'stagger' ? 2 : Math.floor(b.anim * 3) % 2;
    glowAt(cx, b.y + b.h / 2, 80, 'rgba(150,220,255,.3)', .6);
    spr(k + '_s2', f, cx, by + 6, b.face > 0, 1.3, wh || blink);
    if (b.st === 'roar') { for (let i = 0; i < 3; i++) { const r = (b.t * 200 + i * 30) % 90; bx.strokeStyle = 'rgba(200,240,255,' + (1 - r / 90) * .6 + ')'; bx.lineWidth = 2; bx.beginPath(); bx.arc(cx + b.face * 50, b.y + 20, r, 0, 6.3); bx.stroke(); } }
    if (b.st === 'stagger') for (let i = 0; i < 3; i++) { const a = time * 5 + i * 2.1; bx.fillStyle = '#ffe066'; bx.fillRect(Math.round(cx + Math.cos(a) * 34), Math.round(b.y - 4 + Math.sin(a) * 6), 3, 3); }
  } else if (b.type === 6) {
    const breath = b.st === 'breath' || b.st === 'breathT';
    const k = breath ? 'demon_atk' : 'demon_idle', n = meta(k).n;
    const f = b.st === 'breathT' ? Math.min(8, Math.floor(b.t / 0.7 * 9)) : b.st === 'breath' ? 9 + Math.floor(b.t * 8) % 9 : Math.floor(b.anim * 8);
    glowAt(cx, b.y + 70, 140, 'rgba(255,70,30,.5)', .9); glowAt(cx, b.y + 40, 60, 'rgba(255,160,60,.35)', .8);
    if (b.st === 'rest') { for (let i = 0; i < 3; i++) { const a = time * 5 + i * 2.1; bx.fillStyle = '#ffe066'; bx.fillRect(Math.round(cx + Math.cos(a) * 40), Math.round(b.y - 4 + Math.sin(a) * 6), 3, 3); } }
    spr(k, f, cx, by + 14, b.face > 0, 1.35, wh || blink);
    if (b.st === 'breath') glowAt(b.face < 0 ? b.x - 90 : b.x + b.w + 90, b.y + 120, 110, 'rgba(60,220,255,.45)', .8);
  } else if (b.type === 7) {
    let k = 'S_idle', f = Math.floor(b.anim * 5);
    if (b.dying) { k = 'S_death'; f = Math.min(1, Math.floor((2.8 - b.dieT) * 1.2)); }
    else if (b.st === 'dash') k = 'S_dash';
    else if (b.st === 'dashT') { k = 'S_atk1'; f = Math.min(1, Math.floor(b.t * 5)); }
    else if (b.st === 'jump' || b.st === 'jumpT') { k = b.vy > 0 && b.t > 0.35 ? 'S_atk2' : 'S_jump'; f = b.vy > 0 ? 2 : 0; }
    else if (b.st === 'clocks') { k = 'S_atk2'; f = Math.min(3, Math.floor(b.t * 6)); }
    else if (wh) k = 'S_hit';
    else if (b.st === 'idle' && Math.abs(p.x - b.x) > 160) { k = 'S_run'; f = Math.floor(b.anim * 14); }
    if (b.st === 'dashT' || b.st === 'jumpT') glowAt(cx, b.y + 30, 40, 'rgba(255,40,90,.6)', .7);
    glowAt(cx, b.y + 30, 54, 'rgba(200,60,255,.45)', .7);
    spr(k, f, cx, by + 2, b.face < 0, 1.15, wh || blink);
  } else drawBossX(b, wh, blink);
}
function shieldBubble(cx, cy, r0) {
  const r = r0 + Math.round(Math.sin(time * 4) * 2);
  bx.globalCompositeOperation = 'lighter'; bx.fillStyle = 'rgba(40,180,255,.10)';
  bx.beginPath(); bx.arc(cx, cy, r, 0, 6.3); bx.fill();
  bx.strokeStyle = 'rgba(80,220,255,.75)'; bx.lineWidth = 2; bx.beginPath(); bx.arc(cx, cy, r, 0, 6.3); bx.stroke();
  bx.fillStyle = 'rgba(160,240,255,.8)';
  for (let i = 0; i < 10; i++) { const a = time * 1.2 + i * 0.628; bx.fillRect(Math.round(cx + Math.cos(a) * r) - 1, Math.round(cy + Math.sin(a) * r) - 1, 3, 3); }
  bx.globalCompositeOperation = 'source-over';
}
function pxBall(x, y, c1, c2, c3) {
  x = Math.round(x); y = Math.round(y);
  bx.fillStyle = c1; bx.fillRect(x - 5, y - 4, 10, 8); bx.fillRect(x - 4, y - 5, 8, 10);
  bx.fillStyle = c2; bx.fillRect(x - 3, y - 3, 6, 6); bx.fillStyle = c3; bx.fillRect(x - 1, y - 2, 2, 2);
}
function drawProjs() {
  for (const q of projs) {
    if (q.type === 'lightwave') continue;
    if (q.type === 'laser') { glowAt(q.x, q.y, 40, 'rgba(255,40,90,.6)', .8); bx.fillStyle = '#ff2b5a'; bx.fillRect(Math.round(q.x - q.hw), Math.round(q.y - q.hh), q.hw * 2, q.hh * 2); bx.fillStyle = '#ffe0e8'; bx.fillRect(Math.round(q.x - q.hw + 3), Math.round(q.y) - 1, q.hw * 2 - 6, 2); }
    else if (q.type === 'bolt') { glowAt(q.x, q.y, 14, 'rgba(255,220,60,.6)', .8); spr('shot', Math.floor(time * 15), q.x, q.y + 6, q.vx < 0); }
    else if (q.type === 'fire') { glowAt(q.x, q.y, 26, 'rgba(255,110,30,.75)', .9); const x = Math.round(q.x), y = Math.round(q.y); bx.fillStyle = '#c03010'; bx.fillRect(x - 7, y - 5, 14, 10); bx.fillRect(x - 5, y - 7, 10, 14); bx.fillStyle = '#ff8a20'; bx.fillRect(x - 5, y - 4, 10, 8); bx.fillStyle = '#ffe070'; bx.fillRect(x - 3, y - 3, 6, 6); }
    else if (q.type === 'hfire') { glowAt(q.x, q.y, 24, 'rgba(255,120,30,.7)', .9); bx.save(); bx.translate(Math.round(q.x), Math.round(q.y)); bx.rotate(Math.atan2(q.vy, q.vx)); spr('hfireball', Math.floor(time * 12), 0, 7, false); bx.restore(); }
    else if (q.type === 'wormball') { glowAt(q.x, q.y, 16, 'rgba(255,120,30,.7)', .8); spr('worm_ball', Math.floor(time * 12), q.x, q.y + 23, q.vx < 0); }
    else if (q.type === 'spore') { glowAt(q.x, q.y, 10, 'rgba(255,90,160,.5)', .6); spr('mush_proj', Math.floor(time * 10), q.x, q.y + 25); }
    else if (q.type === 'eyeball') { glowAt(q.x, q.y, 14, 'rgba(255,90,40,.6)', .8); pxBall(q.x, q.y, '#7a2010', '#ff6a30', '#ffe0a0'); }
    else if (q.type === 'bomb') { spr('bomb', Math.floor(time * 10), q.x, q.y + 50); if (q.fuse < 0.6 && Math.floor(time * 16) % 2) glowAt(q.x, q.y, 14, 'rgba(255,60,40,.8)', .9); }
    else if (q.type === 'icicle') { const x = Math.round(q.x), y = Math.round(q.y); bx.fillStyle = '#e8fbff'; bx.fillRect(x - 4, y - 12, 8, 6); bx.fillStyle = '#9fdcff'; bx.fillRect(x - 3, y - 6, 6, 8); bx.fillStyle = '#6fb8e8'; bx.fillRect(x - 1, y + 2, 2, 8); }
    else if (q.type === 'bubble' && curWorld === 13) { glowAt(q.x, q.y, 18, 'rgba(120,170,255,.7)', .9); bx.globalCompositeOperation = 'lighter'; bx.drawImage(ptexC('glow', '#8fb4ff'), q.x - 10, q.y - 10, 20, 20); bx.drawImage(ptexC('dot', '#cfe0ff', true), q.x - 4, q.y - 4, 8, 8); bx.globalCompositeOperation = 'source-over'; if (Math.random() < .5) parts.push({ x: q.x, y: q.y, vx: rnd(-20, 20), vy: rnd(-40, -10), life: .4, max: .4, c: '#8fb4ff', s: 1, g: -20 }); }
    else if (q.type === 'bubble') { glowAt(q.x, q.y, 14, 'rgba(120,240,255,.6)', .8); bx.strokeStyle = '#d8fbff'; bx.lineWidth = 1.5; bx.beginPath(); bx.arc(Math.round(q.x), Math.round(q.y), 7, 0, 6.3); bx.stroke(); bx.fillStyle = 'rgba(160,240,255,.35)'; bx.fill(); bx.fillStyle = '#ffffff'; bx.fillRect(Math.round(q.x) - 3, Math.round(q.y) - 4, 2, 2); }
    else if (q.type === 'ring') { glowAt(q.x, q.y, 20, 'rgba(255,220,120,.7)', .9); bx.save(); bx.translate(Math.round(q.x), Math.round(q.y)); bx.rotate(time * 18); bx.strokeStyle = '#ffd34d'; bx.lineWidth = 3; bx.beginPath(); bx.arc(0, 0, 9, 0, 6.3); bx.stroke(); bx.fillStyle = '#fff4c0'; for (let i = 0; i < 4; i++) { bx.rotate(Math.PI / 2); bx.fillRect(9, -2, 5, 4); } bx.restore(); }
    else if (q.type === 'sandblock') { glowAt(q.x, q.y, 18, 'rgba(255,200,90,.6)', .7); const x = Math.round(q.x), y = Math.round(q.y); bx.fillStyle = '#7a5a20'; bx.fillRect(x - 10, y - 10, 20, 20); bx.fillStyle = '#e0b060'; bx.fillRect(x - 8, y - 8, 16, 16); bx.fillStyle = '#fff0c0'; bx.fillRect(x - 6, y - 6, 5, 3); if (Math.random() < .5) parts.push({ x: q.x + rnd(-8, 8), y: q.y - 8, vx: 0, vy: -20, life: .3, max: .3, c: '#e8c070', s: 2, g: 0 }); }
    else if (q.type === 'feather') { glowAt(q.x, q.y, 12, 'rgba(255,255,220,.6)', .8); const x = Math.round(q.x), y = Math.round(q.y); bx.fillStyle = '#ffffff'; bx.fillRect(x - 2, y - 10, 4, 16); bx.fillStyle = '#ffd34d'; bx.fillRect(x - 1, y - 12, 2, 22); }
    else if (q.type === 'clock') {
      glowAt(q.x, q.y, 18, 'rgba(200,100,255,.7)', .8); const x = Math.round(q.x), y = Math.round(q.y);
      bx.fillStyle = '#2a1050'; bx.fillRect(x - 6, y - 7, 12, 14); bx.fillRect(x - 7, y - 6, 14, 12); bx.fillStyle = '#ffd34d'; bx.fillRect(x - 5, y - 5, 10, 10); bx.fillStyle = '#2a1050'; bx.fillRect(x, y - 4, 1, 4); bx.fillRect(x, y, 3, 1);
    } else { const c = curWorld === 2 || curWorld === 6 ? ['#ff6a1a', '#ffd040'] : ['#7dea5a', '#eaffc0']; glowAt(q.x, q.y, 12, curWorld === 2 || curWorld === 6 ? 'rgba(255,110,30,.6)' : 'rgba(150,255,90,.55)', .8); pxBall(q.x, q.y, c[0], c[1], '#ffffff'); }
  }
  for (const w of waves) {
    const x = Math.round(w.x), y = w.y, hgt = 26 + Math.round(Math.sin(w.t * 30) * 3);
    glowAt(x, y - 12, 30, w.col === '#cfefff' ? 'rgba(170,230,255,.5)' : w.col === '#d070ff' ? 'rgba(200,100,255,.5)' : 'rgba(170,255,100,.45)', .7);
    const c = w.col === '#cfefff' ? ['#6fb8e8', '#9fdcff', '#ffffff'] : w.col === '#d070ff' ? ['#5a2a90', '#a060ff', '#f0d0ff'] : ['#8a6a40', '#c8a070', '#e8d8a8'];
    bx.fillStyle = c[0]; bx.fillRect(x - 10, y - hgt * .5, 20, hgt * .5); bx.fillStyle = c[1]; bx.fillRect(x - 7, y - hgt * .8, 14, hgt * .3); bx.fillStyle = c[2]; bx.fillRect(x - 4, y - hgt, 8, hgt * .3);
  }
  for (const w of warns) {
    const a = 0.3 + 0.4 * Math.abs(Math.sin(time * 14)), ice = w.kind === 'ice';
    bx.fillStyle = (ice ? 'rgba(150,220,255,' : 'rgba(255,60,30,') + (a * 0.18) + ')'; bx.fillRect(Math.round(w.x) - 12, cam.y, 24, level.arena.floor - cam.y);
    bx.fillStyle = (ice ? 'rgba(170,230,255,' : 'rgba(255,90,40,') + a + ')'; bx.fillRect(Math.round(w.x) - 18, level.arena.floor - 3, 36, 2); bx.fillRect(Math.round(w.x) - 12, level.arena.floor - 5, 24, 2);
  }
}
function playerAnim() {
  if (p.dead) return ['K_death', Math.min(1, Math.floor(p.anim * 4))];
  if (p.stun > 0) return ['K_hit', 0];
  if (p.dashT > 0) return ['K_dash', 0];
  if (p.atkT > 0) { const t = 0.3 - p.atkT; return [p.atkN ? 'K_atk2' : 'K_atk1', Math.min(3, Math.floor(t / 0.075))]; }
  if (p.hook) return ['K_jump', 0];
  if (p.wall) return ['K_wall', 0];
  if (!p.onGround) return [p.vy < 0 ? 'K_jump' : 'K_fall', 0];
  if (Math.abs(p.vx) > 30) return ['K_run', Math.floor(p.anim * (Math.abs(p.vx) > 400 ? 16 : 13))];
  return ['K_idle', Math.floor(p.anim * 4)];
}
function drawPlayer() {
  for (const t of trails) if (t.dk || !HDOK()) spr(t.dk ? 'S_dash' : 'K_dash', 0, t.x + p.w / 2, t.y + p.h + 2, t.face < 0, t.dk ? 1.15 : 1, true, t.life / 0.22 * 0.45);
  if (!p.dead && p.inv > 0 && p.dashT <= 0 && Math.floor(time * 20) % 2 === 0) return;
  const [k, f] = playerAnim();
  if (p.onGround) { bx.fillStyle = 'rgba(0,0,0,.28)'; bx.fillRect(Math.round(p.x + 1), Math.round(p.y + p.h - 1), p.w - 2, 2); }
  const face = p.wall ? -p.wall : p.face;
  if (slowT > 0) glowAt(p.x + p.w / 2, p.y + p.h / 2, 40, 'rgba(120,200,255,.35)', .6);
  lightAt(p.x + p.w / 2, p.y + p.h / 2, 150, LOOK[curWorld].plc, LOOK[curWorld].pl);
  if (!HDOK()) { const m = meta(k), n = m.n, fr = ((f % n) + n) % n, fl = face < 0, src = flash > 0.08 && p.stun > 0 ? whiteOf(k, fl) : fl ? flipped(k) : SPR[k];
    const fi = fl ? n - 1 - fr : fr, ax = fl ? m.fw - m.ax : m.ax, sy = p.sq || 1, sx = 1 / Math.sqrt(sy), cx = p.x + p.w / 2, by = p.y + p.h + 2;
    bx.drawImage(src, fi * m.fw, 0, m.fw, m.fh, Math.round(cx - ax * sx), Math.round(by - m.ay * sy), Math.round(m.fw * sx), Math.round(m.fh * sy)); }
  if (p.atkT > 0 && p.atkT < 0.24) {
    glowAt(p.x + p.w / 2 + p.face * 40, p.y + p.h * .4, 44, 'rgba(200,240,255,.35)', .7);
    if (p.air) { const t = (0.24 - p.atkT) / 0.2, cx = p.x + p.w / 2, cy = p.y + p.h + 6; bx.strokeStyle = 'rgba(220,250,255,' + (1 - t) + ')'; bx.lineWidth = 3; bx.beginPath(); bx.arc(cx, cy - 10, 26, 0.2 + t, 2.9 - t * .3); bx.stroke(); }
  }
}
function drawLava() {
  const lv = level.lava;
  if (!lv || lv.y > cam.y + VH + 20) return;
  const L = SPR.lava, fr = Math.floor(time * 6) % 4, y0 = Math.round(lv.y) - 4;
  const x0 = Math.floor(cam.x / 16) * 16 - 16 + (Math.floor(time * 20) % 16);
  for (let x = x0 - 16; x < cam.x + VW + 16; x += 16) bx.drawImage(L, fr * 16, 0, 16, 32, x, y0, 16, 32);
  if (cam.y + VH > y0 + 32) { bx.fillStyle = '#9a2a10'; bx.fillRect(cam.x - 4, y0 + 32, VW + 8, cam.y + VH - y0); }
  glowAt(cam.x + VW / 2, y0, VW * 0.6, 'rgba(255,90,20,.35)', .8);
  for (let x = cam.x; x < cam.x + VW + 100; x += 120) lightAt(x, y0, 150, 'rgba(255,120,40,1)', .5);
}
function drawParticles() {
  for (const q of parts) { bx.globalAlpha = q.dust ? Math.max(0, q.life / q.max) * .7 : Math.min(1, q.life / q.max * 1.5); bx.fillStyle = q.c; bx.fillRect(Math.round(q.x), Math.round(q.y), q.s, q.s); }
  bx.globalAlpha = 1;
  for (const e of fx) spr(e.k, Math.floor(e.t * e.fps), e.x, e.y, e.flip, e.s);
}
function drawWorld() {
  bx.globalAlpha = 1; bx.globalCompositeOperation = 'source-over';
  drawDecor(); drawCritters(); drawLife();
  for (const c of level.checks) drawCheck(c);
  drawGoal();
  bx.globalAlpha = 1; bx.globalCompositeOperation = 'source-over';
  for (const s of level.plats) drawPlat(s);
  bx.globalAlpha = 1; bx.globalCompositeOperation = 'source-over';
  drawContactShadows();
  drawHazards();
  for (const l of level.levers) drawLever(l);
  for (const g of level.gems) drawGem(g);
  for (const c of level.cherries) drawCherry(c);
  drawRelic();
  drawPlates(); drawAnchors(); drawCrystals(); drawLiveWorld(); drawSwarms(); extraLights(); drawButterfly();
  for (const e of level.enemies) if (!e.dead && onScreen(e.x, e.w)) drawEnemy(e);
  drawBoss(); drawEcho(); drawPlayer(); drawTic(); drawProjs(); drawAbilWorld(); drawParticles(); drawLava();
  if (arenaLock && level.arena && boss && !boss.done) {
    const A = level.arena, c = WORLDS[curWorld].c;
    for (const x of [A.x1 - 3, A.x2 + 1]) {
      bx.globalAlpha = 0.35 + Math.sin(time * 6 + x) * 0.15; bx.fillStyle = c; bx.fillRect(x, A.floor - 520, 2, 520);
      for (let y = A.floor - 520 + ((time * 80) % 24); y < A.floor; y += 24) bx.fillRect(x - 1, Math.round(y), 4, 6);
      bx.globalAlpha = 1; glowAt(x, A.floor - 200, 60, hexToRgba(c, .35), .6);
    }
  }
}
