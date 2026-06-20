class_name CourseResource
extends Resource

# 涵盖 15 项核心能力的专业课程枚举 (右侧为您在面板中填写的对应中文名)
enum CourseType { 
	# --- 核心演艺 ---
	ACTING_CLASS,       # 对应：影视表演 (主升: 演技)
	VOCAL_TRAINING,     # 对应：发声技巧 (主升: 歌艺)
	DANCE_LESSON,       # 对应：舞蹈形体 (主升: 动感)
	
	# --- 颜值与气场 ---
	ETIQUETTE_CLASS,    # 对应：形体礼仪 (主升: 仪态)
	FASHION_STYLING,    # 对应：时尚鉴赏 (主升: 时尚)
	CAMERA_EXPRESSION,  # 对应：镜头表现 (主升: 自信)
	
	# --- 综艺与口才 ---
	BROADCASTING,       # 对应：播音主持 (主升: 口才)
	COMEDY_WORKSHOP,    # 对应：喜剧工坊 (主升: 喜感)
	IMPROV_THEATER,     # 对应：即兴戏剧 (主升: 即兴)
	
	# --- 内涵与双商 ---
	PR_TRAINING,        # 对应：公关应对 (主升: 亲和)
	LOGIC_PUZZLE,       # 对应：逻辑推理 (主升: 高智)
	MUSIC_THEORY,       # 对应：乐理创作 (主升: 才华)
	SCRIPT_ANALYSIS,    # 对应：剧本解读 (主升: 共情)
	
	# --- 特殊/体能 ---
	PHYSICAL_TRAINING,  # 对应：体能特训 (主升: 体能)
	AVANT_GARDE_ART     # 对应：先锋艺术 (主升: 叛逆)
}

enum CourseLevel { BASIC, INTERMEDIATE, ADVANCED, PROFESSIONAL }

@export_group("课程基础信息")
@export var course_id: String = "course_001"
@export var course_name: String = "未命名课程"
@export var course_type: CourseType = CourseType.ACTING_CLASS
@export var course_level: CourseLevel = CourseLevel.BASIC

@export_group("內容分級")
@export var is_test_content: bool = false

@export_group("消耗与门槛")
@export var cost_money: int = 500  
@export var max_effective_stats: int = 999 

@export_group("状态变化 (可正可负)")
@export var add_fatigue: int = 10      # 增加疲劳
@export var add_stress: int = 10       # 增加压力
@export var add_satisfaction: int = 0  # 满意度变化
@export var add_affection: int = 0     # 好感度变化

@export_group("属性提升 (建议填2-3项，留0为空)")
@export_range(0, 999) var add_empathy: int = 0
@export_range(0, 999) var add_timbre: int = 0
@export_range(0, 999) var add_improvisation: int = 0
@export_range(0, 999) var add_acting: int = 0
@export_range(0, 999) var add_singing: int = 0
@export_range(0, 999) var add_eloquence: int = 0
@export_range(0, 999) var add_dynamism: int = 0
@export_range(0, 999) var add_talent: int = 0
@export_range(0, 999) var add_stamina: int = 0
@export_range(0, 999) var add_deportment: int = 0
@export_range(0, 999) var add_fashion: int = 0
@export_range(0, 999) var add_confidence: int = 0
@export_range(0, 999) var add_rebelliousness: int = 0
@export_range(0, 999) var add_humor: int = 0
@export_range(0, 999) var add_affinity: int = 0
@export_range(0, 999) var add_fame: int = 0
@export_range(0, 999) var add_popularity: int = 0
@export_range(0, 999) var add_exposure: int = 0
@export_range(0, 999) var add_morality: int = 0

@export_group("地理绑定")
# 标记该课程必须在哪个地图的哪个设施触发
@export var unlock_location_id: String = "" # 例如: "screen_3"
@export var unlock_facility_id: String = "" # 例如: "fac_training_base"
