class_name ArtistHealthComponent
extends RefCounted

enum PhysicalState { HEALTHY, SICK, HOSPITALIZED }

var current_state: PhysicalState = PhysicalState.HEALTHY
var fatigue: int = 0
var rest_days_remaining: int = 0

# 记录是否处于出院后的3天强制恢复期
var is_post_hospital_rest: bool = false 

## 每日结算核心逻辑，返回需要扣除的数值报告
func process_daily_update() -> Dictionary:
	var penalty_report = {
		"satisfaction_drop": 0,
		"affection_drop": 0,
		"clear_stress": false # 是否触发住院出院后的清空压力
	}
	
	if rest_days_remaining > 0:
		_handle_resting_state(penalty_report)
	else:
		_check_health_risks()
		
	return penalty_report

## 处理正在休息/生病/住院的状态
func _handle_resting_state(report: Dictionary):
	rest_days_remaining -= 1
	
	match current_state:
		PhysicalState.SICK:
			# 生病期间每天随机掉 1-2 点
			var drop = randi_range(1, 2)
			report.satisfaction_drop += drop
			report.affection_drop += drop
			
			if rest_days_remaining <= 0:
				current_state = PhysicalState.HEALTHY
				
		PhysicalState.HOSPITALIZED:
			# 住院及恢复期每天固定掉 3-5 点
			var drop = randi_range(3, 5)
			report.satisfaction_drop += drop
			report.affection_drop += drop
			
			if rest_days_remaining <= 0:
				if not is_post_hospital_rest:
					# 住院期满，转入3天强制恢复期
					is_post_hospital_rest = true
					rest_days_remaining = 3
				else:
					# 恢复期满，彻底健康，触发清空压力
					is_post_hospital_rest = false
					current_state = PhysicalState.HEALTHY
					report.clear_stress = true

## 检查健康风险（触发突发生病或住院）
func _check_health_risks():
	if fatigue > 85:
		trigger_hospital()
	elif fatigue >= 61:
		# 61到85之间，每点增加4%概率
		var sick_probability = (fatigue - 60) * 0.04
		if randf() <= sick_probability:
			trigger_sick()

func trigger_sick():
	current_state = PhysicalState.SICK
	rest_days_remaining = randi_range(3, 17)

func trigger_hospital():
	current_state = PhysicalState.HOSPITALIZED
	is_post_hospital_rest = false
	# 住院基础耗时设定为 3 到 5 天（不含出院后的3天）
	rest_days_remaining = randi_range(3, 5) 

func can_work() -> bool:
	return current_state == PhysicalState.HEALTHY
