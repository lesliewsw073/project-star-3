extends CanvasLayer
class_name FacilityPanel

signal closed(facility_id: String)

const DIALOGUE_PANEL_SCENE = preload("res://UI/dialogue_panel.tscn")
const ShopPurchaseDialogScript = preload("res://scripts/ui/ShopPurchaseDialog.gd")

@onready var _dim_background: ColorRect = $DimBackground
@onready var _main_panel: PanelContainer = $DimBackground/MainPanel
@onready var _main_vbox: VBoxContainer = $DimBackground/MainPanel/VBoxContainer
@onready var title_label: Label = $DimBackground/MainPanel/VBoxContainer/HeaderBox/TitleLabel
@onready var close_button: Button = $DimBackground/MainPanel/VBoxContainer/HeaderBox/CloseButton
@onready var content_list: VBoxContainer = $DimBackground/MainPanel/VBoxContainer/ScrollContainer/ContentList

var current_facility: FacilityResource
var _shop_dialog: CanvasLayer

func _ready() -> void:
	layer = 30
	if not _validate_ui_nodes():
		return
	_apply_theme()
	close_button.pressed.connect(_on_close_button_pressed)

func _validate_ui_nodes() -> bool:
	var missing: PackedStringArray = PackedStringArray()
	if _dim_background == null:
		missing.append("DimBackground")
	if _main_panel == null:
		missing.append("MainPanel")
	if _main_vbox == null:
		missing.append("VBoxContainer")
	if title_label == null:
		missing.append("TitleLabel")
	if close_button == null:
		missing.append("CloseButton")
	if content_list == null:
		missing.append("ContentList")
	if missing.size() > 0:
		push_error("[FacilityPanel] UI 節點缺失：%s" % ", ".join(missing))
		return false
	return true

func _apply_theme() -> void:
	GameUiTheme.style_panel(_main_panel, GameUiTheme.COLOR_PANEL)
	GameUiTheme.style_label(title_label, GameUiTheme.COLOR_GOLD, GameUiTheme.FONT_SECTION)
	GameUiTheme.compact_button(close_button, 56.0, GameUiTheme.BTN_HEIGHT_SM)
	GameUiTheme.style_button(close_button, GameUiTheme.COLOR_DANGER, GameUiTheme.FONT_HINT)
	_main_vbox.add_theme_constant_override("separation", GameUiTheme.SEP)
	content_list.add_theme_constant_override("separation", 4)
	_dim_background.color = GameUiTheme.COLOR_OVERLAY

func setup(facility: FacilityResource) -> void:
	if not _validate_ui_nodes():
		return
	current_facility = facility
	title_label.text = facility.facility_name

	for child in content_list.get_children():
		child.queue_free()

	if _is_shop_facility(facility):
		var shop_btn := Button.new()
		shop_btn.text = "購買道具"
		shop_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		GameUiTheme.compact_button(shop_btn, 0.0, GameUiTheme.BTN_HEIGHT)
		GameUiTheme.style_button(shop_btn, GameUiTheme.COLOR_WARM, GameUiTheme.FONT_HINT)
		shop_btn.pressed.connect(_on_shop_pressed)
		content_list.add_child(shop_btn)

	if facility.available_npcs.is_empty():
		if not _is_shop_facility(facility):
			var empty_label := Label.new()
			empty_label.text = "（此設施暫無可互動人物）"
			GameUiTheme.style_label(empty_label, GameUiTheme.COLOR_MUTED, GameUiTheme.FONT_HINT)
			content_list.add_child(empty_label)
		return

	for npc in facility.available_npcs:
		if npc == null:
			continue
		var npc_btn := Button.new()
		npc_btn.text = "與 %s 對話" % npc.npc_name
		npc_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		GameUiTheme.compact_button(npc_btn, 0.0, GameUiTheme.BTN_HEIGHT)
		GameUiTheme.style_button(npc_btn, GameUiTheme.COLOR_BLOCK.lightened(0.06), GameUiTheme.FONT_HINT)
		npc_btn.pressed.connect(_on_npc_clicked.bind(npc))
		content_list.add_child(npc_btn)

func _is_shop_facility(facility: FacilityResource) -> bool:
	return facility != null and int(facility.type) == FacilityResource.FacilityType.SHOP

func _on_shop_pressed() -> void:
	if current_facility == null:
		return
	if _shop_dialog != null and is_instance_valid(_shop_dialog):
		_shop_dialog.queue_free()
	_shop_dialog = ShopPurchaseDialogScript.new()
	add_child(_shop_dialog)
	_shop_dialog.open_shop(current_facility.facility_name)

func _on_npc_clicked(npc: NPCResource) -> void:
	if npc.default_dialogue == null:
		push_warning("[FacilityPanel] %s 未配置對話。" % npc.npc_name)
		return
	var dialogue_instance := DIALOGUE_PANEL_SCENE.instantiate() as DialoguePanel
	add_child(dialogue_instance)
	dialogue_instance.call_deferred("start_dialogue", npc.default_dialogue, npc)

func _on_close_button_pressed() -> void:
	var facility_id: String = ""
	if current_facility != null:
		facility_id = str(current_facility.facility_id).strip_edges()
	closed.emit(facility_id)
	queue_free()
