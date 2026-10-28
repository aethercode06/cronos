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

## 4. Personajes propios

**Con animaciones en tira:** en el Inspector del Jugador o del Enemigo, en *Aspecto → Anim Set*, crea un **AetherAnimSet** y añade animaciones con estos nombres:
- Jugador: `idle`, `run`, `jump`, `fall`, `double_jump`, `attack1`, `attack2`, `attack3`, `air_attack`, `dash`, `guard`, `guard_hit`, `hurt`, `death`.
- Criaturas: `move`, `jump`.

**Por piezas:** añade un **Personaje por piezas**, y en *Parts* crea una pieza por cada imagen: nombre, imagen, pieza madre, punto de giro y papel (cuerpo, cabeza, mandíbula, brazo…). Elige la animación automática en *Motion* o crea las tuyas con un **AnimationPlayer** animando la rotación de cada pieza.

## 5. Exportar

**Proyecto → Exportar → Android → Exportar proyecto.** Se genera el APK para instalar o publicar.

## 6. Claude (opcional)

En el panel **Claude (opcional)** pon tu clave de Anthropic y pide cosas como «crea un enemigo que lance fuego». Claude propone archivos y **no se escribe nada hasta que pulsas «Aplicar archivos»**. Sin clave, el panel no hace nada.

## 7. Ejemplo incluido

**Abrir la prueba de Chronos** (panel Aether): el Mundo 1 de *Chronos & The Shift* con el Gran Sapo Ancestral. Mira `demo/chronos_w1/frog_boss.gd` para ver cómo se escribe un jefe completo.
