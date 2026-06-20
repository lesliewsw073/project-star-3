extends Control

var _date_label: Label
var _phase_label: Label
var _roster_label: Label
var _roster_profile_label: Label
var _protagonist_label: Label
var _company_label: Label
var _scale_label: Label
var _money_label: Label
var _reputation_label: Label
var _public_opinion_label: Label
var _job_stats_label: Label
var _upgrade_info_label: Label
var _message_log: RichTextLabel
var _meeting_panel: PanelContainer
var _daily_panel: PanelContainer
var _center_daily_title: Label
var _end_day_button: Button
var _end_meeting_button: Button
var _upgrade_company_button: Button
var _interaction_status_label: Label
var _daily_main_box: VBoxContainer
var _current_week_schedule_host: VBoxContainer
var _job_center_panel: PanelContainer
var _job_summary_label: Label
var _job_list: ItemList
var _job_detail_label: Label
var _job_qualification_label: Label
var _job_active_label: Label
var _job_artist_option: OptionButton
var _job_artist_profile_label: Label
var _job_schedule_label: Label
var _job_sign_box: VBoxContainer
var _job_accept_button: Button
var _job_invite_accept_button: Button
var _job_invite_detail_label: Label
var _job_list_instance_ids: Array[String] = []
var _selected_job_instance_id: String = ""
var _showing_job_center: bool = false
var _meeting_character_row: HBoxContainer
var _meeting_detail_label: Label
var _meeting_profile_label: Label
var _meeting_chat_button: Button
var _meeting_gift_button: Button
var _meeting_renew_button: Button
var _meeting_terminate_button: Button
var _meeting_button_group: ButtonGroup
var _meeting_schedule_grid_host: VBoxContainer
var _meeting_schedule_cell_buttons: Dictionary = {}
var _meeting_schedule_selection_label: Label
var _selected_schedule_artist_id: String = ""
var _selected_meeting_day_index: int = 0
var _meeting_schedule_editor_box: VBoxContainer
var _meeting_schedule_type_row: HBoxContainer
var _meeting_task_option: OptionButton
var _meeting_schedule_detail_label: Label
var _selected_meeting_character_id: String = SecretaryManager.SECRETARY_ID
var _pending_meeting_schedule_type: int = ScheduleManager.ScheduleType.ROUTINE_EMPTY
var _schedule_picker_dialog: SchedulePickerDialog
var _meeting_gift_picker_dialog: CanvasLayer
var _save_slot_picker_dialog: CanvasLayer
var _open_save_slots_button: Button
var _enter_map_button: Button
var _exit_map_button: Button
var _map_hub: Control
var _company_ui_root: VBoxContainer
var _opening_profile_dialog: OpeningProfileDialog
var _opening_artist_pick_dialog: OpeningArtistPickDialog
var _artist_sign_profile_dialog: ArtistSignProfileDialog
var _office_title_label: Label
var _day_work_report_panel: DayWorkReportPanel
var _daily_news_panel: DailyNewsPanel

const MAP_HUB_SCENE: PackedScene = preload("res://UI/MapHub.tscn")
const MeetingGiftPickerDialogScript = preload("res://scripts/ui/MeetingGiftPickerDialog.gd")
const SaveSlotPickerDialogScript = preload("res://scripts/ui/SaveSlotPickerDialog.gd")

const MEETING_SCHEDULE_TYPE_SPECS: Array[Dictionary] = [
	{
		"type": ScheduleManager.ScheduleType.ROUTINE_EMPTY,
		"label": "空白",
		"needs_task": false,
	},
	{
		"type": ScheduleManager.ScheduleType.ROUTINE_REST,
		"label": "休息",
		"needs_task": false,
	},
	{
		"type": ScheduleManager.ScheduleType.COURSE,
		"label": "課程",
		"needs_task": true,
		"task_kind": "course",
	},
	{
		"type": ScheduleManager.ScheduleType.GIG,
		"label": "打工",
		"needs_task": true,
		"task_kind": "gig",
	},
	{
		"type": ScheduleManager.ScheduleType.VACATION_DOMESTIC,
		"label": "國內度假",
		"needs_task": true,
		"task_kind": "vacation_domestic",
		"whole_week": true,
	},
	{
		"type": ScheduleManager.ScheduleType.VACATION_OVERSEAS,
		"label": "國外度假",
		"needs_task": true,
		"task_kind": "vacation_overseas",
		"whole_week": true,
	},
	{
		"type": ScheduleManager.ScheduleType.ROUTINE_CREATION,
		"label": "創作",
		"needs_task": false,
	},
	{
		"type": ScheduleManager.ScheduleType.WORK_LOCAL,
		"label": "通告",
		"needs_task": true,
		"task_kind": "job",
	},
]

const COLOR_BG_ROOT := Color(0.10, 0.11, 0.16, 1.0)
const COLOR_PANEL_LEFT := Color(0.14, 0.18, 0.26, 1.0)
const COLOR_PANEL_CENTER := Color(0.16, 0.15, 0.21, 1.0)
const COLOR_PANEL_RIGHT := Color(0.12, 0.16, 0.23, 1.0)
const COLOR_BLOCK_LIGHT := Color(0.22, 0.24, 0.32, 1.0)
const COLOR_BLOCK_ACCENT := Color(0.26, 0.20, 0.34, 1.0)
const COLOR_BLOCK_SCHEDULE := Color(0.18, 0.24, 0.30, 1.0)
const COLOR_ACCENT_GOLD := Color(0.96, 0.78, 0.36, 1.0)
const COLOR_ACCENT_CYAN := Color(0.48, 0.86, 0.94, 1.0)
const COLOR_ACCENT_CORAL := Color(0.94, 0.48, 0.58, 1.0)
const COLOR_TEXT_PRIMARY := Color(0.92, 0.93, 0.96, 1.0)
const COLOR_TEXT_MUTED := Color(0.62, 0.66, 0.74, 1.0)
const COLOR_BTN_PRIMARY := Color(0.32, 0.52, 0.82, 1.0)
const COLOR_BTN_NAV := Color(0.28, 0.58, 0.54, 1.0)
const COLOR_BTN_WARM := Color(0.72, 0.48, 0.28, 1.0)
const COLOR_BTN_DANGER := Color(0.72, 0.30, 0.36, 1.0)
const COLOR_BTN_SUCCESS := Color(0.28, 0.68, 0.46, 1.0)
const COLOR_BORDER := Color(0.38, 0.42, 0.52, 0.55)
const UI_BTN_HEIGHT := GameUiTheme.BTN_HEIGHT
const UI_BTN_HEIGHT_SM := GameUiTheme.BTN_HEIGHT_SM
const UI_FONT_BODY := GameUiTheme.FONT_BODY
const UI_FONT_SECTION := GameUiTheme.FONT_SECTION
const UI_FONT_HINT := GameUiTheme.FONT_HINT
const UI_FONT_TITLE := GameUiTheme.FONT_TITLE
const UI_SEP := GameUiTheme.SEP
const UI_PAD := GameUiTheme.PAD
const PORTRAIT_SCHEDULE := Vector2(52, 52)
const PORTRAIT_SIGN := Vector2(56, 56)
const PORTRAIT_MEETING_TAB := Vector2(44, 44)

func _ready() -> void:
	theme = _build_ui_theme()
	_meeting_button_group = ButtonGroup.new()
	_build_ui()
	_setup_opening_profile_dialog()
	_setup_opening_artist_pick_dialog()
	_setup_artist_sign_profile_dialog()
	_setup_day_work_report_panel()
	_setup_daily_news_panel()
	_setup_schedule_picker_dialog()
	_setup_meeting_gift_picker_dialog()
	_setup_save_slot_picker_dialog()
	_connect_game_flow_signals()
	_connect_news_signals()
	_connect_artist_signals()
	_connect_job_signals()
	_refresh_status()
	_refresh_interaction_status()
	_refresh_job_center()
	_apply_exploration_visibility()
	if ProtagonistManager.is_profile_locked():
		_add_message("開局劇情進行中。完成首位藝人簽約後將進入 12/31 首次會議。")

func _setup_opening_profile_dialog() -> void:
	_opening_profile_dialog = OpeningProfileDialog.new()
	add_child(_opening_profile_dialog)
	_opening_profile_dialog.profile_confirmed.connect(_on_opening_profile_confirmed)
	if not ProtagonistManager.is_profile_locked():
		_opening_profile_dialog.open_dialog()
	elif GameFlowManager.needs_initial_sign():
		_try_open_initial_artist_pick()

func _setup_opening_artist_pick_dialog() -> void:
	_opening_artist_pick_dialog = OpeningArtistPickDialog.new()
	add_child(_opening_artist_pick_dialog)
	_opening_artist_pick_dialog.artist_confirmed.connect(_on_opening_artist_confirmed)

func _try_open_initial_artist_pick() -> void:
	if not ProtagonistManager.is_profile_locked() or not PlayerManager.is_company_name_locked():
		return
	if _opening_artist_pick_dialog != null and GameFlowManager.needs_initial_sign():
		_opening_artist_pick_dialog.open_dialog()

func _setup_artist_sign_profile_dialog() -> void:
	_artist_sign_profile_dialog = ArtistSignProfileDialog.new()
	add_child(_artist_sign_profile_dialog)
	_artist_sign_profile_dialog.confirmed.connect(_on_artist_sign_profile_confirmed)
	_artist_sign_profile_dialog.cancelled.connect(_on_artist_sign_profile_cancelled)

func _on_artist_sign_profile_confirmed(artist_id: String) -> void:
	if not ArtistManager.sign_artist(artist_id):
		_add_message("[簽約] 失敗：%s" % artist_id)
		return
	var display_name: String = _get_meeting_character_display_name(artist_id)
	_add_message("[簽約] 已簽下 %s。" % display_name)
	_refresh_status()
	_refresh_job_center()
	_refresh_meeting_panel()

func _on_artist_sign_profile_cancelled() -> void:
	pass

func _prompt_artist_sign_profile(artist_id: String) -> void:
	if _artist_sign_profile_dialog == null:
		return
	_artist_sign_profile_dialog.open_for_artist(artist_id)

func _setup_day_work_report_panel() -> void:
	_day_work_report_panel = DayWorkReportPanel.new()
	add_child(_day_work_report_panel)
	_day_work_report_panel.dismissed.connect(_on_day_work_report_dismissed)

func _setup_daily_news_panel() -> void:
	_daily_news_panel = DailyNewsPanel.new()
	add_child(_daily_news_panel)
	_daily_news_panel.dismissed.connect(_on_daily_news_dismissed)

func _on_daily_news_dismissed() -> void:
	GameFlowManager.dismiss_daily_news()
	_apply_exploration_visibility()

func _on_daily_news_requested(edition: Array) -> void:
	if _daily_news_panel != null:
		_daily_news_panel.show_edition(edition)

func _on_day_work_report_dismissed() -> void:
	GameFlowManager.dismiss_work_report()
	_refresh_status()
	_apply_exploration_visibility()

func _on_work_report_requested(reports: Array) -> void:
	if _day_work_report_panel != null:
		_day_work_report_panel.show_report(reports)
	_add_message("[通告進行中] 今日行程結算完成，點擊畫面繼續。")
	_apply_exploration_visibility()
	_refresh_status()

func _on_opening_profile_confirmed(
	last_name: String,
	first_name: String,
	company_name: String
) -> void:
	_add_message(
		"開局設定完成：%s%s · 公司「%s」。姓名與公司名稱已鎖定。"
		% [last_name, first_name, company_name]
	)
	_refresh_status()
	_try_open_initial_artist_pick()

func _on_opening_artist_confirmed(artist_id: String) -> void:
	var display_name: String = _get_meeting_character_display_name(artist_id)
	_add_message("開局行動已確認，首位藝人將在劇情中登場。")
	_refresh_status()
	_refresh_job_center()
	_refresh_meeting_panel()
	if artist_id == "artist_003":
		_play_artist_003_opening_preface(artist_id)
	else:
		_start_opening_sign_story(artist_id)

func _start_opening_sign_story(artist_id: String) -> void:
	var batch: Dictionary = StoryTriggerManager.try_play_sign_story(artist_id)
	if bool(batch.get("pending_playback", false)):
		return
	if bool(batch.get("success", false)):
		_finalize_story_batch(batch, "簽約劇情")
		_try_enter_first_meeting_after_sign()
	elif str(batch.get("reason", "")) == "no_matching_event":
		_add_message("[開局] 找不到 %s 的 sign 劇情占位。" % artist_id)
		_try_enter_first_meeting_after_sign()

func _play_artist_003_opening_preface(artist_id: String) -> void:
	var tv_bridge := StoryBeatTransition.new()
	add_child(tv_bridge)
	tv_bridge.finished.connect(
		func() -> void:
			_play_artist_003_knock_bridge(artist_id),
		CONNECT_ONE_SHOT
	)
	tv_bridge.play_artist_003_tv_preface_bridge()

func _play_artist_003_knock_bridge(artist_id: String) -> void:
	var knock_bridge := StoryBeatTransition.new()
	add_child(knock_bridge)
	knock_bridge.finished.connect(
		func() -> void:
			_start_opening_sign_story(artist_id),
		CONNECT_ONE_SHOT
	)
	knock_bridge.play_artist_003_sign_to_day1_bridge()

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = COLOR_BG_ROOT
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	_company_ui_root = root
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = float(UI_PAD)
	root.offset_top = float(UI_PAD)
	root.offset_right = float(-UI_PAD)
	root.offset_bottom = float(-UI_PAD)
	root.add_theme_constant_override("separation", UI_SEP)
	add_child(root)

	_office_title_label = Label.new()
	_office_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_office_title_label.add_theme_font_size_override("font_size", UI_FONT_TITLE)
	_office_title_label.add_theme_color_override("font_color", COLOR_ACCENT_GOLD)
	root.add_child(_office_title_label)

	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", UI_SEP)
	root.add_child(body)

	body.add_child(_build_left_status_panel())
	body.add_child(_build_center_action_panel())
	body.add_child(_build_right_report_panel())

func _build_ui_theme() -> Theme:
	var ui_theme := Theme.new()
	ui_theme.set_default_font_size(UI_FONT_BODY)
	ui_theme.set_font_size("font", "Label", UI_FONT_BODY)
	ui_theme.set_font_size("font", "Button", UI_FONT_BODY)
	ui_theme.set_font_size("font", "RichTextLabel", UI_FONT_BODY)
	ui_theme.set_font_size("font", "ItemList", UI_FONT_BODY)
	ui_theme.set_font_size("font", "OptionButton", UI_FONT_BODY)
	return ui_theme

func _make_stylebox(
	bg: Color,
	border: Color = COLOR_BORDER,
	border_width: int = 1,
	corner: int = 6,
	content_margin: int = 6
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner)
	style.content_margin_left = content_margin
	style.content_margin_top = content_margin
	style.content_margin_right = content_margin
	style.content_margin_bottom = content_margin
	return style

func _style_panel(panel: PanelContainer, bg: Color, border: Color = COLOR_BORDER) -> void:
	panel.add_theme_stylebox_override("panel", _make_stylebox(bg, border, 1, 8, UI_PAD))

func _style_button(button: Button, bg: Color, font_size: int = UI_FONT_BODY) -> void:
	var hover := bg.lightened(0.10)
	button.add_theme_stylebox_override("normal", _make_stylebox(bg, bg.lightened(0.18), 1, 4, 4))
	button.add_theme_stylebox_override("hover", _make_stylebox(hover, hover.lightened(0.18), 1, 4, 4))
	button.add_theme_stylebox_override("pressed", _make_stylebox(bg.darkened(0.08), bg.lightened(0.12), 1, 4, 4))
	button.add_theme_stylebox_override("disabled", _make_stylebox(bg.darkened(0.22), bg.darkened(0.10), 1, 4, 4))
	button.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	button.add_theme_color_override("font_disabled_color", COLOR_TEXT_MUTED)
	button.add_theme_font_size_override("font_size", font_size)

func _compact_button(button: Button, min_width: float = 0.0, height: int = UI_BTN_HEIGHT) -> Button:
	button.custom_minimum_size = Vector2(min_width, height)
	return button

func _style_body_label(label: Label, muted: bool = false) -> Label:
	label.add_theme_font_size_override("font_size", UI_FONT_BODY)
	label.add_theme_color_override(
		"font_color",
		COLOR_TEXT_MUTED if muted else COLOR_TEXT_PRIMARY
	)
	return label

func _style_hint_label(label: Label) -> Label:
	label.add_theme_font_size_override("font_size", UI_FONT_HINT)
	label.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	return label

func _build_left_status_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_panel(panel, COLOR_PANEL_LEFT, Color(0.42, 0.55, 0.78, 0.45))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI_SEP)
	panel.add_child(box)

	box.add_child(_make_section_title("公司狀態", COLOR_ACCENT_CYAN))

	_protagonist_label = _style_body_label(Label.new())
	box.add_child(_protagonist_label)

	_company_label = _style_body_label(Label.new())
	box.add_child(_company_label)

	_scale_label = _style_body_label(Label.new())
	box.add_child(_scale_label)

	_date_label = _style_body_label(Label.new())
	_date_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_date_label)

	_phase_label = _style_body_label(Label.new())
	box.add_child(_phase_label)

	_roster_label = _style_body_label(Label.new())
	box.add_child(_roster_label)

	_roster_profile_label = _style_hint_label(Label.new())
	_roster_profile_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_roster_profile_label)

	_money_label = _style_body_label(Label.new())
	_money_label.add_theme_color_override("font_color", COLOR_ACCENT_GOLD)
	box.add_child(_money_label)

	_reputation_label = _style_body_label(Label.new())
	box.add_child(_reputation_label)

	_public_opinion_label = _style_body_label(Label.new())
	box.add_child(_public_opinion_label)

	_job_stats_label = _style_body_label(Label.new(), true)
	_job_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_job_stats_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", UI_SEP)
	box.add_child(button_row)

	_end_day_button = _compact_button(Button.new(), 0.0)
	_end_day_button.text = "結束今日"
	_end_day_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(_end_day_button, COLOR_BTN_SUCCESS)
	_end_day_button.pressed.connect(_on_end_day_pressed)
	button_row.add_child(_end_day_button)

	_end_meeting_button = _compact_button(Button.new(), 0.0)
	_end_meeting_button.text = "結束週日會議"
	_end_meeting_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(_end_meeting_button, COLOR_BTN_WARM)
	_end_meeting_button.pressed.connect(_on_end_meeting_pressed)
	button_row.add_child(_end_meeting_button)

	var map_row := HBoxContainer.new()
	map_row.add_theme_constant_override("separation", UI_SEP)
	box.add_child(map_row)

	_enter_map_button = _compact_button(Button.new(), 0.0)
	_enter_map_button.text = "進入大地圖"
	_enter_map_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(_enter_map_button, COLOR_BTN_NAV)
	_enter_map_button.pressed.connect(_on_enter_map_pressed)
	map_row.add_child(_enter_map_button)

	_exit_map_button = _compact_button(Button.new(), 0.0)
	_exit_map_button.text = "離開大地圖"
	_exit_map_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(_exit_map_button, COLOR_BTN_WARM)
	_exit_map_button.pressed.connect(_on_exit_map_pressed)
	map_row.add_child(_exit_map_button)

	return panel

func _build_center_action_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_panel(panel, COLOR_PANEL_CENTER, Color(0.55, 0.45, 0.72, 0.35))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI_SEP)
	panel.add_child(box)

	_center_daily_title = _make_section_title("日常營運", COLOR_ACCENT_GOLD)
	box.add_child(_center_daily_title)

	_daily_panel = PanelContainer.new()
	_daily_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_panel(_daily_panel, Color(0.0, 0.0, 0.0, 0.0), Color(0.0, 0.0, 0.0, 0.0))
	box.add_child(_daily_panel)

	var daily_scroll := ScrollContainer.new()
	daily_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	daily_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	daily_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	daily_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_daily_panel.add_child(daily_scroll)

	_daily_main_box = VBoxContainer.new()
	_daily_main_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_daily_main_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_daily_main_box.add_theme_constant_override("separation", UI_SEP)
	daily_scroll.add_child(_daily_main_box)

	_daily_main_box.add_child(_build_current_week_schedule_panel())
	var daily_nav_row := HBoxContainer.new()
	daily_nav_row.add_theme_constant_override("separation", UI_SEP)
	_daily_main_box.add_child(daily_nav_row)

	daily_nav_row.add_child(_make_nav_button("通告中心", _on_open_job_center_pressed))

	var upgrade_panel := PanelContainer.new()
	_style_panel(upgrade_panel, COLOR_BLOCK_LIGHT, Color(0.45, 0.55, 0.70, 0.35))
	_daily_main_box.add_child(upgrade_panel)

	var upgrade_row := HBoxContainer.new()
	upgrade_row.add_theme_constant_override("separation", UI_SEP)
	upgrade_panel.add_child(upgrade_row)

	var upgrade_title := _make_section_title("升級", COLOR_ACCENT_CYAN)
	upgrade_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	upgrade_row.add_child(upgrade_title)

	_upgrade_info_label = _style_hint_label(Label.new())
	_upgrade_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_upgrade_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	upgrade_row.add_child(_upgrade_info_label)

	_upgrade_company_button = _compact_button(Button.new(), 68.0, UI_BTN_HEIGHT_SM)
	_upgrade_company_button.text = "升級"
	_style_button(_upgrade_company_button, COLOR_BTN_PRIMARY, UI_FONT_HINT)
	_upgrade_company_button.pressed.connect(_on_upgrade_company_pressed)
	upgrade_row.add_child(_upgrade_company_button)

	box.add_child(_build_job_center_panel())
	box.add_child(_build_meeting_interaction_panel())

	return panel

func _build_current_week_schedule_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_style_panel(panel, COLOR_BLOCK_SCHEDULE, Color(0.40, 0.62, 0.72, 0.40))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)

	box.add_child(_make_section_title("本週行程", COLOR_ACCENT_CYAN))

	var hint := _style_hint_label(Label.new())
	hint.text = "▶=今天；首週週日提交後下週一顯示。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 88)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

	_current_week_schedule_host = VBoxContainer.new()
	_current_week_schedule_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_current_week_schedule_host)

	return panel

func _refresh_current_week_schedule_panel() -> void:
	if _current_week_schedule_host == null:
		return

	for child in _current_week_schedule_host.get_children():
		child.queue_free()

	var signed_ids: Array = ArtistManager.get_signed_ids()
	if signed_ids.is_empty():
		var empty_hint := _style_hint_label(Label.new())
		empty_hint.text = "尚無藝人，無法顯示行程。"
		empty_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_current_week_schedule_host.add_child(empty_hint)
		return

	var today_index: int = TimeManager.day_index
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 4)
	_current_week_schedule_host.add_child(header_row)

	var corner_label := _style_hint_label(Label.new())
	corner_label.custom_minimum_size = Vector2(56, 0)
	corner_label.text = "日期"
	header_row.add_child(corner_label)

	for artist_id in signed_ids:
		header_row.add_child(_build_schedule_artist_header(str(artist_id)))

	for day_index in range(ScheduleManager.DAYS_PER_WEEK):
		var day_row := HBoxContainer.new()
		day_row.add_theme_constant_override("separation", 4)
		_current_week_schedule_host.add_child(day_row)

		var day_label := _style_body_label(Label.new())
		day_label.custom_minimum_size = Vector2(56, 0)
		var day_prefix: String = "▶" if day_index == today_index else ""
		day_label.text = "%s週%s" % [day_prefix, ["一", "二", "三", "四", "五", "六", "日"][day_index]]
		if day_index == today_index:
			day_label.add_theme_color_override("font_color", COLOR_ACCENT_GOLD)
		day_row.add_child(day_label)

		for artist_id in signed_ids:
			var artist_id_text: String = str(artist_id)
			var week: Array = ScheduleManager.get_week(artist_id_text)
			var slot: Dictionary = week[day_index]
			var display_lines: PackedStringArray = ScheduleManager.get_slot_display_lines(slot)
			var lock_hint: String = ScheduleManager.get_slot_lock_hint(slot)

			var cell_panel := PanelContainer.new()
			cell_panel.custom_minimum_size = Vector2(84, 28)
			_style_panel(
				cell_panel,
				COLOR_BLOCK_LIGHT.lightened(0.06) if day_index == today_index else COLOR_BLOCK_LIGHT,
				Color(0.45, 0.55, 0.68, 0.35)
			)
			day_row.add_child(cell_panel)

			var cell_label := _style_hint_label(Label.new())
			cell_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			cell_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell_label.text = _build_schedule_cell_text(display_lines, lock_hint)
			cell_panel.add_child(cell_label)

func _build_meeting_interaction_panel() -> PanelContainer:
	_meeting_panel = PanelContainer.new()
	_meeting_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_meeting_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_panel(_meeting_panel, COLOR_BLOCK_ACCENT, Color(0.62, 0.45, 0.78, 0.40))

	var meeting_scroll := ScrollContainer.new()
	meeting_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	meeting_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meeting_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	meeting_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_meeting_panel.add_child(meeting_scroll)

	var meeting_box := VBoxContainer.new()
	meeting_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meeting_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	meeting_box.add_theme_constant_override("separation", UI_SEP)
	meeting_scroll.add_child(meeting_box)

	meeting_box.add_child(_make_section_title("週日會議", COLOR_ACCENT_CORAL))

	var meeting_hint := _style_hint_label(Label.new())
	meeting_hint.text = "編排下週行程與跟隨；完成後按左側「結束週日會議」。"
	meeting_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meeting_box.add_child(meeting_hint)

	_meeting_character_row = HBoxContainer.new()
	_meeting_character_row.add_theme_constant_override("separation", UI_SEP)
	meeting_box.add_child(_meeting_character_row)

	_meeting_detail_label = _style_body_label(Label.new())
	_meeting_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meeting_box.add_child(_meeting_detail_label)

	_meeting_profile_label = _style_body_label(Label.new())
	_meeting_profile_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meeting_box.add_child(_meeting_profile_label)

	var meeting_action_row := HBoxContainer.new()
	meeting_action_row.add_theme_constant_override("separation", UI_SEP)
	meeting_box.add_child(meeting_action_row)

	_meeting_chat_button = _compact_button(Button.new(), 52.0, UI_BTN_HEIGHT_SM)
	_meeting_chat_button.text = "聊天"
	_style_button(_meeting_chat_button, COLOR_BTN_PRIMARY, UI_FONT_HINT)
	_meeting_chat_button.pressed.connect(_on_meeting_chat_pressed)
	meeting_action_row.add_child(_meeting_chat_button)

	_meeting_gift_button = _compact_button(Button.new(), 52.0, UI_BTN_HEIGHT_SM)
	_meeting_gift_button.text = "送禮"
	_style_button(_meeting_gift_button, COLOR_BTN_WARM, UI_FONT_HINT)
	_meeting_gift_button.pressed.connect(_on_meeting_gift_pressed)
	meeting_action_row.add_child(_meeting_gift_button)

	_meeting_renew_button = _compact_button(Button.new(), 52.0, UI_BTN_HEIGHT_SM)
	_meeting_renew_button.text = "續約"
	_style_button(_meeting_renew_button, COLOR_BTN_NAV, UI_FONT_HINT)
	_meeting_renew_button.pressed.connect(_on_meeting_renew_pressed)
	meeting_action_row.add_child(_meeting_renew_button)

	_meeting_terminate_button = _compact_button(Button.new(), 52.0, UI_BTN_HEIGHT_SM)
	_meeting_terminate_button.text = "解約"
	_style_button(_meeting_terminate_button, COLOR_BTN_DANGER, UI_FONT_HINT)
	_meeting_terminate_button.pressed.connect(_on_meeting_terminate_pressed)
	meeting_action_row.add_child(_meeting_terminate_button)

	var meeting_nav_row := HBoxContainer.new()
	meeting_nav_row.add_theme_constant_override("separation", UI_SEP)
	meeting_box.add_child(meeting_nav_row)

	var open_job_center_button := _compact_button(Button.new(), 120.0, UI_BTN_HEIGHT_SM)
	open_job_center_button.text = "通告中心"
	_style_button(open_job_center_button, COLOR_BTN_NAV, UI_FONT_HINT)
	open_job_center_button.pressed.connect(_on_open_job_center_pressed)
	meeting_nav_row.add_child(open_job_center_button)

	_add_meeting_save_controls(meeting_box)

	meeting_box.add_child(_make_section_title("下週草稿", COLOR_ACCENT_CYAN))

	var schedule_hint := _style_hint_label(Label.new())
	schedule_hint.text = "點格子安排行程；勾「跟」=下週該日跟隨（僅通告/打工/課程，同日同任務自動合併）。"
	schedule_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meeting_box.add_child(schedule_hint)

	var schedule_scroll := ScrollContainer.new()
	schedule_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	schedule_scroll.custom_minimum_size = Vector2(0, 120)
	schedule_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	schedule_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	meeting_box.add_child(schedule_scroll)

	_meeting_schedule_grid_host = VBoxContainer.new()
	_meeting_schedule_grid_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	schedule_scroll.add_child(_meeting_schedule_grid_host)

	_meeting_schedule_editor_box = VBoxContainer.new()
	_meeting_schedule_editor_box.visible = false
	_meeting_schedule_editor_box.add_theme_constant_override("separation", UI_SEP)
	meeting_box.add_child(_meeting_schedule_editor_box)

	_meeting_schedule_selection_label = _style_body_label(Label.new())
	_meeting_schedule_selection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_meeting_schedule_editor_box.add_child(_meeting_schedule_selection_label)

	_meeting_schedule_type_row = HBoxContainer.new()
	_meeting_schedule_type_row.add_theme_constant_override("separation", 3)
	_meeting_schedule_editor_box.add_child(_meeting_schedule_type_row)

	for spec in MEETING_SCHEDULE_TYPE_SPECS:
		var type_button := _compact_button(Button.new(), 52.0, UI_BTN_HEIGHT_SM)
		type_button.text = str(spec.get("label", "行程"))
		_style_button(type_button, COLOR_BLOCK_LIGHT.lightened(0.08), UI_FONT_HINT)
		var schedule_type: int = int(spec.get("type", ScheduleManager.ScheduleType.ROUTINE_EMPTY))
		type_button.pressed.connect(_on_meeting_schedule_type_pressed.bind(schedule_type))
		_meeting_schedule_type_row.add_child(type_button)

	var task_row := HBoxContainer.new()
	task_row.add_theme_constant_override("separation", UI_SEP)
	_meeting_schedule_editor_box.add_child(task_row)

	var task_caption := _style_hint_label(Label.new())
	task_caption.text = "項目"
	task_row.add_child(task_caption)

	_meeting_task_option = OptionButton.new()
	_meeting_task_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_meeting_task_option.custom_minimum_size = Vector2(0, UI_BTN_HEIGHT_SM)
	_meeting_task_option.item_selected.connect(_on_meeting_task_selected)
	task_row.add_child(_meeting_task_option)

	_meeting_schedule_detail_label = _style_hint_label(Label.new())
	_meeting_schedule_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_meeting_schedule_editor_box.add_child(_meeting_schedule_detail_label)

	_refresh_meeting_panel()
	return _meeting_panel

func _build_interaction_test_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	_style_panel(panel, COLOR_BLOCK_LIGHT, Color(0.50, 0.42, 0.62, 0.35))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)

	box.add_child(_make_section_title("互動測試", COLOR_ACCENT_CORAL))

	_interaction_status_label = _style_hint_label(Label.new())
	_interaction_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_interaction_status_label)

	var button_row := GridContainer.new()
	button_row.columns = 3
	button_row.add_theme_constant_override("h_separation", UI_SEP)
	button_row.add_theme_constant_override("v_separation", UI_SEP)
	box.add_child(button_row)

	button_row.add_child(_make_interaction_test_button("秘書聊天", _make_test_event_chat_secretary))
	button_row.add_child(_make_interaction_test_button("藝人聊天", _make_test_event_chat_artist))
	button_row.add_child(_make_interaction_test_button("補充測試道具", Callable(self, "_on_test_seed_inventory_items")))
	button_row.add_child(_make_interaction_test_button("劇情事件", _make_test_event_story_once))
	button_row.add_child(_make_interaction_test_button("資金不足", _make_test_event_expensive_gift))

	return panel

func _build_story_dev_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	_style_panel(panel, COLOR_BLOCK_ACCENT, Color(0.55, 0.45, 0.72, 0.35))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)

	box.add_child(_make_section_title("開局流程（測試）", COLOR_ACCENT_GOLD))

	var hint := _style_hint_label(Label.new())
	hint.text = "正式版由劇情自動推進；測試時可手動進入 12/31 首次會議。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint)

	var button := _compact_button(Button.new(), 0.0, UI_BTN_HEIGHT)
	button.text = "開局劇情結束 → 12/31 會議"
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(button, COLOR_BTN_WARM)
	button.pressed.connect(_on_finish_opening_story_pressed)
	box.add_child(button)

	var story_lock_button := _compact_button(Button.new(), 0.0, UI_BTN_HEIGHT)
	story_lock_button.text = "測試：劇情占用 2 天"
	story_lock_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(story_lock_button, COLOR_BTN_DANGER, UI_FONT_HINT)
	story_lock_button.pressed.connect(_on_test_story_lock_pressed)
	box.add_child(story_lock_button)

	var story_row := HBoxContainer.new()
	story_row.add_theme_constant_override("separation", UI_SEP)
	box.add_child(story_row)

	var follow_story_button := _compact_button(Button.new(), 0.0, UI_BTN_HEIGHT_SM)
	follow_story_button.text = "測跟隨劇情"
	follow_story_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(follow_story_button, COLOR_BTN_PRIMARY, UI_FONT_HINT)
	follow_story_button.pressed.connect(_on_test_follow_story_pressed)
	story_row.add_child(follow_story_button)

	var visit_story_button := _compact_button(Button.new(), 0.0, UI_BTN_HEIGHT_SM)
	visit_story_button.text = "測探望酒吧"
	visit_story_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(visit_story_button, COLOR_BTN_NAV, UI_FONT_HINT)
	visit_story_button.pressed.connect(_on_test_visit_bar_pressed)
	story_row.add_child(visit_story_button)

	return panel

func _on_test_follow_story_pressed() -> void:
	var artist_ids: Array[String] = FollowPlanManager.get_today_follow_artist_ids()
	if artist_ids.is_empty():
		_add_message("[測試] 今日無跟隨對象，請先在週日會議勾選。")
		return
	var batch: Dictionary = StoryTriggerManager.run_follow_day(artist_ids)
	if bool(batch.get("pending_playback", false)):
		return
	_finalize_story_batch(batch, "跟隨劇情")

func _on_test_visit_bar_pressed() -> void:
	if GameFlowManager.get_day_mode() != GameFlowManager.DayMode.FREE:
		_add_message("[測試] 需在自由探索日（非跟隨／非劇情鎖）。")
		return
	if not GameFlowManager.is_exploring_map:
		GameFlowManager.enter_map()
		_apply_exploration_visibility()
		_refresh_status()
	var batch: Dictionary = StoryTriggerManager.try_visit("screen_2", "fac_bar")
	if batch.get("reason", "") == "chance_failed":
		_add_message("[探望] 在酒吧沒有遇到特殊狀況（概率未命中）。")
		return
	if bool(batch.get("pending_playback", false)):
		return
	_finalize_story_batch(batch, "探望")

func _on_test_story_lock_pressed() -> void:
	if GameFlowManager.game_phase != GameFlowManager.GamePhase.DAY_OPERATION:
		_add_message("僅日常營運階段可測試劇情占用。")
		return
	GameFlowManager.start_story_lock(2, "test_story_lock")
	_add_message("[劇情] 特殊劇情占用 2 天：不可跟隨、不可進大地圖。")
	_refresh_status()

func _on_finish_opening_story_pressed() -> void:
	if not ProtagonistManager.is_profile_locked() or not PlayerManager.is_company_name_locked():
		_add_message("請先完成開局設定（主角姓名與公司名稱）。")
		if _opening_profile_dialog != null:
			_opening_profile_dialog.open_dialog()
		return
	if GameFlowManager.needs_initial_sign():
		_add_message("請先完成開局 3 選 1 簽約。")
		_try_open_initial_artist_pick()
		return
	if GameFlowManager.game_phase != GameFlowManager.GamePhase.STORY:
		_add_message("目前不在開局劇情階段。")
		return
	GameFlowManager.finish_opening_story()
	_add_message("開局劇情結束，進入 12月31日 首次會議。")
	_refresh_status()

func _add_meeting_save_controls(parent: VBoxContainer) -> void:
	parent.add_child(_make_section_title("存檔", COLOR_ACCENT_CYAN))

	var hint := _style_hint_label(Label.new())
	hint.text = "手動 5 槽（僅週日會議可寫入）+ 自動 2 槽（僅系統週末寫入）。讀檔隨時可用。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(hint)

	_open_save_slots_button = _compact_button(Button.new(), 0.0, UI_BTN_HEIGHT)
	_open_save_slots_button.text = "存檔／讀檔"
	_open_save_slots_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(_open_save_slots_button, COLOR_BTN_NAV)
	_open_save_slots_button.pressed.connect(_on_open_save_slots_pressed)
	parent.add_child(_open_save_slots_button)

func _setup_save_slot_picker_dialog() -> void:
	_save_slot_picker_dialog = SaveSlotPickerDialogScript.new()
	add_child(_save_slot_picker_dialog)
	_save_slot_picker_dialog.load_succeeded.connect(_on_save_slot_load_succeeded)
	_save_slot_picker_dialog.save_succeeded.connect(_on_save_slot_save_succeeded)

func _on_open_save_slots_pressed() -> void:
	if _save_slot_picker_dialog == null:
		return
	_save_slot_picker_dialog.open_dialog()

func _on_save_slot_load_succeeded(_kind: int, _slot_index: int, result: Dictionary) -> void:
	_add_message(str(result.get("message", "讀檔成功。")))
	_apply_post_load_refresh()

func _on_save_slot_save_succeeded(_kind: int, _slot_index: int, result: Dictionary) -> void:
	_add_message(str(result.get("message", "存檔成功。")))

func _apply_post_load_refresh() -> void:
	_apply_exploration_visibility()
	_refresh_status()
	_refresh_interaction_status()
	_refresh_current_week_schedule_panel()
	_refresh_job_center()
	_refresh_meeting_panel()
	if _save_slot_picker_dialog != null and _save_slot_picker_dialog.visible:
		_save_slot_picker_dialog.open_dialog()

func _build_job_center_panel() -> PanelContainer:
	_job_center_panel = PanelContainer.new()
	_job_center_panel.visible = false
	_job_center_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_panel(_job_center_panel, COLOR_BLOCK_ACCENT, Color(0.55, 0.45, 0.72, 0.40))

	var job_scroll := ScrollContainer.new()
	job_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	job_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	job_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	job_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_job_center_panel.add_child(job_scroll)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	box.add_theme_constant_override("separation", UI_SEP)
	job_scroll.add_child(box)

	box.add_child(_make_section_title("通告中心", COLOR_ACCENT_GOLD))

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", UI_SEP)
	box.add_child(header_row)

	var back_button := _compact_button(Button.new(), 72.0, UI_BTN_HEIGHT_SM)
	back_button.text = "返回"
	_style_button(back_button, COLOR_BLOCK_LIGHT.lightened(0.06), UI_FONT_HINT)
	back_button.pressed.connect(_on_close_job_center_pressed)
	header_row.add_child(back_button)

	var refresh_button := _compact_button(Button.new(), 88.0, UI_BTN_HEIGHT_SM)
	refresh_button.text = "刷新通告"
	_style_button(refresh_button, COLOR_BTN_NAV, UI_FONT_HINT)
	refresh_button.pressed.connect(_on_job_refresh_pressed)
	header_row.add_child(refresh_button)

	_job_summary_label = _style_hint_label(Label.new())
	_job_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_job_summary_label)

	var content_row := HBoxContainer.new()
	content_row.add_theme_constant_override("separation", UI_SEP)
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(content_row)

	var list_panel := VBoxContainer.new()
	list_panel.custom_minimum_size = Vector2(240, 0)
	list_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	content_row.add_child(list_panel)

	list_panel.add_child(_make_section_title("可接通告", COLOR_ACCENT_CYAN))

	_job_list = ItemList.new()
	_job_list.custom_minimum_size = Vector2(230, 140)
	_job_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_job_list.item_selected.connect(_on_job_list_item_selected)
	list_panel.add_child(_job_list)

	var detail_panel := VBoxContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_constant_override("separation", UI_SEP)
	content_row.add_child(detail_panel)

	detail_panel.add_child(_make_section_title("通告詳情", COLOR_ACCENT_CYAN))

	_job_detail_label = _style_body_label(Label.new())
	_job_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_panel.add_child(_job_detail_label)

	_job_sign_box = VBoxContainer.new()
	_job_sign_box.add_theme_constant_override("separation", UI_SEP)
	detail_panel.add_child(_job_sign_box)

	detail_panel.add_child(_make_section_title("指派藝人", COLOR_ACCENT_CYAN))

	var artist_row := HBoxContainer.new()
	artist_row.add_theme_constant_override("separation", UI_SEP)
	detail_panel.add_child(artist_row)

	var artist_caption := _style_hint_label(Label.new())
	artist_caption.text = "藝人"
	artist_row.add_child(artist_caption)

	_job_artist_option = OptionButton.new()
	_job_artist_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_job_artist_option.custom_minimum_size = Vector2(0, UI_BTN_HEIGHT_SM)
	_job_artist_option.item_selected.connect(_on_job_artist_selected)
	artist_row.add_child(_job_artist_option)

	_job_artist_profile_label = _style_hint_label(Label.new())
	_job_artist_profile_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_panel.add_child(_job_artist_profile_label)

	_job_schedule_label = _style_hint_label(Label.new())
	_job_schedule_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_panel.add_child(_job_schedule_label)

	_job_accept_button = _compact_button(Button.new(), 0.0, UI_BTN_HEIGHT)
	_job_accept_button.text = "確認接案"
	_job_accept_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(_job_accept_button, COLOR_BTN_SUCCESS)
	_job_accept_button.pressed.connect(_on_job_accept_pressed)
	detail_panel.add_child(_job_accept_button)

	_job_invite_accept_button = _compact_button(Button.new(), 0.0, UI_BTN_HEIGHT)
	_job_invite_accept_button.text = "接受製片人邀請"
	_job_invite_accept_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(_job_invite_accept_button, COLOR_BTN_NAV)
	_job_invite_accept_button.pressed.connect(_on_job_invite_accept_pressed)
	detail_panel.add_child(_job_invite_accept_button)

	_job_invite_detail_label = _style_hint_label(Label.new())
	_job_invite_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_panel.add_child(_job_invite_detail_label)

	_job_qualification_label = _style_hint_label(Label.new())
	_job_qualification_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_panel.add_child(_job_qualification_label)

	detail_panel.add_child(_make_section_title("進行中", COLOR_ACCENT_CYAN))

	_job_active_label = _style_body_label(Label.new())
	_job_active_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_job_active_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.add_child(_job_active_label)

	return _job_center_panel

func _make_nav_button(text: String, callback: Callable) -> Button:
	var button := _compact_button(Button.new(), 0.0)
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(button, COLOR_BTN_NAV)
	button.pressed.connect(callback)
	return button

func _make_interaction_test_button(text: String, event_factory: Callable) -> Button:
	var button := _compact_button(Button.new(), 0.0, UI_BTN_HEIGHT_SM)
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(button, COLOR_BLOCK_LIGHT.lightened(0.10), UI_FONT_HINT)
	button.pressed.connect(func(): _run_interaction_test(event_factory.call()))
	return button

func _build_right_report_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(250, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_panel(panel, COLOR_PANEL_RIGHT, Color(0.42, 0.55, 0.78, 0.45))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI_SEP)
	panel.add_child(box)

	box.add_child(_make_section_title("系統訊息", COLOR_ACCENT_GOLD))

	var log_panel := PanelContainer.new()
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_panel(log_panel, COLOR_BLOCK_LIGHT.darkened(0.06), Color(0.35, 0.40, 0.50, 0.35))
	box.add_child(log_panel)

	_message_log = RichTextLabel.new()
	_message_log.fit_content = false
	_message_log.scroll_following = true
	_message_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_message_log.add_theme_color_override("default_color", COLOR_TEXT_PRIMARY)
	_message_log.add_theme_color_override("font_selected_color", COLOR_ACCENT_GOLD)
	_message_log.add_theme_font_size_override("normal_font_size", UI_FONT_HINT)
	log_panel.add_child(_message_log)

	return panel

func _make_section_title(text: String, accent: Color = COLOR_ACCENT_GOLD) -> Label:
	var label := Label.new()
	label.text = "◆ %s" % text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.add_theme_font_size_override("font_size", UI_FONT_SECTION)
	label.add_theme_color_override("font_color", accent)
	return label

func _make_action_button(text: String, placeholder_message: String) -> Button:
	var button := _compact_button(Button.new(), 0.0, UI_BTN_HEIGHT_SM)
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(button, COLOR_BLOCK_LIGHT.lightened(0.06), UI_FONT_HINT)
	button.pressed.connect(func(): _on_placeholder_feature_pressed(placeholder_message))
	return button

func _apply_exploration_visibility() -> void:
	var exploring: bool = GameFlowManager.is_exploring_map
	if _company_ui_root != null:
		_company_ui_root.visible = not exploring

	if exploring:
		if _map_hub == null:
			_map_hub = MAP_HUB_SCENE.instantiate()
			_map_hub.set_anchors_preset(Control.PRESET_FULL_RECT)
			_map_hub.offset_left = 0.0
			_map_hub.offset_top = 0.0
			_map_hub.offset_right = 0.0
			_map_hub.offset_bottom = 0.0
			add_child(_map_hub)
			_connect_map_hub_signals()
		_map_hub.visible = true
		_refresh_map_hub_actions()
	else:
		_destroy_map_hub()

func _connect_map_hub_signals() -> void:
	if _map_hub == null:
		return
	if _map_hub.has_signal("facility_visit_requested"):
		if not _map_hub.facility_visit_requested.is_connected(_on_map_facility_visit_requested):
			_map_hub.facility_visit_requested.connect(_on_map_facility_visit_requested)
	if _map_hub.has_signal("exit_map_requested"):
		if not _map_hub.exit_map_requested.is_connected(_on_exit_map_pressed):
			_map_hub.exit_map_requested.connect(_on_exit_map_pressed)
	if _map_hub.has_signal("end_day_requested"):
		if not _map_hub.end_day_requested.is_connected(_on_map_end_day_requested):
			_map_hub.end_day_requested.connect(_on_map_end_day_requested)
	if _map_hub.has_signal("exploration_finished"):
		if not _map_hub.exploration_finished.is_connected(_on_map_exploration_finished):
			_map_hub.exploration_finished.connect(_on_map_exploration_finished)

func _refresh_map_hub_actions() -> void:
	if _map_hub != null and _map_hub.has_method("refresh_action_buttons"):
		_map_hub.refresh_action_buttons()

func _destroy_map_hub() -> void:
	if _map_hub == null:
		return
	_map_hub.queue_free()
	_map_hub = null

func _setup_meeting_gift_picker_dialog() -> void:
	_meeting_gift_picker_dialog = MeetingGiftPickerDialogScript.new()
	add_child(_meeting_gift_picker_dialog)
	_meeting_gift_picker_dialog.confirmed.connect(_on_meeting_gift_confirmed)
	_meeting_gift_picker_dialog.cancelled.connect(_on_meeting_gift_cancelled)

func _on_meeting_gift_confirmed(artist_id: String, item_id: String) -> void:
	_execute_meeting_inventory_gift(artist_id, item_id)

func _on_meeting_gift_cancelled() -> void:
	pass

func _setup_schedule_picker_dialog() -> void:
	_schedule_picker_dialog = SchedulePickerDialog.new()
	add_child(_schedule_picker_dialog)
	_schedule_picker_dialog.confirmed.connect(_on_schedule_picker_confirmed)
	_schedule_picker_dialog.cancelled.connect(_on_schedule_picker_cancelled)

func _on_schedule_picker_confirmed(
	artist_id: String,
	day_index: int,
	option: Dictionary
) -> void:
	var kind: String = str(option.get("kind", ""))
	var result: Dictionary
	if kind in [
		SchedulePickerManager.KIND_VACATION_DOMESTIC,
		SchedulePickerManager.KIND_VACATION_OVERSEAS,
	]:
		result = SchedulePickerManager.apply_vacation_selection(artist_id, day_index, option)
	else:
		result = SchedulePickerManager.apply_selection(artist_id, day_index, option)
	if not result.get("success", false):
		_add_message("[會議/行程] %s" % str(result.get("reason", "安排失敗")))
		return

	_selected_schedule_artist_id = artist_id
	_selected_meeting_day_index = day_index
	_add_message("[會議/行程] %s" % str(result.get("message", "已更新行程")))
	FollowPlanManager.sanitize_draft_follows()
	_refresh_meeting_schedule_row()

func _on_schedule_picker_cancelled() -> void:
	pass

func _connect_game_flow_signals() -> void:
	if not GameFlowManager.day_settlement_started.is_connected(_on_day_settlement_started):
		GameFlowManager.day_settlement_started.connect(_on_day_settlement_started)
	if not GameFlowManager.day_settlement_finished.is_connected(_on_day_settlement_finished):
		GameFlowManager.day_settlement_finished.connect(_on_day_settlement_finished)
	if not GameFlowManager.day_advanced.is_connected(_on_day_advanced):
		GameFlowManager.day_advanced.connect(_on_day_advanced)
	if not GameFlowManager.weekly_report_ready.is_connected(_on_weekly_report_ready):
		GameFlowManager.weekly_report_ready.connect(_on_weekly_report_ready)
	if not GameFlowManager.meeting_started.is_connected(_on_meeting_started):
		GameFlowManager.meeting_started.connect(_on_meeting_started)
	if not GameFlowManager.meeting_finished.is_connected(_on_meeting_finished):
		GameFlowManager.meeting_finished.connect(_on_meeting_finished)
	if not GameFlowManager.week_schedule_committed.is_connected(_on_week_schedule_committed):
		GameFlowManager.week_schedule_committed.connect(_on_week_schedule_committed)
	if not GameFlowManager.phase_changed.is_connected(_on_phase_changed):
		GameFlowManager.phase_changed.connect(_on_phase_changed)
	if not FollowPlanManager.follow_plan_changed.is_connected(_on_follow_plan_changed):
		FollowPlanManager.follow_plan_changed.connect(_on_follow_plan_changed)
	if not GameFlowManager.day_mode_changed.is_connected(_on_day_mode_changed):
		GameFlowManager.day_mode_changed.connect(_on_day_mode_changed)
	if not GameFlowManager.follow_day_finished.is_connected(_on_follow_day_finished):
		GameFlowManager.follow_day_finished.connect(_on_follow_day_finished)
	if not GameFlowManager.story_lock_started.is_connected(_on_story_lock_started):
		GameFlowManager.story_lock_started.connect(_on_story_lock_started)
	if not GameFlowManager.story_lock_finished.is_connected(_on_story_lock_finished):
		GameFlowManager.story_lock_finished.connect(_on_story_lock_finished)
	if not GameFlowManager.map_entered.is_connected(_on_map_entered):
		GameFlowManager.map_entered.connect(_on_map_entered)
	if not GameFlowManager.map_exited.is_connected(_on_map_exited):
		GameFlowManager.map_exited.connect(_on_map_exited)
	if not GameFlowManager.work_report_requested.is_connected(_on_work_report_requested):
		GameFlowManager.work_report_requested.connect(_on_work_report_requested)
	if not GameFlowManager.daily_news_requested.is_connected(_on_daily_news_requested):
		GameFlowManager.daily_news_requested.connect(_on_daily_news_requested)
	if not StoryPlaybackController.playback_batch_finished.is_connected(_on_story_playback_batch_finished):
		StoryPlaybackController.playback_batch_finished.connect(_on_story_playback_batch_finished)

func _on_day_mode_changed(_day_mode: int) -> void:
	_refresh_status()

func _on_follow_day_finished(artist_ids: Array) -> void:
	if artist_ids.is_empty():
		_add_message("[跟隨] 今日行程結束。")
		GameFlowManager.notify_follow_stories_finished()
		return
	var names: PackedStringArray = PackedStringArray()
	for artist_id in artist_ids:
		names.append(_get_meeting_character_display_name(str(artist_id)))
	_add_message("[跟隨] 今日跟隨結束：%s" % "、".join(names))
	var batch: Dictionary = StoryTriggerManager.run_follow_day(artist_ids)
	if bool(batch.get("pending_playback", false)):
		return
	_finalize_story_batch(batch, "跟隨劇情")
	GameFlowManager.notify_follow_stories_finished()

func _on_story_playback_batch_finished(batch: Dictionary) -> void:
	var context: String = str(batch.get("context", ""))
	match context:
		"follow":
			_finalize_story_batch(batch, "跟隨劇情")
			GameFlowManager.notify_follow_stories_finished()
		"visit":
			_finalize_story_batch(batch, "探望")
		"sign":
			_finalize_story_batch(batch, "簽約劇情")
			if bool(batch.get("success", false)) or str(batch.get("reason", "")) == "no_matching_event":
				_try_enter_first_meeting_after_sign()
		"calendar":
			_finalize_story_batch(batch, "簽約首日")
			_try_enter_first_meeting_after_sign()
		"meeting":
			_finalize_story_batch(batch, "週日會議")
			_refresh_meeting_panel()
			_refresh_status()
		_:
			_finalize_story_batch(batch, "劇情")

func _finalize_story_batch(batch: Dictionary, log_prefix: String) -> void:
	if str(batch.get("reason", "")) == "pending_playback":
		return
	_present_story_trigger_batch(batch, log_prefix)

func _try_enter_first_meeting_after_sign() -> void:
	if GameFlowManager.game_phase != GameFlowManager.GamePhase.STORY:
		return
	if GameFlowManager.needs_initial_sign():
		return
	GameFlowManager.finish_opening_story()

func _try_play_post_sign_calendar_story(artist_id: String) -> void:
	if artist_id.strip_edges() == "":
		_try_enter_first_meeting_after_sign()
		return
	if artist_id == "artist_003":
		_play_artist_003_sign_to_day1_bridge(artist_id)
		return
	_start_post_sign_calendar_story(artist_id)

func _play_artist_003_sign_to_day1_bridge(artist_id: String) -> void:
	var bridge := StoryBeatTransition.new()
	add_child(bridge)
	bridge.finished.connect(
		func() -> void:
			_start_post_sign_calendar_story(artist_id),
		CONNECT_ONE_SHOT
	)
	bridge.play_artist_003_sign_to_day1_bridge()

func _start_post_sign_calendar_story(artist_id: String) -> void:
	var batch: Dictionary = StoryTriggerManager.try_play_calendar_story(artist_id)
	if bool(batch.get("pending_playback", false)):
		return
	if str(batch.get("reason", "")) == "no_matching_event":
		_try_enter_first_meeting_after_sign()
		return
	_finalize_story_batch(batch, "簽約首日")
	_try_enter_first_meeting_after_sign()

func _on_map_facility_visit_requested(
	location_id: String,
	facility_id: String,
	facility_name: String
) -> void:
	var batch: Dictionary = StoryTriggerManager.try_visit(location_id, facility_id)
	if batch.get("reason", "") == "no_matching_event":
		return
	if batch.get("reason", "") == "chance_failed":
		_add_message("[探望] 在%s沒有遇到特殊狀況。" % facility_name)
		return
	if bool(batch.get("pending_playback", false)):
		return
	_finalize_story_batch(batch, "探望")

func _present_story_trigger_batch(batch: Dictionary, log_prefix: String) -> void:
	if batch.is_empty():
		return

	var reason: String = str(batch.get("reason", ""))
	if not bool(batch.get("success", false)):
		if reason in ["no_matching_event", "chance_failed", "not_follow_day", "not_free_day"]:
			return
		if reason == "no_follow_artists":
			return
		_add_message("[%s] 未觸發：%s" % [log_prefix, reason])
		return

	for entry in batch.get("entries", []):
		if not (entry is Dictionary):
			continue
		var title: String = str(entry.get("event_title", "劇情"))
		var mode_label: String = str(entry.get("trigger_mode", ""))
		var participants: Array = entry.get("participant_ids", [])
		var participant_names: PackedStringArray = PackedStringArray()
		for participant_id in participants:
			participant_names.append(_get_meeting_character_display_name(str(participant_id)))

		var headline: String = "[%s/%s]" % [log_prefix, title]
		if mode_label == "PARALLEL" and participant_names.size() > 0:
			headline += "（並列：%s）" % "、".join(participant_names)
		elif participant_names.size() == 1:
			headline += "（%s）" % participant_names[0]
		_add_message(headline)

		var interaction_result: Dictionary = entry.get("interaction_result", {})
		if str(interaction_result.get("result_text", "")).strip_edges() != "":
			_add_message("・%s" % interaction_result["result_text"])
		elif str(entry.get("result_text", "")).strip_edges() != "":
			_add_message("・%s" % entry["result_text"])

		if interaction_result.get("relationship_changed", false):
			var changes: Variant = interaction_result.get("affection_changes", [])
			if changes is Array and changes.size() > 0:
				for change in changes:
					if not (change is Dictionary):
						continue
					_add_message("・%s 好感 %d → %d（%s）" % [
						_get_meeting_character_display_name(str(change.get("character_id", ""))),
						change.get("old_affection", 0),
						change.get("new_affection", 0),
						change.get("relationship_level", ""),
					])
			else:
				_add_message("・好感 %d → %d（%s）" % [
					interaction_result.get("old_affection", 0),
					interaction_result.get("new_affection", 0),
					interaction_result.get("relationship_level", ""),
				])

func _on_story_lock_started(event_id: String, days: int) -> void:
	var label: String = event_id if event_id.strip_edges() != "" else "特殊劇情"
	_add_message("[劇情] %s 開始，占用 %d 天。" % [label, days])

func _on_story_lock_finished(event_id: String) -> void:
	var label: String = event_id if event_id.strip_edges() != "" else "特殊劇情"
	_add_message("[劇情] %s 段落結束，恢復正常日循環。" % label)

func _on_map_entered() -> void:
	_add_message("[探索] 進入大地圖。")
	_apply_exploration_visibility()
	_refresh_status()

func _on_map_exited() -> void:
	_add_message("[探索] 結束探索，返回公司。")
	_apply_exploration_visibility()
	_refresh_status()

func _on_map_exploration_finished(_reason: String) -> void:
	_finish_map_exploration()

func _on_map_end_day_requested() -> void:
	_finish_map_exploration()

func _finish_map_exploration() -> void:
	if not GameFlowManager.is_exploring_map:
		_add_message("請先在大地圖探索，離開後才會結算今日行程。")
		return
	if GameFlowManager.day_settlement_done:
		return
	var result: Dictionary = GameFlowManager.exit_map()
	if not result.get("success", false):
		_add_message("無法結束探索：%s" % str(result.get("reason", "未知原因")))

func _on_enter_map_pressed() -> void:
	var result: Dictionary = GameFlowManager.enter_map()
	if not result.get("success", false):
		_add_message("無法進入大地圖：%s" % str(result.get("reason", "未知原因")))

func _on_exit_map_pressed() -> void:
	var result: Dictionary = GameFlowManager.exit_map()
	if not result.get("success", false):
		_add_message("無法離開大地圖：%s" % str(result.get("reason", "未知原因")))

func _on_follow_plan_changed() -> void:
	if GameFlowManager.is_meeting_phase:
		_refresh_meeting_schedule_row()
	else:
		_refresh_status()

func _on_phase_changed(_new_phase: int) -> void:
	_refresh_status()

func _connect_news_signals() -> void:
	if not NewsManager.news_added.is_connected(_on_news_added):
		NewsManager.news_added.connect(_on_news_added)

func _connect_artist_signals() -> void:
	if not ArtistManager.roster_changed.is_connected(_refresh_meeting_panel):
		ArtistManager.roster_changed.connect(_refresh_meeting_panel)
	if not ArtistManager.roster_changed.is_connected(_refresh_job_center):
		ArtistManager.roster_changed.connect(_refresh_job_center)
	if not InventoryManager.inventory_changed.is_connected(_refresh_meeting_detail):
		InventoryManager.inventory_changed.connect(_refresh_meeting_detail)

func _connect_job_signals() -> void:
	if not JobManager.job_board_changed.is_connected(_refresh_job_center):
		JobManager.job_board_changed.connect(_refresh_job_center)
	if not JobManager.job_completed.is_connected(_on_job_completed):
		JobManager.job_completed.connect(_on_job_completed)
	if not GigManager.gig_day_settled.is_connected(_on_gig_day_settled):
		GigManager.gig_day_settled.connect(_on_gig_day_settled)
	if not CourseManager.course_day_settled.is_connected(_on_course_day_settled):
		CourseManager.course_day_settled.connect(_on_course_day_settled)

func _on_gig_day_settled(artist_id: String, gig: GigResource, result: Dictionary) -> void:
	_add_activity_settlement_message("打工", artist_id, str(result.get("activity_name", gig.gig_name)), result)

func _on_course_day_settled(artist_id: String, course: CourseResource, result: Dictionary) -> void:
	_add_activity_settlement_message("课程", artist_id, str(result.get("activity_name", course.course_name)), result)

func _add_activity_settlement_message(
	activity_label: String,
	artist_id: String,
	activity_name: String,
	result: Dictionary
) -> void:
	var artist_name: String = _get_meeting_character_display_name(artist_id)
	var quality_name: String = str(result.get("quality_name", ""))
	if quality_name == "":
		_add_message("[結算/%s] %s · %s：%s" % [
			activity_label,
			artist_name,
			activity_name,
			str(result.get("detail", result.get("reason", "未結算"))),
		])
		return
	_add_message("[結算/%s] %s · %s → %s" % [
		activity_label,
		artist_name,
		activity_name,
		quality_name,
	])
	_append_standing_message(result.get("standing", {}))
	_refresh_status()

func _refresh_status() -> void:
	var date_snapshot: Dictionary = TimeManager.get_date_snapshot()
	if _office_title_label != null:
		if PlayerManager.is_company_name_locked():
			_office_title_label.text = PlayerManager.get_company_name()
		else:
			_office_title_label.text = "經紀公司（開局設定）"
	_protagonist_label.text = "主角：%s" % ProtagonistManager.get_full_name()
	_company_label.text = "公司：%s" % (
		PlayerManager.get_company_name() if PlayerManager.is_company_name_locked() else "（尚未設定）"
	)
	_scale_label.text = "公司規模：%s" % PlayerManager.get_company_scale_name()
	_date_label.text = "目前日期：%s" % date_snapshot["display_text"]
	_phase_label.text = GameFlowManager.get_phase_hint()
	_phase_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_roster_label.text = "旗下藝人：%d / %d" % [ArtistManager.get_signed_count(), ArtistManager.get_roster_limit()]
	if _roster_profile_label != null:
		var roster_profile_text: String = ArtistProfileDisplay.build_roster_sidebar_text()
		_roster_profile_label.text = roster_profile_text
		_roster_profile_label.visible = roster_profile_text != ""
	_money_label.text = "資金：$%d" % PlayerManager.money
	_reputation_label.text = "公司聲望：%d" % PlayerManager.company_reputation
	_public_opinion_label.text = "公司口碑：%d" % PlayerManager.company_public_opinion
	_job_stats_label.text = (
		"通告 成功/完美/失败：%d / %d / %d\n"
		+ "打工 成功/完美/失败：%d / %d / %d\n"
		+ "课程 成功/完美/失败：%d / %d / %d"
	) % [
		PlayerManager.successful_jobs_count,
		PlayerManager.perfect_jobs_count,
		PlayerManager.failed_jobs_count,
		PlayerManager.successful_gigs_count,
		PlayerManager.perfect_gigs_count,
		PlayerManager.failed_gigs_count,
		PlayerManager.successful_courses_count,
		PlayerManager.perfect_courses_count,
		PlayerManager.failed_courses_count,
	]
	_upgrade_info_label.text = "\n".join(PlayerManager.get_upgrade_status_lines())

	_end_day_button.visible = GameFlowManager.can_finish_today()
	_end_day_button.disabled = (
		not GameFlowManager.can_finish_today() or StoryPlaybackController.is_playing()
	)
	_end_meeting_button.disabled = (
		not GameFlowManager.can_end_meeting() or StoryPlaybackController.is_playing()
	)
	if _open_save_slots_button != null:
		_open_save_slots_button.disabled = false
	if _enter_map_button != null:
		_enter_map_button.visible = GameFlowManager.can_enter_map()
		_enter_map_button.disabled = not GameFlowManager.can_enter_map()
	if _exit_map_button != null:
		_exit_map_button.visible = GameFlowManager.can_exit_map()
		_exit_map_button.disabled = not GameFlowManager.can_exit_map()
	_refresh_map_hub_actions()
	match GameFlowManager.get_day_mode():
		GameFlowManager.DayMode.STORY_LOCK:
			_end_day_button.text = "繼續劇情"
		GameFlowManager.DayMode.FREE:
			_end_day_button.text = (
				"結束探索" if GameFlowManager.is_exploring_map else "結束今日"
			)
		GameFlowManager.DayMode.FOLLOW:
			_end_day_button.text = "結束今日"
		_:
			_end_day_button.text = "結束今日"
	_apply_exploration_visibility()
	_upgrade_company_button.disabled = not PlayerManager.can_upgrade_company()

	if _showing_job_center:
		if _center_daily_title != null:
			_center_daily_title.visible = false
		_daily_panel.visible = false
		_meeting_panel.visible = false
		if _job_center_panel != null:
			_job_center_panel.visible = true
	else:
		var in_meeting: bool = GameFlowManager.is_meeting_phase
		var in_story: bool = GameFlowManager.game_phase == GameFlowManager.GamePhase.STORY
		_daily_panel.visible = not in_meeting
		_meeting_panel.visible = in_meeting
		if _center_daily_title != null:
			_center_daily_title.visible = not in_meeting and not in_story
		if _job_center_panel != null:
			_job_center_panel.visible = false
		if in_meeting:
			_refresh_meeting_panel()
		elif not in_story:
			_refresh_current_week_schedule_panel()
	_refresh_job_center()

func _add_message(message: String) -> void:
	if _message_log == null:
		return
	_message_log.append_text(message + "\n")

func _on_placeholder_feature_pressed(message: String) -> void:
	_add_message(message)

func _on_upgrade_company_pressed() -> void:
	var upgrade_result: Dictionary = {}
	if PlayerManager.upgrade_company(upgrade_result):
		var event_messages: Array[String] = CompanyEventManager.handle_company_upgraded(
			upgrade_result["old_scale"],
			upgrade_result["new_scale"],
			upgrade_result["upgrade_cost"]
		)
		for message in event_messages:
			_add_message(message)
	else:
		_add_message("公司升級條件尚未滿足。")
		for line in PlayerManager.get_upgrade_status_lines():
			_add_message("・%s" % line)
	_refresh_status()

func _on_end_day_pressed() -> void:
	if _showing_job_center:
		_show_job_center_view(false)
	GameFlowManager.finish_today()
	_refresh_status()

func _on_end_meeting_pressed() -> void:
	if _showing_job_center:
		_show_job_center_view(false)
	GameFlowManager.end_meeting()
	_refresh_status()

func _on_day_settlement_started(date_snapshot: Dictionary) -> void:
	_add_message("開始結算：%s" % date_snapshot["display_text"])

func _on_day_settlement_finished(date_snapshot: Dictionary) -> void:
	_add_message("完成結算：%s" % date_snapshot["display_text"])

func _on_day_advanced(date_snapshot: Dictionary) -> void:
	_add_message("日期推進到：%s" % date_snapshot["display_text"])
	_refresh_status()

func _on_weekly_report_ready(advices: Array) -> void:
	_add_message("秘書週報：")
	for advice in advices:
		_add_message("・%s" % advice)

func _on_meeting_started(date_snapshot: Dictionary) -> void:
	var is_first_meeting: bool = (
		GameFlowManager.game_phase == GameFlowManager.GamePhase.FIRST_MEETING
	)
	if is_first_meeting:
		_add_message("進入首次會議：%s（無當日行程）" % date_snapshot["display_text"])
		_add_message("[會議] 排定下週行程並勾選跟隨；完成後按「結束週日會議」進入 1/1 週一。")
	else:
		_add_message("進入週日會議：%s" % date_snapshot["display_text"])
		if ArtistManager.get_signed_count() == 0:
			_add_message("[會議] 尚無旗下藝人：請先到「通告中心」簽約（小型公司可簽 2 人）。")
		else:
			_add_message("[會議] 編排下週行程、勾選跟隨，完成後按「結束週日會議」提交。")
	FollowPlanManager.sanitize_draft_follows()
	_refresh_meeting_panel()
	_refresh_status()
	var salary_result: Dictionary = ItemManager.try_process_monthly_salary()
	if bool(salary_result.get("success", false)) and not bool(salary_result.get("skipped", false)):
		_add_message("[會議] 本月薪資已扣除 $%d（%d 位藝人）。" % [
			int(salary_result.get("total_salary", 0)),
			int(salary_result.get("artist_count", 0)),
		])
	elif str(salary_result.get("reason", "")) == "insufficient_funds":
		_add_message("[會議] 金幣不足，無法支付本月薪資 $%d。" % int(salary_result.get("total_salary", 0)))
	if not is_first_meeting:
		var auto_result: Dictionary = SaveManager.try_weekly_auto_save(date_snapshot)
		if auto_result.get("success", false):
			_add_message(
				"[自動存檔] 已寫入 %s。"
				% SaveManager.get_slot_display_name(
					SaveManager.SlotKind.AUTO,
					int(auto_result.get("auto_slot_index", 0)),
				)
			)
	var batch: Dictionary = StoryTriggerManager.try_play_meeting_story({
		"is_first_meeting": is_first_meeting,
		"primary_artist_id": _get_primary_signed_artist_id(),
	})
	if bool(batch.get("pending_playback", false)):
		return
	if str(batch.get("reason", "")) != "no_matching_event":
		_finalize_story_batch(batch, "週日會議")

func _on_meeting_finished(_date_snapshot: Dictionary) -> void:
	_add_message("會議結束，目前日期：%s" % TimeManager.get_display_text())
	_refresh_status()

func _on_week_schedule_committed(signed_artist_count: int) -> void:
	_add_message("下週行程已提交，覆蓋 %d 位旗下藝人。" % signed_artist_count)
	_refresh_current_week_schedule_panel()

func _on_news_added(news_item: Dictionary) -> void:
	_add_message("[新聞/%s/%s] %s" % [
		news_item["media_name"],
		news_item["category_name"],
		news_item["title"]
	])

# ==========================================
# 週日會議互動
# ==========================================
func _refresh_meeting_panel() -> void:
	if _meeting_character_row == null:
		return

	for child in _meeting_character_row.get_children():
		child.queue_free()

	var character_ids: Array[String] = [SecretaryManager.SECRETARY_ID]
	for artist_id in ArtistManager.get_signed_ids():
		character_ids.append(str(artist_id))

	if not character_ids.has(_selected_meeting_character_id):
		_selected_meeting_character_id = SecretaryManager.SECRETARY_ID

	for character_id in character_ids:
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 2)
		column.alignment = BoxContainer.ALIGNMENT_CENTER

		if _is_meeting_artist(character_id):
			column.add_child(_make_character_portrait_rect(character_id, PORTRAIT_MEETING_TAB))

		var button := _compact_button(Button.new(), 72.0, UI_BTN_HEIGHT_SM)
		button.toggle_mode = true
		button.button_group = _meeting_button_group
		button.text = _get_meeting_character_display_name(character_id)
		_style_button(
			button,
			COLOR_BTN_PRIMARY if character_id == _selected_meeting_character_id else COLOR_BLOCK_LIGHT.lightened(0.06),
			UI_FONT_HINT
		)
		button.button_pressed = character_id == _selected_meeting_character_id
		button.pressed.connect(_on_meeting_character_selected.bind(character_id))
		column.add_child(button)
		_meeting_character_row.add_child(column)

	_refresh_meeting_detail()
	_refresh_meeting_schedule_row()

func _on_meeting_character_selected(character_id: String) -> void:
	_selected_meeting_character_id = character_id
	_refresh_meeting_detail()
	_refresh_meeting_schedule_row()

func _refresh_meeting_detail() -> void:
	if _meeting_detail_label == null:
		return

	var character_id: String = _selected_meeting_character_id
	var affection: int = RelationshipManager.get_affection(character_id)
	var level_name: String = RelationshipManager.get_relationship_level_name(character_id)
	var role_text: String = CharacterDatabase.get_role_label(character_id)
	var roster_hint: String = ""
	if ArtistManager.get_signed_count() == 0:
		roster_hint = "\n（目前旗下尚無藝人，解約/續約/行程編排需先完成開局簽約。）"

	var is_artist: bool = _is_meeting_artist(character_id)

	_meeting_detail_label.text = (
		"目前對象：%s（%s）\n好感：%d（%s）| 資金：$%d\n聲望：%d | 口碑：%d%s"
		% [
			_get_meeting_character_display_name(character_id),
			role_text,
			affection,
			level_name,
			PlayerManager.money,
			PlayerManager.company_reputation,
			PlayerManager.company_public_opinion,
			roster_hint,
		]
	)

	_meeting_chat_button.disabled = _is_meeting_action_done("meeting_chat", character_id)
	_meeting_renew_button.disabled = not is_artist or _is_meeting_action_done("meeting_renew", character_id)
	_meeting_terminate_button.disabled = not is_artist

	var giftable_count: int = InventoryManager.get_giftable_entries().size() if is_artist else 0
	_meeting_gift_button.disabled = not is_artist
	if not is_artist:
		_meeting_gift_button.text = "送禮（僅藝人）"
		_meeting_chat_button.text = "聊天"
	elif _meeting_chat_button.disabled:
		_meeting_chat_button.text = "聊天（本週已聊）"
	else:
		_meeting_chat_button.text = "聊天"
	if is_artist:
		if giftable_count <= 0:
			_meeting_gift_button.text = "送禮（物品欄空）"
		else:
			_meeting_gift_button.text = "送禮（%d）" % giftable_count

	if _meeting_profile_label != null:
		if is_artist:
			_meeting_profile_label.text = ArtistProfileDisplay.build_detail_multiline_for_id(character_id)
			_meeting_profile_label.visible = true
		else:
			_meeting_profile_label.text = ""
			_meeting_profile_label.visible = false

	if not is_artist:
		_meeting_renew_button.text = "續約（僅藝人）"
		_meeting_terminate_button.text = "解約（僅藝人）"
	elif _meeting_renew_button.disabled:
		_meeting_renew_button.text = "續約（本週已完成）"
		_meeting_terminate_button.text = "解約"
	else:
		_meeting_renew_button.text = "續約"
		_meeting_terminate_button.text = "解約"

func _refresh_meeting_schedule_row() -> void:
	if _meeting_schedule_grid_host == null:
		return

	for child in _meeting_schedule_grid_host.get_children():
		child.queue_free()
	_meeting_schedule_cell_buttons.clear()

	var signed_ids: Array = ArtistManager.get_signed_ids()
	var has_signed_artists: bool = not signed_ids.is_empty()

	if _meeting_schedule_editor_box != null:
		_meeting_schedule_editor_box.visible = false

	if not has_signed_artists:
		_selected_schedule_artist_id = ""
		var empty_hint := _style_hint_label(Label.new())
		empty_hint.text = "尚無藝人，請先完成開局 3 選 1 簽約。"
		empty_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_meeting_schedule_grid_host.add_child(empty_hint)
		if _meeting_schedule_selection_label != null:
			_meeting_schedule_selection_label.text = ""
		return

	_ensure_meeting_schedule_selection_valid(signed_ids)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 4)
	_meeting_schedule_grid_host.add_child(header_row)

	var corner_label := _style_hint_label(Label.new())
	corner_label.custom_minimum_size = Vector2(56, 0)
	corner_label.text = "日期"
	header_row.add_child(corner_label)

	for artist_id in signed_ids:
		var artist_id_text: String = str(artist_id)
		var artist_header := _build_schedule_artist_header(artist_id_text, true)
		header_row.add_child(artist_header)

	for day_index in range(ScheduleManager.DAYS_PER_WEEK):
		var day_row := HBoxContainer.new()
		day_row.add_theme_constant_override("separation", 4)
		_meeting_schedule_grid_host.add_child(day_row)

		var day_label := _style_hint_label(Label.new())
		day_label.custom_minimum_size = Vector2(56, 0)
		day_label.text = "週%s" % ["一", "二", "三", "四", "五", "六", "日"][day_index]
		day_row.add_child(day_label)

		for artist_id in signed_ids:
			var artist_id_text: String = str(artist_id)
			var week: Array = ScheduleManager.get_draft_week(artist_id_text)
			var slot: Dictionary = week[day_index]
			var display_lines: PackedStringArray = ScheduleManager.get_slot_display_lines(slot)
			var lock_hint: String = ScheduleManager.get_slot_lock_hint(slot)
			var is_editable: bool = ScheduleManager.is_draft_slot_editable(artist_id_text, day_index)
			var is_selected: bool = (
				artist_id_text == _selected_schedule_artist_id
				and day_index == _selected_meeting_day_index
			)
			var can_follow: bool = FollowPlanManager.can_follow_slot(slot)
			var follow_enabled: bool = FollowPlanManager.is_follow_enabled(artist_id_text, day_index, true)

			var cell_box := VBoxContainer.new()
			cell_box.custom_minimum_size = Vector2(84, 0)
			cell_box.add_theme_constant_override("separation", 2)
			day_row.add_child(cell_box)

			var cell_button := _compact_button(Button.new(), 84.0, 34)
			cell_button.toggle_mode = true
			cell_button.text = _build_schedule_cell_text(display_lines, lock_hint)
			cell_button.button_pressed = is_selected
			cell_button.pressed.connect(_on_meeting_schedule_cell_pressed.bind(artist_id_text, day_index))
			_apply_schedule_cell_visual(cell_button, is_selected, is_editable, lock_hint)
			cell_box.add_child(cell_button)
			_meeting_schedule_cell_buttons[_make_schedule_cell_key(artist_id_text, day_index)] = cell_button

			var follow_check := CheckBox.new()
			follow_check.text = "跟"
			follow_check.disabled = not can_follow
			follow_check.add_theme_font_size_override("font_size", UI_FONT_HINT)
			follow_check.toggled.connect(func(pressed: bool) -> void:
				_on_meeting_follow_toggled(artist_id_text, day_index, pressed))
			follow_check.set_block_signals(true)
			follow_check.button_pressed = follow_enabled
			follow_check.set_block_signals(false)
			cell_box.add_child(follow_check)

	_refresh_meeting_schedule_selection_label()

func _ensure_meeting_schedule_selection_valid(signed_ids: Array) -> void:
	if _selected_schedule_artist_id == "" or not ArtistManager.is_signed(_selected_schedule_artist_id):
		_selected_schedule_artist_id = str(signed_ids[0])
		_selected_meeting_day_index = 0
	_selected_meeting_day_index = clampi(_selected_meeting_day_index, 0, ScheduleManager.DAYS_PER_WEEK - 1)

func _make_schedule_cell_key(artist_id: String, day_index: int) -> String:
	return "%s|%d" % [artist_id, day_index]

func _on_meeting_schedule_cell_pressed(artist_id: String, day_index: int) -> void:
	if not ArtistManager.is_signed(artist_id):
		return

	_selected_schedule_artist_id = artist_id
	_selected_meeting_day_index = day_index
	_refresh_meeting_schedule_row()
	if _schedule_picker_dialog != null:
		_schedule_picker_dialog.open_for_draft_slot(artist_id, day_index)

func _on_meeting_follow_toggled(artist_id: String, day_index: int, enabled: bool) -> void:
	if not FollowPlanManager.set_follow_enabled(artist_id, day_index, enabled, true):
		_add_message("[跟隨] 此格無法跟隨（僅通告／打工／課程）。")
		_refresh_meeting_schedule_row()
		return

	var group_ids: Array[String] = FollowPlanManager.get_follow_artist_ids_for_day(day_index, true)
	if enabled and group_ids.size() > 1:
		var names: PackedStringArray = PackedStringArray()
		for group_artist_id in group_ids:
			names.append(_get_meeting_character_display_name(group_artist_id))
		_add_message("[跟隨] %s · %s 同日同任務，一併跟隨：%s" % [
			TimeManager.DAY_NAMES[day_index],
			_get_meeting_character_display_name(artist_id),
			"、".join(names),
		])
	_refresh_meeting_schedule_row()

func _refresh_meeting_schedule_selection_label() -> void:
	if _meeting_schedule_selection_label == null:
		return
	if _selected_schedule_artist_id == "":
		_meeting_schedule_selection_label.text = ""
		return
	_meeting_schedule_selection_label.text = "正在編輯：%s · %s" % [
		_get_meeting_character_display_name(_selected_schedule_artist_id),
		TimeManager.DAY_NAMES[_selected_meeting_day_index],
	]
	var lock_hint: String = ScheduleManager.get_slot_lock_hint(
		ScheduleManager.get_draft_week(_selected_schedule_artist_id)[_selected_meeting_day_index]
	)
	if lock_hint != "":
		_meeting_schedule_selection_label.text += "（%s，僅可查看）" % lock_hint

func _build_schedule_cell_text(display_lines: PackedStringArray, lock_hint: String) -> String:
	var type_line: String = display_lines[0] if display_lines.size() > 0 else "空白"
	var detail_line: String = display_lines[1] if display_lines.size() > 1 else "—"
	if lock_hint != "":
		return "%s\n%s\n[%s]" % [type_line, detail_line, lock_hint]
	return "%s\n%s" % [type_line, detail_line]

func _apply_schedule_cell_visual(
	cell_button: Button,
	is_selected: bool,
	is_editable: bool,
	_lock_hint: String
) -> void:
	var bg: Color
	if is_selected:
		bg = COLOR_BTN_PRIMARY.lightened(0.08) if is_editable else COLOR_BLOCK_LIGHT.lightened(0.12)
	elif not is_editable:
		bg = COLOR_BLOCK_LIGHT.darkened(0.12)
	else:
		bg = COLOR_BLOCK_LIGHT.lightened(0.04)
	_style_button(cell_button, bg, UI_FONT_HINT)
	if is_selected:
		cell_button.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	elif not is_editable:
		cell_button.add_theme_color_override("font_color", COLOR_TEXT_MUTED)

func _refresh_meeting_schedule_editor_interaction_state() -> void:
	var can_edit_selected: bool = (
		_selected_schedule_artist_id != ""
		and ScheduleManager.is_draft_slot_editable(_selected_schedule_artist_id, _selected_meeting_day_index)
	)

	if _meeting_schedule_type_row != null:
		for child in _meeting_schedule_type_row.get_children():
			if child is Button:
				child.disabled = not can_edit_selected

	if _meeting_task_option != null:
		var spec: Dictionary = _get_meeting_schedule_type_spec(_pending_meeting_schedule_type)
		var task_disabled: bool = not bool(spec.get("needs_task", false)) or not can_edit_selected
		if _meeting_task_option.item_count > 0 \
				and str(_meeting_task_option.get_item_text(0)) == "（尚無可用模板）":
			task_disabled = true
		if _meeting_task_option.item_count == 0:
			task_disabled = true
		_meeting_task_option.disabled = task_disabled

func _on_meeting_copy_last_week_pressed(artist_id: String) -> void:
	if not ArtistManager.is_signed(artist_id):
		return
	if not ScheduleManager.copy_current_week_to_next_draft(artist_id):
		_add_message("[會議/行程] %s 同上週失敗。" % _get_meeting_character_display_name(artist_id))
		return

	_selected_schedule_artist_id = artist_id
	_selected_meeting_day_index = 0
	_add_message("[會議/行程] 已將 %s 的上週計畫複製到下週草稿。" % _get_meeting_character_display_name(artist_id))
	_refresh_meeting_schedule_row()

func _on_meeting_schedule_type_pressed(schedule_type: int) -> void:
	if _selected_schedule_artist_id == "" or not ArtistManager.is_signed(_selected_schedule_artist_id):
		return

	_pending_meeting_schedule_type = schedule_type
	_refresh_meeting_task_options()
	if not _apply_meeting_schedule_type(schedule_type):
		return

	FollowPlanManager.sanitize_draft_follows()
	_refresh_meeting_schedule_row()
	_add_message("[會議/行程] %s 的 %s 已更新。" % [
		_get_meeting_character_display_name(_selected_schedule_artist_id),
		_get_meeting_schedule_apply_target_text(schedule_type),
	])

func _on_meeting_task_selected(_index: int) -> void:
	var spec: Dictionary = _get_meeting_schedule_type_spec(_pending_meeting_schedule_type)
	if not bool(spec.get("needs_task", false)):
		return
	if _apply_meeting_schedule_type(_pending_meeting_schedule_type):
		FollowPlanManager.sanitize_draft_follows()
		_refresh_meeting_schedule_row()
		_refresh_meeting_schedule_detail_label()

func _sync_meeting_schedule_editor_to_slot() -> void:
	if _selected_schedule_artist_id == "":
		return
	var week: Array = ScheduleManager.get_draft_week(_selected_schedule_artist_id)
	var slot: Dictionary = week[_selected_meeting_day_index]
	_pending_meeting_schedule_type = int(slot.get("type", ScheduleManager.ScheduleType.ROUTINE_EMPTY))
	_refresh_meeting_task_options()
	_select_meeting_task_option_from_slot(slot)
	_refresh_meeting_schedule_detail_label()
	_refresh_meeting_schedule_selection_label()
	_refresh_meeting_schedule_editor_interaction_state()

func _refresh_meeting_task_options() -> void:
	if _meeting_task_option == null:
		return

	var current_metadata = null
	if _meeting_task_option.item_count > 0:
		var selected_index: int = _meeting_task_option.get_selected()
		if selected_index >= 0:
			current_metadata = _meeting_task_option.get_item_metadata(selected_index)
	_meeting_task_option.clear()

	var spec: Dictionary = _get_meeting_schedule_type_spec(_pending_meeting_schedule_type)
	if not bool(spec.get("needs_task", false)):
		_meeting_task_option.add_item("（此類型無需選項目）")
		_meeting_task_option.set_item_metadata(0, null)
		_meeting_task_option.disabled = true
		return

	_meeting_task_option.disabled = false
	var task_kind: String = str(spec.get("task_kind", ""))
	match task_kind:
		"course":
			for course in CourseManager.get_unlocked_courses():
				var item_index: int = _meeting_task_option.item_count
				_meeting_task_option.add_item(course.course_name)
				_meeting_task_option.set_item_metadata(item_index, course)
		"gig":
			for gig in GigManager.get_unlocked_gigs():
				var item_index: int = _meeting_task_option.item_count
				_meeting_task_option.add_item(gig.gig_name)
				_meeting_task_option.set_item_metadata(item_index, gig)
		"vacation_domestic":
			for vacation in VacationManager.get_vacations_by_type(VacationResource.VacationType.DOMESTIC):
				var item_index: int = _meeting_task_option.item_count
				_meeting_task_option.add_item(vacation.vacation_name)
				_meeting_task_option.set_item_metadata(item_index, vacation)
		"vacation_overseas":
			for vacation in VacationManager.get_vacations_by_type(VacationResource.VacationType.OVERSEAS):
				var item_index: int = _meeting_task_option.item_count
				_meeting_task_option.add_item(vacation.vacation_name)
				_meeting_task_option.set_item_metadata(item_index, vacation)
		"job":
			for entry in JobManager.get_active_job_entries_for_artist(_selected_schedule_artist_id):
				var job_instance: JobInstance = entry.get("instance")
				if job_instance == null:
					continue
				var item_index: int = _meeting_task_option.item_count
				_meeting_task_option.add_item(str(entry.get("job_name", "通告")))
				_meeting_task_option.set_item_metadata(item_index, job_instance)

	if _meeting_task_option.item_count == 0:
		_meeting_task_option.add_item("（尚無可用模板）")
		_meeting_task_option.set_item_metadata(0, null)
		_meeting_task_option.disabled = true
		return

	if current_metadata != null:
		for index in range(_meeting_task_option.item_count):
			if _meeting_task_option.get_item_metadata(index) == current_metadata:
				_meeting_task_option.select(index)
				return
	_meeting_task_option.select(0)

func _select_meeting_task_option_from_slot(slot: Dictionary) -> void:
	if _meeting_task_option == null or _meeting_task_option.item_count == 0:
		return

	var task_data = slot.get("task_data")
	if task_data == null:
		_meeting_task_option.select(0)
		return

	for index in range(_meeting_task_option.item_count):
		if _meeting_task_option.get_item_metadata(index) == task_data:
			_meeting_task_option.select(index)
			return

func _apply_meeting_schedule_type(schedule_type: int) -> bool:
	if _selected_schedule_artist_id == "":
		return false

	var spec: Dictionary = _get_meeting_schedule_type_spec(schedule_type)
	if bool(spec.get("whole_week", false)):
		pass
	elif not ScheduleManager.is_draft_slot_editable(_selected_schedule_artist_id, _selected_meeting_day_index):
		if _meeting_schedule_detail_label != null:
			var week: Array = ScheduleManager.get_draft_week(_selected_schedule_artist_id)
			var slot: Dictionary = week[_selected_meeting_day_index]
			_meeting_schedule_detail_label.text = "此格%s，請改選其他日期，或使用整週類型覆蓋。" % ScheduleManager.get_slot_lock_hint(slot)
		return false

	var task_data = _get_selected_meeting_task_data(spec)
	if bool(spec.get("needs_task", false)) and task_data == null:
		if _meeting_schedule_detail_label != null:
			_meeting_schedule_detail_label.text = "此類型需要先建立模板資料，或（通告）先接取進行中的案件。"
		return false

	if bool(spec.get("whole_week", false)):
		return ScheduleManager.set_next_week_schedule(_selected_schedule_artist_id, 0, schedule_type, task_data)

	return ScheduleManager.set_next_week_schedule(
		_selected_schedule_artist_id,
		_selected_meeting_day_index,
		schedule_type,
		task_data
	)

func _get_selected_meeting_task_data(spec: Dictionary) -> Variant:
	if not bool(spec.get("needs_task", false)):
		return null
	if _meeting_task_option == null or _meeting_task_option.item_count == 0:
		return null
	var selected_index: int = _meeting_task_option.get_selected()
	if selected_index < 0:
		return null
	return _meeting_task_option.get_item_metadata(selected_index)

func _get_meeting_schedule_type_spec(schedule_type: int) -> Dictionary:
	for spec in MEETING_SCHEDULE_TYPE_SPECS:
		if int(spec.get("type", -1)) == schedule_type:
			return spec
	return {"type": schedule_type, "label": "行程", "needs_task": false}

func _get_meeting_schedule_apply_target_text(schedule_type: int) -> String:
	var spec: Dictionary = _get_meeting_schedule_type_spec(schedule_type)
	if bool(spec.get("whole_week", false)):
		return "下週整週%s" % spec.get("label", "行程")
	return "%s · %s 的 %s" % [
		_get_meeting_character_display_name(_selected_schedule_artist_id),
		TimeManager.DAY_NAMES[_selected_meeting_day_index],
		spec.get("label", "行程"),
	]

func _refresh_meeting_schedule_detail_label() -> void:
	if _meeting_schedule_detail_label == null:
		return

	var spec: Dictionary = _get_meeting_schedule_type_spec(_pending_meeting_schedule_type)
	var task_data = _get_selected_meeting_task_data(spec)
	match str(spec.get("task_kind", "")):
		"course":
			_meeting_schedule_detail_label.text = CourseManager.build_course_detail_text(task_data, _selected_schedule_artist_id)
		"gig":
			_meeting_schedule_detail_label.text = GigManager.build_gig_detail_text(task_data, _selected_schedule_artist_id)
		"vacation_domestic", "vacation_overseas":
			_meeting_schedule_detail_label.text = VacationManager.build_vacation_detail_text(task_data)
		"job":
			if task_data is JobInstance:
				_meeting_schedule_detail_label.text = "【%s】有效拍摄 %d/%d" % [
					task_data.base_job.job_name,
					task_data.qualified_shoot_days,
					task_data.base_job.get_required_shoot_days(),
				]
			else:
				_meeting_schedule_detail_label.text = "請選擇進行中的通告。"
		_:
			match int(spec.get("type", ScheduleManager.ScheduleType.ROUTINE_EMPTY)):
				ScheduleManager.ScheduleType.ROUTINE_REST:
					_meeting_schedule_detail_label.text = "休息日：降低疲勞與壓力，略微提升滿意度。"
				ScheduleManager.ScheduleType.ROUTINE_CREATION:
					_meeting_schedule_detail_label.text = "創作日：小幅提升才華，壓力略升。"
				ScheduleManager.ScheduleType.ROUTINE_EMPTY:
					_meeting_schedule_detail_label.text = "空白日：不安排特定活動。"
				_:
					_meeting_schedule_detail_label.text = ScheduleManager.get_schedule_type_name(
						int(spec.get("type", ScheduleManager.ScheduleType.ROUTINE_EMPTY))
					)

func _get_schedule_type_name(schedule_type: int) -> String:
	return ScheduleManager.get_schedule_type_name(schedule_type)

func _get_primary_signed_artist_id() -> String:
	var signed_ids: Array = ArtistManager.get_signed_ids()
	if signed_ids.is_empty():
		return ""
	return str(signed_ids[0])

func _get_meeting_character_display_name(character_id: String) -> String:
	return CharacterDatabase.get_display_name(character_id)

func _get_character_avatar_texture(character_id: String) -> Texture2D:
	return CharacterDatabase.get_avatar(character_id)

func _get_character_portrait_texture(character_id: String) -> Texture2D:
	return CharacterDatabase.get_portrait(character_id)

func _make_character_portrait_rect(character_id: String, portrait_size: Vector2) -> TextureRect:
	return GameUiTheme.make_portrait_rect(
		_get_character_avatar_texture(character_id),
		portrait_size,
		_get_meeting_character_display_name(character_id)
	)

func _make_artist_resource_portrait_rect(resource: ArtistResource, portrait_size: Vector2) -> TextureRect:
	var texture: Texture2D = resource.avatar
	if texture == null:
		texture = resource.portrait
	if texture == null and resource.artist_id.strip_edges() != "":
		texture = CharacterDatabase.get_avatar(resource.artist_id)
	return GameUiTheme.make_portrait_rect(texture, portrait_size, resource.artist_name)

func _build_schedule_artist_header(artist_id: String, include_copy_button: bool = false) -> VBoxContainer:
	var artist_id_text: String = str(artist_id)
	var artist_header := VBoxContainer.new()
	artist_header.custom_minimum_size = Vector2(84, 0)
	artist_header.add_theme_constant_override("separation", 2)
	artist_header.alignment = BoxContainer.ALIGNMENT_CENTER
	artist_header.add_child(_make_character_portrait_rect(artist_id_text, PORTRAIT_SCHEDULE))

	var name_label := _style_hint_label(Label.new())
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text = _get_meeting_character_display_name(artist_id_text)
	artist_header.add_child(name_label)

	if include_copy_button:
		var copy_button := _compact_button(Button.new(), 84.0, UI_BTN_HEIGHT_SM)
		copy_button.text = "同上週"
		_style_button(copy_button, COLOR_BTN_NAV, UI_FONT_HINT)
		copy_button.pressed.connect(_on_meeting_copy_last_week_pressed.bind(artist_id_text))
		artist_header.add_child(copy_button)

	return artist_header

func _is_meeting_artist(character_id: String) -> bool:
	return CharacterDatabase.is_agency_artist(character_id) and ArtistManager.is_signed(character_id)

func _get_meeting_week_token() -> String:
	var snapshot: Dictionary = TimeManager.get_date_snapshot()
	return "%d_%d_%d" % [snapshot["year"], snapshot["month"], snapshot["week"]]

func _get_meeting_action_event_id(action_prefix: String, character_id: String) -> String:
	return "%s_%s_%s" % [action_prefix, character_id, _get_meeting_week_token()]

func _is_meeting_action_done(action_prefix: String, character_id: String) -> bool:
	return InteractionManager.has_executed(_get_meeting_action_event_id(action_prefix, character_id))

func _on_meeting_chat_pressed() -> void:
	var character_id: String = _selected_meeting_character_id
	if _is_meeting_action_done("meeting_chat", character_id):
		_add_message("[會議] 本週已與 %s 聊過。" % _get_meeting_character_display_name(character_id))
		return
	_execute_interaction_event(_make_meeting_chat_event(character_id), "會議")

func _on_meeting_gift_pressed() -> void:
	var character_id: String = _selected_meeting_character_id
	if not _is_meeting_artist(character_id):
		_add_message("[會議] 物品欄贈禮僅限已簽約藝人。")
		return
	if not ArtistManager.is_signed(character_id):
		_add_message("[會議] %s 不在旗下，無法贈禮。" % _get_meeting_character_display_name(character_id))
		return
	if _meeting_gift_picker_dialog == null:
		_add_message("[會議] 送禮介面尚未初始化。")
		return
	_meeting_gift_picker_dialog.open_for_artist(character_id)

func _execute_meeting_inventory_gift(artist_id: String, item_id: String) -> void:
	var result: Dictionary = ItemManager.try_gift_to_artist(item_id, artist_id)
	if not result.get("success", false):
		_add_message("[會議/送禮] 失敗：%s" % str(result.get("reason", "未知原因")))
		return

	var item_name: String = str(result.get("item_name", item_id))
	var display_name: String = _get_meeting_character_display_name(artist_id)
	_add_message("[會議/送禮] 已將「%s」贈送給 %s。" % [item_name, display_name])

	var category: int = int(result.get("category", -1))
	if category == ItemResource.ItemCategory.ATTRIBUTE:
		var applied_lines: PackedStringArray = _format_attribute_gift_applied_lines(
			result.get("applied_changes", {})
		)
		for line in applied_lines:
			_add_message("・%s" % line)
		_add_message("・%s 收下了禮物，看起來很開心。" % display_name)
		_emit_meeting_inventory_gift_news(artist_id, item_name)
	elif category == ItemResource.ItemCategory.STORY:
		var event_id: String = str(result.get("gift_story_event_id", "")).strip_edges()
		if event_id != "":
			_add_message("・劇情事件待觸發：%s" % event_id)
		else:
			_add_message("・%s 收下了這份劇情禮物。" % display_name)

	_refresh_status()
	_refresh_interaction_status()
	_refresh_meeting_detail()

func _format_attribute_gift_applied_lines(applied: Variant) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	if applied is not Dictionary:
		return lines

	var display_map: Dictionary = {
		"add_fatigue": "疲勞",
		"add_stress": "壓力",
		"add_satisfaction": "滿意度",
		"add_affection": "好感",
		"empathy": "同理",
		"timbre": "音色",
		"improvisation": "即興",
		"acting": "演技",
		"singing": "歌藝",
		"eloquence": "口才",
		"dynamism": "動感",
		"talent": "才華",
		"stamina": "體能",
		"deportment": "儀態",
		"fashion": "時尚",
		"confidence": "自信",
		"rebelliousness": "叛逆",
		"humor": "喜感",
		"affinity": "親和",
		"fame": "名氣",
		"popularity": "人氣",
		"exposure": "曝光",
		"morality": "道德",
	}
	for stat_name in applied:
		var change: Variant = applied[stat_name]
		if change is not Dictionary:
			continue
		var applied_delta: int = int(change.get("applied", 0))
		if applied_delta == 0:
			continue
		var label: String = str(display_map.get(str(stat_name), stat_name))
		lines.append("%s %+d" % [label, applied_delta])
	return lines

func _emit_meeting_inventory_gift_news(artist_id: String, item_name: String) -> void:
	_ensure_character_registered(artist_id)
	var event := InteractionEventResource.new()
	event.event_id = "meeting_inv_gift_news_%s_%s_%s" % [
		artist_id,
		item_name,
		_get_meeting_week_token(),
	]
	event.event_title = "週日會議送禮"
	event.interaction_type = InteractionEventResource.InteractionType.GIFT
	event.character_id = artist_id
	event.result_text = "%s 收下了 %s。" % [
		_get_meeting_character_display_name(artist_id),
		item_name,
	]
	event.generate_news = true
	event.news_title = "製作人週末慰勞藝人"
	event.news_body = "%s 在週日會議後向 %s 送上 %s。" % [
		ProtagonistManager.get_full_name(),
		_get_meeting_character_display_name(artist_id),
		item_name,
	]
	event.news_media_type = NewsManager.MediaType.TEXT_MEDIA
	event.news_category = NewsManager.NewsCategory.COMPANY
	event.news_importance = NewsManager.Importance.LOW
	InteractionManager.execute_event(event)

func _on_test_seed_inventory_items() -> void:
	var seeded: PackedStringArray = PackedStringArray()
	for item_id in ["attr_item_perfume_01", "attr_item_energy_drink_01", "story_item_old_letter_01"]:
		var count: int = InventoryManager.add_item(item_id, 1)
		if count > 0:
			seeded.append("%s×%d" % [item_id, count])
	if seeded.is_empty():
		_add_message("[測試] 補充道具失敗。")
		return
	_add_message("[測試] 已補充物品欄：%s" % "、".join(seeded))
	_refresh_meeting_detail()
	_refresh_interaction_status()

func _on_meeting_renew_pressed() -> void:
	var character_id: String = _selected_meeting_character_id
	if not _is_meeting_artist(character_id):
		_add_message("[會議] 秘書不需要續約。")
		return
	if _is_meeting_action_done("meeting_renew", character_id):
		_add_message("[會議] 本週已與 %s 完成續約。" % _get_meeting_character_display_name(character_id))
		return
	var display_name: String = _get_meeting_character_display_name(character_id)
	_confirm_meeting_action(
		"確認續約",
		"與 %s 確認本週合作延續？\n續約可提升公司聲望與口碑。" % display_name,
		func() -> void:
			_execute_interaction_event(_make_meeting_renew_event(character_id), "會議")
	)

func _on_meeting_terminate_pressed() -> void:
	var character_id: String = _selected_meeting_character_id
	if not _is_meeting_artist(character_id):
		_add_message("[會議] 秘書無法解約。")
		return
	if not ArtistManager.is_signed(character_id):
		_add_message("[會議] %s 不在旗下，無法解約。" % _get_meeting_character_display_name(character_id))
		return
	var display_name: String = _get_meeting_character_display_name(character_id)
	_confirm_meeting_action(
		"確認解約",
		"確定與 %s 解約？\n解約將降低公司口碑，並解除旗下與行程綁定。" % display_name,
		func() -> void:
			_execute_meeting_terminate(character_id)
	)

func _execute_meeting_terminate(character_id: String) -> void:
	var display_name: String = _get_meeting_character_display_name(character_id)
	if not ArtistManager.terminate_contract(character_id):
		_add_message("[會議] 解約失敗。")
		return

	var standing: Dictionary = CompanyStandingResolver.apply_meeting_terminate(display_name)
	_append_standing_message(standing)
	NewsManager.add_news(
		"與 %s 解約" % display_name,
		"%s 已與旗下藝人 %s 終止合約，業界輿論反應兩極。"
		% [PlayerManager.get_company_name(), display_name],
		NewsManager.MediaType.TEXT_MEDIA,
		NewsManager.NewsCategory.COMPANY,
		NewsManager.Importance.HIGH,
		character_id
	)
	_add_message("[會議] 已與 %s 解約。" % display_name)
	_selected_meeting_character_id = SecretaryManager.SECRETARY_ID
	_refresh_meeting_panel()
	_refresh_status()
	_refresh_interaction_status()

func _confirm_meeting_action(title: String, message: String, on_confirm: Callable) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	dialog.ok_button_text = "確認"
	dialog.cancel_button_text = "取消"
	dialog.confirmed.connect(
		func() -> void:
			on_confirm.call()
			dialog.queue_free(),
		CONNECT_ONE_SHOT
	)
	dialog.canceled.connect(dialog.queue_free, CONNECT_ONE_SHOT)
	dialog.close_requested.connect(dialog.queue_free, CONNECT_ONE_SHOT)
	add_child(dialog)
	dialog.popup_centered()

func _make_meeting_chat_event(character_id: String) -> InteractionEventResource:
	_ensure_character_registered(character_id)
	var event := InteractionEventResource.new()
	event.event_id = _get_meeting_action_event_id("meeting_chat", character_id)
	event.event_title = "週日會議聊天"
	event.interaction_type = InteractionEventResource.InteractionType.MEETING
	event.character_id = character_id
	event.execute_once = true
	var affection: int = RelationshipManager.get_affection(character_id)
	var address: String = ProtagonistManager.get_preferred_address(affection)
	var display_name: String = _get_meeting_character_display_name(character_id)
	if character_id == SecretaryManager.SECRETARY_ID:
		event.affection_delta = 3
		event.public_opinion_delta = 1
		event.result_text = "%s：%s，本週行程我會盯緊。有異常我會第一時間跟你說。" % [display_name, address]
	elif affection >= RelationshipManager.LEVEL_FLOOR[RelationshipManager.RelationshipLevel.CLOSE]:
		event.affection_delta = 6
		event.result_text = "%s：%s，這週辛苦了。下週如果有想調整的節奏，週會上跟我說。" % [display_name, address]
	else:
		event.affection_delta = 4
		event.result_text = "%s：%s，這週行程已確認。我會按計畫執行。" % [display_name, address]
	return event

func _make_meeting_renew_event(character_id: String) -> InteractionEventResource:
	_ensure_character_registered(character_id)
	var display_name: String = _get_meeting_character_display_name(character_id)
	var event := InteractionEventResource.new()
	event.event_id = _get_meeting_action_event_id("meeting_renew", character_id)
	event.event_title = "週日會議續約"
	event.interaction_type = InteractionEventResource.InteractionType.MEETING
	event.character_id = character_id
	event.affection_delta = 5
	event.reputation_delta = 2
	event.public_opinion_delta = 3
	event.execute_once = true
	event.generate_news = true
	event.news_title = "%s 完成續約" % display_name
	event.news_body = "%s 與旗下藝人 %s 完成本週續約，合作關係延續。" % [
		PlayerManager.get_company_name(),
		display_name,
	]
	event.news_media_type = NewsManager.MediaType.TEXT_MEDIA
	event.news_category = NewsManager.NewsCategory.COMPANY
	event.news_importance = NewsManager.Importance.NORMAL
	event.flag_changes = {"contract_renewed_%s" % character_id: true}
	event.result_text = "你與 %s 完成本週續約，合作關係延續。" % display_name
	return event

# ==========================================
# 互動事件（測試 + 會議共用）
# ==========================================
func _ensure_character_registered(character_id: String) -> void:
	if not RelationshipManager.has_character(character_id):
		RelationshipManager.register_character(character_id, 0)

func _ensure_test_character_registered(character_id: String) -> void:
	_ensure_character_registered(character_id)

func _make_test_event_chat_secretary() -> InteractionEventResource:
	var event := InteractionEventResource.new()
	event.event_id = "test_chat_secretary"
	event.event_title = "和秘書聊天"
	event.interaction_type = InteractionEventResource.InteractionType.CHAT
	event.character_id = SecretaryManager.SECRETARY_ID
	event.affection_delta = 5
	event.result_text = "秘書：%s，今天公司這邊我會幫你盯著。" % ProtagonistManager.get_preferred_address(
		RelationshipManager.get_affection(SecretaryManager.SECRETARY_ID)
	)
	return event

func _make_test_event_chat_artist() -> InteractionEventResource:
	_ensure_test_character_registered("artist_001")
	var event := InteractionEventResource.new()
	event.event_id = "test_chat_artist_001"
	event.event_title = "和藝人001聊天"
	event.interaction_type = InteractionEventResource.InteractionType.CHAT
	event.character_id = "artist_001"
	event.affection_delta = 3
	event.result_text = "藝人接受了你的關心，氣氛不錯。"
	return event

func _make_test_event_story_once() -> InteractionEventResource:
	_ensure_test_character_registered("artist_001")
	var event := InteractionEventResource.new()
	event.event_id = "test_story_once_artist_001"
	event.event_title = "藝人001一次性劇情"
	event.interaction_type = InteractionEventResource.InteractionType.STORY_CHOICE
	event.character_id = "artist_001"
	event.affection_delta = 8
	event.execute_once = true
	event.flag_changes = {"met_artist_001_story": true}
	event.result_text = "你聽到了藝人001的一段往事，關係更近了一步。"
	return event

func _make_test_event_expensive_gift() -> InteractionEventResource:
	var event := InteractionEventResource.new()
	event.event_id = "test_expensive_gift_secretary"
	event.event_title = "貴重禮物"
	event.interaction_type = InteractionEventResource.InteractionType.GIFT
	event.character_id = SecretaryManager.SECRETARY_ID
	event.affection_delta = 30
	event.money_delta = -99999999
	event.result_text = "這份禮物太貴了，目前資金不夠。"
	return event

func _run_interaction_test(event: InteractionEventResource) -> void:
	_execute_interaction_event(event, "互動測試")

func _execute_interaction_event(event: InteractionEventResource, log_prefix: String) -> void:
	if event == null:
		_add_message("[%s] 事件建立失敗。" % log_prefix)
		return

	var block_reason: String = InteractionManager.get_execution_block_reason(event)
	if block_reason != "":
		_add_message("[%s/%s] 無法執行：%s" % [log_prefix, event.event_title, block_reason])
		return

	var result: Dictionary = InteractionManager.execute_event(event)
	if not result.get("success", false):
		_add_message("[%s/%s] 失敗：%s" % [log_prefix, event.event_title, result.get("reason", "未知原因")])
		return

	_add_message("[%s/%s] 成功" % [log_prefix, event.event_title])
	if str(result.get("result_text", "")).strip_edges() != "":
		_add_message("・%s" % result["result_text"])
	if result.get("relationship_changed", false):
		_add_message("・好感 %d → %d（%s）" % [
			result.get("old_affection", 0),
			result.get("new_affection", 0),
			result.get("relationship_level", "")
		])
	if result.get("money_changed", false):
		_add_message("・資金變化：%+d，目前 $%d" % [result.get("money_delta_applied", 0), result.get("current_money", 0)])
	if result.get("reputation_changed", false):
		_add_message("・聲望變化：%+d，目前 %d" % [
			result.get("reputation_delta_applied", 0),
			result.get("current_reputation", 0)
		])
	if result.get("public_opinion_changed", false):
		_add_message("・口碑變化：%+d，目前 %d" % [
			result.get("public_opinion_delta_applied", 0),
			result.get("current_public_opinion", 0)
		])
	if result.get("flags_changed", false):
		_add_message("・flag 更新：%s" % str(result.get("applied_flags", {})))
	if result.get("news_generated", false):
		var news_item: Dictionary = result.get("news_item", {})
		if not news_item.is_empty():
			_add_message("・已生成新聞：%s" % news_item.get("title", ""))

	_refresh_status()
	_refresh_interaction_status()
	_refresh_meeting_detail()

func _append_standing_message(standing: Variant) -> void:
	if standing is not Dictionary or standing.is_empty():
		return
	var rep_delta: int = int(standing.get("reputation_delta", 0))
	var opinion_delta: int = int(standing.get("public_opinion_delta", 0))
	if rep_delta == 0 and opinion_delta == 0:
		return
	_add_message(
		"・聲望 %+d（目前 %d）| 口碑 %+d（目前 %d）"
		% [
			rep_delta,
			int(standing.get("current_reputation", PlayerManager.company_reputation)),
			opinion_delta,
			int(standing.get("current_public_opinion", PlayerManager.company_public_opinion)),
		]
	)

func _refresh_interaction_status() -> void:
	if _interaction_status_label == null:
		return
	_ensure_test_character_registered("artist_001")
	_interaction_status_label.text = "秘書好感：%d（%s）| 藝人001好感：%d（%s）| 資金：$%d" % [
		RelationshipManager.get_affection(SecretaryManager.SECRETARY_ID),
		RelationshipManager.get_relationship_level_name(SecretaryManager.SECRETARY_ID),
		RelationshipManager.get_affection("artist_001"),
		RelationshipManager.get_relationship_level_name("artist_001"),
		PlayerManager.money,
	]

func _refresh_job_center() -> void:
	if _job_summary_label == null:
		return

	_job_summary_label.text = "可接通告：%d 則 | 進行中：%d 則 | 公司資金：$%d" % [
		JobManager.get_available_job_count(),
		JobManager.get_active_job_count(),
		PlayerManager.money,
	]

	_refresh_job_center_list()
	_refresh_job_center_sign_panel()
	_refresh_job_center_artist_options()
	_refresh_job_center_detail()
	_refresh_job_center_active_jobs()

func _refresh_job_center_sign_panel() -> void:
	if _job_sign_box == null:
		return

	for child in _job_sign_box.get_children():
		child.queue_free()

	if ArtistManager.is_roster_full():
		_job_sign_box.visible = false
		return

	_job_sign_box.visible = true
	_job_sign_box.add_child(_make_section_title("簽約藝人"))

	var hint := Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if GameFlowManager.needs_initial_sign():
		hint.text = "開局首位藝人須在「3 選 1」流程中簽約，完成後方可進入首次會議。"
	elif ArtistManager.get_signed_count() == 0:
		hint.text = "目前旗下尚無藝人。後續藝人將隨劇情解鎖，在週日會議等流程中簽約。"
	else:
		var remaining_slots: int = ArtistManager.get_roster_limit() - ArtistManager.get_signed_count()
		hint.text = "還可簽約 %d 人（目前 %d / %d）。新藝人將隨劇情解鎖後簽約。" % [
			remaining_slots,
			ArtistManager.get_signed_count(),
			ArtistManager.get_roster_limit(),
		]
	_job_sign_box.add_child(hint)

	var limit_text := Label.new()
	limit_text.text = "簽約上限：%d / %d（依公司規模，與升級無關時小型仍為 2 人）" % [
		ArtistManager.get_signed_count(),
		ArtistManager.get_roster_limit(),
	]
	_job_sign_box.add_child(limit_text)

func _refresh_job_center_list() -> void:
	if _job_list == null:
		return

	_job_list.clear()
	_job_list_instance_ids.clear()

	var summaries: Array[Dictionary] = JobManager.get_available_job_summaries()
	for summary in summaries:
		var instance_id: String = str(summary.get("instance_id", ""))
		var item_text: String = "[%s] %s%s / %s / $%d / %s天" % [
			summary.get("company_name", "未知公司"),
			"【邀請】" if summary.get("invite_only", false) else "",
			summary.get("job_name", ""),
			summary.get("shoot_cycle_name", ""),
			summary.get("reward_money", 0),
			summary.get("total_days", 0),
		]
		_job_list.add_item(item_text)
		_job_list_instance_ids.append(instance_id)

	if _job_list_instance_ids.is_empty():
		_selected_job_instance_id = ""
		return

	if not _job_list_instance_ids.has(_selected_job_instance_id):
		_selected_job_instance_id = _job_list_instance_ids[0]

	var selected_index: int = _job_list_instance_ids.find(_selected_job_instance_id)
	if selected_index >= 0:
		_job_list.select(selected_index)

func _refresh_job_center_artist_options() -> void:
	if _job_artist_option == null:
		return

	var current_artist_id: String = _get_selected_job_artist_id()
	_job_artist_option.clear()

	var signed_ids: Array = ArtistManager.get_signed_ids()
	if signed_ids.is_empty():
		_job_artist_option.add_item("（請先在上方簽約）")
		_job_artist_option.set_item_metadata(0, "")
		_job_artist_option.select(0)
		_job_artist_option.disabled = true
		return

	_job_artist_option.disabled = false

	for artist_id in signed_ids:
		var artist_id_text: String = str(artist_id)
		var display_name: String = _get_meeting_character_display_name(artist_id_text)
		var item_index: int = _job_artist_option.item_count
		_job_artist_option.add_item("%s（%s）" % [display_name, artist_id_text])
		_job_artist_option.set_item_metadata(item_index, artist_id_text)

	if current_artist_id != "":
		for index in range(_job_artist_option.item_count):
			if str(_job_artist_option.get_item_metadata(index)) == current_artist_id:
				_job_artist_option.select(index)
				return
	_job_artist_option.select(0)

func _refresh_job_center_detail() -> void:
	if (
		_job_detail_label == null
		or _job_qualification_label == null
		or _job_accept_button == null
		or _job_invite_accept_button == null
		or _job_invite_detail_label == null
	):
		return

	if _selected_job_instance_id == "":
		_job_detail_label.text = "目前沒有可接通告。你可以按「刷新通告板」重新整理。"
		_job_qualification_label.text = ""
		_job_invite_detail_label.text = ""
		if _job_schedule_label != null:
			_job_schedule_label.text = ""
		_job_accept_button.disabled = true
		_job_invite_accept_button.disabled = true
		return

	var artist_id: String = _get_selected_job_artist_id()
	_job_detail_label.text = JobManager.build_job_detail_text(_selected_job_instance_id, artist_id)
	_job_invite_detail_label.text = JobManager.build_invite_detail_text(_selected_job_instance_id, artist_id)

	if _job_artist_profile_label != null:
		if artist_id == "":
			_job_artist_profile_label.text = ""
			_job_artist_profile_label.visible = false
		else:
			_job_artist_profile_label.text = ArtistProfileDisplay.build_detail_multiline_for_id(artist_id)
			_job_artist_profile_label.visible = true

	var block_reason: String = JobManager.get_accept_block_reason(_selected_job_instance_id, artist_id)
	var invite_block_reason: String = JobManager.get_invite_block_reason(_selected_job_instance_id, artist_id)
	var job_instance: JobInstance = JobManager.get_job_instance(_selected_job_instance_id)
	var invite_only: bool = false
	if job_instance != null and _job_schedule_label != null:
		_job_schedule_label.text = JobManager.build_schedule_rule_text(job_instance.base_job)
		invite_only = job_instance.base_job.invite_only

	_job_accept_button.visible = not invite_only

	if artist_id == "":
		_job_qualification_label.text = "簽約至少一位藝人後，即可選人並確認接案。"
		_job_accept_button.disabled = true
		_job_invite_accept_button.disabled = true
	elif invite_only:
		if invite_block_reason == "":
			var schedule_hint: String = "邀請接案後請在週日會議自行安排拍攝日。"
			if job_instance != null:
				var job: JobResource = job_instance.base_job
				schedule_hint = "邀請接案後請在週日會議自行安排 %d 個有效拍攝日（%d 週窗口內）。" % [
					job.get_required_shoot_days(),
					job.shoot_window_weeks,
				]
			_job_qualification_label.text = schedule_hint
			_job_invite_accept_button.disabled = false
		else:
			_job_qualification_label.text = invite_block_reason
			_job_invite_accept_button.disabled = true
	elif block_reason == "":
		var schedule_hint: String = "接案後請在週日會議自行安排拍攝日。"
		if job_instance != null:
			var job: JobResource = job_instance.base_job
			schedule_hint = "接案後請在週日會議自行安排 %d 個有效拍攝日（%d 週窗口內）。" % [
				job.get_required_shoot_days(),
				job.shoot_window_weeks,
			]
		_job_qualification_label.text = schedule_hint
		_job_accept_button.disabled = false
		_job_invite_accept_button.disabled = invite_block_reason != ""
	else:
		var hint_lines: PackedStringArray = PackedStringArray()
		hint_lines.append(block_reason)
		if invite_block_reason == "":
			hint_lines.append("普通資質不足，仍可嘗試製片人邀請接案。")
		else:
			hint_lines.append(invite_block_reason)
		_job_qualification_label.text = "\n".join(hint_lines)
		_job_accept_button.disabled = true
		_job_invite_accept_button.disabled = invite_block_reason != ""

func _refresh_job_center_active_jobs() -> void:
	if _job_active_label == null:
		return

	var summaries: Array[Dictionary] = JobManager.get_active_job_summaries()
	if summaries.is_empty():
		_job_active_label.text = "目前沒有進行中的通告。"
		return

	var lines: PackedStringArray = PackedStringArray()
	for summary in summaries:
		var artist_name: String = _get_meeting_character_display_name(str(summary.get("artist_id", "")))
		var agency_name: String = str(summary.get("agency_name", ""))
		if agency_name.strip_edges() != "":
			artist_name = "%s（%s）" % [artist_name, agency_name]
		lines.append(
			"・《%s》→ %s | 進度 %s | 酬劳 $%d" % [
				summary.get("job_name", ""),
				artist_name,
				summary.get("shoot_progress", ""),
				summary.get("reward_money", 0),
			]
		)
	_job_active_label.text = "\n".join(lines)

func _get_selected_job_artist_id() -> String:
	if _job_artist_option == null or _job_artist_option.item_count == 0:
		return ""
	var selected_index: int = _job_artist_option.get_selected()
	if selected_index < 0:
		return ""
	return str(_job_artist_option.get_item_metadata(selected_index))

func _show_job_center_view(show_center: bool) -> void:
	_showing_job_center = show_center
	if _daily_main_box != null and not GameFlowManager.is_meeting_phase:
		_daily_main_box.visible = not show_center
	if show_center:
		_refresh_job_center()
	_refresh_status()

func _on_open_job_center_pressed() -> void:
	_show_job_center_view(true)
	_add_message("[通告中心] 已開啟通告列表。")

func _on_close_job_center_pressed() -> void:
	_show_job_center_view(false)

func _on_job_list_item_selected(index: int) -> void:
	if index < 0 or index >= _job_list_instance_ids.size():
		return
	_selected_job_instance_id = _job_list_instance_ids[index]
	_refresh_job_center_detail()

func _on_job_artist_selected(_index: int) -> void:
	_refresh_job_center_detail()

func _on_job_center_sign_artist_pressed(artist_id: String) -> void:
	if ArtistManager.is_initial_signable_artist(artist_id):
		_add_message("[通告中心] 開局候選藝人須在「3 選 1」流程中簽約。")
		_try_open_initial_artist_pick()
		return
	if ArtistManager.is_signed(artist_id):
		_add_message("[通告中心] 該藝人已在旗下。")
		return
	if ArtistManager.is_roster_full():
		_add_message("[通告中心] 簽約失敗：已達公司規模上限。")
		return
	_prompt_artist_sign_profile(artist_id)

func _on_job_refresh_pressed() -> void:
	var count: int = JobManager.refresh_job_board()
	_add_message("[通告中心] 已刷新通告板，可接 %d 則。" % count)
	_refresh_job_center()

func _on_job_accept_pressed() -> void:
	if _selected_job_instance_id == "":
		_add_message("[通告中心] 請先選擇一則通告。")
		return

	var artist_id: String = _get_selected_job_artist_id()
	var block_reason: String = JobManager.get_accept_block_reason(_selected_job_instance_id, artist_id)
	if block_reason != "":
		_add_message("[通告中心] 無法接案：%s" % block_reason)
		return

	var result: Dictionary = JobManager.try_accept_job(_selected_job_instance_id, artist_id)
	if not result.get("success", false):
		_add_message("[通告中心] 接案失敗：%s" % result.get("reason", "未知原因"))
		return

	_add_message("[通告中心] %s 已接取《%s》，請在週日會議自行安排拍攝日（%d 週窗口內需 %d 個有效日）。" % [
		_get_meeting_character_display_name(artist_id),
		result.get("job_name", ""),
		result.get("shoot_window_weeks", 12),
		result.get("required_shoot_days", 0),
	])
	_add_message("[通告中心] 週日會議結束時提交下週行程，之後每日結算才會正式開拍。")
	_selected_job_instance_id = ""
	_refresh_job_center()
	_refresh_status()

func _on_job_invite_accept_pressed() -> void:
	if _selected_job_instance_id == "":
		_add_message("[通告中心] 請先選擇一則通告。")
		return

	var artist_id: String = _get_selected_job_artist_id()
	var invite_block_reason: String = JobManager.get_invite_block_reason(_selected_job_instance_id, artist_id)
	if invite_block_reason != "":
		_add_message("[通告中心] 無法邀請接案：%s" % invite_block_reason)
		return

	var job_instance: JobInstance = JobManager.get_job_instance(_selected_job_instance_id)
	if job_instance == null:
		_add_message("[通告中心] 找不到通告資料。")
		return

	var job: JobResource = job_instance.base_job
	var artist_name: String = _get_meeting_character_display_name(artist_id)
	var confirm_message: String = (
		"%s 將以製片人邀請管道接取《%s》。\n\n"
		+ JobManager.build_invite_detail_text(_selected_job_instance_id, artist_id)
		+ "\n\n拍攝日須維持各項門檻的 90%，確認接案？"
	) % [artist_name, job.job_name]
	_confirm_meeting_action(
		"製片人邀請接案",
		confirm_message,
		func() -> void:
			_execute_job_invite_accept(artist_id, job),
	)

func _execute_job_invite_accept(artist_id: String, job: JobResource) -> void:
	var threshold: int = JobManager.get_invite_threshold_for_job(job)
	var result: Dictionary = JobManager.try_accept_job_invite(
		_selected_job_instance_id,
		artist_id,
		threshold,
	)
	if not result.get("success", false):
		_add_message("[通告中心] 邀請接案失敗：%s" % result.get("reason", "未知原因"))
		return

	_add_message(
		"[通告中心] %s 已透過製片人邀請接取《%s》，拍攝日須維持門檻 90%%。請在週日會議安排 %d 個有效拍攝日（%d 週窗口內）。"
		% [
			_get_meeting_character_display_name(artist_id),
			result.get("job_name", ""),
			result.get("required_shoot_days", 0),
			result.get("shoot_window_weeks", 12),
		]
	)
	_add_message("[通告中心] 週日會議結束時提交下週行程，之後每日結算才會正式開拍。")
	_selected_job_instance_id = ""
	_refresh_job_center()
	_refresh_status()

func _on_job_completed(_instance_id: String, artist_id: String, completion_quality: int) -> void:
	_add_message("[通告中心] %s 完成通告（%s）。" % [
		_get_meeting_character_display_name(artist_id),
		JobManager.get_completion_quality_name(completion_quality),
	])
	_refresh_job_center()
	_refresh_status()
