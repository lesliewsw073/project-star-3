class_name ArtistProfileDisplay
extends RefCounted

## 人物檔案 UI 文案組裝（只讀，不寫入 Manager）。

static func get_profile(resource: ArtistResource) -> ArtistProfileResource:
	if resource == null:
		return null
	return resource.get_character_profile()

static func build_detail_multiline(resource: ArtistResource) -> String:
	var profile: ArtistProfileResource = get_profile(resource)
	if profile == null or not profile.has_any_content():
		return "（檔案尚未填寫）"
	var lines: PackedStringArray = profile.get_summary_lines()
	if lines.is_empty():
		return "（檔案尚未填寫）"
	return "\n".join(lines)

static func build_detail_multiline_for_id(artist_id: String) -> String:
	var resource: ArtistResource = ArtistManager.get_artist_resource(artist_id)
	if resource == null:
		return "（查無此人）"
	return build_detail_multiline(resource)

static func build_compact_line(resource: ArtistResource) -> String:
	var profile: ArtistProfileResource = get_profile(resource)
	if profile == null or not profile.has_any_content():
		return ""
	var parts: PackedStringArray = PackedStringArray()
	if profile.age > 0:
		parts.append(profile.format_age())
	if profile.height_cm > 0:
		parts.append(profile.format_height())
	if profile.weight_kg > 0:
		parts.append(profile.format_weight())
	if profile.bust_cm > 0 or profile.waist_cm > 0 or profile.hip_cm > 0:
		parts.append("三圍 %s" % profile.format_measurements())
	if profile.get_likes_text() != "—":
		parts.append("喜歡：%s" % profile.get_likes_text())
	if profile.get_development_goal_text() != "—":
		parts.append("目標：%s" % profile.get_development_goal_text())
	return " · ".join(parts)

static func build_roster_sidebar_text() -> String:
	var signed_ids: Array = ArtistManager.get_signed_ids()
	if signed_ids.is_empty():
		return ""
	var blocks: PackedStringArray = PackedStringArray()
	for artist_id in signed_ids:
		var artist_id_text: String = str(artist_id)
		var resource: ArtistResource = ArtistManager.get_artist_resource(artist_id_text)
		if resource == null:
			continue
		var compact: String = build_compact_line(resource)
		if compact == "":
			continue
		blocks.append("・%s：%s" % [resource.artist_name, compact])
	if blocks.is_empty():
		return ""
	return "\n".join(blocks)

static func populate_labels(
	container: VBoxContainer,
	resource: ArtistResource,
	include_title: bool = false
) -> void:
	if container == null or resource == null:
		return
	for child in container.get_children():
		child.queue_free()

	if include_title:
		var title := GameUiTheme.make_section_label("人物檔案", GameUiTheme.COLOR_GOLD)
		container.add_child(title)

	var profile: ArtistProfileResource = get_profile(resource)
	if profile == null or not profile.has_any_content():
		var empty := Label.new()
		empty.text = "（檔案尚未填寫）"
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		GameUiTheme.style_label(empty, GameUiTheme.COLOR_MUTED, GameUiTheme.FONT_HINT)
		container.add_child(empty)
		return

	for line in profile.get_summary_lines():
		var label := Label.new()
		label.text = line
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		GameUiTheme.style_label(label, GameUiTheme.COLOR_TEXT, GameUiTheme.FONT_HINT)
		container.add_child(label)
