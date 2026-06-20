extends Node

## 道具系統執行入口：購買、物品欄、贈送、劇情道具、月薪（占位）。

signal item_purchased(result: Dictionary)
signal item_gifted(result: Dictionary)
signal monthly_salary_processed(result: Dictionary)

const SALARY_PER_SIGNED_ARTIST: int = 5000 ## 占位；後續改為合約表

func _ready() -> void:
	print("[ItemManager] 就绪。")

# ==========================================
# 商店
# ==========================================
func get_shop_catalog() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for item_id in ItemDatabase.get_all_item_ids():
		var item: ItemResource = ItemDatabase.get_item(item_id)
		if item == null or item.shop_price <= 0:
			continue
		if int(item.item_category) == ItemResource.ItemCategory.ARTIST_GIFT:
			continue
		entries.append(_build_shop_entry(item))
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var cat_a: int = int(a.get("category", 0))
		var cat_b: int = int(b.get("category", 0))
		if cat_a != cat_b:
			return cat_a < cat_b
		return str(a.get("item_id", "")) < str(b.get("item_id", ""))
	)
	return entries

func can_purchase_from_shop(item_id: String) -> Dictionary:
	var item: ItemResource = ItemDatabase.get_item(item_id)
	if item == null:
		return {"ok": false, "reason": "未知道具。"}
	if item.shop_price <= 0:
		return {"ok": false, "reason": "%s 不可商店購買。" % item.item_name}
	if int(item.item_category) == ItemResource.ItemCategory.ARTIST_GIFT:
		return {"ok": false, "reason": "藝人贈禮不可購買。"}
	if int(item.item_category) == ItemResource.ItemCategory.COMPANY and CompanyItemManager.owns(item.item_id):
		return {"ok": false, "reason": "已持有公司物品：%s" % item.item_name}
	if not PlayerManager.can_afford(item.shop_price):
		return {"ok": false, "reason": "金幣不足。"}
	return {"ok": true, "reason": ""}

func _build_shop_entry(item: ItemResource) -> Dictionary:
	var category: int = int(item.item_category)
	var owned: bool = (
		category == ItemResource.ItemCategory.COMPANY
		and CompanyItemManager.owns(item.item_id)
	)
	var afford: bool = PlayerManager.can_afford(item.shop_price)
	var can_buy: bool = not owned and afford
	var block_reason: String = ""
	if owned:
		block_reason = "已持有"
	elif not afford:
		block_reason = "金幣不足"
	return {
		"item_id": item.item_id,
		"item_name": item.item_name,
		"shop_price": item.shop_price,
		"category": category,
		"description": item.description,
		"owned": owned,
		"bag_count": InventoryManager.get_count(item.item_id) if item.is_bag_item() else 0,
		"can_buy": can_buy,
		"block_reason": block_reason,
	}

# ==========================================
# 購買
# ==========================================
func try_purchase(item_id: String) -> Dictionary:
	var item: ItemResource = ItemDatabase.get_item(item_id)
	if item == null:
		return _fail("未知道具：%s" % item_id)

	match int(item.item_category):
		ItemResource.ItemCategory.COMPANY:
			var company_result: Dictionary = CompanyItemManager.try_purchase(item_id)
			if company_result.get("success", false):
				item_purchased.emit(company_result)
			return company_result
		ItemResource.ItemCategory.ATTRIBUTE, ItemResource.ItemCategory.STORY:
			if item.shop_price <= 0:
				return _fail("%s 不可商店購買。" % item.item_name)
			if not PlayerManager.spend_money(item.shop_price, "購買道具：%s" % item.item_name):
				return _fail("金幣不足。")
			var new_count: int = InventoryManager.add_item(item_id, 1)
			var result: Dictionary = {
				"success": true,
				"item_id": item.item_id,
				"item_name": item.item_name,
				"new_count": new_count,
				"category": int(item.item_category),
			}
			item_purchased.emit(result)
			return result
		ItemResource.ItemCategory.ARTIST_GIFT:
			return _fail("藝人贈禮只能由藝人贈送，不可購買。")
		_:
			return _fail("不支援的道具類別。")

# ==========================================
# 贈送（屬性／劇情）
# ==========================================
func try_gift_to_artist(item_id: String, artist_id: String) -> Dictionary:
	var item: ItemResource = ItemDatabase.get_item(item_id)
	if item == null:
		return _fail("未知道具：%s" % item_id)
	if not item.can_gift_to_signed_artist():
		return _fail("%s 不可贈送。" % item.item_name)

	var clean_artist: String = artist_id.strip_edges()
	if clean_artist == "":
		return _fail("缺少 artist_id。")
	if clean_artist == SecretaryManager.SECRETARY_ID:
		return _fail("秘書不可收禮；請透過談話、獲獎、公司規模與特定劇情提升好感。")
	if not ArtistManager.is_signed(clean_artist):
		return _fail("只能贈送給已簽約的我方藝人。")
	if not InventoryManager.has_item(item_id, 1):
		return _fail("物品欄沒有 %s。" % item.item_name)

	match int(item.item_category):
		ItemResource.ItemCategory.ATTRIBUTE:
			return _gift_attribute_item(item, clean_artist)
		ItemResource.ItemCategory.STORY:
			return _gift_story_item(item, clean_artist)
		_:
			return _fail("此道具不可贈送。")

func try_use_story_item(item_id: String, context: Dictionary = {}) -> Dictionary:
	var item: ItemResource = ItemDatabase.get_item(item_id)
	if item == null:
		return _fail("未知道具：%s" % item_id)
	if int(item.item_category) != ItemResource.ItemCategory.STORY:
		return _fail("%s 不是劇情道具。" % item.item_name)
	if not InventoryManager.has_item(item_id, 1):
		return _fail("物品欄沒有 %s。" % item.item_name)

	var event_id: String = item.story_use_event_id.strip_edges()
	if event_id == "":
		return _fail("劇情道具尚未綁定 story_use_event_id。")

	if not InventoryManager.try_consume(item_id, 1):
		return _fail("消耗道具失敗。")

	return {
		"success": true,
		"item_id": item.item_id,
		"story_use_event_id": event_id,
		"context": context.duplicate(true),
	}

# ==========================================
# 月薪（每月第一個週日會議）
# ==========================================
func try_process_monthly_salary() -> Dictionary:
	if not TimeManager.is_month_start():
		return {"success": false, "reason": "not_month_start", "skipped": true}

	var signed_ids: Array = ArtistManager.get_signed_ids()
	var total: int = signed_ids.size() * SALARY_PER_SIGNED_ARTIST
	if total <= 0:
		return {"success": true, "skipped": true, "total_salary": 0, "artist_count": 0}

	if not PlayerManager.spend_money(total, "每月藝人薪資"):
		return {
			"success": false,
			"reason": "insufficient_funds",
			"total_salary": total,
			"artist_count": signed_ids.size(),
		}

	var result: Dictionary = {
		"success": true,
		"total_salary": total,
		"artist_count": signed_ids.size(),
	}
	monthly_salary_processed.emit(result)
	return result

# ==========================================
# 內部
# ==========================================
func _gift_attribute_item(item: ItemResource, artist_id: String) -> Dictionary:
	var artist = ArtistManager.get_artist(artist_id)
	if artist == null:
		return _fail("找不到藝人：%s" % artist_id)
	if not InventoryManager.try_consume(item.item_id, 1):
		return _fail("消耗道具失敗。")

	var applied: Dictionary = artist.apply_attribute_item(item)
	var result: Dictionary = {
		"success": true,
		"item_id": item.item_id,
		"item_name": item.item_name,
		"artist_id": artist_id,
		"category": ItemResource.ItemCategory.ATTRIBUTE,
		"applied_changes": applied,
	}
	item_gifted.emit(result)
	return result

func _gift_story_item(item: ItemResource, artist_id: String) -> Dictionary:
	if not InventoryManager.try_consume(item.item_id, 1):
		return _fail("消耗道具失敗。")

	var event_id: String = item.gift_story_event_id.strip_edges()
	var result: Dictionary = {
		"success": true,
		"item_id": item.item_id,
		"item_name": item.item_name,
		"artist_id": artist_id,
		"category": ItemResource.ItemCategory.STORY,
		"gift_story_event_id": event_id,
	}
	item_gifted.emit(result)
	return result

func build_gift_effect_summary(item: ItemResource, artist_id: String = "") -> String:
	if item == null:
		return "（無道具資料）"

	var lines: PackedStringArray = PackedStringArray()
	if str(item.description).strip_edges() != "":
		lines.append(item.description.strip_edges())

	var effects: PackedStringArray = PackedStringArray()
	if item.add_fatigue != 0:
		effects.append("疲勞 %s" % _build_scaled_status_text(item.add_fatigue, artist_id, "fatigue"))
	if item.add_stress != 0:
		effects.append("壓力 %s" % _build_scaled_status_text(item.add_stress, artist_id, "stress"))
	if item.add_satisfaction != 0:
		effects.append("滿意度 %s" % _build_scaled_status_text(item.add_satisfaction, artist_id, "satisfaction"))
	if item.add_affection != 0:
		effects.append("好感 %+d" % item.add_affection)

	var stat_fields: Array[Dictionary] = [
		{"label": "同理", "delta": item.add_empathy},
		{"label": "音色", "delta": item.add_timbre},
		{"label": "即興", "delta": item.add_improvisation},
		{"label": "演技", "delta": item.add_acting},
		{"label": "歌藝", "delta": item.add_singing},
		{"label": "口才", "delta": item.add_eloquence},
		{"label": "動感", "delta": item.add_dynamism},
		{"label": "才華", "delta": item.add_talent},
		{"label": "體能", "delta": item.add_stamina},
		{"label": "儀態", "delta": item.add_deportment},
		{"label": "時尚", "delta": item.add_fashion},
		{"label": "自信", "delta": item.add_confidence},
		{"label": "叛逆", "delta": item.add_rebelliousness},
		{"label": "喜感", "delta": item.add_humor},
		{"label": "親和", "delta": item.add_affinity},
		{"label": "名氣", "delta": item.add_fame},
		{"label": "人氣", "delta": item.add_popularity},
		{"label": "曝光", "delta": item.add_exposure},
		{"label": "道德", "delta": item.add_morality},
	]
	for field in stat_fields:
		var delta: int = int(field["delta"])
		if delta != 0:
			effects.append("%s %+d" % [str(field["label"]), delta])

	if int(item.item_category) == ItemResource.ItemCategory.STORY:
		var gift_event: String = item.gift_story_event_id.strip_edges()
		if gift_event != "":
			lines.append("贈送後觸發劇情：%s" % gift_event)
		else:
			lines.append("劇情道具：贈送後消耗，不改能力值。")
	elif not effects.is_empty():
		lines.append("效果：" + "、".join(effects))
	else:
		lines.append("屬性道具：贈送後消耗。")

	return "\n".join(lines)

func _build_scaled_status_text(base_delta: int, artist_id: String, status_name: String) -> String:
	var scaled_delta: int = base_delta
	var artist: ArtistInstance = ArtistManager.get_artist(artist_id)
	if artist != null and artist.base_data != null:
		if status_name == "fatigue":
			scaled_delta = artist.base_data.scale_fatigue_delta(base_delta)
		elif status_name == "stress":
			scaled_delta = artist.base_data.scale_stress_delta(base_delta)
		elif status_name == "satisfaction":
			scaled_delta = artist.base_data.scale_satisfaction_delta(base_delta)

	var text: String = "%+d" % scaled_delta
	if scaled_delta != base_delta:
		text += "（基礎%+d）" % base_delta
	return text

func _fail(reason: String) -> Dictionary:
	return {"success": false, "reason": reason}
