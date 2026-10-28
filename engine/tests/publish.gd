extends Node
## Prueba del asistente de publicación: ficha, privacidad, archivo de GitHub,
## ajuste AAB y comprobaciones.

func _ready() -> void:
	var P = load("res://addons/aether/editor/publish_panel.gd")
	var ok := true
	ok = ok and P.valid_package("com.aethercode.mijuego") and not P.valid_package("Com Mal")
	print("AETHER: ", P.make_listing("Juego de prueba", "Corto", "Largo", "a@b.c", true, true))
	print("AETHER: ", P.make_github())
	ok = ok and FileAccess.file_exists("res://publicar/privacidad.html") and FileAccess.file_exists("res://publicar/google_play.yml")
	ok = ok and P.prepare_aab()
	for c in P.checks():
		print("AETHER: comprobación ", "✔ " if c[1] else "✖ ", c[0])
	print("AETHER: idiomas = ", Aether.lang.available())
	Aether.lang.set_lang("fr")
	print("AETHER: frances = ", Aether.t("JUGAR"))
	ok = ok and Aether.t("JUGAR") == "JOUER"
	if ok:
		print("AETHER: PUBLICAR OK")
	get_tree().quit(0)
