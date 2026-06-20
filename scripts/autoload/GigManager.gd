extends Node

## 打工模板目录：UI / ScheduleManager 只读接口。

signal gig_day_settled(artist_id: String, gig: GigResource, result: Dictionary)

const GIGS_DIR: String = "res://data/gigs/"
const INITIAL_UNLOCKED_GIG_IDS: Array[String] = ["gig_bar_singer_01"]

var gig_templates: Dictionary = {}
var _unlocked_gig_ids: Dictionary = {}

func _ready() -> void:
	var count: int = load_all_gig_templates()
	_reset_initial_unlocks()
	print("[GigManager] 打工模板载入完成，共 %d 则。" % count)

func _reset_initial_unlocks() -> void:
	_unlocked_gig_ids.clear()
	for gig_id in INITIAL_UNLOCKED_GIG_IDS:
		_unlocked_gig_ids[gig_id] = true

func is_gig_unlocked(gig_id: String) -> bool:
	return _unlocked_gig_ids.has(gig_id.strip_edges())

func unlock_gig(gig_id: String) -> bool:
	var clean_id: String = gig_id.strip_edges()
	if clean_id == "" or not gig_templates.has(clean_id):
		return false
	_unlocked_gig_ids[clean_id] = true
	return true

func get_unlocked_gigs() -> Array[GigResource]:
	var gigs: Array[GigResource] = []
	for gig_id in gig_templates.keys():
		if is_gig_unlocked(gig_id):
			var gig: GigResource = gig_templates[gig_id]
			if gig != null:
				gigs.append(gig)
	return gigs

func load_all_gig_templates(dir_path: String = GIGS_DIR) -> int:
	gig_templates.clear()
	_load_resources_in_dir(dir_path)
	return gig_templates.size()

func get_gig(gig_id: String) -> GigResource:
	if gig_templates.has(gig_id):
		return gig_templates[gig_id]
	return null

func get_all_gigs() -> Array[GigResource]:
	var gigs: Array[GigResource] = []
	for gig_id in gig_templates.keys():
		var gig: GigResource = gig_templates[gig_id]
		if gig != null:
			gigs.append(gig)
	return gigs

func get_gig_count() -> int:
	return gig_templates.size()

func build_gig_detail_text(gig: GigResource, artist_id: String = "") -> String:
	if gig == null:
		return "请选择打工。"
	return "【%s】\n酬劳：$%d | 疲劳 %s | 压力 %s" % [
		gig.gig_name,
		gig.reward_money,
		_build_scaled_status_text(gig.add_fatigue, artist_id, "fatigue"),
		_build_scaled_status_text(gig.add_stress, artist_id, "stress"),
	]

func make_picker_option(gig: GigResource) -> Dictionary:
	return {
		"option_id": "gig_%s" % gig.gig_id,
		"tab": SchedulePickerManager.Tab.TRAINING,
		"kind": SchedulePickerManager.KIND_GIG,
		"title": "[打工] %s" % gig.gig_name,
		"subtitle": "酬勞 $%d" % gig.reward_money,
		"schedule_type": ScheduleManager.ScheduleType.GIG,
		"task_data": gig,
		"lock_state": ScheduleManager.LockState.UNLOCKED,
		"disabled": false,
		"disabled_reason": "",
	}

func build_gig_picker_detail_text(gig: GigResource, artist_id: String = "") -> String:
	if gig == null:
		return "請選擇打工。"
	return build_gig_detail_text(gig, artist_id) + "\n" + TrainingActivityEvaluator.build_quality_rule_text()

func process_gig_day(artist_id: String, gig: GigResource) -> Dictionary:
	if gig == null:
		return {"processed": false, "reason": "打工数据无效。"}

	var artist: ArtistInstance = ArtistManager.get_artist(artist_id)
	var eval_result: Dictionary = TrainingActivityEvaluator.evaluate_gig_day(artist, gig)
	eval_result["activity_name"] = gig.gig_name

	if not eval_result.get("is_successful", false):
		PlayerManager.record_gig_failed()
		CompanyStandingResolver.apply_activity_failure("打工", gig.gig_name)
		gig_day_settled.emit(artist_id, gig, eval_result)
		print("[GigManager] %s" % str(eval_result.get("detail", "打工失败。")))
		return eval_result

	if artist != null:
		artist.apply_daily_result(gig)

	var quality: int = int(eval_result.get("quality", CompletionQuality.Level.SUCCESS))
	var reward_money: int = gig.reward_money
	if reward_money > 0:
		PlayerManager.add_money(
			reward_money,
			"打工：%s（%s）" % [gig.gig_name, eval_result.get("quality_name", "成功")]
		)

	PlayerManager.record_gig_completed(quality)
	var standing: Dictionary = CompanyStandingResolver.apply_activity_completion(
		"打工",
		quality,
		gig.gig_name
	)
	eval_result["standing"] = standing
	eval_result["reward_money"] = reward_money
	gig_day_settled.emit(artist_id, gig, eval_result)
	print("[GigManager] 打工完成：%s / %s" % [gig.gig_name, eval_result.get("quality_name", "成功")])
	return eval_result

func _load_resources_in_dir(dir_path: String) -> void:
	var normalized_dir_path: String = dir_path.trim_suffix("/") + "/"
	var dir := DirAccess.open(normalized_dir_path)
	if dir == null:
		push_warning("[GigManager] 无法打开打工目录: " + normalized_dir_path)
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
				if res is GigResource:
					_register_template(res)
		file_name = dir.get_next()
	dir.list_dir_end()

func _normalize_resource_path(dir_path: String, file_name: String) -> String:
	if file_name.ends_with(".tres"):
		return dir_path.path_join(file_name)
	if file_name.ends_with(".tres.remap"):
		return dir_path.path_join(file_name.trim_suffix(".remap"))
	return ""

func _register_template(resource: GigResource) -> void:
	if resource.gig_id.strip_edges() == "":
		push_warning("[GigManager] 有一则打工模板缺少 gig_id，已跳过。")
		return
	if gig_templates.has(resource.gig_id):
		push_warning("[GigManager] 发现重复 gig_id: %s，后者覆盖前者。" % resource.gig_id)
	gig_templates[resource.gig_id] = resource

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
	return _unlocked_gig_ids.keys()

func import_save_state(data: Variant) -> void:
	_unlocked_gig_ids.clear()
	if data is Array:
		for gig_id in data:
			var clean_id: String = str(gig_id).strip_edges()
			if clean_id != "" and gig_templates.has(clean_id):
				_unlocked_gig_ids[clean_id] = true
	if _unlocked_gig_ids.is_empty():
		_reset_initial_unlocks()
