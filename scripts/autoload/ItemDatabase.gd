extends Node

## 道具靜態目錄：載入 data/items/ 下全部 ItemResource。

const ITEMS_DIR: String = "res://data/items/"

var _templates: Dictionary = {}

func _ready() -> void:
	var count: int = reload_all()
	print("[ItemDatabase] 道具模板載入完成，共 %d 種。" % count)

func reload_all() -> int:
	_templates.clear()
	_scan_dir(ITEMS_DIR.trim_suffix("/"))
	return _templates.size()

func get_item(item_id: String) -> ItemResource:
	var clean_id: String = item_id.strip_edges()
	if clean_id == "":
		return null
	return _templates.get(clean_id, null)

func has_item(item_id: String) -> bool:
	return get_item(item_id) != null

func get_all_item_ids() -> Array[String]:
	var ids: Array[String] = []
	for key in _templates:
		ids.append(str(key))
	ids.sort()
	return ids

func get_items_by_category(category: int) -> Array[ItemResource]:
	var result: Array[ItemResource] = []
	for item_id in _templates:
		var item: ItemResource = _templates[item_id]
		if item != null and int(item.item_category) == category:
			result.append(item)
	result.sort_custom(func(a: ItemResource, b: ItemResource) -> bool:
		return a.item_id < b.item_id
	)
	return result

func _scan_dir(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_warning("[ItemDatabase] 無法開啟目錄：%s" % dir_path)
		return

	dir.list_dir_begin()
	var entry_name: String = dir.get_next()
	while entry_name != "":
		if entry_name != "." and entry_name != "..":
			var full_path: String = "%s/%s" % [dir_path, entry_name]
			if dir.current_is_dir():
				_scan_dir(full_path)
			elif entry_name.ends_with(".tres"):
				_register_file(full_path)
		entry_name = dir.get_next()
	dir.list_dir_end()

func _register_file(file_path: String) -> void:
	if not ResourceLoader.exists(file_path):
		return
	var resource = load(file_path)
	if resource is ItemResource:
		var item: ItemResource = resource
		var err: String = item.validate_config()
		if err != "":
			push_warning("[ItemDatabase] %s" % err)
		var clean_id: String = item.item_id.strip_edges()
		if clean_id == "":
			push_warning("[ItemDatabase] %s 缺少 item_id。" % file_path)
			return
		if _templates.has(clean_id):
			push_warning("[ItemDatabase] item_id 重複：%s" % clean_id)
			return
		_templates[clean_id] = item
