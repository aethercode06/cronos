// =====================================================================
//  LÓGICA: jugador, enemigos, peligros, jefes
// =====================================================================
const MOVE = 290, JUMP = 600, GRAV = 1750, DASH = 760;
const PW = 22, PH = 48;
let state = 'loading', diffIdx = 1, curWorld = 0, curAct = 0;
let level = null, p = null, boss = null;
let cam = { x: 0, y: 0 }, time = 0, score = 0, stageScore0 = 0;
let shake = 0, hitStop = 0, fade = 0, flash = 0, flashCol = '255,255,255', arenaLock = false, bossIntro = 0;
let bannerTxt = '', bannerSub = '', bannerC = '#fff', bannerT = 0, levelTime = 0, clearInfo = null;
let projs = [], waves = [], parts = [], trails = [], floats = [], warns = [], fx = [], amb = [], cars = [];
let dim = 0, shiftCD = 0, shiftFx = 0, slowT = 0, loreT = 0, hintTxt = '', hintT = 0, lightning = 0;
const WD_ = () => WORLDS[curWorld];

// ---------------- Partículas ----------------
function burst(x, y, c, n, sp, g, life, size) {
  sp = sp || 160; g = g === undefined ? 300 : g; life = life || 0.6; size = size || 2;
  for (let i = 0; i < n; i++) {
    const a = Math.random() * Math.PI * 2, v = Math.random() * sp;
    parts.push({ x, y, vx: Math.cos(a) * v, vy: Math.sin(a) * v, life: life * rnd(.5, 1), max: life, c, s: Math.random() < .3 ? size + 1 : size, g });
  }
  if (parts.length > 800) parts.splice(0, parts.length - 800);
}
const DUSTC = ['#e8dcc0', '#9a9aaa', '#8a6a60', '#d8b0a0', '#a090b0', '#e0f0ff', '#806060', '#c0a0ff', '#9fe8ff', '#f0d090', '#ffffff', '#e0a0ff', '#8aa080', '#9aa4c0', '#c0a0ff', '#b0c0b8', '#c8a878', '#a0a8d0'];
function dust(x, y, n, dir) {
  for (let i = 0; i < (n || 6); i++) parts.push({ x: x + rnd(-6, 6), y: y - rnd(0, 3), vx: (dir || 0) * rnd(20, 80) + rnd(-50, 50), vy: rnd(-60, -10), life: rnd(.25, .45), max: .45, c: DUSTC[curWorld], s: Math.random() < .5 ? 3 : 2, g: -20, dust: true });
}
const STEPC = [['#9be35a', '#5fb04a'], ['#b0b8c8', '#ffb060'], ['#ffb040', '#ff6a1a'], ['#ffb0c8', '#ffd0a0'], ['#c8bca8', '#a090b0'], ['#ffffff', '#cfefff'], ['#ff8a30', '#704040'], ['#ffd34d', '#d0a0ff'], ['#9ff8ff', '#ff8ad8'], ['#ffe0a0', '#e0b060'], ['#ffffff', '#ffe9a0'], ['#ff6ad5', '#7fe9ff'], ['#6a8a50', '#a0c070'], ['#a0a8c8', '#7fb0ff'], ['#d0a0ff', '#a080ff'], ['#c8d8d0', '#90a8a0'], ['#e0c090', '#a08060'], ['#c0c8e8', '#8090c0']];
function stepFx(x, y) {
  const c = STEPC[curWorld];
  for (let i = 0; i < 3; i++) parts.push({ x: x + rnd(-4, 4), y: y - 1, vx: -p.face * rnd(20, 70) + rnd(-20, 20), vy: rnd(-90, -30), life: rnd(.25, .5), max: .5, c: c[i % 2], s: curWorld === 0 || curWorld === 3 ? 2 : 1, g: VWI(curWorld) === 5 ? 60 : 300 });
  if (curWorld === 7) glowAt(x, y - 2, 6, 'rgba(255,211,77,.5)', .5);
}
function addFx(k, x, y, fps, flip, scale) { fx.push({ k, x, y, t: 0, fps: fps || 14, flip: !!flip, s: scale || 1 }); }
function addFloat(x, y, t, c, s) { floats.push({ x, y, t, c: c || '#fff', life: 1.1, s: s || 18 }); }
function updateParticles(dt) {
  for (let i = parts.length - 1; i >= 0; i--) {
    const q = parts[i]; q.life -= dt;
    if (q.life <= 0) { parts.splice(i, 1); continue; }
    q.vy += q.g * dt; q.x += q.vx * dt; q.y += q.vy * dt; q.vx *= (1 - 2.5 * dt);
  }
  for (let i = fx.length - 1; i >= 0; i--) { const e = fx[i]; e.t += dt; if (e.t * e.fps >= meta(e.k).n) fx.splice(i, 1); }
  for (let i = trails.length - 1; i >= 0; i--) { trails[i].life -= dt; if (trails[i].life <= 0) trails.splice(i, 1); }
  for (let i = floats.length - 1; i >= 0; i--) { const f = floats[i]; f.life -= dt; f.y -= 30 * dt; if (f.life <= 0) floats.splice(i, 1); }
}

// ---------------- Plataformas ----------------
function isSolid(s) {
  return s.k === 'solid' || (s.k === 'door' && !s.plate.on) || s.k === 'move' || s.k === 'bounce' || (s.k === 'laser' && s.on) || (s.k === 'break' && s.st < 2) || (s.k === 'phase' && s.ph === dim);
}
function isWall(s) { return (s.k === 'solid' && !s.float) || (s.k === 'door' && !s.plate.on) || (s.k === 'phase' && s.ph === dim && s.h > 16); }
function updatePlats(dt) {
  for (const s of level.plats) {
    if (s.k === 'move') {
      s.t += dt; const u = (1 - Math.cos(s.t * s.spd)) / 2;
      const nx = lerp(s.ax, s.bx, u), ny = lerp(s.ay, s.by, u);
      s.dx = nx - s.x; s.dy = ny - s.y; s.x = nx; s.y = ny;
    } else if (s.k === 'laser') {
      const c = (time + s.phase) % 3.2; s.on = c < 2; s.warn = c > 1.55 && c < 2;
    } else if (s.k === 'break') {
      if (s.st === 1) { s.t -= dt; if (s.t <= 0) { s.st = 2; s.t = 3; s.vy = 0; s.oy = 0; sfx('crumble', .7); burst(s.x + s.w / 2, s.y + 8, '#5a3030', 14, 120, 600, .8, 3); } }
      else if (s.st === 2) {
        s.t -= dt; s.vy += 900 * dt; s.oy += s.vy * dt;
        if (s.t <= 0 && !(p && overlap(p, { x: s.x, y: s.y, w: s.w, h: s.h }))) { s.st = 0; s.oy = 0; burst(s.x + s.w / 2, s.y + 8, '#ffffff', 8, 60, 0, .4, 2); }
      }
    } else if (s.k === 'bounce' && s.sq > 0) s.sq -= dt;
  }
}
function groundBelow(x, y, maxd) {
  for (const s of level.plats) if (isSolid(s) && x >= s.x && x <= s.x + s.w && s.y >= y - 4 && s.y - y < (maxd || 12)) return s;
  return null;
}

// ---------------- Peligros ----------------
function updateHazards(dt) {
  for (const h of level.hazards) {
    if (h.k === 'jet') {
      const c = (time + h.ph) % 2.4; const was = h.on; h.on = c > 1.8; h.warn = c > 1.4 && c <= 1.8;
      if (h.on && !was && Math.abs(h.x - p.x) < 400) sfx('fire', .35);
      if (h.on && Math.random() < .8) parts.push({ x: h.x + 10 + rnd(-6, 6), y: GY - rnd(0, 66), vx: rnd(-20, 20), vy: rnd(-120, -40), life: .35, max: .35, c: Math.random() < .5 ? '#ffd040' : '#ff6a1a', s: 3, g: -100 });
      if (h.on && !p.dead && overlap(p, h)) hurt(18, h.x + 10);
    } else if (h.k === 'icicle') {
      if (h.st === 0 && Math.abs(p.x + p.w / 2 - (h.x + 6)) < 34 && p.y > h.y && p.y - h.y < 260) { h.st = 1; h.t = 0.35; sfx('ice', .4, 1.4); }
      else if (h.st === 1) { h.t -= dt; if (h.t <= 0) h.st = 2; }
      else if (h.st === 2) {
        h.vy += 1500 * dt; h.y += h.vy * dt;
        if (!p.dead && overlap(p, h)) { hurt(15, h.x + 6); h.st = 3; }
        for (const s of level.plats) if (s.k === 'solid' && h.y + h.h > s.y && h.y < s.y + 8 && h.x + 6 > s.x && h.x + 6 < s.x + s.w && s.y > h.y0 + 20) { h.st = 3; break; }
        if (h.y > level.deathY) h.st = 3;
        if (h.st === 3) { burst(h.x + 6, h.y + h.h, '#cfefff', 12, 140, 500, .5, 2); sfx('ice', .5); h.t = 5; }
      } else if (h.st === 3) { h.t -= dt; if (h.t <= 0) { h.st = 0; h.y = h.y0; h.vy = 0; } }
    } else if (h.k === 'spike') {
      if (!p.dead && overlap(p, { x: h.x + 2, y: h.y + 4, w: h.w - 4, h: h.h - 4 }) && p.inv <= 0) { burst(p.x + p.w / 2, h.y, '#ffffff', 8, 120, 300, .4, 2); hazardRespawn(15); }
    }
  }
  for (const l of level.lavaStrips) if (!p.dead && p.y + p.h > l.y + 4 && p.x + p.w > l.x && p.x < l.x + l.w) { burst(p.x + p.w / 2, l.y, '#ffd040', 20, 200, 400, .7, 2); sfx('fire'); hazardRespawn(25); }
}

// ---------------- Jugador ----------------
function attackBox() { const w = p.atkN === 2 ? 96 : 76; return { x: p.face > 0 ? p.x + p.w - 4 : p.x - w + 4, y: p.y - (p.atkN === 2 ? 12 : 6), w, h: p.h + (p.atkN === 2 ? 18 : 8) }; }
function downBox() { return { x: p.x - 16, y: p.y + p.h - 8, w: p.w + 32, h: 44 }; }
function hurt(dmg, srcX) {
  if (p.inv > 0 || p.dead) return false;
  const D = DIFFS[diffIdx];
  if (p.hook) p.hook = null;
  p.hp -= dmg * D.dmg; p.inv = 0.8; p.stun = 0.28;
  p.vx = (p.x + p.w / 2 < srcX ? -1 : 1) * 340; p.vy = -360; p.noCut = true;
  p.dashT = 0; p.boostT = 0; p.atkT = 0; p.combo = 0; shake = Math.max(shake, 7); hitStop = 0.07; flash = 0.12; flashCol = '255,60,80';
  sfx('hurt'); vib(45); zoomPunch(0.022); burst(p.x + p.w / 2, p.y + 18, '#ff4060', 10, 160, 300, .5, 2);
  addFloat(p.x + p.w / 2, p.y - 8, '-' + Math.round(dmg * D.dmg), '#ff5470');
  if (p.hp <= 0) kill();
  return true;
}
function kill() {
  p.hp = 0; p.dead = true; p.deadT = 1.3; p.anim = 0; shake = 14; hitStop = 0.2; slowT = 0;
  sfx('kill'); sfx('hurt'); vib([80, 60, 200]); playMusic(null);
  burst(p.x + p.w / 2, p.y + p.h / 2, '#ff4060', 24, 200, 300, .8, 2);
}
function hazardRespawn(dmg) {
  const D = DIFFS[diffIdx];
  p.hp -= dmg * D.dmg; shake = 8; sfx('hurt'); flash = 0.15; flashCol = '255,60,80'; p.combo = 0;
  if (p.hp <= 0) { kill(); return; }
  const s = p.safe || p.respawn;
  addFloat(s.x + p.w / 2, s.y - 10, '-' + Math.round(dmg * D.dmg), '#ff5470');
  p.x = s.x; p.y = s.y; p.vx = 0; p.vy = 0; p.inv = 1.3; p.dashT = 0; p.boostT = 0;
  p.ground = null; p.onGround = false;
  if (level.lava) level.lava.y = Math.max(level.lava.y, s.y + p.h + 260);
}
function addTime(v) { if (slowT <= 0) p.time = Math.min(100, p.time + v * (1 + 0.3 * UP('time'))); }
function addCombo() {
  p.combo++; p.comboT = 2.5;
  if (p.combo === 10 || p.combo === 25 || p.combo === 50) { sfx('v_combo', .8); addFloat(p.x + p.w / 2, p.y - 30, '¡COMBO x' + p.combo + '!', '#ffd34d', 22); }
}
function mult() { return 1 + Math.min(2, Math.floor(p.combo / 5) * 0.25); }
function addScore(v) { score += Math.round(v * mult()); }
function overlapsDimBlocks(d) {
  for (const s of level.plats) if (s.k === 'phase' && s.ph === d && overlap(p, s)) return true;
  return false;
}
function updatePlayer(dt) {
  p.anim += dt;
  if (p.dead) {
    p.deadT -= dt;
    if (p.deadT <= 0) { state = 'gameover'; fade = 1; saveBest(); sfx('v_gameover'); sfx('lose', .8); }
    return;
  }
  const WD = WD_();
  p.sq = lerp(p.sq || 1, 1, Math.min(1, dt * 12)); p.hpLag = p.hpLag === undefined ? p.hp : (p.hpLag > p.hp ? Math.max(p.hp, p.hpLag - 40 * dt) : p.hp);
  p.inv = Math.max(0, p.inv - dt); p.dashCD = Math.max(0, p.dashCD - dt); p.atkCD -= dt; p.wjLock -= dt;
  if (p.comboT > 0) { p.comboT -= dt; if (p.comboT <= 0) p.combo = 0; }
  shiftCD -= dt;
  if (p.onGround && p.ground && p.ground.k === 'move') { p.x += p.ground.dx; p.y += p.ground.dy; }
  if (p.onGround && p.ground && p.ground.conv) p.x += p.ground.conv * 120 * dt;
  let dir = (act.right ? 1 : 0) - (act.left ? 1 : 0);
  if (p.wjLock > 0) dir = p.wjDir;
  if (p.stun > 0) p.stun -= dt;
  const ctrl = p.stun <= 0;
  if (ctrl && dir && p.dashT <= 0 && p.atkT <= 0) p.face = dir;
  if (pressed.jump) p.buf = 0.13; else p.buf -= dt;
  if (p.onGround) p.coyote = 0.12; else p.coyote -= dt;
  // SHIFT dimensional
  if (ctrl && pressed.shift && shiftCD <= 0 && curWorld === 0 && !arenaLock) { shiftCD = 0.6; addFloat(p.x + p.w / 2, p.y - 10, 'SHIFT dormido: recupera el 1.er fragmento', '#c0a0ff', 13); sfx('clang', .3, 1.4); }
  else if (ctrl && pressed.shift && shiftCD <= 0) {
    const nd = 1 - dim;
    if (overlapsDimBlocks(nd)) { sfx('clang', .4, 1.5); addFloat(p.x + p.w / 2, p.y - 10, '¡BLOQUEADO!', '#ff5470', 14); }
    else { dim = nd; shiftCD = 0.22; shiftFx = 0.35; sfx('shift', .7); burst(p.x + p.w / 2, p.y + p.h / 2, dim ? '#d070ff' : '#35e2ff', 16, 180, 0, .4, 2); }
  }
  // Poder del tiempo
  if (ctrl && pressed.time && p.time >= 100 && slowT <= 0) {
    slowT = 5.5; p.time = 0; sfx('slow', .9); flash = 0.25; flashCol = '120,200,255';
    addFloat(p.x + p.w / 2, p.y - 24, '¡TIEMPO RALENTIZADO!', '#9fe3ff', 18);
    if (curMusic) curMusic.playbackRate = 0.85;
  }
  if (ctrl && pressed.dash && p.dashCD <= 0) {
    if (dir) p.face = dir;
    p.dashT = 0.17; p.dashCD = dashMax(); if (p.hook) p.hook = null; p.inv = Math.max(p.inv, 0.17); p.vy = 0; p.atkT = 0; p.wall = 0;
    sfx('dash', .6); dust(p.x + p.w / 2, p.y + p.h, 6, -p.face);
  }
  if (ctrl && pressed.eco) ecoPress();
  // Zonas: viento, gravedad baja, agua, arena
  let gmul = 1, wfx = 0, wfy = 0, water = null, sand = false;
  for (const z of level.zones) if (overlap(p, z)) {
    if (z.k === 'lowgrav') gmul = 0.42;
    if (z.k === 'wind') { wfx += z.fx; wfy += z.fy; }
    if (z.k === 'water' && p.y + p.h * 0.45 > z.y) { water = z; wfx += z.fx; }
    if (z.k === 'sand') sand = true;
  }
  if (water && !p.inWater) { p.inWater = true; burst(p.x + p.w / 2, water.y, '#bff4ff', 14, 160, 400, .5, 2); sfx('bounce', .35, .6); p.dashT = 0; }
  else if (!water && p.inWater) { p.inWater = false; burst(p.x + p.w / 2, p.y + p.h, '#bff4ff', 8, 120, 400, .4, 2); }
  if (sand && p.onGround) { p.sinkT = (p.sinkT || 0) + dt; if (Math.random() < .3) parts.push({ x: p.x + rnd(0, p.w), y: p.y + p.h, vx: rnd(-20, 20), vy: rnd(-40, -10), life: .4, max: .4, c: '#e8c070', s: 2, g: 200 }); if (p.sinkT > 2.4) { p.sinkT = 0; addFloat(p.x + p.w / 2, p.y - 10, '¡LA ARENA TE TRAGÓ!', '#ffc24a', 14); hazardRespawn(12); return; } }
  else if (!sand) p.sinkT = 0;

  if (p.hook) updateHook(dt, dir);
  else {
  if (p.dashT > 0) {
    p.dashT -= dt; p.vx = p.face * DASH; p.vy = 0;
    if (trails.length === 0 || trails[trails.length - 1].life < 0.18) trails.push({ x: p.x, y: p.y, face: p.face, f: Math.floor(p.anim * 14), life: 0.22 });
    if (p.dashT <= 0) p.vx = p.face * MOVE;
  } else {
    const atkSlow = p.atkT > 0 && p.onGround ? 0.35 : 1;
    const accel = p.onGround ? (WD.ice ? 700 : 2600) : 1800;
    if (!ctrl) p.vx = approach(p.vx, 0, 600 * dt);
    else if (p.boostT > 0) {
      p.boostT -= dt; if (dir === -p.boostDir) p.boostT -= dt * 2;
      p.vx = approach(p.vx, p.boostDir * 700, 3200 * dt);
      if (trails.length === 0 || trails[trails.length - 1].life < 0.16) trails.push({ x: p.x, y: p.y, face: p.face, f: Math.floor(p.anim * 14), life: 0.2 });
    } else p.vx = approach(p.vx, dir * MOVE * atkSlow * (water ? 0.72 : sand && p.onGround ? 0.45 : 1), (water ? 1400 : accel) * dt);
    p.vx += wfx * dt;
    if (water) {
      // NADO: cada SALTO impulsa hacia arriba; cerca de la superficie, salta fuera
      if (ctrl && p.buf > 0) { p.buf = 0; const surf = p.y < water.y + 14; p.vy = surf ? -JUMP * 0.98 : -330; p.jumps = 1; p.noCut = true; sfx(surf ? 'jump' : 'dj', .35, surf ? 1 : 0.8); for (let i = 0; i < 5; i++) parts.push({ x: p.x + p.w / 2 + rnd(-6, 6), y: p.y + p.h, vx: rnd(-30, 30), vy: rnd(20, 60), life: .5, max: .5, c: '#bff4ff', s: 2, g: -200 }); }
      p.vy = Math.min(p.vy + 520 * dt, 150); if (p.vy < -420 && p.y > water.y + 30) p.vy = -420;
      if (Math.random() < .06) parts.push({ x: p.x + p.w / 2 + p.face * 6, y: p.y + 8, vx: 0, vy: -50, life: 1, max: 1, c: '#d8fbff', s: 2, g: -40 });
    } else {
    if (wfy) { p.noCut = true; p.vy += wfy * dt; if (p.vy < -420) p.vy = -420; if (Math.random() < .3) parts.push({ x: p.x + rnd(0, p.w), y: p.y + p.h, vx: 0, vy: -200, life: .3, max: .3, c: '#ffffff', s: 1, g: 0 }); }
    // Salto, doble salto y salto de pared
    if (ctrl && p.buf > 0) {
      const anc = !p.onGround && p.coyote <= 0 ? nearAnchor() : null;
      if (anc) { attachHook(anc); }
      else if (p.coyote > 0) {
        p.vy = -JUMP * (sand ? 0.78 : 1); p.jumps = 1; p.sinkT = 0; p.coyote = 0; p.buf = 0; p.onGround = false; p.ground = null; p.noCut = false; p.sq = 1.18;
        sfx('jump', .5); dust(p.x + p.w / 2, p.y + p.h, 6);
      } else if (p.wall) {
        p.vy = -JUMP * 0.95; p.vx = -p.wall * 330; p.face = -p.wall; p.wjDir = -p.wall; p.wjLock = 0.16; p.jumps = 1; p.buf = 0; p.noCut = false;
        sfx('wall', .6); dust(p.wall > 0 ? p.x + p.w : p.x, p.y + p.h * .6, 6, -p.wall); p.wall = 0;
      } else if (p.jumps < 2) {
        p.vy = -JUMP * 0.92; p.jumps = 2; p.buf = 0; p.noCut = false; p.sq = 1.14;
        sfx('dj', .5); burst(p.x + p.w / 2, p.y + p.h, '#bff4ff', 10, 120, 0, .35, 2);
      }
    }
    let g = GRAV * gmul; if (p.vy >= 0 && !wfy) p.noCut = false;
    if (!act.jump && p.vy < 0 && !p.noCut) g *= 2.3;
    if (act.jump && Math.abs(p.vy) < 90 && !wfy) g *= 0.55;
    if (p.vy > 0) g *= 1.12;
    p.vy = Math.min(p.vy + g * dt, p.wall && p.vy > 0 ? 110 : 900);
    }
  }
  if (ctrl && pressed.attack && p.atkCD <= 0 && p.dashT <= 0) {
    p.air = !p.onGround;
    p.atkN = (!p.air && time - (p.lastAtk || -9) < 0.6) ? (p.atkN + 1) % 3 : 0; p.lastAtk = time;
    p.atkT = p.atkN === 2 ? 0.38 : 0.3; p.atkCD = p.atkN === 2 ? 0.42 : 0.24; p.hitSet = new Set(); p.pogoDone = false;
    if (p.atkN === 2) { p.vx += p.face * 220; sfx('swing', 1, .75); burst(p.x + p.w / 2 + p.face * 20, p.y + 24, '#ffd34d', 8, 140, 0, .3, 2); } else sfx('swing', .7, p.atkN ? 1.12 : 1);
    if (p.air && p.vy > 0) p.vy *= 0.4;
  }
  if (p.atkT > 0) { p.atkT -= dt; if (p.atkT < 0.24 && p.atkT > 0.04) doAttack(); }

  const sol = level.plats.filter(isSolid);
  p.x += p.vx * dt;
  let touchWall = 0;
  for (const s of sol) {
    if (!isWall(s)) continue;
    if (p.x < s.x + s.w && p.x + p.w > s.x && p.y + p.h > s.y + 2 && p.y < s.y + s.h - 2) {
      if (p.y + p.h - s.y <= 12 && p.vy >= -50 && !level.plats.some(o => o !== s && isWall(o) && o.x < p.x + p.w && o.x + o.w > p.x && o.y + o.h > s.y - p.h && o.y < s.y)) { p.y = s.y - p.h; continue; }
      if (p.x + p.w / 2 < s.x + s.w / 2) { p.x = s.x - p.w; touchWall = 1; } else { p.x = s.x + s.w; touchWall = -1; }
      if (s.k === 'door') touchWall = 0;
      if (p.dashT <= 0) p.vx = 0;
    }
  }
  // contacto con pared para deslizarse
  if (!touchWall && !p.onGround) for (const s of sol) {
    if (!isWall(s) || s.k === 'door' || p.y + p.h <= s.y + 6 || p.y >= s.y + s.h) continue;
    if (Math.abs(p.x + p.w - s.x) < 2) touchWall = 1; else if (Math.abs(p.x - (s.x + s.w)) < 2) touchWall = -1;
  }
  const prevY = p.y, wasGround = p.onGround, fallSpeed = p.vy;
  p.y += p.vy * dt; p.onGround = false;
  let land = null;
  for (const s of sol) {
    if (p.x < s.x + s.w && p.x + p.w > s.x && p.y + p.h > s.y && p.y < s.y + s.h) {
      const tol = 8 + Math.abs(s.dy || 0);
      if (p.vy >= 0 && prevY + p.h <= s.y + tol) { p.y = s.y - p.h; p.vy = 0; land = s; }
      else if (p.vy < 0 && isWall(s) && prevY >= s.y + s.h - tol) {
        const oL = p.x + p.w - s.x, oR = s.x + s.w - p.x;
        if (oL <= 8) { p.x = s.x - p.w; continue; } if (oR <= 8) { p.x = s.x + s.w; continue; }
        p.y = s.y + s.h; p.vy = 0;
      }
    }
  }
  const pushing = touchWall && ((touchWall > 0 && act.right) || (touchWall < 0 && act.left));
  const newWall = !land && touchWall && (pushing || (p.wall === touchWall)) && p.dashT <= 0 ? touchWall : 0;
  if (newWall && !p.wall) { p.jumps = 1; }
  p.wall = newWall;
  if (p.wall && p.vy > 60 && Math.random() < .4) parts.push({ x: p.wall > 0 ? p.x + p.w : p.x, y: p.y + rnd(10, 40), vx: -p.wall * 20, vy: -20, life: .3, max: .3, c: DUSTC[curWorld], s: 2, g: 0, dust: true });
  if (land) {
    if (!wasGround && fallSpeed > 250) p.landT = 0.14;
    if (!wasGround && fallSpeed > 380) { dust(p.x + p.w / 2, p.y + p.h, 8); sfx('step', .45); p.sq = 0.8; if (fallSpeed > 700) vib(8); }
    p.onGround = true; p.ground = land; p.jumps = 0;
    if (land.k === 'bounce') {
      p.vy = -1000; p.onGround = false; p.ground = null; p.jumps = 1; p.noCut = true; land.sq = 0.3;
      sfx('bounce', .8); burst(land.x + land.w / 2, land.y, '#ff7ab0', 12, 140, 300, .5, 2);
    } else if (land.k === 'break' && land.st === 0) { land.st = 1; land.t = 0.45; sfx('crumble', .3, 1.6); }
    else if (land.k === 'solid' && !land.conv && p.inv <= 0.5) {
      const cx = p.x + p.w / 2, near = level.hazards.some(h => (h.k === 'spike' || h.k === 'jet') && Math.abs(h.x + h.w / 2 - cx) < h.w / 2 + 50) || level.lavaStrips.some(l => cx > l.x - 50 && cx < l.x + l.w + 50);
      if (!near && cx > land.x + 12 && cx < land.x + land.w - 12) p.safe = { x: p.x, y: p.y };
    }
  } else p.ground = null;
  if (p.onGround && Math.abs(p.vx) > 60) { p.stepT -= dt; if (p.stepT <= 0) { p.stepT = 0.26; sfx('step', .14, VWI(curWorld) === 5 ? 1.3 : VWI(curWorld) === 1 || curWorld === 7 ? 1.15 : 1); stepFx(p.x + p.w / 2 - p.face * 6, p.y + p.h); } } else p.stepT = 0;
  if (p.onGround) for (const b of level.plats) {
    if (b.k === 'boost' && p.x + p.w > b.x && p.x < b.x + b.w && Math.abs(p.y + p.h - (b.y + b.h)) < 3) {
      if (p.boostT <= 0.05) sfx('dash', .8, 1.3);
      p.boostT = 0.75; p.boostDir = b.dir;
    }
  }
  }
  p.x = clamp(p.x, 0, level.width - p.w);
  if (arenaLock) p.x = clamp(p.x, level.arena.x1, level.arena.x2 - p.w);
  if (p.y > level.deathY) hazardRespawn(20);
  else if (level.lava && p.y + p.h > level.lava.y + 6) { burst(p.x + p.w / 2, level.lava.y, '#ffd040', 20, 200, 400, .7, 2); sfx('fire'); hazardRespawn(30); }
  // Recolectables
  const mag = UP('magnet') ? 110 : 0;
  for (const g of level.gems) {
    if (g.taken) continue;
    if (mag) { const dx = p.x + p.w / 2 - g.x, dy = p.y + p.h / 2 - g.y, d = Math.hypot(dx, dy); if (d < mag) { g.x += dx / d * 420 * dt; g.y += dy / d * 420 * dt; } }
    if ((p.x < g.x + 9 && p.x + p.w > g.x - 9 && p.y < g.y + 9 && p.y + p.h > g.y - 9) || Math.hypot(tic.x - g.x, tic.y - g.y) < 16) {
      g.taken = true; addScore(100); gemToHud(g.x, g.y); addTime(3); sfx('gem', .45);
      addFx('sparkle', g.x, g.y + 16, 18); addFloat(g.x, g.y - 12, '+' + Math.round(100 * mult()), '#ffe066', 16);
    }
  }
  for (const c of level.cherries) {
    if (c.taken) continue;
    if (p.x < c.x + 10 && p.x + p.w > c.x - 10 && p.y < c.y + 10 && p.y + p.h > c.y - 10) {
      const hv = diffIdx >= 1 ? 12 : 20; c.taken = true; p.hp = Math.min(p.maxHp, p.hp + hv); addScore(50); sfx('heal', .5);
      addFx('sparkle', c.x, c.y + 16, 18); addFloat(c.x, c.y - 12, tr('+20 VIDA').replace('20', hv), '#ff7ab0', 16);
    }
  }
  const rl = level.relic;
  if (rl && !rl.taken && Math.abs(p.x + p.w / 2 - rl.x) < 16 && Math.abs(p.y + p.h / 2 - rl.y) < 30) {
    rl.taken = true; addScore(1000); sfx('relic', .8); flash = 0.2; flashCol = '255,220,120'; p.time = 100;
    burst(rl.x, rl.y, '#ffe080', 30, 220, 0, .8, 2); addFloat(rl.x, rl.y - 20, '¡RELOJ DE ARENA SECRETO!', '#ffd34d', 20);
  }
  for (const c of level.checks) {
    if (!c.on && overlap(p, c)) {
      c.on = true; p.respawn = { x: c.x, y: c.y + c.h - p.h }; p.safe = { x: c.x, y: c.y + c.h - p.h };
      p.hp = Math.min(p.maxHp, p.hp + (diffIdx >= 1 ? 0 : 10)); sfx('check', .6);
      burst(c.x + 12, c.y + 6, '#9bffb0', 16, 140, 60, .8, 2);
      addFloat(c.x + 12, c.y - 18, 'PUNTO DE CONTROL', '#9bffb0', 16); tSay(TICQ.check[Math.floor(Math.random() * 2)], 2.2);
      for (let i = 0; i < 24; i++) { const a = i / 24 * 6.283; parts.push({ x: c.x + 12, y: c.y + 10, vx: Math.cos(a) * 140, vy: Math.sin(a) * 140, life: .6, max: .6, c: i % 2 ? '#9bffb0' : '#ffffff', s: 2, g: 0 }); }
    }
  }
  updatePlates(dt);
  for (const h of level.hints) if (!h.shown && p.x > h.x && p.x < h.x + 400) { h.shown = true; hintTxt = h.text; hintT = 5.5; sfx('type', .5); }
  if (level.goal && overlap(p, level.goal)) stageClear();
  const A = level.arena;
  if (A && !arenaLock && p.x > A.x1 + 90) {
    arenaLock = true; p.respawn = { x: A.x1 + 60, y: A.floor - p.h }; p.safe = p.respawn;
    spawnBoss(); bossIntro = 2.8; dim = 0; p.hook = null;
    setView(ARW(), ARH); updateCamera(0, true);
    playMusic(curWorld >= 6 ? 'final' : 'boss');
    sfx(curWorld === 7 || curWorld === 11 ? 'v_final' : 'v_ready'); sfx('alert', .6); shake = 8; slowT = 0;
    if (BOSSL[curWorld] && BOSSL[curWorld].length) sayLines(BOSSL[curWorld], true);
  }
}
function pogo() {
  if (p.pogoDone) return; zoomPunch(0.012); vib(10);
  p.pogoDone = true; p.vy = -560; p.jumps = 1; p.dashCD = 0; p.noCut = true;
  sfx('pogo', .7); hitStop = Math.max(hitStop, 0.04); burst(p.x + p.w / 2, p.y + p.h + 8, '#ffffff', 8, 140, 200, .3, 2);
}
function hitEnemyBox(hb) {
  let hit = false;
  for (const e of level.enemies) if (!e.dead && !p.hitSet.has(e) && overlap(hb, e) && enemyHittable(e)) { p.hitSet.add(e); damageEnemy(e, hb); hit = true; }
  return hit;
}
function enemyHittable(e) { return !(e.b === 'ghost' && dim === 0) && !(e.b === 'riser' && e.st === 'buried'); }
function doAttack() {
  const hb = attackBox();
  hitEnemyBox(hb); hitCrystals(hb); hitLive(hb);
  if (p.air) {
    const db = downBox();
    hitCrystals(db); hitLive(db);
    if (hitEnemyBox(db)) pogo();
    for (const h of level.hazards) if (h.k === 'spike' && overlap(db, h)) { pogo(); break; }
    if (boss && !boss.dying && bossIntro <= 0 && overlap(db, boss) && !p.hitSet.has(boss)) { hitBoss(db, true); pogo(); }
  }
  for (let i = projs.length - 1; i >= 0; i--) {
    const q = projs[i];
    if (q.type !== 'laser' && q.type !== 'breath' && overlap(hb, { x: q.x - q.hw, y: q.y - q.hh, w: q.hw * 2, h: q.hh * 2 })) {
      burst(q.x, q.y, '#ffffff', 8, 160, 0, .3, 2); projs.splice(i, 1); addScore(10); addTime(2); sfx('clang', .5); addFloat(q.x, q.y - 10, 'PARRY', '#35e2ff', 15);
    }
  }
  for (const l of level.levers) {
    if (!l.on && overlap(hb, l)) {
      l.on = true; sfx('lever'); burst(l.x + l.w / 2, l.y + 10, '#9bffb0', 12, 140, 200, .5, 2);
      addFloat(l.x + l.w / 2, l.y - 14, '¡PALANCA!', '#9bffb0', 16);
      if (boss && boss.type === 2 && !boss.dying && level.levers.every(v => v.on)) {
        boss.vulnT = 5.5; shake = 12; sfx('shield'); hitStop = 0.12; flash = 0.2; flashCol = '120,220,255';
        addFloat(boss.x + boss.w / 2, boss.y - 24, '¡ESCUDO ROTO!', '#35e2ff', 24);
      }
    }
  }
  if (boss && !boss.dying && !boss.done && bossIntro <= 0 && !p.hitSet.has(boss) && overlap(hb, boss)) hitBoss(hb, false);
}
function hitBoss(hb, fromAbove) {
  p.hitSet.add(boss);
  const b = boss, behind = (p.x + p.w / 2 - (b.x + b.w / 2)) * b.face < 0;
  if (b.type === 2 && b.vulnT <= 0) { burst(hb.x + hb.w / 2, hb.y + hb.h / 2, '#35e2ff', 8, 160, 0, .3, 2); sfx('clang', .7); addFloat(b.x + b.w / 2, b.y - 10, 'ESCUDO', '#35e2ff'); return; }
  if (b.type === 4 && b.st === 'guard' && !behind && !fromAbove) { burst(hb.x + hb.w / 2, hb.y + hb.h / 2, '#ffffff', 8, 160, 0, .3, 2); sfx('clang', .8); p.vx = -p.face * 260; addFloat(b.x + b.w / 2, b.y - 10, '¡BLOQUEO!', '#ffffff'); return; }
  let dmg = 1; if (b.type === 6 && b.st === 'rest') dmg = 2; if (b.type === 3 && b.st === 'stun') dmg = 2;
  if (b.type >= 8) { const r = bossHitRule(b); if (r === 0) { burst(hb.x + hb.w / 2, hb.y + hb.h / 2, '#35e2ff', 8, 160, 0, .3, 2); sfx('clang', .7); addFloat(b.x + b.w / 2, b.y - 10, b.type === 9 ? 'ESCUDO' : 'INMUNE', '#35e2ff'); return; } dmg = r; }
  dmg *= swordDmg() * (p.atkN === 2 ? 1.6 : 1);
  b.hp -= dmg; b.hit = 0.12; zoomPunch(0.025); vib(22); addScore(25); addTime(4); addCombo(); hitStop = 0.06;
  slashFx(hb); sfx('hit'); shake = Math.max(shake, 5);
  if (b.hp <= 0.01) { b.hp = 0; b.dying = true; b.dieT = 2.8; b.anim = 0; projs = []; waves = []; warns = []; sfx('boom'); sfx('kill'); shake = 20; hitStop = 0.3; flash = 0.3; flashCol = '255,255,255'; playMusic(null); slowT = 0; zoomPunch(0.09); vib([60, 40, 160]); }
}
function slashFx(hb) {
  const cx = hb.x + hb.w / 2, cy = hb.y + hb.h * .45;
  for (let i = 0; i < 10; i++) { const a = (Math.random() - .5) * 1.2; const v = rnd(160, 380); parts.push({ x: cx, y: cy, vx: Math.cos(a) * v * p.face, vy: Math.sin(a) * v - 40, life: rnd(.15, .3), max: .3, c: i % 3 ? '#ffffff' : '#ffe680', s: 2, g: 300 }); }
  burst(cx, cy, '#ffe680', 4, 120, 0, .25, 2);
}
function damageEnemy(e, hb) {
  if (e.b === 'shield' && e.guard && (p.x + p.w / 2 - (e.x + e.w / 2)) * e.dir > 0 && hb.y + hb.h < e.y + e.h + 30 && !p.air) {
    sfx('clang', .7); burst(e.x + e.w / 2 + e.dir * 10, e.y + 20, '#ffffff', 6, 140, 0, .3, 2); p.vx = -p.face * 200; addFloat(e.x + e.w / 2, e.y - 6, 'BLOQUEO', '#ffffff', 14); return;
  }
  e.hp -= swordDmg() * (p.atkN === 2 ? 1.6 : 1); e.hit = 0.15; if (p.atkN === 2) { e.kx = (e.kx || 0) + p.face * 160; hitStop = Math.max(hitStop, 0.07); if (Math.random() < .25 && !ticSay) tSay(TICQ.hit[Math.floor(Math.random() * 3)], 1.4); } sfx('hit', .8, clamp(1.45 - e.w / 70, .8, 1.35)); hitStop = Math.max(hitStop, 0.045); slashFx(hb); addCombo(); addTime(2); vib(12);
  if (e.b !== 'flyer' && e.b !== 'diver' && e.b !== 'ghost' && e.b !== 'bob' && !e.d.still) e.kx = p.face * 220;
  if (e.b === 'diver' || e.b === 'flyer') { e.x += p.face * 10; }
  if (e.hp <= 0.01) {
    e.dead = true; addScore(50); addTime(8); zoomPunch(0.012);
    sfx(e.d.death === 'boom' ? 'boom' : e.b === 'riser' ? 'bones' : e.b === 'ghost' ? 'ghost' : 'kill', .6);
    const k = e.d.death;
    addFx(k, e.x + e.w / 2, e.y + e.h + (k === 'boom' ? 14 : k === 'poof' ? 8 : 4), 16);
    addFloat(e.x + e.w / 2, e.y - 8, '+' + Math.round(50 * mult()), '#ffe066', 16);
    if (Math.random() < 0.05) level.cherries.push({ x: e.x + e.w / 2, y: e.y + e.h - 14, taken: false, ph: 0 });
  }
}

// ---------------- Enemigos ----------------
function shoot(e, kind, tx, ty, sp) {
  const D = DIFFS[diffIdx], cx = e.x + e.w / 2, cy = e.y + e.h / 2, dx = tx - cx, dy = ty - cy, d = Math.hypot(dx, dy) || 1;
  sp = (sp || 210) * D.spd;
  if (kind === 'spore') projs.push({ x: cx, y: e.y + 6, vx: clamp(dx, -260, 260) / 1.0, vy: -320, grav: 700, hw: 6, hh: 6, type: 'spore', dmg: 12, life: 3 });
  else if (kind === 'wormball') projs.push({ x: cx + e.dir * 14, y: cy - 2, vx: e.dir * 200 * D.spd, vy: 0, hw: 7, hh: 5, type: 'wormball', dmg: 14, life: 3 });
  else if (kind === 'bolt' && e.b === 'shooter') projs.push({ x: cx + e.dir * 14, y: e.y + 8, vx: e.dir * 300 * D.spd, vy: 0, hw: 6, hh: 4, type: 'bolt', dmg: 12, life: 3 });
  else projs.push({ x: cx, y: cy, vx: dx / d * sp, vy: dy / d * sp, hw: 5, hh: 5, type: kind === 'bolt' ? 'bolt' : 'orb', dmg: 12, life: 4 });
}
function updateEnemies(dt) {
  const D = DIFFS[diffIdx];
  const pcx = p.x + p.w / 2, pcy = p.y + p.h / 2;
  for (const e of level.enemies) {
    if (e.dead) continue;
    e.hit = Math.max(0, e.hit - dt); e.t += dt; if (e.alert > 0) e.alert -= dt;
    if (Math.abs(e.x - cam.x - VW / 2) > 900) continue;
    const cx = e.x + e.w / 2, dx = pcx - cx, dy = pcy - (e.y + e.h / 2), adx = Math.abs(dx);
    const d = e.d;
    if (e.kx) { const nx = e.x + e.kx * dt; if (groundBelow(e.kx > 0 ? nx + e.w : nx, e.y + e.h, 14) || e.air) e.x = nx; e.kx *= Math.max(0, 1 - 9 * dt); if (Math.abs(e.kx) < 8) e.kx = 0; }
    if (e.b === 'walker') {
      if (e.hit <= 0) e.x += e.dir * (d.spd || 70) * D.spd * dt;
      if (e.x < e.minX) { e.x = e.minX; e.dir = 1; } if (e.x > e.maxX) { e.x = e.maxX; e.dir = -1; }
    } else if (e.b === 'chaser' || e.b === 'bomber' || e.b === 'riser' || e.b === 'shield') {
      if (e.b === 'riser' && e.st === 'buried') { if (adx < 150 && Math.abs(dy) < 80) { e.st = 'rising'; e.rise = 0; sfx('bones', .6); dust(cx, e.y + e.h, 8); } continue; }
      if (e.b === 'riser' && e.st === 'rising') { e.rise += dt; if (e.rise > 0.8) e.st = 'walk'; continue; }
      const sees = adx < (e.b === 'bomber' ? 260 : 230) && Math.abs(dy) < 70;
      if (sees && !e.saw) { e.saw = true; e.alert = 0.6; if (e.b === 'chaser') sfx('roar', .35, 1.3); }
      if (!sees) e.saw = false;
      let sp = (d.spd || 60), target = e.dir;
      if (sees) target = dx > 0 ? 1 : -1;
      if (e.b === 'chaser' && sees && e.alert <= 0) sp = d.run;
      if (e.b === 'bomber' && sees) { sp = adx < 90 ? -d.spd : 0; e.cd -= dt; if (e.cd <= 0 && e.alert <= 0) { e.cd = 2.2 / D.aggr; e.fire = 0.5; sfx('swing', .4, .8);
        const tx = pcx, T = 0.9; projs.push({ x: cx, y: e.y + 4, vx: (tx - cx) / T, vy: -(0.5 * 800 * T) + (pcy - e.y) / T * 0.3, grav: 800, hw: 6, hh: 6, type: 'bomb', dmg: 16, life: 2, fuse: 1.6 }); } }
      if (e.b === 'shield') {
        e.guard = sees && adx < 140 && e.fire <= 0;
        e.cd -= dt;
        if (sees && adx < 52 && e.cd <= 0) { e.fire = 0.75; e.cd = 1.8 / D.aggr; e.guard = false; }
        if (e.fire > 0) { sp = 0; const t = 0.75 - e.fire; if (t > 0.35 && t < 0.55 && !p.dead && overlap(p, { x: e.dir > 0 ? e.x + e.w : e.x - 40, y: e.y, w: 40, h: e.h })) hurt(18, cx); }
        else if (e.guard) sp *= 0.4;
      }
      if (e.fire > 0) e.fire -= dt;
      e.dir = target;
      if (e.hit <= 0 && e.alert <= 0 && sp) {
        const nx = e.x + e.dir * sp * D.spd * dt;
        const fx_ = e.dir > 0 ? nx + e.w + 2 : nx - 2;
        if (groundBelow(fx_, e.y + e.h, 14)) e.x = nx; else if (!sees) e.dir *= -1;
      }
    } else if (e.b === 'jumper') {
      if (!e.air) {
        e.cd -= dt; e.dir = dx > 0 ? 1 : -1;
        if (e.cd <= 0 && adx < 320) { e.air = true; e.vy = -430; e.vx = e.dir * 130 * D.spd; e.cd = rnd(1.1, 1.8) / D.aggr; sfx('jump', .25, 1.6); }
      } else {
        e.vy += 1400 * dt; const ny = e.y + e.vy * dt, nx = e.x + e.vx * dt;
        const gnd = e.vy > 0 ? groundBelow(nx + e.w / 2, ny + e.h, 16) : null;
        if (gnd && e.y + e.h <= gnd.y + 4) { e.y = gnd.y - e.h; e.air = false; e.vy = 0; dust(e.x + e.w / 2, e.y + e.h, 3); }
        else { e.y = ny; if (groundBelow(nx + e.w / 2, e.y + e.h, 400) || e.vy < 0) e.x = nx; }
        if (e.y > level.deathY) e.dead = true;
      }
    } else if (e.b === 'shooter') {
      e.dir = dx > 0 ? 1 : -1;
      if (e.fire > 0) e.fire -= dt;
      if (!d.still && e.fire <= 0 && adx > 120) {
        const nx = e.x + e.dir * (d.spd || 30) * dt, fx_ = e.dir > 0 ? nx + e.w + 2 : nx - 2;
        if (groundBelow(fx_, e.y + e.h, 14) && nx > e.minX - 60 && nx < e.maxX + 60) e.x = nx;
      }
      e.cd -= dt;
      if (e.cd <= 0 && adx < 400 && Math.abs(dy) < 150 && !p.dead) {
        e.cd = rnd(1.8, 2.6) / D.aggr; e.fire = 0.5;
        shoot(e, d.shot, pcx, pcy); sfx(d.shot === 'bolt' ? 'shoot' : 'fire', .3, 1.3);
      }
    } else if (e.b === 'flyer') {
      const ox = e.x; e.x = e.x0 + Math.sin(e.t * 1.2) * 60; e.y = e.y0 + Math.sin(e.t * 2.3) * 18; e.dir = e.x >= ox ? 1 : -1;
      e.cd -= dt;
      if (e.cd <= 0 && Math.hypot(dx, dy) < 400 && !p.dead) { e.cd = rnd(2.2, 3.2) / D.aggr; shoot(e, d.shot, pcx, pcy); sfx('shoot', .25, 1.5); }
    } else if (e.b === 'diver') {
      if (!e.st) e.st = 'hover';
      if (e.st === 'hover') {
        e.x = lerp(e.x, e.x0 + Math.sin(e.t) * 40, dt * 2); e.y = lerp(e.y, e.y0 + Math.sin(e.t * 2) * 12, dt * 2); e.dir = dx > 0 ? 1 : -1;
        e.cd -= dt; if (e.cd <= 0 && adx < 240 && dy > -20 && dy < 260 && !p.dead) { e.st = 'tele'; e.tt = 0.45; e.alert = 0.45; }
      } else if (e.st === 'tele') { e.tt -= dt; e.x += Math.sin(e.t * 60) * 0.6; if (e.tt <= 0) { e.st = 'dive'; e.tt = 0.9; const dd = Math.hypot(dx, dy) || 1; e.vx = dx / dd * 380 * D.spd; e.vy = dy / dd * 380 * D.spd; e.dir = dx > 0 ? 1 : -1; sfx('dash', .3, 1.6); } }
      else if (e.st === 'dive') { e.tt -= dt; e.x += e.vx * dt; e.y += e.vy * dt; if (e.tt <= 0 || groundBelow(e.x + e.w / 2, e.y + e.h, 6)) { e.st = 'back'; } }
      else if (e.st === 'back') { e.x = lerp(e.x, e.x0, dt * 1.5); e.y = lerp(e.y, e.y0, dt * 1.5); if (Math.abs(e.y - e.y0) < 6) { e.st = 'hover'; e.cd = rnd(1.2, 2.2); } }
    } else if (e.b === 'bob') {
      e.y = e.y0 + Math.sin(e.t * 1.4) * 34; e.x = e.x0 + Math.sin(e.t * 0.6) * 20; e.dir = dx > 0 ? 1 : -1;
    } else if (e.b === 'ghost') {
      e.dir = dx > 0 ? 1 : -1;
      if (Math.hypot(dx, dy) < 320) { const dd = Math.hypot(dx, dy) || 1; e.x += dx / dd * 50 * D.spd * dt; e.y += dy / dd * 40 * D.spd * dt; }
      e.y += Math.sin(e.t * 2) * 10 * dt;
      if (dim === 0) continue;
    }
    if (!p.dead && overlap(p, e) && !(e.b === 'riser' && e.st !== 'walk')) hurt(e.b === 'flyer' || e.b === 'diver' ? 12 : 15, e.x + e.w / 2);
  }
}
function updateProjs(dt) {
  const A = level.arena;
  for (let i = projs.length - 1; i >= 0; i--) {
    const q = projs[i]; q.life -= dt;
    if (q.grav) q.vy += q.grav * dt;
    q.x += q.vx * dt; q.y += q.vy * dt;
    if (q.friendly) { friendlyProj(q); if (q.life <= 0) projs.splice(i, 1); continue; }
    if (q.type === 'fire' && Math.random() < 0.8) parts.push({ x: q.x + rnd(-5, 5), y: q.y + rnd(-5, 5), vx: rnd(-20, 20), vy: rnd(-50, 0), life: .35, max: .35, c: Math.random() < .5 ? '#ffd040' : '#ff6a1a', s: Math.random() < .5 ? 3 : 2, g: -80 });
    if (q.type === 'clock' && boss) { const dx = p.x + p.w / 2 - q.x, dy = p.y + p.h / 2 - q.y, d = Math.hypot(dx, dy) || 1; q.vx += dx / d * 300 * dt; q.vy += dy / d * 300 * dt; const v = Math.hypot(q.vx, q.vy); if (v > 260) { q.vx *= 260 / v; q.vy *= 260 / v; } }
    if (q.type === 'breath') { q.life -= 0; }
    let rem = q.life <= 0;
    if (q.type === 'bomb') {
      q.fuse -= dt; const gnd = groundBelow(q.x, q.y + q.hh, 10);
      if (gnd && q.vy > 0) { q.y = gnd.y - q.hh; q.vy = 0; q.vx *= 0.7; }
      if (q.fuse <= 0 || (!p.dead && overlap({ x: q.x - 8, y: q.y - 8, w: 16, h: 16 }, p))) {
        rem = true; addFx('bomb_boom', q.x, q.y + 30, 24); sfx('boom', .6); shake = Math.max(shake, 5);
        if (Math.hypot(p.x + p.w / 2 - q.x, p.y + p.h / 2 - q.y) < 48) hurt(q.dmg, q.x);
      }
      if (rem) { projs.splice(i, 1); continue; }
    }
    const r = { x: q.x - q.hw, y: q.y - q.hh, w: q.hw * 2, h: q.hh * 2 };
    if (!rem && !p.dead && p.guard && overlap(r, p)) { const gr = guardProj(q); if (gr === 'block') rem = true; else if (gr === 'reflect') continue; }
    if (!rem && !p.dead && overlap(r, p)) { if (hurt(q.dmg, q.x)) { if (q.type !== 'breath') rem = true; if (q.type === 'bolt') addFx('shothit', q.x, q.y + 6, 18); if (q.type === 'wormball') addFx('worm_boom', q.x, q.y + 23, 18); } }
    if (!rem && q.type !== 'laser' && q.type !== 'orb' && q.type !== 'breath' && q.type !== 'clock' && q.type !== 'eyeball' && q.type !== 'ring' && q.type !== 'bubble') for (const s of level.plats) if ((s.k === 'solid' || (s.k === 'phase' && s.ph === dim)) && overlap(r, s)) {
      rem = true;
      if (q.type === 'fire' || q.type === 'hfire') { burst(q.x, q.y, '#ff8a30', 12, 160, 300, .5, 2); sfx('fire', .3); }
      else if (q.type === 'wormball') addFx('worm_boom', q.x, q.y + 23, 18);
      else if (q.type === 'spore') burst(q.x, q.y, '#c070a0', 8, 80, 200, .4, 2);
      else addFx('shothit', q.x, q.y + 6, 18);
      break;
    }
    if (!rem && arenaLock && (q.x < A.x1 - 80 || q.x > A.x2 + 80 || q.y > A.floor + 100)) rem = true;
    if (rem) projs.splice(i, 1);
  }
  for (let i = waves.length - 1; i >= 0; i--) {
    const w = waves[i]; w.x += w.dir * w.spd * dt; w.t += dt;
    if (w.x < A.x1 - 30 || w.x > A.x2 + 30) { waves.splice(i, 1); continue; }
    if (!p.dead && overlap(p, { x: w.x - 12, y: w.y - 30, w: 24, h: 30 })) hurt(18, w.x - w.dir * 50);
    if (Math.random() < 0.7) parts.push({ x: w.x + rnd(-8, 8), y: w.y - 2, vx: -w.dir * rnd(20, 80), vy: rnd(-180, -60), life: .4, max: .4, c: w.col || (Math.random() < .5 ? '#c8a070' : '#9bdc5a'), s: Math.random() < .5 ? 3 : 2, g: 600 });
  }
  for (let i = warns.length - 1; i >= 0; i--) {
    const w = warns[i]; w.t -= dt;
    if (w.t <= 0) {
      if (w.kind === 'sand') projs.push({ x: w.x, y: A.floor - 560, vx: 0, vy: 150, grav: 1000, hw: 10, hh: 10, type: 'sandblock', dmg: 15, life: 3 });
      else if (w.kind === 'feather') projs.push({ x: w.x, y: A.floor - 560, vx: rnd(-30, 30), vy: 420, hw: 4, hh: 10, type: 'feather', dmg: 12, life: 3 });
      else if (w.kind === 'ice') projs.push({ x: w.x, y: A.floor - 540, vx: 0, vy: 200, grav: 1200, hw: 6, hh: 12, type: 'icicle', dmg: 15, life: 3 });
      else projs.push({ x: w.x, y: A.floor - 560, vx: 0, vy: 150, grav: 900, hw: 9, hh: 9, type: 'fire', dmg: 15, life: 3 });
      warns.splice(i, 1);
    }
  }
}

// ---------------- Jefes ----------------
function spawnBoss() {
  const A = level.arena, D = DIFFS[diffIdx], t = WD_().boss.type, cx = (A.x1 + A.x2) / 2;
  const HP = [14, 16, 28, 20, 22, 22, 26, 30, 22, 22, 26, 40];
  if (t === 0) boss = { w: 116, h: 92, x: A.x2 - 260, y: A.floor - 92, vx: 0, vy: 0, st: 'idle' };
  else if (t === 1) boss = { w: 104, h: 84, x: A.x2 - 170, y: A.floor - 300, st: 'move', side: 1, cycle: 0, shots: 0, aimY: 0 };
  else if (t === 2) { boss = { w: 64, h: 112, x: cx - 32, y: A.floor - 112, st: 'stand', cd: 2, atk: 0, vulnT: 0, throwA: 0 }; level.levers.forEach(l => { l.on = false; }); }
  else if (t === 3) boss = { w: 72, h: 56, x: A.x2 - 220, y: A.floor - 300, st: 'hover', cd: 1.5, volleys: 0, vx: 0, vy: 0 };
  else if (t === 4) boss = { w: 52, h: 100, x: A.x2 - 200, y: A.floor - 100, st: 'walk', cd: 2, guardCD: 4, summoned: false };
  else if (t === 5) boss = { w: 120, h: 64, x: A.x2 - 220, y: A.floor - 64, st: 'idle', cd: 1.2, vx: 0, vy: 0, moves: 0 };
  else if (t === 6) boss = { w: 130, h: 150, x: cx - 55, y: A.floor - 360, st: 'fly', cd: 1.5, shots: 0, vx: 0, vy: 0 };
  else if (t === 7) boss = { w: 30, h: 62, x: A.x2 - 160, y: A.floor - 62, st: 'idle', cd: 1.2, vx: 0, vy: 0, moves: 0, shiftT: 6 };
  else boss = spawnBossX(t, A);
  Object.assign(boss, { type: t, t: 0, face: -1, anim: 0, hit: 0, dying: false, done: false, name: WD_().boss.name, skin: WD_().boss.skin });
  boss.max = Math.round(HP[t] * D.boss); boss.hp = boss.max;
  for (const e of level.enemies) if (e.x > A.x1 - 300) e.dead = true;
}
function updateBoss(dt) {
  if (!boss || boss.done) return;
  const D = DIFFS[diffIdx], A = level.arena, b = boss;
  b.hit = Math.max(0, b.hit - dt); b.anim += dt;
  if (b.dying) {
    b.dieT -= dt;
    if (Math.random() < 0.25) { addFx(b.type === 1 ? 'boom' : 'poof', b.x + Math.random() * b.w, b.y + Math.random() * b.h + 20, 16); shake = Math.max(shake, 5); sfx('boom', .4); }
    if (b.type === 1 || b.type === 3 || b.type === 6) b.y = Math.min(A.floor - b.h, b.y + 120 * dt);
    if (b.dieT <= 0) {
      b.done = true; flash = 0.5; flashCol = '255,255,255'; burst(b.x + b.w / 2, b.y + b.h / 2, '#ffffff', 50, 380, 100, 1.2, 3);
      for (let i = 0; i < 6; i++) addFx(b.type === 1 ? 'boom' : 'poof', b.x + rnd(0, b.w), b.y + rnd(0, b.h) + 20, 12);
      stageClear();
    }
    return;
  }
  if (bossIntro > 0) { if (dlg && dlg.hold) { bossIntro = Math.max(bossIntro, 0.6); updateDlg(dt); return; } bossIntro -= dt; if (bossIntro <= 0) { banner('', WD_().boss.hint, WD_().c, 2.6); sfx('v_fight'); } return; }
  b.t += dt;
  const pcx = p.x + p.w / 2, pcy = p.y + p.h / 2, bcx = b.x + b.w / 2;
  const ag = D.aggr * (b.hp <= b.max / 2 ? 1.2 : 1);
  let contact = true;
  if (b.type === 0) {
    if (b.st !== 'air') b.face = pcx < bcx ? -1 : 1;
    if (b.st === 'idle') { if (b.t > 1.2 / ag) { b.st = 'crouch'; b.t = 0; } }
    else if (b.st === 'crouch') { if (b.t > 0.45) { b.st = 'air'; b.t = 0; const tx = clamp(pcx - b.w / 2, A.x1 + 10, A.x2 - b.w - 10); b.vx = (tx - b.x) / 1.0; b.vy = -900; sfx('jump', .9, .55); } }
    else if (b.st === 'air') {
      b.vy += 1800 * dt; b.x += b.vx * dt; b.y += b.vy * dt; b.x = clamp(b.x, A.x1 + 10, A.x2 - b.w - 10);
      if (b.vy > 0 && b.y + b.h >= A.floor) {
        b.y = A.floor - b.h; b.st = 'idle'; b.t = 0; shake = 16; sfx('stomp'); sfx('boom', .6);
        const cx = b.x + b.w / 2, sp = 340 * ag;
        waves.push({ x: cx - 56, y: A.floor, dir: -1, spd: sp, t: 0 }); waves.push({ x: cx + 56, y: A.floor, dir: 1, spd: sp, t: 0 });
        dust(cx - 40, A.floor, 10, -1); dust(cx + 40, A.floor, 10, 1);
      }
    }
  } else if (b.type === 1) {
    b.face = b.side > 0 ? -1 : 1;
    if (b.st === 'move') {
      const tx = b.side > 0 ? A.x2 - b.w - 40 : A.x1 + 40;
      const want = clamp(pcy, A.floor - 300, A.floor - 20), ty = clamp(want - b.h * 0.5, A.floor - 340, A.floor - b.h - 10);
      b.x = lerp(b.x, tx, Math.min(1, dt * 2.5)); b.y = lerp(b.y, ty, Math.min(1, dt * 2.5));
      if (b.t > 1.4 / ag) { b.st = 'aim'; b.t = 0; b.aimY = want; sfx('alert', .45); }
    } else if (b.st === 'aim') { if (b.t > 0.6 / Math.sqrt(ag)) { b.st = 'fire'; b.t = 0.22; b.shots = 0; } }
    else if (b.st === 'fire') {
      if (b.t >= 0.22) {
        b.t = 0; b.shots++;
        projs.push({ x: bcx - b.side * 50, y: b.aimY, vx: -b.side * 560 * ag, vy: 0, hw: 26, hh: 4, type: 'laser', dmg: 14, life: 4 }); sfx('shoot', .6);
        if (b.shots >= (diffIdx >= 2 ? 4 : 3)) { b.cycle++; b.st = b.cycle % 2 === 0 ? 'drop' : 'move'; b.t = 0; }
      }
    } else if (b.st === 'drop') { b.y = Math.min(A.floor - b.h, b.y + 520 * dt); if (b.y >= A.floor - b.h) { b.st = 'down'; b.t = 0; shake = 12; sfx('stomp'); dust(bcx, A.floor, 14); } }
    else if (b.st === 'down') { contact = false; if (b.t > 2.4 / Math.sqrt(ag)) { b.st = 'move'; b.t = 0; b.side *= -1; } }
  } else if (b.type === 2) {
    b.face = pcx < bcx ? -1 : 1; contact = b.vulnT <= 0;
    if (b.vulnT > 0) { b.vulnT -= dt; if (b.vulnT <= 0) { level.levers.forEach(l => { l.on = false; }); sfx('shield', .6, .7); addFloat(bcx, b.y - 24, 'ESCUDO RESTAURADO', '#ff8f3a', 20); } }
    b.throwA = Math.max(0, b.throwA - dt); b.cd -= dt;
    if (b.cd <= 0) {
      b.atk++; b.cd = (b.vulnT > 0 ? 2.6 : 1.8) / ag; b.throwA = 0.6; b.anim = 0;
      if (b.atk % 3 === 0) { const cnt = diffIdx >= 2 ? 5 : 4; for (let i = 0; i < cnt; i++) warns.push({ x: i === 0 ? pcx : rnd(A.x1 + 40, A.x2 - 40), t: 0.9 + i * 0.15 }); sfx('alert', .6); shake = Math.max(shake, 6); }
      else {
        const sx = bcx + b.face * 40, sy = b.y + 30, tg = [[pcx, pcy]];
        if (diffIdx > 0 && b.hp <= b.max / 2) { tg.push([pcx - 120, pcy]); tg.push([pcx + 120, pcy]); }
        for (const t of tg) { const T = 1.0, g = 900; projs.push({ x: sx, y: sy, vx: (t[0] - sx) / T, vy: (t[1] - sy - 0.5 * g * T * T) / T, grav: g, hw: 9, hh: 9, type: 'fire', dmg: 15, life: 4 }); }
        sfx('fire', .7);
      }
    }
  } else if (b.type === 3) {
    // OJO ABISAL
    b.face = pcx < bcx ? -1 : 1;
    if (b.st === 'hover') {
      const tx = clamp(pcx - b.w / 2 + Math.sin(b.t * 0.8) * 160, A.x1 + 20, A.x2 - b.w - 20), ty = A.floor - 290 + Math.sin(b.t * 2) * 20;
      b.x = lerp(b.x, tx, dt * 1.6); b.y = lerp(b.y, ty, dt * 2);
      b.cd -= dt;
      if (b.cd <= 0) {
        b.cd = 1.3 / ag; b.volleys++; b.atkA = 0.4; sfx('shoot', .5, .7);
        const n = diffIdx >= 2 ? 5 : 3;
        for (let i = 0; i < n; i++) { const a = Math.atan2(pcy - (b.y + b.h / 2), pcx - bcx) + (i - (n - 1) / 2) * 0.25; projs.push({ x: bcx, y: b.y + b.h / 2, vx: Math.cos(a) * 230 * D.spd, vy: Math.sin(a) * 230 * D.spd, hw: 7, hh: 7, type: 'eyeball', dmg: 12, life: 4 }); }
        if (b.volleys >= 3) { b.volleys = 0; b.st = 'tele'; b.t = 0; sfx('alert', .6); }
      }
    } else if (b.st === 'tele') { b.x += Math.sin(b.t * 70) * 1.2; if (b.t > 0.6) { b.st = 'dive'; b.t = 0; const dx = pcx - bcx, dy = pcy - (b.y + b.h / 2), d = Math.hypot(dx, dy) || 1; b.vx = dx / d * 560 * ag; b.vy = dy / d * 560 * ag; sfx('dash', .8, .7); } }
    else if (b.st === 'dive') { b.x += b.vx * dt; b.y += b.vy * dt; b.x = clamp(b.x, A.x1, A.x2 - b.w); if (b.y + b.h >= A.floor || b.t > 1.1) { b.y = Math.min(b.y, A.floor - b.h); b.st = 'stun'; b.t = 0; shake = 10; sfx('stomp'); dust(bcx, A.floor, 10); } }
    else if (b.st === 'stun') { contact = false; if (b.t > 1.4) { b.st = 'hover'; b.t = 0; b.cd = 1; } }
  } else if (b.type === 4) {
    // CABALLERO ESQUELETO
    if (b.st !== 'slash' && b.st !== 'windup') b.face = pcx < bcx ? -1 : 1;
    b.guardCD -= dt;
    if (!b.summoned && b.hp < b.max * 0.6) { b.summoned = true; for (const sx of [A.x1 + 120, A.x2 - 140]) { const e = { id: 'gskel', d: ENEMY.gskel, b: 'riser', x: sx, y: A.floor - 44, w: 22, h: 44, hp: 2, hit: 0, t: 0, dir: -1, minX: A.x1, maxX: A.x2, cd: 1, dead: false, st: 'rising', rise: 0, x0: sx, y0: 0, fire: 0, alert: 0 }; level.enemies.push(e); } sfx('bones', .8); addFloat(bcx, b.y - 20, '¡LEVANTAOS!', '#c070ff', 22); }
    if (b.st === 'walk') {
      const adx = Math.abs(pcx - bcx);
      if (adx > 70) b.x += b.face * 75 * ag * dt;
      b.x = clamp(b.x, A.x1 + 10, A.x2 - b.w - 10);
      b.cd -= dt;
      if (adx < 120 && b.cd <= 0) { b.st = 'windup'; b.t = 0; sfx('alert', .4); }
      else if (b.guardCD <= 0) { b.st = 'guard'; b.t = 0; b.guardCD = 5 / ag; sfx('clang', .4, .7); }
    } else if (b.st === 'windup') { if (b.t > 0.45 / Math.sqrt(ag)) { b.st = 'slash'; b.t = 0; sfx('swing', 1, .7); } }
    else if (b.st === 'slash') {
      if (b.t > 0.08 && b.t < 0.3 && !p.dead && overlap(p, { x: b.face > 0 ? b.x + b.w - 10 : b.x - 110, y: b.y + 10, w: 120, h: 90 })) hurt(22, bcx);
      if (b.t > 0.55) { b.st = 'walk'; b.cd = 1.2 / ag; }
    } else if (b.st === 'guard') { if (b.t > 1.8) { b.st = 'walk'; b.cd = 0.4; } }
  } else if (b.type === 5) {
    // BESTIA DE ESCARCHA
    if (b.st === 'idle') { b.face = pcx < bcx ? -1 : 1; b.cd -= dt; if (b.cd <= 0) { b.moves++; if (b.moves % 3 === 0) { b.st = 'leapT'; } else { b.st = 'roar'; } b.t = 0; } }
    else if (b.st === 'roar') { if (b.t < 0.05) { sfx('roar', .8, .6); shake = 6; } if (b.t > 0.6 / Math.sqrt(ag)) { b.st = 'charge'; b.t = 0; b.vx = b.face * 520 * ag; } }
    else if (b.st === 'charge') {
      b.x += b.vx * dt; if (Math.random() < .6) dust(b.face > 0 ? b.x : b.x + b.w, A.floor, 2, -b.face);
      if (b.x <= A.x1 + 4 || b.x + b.w >= A.x2 - 4) {
        b.x = clamp(b.x, A.x1 + 4, A.x2 - b.w - 4); b.st = 'stagger'; b.t = 0; shake = 16; sfx('stomp'); sfx('ice', .8);
        const cnt = diffIdx >= 2 ? 6 : 4; for (let i = 0; i < cnt; i++) warns.push({ x: i === 0 ? pcx : rnd(A.x1 + 40, A.x2 - 40), t: 0.5 + i * 0.18, kind: 'ice' });
      }
    } else if (b.st === 'stagger') { contact = false; if (b.t > 1.3) { b.st = 'idle'; b.cd = 0.8 / ag; } }
    else if (b.st === 'leapT') { b.face = pcx < bcx ? -1 : 1; if (b.t > 0.4) { b.st = 'leap'; b.t = 0; const tx = clamp(pcx - b.w / 2, A.x1 + 10, A.x2 - b.w - 10); b.vx = (tx - b.x) / 0.9; b.vy = -820; sfx('jump', .8, .5); } }
    else if (b.st === 'leap') {
      b.vy += 1800 * dt; b.x += b.vx * dt; b.y += b.vy * dt; b.x = clamp(b.x, A.x1 + 4, A.x2 - b.w - 4);
      if (b.vy > 0 && b.y + b.h >= A.floor) { b.y = A.floor - b.h; b.st = 'idle'; b.cd = 1 / ag; shake = 12; sfx('stomp'); waves.push({ x: bcx - 60, y: A.floor, dir: -1, spd: 300 * ag, t: 0, col: '#cfefff' }); waves.push({ x: bcx + 60, y: A.floor, dir: 1, spd: 300 * ag, t: 0, col: '#cfefff' }); }
    }
  } else if (b.type === 6) {
    // DEMONIO DEL ABISMO
    if (b.st === 'fly') {
      b.face = pcx < bcx ? -1 : 1;
      const tx = clamp(pcx - b.w / 2 - b.face * 160, A.x1 + 10, A.x2 - b.w - 10), ty = A.floor - 330 + Math.sin(b.t * 1.6) * 24;
      b.x = lerp(b.x, tx, dt * 1.2); b.y = lerp(b.y, ty, dt * 1.6);
      b.cd -= dt;
      if (b.cd <= 0) {
        b.cd = 1.4 / ag; b.shots++;
        const sx = bcx + b.face * 40, sy = b.y + 40, dx = pcx - sx, dy = pcy - sy, d = Math.hypot(dx, dy) || 1;
        projs.push({ x: sx, y: sy, vx: dx / d * 260 * D.spd, vy: dy / d * 260 * D.spd, hw: 10, hh: 6, type: 'hfire', dmg: 15, life: 4 }); sfx('fire', .6, .8);
        if (b.shots >= 3) { b.shots = 0; b.st = 'breathT'; b.t = 0; sfx('roar', .9, .5); }
      }
    } else if (b.st === 'breathT') { b.face = pcx < bcx ? -1 : 1; b.y = lerp(b.y, A.floor - 230, dt * 2); if (b.t > 0.7) { b.st = 'breath'; b.t = 0; sfx('fire', 1, .5); } }
    else if (b.st === 'breath') {
      const bx_ = b.face < 0 ? b.x - 190 : b.x + b.w, by_ = b.y + 50;
      if (Math.random() < 0.9) for (let i = 0; i < 2; i++) parts.push({ x: b.face < 0 ? b.x + 10 : b.x + b.w - 10, y: b.y + 60, vx: b.face * rnd(250, 420), vy: rnd(40, 200), life: .55, max: .55, c: Math.random() < .5 ? '#40e0ff' : '#a0f8ff', s: 4, g: 100 });
      if (!p.dead && overlap(p, { x: bx_, y: by_, w: 190, h: 160 })) hurt(16, bcx);
      if (b.t > 1.3) { b.st = 'land'; b.t = 0; }
    } else if (b.st === 'land') { b.y = Math.min(A.floor - b.h, b.y + 300 * dt); if (b.y >= A.floor - b.h) { b.st = 'rest'; b.t = 0; shake = 10; sfx('stomp'); dust(bcx, A.floor, 12); } }
    else if (b.st === 'rest') { contact = false; if (b.t > 2.2 / Math.sqrt(ag)) { b.st = 'fly'; b.t = 0; b.cd = 0.8; } }
  } else if (b.type >= 8) { contact = updateBossX(b, dt, A, ag, pcx, pcy, bcx);
  } else {
    // KAEL SOMBRÍO
    b.shiftT -= dt;
    if (b.shiftT <= 0) { b.shiftT = 7 / ag; dim = 1 - dim; sfx('shift', .8, .7); flash = 0.15; flashCol = dim ? '200,100,255' : '60,220,255'; addFloat(bcx, b.y - 20, '¡SHIFT!', '#d070ff', 20); if (overlapsDimBlocks(dim)) p.y = Math.min(p.y, A.floor - p.h); }
    if (b.st === 'idle') {
      b.face = pcx < bcx ? -1 : 1; b.cd -= dt;
      const adx = Math.abs(pcx - bcx); if (adx > 160) b.x += b.face * 120 * dt;
      if (b.cd <= 0) { b.moves++; const m = b.moves % 4; b.st = m === 1 ? 'dashT' : m === 2 ? 'jumpT' : m === 3 ? 'clocks' : 'dashT'; b.t = 0; }
    } else if (b.st === 'dashT') { b.face = pcx < bcx ? -1 : 1; if (b.t > 0.4 / Math.sqrt(ag)) { b.st = 'dash'; b.t = 0; b.vx = b.face * 820 * ag; sfx('dash', .9, .8); } }
    else if (b.st === 'dash') {
      b.x += b.vx * dt; trails.push({ x: b.x + b.w / 2 - p.w / 2, y: b.y + b.h - p.h, face: b.face, f: 3, life: 0.2, dk: true });
      if (!p.dead && overlap(p, { x: b.x - 20, y: b.y, w: b.w + 40, h: b.h })) hurt(20, bcx);
      if (b.t > 0.32 || b.x <= A.x1 + 4 || b.x + b.w >= A.x2 - 4) { b.x = clamp(b.x, A.x1 + 4, A.x2 - b.w - 4); b.st = 'recover'; b.t = 0; }
    } else if (b.st === 'jumpT') { if (b.t > 0.3) { b.st = 'jump'; b.t = 0; b.vy = -900; b.vx = (pcx - bcx) / 0.8; sfx('jump', .8, .7); } }
    else if (b.st === 'jump') {
      b.vy += 1800 * dt; b.x += b.vx * dt; b.y += b.vy * dt; b.x = clamp(b.x, A.x1 + 4, A.x2 - b.w - 4);
      if (b.vy > 0 && b.t > 0.35) { b.vx = 0; b.vy = Math.max(b.vy, 900); }
      if (b.y + b.h >= A.floor) { b.y = A.floor - b.h; b.st = 'recover'; b.t = 0; shake = 10; sfx('stomp');
        waves.push({ x: bcx - 30, y: A.floor, dir: -1, spd: 320 * ag, t: 0, col: '#d070ff' }); waves.push({ x: bcx + 30, y: A.floor, dir: 1, spd: 320 * ag, t: 0, col: '#d070ff' }); }
      if (!p.dead && b.vy > 0 && overlap(p, b)) hurt(20, bcx);
    } else if (b.st === 'clocks') {
      if (b.t > 0.3 && !b.thrown) { b.thrown = true; const n = diffIdx >= 2 ? 4 : 3; for (let i = 0; i < n; i++) projs.push({ x: bcx, y: b.y + 10, vx: (i - (n - 1) / 2) * 140, vy: -260, hw: 8, hh: 8, type: 'clock', dmg: 14, life: 3.5 }); sfx('slow', .5, 1.5); }
      if (b.t > 0.8) { b.thrown = false; b.st = 'recover'; b.t = 0; }
    } else if (b.st === 'recover') { contact = false; if (b.t > 0.9 / Math.sqrt(ag)) { b.st = 'idle'; b.cd = 0.5; } }
  }
  if (contact && !p.dead && overlap(p, b) && b.type !== 7) hurt(20, bcx);
  if (b.type === 11 && b.hp < b.max * 0.5 && !b.summoned) { b.summoned = true; for (const sx of [A.x1 + 140, A.x2 - 160]) { const d = ENEMY.voidling; level.enemies.push({ id: 'voidling', d, b: d.b, x: sx, y: A.floor - d.h, w: d.w, h: d.h, hp: 2, hit: 0, t: 0, dir: -1, minX: A.x1, maxX: A.x2, cd: 1, dead: false, st: 0, x0: sx, y0: 0, fire: 0, alert: 0, vy: 0 }); } addFloat(bcx, b.y - 20, '¡SOMBRAS, DEVORADLO!', '#d070ff', 20); sfx('ghost', .8); }
}

// ---------------- Cámara ----------------
function updateCamera(dt, snap) {
  const A = level.arena;
  let tx, ty;
  if (arenaLock) { const span = A.x2 - A.x1 + 80; tx = VW >= span ? A.x1 - 40 - (VW - span) / 2 : clamp((boss && !boss.done ? lerp(p.x + p.w / 2, boss.x + boss.w / 2, bossIntro > 0 ? 0.7 : 0.35) : p.x + p.w / 2) - VW / 2, A.x1 - 40, A.x2 + 40 - VW); ty = A.floor - VH + 56; }
  else {
    p.look = snap ? p.face * 60 : lerp(p.look, p.face * 60 + p.vx * 0.12, Math.min(1, dt * 2.5));
    tx = clamp(p.x + p.w / 2 - VW / 2 + p.look, 0, level.width - VW);
    ty = clamp(p.y + p.h / 2 - VH * 0.58, level.top, level.bottom - VH);
  }
  if (snap) { cam.x = tx; cam.y = ty; }
  else { cam.x = lerp(cam.x, tx, Math.min(1, dt * 7)); cam.y = lerp(cam.y, ty, Math.min(1, dt * 5)); }
}

// ---------------- Vida ambiental ----------------
function updateAmbient(dt) {
  const wi = ({ 14: 3, 15: 4, 16: 6, 17: 1 })[curWorld] ?? curWorld;
  for (const a of amb) {
    if (wi === 0 || wi === 3) { a.x += (Math.sin(time + a.ph) * 10 + (wi === 0 ? 14 : -6)) * dt; a.y += (wi === 0 ? 18 : Math.cos(time * 0.7 + a.ph) * 8) * dt; }
    else if (wi === 1) { a.y += a.v * 12 * dt; a.x -= a.v * 3 * dt; }
    else if (wi === 5) { a.y += a.v * 1.3 * dt; a.x += Math.sin(time + a.ph) * 14 * dt; }
    else if (wi === 4) { a.x += a.v * 0.5 * dt; }
    else if (wi === 7 || wi === 11) { a.y -= a.v * 0.4 * dt; a.x += Math.sin(time * .5 + a.ph) * 6 * dt; }
    else if (wi === 8) { a.y -= a.v * 1.2 * dt; a.x += Math.sin(time * 2 + a.ph) * 10 * dt; }
    else if (wi === 9) { a.x -= a.v * 4 * dt; a.y += Math.sin(time + a.ph) * 6 * dt; }
    else if (wi === 10) { a.x -= a.v * 0.6 * dt; }
    else { a.y -= a.v * dt; a.x += Math.sin(time + a.ph) * 12 * dt; }
    if (a.y > 560) a.y = -10; if (a.y < -10) a.y = 550; if (a.x < -10) a.x = 970; if (a.x > 970) a.x = -10;
  }
  for (const c of level.critters) {
    if (c.gone) continue;
    c.t += dt;
    const d = Math.abs(p.x + p.w / 2 - c.x);
    if (!c.fly && d < 90 && Math.abs(p.y + p.h - c.y) < 60) { c.fly = true; c.vx = (c.x < p.x ? -1 : 1) * rnd(80, 150); c.vy = rnd(-160, -100); c.face = Math.sign(c.vx); if (Math.random() < .5) sfx('wall', .15, 2.2); }
    if (c.fly) { c.x += c.vx * dt; c.y += c.vy * dt; c.vy -= 20 * dt; if (c.y < cam.y - 60) c.gone = true; }
    else if (Math.random() < dt * 1.5) { c.x += rnd(-6, 6); c.face = Math.random() < .5 ? -1 : 1; c.hop = 0.15; }
    if (c.hop > 0) c.hop -= dt;
  }
  if (curWorld === 1) {
    if (Math.random() < dt * 0.5 && cars.length < 4) cars.push({ k: Math.random() < .5 ? 'car_v-police' : 'car_v-red', x: Math.random() < .5 ? -200 : VW + 200, y: rnd(40, 160), sc: rnd(.25, .45) });
    for (let i = cars.length - 1; i >= 0; i--) { const c = cars[i]; if (c.vx === undefined) c.vx = (c.x < 0 ? 1 : -1) * rnd(60, 140); c.x += c.vx * dt; if (c.x < -300 || c.x > VW + 300) cars.splice(i, 1); }
  }
  if (wi === 4 && Math.random() < dt * 0.08) { lightning = 0.25; sfx('stomp', .25, .5); }
  if (curWorld === 17 && Math.random() < dt * 0.14) { lightning = 0.35; sfx('boom', .22, .45); shake = Math.max(shake, 2); }
  if (wi === 1 && Math.random() < 0.7) {
    const x = cam.x + Math.random() * VW;
    for (const s of level.plats) if (s.k === 'solid' && x >= s.x && x <= s.x + s.w && s.y > cam.y && s.y < cam.y + VH) {
      for (let i = 0; i < 2; i++) parts.push({ x, y: s.y - 1, vx: rnd(-30, 30), vy: rnd(-70, -30), life: .25, max: .25, c: '#a8d0ff', s: 1, g: 500 }); break; }
  }
  if (wi === 5 && Math.random() < 0.15) { const x = cam.x + Math.random() * VW; parts.push({ x, y: cam.y + VH * Math.random(), vx: 10, vy: 6, life: 2, max: 2, c: 'rgba(255,255,255,.8)', s: 1, g: 0 }); }
  if (lightning > 0) lightning -= dt;
}

// ---------------- Actualización ----------------
function update(dt) {
  time += dt; levelTime += dt;
  if (bannerT > 0) bannerT -= dt;
  if (fade > 0) fade = Math.max(0, fade - dt * 2.5);
  if (flash > 0) flash = Math.max(0, flash - dt);
  if (shiftFx > 0) shiftFx -= dt;
  if (loreT > 0) loreT -= dt;
  if (hintT > 0 && bannerT <= 0) hintT -= dt;
  if (slowT > 0) { slowT -= dt; if (slowT <= 0 && curMusic) curMusic.playbackRate = 1; }
  const wdt = slowT > 0 ? dt * 0.35 : dt;
  if (dlg && dlg.hold && boss && bossIntro > 0) { updateBoss(dt); updateCamera(dt, false); updateParticles(dt); return; }
  updatePlats(wdt);
  updatePlayer(dt);
  if (state !== 'playing') return;
  updateHazards(wdt);
  updateEnemies(wdt); updateBoss(wdt);
  if (state !== 'playing') return;
  updateProjs(wdt);
  if (level.lava && levelTime > 2) {
    const lv = level.lava; let sp = lv.rise;
    if (lv.y - (p.y + p.h) > 340) sp *= 2.5;
    lv.y = Math.max(lv.stop, lv.y - sp * wdt);
    if (Math.random() < 0.3) parts.push({ x: cam.x + Math.random() * VW, y: lv.y, vx: 0, vy: rnd(-160, -60), life: .7, max: .7, c: Math.random() < .5 ? '#ffd040' : '#ff6a1a', s: 2, g: 300 });
  }
  updateEcho(dt); updateTic(dt); updateLife(dt); updateMagic(dt); updateLive(dt); updateSwarms(dt); updateAmbEvents(dt); updateDlg(dt); if (invertT > 0) invertT -= dt;
  updateCamera(dt, false); updateParticles(dt); updateAmbient(dt);
  if (shake > 0) shake = Math.max(0, shake - dt * 30);
  zoomKick = Math.max(0, zoomKick - dt * 0.12); camZoom = 1 + (OPT.shake ? zoomKick : 0);
  ambTick(dt);
}
