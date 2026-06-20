class_name LocationResource
extends Resource

enum RegionType {
	DOMESTIC_SCREEN, # 国内轮播屏 (屏1 ~ 屏5)
	INTERNATIONAL    # 国际大地图 (洛杉矶、东京等)
}

@export_group("大地图信息")
@export var location_id: String         # 唯一标识，如 "screen_1" 或 "city_tokyo"
@export var location_name: String       # 界面显示名称，如 "老城生活区"
@export var region: RegionType          # 区分是参与无限轮播，还是点选平滑切换
@export var background_texture: Texture2D # 纯 UI 驱动的背景底图

@export_group("包含设施")
# 核心关联：把该屏/该城市所有的建筑(FacilityResource.tres)全部塞进这个数组
@export var facilities: Array[FacilityResource] = []

# 辅助函数：快速验证当前地图是否包含某类型的设施（供 UI 状态机调用）
func has_facility_type(check_type: FacilityResource.FacilityType) -> bool:
	for facility in facilities:
		if facility.type == check_type:
			return true
	return false
