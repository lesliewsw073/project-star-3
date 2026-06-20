extends Node

enum ScheduleType {
	WORK_LOCAL, WORK_OVERSEAS,
	EVENT_PROMO, EVENT_CONCERT, EVENT_FAN_MEET, EVENT_PREMIERE,
	GIG, COURSE,
	ROUTINE_CREATION, ROUTINE_REST, ROUTINE_EMPTY,
	VACATION_DOMESTIC, VACATION_OVERSEAS
}

enum LockState {
	UNLOCKED, LOCKED_WEEK, LOCKED_HARD
}

const DAYS_PER_WEEK: int = 7

## 本周正式行程表：artist_id -> Array[7 个 slot]
## 每天由 GameFlowManager 执行当天格子。
## slot = {"type": ScheduleType, "task_data": Resource/JobInstance/null, "lock_state": LockState}
var current_week_schedules: Dictionary = {}

## 下周草稿行程表：周日会议中编辑，会议结束时提交为下周正式表。
var next_week_drafts: Dictionary = {}

## 上次会议提交时的週计划快照（供「同上週」复制；current_week 执行后会逐格清空）。
var last_committed_week_schedules: Dictionary = {}

func _ready() -> void:
	if not ArtistManager.artist_terminated.is_connected(_on_artist_terminated):
		ArtistManager.artist_terminated.connect(_on_artist_terminated)
	print("[ScheduleManager] 就绪。")

func set_daily_schedule(artist_id: String, day_index: int, type: int, task_data = null) -> bool:
	if not _is_valid_day(day_index):
		return false
	if not ArtistManager.is_signed(artist_id):
		push_warning("[ScheduleManager] 排期失败：%s 尚未签约。" % artist_id)
		return false

	if type in [ScheduleType.WORK_OVERSEAS, ScheduleType.VACATION_DOMESTIC, ScheduleType.VACATION_OVERSEAS]:
		return _set_whole_week_schedule(current_week_schedules, artist_id, type, task_data)

	var week: Array = get_week(artist_id)
	if week[day_index]["lock_state"] != LockState.UNLOCKED:
		return false

	week[day_index]["type"] = type
	week[day_index]["task_data"] = task_data
	return true

func set_next_week_schedule(
	artist_id: String,
	day_index: int,
	type: int,
	task_data = null,
	apply_lock_state: int = LockState.UNLOCKED
) -> bool:
	if not _is_valid_day(day_index):
		return false
	if not ArtistManager.is_signed(artist_id):
		push_warning("[ScheduleManager] 草稿排期失败：%s 尚未签约。" % artist_id)
		return false

	if type in [ScheduleType.WORK_OVERSEAS, ScheduleType.VACATION_DOMESTIC, ScheduleType.VACATION_OVERSEAS]:
		return _set_whole_week_schedule(next_week_drafts, artist_id, type, task_data)

	var week: Array = get_draft_week(artist_id)
	var slot: Dictionary = week[day_index]
	var lock_state: int = int(slot.get("lock_state", LockState.UNLOCKED))

	if lock_state == LockState.LOCKED_HARD:
		return false

	if lock_state == LockState.LOCKED_WEEK:
		if not _is_partial_override_allowed(slot):
			return false
		_apply_single_day_breaking_week_lock(week, day_index, type, task_data, apply_lock_state)
		return true

	slot["type"] = type
	slot["task_data"] = task_data
	if apply_lock_state != LockState.UNLOCKED:
		slot["lock_state"] = apply_lock_state
	return true

func copy_current_week_to_next_draft(artist_id: String) -> bool:
	if not ArtistManager.is_signed(artist_id):
		push_warning("[ScheduleManager] 同上週失败：%s 尚未签约。" % artist_id)
		return false

	var source_week: Array
	if last_committed_week_schedules.has(artist_id):
		source_week = last_committed_week_schedules[artist_id]
	else:
		source_week = get_week(artist_id)

	next_week_drafts[artist_id] = _duplicate_week(source_week)
	print("[ScheduleManager] 已复制上次提交的週计划到 %s 的下週草稿。" % artist_id)
	return true

func is_draft_slot_editable(artist_id: String, day_index: int) -> bool:
	if not _is_valid_day(day_index) or not ArtistManager.is_signed(artist_id):
		return false
	var week: Array = get_draft_week(artist_id)
	var slot: Dictionary = week[day_index]
	var lock_state: int = int(slot.get("lock_state", LockState.UNLOCKED))
	if lock_state == LockState.UNLOCKED:
		return true
	if lock_state == LockState.LOCKED_WEEK:
		return _is_partial_override_allowed(slot)
	return false

func get_slot_lock_hint(slot: Dictionary) -> String:
	var lock_state: int = int(slot.get("lock_state", LockState.UNLOCKED))
	if lock_state == LockState.UNLOCKED:
		return ""

	var schedule_type: int = int(slot.get("type", ScheduleType.ROUTINE_EMPTY))
	if lock_state == LockState.LOCKED_HARD:
		return "強制鎖定"
	if _is_vacation_schedule_type(schedule_type) or schedule_type == ScheduleType.WORK_OVERSEAS:
		return "整週鎖定"
	if _is_job_schedule_type(schedule_type):
		return "通告鎖定"
	return "已鎖定"

func _set_whole_week_schedule(schedule_store: Dictionary, artist_id: String, type: int, task_data = null) -> bool:
	if not schedule_store.has(artist_id):
		schedule_store[artist_id] = _make_empty_week()

	var week: Array = schedule_store[artist_id]
	for day in week:
		if day["lock_state"] == LockState.LOCKED_HARD:
			return false

	for i in range(DAYS_PER_WEEK):
		week[i]["type"] = type
		week[i]["task_data"] = task_data
		week[i]["lock_state"] = LockState.LOCKED_WEEK
	return true

func force_insert_special_event(artist_id: String, day_index: int, type: int, task_data = null) -> bool:
	if not _is_valid_day(day_index):
		return false
	var week: Array = get_week(artist_id)
	week[day_index]["type"] = type
	week[day_index]["task_data"] = task_data
	week[day_index]["lock_state"] = LockState.LOCKED_HARD
	return true

func force_insert_next_week_special_event(artist_id: String, day_index: int, type: int, task_data = null) -> bool:
	if not _is_valid_day(day_index):
		return false
	var week: Array = get_draft_week(artist_id)
	week[day_index]["type"] = type
	week[day_index]["task_data"] = task_data
	week[day_index]["lock_state"] = LockState.LOCKED_HARD
	return true

## GameFlowManager 每天结束时调用，只执行「今天」这一格。
func execute_today(day_index: int) -> void:
	if not _is_valid_day(day_index):
		return

	for artist_id in ArtistManager.get_signed_ids():
		execute_artist_day(artist_id, day_index)

func settle_day_and_build_report(day_index: int) -> Array:
	var reports: Array = []
	for artist_id in ArtistManager.get_signed_ids():
		reports.append(_build_artist_day_report(str(artist_id), day_index))
	return reports

func _build_artist_day_report(artist_id: String, day_index: int) -> Dictionary:
	var artist: ArtistInstance = ArtistManager.get_artist(artist_id)
	var resource: ArtistResource = ArtistManager.get_artist_resource(artist_id)
	var week: Array = get_week(artist_id)
	var slot: Dictionary = week[day_index].duplicate(true)
	var display_lines: PackedStringArray = get_slot_display_lines(slot)
	var stats_before: Dictionary = DayWorkReportBuilder.snapshot_stats(artist)
	var exec_result: Dictionary = execute_artist_day(artist_id, day_index)
	var stats_after: Dictionary = DayWorkReportBuilder.snapshot_stats(artist)

	return {
		"artist_id": artist_id,
		"artist_name": resource.artist_name if resource != null else artist_id,
		"task_type_label": display_lines[0] if display_lines.size() > 0 else "空白",
		"task_title": display_lines[1] if display_lines.size() > 1 else "—",
		"outcome_label": str(exec_result.get("outcome_label", "—")),
		"stat_lines": DayWorkReportBuilder.format_stat_deltas(stats_before, stats_after),
		"empty": false,
	}

func execute_artist_day(artist_id: String, day_index: int) -> Dictionary:
	if not _is_valid_day(day_index):
		return {"success": false, "outcome_label": "—"}

	var artist: ArtistInstance = ArtistManager.get_artist(artist_id)
	if artist == null:
		return {"success": false, "outcome_label": "—"}

	var week: Array = get_week(artist_id)
	var slot: Dictionary = week[day_index]
	var data = slot["task_data"]
	var current_type: int = slot["type"]
	var outcome_label: String = "—"

	if current_type == ScheduleType.ROUTINE_EMPTY:
		artist.apply_daily_result(null)
		outcome_label = "空白"
	elif artist.is_hospitalized():
		if data is JobInstance:
			JobManager.process_shoot_day(artist_id, data, true)
		outcome_label = "缺勤"
	elif _is_job_schedule_type(current_type) and data is JobInstance:
		var shoot_result: Dictionary = JobManager.process_shoot_day(artist_id, data, false)
		if shoot_result.get("skipped", false):
			outcome_label = "已結束"
		else:
			if not artist.is_hospitalized() and artist.mood.current_state != ArtistMoodComponent.MoodState.RED:
				artist.apply_daily_result(data)
			if shoot_result.get("canceled", false):
				outcome_label = "終止"
			elif shoot_result.get("completed", false):
				outcome_label = "殺青"
			else:
				outcome_label = "成功"
	elif current_type == ScheduleType.COURSE and data is CourseResource:
		var course_result: Dictionary = CourseManager.process_course_day(artist_id, data)
		outcome_label = "成功" if course_result.get("is_successful", false) else "失敗"
	elif current_type == ScheduleType.GIG and data is GigResource:
		var gig_result: Dictionary = GigManager.process_gig_day(artist_id, data)
		outcome_label = "成功" if gig_result.get("is_successful", false) else "失敗"
	elif _is_vacation_schedule_type(current_type) and data is VacationResource:
		if _should_charge_vacation_fee(week, day_index, current_type):
			if not PlayerManager.can_afford(data.cost_money):
				push_warning("[ScheduleManager] 资金不足，无法完成度假：%s" % data.vacation_name)
				outcome_label = "失敗"
			else:
				PlayerManager.spend_money(data.cost_money, "度假：%s" % data.vacation_name)
				artist.apply_daily_result(data)
				outcome_label = "成功"
		else:
			artist.apply_daily_result(data)
			outcome_label = "成功"
	elif current_type == ScheduleType.ROUTINE_REST:
		artist.apply_rest_day()
		outcome_label = "休息"
	elif current_type == ScheduleType.ROUTINE_CREATION:
		artist.apply_creation_day()
		outcome_label = "創作"
	else:
		artist.apply_daily_result(data)
		outcome_label = "完成"

	week[day_index] = _make_empty_slot()
	return {"success": true, "outcome_label": outcome_label}

func get_slot_display_text(slot: Dictionary) -> String:
	var lines: PackedStringArray = get_slot_display_lines(slot)
	if lines.size() >= 2 and lines[1] != "—":
		return "%s·%s" % [lines[0], lines[1]]
	return lines[0]

func get_slot_display_lines(slot: Dictionary) -> PackedStringArray:
	var schedule_type: int = slot.get("type", ScheduleType.ROUTINE_EMPTY)
	var data = slot.get("task_data")
	var type_line: String = _get_slot_type_line(schedule_type)
	var detail_line: String = "—"

	match schedule_type:
		ScheduleType.COURSE:
			if data is CourseResource:
				detail_line = data.course_name
		ScheduleType.GIG:
			if data is GigResource:
				detail_line = data.gig_name
		ScheduleType.VACATION_DOMESTIC, ScheduleType.VACATION_OVERSEAS:
			if data is VacationResource:
				detail_line = data.vacation_name
		ScheduleType.WORK_LOCAL, ScheduleType.WORK_OVERSEAS:
			if data is JobInstance:
				detail_line = data.base_job.job_name

	return PackedStringArray([type_line, detail_line])

func _get_slot_type_line(schedule_type: int) -> String:
	if schedule_type == ScheduleType.WORK_LOCAL:
		return "通告"
	if schedule_type == ScheduleType.WORK_OVERSEAS:
		return "海外通告"
	return get_schedule_type_name(schedule_type)

func get_schedule_type_name(schedule_type: int) -> String:
	match schedule_type:
		ScheduleType.ROUTINE_EMPTY:
			return "空白"
		ScheduleType.ROUTINE_REST:
			return "休息"
		ScheduleType.ROUTINE_CREATION:
			return "创作"
		ScheduleType.COURSE:
			return "课程"
		ScheduleType.GIG:
			return "打工"
		ScheduleType.VACATION_DOMESTIC:
			return "国内度假"
		ScheduleType.VACATION_OVERSEAS:
			return "国外度假"
		ScheduleType.WORK_LOCAL:
			return "本地工作"
		ScheduleType.WORK_OVERSEAS:
			return "海外工作"
		ScheduleType.EVENT_PROMO:
			return "宣传"
		ScheduleType.EVENT_CONCERT:
			return "演唱会"
		ScheduleType.EVENT_FAN_MEET:
			return "粉丝会"
		ScheduleType.EVENT_PREMIERE:
			return "首映"
		_:
			return "其他"

func _is_vacation_schedule_type(schedule_type: int) -> bool:
	return schedule_type in [
		ScheduleType.VACATION_DOMESTIC,
		ScheduleType.VACATION_OVERSEAS,
	]

func _is_partial_override_allowed(slot: Dictionary) -> bool:
	## 整週鎖定（度假/海外通告）下，允許單日覆蓋；其餘整週鎖定格改為空白。
	var schedule_type: int = int(slot.get("type", ScheduleType.ROUTINE_EMPTY))
	return _is_vacation_schedule_type(schedule_type) or schedule_type == ScheduleType.WORK_OVERSEAS

func _apply_single_day_breaking_week_lock(
	week: Array,
	day_index: int,
	type: int,
	task_data,
	apply_lock_state: int
) -> void:
	for i in range(DAYS_PER_WEEK):
		if i == day_index:
			continue
		if int(week[i].get("lock_state", LockState.UNLOCKED)) == LockState.LOCKED_WEEK:
			week[i] = _make_empty_slot()

	week[day_index]["type"] = type
	week[day_index]["task_data"] = task_data
	week[day_index]["lock_state"] = (
		apply_lock_state if apply_lock_state != LockState.UNLOCKED else LockState.UNLOCKED
	)

func _should_charge_vacation_fee(week: Array, day_index: int, schedule_type: int) -> bool:
	if day_index <= 0:
		return true
	var previous_slot: Dictionary = week[day_index - 1]
	var current_slot: Dictionary = week[day_index]
	return not (
		int(previous_slot.get("type", ScheduleType.ROUTINE_EMPTY)) == schedule_type
		and previous_slot.get("task_data") == current_slot.get("task_data")
	)

func _is_job_schedule_type(schedule_type: int) -> bool:
	return schedule_type in [
		ScheduleType.WORK_LOCAL,
		ScheduleType.WORK_OVERSEAS,
	]

func get_week(artist_id: String) -> Array:
	if not current_week_schedules.has(artist_id):
		current_week_schedules[artist_id] = _make_empty_week()
	return current_week_schedules[artist_id]

func get_draft_week(artist_id: String) -> Array:
	if not next_week_drafts.has(artist_id):
		next_week_drafts[artist_id] = _make_empty_week()
	return next_week_drafts[artist_id]

func commit_next_week_schedules() -> int:
	current_week_schedules.clear()
	last_committed_week_schedules.clear()
	for artist_id in ArtistManager.get_signed_ids():
		if next_week_drafts.has(artist_id):
			var committed_week: Array = _duplicate_week(next_week_drafts[artist_id])
			current_week_schedules[artist_id] = committed_week
			last_committed_week_schedules[artist_id] = _duplicate_week(committed_week)
		else:
			current_week_schedules[artist_id] = _make_empty_week()

	next_week_drafts.clear()
	print("[ScheduleManager] 下周行程已提交，共 %d 位旗下艺人。" % current_week_schedules.size())
	return current_week_schedules.size()

func cancel_next_week_drafts() -> void:
	next_week_drafts.clear()

func reset_week(artist_id: String) -> void:
	current_week_schedules[artist_id] = _make_empty_week()

func reset_next_week_draft(artist_id: String) -> void:
	next_week_drafts[artist_id] = _make_empty_week()

func clear_artist(artist_id: String) -> void:
	current_week_schedules.erase(artist_id)
	next_week_drafts.erase(artist_id)
	last_committed_week_schedules.erase(artist_id)

func clear_all() -> void:
	current_week_schedules.clear()
	next_week_drafts.clear()
	last_committed_week_schedules.clear()

func _on_artist_terminated(artist_id: String) -> void:
	clear_artist(artist_id)

## 通告殺青／流產／逾期後，清除該藝人行程中殘留的同一 JobInstance 引用。
func clear_job_instance_from_schedules(artist_id: String, job_instance: JobInstance) -> int:
	var cleared: int = 0
	if job_instance == null:
		return cleared

	var clean_artist: String = artist_id.strip_edges()
	if clean_artist == "":
		return cleared

	for week_store in [current_week_schedules, next_week_drafts]:
		if not week_store.has(clean_artist):
			continue
		var week: Array = week_store[clean_artist]
		for day_index in range(week.size()):
			var slot: Dictionary = week[day_index]
			if slot.get("task_data") == job_instance:
				week[day_index] = _make_empty_slot()
				cleared += 1
	return cleared

func _make_empty_week() -> Array:
	var week: Array = []
	for _i in range(DAYS_PER_WEEK):
		week.append(_make_empty_slot())
	return week

func _duplicate_week(week: Array) -> Array:
	var copied_week: Array = []
	for slot in week:
		copied_week.append(slot.duplicate(true))
	return copied_week

func _make_empty_slot() -> Dictionary:
	return {
		"type": ScheduleType.ROUTINE_EMPTY,
		"task_data": null,
		"lock_state": LockState.UNLOCKED
	}

func _is_valid_day(day_index: int) -> bool:
	if day_index < 0 or day_index >= DAYS_PER_WEEK:
		push_warning("[ScheduleManager] day_index 超出范围，应为 0-6，实际为 %d。" % day_index)
		return false
	return true

func export_save_state() -> Dictionary:
	return {
		"current_week": _export_week_store(current_week_schedules),
		"next_draft": _export_week_store(next_week_drafts),
		"last_committed_week": _export_week_store(last_committed_week_schedules),
	}

func import_save_state(data: Dictionary) -> void:
	current_week_schedules.clear()
	next_week_drafts.clear()
	last_committed_week_schedules.clear()
	if data == null:
		return

	var current_week: Variant = data.get("current_week", {})
	if current_week is Dictionary:
		for artist_id in current_week:
			current_week_schedules[artist_id] = _import_week(current_week[artist_id])

	var next_draft: Variant = data.get("next_draft", {})
	if next_draft is Dictionary:
		for artist_id in next_draft:
			next_week_drafts[artist_id] = _import_week(next_draft[artist_id])

	var last_committed: Variant = data.get("last_committed_week", {})
	if last_committed is Dictionary:
		for artist_id in last_committed:
			last_committed_week_schedules[artist_id] = _import_week(last_committed[artist_id])
	elif not current_week_schedules.is_empty():
		# 旧档兼容：无快照时用 current_week 回填（可能已部分执行）
		for artist_id in current_week_schedules:
			last_committed_week_schedules[artist_id] = _duplicate_week(current_week_schedules[artist_id])

func _export_week_store(store: Dictionary) -> Dictionary:
	var payload: Dictionary = {}
	for artist_id in store:
		payload[artist_id] = _export_week(store[artist_id])
	return payload

func _export_week(week: Array) -> Array:
	var exported_week: Array = []
	for slot in week:
		if slot is Dictionary:
			exported_week.append(_export_slot(slot))
		else:
			exported_week.append(_export_slot(_make_empty_slot()))
	return exported_week

func _export_slot(slot: Dictionary) -> Dictionary:
	var task_ref = null
	var task_data = slot.get("task_data")
	if task_data is JobInstance:
		var instance_id: String = JobManager.get_instance_id_for_job(task_data)
		if instance_id != "":
			task_ref = {"kind": "job_instance", "id": instance_id}
	elif task_data is GigResource:
		task_ref = {"kind": "gig", "id": task_data.gig_id}
	elif task_data is CourseResource:
		task_ref = {"kind": "course", "id": task_data.course_id}
	elif task_data is VacationResource:
		task_ref = {"kind": "vacation", "id": task_data.vacation_id}

	return {
		"type": int(slot.get("type", ScheduleType.ROUTINE_EMPTY)),
		"lock_state": int(slot.get("lock_state", LockState.UNLOCKED)),
		"task_ref": task_ref,
	}

func _import_week(week_data: Variant) -> Array:
	var week: Array = _make_empty_week()
	if not (week_data is Array):
		return week

	for day_index in range(mini(week_data.size(), DAYS_PER_WEEK)):
		var slot_dto: Variant = week_data[day_index]
		if slot_dto is Dictionary:
			week[day_index] = _import_slot(slot_dto)
	return week

func _import_slot(slot_dto: Dictionary) -> Dictionary:
	var schedule_type: int = int(slot_dto.get("type", ScheduleType.ROUTINE_EMPTY))
	var lock_state: int = int(slot_dto.get("lock_state", LockState.UNLOCKED))
	var task_data = null
	var task_ref: Variant = slot_dto.get("task_ref")

	if task_ref is Dictionary and not task_ref.is_empty():
		task_data = _resolve_task_ref(task_ref)
		if task_data == null:
			push_warning("[ScheduleManager] 无法解析 task_ref: %s" % str(task_ref))
			schedule_type = ScheduleType.ROUTINE_EMPTY
			lock_state = LockState.UNLOCKED

	return {
		"type": schedule_type,
		"task_data": task_data,
		"lock_state": lock_state,
	}

func _resolve_task_ref(task_ref: Dictionary) -> Variant:
	var kind: String = str(task_ref.get("kind", "")).strip_edges()
	var ref_id: String = str(task_ref.get("id", "")).strip_edges()
	if kind == "" or ref_id == "":
		return null

	match kind:
		"job_instance":
			return JobManager.get_job_instance(ref_id)
		"gig":
			return GigManager.get_gig(ref_id)
		"course":
			return CourseManager.get_course(ref_id)
		"vacation":
			return VacationManager.get_vacation(ref_id)
		_:
			push_warning("[ScheduleManager] 未知 task_ref kind: %s" % kind)
			return null
