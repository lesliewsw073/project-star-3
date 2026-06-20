class_name ShopPurchaseDialog
extends CanvasLayer

signal purchased(item_id: String, result: Dictionary)
signal cancelled()

const COLOR_OVERLAY := Color(0.04, 0.05, 0.08, 0.72)
const COLOR_PANEL := Color(0.16, 0.15, 0.21, 1.0)
const COLOR_BORDER := Color(0.38, 0.42, 0.52, 0.55)
const COLOR_TEXT := Color(0.92, 0.93, 0.96, 1.0)
const COLOR_MUTED := Color(0.62, 0.66, 0.74, 1.0)
const COLOR_GOLD := Color(0.96, 0.78, 0.36, 1.0)
const COLOR_WARM := Color(0.78, 0.52, 0.28, 1.0)
const COLOR_SUCCESS := Color(0.28, 0.68, 0.46, 1.0)

var _shop_name: String = "商店"
var _selected_item_id: String = ""
var _header_label: Label
var _money_label: Label
var _hint_label: Label
var _detail_label: Label
var _status_label: Label
var _item_list: ItemList
var _confirm_button: Button

func _ready() -> void:
	layer = 22
	_build_ui()
	hide()

func open_shop(shop_name: String = "商店") -> void:
	_ensure_ui_ready()
	_shop_name = shop_name.strip_edges()
	if _shop_name == "":
		_shop_name = "商店"
	_selected_item_id = ""
	_status_label.text = ""
	_refresh_list()
	show()

func _ensure_ui_ready() -> void:
	if _item_list == null:
		_build_ui()

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
	panel.custom_minimum_size = Vector2(500, 400)
	_style_panel(panel, COLOR_PANEL)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	_header_label = _make_label("商店", COLOR_GOLD, 14)
	box.add_child(_header_label)

	_money_label = _make_label("", COLOR_TEXT, 11)
	box.add_child(_money_label)

	_hint_label = _make_label("選擇商品後按購買；金幣從公司資金扣除。", COLOR_MUTED, 11)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_hint_label)

	_item_list = ItemList.new()
	_item_list.custom_minimum_size = Vector2(0, 190)
	_item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_item_list.item_selected.connect(_on_item_selected)
	box.add_child(_item_list)

	_detail_label = _make_label("請選擇商品。", COLOR_TEXT, 11)
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_detail_label)

	_status_label = _make_label("", COLOR_SUCCESS, 11)
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status_label)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	button_row.alignment = BoxContainer.ALIGNMENT_END
	box.add_child(button_row)

	var cancel_button := Button.new()
	cancel_button.text = "離開"
	cancel_button.custom_minimum_size = Vector2(88, 30)
	_style_button(cancel_button, COLOR_MUTED.darkened(0.35))
	cancel_button.pressed.connect(_on_cancel_pressed)
	button_row.add_child(cancel_button)

	_confirm_button = Button.new()
	_confirm_button.text = "購買"
	_confirm_button.custom_minimum_size = Vector2(88, 30)
	_style_button(_confirm_button, COLOR_WARM)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	button_row.add_child(_confirm_button)

	if not ItemManager.item_purchased.is_connected(_on_item_purchased):
		ItemManager.item_purchased.connect(_on_item_purchased)

func _refresh_list() -> void:
	_item_list.clear()
	_header_label.text = "%s · 購買道具" % _shop_name
	_money_label.text = "公司資金：$%d" % PlayerManager.money

	var entries: Array[Dictionary] = ItemManager.get_shop_catalog()
	if entries.is_empty():
		_hint_label.text = "目前沒有可購買的商品。"
		_detail_label.text = "請稍後再來，或請企劃在 data/items/ 新增 shop_price > 0 的道具。"
		_update_confirm_state()
		return

	_hint_label.text = "公司物品已持有不可重複購買；屬性／劇情道具可重複購買入物品欄。"
	for entry in entries:
		var item_id: String = str(entry.get("item_id", ""))
		var item_name: String = str(entry.get("item_name", item_id))
		var price: int = int(entry.get("shop_price", 0))
		var category_label: String = _category_label(int(entry.get("category", -1)))
		var suffix: String = ""
		if bool(entry.get("owned", false)):
			suffix = " [已持有]"
		elif str(entry.get("block_reason", "")) != "" and not bool(entry.get("can_buy", false)):
			suffix = " [%s]" % str(entry.get("block_reason", ""))
		var line: String = "%s · $%d（%s）%s" % [item_name, price, category_label, suffix]
		var index: int = _item_list.add_item(line)
		_item_list.set_item_metadata(index, item_id)
		if not bool(entry.get("can_buy", false)):
			_item_list.set_item_custom_fg_color(index, COLOR_MUTED)

	_update_confirm_state()

func _on_item_selected(index: int) -> void:
	_status_label.text = ""
	if index < 0:
		_selected_item_id = ""
		_detail_label.text = "請選擇商品。"
		_update_confirm_state()
		return

	_selected_item_id = str(_item_list.get_item_metadata(index))
	var item: ItemResource = ItemDatabase.get_item(_selected_item_id)
	if item == null:
		_detail_label.text = "商品資料遺失。"
		_update_confirm_state()
		return

	var lines: PackedStringArray = PackedStringArray()
	lines.append(ItemManager.build_gift_effect_summary(item))
	lines.append("售價：$%d" % item.shop_price)
	if int(item.item_category) == ItemResource.ItemCategory.COMPANY:
		if item.reputation_bonus > 0:
			lines.append("聲望加成上限：+%d（邊際結算）" % item.reputation_bonus)
		if item.public_opinion_bonus > 0:
			lines.append("口碑加成上限：+%d（邊際結算）" % item.public_opinion_bonus)
	elif item.is_bag_item():
		lines.append("物品欄現有：%d" % InventoryManager.get_count(item.item_id))

	var check: Dictionary = ItemManager.can_purchase_from_shop(item.item_id)
	if not bool(check.get("ok", false)):
		lines.append("狀態：%s" % str(check.get("reason", "")))

	_detail_label.text = "\n".join(lines)
	_update_confirm_state()

func _update_confirm_state() -> void:
	if _selected_item_id.strip_edges() == "":
		_confirm_button.disabled = true
		return
	var check: Dictionary = ItemManager.can_purchase_from_shop(_selected_item_id)
	_confirm_button.disabled = not bool(check.get("ok", false))

func _on_confirm_pressed() -> void:
	if _selected_item_id.strip_edges() == "":
		return
	var result: Dictionary = ItemManager.try_purchase(_selected_item_id)
	_refresh_list()
	var selected_items: PackedInt32Array = _item_list.get_selected_items()
	if not result.get("success", false):
		_status_label.add_theme_color_override("font_color", Color(0.92, 0.45, 0.45))
		_status_label.text = str(result.get("reason", "購買失敗。"))
		if selected_items.size() > 0:
			_on_item_selected(int(selected_items[0]))
		return

	_status_label.add_theme_color_override("font_color", COLOR_SUCCESS)
	_status_label.text = "已購買「%s」。" % str(result.get("item_name", _selected_item_id))
	purchased.emit(_selected_item_id, result)
	if selected_items.size() > 0:
		_on_item_selected(int(selected_items[0]))

func _on_cancel_pressed() -> void:
	cancelled.emit()
	hide()

func _on_item_purchased(_result: Dictionary) -> void:
	if visible and is_inside_tree():
		_refresh_list()

func _category_label(category: int) -> String:
	match category:
		ItemResource.ItemCategory.COMPANY:
			return "公司"
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
