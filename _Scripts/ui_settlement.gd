extends Control

@onready var story_text = $Panel/StoryText
# 假设你的按钮节点叫 NextBtn，如果叫其他名字请自行修改，例如 $Panel/Button
@onready var next_btn = $Panel/NextBtn 

# 1. 新增变量：用于暂存外部传来的文本 (用于结局模式)
var custom_report_text: String = "" 

func _ready():
	# 2. 核心判断：如果有外部文案，就是结局；否则就是半月结算
	if custom_report_text != "":
		show_custom_report()
	else:
		generate_diary()
	
	# 暂停游戏，防止玩家在看报告时时间流逝或乱动
	get_tree().paused = true

# --- 新增：外部调用入口 (在 add_child 之前调用) ---
func setup_as_ending(text: String):
	custom_report_text = text

# --- 新增：显示自定义报告模式 (结局) ---
func show_custom_report():
	story_text.text = custom_report_text
	
	# 如果是结局，把按钮文字改一下
	if next_btn:
		next_btn.text = "结束旅程" 
		# 如果你想在结局时彻底断开原来的信号连接新的，也可以在这里写，
		# 但简单的做法是在 _on_next_btn_pressed 里做判断。

# --- 原有的半月日记生成逻辑 (保持不变) ---
func generate_diary():
	var total_stress = 0.0
	var total_progress = 0.0
	var total_sed = 0
	var events_experienced = []
	
	# 1. 汇总数据
	for log in Global.journal_logs:
		match log.type:
			"STRESS": total_stress += log.val
			"PROGRESS": total_progress += log.val
			"SED": total_sed += log.val
			_: pass
		
		if log.desc not in events_experienced:
			events_experienced.append(log.desc)
	
	# 2. 开始生成文案 (拼凑故事)
	var text = "[center][b]—— 半月谈 ——[/b][/center]\n\n"
	
	# --- A. 开头：回顾经历了什么 ---
	text += "[color=#aaaaaa]这段时间，我经历了很多事……[/color]\n"
	if events_experienced.size() > 0:
		text += "比如" + events_experienced.pick_random()
		if events_experienced.size() > 1:
			text += "，还有" + events_experienced.pick_random()
		text += "。\n\n"
	else:
		text += "日子平平淡淡，没有什么特别值得记录的。\n\n"
	
	# --- B. 焦虑描写 (Stress) ---
	if total_stress > 50:
		text += "[color=#ff5555]我很焦虑。[/color] 这种压力几乎让我窒息，有好几个晚上我盯着天花板，感觉心脏在剧烈跳动。\n"
	elif total_stress > 20:
		text += "虽然有些磕磕绊绊，感到了一丝疲惫，但好在还能勉强支撑。\n"
	else:
		text += "这段日子过得还算平稳，没有太大的风浪。\n"
		
	# --- C. 沉淀描写 (Sedimentation) ---
	if total_sed > 0:
		text += "\n[color=#88ffff]但也有一种奇妙的变化正在发生。[/color]\n"
		text += "在那些死磕难关的深夜里，我感到内心某种浮躁的东西沉淀下来了。\n"
		if Global.entropy > 5:
			text += "我似乎开始看清这个世界的底层逻辑了，这种[b]眼界的开阔[/b]让我不再那么慌张。\n"
		else:
			text += "虽然身体很累，但心里反而觉得踏实了一些。\n"
	else:
		if total_stress > 30:
			text += "\n[color=#aaaaaa]但我感觉自己只是在空转。[/color] 忙忙碌碌却没有任何沉淀，这种徒劳感比疲劳更可怕。\n"

	# --- D. 进度描写 (Progress) ---
	text += "\n[b]关于项目：[/b]\n"
	if total_progress > 10:
		text += "看着进度条推进了 [color=#ffff00]%.1f%%[/color]，我知道所有的付出都有了回报。这不只是数字，这是我的作品。\n" % total_progress
	elif total_progress > 0:
		text += "项目推进了 %.1f%%。虽然很慢，但至少在往前走。\n" % total_progress
	else:
		text += "项目停滞不前。我必须行动起来了，否则 deadline 会教我做人。\n"
		
	# --- E. 结尾 ---
	text += "\n[right]—— 现在的焦虑值: %.1f[/right]" % Global.current_anxiety
	
	story_text.text = text

# --- 按钮回调 ---
func _on_next_btn_pressed():
	# 1. 如果是结局模式，点击按钮退出游戏或回主菜单
	if custom_report_text != "":
		print(">>> 游戏结束，退出游戏")
		get_tree().quit() 
		# 或者: get_tree().change_scene_to_file("res://_Scenes/MainMenu.tscn")
	
	# 2. 如果是半月结算模式，继续游戏
	else:
		Global.clear_journal() # 清空旧日志
		get_tree().paused = false # 恢复时间流逝
		queue_free() # 关闭弹窗
