extends Control

@onready var story_text = $Panel/StoryText

func _ready():
	generate_diary()
	# 暂停游戏
	get_tree().paused = true

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
	text += "比如" + events_experienced.pick_random() + "，还有" + events_experienced.pick_random() + "。\n\n"
	
	# --- B. 焦虑描写 (Stress) ---
	if total_stress > 50:
		text += "[color=#ff5555]我很焦虑。[/color] 这种压力几乎让我窒息，有好几个晚上我盯着天花板，感觉心脏在剧烈跳动。\n"
	elif total_stress > 20:
		text += "虽然有些磕磕绊绊，感到了一丝疲惫，但好在还能勉强支撑。\n"
	else:
		text += "这段日子过得还算平稳，没有太大的风浪。\n"
		
	# --- C. 沉淀描写 (Sedimentation) - 核心心态变化 ---
	# 这里体现“沉淀”如何抵消“焦虑”
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

func _on_next_btn_pressed():
	# 清空日志，准备下一轮
	Global.clear_journal()
	# 恢复游戏
	get_tree().paused = false
	queue_free() # 关闭窗口
