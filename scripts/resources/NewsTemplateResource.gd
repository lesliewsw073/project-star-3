class_name NewsTemplateResource
extends Resource

## 填充類新聞模板（天氣、度假、課程等）。

@export var template_id: String = ""
@export var title: String = ""
@export_multiline var body: String = ""
@export var category: int = 7 ## NewsManager.NewsCategory.INDUSTRY
@export var importance: int = 0 ## NewsManager.Importance.LOW
@export var repeat_allowed: bool = true
@export_range(0, 12) var month_min: int = 0 ## 0 = 不限
@export_range(0, 12) var month_max: int = 0 ## 0 = 不限
@export var is_test_content: bool = true

func matches_month(game_month: int) -> bool:
	if month_min <= 0 and month_max <= 0:
		return true
	if month_min > 0 and game_month < month_min:
		return false
	if month_max > 0 and game_month > month_max:
		return false
	return true
