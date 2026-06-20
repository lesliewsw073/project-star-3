extends Resource
class_name DialogueLine

@export var speaker_name: String = ""
@export var speaker_id: String = "" ## 說話人 ID，例如 artist_001、secretary；用來自動查對主角好感度。
@export var special_player_address: String = "" ## 專屬稱呼，例如「大哥」「老闆」。留空時依好感度自動稱呼。
@export var speaker_avatar: Texture2D ## 行內小頭像差分（少用）
@export var speaker_portrait: Texture2D ## 行內半身立繪差分
@export_multiline var text: String = ""
