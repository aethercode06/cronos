class_name ZarekObjetoFisico
extends RigidBody3D
## Mueble u objeto suelto con física real: se empuja, se vuelca y suena al golpear (Elena lo oye).
## Empieza dormido, así no cuesta nada hasta que alguien lo toca.

var sonido := "golpe_madera"
var rompible := false          # cerámica, porcelana, cristal: se hace añicos si choca fuerte
var _v_antes := Vector3.ZERO
var _sonar_t := 0.0
var _roto := false

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
	if rompible and not _roto and v > 3.2:
		_romper(v)
		return
	if v > 1.1 and _sonar_t <= 0.0:
		_sonar_t = 0.3
		var a := AudioStreamPlayer3D.new()
		a.stream = ZarekSonido.uno(sonido)
		a.volume_db = -16.0 + minf(v, 5.0) * 3.5 + clampf(mass * 0.15, 0.0, 6.0)
		a.pitch_scale = clampf(1.6 - mass * 0.03, 0.6, 1.6) * randf_range(0.92, 1.08)
		a.unit_size = 3.0
		a.max_distance = 28.0
		get_parent().add_child(a)
		a.global_position = global_position
		a.play()
		a.finished.connect(a.queue_free)
		get_tree().call_group("zarek_oyentes", "oir_ruido", global_position, 2.0 + v * 2.5 + mass * 0.1)

## Se hace añicos: trozos con el material del objeto que saltan por el suelo, sonido de cerámica rota y ruido
## que Elena oye desde lejos.
func _romper(v: float) -> void:
	_roto = true
	var mat: Material = null
	var tam := Vector3(0.2, 0.2, 0.2)
	for mi in find_children("*", "MeshInstance3D", true, false):
		var m3 := mi as MeshInstance3D
		if m3.mesh and m3.mesh.get_surface_count() > 0:
			mat = m3.get_active_material(0)
			tam = m3.mesh.get_aabb().size * m3.global_transform.basis.get_scale()
			break
	var n := clampi(int(tam.length() * 40.0), 6, 18)
	for k in n:
		var f := ZarekFragmento.new()
		var s := clampf(tam.length() * 0.22, 0.02, 0.09)
		f.tam = Vector3(s * randf_range(0.6, 1.4), s * 0.25, s * randf_range(0.6, 1.4))
		f.material = mat
		get_parent().add_child(f)
		f.global_position = global_position + Vector3(randf_range(-0.5, 0.5) * tam.x, randf_range(0.0, 0.8) * tam.y, randf_range(-0.5, 0.5) * tam.z)
		f.linear_velocity = _v_antes * 0.3 + Vector3(randf_range(-1.6, 1.6), randf_range(0.6, 2.4), randf_range(-1.6, 1.6))
		f.angular_velocity = Vector3(randf_range(-12, 12), randf_range(-12, 12), randf_range(-12, 12))
	var a := AudioStreamPlayer3D.new()
	a.stream = ZarekSonido.uno("ceramica")
	a.volume_db = 2.0
	a.unit_size = 4.0
	a.max_distance = 35.0
	get_parent().add_child(a)
	a.global_position = global_position
	a.play()
	a.finished.connect(a.queue_free)
	get_tree().call_group("zarek_oyentes", "oir_ruido", global_position, 15.0)
	queue_free()
