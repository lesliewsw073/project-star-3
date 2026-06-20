extends Node

## 玩家家中：藝人贈禮展示（不進物品欄）。
## 每位藝人可配置贈送次數上限（v1 預設 3，後續可改為 per-artist 表）。

signal home_gifts_changed()

const DEFAULT_MAX_GIFTS_PER_ARTIST: int = 3

var _gifts: Array[Dictionary] = []
var _artist_gift_counts: Dictionary = {}

func _ready() -> void:
	print("[PlayerHomeManager] 就绪。")

func get_gifts() -> Array[Dictionary]:
	return _gifts.duplicate(true)

func get_gifts_by_slot(slot: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for gift in _gifts:
		if int(gift.get("home_display_slot", ItemResource.HomeDisplaySlot.NONE)) == slot:
			result.append(gift.duplicate(true))
	return result

func get_artist_gift_count(artist_id: String) -> int:
	return int(_artist_gift_counts.get(artist_id.strip_edges(), 0))

func can_receive_artist_gift(artist_id: String, max_gifts: int = DEFAULT_MAX_GIFTS_PER_ARTIST) -> bool:
	return get_artist_gift_count(artist_id) < maxi(max_gifts, 1)

func try_receive_artist_gift(item_id: String, artist_id: String) -> Dictionary:
	var item: ItemResource = ItemDatabase.get_item(item_id)
	if item == null:
		return _fail("未知道具：%s" % item_id)
	if int(item.item_category) != ItemResource.ItemCategory.ARTIST_GIFT:
		return _fail("%s 不是藝人贈禮。" % item_id)

	var clean_artist: String = artist_id.strip_edges()
	if clean_artist == "":
		clean_artist = item.default_source_artist_id.strip_edges()
	if clean_artist == "":
		return _fail("缺少贈送者 artist_id。")

	if not can_receive_artist_gift(clean_artist):
		return _fail("該藝人贈禮次數已達上限。")

	var entry: Dictionary = {
		"item_id": item.item_id,
		"item_name": item.item_name,
		"artist_id": clean_artist,
		"home_display_slot": int(item.home_display_slot),
		"received_total_day": TimeManager.total_days_elapsed,
	}
	_gifts.append(entry)
	_artist_gift_counts[clean_artist] = get_artist_gift_count(clean_artist) + 1
	home_gifts_changed.emit()
	return {"success": true, "gift": entry.duplicate(true)}

func export_save_state() -> Dictionary:
	return {
		"gifts": _gifts.duplicate(true),
		"artist_gift_counts": _artist_gift_counts.duplicate(true),
	}

func import_save_state(data: Dictionary) -> void:
	_gifts.clear()
	_artist_gift_counts.clear()
	if data == null:
		return

	var gifts: Variant = data.get("gifts", [])
	if gifts is Array:
		for entry in gifts:
			if entry is Dictionary:
				_gifts.append(entry.duplicate(true))

	var counts: Variant = data.get("artist_gift_counts", {})
	if counts is Dictionary:
		for artist_id in counts:
			var clean_id: String = str(artist_id).strip_edges()
			if clean_id != "":
				_artist_gift_counts[clean_id] = int(counts[artist_id])

func _fail(reason: String) -> Dictionary:
	return {"success": false, "reason": reason}
