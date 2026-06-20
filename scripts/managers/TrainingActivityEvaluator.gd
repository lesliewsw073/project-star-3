class_name TrainingActivityEvaluator
extends RefCounted

## 打工 / 课程单日品质判定（与通告同构：失败 / 成功 / 完美）
## - 失败：主要看疲劳 + 压力（与通告属性门槛不同，灵魂相通）
## - 完成后再 Roll 完美；概率由好感/满意/低疲劳/低压力决定（公式占位，待调）
## - 完美概率上限 50%，四维全低时默认 0%

const FAILURE_FATIGUE_THRESHOLD: int = 85
const FAILURE_STRESS_THRESHOLD: int = 76

static func evaluate_gig_day(artist: ArtistInstance, gig: GigResource) -> Dictionary:
	if gig == null:
		return _make_result(CompletionQuality.Level.FAILED, 0.0, "打工数据无效。")
	return _evaluate_day(
		artist,
		gig.add_fatigue,
		gig.add_stress,
		"打工：%s" % gig.gig_name
	)

static func evaluate_course_day(artist: ArtistInstance, course: CourseResource) -> Dictionary:
	if course == null:
		return _make_result(CompletionQuality.Level.FAILED, 0.0, "课程数据无效。")
	return _evaluate_day(
		artist,
		course.add_fatigue,
		course.add_stress,
		"课程：%s" % course.course_name
	)

static func calculate_perfect_probability(artist: ArtistInstance) -> float:
	if artist == null:
		return 0.0

	# TODO: 正式公式后续替换；当前占位：四维均值 × 上限 50%
	var affection_score: float = clampf(float(artist.get_affection()) / 100.0, 0.0, 1.0)
	var satisfaction_score: float = clampf(float(artist.satisfaction) / 100.0, 0.0, 1.0)
	var low_fatigue_score: float = 1.0 - clampf(float(artist.health.fatigue) / 100.0, 0.0, 1.0)
	var low_stress_score: float = 1.0 - clampf(float(artist.mood.stress) / 100.0, 0.0, 1.0)

	var average_score: float = (
		affection_score
		+ satisfaction_score
		+ low_fatigue_score
		+ low_stress_score
	) / 4.0
	var probability: float = average_score * CompletionQuality.MAX_PERFECT_PROBABILITY
	if artist.base_data != null:
		probability += artist.base_data.get_perfect_rate_adjustment()
	return clampf(probability, 0.0, CompletionQuality.MAX_PERFECT_PROBABILITY)

static func build_quality_rule_text() -> String:
	return (
		"结算三档：失败 / 成功 / 完美。"
		+ "失败主要看疲劳与压力；"
		+ "完成后再依好感、满意度、低疲劳、低压力 Roll 完美（上限 50%，公式待调）。"
	)

static func _evaluate_day(
	artist: ArtistInstance,
	add_fatigue: int,
	add_stress: int,
	activity_label: String
) -> Dictionary:
	if artist == null:
		return _make_result(CompletionQuality.Level.FAILED, 0.0, "艺人不存在。")

	if not artist.health.can_work():
		return _make_result(
			CompletionQuality.Level.FAILED,
			0.0,
			"%s失败：艺人无法工作（生病/住院）。" % activity_label
		)

	if artist.mood.current_state == ArtistMoodComponent.MoodState.RED:
		return _make_result(
			CompletionQuality.Level.FAILED,
			0.0,
			"%s失败：压力过大。" % activity_label
		)

	var fatigue: int = artist.health.fatigue
	var stress: int = artist.mood.stress
	var scaled_fatigue: int = _scale_artist_fatigue_delta(artist, add_fatigue)
	var scaled_stress: int = _scale_artist_stress_delta(artist, add_stress)
	var failure_reason: String = _get_failure_reason(fatigue, stress, scaled_fatigue, scaled_stress)
	if failure_reason != "":
		return _make_result(CompletionQuality.Level.FAILED, 0.0, "%s%s" % [activity_label, failure_reason])

	var mood_fail_rate: float = artist.mood.get_additional_failure_rate()
	if artist.base_data != null:
		mood_fail_rate += artist.base_data.get_fail_rate_adjustment()
	mood_fail_rate = maxf(mood_fail_rate, 0.0)
	if mood_fail_rate > 0.0 and randf() < mood_fail_rate:
		return _make_result(
			CompletionQuality.Level.FAILED,
			0.0,
			"%s失败：状态不稳，未能完成。" % activity_label
		)

	var perfect_probability: float = calculate_perfect_probability(artist)
	var quality: int = CompletionQuality.Level.SUCCESS
	if perfect_probability > 0.0 and randf() <= perfect_probability:
		quality = CompletionQuality.Level.PERFECT

	return _make_result(quality, perfect_probability, "")

static func _get_failure_reason(
	fatigue: int,
	stress: int,
	add_fatigue: int,
	add_stress: int
) -> String:
	if fatigue >= FAILURE_FATIGUE_THRESHOLD:
		return "失败：疲劳过高。"
	if stress >= FAILURE_STRESS_THRESHOLD:
		return "失败：压力过大。"

	var projected_fatigue: int = fatigue + add_fatigue
	var projected_stress: int = stress + add_stress
	if projected_fatigue >= FAILURE_FATIGUE_THRESHOLD:
		return "失败：预计疲劳将超出承受范围。"
	if projected_stress >= FAILURE_STRESS_THRESHOLD:
		return "失败：预计压力将超出承受范围。"
	return ""

static func _scale_artist_fatigue_delta(artist: ArtistInstance, base_delta: int) -> int:
	if artist == null or artist.base_data == null or base_delta == 0:
		return base_delta
	return artist.base_data.scale_fatigue_delta(base_delta)

static func _scale_artist_stress_delta(artist: ArtistInstance, base_delta: int) -> int:
	if artist == null or artist.base_data == null or base_delta == 0:
		return base_delta
	return artist.base_data.scale_stress_delta(base_delta)

static func _make_result(quality: int, perfect_probability: float, detail: String) -> Dictionary:
	return {
		"processed": true,
		"quality": quality,
		"quality_name": CompletionQuality.get_display_name(quality),
		"perfect_probability": perfect_probability,
		"detail": detail,
		"is_successful": CompletionQuality.is_successful(quality),
	}
