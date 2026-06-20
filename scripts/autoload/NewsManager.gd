extends Node

signal news_added(news_item: Dictionary)
signal news_feed_changed()
signal daily_edition_ready(edition: Array)

enum MediaType {
	PAPER,
	STREAMING,
	TEXT_MEDIA,
}

enum NewsCategory {
	COMPANY,
	ARTIST,
	JOB,
	AUDITION,
	AWARD,
	RELEASE,
	SCANDAL,
	INDUSTRY,
}

enum Importance {
	LOW,
	NORMAL,
	HIGH,
	BREAKING,
}

## 當日頭條類型（對應企劃九類）。
enum EditionType {
	TABLOID,
	PRESS_COVERAGE,
	AWARD_PREVIEW,
	ARTIST_DEBUT,
	MAJOR_JOB_PREVIEW,
	MAJOR_JOB_WRAP,
	MAJOR_JOB_HIT,
	SPECIAL_EVENT,
	FILLER,
}

enum ImageKind {
	NONE,
	PORTRAIT,
	CG,
	GENERIC,
	JOB,
	AWARD,
}

const MAX_NEWS_ITEMS: int = 200
const MAX_DAILY_EDITION_SLOTS: int = 6

var news_feed: Array[Dictionary] = []
var _next_news_serial: int = 1

var _daily_edition: Array[Dictionary] = []
var _edition_date_key: String = ""
var _edition_shown_date_key: String = ""

var _queued_edition_items: Array[Dictionary] = []
var _major_job_items: Array[Dictionary] = []
var _special_event_items: Array[Dictionary] = []
var _used_once_template_ids: Dictionary = {}
var _filler_templates: Array[NewsTemplateResource] = []

func _ready() -> void:
	_load_filler_templates()
	print("[NewsManager] 就绪。")

func _load_filler_templates() -> void:
	_filler_templates.clear()
	var dir := DirAccess.open("res://data/news/templates/")
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var loaded: Resource = load("res://data/news/templates/%s" % file_name)
			if loaded is NewsTemplateResource:
				_filler_templates.append(loaded)
		file_name = dir.get_next()
	dir.list_dir_end()

func build_daily_edition_for_today(force: bool = false) -> Array[Dictionary]:
	var date_key: String = _make_date_key(TimeManager.get_date_snapshot())
	if not force and date_key == _edition_date_key and not _daily_edition.is_empty():
		return _daily_edition.duplicate(true)

	_edition_date_key = date_key
	_daily_edition = NewsEditionBuilder.build_for_today({
		"date_snapshot": TimeManager.get_date_snapshot(),
		"queued_items": _queued_edition_items.duplicate(true),
		"major_job_items": _major_job_items.duplicate(true),
		"special_event_items": _special_event_items.duplicate(true),
		"filler_templates": _filler_templates,
		"used_once_template_ids": _used_once_template_ids,
	})
	_queued_edition_items.clear()
	_major_job_items.clear()
	_special_event_items.clear()
	if not _daily_edition.is_empty():
		daily_edition_ready.emit(_daily_edition.duplicate(true))
	return _daily_edition.duplicate(true)

func has_daily_edition_for_today() -> bool:
	var date_key: String = _make_date_key(TimeManager.get_date_snapshot())
	if date_key != _edition_date_key:
		build_daily_edition_for_today()
	return not _daily_edition.is_empty() and _edition_shown_date_key != date_key

func get_daily_edition() -> Array[Dictionary]:
	return _daily_edition.duplicate(true)

func mark_daily_edition_shown() -> void:
	_edition_shown_date_key = _edition_date_key
	for item in _daily_edition:
		_commit_edition_item_to_feed(item)

func queue_edition_item(item: Dictionary) -> void:
	if item.is_empty():
		return
	_queued_edition_items.append(item.duplicate(true))

func queue_tabloid_story(
	title: String,
	body: String,
	options: Dictionary = {}
) -> void:
	var merged: Dictionary = options.duplicate(true)
	merged["reporter_id"] = ReporterManager.get_paparazzi_id()
	merged["category"] = NewsCategory.SCANDAL
	merged["importance"] = Importance.HIGH
	if not merged.has("image_kind"):
		merged["image_kind"] = ImageKind.CG if str(merged.get("cg_id", "")) != "" else ImageKind.PORTRAIT
	queue_edition_item(make_edition_item(EditionType.TABLOID, title, body, merged))

func queue_artist_debut_news(artist_id: String) -> void:
	var artist_name: String = CharacterDatabase.get_display_name(artist_id)
	var agency_name: String = ArtistManager.get_artist_agency_name(artist_id)
	if agency_name == "":
		agency_name = PlayerManager.get_company_name()
	queue_edition_item(
		make_edition_item(
			EditionType.ARTIST_DEBUT,
			"【出道】%s 正式亮相" % artist_name,
			"%s 已掛牌 %s，業界關注其後續動向。" % [artist_name, agency_name],
			{
				"related_artist_id": artist_id,
				"category": NewsCategory.ARTIST,
				"importance": Importance.HIGH,
				"image_kind": ImageKind.PORTRAIT,
			}
		)
	)

func queue_major_job_preview(job_resource: JobResource) -> void:
	if job_resource == null or not job_resource.is_major_job:
		return
	var company_name: String = CompanyDatabase.get_publisher_name(job_resource.target_company_id)
	queue_edition_item(
		make_edition_item(
			EditionType.MAJOR_JOB_PREVIEW,
			"【預熱】%s 即將開案" % job_resource.job_name,
			"%s 宣布籌備 %s，業界預期將成為本季重點項目。" % [company_name, job_resource.job_name],
			{
				"related_job_id": job_resource.job_id,
				"related_company_id": job_resource.target_company_id,
				"category": NewsCategory.JOB,
				"importance": Importance.HIGH,
				"image_kind": ImageKind.JOB,
			}
		)
	)

func queue_major_job_wrap(job_id: String, job_name: String, company_id: String, artist_id: String = "") -> void:
	queue_edition_item(
		make_edition_item(
			EditionType.MAJOR_JOB_WRAP,
			"【殺青】%s 順利殺青" % job_name,
			"%s 確認殺青，後期製作時程同步公開。" % job_name,
			{
				"related_job_id": job_id,
				"related_company_id": company_id,
				"related_artist_id": artist_id,
				"reporter_id": ReporterManager.get_press_reporter_id(),
				"category": NewsCategory.RELEASE,
				"importance": Importance.HIGH,
				"image_kind": ImageKind.JOB,
			}
		)
	)

func queue_major_job_hit(job_id: String, job_name: String, company_id: String) -> void:
	queue_edition_item(
		make_edition_item(
			EditionType.MAJOR_JOB_HIT,
			"【大熱】%s 口碑發酵" % job_name,
			"%s 上線後反應熱烈，相關話題持續占據版面。" % job_name,
			{
				"related_job_id": job_id,
				"related_company_id": company_id,
				"reporter_id": ReporterManager.get_press_reporter_id(),
				"category": NewsCategory.RELEASE,
				"importance": Importance.BREAKING,
				"image_kind": ImageKind.JOB,
			}
		)
	)

func queue_special_event(title: String, body: String, options: Dictionary = {}) -> void:
	var merged: Dictionary = options.duplicate(true)
	if not merged.has("category"):
		merged["category"] = NewsCategory.INDUSTRY
	if not merged.has("importance"):
		merged["importance"] = Importance.NORMAL
	_special_event_items.append(make_edition_item(EditionType.SPECIAL_EVENT, title, body, merged))

func make_edition_item(
	edition_type: int,
	title: String,
	body: String,
	options: Dictionary = {}
) -> Dictionary:
	var item: Dictionary = {
		"edition_type": edition_type,
		"edition_type_name": get_edition_type_name(edition_type),
		"title": title,
		"body": body,
		"reporter_id": str(options.get("reporter_id", "")),
		"related_artist_id": str(options.get("related_artist_id", "")),
		"related_company_id": str(options.get("related_company_id", "")),
		"related_job_id": str(options.get("related_job_id", "")),
		"category": int(options.get("category", NewsCategory.INDUSTRY)),
		"importance": int(options.get("importance", Importance.NORMAL)),
		"image_kind": int(options.get("image_kind", ImageKind.GENERIC)),
		"image_owner_id": str(options.get("image_owner_id", "")),
		"cg_id": str(options.get("cg_id", "")),
		"image_path": str(options.get("image_path", "")),
	}
	if item["image_owner_id"] == "" and item["related_artist_id"] != "":
		item["image_owner_id"] = item["related_artist_id"]
	if item["reporter_id"] == "" and edition_type == EditionType.TABLOID:
		item["reporter_id"] = ReporterManager.get_paparazzi_id()
	if item["reporter_id"] == "" and edition_type in [
		EditionType.PRESS_COVERAGE,
		EditionType.AWARD_PREVIEW,
		EditionType.MAJOR_JOB_WRAP,
		EditionType.MAJOR_JOB_HIT,
	]:
		item["reporter_id"] = ReporterManager.get_press_reporter_id()
	return item

func resolve_edition_image_texture(item: Dictionary) -> Texture2D:
	var image_path: String = str(item.get("image_path", ""))
	if image_path != "":
		return CharacterVisualPaths.try_load_texture(image_path)
	var owner_id: String = str(item.get("image_owner_id", item.get("related_artist_id", "")))
	var image_kind: int = int(item.get("image_kind", ImageKind.GENERIC))
	match image_kind:
		ImageKind.CG:
			return CharacterDatabase.get_cg_texture(owner_id, str(item.get("cg_id", "")))
		ImageKind.PORTRAIT:
			if owner_id != "":
				return CharacterDatabase.get_portrait(owner_id)
		ImageKind.JOB, ImageKind.GENERIC, ImageKind.AWARD:
			if owner_id != "":
				return CharacterDatabase.get_avatar(owner_id)
	var reporter_id: String = str(item.get("reporter_id", ""))
	if reporter_id != "":
		return ReporterManager.get_avatar(reporter_id)
	return null

func add_news(
	title: String,
	body: String,
	media_type: int = MediaType.TEXT_MEDIA,
	category: int = NewsCategory.INDUSTRY,
	importance: int = Importance.NORMAL,
	related_artist_id: String = "",
	related_company_id: String = "",
	related_job_id: String = ""
) -> Dictionary:
	if title.strip_edges() == "":
		push_warning("[NewsManager] 新闻标题为空，已跳过。")
		return {}

	var date_snapshot: Dictionary = TimeManager.get_date_snapshot()
	var news_item: Dictionary = {
		"news_id": _make_news_id(),
		"title": title,
		"body": body,
		"media_type": media_type,
		"media_name": get_media_type_name(media_type),
		"category": category,
		"category_name": get_category_name(category),
		"importance": importance,
		"importance_name": get_importance_name(importance),
		"date": date_snapshot.duplicate(true),
		"date_text": date_snapshot["display_text"],
		"related_artist_id": related_artist_id,
		"related_company_id": related_company_id,
		"related_job_id": related_job_id,
		"read": false,
	}

	news_feed.push_front(news_item)
	_trim_feed()
	_apply_news_standing(news_item)

	news_added.emit(news_item)
	news_feed_changed.emit()
	print("[NewsManager] 新增新闻：%s" % title)
	return news_item

func add_company_news(title: String, body: String, importance: int = Importance.NORMAL) -> Dictionary:
	return add_news(title, body, MediaType.TEXT_MEDIA, NewsCategory.COMPANY, importance)

func add_audition_news(title: String, body: String, importance: int = Importance.NORMAL) -> Dictionary:
	return add_news(title, body, MediaType.STREAMING, NewsCategory.AUDITION, importance)

func get_recent_news(limit: int = 10) -> Array[Dictionary]:
	var safe_limit: int = clampi(limit, 0, news_feed.size())
	return news_feed.slice(0, safe_limit)

func get_news_by_category(category: int, limit: int = 20) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for item in news_feed:
		if item["category"] == category:
			results.append(item)
			if results.size() >= limit:
				break
	return results

func mark_read(news_id: String) -> bool:
	for item in news_feed:
		if item["news_id"] == news_id:
			item["read"] = true
			news_feed_changed.emit()
			return true
	return false

func get_unread_count() -> int:
	var count: int = 0
	for item in news_feed:
		if not item["read"]:
			count += 1
	return count

func clear_all_news() -> void:
	news_feed.clear()
	news_feed_changed.emit()

func export_save_state() -> Dictionary:
	return {
		"next_news_serial": _next_news_serial,
		"news_feed": news_feed.duplicate(true),
		"daily_edition": _daily_edition.duplicate(true),
		"edition_date_key": _edition_date_key,
		"edition_shown_date_key": _edition_shown_date_key,
		"used_once_template_ids": _used_once_template_ids.duplicate(true),
	}

func import_save_state(data: Dictionary) -> void:
	_next_news_serial = int(data.get("next_news_serial", 1))
	news_feed = []
	for item in data.get("news_feed", []):
		if item is Dictionary:
			news_feed.append(item.duplicate(true))
	_daily_edition = []
	for item in data.get("daily_edition", []):
		if item is Dictionary:
			_daily_edition.append(item.duplicate(true))
	_edition_date_key = str(data.get("edition_date_key", ""))
	_edition_shown_date_key = str(data.get("edition_shown_date_key", ""))
	_used_once_template_ids = data.get("used_once_template_ids", {}).duplicate(true)
	news_feed_changed.emit()

static func get_edition_type_name(edition_type: int) -> String:
	match edition_type:
		EditionType.TABLOID:
			return "狗仔"
		EditionType.PRESS_COVERAGE:
			return "正面採訪"
		EditionType.AWARD_PREVIEW:
			return "頒獎預熱"
		EditionType.ARTIST_DEBUT:
			return "藝人出道"
		EditionType.MAJOR_JOB_PREVIEW:
			return "重大通告預熱"
		EditionType.MAJOR_JOB_WRAP:
			return "重大通告殺青"
		EditionType.MAJOR_JOB_HIT:
			return "重大通告大熱"
		EditionType.SPECIAL_EVENT:
			return "特殊事件"
		EditionType.FILLER:
			return "綜合"
		_:
			return "新聞"

func get_media_type_name(media_type: int) -> String:
	match media_type:
		MediaType.PAPER:
			return "紙媒"
		MediaType.STREAMING:
			return "流媒體"
		MediaType.TEXT_MEDIA:
			return "文字媒體"
		_:
			return "未知媒體"

func get_category_name(category: int) -> String:
	match category:
		NewsCategory.COMPANY:
			return "公司"
		NewsCategory.ARTIST:
			return "藝人"
		NewsCategory.JOB:
			return "通告"
		NewsCategory.AUDITION:
			return "選秀"
		NewsCategory.AWARD:
			return "獎項"
		NewsCategory.RELEASE:
			return "作品發布"
		NewsCategory.SCANDAL:
			return "醜聞"
		NewsCategory.INDUSTRY:
			return "業界"
		_:
			return "未分類"

func get_importance_name(importance: int) -> String:
	match importance:
		Importance.LOW:
			return "低"
		Importance.NORMAL:
			return "一般"
		Importance.HIGH:
			return "重要"
		Importance.BREAKING:
			return "速報"
		_:
			return "未知"

func _commit_edition_item_to_feed(item: Dictionary) -> void:
	add_news(
		str(item.get("title", "")),
		str(item.get("body", "")),
		MediaType.TEXT_MEDIA,
		int(item.get("category", NewsCategory.INDUSTRY)),
		int(item.get("importance", Importance.NORMAL)),
		str(item.get("related_artist_id", "")),
		str(item.get("related_company_id", "")),
		str(item.get("related_job_id", "")),
	)

func _make_news_id() -> String:
	var news_id: String = "news_%06d" % _next_news_serial
	_next_news_serial += 1
	return news_id

func _make_date_key(date_snapshot: Dictionary) -> String:
	return "%04d-%02d-%02d" % [
		int(date_snapshot.get("year", 0)),
		int(date_snapshot.get("month", 0)),
		int(date_snapshot.get("day_of_month", 0)),
	]

func _trim_feed() -> void:
	while news_feed.size() > MAX_NEWS_ITEMS:
		news_feed.pop_back()

func _apply_news_standing(news_item: Dictionary) -> void:
	var category: int = int(news_item.get("category", NewsCategory.INDUSTRY))
	if category not in [NewsCategory.SCANDAL, NewsCategory.AWARD, NewsCategory.COMPANY]:
		return
	var importance: int = int(news_item.get("importance", Importance.NORMAL))
	var standing: Dictionary = CompanyStandingResolver.apply_news_standing(category, importance)
	if int(standing.get("reputation_delta", 0)) == 0 and int(standing.get("public_opinion_delta", 0)) == 0:
		return
	news_item["standing"] = standing
