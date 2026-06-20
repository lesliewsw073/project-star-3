extends Node

## 互動事件執行中樞。
## UI / 對話 / 週日會議只需要丟 InteractionEventResource 進來，
## 好感、金錢、聲望、flag、新聞都由這裡統一套用。
##
## 重要原則：
## - 不直接修改其它 Manager 的內部字典，只呼叫公開接口。
## - 先做資金預檢，避免「好感已加、錢卻不夠扣」的半套用狀態。
## - 第一版 flag 先收在本 Manager，未來若拆 StoryFlagManager，可只改這裡。

signal interaction_executed(event_id: String, result: Dictionary)
signal interaction_failed(event_id: String, reason: String)
signal interaction_flags_changed()

var interaction_flags: Dictionary = {}
var executed_event_ids: Dictionary = {}

func _ready() -> void:
	print("[InteractionManager] 就绪，互动事件中枢上线。")

# ==========================================
# 核心執行入口
# ==========================================
func execute_event(event: InteractionEventResource) -> Dictionary:
	var validation_error: String = _validate_event(event)
	if validation_error != "":
		return _fail(_get_event_id(event), validation_error)

	var event_id: String = event.event_id.strip_edges()
	if event.execute_once and has_executed(event_id):
		return _fail(event_id, "事件已执行过，不能重复执行。")

	var money_cost: int = maxi(-event.money_delta, 0)
	if money_cost > 0 and not PlayerManager.can_afford(money_cost):
		return _fail(event_id, "资金不足，无法执行互动事件。")

	var result: Dictionary = _build_base_result(event)

	_apply_relationship_change(event, result)
	_apply_money_change(event, result)
	_apply_reputation_change(event, result)
	_apply_public_opinion_change(event, result)
	_apply_flag_changes(event, result)
	_apply_news(event, result)

	if event.execute_once:
		executed_event_ids[event_id] = true

	interaction_executed.emit(event_id, result)
	return result

func can_execute_event(event: InteractionEventResource) -> bool:
	return get_execution_block_reason(event) == ""

func get_execution_block_reason(event: InteractionEventResource) -> String:
	var validation_error: String = _validate_event(event)
	if validation_error != "":
		return validation_error

	if event.execute_once and has_executed(event.event_id):
		return "事件已执行过，不能重复执行。"

	var money_cost: int = maxi(-event.money_delta, 0)
	if money_cost > 0 and not PlayerManager.can_afford(money_cost):
		return "资金不足，无法执行互动事件。"

	return ""

# ==========================================
# flag / 狀態查詢
# ==========================================
func has_executed(event_id: String) -> bool:
	return executed_event_ids.has(event_id.strip_edges())

func get_flag(flag_id: String, default_value: Variant = false) -> Variant:
	return interaction_flags.get(flag_id, default_value)

func set_flag(flag_id: String, value: Variant) -> void:
	var clean_flag_id: String = flag_id.strip_edges()
	if clean_flag_id == "":
		return
	interaction_flags[clean_flag_id] = value
	interaction_flags_changed.emit()

func clear_flags() -> void:
	interaction_flags.clear()
	interaction_flags_changed.emit()

# ==========================================
# 套用效果
# ==========================================
func _apply_relationship_change(event: InteractionEventResource, result: Dictionary) -> void:
	if int(event.affection_settlement) == InteractionEventResource.AffectionSettlement.NONE:
		return

	if not event.affection_targets.is_empty():
		_apply_affection_targets(event, result)
		return

	var character_id: String = event.character_id.strip_edges()
	if character_id == "" or event.affection_delta == 0:
		return

	_apply_single_affection_change(character_id, event.affection_delta, result)

func _apply_affection_targets(event: InteractionEventResource, result: Dictionary) -> void:
	var changes: Array = []
	for target_id in event.affection_targets:
		var clean_id: String = str(target_id).strip_edges()
		if clean_id == "":
			continue
		var delta: int = int(event.affection_targets[target_id])
		if delta == 0:
			continue
		var change: Dictionary = _apply_single_affection_change(clean_id, delta, {})
		if not change.is_empty():
			changes.append(change)

	if changes.is_empty():
		return

	result["relationship_changed"] = true
	result["affection_changes"] = changes
	if changes.size() == 1:
		var only: Dictionary = changes[0]
		result["character_id"] = only.get("character_id", "")
		result["old_affection"] = only.get("old_affection", 0)
		result["new_affection"] = only.get("new_affection", 0)
		result["affection_delta_applied"] = only.get("affection_delta_applied", 0)
		result["relationship_level"] = only.get("relationship_level", "")

func _apply_single_affection_change(
	character_id: String,
	delta: int,
	result: Dictionary
) -> Dictionary:
	var clean_id: String = character_id.strip_edges()
	if clean_id == "" or delta == 0:
		return {}

	var old_affection: int = RelationshipManager.get_affection(clean_id)
	RelationshipManager.add_affection(clean_id, delta)
	var new_affection: int = RelationshipManager.get_affection(clean_id)

	var change: Dictionary = {
		"character_id": clean_id,
		"old_affection": old_affection,
		"new_affection": new_affection,
		"affection_delta_applied": new_affection - old_affection,
		"relationship_level": RelationshipManager.get_relationship_level_name(clean_id),
	}

	if not result.is_empty():
		result["relationship_changed"] = true
		result["character_id"] = clean_id
		result["old_affection"] = old_affection
		result["new_affection"] = new_affection
		result["affection_delta_applied"] = new_affection - old_affection
		result["relationship_level"] = change["relationship_level"]

	return change

func _apply_money_change(event: InteractionEventResource, result: Dictionary) -> void:
	if event.money_delta > 0:
		PlayerManager.add_money(event.money_delta, event.event_title)
	elif event.money_delta < 0:
		PlayerManager.spend_money(-event.money_delta, event.event_title)
	else:
		return

	result["money_changed"] = true
	result["money_delta_applied"] = event.money_delta
	result["current_money"] = PlayerManager.money

func _apply_reputation_change(event: InteractionEventResource, result: Dictionary) -> void:
	if event.reputation_delta > 0:
		PlayerManager.add_reputation(event.reputation_delta, event.event_title)
	elif event.reputation_delta < 0:
		PlayerManager.reduce_reputation(-event.reputation_delta, event.event_title)
	else:
		return

	result["reputation_changed"] = true
	result["reputation_delta_applied"] = event.reputation_delta
	result["current_reputation"] = PlayerManager.company_reputation

func _apply_public_opinion_change(event: InteractionEventResource, result: Dictionary) -> void:
	if event.public_opinion_delta > 0:
		PlayerManager.add_public_opinion(event.public_opinion_delta, event.event_title)
	elif event.public_opinion_delta < 0:
		PlayerManager.reduce_public_opinion(-event.public_opinion_delta, event.event_title)
	else:
		return

	result["public_opinion_changed"] = true
	result["public_opinion_delta_applied"] = event.public_opinion_delta
	result["current_public_opinion"] = PlayerManager.company_public_opinion

func _apply_flag_changes(event: InteractionEventResource, result: Dictionary) -> void:
	if event.flag_changes.is_empty():
		return

	var applied_flags: Dictionary = {}
	for flag_id in event.flag_changes:
		var clean_flag_id: String = str(flag_id).strip_edges()
		if clean_flag_id == "":
			continue
		var value: Variant = event.flag_changes[flag_id]
		interaction_flags[clean_flag_id] = value
		applied_flags[clean_flag_id] = value

	if applied_flags.is_empty():
		return

	result["flags_changed"] = true
	result["applied_flags"] = applied_flags
	interaction_flags_changed.emit()

func _apply_news(event: InteractionEventResource, result: Dictionary) -> void:
	if not event.generate_news:
		return

	var title: String = event.news_title.strip_edges()
	if title == "":
		title = event.event_title.strip_edges()
	if title == "":
		title = "未命名互动事件"

	var body: String = event.news_body.strip_edges()
	if body == "":
		body = event.result_text.strip_edges()
	if body == "":
		body = event.description.strip_edges()

	var news_item: Dictionary = NewsManager.add_news(
		title,
		body,
		event.news_media_type,
		event.news_category,
		event.news_importance,
		event.character_id,
		event.related_company_id,
		event.related_job_id
	)

	result["news_generated"] = not news_item.is_empty()
	result["news_item"] = news_item

# ==========================================
# 結果與驗證
# ==========================================
func _validate_event(event: InteractionEventResource) -> String:
	if event == null:
		return "互动事件为空。"
	if event.event_id.strip_edges() == "":
		return "互动事件缺少 event_id。"
	return ""

func _build_base_result(event: InteractionEventResource) -> Dictionary:
	return {
		"success": true,
		"event_id": event.event_id,
		"event_title": event.event_title,
		"interaction_type": event.interaction_type,
		"character_id": event.character_id,
		"result_text": event.result_text,
		"relationship_changed": false,
		"money_changed": false,
		"reputation_changed": false,
		"public_opinion_changed": false,
		"flags_changed": false,
		"news_generated": false,
	}

func _fail(event_id: String, reason: String) -> Dictionary:
	var result: Dictionary = {
		"success": false,
		"event_id": event_id,
		"reason": reason,
	}
	interaction_failed.emit(event_id, reason)
	push_warning("[InteractionManager] %s" % reason)
	return result

func _get_event_id(event: InteractionEventResource) -> String:
	if event == null:
		return ""
	return event.event_id

func export_save_state() -> Dictionary:
	return {
		"flags": interaction_flags.duplicate(true),
		"executed_event_ids": executed_event_ids.duplicate(true),
	}

func import_save_state(data: Dictionary) -> void:
	interaction_flags.clear()
	executed_event_ids.clear()
	if data == null:
		return

	var flags: Variant = data.get("flags", {})
	if flags is Dictionary:
		for flag_id in flags:
			var clean_flag_id: String = str(flag_id).strip_edges()
			if clean_flag_id == "":
				continue
			interaction_flags[clean_flag_id] = flags[flag_id]

	var executed: Variant = data.get("executed_event_ids", {})
	if executed is Dictionary:
		for event_id in executed:
			var clean_event_id: String = str(event_id).strip_edges()
			if clean_event_id == "":
				continue
			executed_event_ids[clean_event_id] = bool(executed[event_id])
