class_name ArtistSignProfileDialog
extends CanvasLayer

signal confirmed(artist_id: String)
signal cancelled()

var _artist_id: String = ""
var _profile_box: VBoxContainer
var _error_label: Label

func _ready() -> void:
	layer = 52
	_build_ui()
	hide()

func open_for_artist(artist_id: String) -> void:
	_artist_id = artist_id.strip_edges()
	if _artist_id == "":
		push_warning("[ArtistSignProfileDialog] artist_id 為空。")
		return

	var resource: ArtistResource = ArtistManager.get_artist_resource(_artist_id)
	if resource == null:
		_error_label.text = "找不到藝人資料。"
		return

	_error_label.text = ""
	_rebuild_content(resource)
	show()

func _build_ui() -> void:
	var overlay := ColorRect.new()
	overlay.color = GameUiTheme.COLOR_OVERLAY
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 0)
	GameUiTheme.style_panel(panel, GameUiTheme.COLOR_PANEL)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", GameUiTheme.SEP)
	panel.add_child(box)

	var title := GameUiTheme.make_section_label("簽約確認 · 人物檔案", GameUiTheme.COLOR_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var hint := Label.new()
	hint.text = "以下為人物檔案（不影響能力與劇情判定）。確認後完成簽約。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUiTheme.style_label(hint, GameUiTheme.COLOR_MUTED, GameUiTheme.FONT_HINT)
	box.add_child(hint)

	_profile_box = VBoxContainer.new()
	_profile_box.add_theme_constant_override("separation", 4)
	box.add_child(_profile_box)

	_error_label = Label.new()
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUiTheme.style_label(_error_label, GameUiTheme.COLOR_DANGER, GameUiTheme.FONT_HINT)
	box.add_child(_error_label)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", GameUiTheme.SEP)
	box.add_child(action_row)

	var cancel_button := Button.new()
	cancel_button.text = "返回"
	cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GameUiTheme.compact_button(cancel_button, 0.0, GameUiTheme.BTN_HEIGHT)
	GameUiTheme.style_button(cancel_button, GameUiTheme.COLOR_DANGER, GameUiTheme.FONT_HINT)
	cancel_button.pressed.connect(_on_cancel_pressed)
	action_row.add_child(cancel_button)

	var confirm_button := Button.new()
	confirm_button.text = "確認簽約"
	confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GameUiTheme.compact_button(confirm_button, 0.0, GameUiTheme.BTN_HEIGHT)
	GameUiTheme.style_button(confirm_button, GameUiTheme.COLOR_SUCCESS, GameUiTheme.FONT_HINT)
	confirm_button.pressed.connect(_on_confirm_pressed)
	action_row.add_child(confirm_button)

func _rebuild_content(resource: ArtistResource) -> void:
	for child in _profile_box.get_children():
		child.queue_free()

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", GameUiTheme.SEP)
	_profile_box.add_child(header_row)

	var portrait := GameUiTheme.make_portrait_rect(
		CharacterDatabase.get_portrait(resource.artist_id),
		Vector2(200, 280),
		resource.artist_name
	)
	header_row.add_child(portrait)

	var name_box := VBoxContainer.new()
	name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_box.add_theme_constant_override("separation", 2)
	header_row.add_child(name_box)

	var name_label := Label.new()
	name_label.text = resource.artist_name
	GameUiTheme.style_label(name_label, GameUiTheme.COLOR_GOLD, GameUiTheme.FONT_SECTION)
	name_box.add_child(name_label)

	var profile_panel := PanelContainer.new()
	GameUiTheme.style_panel(profile_panel, GameUiTheme.COLOR_BLOCK)
	_profile_box.add_child(profile_panel)

	var profile_inner := VBoxContainer.new()
	profile_inner.add_theme_constant_override("separation", 4)
	profile_panel.add_child(profile_inner)

	ArtistProfileDisplay.populate_labels(profile_inner, resource, false)

func _on_confirm_pressed() -> void:
	if _artist_id == "":
		_error_label.text = "藝人 ID 無效。"
		return
	hide()
	confirmed.emit(_artist_id)

func _on_cancel_pressed() -> void:
	hide()
	cancelled.emit()
