extends Node

## 通告／製作公司註冊表（comp_*）：僅發布通告、出品作品，**不可簽約藝人**。
## 經紀公司請使用 AgencyDatabase（agency_*）。

# 通告公司产业类型
enum CompanyType { FILM, TV, MUSIC, AD }
# 通告公司规模
enum CompanyScale { DOMESTIC, INTERNATIONAL }

# Key: comp_* → 通告／製作方靜態資料
var companies_registry: Dictionary = {
	# ================= 影视类 =================
	"comp_film_01": {
		"name": "穹宇映画", "type": CompanyType.FILM, "scale": CompanyScale.DOMESTIC,
		"location_id": "screen_3", # 对应屏 3：文创艺术园
		"preferred_stats": ["acting", "rebelliousness"], # 偏好：演技、个性
		"required_cert": ""
	},
	"comp_film_02": {
		"name": "极昼影业集团", "type": CompanyType.FILM, "scale": CompanyScale.DOMESTIC,
		"location_id": "screen_5", # 对应屏 5：近郊影视城
		"preferred_stats": ["acting", "popularity"],
		"required_cert": ""
	},
	"comp_film_03": {
		"name": "曜岩视界", "type": CompanyType.FILM, "scale": CompanyScale.DOMESTIC,
		"location_id": "screen_5",
		"preferred_stats": ["stamina", "affinity"],
		"required_cert": ""
	},
	"comp_film_intl_01": {
		"name": "Aetherius Studios (以太渊影业)", "type": CompanyType.FILM, "scale": CompanyScale.INTERNATIONAL,
		"location_id": "city_la", # 对应洛杉矶
		"preferred_stats": ["acting", "fame"],
		"required_cert": "cert_acting_intl" # 需要表演国际证
	},
	"comp_film_intl_02": {
		"name": "梦境工作室", "type": CompanyType.FILM, "scale": CompanyScale.INTERNATIONAL,
		"location_id": "city_wellington", # 对应惠灵顿
		"preferred_stats": ["acting", "talent"],
		"required_cert": "cert_acting_intl"
	},

	# ================= 电视类 =================
	"comp_tv_01": {
		"name": "草莓卫视", "type": CompanyType.TV, "scale": CompanyScale.DOMESTIC,
		"location_id": "screen_2", # 对应屏 2：流行商圈
		"preferred_stats": ["humor", "rebelliousness"],
		"required_cert": ""
	},
	"comp_tv_02": {
		"name": "星云流媒体", "type": CompanyType.TV, "scale": CompanyScale.DOMESTIC,
		"location_id": "screen_4", # 对应屏 4：核心 CBD
		"preferred_stats": ["exposure", "affinity"],
		"required_cert": ""
	},
	"comp_tv_03": {
		"name": "地心引力传媒", "type": CompanyType.TV, "scale": CompanyScale.DOMESTIC,
		"location_id": "screen_5",
		"preferred_stats": ["acting", "fame"],
		"required_cert": ""
	},
	"comp_tv_intl_01": {
		"name": "Meridian Syndicate (子午线电视网)", "type": CompanyType.TV, "scale": CompanyScale.INTERNATIONAL,
		"location_id": "city_ny", # 对应纽约
		"preferred_stats": ["talent", "eloquence"],
		"required_cert": ""
	},
	"comp_tv_intl_02": {
		"name": "OmniStream Global (奥姆尼流媒体)", "type": CompanyType.TV, "scale": CompanyScale.INTERNATIONAL,
		"location_id": "city_london", 
		"preferred_stats": ["exposure", "fame"],
		"required_cert": ""
	},

	# ================= 音乐类 =================
	"comp_music_01": {
		"name": "灵动唱片", "type": CompanyType.MUSIC, "scale": CompanyScale.DOMESTIC,
		"location_id": "screen_2",
		"preferred_stats": ["singing", "rebelliousness"],
		"required_cert": ""
	},
	"comp_music_02": {
		"name": "幻音数字音乐", "type": CompanyType.MUSIC, "scale": CompanyScale.DOMESTIC,
		"location_id": "screen_3",
		"preferred_stats": ["singing", "exposure"],
		"required_cert": ""
	},
	"comp_music_03": {
		"name": "空间娱乐音乐", "type": CompanyType.MUSIC, "scale": CompanyScale.DOMESTIC,
		"location_id": "screen_5",
		"preferred_stats": ["singing", "popularity"],
		"required_cert": ""
	},
	"comp_music_intl_01": {
		"name": "环球音浪娱乐", "type": CompanyType.MUSIC, "scale": CompanyScale.INTERNATIONAL,
		"location_id": "city_tokyo", # 对应东京
		"preferred_stats": ["singing", "fame"],
		"required_cert": "cert_music_intl" # 需要音乐国际证
	},
	"comp_music_intl_02": {
		"name": "Billboard打歌台", "type": CompanyType.MUSIC, "scale": CompanyScale.INTERNATIONAL,
		"location_id": "city_seoul", # 对应首尔
		"preferred_stats": ["singing", "talent"],
		"required_cert": ""
	},

	# ================= 广告类 =================
	"comp_ad_01": {
		"name": "蓝图视觉", "type": CompanyType.AD, "scale": CompanyScale.DOMESTIC,
		"location_id": "screen_1", # 对应屏 1：老城生活区
		"preferred_stats": ["affinity", "stamina"],
		"required_cert": ""
	},
	"comp_ad_02": {
		"name": "光谱互动", "type": CompanyType.AD, "scale": CompanyScale.DOMESTIC,
		"location_id": "screen_3",
		"preferred_stats": ["exposure", "fashion"],
		"required_cert": ""
	},
	"comp_ad_03": {
		"name": "吴氏广告传媒", "type": CompanyType.AD, "scale": CompanyScale.DOMESTIC,
		"location_id": "screen_4",
		"preferred_stats": ["fashion", "exposure"],
		"required_cert": ""
	},
	"comp_ad_intl_01": {
		"name": "全域传播 (Omni Global)", "type": CompanyType.AD, "scale": CompanyScale.INTERNATIONAL,
		"location_id": "city_london", # 对应伦敦
		"preferred_stats": ["fame", "eloquence"],
		"required_cert": "cert_model_intl" # 需要模特国际证
	},
	"comp_ad_intl_02": {
		"name": "光环高奢 (Aura Prestige)", "type": CompanyType.AD, "scale": CompanyScale.INTERNATIONAL,
		"location_id": "city_paris", # 对应巴黎
		"preferred_stats": ["deportment", "fashion"],
		"required_cert": "cert_model_intl"
	}
}

# ================= 核心查询函数 =================

## 取得通告／製作公司資料（comp_*）
func get_publisher_info(company_id: String) -> Dictionary:
	return get_company_info(company_id)

## 通告／製作公司顯示名
func get_publisher_name(company_id: String) -> String:
	var info: Dictionary = get_publisher_info(company_id)
	return str(info.get("name", ""))

# 1. 供大地图 UI 调用：获取目标地点(如 screen_3)驻扎的所有通告公司
func get_companies_by_location(target_location_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for comp_id in companies_registry:
		var comp_data = companies_registry[comp_id]
		if comp_data["location_id"] == target_location_id:
			var return_data = comp_data.duplicate()
			return_data["id"] = comp_id # 注入唯一代号
			result.append(return_data)
	return result

# 2. 通过通告公司代号（comp_*）直接获取完整数据
func get_company_info(company_id: String) -> Dictionary:
	if companies_registry.has(company_id):
		return companies_registry[company_id]
	push_error("CompanyDatabase: 找不到通告公司代号 " + company_id)
	return {}
