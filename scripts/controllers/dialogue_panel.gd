extends CanvasLayer
class_name DialoguePanel

signal dialogue_finished

@export var portrait_left_rect: TextureRect
@export var portrait_right_rect: TextureRect
@export var cg_rect: TextureRect
@export var name_label: Label
@export var text_label: RichTextLabel

@export var type_speed: float = 0.05

const OVERLAY_ALPHA_DEFAULT := 0.72
const OVERLAY_ALPHA_WITH_CG := 0.38
const FONT_DIALOG := 22
const FONT_NAME := 28

var current_sequence: DialogueSequence
var current_line_index: int = 0
var current_tween: Tween
var _npc_context: NPCResource = null
var _cg_owner_id: String = ""
var _cg_id: String = ""

@onready var _dim_background: ColorRect = $DimBackground
@onready var _dialog_box: Panel = $DialogStack/DialogBox
@onready var _name_plate: PanelContainer = $DialogStack/NamePlate

func _ready() -> void:
	if not _validate_ui_nodes():
		return
	_dim_background.gui_input.connect(_on_overlay_gui_input)
	_dialog_box.gui_input.connect(_on_overlay_gui_input)
	if _name_plate != null:
		_name_plate.gui_input.connect(_on_overlay_gui_input)
	_apply_theme()

func _validate_ui_nodes() -> bool:
	var missing: PackedStringArray = PackedStringArray()
	if _dim_background == null:
		missing.append("DimBackground")
	if _dialog_box == null:
		missing.append("DialogBox")
	if name_label == null:
		missing.append("name_label")
	if text_label == null:
		missing.append("text_label")
	if missing.size() > 0:
		push_error("[DialoguePanel] UI 節點缺失：%s" % ", ".join(missing))
		return false
	return true

func _apply_theme() -> void:
	layer = 40
	GameUiTheme.style_panel_node(_dialog_box, GameUiTheme.COLOR_BLOCK_ACCENT)
	if _name_plate != null:
		GameUiTheme.style_panel(_name_plate, Color(0.20, 0.16, 0.28, 0.96))
	if name_label != null:
		GameUiTheme.style_label(name_label, GameUiTheme.COLOR_GOLD, FONT_NAME)
		name_label.add_theme_constant_override("outline_size", 2)
		name_label.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.12, 0.85))
	GameUiTheme.style_rich_text_label(text_label, GameUiTheme.COLOR_TEXT, FONT_DIALOG)
	_apply_overlay_alpha(OVERLAY_ALPHA_DEFAULT)
	_dim_background.mouse_filter = Control.MOUSE_FILTER_STOP
	for portrait_rect in [portrait_left_rect, portrait_right_rect]:
		if portrait_rect == null:
			continue
		portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		portrait_rect.z_index = 2
		portrait_rect.hide()
	if cg_rect != null:
		cg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if name_label != null:
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if text_label != null:
		text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_label.fit_content = false
	_dialog_box.mouse_filter = Control.MOUSE_FILTER_STOP

func start_dialogue(
	sequence: DialogueSequence,
	npc: NPCResource = null,
	cg_owner_id: String = "",
	cg_id: String = ""
) -> void:
	current_sequence = sequence
	current_line_index = 0
	_npc_context = npc
	_cg_owner_id = cg_owner_id.strip_edges()
	_cg_id = cg_id.strip_edges()
	_apply_cg_background()

	if current_sequence == null or current_sequence.lines.is_empty():
		queue_free()
		return

	show_current_line()

func _apply_cg_background() -> void:
	var has_cg: bool = false
	if cg_rect != null:
		var texture: Texture2D = CharacterDatabase.get_cg_texture(_cg_owner_id, _cg_id)
		if texture != null:
			cg_rect.texture = texture
			cg_rect.show()
			has_cg = true
		else:
			cg_rect.texture = null
			cg_rect.hide()
	_apply_overlay_alpha(OVERLAY_ALPHA_WITH_CG if has_cg else OVERLAY_ALPHA_DEFAULT)

func _apply_overlay_alpha(alpha: float) -> void:
	if _dim_background == null:
		return
	var color: Color = _dim_background.color
	color.a = alpha
	_dim_background.color = color

func show_current_line() -> void:
	var line = current_sequence.lines[current_line_index]
	var speaker_id: String = line.speaker_id.strip_edges()
	if speaker_id == "" and _npc_context != null:
		speaker_id = _npc_context.npc_id.strip_edges()
	var context: Dictionary = {
		"speaker_id": speaker_id,
		"character_id": speaker_id,
		"special_address": line.special_player_address,
	}
	var resolved_speaker_name: String = DialogueVariableResolver.resolve_text(line.speaker_name, context)
	if resolved_speaker_name.strip_edges() == "" and speaker_id != "":
		resolved_speaker_name = CharacterDatabase.get_display_name(speaker_id)
	name_label.text = resolved_speaker_name
	text_label.text = DialogueVariableResolver.resolve_text(line.text, context)

	_apply_line_portrait(line, speaker_id)

	text_label.visible_characters = 0

	if current_tween:
		current_tween.kill()

	current_tween = create_tween()
	var text_length: int = text_label.text.length()
	var duration: float = text_length * type_speed
	current_tween.tween_property(text_label, "visible_characters", text_length, duration)

func _apply_line_portrait(line: DialogueLine, speaker_id: String) -> void:
	_hide_all_portraits()
	var portrait: Texture2D = _resolve_line_portrait(line, speaker_id)
	if portrait == null:
		return
	if _is_protagonist_speaker(speaker_id):
		if portrait_right_rect != null:
			portrait_right_rect.texture = portrait
			portrait_right_rect.show()
	else:
		if portrait_left_rect != null:
			portrait_left_rect.texture = portrait
			portrait_left_rect.show()

func _hide_all_portraits() -> void:
	if portrait_left_rect != null:
		portrait_left_rect.hide()
	if portrait_right_rect != null:
		portrait_right_rect.hide()

func _is_protagonist_speaker(speaker_id: String) -> bool:
	var clean_id: String = speaker_id.strip_edges()
	return (
		clean_id == ProtagonistManager.PROTAGONIST_ID
		or CharacterDatabase.is_protagonist(clean_id)
	)

## 半身立繪：行內差分 > CharacterDatabase 立繪 > 設施 NPC
func _resolve_line_portrait(line: DialogueLine, speaker_id: String) -> Texture2D:
	if line.speaker_portrait != null:
		return line.speaker_portrait
	if line.speaker_avatar != null:
		return line.speaker_avatar
	var clean_id: String = speaker_id.strip_edges()
	if clean_id != "":
		var portrait: Texture2D = CharacterDatabase.get_portrait(clean_id)
		if portrait != null:
			return portrait
		if _is_protagonist_speaker(clean_id):
			return null
		return CharacterDatabase.get_avatar(clean_id)
	if _npc_context == null:
		return null
	if _npc_context.portrait != null:
		return _npc_context.portrait
	if _npc_context.avatar != null:
		return _npc_context.avatar
	if _npc_context.type == NPCResource.NPCType.STORY:
		return GameUiTheme.make_placeholder_avatar(_npc_context.npc_name)
	return null

func _on_overlay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_advance_dialogue()

func _advance_dialogue() -> void:
	if current_tween and current_tween.is_running():
		current_tween.kill()
		text_label.visible_characters = text_label.text.length()
		return

	current_line_index += 1
	if current_line_index >= current_sequence.lines.size():
		dialogue_finished.emit()
		queue_free()
	else:
		show_current_line()
