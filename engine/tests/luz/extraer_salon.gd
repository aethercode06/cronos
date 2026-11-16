extends SceneTree
## Prueba de luz precalculada (paso 1): construye la mansión, copia el «Salón con chimenea» (geometría, muebles y
## lámparas) a una escena aparte con UV2 para lightmap y un LightmapGI, y la guarda en res://tests/luz/salon.tscn.
const SALA := AABB(Vector3(83.5, -0.6, 83.5), Vector3(13.0, 5.4, 10.6))

func _initialize() -> void:
	var m := ZarekMansion.new()
	root.add_child.call_deferred(m)
	while not m.is_inside_tree():
		await process_frame
	print("SALON en el árbol: ", m.is_inside_tree())
	# como build() pero sin fusionar (cada pared y mueble queda suelto para poder elegir los del salón)
	m.quality = 2
	m._rng.seed = 1874
	m.plan = JSON.parse_string(FileAccess.open(m.PLAN, FileAccess.READ).get_as_text())
	m._materials()
	m.nav_region = NavigationRegion3D.new()
	m.add_child(m.nav_region)
	m._house = Node3D.new()
	m.nav_region.add_child(m._house)
	m._stairs_plan()
	for key in ["sotano", "baja", "alta", "atico"]:
		m._level(key)
	m._build_stairs()
	m._roof()
	m._ornatos_fachada()
	m._markers()
	m._portals()
	m._decorate()
	for l in m.lamps:
		m.set_lamp(l, true)
	await process_frame
	await process_frame
	var escena := Node3D.new()
	escena.name = "Salon"
	var n_mallas := 0
	var n_luces := 0
	for g in m.find_children("*", "MeshInstance3D", true, false):
		var mi := g as MeshInstance3D
		if mi.mesh == null:
			continue
		var ab: AABB = mi.global_transform * mi.get_aabb()
		if not SALA.grow(0.3).has_point(ab.get_center()) or ab.size.length() > 30.0:
			continue
		# piezas enormes (fusiones que cruzan media casa): solo si su centro cae cerca
		var am: ArrayMesh = null
		if mi.mesh is ArrayMesh:
			am = (mi.mesh as ArrayMesh).duplicate(true)
		elif mi.mesh is PrimitiveMesh:
			am = ArrayMesh.new()
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mi.mesh.surface_get_arrays(0))
			am.surface_set_material(0, (mi.mesh as PrimitiveMesh).material)
		if am == null:
			continue
		var nm := MeshInstance3D.new()
		nm.name = "m%d" % n_mallas
		nm.mesh = am
		nm.material_override = mi.material_override
		for si in mi.get_surface_override_material_count():
			nm.set_surface_override_material(si, mi.get_surface_override_material(si))
		nm.transform = mi.global_transform
		var tamano := ab.size.length()
		# lo que se mueve (objetos con física) no entra en el horneado: recibe luz de las sondas
		var movil := false
		var q: Node = mi.get_parent()
		while q and q != m:
			if q is RigidBody3D:
				movil = true
			q = q.get_parent()
		if movil or tamano < 0.25:
			nm.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC
		else:
			nm.gi_mode = GeometryInstance3D.GI_MODE_STATIC
			var texel := clampf(0.08 if tamano > 4.0 else 0.04, 0.02, 0.2)
			var err := am.lightmap_unwrap(Transform3D.IDENTITY, texel)
			if err != OK:
				nm.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC
		nm.cast_shadow = mi.cast_shadow
		escena.add_child(nm)
		nm.owner = escena
		n_mallas += 1
	for g in m.find_children("*", "Light3D", true, false):
		var l := g as Light3D
		if l is DirectionalLight3D or not SALA.grow(2.0).has_point(l.global_position):
			continue
		var nl: Light3D = l.duplicate()
		nl.name = "luz%d" % n_luces
		nl.transform = l.global_transform
		nl.light_bake_mode = Light3D.BAKE_STATIC
		nl.shadow_enabled = true
		nl.visible = true  # las lámparas empiezan encendidas en el juego
		escena.add_child(nl)
		nl.owner = escena
		n_luces += 1
	var lm := LightmapGI.new()
	lm.name = "LightmapGI"
	lm.quality = LightmapGI.BAKE_QUALITY_MEDIUM
	lm.bounces = 3
	lm.interior = true
	lm.environment_mode = LightmapGI.ENVIRONMENT_MODE_CUSTOM_COLOR
	lm.environment_custom_color = Color(0.05, 0.05, 0.07)
	lm.environment_custom_energy = 1.0
	lm.max_texture_size = 4096
	escena.add_child(lm)
	lm.owner = escena
	var ps := PackedScene.new()
	ps.pack(escena)
	var err2 := ResourceSaver.save(ps, "res://tests/luz/salon.scn")
	print("SALON mallas=%d luces=%d guardado=%s" % [n_mallas, n_luces, error_string(err2)])
	quit()
