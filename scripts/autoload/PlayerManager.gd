extends Node

enum CompanyScale { SMALL, MEDIUM, LARGE, MEGA }

const COMPANY_SCALE_RULES: Dictionary = {
	CompanyScale.SMALL: {
		"name": "小型",
		"roster_limit": 2,
	},
	CompanyScale.MEDIUM: {
		"name": "中型",
		"roster_limit": 2,
		"required_money": 200000,
		"required_reputation": 100,
		"required_completed_jobs": 5,
		"required_perfect_jobs": 0,
		"upgrade_cost": 50000,
	},
	CompanyScale.LARGE: {
		"name": "大型",
		"roster_limit": 3,
		"required_money": 800000,
		"required_reputation": 400,
		"required_completed_jobs": 20,
		"required_perfect_jobs": 0,
		"upgrade_cost": 200000,
	},
	CompanyScale.MEGA: {
		"name": "特大型",
		"roster_limit": 4,
		"required_money": 2000000,
		"required_reputation": 1000,
		"required_completed_jobs": 50,
		"required_perfect_jobs": 2,
		"upgrade_cost": 500000,
	},
}

# 基础信息（开局可被玩家修改，确认后锁定）
var player_name: String = "制作人"
var company_name: String = ""
var company_name_locked: bool = false

# 核心资产
var money: int = 100000 ## 金幣（虛構貨幣，非真實貨幣）
var company_reputation: int = 0 ## 聲望：影響公司規模；正向經營累積（細則待埋）
var company_public_opinion: int = 0 ## 口碑：影響簽約難度、頒獎資格等；**不影響公司規模**（細則待埋）
var company_scale: int = CompanyScale.SMALL

# 经营统计（成功 + 完美；失败单独计）
var successful_jobs_count: int = 0
var failed_jobs_count: int = 0
var perfect_jobs_count: int = 0
var successful_gigs_count: int = 0
var failed_gigs_count: int = 0
var perfect_gigs_count: int = 0
var successful_courses_count: int = 0
var failed_courses_count: int = 0
var perfect_courses_count: int = 0

## 提供给全局的改名接口
func set_player_name(new_name: String) -> void:
	if new_name.strip_edges() != "":
		player_name = new_name

func set_company_name(new_name: String) -> bool:
	if company_name_locked:
		push_warning("[PlayerManager] 公司名稱已鎖定，無法修改。")
		return false
	if new_name.strip_edges() == "":
		return false
	company_name = new_name.strip_edges()
	return true

func finalize_company_name(new_name: String) -> bool:
	if company_name_locked:
		push_warning("[PlayerManager] 公司名稱已鎖定。")
		return false
	var clean: String = new_name.strip_edges()
	if clean == "":
		return false
	company_name = clean
	company_name_locked = true
	return true

func is_company_name_locked() -> bool:
	return company_name_locked

func get_company_name() -> String:
	return company_name

# ==========================================
# 资金
# ==========================================
func add_money(amount: int, reason: String = "") -> void:
	var safe_amount: int = maxi(amount, 0)
	if safe_amount <= 0:
		return
	money += safe_amount
	_print_change("资金增加", safe_amount, reason)

func spend_money(amount: int, reason: String = "") -> bool:
	var safe_amount: int = maxi(amount, 0)
	if safe_amount <= 0:
		return true
	if not can_afford(safe_amount):
		push_warning("[PlayerManager] 资金不足，无法支出 %d。用途：%s" % [safe_amount, reason])
		return false

	money -= safe_amount
	_print_change("资金支出", safe_amount, reason)
	return true

func can_afford(amount: int) -> bool:
	return money >= maxi(amount, 0)

# ==========================================
# 公司声望
# ==========================================
func add_reputation(amount: int, reason: String = "") -> void:
	var safe_amount: int = maxi(amount, 0)
	if safe_amount <= 0:
		return
	company_reputation += safe_amount
	_print_change("声望增加", safe_amount, reason)

func reduce_reputation(amount: int, reason: String = "") -> void:
	var safe_amount: int = maxi(amount, 0)
	if safe_amount <= 0:
		return
	company_reputation = maxi(company_reputation - safe_amount, 0)
	_print_change("声望减少", safe_amount, reason)

# ==========================================
# 公司口碑
# ==========================================
func add_public_opinion(amount: int, reason: String = "") -> void:
	var safe_amount: int = maxi(amount, 0)
	if safe_amount <= 0:
		return
	company_public_opinion += safe_amount
	_print_change("口碑增加", safe_amount, reason)

func reduce_public_opinion(amount: int, reason: String = "") -> void:
	var safe_amount: int = maxi(amount, 0)
	if safe_amount <= 0:
		return
	company_public_opinion = maxi(company_public_opinion - safe_amount, 0)
	_print_change("口碑减少", safe_amount, reason)

# ==========================================
# 通告统计
# ==========================================
func record_job_completed(completion_quality: int) -> void:
	if not CompletionQuality.is_completed_outcome(completion_quality):
		return
	successful_jobs_count += 1
	if completion_quality == CompletionQuality.Level.PERFECT:
		perfect_jobs_count += 1

func record_job_failed() -> void:
	failed_jobs_count += 1

func record_gig_completed(completion_quality: int) -> void:
	if not CompletionQuality.is_completed_outcome(completion_quality):
		return
	successful_gigs_count += 1
	if completion_quality == CompletionQuality.Level.PERFECT:
		perfect_gigs_count += 1

func record_gig_failed() -> void:
	failed_gigs_count += 1

func record_course_completed(completion_quality: int) -> void:
	if not CompletionQuality.is_completed_outcome(completion_quality):
		return
	successful_courses_count += 1
	if completion_quality == CompletionQuality.Level.PERFECT:
		perfect_courses_count += 1

func record_course_failed() -> void:
	failed_courses_count += 1

# ==========================================
# 公司规模
# ==========================================
func get_company_scale_name(scale: int = -1) -> String:
	var target_scale: int = company_scale if scale < 0 else scale
	if COMPANY_SCALE_RULES.has(target_scale):
		return COMPANY_SCALE_RULES[target_scale]["name"]
	return "未知"

func get_roster_limit(scale: int = -1) -> int:
	var target_scale: int = company_scale if scale < 0 else scale
	if COMPANY_SCALE_RULES.has(target_scale):
		return COMPANY_SCALE_RULES[target_scale]["roster_limit"]
	return 0

func is_max_company_scale() -> bool:
	return company_scale >= CompanyScale.MEGA

func get_next_company_scale() -> int:
	if is_max_company_scale():
		return company_scale
	return company_scale + 1

func get_upgrade_requirements(target_scale: int = -1) -> Dictionary:
	var scale: int = target_scale
	if scale < 0:
		scale = get_next_company_scale()
	if not COMPANY_SCALE_RULES.has(scale) or scale == CompanyScale.SMALL:
		return {}
	return COMPANY_SCALE_RULES[scale]

func can_upgrade_company() -> bool:
	if is_max_company_scale():
		return false

	var req: Dictionary = get_upgrade_requirements()
	if req.is_empty():
		return false

	return (
		money >= req["required_money"]
		and company_reputation >= req["required_reputation"]
		and successful_jobs_count >= req["required_completed_jobs"]
		and perfect_jobs_count >= req["required_perfect_jobs"]
		and can_afford(req["upgrade_cost"])
	)

func upgrade_company(result: Dictionary = {}) -> bool:
	if is_max_company_scale():
		push_warning("[PlayerManager] 公司已是最高规模。")
		return false
	if not can_upgrade_company():
		push_warning("[PlayerManager] 公司升级条件未满足。")
		return false

	var old_scale: int = company_scale
	var target_scale: int = get_next_company_scale()
	var req: Dictionary = get_upgrade_requirements(target_scale)
	if not spend_money(req["upgrade_cost"], "公司规模升级"):
		return false

	company_scale = target_scale
	result["old_scale"] = old_scale
	result["new_scale"] = target_scale
	result["upgrade_cost"] = req["upgrade_cost"]
	print("[PlayerManager] 公司已升级为%s公司。" % get_company_scale_name())
	return true

func get_upgrade_status_lines() -> Array[String]:
	if is_max_company_scale():
		return ["公司已达到最高规模。"]

	var target_scale: int = get_next_company_scale()
	var req: Dictionary = get_upgrade_requirements(target_scale)
	return [
		"下一规模：%s" % get_company_scale_name(target_scale),
		"签约上限：%d → %d 人" % [get_roster_limit(), get_roster_limit(target_scale)],
		"资金：%d / %d" % [money, req["required_money"]],
		"声望：%d / %d" % [company_reputation, req["required_reputation"]],
		"口碑：%d" % company_public_opinion,
		"完成通告：%d / %d" % [successful_jobs_count, req["required_completed_jobs"]],
		"完美通告：%d / %d" % [perfect_jobs_count, req["required_perfect_jobs"]],
		"失败通告：%d" % failed_jobs_count,
		"升级费用：%d" % req["upgrade_cost"],
	]

func _print_change(label: String, amount: int, reason: String) -> void:
	if reason.strip_edges() == "":
		print("[PlayerManager] %s：%d" % [label, amount])
	else:
		print("[PlayerManager] %s：%d（%s）" % [label, amount, reason])

func export_save_state() -> Dictionary:
	return {
		"player_name": player_name,
		"company_name": company_name,
		"company_name_locked": company_name_locked,
		"money": money,
		"company_reputation": company_reputation,
		"company_public_opinion": company_public_opinion,
		"company_scale": company_scale,
		"successful_jobs_count": successful_jobs_count,
		"failed_jobs_count": failed_jobs_count,
		"perfect_jobs_count": perfect_jobs_count,
		"successful_gigs_count": successful_gigs_count,
		"failed_gigs_count": failed_gigs_count,
		"perfect_gigs_count": perfect_gigs_count,
		"successful_courses_count": successful_courses_count,
		"failed_courses_count": failed_courses_count,
		"perfect_courses_count": perfect_courses_count,
	}

func import_save_state(data: Dictionary) -> void:
	if data == null:
		return
	player_name = str(data.get("player_name", player_name))
	company_name = str(data.get("company_name", company_name))
	company_name_locked = bool(data.get("company_name_locked", company_name_locked))
	if not company_name_locked and company_name.strip_edges() != "":
		company_name_locked = true
	money = int(data.get("money", money))
	company_reputation = int(data.get("company_reputation", company_reputation))
	company_public_opinion = int(data.get("company_public_opinion", company_public_opinion))
	company_scale = int(data.get("company_scale", company_scale))
	successful_jobs_count = int(data.get("successful_jobs_count", successful_jobs_count))
	failed_jobs_count = int(data.get("failed_jobs_count", failed_jobs_count))
	perfect_jobs_count = int(data.get("perfect_jobs_count", perfect_jobs_count))
	successful_gigs_count = int(data.get("successful_gigs_count", successful_gigs_count))
	failed_gigs_count = int(data.get("failed_gigs_count", failed_gigs_count))
	perfect_gigs_count = int(data.get("perfect_gigs_count", perfect_gigs_count))
	successful_courses_count = int(data.get("successful_courses_count", successful_courses_count))
	failed_courses_count = int(data.get("failed_courses_count", failed_courses_count))
	perfect_courses_count = int(data.get("perfect_courses_count", perfect_courses_count))
