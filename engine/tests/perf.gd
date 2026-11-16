extends Node3D
## Revisión de rendimiento de Zarek: tiempos de carga por paso, contenido de la escena y coste de dibujo por vista.
## godot --path . res://tests/perf.tscn   (Q=1 calidad del teléfono)
var m: ZarekMansion
func _t(nombre: String, c: Callable) -> void:
	var t0 := Time.get_ticks_msec()
	c.call()
	print("CARGA %-22s %6d ms" % [nombre, Time.get_ticks_msec() - t0])

func _ready() -> void:
	var q := int(OS.get_environment("Q")) if OS.get_environment("Q") != "" else 1
	var t_all := Time.get_ticks_msec()
	m = ZarekMansion.new(); add_child(m)
	m.quality = q; m._rng.seed = 1874
	m.plan = JSON.parse_string(FileAccess.open(m.PLAN, FileAccess.READ).get_as_text())
	_t("materiales", m._materials)
	m.nav_region = NavigationRegion3D.new(); m.add_child(m.nav_region)
	m._house = Node3D.new(); m.nav_region.add_child(m._house)
	_t("escaleras_plan", m._stairs_plan)
	for key in ["sotano", "baja", "alta", "atico"]:
		_t("nivel " + key, m._level.bind(key))
	_t("escaleras", m._build_stairs)
	_t("tejado", m._roof)
	_t("ornatos", m._ornatos_fachada)
	_t("abandono", m._abandono_exterior)
	_t("exterior", m._exterior)
	_t("marcas", m._markers)
	_t("portales", m._portals)
	_t("decorado", m._decorate)
	_t("fusionar", m._merge_static)
	_t("optimizar", m._optimizar)
	_t("navegacion", m.bake_nav)
	if OS.get_environment("IMP") != "":
		await m.crear_impostores()
	print("CARGA TOTAL %d ms" % (Time.get_ticks_msec() - t_all))
	# contenido
	var cuenta := {"nodos": 0, "mesh": 0, "multimesh": 0, "inst_mm": 0, "luces": 0, "luces_sombra": 0, "cuerpos": 0, "rigid": 0, "particulas": 0, "audio": 0, "tris_mesh": 0, "tris_mm": 0}
	var mats := {}
	var texs := {}
	var por := {}
	var pila: Array = [m]
	while not pila.is_empty():
		var n: Node = pila.pop_back()
		cuenta.nodos += 1
		pila.append_array(n.get_children())
		if n is MeshInstance3D and n.mesh:
			cuenta.mesh += 1
			var clave := n.owner.scene_file_path.get_file() if n.owner and n.owner.scene_file_path != "" else ("gen:" + String(n.get_parent().name).left(14))
			por[clave] = por.get(clave, 0) + _tris(n.mesh)
			cuenta.tris_mesh += _tris(n.mesh)
			for s in n.mesh.get_surface_count():
				var mt = n.get_active_material(s)
				if mt: mats[mt] = 1
		elif n is MultiMeshInstance3D and n.multimesh and n.multimesh.mesh:
			cuenta.multimesh += 1
			cuenta.inst_mm += n.multimesh.instance_count
			cuenta.tris_mm += _tris(n.multimesh.mesh) * n.multimesh.instance_count
			var mk := "MM:%s/%s (%d tris) x" % [String(n.get_parent().name).left(12), n.multimesh.mesh.resource_name.left(24), _tris(n.multimesh.mesh)]
			por[mk] = por.get(mk, 0) + _tris(n.multimesh.mesh) * n.multimesh.instance_count
		elif n is Light3D:
			cuenta.luces += 1
			if n.shadow_enabled: cuenta.luces_sombra += 1
		elif n is RigidBody3D: cuenta.rigid += 1
		elif n is CollisionObject3D: cuenta.cuerpos += 1
		elif n is GPUParticles3D or n is CPUParticles3D: cuenta.particulas += 1
		elif n is AudioStreamPlayer3D: cuenta.audio += 1
	var px := 0
	for mt in mats:
		if mt is BaseMaterial3D:
			for p in ["albedo_texture", "normal_texture", "roughness_texture", "ao_texture", "heightmap_texture"]:
				var t = mt.get(p)
				if t: texs[t] = 1
		elif mt is ShaderMaterial:
			for u in mt.shader.get_shader_uniform_list():
				var t = mt.get_shader_parameter(u.name)
				if t is Texture2D: texs[t] = 1
	var img_tex := 0
	for t in texs:
		px += t.get_width() * t.get_height()
		if t is ImageTexture: img_tex += 1
	print("ESCENA ", cuenta)
	var ks := por.keys()
	ks.sort_custom(func(a, b): return por[a] > por[b])
	for k in ks.slice(0, 40):
		print("TRIS %-50s %d" % [k, por[k]])
	if OS.get_environment("SOLO_ESCENA") != "":
		get_tree().quit()
		return
	print("ESCENA materiales=%d texturas=%d (generadas_en_codigo=%d) megapixeles=%.1f" % [mats.size(), texs.size(), img_tex, px / 1e6])
	# vistas
	var cam := Camera3D.new(); cam.far = 60.0; cam.fov = 70.0; add_child(cam)
	if OS.get_environment("CULL") != "": cam.cull_mask = int(OS.get_environment("CULL"))
	var fl := SpotLight3D.new(); fl.spot_range = 32.0; fl.spot_angle = 40.0; fl.light_energy = 6.0; fl.shadow_enabled = OS.get_environment("SINSOMBRA") == ""; cam.add_child(fl)
	var moon := DirectionalLight3D.new(); moon.shadow_enabled = OS.get_environment("SINSOMBRA") == "" and OS.get_environment("SINLUNA") == ""; moon.directional_shadow_max_distance = 32.0; moon.rotation_degrees = Vector3(-38, -55, 0); moon.shadow_caster_mask = 0xFFFFF & ~2; moon.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS; add_child(moon)
	get_viewport().use_occlusion_culling = OS.get_environment("SINOCL") == ""
	print("OCLUSION ", get_viewport().use_occlusion_culling)
	var hr: Rect2 = m.house_rect
	var vistas := {"inicio": [m.start_pos + Vector3(0, 1.6, 0), m.start_pos + Vector3(0, 1.6, -5)],
		"fachada": [Vector3(hr.get_center().x, 1.7, hr.end.y + 20.0), Vector3(hr.get_center().x, 4, hr.end.y)],
		"bosque": [m.cell_to_world("exterior", 20.0, 80.0) + Vector3(0, 1.7, 0), m.cell_to_world("exterior", 40.0, 80.0) + Vector3(0, 1.5, 0)],
		"salon": [m.cell_to_world("baja", 9.0, 11.2) + Vector3(0, 1.6, 0), m.cell_to_world("baja", 14.0, 11.2) + Vector3(0, 1.6, 0)]}
	for k in vistas:
		cam.look_at_from_position(vistas[k][0], vistas[k][1])
		fl.shadow_caster_mask = (0xFFFFF & ~4) if k == "salon" else (0xFFFFF & ~2)
		for i in 6:
			await get_tree().process_frame
		var t0 := Time.get_ticks_usec()
		for i in 5:
			await get_tree().process_frame
		print("VISTA %-8s draw_calls=%d objetos=%d primitivas=%d  ms/frame(software)=%.0f" % [k,
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), (Time.get_ticks_usec() - t0) / 5000.0])
	if OS.get_environment("DESGLOSE") != "":
		var vv: String = OS.get_environment("DESGLOSE")
		cam.look_at_from_position(vistas[vv][0], vistas[vv][1])
		var fr := cam.get_frustum()
		var grupos := {}
		var porobj := {}
		for g in m.find_children("*", "GeometryInstance3D", true, false):
			var gi := g as GeometryInstance3D
			if not gi.is_visible_in_tree(): continue
			var ab: AABB = gi.global_transform * gi.get_aabb()
			var d := ab.get_center().distance_to(cam.global_position)
			if gi.visibility_range_end > 0.0 and d > gi.visibility_range_end + ab.size.length() * 0.5: continue
			if gi.visibility_range_begin > 0.0 and d < gi.visibility_range_begin - ab.size.length() * 0.5: continue
			if d > 60.0: continue
			var dentro := true
			for pl in fr:
				if pl.distance_to(ab.get_center()) > ab.size.length() * 0.5: dentro = false
			if not dentro: continue
			var k := ""
			if gi.owner and gi.owner.scene_file_path != "": k = gi.owner.scene_file_path.get_file()
			else:
				var mm = gi.get("mesh")
				k = "%s:%s<%s dyn=%s r=%d" % [gi.get_class(), (mm.get_class() if mm else "-"), String(gi.get_parent().name).left(18), m._is_dyn(gi), int(gi.visibility_range_end)]
			var tri := 0
			if gi is MultiMeshInstance3D and gi.multimesh and gi.multimesh.mesh:
				tri = _tris(gi.multimesh.mesh) * gi.multimesh.instance_count
				k = "MM " + gi.multimesh.mesh.resource_name.left(30) + " %d" % _tris(gi.multimesh.mesh)
			elif gi is MeshInstance3D and gi.mesh:
				tri = _tris(gi.mesh)
			grupos[k] = grupos.get(k, 0) + tri
			porobj[k] = porobj.get(k, 0) + 1
		var kg := grupos.keys()
		kg.sort_custom(func(a, b): return grupos[a] > grupos[b])
		for k in kg.slice(0, 30): print("DES %-60s %d" % [k, grupos[k]])
		var kc := porobj.keys()
		kc.sort_custom(func(a, b): return porobj[a] > porobj[b])
		for k in kc.slice(0, 30): print("CUENTA %-60s %d" % [k, porobj[k]])
	if OS.get_environment("CAPA1") != "":
		var gr := {}
		for g in m.find_children("*", "GeometryInstance3D", true, false):
			var gi := g as GeometryInstance3D
			if gi.layers != 1 or not gi.is_visible_in_tree(): continue
			var par := gi.get_parent()
			var mm = gi.get("mesh")
			var k := "%s:%s par=%s(%s) dyn=%s r=%d" % [gi.get_class(), (mm.get_class() if mm else "-"), par.get_class(), String(par.name).left(16), m._is_dyn(gi), int(gi.visibility_range_end)]
			gr[k] = gr.get(k, 0) + 1
		var kg2 := gr.keys()
		kg2.sort_custom(func(a, b): return gr[a] > gr[b])
		for k in kg2.slice(0, 6): print("CAPA1 %-80s %d" % [k, gr[k]])
		for g in m.find_children("*", "MeshInstance3D", true, false):
			if g.get_parent() is RigidBody3D and g.layers == 1:
				var rbx: Node = g.get_parent()
				print("RB2 ", g.get_path(), " script=", rbx.get_script(), " hijos=", rbx.get_child_count(), " owner=", g.owner, " aabb=", g.mesh.get_aabb().size, " mat=", g.get_active_material(0))
				break
		for rb in m.find_children("*", "RigidBody3D", true, false):
			if rb.get_child_count() > 10:
				print("RB ", rb.get_script().resource_path if rb.get_script() else "-", " ", rb.global_position, " hijos=", rb.get_child_count(), " ", rb.get_child(0).name, " ", rb.get_child(1).name, " ", (rb.get_child(1) as MeshInstance3D).mesh.get_aabb().size if rb.get_child(1) is MeshInstance3D else "")
				break
	print("MEMORIA estatica=%.0f MB  video=%.0f MB  texturas=%.0f MB" % [Performance.get_monitor(Performance.MEMORY_STATIC) / 1e6,
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1e6, Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1e6])
	print("PERF FIN")
	get_tree().quit()

func _tris(mesh: Mesh) -> int:
	var n := 0
	for s in mesh.get_surface_count():
		var a := mesh.surface_get_arrays(s)
		if a[Mesh.ARRAY_INDEX] != null: n += (a[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
		else: n += (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return n
