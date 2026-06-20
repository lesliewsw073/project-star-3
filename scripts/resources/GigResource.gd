class_name GigResource
extends Resource

# 16种打工类型的系统代号 (右侧为您在面板中填写的对应中文名)
enum GigType { 
	# --- 颜值与形体 ---
	MODEL_PRINT,        # 对应：平面模特
	MODEL_EXPO,         # 对应：展台模特
	BOUTIQUE_CLERK,     # 对应：精品店员
	
	# --- 口才与喜感 ---
	TV_SHOPPING,        # 对应：电视推销
	MASCOT_ACTOR,       # 对应：扮演布偶
	SET_ASSISTANT,      # 对应：节目场记
	
	# --- 音乐与才华 ---
	BAR_SINGER,         # 对应：酒吧驻唱
	BACKUP_SINGER,      # 对应：幕后合音
	SCORE_COPYIST,      # 对应：抄写乐谱
	
	# --- 演艺与舞台 ---
	EXTRA_ACTOR,        # 对应：临时演员
	BACKUP_DANCER,      # 对应：明星伴舞
	UNDERGROUND_LIVE,   # 对应：地下暖场
	
	# --- 体能与极限 ---
	STUNT_DOUBLE,       # 对应：武术替身
	MOCAP_ACTOR,        # 对应：动捕演员
	
	# --- 道德与名气 ---
	CHARITY_WORKER,     # 对应：慈善义工
	OUTDOOR_ROADSHOW    # 对应：户外路演
}

@export_group("打工基础信息")
@export var gig_id: String = "gig_001"
@export var gig_name: String = "未命名打工"
@export var gig_type: GigType = GigType.BAR_SINGER

@export_group("內容分級")
@export var is_test_content: bool = false

@export_group("基础收益与防逃课")
@export var reward_money: int = 800 
@export var penalty_threshold: int = 300 

@export_group("状态变化 (可正可负)")
@export var add_fatigue: int = 15      # 增加疲劳
@export var add_stress: int = 10       # 增加压力
@export var add_satisfaction: int = -2 # 打工通常降满意度
@export var add_affection: int = -1    # 好感度变化

@export_group("属性变化 (建议填最多5项，允许填负数扣除)")
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
