class_name AetherBoss
extends CharacterBody2D
## Base de jefes de Aether Engine: vida, fases (furia al 50 %), momento débil
## (crítico ×2), golpes «DUROS» fuera de él, guardia, presentación y derrota épica.
## Cada jefe concreto hereda y escribe su propia secuencia de ataques.

signal hp_changed(hp: float, max_hp: float)
signal defeated

@export var boss_name := "JEFE"
@export var max_hp := 60.0
@export var contact_damage := 20.0
@export var body_size := Vector2(220, 200)

var hp := 60.0
var face := -1.0
var fury := false
var weak := false          # en su momento débil los golpes hacen crítico
var guard := false         # se está cubriendo: los golpes rebotan
var dying := false
var active := false
var state := "intro"
var state_t := 0.0
var _contact_cd := 0.0
var _flash := 0.0
var arena := Rect2()

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	hp = max_hp
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = body_size
	cs.shape = r
	cs.position = Vector2(0, -body_size.y * 0.5)
	add_child(cs)
	add_to_group("boss")

func hurt_rect() -> Rect2:
	return Rect2(global_position + Vector2(-body_size.x * 0.5, -body_size.y), body_size)

func set_state(s: String) -> void:
	state = s
	state_t = 0.0

func _physics_process(delta: float) -> void:
	if not active:
		return
	state_t += delta
	_contact_cd = max(0.0, _contact_cd - delta)
	_flash = max(0.0, _flash - delta * 5.0)
	if dying:
		_dying_tick(delta)
		return
	_boss_tick(delta)
	var pl = Aether.player
	if pl and not pl.dead and _contact_cd <= 0 and hurt_rect().grow(-30).intersects(pl.hurt_rect()):
		pl.take_damage(contact_damage, global_position.x)
		_contact_cd = 0.6

## Cada jefe implementa su comportamiento aquí.
func _boss_tick(_delta: float) -> void:
	pass

func _dying_tick(_delta: float) -> void:
	pass

func take_hit(dmg: float, from: Node2D, heavy := false) -> void:
	if dying or not active:
		return
	var c := global_position + Vector2(0, -body_size.y * 0.55)
	if guard:
		Aether.sfx("clang", 0.9)
		Aether.hitstop(0.05)
		FX.burst(get_parent(), c + Vector2(-face * -body_size.x * 0.4, 0), Color(1.5, 1.9, 2.6), 14, 420, 0.3, 9, 400)
		FX.float_text(get_parent(), c + Vector2(0, -60), "¡BLOQUEO!", Color(0.8, 0.9, 1.2), 26)
		if from.has_method("take_damage"):
			from.velocity.x = sign(from.global_position.x - global_position.x) * 520
		_on_blocked()
		return
	var mult := 2.0 if weak else 0.45
	var total := dmg * mult * (1.2 if heavy else 1.0)
	hp = max(0.0, hp - total)
	hp_changed.emit(hp, max_hp)
	_flash = 1.0
	Aether.sfx("hit", 1.0, 0.9 if weak else 1.2)
	if weak:
		Aether.hitstop(0.11)
		Aether.shake(12, 0.05)
		FX.burst(get_parent(), c, Color(3.0, 2.4, 1.0), 30, 700, 0.4, 12, 600)
		FX.ring(get_parent(), c, Color(2.4, 2.0, 1.0, 0.9), 180, 0.3)
		FX.float_text(get_parent(), c + Vector2(0, -90), "¡CRÍTICO!", Color(2.0, 1.7, 0.4), 34)
	else:
		Aether.hitstop(0.05)
		Aether.shake(5, 0.02)
		FX.burst(get_parent(), c, Color(1.6, 1.6, 1.8), 10, 420, 0.25, 8, 500)
		FX.float_text(get_parent(), c + Vector2(0, -80), "DURO", Color(0.75, 0.8, 0.9), 22)
	_on_hurt(weak)
	if not fury and hp <= max_hp * 0.5:
		fury = true
		_on_fury()
	if hp <= 0:
		dying = true
		weak = false
		guard = false
		set_state("die")
		Aether.sfx("boom", 1.0)
		Aether.sfx("kill", 0.9, 0.7)
		Aether.slowmo(0.2, 1.6)
		Aether.hitstop(0.3)
		Aether.shake(30, 0.12)
		Aether.flash(Color(1, 1, 1), 0.7)
		_on_defeat_start()

func _on_hurt(_crit: bool) -> void:
	pass

func _on_blocked() -> void:
	pass

func _on_fury() -> void:
	pass

func _on_defeat_start() -> void:
	pass

func finish_defeat() -> void:
	defeated.emit()
	Aether.boss_defeated.emit()
