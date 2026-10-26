# Chronos & The Shift — notas para Claude

Juego de plataformas 2D dark fantasy de Aether Code (César de los Santos Rivera). Un solo HTML con el arte embebido.

## Estructura
- `src/*.js` — módulos del juego. Orden de ensamblado en `src/build.py` (MODS). `python3 src/build.py` genera `www/index.html`.
  - core, hdrender, gl, amb, story, data, logic, ext, terrain, hd, live, live2, render, particles, abilities, flow, ui,
    polish (continuar en checkpoint, furia de jefes, Cámaras del Desafío, logros, mando, calidad, Android),
    modes (estrellas por fase, Torre del Tiempo), i18n_data + i18n_extra + i18n (9 idiomas).
  - `src/*assets.js` — arte embebido (no editar a mano). `src/head.html` — cabecera del HTML.
- Mundos 14-17 (v1.9: Minas de Cristal, Bosque de Huesos, Biblioteca Prohibida, Torre de las Tormentas) tienen fondos pintados con Higgsfield (`pbg14`-`pbg17`, `pbg13` del Rey Caído y `pbg12` del Pantano; guardianes pintados `boss_golemc`, `boss_stag`, `boss_archi`; originales en `store/fondos_higgsfield/`) y el resto del arte recoloreado de otros mundos en `src/hf16assets.js` (terreno, decorado, guardianes `boss_golemc`, `boss_stag`, `boss_dragon`, `WZB_*`). `WBASE`/`VWI()` en data.js dice a qué mundo se parecen para pasos y partículas. Orden de juego en `ORDER` (flow.js); el guardado v5 desplaza las fases ≥36.
- v2.0: guardianes clásicos pintados `hdb_frog`, `hdb_wizard`, `hdb_eye`, `hdb_knight`, `hdb_beast`, `hdb_demon` (HDB en render.js) y `boss_dragon` pintado; decorados propios `pr12_*` y `pr14_*`-`pr17_*`; escenas nuevas `veil` (tras el mundo 10) y `late` (tras el 17) con `cs_veil`, `cs_swamp`, `cs_storm`, `cs_echo`, `cs_citadel`; todo en `src/hf16assets.js` (originales en `store/fondos_higgsfield/hf_guardian_*`). Recortes de fondo con rembg en local.
- v2.1: `src/foes.js` — variantes de enemigos por mundo (FOE_PLAN): rammer (embiste), sniper (mira láser), dropper (suelta cosas, sombra), burrower (bajo la arena), ambusher/dormant (disfrazado), reviver (se recompone salvo en dimensión violeta), book (libros que persiguen, arte `pr16_5`), pulse (medusa con descarga), splitter (rata que se parte), spread (abanico), y rayos con aviso en la Torre. Pistas de Tic en FOE_HINT (traducidas en i18n_extra2).
- v2.1: `src/tele.js` — medición local de partidas (intentos, muertes con posición y causa, abandonos, reinicios, tiempos) en `chronos_stats`; pantalla ESTADÍSTICAS (botón arriba a la derecha del título) con mapa de calor y botón COMPARTIR (informe de texto).
- v2.2: `src/rush.js` — Modo PESADILLA (4.ª dificultad, DIFFS[3].nm; se abre al terminar la historia; +1 vida a enemigos, gemas x2; las ramas `diffIdx >= 2` cubren Difícil y Pesadilla) y BOSS RUSH (18 guardianes en orden ORDER, vida entre jefes +30; se abre con 3 guardianes; récord SAVE.rushMax/rushBest). Logros nuevos pesadilla1/18, rush6/18.
- v2.2: `src/music.js` — banda sonora original generada por código (SONGS: un tema por mundo + gmenu/gboss/gfinal), sintetizador propio SYNTH() en un Worker → WAV en memoria (máx. 8 temas). Opción «Banda sonora: Original/Clásica» (OPT.ost). Sombras de contacto suaves para jugador y enemigos al final de foes.js.
- Criaturas gigantes del cielo por mundo en `GIANT_OF` (live2.js): las marinas (ballena, mantarraya, medusa) solo en el Arrecife y el Nexo.
- `i18n/*.json` — traducciones por id (`es.json` es el original). Textos nuevos: añadirlos en `src/i18n_extra.js` o `src/i18n_extra2.js` en los 9 idiomas.
- `www/prueba.html` — versión de prueba (window.CHRONOS_PRUEBA: todo abierto, guardado aparte `chronos_prueba`); el workflow la compila como APK aparte `Chronos-PRUEBA.apk` (com.aethercode.chronos.prueba).
- `www/` — juego listo + PWA (manifest, sw.js: subir VERSION en cada publicación) + privacidad.html.
- `assets/` — icono y splash para @capacitor/assets. `keys/debug.keystore` — firma fija del APK (no cambiar: permite actualizar sin desinstalar).
- `.github/workflows/android.yml` — compila el APK y lo publica en la release `ultima-version` (Chronos-The-Shift.apk).
- `.github/workflows/web.yml` — publica `www/` en la rama gh-pages.
- `store/` — material para Google Play.

## Al cambiar el juego
1. Editar `src/`, ejecutar `python3 src/build.py`, subir VERSION en `www/sw.js`.
2. Probar con Playwright (Chromium headless con `--headless=new`): sin errores de página, 54 fases alcanzables, 18 jefes vencibles.
3. Commit y push a main: GitHub compila el APK solo.

## Pendiente
- PRÓXIMO (pedido por el usuario): mundo nuevo de bosque medieval fantástico con duendes y elfos como enemigos/personajes. Arte de concepto ya hecho en `store/concepto/bosque_medieval.jpg` y `store/concepto/duendes_elfos.jpg` (duende, duende chamán, elfa arquera, caballero elfo): usarlo como guía de estilo. Faltan hojas de animación, fondo final, terreno y decorados (necesita créditos de Higgsfield).
- Música: la original (music.js) es sintetizada; si el usuario quiere más calidad, mejorar instrumentos o componer temas a mano en SONGS.
- Fases secretas por mundo. AAB firmado y API 36 para Google Play.
- El usuario habla español y trabaja desde un Samsung S23 Ultra (sin computadora).
