class_name GameUiTheme
extends RefCounted

## 與 GameRoot 會議／日常面板一致的緊湊 UI 主題。

const COLOR_PANEL := Color(0.16, 0.15, 0.21, 0.94)
const COLOR_BLOCK := Color(0.22, 0.24, 0.32, 1.0)
const COLOR_BLOCK_ACCENT := Color(0.26, 0.20, 0.34, 1.0)
const COLOR_OVERLAY := Color(0.04, 0.05, 0.08, 0.72)
const COLOR_BORDER := Color(0.38, 0.42, 0.52, 0.55)
const COLOR_TEXT := Color(0.92, 0.93, 0.96, 1.0)
const COLOR_MUTED := Color(0.62, 0.66, 0.74, 1.0)
const COLOR_GOLD := Color(0.96, 0.78, 0.36, 1.0)
const COLOR_PRIMARY := Color(0.32, 0.52, 0.82, 1.0)
const COLOR_NAV := Color(0.28, 0.58, 0.54, 1.0)
const COLOR_WARM := Color(0.72, 0.48, 0.28, 1.0)
const COLOR_SUCCESS := Color(0.28, 0.68, 0.46, 1.0)
const COLOR_DANGER := Color(0.72, 0.30, 0.36, 1.0)

const BTN_HEIGHT := 32
const BTN_HEIGHT_SM := 28
const FONT_BODY := 16
const FONT_HINT := 14
const FONT_SECTION := 18
const FONT_TITLE := 24
const SEP := 8
const PAD := 10


static func make_stylebox(
	bg: Color,
	border: Color = COLOR_BORDER,
	border_width: int = 1,
	radius: int = 6,
	margin: int = PAD
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_top = margin
	style.content_margin_right = margin
	style.content_margin_bottom = margin
	return style


static func style_panel(panel: PanelContainer, bg: Color, border: Color = COLOR_BORDER) -> void:
	panel.add_theme_stylebox_override("panel", make_stylebox(bg, border))


static func style_panel_node(panel: Panel, bg: Color, border: Color = COLOR_BORDER) -> void:
	panel.add_theme_stylebox_override("panel", make_stylebox(bg, border))


static func style_button(button: Button, bg: Color, font_size: int = FONT_BODY) -> void:
	if button == null:
		return
	var hover := bg.lightened(0.10)
	button.add_theme_stylebox_override("normal", make_stylebox(bg, bg.lightened(0.18), 1, 4, 4))
	button.add_theme_stylebox_override("hover", make_stylebox(hover, hover.lightened(0.18), 1, 4, 4))
	button.add_theme_stylebox_override("pressed", make_stylebox(bg.darkened(0.08), bg.lightened(0.12), 1, 4, 4))
	button.add_theme_stylebox_override("disabled", make_stylebox(bg.darkened(0.22), bg.darkened(0.10), 1, 4, 4))
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_disabled_color", COLOR_MUTED)
	button.add_theme_font_size_override("font_size", font_size)


static func compact_button(button: Button, min_width: float = 0.0, height: int = BTN_HEIGHT) -> Button:
	if button == null:
		push_warning("[GameUiTheme] compact_button 收到 null。")
		return button
	if min_width > 0.0:
		button.custom_minimum_size.x = min_width
	button.custom_minimum_size.y = height
	return button


static func style_label(label: Label, color: Color = COLOR_TEXT, font_size: int = FONT_BODY) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)


static func style_rich_text_label(
	rich_label: RichTextLabel,
	color: Color = COLOR_TEXT,
	font_size: int = FONT_BODY
) -> void:
	rich_label.add_theme_color_override("default_color", color)
	rich_label.add_theme_font_size_override("normal_font_size", font_size)


static func make_section_label(text: String, accent: Color = COLOR_GOLD) -> Label:
	var label := Label.new()
	label.text = "◆ %s" % text
	label.add_theme_font_size_override("font_size", FONT_SECTION)
	label.add_theme_color_override("font_color", accent)
	return label


static func make_portrait_rect(texture: Texture2D, portrait_size: Vector2, label_fallback: String = "") -> TextureRect:
	var rect := TextureRect.new()
	rect.custom_minimum_size = portrait_size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if texture != null:
		rect.texture = texture
	elif label_fallback.strip_edges() != "":
		rect.texture = make_placeholder_avatar(label_fallback, int(portrait_size.x))
	return rect


static func make_placeholder_avatar(label_text: String, pixel_size: int = 128) -> ImageTexture:
	var image := Image.create(pixel_size, pixel_size, false, Image.FORMAT_RGBA8)
	var hash_value: int = absi(label_text.hash())
	var color := Color.from_hsv(float(hash_value % 360) / 360.0, 0.35, 0.72, 1.0)
	image.fill(color)
	return ImageTexture.create_from_image(image)
