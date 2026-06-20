extends Node

## 劇情統一播放入口：對話 → dialogue_finished → InteractionManager 結算（一次）。

signal playback_batch_finished(batch_result: Dictionary)

const DIALOGUE_PANEL_SCENE: PackedScene = preload("res://UI/dialogue_panel.tscn")

var _queue: Array[Dictionary] = []
var _playing: bool = false

func enqueue_batch(
	template: InteractionEventResource,
	participant_ids: Array,
	meta: Dictionary = {}
) -> void:
	if template == null:
		return
	_queue.append({
		"template": template,
		"participant_ids": participant_ids.duplicate(),
		"meta": meta.duplicate(),
		"entries": [],
		"pending_participants": participant_ids.duplicate(),
	})
	if not _playing:
		_process_queue()

func is_playing() -> bool:
	return _playing

func _process_queue() -> void:
	if _queue.is_empty():
		_playing = false
		return
	_playing = true
	var job: Dictionary = _queue[0]
	_advance_job(job)

func _advance_job(job: Dictionary) -> void:
	var template: InteractionEventResource = job["template"]
	var pending: Array = job.get("pending_participants", [])
	if template == null:
		_finish_current_job(false, "empty_template")
		return

	if int(template.trigger_mode) == InteractionEventResource.TriggerMode.PARALLEL:
		var primary_id: String = ""
		if not pending.is_empty():
			primary_id = str(pending[0])
		_play_runtime_event(_build_runtime_event(template, primary_id), job, pending, "PARALLEL", false)
		return

	if pending.is_empty():
		_play_runtime_event(_build_runtime_event(template, ""), job, [], "SOLO", false)
		return

	var artist_id: String = str(pending[0])
	job["pending_participants"] = pending.slice(1)
	_play_runtime_event(_build_runtime_event(template, artist_id), job, [artist_id], "SOLO", true)

func _build_runtime_event(
	template: InteractionEventResource,
	primary_id: String
) -> InteractionEventResource:
	var runtime_event: InteractionEventResource = template.duplicate(true) as InteractionEventResource
	if primary_id.strip_edges() != "" and runtime_event.character_id.strip_edges() == "":
		runtime_event.character_id = primary_id
	return runtime_event

func _resolve_cg_owner_id(runtime_event: InteractionEventResource) -> String:
	if runtime_event == null:
		return ""
	var owner_id: String = runtime_event.owner.strip_edges()
	if owner_id != "" and not owner_id.contains("+") and not owner_id.contains("*"):
		return owner_id.split(":")[0]
	var character_id: String = runtime_event.character_id.strip_edges()
	if character_id != "":
		return character_id
	return ""

func _play_runtime_event(
	runtime_event: InteractionEventResource,
	job: Dictionary,
	participant_ids: Array,
	mode_label: String,
	continue_solo_chain: bool
) -> void:
	var block_reason: String = InteractionManager.get_execution_block_reason(runtime_event)
	if block_reason != "":
		job["entries"].append(
			StoryTriggerManager.make_playback_entry(runtime_event, participant_ids, {
				"success": false,
				"reason": block_reason,
				"event_id": runtime_event.event_id,
			}, mode_label)
		)
		if continue_solo_chain and not job.get("pending_participants", []).is_empty():
			_advance_job(job)
			return
		_finish_current_job(false, block_reason)
		return

	if runtime_event.has_dialogue():
		var panel := DIALOGUE_PANEL_SCENE.instantiate() as DialoguePanel
		if panel == null:
			_settle_runtime_event(runtime_event, job, participant_ids, mode_label, continue_solo_chain)
			return
		get_tree().root.add_child(panel)
		panel.dialogue_finished.connect(
			func() -> void:
				_settle_runtime_event(runtime_event, job, participant_ids, mode_label, continue_solo_chain),
			CONNECT_ONE_SHOT
		)
		panel.start_dialogue(
			runtime_event.dialogue,
			null,
			_resolve_cg_owner_id(runtime_event),
			runtime_event.cg_id,
		)
		return

	_settle_runtime_event(runtime_event, job, participant_ids, mode_label, continue_solo_chain)

func _settle_runtime_event(
	runtime_event: InteractionEventResource,
	job: Dictionary,
	participant_ids: Array,
	mode_label: String,
	continue_solo_chain: bool
) -> void:
	var result: Dictionary = InteractionManager.execute_event(runtime_event)
	if bool(result.get("success", false)):
		StoryTriggerManager.record_event_cooldown(runtime_event)
		if mode_label == "PARALLEL":
			StoryTriggerManager.apply_parallel_secondary_effects(
				job["template"],
				participant_ids,
				runtime_event.character_id
			)

	job["entries"].append(
		StoryTriggerManager.make_playback_entry(
			job["template"],
			participant_ids,
			result,
			mode_label
		)
	)

	if continue_solo_chain and not job.get("pending_participants", []).is_empty():
		_advance_job(job)
		return

	var any_success: bool = false
	for entry in job["entries"]:
		if entry is Dictionary and bool(entry.get("interaction_result", {}).get("success", false)):
			any_success = true
			break
	_finish_current_job(any_success, "")

func _finish_current_job(success: bool, reason: String) -> void:
	if _queue.is_empty():
		_playing = false
		return
	var job: Dictionary = _queue.pop_front()
	var meta: Dictionary = job.get("meta", {})
	var batch: Dictionary = StoryTriggerManager.make_playback_batch(
		success,
		reason,
		job.get("entries", []),
		meta
	)
	playback_batch_finished.emit(batch)
	call_deferred("_process_queue")
