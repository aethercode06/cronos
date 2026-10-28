@icon("res://addons/aether/icons/enemy.svg")
class_name AetherEnemy
extends CharacterBody2D
## Criatura genérica de Aether Engine. Tipos: «walker» (patrulla y embiste),
## «jumper» (salta hacia ti), «flyer» (vuela y se lanza en picado).
## Al recibir golpes: destello blanco, retroceso, aplastamiento y chispas.

const FLASH_SHADER := preload("res://addons/aether/fx/flash.gdshader")

## Comportamiento: «walker» patrulla y embiste · «jumper» salta hacia ti · «flyer» vuela y se lanza en picado.
@export_enum("walker", "jumper", "flyer") var kind := "walker"
@export_group("Aspecto")
## Animaciones (move, jump, attack…). Vacío = usa las hojas de Chronos de abajo.
@export var anim_set: AetherAnimSet
## Hoja de Chronos para moverse.
@export var sheet_move := "opossum"
## Hoja de Chronos para saltar o atacar (opcional).
@export var sheet_alt := ""
## Escala de las hojas de Chronos.
@export var unit_scale := 0.667
@export_group("Combate")
## Golpes que aguanta.
@export var hp := 3.0
## Velocidad de movimiento.
@export var speed := 150.0
## Daño al tocar al jugador.
@export var damage := 14.0
## Distancia que patrulla a cada lado (o radio de vuelo).
@export var patrol := 220.0
## Tamaño del cuerpo para los golpes.
@export var body_size := Vector2(60, 46)

var face := -1.0
var home := Vector2.ZERO
var sprite: SheetSprite
var visual: Node2D
var _mat: ShaderMaterial
var _flash := 0.0
var _hit_t := 0.0
var _t := 0.0
var _state := "idle"
var _state_t := 0.0
var _squash := 0.0
var dead := false

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	home = global_position
	_t = randf() * 5.0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = body_size
	cs.shape = r
	cs.position = Vector2(0, -body_size.y * 0.5)
	add_child(cs)
	visual = Node2D.new()
	add_child(visual)
	sprite = SheetSprite.new()
	sprite.unit_scale = unit_scale
	sprite.anim_set = anim_set
	sprite.aliases = {"move": sheet_move, "jump": sheet_alt if sheet_alt != "" else sheet_move}
	visual.add_child(sprite)
	sprite.play("move", 12.0)
	_mat = ShaderMaterial.new()
	_mat.shader = FLASH_SHADER
	sprite.material = _mat
	add_to_group("enemies")

func hurt_rect() -> Rect2:
	return Rect2(global_position + Vector2(-body_size.x * 0.5, -body_size.y), body_size)

func _physics_process(delta: float) -> void:
	if dead:
		return
	_t += delta
	_state_t += delta
	_hit_t = max(0.0, _hit_t - delta)
	_flash = max(0.0, _flash - delta * 6.0)
	_squash = max(0.0, _squash - delta * 5.0)
	_mat.set_shader_parameter("flash", _flash)
	var pl: Node2D = Aether.player
	var to_p := Vector2.ZERO
	if pl:
		to_p = pl.global_position - global_position
	match kind:
		"walker": _walker(delta, to_p)
		"jumper": _jumper(delta, to_p)
		"flyer": _flyer(delta, to_p)
	# daño por contacto
	if pl and not pl.dead and _hit_t <= 0 and hurt_rect().grow(-6).intersects(pl.hurt_rect()):
		pl.take_damage(damage, global_position.x)
	visual.scale = Vector2(-face * (1.0 + 0.25 * _squash), 1.0 - 0.25 * _squash)

func _walker(delta: float, to_p: Vector2) -> void:
	velocity.y = min(velocity.y + 2600 * delta, 1400)
	if _hit_t > 0:
		velocity.x = move_toward(velocity.x, 0, 1800 * delta)
	elif _state == "wind":
		velocity.x = 0
		visual.position.x = sin(_t * 60.0) * 2.0
		if _state_t > 0.38:
			_state = "lunge"; _state_t = 0
			Aether.sfx("dash", 0.4, 1.3)
	elif _state == "lunge":
		velocity.x = face * speed * 3.4
		if _state_t > 0.28:
			_state = "idle"; _state_t = -0.9
	else:
		visual.position.x = 0
		var sees: bool = abs(to_p.x) < 420 and abs(to_p.y) < 120 and not Aether.player.dead
		if sees:
			face = sign(to_p.x)
			velocity.x = face * speed * 1.4
			if abs(to_p.x) < 190 and _state_t > 0:
				_state = "wind"; _state_t = 0
				FX.float_text(get_parent(), global_position + Vector2(0, -body_size.y - 30), "!", Color(2.0, 1.6, 0.3), 34)
		else:
			if global_position.x > home.x + patrol: face = -1
			elif global_position.x < home.x - patrol: face = 1
			velocity.x = face * speed
		if is_on_floor() and not _ground_ahead():
			face = -face
			velocity.x = face * speed
	move_and_slide()

func _ground_ahead() -> bool:
	var q := PhysicsRayQueryParameters2D.create(global_position + Vector2(face * (body_size.x * 0.5 + 8), -8), global_position + Vector2(face * (body_size.x * 0.5 + 8), 60), 1)
	return not get_world_2d().direct_space_state.intersect_ray(q).is_empty()

func _jumper(delta: float, to_p: Vector2) -> void:
	velocity.y = min(velocity.y + 2600 * delta, 1400)
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, 3000 * delta)
		if sprite.anim != "move":
			sprite.play("move", 8.0)
			_squash = 1.0
		if _state_t > 1.4 and _hit_t <= 0:
			_state_t = 0
			face = sign(to_p.x) if abs(to_p.x) < 600 else -face
			velocity = Vector2(face * clamp(abs(to_p.x) * 1.3, 120, 420), -980)
			sprite.play("jump", 6.0, false)
	move_and_slide()

func _flyer(delta: float, to_p: Vector2) -> void:
	if _state == "dive":
		velocity = velocity.move_toward(Vector2.ZERO, 300 * delta)
		if _state_t > 0.9:
			_state = "idle"; _state_t = 0
	else:
		var want := home + Vector2(sin(_t * 1.3) * patrol, sin(_t * 2.6) * 30)
		if abs(to_p.x) < 520 and abs(to_p.y) < 420 and not Aether.player.dead:
			want = Aether.player.global_position + Vector2(-sign(to_p.x) * 160, -220)
			if _state_t > 2.2:
				_state = "dive"; _state_t = 0
				velocity = (Aether.player.global_position + Vector2(0, -50) - global_position).normalized() * 820
				Aether.sfx("dash", 0.4, 1.5)
		velocity = velocity.lerp((want - global_position) * 2.2, 1.0 - exp(-delta * 3.0))
		face = sign(to_p.x) if to_p.x != 0 else face
	if _hit_t > 0:
		velocity *= 0.9
	move_and_slide()

func take_hit(dmg: float, from: Node2D, heavy := false) -> void:
	if dead:
		return
	hp -= dmg
	_flash = 1.0
	_squash = 1.0
	_hit_t = 0.25
	_state = "idle"; _state_t = -0.4
	var dir: float = sign(global_position.x - from.global_position.x)
	velocity = Vector2(dir * (520.0 if heavy else 360.0), -260.0 if kind != "flyer" else -80.0)
	Aether.hitstop(0.07 if heavy else 0.045)
	Aether.shake(6 if heavy else 3.5, 0.02)
	Aether.sfx("hit", 0.8, 1.1 if heavy else 1.0)
	var c := global_position + Vector2(0, -body_size.y * 0.5)
	FX.burst(get_parent(), c, Color(2.6, 2.2, 1.2), 14 if heavy else 9, 520, 0.28, 9, 900)
	FX.glow(get_parent(), c, Color(1.6, 1.2, 0.6, 0.7), 70, 0.12)
	if hp <= 0:
		_die(dir)

func _die(dir: float) -> void:
	dead = true
	Aether.enemy_killed.emit()
	collision_layer = 0
	Aether.sfx("kill", 0.7, 1.2)
	var c := global_position + Vector2(0, -body_size.y * 0.5)
	FX.burst(get_parent(), c, Color(2.2, 1.8, 2.6), 26, 560, 0.5, 14, 300)
	FX.ring(get_parent(), c, Color(1.8, 1.6, 2.4, 0.9), 120, 0.3)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "rotation", dir * 1.6, 0.35)
	tw.tween_property(self, "position", position + Vector2(dir * 90, -60), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(visual, "modulate:a", 0.0, 0.35)
	tw.chain().tween_callback(queue_free)
