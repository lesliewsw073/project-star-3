class_name SaveSlotPickerDialog
extends CanvasLayer

signal load_succeeded(kind: int, slot_index: int, result: Dictionary)
signal save_succeeded(kind: int, slot_index: int, result: Dictionary)
signal closed()

const PORTRAIT_SIZE := Vector2(44, 44)

var _scroll: ScrollContainer
var _rows_host: VBoxContainer
var _status_label: Label
var _row_hosts: Dictionary = {}

func _ready() -> void:
	layer = 23
	_build_ui()
	hide()

func open_dialog() -> void:
	_ensure_ui_ready()
	_status_label.text = ""
	_refresh_rows()
	show()

func _ensure_ui_ready() -> void:
	if _rows_host == null:
		_build_ui()

func _build_ui() -> void:
	var overlay := ColorRect.new()
	overlay.color = GameUiTheme.COLOR_OVERLAY
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(_on_overlay_gui_input)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 560)
	GameUiTheme.style_panel(panel, GameUiTheme.COLOR_PANEL)
	center.add_child(panel)

	var outer := MarginContainer.new()
	outer.add_theme_constant_override("margin_left", GameUiTheme.PAD)
	outer.add_theme_constant_override("margin_top", GameUiTheme.PAD)
	outer.add_theme_constant_override("margin_right", GameUiTheme.PAD)
	outer.add_theme_constant_override("margin_bottom", GameUiTheme.PAD)
	panel.add_child(outer)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", GameUiTheme.SEP)
	outer.add_child(box)

	var title := Label.new()
	title.text = "存檔／讀檔"
	GameUiTheme.style_label(title, GameUiTheme.COLOR_GOLD, GameUiTheme.FONT_TITLE)
	box.add_child(title)

	var hint := Label.new()
	hint.text = "自動存檔僅於每週週日會議由系統輪流覆寫 A→B，玩家不可手動寫入；手動槽僅週日會議可存。讀檔無需確認。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GameUiTheme.style_label(hint, GameUiTheme.COLOR_MUTED, GameUiTheme.FONT_HINT)
	box.add_child(hint)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.custom_minimum_size = Vector2(0, 420)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(_scroll)

	_rows_host = VBoxContainer.new()
	_rows_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_host.add_theme_constant_override("separation", GameUiTheme.SEP)
	_scroll.add_child(_rows_host)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GameUiTheme.style_label(_status_label, GameUiTheme.COLOR_SUCCESS, GameUiTheme.FONT_HINT)
	box.add_child(_status_label)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(footer)

	var close_button := Button.new()
	close_button.text = "關閉"
	close_button.custom_minimum_size = Vector2(96, GameUiTheme.BTN_HEIGHT_SM)
	GameUiTheme.style_button(close_button, GameUiTheme.COLOR_MUTED.darkened(0.35), GameUiTheme.FONT_HINT)
	close_button.pressed.connect(_on_close_pressed)
	footer.add_child(close_button)

func _refresh_rows() -> void:
	for child in _rows_host.get_children():
		child.queue_free()
	_row_hosts.clear()

	_rows_host.add_child(GameUiTheme.make_section_label("自動存檔（週末輪替）", GameUiTheme.COLOR_NAV))
	for index in range(SaveManager.AUTO_SLOT_COUNT):
		var summary: Dictionary = SaveManager.peek_slot_summary(SaveManager.SlotKind.AUTO, index)
		_rows_host.add_child(_build_slot_row(SaveManager.SlotKind.AUTO, index, summary))

	_rows_host.add_child(GameUiTheme.make_section_label("手動存檔", GameUiTheme.COLOR_GOLD))
	for slot in range(1, SaveManager.MANUAL_SLOT_COUNT + 1):
		var summary: Dictionary = SaveManager.peek_slot_summary(SaveManager.SlotKind.MANUAL, slot)
		_rows_host.add_child(_build_slot_row(SaveManager.SlotKind.MANUAL, slot, summary))

func _build_slot_row(kind: int, slot_index: int, summary: Dictionary) -> PanelContainer:
	var row_key: String = "%d:%d" % [kind, slot_index]
	var panel := PanelContainer.new()
	GameUiTheme.style_panel(panel, GameUiTheme.COLOR_BLOCK, GameUiTheme.COLOR_BORDER.darkened(0.2))
	_row_hosts[row_key] = panel

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)

	var title := Label.new()
	title.text = _slot_title(kind, slot_index, bool(summary.get("empty", true)))
	GameUiTheme.style_label(title, GameUiTheme.COLOR_GOLD, GameUiTheme.FONT_SECTION)
	info.add_child(title)

	info.add_child(_make_meta_line("存檔時間", str(summary.get("saved_at_text", "—"))))
	info.add_child(_make_meta_line("遊戲日期", str(summary.get("game_date_text", "—"))))
	info.add_child(_make_meta_line("公司名稱", str(summary.get("company_name", "—"))))

	var avatar_row := HBoxContainer.new()
	avatar_row.add_theme_constant_override("separation", 6)
	info.add_child(avatar_row)
	_populate_avatar_row(avatar_row, summary)

	var action_col := VBoxContainer.new()
	action_col.add_theme_constant_override("separation", 6)
	row.add_child(action_col)

	var is_auto: bool = kind == SaveManager.SlotKind.AUTO
	if not is_auto:
		var save_button := Button.new()
		save_button.text = "存檔"
		save_button.custom_minimum_size = Vector2(88, GameUiTheme.BTN_HEIGHT_SM)
		GameUiTheme.style_button(save_button, GameUiTheme.COLOR_NAV, GameUiTheme.FONT_HINT)
		save_button.disabled = not SaveManager.can_save()
		save_button.pressed.connect(func() -> void: _on_save_pressed(kind, slot_index))
		action_col.add_child(save_button)
	else:
		var auto_hint := Label.new()
		auto_hint.text = "僅系統週末自動寫入"
		auto_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		auto_hint.custom_minimum_size = Vector2(96, 0)
		GameUiTheme.style_label(auto_hint, GameUiTheme.COLOR_MUTED, GameUiTheme.FONT_HINT)
		action_col.add_child(auto_hint)

	var load_button := Button.new()
	load_button.text = "讀檔"
	load_button.custom_minimum_size = Vector2(88, GameUiTheme.BTN_HEIGHT_SM)
	GameUiTheme.style_button(load_button, GameUiTheme.COLOR_WARM, GameUiTheme.FONT_HINT)
	load_button.pressed.connect(func() -> void: _on_load_pressed(kind, slot_index))
	action_col.add_child(load_button)

	var is_empty: bool = bool(summary.get("empty", true))
	load_button.disabled = is_empty

	return panel

func _make_meta_line(caption: String, value: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var cap := Label.new()
	cap.text = "%s：" % caption
	cap.custom_minimum_size.x = 88
	GameUiTheme.style_label(cap, GameUiTheme.COLOR_MUTED, GameUiTheme.FONT_HINT)
	row.add_child(cap)
	var val := Label.new()
	val.text = value
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GameUiTheme.style_label(val, GameUiTheme.COLOR_TEXT, GameUiTheme.FONT_BODY)
	row.add_child(val)
	return row

func _populate_avatar_row(host: HBoxContainer, summary: Dictionary) -> void:
	var signed_ids: PackedStringArray = summary.get("signed_artist_ids", PackedStringArray())
	for index in range(SaveManager.ROSTER_PREVIEW_SLOTS):
		var portrait_host := PanelContainer.new()
		portrait_host.custom_minimum_size = PORTRAIT_SIZE
		GameUiTheme.style_panel(
			portrait_host,
			GameUiTheme.COLOR_BLOCK.darkened(0.12),
			GameUiTheme.COLOR_BORDER.darkened(0.35)
		)
		host.add_child(portrait_host)

		if index >= signed_ids.size():
			continue
		var artist_id: String = str(signed_ids[index])
		var texture: Texture2D = CharacterDatabase.get_avatar(artist_id)
		var fallback: String = CharacterDatabase.get_display_name(artist_id)
		var rect := GameUiTheme.make_portrait_rect(texture, PORTRAIT_SIZE - Vector2(4, 4), fallback)
		rect.set_anchors_preset(Control.PRESET_CENTER)
		portrait_host.add_child(rect)

func _slot_title(kind: int, slot_index: int, is_empty: bool) -> String:
	var base: String = SaveManager.get_slot_display_name(kind, slot_index)
	if is_empty:
		return "%s（空）" % base
	return base

func _on_save_pressed(kind: int, slot_index: int) -> void:
	if not SaveManager.can_player_save_to_slot(kind):
		_status_label.text = "自動存檔槽無法手動寫入。"
		return
	if SaveManager.slot_exists(kind, slot_index):
		_confirm_overwrite(kind, slot_index)
	else:
		_execute_save(kind, slot_index)

func _confirm_overwrite(kind: int, slot_index: int) -> void:
	var summary: Dictionary = SaveManager.peek_slot_summary(kind, slot_index)
	var dialog := ConfirmationDialog.new()
	dialog.title = "覆蓋存檔"
	dialog.dialog_text = (
		"確定覆蓋 %s？\n\n存檔時間：%s\n遊戲日期：%s\n公司：%s"
		% [
			SaveManager.get_slot_display_name(kind, slot_index),
			summary.get("saved_at_text", "—"),
			summary.get("game_date_text", "—"),
			summary.get("company_name", "—"),
		]
	)
	dialog.ok_button_text = "覆蓋存檔"
	dialog.cancel_button_text = "取消"
	dialog.confirmed.connect(
		func() -> void:
			_execute_save(kind, slot_index)
			dialog.queue_free(),
		CONNECT_ONE_SHOT
	)
	dialog.canceled.connect(dialog.queue_free, CONNECT_ONE_SHOT)
	dialog.close_requested.connect(dialog.queue_free, CONNECT_ONE_SHOT)
	add_child(dialog)
	dialog.popup_centered()

func _execute_save(kind: int, slot_index: int) -> void:
	var result: Dictionary = SaveManager.save_slot(kind, slot_index)
	if result.get("success", false):
		_status_label.text = str(result.get("message", "存檔成功。"))
		save_succeeded.emit(kind, slot_index, result)
		_refresh_rows()
	else:
		_status_label.text = "存檔失敗：%s" % str(result.get("reason", "未知錯誤"))

func _on_load_pressed(kind: int, slot_index: int) -> void:
	var result: Dictionary = SaveManager.load_slot(kind, slot_index)
	if result.get("success", false):
		_status_label.text = str(result.get("message", "讀檔成功。"))
		load_succeeded.emit(kind, slot_index, result)
		_refresh_rows()
	else:
		_status_label.text = "讀檔失敗：%s" % str(result.get("reason", "未知錯誤"))

func _on_close_pressed() -> void:
	hide()
	closed.emit()

func _on_overlay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_close_pressed()
