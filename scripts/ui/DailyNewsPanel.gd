class_name DailyNewsPanel
extends CanvasLayer

signal dismissed

var _edition: Array = []
var _dismiss_pending: bool = false
var _date_label: Label
var _items_box: VBoxContainer
var _click_layer: ColorRect

func _ready() -> void:
	layer = 46
	_build_shell()
	hide()

func show_edition(edition: Array) -> void:
	_dismiss_pending = false
	_edition = edition.duplicate(true)
	_rebuild_content()
	show()

func _build_shell() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.04, 0.05, 0.09, 0.94)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 48)
	root.add_theme_constant_override("margin_top", 36)
	root.add_theme_constant_override("margin_right", 48)
	root.add_theme_constant_override("margin_bottom", 36)
	add_child(root)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 14)
	root.add_child(box)

	var title := Label.new()
	title.text = "今日頭條"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUiTheme.style_label(title, GameUiTheme.COLOR_GOLD, GameUiTheme.FONT_TITLE)
	box.add_child(title)

	_date_label = Label.new()
	_date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUiTheme.style_label(_date_label, GameUiTheme.COLOR_MUTED, GameUiTheme.FONT_HINT)
	box.add_child(_date_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

	_items_box = VBoxContainer.new()
	_items_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items_box.add_theme_constant_override("separation", 10)
	scroll.add_child(_items_box)

	var hint := Label.new()
	hint.text = "點擊空白處繼續"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUiTheme.style_label(hint, GameUiTheme.COLOR_MUTED, GameUiTheme.FONT_HINT)
	box.add_child(hint)

	_click_layer = ColorRect.new()
	_click_layer.color = Color(0, 0, 0, 0)
	_click_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_click_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_click_layer.gui_input.connect(_on_click_to_dismiss)
	add_child(_click_layer)

func _rebuild_content() -> void:
	if _date_label == null or _items_box == null:
		return
	var snapshot: Dictionary = TimeManager.get_date_snapshot()
	_date_label.text = snapshot.get("display_text", "")
	for child in _items_box.get_children():
		child.queue_free()
	for item in _edition:
		if item is Dictionary:
			_items_box.add_child(_make_news_card(item))

func _make_news_card(item: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GameUiTheme.style_panel(panel, Color(0.14, 0.16, 0.22, 0.98))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)

	var thumb := _make_thumbnail(item)
	row.add_child(thumb)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 4)
	row.add_child(text_col)

	var type_label := Label.new()
	type_label.text = str(item.get("edition_type_name", "新聞"))
	GameUiTheme.style_label(type_label, GameUiTheme.COLOR_WARM, GameUiTheme.FONT_HINT)
	text_col.add_child(type_label)

	var headline := Label.new()
	headline.text = str(item.get("title", ""))
	headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GameUiTheme.style_label(headline, GameUiTheme.COLOR_GOLD, GameUiTheme.FONT_SECTION)
	text_col.add_child(headline)

	var body := Label.new()
	body.text = str(item.get("body", ""))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GameUiTheme.style_label(body, GameUiTheme.COLOR_TEXT, GameUiTheme.FONT_BODY)
	text_col.add_child(body)

	var reporter_id: String = str(item.get("reporter_id", ""))
	if reporter_id != "":
		var reporter_line := Label.new()
		reporter_line.text = "記者：%s" % CharacterDatabase.get_display_name(reporter_id)
		GameUiTheme.style_label(reporter_line, GameUiTheme.COLOR_MUTED, GameUiTheme.FONT_HINT)
		text_col.add_child(reporter_line)

	return panel

func _make_thumbnail(item: Dictionary) -> Control:
	var wrap := PanelContainer.new()
	wrap.custom_minimum_size = Vector2(96, 96)
	GameUiTheme.style_panel(wrap, Color(0.10, 0.11, 0.16, 1.0))
	var tex: Texture2D = NewsManager.resolve_edition_image_texture(item)
	var rect := TextureRect.new()
	rect.custom_minimum_size = Vector2(88, 88)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if tex != null:
		rect.texture = tex
	else:
		var placeholder := ColorRect.new()
		placeholder.custom_minimum_size = Vector2(88, 88)
		placeholder.color = Color(0.22, 0.24, 0.30, 1.0)
		wrap.add_child(placeholder)
		return wrap
	wrap.add_child(rect)
	return wrap

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
