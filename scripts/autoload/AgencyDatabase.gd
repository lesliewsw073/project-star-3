extends Node

## 經紀公司註冊表：負責簽約藝人，不發布通告。
## 玩家公司邏輯 id 固定為 agency_player，顯示名由 PlayerManager 提供。

const PLAYER_AGENCY_ID: String = "agency_player"

const NPC_AGENCY_IDS: PackedStringArray = [
	"agency_001",
	"agency_002",
	"agency_003",
	"agency_004",
	"agency_005",
]

enum AgencyScale { SMALL, MEDIUM, LARGE, MEGA }

# Key: agency_id → 靜態資料（name 為占位，後續可改）
var agencies_registry: Dictionary = {
	"agency_001": {
		"name": "索尼",
		"scale": AgencyScale.LARGE,
	},
	"agency_002": {
		"name": "滚石",
		"scale": AgencyScale.MEDIUM,
	},
	"agency_003": {
		"name": "卢卡斯",
		"scale": AgencyScale.LARGE,
	},
	"agency_004": {
		"name": "迪士尼",
		"scale": AgencyScale.MEGA,
	},
	"agency_005": {
		"name": "华纳",
		"scale": AgencyScale.LARGE,
	},
}

func is_player_agency(agency_id: String) -> bool:
	return agency_id.strip_edges() == PLAYER_AGENCY_ID

func is_npc_agency(agency_id: String) -> bool:
	return agencies_registry.has(agency_id.strip_edges())

func get_npc_agency_ids() -> PackedStringArray:
	return NPC_AGENCY_IDS

func get_agency_info(agency_id: String) -> Dictionary:
	var clean_id: String = agency_id.strip_edges()
	if clean_id == "":
		return {}
	if is_player_agency(clean_id):
		return {
			"id": PLAYER_AGENCY_ID,
			"name": PlayerManager.get_company_name(),
			"scale": PlayerManager.company_scale,
			"is_player": true,
		}
	if agencies_registry.has(clean_id):
		var data: Dictionary = agencies_registry[clean_id].duplicate()
		data["id"] = clean_id
		data["is_player"] = false
		return data
	push_warning("[AgencyDatabase] 找不到經紀公司 id：%s" % clean_id)
	return {}

func get_agency_display_name(agency_id: String) -> String:
	var info: Dictionary = get_agency_info(agency_id)
	return str(info.get("name", ""))

func get_agency_scale_name(agency_id: String) -> String:
	if is_player_agency(agency_id):
		return PlayerManager.get_company_scale_name()
	var info: Dictionary = get_agency_info(agency_id)
	var scale: int = int(info.get("scale", AgencyScale.SMALL))
	match scale:
		AgencyScale.SMALL:
			return "小型"
		AgencyScale.MEDIUM:
			return "中型"
		AgencyScale.LARGE:
			return "大型"
		AgencyScale.MEGA:
			return "特大型"
		_:
			return "未知"

func get_all_npc_agencies() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for agency_id in NPC_AGENCY_IDS:
		var info: Dictionary = get_agency_info(agency_id)
		if not info.is_empty():
			result.append(info)
	return result
