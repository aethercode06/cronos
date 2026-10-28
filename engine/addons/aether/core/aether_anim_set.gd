@icon("res://addons/aether/icons/anim.svg")
class_name AetherAnimSet
extends Resource
## Conjunto de animaciones de un personaje. Los nombres que usan las piezas de
## Aether son: idle, run, jump, fall, double_jump, attack1, attack2, attack3,
## air_attack, dash, guard, guard_hit, hurt, death (jugador) y move, attack,
## jump, hurt, death (criaturas). Si falta alguna, se usa la más parecida.

## Escala con la que se dibujan los fotogramas en el mundo.
@export_range(0.05, 4.0) var scale := 0.6
## Animaciones por nombre.
@export var anims: Dictionary[String, AetherAnim] = {}
