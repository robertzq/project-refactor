extends Node2D

signal session_ended # 结束信号

@onready var bg_rect = $TextureRect # 你的宿舍背景图
@onready var info_label = $Panel/Label

func setup():
	show()
	info_label.text = "回到宿舍。室友们似乎还没睡。"
	# 可以在这里根据时间切换背景（白天/晚上）

# --- 交互功能 ---

# 1. 睡觉：推进时间 + 大回血
func _on_sleep_btn_pressed():
	Global.log_story("你在宿舍昏睡了一整晚...")
	
	# 恢复逻辑
	var heal = 30.0
	Global.current_anxiety = max(0, Global.current_anxiety - heal)
	Global.record_journal("HEAL", heal, "宿舍睡眠")
	
	# 推进时间 (假设睡了8小时/或者直接过一天)
	Global.advance_time(1) 
	
	# 弹个提示然后退出
	info_label.text = "睡得很香。焦虑 -30。"
	await get_tree().create_timer(1.0).timeout
	_close_scene()

# 2. 卧谈会：触发 CSV 里的 DORM 事件
func _on_chat_btn_pressed():
	# 专门去 Global 里抓取类型为 'dorm_enter' 的事件
	# 你的 Excel 里有很多 dorm_enter 的事件 (比如 EVT_102_XUAN_PC)
	var evt = Global.get_random_event("DORM") 
	
	# 调用通用的 UI_Event 显示事件
	# 注意：这里需要 MainWorld 把 UI_Event 的引用传进来，或者用 Signal 发出去
	# 为了解耦，我们发信号给 MainWorld 处理
	if evt.id != "none":
		get_node("/root/MainWorld").ui.show_event(evt)
		_close_scene() # 关闭宿舍界面，把焦点给事件弹窗
	else:
		info_label.text = "大家都在玩手机，没人说话。"

func _close_scene():
	hide()
	emit_signal("session_ended")
	get_tree().paused = false
