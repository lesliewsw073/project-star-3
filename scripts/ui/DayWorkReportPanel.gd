class_name DayWorkReportPanel
extends CanvasLayer

signal dismissed

var _reports: Array = []
var _dismiss_pending: bool = false
var _date_label: Label
var _money_label: Label
var _task_grid: GridContainer
var _artist_row: HBoxContainer
var _click_layer: ColorRect

func _ready() -> void:
	layer = 45
	_build_shell()
	hide()

func show_report(reports: Array) -> void:
	_dismiss_pending = false
	_reports = DayWorkReportBuilder.pad_reports(reports)
	_rebuild_content()
	show()

func _build_shell() -> void:
	var overlay := ColorRect.new()
	overlay.name = "Overlay"
	overlay.color = Color(0.05, 0.06, 0.10, 0.92)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var root := MarginContainer.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_constant_override("margin_left", 24)
	root.add_theme_constant_override("margin_top", 16)
	root.add_theme_constant_override("margin_right", 24)
	root.add_theme_constant_override("margin_bottom", 16)
	add_child(root)

	var box := VBoxContainer.new()
	box.name = "MainBox"
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	root.add_child(box)

	var header := HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 12)
	box.add_child(header)

	_date_label = Label.new()
	_date_label.name = "DateLabel"
	GameUiTheme.style_label(_date_label, GameUiTheme.COLOR_GOLD, GameUiTheme.FONT_SECTION)
	header.add_child(_date_label)

	_money_label = Label.new()
	_money_label.name = "MoneyLabel"
	_money_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	GameUiTheme.style_label(_money_label, GameUiTheme.COLOR_GOLD, GameUiTheme.FONT_SECTION)
	header.add_child(_money_label)

	_task_grid = GridContainer.new()
	_task_grid.name = "TaskGrid"
	_task_grid.columns = 2
	_task_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_task_grid.add_theme_constant_override("h_separation", 10)
	_task_grid.add_theme_constant_override("v_separation", 10)
	box.add_child(_task_grid)

	_artist_row = HBoxContainer.new()
	_artist_row.name = "ArtistRow"
	_artist_row.add_theme_constant_override("separation", 8)
	_artist_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	box.add_child(_artist_row)

	var hint := Label.new()
	hint.text = "點擊空白處繼續"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUiTheme.style_label(hint, GameUiTheme.COLOR_MUTED, GameUiTheme.FONT_HINT)
	box.add_child(hint)

	_click_layer = ColorRect.new()
	_click_layer.name = "ClickLayer"
	_click_layer.color = Color(0, 0, 0, 0)
	_click_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_click_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_click_layer.gui_input.connect(_on_click_to_dismiss)
	add_child(_click_layer)

func _rebuild_content() -> void:
	if _date_label == null or _money_label == null or _task_grid == null or _artist_row == null:
		push_error("[DayWorkReportPanel] UI 節點尚未初始化。")
		return

	var snapshot: Dictionary = TimeManager.get_date_snapshot()
	_date_label.text = "%d / %d / %d  %s" % [
		snapshot.get("year", 0),
		snapshot.get("month", 0),
		snapshot.get("day_of_month", 0),
		snapshot.get("day_name", ""),
	]
	_money_label.text = "$ %d" % PlayerManager.money

	for child in _task_grid.get_children():
		child.queue_free()
	for child in _artist_row.get_children():
		child.queue_free()

	for report in _reports:
		_task_grid.add_child(_make_task_cell(report))
		_artist_row.add_child(_make_artist_cell(report))

func _make_task_cell(report: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = Vector2(280, 150)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var is_empty: bool = bool(report.get("empty", false))
	var bg := Color(0.18, 0.20, 0.28, 1.0) if not is_empty else Color(0.12, 0.13, 0.18, 1.0)
	GameUiTheme.style_panel(panel, bg)

	var stack := Control.new()
	stack.custom_minimum_size = panel.custom_minimum_size
	panel.add_child(stack)

	if not is_empty:
		var outcome := Label.new()
		outcome.text = str(report.get("outcome_label", "成功"))
		outcome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		outcome.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		outcome.set_anchors_preset(Control.PRESET_FULL_RECT)
		outcome.add_theme_font_size_override("font_size", 28)
		outcome.add_theme_color_override("font_color", Color(0.98, 0.86, 0.28, 1.0))
		stack.add_child(outcome)

		var preview := ColorRect.new()
		preview.color = Color(0.28, 0.34, 0.42, 0.55)
		preview.set_anchors_preset(Control.PRESET_FULL_RECT)
		preview.offset_left = 12.0
		preview.offset_top = 12.0
		preview.offset_right = -12.0
		preview.offset_bottom = -28.0
		stack.add_child(preview)

	var caption := Label.new()
	caption.text = str(report.get("task_type_label", ""))
	if str(report.get("task_title", "")) not in ["", "—"]:
		caption.text += " · %s" % str(report.get("task_title", ""))
	caption.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_left = 8.0
	caption.offset_bottom = -6.0
	GameUiTheme.style_label(caption, GameUiTheme.COLOR_TEXT, GameUiTheme.FONT_HINT)
	stack.add_child(caption)

	return panel

func _make_artist_cell(report: Dictionary) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.custom_minimum_size = Vector2(140, 0)
	column.add_theme_constant_override("separation", 4)
	column.alignment = BoxContainer.ALIGNMENT_CENTER

	var is_empty: bool = bool(report.get("empty", false))
	var artist_id: String = str(report.get("artist_id", ""))

	if is_empty or artist_id == "":
		var placeholder := PanelContainer.new()
		placeholder.custom_minimum_size = Vector2(72, 72)
		GameUiTheme.style_panel(placeholder, Color(0.14, 0.15, 0.20, 1.0))
		column.add_child(placeholder)
		var empty_label := Label.new()
		empty_label.text = "—"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		GameUiTheme.style_label(empty_label, GameUiTheme.COLOR_MUTED, GameUiTheme.FONT_HINT)
		column.add_child(empty_label)
		return column

	var portrait := GameUiTheme.make_portrait_rect(
		ArtistManager.get_artist_avatar(artist_id),
		Vector2(72, 72),
		str(report.get("artist_name", artist_id))
	)
	column.add_child(portrait)

	var name_label := Label.new()
	name_label.text = str(report.get("artist_name", artist_id))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUiTheme.style_label(name_label, GameUiTheme.COLOR_GOLD, GameUiTheme.FONT_HINT)
	column.add_child(name_label)

	for line in report.get("stat_lines", PackedStringArray()):
		var stat_label := Label.new()
		stat_label.text = str(line)
		stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stat_label.add_theme_font_size_override("font_size", GameUiTheme.FONT_BODY)
		stat_label.add_theme_color_override("font_color", Color(0.48, 0.82, 0.94, 1.0))
		column.add_child(stat_label)

	return column

func _on_click_to_dismiss(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_request_dismiss()

func _request_dismiss() -> void:
	if _dismiss_pending:
		return
	_dismiss_pending = true
	hide()
	dismissed.emit()
