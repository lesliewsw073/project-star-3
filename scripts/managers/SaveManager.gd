extends Node

## Save v1 編排：手動槽 1～5、自動槽 A/B（週末輪流覆寫）。
## 路徑：user://saves/slot_{n}.json、auto_slot_{n}.json

signal save_finished(kind: int, slot_index: int, success: bool, message: String)
signal load_finished(kind: int, slot_index: int, success: bool, message: String)

enum SlotKind { MANUAL, AUTO }

const SAVE_VERSION: int = 1
const SAVES_DIR: String = "user://saves/"
const AUTO_ROTATE_PATH: String = "user://saves/auto_rotate.json"
const MANUAL_SLOT_COUNT: int = 5
const AUTO_SLOT_COUNT: int = 2
const ROSTER_PREVIEW_SLOTS: int = 4

var _last_auto_save_week_token: String = ""

func _ready() -> void:
	_ensure_saves_dir()
	print("[SaveManager] 就绪：手動 %d 槽 + 自動 %d 槽。" % [MANUAL_SLOT_COUNT, AUTO_SLOT_COUNT])

func _ensure_saves_dir() -> void:
	DirAccess.make_dir_recursive_absolute(SAVES_DIR)

func get_manual_slot_path(slot: int) -> String:
	return "%sslot_%d.json" % [SAVES_DIR, clampi(slot, 1, MANUAL_SLOT_COUNT)]

func get_auto_slot_path(slot: int) -> String:
	return "%sauto_slot_%d.json" % [SAVES_DIR, clampi(slot, 0, AUTO_SLOT_COUNT - 1)]

func resolve_slot_path(kind: int, slot_index: int) -> String:
	if kind == SlotKind.AUTO:
		return get_auto_slot_path(slot_index)
	return get_manual_slot_path(slot_index)

func slot_exists(kind: int, slot_index: int) -> bool:
	return FileAccess.file_exists(resolve_slot_path(kind, slot_index))

## 相容舊接口：手動槽 1
func get_slot_path(slot: int) -> String:
	return get_manual_slot_path(slot)

func build_save_payload(kind: int, slot_index: int) -> Dictionary:
	var signed_ids: Array[String] = []
	for artist_id in ArtistManager.get_signed_ids():
		signed_ids.append(str(artist_id))
	return {
		"save_version": SAVE_VERSION,
		"meta": {
			"saved_at_unix": Time.get_unix_time_from_system(),
			"slot_kind": "auto" if kind == SlotKind.AUTO else "manual",
			"slot_index": slot_index,
			"display_date": TimeManager.get_display_text(),
			"company_name": PlayerManager.get_company_name(),
			"signed_artist_ids": signed_ids,
		},
		"time": TimeManager.export_save_state(),
		"flow": GameFlowManager.export_save_state(),
		"protagonist": ProtagonistManager.export_save_state(),
		"player": PlayerManager.export_save_state(),
		"relationships": RelationshipManager.export_save_state(),
		"roster": ArtistManager.export_save_state(),
		"schedules": ScheduleManager.export_save_state(),
		"follow_plan": FollowPlanManager.export_save_state(),
		"jobs": JobManager.export_save_state(),
		"interaction": InteractionManager.export_save_state(),
		"inventory": InventoryManager.export_save_state(),
		"company_items": CompanyItemManager.export_save_state(),
		"player_home": PlayerHomeManager.export_save_state(),
		"news": NewsManager.export_save_state(),
		"unlocks": {
			"gigs": GigManager.export_save_state(),
			"courses": CourseManager.export_save_state(),
			"vacations": VacationManager.export_save_state(),
		},
	}

func peek_slot_summary(kind: int, slot_index: int) -> Dictionary:
	var summary: Dictionary = {
		"kind": kind,
		"slot_index": slot_index,
		"empty": true,
		"saved_at_text": "—",
		"game_date_text": "—",
		"company_name": "—",
		"signed_artist_ids": PackedStringArray(),
	}
	var path: String = resolve_slot_path(kind, slot_index)
	if not FileAccess.file_exists(path):
		return summary

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return summary
	var json_text: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_text) != OK or not (json.data is Dictionary):
		return summary

	var payload: Dictionary = json.data
	var meta: Dictionary = payload.get("meta", {})
	summary["empty"] = false
	summary["saved_at_text"] = format_saved_at_unix(int(meta.get("saved_at_unix", 0)))
	summary["game_date_text"] = str(meta.get("display_date", "—"))
	summary["company_name"] = str(meta.get("company_name", "—"))

	var artist_ids: PackedStringArray = PackedStringArray()
	var meta_ids: Variant = meta.get("signed_artist_ids", [])
	if meta_ids is Array:
		for artist_id in meta_ids:
			artist_ids.append(str(artist_id))
	elif payload.get("roster", {}) is Dictionary:
		for artist_id in payload["roster"].keys():
			artist_ids.append(str(artist_id))
	summary["signed_artist_ids"] = artist_ids
	return summary

func get_all_slot_summaries() -> Dictionary:
	var auto_rows: Array[Dictionary] = []
	for index in range(AUTO_SLOT_COUNT):
		auto_rows.append(peek_slot_summary(SlotKind.AUTO, index))
	var manual_rows: Array[Dictionary] = []
	for slot in range(1, MANUAL_SLOT_COUNT + 1):
		manual_rows.append(peek_slot_summary(SlotKind.MANUAL, slot))
	return {"auto": auto_rows, "manual": manual_rows}

func format_saved_at_unix(unix_time: int) -> String:
	if unix_time <= 0:
		return "—"
	var dt: Dictionary = Time.get_datetime_dict_from_unix_time(unix_time)
	return "%04d-%02d-%02d %02d:%02d" % [
		int(dt.get("year", 0)),
		int(dt.get("month", 0)),
		int(dt.get("day", 0)),
		int(dt.get("hour", 0)),
		int(dt.get("minute", 0)),
	]

func save_slot(kind: int, slot_index: int) -> Dictionary:
	if kind == SlotKind.AUTO:
		var reason: String = "自動存檔槽僅由系統於週日會議寫入，無法手動存檔。"
		save_finished.emit(SlotKind.AUTO, slot_index, false, reason)
		return {"success": false, "reason": reason}
	return _save_manual_slot(slot_index)

func can_player_save_to_slot(kind: int) -> bool:
	return kind == SlotKind.MANUAL

func save_to_slot(slot: int = 1) -> Dictionary:
	return save_slot(SlotKind.MANUAL, clampi(slot, 1, MANUAL_SLOT_COUNT))

func _save_manual_slot(slot: int) -> Dictionary:
	var safe_slot: int = clampi(slot, 1, MANUAL_SLOT_COUNT)
	if not can_save():
		var reason: String = "僅週日會議期間可以存檔。"
		save_finished.emit(SlotKind.MANUAL, safe_slot, false, reason)
		return {"success": false, "reason": reason}
	return _write_payload_to_path(SlotKind.MANUAL, safe_slot)

func _save_auto_slot(slot_index: int) -> Dictionary:
	var safe_index: int = clampi(slot_index, 0, AUTO_SLOT_COUNT - 1)
	return _write_payload_to_path(SlotKind.AUTO, safe_index)

func _write_payload_to_path(kind: int, slot_index: int) -> Dictionary:
	_ensure_saves_dir()
	var path: String = resolve_slot_path(kind, slot_index)
	var payload: Dictionary = build_save_payload(kind, slot_index)
	var json_text: String = JSON.stringify(payload, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var reason: String = "無法寫入存檔：%s" % path
		save_finished.emit(kind, slot_index, false, reason)
		return {"success": false, "reason": reason}
	file.store_string(json_text)
	file.close()

	var label: String = _slot_label(kind, slot_index)
	var message: String = "存檔成功：%s" % label
	print("[SaveManager] ", message)
	save_finished.emit(kind, slot_index, true, message)
	return {"success": true, "path": path, "message": message, "kind": kind, "slot_index": slot_index}

func load_slot(kind: int, slot_index: int) -> Dictionary:
	return _load_from_path(kind, slot_index)

func load_from_slot(slot: int = 1) -> Dictionary:
	return load_slot(SlotKind.MANUAL, clampi(slot, 1, MANUAL_SLOT_COUNT))

func _load_from_path(kind: int, slot_index: int) -> Dictionary:
	var path: String = resolve_slot_path(kind, slot_index)
	if not FileAccess.file_exists(path):
		var reason: String = "存檔不存在：%s" % _slot_label(kind, slot_index)
		load_finished.emit(kind, slot_index, false, reason)
		return {"success": false, "reason": reason}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		var reason: String = "無法讀取存檔：%s" % path
		load_finished.emit(kind, slot_index, false, reason)
		return {"success": false, "reason": reason}

	var json_text: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(json_text) != OK:
		var reason: String = "存檔 JSON 解析失敗（%s）。" % json.get_error_message()
		load_finished.emit(kind, slot_index, false, reason)
		return {"success": false, "reason": reason}
	if not (json.data is Dictionary):
		var reason: String = "存檔格式錯誤：根節點不是物件。"
		load_finished.emit(kind, slot_index, false, reason)
		return {"success": false, "reason": reason}

	var result: Dictionary = load_from_payload(json.data, kind, slot_index)
	if result.get("success", false):
		load_finished.emit(kind, slot_index, true, str(result.get("message", "")))
	else:
		load_finished.emit(kind, slot_index, false, str(result.get("reason", "")))
	return result

func can_save() -> bool:
	return GameFlowManager.can_save_game()

func can_load() -> bool:
	return true

func try_weekly_auto_save(date_snapshot: Dictionary) -> Dictionary:
	if GameFlowManager.game_phase != GameFlowManager.GamePhase.WEEKLY_MEETING:
		return {"success": false, "skipped": true, "reason": "not_weekly_meeting"}
	var year: int = int(date_snapshot.get("year", 0))
	var month: int = int(date_snapshot.get("month", 0))
	var week: int = int(date_snapshot.get("week", 0))
	var token: String = "%d-%02d-%02d" % [year, month, week]
	if token == _last_auto_save_week_token:
		return {"success": false, "skipped": true, "reason": "already_saved_this_week"}

	var rotate_index: int = _read_auto_rotate_index()
	var result: Dictionary = _save_auto_slot(rotate_index)
	if not result.get("success", false):
		return result

	_write_auto_rotate_index((rotate_index + 1) % AUTO_SLOT_COUNT)
	_last_auto_save_week_token = token
	result["auto_slot_index"] = rotate_index
	result["skipped"] = false
	return result

func _read_auto_rotate_index() -> int:
	if not FileAccess.file_exists(AUTO_ROTATE_PATH):
		return 0
	var file := FileAccess.open(AUTO_ROTATE_PATH, FileAccess.READ)
	if file == null:
		return 0
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not (json.data is Dictionary):
		file.close()
		return 0
	file.close()
	return clampi(int(json.data.get("next_index", 0)), 0, AUTO_SLOT_COUNT - 1)

func _write_auto_rotate_index(next_index: int) -> void:
	_ensure_saves_dir()
	var file := FileAccess.open(AUTO_ROTATE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"next_index": clampi(next_index, 0, AUTO_SLOT_COUNT - 1)}, "\t"))
	file.close()

func get_slot_display_name(kind: int, slot_index: int) -> String:
	return _slot_label(kind, slot_index)

func _slot_label(kind: int, slot_index: int) -> String:
	if kind == SlotKind.AUTO:
		return "自動存檔 %s" % ("A" if slot_index == 0 else "B")
	return "手動槽 %d" % slot_index

func load_from_payload(payload: Dictionary, kind: int = SlotKind.MANUAL, slot_index: int = 1) -> Dictionary:
	var migrated: Dictionary
	var migrate_err: String = _try_migrate_payload(payload, migrated)
	if migrate_err != "":
		return {"success": false, "reason": migrate_err}

	TimeManager.import_save_state(migrated.get("time", {}))
	ProtagonistManager.import_save_state(migrated.get("protagonist", {}))
	PlayerManager.import_save_state(migrated.get("player", {}))
	RelationshipManager.import_save_state(migrated.get("relationships", {}))
	JobManager.import_save_state(migrated.get("jobs", {}))
	ArtistManager.import_save_state(migrated.get("roster", {}))
	ScheduleManager.import_save_state(migrated.get("schedules", {}))
	FollowPlanManager.import_save_state(migrated.get("follow_plan", {}))
	InteractionManager.import_save_state(migrated.get("interaction", {}))
	InventoryManager.import_save_state(migrated.get("inventory", {}))
	CompanyItemManager.import_save_state(migrated.get("company_items", {}))
	PlayerHomeManager.import_save_state(migrated.get("player_home", {}))
	NewsManager.import_save_state(migrated.get("news", {}))
	var unlocks: Dictionary = migrated.get("unlocks", {})
	if unlocks is Dictionary:
		GigManager.import_save_state(unlocks.get("gigs", []))
		CourseManager.import_save_state(unlocks.get("courses", []))
		VacationManager.import_save_state(unlocks.get("vacations", {}))
	GameFlowManager.import_save_state(migrated.get("flow", {}))

	JobManager.refresh_job_board()

	var message: String = "讀檔成功（%s，%s）。" % [
		_slot_label(kind, slot_index),
		str(migrated.get("meta", {}).get("display_date", "未知日期")),
	]
	print("[SaveManager] ", message)
	return {
		"success": true,
		"message": message,
		"payload": migrated,
		"kind": kind,
		"slot_index": slot_index,
	}

func _try_migrate_payload(source: Dictionary, out_payload: Dictionary) -> String:
	if source.is_empty():
		return "存檔為空。"

	var payload: Dictionary = source.duplicate(true)
	var version: int = int(payload.get("save_version", 0))

	if version == 0:
		payload["save_version"] = SAVE_VERSION
		if not payload.has("inventory"):
			payload["inventory"] = {}
		version = SAVE_VERSION

	if version == SAVE_VERSION:
		if not payload.has("inventory"):
			payload["inventory"] = {}
		if not payload.has("company_items"):
			payload["company_items"] = {}
		if not payload.has("player_home"):
			payload["player_home"] = {}
		var player: Variant = payload.get("player", {})
		if player is Dictionary and not player.has("company_public_opinion"):
			player["company_public_opinion"] = 0
			payload["player"] = player
		var meta: Variant = payload.get("meta", {})
		if meta is Dictionary:
			if not meta.has("company_name"):
				meta["company_name"] = PlayerManager.get_company_name()
			if not meta.has("signed_artist_ids"):
				var roster: Variant = payload.get("roster", {})
				var ids: Array = []
				if roster is Dictionary:
					for artist_id in roster.keys():
						ids.append(str(artist_id))
				meta["signed_artist_ids"] = ids
			payload["meta"] = meta

	if version > SAVE_VERSION:
		return "存檔版本過新：%d > %d，請更新遊戲。" % [version, SAVE_VERSION]

	if version != SAVE_VERSION:
		return "不支援的存檔版本：%d。" % version

	out_payload.clear()
	for key in payload:
		out_payload[key] = payload[key]
	return ""
