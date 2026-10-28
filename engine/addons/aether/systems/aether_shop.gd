@icon("res://addons/aether/icons/ui.svg")
class_name AetherShop
extends CanvasLayer
## Tienda lista: escribe los productos en «products», uno por línea:
##   Nombre del producto | precio | objeto que da
## Se paga con la variable «currency» (monedas). Ej.: «Poción | 30 | pocion».
## Ábrela con el evento «Abrir tienda» o con $Tienda.open().

## Productos: «Nombre | precio | objeto».
@export_multiline var products := "Poción de vida | 30 | pocion\nTraje de fuego | 200 | traje_fuego\nLlave dorada | 120 | llave_dorada"
## Variable con la que se paga.
@export var currency := "monedas"
## Título de la tienda.
@export var title := "TIENDA"

var _root: Control
var _list: VBoxContainer
var _money: Label

func _ready() -> void:
	layer = 75
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = ColorRect.new()
	(_root as ColorRect).color = Color(0, 0, 0, 0.7)
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.position = Vector2(-300, -260)
	v.custom_minimum_size = Vector2(600, 0)
	v.add_theme_constant_override("separation", 10)
	_root.add_child(v)
	var t := Label.new()
	t.text = Aether.t(title)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 52)
	t.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	v.add_child(t)
	_money = Label.new()
	_money.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_money.add_theme_font_size_override("font_size", 30)
	v.add_child(_money)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	v.add_child(_list)
	var close := Button.new()
	close.text = Aether.t("CERRAR")
	close.custom_minimum_size = Vector2(600, 64)
	close.add_theme_font_size_override("font_size", 28)
	close.pressed.connect(close_shop)
	v.add_child(close)

func open() -> void:
	_refresh()
	_root.visible = true
	get_tree().paused = true

func close_shop() -> void:
	_root.visible = false
	get_tree().paused = false

func _refresh() -> void:
	_money.text = "◆ %d" % int(Aether.get_var(currency))
	for c in _list.get_children():
		c.queue_free()
	for line in products.split("\n"):
		var parts := line.split("|")
		if parts.size() < 2:
			continue
		var pname := parts[0].strip_edges()
		var price := int(parts[1].strip_edges())
		var item := parts[2].strip_edges() if parts.size() > 2 else pname
		var b := Button.new()
		var owned := Aether.inventory.count(item)
		b.text = "%s   ·   ◆ %d%s" % [Aether.t(pname), price, ("   (x%d)" % owned) if owned > 0 else ""]
		b.custom_minimum_size = Vector2(600, 70)
		b.add_theme_font_size_override("font_size", 28)
		b.disabled = Aether.get_var(currency) < price
		b.pressed.connect(_buyer(price, item, pname))
		_list.add_child(b)

func _buyer(price: int, item: String, pname: String) -> Callable:
	return func() -> void:
		if Aether.get_var(currency) < price:
			return
		Aether.add_var(currency, -price)
		Aether.inventory.give(item)
		Aether.sfx("win", 0.6, 1.4)
		Aether.toast(Aether.t("Comprado") + ": " + Aether.t(pname))
		_refresh()
