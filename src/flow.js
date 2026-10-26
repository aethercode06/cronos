// =====================================================================
//  FLUJO DEL JUEGO, PROGRESO, MENÚS Y HUD
// =====================================================================
let SAVE = { unl: 0, st: {}, best: 0, bank: 0, up: {}, intro: 0 };
try {
  const s = JSON.parse(localStorage.getItem('chronos_save3') || 'null');
  if (s && typeof s.unl === 'number') SAVE = Object.assign(SAVE, s);
  else { const o = JSON.parse(localStorage.getItem('chronos_save2') || 'null'); if (o && typeof o.unl === 'number') { SAVE.unl = Math.floor(o.unl / 2) * 3; SAVE.best = o.best || 0; SAVE.intro = 0; } }
} catch (e) {}
try { migrateSave(); } catch (e) {}
function migrateSave() {
  if ((SAVE.v || 0) >= 5) return;
  if ((SAVE.v || 0) < 4) {
  const st = {}; for (const k in SAVE.st) { const n = +k, w = Math.floor(n / 3), a = n % 3; if (w === 11) st[39 + a] = SAVE.st[k]; else st[n] = SAVE.st[k]; }
  SAVE.st = st; if (SAVE.unl > 33) SAVE.unl = 33; SAVE.v = 4;
  }
  // v5: cuatro mundos nuevos entre el Pantano y el Rey Caído (las fases desde la 36 se desplazan 12)
  const s5 = {}; for (const k in SAVE.st) { const n = +k; s5[n >= 36 ? n + 12 : n] = SAVE.st[k]; }
  SAVE.st = s5; if (SAVE.unl > 36) SAVE.unl = 36; SAVE.v = 5;
}
function persist() { migrateSave(); try { localStorage.setItem('chronos_save3', JSON.stringify(SAVE)); } catch (e) {} }
let best = SAVE.best || 0;
function saveBest() { if (score > best) { best = score; SAVE.best = best; persist(); } }
const ORDER = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 14, 15, 16, 17, 13, 11];
const WPOS = w => ORDER.indexOf(w);
const sIdx = (w, a) => WPOS(w) * 3 + a;
const LAST = ORDER.length * 3 - 1;

function startStage(wi, act, fresh) {
  curWorld = wi; curAct = act;
  if (fresh !== false) score = 0;
  stageScore0 = score;
  setView(EXW(), EXH);
  dim = 0; slowT = 0; cars = []; lightning = 0;
  liveSeed = Math.floor(Math.random() * 1e6);
  level = buildStage(wi, act);
  const D = DIFFS[diffIdx];
  p = { x: level.start.x, y: level.start.y, w: PW, h: PH, vx: 0, vy: 0, face: 1, onGround: false, ground: null,
        jumps: 0, coyote: 0, buf: 0, dashT: 0, dashCD: 0, atkT: 0, atkCD: 0, atkN: 0, inv: 0, stun: 0, noCut: false,
        hp: D.hp + 20 * UP('hp'), maxHp: D.hp + 20 * UP('hp'), boostT: 0, boostDir: 1, dead: false, deadT: 0, hitSet: new Set(), look: 0, anim: 0, stepT: 0,
        wall: 0, wjLock: 0, wjDir: 0, time: 0, combo: 0, comboT: 0, air: false, pogoDone: false };
  p.respawn = { x: p.x, y: p.y }; p.safe = { x: p.x, y: p.y };
  echo = null; invertT = 0; dlg = null; resetTic(); spawnLife(); resetLive(); spawnSwarms(); spawnGiants(); ambEv = null; giantEvent = null; ambEvT = rnd(8, 16);
  boss = null; arenaLock = false; bossIntro = 0;
  projs = []; waves = []; parts = []; trails = []; floats = []; warns = []; fx = [];
  shake = 0; hitStop = 0; flash = 0; levelTime = 0; clearInfo = null; fade = 1; hintT = 0;
  amb = []; for (let i = 0; i < 46; i++) amb.push({ x: Math.random() * 960, y: Math.random() * 540, s: Math.random() < .3 ? 2 : 1, ph: Math.random() * 6, v: rnd(10, 40) });
  updateCamera(0, true);
  state = 'playing';
  playMusic(WORLDS[wi].music); startAmbience(wi); if (curMusic) curMusic.playbackRate = WORLDS[wi].rate || 1;
  banner('MUNDO ' + (WPOS(wi) + 1) + '-' + (act + 1), act === 2 ? 'GUARDIÁN: ' + WORLDS[wi].boss.name : WORLDS[wi].name, WORLDS[wi].c, 2.8);
  loreT = 0;
  const L0 = []; if (act === 0) L0.push(['NARR', WORLDS[wi].lore]); L0.push(['TIC', TICL[wi][act]]);
  sayLines(L0, false); dlg.delay = 2.9;
}
function stageClear() {
  if (state !== 'playing') return;
  const L = level, s = sIdx(curWorld, curAct);
  const g = L.gems.filter(x => x.taken).length, hpB = Math.round(Math.max(0, p.hp)) * 5, bonus = curAct === 2 ? 1500 : 500 + curAct * 300;
  SAVE.bank = (SAVE.bank || 0) + g;
  score += bonus + hpB;
  clearInfo = { g, t: L.gems.length, relic: L.relic && L.relic.taken, hpB, bonus, time: levelTime };
  const prev = SAVE.st[s] || {};
  SAVE.st[s] = { gems: Math.max(prev.gems || 0, g), total: L.gems.length, relic: !!(prev.relic || clearInfo.relic), done: true, score: Math.max(prev.score || 0, score - stageScore0) };
  SAVE.unl = Math.max(SAVE.unl, Math.min(LAST, s + 1));
  saveBest(); persist(); fade = 1; slowT = 0; stopAmbience();
  if (curMusic) curMusic.playbackRate = 1;
  echo = null; dlg = null; invertT = 0;
  if (curAct === 2) { sfx(p.hp >= p.maxHp ? 'v_flawless' : 'v_youwin'); sfx('win', .8); startFragment(curWorld); return; }
  state = 'clear'; sfx('portal', .8); sfx('win', .8);
  playMusic('menu');
}
function nextStage() { const s = sIdx(curWorld, curAct) + 1; if (s > LAST) return toMap(); startStage(ORDER[Math.floor(s / 3)], s % 3, false); }
function retry() { score = stageScore0; startStage(curWorld, curAct, false); }
function toMap() { saveBest(); state = 'map'; fade = 1; setView(MENUW(), 360); stopAmbience(); playMusic('menu'); slowT = 0; }
function toTitle() { state = 'title'; fade = 1; setView(MENUW(), 360); stopAmbience(); playMusic('menu'); }
function pauseGame() { if (state !== 'playing') return; state = 'paused'; if (curMusic) curMusic.volume = 0.15 * OPT.mus; ambGain(0); }
function resume() { state = 'playing'; if (curMusic) curMusic.volume = musicVol * OPT.mus; ambGain(1); }
function banner(t, s, c, d) { bannerTxt = t; bannerSub = s; bannerC = c; bannerT = d; }

// ---------------- Botones ----------------
let mapSel = 0;
function handleTap(x, y, type) {
  const pt = { x, y };
  if (state === 'loading') return;
  if (state === 'cutscene') { if (x > W - 140 && y < 70) { sfx('click'); endCut(); } else cutAdvance(); return; }
  if (state === 'ability') { abilAdvance(); return; }
  if (state === 'fragment') { fragAdvance(); return; }
  if (state === 'playing') {
    if (inRect(pt, pauseBtn)) { pauseGame(); sfx('click'); return; }
    if (dlg && dlg.hold && !(touchMode && inAnyTouchBtn(pt))) { dlgAdvance(); return; }
    if (dlg && !dlg.hold && y < 210 && y > 90) { dlgAdvance(); return; }
    if (loreT > 0 && y > 100 && y < 220) { loreT = Math.min(loreT, 0.4); }
    if (type === 'mouse' && !(touchMode && inAnyTouchBtn(pt))) mouseAttack = true;
    return;
  }
  if (state === 'title' && inRect(pt, musicBtn)) { toggleMusic(); OPT.mus = musicOn ? (OPT.mus || 0.8) : OPT.mus; sfx('click'); return; }
  for (const b of uiButtons()) if (inRect(pt, b)) { sfx(b.big ? 'select' : 'click'); b.fn(); return; }
}
function onKey(c) {
  if (c === 'KeyM' && state !== 'loading') { toggleMusic(); return; }
  if (state === 'cutscene') { if (c === 'Escape') endCut(); else if (c === 'Enter' || c === 'Space' || c === 'KeyZ') cutAdvance(); return; }
  if (state === 'ability') { if (c === 'Enter' || c === 'Space' || c === 'KeyZ' || c === 'Escape') abilAdvance(); return; }
  if (state === 'fragment') { if (c === 'Enter' || c === 'Space' || c === 'KeyZ') fragAdvance(); return; }
  if (state === 'shop') { if (c === 'Escape' || c === 'Enter') state = 'map'; return; }
  if (state === 'title') { if (c === 'Enter' || c === 'Space') { sfx('select'); uiButtons()[0].fn(); } }
  else if (state === 'map') {
    if (c === 'ArrowLeft') { mapSel = (mapSel + LAST) % (LAST + 1); sfx('click'); } else if (c === 'ArrowRight') { mapSel = (mapSel + 1) % (LAST + 1); sfx('click'); }
    else if (c === 'ArrowUp') { mapSel = (mapSel + LAST + 1 - 9) % (LAST + 1); sfx('click'); } else if (c === 'ArrowDown') { mapSel = (mapSel + 9) % (LAST + 1); sfx('click'); }
    else if (c === 'Digit1' || c === 'Digit2' || c === 'Digit3') { diffIdx = +c.slice(5) - 1; sfx('click'); }
    else if (c === 'KeyT') state = 'shop';
    else if (c === 'Enter') { const w = ORDER[Math.floor(mapSel / 3)], a = mapSel % 3; if (mapSel <= SAVE.unl) { sfx('select'); beginStage(w, a); } }
    else if (c === 'Escape') toTitle();
    mapPage = Math.floor(Math.floor(mapSel / 3) / 6);
  } else if (state === 'playing') { if (c === 'Escape' || c === 'KeyP') pauseGame(); else if (dlg && dlg.hold && (c === 'Enter' || c === 'KeyZ' || c === 'KeyJ')) dlgAdvance(); }
  else if (state === 'paused') { if (c === 'Escape' || c === 'KeyP' || c === 'Enter') resume(); }
  else if (state === 'options') { if (c === 'Escape' || c === 'Enter') closeOptions(); }
  else if (c === 'Enter') { const b = uiButtons(); if (b[0]) b[0].fn(); }
}

