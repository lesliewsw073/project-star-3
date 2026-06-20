extends Node

func resolve_text(raw_text: String, context: Dictionary = {}) -> String:
	var resolved_text: String = raw_text
	var replacements: Dictionary = _build_replacements(context)

	for key in replacements:
		resolved_text = resolved_text.replace("{%s}" % key, str(replacements[key]))

	return resolved_text

func _build_replacements(context: Dictionary = {}) -> Dictionary:
	var character_id: String = _get_context_character_id(context)
	var affection: int = _get_context_affection(context, character_id)
	var special_address: String = str(context.get("special_address", ""))
	var relationship_level_name: String = ""
	if character_id != "":
		relationship_level_name = RelationshipManager.get_relationship_level_name(character_id)

	var replacements: Dictionary = {
		"speaker_id": character_id,
		"character_id": character_id,
		"protagonist_id": ProtagonistManager.PROTAGONIST_ID,
		"protagonist_full_name": ProtagonistManager.get_full_name(),
		"protagonist_last_name": ProtagonistManager.get_last_name(),
		"protagonist_first_name": ProtagonistManager.get_first_name(),
		"protagonist_title": ProtagonistManager.get_default_title(),
		"protagonist_formal_title": ProtagonistManager.get_formal_title(),
		"protagonist_address": ProtagonistManager.get_preferred_address(affection, special_address),
		"player_full_name": ProtagonistManager.get_full_name(),
		"player_last_name": ProtagonistManager.get_last_name(),
		"player_first_name": ProtagonistManager.get_first_name(),
		"player_title": ProtagonistManager.get_default_title(),
		"player_formal_title": ProtagonistManager.get_formal_title(),
		"player_address": ProtagonistManager.get_preferred_address(affection, special_address),
		"relationship_affection": affection,
		"relationship_level": relationship_level_name,
		"company_name": PlayerManager.get_company_name(),
		"player_company": PlayerManager.get_company_name(),
		"player_company_name": PlayerManager.get_company_name(),
		"player_agency_id": AgencyDatabase.PLAYER_AGENCY_ID,
		"agency_name": _get_context_agency_name(context),
		"publisher_name": _get_context_publisher_name(context),
		"job_company_name": _get_context_publisher_name(context),
		"secretary_name": SecretaryManager.get_display_name(),
		"speaker_name": _get_context_speaker_name(context),
	}
	_merge_character_replacements(replacements, character_id)
	return replacements

func _merge_character_replacements(replacements: Dictionary, character_id: String) -> void:
	var resource: ArtistResource = ArtistManager.get_artist_resource(character_id)
	if resource != null:
		replacements["artist_name"] = resource.artist_name
	else:
		replacements["artist_name"] = character_id

	var npc_resource: NPCResource = NpcManager.get_npc_resource(character_id)
	if npc_resource != null:
		replacements["npc_name"] = npc_resource.npc_name.strip_edges()

	_merge_artist_profile_replacements(replacements, character_id)

func _merge_artist_profile_replacements(replacements: Dictionary, character_id: String) -> void:
	var profile: ArtistProfileResource = ArtistManager.get_artist_profile(character_id)
	if profile == null:
		for key in [
			"artist_age", "artist_height", "artist_weight", "artist_measurements", "artist_bwh",
			"artist_likes", "artist_dislikes", "artist_goal", "artist_development_goal",
		]:
			replacements[key] = "—"
		return

	var profile_vars: Dictionary = profile.get_dialogue_replacements()
	for key in profile_vars:
		replacements[key] = profile_vars[key]

func _get_context_character_id(context: Dictionary) -> String:
	var character_id: String = str(context.get("character_id", "")).strip_edges()
	if character_id != "":
		return character_id
	return str(context.get("speaker_id", "")).strip_edges()

func _get_context_agency_name(context: Dictionary) -> String:
	if context.has("agency_id"):
		return AgencyDatabase.get_agency_display_name(str(context.get("agency_id", "")))
	var character_id: String = _get_context_character_id(context)
	if character_id == "":
		return ""
	return ArtistManager.get_artist_agency_name(character_id)

func _get_context_publisher_name(context: Dictionary) -> String:
	if context.has("publisher_name"):
		return str(context.get("publisher_name", "")).strip_edges()
	if context.has("publisher_company_id"):
		return CompanyDatabase.get_publisher_name(str(context.get("publisher_company_id", "")))
	if context.has("target_company_id"):
		return CompanyDatabase.get_publisher_name(str(context.get("target_company_id", "")))
	if context.has("company_id"):
		return CompanyDatabase.get_publisher_name(str(context.get("company_id", "")))
	return ""

func _get_context_speaker_name(context: Dictionary) -> String:
	var character_id: String = _get_context_character_id(context)
	if character_id == "":
		return ""
	return CharacterDatabase.get_display_name(character_id)

func _get_context_affection(context: Dictionary, character_id: String) -> int:
	# 兼容舊用法：若呼叫端明確傳入 affection，優先使用手動值。
	if context.has("affection"):
		return clampi(int(context.get("affection", 0)), 0, 100)
	if character_id == "":
		return 0
	return RelationshipManager.get_affection(character_id)
