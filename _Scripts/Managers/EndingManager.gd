extends Node

func generate_verdict() -> String:
	var text = "[center][b]—— 毕业档案 ——[/b][/center]\n\n"
	
	# 1. 身份回顾
	text += "【出身】：%s\n" % get_archetype_name()
	if Global.fin_security < 3:
		text += "那张通往大城市的车票，你攥出了汗水。但这四年，你没有被贫穷击垮。\n"
	elif Global.fin_security > 7:
		text += "你拥有很多人梦寐以求的起点，但这并没有让你停止探索。\n"
	
	# 2. 过程挣扎
	text += "\n【心路历程】：\n"
	if Global.current_anxiety > 100:
		text += "你无数次在崩溃的边缘徘徊。深夜的机房见过你最狼狈的样子。\n"
	if Global.sedimentation > 15:
		text += "但你比任何人都清楚自己要什么。那些孤独的夜晚，最终凝结成了你的铠甲。\n"
	elif Global.entropy > 8:
		text += "你最大的收获不是绩点，而是看清了这个世界的运行规则。\n"
		
	# 3. 最终结局判定
	text += "\n【最终去向】：\n"
	if has_path("end_tech_lead"):
		text += "[color=#ffff00]互联网大厂核心成员[/color]\n你的代码运行在数亿人的手机里。你终于在这个陌生的城市扎下了根。"
	elif has_path("end_outlier"):
		text += "[color=#00ffff]独立开发者 / 自由职业[/color]\n你拒绝了被定义的成功。虽然前途未卜，但你是自由的。"
	elif has_path("end_grad_student"):
		text += "某985高校研究生\n这是一条安全的缓兵之计。希望在未来的三年里，你能找到真正的答案。"
	else:
		text += "普通毕业生\n你顺利毕业了。虽然没有惊天动地的成就，但你在这个残酷的游戏里活下来了，这本身就是一种胜利。"
		
	return text

func get_archetype_name():
	# 简单转换一下 Code 到中文
	match Global.current_archetype_code: # 注意：需要在 Global 里存一下这个变量
		"ARCH_STRIVER": return "错位过客"
		"ARCH_SURVIVOR": return "霓虹暗面"
		_: return "普通学生"

func has_path(id):
	return id in Global.selected_paths
