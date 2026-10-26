# Chronos & The Shift — notas para Claude

Juego de plataformas 2D dark fantasy de Aether Code (César de los Santos Rivera). Un solo HTML con el arte embebido.

## Estructura
- `src/*.js` — módulos del juego. Orden de ensamblado en `src/build.py` (MODS). `python3 src/build.py` genera `www/index.html`.
  - core, hdrender, gl, amb, story, data, logic, ext, terrain, hd, live, live2, render, particles, abilities, flow, ui,
    polish (continuar en checkpoint, furia de jefes, Cámaras del Desafío, logros, mando, calidad, Android),
    modes (estrellas por fase, Torre del Tiempo), i18n_data + i18n_extra + i18n (9 idiomas).
  - `src/*assets.js` — arte embebido (no editar a mano). `src/head.html` — cabecera del HTML.
- Mundos 14-17 (v1.9: Minas de Cristal, Bosque de Huesos, Biblioteca Prohibida, Torre de las Tormentas) tienen fondos pintados con Higgsfield (`pbg14`-`pbg17`, `pbg13` del Rey Caído y `pbg12` del Pantano; guardianes pintados `boss_golemc`, `boss_stag`, `boss_archi`; originales en `store/fondos_higgsfield/`) y el resto del arte recoloreado de otros mundos en `src/hf16assets.js` (terreno, decorado, guardianes `boss_golemc`, `boss_stag`, `boss_dragon`, `WZB_*`). `WBASE`/`VWI()` en data.js dice a qué mundo se parecen para pasos y partículas. Orden de juego en `ORDER` (flow.js); el guardado v5 desplaza las fases ≥36.
- Criaturas gigantes del cielo por mundo en `GIANT_OF` (live2.js): las marinas (ballena, mantarraya, medusa) solo en el Arrecife y el Nexo.
- `i18n/*.json` — traducciones por id (`es.json` es el original). Textos nuevos: añadirlos en `src/i18n_extra.js` o `src/i18n_extra2.js` en los 9 idiomas.
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
- Arte HD de los jefes de los mundos 1 y 3–7, arte propio para Pantano y Ciudadela, música original (necesita créditos de Higgsfield).
- Fases secretas por mundo, Modo Pesadilla, Boss Rush. AAB firmado y API 36 para Google Play.
- El usuario habla español y trabaja desde un Samsung S23 Ultra (sin computadora).
