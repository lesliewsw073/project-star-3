extends Node

## 週日會議（及後續日常排程）的「選一天 → 選類型」中樞。
## UI 只負責展示分頁；具體可選項與寫入草稿由此處統一處理。

enum Tab { JOB, TRAINING, REST, VACATION }

const TAB_TITLES: PackedStringArray = ["通告", "打工/課程", "休息", "度假"]
const KIND_JOB := "job"
const KIND_GIG := "gig"
const KIND_COURSE := "course"
const KIND_REST := "rest"
const KIND_EMPTY := "empty"
const KIND_VACATION_DOMESTIC := "vacation_domestic"
const KIND_VACATION_OVERSEAS := "vacation_overseas"

func get_tab_titles() -> PackedStringArray:
	return TAB_TITLES

func build_tab_options(artist_id: String, tab: Tab) -> Array[Dictionary]:
	match tab:
		Tab.JOB:
			return JobManager.get_job_picker_options(artist_id)
		Tab.TRAINING:
			return _build_training_options()
		Tab.REST:
			return _build_rest_options()
		Tab.VACATION:
			return VacationManager.get_vacation_picker_options()
		_:
			return []

func build_all_tab_options(artist_id: String) -> Array:
	var all_tabs: Array = []
	for tab_index in range(TAB_TITLES.size()):
		all_tabs.append(build_tab_options(artist_id, tab_index))
	return all_tabs

func get_recommended_tab_for_slot(slot: Dictionary) -> Tab:
	var schedule_type: int = int(slot.get("type", ScheduleManager.ScheduleType.ROUTINE_EMPTY))
	var task_data = slot.get("task_data")

	if _is_vacation_schedule_type(schedule_type):
		return Tab.VACATION
	if _is_job_schedule_type(schedule_type) and task_data is JobInstance:
		return Tab.JOB
	if schedule_type == ScheduleManager.ScheduleType.GIG:
		return Tab.TRAINING
	if schedule_type == ScheduleManager.ScheduleType.COURSE:
		return Tab.TRAINING
	if schedule_type in [
		ScheduleManager.ScheduleType.ROUTINE_REST,
		ScheduleManager.ScheduleType.ROUTINE_EMPTY,
	]:
		return Tab.REST
	return Tab.JOB

func find_option_index_for_slot(options: Array, slot: Dictionary) -> int:
	var schedule_type: int = int(slot.get("type", ScheduleManager.ScheduleType.ROUTINE_EMPTY))
	var task_data = slot.get("task_data")

	for index in range(options.size()):
		var option: Dictionary = options[index]
		if int(option.get("schedule_type", -1)) != schedule_type:
			continue
		var option_task = option.get("task_data")
		if task_data == null and option_task == null:
			return index
		if task_data != null and option_task == task_data:
			return index
		if task_data is JobInstance and option_task is JobInstance:
			if task_data.base_job.job_id == option_task.base_job.job_id:
				return index
		if task_data is CourseResource and option_task is CourseResource:
			if task_data.course_id == option_task.course_id:
				return index
		if task_data is GigResource and option_task is GigResource:
			if task_data.gig_id == option_task.gig_id:
				return index
		if task_data is VacationResource and option_task is VacationResource:
			if task_data.vacation_id == option_task.vacation_id:
				return index
	return -1

func build_picker_header_text(artist_id: String, day_index: int) -> String:
	var artist_name: String = _get_artist_display_name(artist_id)
	var day_name: String = TimeManager.DAY_NAMES[clampi(day_index, 0, ScheduleManager.DAYS_PER_WEEK - 1)]
	return "%s · %s" % [artist_name, day_name]

func build_slot_preview_text(slot: Dictionary) -> String:
	var lines: PackedStringArray = ScheduleManager.get_slot_display_lines(slot)
	var lock_hint: String = ScheduleManager.get_slot_lock_hint(slot)
	var preview: String = "%s · %s" % [lines[0], lines[1]]
	if lock_hint != "":
		preview += "（%s）" % lock_hint
	return preview

func can_edit_draft_slot(artist_id: String, day_index: int) -> bool:
	return ScheduleManager.is_draft_slot_editable(artist_id, day_index)

func get_edit_block_reason(artist_id: String, day_index: int) -> String:
	if not ArtistManager.is_signed(artist_id):
		return "藝人尚未簽約。"
	if not _is_valid_day(day_index):
		return "日期無效。"
	if ScheduleManager.is_draft_slot_editable(artist_id, day_index):
		return ""
	var slot: Dictionary = ScheduleManager.get_draft_week(artist_id)[day_index]
	return "此格%s，無法修改。" % ScheduleManager.get_slot_lock_hint(slot)

func apply_selection(artist_id: String, day_index: int, option: Dictionary) -> Dictionary:
	if option.is_empty():
		return {"success": false, "reason": "未選擇任何項目。"}

	var kind: String = str(option.get("kind", ""))
	if kind in [KIND_VACATION_DOMESTIC, KIND_VACATION_OVERSEAS]:
		return apply_vacation_selection(artist_id, day_index, option)

	var block_reason: String = get_edit_block_reason(artist_id, day_index)
	if block_reason != "":
		return {"success": false, "reason": block_reason}

	var schedule_type: int = int(option.get("schedule_type", ScheduleManager.ScheduleType.ROUTINE_EMPTY))
	var task_data = option.get("task_data")
	var lock_state: int = int(
		option.get("lock_state", ScheduleManager.LockState.UNLOCKED)
	)

	if kind == KIND_JOB:
		var validation: Dictionary = JobManager.validate_job_picker_selection(artist_id, task_data)
		if not validation.get("success", false):
			return validation

	var applied: bool = ScheduleManager.set_next_week_schedule(
		artist_id,
		day_index,
		schedule_type,
		task_data,
		lock_state
	)
	if not applied:
		return {"success": false, "reason": "寫入下週草稿失敗，請確認格子未被鎖定。"}

	return {
		"success": true,
		"message": _build_apply_message(artist_id, day_index, option),
	}

func apply_vacation_selection(artist_id: String, day_index: int, option: Dictionary) -> Dictionary:
	if not ArtistManager.is_signed(artist_id):
		return {"success": false, "reason": "藝人尚未簽約。"}
	if not _is_valid_day(day_index):
		return {"success": false, "reason": "日期無效。"}

	var task_data = option.get("task_data")
	if task_data == null or not (task_data is VacationResource):
		return {"success": false, "reason": "請選擇度假方案。"}

	var schedule_type: int = int(option.get("schedule_type", ScheduleManager.ScheduleType.VACATION_DOMESTIC))
	var applied: bool = ScheduleManager.set_next_week_schedule(
		artist_id,
		day_index,
		schedule_type,
		task_data
	)
	if not applied:
		return {"success": false, "reason": "無法覆蓋下週行程（可能有強制鎖定格）。"}

	return {
		"success": true,
		"message": "%s · 下週整週 → %s" % [
			_get_artist_display_name(artist_id),
			str(option.get("title", "度假")),
		],
	}

func build_option_detail_text(option: Dictionary, artist_id: String = "") -> String:
	if option.is_empty():
		return "請選擇一項。"

	var kind: String = str(option.get("kind", ""))
	var task_data = option.get("task_data")
	match kind:
		KIND_JOB:
			if task_data is JobInstance:
				return JobManager.build_job_picker_detail_text(task_data, artist_id)
		KIND_COURSE:
			if task_data is CourseResource:
				return CourseManager.build_course_picker_detail_text(task_data, artist_id)
		KIND_GIG:
			if task_data is GigResource:
				return GigManager.build_gig_picker_detail_text(task_data, artist_id)
		KIND_VACATION_DOMESTIC, KIND_VACATION_OVERSEAS:
			if task_data is VacationResource:
				return VacationManager.build_vacation_detail_text(task_data) + "\n選中後立即覆蓋下週整週行程。"
		KIND_REST:
			return "休息日：降低疲勞與壓力，略微提升滿意度。"
		KIND_EMPTY:
			return "空白日：清除此格安排。"
	return str(option.get("subtitle", ""))

func _build_training_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for gig in GigManager.get_unlocked_gigs():
		options.append(GigManager.make_picker_option(gig))
	for course in CourseManager.get_unlocked_courses():
		options.append(CourseManager.make_picker_option(course))
	if options.is_empty():
		options.append({
			"option_id": "training_none",
			"tab": Tab.TRAINING,
			"kind": KIND_GIG,
			"title": "（尚無打工/課程模板）",
			"subtitle": "請在 data/gigs 與 data/courses 新增資源",
			"schedule_type": ScheduleManager.ScheduleType.GIG,
			"task_data": null,
			"lock_state": ScheduleManager.LockState.UNLOCKED,
			"disabled": true,
			"disabled_reason": "目前沒有可用的打工或課程模板。",
		})
	return options

func _build_rest_options() -> Array[Dictionary]:
	return [
		{
			"option_id": "rest_day",
			"tab": Tab.REST,
			"kind": KIND_REST,
			"title": "休息",
			"subtitle": "恢復狀態，不消耗金錢",
			"schedule_type": ScheduleManager.ScheduleType.ROUTINE_REST,
			"task_data": null,
			"lock_state": ScheduleManager.LockState.UNLOCKED,
			"disabled": false,
			"disabled_reason": "",
		},
		{
			"option_id": "empty_day",
			"tab": Tab.REST,
			"kind": KIND_EMPTY,
			"title": "空白",
			"subtitle": "清除此日安排",
			"schedule_type": ScheduleManager.ScheduleType.ROUTINE_EMPTY,
			"task_data": null,
			"lock_state": ScheduleManager.LockState.UNLOCKED,
			"disabled": false,
			"disabled_reason": "",
		},
	]

func _build_apply_message(artist_id: String, day_index: int, option: Dictionary) -> String:
	return "%s · %s → %s" % [
		_get_artist_display_name(artist_id),
		TimeManager.DAY_NAMES[day_index],
		str(option.get("title", "行程")),
	]

func _is_job_schedule_type(schedule_type: int) -> bool:
	return schedule_type in [
		ScheduleManager.ScheduleType.WORK_LOCAL,
		ScheduleManager.ScheduleType.WORK_OVERSEAS,
	]

func _is_vacation_schedule_type(schedule_type: int) -> bool:
	return schedule_type in [
		ScheduleManager.ScheduleType.VACATION_DOMESTIC,
		ScheduleManager.ScheduleType.VACATION_OVERSEAS,
	]

func _is_valid_day(day_index: int) -> bool:
	return day_index >= 0 and day_index < ScheduleManager.DAYS_PER_WEEK

func _get_artist_display_name(artist_id: String) -> String:
	var resource: ArtistResource = ArtistManager.get_artist_resource(artist_id)
	if resource != null and resource.artist_name.strip_edges() != "":
		return resource.artist_name
	return artist_id
