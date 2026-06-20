class_name CompletionQuality
extends RefCounted

## 活动/通告结案三档：失败 | 成功 | 完美（成功+完美均属「完成」）

enum Level {
	NONE,
	FAILED,
	SUCCESS,
	PERFECT,
}

## 打工/课程完美 Roll 上限（具体公式见 TrainingActivityEvaluator）
const MAX_PERFECT_PROBABILITY: float = 0.5

static func is_successful(quality: int) -> bool:
	return quality == Level.SUCCESS or quality == Level.PERFECT

static func is_completed_outcome(quality: int) -> bool:
	return is_successful(quality)

static func get_display_name(quality: int) -> String:
	match quality:
		Level.FAILED:
			return "失败"
		Level.SUCCESS:
			return "成功"
		Level.PERFECT:
			return "完美"
		_:
			return "未定"
