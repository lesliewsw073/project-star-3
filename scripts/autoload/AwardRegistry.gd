extends Node

## 獎項全局表（占位）。
## 規格：每個獎項頒發前 7 天出預熱新聞，列出 3 名候選人／公司。

const PREVIEW_DAYS_BEFORE: int = 7
const CANDIDATE_COUNT: int = 3

var _awards: Array[Dictionary] = []

func _ready() -> void:
	print("[AwardRegistry] 獎項全局占位就緒（待企劃填表）。")

func register_award(award_data: Dictionary) -> void:
	var award_id: String = str(award_data.get("award_id", "")).strip_edges()
	if award_id == "":
		return
	for index in range(_awards.size()):
		if str(_awards[index].get("award_id", "")) == award_id:
			_awards[index] = award_data.duplicate(true)
			return
	_awards.append(award_data.duplicate(true))

func get_all_awards() -> Array[Dictionary]:
	return _awards.duplicate(true)

func get_preview_awards_for_date(date_snapshot: Dictionary) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var total_days: int = int(date_snapshot.get("total_days_elapsed", 0))
	for award in _awards:
		var ceremony_day: int = int(award.get("ceremony_day", -1))
		if ceremony_day < 0:
			continue
		if total_days + PREVIEW_DAYS_BEFORE != ceremony_day:
			continue
		results.append(award.duplicate(true))
	return results

func get_ceremony_awards_for_date(date_snapshot: Dictionary) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var total_days: int = int(date_snapshot.get("total_days_elapsed", 0))
	for award in _awards:
		var ceremony_day: int = int(award.get("ceremony_day", -1))
		if ceremony_day == total_days:
			results.append(award.duplicate(true))
	return results

func build_preview_candidates(_award: Dictionary) -> Array[String]:
	## 占位：正式版從候選池讀取 3 名。
	var pool: Array[String] = ["agency_player", "agency_001", "agency_002", "agency_003"]
	pool.shuffle()
	return pool.slice(0, mini(CANDIDATE_COUNT, pool.size()))
