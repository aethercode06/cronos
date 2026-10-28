@icon("res://addons/aether/icons/aether.svg")
class_name AetherLogic
extends Node
## Lógica sin código de la escena: lista de eventos «CUANDO… SI… → HACER…».
## Edítalos en el panel «Eventos» del editor (o en el Inspector).

## Eventos de esta escena.
@export var events: Array[AetherEvent] = []
## Variables con las que empieza la escena (nombre → valor).
@export var start_vars := {"monedas": 0}
## Cargar las variables guardadas (si existen) en vez de las iniciales.
@export var load_saved_vars := false

var runner: AetherLogicRunner

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	for k in start_vars:
		Aether.set_var(k, float(start_vars[k]))
	if load_saved_vars:
		var saved: Dictionary = Aether.save.get_value("vars", {})
		for k in saved:
			Aether.set_var(k, float(saved[k]))
	runner = AetherLogicRunner.new(self, events)
	runner.start.call_deferred()

func _process(delta: float) -> void:
	if runner:
		runner.tick(delta)

func _exit_tree() -> void:
	if runner:
		runner.dispose()
