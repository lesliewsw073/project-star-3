extends Node

func _ready() -> void:
	print(">>> 开始注入测试视觉资产...")
	
	# 定义 5 种区分度高的赛博朋克风测试颜色
	var test_colors = [
		Color.DEEP_SKY_BLUE, # 老城
		Color.CRIMSON,       # 商圈
		Color.GOLDENROD,     # 文创园
		Color.SEA_GREEN,     # CBD
		Color.MEDIUM_PURPLE  # 影视城
	]
	
	for i in range(1, 6):
		var file_path = "res://data/locations/screen_%d.tres" % i
		if not ResourceLoader.exists(file_path):
			push_warning("找不到图纸: " + file_path)
			continue
			
		var loc: LocationResource = load(file_path)
		
		# 利用 Godot 4 强大的 GradientTexture2D 纯代码捏一张图
		var bg_tex = GradientTexture2D.new()
		bg_tex.width = 1920
		bg_tex.height = 1080
		bg_tex.fill = GradientTexture2D.FILL_LINEAR
		bg_tex.fill_from = Vector2(0, 0)
		bg_tex.fill_to = Vector2(1, 1)
		
		# 创建渐变色：从亮色过渡到暗色
		var grad = Gradient.new()
		grad.colors = PackedColorArray([test_colors[i-1].lightened(0.2), test_colors[i-1].darkened(0.6)])
		bg_tex.gradient = grad
		
		# 将生成的测试图强制塞入底层资源并保存到硬盘
		loc.background_texture = bg_tex
		ResourceSaver.save(loc, file_path)
		
		print("✅ 已成功为 [%s] 注入测试渐变背景图！" % loc.location_name)
		
	print("🎉 占位图生成完毕！请重新运行您的 UI/MapHub.tscn 查看效果！")
