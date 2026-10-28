@icon("res://addons/aether/icons/player.svg")
class_name PlatformerPlayer
extends CharacterBody2D
## Jugador de plataformas de Aether Engine (Kael en la prueba de Chronos).
## Correr con inercia, salto variable con margen (coyote) y memoria,
## doble salto, dash, combo de 3 golpes, golpe aéreo, guardia, daño
## con retroceso e invulnerabilidad.

signal hp_changed(hp: float, max_hp: float)
signal died

const LAYER_WORLD := 1
const LAYER_PLAYER := 2
const LAYER_ENEMY := 4

@export_group("Aspecto")
## Animaciones del personaje. Vacío = Kael de Chronos.
@export var anim_set: AetherAnimSet
@export_group("Movimiento")
## Velocidad al correr (píxeles por segundo).
@export var move_speed := 560.0
## Lo rápido que alcanza la velocidad en el suelo.
@export var accel := 5200.0
## Lo rápido que frena en el suelo.
@export var decel := 6200.0
## Control en el aire.
@export var air_accel := 3600.0
## Gravedad: más alta = cae más rápido.
@export var gravity := 3500.0
## Fuerza del salto.
@export var jump_speed := 1180.0
## Fuerza del doble salto (0 = sin doble salto).
@export var double_jump_speed := 1080.0
## Velocidad máxima de caída.
@export var max_fall := 1500.0
## Corre solo hacia la derecha (juegos tipo corredor).
@export var auto_run := false
## Vuelve a aparecer en el último punto de control al caer.
@export var auto_respawn := true
@export_group("Dash")
## Velocidad del dash.
@export var dash_speed := 1500.0
## Duración del dash en segundos.
@export var dash_time := 0.17
@export_group("Vida")
## Vida máxima.
@export var max_hp := 100.0

const KAEL := {"idle": "KH_idle", "run": "KH_run", "jump": "KH_jumpU", "fall": "KH_fallU", "double_jump": "KH_jump",
	"attack1": "KH_atk1", "attack2": "KH_atk2", "attack3": "KH_atk3", "air_attack": "KH_airslash", "dash": "KH_dash",
	"guard": "KH_guard", "guard_hit": "KH_guardHit", "hurt": "KH_hurt", "death": "KH_death"}

var face := 1.0
var hp := 100.0
var jumps := 0
var coyote := 0.0
var jump_buffer := 0.0
var dash_t := 0.0
var dash_cd := 0.0
var air_dashed := false
var atk_t := 0.0
var atk_dur := 0.0
var atk_n := 0
var atk_hit_done := false
var combo_window := 0.0
var queued_attack := false
var inv := 0.0
var stun := 0.0
var guarding := false
var guard_stamina := 100.0
var dead := false
var checkpoint := Vector2.ZERO
var land_squash := 0.0
var _was_on_floor := false
var _hit_set: Array = []
var _run_dust := 0.0

var visual: Node2D
var sprite: SheetSprite
var light: PointLight2D

func _ready() -> void:
	collision_layer = LAYER_PLAYER
	collision_mask = LAYER_WORLD
	floor_snap_length = 14.0
	floor_max_angle = deg_to_rad(50)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(50, 124)
	shape.shape = rect
	shape.position = Vector2(0, -62)
	add_child(shape)
	visual = Node2D.new()
	add_child(visual)
	sprite = SheetSprite.new()
	sprite.unit_scale = 0.6
	sprite.anim_set = anim_set
	sprite.aliases = KAEL
	visual.add_child(sprite)
	sprite.play("idle", 14.0)
	light = PointLight2D.new()
	light.texture = FX.soft()
	light.texture_scale = 9.0
	light.energy = 0.55
	light.color = Color(1.0, 0.85, 0.65)
	light.position = Vector2(0, -72)
	add_child(light)
	hp = max_hp
	checkpoint = global_position
	Aether.player = self
	add_to_group("player")

func hurt_rect() -> Rect2:
	return Rect2(global_position + Vector2(-25, -124), Vector2(50, 124))

# ---------------- física y controles ----------------
func _physics_process(delta: float) -> void:
	if dead:
		velocity.y = min(velocity.y + gravity * delta, max_fall)
		velocity.x = move_toward(velocity.x, 0, decel * delta)
		move_and_slide()
		return
	inv = max(0.0, inv - delta)
	stun = max(0.0, stun - delta)
	dash_cd = max(0.0, dash_cd - delta)
	combo_window = max(0.0, combo_window - delta)
	jump_buffer = max(0.0, jump_buffer - delta)
	land_squash = max(0.0, land_squash - delta * 5.0)
	var on_floor := is_on_floor()
	if on_floor:
		coyote = 0.11
		jumps = 0
		air_dashed = false
		if not _was_on_floor and velocity.y >= 0:
			_on_land()
	else:
		coyote = max(0.0, coyote - delta)
	var dir := Input.get_axis("left", "right")
	if auto_run:
		dir = 1.0
	if Input.is_action_just_pressed("jump"):
		jump_buffer = 0.13
	guarding = Input.is_action_pressed("guard") and on_floor and dash_t <= 0 and atk_t <= 0 and stun <= 0
	if not guarding:
		guard_stamina = min(100.0, guard_stamina + delta * 30.0)
	# dash
	if Input.is_action_just_pressed("dash") and dash_cd <= 0 and stun <= 0 and not (air_dashed and not on_floor):
		dash_t = dash_time
		dash_cd = 0.55
		if not on_floor:
			air_dashed = true
		if dir != 0:
			face = sign(dir)
		velocity = Vector2(face * dash_speed, 0)
		atk_t = 0
		Aether.sfx("dash", 0.7)
		FX.burst(get_parent(), global_position + Vector2(0, -10), Color(1.6, 1.4, 1.0, 0.8), 10, 260, 0.3, 14, 0, 40, Vector2(-face, 0))
	if dash_t > 0:
		dash_t -= delta
		velocity.y = 0
		velocity.x = face * dash_speed
		if fmod(dash_t, 0.03) < delta:
			_afterimage()
		move_and_slide()
		_was_on_floor = is_on_floor()
		_animate(delta)
		return
	# ataque
	if Input.is_action_just_pressed("attack") and stun <= 0:
		if atk_t > atk_dur * 0.45 or atk_t <= 0:
			if atk_t <= 0:
				_start_attack(on_floor)
			else:
				queued_attack = true
	if atk_t > 0:
		atk_t -= delta
		_attack_tick(on_floor)
		if atk_t <= 0:
			atk_t = 0
			if queued_attack:
				queued_attack = false
				_start_attack(is_on_floor())
	# movimiento horizontal
	var speed_k := 1.0
	if guarding:
		speed_k = 0.0
	elif atk_t > 0 and on_floor:
		speed_k = 0.15
	if stun > 0:
		velocity.x = move_toward(velocity.x, 0, decel * 0.4 * delta)
	elif dir != 0 and speed_k > 0:
		var a := accel if on_floor else air_accel
		velocity.x = move_toward(velocity.x, dir * move_speed * speed_k, a * delta)
		if atk_t <= 0:
			face = sign(dir)
	else:
		velocity.x = move_toward(velocity.x, 0, (decel if on_floor else air_accel * 0.6) * delta)
	# salto
	if jump_buffer > 0 and stun <= 0 and not guarding:
		if coyote > 0:
			_jump(jump_speed, false)
		elif jumps < 1:
			jumps += 1
			_jump(double_jump_speed, true)
	if Input.is_action_just_released("jump") and velocity.y < -380:
		velocity.y *= 0.5
	velocity.y = min(velocity.y + gravity * delta, max_fall)
	move_and_slide()
	_was_on_floor = is_on_floor()
	# caer al vacío
	if global_position.y > 1600:
		take_damage(9999, global_position.x, true)
	_animate(delta)

func _jump(v: float, double: bool) -> void:
	velocity.y = -v
	coyote = 0
	jump_buffer = 0
	land_squash = -0.6
	if double:
		Aether.sfx("dj", 0.6)
		FX.ring(get_parent(), global_position + Vector2(0, -6), Color(1.5, 1.4, 1.0, 0.8), 70, 0.25)
		sprite.play("double_jump", 26.0, false, true)
	else:
		Aether.sfx("jump", 0.55)
		FX.burst(get_parent(), global_position, Color(0.9, 0.85, 0.7, 0.6), 8, 160, 0.35, 12, 300, 60, Vector2.UP)

func _on_land() -> void:
	land_squash = 1.0
	FX.burst(get_parent(), global_position, Color(0.9, 0.85, 0.7, 0.55), 10, 200, 0.35, 12, 200, 70, Vector2.UP)
	Aether.sfx("step", 0.5, 0.8)

func _afterimage() -> void:
	var ghost := Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.hframes = sprite.hframes
	ghost.frame = sprite.frame
	ghost.centered = false
	ghost.offset = sprite.offset
	ghost.scale = sprite.scale * Vector2(visual.scale.x, 1)
	ghost.global_position = global_position
	ghost.modulate = Color(1.6, 1.2, 0.6, 0.55)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	ghost.material = mat
	get_parent().add_child(ghost)
	var tw := ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.22)
	tw.tween_callback(ghost.queue_free)

# ---------------- combate ----------------
func _start_attack(on_floor: bool) -> void:
	_hit_set.clear()
	atk_hit_done = false
	if not on_floor:
		atk_n = 9
		atk_dur = 0.3
		sprite.play("air_attack", 1.0, false, true)
	else:
		if combo_window > 0:
			atk_n = (atk_n % 3) + 1
		else:
			atk_n = 1
		atk_dur = [0.0, 0.27, 0.27, 0.42][atk_n]
		sprite.play("attack%d" % atk_n, [0.0, 34.0, 30.0, 27.0][atk_n], false, true)
	atk_t = atk_dur
	combo_window = atk_dur + 0.32
	Aether.sfx("swing", 0.6, 1.0 + 0.08 * atk_n)

func _attack_tick(_on_floor: bool) -> void:
	var elapsed := atk_dur - atk_t
	var hit_at := 0.13 if atk_n == 3 else 0.07
	if atk_hit_done or elapsed < hit_at:
		return
	atk_hit_done = true
	var heavy := atk_n == 3
	var reach := 130.0 if heavy else 112.0
	var center := global_position + Vector2(face * reach * 0.5, -58)
	FX.slash(get_parent(), global_position + Vector2(face * 20, -60), face, Color(2.4, 2.0, 1.3) if heavy else Color(1.8, 1.7, 1.4), 110.0 if heavy else 92.0, -80.0 if atk_n != 2 else 70.0, 60.0 if atk_n != 2 else -60.0)
	if atk_n == 3:
		velocity.x = face * 420
	var shape := RectangleShape2D.new()
	shape.size = Vector2(reach, 120)
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.transform = Transform2D(0, center)
	q.collision_mask = LAYER_ENEMY
	q.collide_with_bodies = true
	q.collide_with_areas = true
	var hits := get_world_2d().direct_space_state.intersect_shape(q, 16)
	var dmg := 1.6 if heavy else 1.0
	if atk_n == 9:
		dmg = 1.2
	for h in hits:
		var c = h.collider
		if c == null or c in _hit_set or not c.has_method("take_hit"):
			continue
		_hit_set.append(c)
		c.take_hit(dmg, self, heavy)

func take_damage(amount: float, from_x: float, unblockable := false) -> void:
	if dead or (inv > 0 and not unblockable):
		return
	var from_dir: float = sign(global_position.x - from_x) if from_x != global_position.x else -face
	# guardia: bloquea los golpes que vienen de frente
	if guarding and not unblockable and sign(from_x - global_position.x) == face and guard_stamina > 0:
		guard_stamina -= amount * 2.2
		velocity.x = from_dir * 260
		sprite.play("guard_hit", 1.0, false, true)
		Aether.sfx("shield", 0.8)
		FX.burst(get_parent(), global_position + Vector2(face * 30, -60), Color(1.4, 1.8, 2.4), 16, 380, 0.3, 10, 300)
		Aether.hitstop(0.05)
		if guard_stamina <= 0:
			stun = 0.6
		return
	hp = max(0.0, hp - amount)
	hp_changed.emit(hp, max_hp)
	inv = 0.9
	stun = 0.28
	atk_t = 0
	velocity = Vector2(from_dir * 520, -520)
	sprite.play("hurt", 1.0, false, true)
	Aether.sfx("hurt", 0.9)
	Aether.hitstop(0.09)
	Aether.shake(12, 0.04)
	Aether.flash(Color(1, 0.15, 0.2), 0.28)
	FX.burst(get_parent(), global_position + Vector2(0, -60), Color(2.2, 0.4, 0.4), 18, 420, 0.4, 12)
	if hp <= 0:
		_die()

func heal(v: float) -> void:
	hp = min(max_hp, hp + v)
	hp_changed.emit(hp, max_hp)

func _die() -> void:
	dead = true
	sprite.play("death", 6.0, false, true)
	Aether.slowmo(0.35, 0.9)
	Aether.sfx("kill", 0.8, 0.7)
	died.emit()
	Aether.player_died.emit()
	if auto_respawn:
		await get_tree().create_timer(1.4, true, false, true).timeout
		respawn()
		if Aether.camera and Aether.camera.has_method("snap"):
			Aether.camera.snap()

func respawn() -> void:
	dead = false
	hp = max_hp
	hp_changed.emit(hp, max_hp)
	global_position = checkpoint
	velocity = Vector2.ZERO
	inv = 1.2
	sprite.play("idle", 14.0, true, true)

# ---------------- animación ----------------
func _animate(delta: float) -> void:
	visual.scale.x = face
	# estirar y aplastar al saltar y aterrizar
	var sq := 1.0
	if land_squash > 0:
		sq = 1.0 - 0.14 * land_squash
	elif land_squash < 0:
		sq = 1.0 + 0.1 * -land_squash
	visual.scale.y = sq
	visual.scale.x = face * (1.0 / sqrt(sq))
	# inclinación al correr
	var lean: float = clamp(velocity.x / 5000.0, -0.08, 0.08)
	visual.rotation = lerp(visual.rotation, lean, 1.0 - exp(-delta * 12.0))
	# parpadeo de invulnerabilidad
	visual.modulate.a = 0.35 if (inv > 0 and fmod(inv, 0.12) < 0.06) else 1.0
	if dead:
		return
	if stun > 0 and inv > 0.5:
		return
	if dash_t > 0:
		sprite.play("dash", 1.0)
		return
	if atk_t > 0:
		return
	if sprite.anim == "guard_hit" and not sprite.is_done():
		return
	if guarding:
		sprite.play("guard", 1.0)
		return
	if not is_on_floor():
		if sprite.anim == "double_jump" and not sprite.is_done():
			return
		sprite.play("jump" if velocity.y < 0 else "fall", 1.0)
		return
	if abs(velocity.x) > 40:
		sprite.play("run", clamp(abs(velocity.x) / move_speed * 30.0, 14.0, 32.0))
		_run_dust -= delta
		if _run_dust <= 0:
			_run_dust = 0.16
			FX.burst(get_parent(), global_position, Color(0.85, 0.8, 0.65, 0.35), 3, 90, 0.3, 10, 120, 50, Vector2(-face, -1))
	else:
		sprite.play("idle", 14.0)
