class_name DeformSprite
extends MeshInstance2D
## Convierte un dibujo de una sola pose en una malla deformable
## (como los «meshes» de Spine). Los pies quedan en el origen.

const SHADER := preload("res://addons/aether/fx/deform.gdshader")

@export var cols := 18
@export var rows := 18

var mat: ShaderMaterial
var draw_size := Vector2.ONE

func setup(tex: Texture2D, world_scale: float, foot_frac := 1.0) -> void:
	texture = tex
	draw_size = Vector2(tex.get_width(), tex.get_height()) * world_scale
	var verts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	for j in rows + 1:
		for i in cols + 1:
			var u := float(i) / cols
			var v := float(j) / rows
			verts.append(Vector2((u - 0.5) * draw_size.x, (v - foot_frac) * draw_size.y))
			uvs.append(Vector2(u, v))
	for j in rows:
		for i in cols:
			var a := j * (cols + 1) + i
			var b := a + 1
			var c := a + cols + 1
			var d := c + 1
			idx.append_array([a, b, c, b, d, c])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_TEX_UV] = uvs
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	mesh = m
	mat = ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("size", draw_size)
	material = mat

func set_p(name: String, v) -> void:
	if mat:
		mat.set_shader_parameter(name, v)
