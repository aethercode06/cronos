class_name AetherAchievements
extends RefCounted
## Logros: Aether.achievements.define("primer_jefe", "Rompeguardianes", "Vence a tu primer jefe")
## y luego Aether.achievements.unlock("primer_jefe"). Muestra un aviso y lo guarda.

signal unlocked(id: String, title: String)

var defs := {}

func define(id: String, title: String, desc := "") -> void:
	defs[id] = {"title": title, "desc": desc}

func is_unlocked(id: String) -> bool:
	var got: Dictionary = Aether.save.get_value("logros", {})
	return got.has(id)

func unlock(id: String) -> void:
	if is_unlocked(id):
		return
	var got: Dictionary = Aether.save.get_value("logros", {})
	got[id] = Time.get_unix_time_from_system()
	Aether.save.set_value("logros", got)
	var title: String = defs.get(id, {}).get("title", id)
	unlocked.emit(id, title)
	Aether.toast(Aether.t("LOGRO") + ": " + Aether.t(title))
	Aether.sfx("win", 0.6, 1.3)

func progress() -> Vector2i:
	var got: Dictionary = Aether.save.get_value("logros", {})
	return Vector2i(got.size(), defs.size())
