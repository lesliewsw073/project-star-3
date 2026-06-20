class_name FacilityResource
extends Resource

enum FacilityType { 
	BASE,           # 大本营（家/公司，用于结算和休息）
	COMPANY,        # 通告／製作公司駐點（CompanyDatabase comp_*，非經紀公司）
	SHOP,           # 购物类（商店/酒吧/寺庙，用于购买物品）
	COURSE_BASE,    # 课程基地（训练基地，用于开放课程库）
	NPC_SCENE,      # 纯NPC场景（公园/医院/美术馆，触发事件或打工）
	RESORT,         # 度假区（米兰/夏威夷等，用于降压去疲劳）
	TRANSPORT       # 交通枢纽（国际机场等，用于开启世界地图）
}

@export_group("基础信息")
@export var facility_id: String
@export var facility_name: String
@export var type: FacilityType

@export_group("关联数据 (按需填写)")
@export var linked_company_id: String = ""

# 挂载在该设施下的打工选项（需后续将具体的 GigResource.tres 拖入）
@export var available_gigs: Array[Resource] = []

# 挂载在该设施下的课程选项
@export var available_courses: Array[Resource] = []

# 挂载该设施下会出现的 NPC 
@export var available_npcs: Array[NPCResource] = []
