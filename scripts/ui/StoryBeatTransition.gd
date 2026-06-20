class_name StoryBeatTransition
extends CanvasLayer

## 簽約後場景銜接：CG 背景 → 畫面變暗 → 音效提示 → 再接下一則劇情。

signal finished

const LAYER_ORDER := 45
const FADE_IN_SEC := 0.55
const FADE_OUT_SEC := 0.45
const BEAT_HOLD_SEC := 0.75

var _overlay: ColorRect
var _cg_rect: TextureRect
var _beat_label: Label
var _busy: bool = false
var _cg_owner_id: String = ""
var _cg_id: String = ""

func _ready() -> void:
	layer = LAYER_ORDER
	_build_ui()

func play_artist_003_tv_preface_bridge() -> void:
	if _busy:
		return
	_busy = true
	_cg_rect.hide()
	_run_tv_preface()

func play_artist_003_sign_to_day1_bridge(
	cg_owner_id: String = "artist_003",
	cg_id: String = "sign_knock_office"
) -> void:
	if _busy:
		return
	_busy = true
	_cg_owner_id = cg_owner_id.strip_edges()
	_cg_id = cg_id.strip_edges()
	_apply_cg_background()
	_run_bridge()

func _build_ui() -> void:
	_cg_rect = TextureRect.new()
	_cg_rect.name = "CgBackground"
	_cg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_cg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cg_rect.visible = false
	add_child(_cg_rect)

	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.02, 0.02, 0.04, 0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	_beat_label = Label.new()
	_beat_label.set_anchors_preset(Control.PRESET_CENTER)
	_beat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_beat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_beat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_beat_label.custom_minimum_size = Vector2(360, 0)
	_beat_label.visible = false
	GameUiTheme.style_label(_beat_label, GameUiTheme.COLOR_MUTED, GameUiTheme.FONT_SECTION)
	add_child(_beat_label)

func _apply_cg_background() -> void:
	if _cg_rect == null:
		return
	var texture: Texture2D = CharacterDatabase.get_cg_texture(_cg_owner_id, _cg_id)
	if texture != null:
		_cg_rect.texture = texture
		_cg_rect.show()
	else:
		_cg_rect.hide()

func _run_tv_preface() -> void:
	await _fade_overlay(0.85, FADE_IN_SEC)
	await _show_beat("電視正在轉播一場體育賽事。\n女主播（米語）的聲音與形象，讓人眼前一亮。")
	await _show_beat("你立刻讓小唯打電話給電視台，詢問聯絡方式，發起邀約。")
	await _show_beat("（隔了一天）")
	await _fade_overlay(0.0, FADE_OUT_SEC)
	_busy = false
	finished.emit()
	queue_free()

func _run_bridge() -> void:
	await _fade_overlay(0.72, FADE_IN_SEC)
	await _show_beat("（敲門聲三下）")
	await _show_beat("（門被直接推開）")
	await _fade_overlay(0.35, FADE_OUT_SEC)
	_busy = false
	finished.emit()
	queue_free()

func _fade_overlay(target_alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", target_alpha, duration)
	await tween.finished

func _show_beat(text: String) -> void:
	_beat_label.text = text
	_beat_label.visible = true
	await get_tree().create_timer(BEAT_HOLD_SEC).timeout
	_beat_label.visible = false
