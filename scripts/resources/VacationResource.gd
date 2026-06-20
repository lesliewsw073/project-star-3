class_name VacationResource
extends Resource

enum VacationType { DOMESTIC, OVERSEAS }

@export_group("度假基础信息")
@export var vacation_id: String = "vacation_001"
@export var vacation_name: String = "未命名度假"
@export var vacation_type: VacationType = VacationType.DOMESTIC

@export_group("內容分級")
@export var is_test_content: bool = false

@export_group("消耗与收益")
@export var cost_money: int = 8000

@export_group("状态变化 (可正可负，负值表示恢复)")
@export var add_fatigue: int = -30
@export var add_stress: int = -25
@export var add_satisfaction: int = 8
@export var add_affection: int = 0

@export_group("属性变化")
@export_range(-999, 999) var add_empathy: int = 0
@export_range(-999, 999) var add_timbre: int = 0
@export_range(-999, 999) var add_improvisation: int = 0
@export_range(-999, 999) var add_acting: int = 0
@export_range(-999, 999) var add_singing: int = 0
@export_range(-999, 999) var add_eloquence: int = 0
@export_range(-999, 999) var add_dynamism: int = 0
@export_range(-999, 999) var add_talent: int = 0
@export_range(-999, 999) var add_stamina: int = 0
@export_range(-999, 999) var add_deportment: int = 0
@export_range(-999, 999) var add_fashion: int = 0
@export_range(-999, 999) var add_confidence: int = 0
@export_range(-999, 999) var add_rebelliousness: int = 0
@export_range(-999, 999) var add_humor: int = 0
@export_range(-999, 999) var add_affinity: int = 0
@export_range(-999, 999) var add_fame: int = 0
@export_range(-999, 999) var add_popularity: int = 0
@export_range(-999, 999) var add_exposure: int = 0
@export_range(-999, 999) var add_morality: int = 0

@export_group("地理绑定")
@export var unlock_location_id: String = ""
@export var unlock_facility_id: String = ""
