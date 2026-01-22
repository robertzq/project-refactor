extends Control

signal session_ended

func setup():
	show()

func _on_buy_cheap_pressed():
	_eat_food(8, 0, "一碗清汤挂面，只有几根青菜。")

func _on_buy_normal_pressed():
	_eat_food(15, -5, "加了大鸡腿，感觉活过来了。")

func _on_buy_luxury_pressed():
	# 只有富裕时才敢点
	if Global.money < 40:
		$Panel/Label.text = "囊中羞涩，吃不起..."
		return
	_eat_food(40, -15, "点了最贵的小炒肉，引来室友羡慕的目光。")

func _eat_food(cost, stress_relief, desc):
	if Global.money >= cost:
		Global.money -= cost
		Global.log_story(desc)
		
		if stress_relief < 0:
			var res = Global.apply_stress(stress_relief, "GEN") # 负数即回血
		
		$Panel/Label.text = "花费 ¥%d。%s" % [cost, desc]
		
		# 食堂可能会听到八卦 (20%概率)
		if randf() < 0.2:
			await get_tree().create_timer(1.0).timeout
			# 触发食堂通用事件
			var evt = Global.get_random_event("CAFE")
			get_node("/root/MainWorld").ui.show_event(evt)
			
		await get_tree().create_timer(1.0).timeout
		_close_scene()
	else:
		$Panel/Label.text = "钱不够... 尴尬了。"

func _close_scene():
	hide()
	emit_signal("session_ended")
	get_tree().paused = false
