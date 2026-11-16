extends Node3D
## Escena mínima de control para el emulador: un cubo girando, una luz y sonido.
var t := 0.0
var c: MeshInstance3D
func _ready() -> void:
	var cam := Camera3D.new(); cam.position = Vector3(0, 1, 3); add_child(cam)
	var l := DirectionalLight3D.new(); l.rotation_degrees = Vector3(-45, 30, 0); l.shadow_enabled = true; add_child(l)
	c = MeshInstance3D.new(); c.mesh = BoxMesh.new(); add_child(c)
	var p := AudioStreamPlayer.new(); p.stream = AetherSynth.make("drone"); add_child(p); p.play()
func _process(d: float) -> void:
	t += d
	c.rotation.y = t
	if int(t * 10) % 50 == 0:
		print("ZAREK FPS %d control" % Engine.get_frames_per_second())
	if t > 3.0 and not has_meta("x"):
		set_meta("x", 1)
		print("ZAREK CARGA 0 ms (control)")
