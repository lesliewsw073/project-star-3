extends Node

## 通告中樞：管理通告模板、已發布可接案、進行中拍攝，並在殺青時結算資金/統計/新聞。
## UI / ScheduleManager 只呼叫公開接口，不直接改內部字典。

signal job_published(instance_id: String, job_id: String)
signal job_accepted(instance_id: String, artist_id: String)
signal job_completed(instance_id: String, artist_id: String, completion_quality: int)
signal job_canceled(instance_id: String, artist_id: String)
signal job_board_changed()

const JOBS_DIR: String = "res://data/jobs/"

## 靜態模板：job_id -> JobResource
var job_templates: Dictionary = {}
## 已發布可接：instance_id -> JobInstance（PUBLISHED）
var available_jobs: Dictionary = {}
## 進行中：instance_id -> { "instance": JobInstance, "artist_id": String }
var active_jobs: Dictionary = {}

var _next_instance_serial: int = 1

func _ready() -> void:
	var count: int = load_all_job_templates()
	print("[JobManager] 通告模板载入完成，共 %d 则。" % count)
	refresh_job_board()
	if not GameFlowManager.day_advanced.is_connected(_on_day_advanced):
		GameFlowManager.day_advanced.connect(_on_day_advanced)

# ==========================================
# 模板载入
# ==========================================
func load_all_job_templates(dir_path: String = JOBS_DIR) -> int:
	job_templates.clear()
	_load_job_resources_in_dir(dir_path)
	return job_templates.size()

func _load_job_resources_in_dir(dir_path: String) -> void:
	var normalized_dir_path: String = dir_path.trim_suffix("/") + "/"
	var dir := DirAccess.open(normalized_dir_path)
	if dir == null:
		push_warning("[JobManager] 无法打开通告目录: " + normalized_dir_path)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				_load_job_resources_in_dir(normalized_dir_path.path_join(file_name))
		else:
			var res_path: String = _normalize_resource_path(normalized_dir_path, file_name)
			if res_path != "":
				var res: Resource = load(res_path)
				if res is JobResource:
					_register_template(res)
		file_name = dir.get_next()
	dir.list_dir_end()

func _normalize_resource_path(dir_path: String, file_name: String) -> String:
	if file_name.ends_with(".tres"):
		return dir_path.path_join(file_name)
	if file_name.ends_with(".tres.remap"):
		return dir_path.path_join(file_name.trim_suffix(".remap"))
	return ""

func _register_template(resource: JobResource) -> void:
	if resource.job_id.strip_edges() == "":
		push_warning("[JobManager] 有一则通告模板缺少 job_id，已跳过。")
		return
	if job_templates.has(resource.job_id):
		push_warning("[JobManager] 发现重复 job_id: %s，后者覆盖前者。" % resource.job_id)
	job_templates[resource.job_id] = resource

# ==========================================
# 通告板
# ==========================================
func refresh_job_board() -> int:
	available_jobs.clear()
	var published_count: int = 0
	for job_id in job_templates.keys():
		var instance_id: String = publish_job(job_id)
		if instance_id != "":
			published_count += 1
	job_board_changed.emit()
	print("[JobManager] 通告板已刷新，可接 %d 则。" % published_count)
	return published_count

func get_accept_block_reason(instance_id: String, artist_id: String) -> String:
	if not available_jobs.has(instance_id):
		return "通告不存在或已被接取。"
	if artist_id.strip_edges() == "":
		return "请先选择指派艺人。"
	var artist: ArtistInstance = ArtistManager.get_artist(artist_id)
	if artist == null:
		return "艺人尚未签约。"
	var job_instance: JobInstance = available_jobs[instance_id]
	if job_instance.base_job.invite_only:
		return "此通告僅接受製片人邀請接案。"
	if not _check_artist_qualification(job_instance, artist):
		return "资质不足，无法接取该通告。"
	return ""

func get_invite_threshold_for_job(job: JobResource) -> int:
	if job == null:
		return JobDayEvaluator.DEFAULT_INVITE_THRESHOLD
	if job.invite_threshold > 0:
		return job.invite_threshold
	return JobDayEvaluator.DEFAULT_INVITE_THRESHOLD

func get_invite_block_reason(instance_id: String, artist_id: String) -> String:
	if not available_jobs.has(instance_id):
		return "通告不存在或已被接取。"
	if artist_id.strip_edges() == "":
		return "請先選擇指派藝人。"
	var artist: ArtistInstance = ArtistManager.get_artist(artist_id)
	if artist == null:
		return "藝人尚未簽約。"
	var job_instance: JobInstance = available_jobs[instance_id]
	var threshold: int = get_invite_threshold_for_job(job_instance.base_job)
	if not JobDayEvaluator.can_invite_accept(artist, threshold):
		return "邀請資格不足（分數未達門檻 %d）。" % threshold
	return ""

func build_invite_detail_text(instance_id: String, artist_id: String = "") -> String:
	var job_instance: JobInstance = get_job_instance(instance_id)
	if job_instance == null:
		return ""
	var job: JobResource = job_instance.base_job
	var threshold: int = get_invite_threshold_for_job(job)
	var lines: PackedStringArray = PackedStringArray()
	lines.append("【製片人邀請接案】")
	if job.invite_only:
		lines.append("此通告僅能透過邀請管道接案。")
	lines.append("門檻分數：%d（聲望×0.4 + 口碑×0.3 + 名氣×0.15 + 人氣×0.10 + 完成通告×0.05）" % threshold)
	lines.append("拍攝規則：邀請接案後，拍攝日須維持各項門檻的 90%。")
	if artist_id.strip_edges() == "":
		lines.append("選擇藝人後顯示邀請分數明細。")
		return "\n".join(lines)

	var artist: ArtistInstance = ArtistManager.get_artist(artist_id)
	if artist == null:
		lines.append("藝人尚未簽約。")
		return "\n".join(lines)

	var score: float = JobDayEvaluator.calculate_invite_score(artist)
	var works: int = PlayerManager.successful_jobs_count
	lines.append("邀請分數：%.1f / %d（%s）" % [
		score,
		threshold,
		"可接案" if score >= float(threshold) else "不足",
	])
	lines.append(
		"  公司聲望 %d ×%.1f = %.1f" % [
			PlayerManager.company_reputation,
			JobDayEvaluator.INVITE_W_REPUTATION,
			float(PlayerManager.company_reputation) * JobDayEvaluator.INVITE_W_REPUTATION,
		]
	)
	lines.append(
		"  公司口碑 %d ×%.1f = %.1f" % [
			PlayerManager.company_public_opinion,
			JobDayEvaluator.INVITE_W_OPINION,
			float(PlayerManager.company_public_opinion) * JobDayEvaluator.INVITE_W_OPINION,
		]
	)
	lines.append(
		"  藝人名氣 %d ×%.1f = %.1f" % [
			artist.fame,
			JobDayEvaluator.INVITE_W_FAME,
			float(artist.fame) * JobDayEvaluator.INVITE_W_FAME,
		]
	)
	lines.append(
		"  藝人人氣 %d ×%.1f = %.1f" % [
			artist.popularity,
			JobDayEvaluator.INVITE_W_POPULARITY,
			float(artist.popularity) * JobDayEvaluator.INVITE_W_POPULARITY,
		]
	)
	lines.append(
		"  完成通告 %d ×%.1f = %.1f" % [
			works,
			JobDayEvaluator.INVITE_W_WORKS,
			float(works) * JobDayEvaluator.INVITE_W_WORKS,
		]
	)
	return "\n".join(lines)

func build_job_detail_text(instance_id: String, artist_id: String = "") -> String:
	var job_instance: JobInstance = get_job_instance(instance_id)
	if job_instance == null:
		return "请选择一则可接通告。"

	var job: JobResource = job_instance.base_job
	var lines: PackedStringArray = PackedStringArray()
	lines.append("【%s】" % job.job_name)
	lines.append("合作公司：%s" % _get_publisher_name(job.target_company_id))
	lines.append("有效拍摄日：%d 天 | 开机窗口：%d 周" % [
		job.get_required_shoot_days(),
		job.shoot_window_weeks,
	])
	lines.append("排程规则：%s" % build_schedule_rule_text(job))
	lines.append("完成酬劳：$%d | 名气 +%d" % [job.reward_money, job.reward_fame])
	lines.append("状态变化：疲劳 %s | 压力 %s" % [
		_build_scaled_status_text(job.add_fatigue, artist_id, "fatigue"),
		_build_scaled_status_text(job.add_stress, artist_id, "stress"),
	])

	var requirement_lines: PackedStringArray = _get_requirement_lines(job)
	if requirement_lines.is_empty():
		lines.append("门槛要求：无")
	else:
		lines.append("门槛要求：%s" % "、".join(requirement_lines))

	if artist_id.strip_edges() != "":
		var block_reason: String = get_accept_block_reason(instance_id, artist_id)
		var artist_name: String = _get_artist_display_name(artist_id)
		if block_reason == "":
			lines.append("指派艺人：%s（可接案）" % artist_name)
		else:
			lines.append("指派艺人：%s（%s）" % [artist_name, block_reason])

	return "\n".join(lines)

func publish_job(job_id: String) -> String:
	if not job_templates.has(job_id):
		push_warning("[JobManager] 发布失败，找不到模板: " + job_id)
		return ""

	var template: JobResource = job_templates[job_id]
	var instance := JobInstance.new(template)
	instance.transition_to(JobInstance.JobStatus.PUBLISHED)

	var instance_id: String = _make_instance_id(job_id)
	available_jobs[instance_id] = instance
	job_published.emit(instance_id, job_id)
	return instance_id

func get_available_job_summaries() -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	for instance_id in available_jobs.keys():
		summaries.append(_make_job_summary(instance_id, available_jobs[instance_id], ""))
	return summaries

func get_active_job_summaries() -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	for instance_id in active_jobs.keys():
		var entry: Dictionary = active_jobs[instance_id]
		var instance: JobInstance = entry.get("instance")
		var artist_id: String = str(entry.get("artist_id", ""))
		if instance != null:
			summaries.append(_make_job_summary(instance_id, instance, artist_id))
	return summaries

func get_jobs_by_company(company_id: String) -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	for instance_id in available_jobs.keys():
		var instance: JobInstance = available_jobs[instance_id]
		if instance.base_job.target_company_id == company_id:
			summaries.append(_make_job_summary(instance_id, instance, ""))
	return summaries

# ==========================================
# 接案 / 排程
# ==========================================
func try_accept_job(instance_id: String, artist_id: String) -> Dictionary:
	return _accept_job_internal(instance_id, artist_id, false)

func try_accept_job_invite(instance_id: String, artist_id: String, invite_threshold: int = JobDayEvaluator.DEFAULT_INVITE_THRESHOLD) -> Dictionary:
	return _accept_job_internal(instance_id, artist_id, true, invite_threshold)

func _accept_job_internal(
	instance_id: String,
	artist_id: String,
	use_invite: bool,
	invite_threshold: int = JobDayEvaluator.DEFAULT_INVITE_THRESHOLD
) -> Dictionary:
	if not available_jobs.has(instance_id):
		return {"success": false, "reason": "通告不存在或已被接取。"}

	var artist: ArtistInstance = ArtistManager.get_artist(artist_id)
	if artist == null:
		return {"success": false, "reason": "艺人尚未签约，无法接案。"}

	var job_instance: JobInstance = available_jobs[instance_id]
	var accepted: bool = (
		job_instance.try_accept_invite(artist, invite_threshold)
		if use_invite
		else job_instance.try_accept(artist)
	)
	if not accepted:
		return {
			"success": false,
			"reason": "邀请资格不足，无法接取该通告。" if use_invite else "资质不足，无法接取该通告。",
		}

	available_jobs.erase(instance_id)
	active_jobs[instance_id] = {
		"instance": job_instance,
		"artist_id": artist_id,
	}
	job_instance.start_shoot_window(TimeManager.total_days_elapsed)
	job_accepted.emit(instance_id, artist_id)
	job_board_changed.emit()
	return {
		"success": true,
		"instance_id": instance_id,
		"artist_id": artist_id,
		"job_id": job_instance.base_job.job_id,
		"job_name": job_instance.base_job.job_name,
		"required_shoot_days": job_instance.base_job.get_required_shoot_days(),
		"shoot_window_weeks": job_instance.base_job.shoot_window_weeks,
		"accept_mode": job_instance.accept_mode,
	}

func get_active_job_for_artist(artist_id: String) -> JobInstance:
	for instance_id in active_jobs.keys():
		var entry: Dictionary = active_jobs[instance_id]
		if str(entry.get("artist_id", "")) == artist_id:
			return entry.get("instance")
	return null

func get_active_job_entries_for_artist(artist_id: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for instance_id in active_jobs.keys():
		var entry: Dictionary = active_jobs[instance_id]
		if str(entry.get("artist_id", "")) != artist_id:
			continue
		var job_instance: JobInstance = entry.get("instance")
		if job_instance == null:
			continue
		entries.append({
			"instance_id": instance_id,
			"instance": job_instance,
			"job_name": job_instance.base_job.job_name,
		})
	return entries

func get_job_picker_options(artist_id: String) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for entry in get_active_job_entries_for_artist(artist_id):
		var instance_id: String = str(entry.get("instance_id", ""))
		var job_instance: JobInstance = entry.get("instance")
		if job_instance == null:
			continue
		var job: JobResource = job_instance.base_job
		var window_text: String = _build_window_progress_text(job_instance)
		options.append({
			"option_id": "job_%s" % instance_id,
			"tab": SchedulePickerManager.Tab.JOB,
			"kind": SchedulePickerManager.KIND_JOB,
			"title": job.job_name,
			"subtitle": "有效 %d/%d | %s | $%d" % [
				job_instance.qualified_shoot_days,
				job.get_required_shoot_days(),
				window_text,
				job.reward_money,
			],
			"schedule_type": ScheduleManager.ScheduleType.WORK_LOCAL,
			"task_data": job_instance,
			"lock_state": ScheduleManager.LockState.UNLOCKED,
			"disabled": false,
			"disabled_reason": "",
		})

	if options.is_empty():
		options.append({
			"option_id": "job_none",
			"tab": SchedulePickerManager.Tab.JOB,
			"kind": SchedulePickerManager.KIND_JOB,
			"title": "（尚無進行中通告）",
			"subtitle": "請先到通告中心接案",
			"schedule_type": ScheduleManager.ScheduleType.WORK_LOCAL,
			"task_data": null,
			"lock_state": ScheduleManager.LockState.UNLOCKED,
			"disabled": true,
			"disabled_reason": "尚無進行中通告，請先到通告中心接案。",
		})
	return options

func validate_job_picker_selection(artist_id: String, task_data) -> Dictionary:
	if task_data == null or not (task_data is JobInstance):
		return {"success": false, "reason": "請選擇一則進行中的通告。"}

	var matched: bool = false
	for entry in get_active_job_entries_for_artist(artist_id):
		if entry.get("instance") == task_data:
			matched = true
			break
	if not matched:
		return {"success": false, "reason": "該通告不屬於此藝人。"}
	return {"success": true}

func build_job_picker_detail_text(job_instance: JobInstance, artist_id: String = "") -> String:
	if job_instance == null:
		return "請選擇通告。"
	var job: JobResource = job_instance.base_job
	return "【%s】\n合作公司：%s\n有效拍摄：%d / %d 天\n%s\n酬劳：$%d | 名气 +%d\n状态变化：疲劳 %s | 压力 %s\n排程：%s" % [
		job.job_name,
		_get_publisher_name(job.target_company_id),
		job_instance.qualified_shoot_days,
		job.get_required_shoot_days(),
		_build_window_progress_text(job_instance),
		job.reward_money,
		job.reward_fame,
		_build_scaled_status_text(job.add_fatigue, artist_id, "fatigue"),
		_build_scaled_status_text(job.add_stress, artist_id, "stress"),
		build_schedule_rule_text(job),
	]

func get_job_instance(instance_id: String) -> JobInstance:
	if available_jobs.has(instance_id):
		return available_jobs[instance_id]
	if active_jobs.has(instance_id):
		return active_jobs[instance_id].get("instance")
	return null

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

func _on_day_advanced(date_snapshot: Dictionary) -> void:
	var current_total_day: int = int(date_snapshot.get("total_days_elapsed", TimeManager.total_days_elapsed))
	_check_expired_shoot_windows(current_total_day)

func _check_expired_shoot_windows(current_total_day: int) -> void:
	var expired_entries: Array[Dictionary] = []
	for instance_id in active_jobs.keys():
		var entry: Dictionary = active_jobs[instance_id]
		var job_instance: JobInstance = entry.get("instance")
		if job_instance == null:
			continue
		if job_instance.current_status in [
			JobInstance.JobStatus.COMPLETED,
			JobInstance.JobStatus.CANCELED,
		]:
			continue
		if job_instance.qualified_shoot_days >= job_instance.base_job.get_required_shoot_days():
			continue
		if not job_instance.is_window_expired(current_total_day):
			continue
		expired_entries.append({
			"instance_id": instance_id,
			"instance": job_instance,
			"artist_id": str(entry.get("artist_id", "")),
		})

	for entry in expired_entries:
		_settle_job_window_expired(
			entry.get("instance"),
			str(entry.get("artist_id", "")),
			str(entry.get("instance_id", ""))
		)

func get_shoot_cycle_name(shoot_cycle: int) -> String:
	match shoot_cycle:
		JobResource.ShootCycle.SHORT:
			return "短周期"
		JobResource.ShootCycle.LONG:
			return "长周期"
		_:
			return "未知"

func build_schedule_rule_text(job: JobResource) -> String:
	var required: int = job.get_required_shoot_days()
	var window_weeks: int = maxi(job.shoot_window_weeks, 1)
	return "接案后 %d 周内自行安排 %d 个有效拍摄日（可跳着排）" % [window_weeks, required]

func _build_window_progress_text(job_instance: JobInstance) -> String:
	if job_instance == null:
		return "窗口未定"
	var remaining_days: int = maxi(
		job_instance.get_window_end_total_day() - TimeManager.total_days_elapsed,
		0
	)
	return "窗口剩 %d 天" % remaining_days

# ==========================================
# 每日拍摄（由 ScheduleManager 调用）
# ==========================================
func process_shoot_day(artist_id: String, job_instance: JobInstance, is_absent: bool) -> Dictionary:
	if job_instance == null:
		return {"processed": false, "skipped": true, "reason": "null_instance"}

	if job_instance.current_status in [
		JobInstance.JobStatus.COMPLETED,
		JobInstance.JobStatus.CANCELED,
	]:
		ScheduleManager.clear_job_instance_from_schedules(artist_id, job_instance)
		return {"processed": false, "skipped": true, "reason": "job_already_settled"}

	var instance_id: String = _find_active_instance_id(job_instance)
	if instance_id == "":
		ScheduleManager.clear_job_instance_from_schedules(artist_id, job_instance)
		return {"processed": false, "skipped": true, "reason": "orphan_schedule_slot"}

	var previous_status: int = job_instance.current_status
	var shoot_result: Dictionary = job_instance.register_shoot_day(
		is_absent,
		ArtistManager.get_artist(artist_id)
	)
	if not shoot_result.get("processed", false):
		return {"processed": false}

	var result: Dictionary = {
		"processed": true,
		"completed": false,
		"instance_id": instance_id,
		"job_name": job_instance.base_job.job_name,
	}

	if job_instance.current_status == JobInstance.JobStatus.CANCELED:
		_settle_job_canceled(job_instance, artist_id, instance_id)
		result["canceled"] = true
		return result

	if previous_status != JobInstance.JobStatus.COMPLETED \
			and job_instance.current_status == JobInstance.JobStatus.COMPLETED:
		_settle_job_completed(job_instance, artist_id, instance_id)
		result["completed"] = true
		result["completion_quality"] = job_instance.completion_quality

	return result

# ==========================================
# 杀青 / 流产结算
# ==========================================
func _settle_job_completed(job_instance: JobInstance, artist_id: String, instance_id: String) -> void:
	var job: JobResource = job_instance.base_job
	var artist: ArtistInstance = ArtistManager.get_artist(artist_id)

	if job.reward_money > 0:
		PlayerManager.add_money(job.reward_money, "通告完成：%s" % job.job_name)
	if job.reward_fame > 0 and artist != null:
		artist.fame = clampi(artist.fame + job.reward_fame, 0, 999)

	PlayerManager.record_job_completed(job_instance.completion_quality)
	var standing: Dictionary = CompanyStandingResolver.apply_job_completion(
		job_instance.completion_quality,
		job.job_name
	)

	var quality_name: String = get_completion_quality_name(job_instance.completion_quality)
	var company_name: String = _get_publisher_name(job.target_company_id)
	var body: String = "%s 旗下艺人完成通告《%s》" % [PlayerManager.company_name, job.job_name]
	if company_name != "":
		body += "，合作方 %s" % company_name
	body += "，业界评价 %s。" % quality_name
	if int(standing.get("reputation_delta", 0)) != 0 or int(standing.get("public_opinion_delta", 0)) != 0:
		body += " 公司声望 %+d、口碑 %+d。" % [
			int(standing.get("reputation_delta", 0)),
			int(standing.get("public_opinion_delta", 0)),
		]

	NewsManager.add_news(
		"《%s》杀青" % job.job_name,
		body,
		NewsManager.MediaType.TEXT_MEDIA,
		NewsManager.NewsCategory.JOB,
		_get_news_importance(job_instance.completion_quality),
		artist_id,
		job.target_company_id,
		job.job_id
	)
	if job.is_major_job:
		NewsManager.queue_major_job_wrap(
			job.job_id,
			job.job_name,
			job.target_company_id,
			artist_id
		)
		if job_instance.completion_quality == CompletionQuality.Level.PERFECT:
			NewsManager.queue_major_job_hit(job.job_id, job.job_name, job.target_company_id)

	active_jobs.erase(instance_id)
	ScheduleManager.clear_job_instance_from_schedules(artist_id, job_instance)
	job_completed.emit(instance_id, artist_id, job_instance.completion_quality)
	job_board_changed.emit()
	print("[JobManager] 通告杀青：%s / %s" % [job.job_name, quality_name])

func _settle_job_window_expired(job_instance: JobInstance, artist_id: String, instance_id: String) -> void:
	var job: JobResource = job_instance.base_job
	job_instance.completion_quality = CompletionQuality.Level.FAILED
	PlayerManager.record_job_failed()
	CompanyStandingResolver.apply_job_failure(job.job_name, "拍摄窗口逾期")
	NewsManager.add_news(
		"《%s》拍摄窗口逾期" % job.job_name,
		"%s 的通告《%s》未在 %d 周窗口内凑齐 %d 个有效拍摄日，项目失败。" % [
			PlayerManager.company_name,
			job.job_name,
			job.shoot_window_weeks,
			job.get_required_shoot_days(),
		],
		NewsManager.MediaType.TEXT_MEDIA,
		NewsManager.NewsCategory.JOB,
		NewsManager.Importance.HIGH,
		artist_id,
		job.target_company_id,
		job.job_id
	)
	active_jobs.erase(instance_id)
	ScheduleManager.clear_job_instance_from_schedules(artist_id, job_instance)
	job_canceled.emit(instance_id, artist_id)
	job_board_changed.emit()
	print("[JobManager] 通告窗口逾期失败：%s" % job.job_name)

func _settle_job_canceled(job_instance: JobInstance, artist_id: String, instance_id: String) -> void:
	var job: JobResource = job_instance.base_job
	PlayerManager.record_job_failed()
	CompanyStandingResolver.apply_job_failure(job.job_name, "项目流产")
	NewsManager.add_news(
		"《%s》项目流产" % job.job_name,
		"%s 的通告《%s》因缺勤过多而终止。" % [PlayerManager.company_name, job.job_name],
		NewsManager.MediaType.TEXT_MEDIA,
		NewsManager.NewsCategory.JOB,
		NewsManager.Importance.HIGH,
		artist_id,
		job.target_company_id,
		job.job_id
	)
	active_jobs.erase(instance_id)
	ScheduleManager.clear_job_instance_from_schedules(artist_id, job_instance)
	job_canceled.emit(instance_id, artist_id)
	job_board_changed.emit()
	print("[JobManager] 通告流产：%s" % job.job_name)

# ==========================================
# 查询辅助
# ==========================================
func get_available_job_count() -> int:
	return available_jobs.size()

func get_active_job_count() -> int:
	return active_jobs.size()

func can_accept_any_job(artist_id: String) -> bool:
	var artist: ArtistInstance = ArtistManager.get_artist(artist_id)
	if artist == null:
		return false
	for instance_id in available_jobs.keys():
		var job_instance: JobInstance = available_jobs[instance_id]
		if _check_artist_qualification(job_instance, artist):
			return true
	return false

func find_first_acceptable_job(artist_id: String) -> String:
	var artist: ArtistInstance = ArtistManager.get_artist(artist_id)
	if artist == null:
		return ""
	for instance_id in available_jobs.keys():
		var job_instance: JobInstance = available_jobs[instance_id]
		if _check_artist_qualification(job_instance, artist):
			return instance_id
	return ""

# ==========================================
# 内部工具
# ==========================================
func _make_instance_id(job_id: String) -> String:
	var instance_id: String = "%s_%d" % [job_id, _next_instance_serial]
	_next_instance_serial += 1
	return instance_id

func _find_active_instance_id(job_instance: JobInstance) -> String:
	for instance_id in active_jobs.keys():
		if active_jobs[instance_id].get("instance") == job_instance:
			return instance_id
	return ""

func _check_artist_qualification(job_instance: JobInstance, artist: ArtistInstance) -> bool:
	if job_instance.current_status != JobInstance.JobStatus.PUBLISHED:
		return false
	for stat_name in _get_artist_stat_names():
		var required_value: int = job_instance.base_job.get("req_%s" % stat_name)
		var current_value: int = artist.get(stat_name)
		if required_value > 0 and current_value < required_value:
			return false
	return true

func _make_job_summary(instance_id: String, job_instance: JobInstance, artist_id: String) -> Dictionary:
	var job: JobResource = job_instance.base_job
	return {
		"instance_id": instance_id,
		"job_id": job.job_id,
		"job_name": job.job_name,
		"company_id": job.target_company_id,
		"company_name": _get_publisher_name(job.target_company_id),
		"reward_money": job.reward_money,
		"total_days": job.get_required_shoot_days(),
		"shoot_cycle": job.shoot_cycle,
		"shoot_cycle_name": get_shoot_cycle_name(job.shoot_cycle),
		"shoot_window_weeks": job.shoot_window_weeks,
		"status": job_instance.current_status,
		"status_name": JobInstance.JobStatus.keys()[job_instance.current_status],
		"artist_id": artist_id,
		"agency_name": ArtistManager.get_artist_agency_name(artist_id),
		"invite_only": job.invite_only,
		"invite_threshold": get_invite_threshold_for_job(job),
		"is_test_content": job.is_test_content,
		"shoot_progress": "%d/%d" % [
			job_instance.qualified_shoot_days,
			job.get_required_shoot_days(),
		],
	}

func _get_publisher_name(company_id: String) -> String:
	return CompanyDatabase.get_publisher_name(company_id)

func get_completion_quality_name(quality: int) -> String:
	return CompletionQuality.get_display_name(quality)

func _get_news_importance(quality: int) -> int:
	if quality == CompletionQuality.Level.PERFECT:
		return NewsManager.Importance.HIGH
	if quality == CompletionQuality.Level.SUCCESS:
		return NewsManager.Importance.NORMAL
	return NewsManager.Importance.LOW

func _get_artist_stat_names() -> Array[String]:
	return [
		"empathy", "timbre", "improvisation", "acting", "singing", "eloquence",
		"dynamism", "talent", "stamina", "deportment", "fashion", "confidence",
		"rebelliousness", "humor", "affinity", "fame", "popularity", "exposure", "morality",
	]

func _get_requirement_lines(job: JobResource) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	for stat_name in _get_artist_stat_names():
		var required_value: int = job.get("req_%s" % stat_name)
		if required_value > 0:
			lines.append("%s≥%d" % [_get_stat_display_name(stat_name), required_value])
	return lines

func _get_stat_display_name(stat_name: String) -> String:
	match stat_name:
		"empathy": return "共情"
		"timbre": return "音色"
		"improvisation": return "即兴"
		"acting": return "演技"
		"singing": return "歌艺"
		"eloquence": return "口才"
		"dynamism": return "动感"
		"talent": return "才华"
		"stamina": return "体能"
		"deportment": return "仪态"
		"fashion": return "时尚"
		"confidence": return "自信"
		"rebelliousness": return "叛逆"
		"humor": return "喜感"
		"affinity": return "亲和"
		"fame": return "名气"
		"popularity": return "人气"
		"exposure": return "曝光"
		"morality": return "道德"
		_: return stat_name

func _get_artist_display_name(artist_id: String) -> String:
	var resource: ArtistResource = ArtistManager.get_artist_resource(artist_id)
	if resource != null and resource.artist_name.strip_edges() != "":
		return resource.artist_name
	return artist_id

func export_save_state() -> Dictionary:
	var active_payload: Array = []
	for instance_id in active_jobs:
		var entry: Dictionary = active_jobs[instance_id]
		var job_instance: JobInstance = entry.get("instance")
		if job_instance == null:
			continue
		var payload: Dictionary = {
			"instance_id": instance_id,
			"job_id": job_instance.base_job.job_id,
			"artist_id": str(entry.get("artist_id", "")),
			"qualified_shoot_days": job_instance.qualified_shoot_days,
			"attempted_shoot_days": job_instance.attempted_shoot_days,
			"perfect_shoot_days": job_instance.perfect_shoot_days,
			"missed_shoot_days": job_instance.missed_shoot_days,
			"current_status": job_instance.current_status,
			"completion_quality": job_instance.completion_quality,
			"window_start_total_day": job_instance.window_start_total_day,
			"current_hype": job_instance.current_hype,
			"total_box_office": job_instance.total_box_office,
		}
		payload.merge(job_instance.export_accept_state())
		active_payload.append(payload)

	return {
		"next_instance_serial": _next_instance_serial,
		"active": active_payload,
	}

func import_save_state(data: Dictionary) -> void:
	available_jobs.clear()
	active_jobs.clear()
	if data == null:
		_next_instance_serial = 1
		return

	_next_instance_serial = maxi(int(data.get("next_instance_serial", 1)), 1)
	var active_list: Variant = data.get("active", [])
	if not (active_list is Array):
		return

	for entry_variant in active_list:
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		var instance_id: String = str(entry.get("instance_id", "")).strip_edges()
		var job_id: String = str(entry.get("job_id", "")).strip_edges()
		if instance_id == "" or job_id == "" or not job_templates.has(job_id):
			push_warning("[JobManager] 读档跳过无效进行中通告: %s / %s" % [instance_id, job_id])
			continue

		var template: JobResource = job_templates[job_id]
		var job_instance := JobInstance.new(template)
		job_instance.qualified_shoot_days = int(entry.get("qualified_shoot_days", 0))
		job_instance.attempted_shoot_days = int(entry.get("attempted_shoot_days", 0))
		job_instance.perfect_shoot_days = int(entry.get("perfect_shoot_days", 0))
		job_instance.missed_shoot_days = int(entry.get("missed_shoot_days", 0))
		job_instance.current_status = int(entry.get("current_status", JobInstance.JobStatus.SHOOTING))
		job_instance.completion_quality = int(entry.get("completion_quality", CompletionQuality.Level.NONE))
		job_instance.window_start_total_day = int(entry.get("window_start_total_day", 0))
		job_instance.current_hype = int(entry.get("current_hype", 0))
		job_instance.total_box_office = int(entry.get("total_box_office", 0))
		job_instance.import_accept_state(entry)

		active_jobs[instance_id] = {
			"instance": job_instance,
			"artist_id": str(entry.get("artist_id", "")),
		}
		_bump_serial_from_instance_id(instance_id, job_id)

func get_instance_id_for_job(job_instance: JobInstance) -> String:
	return _find_active_instance_id(job_instance)

func _bump_serial_from_instance_id(instance_id: String, job_id: String) -> void:
	var prefix: String = "%s_" % job_id
	if not instance_id.begins_with(prefix):
		return
	var tail: String = instance_id.substr(prefix.length())
	if tail.is_valid_int():
		_next_instance_serial = maxi(_next_instance_serial, int(tail) + 1)
