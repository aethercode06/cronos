@icon("res://addons/aether/icons/player.svg")
class_name AetherCar3D
extends VehicleBody3D
## Coche 3D con física real (suspensión, ruedas, derrape): ▲ o ATAQUE acelera,
## ▼ frena y da marcha atrás, ◀ ▶ gira, SALTO = freno de mano.
## Se monta solo con una carrocería y cuatro ruedas; puedes poner tu modelo .glb.

## Tu modelo 3D (opcional). Si no hay, se crea uno sencillo.
@export var model: PackedScene
@export var body_color := Color(0.85, 0.15, 0.2)
@export var power := 260.0
@export var max_steer := 0.55
@export var brake_force := 6.0
## Velocidad máxima (km/h aprox.).
@export var top_speed := 140.0

var _wheels: Array[VehicleWheel3D] = []
var _steer := 0.0

func _ready() -> void:
	mass = 900.0
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, -0.3, 0)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.8, 0.7, 3.8)
	cs.shape = box
	cs.position = Vector3(0, 0.55, 0)
	add_child(cs)
	if model:
		add_child(model.instantiate())
	else:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = body_color
		mat.metallic = 0.4
		mat.roughness = 0.35
		var b := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.8, 0.6, 3.8)
		b.mesh = bm
		b.material_override = mat
		b.position = Vector3(0, 0.55, 0)
		add_child(b)
		var top := MeshInstance3D.new()
		var tm := BoxMesh.new()
		tm.size = Vector3(1.5, 0.5, 1.8)
		top.mesh = tm
		var glass := StandardMaterial3D.new()
		glass.albedo_color = Color(0.1, 0.15, 0.25)
		glass.metallic = 0.8
		glass.roughness = 0.1
		top.material_override = glass
		top.position = Vector3(0, 1.05, -0.2)
		add_child(top)
	for w in [[Vector3(-0.85, 0.35, 1.25), true], [Vector3(0.85, 0.35, 1.25), true], [Vector3(-0.85, 0.35, -1.25), false], [Vector3(0.85, 0.35, -1.25), false]]:
		var wh := VehicleWheel3D.new()
		wh.position = w[0]
		wh.use_as_steering = w[1]
		wh.use_as_traction = true
		wh.wheel_radius = 0.38
		wh.wheel_rest_length = 0.18
		wh.suspension_travel = 0.25
		wh.suspension_stiffness = 45.0
		wh.damping_compression = 0.9
		wh.damping_relaxation = 1.2
		wh.wheel_friction_slip = 2.6
		wh.suspension_max_force = 12000.0
		var wm := MeshInstance3D.new()
		var cy := CylinderMesh.new()
		cy.top_radius = 0.38
		cy.bottom_radius = 0.38
		cy.height = 0.3
		wm.mesh = cy
		wm.rotation_degrees = Vector3(0, 0, 90)
		var wmat := StandardMaterial3D.new()
		wmat.albedo_color = Color(0.08, 0.08, 0.08)
		wm.material_override = wmat
		wh.add_child(wm)
		add_child(wh)
		_wheels.append(wh)
	if not Engine.is_editor_hint():
		Aether.player = self
		add_to_group("player")

func speed_kmh() -> float:
	return linear_velocity.length() * 3.6

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var gas := Input.get_action_strength("up") + Input.get_action_strength("attack")
	var back := Input.get_action_strength("down")
	var fwd_speed := linear_velocity.dot(global_transform.basis.z)
	var want: float = -Input.get_axis("left", "right") * max_steer * clamp(1.2 - speed_kmh() / 200.0, 0.35, 1.0)
	_steer = move_toward(_steer, want, delta * 2.5)
	steering = _steer
	if back > 0.0 and fwd_speed > 1.0:
		engine_force = 0.0
		brake = brake_force * back
	else:
		brake = 0.0
		engine_force = (gas - back * 0.6) * power * (1.0 if speed_kmh() < top_speed else 0.0) * mass / 100.0
	var hand := Input.is_action_pressed("jump")
	for i in _wheels.size():
		_wheels[i].wheel_friction_slip = 1.1 if (hand and i >= 2) else 2.6
	if global_position.y < -30.0:
		global_position += Vector3(0, 40, 0)
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		rotation = Vector3(0, rotation.y, 0)
	if global_transform.basis.y.y < 0.2 and linear_velocity.length() < 1.0:
		rotation = Vector3(0, rotation.y, 0)
		global_position += Vector3(0, 1.0, 0)
