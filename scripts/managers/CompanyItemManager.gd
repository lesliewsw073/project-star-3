extends Node

## 公司物品：不進物品欄；購買後累積展示於會議室，聲望／口碑按「最高檔位邊際增量」結算。

signal company_items_changed()

var _owned_ids: Array[String] = []
var _applied_reputation_bonus: int = 0
var _applied_public_opinion_bonus: int = 0

func _ready() -> void:
	print("[CompanyItemManager] 就绪。")

func get_owned_ids() -> Array[String]:
	return _owned_ids.duplicate()

func owns(item_id: String) -> bool:
	return _owned_ids.has(item_id.strip_edges())

func get_meeting_display_keys() -> Array[String]:
	var keys: Array[String] = []
	for owned_id in _owned_ids:
		var item: ItemResource = ItemDatabase.get_item(owned_id)
		if item == null:
			continue
		var key: String = item.meeting_display_key.strip_edges()
		if key != "" and not keys.has(key):
			keys.append(key)
	return keys

func get_effective_reputation_bonus() -> int:
	return _max_bonus_among_owned("reputation")

func get_effective_public_opinion_bonus() -> int:
	return _max_bonus_among_owned("public_opinion")

func try_purchase(item_id: String) -> Dictionary:
	var item: ItemResource = ItemDatabase.get_item(item_id)
	if item == null:
		return _fail("未知道具：%s" % item_id)
	if int(item.item_category) != ItemResource.ItemCategory.COMPANY:
		return _fail("%s 不是公司物品。" % item_id)
	if owns(item_id):
		return _fail("已持有公司物品：%s" % item.item_name)

	if item.shop_price > 0 and not PlayerManager.spend_money(item.shop_price, "購買公司物品：%s" % item.item_name):
		return _fail("金幣不足。")

	_owned_ids.append(item.item_id)
	var delta: Dictionary = _apply_bonus_delta()
	company_items_changed.emit()
	return {
		"success": true,
		"item_id": item.item_id,
		"item_name": item.item_name,
		"reputation_delta": delta.get("reputation_delta", 0),
		"public_opinion_delta": delta.get("public_opinion_delta", 0),
		"meeting_display_key": item.meeting_display_key,
	}

func _apply_bonus_delta() -> Dictionary:
	var new_rep: int = get_effective_reputation_bonus()
	var new_opinion: int = get_effective_public_opinion_bonus()
	var rep_delta: int = new_rep - _applied_reputation_bonus
	var opinion_delta: int = new_opinion - _applied_public_opinion_bonus

	if rep_delta > 0:
		PlayerManager.add_reputation(rep_delta, "公司物品加成")
	if opinion_delta > 0:
		PlayerManager.add_public_opinion(opinion_delta, "公司物品加成")

	_applied_reputation_bonus = new_rep
	_applied_public_opinion_bonus = new_opinion
	return {
		"reputation_delta": rep_delta,
		"public_opinion_delta": opinion_delta,
	}

func _max_bonus_among_owned(kind: String) -> int:
	var best: int = 0
	for owned_id in _owned_ids:
		var item: ItemResource = ItemDatabase.get_item(owned_id)
		if item == null:
			continue
		var value: int = item.reputation_bonus if kind == "reputation" else item.public_opinion_bonus
		best = maxi(best, value)
	return best

func export_save_state() -> Dictionary:
	return {
		"owned_ids": _owned_ids.duplicate(),
		"applied_reputation_bonus": _applied_reputation_bonus,
		"applied_public_opinion_bonus": _applied_public_opinion_bonus,
	}

func import_save_state(data: Dictionary) -> void:
	_owned_ids.clear()
	_applied_reputation_bonus = 0
	_applied_public_opinion_bonus = 0
	if data == null:
		return

	var owned: Variant = data.get("owned_ids", [])
	if owned is Array:
		for entry in owned:
			var clean_id: String = str(entry).strip_edges()
			if clean_id != "" and ItemDatabase.has_item(clean_id):
				_owned_ids.append(clean_id)

	_applied_reputation_bonus = int(data.get("applied_reputation_bonus", 0))
	_applied_public_opinion_bonus = int(data.get("applied_public_opinion_bonus", 0))

func _fail(reason: String) -> Dictionary:
	return {"success": false, "reason": reason}
