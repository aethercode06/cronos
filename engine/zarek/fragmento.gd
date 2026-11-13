class_name ZarekFragmento
extends RigidBody3D
## Trozo de vidrio de una botella rota: salta, rebota y se queda quieto en el suelo (luego deja de simularse).

var tam := Vector3(0.03, 0.004, 0.03)
var material: Material
var _vida := 0.0

func _ready() -> void:
	mass = 0.03
	collision_layer = 16
	collision_mask = 1 | 8
	continuous_cd = true
	var pm := PhysicsMaterial.new()
	pm.bounce = 0.25
	pm.friction = 0.7
	physics_material_override = pm
	# trozo irregular: un prisma triangular fino
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := Vector3(-tam.x * 0.5, 0, -tam.z * 0.5)
	var b := Vector3(tam.x * 0.5, 0, -tam.z * randf_range(0.1, 0.5))
	var c := Vector3(randf_range(-0.3, 0.3) * tam.x, 0, tam.z * 0.5)
	var up := Vector3(0, tam.y, 0)
	for tri in [[a, b, c], [a + up, c + up, b + up], [a, a + up, b + up], [a, b + up, b], [b, b + up, c + up], [b, c + up, c], [c, c + up, a + up], [c, a + up, a]]:
		for v in tri:
			st.add_vertex(v)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(maxf(tam.x, 0.01), maxf(tam.y, 0.006), maxf(tam.z, 0.01))
	cs.shape = bx
	cs.position.y = tam.y * 0.5
	add_child(cs)

func _physics_process(delta: float) -> void:
	_vida += delta
	# a los pocos segundos se congela: los cristales quedan en el suelo sin gastar física
	if _vida > 5.0 and linear_velocity.length() < 0.05:
		freeze = true
		set_physics_process(false)
