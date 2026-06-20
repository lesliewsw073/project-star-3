extends Node

## 度假模板目录：UI / ScheduleManager 只读接口。

const VACATIONS_DIR: String = "res://data/vacations/"

var vacation_templates: Dictionary = {}

func _ready() -> void:
	var count: int = load_all_vacation_templates()
	print("[VacationManager] 度假模板载入完成，共 %d 则。" % count)

func load_all_vacation_templates(dir_path: String = VACATIONS_DIR) -> int:
	vacation_templates.clear()
	_load_resources_in_dir(dir_path)
	return vacation_templates.size()

func get_vacation(vacation_id: String) -> VacationResource:
	if vacation_templates.has(vacation_id):
		return vacation_templates[vacation_id]
	return null

func get_all_vacations() -> Array[VacationResource]:
	var vacations: Array[VacationResource] = []
	for vacation_id in vacation_templates.keys():
		var vacation: VacationResource = vacation_templates[vacation_id]
		if vacation != null:
			vacations.append(vacation)
	return vacations

func get_vacations_by_type(vacation_type: int) -> Array[VacationResource]:
	var vacations: Array[VacationResource] = []
	for vacation in get_all_vacations():
		if vacation.vacation_type == vacation_type:
			vacations.append(vacation)
	return vacations

func get_vacation_count() -> int:
	return vacation_templates.size()

func build_vacation_detail_text(vacation: VacationResource) -> String:
	if vacation == null:
		return "请选择度假方案。"
	var type_name: String = "国内" if vacation.vacation_type == VacationResource.VacationType.DOMESTIC else "国外"
	return "【%s】（%s）\n费用：$%d | 疲劳 %+d | 压力 %+d" % [
		vacation.vacation_name,
		type_name,
		vacation.cost_money,
		vacation.add_fatigue,
		vacation.add_stress,
	]

func get_vacation_picker_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for vacation in get_all_vacations():
		options.append(make_picker_option(vacation))
	if options.is_empty():
		options.append({
			"option_id": "vacation_none",
			"tab": SchedulePickerManager.Tab.VACATION,
			"kind": SchedulePickerManager.KIND_VACATION_DOMESTIC,
			"title": "（尚無度假模板）",
			"subtitle": "請在 data/vacations 新增資源",
			"schedule_type": ScheduleManager.ScheduleType.VACATION_DOMESTIC,
			"task_data": null,
			"lock_state": ScheduleManager.LockState.UNLOCKED,
			"disabled": true,
			"disabled_reason": "目前沒有可用的度假方案。",
		})
	return options

func make_picker_option(vacation: VacationResource) -> Dictionary:
	var is_domestic: bool = vacation.vacation_type == VacationResource.VacationType.DOMESTIC
	var schedule_type: int = (
		ScheduleManager.ScheduleType.VACATION_DOMESTIC
		if is_domestic
		else ScheduleManager.ScheduleType.VACATION_OVERSEAS
	)
	var kind: String = (
		SchedulePickerManager.KIND_VACATION_DOMESTIC
		if is_domestic
		else SchedulePickerManager.KIND_VACATION_OVERSEAS
	)
	var type_label: String = "国内" if is_domestic else "国外"
	return {
		"option_id": "vacation_%s" % vacation.vacation_id,
		"tab": SchedulePickerManager.Tab.VACATION,
		"kind": kind,
		"title": vacation.vacation_name,
		"subtitle": "%s · $%d · 整週覆蓋" % [type_label, vacation.cost_money],
		"schedule_type": schedule_type,
		"task_data": vacation,
		"lock_state": ScheduleManager.LockState.UNLOCKED,
		"disabled": false,
		"disabled_reason": "",
	}

func build_vacation_picker_detail_text(vacation: VacationResource) -> String:
	if vacation == null:
		return "請選擇度假方案。"
	return build_vacation_detail_text(vacation) + "\n選中後立即覆蓋下週整週行程。"

func _load_resources_in_dir(dir_path: String) -> void:
	var normalized_dir_path: String = dir_path.trim_suffix("/") + "/"
	var dir := DirAccess.open(normalized_dir_path)
	if dir == null:
		push_warning("[VacationManager] 无法打开度假目录: " + normalized_dir_path)
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
				if res is VacationResource:
					_register_template(res)
		file_name = dir.get_next()
	dir.list_dir_end()

func _normalize_resource_path(dir_path: String, file_name: String) -> String:
	if file_name.ends_with(".tres"):
		return dir_path.path_join(file_name)
	if file_name.ends_with(".tres.remap"):
		return dir_path.path_join(file_name.trim_suffix(".remap"))
	return ""

func _register_template(resource: VacationResource) -> void:
	if resource.vacation_id.strip_edges() == "":
		push_warning("[VacationManager] 有一则度假模板缺少 vacation_id，已跳过。")
		return
	if vacation_templates.has(resource.vacation_id):
		push_warning("[VacationManager] 发现重复 vacation_id: %s，后者覆盖前者。" % resource.vacation_id)
	vacation_templates[resource.vacation_id] = resource

func export_save_state() -> Dictionary:
	# 预留：未来若加入度假地点解锁进度，可直接落盘 unlocked_ids。
	return {
		"version": 1,
		"unlocked_ids": PackedStringArray(),
	}

func import_save_state(data: Variant) -> void:
	# 当前版本度假模板默认全可用；保留接口保障读档字段完整性。
	if data == null:
		return
	if data is Dictionary:
		return
