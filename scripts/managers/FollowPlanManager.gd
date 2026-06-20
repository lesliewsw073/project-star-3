extends Node

## 跟随计划：周日会议一次勾选整周，会议结束提交为本周正式表。
## 规则：休息/度假不可跟随；同一天默认只跟一组；同 gig/course/job_id 自动合并。

signal follow_plan_changed()

const DAYS_PER_WEEK: int = 7

## 下周跟随草稿：artist_id -> Array[bool x7]
var next_week_follow_drafts: Dictionary = {}
## 本周正式跟随：artist_id -> Array[bool x7]
var current_week_follows: Dictionary = {}

var _is_mutating: bool = false

func _ready() -> void:
	if not ArtistManager.artist_signed.is_connected(_on_artist_signed):
		ArtistManager.artist_signed.connect(_on_artist_signed)
	if not ArtistManager.artist_terminated.is_connected(_on_artist_terminated):
		ArtistManager.artist_terminated.connect(_on_artist_terminated)
	print("[FollowPlanManager] 就绪。")

func can_follow_slot(slot: Dictionary) -> bool:
	var schedule_type: int = int(slot.get("type", ScheduleManager.ScheduleType.ROUTINE_EMPTY))
	if schedule_type in [
		ScheduleManager.ScheduleType.ROUTINE_REST,
		ScheduleManager.ScheduleType.ROUTINE_EMPTY,
		ScheduleManager.ScheduleType.ROUTINE_CREATION,
		ScheduleManager.ScheduleType.VACATION_DOMESTIC,
		ScheduleManager.ScheduleType.VACATION_OVERSEAS,
	]:
		return false
	if schedule_type in [
		ScheduleManager.ScheduleType.GIG,
		ScheduleManager.ScheduleType.COURSE,
		ScheduleManager.ScheduleType.WORK_LOCAL,
		ScheduleManager.ScheduleType.WORK_OVERSEAS,
	]:
		return get_slot_task_signature(slot) != ""
	return false

func get_slot_task_signature(slot: Dictionary) -> String:
	## 只读任务 ID，禁止调用 can_follow_slot（否则会与 can_follow_slot 互递归栈溢出）。
	var schedule_type: int = int(slot.get("type", ScheduleManager.ScheduleType.ROUTINE_EMPTY))
	var task_data = slot.get("task_data")

	if schedule_type in [
		ScheduleManager.ScheduleType.WORK_LOCAL,
		ScheduleManager.ScheduleType.WORK_OVERSEAS,
	] and task_data is JobInstance:
		return "job:%s" % task_data.base_job.job_id
	if schedule_type == ScheduleManager.ScheduleType.GIG and task_data is GigResource:
		return "gig:%s" % task_data.gig_id
	if schedule_type == ScheduleManager.ScheduleType.COURSE and task_data is CourseResource:
		return "course:%s" % task_data.course_id
	return ""

func is_follow_enabled(artist_id: String, day_index: int, use_draft: bool = true) -> bool:
	if not _is_valid_day(day_index) or not ArtistManager.is_signed(artist_id):
		return false
	var store: Dictionary = _get_store(use_draft)
	if not store.has(artist_id):
		return false
	var week: Array = store[artist_id]
	return bool(week[day_index])

func set_follow_enabled(artist_id: String, day_index: int, enabled: bool, use_draft: bool = true) -> bool:
	if _is_mutating:
		push_warning("[FollowPlanManager] 重入拦截：set_follow_enabled 正在执行中。")
		return false
	if not _is_valid_day(day_index) or not ArtistManager.is_signed(artist_id):
		return false

	var slot: Dictionary = _get_schedule_slot(artist_id, day_index, use_draft)
	if enabled and not can_follow_slot(slot):
		return false

	_is_mutating = true
	var store: Dictionary = _get_store(use_draft)
	if enabled:
		var signature: String = get_slot_task_signature(slot)
		if signature == "":
			_is_mutating = false
			return false
		for signed_id in ArtistManager.get_signed_ids():
			var signed_artist_id: String = str(signed_id)
			_ensure_week(store, signed_artist_id)
			var other_slot: Dictionary = _get_schedule_slot(signed_artist_id, day_index, use_draft)
			store[signed_artist_id][day_index] = (
				get_slot_task_signature(other_slot) == signature
				and can_follow_slot(other_slot)
			)
	else:
		_ensure_week(store, artist_id)
		var signature: String = get_slot_task_signature(slot)
		if signature == "":
			store[artist_id][day_index] = false
		else:
			for signed_id in ArtistManager.get_signed_ids():
				var signed_artist_id: String = str(signed_id)
				_ensure_week(store, signed_artist_id)
				var other_slot: Dictionary = _get_schedule_slot(signed_artist_id, day_index, use_draft)
				if get_slot_task_signature(other_slot) == signature:
					store[signed_artist_id][day_index] = false

	if use_draft:
		sanitize_draft_follows()
	else:
		sanitize_current_follows()
	_is_mutating = false
	follow_plan_changed.emit()
	return true

func toggle_follow(artist_id: String, day_index: int, use_draft: bool = true) -> bool:
	var next_enabled: bool = not is_follow_enabled(artist_id, day_index, use_draft)
	return set_follow_enabled(artist_id, day_index, next_enabled, use_draft)

func get_follow_artist_ids_for_day(day_index: int, use_draft: bool = false) -> Array[String]:
	var result: Array[String] = []
	if not _is_valid_day(day_index):
		return result

	for signed_id in ArtistManager.get_signed_ids():
		var artist_id: String = str(signed_id)
		if is_follow_enabled(artist_id, day_index, use_draft):
			result.append(artist_id)

	result.sort_custom(func(a: String, b: String) -> bool:
		return _compare_follow_priority(a, b)
	)
	return result

func get_today_follow_artist_ids() -> Array[String]:
	return get_follow_artist_ids_for_day(TimeManager.day_index, false)

func has_follow_today() -> bool:
	return not get_today_follow_artist_ids().is_empty()

func sanitize_draft_follows() -> void:
	_sanitize_store(next_week_follow_drafts, true)

func sanitize_current_follows() -> void:
	_sanitize_store(current_week_follows, false)

func commit_next_week_follow_plan() -> int:
	current_week_follows.clear()
	var committed_count: int = 0
	for signed_id in ArtistManager.get_signed_ids():
		var artist_id: String = str(signed_id)
		if next_week_follow_drafts.has(artist_id):
			current_week_follows[artist_id] = _duplicate_bool_week(next_week_follow_drafts[artist_id])
		else:
			current_week_follows[artist_id] = _make_empty_bool_week()
		committed_count += 1

	next_week_follow_drafts.clear()
	follow_plan_changed.emit()
	print("[FollowPlanManager] 下周跟随计划已提交，共 %d 位艺人。" % committed_count)
	return committed_count

func clear_artist(artist_id: String) -> void:
	next_week_follow_drafts.erase(artist_id)
	current_week_follows.erase(artist_id)

func export_save_state() -> Dictionary:
	return {
		"current_week": _export_bool_store(current_week_follows),
		"next_draft": _export_bool_store(next_week_follow_drafts),
	}

func import_save_state(data: Dictionary) -> void:
	current_week_follows.clear()
	next_week_follow_drafts.clear()
	if data == null:
		return

	var current_week: Variant = data.get("current_week", {})
	if current_week is Dictionary:
		for artist_id in current_week:
			current_week_follows[artist_id] = _import_bool_week(current_week[artist_id])

	var next_draft: Variant = data.get("next_draft", {})
	if next_draft is Dictionary:
		for artist_id in next_draft:
			next_week_follow_drafts[artist_id] = _import_bool_week(next_draft[artist_id])

	sanitize_draft_follows()
	sanitize_current_follows()
	follow_plan_changed.emit()

func _on_artist_signed(artist_id: String) -> void:
	_ensure_week(next_week_follow_drafts, artist_id)
	_ensure_week(current_week_follows, artist_id)

func _on_artist_terminated(artist_id: String) -> void:
	clear_artist(artist_id)
	follow_plan_changed.emit()

func _sanitize_store(store: Dictionary, use_draft: bool) -> void:
	for signed_id in ArtistManager.get_signed_ids():
		var artist_id: String = str(signed_id)
		_ensure_week(store, artist_id)
		for day_index in range(DAYS_PER_WEEK):
			if not bool(store[artist_id][day_index]):
				continue
			var slot: Dictionary = _get_schedule_slot(artist_id, day_index, use_draft)
			if not can_follow_slot(slot):
				store[artist_id][day_index] = false

func _get_schedule_slot(artist_id: String, day_index: int, use_draft: bool) -> Dictionary:
	var week: Array
	if use_draft:
		week = ScheduleManager.get_draft_week(artist_id)
	else:
		week = ScheduleManager.get_week(artist_id)
	return week[day_index]

func _get_store(use_draft: bool) -> Dictionary:
	return next_week_follow_drafts if use_draft else current_week_follows

func _compare_follow_priority(artist_id_a: String, artist_id_b: String) -> bool:
	var affection_a: int = RelationshipManager.get_affection(artist_id_a)
	var affection_b: int = RelationshipManager.get_affection(artist_id_b)
	if affection_a != affection_b:
		return affection_a > affection_b
	return artist_id_a < artist_id_b

func _ensure_week(store: Dictionary, artist_id: String) -> void:
	if not store.has(artist_id):
		store[artist_id] = _make_empty_bool_week()

func _make_empty_bool_week() -> Array:
	var week: Array = []
	for _i in range(DAYS_PER_WEEK):
		week.append(false)
	return week

func _duplicate_bool_week(week: Array) -> Array:
	var copied: Array = []
	for day_index in range(mini(week.size(), DAYS_PER_WEEK)):
		copied.append(bool(week[day_index]))
	while copied.size() < DAYS_PER_WEEK:
		copied.append(false)
	return copied

func _export_bool_store(store: Dictionary) -> Dictionary:
	var payload: Dictionary = {}
	for artist_id in store:
		payload[artist_id] = _duplicate_bool_week(store[artist_id])
	return payload

func _import_bool_week(week_data: Variant) -> Array:
	var week: Array = _make_empty_bool_week()
	if not (week_data is Array):
		return week
	for day_index in range(mini(week_data.size(), DAYS_PER_WEEK)):
		week[day_index] = bool(week_data[day_index])
	return week

func _is_valid_day(day_index: int) -> bool:
	return day_index >= 0 and day_index < DAYS_PER_WEEK
