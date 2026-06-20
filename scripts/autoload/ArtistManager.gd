extends Node

## 艺人总管：分两层管理。
##   1. all_artists —— 全体艺人「静态图纸」(ArtistResource)，开局批量从 data/artists 载入。
##      未签约的艺人也在这里，剧情/资料/聊天照样能引用他们的人设属性。
##   2. roster       —— 已签约艺人的「运行时实例」(ArtistInstance)，可养成、会结算每日状态。
##      上限由 PlayerManager 的公司规模决定；签约 = 把图纸转成运行时实例放进 roster。
##
## 关键设定：签约名单(≤4) 和 剧情可推进的全体艺人 是两个层面。
## 解约只是把人移出 roster，他依旧留在 all_artists 里继续推剧情。

signal artist_signed(artist_id: String)
signal artist_terminated(artist_id: String)
signal roster_changed()

const ARTISTS_DIR: String = "res://data/artists/"
const ABSOLUTE_MAX_ROSTER_SIZE: int = 4

## 全体艺人图纸：artist_id -> ArtistResource
var all_artists: Dictionary = {}
## 已签约 roster：artist_id -> ArtistInstance（运行时养成对象）
var roster: Dictionary = {}
## 開局三選一候選（由資源 opening_pick 在載入時收集）
var _opening_pick_ids: PackedStringArray = PackedStringArray()

func _ready() -> void:
	var count: int = load_all_artists()
	print("[ArtistManager] 全体艺人入册完成，共 %d 人。" % count)

# ==========================================
# 批量加载：开局把 data/artists 下所有图纸读进 all_artists
# ==========================================
func load_all_artists(dir_path: String = ARTISTS_DIR) -> int:
	all_artists.clear()
	_opening_pick_ids = PackedStringArray()
	_load_artist_resources_in_dir(dir_path)
	_opening_pick_ids.sort()
	return all_artists.size()

func _load_artist_resources_in_dir(dir_path: String) -> void:
	var normalized_dir_path: String = dir_path.trim_suffix("/") + "/"

	var dir := DirAccess.open(normalized_dir_path)
	if dir == null:
		push_error("[ArtistManager] 无法打开艺人目录: " + normalized_dir_path)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				_load_artist_resources_in_dir(normalized_dir_path.path_join(file_name))
		else:
			var res_path: String = _normalize_resource_path(normalized_dir_path, file_name)
			if res_path != "":
				var res: Resource = load(res_path)
				if res is ArtistResource:
					_register_resource(res)
				else:
					push_warning("[ArtistManager] 跳过非艺人资源: " + res_path)
		file_name = dir.get_next()
	dir.list_dir_end()

## 把一个 .tres 文件名转成可 load 的资源路径；非艺人图纸返回空字符串。
## 兼容导出后的 .tres.remap（去掉 .remap 后缀即可 load）。
func _normalize_resource_path(dir_path: String, file_name: String) -> String:
	if file_name.ends_with(".tres"):
		return dir_path.path_join(file_name)
	if file_name.ends_with(".tres.remap"):
		return dir_path.path_join(file_name.trim_suffix(".remap"))
	return ""

func _register_resource(resource: ArtistResource) -> void:
	if resource.artist_id == "":
		push_warning("[ArtistManager] 有一个艺人图纸没填 artist_id，已跳过。")
		return
	if all_artists.has(resource.artist_id):
		push_warning("[ArtistManager] 发现重复 artist_id: %s，后者覆盖前者。" % resource.artist_id)
	all_artists[resource.artist_id] = resource
	if resource.opening_pick and not _opening_pick_ids.has(resource.artist_id):
		_opening_pick_ids.append(resource.artist_id)

# ==========================================
# 签约 / 解约
# ==========================================
## 签约：把全体图纸转成运行时实例放进 roster。受公司规模与 4 人硬上限约束。
func sign_artist(artist_id: String, allow_story_override: bool = false) -> bool:
	if not can_player_sign_artist(artist_id, allow_story_override):
		push_warning("[ArtistManager] 签约失败：%s 不可直接签约（需剧情或不在可签名单）。" % artist_id)
		return false
	if not all_artists.has(artist_id):
		push_warning("[ArtistManager] 签约失败：查无此人 " + artist_id)
		return false
	if roster.has(artist_id):
		push_warning("[ArtistManager] 签约失败：%s 已在旗下。" % artist_id)
		return false
	if is_roster_full():
		push_warning("[ArtistManager] 签约失败：当前公司规模上限为 %d 人，请先升级公司或解约腾位。" % get_roster_limit())
		return false

	var resource: ArtistResource = all_artists[artist_id]
	var was_debuted: bool = resource.is_debuted
	var instance := ArtistInstance.new(resource)
	roster[artist_id] = instance

	# 登记初始好感度到关系中枢；默认不覆盖（解约再签保留旧情分）。
	RelationshipManager.register_character(artist_id, resource.affection)

	if not was_debuted:
		resource.is_debuted = true
		resource.home_agency_id = AgencyDatabase.PLAYER_AGENCY_ID
		NewsManager.queue_artist_debut_news(artist_id)

	print("[ArtistManager] 已签约: ", resource.artist_name)
	artist_signed.emit(artist_id)
	roster_changed.emit()
	return true

## 解约：把人移出 roster（释放运行时实例），但仍保留在全体名单里。
func terminate_contract(artist_id: String) -> bool:
	if not roster.has(artist_id):
		push_warning("[ArtistManager] 解约失败：%s 不在旗下。" % artist_id)
		return false

	roster.erase(artist_id)

	print("[ArtistManager] 已解约: ", artist_id)
	artist_terminated.emit(artist_id)
	roster_changed.emit()
	return true

# ==========================================
# 每日推进：只结算已签约艺人（未签约不养成、不会生病罢工）
# ==========================================
func advance_day() -> void:
	for artist_id in roster:
		var artist: ArtistInstance = roster[artist_id]
		if artist == null:
			continue
		artist.process_day_passed()

# ==========================================
# 查询接口
# ==========================================
## 取已签约艺人的运行时实例（养成、每日结算用）；未签约返回 null。
func get_artist(artist_id: String) -> ArtistInstance:
	if roster.has(artist_id):
		return roster[artist_id]
	return null

## 取全体艺人的静态图纸（剧情、资料、聊天用）；查无此人返回 null。
func get_artist_resource(artist_id: String) -> ArtistResource:
	if all_artists.has(artist_id):
		return all_artists[artist_id]
	return null

## 藝人目前所屬經紀公司 id；已簽約為 agency_player，否則讀 ArtistResource.home_agency_id。
func get_artist_agency_id(artist_id: String) -> String:
	if is_signed(artist_id):
		return AgencyDatabase.PLAYER_AGENCY_ID
	var resource: ArtistResource = get_artist_resource(artist_id)
	if resource == null:
		return ""
	return resource.home_agency_id.strip_edges()

## 藝人目前所屬經紀公司顯示名；未設定經紀返回空字串。
func get_artist_agency_name(artist_id: String) -> String:
	var agency_id: String = get_artist_agency_id(artist_id)
	if agency_id == "":
		return ""
	return AgencyDatabase.get_agency_display_name(agency_id)

## 小頭像（列表、存檔槽、對話框旁小圖）
func get_artist_avatar(artist_id: String) -> Texture2D:
	var resource: ArtistResource = get_artist_resource(artist_id)
	if resource == null:
		return null
	if resource.avatar != null:
		return resource.avatar
	return CharacterVisualPaths.try_load_texture(CharacterVisualPaths.avatar_path(artist_id))

## 半身立繪（對話、簽約、會議大圖）
func get_artist_portrait(artist_id: String) -> Texture2D:
	var resource: ArtistResource = get_artist_resource(artist_id)
	if resource == null:
		return null
	if resource.portrait != null:
		return resource.portrait
	if resource.avatar != null:
		return resource.avatar
	return CharacterVisualPaths.try_load_texture(CharacterVisualPaths.portrait_path(artist_id))

func get_artist_profile(artist_id: String) -> ArtistProfileResource:
	var resource: ArtistResource = get_artist_resource(artist_id)
	if resource == null:
		return null
	return resource.get_character_profile()

func is_signed(artist_id: String) -> bool:
	return roster.has(artist_id)

func is_roster_full() -> bool:
	return roster.size() >= get_roster_limit()

func get_roster_limit() -> int:
	return mini(PlayerManager.get_roster_limit(), ABSOLUTE_MAX_ROSTER_SIZE)

func get_signed_count() -> int:
	return roster.size()

func get_all_artist_ids() -> Array:
	return all_artists.keys()

func get_signed_ids() -> Array:
	return roster.keys()

## 我方藝人 id 列表（artist_001～016，data/artists 全員）。
func get_agency_artist_ids() -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	for artist_id in all_artists.keys():
		ids.append(str(artist_id))
	ids.sort()
	return ids

## 是否允许进入玩家 roster（不含剧情 override）。rival_* 永不可签。
func can_player_sign_artist(artist_id: String, allow_story_override: bool = false) -> bool:
	if RivalManager.is_rival_id(artist_id):
		return false
	if allow_story_override:
		return all_artists.has(artist_id)
	var resource: ArtistResource = get_artist_resource(artist_id)
	if resource == null:
		return false
	if not CharacterDatabase.is_agency_artist_id(artist_id):
		return false
	if resource.opening_pick:
		return not GameFlowManager.is_initial_sign_completed()
	if resource.fixed_story_join or resource.poachable_in:
		return false
	return true

## 剧情触发的签约（固定加入／挖角等），绕过 can_player_sign 门禁。
func sign_artist_via_story(artist_id: String) -> bool:
	return sign_artist(artist_id, true)

func get_fixed_story_join_artist_ids() -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	for artist_id in all_artists.keys():
		var resource: ArtistResource = all_artists[artist_id]
		if resource != null and resource.fixed_story_join:
			ids.append(str(artist_id))
	ids.sort()
	return ids

func get_poachable_in_artist_ids() -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	for artist_id in all_artists.keys():
		var resource: ArtistResource = all_artists[artist_id]
		if resource != null and resource.poachable_in:
			ids.append(str(artist_id))
	ids.sort()
	return ids

func get_poachable_out_artist_ids() -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	for artist_id in all_artists.keys():
		var resource: ArtistResource = all_artists[artist_id]
		if resource != null and resource.poachable_out:
			ids.append(str(artist_id))
	ids.sort()
	return ids

func get_sibling_partner_id(artist_id: String) -> String:
	var resource: ArtistResource = get_artist_resource(artist_id)
	if resource == null:
		return ""
	return resource.sibling_partner_id.strip_edges()

func get_sibling_pair_ids(artist_id: String) -> PackedStringArray:
	var partner_id: String = get_sibling_partner_id(artist_id)
	if partner_id == "":
		return PackedStringArray()
	return PackedStringArray([artist_id.strip_edges(), partner_id])

func get_initial_signable_artist_ids() -> PackedStringArray:
	return _opening_pick_ids

func get_initial_signable_artist_resources() -> Array[ArtistResource]:
	var resources: Array[ArtistResource] = []
	for artist_id in _opening_pick_ids:
		var resource: ArtistResource = get_artist_resource(artist_id)
		if resource != null:
			resources.append(resource)
	return resources

func is_initial_signable_artist(artist_id: String) -> bool:
	return _opening_pick_ids.has(artist_id)

## 開局 3 選 1：簽約首位藝人（不走難度判定，僅限候選三人且僅能執行一次）。
func sign_initial_artist(artist_id: String) -> bool:
	if GameFlowManager.is_initial_sign_completed():
		push_warning("[ArtistManager] 開局簽約已完成，不可重複。")
		return false
	if not is_initial_signable_artist(artist_id):
		push_warning("[ArtistManager] 開局簽約失敗：%s 不在候選名單。" % artist_id)
		return false
	if not sign_artist(artist_id):
		return false
	GameFlowManager.mark_initial_sign_completed()
	return true

# ==========================================
# 兼容旧接口（早期测试用）：加入全体并立即签约
# ==========================================
func register_artist(resource: ArtistResource) -> void:
	if resource == null:
		return
	_register_resource(resource)
	sign_artist(resource.artist_id)

const RUNTIME_STAT_NAMES: Array[String] = [
	"empathy", "timbre", "improvisation", "acting", "singing", "eloquence",
	"dynamism", "talent", "stamina", "deportment", "fashion", "confidence",
	"rebelliousness", "humor", "affinity", "fame", "popularity", "exposure", "morality",
]

func export_save_state() -> Dictionary:
	var payload: Dictionary = {}
	for artist_id in roster:
		var artist: ArtistInstance = roster[artist_id]
		if artist == null:
			continue
		payload[artist_id] = _export_artist_instance(artist)
	return payload

func import_save_state(data: Dictionary) -> void:
	_clear_roster_instances()
	if data == null:
		roster_changed.emit()
		return

	for artist_id in data:
		var clean_id: String = str(artist_id).strip_edges()
		if clean_id == "" or not all_artists.has(clean_id):
			push_warning("[ArtistManager] 读档跳过未知艺人: %s" % clean_id)
			continue

		var resource: ArtistResource = all_artists[clean_id]
		var instance := ArtistInstance.new(resource)
		_apply_artist_instance_state(instance, data[clean_id])
		roster[clean_id] = instance

	roster_changed.emit()

func _clear_roster_instances() -> void:
	for artist_id in roster.keys():
		roster.erase(artist_id)

func _export_artist_instance(artist: ArtistInstance) -> Dictionary:
	var payload: Dictionary = {
		"satisfaction": artist.satisfaction,
		"health": {
			"fatigue": artist.health.fatigue,
			"current_state": artist.health.current_state,
			"rest_days_remaining": artist.health.rest_days_remaining,
			"is_post_hospital_rest": artist.health.is_post_hospital_rest,
		},
		"mood": {
			"stress": artist.mood.stress,
			"current_state": artist.mood.current_state,
		},
	}
	for stat_name in RUNTIME_STAT_NAMES:
		payload[stat_name] = artist.get(stat_name)
	return payload

func _apply_artist_instance_state(artist: ArtistInstance, data: Dictionary) -> void:
	if data == null:
		return

	artist.satisfaction = clampi(int(data.get("satisfaction", artist.satisfaction)), 0, 100)
	for stat_name in RUNTIME_STAT_NAMES:
		if data.has(stat_name):
			artist.set(stat_name, clampi(int(data[stat_name]), 0, 999))

	var health_data: Variant = data.get("health", {})
	if health_data is Dictionary:
		artist.health.fatigue = clampi(int(health_data.get("fatigue", artist.health.fatigue)), 0, 100)
		artist.health.current_state = int(
			health_data.get("current_state", artist.health.current_state)
		) as ArtistHealthComponent.PhysicalState
		artist.health.rest_days_remaining = maxi(int(health_data.get("rest_days_remaining", 0)), 0)
		artist.health.is_post_hospital_rest = bool(health_data.get("is_post_hospital_rest", false))

	var mood_data: Variant = data.get("mood", {})
	if mood_data is Dictionary:
		artist.mood.stress = clampi(int(mood_data.get("stress", artist.mood.stress)), 0, 100)
		artist.mood.current_state = int(
			mood_data.get("current_state", artist.mood.current_state)
		) as ArtistMoodComponent.MoodState
