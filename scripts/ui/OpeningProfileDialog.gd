class_name OpeningProfileDialog
extends CanvasLayer

signal profile_confirmed(last_name: String, first_name: String, company_name: String)

var _last_name_edit: LineEdit
var _first_name_edit: LineEdit
var _company_edit: LineEdit
var _error_label: Label

func _ready() -> void:
	layer = 50
	_build_ui()
	hide()

func open_dialog() -> void:
	if ProtagonistManager.is_profile_locked():
		hide()
		return
	_last_name_edit.text = ProtagonistManager.get_last_name()
	_first_name_edit.text = ProtagonistManager.get_first_name()
	_company_edit.text = ""
	_error_label.text = ""
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
	panel.custom_minimum_size = Vector2(360, 0)
	GameUiTheme.style_panel(panel, GameUiTheme.COLOR_PANEL)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", GameUiTheme.SEP)
	panel.add_child(box)

	var title := GameUiTheme.make_section_label("開局設定", GameUiTheme.COLOR_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var hint := Label.new()
	hint.text = "請設定主角姓名與經紀公司名稱。確認後不可再修改。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GameUiTheme.style_label(hint, GameUiTheme.COLOR_MUTED, GameUiTheme.FONT_HINT)
	box.add_child(hint)

	_last_name_edit = _make_line_edit("例如：陸")
	_first_name_edit = _make_line_edit("例如：星河")
	_company_edit = _make_line_edit("請輸入經紀公司名稱")

	box.add_child(_make_field_row("姓氏", _last_name_edit))
	box.add_child(_make_field_row("名字", _first_name_edit))
	box.add_child(_make_field_row("公司名稱", _company_edit))

	_error_label = Label.new()
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GameUiTheme.style_label(_error_label, GameUiTheme.COLOR_DANGER, GameUiTheme.FONT_HINT)
	box.add_child(_error_label)

	var confirm := Button.new()
	confirm.text = "確認並開始"
	GameUiTheme.compact_button(confirm, 0.0, GameUiTheme.BTN_HEIGHT)
	GameUiTheme.style_button(confirm, GameUiTheme.COLOR_SUCCESS, GameUiTheme.FONT_HINT)
	confirm.pressed.connect(_on_confirm_pressed)
	box.add_child(confirm)

func _make_field_row(label_text: String, edit: LineEdit) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", GameUiTheme.SEP)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(72, 0)
	GameUiTheme.style_label(label, GameUiTheme.COLOR_TEXT, GameUiTheme.FONT_HINT)
	row.add_child(label)
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.custom_minimum_size = Vector2(0, GameUiTheme.BTN_HEIGHT)
	row.add_child(edit)
	return row

func _make_line_edit(placeholder: String) -> LineEdit:
	var edit := LineEdit.new()
	edit.placeholder_text = placeholder
	edit.add_theme_font_size_override("font_size", GameUiTheme.FONT_BODY)
	return edit

func _on_confirm_pressed() -> void:
	var last_name: String = _last_name_edit.text.strip_edges()
	var first_name: String = _first_name_edit.text.strip_edges()
	var company_name: String = _company_edit.text.strip_edges()

	if last_name == "" or first_name == "":
		_error_label.text = "姓氏與名字皆不可為空。"
		return
	if company_name == "":
		_error_label.text = "請輸入公司名稱。"
		return
	if not ProtagonistManager.rename(last_name, first_name):
		_error_label.text = "主角姓名設定失敗。"
		return
	if not PlayerManager.finalize_company_name(company_name):
		_error_label.text = "公司名稱設定失敗。"
		return

	ProtagonistManager.lock_profile()
	PlayerManager.set_player_name(ProtagonistManager.get_full_name())
	hide()
	profile_confirmed.emit(last_name, first_name, company_name)
