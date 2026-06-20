class_name ArtistProfileResource
extends Resource

## 人物檔案：純展示／台詞用，不參與能力結算、不影響劇情判定。
## 與 ArtistResource 核心數值分開；同一藝人 .tres 以 character_profile 引用本資源。

@export_group("基本檔案")
@export_range(0, 120) var age: int = 0 ## 0 表示未設定
@export_range(0, 250) var height_cm: int = 0 ## 身高（公分）
@export_range(0, 200) var weight_kg: int = 0 ## 體重（公斤）

@export_group("三圍（公分）")
@export_range(0, 200) var bust_cm: int = 0
@export_range(0, 200) var waist_cm: int = 0
@export_range(0, 200) var hip_cm: int = 0

@export_group("人物小傳")
@export_multiline var likes: String = "" ## 喜歡的事情
@export_multiline var dislikes: String = "" ## 討厭的事情
@export_multiline var development_goal: String = "" ## 發展目標

func has_any_content() -> bool:
	return (
		age > 0
		or height_cm > 0
		or weight_kg > 0
		or bust_cm > 0
		or waist_cm > 0
		or hip_cm > 0
		or likes.strip_edges() != ""
		or dislikes.strip_edges() != ""
		or development_goal.strip_edges() != ""
	)

func format_age() -> String:
	if age <= 0:
		return "—"
	return "%d 歲" % age

func format_height() -> String:
	if height_cm <= 0:
		return "—"
	return "%d cm" % height_cm

func format_weight() -> String:
	if weight_kg <= 0:
		return "—"
	return "%d kg" % weight_kg

func format_measurements() -> String:
	if bust_cm <= 0 and waist_cm <= 0 and hip_cm <= 0:
		return "—"
	return "%d / %d / %d" % [bust_cm, waist_cm, hip_cm]

func get_likes_text() -> String:
	return _normalize_text(likes)

func get_dislikes_text() -> String:
	return _normalize_text(dislikes)

func get_development_goal_text() -> String:
	return _normalize_text(development_goal)

func get_summary_lines() -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	if age > 0:
		lines.append("年齡：%s" % format_age())
	if height_cm > 0:
		lines.append("身高：%s" % format_height())
	if weight_kg > 0:
		lines.append("體重：%s" % format_weight())
	if bust_cm > 0 or waist_cm > 0 or hip_cm > 0:
		lines.append("三圍：%s" % format_measurements())
	if get_likes_text() != "—":
		lines.append("喜歡：%s" % get_likes_text())
	if get_dislikes_text() != "—":
		lines.append("討厭：%s" % get_dislikes_text())
	if get_development_goal_text() != "—":
		lines.append("目標：%s" % get_development_goal_text())
	return lines

func get_dialogue_replacements() -> Dictionary:
	return {
		"artist_age": format_age(),
		"artist_height": format_height(),
		"artist_weight": format_weight(),
		"artist_measurements": format_measurements(),
		"artist_bwh": format_measurements(),
		"artist_likes": get_likes_text(),
		"artist_dislikes": get_dislikes_text(),
		"artist_goal": get_development_goal_text(),
		"artist_development_goal": get_development_goal_text(),
	}

func _normalize_text(value: String) -> String:
	var text: String = value.strip_edges()
	if text == "":
		return "—"
	return text.replace("\n", " ")
