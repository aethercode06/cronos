@icon("res://addons/aether/icons/ui.svg")
class_name AetherDaily
extends CanvasLayer
## Recompensa diaria con racha (como el cofre de Chronos): al abrir el juego un
## día nuevo, regala «base + extra × días seguidos» de la variable elegida.

## Variable que se regala.
@export var currency := "monedas"
## Regalo base.
@export var base := 15
## Extra por cada día seguido.
@export var per_day := 5
## Máximo de días de racha.
@export var max_streak := 7

func _ready() -> void:
	layer = 72
	var today := int(Time.get_unix_time_from_system() / 86400.0)
	var last := int(Aether.save.get_value("daily_last", -1))
	if last == today:
		return
	var streak := int(Aether.save.get_value("daily_streak", 0))
	streak = streak + 1 if last == today - 1 else 1
	streak = min(streak, max_streak)
	var gift := base + per_day * (streak - 1)
	Aether.save.set_value("daily_streak", streak)
	Aether.save.set_value("daily_last", today)
	await get_tree().create_timer(0.8).timeout
	Aether.add_var(currency, gift)
	Aether.save.set_value("vars", Aether.vars)
	Aether.sfx("win", 0.8)
	Aether.toast(Aether.t("Regalo diario") + ": +%d  ·  %s %d" % [gift, Aether.t("racha"), streak], 3.5)
