class_name JobDayEvaluator
extends RefCounted

## 通告每日拍攝三档判定：失败 / 成功 / 完美
## 设计文档：docs/design/JOB_DAY_EVALUATOR.md

const SHOOT_STAT_RATIO: float = 0.90
const FAIL_FATIGUE_HARD: int = 85
const FAIL_STRESS_HARD: int = 76
const PERFECT_CAP: float = CompletionQuality.MAX_PERFECT_PROBABILITY

const ACCEPT_MODE_NORMAL: int = 0
const ACCEPT_MODE_INVITE: int = 1

const FLAG_JOB_FORCE_FAIL: String = "event.job_force_fail"
const FLAG_JOB_FORCE_FAIL_PREFIX: String = "event.job_force_fail."

## 邀请接案分数占位权重
const INVITE_W_REPUTATION: float = 0.4
const INVITE_W_OPINION: float = 0.3
const INVITE_W_FAME: float = 0.15
const INVITE_W_POPULARITY: float = 0.10
const INVITE_W_WORKS: float = 0.05
const DEFAULT_INVITE_THRESHOLD: int = 300

static func get_stat_names() -> Array[String]:
	return [
		"empathy", "timbre", "improvisation", "acting", "singing", "eloquence",
		"dynamism", "talent", "stamina", "deportment", "fashion", "confidence",
		"rebelliousness", "humor", "affinity", "fame", "popularity", "exposure", "morality",
	]

static func build_shoot_floor(req_value: int) -> int:
	return int(float(maxi(req_value, 0)) * SHOOT_STAT_RATIO)

static func build_accept_shoot_floors(job: JobResource) -> Dictionary:
	var floors: Dictionary = {}
	if job == null:
		return floors
	for stat_name in get_stat_names():
		var req: int = int(job.get("req_%s" % stat_name))
		if req > 0:
			floors[stat_name] = build_shoot_floor(req)
	return floors

static func build_accept_req_snapshot(job: JobResource) -> Dictionary:
	var snapshot: Dictionary = {}
	if job == null:
		return snapshot
	for stat_name in get_stat_names():
		var req: int = int(job.get("req_%s" % stat_name))
		if req > 0:
			snapshot[stat_name] = req
	return snapshot

static func calculate_invite_score(artist: ArtistInstance, completed_jobs: int = -1) -> float:
	if artist == null:
		return 0.0
	var works: int = completed_jobs
	if works < 0:
		works = PlayerManager.successful_jobs_count
	return (
		float(PlayerManager.company_reputation) * INVITE_W_REPUTATION
		+ float(PlayerManager.company_public_opinion) * INVITE_W_OPINION
		+ float(artist.fame) * INVITE_W_FAME
		+ float(artist.popularity) * INVITE_W_POPULARITY
		+ float(works) * INVITE_W_WORKS
	)

static func can_invite_accept(artist: ArtistInstance, invite_threshold: int = DEFAULT_INVITE_THRESHOLD) -> bool:
	return calculate_invite_score(artist) >= float(invite_threshold)

static func evaluate_shoot_day(artist: ArtistInstance, job_instance: JobInstance) -> Dictionary:
	if artist == null or job_instance == null or job_instance.base_job == null:
		return _result(CompletionQuality.Level.FAILED, "invalid_input", {}, 0.0, 0.0)

	var job: JobResource = job_instance.base_job
	if _has_forced_fail_event(job.job_id):
		return _result(CompletionQuality.Level.FAILED, "forced_event", {}, 0.0, 0.0)

	var state_block: String = _get_state_hard_fail_reason(artist, job)
	if state_block != "":
		return _result(CompletionQuality.Level.FAILED, state_block, {}, 0.0, 0.0)

	var stat_eval: Dictionary = _evaluate_stat_layer(artist, job_instance)
	if not bool(stat_eval.get("stat_pass", false)):
		return _result(
			CompletionQuality.Level.FAILED,
			"stat_below_shoot_floor",
			stat_eval,
			0.0,
			0.0
		)

	var fatigue: int = artist.health.fatigue
	var stress: int = artist.mood.stress
	var body_factor: float = _calculate_body_factor(fatigue, stress)
	var p_fail: float = _calculate_fail_probability(artist, body_factor)
	if p_fail > 0.0 and randf() < p_fail:
		return _result(
			CompletionQuality.Level.FAILED,
			"trait_or_mood_roll",
			stat_eval,
			p_fail,
			0.0
		)

	var p_perfect: float = _calculate_perfect_probability(artist, stat_eval, fatigue, stress, body_factor)
	var quality: int = CompletionQuality.Level.SUCCESS
	if p_perfect > 0.0 and randf() <= p_perfect:
		quality = CompletionQuality.Level.PERFECT

	return _result(quality, "ok", stat_eval, p_fail, p_perfect)

static func evaluate_shoot_day_deterministic(
	artist: ArtistInstance,
	job_instance: JobInstance,
	rng_roll_fail: float,
	rng_roll_perfect: float
) -> Dictionary:
	if artist == null or job_instance == null or job_instance.base_job == null:
		return _result(CompletionQuality.Level.FAILED, "invalid_input", {}, 0.0, 0.0)

	var job: JobResource = job_instance.base_job
	if _has_forced_fail_event(job.job_id):
		return _result(CompletionQuality.Level.FAILED, "forced_event", {}, 0.0, 0.0)

	var state_block: String = _get_state_hard_fail_reason(artist, job)
	if state_block != "":
		return _result(CompletionQuality.Level.FAILED, state_block, {}, 0.0, 0.0)

	var stat_eval: Dictionary = _evaluate_stat_layer(artist, job_instance)
	if not bool(stat_eval.get("stat_pass", false)):
		return _result(
			CompletionQuality.Level.FAILED,
			"stat_below_shoot_floor",
			stat_eval,
			0.0,
			0.0
		)

	var fatigue: int = artist.health.fatigue
	var stress: int = artist.mood.stress
	var body_factor: float = _calculate_body_factor(fatigue, stress)
	var p_fail: float = _calculate_fail_probability(artist, body_factor)
	if p_fail > 0.0 and rng_roll_fail < p_fail:
		return _result(
			CompletionQuality.Level.FAILED,
			"trait_or_mood_roll",
			stat_eval,
			p_fail,
			0.0
		)

	var p_perfect: float = _calculate_perfect_probability(artist, stat_eval, fatigue, stress, body_factor)
	var quality: int = CompletionQuality.Level.SUCCESS
	if p_perfect > 0.0 and rng_roll_perfect <= p_perfect:
		quality = CompletionQuality.Level.PERFECT

	return _result(quality, "ok", stat_eval, p_fail, p_perfect)

static func _has_forced_fail_event(job_id: String) -> bool:
	if InteractionManager.get_flag(FLAG_JOB_FORCE_FAIL, false):
		return true
	var clean_id: String = job_id.strip_edges()
	if clean_id == "":
		return false
	return InteractionManager.get_flag(FLAG_JOB_FORCE_FAIL_PREFIX + clean_id, false)

static func _get_state_hard_fail_reason(artist: ArtistInstance, job: JobResource) -> String:
	if not artist.health.can_work():
		return "health_blocked"
	if artist.mood.current_state == ArtistMoodComponent.MoodState.RED:
		return "stress_red"

	var fatigue: int = artist.health.fatigue
	var stress: int = artist.mood.stress
	var add_fatigue: int = _scale_artist_fatigue_delta(artist, job.add_fatigue)
	var add_stress: int = _scale_artist_stress_delta(artist, job.add_stress)

	if fatigue >= FAIL_FATIGUE_HARD:
		return "fatigue_hard"
	if stress >= FAIL_STRESS_HARD:
		return "stress_hard"
	if fatigue + add_fatigue >= FAIL_FATIGUE_HARD:
		return "fatigue_projected"
	if stress + add_stress >= FAIL_STRESS_HARD:
		return "stress_projected"
	return ""

static func _scale_artist_fatigue_delta(artist: ArtistInstance, base_delta: int) -> int:
	if artist == null or artist.base_data == null or base_delta == 0:
		return base_delta
	return artist.base_data.scale_fatigue_delta(base_delta)

static func _scale_artist_stress_delta(artist: ArtistInstance, base_delta: int) -> int:
	if artist == null or artist.base_data == null or base_delta == 0:
		return base_delta
	return artist.base_data.scale_stress_delta(base_delta)

static func _evaluate_stat_layer(artist: ArtistInstance, job_instance: JobInstance) -> Dictionary:
	if int(job_instance.accept_mode) == ACCEPT_MODE_NORMAL:
		return {
			"stat_pass": true,
			"stat_score": 1.0,
			"accept_mode": ACCEPT_MODE_NORMAL,
		}

	var floors: Dictionary = job_instance.accept_shoot_floor
	if floors.is_empty():
		floors = build_accept_shoot_floors(job_instance.base_job)
		job_instance.accept_shoot_floor = floors.duplicate(true)

	var min_ratio: float = 999.0
	var worst_stat: String = ""
	for stat_name in floors:
		var floor_value: int = int(floors[stat_name])
		if floor_value <= 0:
			continue
		var current: int = int(artist.get(stat_name))
		var ratio: float = float(current) / float(floor_value)
		if ratio < min_ratio:
			min_ratio = ratio
			worst_stat = str(stat_name)

	if min_ratio == 999.0:
		return {"stat_pass": true, "stat_score": 1.0, "accept_mode": ACCEPT_MODE_INVITE}

	return {
		"stat_pass": min_ratio >= 1.0,
		"stat_score": min_ratio,
		"worst_stat": worst_stat,
		"accept_mode": ACCEPT_MODE_INVITE,
	}

static func _calculate_body_factor(fatigue: int, stress: int) -> float:
	var low_fatigue: float = 1.0 - clampf(float(fatigue) / 100.0, 0.0, 1.0)
	var low_stress: float = 1.0 - clampf(float(stress) / 100.0, 0.0, 1.0)
	return clampf(0.5 * low_fatigue + 0.5 * low_stress, 0.0, 1.0)

static func _calculate_fail_probability(artist: ArtistInstance, body_factor: float) -> float:
	var p_mood: float = artist.mood.get_additional_failure_rate()
	var p_trait: float = 0.0
	if artist.base_data != null:
		p_trait = artist.base_data.get_fail_rate_adjustment()
	var p_body: float = (1.0 - body_factor) * 0.15
	return clampf(p_mood + p_trait + p_body, 0.0, 0.95)

static func _calculate_perfect_probability(
	artist: ArtistInstance,
	stat_eval: Dictionary,
	fatigue: int,
	stress: int,
	body_factor: float
) -> float:
	var stat_score: float = float(stat_eval.get("stat_score", 1.0))
	var overflow: float = maxf(stat_score - 1.0, 0.0)
	var stat_part: float = clampf(overflow / 0.5, 0.0, 1.0) * 0.20

	var satisf_part: float = clampf(float(artist.satisfaction) / 100.0, 0.0, 1.0) * 0.10
	var low_fatigue: float = (1.0 - clampf(float(fatigue) / 100.0, 0.0, 1.0)) * 0.08
	var low_stress: float = (1.0 - clampf(float(stress) / 100.0, 0.0, 1.0)) * 0.07

	var favor_mod: int = 0
	if artist.base_data != null:
		favor_mod = artist.base_data.favor_gain_mod
	var affection_eff: float = float(artist.get_affection()) * (100.0 + float(favor_mod)) / 100.0
	var affect_part: float = clampf(affection_eff / 100.0, 0.0, 1.0) * 0.10

	var p_trait: float = 0.0
	if artist.base_data != null:
		p_trait = artist.base_data.get_perfect_rate_adjustment()

	var p_base: float = (stat_part + satisf_part + low_fatigue + low_stress + affect_part) * body_factor
	return clampf(p_base + p_trait, 0.0, PERFECT_CAP)

static func _result(
	quality: int,
	reason: String,
	stat_eval: Dictionary,
	p_fail: float,
	p_perfect: float
) -> Dictionary:
	return {
		"quality": quality,
		"quality_name": CompletionQuality.get_display_name(quality),
		"reason": reason,
		"is_successful": CompletionQuality.is_successful(quality),
		"stat_eval": stat_eval,
		"p_fail": p_fail,
		"p_perfect": p_perfect,
	}
