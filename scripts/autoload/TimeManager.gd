extends Node

signal day_ending(date_snapshot: Dictionary)
signal day_started(date_snapshot: Dictionary)
signal date_changed(date_snapshot: Dictionary)
signal week_ended(date_snapshot: Dictionary)
signal week_started(date_snapshot: Dictionary)
signal month_ended(date_snapshot: Dictionary)
signal month_started(date_snapshot: Dictionary)
signal year_ended(date_snapshot: Dictionary)
signal year_started(date_snapshot: Dictionary)

const DAYS_PER_WEEK: int = 7
const WEEKS_PER_MONTH: int = 4
const MONTHS_PER_YEAR: int = 12
const DAY_NAMES: Array[String] = [
	"星期一",
	"星期二",
	"星期三",
	"星期四",
	"星期五",
	"星期六",
	"星期日"
]

var year: int = 1
var month: int = 1
var week: int = 1
var day_index: int = 0
var total_days_elapsed: int = 0

var _display_override: String = ""

func _ready() -> void:
	date_changed.emit(get_date_snapshot())

func reset(
	start_year: int = 1,
	start_month: int = 1,
	start_week: int = 1,
	start_day_index: int = 0,
	start_total_days_elapsed: int = 0
) -> void:
	year = maxi(start_year, 1)
	month = clampi(start_month, 1, MONTHS_PER_YEAR)
	week = clampi(start_week, 1, WEEKS_PER_MONTH)
	day_index = clampi(start_day_index, 0, DAYS_PER_WEEK - 1)
	total_days_elapsed = maxi(start_total_days_elapsed, 0)
	date_changed.emit(get_date_snapshot())

func advance_day() -> Dictionary:
	var ending_snapshot: Dictionary = get_date_snapshot()
	day_ending.emit(ending_snapshot)

	var should_end_week: bool = is_week_end()
	var should_end_month: bool = is_month_end()
	var should_end_year: bool = is_year_end()

	if should_end_year:
		year_ended.emit(ending_snapshot)
	if should_end_month:
		month_ended.emit(ending_snapshot)
	if should_end_week:
		week_ended.emit(ending_snapshot)

	_add_one_day()

	var started_snapshot: Dictionary = get_date_snapshot()
	day_started.emit(started_snapshot)

	if should_end_year:
		year_started.emit(started_snapshot)
	if should_end_month:
		month_started.emit(started_snapshot)
	if should_end_week:
		week_started.emit(started_snapshot)

	date_changed.emit(started_snapshot)
	return started_snapshot

func advance_days(day_count: int) -> Dictionary:
	var safe_count: int = maxi(day_count, 0)
	for _i in range(safe_count):
		advance_day()
	return get_date_snapshot()

func get_date_snapshot() -> Dictionary:
	return {
		"year": year,
		"month": month,
		"week": week,
		"day_index": day_index,
		"day_name": get_day_name(),
		"day_of_month": get_day_of_month(),
		"total_days_elapsed": total_days_elapsed,
		"is_week_end": is_week_end(),
		"is_month_end": is_month_end(),
		"is_year_end": is_year_end(),
		"display_text": get_display_text()
	}

func get_day_name(target_day_index: int = day_index) -> String:
	var safe_day_index: int = clampi(target_day_index, 0, DAYS_PER_WEEK - 1)
	return DAY_NAMES[safe_day_index]

func get_day_of_month() -> int:
	return ((week - 1) * DAYS_PER_WEEK) + day_index + 1

func get_display_text() -> String:
	if _display_override.strip_edges() != "":
		return _display_override.strip_edges()
	return "第%d年 %d月 第%d週 %s" % [year, month, week, get_day_name()]

func has_display_override() -> bool:
	return _display_override.strip_edges() != ""

func set_display_override(text: String) -> void:
	_display_override = text.strip_edges()
	date_changed.emit(get_date_snapshot())

func clear_display_override() -> void:
	if _display_override == "":
		return
	_display_override = ""
	date_changed.emit(get_date_snapshot())

## 12/31 周日：首次纯会议日（无当日行程）
func reset_to_first_meeting_sunday(game_year: int = 1) -> void:
	reset(game_year, 12, 4, DAYS_PER_WEEK - 1, 0)
	set_display_override("第%d年 12月31日 星期日" % game_year)

## 1/1 周一：首次会议结束后进入正式周循环
func reset_to_new_year_monday(game_year: int = 1, total_days: int = 1) -> void:
	clear_display_override()
	reset(game_year, 1, 1, 0, total_days)

func is_week_start() -> bool:
	return day_index == 0

func is_week_end() -> bool:
	return day_index == DAYS_PER_WEEK - 1

func is_month_start() -> bool:
	return week == 1 and is_week_start()

func is_month_end() -> bool:
	return week == WEEKS_PER_MONTH and is_week_end()

func is_year_start() -> bool:
	return month == 1 and is_month_start()

func is_year_end() -> bool:
	return month == MONTHS_PER_YEAR and is_month_end()

func _add_one_day() -> void:
	total_days_elapsed += 1
	day_index += 1

	if day_index < DAYS_PER_WEEK:
		return

	day_index = 0
	week += 1

	if week <= WEEKS_PER_MONTH:
		return

	week = 1
	month += 1

	if month <= MONTHS_PER_YEAR:
		return

	month = 1
	year += 1

func export_save_state() -> Dictionary:
	return {
		"year": year,
		"month": month,
		"week": week,
		"day_index": day_index,
		"total_days_elapsed": total_days_elapsed,
		"display_override": _display_override,
	}

func import_save_state(data: Dictionary) -> void:
	reset(
		int(data.get("year", 1)),
		int(data.get("month", 1)),
		int(data.get("week", 1)),
		int(data.get("day_index", 0)),
		int(data.get("total_days_elapsed", 0))
	)
	_display_override = str(data.get("display_override", ""))
