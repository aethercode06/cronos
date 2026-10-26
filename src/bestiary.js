// =====================================================================
//  BESTIARIO NUEVO (v2.5): 16 criaturas con animaciones completas
//  (arte CC0 de Luis Zuno @ansimuz, Gothicvania Patreon's Collection,
//  Gothicvania Swamp y Church). Sustituyen a los enemigos recoloreados.
// =====================================================================
// los "buceadores" usan la misma animación al lanzarse
for (const k of ['nb_flyeye_fly', 'nb_bat_fly']) { IMG12[k + '_atk'] = IMG12[k]; META12[k + '_atk'] = META12[k]; }
Object.assign(IMG, IMG12); Object.assign(META, META12);
for (const k in IMG12) if (!SPR[k]) { const im = new Image(); im.src = IMG12[k]; SPR[k] = im; }
Object.assign(ENEMY, {
  nb_werewolf:  { b: 'chaser',  anim: 'nb_werewolf_run', w: 52, h: 28, hp: 3, face: 1, spd: 75, run: 330, death: 'poof' },
  nb_nightmare: { b: 'chaser',  anim: 'nb_nightmare_run', w: 70, h: 50, hp: 4, face: -1, spd: 70, run: 320, death: 'flame_death' },
  nb_knight:    { b: 'brute',   anim: 'nb_knight_run', atk: 'nb_knight_atk', w: 26, h: 38, hp: 4, face: 1, spd: 60, reach: 46, death: 'poof' },
  nb_ogre:      { b: 'brute',   anim: 'nb_ogre_walk', atk: 'nb_ogre_atk', w: 34, h: 50, hp: 6, face: -1, spd: 40, reach: 58, death: 'poof' },
  nb_reaper:    { b: 'riser',   anim: 'nb_reaper_walk', rise: 'nb_reaper_rise', w: 18, h: 30, hp: 3, face: 1, spd: 55, death: 'flame_death' },
  nb_eghost:    { b: 'ghost',   anim: 'nb_eghost_fly', w: 22, h: 28, hp: 2, face: 1, death: 'poof' },
  nb_flyeye:    { b: 'diver',   anim: 'nb_flyeye_fly', w: 22, h: 22, hp: 2, face: 1, death: 'flame_death' },
  nb_toad:      { b: 'jumper',  anim: 'nb_toad_idle', jump: 'nb_toad_jump', w: 38, h: 30, hp: 3, face: 1, death: 'poof' },
  nb_fireskull: { b: 'flyer',   anim: 'nb_fireskull_fly', w: 26, h: 28, hp: 2, face: -1, shot: 'orb', death: 'flame_death', sc: 0.5, glow: 'rgba(255,120,40,.5)' },
  nb_meerman:   { b: 'walker',  anim: 'nb_meerman_walk', w: 18, h: 28, hp: 2, face: -1, spd: 55, death: 'poof' },
  nb_bat:       { b: 'flyer',   anim: 'nb_bat_fly', w: 26, h: 24, hp: 1, face: 0, shot: 'orb', death: 'poof', sc: 2 },
  nb_hellbeast: { b: 'shooter', anim: 'nb_hellbeast_idle', atk: 'nb_hellbeast_atk', w: 30, h: 52, hp: 3, face: -1, shot: 'orb', still: true, death: 'flame_death', animAlways: true },
  nb_thing:     { b: 'chaser',  anim: 'nb_thing_walk', w: 20, h: 36, hp: 3, face: 1, spd: 40, run: 120, death: 'poof' },
  nb_swghost:   { b: 'ghost',   anim: 'nb_swghost_fly', w: 22, h: 38, hp: 2, face: 1, death: 'poof' },
  nb_hooded:    { b: 'chaser',  anim: 'nb_hooded_walk', w: 24, h: 26, hp: 2, face: -1, spd: 65, run: 230, death: 'poof', sc: 2 },
  nb_spider:    { b: 'chaser',  anim: 'nb_spider_walk', w: 28, h: 18, hp: 2, face: 1, spd: 70, run: 280, death: 'poof' }
});
// qué criatura nueva reemplaza a cada enemigo recoloreado, por mundo
const BEST_SWAP = {
  1: { g: ['nb_hellbeast', 'nb_hooded'], a: ['nb_bat'] },
  2: { a: ['nb_fireskull'] },
  5: { g: ['nb_reaper', 'icehound'], a: ['nb_eghost'] },
  6: { g: ['nb_hellbeast', 'nb_nightmare'], a: ['nb_fireskull'] },
  7: { g: ['shieldskel', 'nb_knight'], a: ['nb_flyeye', 'nb_bat'] },
  8: { g: ['crab', 'nb_meerman'] },
  12: { g: ['nb_toad', 'mushroom', 'nb_thing'], a: ['nb_swghost', 'eye'] },
  13: { g: ['nb_ogre', 'nb_werewolf', 'gskel'], a: ['nb_eghost', 'nb_flyeye'] },
  14: { g: ['golem', 'nb_spider'], a: ['nb_bat'] },
  15: { g: ['nb_reaper', 'nb_nightmare'], a: ['ghost', 'nb_flyeye'] },
  16: { g: ['nb_knight', 'nb_reaper'] },
  17: { a: ['seraph', 'nb_flyeye'] }
};
for (const w in BEST_SWAP) { const s = BEST_SWAP[w]; if (s.g) WORLDS[w].g = s.g; if (s.a) WORLDS[w].a = s.a; }
// comportamientos especiales ajustados a las criaturas nuevas
Object.assign(FOE_PLAN, {
  1: [['nb_hooded', 'rammer', .4], ['nb_hellbeast', 'sniper', .5]],
  5: [['icehound', 'rammer', .7]],
  6: [['nb_nightmare', 'rammer', .8]],
  7: [['nb_flyeye', 'dropper', .4]],
  12: [['mushroom', 'ambusher', .8]],
  13: [['nb_werewolf', 'rammer', .5], ['gskel', 'reviver', .6]],
  14: [['golem', 'ambusher', .7], ['nb_bat', 'dropper', .4]],
  15: [['nb_reaper', 'reviver', .8], ['nb_nightmare', 'rammer', .6]],
  16: [['ghost', 'book', .6], ['eye', 'book', .8], ['nb_reaper', 'reviver', .5]],
  17: [['nb_flyeye', 'dropper', .35], ['seraph', 'spread', .6]]
});
FOE_HINT.brute = 'Ese bruto levanta el arma antes de golpear: apártate y contraataca por la espalda.';
try { Object.assign(ENAME, { nb_werewolf: 'hombre lobo', nb_nightmare: 'pesadilla', nb_knight: 'caballero terrible', nb_ogre: 'ogro', nb_reaper: 'segador', nb_eghost: 'espectro', nb_flyeye: 'ojo demoníaco', nb_toad: 'sapo mutante', nb_fireskull: 'calavera de fuego', nb_meerman: 'hombre pez', nb_bat: 'murciélago', nb_hellbeast: 'bestia infernal', nb_thing: 'cosa del pantano', nb_swghost: 'fantasma del pantano', nb_hooded: 'encapuchado', nb_spider: 'araña' }); } catch (e) {}
// ---------------- bruto: camina, levanta el arma (aviso) y golpea delante ----------------
const _updEnemiesB = updateEnemies;
updateEnemies = function (dt) {
  _updEnemiesB(dt);
  const D = DIFFS[diffIdx], pcx = p.x + p.w / 2, pcy = p.y + p.h / 2;
  for (const e of level.enemies) {
    if (e.dead || e.b !== 'brute' || Math.abs(e.x - cam.x - VW / 2) > 900) continue;
    const d = e.d, cx = e.x + e.w / 2, dx = pcx - cx, dy = pcy - (e.y + e.h / 2), adx = Math.abs(dx);
    if (!e.st) e.st = 'walk';
    e.cd = (e.cd || 0) - dt;
    if (e.st === 'walk') {
      const sees = adx < 260 && Math.abs(dy) < 80 && !p.dead;
      if (sees) e.dir = dx > 0 ? 1 : -1;
      if (sees && adx < d.reach + 10 && e.cd <= 0) { e.st = 'wind'; e.tt = 0.5 / Math.max(.8, D.aggr); e.alert = e.tt; e.af = 0; sfx('swing', .3, .7); foeHint('brute', cx); }
      else if (e.hit <= 0) {
        const nx = e.x + e.dir * d.spd * D.spd * dt, fx_ = e.dir > 0 ? nx + e.w + 2 : nx - 2;
        if (groundBelow(fx_, e.y + e.h, 14) && (sees || (nx > e.minX && nx < e.maxX))) e.x = nx; else if (!sees) e.dir *= -1;
      }
    } else if (e.st === 'wind') {
      e.tt -= dt; if (e.hit > 0.1) { e.st = 'walk'; e.cd = 0.8; continue; }
      if (e.tt <= 0) { e.st = 'hit'; e.tt = 0.32; sfx('stomp', .45); shake = Math.max(shake, 3); }
    } else if (e.st === 'hit') {
      e.tt -= dt;
      if (!e.dmgDone && !p.dead && overlap(p, { x: e.dir > 0 ? e.x + e.w - 6 : e.x - d.reach + 6, y: e.y - 6, w: d.reach, h: e.h + 8 })) { e.dmgDone = true; hurt(18, cx); }
      if (e.tt <= 0) { e.st = 'walk'; e.cd = 1.5 / D.aggr; e.dmgDone = false; }
    }
  }
};
// ---------------- dibujo: brutos y criaturas con escala propia ----------------
const _drawEnemyB = drawEnemy;
drawEnemy = function (e) {
  const d = e.d;
  if (e.b !== 'brute' && !d.sc) return _drawEnemyB(e);
  const cx = e.x + e.w / 2, by = e.y + e.h, wh = e.hit > 0, flip = d.face === 0 ? false : e.dir !== d.face, sc = d.sc || 1;
  if (d.glow) glowAt(cx, e.y + e.h / 2, Math.max(e.w, e.h) * .9, d.glow, .6);
  if (e.b === 'brute') {
    if (e.st === 'wind' || e.st === 'hit') {
      const n = meta(d.atk).n, half = Math.max(1, Math.floor(n / 2));
      const f = e.st === 'wind' ? Math.min(half - 1, Math.floor((1 - e.tt / 0.5) * half)) : Math.min(n - 1, half + Math.floor((1 - e.tt / 0.32) * (n - half)));
      if (e.st === 'wind') { bx.save(); bx.translate(Math.round(Math.sin(time * 50)), 0); spr(d.atk, f, cx, by + 1, flip, 1, wh); bx.restore(); glowAt(cx + e.dir * 20, e.y + e.h * .4, 26, 'rgba(255,70,60,.5)', .6); }
      else spr(d.atk, f, cx, by + 1, flip, 1, wh);
    } else spr(d.anim, Math.floor(e.t * (e.hit > 0 ? 0 : 9)), cx, by + 1, flip, 1, wh);
    if (e.alert > 0) { const y = e.y - 14; bx.fillStyle = '#ffffff'; bx.fillRect(Math.round(cx) - 2, y - 1, 5, 12); bx.fillStyle = '#ff3d5a'; bx.fillRect(Math.round(cx) - 1, y, 3, 7); bx.fillRect(Math.round(cx) - 1, y + 8, 3, 2); }
    return;
  }
  // criaturas con escala: voladoras y el encapuchado
  const air = e.b === 'flyer' || e.b === 'diver' || e.b === 'dropper';
  spr(d.anim, Math.floor(e.t * 10), cx, air ? e.y + e.h + 4 : by + 1, flip, sc, wh);
};
