@icon("res://addons/aether/icons/aether.svg")
class_name AetherEvent
extends Resource
## Un evento sin código: CUANDO (disparador) + SI (condiciones) → HACER (acciones).

## Disparador (ver AetherLogicSchema.TRIGGERS).
@export var trigger := "inicio"
@export var trigger_params := {}
## Condiciones: todas deben cumplirse.
@export var conditions: Array[AetherStep] = []
## Acciones en orden.
@export var actions: Array[AetherStep] = []
## Solo una vez.
@export var once := false
## Activado.
@export var enabled := true

func describe() -> String:
	var s := "CUANDO " + AetherLogicSchema.describe("trigger", trigger, trigger_params)
	for c in conditions:
		s += "\n  SI " + AetherLogicSchema.describe("condition", c.kind, c.params)
	for a in actions:
		s += "\n  → " + AetherLogicSchema.describe("action", a.kind, a.params)
	return s
