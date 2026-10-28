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

## 5. Exportar

**Proyecto → Exportar → Android → Exportar proyecto.** Se genera el APK para instalar o publicar.

## 6. Claude (opcional)

El motor funciona completo **sin IA**. Si quieres ayuda, en el panel **Claude (opcional)** pon tu clave de Anthropic y pide cosas como:
- «Pon 5 monedas y una meta al final»
- «Haz que el jugador salte más alto»
- «Cuando tenga 10 monedas, abre la puerta»
- «Crea un jefe que lance fuego»

Claude **ve tu escena** y puede crear piezas, ajustarlas, borrarlas, crear eventos, abrir plantillas, escribir scripts, guardar y probar el juego. **Nada cambia hasta que pulsas «Aplicar»**, y todo se puede deshacer con *Deshacer*.

## 7. Ejemplo incluido

**Abrir la prueba de Chronos** (panel Aether): el Mundo 1 de *Chronos & The Shift* con el Gran Sapo Ancestral. Mira `demo/chronos_w1/frog_boss.gd` para ver cómo se escribe un jefe completo.
