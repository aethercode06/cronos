@tool
extends VBoxContainer
## Panel «Eventos»: crea la lógica del juego sin escribir código.
## Selecciona un nodo «Lógica» o «Zona» y añade eventos:
## CUANDO (disparador) · SI (condiciones) · HACER (acciones).

var target: Node
var list: VBoxContainer
var title: Label
var hint: Label

func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	title = Label.new()
	title.text = "EVENTOS"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.4, 0.88, 1.0))
	add_child(title)
	hint = Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.text = "Selecciona un nodo «Lógica» o «Zona» (o añádelo desde el panel Aether) para crear eventos sin programar."
	add_child(hint)
	var add := Button.new()
	add.text = "+ Nuevo evento"
	add.custom_minimum_size.y = 44
	add.pressed.connect(_add_event)
	add_child(add)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.custom_minimum_size.y = 300
	add_child(sc)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	EditorInterface.get_selection().selection_changed.connect(_on_sel)
	_on_sel()

func _on_sel() -> void:
	var sel := EditorInterface.get_selection().get_selected_nodes()
	target = null
	for n in sel:
		if n is AetherLogic or n is AetherZone:
			target = n
			break
	_rebuild()

func _events() -> Array:
	return target.events if target else []

func _changed() -> void:
	if target:
		target.notify_property_list_changed()
	EditorInterface.mark_scene_as_unsaved()

func _add_event() -> void:
	if target == null:
		return
	var ev := AetherEvent.new()
	ev.trigger = "entra" if target is AetherZone else "inicio"
	ev.trigger_params = AetherLogicSchema.defaults("trigger", ev.trigger)
	var arr: Array[AetherEvent] = target.events.duplicate()
	arr.append(ev)
	target.events = arr
	_changed()
	_rebuild()

func _rebuild() -> void:
	for c in list.get_children():
		c.queue_free()
	hint.visible = target == null
	if target == null:
		title.text = "EVENTOS"
		return
	title.text = "EVENTOS · " + target.name
	var i := 0
	for ev in _events():
		if ev:
			list.add_child(_event_box(ev, i))
		i += 1

func _event_box(ev: AetherEvent, idx: int) -> Control:
	var pc := PanelContainer.new()
	var v := VBoxContainer.new()
	pc.add_child(v)
	# CUANDO
	v.add_child(_section("CUANDO", Color(0.4, 0.9, 1.0)))
	var on_trigger := func(id: String) -> void:
		ev.trigger = id
		ev.trigger_params = AetherLogicSchema.defaults("trigger", id)
		_changed()
		_rebuild()
	v.add_child(_step_editor("trigger", ev.trigger, ev.trigger_params, on_trigger, Callable()))
	# SI
	for c in ev.conditions:
		v.add_child(_section("SI", Color(1.0, 0.85, 0.4)))
		v.add_child(_step_editor("condition", c.kind, c.params, _kind_setter(c, "condition"), _remover(ev.conditions, c)))
	# HACER
	for a in ev.actions:
		v.add_child(_section("HACER", Color(0.5, 1.0, 0.6)))
		v.add_child(_step_editor("action", a.kind, a.params, _kind_setter(a, "action"), _remover(ev.actions, a)))
	var row := HBoxContainer.new()
	var b1 := Button.new()
	b1.text = "+ SI"
	b1.pressed.connect(_adder(ev.conditions, "condition", "var_cmp"))
	row.add_child(b1)
	var b2 := Button.new()
	b2.text = "+ HACER"
	b2.pressed.connect(_adder(ev.actions, "action", "aviso"))
	row.add_child(b2)
	var once := CheckBox.new()
	once.text = "Una vez"
	once.button_pressed = ev.once
	once.toggled.connect(_once_setter(ev))
	row.add_child(once)
	var del := Button.new()
	del.text = "Borrar"
	del.tooltip_text = "Eliminar evento"
	del.pressed.connect(_event_remover(idx))
	row.add_child(del)
	v.add_child(row)
	v.add_child(HSeparator.new())
	return pc

func _kind_setter(step: AetherStep, kind: String) -> Callable:
	return func(id: String) -> void:
		step.kind = id
		step.params = AetherLogicSchema.defaults(kind, id)
		_changed()
		_rebuild()

func _remover(arr: Array, step: AetherStep) -> Callable:
	return func() -> void:
		arr.erase(step)
		_changed()
		_rebuild()

func _adder(arr: Array, kind: String, id: String) -> Callable:
	return func() -> void:
		arr.append(AetherStep.make(id, AetherLogicSchema.defaults(kind, id)))
		_changed()
		_rebuild()

func _once_setter(ev: AetherEvent) -> Callable:
	return func(on: bool) -> void:
		ev.once = on
		_changed()

func _event_remover(idx: int) -> Callable:
	return func() -> void:
		var arr: Array[AetherEvent] = target.events.duplicate()
		arr.remove_at(idx)
		target.events = arr
		_changed()
		_rebuild()

func _section(t: String, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_size_override("font_size", 13)
	return l

## Selector del bloque + sus valores.
func _step_editor(kind: String, id: String, params: Dictionary, on_kind: Callable, on_delete: Callable) -> Control:
	var v := VBoxContainer.new()
	var row := HBoxContainer.new()
	var ob := OptionButton.new()
	ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var keys := AetherLogicSchema.table(kind).keys()
	for k in keys:
		ob.add_item(AetherLogicSchema.describe(kind, k, AetherLogicSchema.defaults(kind, k)))
		if k == id:
			ob.select(ob.item_count - 1)
	ob.item_selected.connect(func(i): on_kind.call(keys[i]))
	row.add_child(ob)
	if on_delete.is_valid():
		var d := Button.new()
		d.text = "✕"
		d.pressed.connect(on_delete)
		row.add_child(d)
	v.add_child(row)
	for p in AetherLogicSchema.table(kind).get(id, {}).get("params", []):
		v.add_child(_param_editor(p, params))
	return v

func _param_setter(params: Dictionary, name: String) -> Callable:
	return func(val) -> void:
		params[name] = val
		_changed()

func _param_editor(p: Array, params: Dictionary) -> Control:
	var row := HBoxContainer.new()
	var l := Label.new()
	l.text = "   " + String(p[0]) + ":"
	l.custom_minimum_size.x = 90
	row.add_child(l)
	var name: String = p[0]
	var cur = params.get(name, p[2])
	var set_v := _param_setter(params, name)
	match String(p[1]):
		"number":
			var sb := SpinBox.new()
			sb.allow_greater = true
			sb.allow_lesser = true
			sb.step = 0.1
			sb.value = float(cur)
			sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sb.value_changed.connect(func(val): set_v.call(val))
			row.add_child(sb)
		"op", "action", "sound", "music":
			var opts: Array = {"op": AetherLogicSchema.OPS, "action": AetherLogicSchema.ACTIONS_INPUT, "sound": AetherLogicSchema.SOUNDS, "music": AetherLogicSchema.MUSIC}[String(p[1])]
			var ob := OptionButton.new()
			for o in opts:
				ob.add_item(o if o != "" else "(silencio)")
				if o == cur:
					ob.select(ob.item_count - 1)
			ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ob.item_selected.connect(func(i): set_v.call(opts[i]))
			row.add_child(ob)
		"color":
			var cp := ColorPickerButton.new()
			cp.color = Color.from_string(String(cur), Color.WHITE)
			cp.custom_minimum_size = Vector2(60, 32)
			cp.color_changed.connect(func(c): set_v.call("#" + c.to_html(false)))
			row.add_child(cp)
		_:
			var le := LineEdit.new()
			le.text = String(cur)
			le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if String(p[1]) == "scene":
				le.placeholder_text = "res://mi_escena.tscn"
			elif String(p[1]) == "node":
				le.placeholder_text = "Ruta del nodo (ej. ../Puerta)"
			le.text_changed.connect(func(t): set_v.call(t))
			row.add_child(le)
	return row
