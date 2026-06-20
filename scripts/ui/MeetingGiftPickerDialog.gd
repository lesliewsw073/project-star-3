class_name MeetingGiftPickerDialog
extends CanvasLayer

signal confirmed(artist_id: String, item_id: String)
signal cancelled()

const COLOR_OVERLAY := Color(0.04, 0.05, 0.08, 0.72)
const COLOR_PANEL := Color(0.16, 0.15, 0.21, 1.0)
const COLOR_BORDER := Color(0.38, 0.42, 0.52, 0.55)
const COLOR_TEXT := Color(0.92, 0.93, 0.96, 1.0)
const COLOR_MUTED := Color(0.62, 0.66, 0.74, 1.0)
const COLOR_GOLD := Color(0.96, 0.78, 0.36, 1.0)
const COLOR_PRIMARY := Color(0.32, 0.52, 0.82, 1.0)
const COLOR_WARM := Color(0.78, 0.52, 0.28, 1.0)

var _artist_id: String = ""
var _selected_item_id: String = ""
var _header_label: Label
var _hint_label: Label
var _detail_label: Label
var _item_list: ItemList
var _confirm_button: Button

func _ready() -> void:
	layer = 21
	_build_ui()
	hide()

func _ensure_ui_ready() -> void:
	if _item_list == null:
		_build_ui()

func open_for_artist(artist_id: String) -> void:
	_ensure_ui_ready()
	_artist_id = artist_id.strip_edges()
	_selected_item_id = ""
	_refresh_list()
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
	panel.custom_minimum_size = Vector2(460, 360)
	_style_panel(panel, COLOR_PANEL)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	_header_label = _make_label("週日會議送禮", COLOR_GOLD, 14)
	box.add_child(_header_label)

	_hint_label = _make_label("", COLOR_MUTED, 11)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_hint_label)

	_item_list = ItemList.new()
	_item_list.custom_minimum_size = Vector2(0, 180)
	_item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_item_list.item_selected.connect(_on_item_selected)
	box.add_child(_item_list)

	_detail_label = _make_label("請從物品欄選擇要贈送的道具。", COLOR_TEXT, 11)
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_detail_label)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	button_row.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(button_row)

	var cancel_button := Button.new()
	cancel_button.text = "取消"
	cancel_button.custom_minimum_size = Vector2(88, 30)
	_style_button(cancel_button, COLOR_MUTED.darkened(0.35))
	cancel_button.pressed.connect(_on_cancel_pressed)
	button_row.add_child(cancel_button)

	_confirm_button = Button.new()
	_confirm_button.text = "贈送"
	_confirm_button.custom_minimum_size = Vector2(88, 30)
	_style_button(_confirm_button, COLOR_WARM)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	button_row.add_child(_confirm_button)

func _refresh_list() -> void:
	_item_list.clear()
	_selected_item_id = ""

	var display_name: String = CharacterDatabase.get_display_name(_artist_id)
	_header_label.text = "週日會議送禮 · %s" % display_name

	var entries: Array[Dictionary] = InventoryManager.get_giftable_entries()
	if entries.is_empty():
		_hint_label.text = "物品欄沒有可贈送的道具（屬性／劇情類）。"
		_detail_label.text = "可透過商店購買。"
		_update_confirm_state()
		return

	_hint_label.text = "僅顯示可贈送給已簽約藝人的道具；贈送後從物品欄扣除 1 個。"
	for entry in entries:
		var item_id: String = str(entry.get("item_id", ""))
		var item_name: String = str(entry.get("item_name", item_id))
		var count: int = int(entry.get("count", 0))
		var category: int = int(entry.get("category", -1))
		var category_label: String = _category_label(category)
		var line: String = "%s ×%d（%s）" % [item_name, count, category_label]
		var index: int = _item_list.add_item(line)
		_item_list.set_item_metadata(index, item_id)

	_update_confirm_state()

func _on_item_selected(index: int) -> void:
	if index < 0:
		_selected_item_id = ""
		_detail_label.text = "請選擇一項道具。"
		_update_confirm_state()
		return

	_selected_item_id = str(_item_list.get_item_metadata(index))
	var item: ItemResource = ItemDatabase.get_item(_selected_item_id)
	if item == null:
		_detail_label.text = "道具資料遺失。"
		_update_confirm_state()
		return

	_detail_label.text = ItemManager.build_gift_effect_summary(item, _artist_id)
	_update_confirm_state()

func _update_confirm_state() -> void:
	_confirm_button.disabled = _selected_item_id.strip_edges() == ""

func _on_confirm_pressed() -> void:
	if _selected_item_id.strip_edges() == "":
		return
	confirmed.emit(_artist_id, _selected_item_id)
	hide()

func _on_cancel_pressed() -> void:
	cancelled.emit()
	hide()

func _category_label(category: int) -> String:
	match category:
		ItemResource.ItemCategory.ATTRIBUTE:
			return "屬性"
		ItemResource.ItemCategory.STORY:
			return "劇情"
		_:
			return "道具"

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
