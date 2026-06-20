extends Node

## 关系管理器（RelationshipManager）
## 唯一职责：保存「每个角色 → 男主角」的亲密度，并对外提供唯一的读/写入口。
## 艺人、秘书、未来所有 NPC 的亲密度都收纳在这里，主角是所有关系的唯一锚点。
##
## 防 bug 设计（针对循环/溢出，务必保持）：
##   1) 严格单向依赖：本管理器只操作自己的字典，绝不反向调用 ArtistInstance /
##      SecretaryManager / ArtistManager 等任何角色对象。外部 → 本管理器，永不回头，
##      从结构上杜绝调用环。
##   2) 数值恒定夹紧在 [0,100]：杜绝数值溢出 / 无限增长。
##   3) 信号只在「值真的变了」时才发：单调推动的反馈最终被夹紧而收敛，自动断环。
##   4) 重入护栏 _is_emitting：信号处理函数若回写亲密度，只落库、不再次派发信号，
##      彻底杜绝「改值 → 发信号 → 又改值 → 又发信号」的栈溢出 / 死循环。

signal affection_changed(character_id: String, new_value: int, old_value: int)
signal relationship_level_changed(character_id: String, new_level: int)

const MIN_AFFECTION: int = 0
const MAX_AFFECTION: int = 100

enum RelationshipLevel { STRANGER, ACQUAINTANCE, FRIEND, CLOSE, INTIMATE }

## 各等级下界（含）。判定时从高到低比对。
const LEVEL_FLOOR: Dictionary = {
	RelationshipLevel.INTIMATE: 90,
	RelationshipLevel.CLOSE: 70,
	RelationshipLevel.FRIEND: 40,
	RelationshipLevel.ACQUAINTANCE: 20,
	RelationshipLevel.STRANGER: 0,
}

## 「亲密称呼」起始等级：CLOSE 及以上才会直呼其名 / 用昵称。
const FIRST_NAME_LEVEL: int = RelationshipLevel.CLOSE

# character_id(String) -> affection(int)
var _affection: Dictionary = {}
# character_id(String) -> level(int)，避免每次重算并用于判定等级跃迁
var _level_cache: Dictionary = {}
# 重入护栏：正在派发信号时为 true
var _is_emitting: bool = false

func _ready() -> void:
	print("[RelationshipManager] 就绪，亲密度中枢上线。")

# ==========================================
# 注册 / 查询（只读，绝不触发回调）
# ==========================================
## 登记一个角色的初始亲密度。默认不覆盖已有关系（解约再签不会清零旧情分）。
func register_character(character_id: String, initial_affection: int = 0, overwrite: bool = false) -> void:
	if character_id == "":
		push_warning("[RelationshipManager] 注册失败：character_id 为空。")
		return
	if _affection.has(character_id) and not overwrite:
		return
	set_affection(character_id, initial_affection)

func has_character(character_id: String) -> bool:
	return _affection.has(character_id)

func get_affection(character_id: String) -> int:
	return int(_affection.get(character_id, 0))

func get_relationship_level(character_id: String) -> int:
	return _level_for_value(get_affection(character_id))

func get_relationship_level_name(character_id: String) -> String:
	match get_relationship_level(character_id):
		RelationshipLevel.INTIMATE:
			return "亲密"
		RelationshipLevel.CLOSE:
			return "亲近"
		RelationshipLevel.FRIEND:
			return "朋友"
		RelationshipLevel.ACQUAINTANCE:
			return "相识"
		_:
			return "陌生"

## 是否到了可直呼其名 / 用昵称的程度（供称呼系统查询）。
func should_use_first_name(character_id: String) -> bool:
	return get_relationship_level(character_id) >= FIRST_NAME_LEVEL

## 一次性导出全部关系快照（存档 / 调试用），返回的是拷贝。
func get_all_affection() -> Dictionary:
	return _affection.duplicate()

# ==========================================
# 写入（唯一入口，全部经此夹紧与门控）
# ==========================================
func set_affection(character_id: String, value: int) -> void:
	if character_id == "":
		return

	var old_value: int = int(_affection.get(character_id, 0))
	var new_value: int = clampi(value, MIN_AFFECTION, MAX_AFFECTION)

	# 不论变没变，先把最新值落库，保证 has_character / 后续读取一致。
	_affection[character_id] = new_value

	# 值没变 → 不发信号。这是「单调反馈收敛」断环的关键。
	if new_value == old_value:
		# 仍补上等级缓存，方便后续跃迁判定。
		if not _level_cache.has(character_id):
			_level_cache[character_id] = _level_for_value(new_value)
		return

	# 重入护栏：若当前正在派发信号（说明是某个监听器回写进来的），
	# 只落库、不再次派发，从根上杜绝递归死循环 / 栈溢出。
	if _is_emitting:
		return

	_is_emitting = true
	affection_changed.emit(character_id, new_value, old_value)

	var new_level: int = _level_for_value(new_value)
	var old_level: int = int(_level_cache.get(character_id, _level_for_value(old_value)))
	_level_cache[character_id] = new_level
	if new_level != old_level:
		relationship_level_changed.emit(character_id, new_level)

	_is_emitting = false

## 增减亲密度（amount 可正可负）；内部仍走 set_affection 完成夹紧与门控。
func add_affection(character_id: String, amount: int) -> void:
	if character_id == "":
		return
	if amount == 0:
		# 即便不变，也确保该角色已建档。
		if not _affection.has(character_id):
			set_affection(character_id, 0)
		return
	set_affection(character_id, get_affection(character_id) + amount)

# ==========================================
# 内部工具
# ==========================================
func _level_for_value(value: int) -> int:
	if value >= int(LEVEL_FLOOR[RelationshipLevel.INTIMATE]):
		return RelationshipLevel.INTIMATE
	if value >= int(LEVEL_FLOOR[RelationshipLevel.CLOSE]):
		return RelationshipLevel.CLOSE
	if value >= int(LEVEL_FLOOR[RelationshipLevel.FRIEND]):
		return RelationshipLevel.FRIEND
	if value >= int(LEVEL_FLOOR[RelationshipLevel.ACQUAINTANCE]):
		return RelationshipLevel.ACQUAINTANCE
	return RelationshipLevel.STRANGER

func export_save_state() -> Dictionary:
	return get_all_affection()

func import_save_state(data: Dictionary) -> void:
	_affection.clear()
	_level_cache.clear()
	if data == null:
		return
	for character_id in data:
		var clean_id: String = str(character_id).strip_edges()
		if clean_id == "":
			continue
		var value: int = clampi(int(data[character_id]), MIN_AFFECTION, MAX_AFFECTION)
		_affection[clean_id] = value
		_level_cache[clean_id] = _level_for_value(value)
