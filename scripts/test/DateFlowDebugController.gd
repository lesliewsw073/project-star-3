extends Control

var _date_label: Label
var _state_label: Label
var _log_label: RichTextLabel
var _end_day_button: Button
var _end_meeting_button: Button

func _ready() -> void:
	theme = _build_ui_theme()
	_build_ui()
	_connect_game_flow_signals()
	_refresh_status()
	_append_log("日期流程测试器已就绪。")
	_append_log("按「结束今日」推进日期；到星期日会进入会议阶段。")

func _build_ui() -> void:
	anchors_preset = Control.PRESET_FULL_RECT

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 24.0
	root.offset_top = 24.0
	root.offset_right = -24.0
	root.offset_bottom = -24.0
	root.add_theme_constant_override("separation", GameUiTheme.SEP + 4)
	add_child(root)

	var title := Label.new()
	title.text = "日期 / 周日会议流程测试器"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUiTheme.style_label(title, GameUiTheme.COLOR_GOLD, GameUiTheme.FONT_TITLE)
	root.add_child(title)

	_date_label = Label.new()
	GameUiTheme.style_label(_date_label)
	root.add_child(_date_label)

	_state_label = Label.new()
	GameUiTheme.style_label(_state_label, GameUiTheme.COLOR_MUTED)
	root.add_child(_state_label)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", GameUiTheme.SEP + 4)
	root.add_child(button_row)

	_end_day_button = _make_action_button("结束今日 / End Day")
	_end_day_button.pressed.connect(_on_end_day_pressed)
	button_row.add_child(_end_day_button)

	_end_meeting_button = _make_action_button("结束周日会议 / End Meeting")
	_end_meeting_button.pressed.connect(_on_end_meeting_pressed)
	button_row.add_child(_end_meeting_button)

	var clear_log_button := _make_action_button("清空日志 / Clear Log")
	clear_log_button.pressed.connect(_on_clear_log_pressed)
	button_row.add_child(clear_log_button)

	_log_label = RichTextLabel.new()
	_log_label.fit_content = false
	_log_label.scroll_following = true
	_log_label.custom_minimum_size = Vector2(0, 360)
	_log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	GameUiTheme.style_rich_text_label(_log_label)
	root.add_child(_log_label)

func _build_ui_theme() -> Theme:
	var ui_theme := Theme.new()
	ui_theme.set_default_font_size(GameUiTheme.FONT_BODY)
	ui_theme.set_font_size("font", "Label", GameUiTheme.FONT_BODY)
	ui_theme.set_font_size("font", "Button", GameUiTheme.FONT_BODY)
	ui_theme.set_font_size("font", "RichTextLabel", GameUiTheme.FONT_BODY)
	return ui_theme

func _make_action_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	GameUiTheme.style_button(button, GameUiTheme.COLOR_PRIMARY, GameUiTheme.FONT_BODY)
	GameUiTheme.compact_button(button, 0.0, GameUiTheme.BTN_HEIGHT)
	return button

func _connect_game_flow_signals() -> void:
	if not GameFlowManager.day_settlement_started.is_connected(_on_day_settlement_started):
		GameFlowManager.day_settlement_started.connect(_on_day_settlement_started)
	if not GameFlowManager.day_settlement_finished.is_connected(_on_day_settlement_finished):
		GameFlowManager.day_settlement_finished.connect(_on_day_settlement_finished)
	if not GameFlowManager.meeting_started.is_connected(_on_meeting_started):
		GameFlowManager.meeting_started.connect(_on_meeting_started)
	if not GameFlowManager.meeting_finished.is_connected(_on_meeting_finished):
		GameFlowManager.meeting_finished.connect(_on_meeting_finished)
	if not GameFlowManager.day_advanced.is_connected(_on_day_advanced):
		GameFlowManager.day_advanced.connect(_on_day_advanced)
	if not GameFlowManager.weekly_report_ready.is_connected(_on_weekly_report_ready):
		GameFlowManager.weekly_report_ready.connect(_on_weekly_report_ready)
	if not GameFlowManager.week_schedule_committed.is_connected(_on_week_schedule_committed):
		GameFlowManager.week_schedule_committed.connect(_on_week_schedule_committed)

func _refresh_status() -> void:
	var date_snapshot: Dictionary = TimeManager.get_date_snapshot()
	_date_label.text = "当前日期：%s" % date_snapshot["display_text"]
	_state_label.text = "会议阶段：%s | 已签约艺人数：%d" % [
		"是" if GameFlowManager.is_meeting_phase else "否",
		ArtistManager.get_signed_count()
	]

	_end_day_button.disabled = GameFlowManager.is_meeting_phase
	_end_meeting_button.disabled = not GameFlowManager.is_meeting_phase

func _append_log(message: String) -> void:
	if _log_label == null:
		return
	_log_label.append_text(message + "\n")

func _on_end_day_pressed() -> void:
	_append_log("玩家点击：结束今日")
	if GameFlowManager.can_finish_today():
		GameFlowManager.finish_today()
	else:
		GameFlowManager.end_day()
	_refresh_status()

func _on_end_meeting_pressed() -> void:
	_append_log("玩家点击：结束周日会议")
	GameFlowManager.end_meeting()
	_refresh_status()

func _on_clear_log_pressed() -> void:
	_log_label.clear()

func _on_day_settlement_started(date_snapshot: Dictionary) -> void:
	_append_log("开始结算：%s" % date_snapshot["display_text"])

func _on_day_settlement_finished(date_snapshot: Dictionary) -> void:
	_append_log("完成结算：%s" % date_snapshot["display_text"])

func _on_meeting_started(date_snapshot: Dictionary) -> void:
	_append_log("进入周日会议：%s" % date_snapshot["display_text"])
	_refresh_status()

func _on_meeting_finished(date_snapshot: Dictionary) -> void:
	_append_log("结束周日会议：%s" % date_snapshot["display_text"])

func _on_day_advanced(date_snapshot: Dictionary) -> void:
	_append_log("日期推进到：%s" % date_snapshot["display_text"])
	_refresh_status()

func _on_weekly_report_ready(advices: Array) -> void:
	_append_log("秘书周报已生成，共 %d 条：" % advices.size())
	for advice in advices:
		_append_log("  - %s" % advice)

func _on_week_schedule_committed(signed_artist_count: int) -> void:
	_append_log("下周行程已提交，覆盖 %d 位旗下艺人。" % signed_artist_count)
