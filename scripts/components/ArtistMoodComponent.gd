class_name ArtistMoodComponent
extends RefCounted

enum MoodState { GREEN, YELLOW, RED }

var current_state: MoodState = MoodState.GREEN
var stress: int = 0

## 每日结算核心逻辑，更新心情并返回惩罚报告
func process_daily_update() -> Dictionary:
	var penalty_report = {
		"satisfaction_drop": 0,
		"affection_drop": 0
	}
	
	_update_mood_color()
	
	if current_state == MoodState.RED:
		# 红色状态每天随机掉 1-5 点
		var drop = randi_range(1, 5)
		penalty_report.satisfaction_drop += drop
		penalty_report.affection_drop += drop
		
	return penalty_report

## 实时更新心情颜色
func _update_mood_color():
	if stress > 75:
		current_state = MoodState.RED
	elif stress >= 51:
		current_state = MoodState.YELLOW
	else:
		current_state = MoodState.GREEN

## 提供给通告系统的接口：获取当前额外的失败率
func get_additional_failure_rate() -> float:
	match current_state:
		MoodState.GREEN:
			return 0.0
		MoodState.YELLOW:
			# 基础 10% + 超出 51 的部分每点 2%
			var extra_points = stress - 51
			var rate = 0.10 + (extra_points * 0.02)
			return rate
		MoodState.RED:
			return 1.0 # 100% 失败率
			
	return 0.0
