@tool
@icon("res://addons/aether/icons/aether.svg")
class_name AetherMap
extends Node2D
## Mapa escrito con letras (vista desde arriba): dibuja tu nivel como texto
## y el motor crea paredes, personajes y objetos. Se ve en el editor.
##   #  pared        .  suelo        P  inicio del jugador
##   M  monstruo     S  acechador (terror)    N  personaje para hablar
##   $  moneda       C  cofre (5 gemas)       K  llave     H  corazón (vida)
##   B  pilas (linterna)   E  salida (necesita las llaves)   T  árbol / columna

signal completed

@export_multiline var map := "##########\n#P...$..E#\n#..M.....#\n##########":
	set(v):
		map = v
		queue_redraw()
@export var tile := 64.0:
	set(v):
		tile = v
		queue_redraw()
@export var floor_color := Color(0.22, 0.2, 0.18):
	set(v):
		floor_color = v
		queue_redraw()
@export var wall_color := Color(0.4, 0.36, 0.33):
	set(v):
		wall_color = v
		queue_redraw()
@export var floor_texture: Texture2D
@export var wall_texture: Texture2D
## Llaves necesarias para abrir la salida.
@export var keys_needed := 0
## Escena a la que ir al salir (vacío = mensaje de victoria).
@export_file("*.tscn") var next_scene := ""
## Lo que dicen los personajes N (uno por bloque, separados por una línea «---»).
@export_multiline var npc_lines := "Anciano: Busca las llaves para abrir la salida.\nAnciano: ¡Y cuidado con los monstruos!"
## Modo terror: oscuridad, linterna y sin espada.
@export var horror := false
## Imagen del jugador y de los monstruos (opcional).
@export var player_texture: Texture2D
@export var monster_texture: Texture2D

var _rows: PackedStringArray = []
var _exit_open := false
var _exit_pos := Vector2.ZERO
var _done := false

func _rows_now() -> PackedStringArray:
	return map.split("\n")

func cell_pos(x: int, y: int) -> Vector2:
	return Vector2(x + 0.5, y + 0.5) * tile

func _ready() -> void:
	_rows = _rows_now()
	if Engine.is_editor_hint():
		return
	var npc_i := 0
	var npc_blocks := npc_lines.split("---")
	Aether.set_var("llaves", 0)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	add_child(body)
	for y in _rows.size():
		var row := _rows[y]
		var x := 0
		while x < row.length():
			if row[x] == "#":
				var x0 := x
				while x < row.length() and row[x] == "#":
					x += 1
				var r := Rect2(Vector2(x0, y) * tile, Vector2(x - x0, 1) * tile)
				var cs := CollisionShape2D.new()
				var sh := RectangleShape2D.new()
				sh.size = r.size
				cs.shape = sh
				cs.position = r.get_center()
				body.add_child(cs)
				var occ := LightOccluder2D.new()
				var poly := OccluderPolygon2D.new()
				poly.polygon = PackedVector2Array([r.position, r.position + Vector2(r.size.x, 0), r.end, r.position + Vector2(0, r.size.y)])
				occ.occluder = poly
				add_child(occ)
				continue
			var p := cell_pos(x, y)
			match row[x]:
				"P":
					var pl: Node2D = null
					for n in get_tree().get_nodes_in_group("player"):
						pl = n
					if pl == null:
						var tp := AetherTopDownPlayer.new()
						tp.texture = player_texture
						tp.can_attack = not horror
						pl = tp
						add_child.call_deferred(tp)
						if horror:
							tp.add_child(AetherFlashlight.new())
					pl.position = p
				"T":
					var cs := CollisionShape2D.new()
					var sh := CircleShape2D.new()
					sh.radius = tile * 0.35
					cs.shape = sh
					cs.position = p
					body.add_child(cs)
				"M", "S":
					var m := AetherChaser.new()
					m.mode = "acechador" if row[x] == "S" else "perseguir"
					m.texture = monster_texture
					m.position = p
					add_child(m)
				"N":
					var n := AetherNPC.new()
					n.lines = npc_blocks[npc_i % npc_blocks.size()].strip_edges() if npc_blocks.size() > 0 else ""
					npc_i += 1
					n.position = p
					add_child(n)
				"$", "C", "K", "H", "B":
					var pk := AetherPickup.new()
					pk.position = p
					var c := row[x]
					pk.var_name = {"$": "monedas", "C": "gemas", "K": "llaves", "H": "vida", "B": "pilas"}[c]
					pk.amount = 5.0 if c == "C" else 1.0
					pk.heal = 30.0 if c == "H" else 0.0
					pk.color = {"$": Color(1, 0.8, 0.3), "C": Color(0.5, 0.9, 1), "K": Color(1, 0.95, 0.5), "H": Color(1, 0.35, 0.45), "B": Color(0.5, 1, 0.5)}[c]
					add_child(pk)
				"E":
					_exit_pos = p
			x += 1
	if horror:
		var cm := CanvasModulate.new()
		cm.color = Color(0.04, 0.04, 0.06)
		add_child(cm)

func _process(_d: float) -> void:
	if Engine.is_editor_hint() or _done:
		return
	var open := Aether.get_var("llaves") >= keys_needed
	if open != _exit_open:
		_exit_open = open
		queue_redraw()
		if open and keys_needed > 0:
			Aether.toast(Aether.t("¡La salida está abierta!"))
			Aether.sfx("check", 0.7)
	var pl = Aether.player
	if _exit_pos != Vector2.ZERO and _exit_open and pl is Node2D and (pl as Node2D).global_position.distance_to(to_global(_exit_pos)) < tile * 0.6:
		_done = true
		completed.emit()
		Aether.sfx("win", 0.9)
		Aether.flash(Color(1, 1, 0.8), 0.5)
		for h in get_tree().get_nodes_in_group("aether_hud"):
			h.banner(Aether.t("¡FASE SUPERADA!"))
		Aether.toast(Aether.t("¡FASE SUPERADA!"))
		if next_scene != "":
			await get_tree().create_timer(2.0).timeout
			get_tree().change_scene_to_file(next_scene)

func _draw() -> void:
	var rows := _rows_now()
	for y in rows.size():
		var row := rows[y]
		for x in row.length():
			var r := Rect2(Vector2(x, y) * tile, Vector2(tile, tile))
			var ch := row[x]
			if ch == " ":
				continue
			if ch == "#":
				if wall_texture:
					draw_texture_rect(wall_texture, r, false)
				else:
					draw_rect(r, wall_color)
					draw_rect(Rect2(r.position, Vector2(tile, tile * 0.18)), wall_color.lightened(0.18))
				continue
			if floor_texture:
				draw_texture_rect(floor_texture, r, false)
			else:
				draw_rect(r, floor_color if (x + y) % 2 == 0 else floor_color.darkened(0.06))
			var c := r.get_center()
			match ch:
				"T":
					draw_circle(c + Vector2(0, 10), tile * 0.32, Color(0, 0, 0, 0.3))
					draw_circle(c, tile * 0.42, Color(0.18, 0.45, 0.22))
					draw_circle(c + Vector2(-8, -8), tile * 0.22, Color(0.25, 0.58, 0.3))
				"E":
					var col: Color = Color(0.4, 1.0, 0.6) if (_exit_open or keys_needed == 0) else Color(0.6, 0.3, 0.3)
					draw_rect(r.grow(-6), col.darkened(0.5))
					draw_rect(r.grow(-6), col, false, 4)
			if Engine.is_editor_hint() and ch in "PMSN$CKHB":
				draw_string(ThemeDB.fallback_font, c + Vector2(-10, 10), ch, HORIZONTAL_ALIGNMENT_CENTER, 20, 28, Color(1, 1, 1))
