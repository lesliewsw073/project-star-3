class_name NPCResource
extends Resource

enum NPCType {
	BACKGROUND, # 背景路人（无立绘，仅文本或极简交互）
	STORY       # 剧情角色（商店老板、投资人、特殊NPC，有头像/立绘）
}

@export_group("基础信息")
@export var npc_id: String
@export var npc_name: String
@export var type: NPCType = NPCType.BACKGROUND
@export var home_facility_id: String = "" ## 常駐設施 facility_id（可選）

@export_group("內容分級")
@export var is_test_content: bool = false

@export var default_dialogue: DialogueSequence

@export_group("视觉资产 (路人留空)")
@export var avatar: Texture2D   # 小头像（用于对话框旁）
@export var portrait: Texture2D # 半身立绘（用于主界面交互）

@export_group("关系系统")
@export var can_gain_affection: bool = false ## 是否开启好感度系统
@export var default_affection: int = 10      ## 初始好感度（can_gain_affection 时生效）
