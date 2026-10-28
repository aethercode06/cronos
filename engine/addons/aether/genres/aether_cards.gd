@icon("res://addons/aether/icons/aether.svg")
class_name AetherCards
extends AetherKit
## Juego de CARTAS completo (estilo combate por turnos): cada turno tienes
## 3 de energía y 5 cartas. Toca una carta para jugarla y «TERMINAR TURNO».
## Mira la intención del enemigo para defenderte. Tras cada victoria eliges
## una carta nueva. Todo se escribe en texto, sin programar.

@export_group("Cartas")
## Una carta por línea: Nombre | coste | daño | escudo | robar | curar
@export_multiline var cards_text := "Golpe | 1 | 6 | 0 | 0 | 0\nDefensa | 1 | 0 | 5 | 0 | 0\nGolpe fuerte | 2 | 13 | 0 | 0 | 0\nTajo rápido | 0 | 4 | 0 | 0 | 0\nEscudo y espada | 1 | 5 | 4 | 0 | 0\nConcentración | 1 | 0 | 0 | 2 | 0\nMuro | 2 | 0 | 12 | 0 | 0\nPoción | 1 | 0 | 0 | 0 | 8\nTormenta | 3 | 24 | 0 | 0 | 0"
## Mazo inicial: Nombre xCantidad, una por línea.
@export_multiline var deck_text := "Golpe x5\nDefensa x4\nGolpe fuerte x1"
@export_group("Enemigos")
## Un enemigo por línea: Nombre | vida | acciones (atacar N, defender N, fuerza N, curar N)
@export_multiline var enemies_text := "Limo | 30 | atacar 6, defender 5, atacar 8\nCaballero hueco | 46 | defender 6, atacar 10, fuerza 2, atacar 9\nGran Sapo | 80 | atacar 12, fuerza 3, defender 10, atacar 18"
@export var player_hp := 70
@export var energy_per_turn := 3
@export var hand_size := 5
## Imágenes de enemigos (en el mismo orden, opcional).
@export var enemy_textures: Array[Texture2D] = []

var defs := {}
var deck: Array = []
var draw_pile: Array = []
var discard: Array = []
var hand: Array = []
var hp := 70
var block := 0
var energy := 3
var foes: Array = []
var fight := 0
var foe := {}
var _intent := 0
var _shake := 0.0
var _hand_box: HBoxContainer
var _end_btn: Button
var _info: Label
var _reward: Control
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	_kit_setup("cartas")
	rng.randomize()
	hp = player_hp
	for line in cards_text.split("\n", false):
		var c := line.split("|")
		if c.size() >= 2:
			var n := c[0].strip_edges()
			defs[n] = {"name": n, "cost": _i(c, 1), "dmg": _i(c, 2), "block": _i(c, 3), "draw": _i(c, 4), "heal": _i(c, 5)}
	for line in deck_text.split("\n", false):
		var parts := line.rsplit("x", true, 1)
		var n := parts[0].strip_edges()
		var count := 1
		if parts.size() == 2 and parts[1].strip_edges().is_valid_int():
			count = parts[1].strip_edges().to_int()
		else:
			n = line.strip_edges()
		if defs.has(n):
			for i in count:
				deck.append(n)
	for line in enemies_text.split("\n", false):
		var c := line.split("|")
		if c.size() >= 3:
			var acts: Array = []
			for a in c[2].split(",", false):
				var w := a.strip_edges().split(" ", false)
				if w.size() >= 2:
					acts.append([w[0].to_lower(), w[1].to_int()])
			foes.append({"name": c[0].strip_edges(), "hp": _i(c, 1), "acts": acts})
	_build_ui()
	_start_fight()
	Aether.music("w0")

func _i(c: PackedStringArray, k: int) -> int:
	return c[k].strip_edges().to_int() if c.size() > k else 0

func _build_ui() -> void:
	var vs := view()
	_hand_box = HBoxContainer.new()
	_hand_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_hand_box.position = Vector2(20, vs.y - 250)
	_hand_box.size = Vector2(vs.x - 300, 230)
	_hand_box.add_theme_constant_override("separation", 10)
	hud.add_child(_hand_box)
	_end_btn = Button.new()
	_end_btn.text = Aether.t("TERMINAR\nTURNO")
	_end_btn.position = Vector2(vs.x - 260, vs.y - 200)
	_end_btn.size = Vector2(230, 120)
	_end_btn.add_theme_font_size_override("font_size", 28)
	_end_btn.pressed.connect(end_turn)
	hud.add_child(_end_btn)
	_info = _mk_label(28, Color(1, 1, 1))
	_info.position = Vector2(30, vs.y - 330)
	_info.size = Vector2(700, 60)
	hud.add_child(_info)

func _start_fight() -> void:
	if fight >= foes.size():
		end_game(true)
		return
	var d: Dictionary = foes[fight]
	foe = {"name": d["name"], "hp": d["hp"], "max": d["hp"], "block": 0, "str": 0, "acts": d["acts"]}
	_intent = 0
	draw_pile = deck.duplicate()
	draw_pile.shuffle()
	discard = []
	hand = []
	big(d["name"], 1.0)
	_start_turn()

func _start_turn() -> void:
	block = 0
	energy = energy_per_turn
	_draw_cards(hand_size)
	_refresh()

func _draw_cards(n: int) -> void:
	for i in n:
		if draw_pile.is_empty():
			draw_pile = discard.duplicate()
			draw_pile.shuffle()
			discard = []
		if draw_pile.is_empty() or hand.size() >= 10:
			return
		hand.append(draw_pile.pop_back())

func _intent_text() -> String:
	if foe.is_empty() or foe["acts"].is_empty():
		return ""
	var a: Array = foe["acts"][_intent % foe["acts"].size()]
	match a[0]:
		"atacar":
			return "⚔ %s %d" % [Aether.t("Ataca"), int(a[1]) + int(foe["str"])]
		"defender":
			return "🛡 %s %d" % [Aether.t("Se defiende"), a[1]]
		"fuerza":
			return "▲ %s +%d" % [Aether.t("Fuerza"), a[1]]
		"curar":
			return "✚ %s %d" % [Aether.t("Se cura"), a[1]]
	return "?"

func _refresh() -> void:
	for c in _hand_box.get_children():
		c.queue_free()
	for i in hand.size():
		var d: Dictionary = defs[hand[i]]
		var b := Button.new()
		b.custom_minimum_size = Vector2(150, 210)
		b.add_theme_font_size_override("font_size", 20)
		var lines: Array = ["(%d)  %s" % [d["cost"], Aether.t(d["name"])], ""]
		if d["dmg"] > 0:
			lines.append("⚔ %d" % d["dmg"])
		if d["block"] > 0:
			lines.append("🛡 %d" % d["block"])
		if d["draw"] > 0:
			lines.append("%s %d" % [Aether.t("Roba"), d["draw"]])
		if d["heal"] > 0:
			lines.append("✚ %d" % d["heal"])
		b.text = "\n".join(lines)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.disabled = d["cost"] > energy or over
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.5, 0.15, 0.15) if d["dmg"] > 0 else (Color(0.15, 0.3, 0.55) if d["block"] > 0 else Color(0.2, 0.45, 0.25))
		sb.set_corner_radius_all(14)
		sb.set_border_width_all(4)
		sb.border_color = Color(1, 0.85, 0.4)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.pressed.connect(play.bind(i))
		_hand_box.add_child(b)
	_info.text = "♥ %d/%d   🛡 %d   ⚡ %d/%d   ·   %s %d · %s %d" % [hp, player_hp, block, energy, energy_per_turn, Aether.t("Mazo"), draw_pile.size(), Aether.t("Descartes"), discard.size()]
	set_top("%s %d/%d" % [Aether.t("Combate"), fight + 1, foes.size()])
	set_top_right("%d" % score)
	queue_redraw()

## Juega la carta número i de la mano.
func play(i: int) -> void:
	if over or i >= hand.size() or _reward != null:
		return
	var d: Dictionary = defs[hand[i]]
	if d["cost"] > energy:
		return
	energy -= int(d["cost"])
	discard.append(hand[i])
	hand.remove_at(i)
	var center := Vector2(view().x * 0.5, view().y * 0.32)
	if d["dmg"] > 0:
		var dmg: int = d["dmg"]
		var absorbed: int = min(dmg, int(foe["block"]))
		foe["block"] -= absorbed
		foe["hp"] -= dmg - absorbed
		add_score((dmg - absorbed) * 10)
		_shake = 0.25
		Aether.sfx("hit", 0.8)
		Aether.shake(4 + dmg * 0.3)
		FX.burst(self, center, Color(2.2, 1.6, 1), 14, 380, 0.35, 8, 0)
		FX.float_text(self, center + Vector2(0, -100), str(dmg - absorbed), Color(1, 0.8, 0.3), 44)
	if d["block"] > 0:
		block += int(d["block"])
		Aether.sfx("shield", 0.6)
	if d["heal"] > 0:
		hp = min(player_hp, hp + int(d["heal"]))
		Aether.sfx("heal", 0.6)
	if d["draw"] > 0:
		_draw_cards(int(d["draw"]))
	if foe["hp"] <= 0:
		_win_fight()
		return
	_refresh()

func end_turn() -> void:
	if over or _reward != null:
		return
	discard.append_array(hand)
	hand = []
	foe["block"] = 0
	if not foe["acts"].is_empty():
		var a: Array = foe["acts"][_intent % foe["acts"].size()]
		var n: int = int(a[1])
		match a[0]:
			"atacar":
				var dmg: int = n + int(foe["str"])
				var absorbed: int = min(dmg, block)
				hp -= dmg - absorbed
				Aether.sfx("hurt", 0.7)
				Aether.shake(6 + dmg * 0.4)
				Aether.flash(Color(1, 0.2, 0.2), 0.25)
				FX.float_text(self, Vector2(200, view().y - 380), "-%d" % (dmg - absorbed), Color(1, 0.4, 0.4), 44)
			"defender":
				foe["block"] = n
			"fuerza":
				foe["str"] += n
			"curar":
				foe["hp"] = min(foe["max"], foe["hp"] + n)
	_intent += 1
	if hp <= 0:
		hp = 0
		_refresh()
		end_game(false)
		return
	_start_turn()

func _win_fight() -> void:
	add_score(1000)
	Aether.sfx("kill", 0.8)
	Aether.slowmo(0.3, 0.5)
	FX.ring(self, Vector2(view().x * 0.5, view().y * 0.32), Color(2, 1.6, 1), 260)
	fight += 1
	hand = []
	_refresh()
	if fight >= foes.size():
		end_game(true)
		return
	_show_reward()

func _show_reward() -> void:
	_reward = ColorRect.new()
	(_reward as ColorRect).color = Color(0, 0, 0, 0.7)
	_reward.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.add_child(_reward)
	var t := _mk_label(44, Color(1, 0.9, 0.5))
	t.text = Aether.t("Elige una carta nueva")
	t.position = Vector2(0, 80)
	t.size = Vector2(view().x, 60)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reward.add_child(t)
	var box := HBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.position = Vector2(0, 200)
	box.size = Vector2(view().x, 240)
	box.add_theme_constant_override("separation", 24)
	_reward.add_child(box)
	var names: Array = defs.keys()
	names.shuffle()
	for k in min(3, names.size()):
		var d: Dictionary = defs[names[k]]
		var b := Button.new()
		b.custom_minimum_size = Vector2(200, 220)
		b.add_theme_font_size_override("font_size", 22)
		b.text = "%s\n(%d)\n⚔ %d  🛡 %d" % [Aether.t(d["name"]), d["cost"], d["dmg"], d["block"]]
		b.pressed.connect(_take_reward.bind(names[k]))
		box.add_child(b)
	var skip := Button.new()
	skip.text = Aether.t("Saltar")
	skip.position = Vector2(view().x * 0.5 - 100, 480)
	skip.size = Vector2(200, 70)
	skip.add_theme_font_size_override("font_size", 26)
	skip.pressed.connect(_take_reward.bind(""))
	_reward.add_child(skip)

func _take_reward(n: String) -> void:
	if n != "":
		deck.append(n)
		Aether.toast(Aether.t("Carta añadida: ") + Aether.t(n))
	_reward.queue_free()
	_reward = null
	_start_fight()

func _process(d: float) -> void:
	_shake = max(0.0, _shake - d)
	queue_redraw()

func _draw() -> void:
	var vs := view()
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.07, 0.05, 0.1))
	draw_rect(Rect2(0, vs.y * 0.55, vs.x, vs.y * 0.45), Color(0.1, 0.07, 0.12))
	if foe.is_empty():
		return
	var c := Vector2(vs.x * 0.5, vs.y * 0.32) + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake * 40.0
	var tex: Texture2D = enemy_textures[fight] if fight < enemy_textures.size() else null
	if tex:
		var h := vs.y * 0.36
		var w := h * tex.get_width() / float(tex.get_height())
		draw_texture_rect(tex, Rect2(c - Vector2(w, h) * 0.5, Vector2(w, h)), false)
	else:
		var t := Time.get_ticks_msec() / 1000.0
		var r := 90.0 + sin(t * 3.0) * 6.0
		draw_circle(c + Vector2(0, 100), 110, Color(0, 0, 0, 0.3))
		draw_circle(c, r, Color(0.55, 0.2, 0.45))
		draw_circle(c + Vector2(-32, -20), 18, Color(1, 1, 0.8))
		draw_circle(c + Vector2(32, -20), 18, Color(1, 1, 0.8))
		draw_circle(c + Vector2(-28, -18), 8, Color(0.1, 0, 0))
		draw_circle(c + Vector2(36, -18), 8, Color(0.1, 0, 0))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(vs.x * 0.5 - 200, 120), foe["name"], HORIZONTAL_ALIGNMENT_CENTER, 400, 34, Color(1, 1, 1))
	var bw := 360.0
	var bx := vs.x * 0.5 - bw * 0.5
	draw_rect(Rect2(bx, vs.y * 0.32 + 130, bw, 22), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(bx, vs.y * 0.32 + 130, bw * max(0, foe["hp"]) / float(foe["max"]), 22), Color(0.9, 0.25, 0.3))
	draw_string(font, Vector2(bx, vs.y * 0.32 + 180), "♥ %d/%d   🛡 %d   ▲ %d" % [max(0, foe["hp"]), foe["max"], foe["block"], foe["str"]], HORIZONTAL_ALIGNMENT_CENTER, bw, 26, Color(1, 1, 1))
	draw_string(font, Vector2(vs.x * 0.5 + 150, vs.y * 0.32 - 40), _intent_text(), HORIZONTAL_ALIGNMENT_LEFT, 360, 30, Color(1, 0.8, 0.4))

func selftest() -> bool:
	var before: int = foe["hp"]
	for i in hand.size():
		if defs[hand[i]]["dmg"] > 0:
			play(i)
			break
	end_turn()
	return foe["hp"] < before or fight > 0
