@icon("res://addons/aether/icons/anim.svg")
class_name AetherAnim
extends Resource
## Una animación en tira: todos los fotogramas en una sola imagen, uno al lado del otro.
## Se crea en el Inspector sin programar: elige la imagen, cuántos fotogramas tiene y la velocidad.

## Imagen con los fotogramas en fila (de izquierda a derecha).
@export var texture: Texture2D
## Número de fotogramas que hay en la imagen.
@export_range(1, 128) var frames := 1
## Fotogramas por segundo.
@export_range(1.0, 60.0) var fps := 12.0
## ¿Vuelve a empezar al terminar? (correr, reposo: sí · golpe, muerte: no)
@export var loop := true
## Punto de apoyo dentro de cada fotograma, en píxeles (normalmente los pies).
## Si lo dejas en (0, 0), se usan los pies centrados.
@export var anchor := Vector2.ZERO
