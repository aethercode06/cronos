class_name AetherLang
extends RefCounted
## Idiomas: textos en res://idiomas/<código>.json  ({"JUGAR": "PLAY", …}).
## El texto original (español) es la clave. Aether.t("JUGAR") devuelve la traducción.
## Detecta el idioma del teléfono; se puede cambiar con Aether.lang.set_lang("en").

signal changed(code: String)

var code := "es"
var table := {}

func setup() -> void:
	var sys := OS.get_locale_language()
	set_lang(sys if available().has(sys) else "es")

func available() -> PackedStringArray:
	var out := PackedStringArray(["es"])
	var d := DirAccess.open("res://idiomas")
	if d:
		for f in d.get_files():
			if f.ends_with(".json"):
				var c := f.get_basename()
				if not out.has(c):
					out.append(c)
	return out

func set_lang(c: String) -> void:
	code = c
	table = {}
	var p := "res://idiomas/%s.json" % c
	if c != "es" and FileAccess.file_exists(p):
		var d = JSON.parse_string(FileAccess.open(p, FileAccess.READ).get_as_text())
		if d is Dictionary:
			table = d
	changed.emit(c)

func t(text: String) -> String:
	return table.get(text, text)
