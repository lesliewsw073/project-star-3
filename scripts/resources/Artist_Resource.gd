class_name ArtistResource
extends Resource

enum Gender { MALE, FEMALE }

@export_group("基礎資訊")
@export var artist_id: String = ""
@export var artist_name: String = ""
@export var gender: Gender = Gender.MALE
@export var home_agency_id: String = "" ## 所屬經紀公司（agency_*）；簽約後由系統改為 agency_player
## 已出道須掛經紀公司；未出道 home_agency_id 應為空（簽約／選秀出道後由系統更新）。
@export var is_debuted: bool = false

@export_group("劇情標記")
@export var opening_pick: bool = false ## 開局三選一候選
@export var poachable_in: bool = false ## 劇情可挖角加入
@export var poachable_out: bool = false ## 劇情可被挖角離開
@export var fixed_story_join: bool = false ## 固定劇情加入旗下（004～016 中僅一人）
@export var sibling_partner_id: String = "" ## 兄妹／姐弟組合的另一方 artist_id

@export_group("內容分級")
@export var is_test_content: bool = false

@export_group("外觀")
@export var avatar: Texture2D ## 小頭像（排程表、對話框）
@export var portrait: Texture2D ## 半身立繪（簽約、會議）

@export_group("人物檔案")
@export var character_profile: ArtistProfileResource ## 身高／三圍／喜好等；不參與能力結算

@export_group("核心數值")
@export_range(0, 999) var empathy: int = 0 ## 共情
@export_range(0, 999) var timbre: int = 0 ## 音色
@export_range(0, 999) var improvisation: int = 0 ## 即興

@export_range(0, 999) var acting: int = 0 ## 演技
@export_range(0, 999) var singing: int = 0 ## 歌藝
@export_range(0, 999) var eloquence: int = 0 ## 口才
@export_range(0, 999) var dynamism: int = 0 ## 動感
@export_range(0, 999) var talent: int = 0 ## 才華
@export_range(0, 999) var stamina: int = 0 ## 體能
@export_range(0, 999) var deportment: int = 0 ## 儀態
@export_range(0, 999) var fashion: int = 0 ## 時尚
@export_range(0, 999) var confidence: int = 0 ## 自信

@export_range(0, 999) var rebelliousness: int = 0 ## 叛逆
@export_range(0, 999) var humor: int = 0 ## 喜感
@export_range(0, 999) var affinity: int = 0 ## 親和
@export_range(0, 999) var fame: int = 0 ## 名氣
@export_range(0, 999) var popularity: int = 0 ## 人氣
@export_range(0, 999) var exposure: int = 0 ## 曝光
@export_range(0, 999) var morality: int = 0 ## 道德

@export_group("初始狀態")
@export_range(-100, 100) var initial_stress: int = 0 ## 初始壓力
@export_range(-100, 100) var initial_fatigue: int = 0 ## 初始疲勞
@export_range(0, 100) var satisfaction: int = 0 ## 滿意度（運行時 0～100）
@export_range(0, 100) var affection: int = 0 ## 初始好感（運行時由 RelationshipManager 夾在 0～100）

@export_group("狀態閾值")
@export var stress_yellow_threshold: int = 40 ## 壓力達到此值變黃
@export var stress_red_threshold: int = 80    ## 壓力達到此值變紅
@export var fatigue_sick_threshold: int = 70  ## 疲勞達到此值有概率生病
@export var fatigue_hospital_threshold: int = 95 ## 疲勞達到此值直接住院

@export_group("養成修正")
@export var contract_diff_mod: int = 0 ## 簽約難度修正%（疊加基準 50）
@export var fail_rate_abs: int = 0 ## 失敗率絕對值修正%（百分點）
@export var perfect_rate_abs: int = 0 ## 完美率絕對值修正%（百分點）
@export var morality_mod: int = 0 ## 道德變化倍率修正%（100+mod 為倍率）
@export var favor_gain_mod: int = 0 ## 好感提升倍率修正%（100+mod 為倍率）
@export var stress_gain_mod: int = 0 ## 壓力獲得倍率修正%（100+mod 為倍率）
@export var fatigue_gain_mod: int = 0 ## 疲勞獲得倍率修正%（100+mod 為倍率）
@export var satisfaction_gain_mod: int = 0 ## 滿意度獲得倍率修正%（100+mod 為倍率）

const BASE_CONTRACT_DIFFICULTY: int = 50

func get_contract_difficulty() -> int:
	return clampi(BASE_CONTRACT_DIFFICULTY + contract_diff_mod, 1, 100)

## 已出道 ↔ 經紀公司掛載是否一致。
func has_valid_debut_state() -> bool:
	var agency_id: String = home_agency_id.strip_edges()
	if is_debuted:
		return agency_id != ""
	return agency_id == ""

func get_fail_rate_adjustment() -> float:
	return float(fail_rate_abs) / 100.0

func get_perfect_rate_adjustment() -> float:
	return float(perfect_rate_abs) / 100.0

func scale_delta_by_mod(base_delta: int, mod_percent: int) -> int:
	if base_delta == 0:
		return 0
	return int(round(float(base_delta) * (100.0 + mod_percent) / 100.0))

func scale_morality_delta(base_delta: int) -> int:
	return scale_delta_by_mod(base_delta, morality_mod)

func scale_favor_delta(base_delta: int) -> int:
	return scale_delta_by_mod(base_delta, favor_gain_mod)

func scale_stress_delta(base_delta: int) -> int:
	return scale_delta_by_mod(base_delta, stress_gain_mod)

func scale_fatigue_delta(base_delta: int) -> int:
	return scale_delta_by_mod(base_delta, fatigue_gain_mod)

func scale_satisfaction_delta(base_delta: int) -> int:
	return scale_delta_by_mod(base_delta, satisfaction_gain_mod)

@export_group("主角關聯劇情")
@export_multiline var dialogue_male_protagonist: String = ""
@export_multiline var story_hook_male_protagonist: String = ""

func get_character_profile() -> ArtistProfileResource:
	if character_profile != null:
		return character_profile
	return null
