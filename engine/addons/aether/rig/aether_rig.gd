@tool
@icon("res://addons/aether/icons/rig.svg")
class_name AetherRig
extends Node2D
## Personaje por piezas con huesos (estilo Spine), para jefes, criaturas y héroes.
## 1) Añade las piezas en «parts» (Inspector) y se monta solo, también en el editor.
## 2) Elige una animación automática en «motion» (reposo, andar, preparar, golpe,
##    cubrirse, herido, furia, derrota) o crea las tuyas con un AnimationPlayer
##    animando la rotación de cada pieza: no hace falta programar.

signal motion_finished(name: String)

## Piezas del personaje.
@export var parts: Array[AetherRigPart] = []:
	set(v):
		parts = v
		_rebuild.call_deferred()
## Escala general.
@export_range(0.05, 4.0) var art_scale := 1.0:
	set(v):
		art_scale = v
		scale = Vector2.ONE * v
## Animación automática en curso.
@export_enum("reposo", "andar", "preparar", "golpe", "cubrirse", "herido", "furia", "derrota", "nada") var motion := "reposo"
## Velocidad de las animaciones automáticas.
@export_range(0.1, 3.0) var speed := 1.0
## Intensidad de los movimientos.
@export_range(0.0, 2.0) var intensity := 1.0

var bones := {}            # nombre → Node2D (punto de giro)
var _base := {}            # nombre → {rot, pos, scale}
var _t := 0.0
var _mt := 0.0             # tiempo dentro de la animación actual
var _last_motion := ""

func _ready() -> void:
	scale = Vector2.ONE * art_scale
	_rebuild()

func _rebuild() -> void:
	for c in get_children():
		if c.has_meta("aether_rig"):
			c.free()
	bones.clear()
	_base.clear()
	var pending := parts.duplicate()
	var guard := 0
	while pending.size() > 0 and guard < 200:
		guard += 1
		var p: AetherRigPart = pending.pop_front()
		if p == null or p.name == "":
			continue
		var holder: Node = self
		if p.parent != "":
			if not bones.has(p.parent):
				pending.append(p)
				continue
			holder = bones[p.parent]
		var bone := Node2D.new()
		bone.name = p.name
		bone.position = p.offset
		bone.set_meta("aether_rig", true)
		bone.set_meta("role", p.role)
		bone.z_index = p.z
		bone.z_as_relative = false if p.parent == "" else true
		var spr := Sprite2D.new()
		spr.texture = p.texture
		spr.centered = false
		spr.offset = -p.pivot
		bone.add_child(spr)
		holder.add_child(bone)
		bones[p.name] = bone
		_base[p.name] = {"rot": 0.0, "pos": p.offset, "scale": Vector2.ONE}

## Lanza una animación automática desde el código: rig.play("golpe").
func play(m: String, restart := true) -> void:
	if m != motion or restart:
		motion = m
		_mt = 0.0

func _process(delta: float) -> void:
	if bones.is_empty():
		return
	_t += delta * speed
	_mt += delta * speed
	if motion != _last_motion:
		_last_motion = motion
		_mt = 0.0
	var k := intensity
	for n in bones:
		var b: Node2D = bones[n]
		var role: String = b.get_meta("role")
		var base: Dictionary = _base[n]
		var rot := 0.0
		var pos: Vector2 = base.pos
		var sc := Vector2.ONE
		var side := 1.0 if role.ends_with("delante") else -1.0
		match motion:
			"reposo":
				if role == "cuerpo":
					sc = Vector2(1.0 + sin(_t * 2.4) * 0.015 * k, 1.0 + sin(_t * 2.4) * 0.025 * k)
				elif role == "cabeza":
					rot = sin(_t * 2.4 - 0.6) * 0.04 * k
				elif role.begins_with("brazo"):
					rot = sin(_t * 2.4 + side) * 0.06 * k
				elif role in ["cola", "ala"]:
					rot = sin(_t * 3.0) * 0.12 * k
				elif role == "mandibula":
					rot = (sin(_t * 0.8) * 0.5 + 0.5) * 0.04 * k
			"andar":
				var ph := _t * 7.0
				if role == "cuerpo":
					pos.y = base.pos.y - abs(sin(ph)) * 8.0 * k
					rot = sin(ph) * 0.03 * k
				elif role.begins_with("pierna"):
					rot = sin(ph + (0.0 if side > 0 else PI)) * 0.45 * k
				elif role.begins_with("brazo"):
					rot = sin(ph + (PI if side > 0 else 0.0)) * 0.35 * k
				elif role == "cabeza":
					rot = sin(ph * 2.0) * 0.03 * k
				elif role in ["cola", "ala"]:
					rot = sin(ph) * 0.2 * k
			"preparar":
				var e: float = min(1.0, _mt / 0.35)
				if role == "cuerpo":
					sc = Vector2(1.0 + 0.08 * e * k, 1.0 - 0.1 * e * k)
					rot = -0.1 * e * k
				elif role.begins_with("brazo"):
					rot = -1.2 * e * k * (1.0 if side > 0 else 0.5)
				elif role == "cabeza":
					rot = -0.12 * e * k
				elif role == "mandibula":
					rot = 0.25 * e * k
				elif role == "arma":
					rot = -0.8 * e * k
				pos += Vector2(sin(_t * 60.0) * 1.5 * e, 0)
			"golpe":
				var e2: float = clamp(_mt / 0.12, 0.0, 1.0)
				var back: float = clamp((_mt - 0.35) / 0.3, 0.0, 1.0)
				var a: float = e2 * (1.0 - back)
				if role == "cuerpo":
					rot = 0.18 * a * k
					pos.x = base.pos.x + 14.0 * a * k
				elif role.begins_with("brazo"):
					rot = lerp(-1.2, 1.1, e2) * (1.0 - back) * k * (1.0 if side > 0 else 0.5)
				elif role == "cabeza":
					rot = 0.1 * a * k
				elif role == "mandibula":
					rot = 0.35 * a * k
				elif role == "arma":
					rot = lerp(-0.8, 1.4, e2) * (1.0 - back) * k
				if _mt > 0.7:
					_finish()
			"cubrirse":
				var e3: float = min(1.0, _mt / 0.15)
				if role == "cuerpo":
					sc = Vector2(1.0 + 0.04 * e3, 1.0 - 0.06 * e3)
					rot = -0.08 * e3
				elif role.begins_with("brazo"):
					rot = -0.9 * e3 * k
				elif role == "cabeza":
					rot = 0.15 * e3
			"herido":
				var f: float = max(0.0, 1.0 - _mt / 0.35)
				if role == "cuerpo":
					rot = -0.2 * f * k
					pos.x = base.pos.x - 12.0 * f
				elif role == "cabeza":
					rot = -0.25 * f * k
				elif role.begins_with("brazo"):
					rot = 0.5 * f * k * side
				if _mt > 0.35:
					_finish()
			"furia":
				var sh := sin(_t * 40.0) * 0.03
				if role == "cuerpo":
					sc = Vector2(1.06, 0.97)
					rot = sh
				elif role == "cabeza":
					rot = -0.25 * k + sh
				elif role == "mandibula":
					rot = 0.45 * k
				elif role.begins_with("brazo"):
					rot = (-0.7 + sin(_t * 18.0) * 0.1) * k
			"derrota":
				var d: float = min(1.0, _mt / 1.2)
				if role == "cuerpo":
					rot = -0.6 * d * k
					pos.y = base.pos.y + 30.0 * d
					sc = Vector2(1.0 + 0.1 * d, 1.0 - 0.2 * d)
				elif role == "cabeza":
					rot = 0.5 * d * k
				elif role.begins_with("brazo") or role.begins_with("pierna"):
					rot = 0.9 * d * k * side
				elif role == "mandibula":
					rot = 0.5 * d
				if _mt > 1.3:
					_finish()
		b.rotation = lerp_angle(b.rotation, rot, 1.0 - exp(-delta * 18.0))
		b.position = b.position.lerp(pos, 1.0 - exp(-delta * 18.0))
		b.scale = b.scale.lerp(sc, 1.0 - exp(-delta * 18.0))

func _finish() -> void:
	var m := motion
	if m in ["golpe", "herido"]:
		motion = "reposo"
	if m == "derrota":
		motion = "nada"
	motion_finished.emit(m)
