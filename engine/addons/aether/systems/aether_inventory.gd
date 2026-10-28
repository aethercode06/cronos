class_name AetherInventory
extends RefCounted
## Inventario: Aether.inventory.give("llave_roja") · has("llave_roja") · take("pocion")
## Se guarda solo en la partida.

signal changed(item: String, count: int)

var items := {}

func load_saved() -> void:
	items = Aether.save.get_value("inventario", {})

func give(item: String, n := 1) -> void:
	items[item] = int(items.get(item, 0)) + n
	Aether.save.set_value("inventario", items)
	changed.emit(item, items[item])

func take(item: String, n := 1) -> bool:
	if count(item) < n:
		return false
	items[item] = count(item) - n
	if items[item] <= 0:
		items.erase(item)
	Aether.save.set_value("inventario", items)
	changed.emit(item, count(item))
	return true

func has(item: String, n := 1) -> bool:
	return count(item) >= n

func count(item: String) -> int:
	return int(items.get(item, 0))
