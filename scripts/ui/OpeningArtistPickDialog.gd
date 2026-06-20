class_name OpeningArtistPickDialog
extends CanvasLayer

## 開局 STAGE3：行動三選一（不顯示藝人姓名／立繪／標籤）。

signal artist_confirmed(artist_id: String)

const OPENING_ACTIONS: Array[Dictionary] = [
	{"label": "下樓透透氣", "artist_id": "artist_001"},
	{"label": "去看場舞台劇", "artist_id": "artist_002"},
	{"label": "打開電視看看", "artist_id": "artist_003"},
]

var _selected_artist_id: String = ""
var _action_buttons: Dictionary = {}
var _error_label: Label
var _confirm_button: Button

func _ready() -> void:
	layer = 51
	_build_ui()
	hide()

func open_dialog() -> void:
	if GameFlowManager.is_initial_sign_completed():
		hide()
		return
	_selected_artist_id = ""
	_error_label.text = ""
	_confirm_button.disabled = true
	_refresh_action_selection()
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
	panel.custom_minimum_size = Vector2(640, 0)
	GameUiTheme.style_panel(panel, GameUiTheme.COLOR_PANEL)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", GameUiTheme.SEP)
	panel.add_child(box)

	var title := GameUiTheme.make_section_label("今天做什麼？", GameUiTheme.COLOR_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var hint := Label.new()
	hint.text = "選一個行動。簽約對象由劇情揭曉，此處不顯示藝人資訊。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUiTheme.style_label(hint, GameUiTheme.COLOR_MUTED, GameUiTheme.FONT_HINT)
	box.add_child(hint)

	var actions_box := VBoxContainer.new()
	actions_box.add_theme_constant_override("separation", 8)
	box.add_child(actions_box)

	for action in OPENING_ACTIONS:
		var artist_id: String = str(action.get("artist_id", "")).strip_edges()
		var label: String = str(action.get("label", "")).strip_edges()
		var button := Button.new()
		button.text = label
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		GameUiTheme.compact_button(button, 0.0, GameUiTheme.BTN_HEIGHT)
		GameUiTheme.style_button(button, GameUiTheme.COLOR_PRIMARY, GameUiTheme.FONT_BODY)
		button.pressed.connect(func(): _select_action(artist_id))
		actions_box.add_child(button)
		_action_buttons[artist_id] = button

	_error_label = Label.new()
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	GameUiTheme.style_label(_error_label, GameUiTheme.COLOR_DANGER, GameUiTheme.FONT_HINT)
	box.add_child(_error_label)

	_confirm_button = Button.new()
	_confirm_button.text = "就這樣"
	_confirm_button.disabled = true
	GameUiTheme.compact_button(_confirm_button, 0.0, GameUiTheme.BTN_HEIGHT)
	GameUiTheme.style_button(_confirm_button, GameUiTheme.COLOR_SUCCESS, GameUiTheme.FONT_HINT)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	box.add_child(_confirm_button)

func _select_action(artist_id: String) -> void:
	if artist_id.strip_edges() == "":
		return
	_selected_artist_id = artist_id
	_error_label.text = ""
	_confirm_button.disabled = false
	_refresh_action_selection()

func _refresh_action_selection() -> void:
	for artist_id in _action_buttons:
		var button: Button = _action_buttons[artist_id]
		var selected: bool = artist_id == _selected_artist_id
		GameUiTheme.style_button(
			button,
			GameUiTheme.COLOR_GOLD.darkened(0.15) if selected else GameUiTheme.COLOR_PRIMARY,
			GameUiTheme.FONT_BODY
		)

func _on_confirm_pressed() -> void:
	if _selected_artist_id == "":
		_error_label.text = "請先選擇一個行動。"
		return
	if not ArtistManager.is_initial_signable_artist(_selected_artist_id):
		_error_label.text = "此行動暫不可用。"
		return
	InteractionManager.set_flag("opening_pick", _selected_artist_id)
	if not ArtistManager.sign_initial_artist(_selected_artist_id):
		_error_label.text = "簽約失敗，請重試。"
		return
	hide()
	artist_confirmed.emit(_selected_artist_id)
