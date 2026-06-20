extends Node

## 跟隨 / 探望 / 簽約等劇情觸發中樞。
## 匹配 InteractionEventResource → StoryPlaybackController 播放 → InteractionManager 結算。

signal follow_stories_resolved(batch_result: Dictionary)
signal visit_story_resolved(batch_result: Dictionary)
signal sign_story_resolved(batch_result: Dictionary)
signal calendar_story_resolved(batch_result: Dictionary)
signal meeting_story_resolved(batch_result: Dictionary)

const STORY_EVENTS_DIR: String = "res://data/story_events/"

var event_templates: Dictionary = {}

func _ready() -> void:
	var count: int = load_all_story_events()
	print("[StoryTriggerManager] 劇情事件模板載入完成，共 %d 則。" % count)

func load_all_story_events(dir_path: String = STORY_EVENTS_DIR) -> int:
	event_templates.clear()
	_scan_story_events_dir(dir_path.trim_suffix("/"))
	return event_templates.size()

func run_follow_day(artist_ids: Array) -> Dictionary:
	var participant_ids: Array[String] = _normalize_artist_ids(artist_ids)
	if participant_ids.is_empty():
		var empty: Dictionary = _make_batch_result(false, "no_follow_artists")
		follow_stories_resolved.emit(empty)
		return empty

	if GameFlowManager.get_day_mode() != GameFlowManager.DayMode.FOLLOW:
		var blocked: Dictionary = _make_batch_result(false, "not_follow_day")
		follow_stories_resolved.emit(blocked)
		return blocked

	var signature: String = _get_artist_task_signature(participant_ids[0])
	var prefer_parallel: bool = participant_ids.size() >= 2
	var template: InteractionEventResource = _find_best_event(
		InteractionEventResource.StoryChannel.FOLLOW,
		signature,
		"",
		"",
		prefer_parallel
	)
	if template == null:
		var none: Dictionary = _make_batch_result(false, "no_matching_event")
		none["participant_ids"] = participant_ids
		none["task_signature"] = signature
		follow_stories_resolved.emit(none)
		return none

	return _enqueue_playback(
		template,
		participant_ids,
		{
			"context": "follow",
			"task_signature": signature,
			"participant_ids": participant_ids,
		},
		follow_stories_resolved
	)

func try_visit(location_id: String, facility_id: String = "") -> Dictionary:
	var clean_location_id: String = location_id.strip_edges()
	if clean_location_id == "":
		var invalid: Dictionary = _make_batch_result(false, "invalid_location")
		visit_story_resolved.emit(invalid)
		return invalid

	if GameFlowManager.get_day_mode() != GameFlowManager.DayMode.FREE:
		var blocked: Dictionary = _make_batch_result(false, "not_free_day")
		visit_story_resolved.emit(blocked)
		return blocked

	if not GameFlowManager.is_exploring_map:
		var not_map: Dictionary = _make_batch_result(false, "not_on_map")
		visit_story_resolved.emit(not_map)
		return not_map

	var participant_ids: Array[String] = get_artists_with_schedule_at(
		clean_location_id,
		facility_id.strip_edges()
	)
	var signature: String = ""
	if not participant_ids.is_empty():
		signature = _get_artist_task_signature(participant_ids[0])

	var template: InteractionEventResource = _find_best_event(
		InteractionEventResource.StoryChannel.VISIT,
		signature,
		clean_location_id,
		facility_id.strip_edges()
	)
	if template == null:
		var none: Dictionary = _make_batch_result(false, "no_matching_event")
		none["location_id"] = clean_location_id
		none["facility_id"] = facility_id.strip_edges()
		visit_story_resolved.emit(none)
		return none

	if template.task_signature.strip_edges() != "" and participant_ids.is_empty():
		var no_artist: Dictionary = _make_batch_result(false, "no_artist_at_location")
		no_artist["location_id"] = clean_location_id
		no_artist["facility_id"] = facility_id.strip_edges()
		visit_story_resolved.emit(no_artist)
		return no_artist

	if randf() > clampf(template.trigger_chance, 0.0, 1.0):
		var missed: Dictionary = _make_batch_result(false, "chance_failed")
		missed["location_id"] = clean_location_id
		missed["facility_id"] = facility_id.strip_edges()
		visit_story_resolved.emit(missed)
		return missed

	return _enqueue_playback(
		template,
		participant_ids,
		{
			"context": "visit",
			"location_id": clean_location_id,
			"facility_id": facility_id.strip_edges(),
			"participant_ids": participant_ids,
		},
		visit_story_resolved
	)

func try_play_sign_story(artist_id: String) -> Dictionary:
	var clean_id: String = artist_id.strip_edges()
	if clean_id == "":
		var invalid: Dictionary = _make_batch_result(false, "invalid_artist")
		sign_story_resolved.emit(invalid)
		return invalid

	var template: InteractionEventResource = _find_best_event(
		InteractionEventResource.StoryChannel.SIGN,
		"",
		"",
		"",
		false,
		clean_id
	)
	if template == null:
		var none: Dictionary = _make_batch_result(false, "no_matching_event")
		none["artist_id"] = clean_id
		sign_story_resolved.emit(none)
		return none

	return _enqueue_playback(
		template,
		[clean_id],
		{
			"context": "sign",
			"artist_id": clean_id,
		},
		sign_story_resolved
	)

func try_play_calendar_story(artist_id: String) -> Dictionary:
	var clean_id: String = artist_id.strip_edges()
	if clean_id == "":
		var invalid: Dictionary = _make_batch_result(false, "invalid_artist")
		calendar_story_resolved.emit(invalid)
		return invalid

	var template: InteractionEventResource = _find_best_event(
		InteractionEventResource.StoryChannel.CALENDAR,
		"",
		"",
		"",
		false,
		clean_id
	)
	if template == null:
		var none: Dictionary = _make_batch_result(false, "no_matching_event")
		none["artist_id"] = clean_id
		calendar_story_resolved.emit(none)
		return none

	return _enqueue_playback(
		template,
		[clean_id],
		{
			"context": "calendar",
			"artist_id": clean_id,
		},
		calendar_story_resolved
	)

func try_play_meeting_story(meeting_context: Dictionary = {}) -> Dictionary:
	if not GameFlowManager.is_meeting_phase:
		var blocked: Dictionary = _make_batch_result(false, "not_meeting_phase")
		meeting_story_resolved.emit(blocked)
		return blocked

	var is_first_meeting: bool = bool(meeting_context.get("is_first_meeting", false))
	var primary_artist_id: String = str(meeting_context.get("primary_artist_id", "")).strip_edges()
	var participant_ids: Array = []
	if primary_artist_id != "":
		participant_ids = [primary_artist_id]

	var template: InteractionEventResource = _find_best_event(
		InteractionEventResource.StoryChannel.MEETING,
		"",
		"",
		"",
		false,
		primary_artist_id if is_first_meeting else "",
		meeting_context
	)
	if template == null:
		var none: Dictionary = _make_batch_result(false, "no_matching_event")
		none["is_first_meeting"] = is_first_meeting
		meeting_story_resolved.emit(none)
		return none

	var meta: Dictionary = {
		"context": "meeting",
		"is_first_meeting": is_first_meeting,
		"primary_artist_id": primary_artist_id,
	}
	if template.owner.strip_edges() == SecretaryManager.SECRETARY_ID:
		participant_ids = [SecretaryManager.SECRETARY_ID]

	return _enqueue_playback(
		template,
		participant_ids,
		meta,
		meeting_story_resolved
	)

func get_artists_with_schedule_at(
	location_id: String,
	facility_id: String = "",
	day_index: int = -1
) -> Array[String]:
	var target_day: int = TimeManager.day_index if day_index < 0 else day_index
	if target_day < 0 or target_day >= ScheduleManager.DAYS_PER_WEEK:
		return []

	var result: Array[String] = []
	for signed_id in ArtistManager.get_signed_ids():
		var artist_id: String = str(signed_id)
		var week: Array = ScheduleManager.get_week(artist_id)
		var slot: Dictionary = week[target_day]
		var binding: Dictionary = resolve_slot_location_binding(slot)
		if _location_binding_matches(binding, location_id, facility_id):
			result.append(artist_id)

	result.sort_custom(func(a: String, b: String) -> bool:
		return _compare_follow_priority(a, b)
	)
	return result

func resolve_slot_location_binding(slot: Dictionary) -> Dictionary:
	var task_data = slot.get("task_data")
	var location_id: String = ""
	var facility_id: String = ""

	if task_data is GigResource:
		location_id = str(task_data.unlock_location_id).strip_edges()
		facility_id = str(task_data.unlock_facility_id).strip_edges()
	elif task_data is CourseResource:
		location_id = str(task_data.unlock_location_id).strip_edges()
		facility_id = str(task_data.unlock_facility_id).strip_edges()
	elif task_data is JobInstance:
		var job: JobResource = task_data.base_job
		if job != null:
			location_id = str(job.unlock_location_id).strip_edges()
			facility_id = str(job.unlock_facility_id).strip_edges()

	return {
		"location_id": location_id,
		"facility_id": facility_id,
		"signature": FollowPlanManager.get_slot_task_signature(slot),
	}

func make_playback_batch(
	success: bool,
	reason: String,
	entries: Array,
	meta: Dictionary = {}
) -> Dictionary:
	var batch: Dictionary = _make_batch_result(success, reason, entries)
	for key in meta:
		batch[key] = meta[key]
	return batch

func make_playback_entry(
	template: InteractionEventResource,
	participant_ids: Array,
	interaction_result: Dictionary,
	trigger_mode_label: String
) -> Dictionary:
	return _make_entry(template, participant_ids, interaction_result, trigger_mode_label)

func record_event_cooldown(template: InteractionEventResource) -> void:
	if template == null or template.cooldown_days <= 0:
		return
	InteractionManager.set_flag(template.get_cooldown_flag_key(), TimeManager.total_days_elapsed)

func apply_parallel_secondary_effects(
	template: InteractionEventResource,
	participant_ids: Array[String],
	primary_id: String
) -> void:
	if template == null:
		return
	if not template.affection_targets.is_empty():
		return
	if template.affection_delta == 0:
		return
	for artist_id in participant_ids:
		if artist_id == primary_id:
			continue
		RelationshipManager.add_affection(artist_id, template.affection_delta)

func _enqueue_playback(
	template: InteractionEventResource,
	participant_ids: Array,
	meta: Dictionary,
	resolved_signal: Signal
) -> Dictionary:
	StoryPlaybackController.enqueue_batch(template, participant_ids, meta)
	var pending: Dictionary = _make_batch_result(true, "pending_playback")
	pending["pending_playback"] = true
	for key in meta:
		pending[key] = meta[key]
	resolved_signal.emit(pending)
	return pending

func _find_best_event(
	channel: int,
	task_signature: String,
	location_id: String,
	facility_id: String,
	prefer_parallel: bool = false,
	query_owner: String = "",
	meeting_context: Dictionary = {}
) -> InteractionEventResource:
	var is_first_meeting: bool = bool(meeting_context.get("is_first_meeting", false))
	if OS.is_debug_build():
		print(
			"[StoryTriggerManager][DEBUG] 尋找最佳事件：channel=%d owner=%s signature=%s location=%s facility=%s prefer_parallel=%s first_meeting=%s（模板 %d 則）"
			% [
				channel,
				query_owner,
				task_signature,
				location_id,
				facility_id,
				prefer_parallel,
				is_first_meeting,
				event_templates.size(),
			]
		)

	var best_event: InteractionEventResource = null
	var best_score: int = -1
	var best_events: Array[InteractionEventResource] = []

	for event_id in event_templates:
		var template: InteractionEventResource = event_templates[event_id]
		if template == null:
			continue
		if not _event_matches_filters(
			template,
			channel,
			task_signature,
			location_id,
			facility_id,
			query_owner
		):
			continue
		if not _meeting_scope_matches(template, channel, meeting_context):
			if OS.is_debug_build():
				print(
					"[StoryTriggerManager][DEBUG] 事件 '%s' 跳過（meeting_scope=%s）。"
					% [_event_log_label(template, event_id), template.meeting_scope]
				)
			continue
		if template.execute_once and InteractionManager.has_executed(template.event_id):
			if OS.is_debug_build():
				print(
					"[StoryTriggerManager][DEBUG] 事件 '%s' 跳過（已執行）。"
					% _event_log_label(template, event_id)
				)
			continue
		if _is_on_cooldown(template):
			if OS.is_debug_build():
				print(
					"[StoryTriggerManager][DEBUG] 事件 '%s' 跳過（cooldown）。"
					% _event_log_label(template, event_id)
				)
			continue
		var flag_mismatch: String = _get_required_flags_mismatch(template)
		if flag_mismatch != "":
			if OS.is_debug_build():
				print(
					"[StoryTriggerManager][DEBUG] 事件 '%s' 跳過（required_flags）：%s"
					% [_event_log_label(template, event_id), flag_mismatch]
				)
			continue

		var score: int = template.priority
		if channel == InteractionEventResource.StoryChannel.SIGN:
			if int(template.arc_type) == InteractionEventResource.StoryArcType.FIRST_MEETING:
				score += 100
		if channel == InteractionEventResource.StoryChannel.MEETING:
			var scope: String = template.meeting_scope.strip_edges().to_lower()
			if is_first_meeting and scope == "first":
				score += 100
			elif not is_first_meeting and scope == "weekly":
				score += 50
		if channel == InteractionEventResource.StoryChannel.FOLLOW:
			if prefer_parallel:
				if int(template.trigger_mode) == InteractionEventResource.TriggerMode.PARALLEL:
					score += 50
			elif int(template.trigger_mode) == InteractionEventResource.TriggerMode.SOLO:
				score += 50
		var wanted_signature: String = task_signature.strip_edges()
		var template_signature: String = template.task_signature.strip_edges()
		if wanted_signature != "" and template_signature == wanted_signature:
			score += 100
		elif template_signature == "":
			score += 10

		if score > best_score:
			best_score = score
			best_event = template
			best_events = [template]
		elif score == best_score:
			best_events.append(template)

	if not best_events.is_empty():
		best_event = best_events.pick_random()

	if OS.is_debug_build():
		if best_event == null:
			print("[StoryTriggerManager][DEBUG] 未找到符合條件的事件。")
		else:
			print(
				"[StoryTriggerManager][DEBUG] 選中事件 '%s'（priority=%d，score=%d）。"
				% [_event_log_label(best_event, best_event.event_id), best_event.priority, best_score]
			)

	return best_event

func _event_matches_filters(
	template: InteractionEventResource,
	channel: int,
	task_signature: String,
	location_id: String,
	facility_id: String,
	query_owner: String = ""
) -> bool:
	var template_channel: int = template.get_resolved_channel()
	if template_channel not in [InteractionEventResource.StoryChannel.ANY, channel]:
		return false

	if not _owner_matches(template, query_owner):
		return false

	var wanted_signature: String = task_signature.strip_edges()
	var template_signature: String = template.task_signature.strip_edges()
	if template_signature != "" and wanted_signature != "" and template_signature != wanted_signature:
		return false

	var wanted_location: String = location_id.strip_edges()
	var template_location: String = template.location_id.strip_edges()
	if template_location != "" and wanted_location != "" and template_location != wanted_location:
		return false

	var wanted_facility: String = facility_id.strip_edges()
	var template_facility: String = template.facility_id.strip_edges()
	if template_facility != "" and wanted_facility != "" and template_facility != wanted_facility:
		return false

	return true

func _owner_matches(template: InteractionEventResource, query_owner: String) -> bool:
	var event_owner: String = template.owner.strip_edges()
	var wanted_owner: String = query_owner.strip_edges()
	if event_owner == "" or wanted_owner == "":
		return true
	return event_owner == wanted_owner

func _meeting_scope_matches(
	template: InteractionEventResource,
	channel: int,
	meeting_context: Dictionary
) -> bool:
	if channel != InteractionEventResource.StoryChannel.MEETING:
		return true
	var scope: String = template.meeting_scope.strip_edges().to_lower()
	if scope == "":
		return true
	var is_first_meeting: bool = bool(meeting_context.get("is_first_meeting", false))
	if scope == "first":
		return is_first_meeting
	if scope == "weekly":
		return not is_first_meeting
	return true

func _is_on_cooldown(template: InteractionEventResource) -> bool:
	if template.cooldown_days <= 0:
		return false
	var key: String = template.get_cooldown_flag_key()
	if not InteractionManager.interaction_flags.has(key):
		return false
	var last_day: int = int(InteractionManager.get_flag(key, -999999))
	return TimeManager.total_days_elapsed - last_day < template.cooldown_days

func _get_required_flags_mismatch(template: InteractionEventResource) -> String:
	if template.required_flags.is_empty():
		return ""
	for flag_id in template.required_flags:
		var clean_flag_id: String = str(flag_id).strip_edges()
		if clean_flag_id == "":
			continue
		var expected: Variant = template.required_flags[flag_id]
		var actual: Variant = InteractionManager.get_flag(clean_flag_id)
		if actual != expected:
			return "flag '%s' 需要 %s，目前 %s" % [clean_flag_id, expected, actual]
	return ""

func _event_log_label(template: InteractionEventResource, fallback_id: String = "") -> String:
	var event_id: String = template.event_id.strip_edges()
	if event_id != "":
		return event_id
	return fallback_id.strip_edges()

func _location_binding_matches(
	binding: Dictionary,
	location_id: String,
	facility_id: String
) -> bool:
	var wanted_location: String = location_id.strip_edges()
	var wanted_facility: String = facility_id.strip_edges()
	var slot_location: String = str(binding.get("location_id", "")).strip_edges()
	var slot_facility: String = str(binding.get("facility_id", "")).strip_edges()

	if wanted_location != "" and slot_location != wanted_location:
		return false
	if wanted_facility != "":
		if slot_facility != "":
			return slot_facility == wanted_facility
		return false
	return slot_location != "" or slot_facility != ""

func _get_artist_task_signature(artist_id: String) -> String:
	var week: Array = ScheduleManager.get_week(artist_id)
	var slot: Dictionary = week[TimeManager.day_index]
	return FollowPlanManager.get_slot_task_signature(slot)

func _normalize_artist_ids(raw_ids: Array) -> Array[String]:
	var result: Array[String] = []
	for raw_id in raw_ids:
		var artist_id: String = str(raw_id).strip_edges()
		if artist_id == "" or not ArtistManager.is_signed(artist_id):
			continue
		if artist_id in result:
			continue
		result.append(artist_id)
	return result

func _compare_follow_priority(artist_id_a: String, artist_id_b: String) -> bool:
	var affection_a: int = RelationshipManager.get_affection(artist_id_a)
	var affection_b: int = RelationshipManager.get_affection(artist_id_b)
	if affection_a != affection_b:
		return affection_a > affection_b
	return artist_id_a < artist_id_b

func _make_batch_result(success: bool, reason: String = "", entries: Array = []) -> Dictionary:
	return {
		"success": success,
		"reason": reason,
		"entries": entries,
	}

func _make_entry(
	template: InteractionEventResource,
	participant_ids: Array,
	interaction_result: Dictionary,
	trigger_mode_label: String
) -> Dictionary:
	return {
		"event_id": template.event_id,
		"event_title": template.event_title,
		"trigger_mode": trigger_mode_label,
		"participant_ids": participant_ids.duplicate(),
		"interaction_result": interaction_result,
		"result_text": str(interaction_result.get("result_text", template.result_text)),
	}

func _scan_story_events_dir(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_warning("[StoryTriggerManager] 無法打開目錄：%s" % dir_path)
		return

	dir.list_dir_begin()
	var entry_name: String = dir.get_next()
	while entry_name != "":
		if entry_name.begins_with("."):
			entry_name = dir.get_next()
			continue

		var full_path: String = "%s/%s" % [dir_path, entry_name]
		if dir.current_is_dir():
			_scan_story_events_dir(full_path)
		elif entry_name.ends_with(".tres"):
			_register_story_event_file(full_path)
		entry_name = dir.get_next()
	dir.list_dir_end()

func _register_story_event_file(file_path: String) -> void:
	if not ResourceLoader.exists(file_path):
		return
	var resource: Resource = load(file_path)
	if not (resource is InteractionEventResource):
		push_warning("[StoryTriggerManager] 非 InteractionEventResource，已跳過：%s" % file_path)
		return

	var template: InteractionEventResource = resource as InteractionEventResource
	template.sync_legacy_trigger_context_from_channel()
	var config_error: String = template.validate_config()
	if config_error != "":
		push_warning("[StoryTriggerManager] %s" % config_error)

	var event_id: String = template.event_id.strip_edges()
	if event_id == "":
		push_warning("[StoryTriggerManager] 缺少 event_id，已跳過：%s" % file_path)
		return
	if event_templates.has(event_id):
		push_warning("[StoryTriggerManager] 重複 event_id：%s（後者覆蓋）" % event_id)
	event_templates[event_id] = template
