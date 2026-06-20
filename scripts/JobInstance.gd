class_name JobInstance
extends RefCounted

var base_job: JobResource

enum JobStatus {
	UNPUBLISHED, PUBLISHED, NEGOTIATING, ACCEPTED,
	SHOOTING, COMPLETED, PROMOTING, SCREENING,
	OFF_SHELVES, CANCELED
}

var current_status: int = JobStatus.UNPUBLISHED
var completion_quality: int = CompletionQuality.Level.NONE

## 有效拍攝日（成功/完美）累計，達 required 即杀青
var qualified_shoot_days: int = 0
## 已結算拍攝日次數（含失败日）
var attempted_shoot_days: int = 0
## 有效日中的「完美」日數，供結案檔位參考
var perfect_shoot_days: int = 0
var missed_shoot_days: int = 0
var current_hype: int = 0
var total_box_office: int = 0
## 接案當日 TimeManager.total_days_elapsed，用於開機窗口
var window_start_total_day: int = 0

## 接案快照（JobDayEvaluator 使用）
var accept_mode: int = JobDayEvaluator.ACCEPT_MODE_NORMAL
var accept_req_snapshot: Dictionary = {}
var accept_shoot_floor: Dictionary = {}
var accept_total_day: int = 0

func _init(job_resource: JobResource):
	base_job = job_resource

func try_accept(artist) -> bool:
	if current_status != JobStatus.PUBLISHED:
		print("操作失败：该通告当前不可接取。")
		return false

	print("--- 开始资质审核：", base_job.job_name, " ---")
	for stat_name in JobDayEvaluator.get_stat_names():
		var required_value: int = int(base_job.get("req_%s" % stat_name))
		var current_value: int = int(artist.get(stat_name))
		if required_value > 0 and current_value < required_value:
			print("被拒：%s 不达标！要求:%s 当前:%s" % [stat_name, required_value, current_value])
			return false

	print("审核通过！成功接取通告。")
	_commit_accept_snapshot(artist, JobDayEvaluator.ACCEPT_MODE_NORMAL)
	transition_to(JobStatus.ACCEPTED)
	return true

func try_accept_invite(artist, invite_threshold: int = JobDayEvaluator.DEFAULT_INVITE_THRESHOLD) -> bool:
	if current_status != JobStatus.PUBLISHED:
		print("操作失败：该通告当前不可接取。")
		return false
	if artist == null:
		return false
	if not JobDayEvaluator.can_invite_accept(artist, invite_threshold):
		print("邀请分数不足，无法接取该通告。")
		return false

	print("--- 制片人邀请接案：", base_job.job_name, " ---")
	_commit_accept_snapshot(artist, JobDayEvaluator.ACCEPT_MODE_INVITE)
	transition_to(JobStatus.ACCEPTED)
	return true

func _commit_accept_snapshot(_artist, mode: int) -> void:
	accept_mode = mode
	accept_total_day = TimeManager.total_days_elapsed
	accept_req_snapshot = JobDayEvaluator.build_accept_req_snapshot(base_job)
	accept_shoot_floor = JobDayEvaluator.build_accept_shoot_floors(base_job)

func start_shoot_window(start_total_day: int) -> void:
	window_start_total_day = maxi(start_total_day, 0)

func get_window_end_total_day() -> int:
	return window_start_total_day + base_job.get_shoot_window_days()

func is_window_expired(current_total_day: int) -> bool:
	if window_start_total_day <= 0:
		return false
	return current_total_day > get_window_end_total_day()

func get_remaining_qualified_days_needed() -> int:
	return maxi(base_job.get_required_shoot_days() - qualified_shoot_days, 0)

func transition_to(new_status: int, artist = null) -> void:
	current_status = new_status
	print("通告 [", base_job.job_name, "] 状态变更为: ", JobStatus.keys()[current_status])

	match current_status:
		JobStatus.COMPLETED:
			_finalize_completion_quality(artist)
			print(">>> 项目杀青！最终评级: ", get_completion_quality_display_name(completion_quality))
		JobStatus.CANCELED:
			print(">>> 警告！项目流产，准备结算！")
			completion_quality = CompletionQuality.Level.FAILED

## 單日拍攝結算；僅成功/完美计入 qualified_shoot_days
func register_shoot_day(is_absent: bool, artist) -> Dictionary:
	if current_status != JobStatus.SHOOTING and current_status != JobStatus.ACCEPTED:
		return {"processed": false}

	current_status = JobStatus.SHOOTING
	attempted_shoot_days += 1

	var day_quality: int = CompletionQuality.Level.FAILED
	var eval_detail: Dictionary = {}
	if is_absent:
		missed_shoot_days += 1
		print("[缺勤] %s 本日拍攝失败。" % base_job.job_name)
		if missed_shoot_days >= 3:
			transition_to(JobStatus.CANCELED)
			return {
				"processed": true,
				"day_quality": day_quality,
				"qualified_gained": false,
				"canceled": true,
			}
	else:
		eval_detail = JobDayEvaluator.evaluate_shoot_day(artist, self)
		day_quality = int(eval_detail.get("quality", CompletionQuality.Level.FAILED))
		if is_successful_quality(day_quality):
			qualified_shoot_days += 1
			if day_quality == CompletionQuality.Level.PERFECT:
				perfect_shoot_days += 1
			print("[拍摄] %s 有效日 %d / %d（本日%s）" % [
				base_job.job_name,
				qualified_shoot_days,
				base_job.get_required_shoot_days(),
				get_completion_quality_display_name(day_quality),
			])
		else:
			print(
				"[拍摄] %s 本日未计入有效日（失败：%s）。" % [
					base_job.job_name,
					str(eval_detail.get("reason", "unknown")),
				]
			)

	if qualified_shoot_days >= base_job.get_required_shoot_days():
		transition_to(JobStatus.COMPLETED, artist)
		return {
			"processed": true,
			"day_quality": day_quality,
			"qualified_gained": is_successful_quality(day_quality),
			"completed": true,
			"eval_detail": eval_detail,
		}

	return {
		"processed": true,
		"day_quality": day_quality,
		"qualified_gained": is_successful_quality(day_quality),
		"eval_detail": eval_detail,
	}

static func is_successful_quality(quality: int) -> bool:
	return CompletionQuality.is_successful(quality)

static func is_completed_outcome(quality: int) -> bool:
	return CompletionQuality.is_completed_outcome(quality)

static func get_completion_quality_display_name(quality: int) -> String:
	return CompletionQuality.get_display_name(quality)

func _finalize_completion_quality(artist) -> void:
	if missed_shoot_days > 0:
		completion_quality = CompletionQuality.Level.SUCCESS
	elif perfect_shoot_days >= base_job.get_required_shoot_days():
		completion_quality = CompletionQuality.Level.PERFECT
	elif artist == null:
		completion_quality = CompletionQuality.Level.SUCCESS
	else:
		var wrap_eval: Dictionary = JobDayEvaluator.evaluate_shoot_day(artist, self)
		var wrap_quality: int = int(wrap_eval.get("quality", CompletionQuality.Level.SUCCESS))
		if wrap_quality == CompletionQuality.Level.PERFECT:
			completion_quality = CompletionQuality.Level.PERFECT
		elif is_successful_quality(wrap_quality):
			completion_quality = CompletionQuality.Level.SUCCESS
		else:
			completion_quality = CompletionQuality.Level.SUCCESS

func export_accept_state() -> Dictionary:
	return {
		"accept_mode": accept_mode,
		"accept_req_snapshot": accept_req_snapshot.duplicate(true),
		"accept_shoot_floor": accept_shoot_floor.duplicate(true),
		"accept_total_day": accept_total_day,
	}

func import_accept_state(data: Dictionary) -> void:
	if data == null:
		return
	accept_mode = int(data.get("accept_mode", JobDayEvaluator.ACCEPT_MODE_NORMAL))
	accept_total_day = int(data.get("accept_total_day", 0))
	var req_snap: Variant = data.get("accept_req_snapshot", {})
	if req_snap is Dictionary:
		accept_req_snapshot = req_snap.duplicate(true)
	var floor_snap: Variant = data.get("accept_shoot_floor", {})
	if floor_snap is Dictionary:
		accept_shoot_floor = floor_snap.duplicate(true)
