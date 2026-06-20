extends Node

## 物品欄（背包）：僅存放「屬性道具」「劇情道具」；數量為 0 時不顯示。

signal inventory_changed(item_id: String, new_count: int)

var _items: Dictionary = {}

func _ready() -> void:
	print("[InventoryManager] 物品欄就绪。")

func get_count(item_id: String) -> int:
	var clean_id: String = item_id.strip_edges()
	if clean_id == "":
		return 0
	return maxi(int(_items.get(clean_id, 0)), 0)

func has_item(item_id: String, amount: int = 1) -> bool:
	return get_count(item_id) >= maxi(amount, 1)

func add_item(item_id: String, amount: int = 1) -> int:
	var clean_id: String = item_id.strip_edges()
	var safe_amount: int = maxi(amount, 0)
	if clean_id == "" or safe_amount <= 0:
		return get_count(clean_id)

	var item: ItemResource = ItemDatabase.get_item(clean_id)
	if item == null:
		push_warning("[InventoryManager] 未知 item_id：%s" % clean_id)
		return get_count(clean_id)
	if not item.is_bag_item():
		push_warning("[InventoryManager] %s 不可放入物品欄。" % clean_id)
		return get_count(clean_id)

	var new_count: int = get_count(clean_id) + safe_amount
	_items[clean_id] = new_count
	inventory_changed.emit(clean_id, new_count)
	return new_count

func try_consume(item_id: String, amount: int = 1) -> bool:
	var clean_id: String = item_id.strip_edges()
	var safe_amount: int = maxi(amount, 1)
	if clean_id == "":
		return false
	if get_count(clean_id) < safe_amount:
		return false

	var new_count: int = get_count(clean_id) - safe_amount
	if new_count <= 0:
		_items.erase(clean_id)
	else:
		_items[clean_id] = new_count
	inventory_changed.emit(clean_id, new_count)
	return true

## 僅返回 count > 0 且仍為物品欄類別的項目。
func get_bag_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for item_id in _items:
		var count: int = get_count(str(item_id))
		if count <= 0:
			continue
		var item: ItemResource = ItemDatabase.get_item(str(item_id))
		if item != null and item.is_bag_item():
			snapshot[str(item_id)] = count
	return snapshot

func get_all_items() -> Dictionary:
	return get_bag_snapshot()

func get_bag_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for item_id in get_bag_snapshot():
		var item: ItemResource = ItemDatabase.get_item(item_id)
		if item == null:
			continue
		entries.append({
			"item_id": item_id,
			"item_name": item.item_name,
			"count": get_count(item_id),
			"category": int(item.item_category),
		})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("item_id", "")) < str(b.get("item_id", ""))
	)
	return entries

## 可贈送給已簽約藝人的物品欄項目（屬性／劇情）。
func get_giftable_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for entry in get_bag_entries():
		var item_id: String = str(entry.get("item_id", ""))
		var item: ItemResource = ItemDatabase.get_item(item_id)
		if item != null and item.can_gift_to_signed_artist():
			entries.append(entry)
	return entries

func clear_inventory() -> void:
	_items.clear()

func export_save_state() -> Dictionary:
	return get_bag_snapshot()

func import_save_state(data: Dictionary) -> void:
	_items.clear()
	if data == null:
		return
	for item_id in data:
		var clean_id: String = str(item_id).strip_edges()
		if clean_id == "":
			continue
		var count: int = maxi(int(data[item_id]), 0)
		if count > 0:
			_items[clean_id] = count
