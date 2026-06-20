extends Node

const HIGH_AFFECTION_THRESHOLD: int = 70
const CONGRATULATION_COMPANY_COUNT: int = 2

func _ready() -> void:
	print("[CompanyEventManager] 就绪。")

func handle_company_upgraded(old_scale: int, new_scale: int, upgrade_cost: int = 0) -> Array[String]:
	var old_scale_name: String = PlayerManager.get_company_scale_name(old_scale)
	var new_scale_name: String = PlayerManager.get_company_scale_name(new_scale)
	var messages: Array[String] = []

	messages.append("重大事件：公司由%s升級為%s公司。" % [old_scale_name, new_scale_name])
	messages.append(_build_secretary_congratulation(old_scale, new_scale, new_scale_name))

	NewsManager.add_company_news(
		"%s完成公司規模升級" % PlayerManager.company_name,
		"%s正式由%s升級為%s公司。業界預期，該公司將獲得更多通告合作與新人簽約空間。" % [
			PlayerManager.company_name,
			old_scale_name,
			new_scale_name
		],
		NewsManager.Importance.BREAKING
	)

	for line in _build_partner_company_congratulations():
		messages.append(line)

	for line in _build_artist_congratulations():
		messages.append(line)

	if upgrade_cost > 0:
		messages.append("本次升級支出：$%d。" % upgrade_cost)

	return messages

func _build_secretary_congratulation(old_scale: int, new_scale: int, new_scale_name: String) -> String:
	var old_limit: int = PlayerManager.get_roster_limit(old_scale)
	var new_limit: int = PlayerManager.get_roster_limit(new_scale)
	if new_limit > old_limit:
		return "秘書：老闆，我們正式成為%s公司了。旗下藝人簽約上限已從 %d 人提升到 %d 人。" % [
			new_scale_name,
			old_limit,
			new_limit,
		]
	return "秘書：老闆，我們正式成為%s公司了。這次升級主要擴大合作資源，簽約名額仍是 %d 人。" % [
		new_scale_name,
		new_limit,
	]

func _build_partner_company_congratulations() -> Array[String]:
	var messages: Array[String] = []
	var company_ids: Array = CompanyDatabase.companies_registry.keys()
	company_ids.shuffle()

	var count: int = mini(CONGRATULATION_COMPANY_COUNT, company_ids.size())
	for i in range(count):
		var company_id: String = company_ids[i]
		var company_data: Dictionary = CompanyDatabase.get_company_info(company_id)
		if company_data.is_empty():
			continue

		var company_name: String = company_data.get("name", company_id)
		messages.append("%s 發來賀電：期待未來有更多合作機會。" % company_name)

	return messages

func _build_artist_congratulations() -> Array[String]:
	var messages: Array[String] = []

	for artist_id in ArtistManager.get_signed_ids():
		var artist: ArtistInstance = ArtistManager.get_artist(artist_id)
		if artist == null:
			continue
		if artist.get_affection() < HIGH_AFFECTION_THRESHOLD:
			continue

		var artist_name: String = artist.base_data.artist_name
		messages.append("%s 送來祝賀禮物。（禮物系統尚未接入，暫記為事件文字）" % artist_name)

	return messages
