# Aether Engine — Guía rápida

Aether Engine es el motor de **Aether Code**, construido sobre **Godot 4.7**. Tiene todo lo que tiene Godot (2D, 3D, física, animación, sonido, exportar a Android y PC) y, además, las **piezas de Aether**: listas para hacer juegos de acción sin programar.

El asistente **Claude es opcional**: el motor funciona completo sin IA.

---

## 1. Instalar en Android

1. Descarga **AetherEngine-Editor.apk** e instálalo (si el teléfono lo pide, permite instalar apps de origen desconocido).
2. Descarga **AetherEngine-Proyecto.zip**.
3. Abre Aether Engine → **Importar** → elige el zip → **Importar y editar**.

## 2. Tu primer juego en 5 minutos

1. En el panel **Aether** (a la derecha) pulsa **Nueva fase de plataformas**.
2. Pulsa **▶** (arriba a la derecha) para jugar.
3. Toca cualquier pieza y cambia sus ajustes en el **Inspector**:
   - **Jugador**: velocidad, salto, doble salto, dash, vida.
   - **Enemigo**: comportamiento (patrulla, saltarín, volador), vida, daño.
   - **Suelo**: ancho y alto, textura, plataforma atravesable.
4. Mueve suelos y enemigos arrastrándolos con el dedo.
5. Para añadir más: botones del panel **Aether → Añadir a la escena**.

## 3. Las piezas

| Pieza | Qué hace |
|---|---|
| **Jugador** (`PlatformerPlayer`) | Correr con inercia, salto con margen, doble salto, dash, combo de 3 golpes, golpe aéreo, guardia, daño y reaparición. |
| **Enemigo** (`AetherEnemy`) | Patrulla y embiste con aviso «!», salta hacia ti o vuela y se lanza en picado. Destello, retroceso y explosión al morir. |
| **Jefe** (`AetherBoss`) | Vida, furia al 50 %, momento débil con «¡CRÍTICO!», golpes «DUROS», guardia «¡BLOQUEO!» y derrota épica. Se hereda para crear cada jefe. |
| **Suelo** (`AetherGround`) | Bloques y plataformas con textura que se ven también en el editor. |
| **Cámara épica** (`AetherCamera`) | Sigue con anticipación, tiembla con suavidad, zoom de impacto y zona fija para arenas. |
| **Personaje por piezas** (`AetherRig`) | Monta un personaje con piezas (cabeza, brazos, piernas, alas…) y anímalo con huesos: reposo, andar, preparar, golpe, cubrirse, herido, furia, derrota. |
| **Animaciones** (`AetherAnimSet`) | Tus propias animaciones en tira: imagen, número de fotogramas, velocidad. |
| **Interfaz** (`AetherHUD`) | Vida con retrato, barra de jefe y carteles grandes. Se conecta sola al jugador. |
| **Controles táctiles** | Botones grandes que aparecen solo en pantallas táctiles. |
| **Efectos** (`FX`) | Chispas, ondas expansivas, halos, estelas de espada y textos flotantes que brillan. |
| **Aether** (siempre activo) | Parón de impacto, cámara lenta, temblor, destellos, sonido y música. |

### Plantillas (panel Aether → Crear)

| Plantilla | Qué es |
|---|---|
| Fase de plataformas | Nivel 2D con suelos, enemigos, cámara, vida, controles y pausa. |
| Arena de jefe | Combate contra el Gran Sapo: el jefe empieza solo al acercarte y su barra aparece sola. |
| Corredor infinito | El jugador corre solo; el nivel se genera sin fin y se guarda el récord. |
| Aventura 3D | Mundo 3D con cielo, sol y sombras, jugador en tercera persona, enemigos, joystick táctil. |
| Pantalla de título | Menú con JUGAR, OPCIONES (música, efectos, idioma) y SALIR. |
| + 9 juegos por género | Ver la tabla siguiente. |

### Juegos completos por género (panel Aether → Juegos completos por género)

Cada uno es un juego terminado que se cambia desde el Inspector, sin programar:

| Juego | Qué tiene | Qué puedes cambiar |
|---|---|---|
| **Disparos (nave)** | Nave que dispara sola, oleadas, jefe cada 5 oleadas, mejoras (triple disparo, vida). Se mueve arrastrando el dedo. | Imágenes de nave, enemigos y fondo, velocidad, cadencia, vidas, oleadas para ganar. |
| **Puzle de unir 3** | Desliza gemas, cascadas con combo, sin jugadas = tablero nuevo. | Tamaño del tablero, tipos de gema, imágenes, movimientos y puntos objetivo. |
| **Defensa de torres** | Camino, oleadas, 3 torres (Arquero, Cañón, Hielo) que se mejoran tocándolas. | Puntos del camino, oro inicial, vidas, oleadas, imagen de enemigos. |
| **Carreras (vista de arriba)** | Circuito, rivales con IA, vueltas, derrape, puesto final. | Puntos del circuito, vueltas, rivales y su habilidad, velocidad, coche. |
| **Carreras 3D** | Coche con física real (suspensión, derrape), rampa, conos, cámara detrás. | Potencia, giro, velocidad máxima, tu modelo .glb. |
| **Lucha 1 contra 1** | Puñetazo, patada, bloqueo, onda de energía, rival con IA, rondas, K.O. | Nombres, colores, dificultad del rival, vida, tiempo, rondas. |
| **Cartas por turnos** | Energía, mano de 5, intenciones del enemigo, carta nueva tras cada victoria. | Cartas, mazo y enemigos **escritos como texto**. |
| **RPG / aventura** | Mapa dibujado con letras, personajes que hablan, monstruos, llaves, cofres y salida. | El mapa (letras), lo que dicen los personajes, llaves necesarias. |
| **Terror con linterna** | Oscuridad, linterna con batería, acechadores que solo se mueven si no los miras. | El mapa, pilas, llaves, imágenes. |

**Mapa de letras:** `#` pared · `.` suelo · `P` jugador · `M` monstruo · `S` acechador · `N` personaje · `$` moneda · `C` cofre · `K` llave · `H` corazón · `B` pilas · `E` salida · `T` árbol.

### Piezas 3D

| Pieza | Qué hace |
|---|---|
| **Jugador 3D** (`AetherPlayer3D`) | Se mueve según la cámara, salta, doble salto, dash, combo. Usa tu modelo .glb (con animaciones idle, run, jump, attack…) o una figura sencilla. |
| **Enemigo 3D** (`AetherEnemy3D`) | Patrulla, te persigue, avisa y embiste. |
| **Cámara 3D** (`AetherCamera3D`) | Tercera persona; gira con el dedo (lado derecho) o el ratón; no atraviesa paredes. |
| **Ambiente 3D** (`AetherWorld3D`) | Cielo, sol con sombras, niebla y brillo: día, atardecer, noche o mazmorra. |
| **Joystick táctil** | Mover con el pulgar izquierdo, girar la cámara con el derecho, botones de salto, ataque y dash. |

Las formas 3D sencillas (cajas, esferas, cilindros) se crean con los nodos **CSG** de Godot y se les puede activar colisión.

### Sistemas listos (desde cualquier script)

| Sistema | Uso |
|---|---|
| Guardado | `Aether.save.set_value("nivel", 3)` · `Aether.save.get_value("nivel", 1)` |
| Idiomas | Textos en `idiomas/en.json`, etc. `Aether.t("JUGAR")`. Detecta el idioma del teléfono. |
| Logros | `Aether.achievements.define(...)` y `Aether.achievements.unlock("id")` con aviso en pantalla. |
| Avisos | `Aether.toast("¡Bien hecho!")` |
| Anuncios y compras | `Aether.store.show_rewarded(func(ok): ...)` · `Aether.store.buy("traje", func(ok): ...)`. Sin cuentas funciona en modo prueba; con los plugins de AdMob y Google Play Billing usa los reales. |
| Menús | Pieza **Menú** en modo título o pausa (música, efectos, idioma). |

### Lógica sin código (panel «Eventos»)

1. Añade **Lógica de la escena** (o una **Zona**) desde el panel Aether.
2. Selecciónala: en el panel **Eventos** pulsa **+ Nuevo evento**.
3. Elige **CUANDO** (al empezar, cada X segundos, al pulsar un botón, al entrar en la zona, al recoger algo, cuando una variable llega a un valor, al vencer a un enemigo o al jefe, cuando el jugador cae).
4. Añade **SI** (condiciones) y **HACER** (sumar, mostrar aviso o cartel, sonar, música, curar, dañar, crear, eliminar, llevar al jugador, punto de control, ir a otra escena, temblor, destello, cámara lenta, logro, guardar, esperar, diálogo, tienda, dar o quitar objetos, efecto, «¡fase superada!», anuncio con premio).

Ejemplo de la plantilla de plataformas: *CUANDO monedas llega a 5 → aviso «¡5 monedas!» + sonido* y una **Zona** al final: *CUANDO el jugador entra → ¡Fase superada!*

Piezas de apoyo: **Objeto recogible** (monedas, gemas, vida), **Contador en pantalla**, **Diálogo con retratos**, **Tienda**, **Misiones**, **Regalo diario**, **Efecto especial** (golpe, magia, explosión, curación, rayo, fuego, portal, nieve, lluvia, hojas, chispas, aura).

### Modo fácil

En el panel Aether, **Modo fácil** oculta lo avanzado del editor para empezar sin agobios. Desactívalo para tener todo Godot.

### Calidad automática

El motor detecta el teléfono y ajusta la calidad (resolución 3D, brillo, 60 fps) para que vaya fluido en gama media.

## 4. Personajes propios

**Con animaciones en tira:** en el Inspector del Jugador o del Enemigo, en *Aspecto → Anim Set*, crea un **AetherAnimSet** y añade animaciones con estos nombres:
- Jugador: `idle`, `run`, `jump`, `fall`, `double_jump`, `attack1`, `attack2`, `attack3`, `air_attack`, `dash`, `guard`, `guard_hit`, `hurt`, `death`.
- Criaturas: `move`, `jump`.

**Por piezas:** añade un **Personaje por piezas**, y en *Parts* crea una pieza por cada imagen: nombre, imagen, pieza madre, punto de giro y papel (cuerpo, cabeza, mandíbula, brazo…). Elige la animación automática en *Motion* o crea las tuyas con un **AnimationPlayer** animando la rotación de cada pieza.

## 5. Exportar y publicar (panel «Publicar»)

1. **Datos del juego:** nombre, paquete (`com.tuempresa.tujuego`), versión, icono y orientación → **Guardar datos**.
2. **Comprobar:** la lista marca en verde lo que está listo para Google Play.
3. **Ficha de Google Play:** escribe las descripciones y crea la ficha y la **política de privacidad** (`publicar/privacidad.html`).
4. **Capturas:** mientras pruebas el juego, toca la pantalla con **3 dedos** (o F12): se guardan en Imágenes/Aether. **Tráiler:** el panel graba un vídeo mientras juegas.
5. **APK de prueba:** Proyecto → Exportar → Android → Exportar proyecto.
6. **AAB para Google Play:** Google Play pide AAB firmado con tu clave de subida y el teléfono no puede crearlo, pero GitHub sí (gratis). El panel crea `publicar/google_play.yml` y `COMO_PUBLICAR.txt` con los pasos (repositorio privado, crear la clave una sola vez, obtener el AAB).

## Aprender

El panel **Aprender** tiene 8 lecciones paso a paso con botones «Hazlo por mí»: primer juego, lógica sin código, géneros, mapas de letras, personajes propios, 3D, publicar y Claude.

## Idiomas

El motor y los juegos vienen en español, inglés, portugués, francés, alemán e italiano. Detecta el idioma del teléfono; se cambia en Opciones. Para añadir otro, crea `idiomas/<código>.json` con las traducciones.

## 6. Claude (opcional)

El motor funciona completo **sin IA**. Si quieres ayuda, en el panel **Claude (opcional)** pon tu clave de Anthropic y pide cosas como:
- «Pon 5 monedas y una meta al final»
- «Haz que el jugador salte más alto»
- «Cuando tenga 10 monedas, abre la puerta»
- «Crea un jefe que lance fuego»

Claude **ve tu escena** y puede crear piezas, ajustarlas, borrarlas, crear eventos, abrir plantillas, escribir scripts, guardar y probar el juego. **Nada cambia hasta que pulsas «Aplicar»**, y todo se puede deshacer con *Deshacer*.

## 7. Ejemplo incluido

**Abrir la prueba de Chronos** (panel Aether): el Mundo 1 de *Chronos & The Shift* con el Gran Sapo Ancestral. Mira `demo/chronos_w1/frog_boss.gd` para ver cómo se escribe un jefe completo.
