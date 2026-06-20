extends Node

## 课程模板目录：UI / ScheduleManager 只读接口。

signal course_day_settled(artist_id: String, course: CourseResource, result: Dictionary)

const COURSES_DIR: String = "res://data/courses/"
const INITIAL_UNLOCKED_COURSE_IDS: Array[String] = ["course_acting_basic_01"]

var course_templates: Dictionary = {}
var _unlocked_course_ids: Dictionary = {}

func _ready() -> void:
	var count: int = load_all_course_templates()
	_reset_initial_unlocks()
	print("[CourseManager] 课程模板载入完成，共 %d 则。" % count)

func _reset_initial_unlocks() -> void:
	_unlocked_course_ids.clear()
	for course_id in INITIAL_UNLOCKED_COURSE_IDS:
		_unlocked_course_ids[course_id] = true

func is_course_unlocked(course_id: String) -> bool:
	return _unlocked_course_ids.has(course_id.strip_edges())

func unlock_course(course_id: String) -> bool:
	var clean_id: String = course_id.strip_edges()
	if clean_id == "" or not course_templates.has(clean_id):
		return false
	_unlocked_course_ids[clean_id] = true
	return true

func get_unlocked_courses() -> Array[CourseResource]:
	var courses: Array[CourseResource] = []
	for course_id in course_templates.keys():
		if is_course_unlocked(course_id):
			var course: CourseResource = course_templates[course_id]
			if course != null:
				courses.append(course)
	return courses

func load_all_course_templates(dir_path: String = COURSES_DIR) -> int:
	course_templates.clear()
	_load_resources_in_dir(dir_path)
	return course_templates.size()

func get_course(course_id: String) -> CourseResource:
	if course_templates.has(course_id):
		return course_templates[course_id]
	return null

func get_all_courses() -> Array[CourseResource]:
	var courses: Array[CourseResource] = []
	for course_id in course_templates.keys():
		var course: CourseResource = course_templates[course_id]
		if course != null:
			courses.append(course)
	return courses

func get_course_count() -> int:
	return course_templates.size()

func build_course_detail_text(course: CourseResource, artist_id: String = "") -> String:
	if course == null:
		return "请选择课程。"
	return "【%s】\n学费：$%d | 疲劳 %s | 压力 %s" % [
		course.course_name,
		course.cost_money,
		_build_scaled_status_text(course.add_fatigue, artist_id, "fatigue"),
		_build_scaled_status_text(course.add_stress, artist_id, "stress"),
	]

func make_picker_option(course: CourseResource) -> Dictionary:
	return {
		"option_id": "course_%s" % course.course_id,
		"tab": SchedulePickerManager.Tab.TRAINING,
		"kind": SchedulePickerManager.KIND_COURSE,
		"title": "[課程] %s" % course.course_name,
		"subtitle": "學費 $%d" % course.cost_money,
		"schedule_type": ScheduleManager.ScheduleType.COURSE,
		"task_data": course,
		"lock_state": ScheduleManager.LockState.UNLOCKED,
		"disabled": false,
		"disabled_reason": "",
	}

func build_course_picker_detail_text(course: CourseResource, artist_id: String = "") -> String:
	if course == null:
		return "請選擇課程。"
	var detail: String = build_course_detail_text(course, artist_id)
	if not PlayerManager.can_afford(course.cost_money):
		detail += "\n（目前資金可能不足，結算日仍會嘗試扣款）"
	return detail + "\n" + TrainingActivityEvaluator.build_quality_rule_text()

func process_course_day(artist_id: String, course: CourseResource) -> Dictionary:
	if course == null:
		return {"processed": false, "reason": "课程数据无效。"}

	if not PlayerManager.can_afford(course.cost_money):
		var blocked: Dictionary = {
			"processed": false,
			"reason": "资金不足，无法完成课程：%s" % course.course_name,
			"activity_name": course.course_name,
		}
		push_warning("[CourseManager] %s" % blocked["reason"])
		return blocked

	var artist: ArtistInstance = ArtistManager.get_artist(artist_id)
	var eval_result: Dictionary = TrainingActivityEvaluator.evaluate_course_day(artist, course)
	eval_result["activity_name"] = course.course_name

	if not eval_result.get("is_successful", false):
		PlayerManager.record_course_failed()
		CompanyStandingResolver.apply_activity_failure("课程", course.course_name)
		course_day_settled.emit(artist_id, course, eval_result)
		print("[CourseManager] %s" % str(eval_result.get("detail", "课程失败。")))
		return eval_result

	PlayerManager.spend_money(
		course.cost_money,
		"课程：%s（%s）" % [course.course_name, eval_result.get("quality_name", "成功")]
	)
	if artist != null:
		artist.apply_daily_result(course)

	var quality: int = int(eval_result.get("quality", CompletionQuality.Level.SUCCESS))
	PlayerManager.record_course_completed(quality)
	var standing: Dictionary = CompanyStandingResolver.apply_activity_completion(
		"课程",
		quality,
		course.course_name
	)
	eval_result["standing"] = standing
	course_day_settled.emit(artist_id, course, eval_result)
	print("[CourseManager] 课程完成：%s / %s" % [course.course_name, eval_result.get("quality_name", "成功")])
	return eval_result

func _load_resources_in_dir(dir_path: String) -> void:
	var normalized_dir_path: String = dir_path.trim_suffix("/") + "/"
	var dir := DirAccess.open(normalized_dir_path)
	if dir == null:
		push_warning("[CourseManager] 无法打开课程目录: " + normalized_dir_path)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				_load_resources_in_dir(normalized_dir_path.path_join(file_name))
		else:
			var res_path: String = _normalize_resource_path(normalized_dir_path, file_name)
			if res_path != "":
				var res: Resource = load(res_path)
				if res is CourseResource:
					_register_template(res)
		file_name = dir.get_next()
	dir.list_dir_end()

func _normalize_resource_path(dir_path: String, file_name: String) -> String:
	if file_name.ends_with(".tres"):
		return dir_path.path_join(file_name)
	if file_name.ends_with(".tres.remap"):
		return dir_path.path_join(file_name.trim_suffix(".remap"))
	return ""

func _register_template(resource: CourseResource) -> void:
	if resource.course_id.strip_edges() == "":
		push_warning("[CourseManager] 有一则课程模板缺少 course_id，已跳过。")
		return
	if course_templates.has(resource.course_id):
		push_warning("[CourseManager] 发现重复 course_id: %s，后者覆盖前者。" % resource.course_id)
	course_templates[resource.course_id] = resource

func _build_scaled_status_text(base_delta: int, artist_id: String, status_name: String) -> String:
	var scaled_delta: int = base_delta
	var artist: ArtistInstance = ArtistManager.get_artist(artist_id)
	if artist != null and artist.base_data != null:
		if status_name == "fatigue":
			scaled_delta = artist.base_data.scale_fatigue_delta(base_delta)
		elif status_name == "stress":
			scaled_delta = artist.base_data.scale_stress_delta(base_delta)
	var text: String = "%+d" % scaled_delta
	if scaled_delta != base_delta:
		text += "（基礎%+d）" % base_delta
	return text

func export_save_state() -> Array:
	return _unlocked_course_ids.keys()

func import_save_state(data: Variant) -> void:
	_unlocked_course_ids.clear()
	if data is Array:
		for course_id in data:
			var clean_id: String = str(course_id).strip_edges()
			if clean_id != "" and course_templates.has(clean_id):
				_unlocked_course_ids[clean_id] = true
	if _unlocked_course_ids.is_empty():
		_reset_initial_unlocks()
