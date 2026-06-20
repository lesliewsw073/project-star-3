extends Node

## 游戏总控：阶段状态机 + 日推进 + 周日会议 + 每日三分支（剧情锁 / 跟随 / 自由探索）。

signal day_advanced(date_snapshot: Dictionary)
signal day_settlement_started(date_snapshot: Dictionary)
signal day_settlement_finished(date_snapshot: Dictionary)
signal meeting_started(date_snapshot: Dictionary)
signal meeting_finished(date_snapshot: Dictionary)
signal weekly_report_ready(advices: Array)
signal week_schedule_committed(signed_artist_count: int)
signal phase_changed(new_phase: int)
signal day_mode_changed(day_mode: int)
signal follow_day_finished(artist_ids: Array)
signal story_lock_started(event_id: String, days: int)
signal story_lock_finished(event_id: String)
signal map_entered()
signal map_exited()
signal work_report_requested(reports: Array)
signal daily_news_requested(edition: Array)

enum GamePhase {
	STORY,
	FIRST_MEETING,
	WEEKLY_MEETING,
	DAY_OPERATION,
}

enum DayMode {
	STORY_LOCK,
	FOLLOW,
	FREE,
}

var game_phase: int = GamePhase.STORY
var story_lock_days_remaining: int = 0
var story_lock_event_id: String = ""
var is_exploring_map: bool = false
var day_settlement_done: bool = false
var _is_transitioning: bool = false
var _begin_day_queued: bool = false
var _dismiss_report_queued: bool = false
var _finish_follow_queued: bool = false
var _end_day_queued: bool = false
var _finish_today_queued: bool = false
var _work_report_dismissed: bool = false
var _daily_news_dismissed: bool = false
var _awaiting_daily_news: bool = false
var initial_sign_completed: bool = false

var is_meeting_phase: bool:
	get:
		return game_phase == GamePhase.FIRST_MEETING or game_phase == GamePhase.WEEKLY_MEETING

func _ready() -> void:
	_sync_story_time_presentation()
	print("[GameFlowManager] 就绪，阶段：%s" % get_phase_name())

func get_day_mode() -> int:
	if game_phase != GamePhase.DAY_OPERATION:
		return -1
	_clear_transient_story_visit_lock(false)
	if story_lock_days_remaining > 0:
		return DayMode.STORY_LOCK
	if FollowPlanManager.has_follow_today():
		return DayMode.FOLLOW
	return DayMode.FREE

func get_day_mode_name(day_mode: int = -1) -> String:
	var target_mode: int = get_day_mode() if day_mode < 0 else day_mode
	match target_mode:
		DayMode.STORY_LOCK:
			return "剧情占用"
		DayMode.FOLLOW:
			return "跟随日"
		DayMode.FREE:
			return "自由探索"
		_:
			return "未知"

func get_day_mode_hint() -> String:
	var day_mode: int = get_day_mode()
	if day_mode < 0:
		return ""
	match day_mode:
		DayMode.STORY_LOCK:
			var label: String = story_lock_event_id
			if label.strip_edges() == "":
				label = "特殊剧情"
			return "今日模式：%s（剩 %d 天，不可跟隨／不可進地圖）" % [
				label,
				story_lock_days_remaining,
			]
		DayMode.FOLLOW:
			var names: PackedStringArray = PackedStringArray()
			for artist_id in FollowPlanManager.get_today_follow_artist_ids():
				names.append(artist_id)
			return "今日模式：跟隨 %s（不可進地圖）" % "、".join(names)
		DayMode.FREE:
			if is_exploring_map:
				return "今日模式：自由探索（大地圖中）"
			return "今日模式：自由探索（可進大地圖）"
	return ""

func get_phase_name(phase: int = -1) -> String:
	var target_phase: int = game_phase if phase < 0 else phase
	match target_phase:
		GamePhase.STORY:
			return "开局剧情"
		GamePhase.FIRST_MEETING:
			return "首次会议（12/31）"
		GamePhase.WEEKLY_MEETING:
			return "周日会议"
		GamePhase.DAY_OPERATION:
			return "日常营运"
		_:
			return "未知"

func get_phase_hint() -> String:
	match game_phase:
		GamePhase.STORY:
			return "目前階段：開局劇情（時間尚未開始）"
		GamePhase.FIRST_MEETING:
			return "目前階段：12月31日首次會議（無當日行程，排定下週後按「結束週日會議」）"
		GamePhase.WEEKLY_MEETING:
			return "目前階段：週日會議（按「結束週日會議」提交下週行程）"
		GamePhase.DAY_OPERATION:
			var hint: String = "目前階段：日常營運"
			var day_hint: String = get_day_mode_hint()
			if day_hint != "":
				hint += "\n" + day_hint
			return hint
		_:
			return "目前階段：未知"

## 劇情鎖專用（內部）；主畫面請用 can_finish_today()。
func can_end_day() -> bool:
	return (
		game_phase == GamePhase.DAY_OPERATION
		and get_day_mode() == DayMode.STORY_LOCK
		and story_lock_days_remaining > 0
	)

## 主畫面「結束今日／結束探索／繼續劇情」是否可用（依日模式分派）。
func can_finish_today() -> bool:
	if game_phase != GamePhase.DAY_OPERATION or _is_transitioning:
		return false
	match get_day_mode():
		DayMode.STORY_LOCK:
			return story_lock_days_remaining > 0
		DayMode.FREE:
			return not day_settlement_done
		DayMode.FOLLOW:
			return (
				day_settlement_done
				and _work_report_dismissed
				and not StoryPlaybackController.is_playing()
			)
		_:
			return false

func can_end_meeting() -> bool:
	return is_meeting_phase

func can_save_game() -> bool:
	return is_meeting_phase

func can_enter_map() -> bool:
	return (
		game_phase == GamePhase.DAY_OPERATION
		and get_day_mode() == DayMode.FREE
		and not is_exploring_map
	)

func can_exit_map() -> bool:
	return game_phase == GamePhase.DAY_OPERATION and is_exploring_map

func enter_map() -> Dictionary:
	if _awaiting_daily_news and not _daily_news_dismissed:
		return {
			"success": false,
			"reason": "daily_news_pending",
		}
	if not can_enter_map():
		return {
			"success": false,
			"reason": _get_map_block_reason(),
		}
	is_exploring_map = true
	map_entered.emit()
	day_mode_changed.emit(get_day_mode())
	return {"success": true}

func exit_map() -> Dictionary:
	if not can_exit_map() and not (game_phase == GamePhase.DAY_OPERATION and is_exploring_map):
		return {"success": false, "reason": "当前不在大地图。"}

	var should_settle: bool = (
		game_phase == GamePhase.DAY_OPERATION
		and get_day_mode() == DayMode.FREE
		and not day_settlement_done
	)

	if is_exploring_map:
		is_exploring_map = false
		map_exited.emit()
		day_mode_changed.emit(get_day_mode())

	if should_settle:
		_trigger_work_report()
		return {"success": true, "reason": "work_report"}

	return {"success": true}

func start_story_lock(days: int, event_id: String = "") -> void:
	var safe_days: int = maxi(days, 0)
	if safe_days <= 0:
		return
	if is_exploring_map:
		is_exploring_map = false
		map_exited.emit()
	story_lock_days_remaining = safe_days
	story_lock_event_id = event_id.strip_edges()
	story_lock_started.emit(story_lock_event_id, safe_days)
	day_mode_changed.emit(get_day_mode())
	print("[GameFlowManager] 剧情锁开始：%s / %d 天" % [story_lock_event_id, safe_days])

func is_initial_sign_completed() -> bool:
	if initial_sign_completed:
		return true
	return ArtistManager.get_signed_count() > 0

func needs_initial_sign() -> bool:
	return not is_initial_sign_completed()

func mark_initial_sign_completed() -> void:
	initial_sign_completed = true

func _clear_transient_story_visit_lock(emit_updates: bool = true) -> void:
	if story_lock_days_remaining <= 0:
		return
	if not story_lock_event_id.begins_with("story_visit_"):
		return
	var finished_event_id: String = story_lock_event_id
	story_lock_days_remaining = 0
	story_lock_event_id = ""
	if emit_updates:
		story_lock_finished.emit(finished_event_id)
		day_mode_changed.emit(DayMode.FREE)

func finish_opening_story() -> void:
	if game_phase != GamePhase.STORY:
		push_warning("[GameFlowManager] 只有开局剧情阶段可以调用 finish_opening_story()。")
		return
	if needs_initial_sign():
		push_warning("[GameFlowManager] 請先完成開局 3 選 1 簽約。")
		return
	enter_first_meeting()

func enter_first_meeting() -> void:
	game_phase = GamePhase.FIRST_MEETING
	TimeManager.reset_to_first_meeting_sunday()
	weekly_report_ready.emit(SecretaryManager.generate_weekly_advice())
	meeting_started.emit(TimeManager.get_date_snapshot())
	phase_changed.emit(game_phase)

func finish_today() -> void:
	if not can_finish_today():
		push_warning(
			"[GameFlowManager] 当前无法结束今日：%s / %s"
			% [get_phase_name(), get_day_mode_name()]
		)
		return
	if _finish_today_queued:
		return
	_finish_today_queued = true
	call_deferred("_do_finish_today")

func _do_finish_today() -> void:
	_finish_today_queued = false
	if not can_finish_today():
		return
	if _is_transitioning:
		finish_today()
		return

	match get_day_mode():
		DayMode.STORY_LOCK:
			end_day()
		DayMode.FREE:
			if is_exploring_map:
				exit_map()
			else:
				_trigger_work_report()
		DayMode.FOLLOW:
			notify_follow_stories_finished()
		_:
			push_warning("[GameFlowManager] finish_today 不支援的模式。")

func end_day() -> void:
	if not can_end_day():
		push_warning("[GameFlowManager] 当前阶段无法结束今日：%s" % get_phase_name())
		return
	if _end_day_queued:
		return
	_end_day_queued = true
	call_deferred("_do_end_day")

func _do_end_day() -> void:
	_end_day_queued = false
	if not can_end_day():
		return
	if _is_transitioning:
		end_day()
		return
	if day_settlement_done:
		push_warning("[GameFlowManager] 今日已結算，跳過重複結算。")
		_advance_story_lock_day()
		_finish_day_and_advance()
		return

	_is_transitioning = true
	if is_exploring_map:
		is_exploring_map = false
		map_exited.emit()

	var ending: Dictionary = TimeManager.get_date_snapshot()
	_run_day_settlement(ending)
	_advance_story_lock_day()
	_finish_day_and_advance()
	_is_transitioning = false

func end_meeting() -> void:
	if not can_end_meeting():
		push_warning("[GameFlowManager] 当前不在会议阶段，无法结束会议。")
		return

	if is_exploring_map:
		exit_map()

	var was_first_meeting: bool = game_phase == GamePhase.FIRST_MEETING
	var committed_count: int = ScheduleManager.commit_next_week_schedules()
	FollowPlanManager.commit_next_week_follow_plan()
	week_schedule_committed.emit(committed_count)

	game_phase = GamePhase.DAY_OPERATION

	if was_first_meeting:
		TimeManager.reset_to_new_year_monday(TimeManager.year, TimeManager.total_days_elapsed + 1)
	else:
		TimeManager.advance_day()

	meeting_finished.emit(TimeManager.get_date_snapshot())
	phase_changed.emit(game_phase)
	day_advanced.emit(TimeManager.get_date_snapshot())
	day_mode_changed.emit(get_day_mode())
	begin_operational_day()

func begin_operational_day() -> void:
	if _begin_day_queued:
		return
	_begin_day_queued = true
	call_deferred("_do_begin_operational_day")

func _do_begin_operational_day() -> void:
	_begin_day_queued = false
	if _is_transitioning:
		begin_operational_day()
		return
	if game_phase != GamePhase.DAY_OPERATION:
		return
	_is_transitioning = true
	day_settlement_done = false
	_work_report_dismissed = false
	_daily_news_dismissed = false
	_awaiting_daily_news = false
	match get_day_mode():
		DayMode.STORY_LOCK:
			pass
		DayMode.FOLLOW:
			_trigger_work_report()
		DayMode.FREE:
			if not is_exploring_map:
				_try_begin_free_day_with_news()
	_is_transitioning = false

func dismiss_work_report() -> void:
	if _dismiss_report_queued:
		return
	_dismiss_report_queued = true
	call_deferred("_do_dismiss_work_report")

func _do_dismiss_work_report() -> void:
	_dismiss_report_queued = false
	if _is_transitioning:
		dismiss_work_report()
		return
	if not day_settlement_done:
		return
	_work_report_dismissed = true
	_is_transitioning = true
	if get_day_mode() == DayMode.FOLLOW:
		follow_day_finished.emit(FollowPlanManager.get_today_follow_artist_ids())
	else:
		_finish_day_and_advance()
	_is_transitioning = false

func notify_follow_stories_finished() -> void:
	if _finish_follow_queued:
		return
	_finish_follow_queued = true
	call_deferred("_do_notify_follow_stories_finished")

func _do_notify_follow_stories_finished() -> void:
	_finish_follow_queued = false
	if _is_transitioning:
		notify_follow_stories_finished()
		return
	_is_transitioning = true
	_finish_day_and_advance()
	_is_transitioning = false

func dismiss_daily_news() -> void:
	if not _awaiting_daily_news or _daily_news_dismissed:
		return
	_daily_news_dismissed = true
	NewsManager.mark_daily_edition_shown()
	if can_enter_map():
		_awaiting_daily_news = false
		enter_map()

func _try_begin_free_day_with_news() -> void:
	NewsManager.build_daily_edition_for_today()
	if NewsManager.has_daily_edition_for_today():
		_awaiting_daily_news = true
		daily_news_requested.emit(NewsManager.get_daily_edition())
		return
	enter_map()

func _trigger_work_report() -> void:
	if day_settlement_done:
		return
	_work_report_dismissed = false
	if is_exploring_map:
		is_exploring_map = false
		map_exited.emit()

	var ending: Dictionary = TimeManager.get_date_snapshot()
	_run_day_settlement_with_report(ending)
	day_settlement_done = true
	day_mode_changed.emit(get_day_mode())

func _run_day_settlement_with_report(date_snapshot: Dictionary) -> void:
	day_settlement_started.emit(date_snapshot)
	var reports: Array = ScheduleManager.settle_day_and_build_report(date_snapshot["day_index"])
	ArtistManager.advance_day()
	day_settlement_finished.emit(date_snapshot)
	work_report_requested.emit(reports)

func _finish_day_and_advance() -> void:
	var ending: Dictionary = TimeManager.get_date_snapshot()
	if ending.get("is_week_end", false):
		game_phase = GamePhase.WEEKLY_MEETING
		weekly_report_ready.emit(SecretaryManager.generate_weekly_advice())
		meeting_started.emit(ending)
		phase_changed.emit(game_phase)
		day_mode_changed.emit(-1)
		day_settlement_done = false
		_work_report_dismissed = false
		return

	day_advanced.emit(TimeManager.advance_day())
	day_settlement_done = false
	_work_report_dismissed = false
	day_mode_changed.emit(get_day_mode())
	begin_operational_day()

func _advance_story_lock_day() -> void:
	if story_lock_days_remaining <= 0:
		return
	story_lock_days_remaining -= 1
	if story_lock_days_remaining <= 0:
		var finished_event_id: String = story_lock_event_id
		story_lock_event_id = ""
		story_lock_finished.emit(finished_event_id)

func _run_day_settlement(date_snapshot: Dictionary) -> void:
	day_settlement_started.emit(date_snapshot)
	ScheduleManager.execute_today(date_snapshot["day_index"])
	ArtistManager.advance_day()
	day_settlement_finished.emit(date_snapshot)

func _get_map_block_reason() -> String:
	if game_phase != GamePhase.DAY_OPERATION:
		return "当前不在日常营运阶段。"
	match get_day_mode():
		DayMode.STORY_LOCK:
			return "剧情占用日，无法进入大地图。"
		DayMode.FOLLOW:
			return "跟随日无法进入大地图，请先结束今日。"
		_:
			if is_exploring_map:
				return "已经在大地图中。"
			return "当前无法进入大地图。"

func _sync_story_time_presentation() -> void:
	if game_phase == GamePhase.STORY:
		TimeManager.set_display_override("開局劇情進行中（時間尚未開始）")
	elif TimeManager.has_display_override() and game_phase == GamePhase.DAY_OPERATION:
		TimeManager.clear_display_override()

func export_save_state() -> Dictionary:
	return {
		"game_phase": game_phase,
		"is_meeting_phase": is_meeting_phase,
		"story_lock_days_remaining": story_lock_days_remaining,
		"story_lock_event_id": story_lock_event_id,
		"is_exploring_map": is_exploring_map,
		"day_settlement_done": day_settlement_done,
		"work_report_dismissed": _work_report_dismissed,
		"daily_news_dismissed": _daily_news_dismissed,
		"awaiting_daily_news": _awaiting_daily_news,
		"initial_sign_completed": initial_sign_completed,
	}

func import_save_state(data: Dictionary) -> void:
	if data.has("game_phase"):
		game_phase = int(data["game_phase"])
	elif bool(data.get("is_meeting_phase", false)):
		game_phase = GamePhase.WEEKLY_MEETING
	else:
		game_phase = GamePhase.DAY_OPERATION

	story_lock_days_remaining = maxi(int(data.get("story_lock_days_remaining", 0)), 0)
	story_lock_event_id = str(data.get("story_lock_event_id", ""))
	_clear_transient_story_visit_lock(false)
	is_exploring_map = bool(data.get("is_exploring_map", false))
	day_settlement_done = bool(data.get("day_settlement_done", false))
	_work_report_dismissed = bool(data.get("work_report_dismissed", false))
	_daily_news_dismissed = bool(data.get("daily_news_dismissed", false))
	_awaiting_daily_news = bool(data.get("awaiting_daily_news", false))
	initial_sign_completed = bool(data.get("initial_sign_completed", false))
	if not initial_sign_completed and ArtistManager.get_signed_count() > 0:
		initial_sign_completed = true

	if is_exploring_map and get_day_mode() != DayMode.FREE:
		is_exploring_map = false
	if day_settlement_done and game_phase != GamePhase.DAY_OPERATION:
		day_settlement_done = false

	_sync_story_time_presentation()
	phase_changed.emit(game_phase)
	day_mode_changed.emit(get_day_mode())
