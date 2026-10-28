class_name AetherLogicRunner
extends RefCounted
## Ejecuta los eventos sin código. Lo usan AetherLogic y AetherZone.

var host: Node                  # nodo dueño (para crear cosas «aquí» y resolver rutas)
var events: Array = []
var _done := {}                 # eventos «solo una vez» ya ejecutados
var _timers := {}               # evento → tiempo acumulado
var _t := 0.0
var _var_reached := {}
var _links := []

func _init(p_host: Node, p_events: Array) -> void:
	host = p_host
	events = p_events
	_link(Aether.enemy_killed, func(): fire("enemigo"))
	_link(Aether.boss_defeated, func(): fire("jefe"))
	_link(Aether.player_died, func(): fire("cae"))
	_link(Aether.picked, func(v): fire("recoge", {"var": v}))
	_link(Aether.var_changed, _on_var)

func _link(sig: Signal, f: Callable) -> void:
	sig.connect(f)
	_links.append([sig, f])

## Desconecta todo (al salir de la escena).
func dispose() -> void:
	for l in _links:
		if l[0].is_connected(l[1]):
			l[0].disconnect(l[1])
	_links.clear()

func start() -> void:
	fire("inicio")

## Llamar cada fotograma (tiempo e entradas).
func tick(delta: float) -> void:
	_t += delta
	for ev in events:
		if ev == null or not ev.enabled:
			continue
		match ev.trigger:
			"cada":
				var every: float = max(0.05, float(ev.trigger_params.get("seg", 1.0)))
				_timers[ev] = float(_timers.get(ev, 0.0)) + delta
				if _timers[ev] >= every:
					_timers[ev] = 0.0
					run(ev)
			"tras":
				if not _timers.has(ev) and _t >= float(ev.trigger_params.get("seg", 3.0)):
					_timers[ev] = true
					run(ev)
			"accion":
				if Input.is_action_just_pressed(String(ev.trigger_params.get("accion", "jump"))):
					run(ev)

func _on_var(n: String, v: float) -> void:
	for ev in events:
		if ev and ev.enabled and ev.trigger == "variable" and String(ev.trigger_params.get("var", "")) == n:
			var goal := float(ev.trigger_params.get("valor", 0.0))
			var key := str(ev.get_instance_id())
			if v >= goal and not _var_reached.get(key, false):
				_var_reached[key] = true
				run(ev)
			elif v < goal:
				_var_reached[key] = false

## Lanza todos los eventos con este disparador.
func fire(trigger: String, match_params := {}) -> void:
	for ev in events:
		if ev == null or not ev.enabled or ev.trigger != trigger:
			continue
		var ok := true
		for k in match_params:
			if str(ev.trigger_params.get(k, "")) != str(match_params[k]):
				ok = false
		if ok:
			run(ev)

func check(c: AetherStep) -> bool:
	var p := c.params
	var pl = Aether.player
	match c.kind:
		"var_cmp":
			var a := Aether.get_var(String(p.get("var", "")))
			var b := float(p.get("valor", 0.0))
			match String(p.get("op", ">=")):
				"=": return is_equal_approx(a, b)
				"!=": return not is_equal_approx(a, b)
				">": return a > b
				"<": return a < b
				">=": return a >= b
				"<=": return a <= b
		"azar":
			return randf() * 100.0 < float(p.get("pct", 50.0))
		"vida":
			return pl != null and float(pl.get("hp")) < float(p.get("valor", 50.0))
		"suelo":
			return pl != null and pl.has_method("is_on_floor") and pl.is_on_floor()
		"logro":
			return Aether.achievements.is_unlocked(String(p.get("id", "")))
		"no_logro":
			return not Aether.achievements.is_unlocked(String(p.get("id", "")))
		"tiene":
			return Aether.inventory.has(String(p.get("objeto", "")), int(p.get("cantidad", 1)))
		"no_tiene":
			return not Aether.inventory.has(String(p.get("objeto", "")))
	return true

func run(ev: AetherEvent) -> void:
	if ev.once and _done.has(ev):
		return
	for c in ev.conditions:
		if c and not check(c):
			return
	_done[ev] = true
	for a in ev.actions:
		if a == null:
			continue
		if a.kind == "esperar":
			await Aether.get_tree().create_timer(float(a.params.get("seg", 1.0)), false).timeout
			if not is_instance_valid(host):
				return
			continue
		do_action(a)

func _node(path: String) -> Node:
	if path == "" or not is_instance_valid(host):
		return null
	var n := host.get_node_or_null(NodePath(path))
	if n == null and host.get_tree().current_scene:
		n = host.get_tree().current_scene.get_node_or_null(NodePath(path))
	return n

func do_action(a: AetherStep) -> void:
	var p := a.params
	var pl = Aether.player
	match a.kind:
		"sumar": Aether.add_var(String(p.get("var", "")), float(p.get("cantidad", 1.0)))
		"poner": Aether.set_var(String(p.get("var", "")), float(p.get("valor", 0.0)))
		"aviso": Aether.toast(Aether.t(String(p.get("texto", ""))))
		"cartel":
			var hud := host.get_tree().get_first_node_in_group("aether_hud")
			if hud:
				hud.banner(Aether.t(String(p.get("texto", ""))), "", 2.4)
			else:
				Aether.toast(Aether.t(String(p.get("texto", ""))), 3.0)
		"sonido": Aether.sfx(String(p.get("sonido", "gem")))
		"musica": Aether.music(String(p.get("musica", "")))
		"curar":
			if pl and pl.has_method("heal"):
				pl.heal(float(p.get("cantidad", 20.0)))
		"danar":
			if pl and pl.has_method("take_damage"):
				pl.take_damage(float(p.get("cantidad", 10.0)), host.global_position.x if host is Node2D else pl.global_position.x)
		"crear":
			var path := String(p.get("escena", ""))
			if path != "" and ResourceLoader.exists(path):
				var inst: Node = load(path).instantiate()
				host.get_parent().add_child(inst)
				if inst is Node2D and host is Node2D:
					inst.global_position = host.global_position
				elif inst is Node3D and host is Node3D:
					inst.global_position = host.global_position
		"eliminar":
			var n := _node(String(p.get("nodo", "")))
			if n == null and String(p.get("nodo", "")) == "":
				n = host
			if n:
				n.queue_free()
		"mostrar":
			var n2 := _node(String(p.get("nodo", "")))
			if n2 and "visible" in n2:
				n2.visible = not n2.visible
		"llevar":
			var dest := _node(String(p.get("nodo", "")))
			if dest and pl:
				pl.global_position = dest.global_position
				if Aether.camera and Aether.camera.has_method("snap"):
					Aether.camera.snap()
		"control":
			if pl and "checkpoint" in pl:
				pl.checkpoint = pl.global_position
				Aether.toast(Aether.t("PUNTO DE CONTROL"))
		"escena":
			var sp := String(p.get("escena", ""))
			if sp != "":
				host.get_tree().change_scene_to_file.call_deferred(sp)
		"temblor": Aether.shake(float(p.get("fuerza", 12.0)), 0.03)
		"destello": Aether.flash(Color.from_string(String(p.get("color", "#ffffff")), Color.WHITE), 0.5)
		"lenta": Aether.slowmo(0.3, float(p.get("seg", 1.0)))
		"logro": Aether.achievements.unlock(String(p.get("id", "")))
		"guardar":
			Aether.save.set_value("vars", Aether.vars)
			Aether.toast(Aether.t("Partida guardada"))
		"dialogo":
			var dn := _node(String(p.get("nodo", "")))
			if dn and dn.has_method("play"):
				dn.play()
		"efecto":
			var en := _node(String(p.get("nodo", "")))
			if en and en.has_method("play"):
				en.play()
		"tienda":
			var tn := _node(String(p.get("nodo", "")))
			if tn and tn.has_method("open"):
				tn.open()
		"dar": Aether.inventory.give(String(p.get("objeto", "")), int(p.get("cantidad", 1)))
		"quitar": Aether.inventory.take(String(p.get("objeto", "")), int(p.get("cantidad", 1)))
		"ganar":
			var hud2 := host.get_tree().get_first_node_in_group("aether_hud")
			if hud2:
				hud2.banner(Aether.t("¡FASE SUPERADA!"), "", 2.5)
			Aether.sfx("win", 1.0)
			Aether.flash(Color(1, 0.95, 0.7), 0.5)
			FX.burst(host.get_parent(), host.global_position if host is Node2D else Vector2.ZERO, Color(2.6, 2.2, 1.0), 60, 700, 1.0, 14, 300)
			Aether.save.set_value("vars", Aether.vars)
			var next := String(p.get("escena", ""))
			if next != "":
				await host.get_tree().create_timer(2.6, true, false, true).timeout
				host.get_tree().change_scene_to_file(next)
		"anuncio":
			var vn := String(p.get("var", "monedas"))
			var amt := float(p.get("cantidad", 50.0))
			Aether.store.show_rewarded(func(ok):
				if ok:
					Aether.add_var(vn, amt))
