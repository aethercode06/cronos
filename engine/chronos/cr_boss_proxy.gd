extends Node
## Enlace con la barra de jefe del HUD de Aether.
signal hp_changed(hp: float, max_hp: float)
var active := false
var boss_name := ""

func activate(n: String, max_hp: float) -> void:
	boss_name = n
	active = true
	add_to_group("boss")
	hp_changed.emit.call_deferred(max_hp, max_hp)

func set_hp(hp: float, max_hp: float) -> void:
	hp_changed.emit(hp, max_hp)
