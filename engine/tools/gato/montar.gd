extends SceneTree
## Monta la malla exportada de Blender (json) sobre la piel del gato original y la guarda como recurso.
## godot --headless --path . --script res://tools/gato/montar.gd -- <malla.json> <salida.res>
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var datos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var ps: PackedScene = load("res://zarek/fauna/gato_real.glb")
	var g: Node3D = ps.instantiate()
	var mi: MeshInstance3D = null
	for n in g.find_children("*", "MeshInstance3D", true, false):
		if (n as MeshInstance3D).skin != null:
			mi = n
	var esq: Skeleton3D = g.find_children("*", "Skeleton3D", true, false)[0]
	var skin := mi.skin
	var por_nombre := {}
	for b in skin.get_bind_count():
		var nombre := skin.get_bind_name(b)
		if nombre == "":
			nombre = esq.get_bone_name(skin.get_bind_bone(b))
		por_nombre[nombre] = b
	var pos := PackedVector3Array(); var nor := PackedVector3Array(); var uv := PackedVector2Array()
	var bon := PackedInt32Array(); var pes := PackedFloat32Array(); var idx := PackedInt32Array()
	var faltan := {}
	for i in (datos.pos as Array).size():
		var p: Array = datos.pos[i]; var n: Array = datos.nor[i]; var u: Array = datos.uv[i]
		pos.append(Vector3(p[0], p[1], p[2])); nor.append(Vector3(n[0], n[1], n[2])); uv.append(Vector2(u[0], u[1]))
		for k in 4:
			var hn: String = datos.huesos[i][k]
			var w: float = datos.pesos[i][k]
			if hn != "" and not por_nombre.has(hn):
				faltan[hn] = true
				w = 0.0
			bon.append(int(por_nombre.get(hn, 0)))
			pes.append(w)
	for t in datos.tris:
		# glTF/Blender van en sentido antihorario; Godot, horario
		idx.append(int(t[0])); idx.append(int(t[2])); idx.append(int(t[1]))
	# Blender deja la malla desplazada respecto al espacio del modelo original: se alinea con la caja original
	# (la de la malla sin editar, guardada en el json la primera vez)
	var caja := AABB(pos[0], Vector3.ZERO)
	for q in pos:
		caja = caja.expand(q)
	var ref: AABB = mi.mesh.get_aabb()
	var desp := Vector3(0, ref.position.y - caja.position.y, 0) if not datos.has("desp") else Vector3(datos.desp[0], datos.desp[1], datos.desp[2])
	if args.size() > 2:
		var d2: Array = JSON.parse_string(args[2])
		desp = Vector3(d2[0], d2[1], d2[2])
	for i in pos.size():
		pos[i] += desp
	print("DESPLAZAMIENTO ", desp)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = pos; arr[Mesh.ARRAY_NORMAL] = nor; arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_BONES] = bon; arr[Mesh.ARRAY_WEIGHTS] = pes; arr[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var st := SurfaceTool.new()
	st.create_from(am, 0)
	st.generate_tangents()
	var am2 := st.commit()
	ResourceSaver.save(am2, args[1])
	print("MONTADO ", pos.size(), " vértices; huesos que faltan: ", faltan.keys(), " ; aabb ", am2.get_aabb(), " original ", mi.mesh.get_aabb())
	quit()
