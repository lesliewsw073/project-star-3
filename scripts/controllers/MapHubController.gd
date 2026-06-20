extends Control
class_name MapHubController

signal facility_visit_requested(location_id: String, facility_id: String, facility_name: String)
signal exit_map_requested()
signal end_day_requested()
signal exploration_finished(reason: String)

const FACILITY_PANEL_SCENE = preload("res://UI/facility_panel.tscn")

@export_group("地图数据")
@export var domestic_locations: Array[LocationResource] = []

@onready var bg_rect: TextureRect = $Background
@onready var _top_panel: PanelContainer = $UI_Layer/TopPanel
@onready var title_label: Label = $UI_Layer/TopPanel/TopBox/TitleLabel
@onready var _screen_hint_label: Label = $UI_Layer/TopPanel/TopBox/ScreenHintLabel
@onready var btn_left: Button = $UI_Layer/NavLeft
@onready var btn_right: Button = $UI_Layer/NavRight
@onready var facility_container: VBoxContainer = $UI_Layer/FacilityPanel/FacilityBox/FacilityScroll/FacilityContainer
@onready var _facility_title: Label = $UI_Layer/FacilityPanel/FacilityBox/FacilityTitle
@onready var _facility_box: VBoxContainer = $UI_Layer/FacilityPanel/FacilityBox
@onready var _footer_bar: HBoxContainer = $UI_Layer/FooterBar
@onready var btn_exit_map: Button = $UI_Layer/FooterBar/BtnExitMap
@onready var btn_end_day: Button = $UI_Layer/FooterBar/BtnEndDay
@onready var _facility_panel: PanelContainer = $UI_Layer/FacilityPanel
@onready var _world_panel: PanelContainer = $WorldMapLayer/WorldPanel
@onready var _world_title: Label = $WorldMapLayer/WorldPanel/WorldVBox/HeaderBox/TitleLabel
@onready var _paris_button: Button = $WorldMapLayer/WorldPanel/WorldVBox/CityContainer/ParisButton
@onready var world_map_layer: CanvasLayer = $WorldMapLayer
@onready var btn_close_map: Button = $WorldMapLayer/WorldPanel/WorldVBox/HeaderBox/BtnClose

var current_index: int = 0

func _ready() -> void:
	if domestic_locations.is_empty():
		push_error("[MapHub] 未在 Inspector 中装配 Locations 数组。")
		return
	if not _validate_ui_nodes():
		return

	_apply_theme()
	btn_left.pressed.connect(_on_left_button_pressed)
	btn_right.pressed.connect(_on_right_button_pressed)
	btn_exit_map.pressed.connect(func(): exit_map_requested.emit())
	btn_end_day.pressed.connect(func(): end_day_requested.emit())
	btn_close_map.pressed.connect(_on_close_world_map)
	world_map_layer.hide()
	update_screen()
	refresh_action_buttons()

func refresh_action_buttons() -> void:
	var on_map: bool = GameFlowManager.is_exploring_map
	var free_day: bool = GameFlowManager.get_day_mode() == GameFlowManager.DayMode.FREE
	var pending_settlement: bool = not GameFlowManager.day_settlement_done
	btn_end_day.visible = on_map and free_day and pending_settlement
	btn_end_day.disabled = not on_map
	btn_end_day.text = "結束探索"
	btn_exit_map.visible = on_map
	btn_exit_map.disabled = not GameFlowManager.can_exit_map()

func _validate_ui_nodes() -> bool:
	var missing: PackedStringArray = PackedStringArray()
	if bg_rect == null:
		missing.append("Background")
	if title_label == null:
		missing.append("TitleLabel")
	if facility_container == null:
		missing.append("FacilityContainer")
	if btn_exit_map == null:
		missing.append("BtnExitMap")
	if btn_end_day == null:
		missing.append("BtnEndDay")
	if btn_close_map == null:
		missing.append("BtnClose")
	if world_map_layer == null:
		missing.append("WorldMapLayer")
	if missing.size() > 0:
		push_error("[MapHub] UI 節點缺失：%s" % ", ".join(missing))
		return false
	return true

func _apply_theme() -> void:
	GameUiTheme.style_panel(_top_panel, GameUiTheme.COLOR_BLOCK_ACCENT)
	GameUiTheme.style_panel(_facility_panel, GameUiTheme.COLOR_BLOCK)
	GameUiTheme.style_panel(_world_panel, GameUiTheme.COLOR_PANEL)

	GameUiTheme.compact_button(btn_left, 36.0, GameUiTheme.BTN_HEIGHT_SM)
	GameUiTheme.compact_button(btn_right, 36.0, GameUiTheme.BTN_HEIGHT_SM)
	GameUiTheme.style_button(btn_left, GameUiTheme.COLOR_BLOCK.lightened(0.06), GameUiTheme.FONT_HINT)
	GameUiTheme.style_button(btn_right, GameUiTheme.COLOR_BLOCK.lightened(0.06), GameUiTheme.FONT_HINT)

	GameUiTheme.compact_button(btn_exit_map, 0.0, GameUiTheme.BTN_HEIGHT)
	GameUiTheme.compact_button(btn_end_day, 0.0, GameUiTheme.BTN_HEIGHT)
	GameUiTheme.compact_button(btn_close_map, 72.0, GameUiTheme.BTN_HEIGHT_SM)
	btn_exit_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_end_day.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GameUiTheme.style_button(btn_exit_map, GameUiTheme.COLOR_WARM, GameUiTheme.FONT_HINT)
	GameUiTheme.style_button(btn_end_day, GameUiTheme.COLOR_SUCCESS, GameUiTheme.FONT_HINT)
	GameUiTheme.style_button(btn_close_map, GameUiTheme.COLOR_DANGER, GameUiTheme.FONT_HINT)

	_world_title.text = "世界地圖"
	GameUiTheme.style_label(_world_title, GameUiTheme.COLOR_GOLD, GameUiTheme.FONT_SECTION)

	if _paris_button != null:
		GameUiTheme.compact_button(_paris_button, 0.0, GameUiTheme.BTN_HEIGHT)
		GameUiTheme.style_button(_paris_button, GameUiTheme.COLOR_NAV, GameUiTheme.FONT_HINT)

	GameUiTheme.style_label(title_label, GameUiTheme.COLOR_GOLD, GameUiTheme.FONT_TITLE)
	GameUiTheme.style_label(_screen_hint_label, GameUiTheme.COLOR_MUTED, GameUiTheme.FONT_HINT)

	if _footer_bar != null:
		_footer_bar.add_theme_constant_override("separation", GameUiTheme.SEP)
	if _facility_title != null:
		GameUiTheme.style_label(_facility_title, GameUiTheme.COLOR_GOLD, GameUiTheme.FONT_SECTION)
	if _facility_box != null:
		_facility_box.add_theme_constant_override("separation", GameUiTheme.SEP)
	if facility_container != null:
		facility_container.add_theme_constant_override("separation", 4)

func _on_left_button_pressed() -> void:
	current_index = (current_index - 1 + domestic_locations.size()) % domestic_locations.size()
	update_screen()

func _on_right_button_pressed() -> void:
	current_index = (current_index + 1) % domestic_locations.size()
	update_screen()

func update_screen() -> void:
	if facility_container == null or bg_rect == null or title_label == null:
		push_error("[MapHub] update_screen 失敗：UI 節點未就緒。")
		return
	var current_location: LocationResource = domestic_locations[current_index]
	bg_rect.texture = current_location.background_texture
	title_label.text = current_location.location_name
	_screen_hint_label.text = "%d / %d · %s" % [
		current_index + 1,
		domestic_locations.size(),
		str(current_location.location_id),
	]

	for child in facility_container.get_children():
		child.queue_free()

	for facility in current_location.facilities:
		if facility == null:
			continue
		var btn := Button.new()
		btn.text = facility.facility_name
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		GameUiTheme.compact_button(btn, 0.0, GameUiTheme.BTN_HEIGHT)
		GameUiTheme.style_button(btn, GameUiTheme.COLOR_BLOCK.lightened(0.04), GameUiTheme.FONT_HINT)
		btn.pressed.connect(_on_facility_clicked.bind(facility))
		facility_container.add_child(btn)

func _on_facility_clicked(facility: FacilityResource) -> void:
	if domestic_locations.is_empty():
		return
	var current_location: LocationResource = domestic_locations[current_index]
	facility_visit_requested.emit(
		str(current_location.location_id).strip_edges(),
		str(facility.facility_id).strip_edges(),
		facility.facility_name
	)

	if facility.type == FacilityResource.FacilityType.TRANSPORT:
		world_map_layer.show()
	else:
		var panel_instance := FACILITY_PANEL_SCENE.instantiate() as FacilityPanel
		add_child(panel_instance)
		panel_instance.closed.connect(_on_facility_panel_closed, CONNECT_ONE_SHOT)
		panel_instance.call_deferred("setup", facility)

func _on_facility_panel_closed(_facility_id: String) -> void:
	exploration_finished.emit("facility")

func _on_close_world_map() -> void:
	world_map_layer.hide()
	exploration_finished.emit("transport")
