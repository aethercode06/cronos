@tool
@icon("res://addons/aether/icons/ui.svg")
class_name AetherGround
extends StaticBody2D
## Suelo o plataforma listo para usar: arrástralo a la escena, cambia el tamaño
## en el Inspector y se dibuja con la textura que elijas (también en el editor).

## Ancho y alto del bloque. La parte de arriba es donde se pisa.
@export var size := Vector2(800, 300):
	set(v):
		size = v
		_rebuild()
## Textura de relleno (se repite).
@export var fill_texture: Texture2D:
	set(v):
		fill_texture = v
		_rebuild()
## Textura del borde superior (hierba, piedra…), opcional.
@export var edge_texture: Texture2D:
	set(v):
		edge_texture = v
		_rebuild()
## Escala de las texturas.
@export_range(0.1, 4.0) var texture_scale := 0.667:
	set(v):
		texture_scale = v
		_rebuild()
## Plataforma que se atraviesa desde abajo.
@export var one_way := false:
	set(v):
		one_way = v
		_rebuild()
## Color si no hay textura.
@export var color := Color(0.25, 0.35, 0.2):
	set(v):
		color = v
		_rebuild()

func _ready() -> void:
	collision_layer = 1
	_rebuild()

func _rebuild() -> void:
	if not is_inside_tree():
		return
	for c in get_children():
		if c.has_meta("aether_ground"):
			c.free()
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(size.x, 24 if one_way else size.y)
	cs.shape = r
	cs.position = Vector2(size.x * 0.5, (12 if one_way else size.y * 0.5))
	cs.one_way_collision = one_way
	cs.set_meta("aether_ground", true)
	add_child(cs)
	var poly := Polygon2D.new()
	poly.set_meta("aether_ground", true)
	var pts := PackedVector2Array([Vector2(0, 8), Vector2(size.x, 8), Vector2(size.x, size.y), Vector2(0, size.y)])
	poly.polygon = pts
	if fill_texture:
		poly.texture = fill_texture
		poly.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		var uv := PackedVector2Array()
		for p in pts:
			uv.append(p / texture_scale)
		poly.uv = uv
	else:
		poly.color = color
	poly.z_index = -2
	add_child(poly)
	var shade := Polygon2D.new()
	shade.set_meta("aether_ground", true)
	shade.polygon = pts
	shade.vertex_colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.7), Color(0, 0, 0, 0.7)])
	shade.z_index = -2
	add_child(shade)
	if edge_texture:
		var h := edge_texture.get_height() * texture_scale
		var e := Polygon2D.new()
		e.set_meta("aether_ground", true)
		e.texture = edge_texture
		e.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		var ep := PackedVector2Array([Vector2(-8, -h * 0.2), Vector2(size.x + 8, -h * 0.2), Vector2(size.x + 8, h * 0.8), Vector2(-8, h * 0.8)])
		e.polygon = ep
		var euv := PackedVector2Array()
		for p in ep:
			euv.append(Vector2(p.x + 8, p.y + h * 0.2) / texture_scale)
		e.uv = euv
		e.z_index = -1
		add_child(e)
