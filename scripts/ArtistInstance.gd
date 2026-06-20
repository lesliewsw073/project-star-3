class_name ArtistInstance
extends RefCounted

# ==========================================
# 核心数据与图纸绑定
# ==========================================
var base_data: ArtistResource

# ==========================================
# 核心组件封装 (完全委托管理身体与心理)
# ==========================================
var health: ArtistHealthComponent
var mood: ArtistMoodComponent

var satisfaction: int = 0         # 满意度 (0-100)，保留在顶层，由组件惩罚报告进行扣减
# 好感度（对主角）不再在此本地存储：唯一真相在 RelationshipManager，按 artist_id 索引。
# 本类只通过 get_affection() / add_affection() 间接读写，避免出现「双份真相」。

# ==========================================
# 核心属性（与 Artist_Resource.gd 保持一致）
# ==========================================
var empathy: int = 0           # 共情
var timbre: int = 0            # 音色
var improvisation: int = 0     # 即兴
var acting: int = 0            # 演技
var singing: int = 0           # 歌艺
var eloquence: int = 0         # 口才
var dynamism: int = 0          # 动感
var talent: int = 0            # 才华
var stamina: int = 0           # 体能
var deportment: int = 0        # 仪态
var fashion: int = 0           # 时尚
var confidence: int = 0        # 自信
var rebelliousness: int = 0    # 叛逆
var humor: int = 0             # 喜感
var affinity: int = 0          # 亲和
var fame: int = 0              # 名气
var popularity: int = 0        # 人气
var exposure: int = 0          # 曝光
var morality: int = 0          # 道德

# ==========================================
# 构造函数
# ==========================================
func _init(resource: ArtistResource = null):
	# 初始化装载两大核心组件
	health = ArtistHealthComponent.new()
	mood = ArtistMoodComponent.new()
	
	if resource != null:
		base_data = resource
		empathy = resource.empathy
		timbre = resource.timbre
		improvisation = resource.improvisation
		acting = resource.acting
		singing = resource.singing
		eloquence = resource.eloquence
		dynamism = resource.dynamism
		talent = resource.talent
		stamina = resource.stamina
		deportment = resource.deportment
		fashion = resource.fashion
		confidence = resource.confidence
		rebelliousness = resource.rebelliousness
		humor = resource.humor
		affinity = resource.affinity
		fame = resource.fame
		popularity = resource.popularity
		exposure = resource.exposure
		morality = resource.morality
		satisfaction = clampi(resource.satisfaction, 0, 100)
		# 初始好感度由 ArtistManager 签约时登记进 RelationshipManager，这里不再本地写入。
		health.fatigue = resource.initial_fatigue
		mood.stress = resource.initial_stress

# ==========================================
# 核心结算接收器 (每天行程结束后由排班系统调用)
# ==========================================
func apply_daily_result(task_data: Variant):
	# 1. 拦截异常状态：生病/住院/罢工等非工作状态下无法获得收益
	# (注意：MoodState.RED代表压力过大，按您之前逻辑也可视为罢工临界点)
	if not health.can_work() or mood.current_state == ArtistMoodComponent.MoodState.RED:
		return # 自然恢复逻辑已下放到 process_day_passed，这里直接跳过
		
	# 2. 提取有效的数据源
	var source_data = null
	
	if task_data is GigResource or task_data is CourseResource or task_data is VacationResource:
		source_data = task_data
	elif task_data is JobInstance:
		# 兼容可能的 JobInstance
		source_data = task_data.base_job 
		
	# 3. 如果今天是纯休息日或没有安排
	if source_data == null:
		health.fatigue = clampi(health.fatigue + _scale_fatigue_delta(-15), 0, 100)
		mood.stress = clampi(mood.stress + _scale_stress_delta(-5), 0, 100)
		return
		
	# 4. 物理注入状态变化 (数值注入组件的变量中)
	health.fatigue = clampi(health.fatigue + _scale_fatigue_delta(source_data.add_fatigue), 0, 100)
	mood.stress = clampi(mood.stress + _scale_stress_delta(source_data.add_stress), 0, 100)
	
	satisfaction = clampi(satisfaction + _scale_satisfaction_delta(source_data.add_satisfaction), 0, 100)
	add_affection(_scale_favor_delta(source_data.add_affection))

	# 5. 物理注入核心属性变化 (与 Artist_Resource.gd 保持一致)
	empathy = clampi(empathy + source_data.add_empathy, 0, 999)
	timbre = clampi(timbre + source_data.add_timbre, 0, 999)
	improvisation = clampi(improvisation + source_data.add_improvisation, 0, 999)
	acting = clampi(acting + source_data.add_acting, 0, 999)
	singing = clampi(singing + source_data.add_singing, 0, 999)
	eloquence = clampi(eloquence + source_data.add_eloquence, 0, 999)
	dynamism = clampi(dynamism + source_data.add_dynamism, 0, 999)
	talent = clampi(talent + source_data.add_talent, 0, 999)
	stamina = clampi(stamina + source_data.add_stamina, 0, 999)
	deportment = clampi(deportment + source_data.add_deportment, 0, 999)
	fashion = clampi(fashion + source_data.add_fashion, 0, 999)
	confidence = clampi(confidence + source_data.add_confidence, 0, 999)
	rebelliousness = clampi(rebelliousness + source_data.add_rebelliousness, 0, 999)
	humor = clampi(humor + source_data.add_humor, 0, 999)
	affinity = clampi(affinity + source_data.add_affinity, 0, 999)
	fame = clampi(fame + source_data.add_fame, 0, 999)
	popularity = clampi(popularity + source_data.add_popularity, 0, 999)
	exposure = clampi(exposure + source_data.add_exposure, 0, 999)
	morality = clampi(morality + _scale_morality_delta(source_data.add_morality), 0, 999)

func apply_rest_day() -> void:
	if not health.can_work() or mood.current_state == ArtistMoodComponent.MoodState.RED:
		return
	health.fatigue = clampi(health.fatigue + _scale_fatigue_delta(-20), 0, 100)
	mood.stress = clampi(mood.stress + _scale_stress_delta(-10), 0, 100)
	satisfaction = clampi(satisfaction + _scale_satisfaction_delta(2), 0, 100)

func apply_creation_day() -> void:
	if not health.can_work() or mood.current_state == ArtistMoodComponent.MoodState.RED:
		return
	health.fatigue = clampi(health.fatigue + _scale_fatigue_delta(-5), 0, 100)
	mood.stress = clampi(mood.stress + _scale_stress_delta(5), 0, 100)
	talent = clampi(talent + 1, 0, 999)
	satisfaction = clampi(satisfaction + _scale_satisfaction_delta(1), 0, 100)

## 屬性道具：逐項套用，屬性已滿則該項不加（負向仍生效）。
func apply_attribute_item(item: ItemResource) -> Dictionary:
	if item == null:
		return {}

	var applied: Dictionary = {}

	applied["add_fatigue"] = _apply_meter_delta(
		"fatigue", health.fatigue, _scale_fatigue_delta(item.add_fatigue), ItemResource.METER_MAX
	)
	health.fatigue = int(applied["add_fatigue"]["new_value"])

	applied["add_stress"] = _apply_meter_delta(
		"stress", mood.stress, _scale_stress_delta(item.add_stress), ItemResource.METER_MAX
	)
	mood.stress = int(applied["add_stress"]["new_value"])

	applied["add_satisfaction"] = _apply_meter_delta(
		"satisfaction", satisfaction, _scale_satisfaction_delta(item.add_satisfaction), ItemResource.METER_MAX
	)
	satisfaction = int(applied["add_satisfaction"]["new_value"])

	if item.add_affection != 0:
		var old_affection: int = get_affection()
		add_affection(_scale_favor_delta(item.add_affection))
		applied["add_affection"] = {
			"requested": item.add_affection,
			"applied": get_affection() - old_affection,
			"old_value": old_affection,
			"new_value": get_affection(),
		}

	var stat_fields: Array[Dictionary] = [
		{"name": "empathy", "delta": item.add_empathy},
		{"name": "timbre", "delta": item.add_timbre},
		{"name": "improvisation", "delta": item.add_improvisation},
		{"name": "acting", "delta": item.add_acting},
		{"name": "singing", "delta": item.add_singing},
		{"name": "eloquence", "delta": item.add_eloquence},
		{"name": "dynamism", "delta": item.add_dynamism},
		{"name": "talent", "delta": item.add_talent},
		{"name": "stamina", "delta": item.add_stamina},
		{"name": "deportment", "delta": item.add_deportment},
		{"name": "fashion", "delta": item.add_fashion},
		{"name": "confidence", "delta": item.add_confidence},
		{"name": "rebelliousness", "delta": item.add_rebelliousness},
		{"name": "humor", "delta": item.add_humor},
		{"name": "affinity", "delta": item.add_affinity},
		{"name": "fame", "delta": item.add_fame},
		{"name": "popularity", "delta": item.add_popularity},
		{"name": "exposure", "delta": item.add_exposure},
		{"name": "morality", "delta": item.add_morality},
	]

	for field in stat_fields:
		var stat_name: String = str(field["name"])
		var delta: int = int(field["delta"])
		if delta == 0:
			continue
		if stat_name == "morality":
			delta = _scale_morality_delta(delta)
		var current: int = int(get(stat_name))
		var change: Dictionary = _apply_stat_delta(stat_name, current, delta)
		set(stat_name, int(change["new_value"]))
		applied[stat_name] = change

	return applied

func _apply_meter_delta(field_name: String, current: int, delta: int, max_value: int) -> Dictionary:
	if delta == 0:
		return {"field": field_name, "requested": 0, "applied": 0, "old_value": current, "new_value": current}
	var applied_delta: int = _clamped_positive_delta(current, delta, max_value)
	var new_value: int = clampi(current + applied_delta, 0, max_value)
	return {
		"field": field_name,
		"requested": delta,
		"applied": new_value - current,
		"old_value": current,
		"new_value": new_value,
	}

func _apply_stat_delta(stat_name: String, current: int, delta: int) -> Dictionary:
	var applied_delta: int = _clamped_positive_delta(current, delta, ItemResource.STAT_MAX)
	var new_value: int = clampi(current + applied_delta, 0, ItemResource.STAT_MAX)
	return {
		"field": stat_name,
		"requested": delta,
		"applied": new_value - current,
		"old_value": current,
		"new_value": new_value,
	}

func _clamped_positive_delta(current: int, delta: int, max_value: int) -> int:
	if delta == 0:
		return 0
	if delta < 0:
		return maxi(delta, -current)
	if current >= max_value:
		return 0
	return mini(delta, max_value - current)

# ==========================================
# 每日周期推演 (由 ArtistManager 全局 advance_day 调用)
# ==========================================
func process_day_passed():
	# 1. 让组件自己推演今日状态，并收集惩罚报告
	var health_report = health.process_daily_update()
	var mood_report = mood.process_daily_update()
	
	# 2. 结算组件回传的惩罚
	var total_satisfaction_drop = health_report.satisfaction_drop + mood_report.satisfaction_drop
	var total_affection_drop = health_report.affection_drop + mood_report.affection_drop
	
	if total_satisfaction_drop > 0:
		satisfaction = clampi(satisfaction - total_satisfaction_drop, 0, 100)
	if total_affection_drop > 0:
		add_affection(-total_affection_drop)
		
	# 3. 结算特殊治愈事件 (如：出院彻底康复清空压力)
	if health_report.get("clear_stress", false):
		mood.stress = 0
		print("【状态更新】艺人经过深度休养，压力值已全部清空！")

func is_hospitalized() -> bool:
	return health != null and health.current_state == ArtistHealthComponent.PhysicalState.HOSPITALIZED

# ==========================================
# 好感度（对主角）—— 统一委托给 RelationshipManager（唯一真相）
# 单向调用：ArtistInstance → RelationshipManager，永不反向，杜绝循环。
# ==========================================
func get_affection() -> int:
	if base_data == null or base_data.artist_id == "":
		return 0
	return RelationshipManager.get_affection(base_data.artist_id)

func add_affection(amount: int) -> void:
	if base_data == null or base_data.artist_id == "":
		return
	RelationshipManager.add_affection(base_data.artist_id, amount)

func _scale_morality_delta(base_delta: int) -> int:
	if base_data == null or base_delta == 0:
		return base_delta
	return base_data.scale_morality_delta(base_delta)

func _scale_favor_delta(base_delta: int) -> int:
	if base_data == null or base_delta == 0:
		return base_delta
	return base_data.scale_favor_delta(base_delta)

func _scale_stress_delta(base_delta: int) -> int:
	if base_data == null or base_delta == 0:
		return base_delta
	return base_data.scale_stress_delta(base_delta)

func _scale_fatigue_delta(base_delta: int) -> int:
	if base_data == null or base_delta == 0:
		return base_delta
	return base_data.scale_fatigue_delta(base_delta)

func _scale_satisfaction_delta(base_delta: int) -> int:
	if base_data == null or base_delta == 0:
		return base_delta
	return base_data.scale_satisfaction_delta(base_delta)
