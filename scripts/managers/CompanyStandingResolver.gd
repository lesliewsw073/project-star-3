class_name CompanyStandingResolver
extends RefCounted

## 公司聲望／口碑結算規則（通告、活動、新聞、會議互動共用）。

static func apply_job_completion(quality: int, job_name: String) -> Dictionary:
	var rep_delta: int = 0
	var opinion_delta: int = 0
	match quality:
		CompletionQuality.Level.PERFECT:
			rep_delta = 8
			opinion_delta = 5
		CompletionQuality.Level.SUCCESS:
			rep_delta = 4
			opinion_delta = 2
		_:
			return _empty_result()
	return apply_deltas(rep_delta, opinion_delta, "通告殺青：%s" % job_name)

static func apply_job_failure(job_name: String, reason: String) -> Dictionary:
	return apply_deltas(-3, -8, "通告失敗：%s（%s）" % [job_name, reason])

static func apply_activity_completion(activity_kind: String, quality: int, activity_name: String) -> Dictionary:
	if not CompletionQuality.is_successful(quality):
		return apply_activity_failure(activity_kind, activity_name)
	var rep_delta: int = 1 if quality == CompletionQuality.Level.PERFECT else 0
	var opinion_delta: int = 2 if quality == CompletionQuality.Level.PERFECT else 1
	return apply_deltas(rep_delta, opinion_delta, "%s完成：%s" % [activity_kind, activity_name])

static func apply_activity_failure(activity_kind: String, activity_name: String) -> Dictionary:
	return apply_deltas(0, -2, "%s失敗：%s" % [activity_kind, activity_name])

static func apply_news_standing(category: int, importance: int) -> Dictionary:
	var rep_delta: int = 0
	var opinion_delta: int = 0
	match category:
		NewsManager.NewsCategory.SCANDAL:
			opinion_delta = -10
			if importance >= NewsManager.Importance.HIGH:
				opinion_delta = -15
		NewsManager.NewsCategory.AWARD:
			rep_delta = 6
			opinion_delta = 4
		NewsManager.NewsCategory.COMPANY:
			opinion_delta = 1
		NewsManager.NewsCategory.JOB:
			if importance >= NewsManager.Importance.HIGH:
				rep_delta = 2
				opinion_delta = 1
		_:
			return _empty_result()
	if rep_delta == 0 and opinion_delta == 0:
		return _empty_result()
	return apply_deltas(rep_delta, opinion_delta, "新聞輿情")

static func apply_meeting_renew(artist_name: String) -> Dictionary:
	return apply_deltas(2, 3, "週日會議續約：%s" % artist_name)

static func apply_meeting_terminate(artist_name: String) -> Dictionary:
	return apply_deltas(-2, -12, "解約：%s" % artist_name)

static func apply_deltas(rep_delta: int, opinion_delta: int, reason: String) -> Dictionary:
	if rep_delta > 0:
		PlayerManager.add_reputation(rep_delta, reason)
	elif rep_delta < 0:
		PlayerManager.reduce_reputation(-rep_delta, reason)
	if opinion_delta > 0:
		PlayerManager.add_public_opinion(opinion_delta, reason)
	elif opinion_delta < 0:
		PlayerManager.reduce_public_opinion(-opinion_delta, reason)
	return {
		"reputation_delta": rep_delta,
		"public_opinion_delta": opinion_delta,
		"current_reputation": PlayerManager.company_reputation,
		"current_public_opinion": PlayerManager.company_public_opinion,
		"reason": reason,
	}

static func _empty_result() -> Dictionary:
	return {
		"reputation_delta": 0,
		"public_opinion_delta": 0,
		"current_reputation": PlayerManager.company_reputation,
		"current_public_opinion": PlayerManager.company_public_opinion,
		"reason": "",
	}
