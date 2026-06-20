class_name SchedulePickerDialog
extends CanvasLayer

signal confirmed(artist_id: String, day_index: int, option: Dictionary)
signal cancelled()

const COLOR_OVERLAY := Color(0.04, 0.05, 0.08, 0.72)
const COLOR_PANEL := Color(0.16, 0.15, 0.21, 1.0)
const COLOR_BLOCK := Color(0.22, 0.24, 0.32, 1.0)
const COLOR_BORDER := Color(0.38, 0.42, 0.52, 0.55)
const COLOR_TEXT := Color(0.92, 0.93, 0.96, 1.0)
const COLOR_MUTED := Color(0.62, 0.66, 0.74, 1.0)
const COLOR_GOLD := Color(0.96, 0.78, 0.36, 1.0)
const COLOR_PRIMARY := Color(0.32, 0.52, 0.82, 1.0)
const COLOR_SUCCESS := Color(0.28, 0.68, 0.46, 1.0)
const COLOR_DANGER := Color(0.72, 0.30, 0.36, 1.0)

var _artist_id: String = ""
var _day_index: int = 0
var _readonly: bool = false
var _current_tab: int = 0
var _tab_options: Array = [[], [], [], []]
var _selected_option: Dictionary = {}
var _tab_buttons: Array[Button] = []
var _option_list: ItemList
var _header_label: Label
var _current_label: Label
var _detail_label: Label
var _hint_label: Label
var _confirm_button: Button

func _ready() -> void:
	layer = 20
	_build_ui()
	hide()

func open_for_draft_slot(artist_id: String, day_index: int) -> void:
	_artist_id = artist_id
	_day_index = day_index
	_readonly = not SchedulePickerManager.can_edit_draft_slot(artist_id, day_index)
	_tab_options = SchedulePickerManager.build_all_tab_options(artist_id)

	var slot: Dictionary = ScheduleManager.get_draft_week(artist_id)[day_index]
	_current_tab = int(SchedulePickerManager.get_recommended_tab_for_slot(slot))
	_selected_option = {}

	_header_label.text = "安排行程 · %s" % SchedulePickerManager.build_picker_header_text(artist_id, day_index)
	_current_label.text = "目前：%s" % SchedulePickerManager.build_slot_preview_text(slot)
	_hint_label.text = (
		SchedulePickerManager.get_edit_block_reason(artist_id, day_index)
		if _readonly and _current_tab != SchedulePickerManager.Tab.VACATION
		else _build_tab_hint_text()
	)

	_select_tab(_current_tab)
	_preselect_option_from_slot(slot)
	_update_confirm_state()
	show()

func _build_ui() -> void:
	var overlay := ColorRect.new()
	overlay.color = COLOR_OVERLAY
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 390)
	_style_panel(panel, COLOR_PANEL)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	_header_label = _make_label("", COLOR_GOLD, 14)
	box.add_child(_header_label)

	_current_label = _make_label("", COLOR_MUTED, 11)
	_current_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_current_label)

	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 4)
	box.add_child(tab_row)

	for tab_index in range(SchedulePickerManager.get_tab_titles().size()):
		var tab_button := Button.new()
		tab_button.text = SchedulePickerManager.get_tab_titles()[tab_index]
		tab_button.custom_minimum_size = Vector2(0, 26)
		tab_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_button(tab_button, COLOR_BLOCK)
		tab_button.pressed.connect(_on_tab_pressed.bind(tab_index))
		tab_row.add_child(tab_button)
		_tab_buttons.append(tab_button)

	var list_panel := PanelContainer.new()
	list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_panel(list_panel, COLOR_BLOCK.darkened(0.04))
	box.add_child(list_panel)

	_option_list = ItemList.new()
	_option_list.custom_minimum_size = Vector2(0, 180)
	_option_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_option_list.item_selected.connect(_on_option_selected)
	list_panel.add_child(_option_list)

	_detail_label = _make_label("請選擇一項。", COLOR_TEXT, 11)
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_detail_label)

	_hint_label = _make_label("", COLOR_MUTED, 11)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_hint_label)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 6)
	box.add_child(action_row)

	var cancel_button := Button.new()
	cancel_button.text = "取消"
	cancel_button.custom_minimum_size = Vector2(72, 26)
	cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(cancel_button, COLOR_DANGER)
	cancel_button.pressed.connect(_on_cancel_pressed)
	action_row.add_child(cancel_button)

	_confirm_button = Button.new()
	_confirm_button.text = "確認"
	_confirm_button.custom_minimum_size = Vector2(72, 26)
	_confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(_confirm_button, COLOR_SUCCESS)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	action_row.add_child(_confirm_button)

func _select_tab(tab_index: int) -> void:
	_current_tab = clampi(tab_index, 0, _tab_buttons.size() - 1)
	for index in range(_tab_buttons.size()):
		_style_button(
			_tab_buttons[index],
			COLOR_PRIMARY if index == _current_tab else COLOR_BLOCK
		)
	_refresh_option_list()

func _refresh_option_list() -> void:
	_option_list.clear()
	var options: Array = _tab_options[_current_tab] if _current_tab < _tab_options.size() else []
	if options.is_empty():
		_option_list.add_item("（此分頁尚無可選項目）")
		_option_list.set_item_metadata(0, {})
		_option_list.set_item_disabled(0, true)
		_selected_option = {}
		_detail_label.text = "此分頁尚無可選項目。"
		return

	for index in range(options.size()):
		var option: Dictionary = options[index]
		var line: String = str(option.get("title", "項目"))
		var subtitle: String = str(option.get("subtitle", ""))
		if subtitle.strip_edges() != "":
			line += "  ·  %s" % subtitle
		_option_list.add_item(line)
		_option_list.set_item_metadata(index, option)
		if bool(option.get("disabled", false)):
			_option_list.set_item_disabled(index, true)

func _preselect_option_from_slot(slot: Dictionary) -> void:
	var options: Array = _tab_options[_current_tab] if _current_tab < _tab_options.size() else []
	var match_index: int = SchedulePickerManager.find_option_index_for_slot(options, slot)
	if match_index >= 0:
		_option_list.select(match_index)
		_on_option_selected(match_index)
	elif _option_list.item_count > 0 and not _option_list.is_item_disabled(0):
		_option_list.select(0)
		_on_option_selected(0)
	else:
		_on_option_selected(-1)

func _on_tab_pressed(tab_index: int) -> void:
	_select_tab(tab_index)
	_hint_label.text = _build_tab_hint_text()
	_preselect_option_from_slot(ScheduleManager.get_draft_week(_artist_id)[_day_index])
	_update_confirm_state()

func _build_tab_hint_text() -> String:
	if _current_tab == SchedulePickerManager.Tab.VACATION:
		return "度假：選中方案後立即覆蓋下週整週（無需確認）。"
	var slot: Dictionary = ScheduleManager.get_draft_week(_artist_id)[_day_index]
	if ScheduleManager.is_draft_slot_editable(_artist_id, _day_index) \
			and int(slot.get("lock_state", ScheduleManager.LockState.UNLOCKED)) == ScheduleManager.LockState.LOCKED_WEEK:
		return "此日可覆蓋整週度假/海外通告，其餘日期將清空為空白。"
	if _readonly:
		return SchedulePickerManager.get_edit_block_reason(_artist_id, _day_index)
	return "切換分頁後選擇項目，再按確認。"

func _on_option_selected(index: int) -> void:
	if index < 0:
		_selected_option = {}
		_detail_label.text = "請選擇一項。"
		_update_confirm_state()
		return

	_selected_option = _option_list.get_item_metadata(index)
	if typeof(_selected_option) != TYPE_DICTIONARY:
		_selected_option = {}

	var disabled_reason: String = str(_selected_option.get("disabled_reason", ""))
	if bool(_selected_option.get("disabled", false)) and disabled_reason != "":
		_detail_label.text = disabled_reason
	else:
		_detail_label.text = SchedulePickerManager.build_option_detail_text(_selected_option, _artist_id)

	if _current_tab == SchedulePickerManager.Tab.VACATION:
		_try_apply_vacation_selection()
		return
	_update_confirm_state()

func _try_apply_vacation_selection() -> void:
	if _selected_option.is_empty() or bool(_selected_option.get("disabled", false)):
		_update_confirm_state()
		return

	var kind: String = str(_selected_option.get("kind", ""))
	if kind not in [
		SchedulePickerManager.KIND_VACATION_DOMESTIC,
		SchedulePickerManager.KIND_VACATION_OVERSEAS,
	]:
		_update_confirm_state()
		return

	var result: Dictionary = SchedulePickerManager.apply_vacation_selection(
		_artist_id,
		_day_index,
		_selected_option
	)
	if not result.get("success", false):
		_hint_label.text = str(result.get("reason", "套用失敗。"))
		_update_confirm_state()
		return

	confirmed.emit(_artist_id, _day_index, _selected_option)
	hide()

func _update_confirm_state() -> void:
	var can_confirm: bool = (
		not _readonly
		and _current_tab != SchedulePickerManager.Tab.VACATION
		and not _selected_option.is_empty()
	)
	if can_confirm and bool(_selected_option.get("disabled", false)):
		can_confirm = false
	_confirm_button.disabled = not can_confirm

func _on_confirm_pressed() -> void:
	if _readonly or _selected_option.is_empty():
		return
	confirmed.emit(_artist_id, _day_index, _selected_option)
	hide()

func _on_cancel_pressed() -> void:
	cancelled.emit()
	hide()

func _make_label(text: String, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _make_stylebox(bg: Color, border: Color = COLOR_BORDER) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	return style

func _style_panel(panel: PanelContainer, bg: Color) -> void:
	panel.add_theme_stylebox_override("panel", _make_stylebox(bg))

func _style_button(button: Button, bg: Color) -> void:
	var hover := bg.lightened(0.10)
	button.add_theme_stylebox_override("normal", _make_stylebox(bg, bg.lightened(0.18)))
	button.add_theme_stylebox_override("hover", _make_stylebox(hover, hover.lightened(0.18)))
	button.add_theme_stylebox_override("pressed", _make_stylebox(bg.darkened(0.08), bg.lightened(0.12)))
	button.add_theme_stylebox_override("disabled", _make_stylebox(bg.darkened(0.22), bg.darkened(0.10)))
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_disabled_color", COLOR_MUTED)
	button.add_theme_font_size_override("font_size", GameUiTheme.FONT_HINT)
