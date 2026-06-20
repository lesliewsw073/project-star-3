class_name DayWorkReportBuilder
extends RefCounted

const TRACK_STATS: Array[String] = [
	"acting", "singing", "fame", "stamina", "eloquence", "dynamism", "talent",
]

static func snapshot_stats(artist: ArtistInstance) -> Dictionary:
	var payload: Dictionary = {}
	if artist == null:
		return payload
	for stat_name in TRACK_STATS:
		payload[stat_name] = int(artist.get(stat_name))
	return payload

static func format_stat_deltas(before: Dictionary, after: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	for stat_name in TRACK_STATS:
		if not before.has(stat_name) or not after.has(stat_name):
			continue
		var delta: int = int(after[stat_name]) - int(before[stat_name])
		if delta == 0:
			continue
		if delta > 0:
			lines.append("↑%d" % delta)
		else:
			lines.append("↓%d" % absi(delta))
		if lines.size() >= 5:
			break
	if lines.is_empty():
		lines.append("—")
	return lines

static func pad_reports(reports: Array) -> Array:
	var padded: Array = reports.duplicate()
	while padded.size() < 4:
		padded.append({
			"artist_id": "",
			"artist_name": "",
			"task_type_label": "",
			"task_title": "",
			"outcome_label": "",
			"stat_lines": PackedStringArray(["—"]),
			"empty": true,
		})
	return padded.slice(0, 4)
