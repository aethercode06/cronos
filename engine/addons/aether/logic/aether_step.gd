class_name AetherStep
extends Resource
## Un bloque de condición o de acción con sus valores.

@export var kind := ""
@export var params := {}

static func make(p_kind: String, p_params := {}) -> AetherStep:
	var s := AetherStep.new()
	s.kind = p_kind
	s.params = p_params
	return s
