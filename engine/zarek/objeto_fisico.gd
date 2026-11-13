class_name ZarekObjetoFisico
extends RigidBody3D
## Mueble u objeto suelto con física real: se empuja, se vuelca y suena al golpear (Elena lo oye).
## Empieza dormido, así no cuesta nada hasta que alguien lo toca.

var sonido := "golpe_madera"
var _v_antes := Vector3.ZERO
var _sonar_t := 0.0

func _ready() -> void:
	collision_layer = 8
	collision_mask = 1 | 2 | 8
	contact_monitor = true
	max_contacts_reported = 2
	can_sleep = true
	body_entered.connect(_al_chocar)

func _physics_process(delta: float) -> void:
	_v_antes = linear_velocity
	_sonar_t = maxf(0.0, _sonar_t - delta)

func _al_chocar(_otro: Node) -> void:
	var v := _v_antes.length()
	if v > 1.1 and _sonar_t <= 0.0:
		_sonar_t = 0.3
		var a := AudioStreamPlayer3D.new()
		a.stream = AetherSynth.make(sonido)
		a.volume_db = -16.0 + minf(v, 5.0) * 3.5 + clampf(mass * 0.15, 0.0, 6.0)
		a.pitch_scale = clampf(1.6 - mass * 0.03, 0.6, 1.6) * randf_range(0.92, 1.08)
		a.unit_size = 3.0
		a.max_distance = 28.0
		get_parent().add_child(a)
		a.global_position = global_position
		a.play()
		a.finished.connect(a.queue_free)
		get_tree().call_group("zarek_oyentes", "oir_ruido", global_position, 2.0 + v * 2.5 + mass * 0.1)
