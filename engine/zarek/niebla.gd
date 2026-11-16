extends MultiMeshInstance3D
class_name ZarekNiebla
## Niebla de suelo del exterior: bancos de niebla alrededor del jugador que se reciclan al alejarse
## (siempre hay niebla cerca sin poner miles en el mapa). Se desvanece dentro de la casa.
var objetivo: Node3D
var fuerza := 1.0
var _mat: ShaderMaterial
var _pos: Array[Vector3] = []
var _tam: Array[Vector2] = []
var _rng := RandomNumberGenerator.new()
const N := 48
const RADIO := 34.0

func _ready() -> void:
	_rng.seed = 1874
	var tex := NoiseTexture2D.new()
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	var fn := FastNoiseLite.new()
	fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	fn.frequency = 0.012
	fn.fractal_octaves = 4
	tex.noise = fn
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://zarek/niebla.gdshader")
	_mat.set_shader_parameter("ruido", tex)
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	q.center_offset = Vector3(0, 0.5, 0)
	q.material = _mat
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = q
	multimesh.instance_count = N
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = 40.0
	for i in N:
		_pos.append(Vector3.ZERO)
		_tam.append(Vector2(_rng.randf_range(7.0, 14.0), _rng.randf_range(1.6, 3.2)))
	top_level = true

func _colocar(i: int, c: Vector3, lejos: bool) -> void:
	var a := _rng.randf() * TAU
	var r := _rng.randf_range(RADIO * 0.75, RADIO) if lejos else sqrt(_rng.randf()) * RADIO
	r = maxf(r, 3.0)
	_pos[i] = Vector3(c.x + cos(a) * r, -0.35 + _rng.randf() * 0.4, c.z + sin(a) * r)

func _process(delta: float) -> void:
	if objetivo == null:
		return
	var c := objetivo.global_position
	visible = fuerza > 0.02
	if not visible:
		return
	_mat.set_shader_parameter("densidad", 0.34 * fuerza)
	var viento := Vector3(0.25, 0, 0.08) * delta
	for i in N:
		if _pos[i] == Vector3.ZERO:
			_colocar(i, c, false)
		_pos[i] += viento * (0.6 + float(i % 5) * 0.2)
		var d := Vector2(_pos[i].x - c.x, _pos[i].z - c.z).length()
		if d > RADIO * 1.05:
			_colocar(i, c, true)
		var t := _tam[i]
		multimesh.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(t.x, t.y, t.x)), _pos[i]))
