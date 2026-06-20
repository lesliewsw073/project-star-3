extends Node

## 角色身分中樞：protagonist / secretary / artist_001～016（我方）/ rival_NNN / npc_*（劇情 NPC）
## 注意：勿加 class_name，與 Autoload「CharacterDatabase」同名會遮蔽 singleton。

enum CharacterKind {
	UNKNOWN,
	PROTAGONIST,
	SECRETARY,
	REPORTER,
	AGENCY_ARTIST,
	RIVAL,
	STORY_NPC,
	BACKGROUND,
}

const DEFAULT_NON_PLAYER_AFFECTION: int = 10
const AGENCY_ARTIST_ID_PATTERN: String = "^artist_\\d{3}$"

func _ready() -> void:
	_register_core_relationships()
	print("[CharacterDatabase] 核心角色關係已登記。")

func get_kind(character_id: String) -> CharacterKind:
	var clean_id: String = character_id.strip_edges()
	if clean_id == "":
		return CharacterKind.UNKNOWN
	if clean_id == ProtagonistManager.PROTAGONIST_ID:
		return CharacterKind.PROTAGONIST
	if clean_id == SecretaryManager.SECRETARY_ID:
		return CharacterKind.SECRETARY
	if ReporterManager.is_reporter_id(clean_id):
		return CharacterKind.REPORTER
	if is_agency_artist_id(clean_id):
		return CharacterKind.AGENCY_ARTIST
	if RivalManager.is_rival_id(clean_id):
		return CharacterKind.RIVAL
	if NpcManager.is_story_npc_id(clean_id):
		return CharacterKind.STORY_NPC
	return CharacterKind.UNKNOWN

func is_agency_artist_id(character_id: String) -> bool:
	var clean_id: String = character_id.strip_edges()
	return RegEx.create_from_string(AGENCY_ARTIST_ID_PATTERN).search(clean_id) != null

func is_agency_artist(character_id: String) -> bool:
	return get_kind(character_id) == CharacterKind.AGENCY_ARTIST

func is_rival(character_id: String) -> bool:
	return get_kind(character_id) == CharacterKind.RIVAL

func is_story_npc(character_id: String) -> bool:
	return get_kind(character_id) == CharacterKind.STORY_NPC

func is_protagonist(character_id: String) -> bool:
	return get_kind(character_id) == CharacterKind.PROTAGONIST

func is_secretary(character_id: String) -> bool:
	return get_kind(character_id) == CharacterKind.SECRETARY

func is_reporter(character_id: String) -> bool:
	return get_kind(character_id) == CharacterKind.REPORTER

## 我方藝人或競爭對手；不含主角／秘書／NPC。
func is_performer(character_id: String) -> bool:
	var kind: int = get_kind(character_id)
	return kind == CharacterKind.AGENCY_ARTIST or kind == CharacterKind.RIVAL

func get_performer_resource(character_id: String) -> ArtistResource:
	var resource: ArtistResource = ArtistManager.get_artist_resource(character_id)
	if resource != null:
		return resource
	return RivalManager.get_rival_resource(character_id)

func get_npc_resource(character_id: String) -> NPCResource:
	return NpcManager.get_npc_resource(character_id)

func get_display_name(character_id: String) -> String:
	match get_kind(character_id):
		CharacterKind.PROTAGONIST:
			return ProtagonistManager.get_full_name()
		CharacterKind.SECRETARY:
			return SecretaryManager.get_display_name()
		CharacterKind.REPORTER:
			return ReporterManager.get_display_name(character_id)
		CharacterKind.AGENCY_ARTIST, CharacterKind.RIVAL:
			var resource: ArtistResource = get_performer_resource(character_id)
			if resource != null and resource.artist_name.strip_edges() != "":
				return resource.artist_name.strip_edges()
		CharacterKind.STORY_NPC:
			return NpcManager.get_npc_display_name(character_id)
	return character_id.strip_edges()

func get_avatar(character_id: String) -> Texture2D:
	match get_kind(character_id):
		CharacterKind.SECRETARY:
			return SecretaryManager.get_avatar()
		CharacterKind.REPORTER:
			return ReporterManager.get_avatar(character_id)
		CharacterKind.AGENCY_ARTIST:
			return ArtistManager.get_artist_avatar(character_id)
		CharacterKind.RIVAL:
			return RivalManager.get_rival_avatar(character_id)
		CharacterKind.STORY_NPC:
			return NpcManager.get_npc_avatar(character_id)
		_:
			return null

func get_portrait(character_id: String) -> Texture2D:
	match get_kind(character_id):
		CharacterKind.SECRETARY:
			return SecretaryManager.get_portrait()
		CharacterKind.REPORTER:
			return ReporterManager.get_portrait(character_id)
		CharacterKind.AGENCY_ARTIST:
			return ArtistManager.get_artist_portrait(character_id)
		CharacterKind.RIVAL:
			return RivalManager.get_rival_portrait(character_id)
		CharacterKind.STORY_NPC:
			return NpcManager.get_npc_portrait(character_id)
		_:
			return null

func get_cg_texture(owner_id: String, cg_id: String) -> Texture2D:
	var clean_owner_id: String = owner_id.strip_edges()
	var key: String = cg_id.strip_edges()
	if clean_owner_id == "" or key == "":
		return null
	return CharacterVisualPaths.try_load_texture(CharacterVisualPaths.cg_path(clean_owner_id, key))

func get_initial_affection(character_id: String) -> int:
	match get_kind(character_id):
		CharacterKind.PROTAGONIST:
			return 0
		CharacterKind.SECRETARY, CharacterKind.RIVAL:
			return DEFAULT_NON_PLAYER_AFFECTION
		CharacterKind.REPORTER:
			return 0
		CharacterKind.AGENCY_ARTIST:
			var artist_resource: ArtistResource = ArtistManager.get_artist_resource(character_id)
			if artist_resource != null and artist_resource.affection > 0:
				return clampi(
					artist_resource.affection,
					RelationshipManager.MIN_AFFECTION,
					RelationshipManager.MAX_AFFECTION
				)
			return DEFAULT_NON_PLAYER_AFFECTION
		CharacterKind.STORY_NPC:
			return NpcManager.get_npc_initial_affection(character_id)
		_:
			return DEFAULT_NON_PLAYER_AFFECTION

func get_role_label(character_id: String) -> String:
	match get_kind(character_id):
		CharacterKind.PROTAGONIST:
			return "主角"
		CharacterKind.SECRETARY:
			return "秘書"
		CharacterKind.REPORTER:
			return "記者"
		CharacterKind.AGENCY_ARTIST:
			if ArtistManager.is_signed(character_id):
				return "旗下藝人"
			return "我方藝人"
		CharacterKind.RIVAL:
			return "競爭對手"
		CharacterKind.STORY_NPC:
			return "NPC"
		_:
			return "未知"

func get_agency_name_for_character(character_id: String) -> String:
	match get_kind(character_id):
		CharacterKind.AGENCY_ARTIST:
			return ArtistManager.get_artist_agency_name(character_id)
		CharacterKind.RIVAL:
			return RivalManager.get_rival_agency_name(character_id)
		_:
			return ""

func _register_core_relationships() -> void:
	RelationshipManager.register_character(
		SecretaryManager.SECRETARY_ID,
		get_initial_affection(SecretaryManager.SECRETARY_ID)
	)
	for artist_id in ArtistManager.get_all_artist_ids():
		RelationshipManager.register_character(
			str(artist_id),
			get_initial_affection(str(artist_id))
		)
	for rival_id in RivalManager.get_all_rival_ids():
		RelationshipManager.register_character(
			str(rival_id),
			get_initial_affection(str(rival_id))
		)
	for npc_id in NpcManager.get_all_npc_ids():
		var resource: NPCResource = NpcManager.get_npc_resource(str(npc_id))
		if resource == null or not resource.can_gain_affection:
			continue
		RelationshipManager.register_character(
			str(npc_id),
			get_initial_affection(str(npc_id))
		)
