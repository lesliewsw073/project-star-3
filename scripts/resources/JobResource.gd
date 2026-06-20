class_name JobResource
extends Resource

enum JobClass { REGULAR, SPECIAL, HIDDEN }
enum JobType { MOVIE, TV_DRAMA, TV_VARIETY, MUSIC_SOLO, MUSIC_GROUP, MUSIC_BAND, AD_SHOOT, VOICEOVER }
enum ShootCycle { SHORT, LONG }

@export_group("通告基础信息")
@export var job_id: String = "job_001"
@export var job_name: String = "未命名通告"
@export var job_class: JobClass = JobClass.REGULAR
@export var job_type: JobType = JobType.MOVIE
@export var target_company_id: String = "" 

@export_group("排期与最低门槛")
@export var total_days: int = 10
## 需凑齐的有效拍摄日（若 >0 优先于 total_days）
@export var required_shoot_days: int = 0
## 开机窗口：接案后可排期的週数（×7 天）
@export_range(1, 52) var shoot_window_weeks: int = 12
@export var shoot_cycle: ShootCycle = ShootCycle.SHORT
## [已废弃] 长周期自动排程，离散拍摄实作后忽略
@export_range(1, 7) var shoot_days_per_week: int = 3
## 下週草稿起始日（0=星期一）；電視台普通通告會在執行層強制為星期一
@export_range(0, 6) var start_day_index: int = 0
@export var required_personnel: int = 1
@export var req_empathy: int = 0
@export var req_timbre: int = 0
@export var req_improvisation: int = 0
@export var req_acting: int = 0
@export var req_singing: int = 0
@export var req_eloquence: int = 0
@export var req_dynamism: int = 0
@export var req_talent: int = 0
@export var req_stamina: int = 0
@export var req_deportment: int = 0
@export var req_fashion: int = 0
@export var req_confidence: int = 0
@export var req_rebelliousness: int = 0
@export var req_humor: int = 0
@export var req_affinity: int = 0
@export var req_fame: int = 0
@export var req_popularity: int = 0
@export var req_exposure: int = 0
@export var req_morality: int = 0

@export_group("邀請接案")
## 僅能透過製片人邀請接案（不顯示普通接案按鈕）
@export var invite_only: bool = false
## 邀請分數門檻；0 表示使用 JobDayEvaluator.DEFAULT_INVITE_THRESHOLD
@export var invite_threshold: int = 0

@export_group("內容分級")
## 企劃預填／沙盒占位；正式定稿前須為 true。見 docs/writing/CONTENT_TIER_REGISTRY.md
@export var is_test_content: bool = false

@export_group("重大通告")
## 重大通告：可觸發立項預熱、殺青、大熱等頭條新聞。
@export var is_major_job: bool = false

func get_required_shoot_days() -> int:
	if required_shoot_days > 0:
		return required_shoot_days
	return maxi(total_days, 1)

func get_shoot_window_days() -> int:
	return maxi(shoot_window_weeks, 1) * 7

@export_group("殺青一次性獎勵（僅 _settle_job_completed）")
## 殺青時發給玩家公司；不是每日結算。
@export var reward_money: int = 50000
## 殺青時加在藝人身上；與下方 add_fame（每日）不同。
@export var reward_fame: int = 100

@export_group("每日拍攝結算 · 狀態（每個排程拍攝日）")
## 每個排程上的拍攝日結算一次（ScheduleManager → ArtistInstance.apply_daily_result）。
## 長通告請填「單日」量，勿填整案總量。疲勞/壓力 clamp 0～100。
@export var add_fatigue: int = 20
@export var add_stress: int = 15
@export var add_satisfaction: int = 5
@export var add_affection: int = 2

@export_group("每日拍攝結算 · 屬性（每個排程拍攝日，建議填 3～5 項）")
## 同上：每個排程拍攝日各加一次，屬性 clamp 0～999。留 0 表示該項不變。
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
@export var unlock_location_id: String = "" ## 拍攝地地圖屏 ID，如 screen_2
@export var unlock_facility_id: String = "" ## 拍攝設施 ID，如 fac_tv_01；留空表示該屏任意設施
