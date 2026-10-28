@icon("res://addons/aether/icons/rig.svg")
class_name AetherRigPart
extends Resource
## Una pieza de un personaje por piezas (cabeza, brazo, pierna, ala…).
## Se monta en el Inspector: imagen, a qué pieza va unida y por dónde gira.

## Nombre único de la pieza (por ejemplo «torso», «cabeza», «brazo_d»).
@export var name := ""
## Imagen de la pieza.
@export var texture: Texture2D
## Pieza a la que va unida (vacío = es la raíz, normalmente el torso o la cadera).
@export var parent := ""
## Punto de giro dentro de la imagen, en píxeles (hombro, cuello, cadera…).
@export var pivot := Vector2.ZERO
## Dónde se coloca ese punto de giro respecto al punto de giro de la pieza madre.
@export var offset := Vector2.ZERO
## Orden de dibujo: mayor = por delante.
@export var z := 0
## Papel de la pieza en las animaciones automáticas.
@export_enum("cuerpo", "cabeza", "mandibula", "brazo_delante", "brazo_detras", "pierna_delante", "pierna_detras", "cola", "ala", "arma", "otro") var role := "otro"
