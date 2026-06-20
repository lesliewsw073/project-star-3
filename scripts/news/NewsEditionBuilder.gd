class_name NewsEditionBuilder
extends RefCounted

## 組裝當日頭條版面（優先 1～8 類，剩餘槽位填 9 類）。

const MAX_SLOTS: int = 6

static func build_for_today(context: Dictionary) -> Array[Dictionary]:
	var edition: Array[Dictionary] = []
	var date_snapshot: Dictionary = context.get("date_snapshot", TimeManager.get_date_snapshot())
	var queued: Array = context.get("queued_items", [])
	var used_once_ids: Dictionary = context.get("used_once_template_ids", {})

	for item in queued:
		if edition.size() >= MAX_SLOTS:
			break
		if item is Dictionary and not item.is_empty():
			edition.append(item.duplicate(true))

	_append_award_previews(edition, date_snapshot)
	_append_award_ceremonies(edition, date_snapshot)
	_append_major_job_items(edition, context)
	_append_special_events(edition, context)
	_append_filler_items(edition, date_snapshot, context, used_once_ids)

	while edition.size() > MAX_SLOTS:
		edition.pop_back()
	return edition

static func _append_award_previews(edition: Array[Dictionary], date_snapshot: Dictionary) -> void:
	for award in AwardRegistry.get_preview_awards_for_date(date_snapshot):
		if edition.size() >= MAX_SLOTS:
			return
		var award_name: String = str(award.get("award_name", "年度獎項"))
		var candidates: Array[String] = AwardRegistry.build_preview_candidates(award)
		var body_lines: PackedStringArray = PackedStringArray()
		for index in range(candidates.size()):
			var agency_name: String = AgencyDatabase.get_agency_display_name(candidates[index])
			body_lines.append("%d. %s" % [index + 1, agency_name if agency_name != "" else candidates[index]])
		edition.append(
			NewsManager.make_edition_item(
				NewsManager.EditionType.AWARD_PREVIEW,
				"【預熱】%s 入圍名單出爐" % award_name,
				"\n".join(body_lines),
				{
					"reporter_id": ReporterManager.get_press_reporter_id(),
					"category": NewsManager.NewsCategory.AWARD,
					"importance": NewsManager.Importance.HIGH,
				}
			)
		)

static func _append_award_ceremonies(edition: Array[Dictionary], date_snapshot: Dictionary) -> void:
	for award in AwardRegistry.get_ceremony_awards_for_date(date_snapshot):
		if edition.size() >= MAX_SLOTS:
			return
		var award_name: String = str(award.get("award_name", "年度獎項"))
		var winners: Array = award.get("winners", [])
		var body_lines: PackedStringArray = PackedStringArray()
		for winner in winners:
			if winner is Dictionary:
				var company_id: String = str(winner.get("company_id", ""))
				var company_name: String = CompanyDatabase.get_publisher_name(company_id)
				if company_name == "":
					company_name = AgencyDatabase.get_agency_display_name(company_id)
				var winner_label: String = company_name if company_name != "" else company_id
				if company_id == AgencyDatabase.PLAYER_AGENCY_ID:
					winner_label = "★ %s" % PlayerManager.get_company_name()
				body_lines.append("%s：%s" % [str(winner.get("prize_name", "最佳")), winner_label])
		if body_lines.is_empty():
			body_lines.append("頒獎典禮圓滿落幕，各獎項得主已揭曉。")
		edition.append(
			NewsManager.make_edition_item(
				NewsManager.EditionType.PRESS_COVERAGE,
				"%s 頒獎結果" % award_name,
				"\n".join(body_lines),
				{
					"reporter_id": ReporterManager.get_press_reporter_id(),
					"category": NewsManager.NewsCategory.AWARD,
					"importance": NewsManager.Importance.BREAKING,
				}
			)
		)

static func _append_major_job_items(edition: Array[Dictionary], context: Dictionary) -> void:
	for item in context.get("major_job_items", []):
		if edition.size() >= MAX_SLOTS:
			return
		if item is Dictionary and not item.is_empty():
			edition.append(item.duplicate(true))

static func _append_special_events(edition: Array[Dictionary], context: Dictionary) -> void:
	for item in context.get("special_event_items", []):
		if edition.size() >= MAX_SLOTS:
			return
		if item is Dictionary and not item.is_empty():
			edition.append(item.duplicate(true))

static func _append_filler_items(
	edition: Array[Dictionary],
	date_snapshot: Dictionary,
	context: Dictionary,
	used_once_ids: Dictionary
) -> void:
	var templates: Array = context.get("filler_templates", [])
	if templates.is_empty():
		return
	var month: int = int(date_snapshot.get("month", 0))
	var candidates: Array[NewsTemplateResource] = []
	for template in templates:
		if template == null:
			continue
		if not template.matches_month(month):
			continue
		if not template.repeat_allowed and used_once_ids.has(template.template_id):
			continue
		candidates.append(template)
	candidates.shuffle()
	for template in candidates:
		if edition.size() >= MAX_SLOTS:
			return
		edition.append(
			NewsManager.make_edition_item(
				NewsManager.EditionType.FILLER,
				template.title,
				template.body,
				{
					"category": template.category,
					"importance": template.importance,
				}
			)
		)
		if not template.repeat_allowed:
			used_once_ids[template.template_id] = true
