extends Node

func generate_verdict() -> String:
	var text = "[center][b]—— 最终档案 ——[/b][/center]\n\n"
	var paths = Global.selected_paths

	# 1. 真结局：B家 Tech Lead (技术大成)
	if "b_core_staff_dev" in paths:
		text += "[color=#FFD700][b]结局：技术权贵[/b][/color]\n"
		text += "你用无数个加班的深夜，换来了这个行业最高的认可。\n"
		text += "Bosch 的工牌在胸前闪闪发光。你面试过很多像当年的你一样的年轻人，\n"
		text += "可惜，他们大多没有你那样的运气，也没有你那样的沉淀。\n"
		
	# 2. 遗憾结局：海投找 Offer (海归梦碎)
	elif "big_amount_interview" in paths:
		text += "[color=#AAAAAA][b]结局：学历的通货膨胀[/b][/color]\n"
		text += "那张昂贵的国外文凭，并没有成为你的免死金牌。\n"
		text += "面试官问的问题很基础，但你回答得很犹豫。\n"
		text += "你偶尔会想，如果当年没有出国，而是留在实验室死磕代码，现在会怎样？\n"

	# 3. 学术结局：博士找教职
	elif "big_amount_interviewphd" in paths:
		text += "[color=#88CCFF][b]结局：象牙塔的守望者[/b][/color]\n"
		text += "非升即走。这四个字像一把剑悬在头顶。\n"
		text += "你逃离了职场的内卷，却跳进了学术的绞肉机。\n"
		text += "但看着论文被接收的那一刻，你依然觉得，这比写业务代码有意义。\n"

	# 4. 创业结局分支 (Mark vs Hong)
	elif "back_to_society" in paths: # Mark线崩盘
		text += "[color=#FF5555][b]结局：理想主义的余烬[/b][/color]\n"
		text += "Mark 走了。Xuan 拿走了钱。你只剩下满脑子的架构设计和一地鸡毛。\n"
		text += "但这段经历让你比任何人都成熟。你不再相信画饼，你只相信代码。\n"
		
	elif "hong_target_sale" in paths: # Hong线套现
		text += "[color=#55FF55][b]结局：精致的利己主义者[/b][/color]\n"
		text += "公司卖了个好价钱。你拿到了分红，买了房，成为了别人眼里的成功人士。\n"
		text += "偶尔深夜，你会想起那个想做独立游戏的念头，然后笑着摇摇头：'太幼稚了'。\n"

	else:
		text += "[color=#FFFFFF]结局：未完待续...[/color]\n"
		text += "你在洪流中活下来了。这本身就是一种胜利。"

	return text

func get_archetype_name():
	# 简单转换一下 Code 到中文
	match Global.current_archetype_code: # 注意：需要在 Global 里存一下这个变量
		"ARCH_STRIVER": return "错位过客"
		"ARCH_SURVIVOR": return "霓虹暗面"
		_: return "普通学生"

func has_path(id):
	return id in Global.selected_paths
