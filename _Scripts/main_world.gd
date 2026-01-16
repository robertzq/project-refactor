extends Node3D

@onready var player = $Player
@onready var ui = %UI_Event
@onready var library_view = $LibraryView # 假设路径在这里
func _ready():
	if library_view:
		library_view.hide() # 游戏开始时先隐藏
		# 连接信号：当选座结束时，触发 _on_library_session_started
		library_view.session_started.connect(_on_library_session_started)
	else:
		print("❌ 错误：MainWorld 下面找不到 'LibraryView' 节点！")
		
	# 当玩家发出“撞墙”信号时，让 UI 显示那个 ID
	player.hit_building.connect(func(building_id): 
		var event_data = Global.get_random_event(building_id)
		ui.show_event(event_data) 
	)
	if library_view:
		# 这是一个来自 LibraryView.gd 的自定义信号
		# signal session_started(seat_data, random_event)
		library_view.session_started.connect(_on_library_session_started)
	
func _input(event):
	# 按 "P" 键模拟半个月结束，弹出结算报告
	if event.is_action_pressed("ui_accept"): # 或者自定义按键
		Global.show_settlement()
		
	if event.is_action_pressed("ui_end"): # 比如按 E 键
		show_ending()

# --- 核心：处理图书馆结算 ---
func _on_library_session_started(seat_data, random_event):
	print(">>> 图书馆选座完毕，开始结算...")
	
	# 1. 恢复游戏 (因为 UI 关闭了)
	get_tree().paused = false
	
	# 2. 应用随机事件的即时效果 (看到iPad焦虑了)
	# 这里的 random_event 结构是 {"text":..., "effect": {"stress": 10}}
	var effects = random_event.get("effect", {})
	if not effects.is_empty():
		apply_effects_dict(effects)
	
	# 3. 记录当前的学习状态 (Buff)
	# seat_data 包含 {"eff_mod": 1.3, "stress_fix": 5}
	# 你可以将这个存入 Global，用于接下来的“学习小游戏”或者“时间流逝”计算
	Global.current_study_buff = seat_data["stats"]
	
	print(">>> 获得学习 Buff: ", Global.current_study_buff)
	
	# 4. (可选) 如果你想立刻弹出一个提示，告诉玩家开始学习了
	# ui_event.show_toast("开始专注学习...") 

# --- 辅助工具：解析字典并应用效果 ---
# 这是一个简化的解析器，专门处理 UI 传回来的字典
func apply_effects_dict(effect_map: Dictionary):
	for key in effect_map:
		var val = effect_map[key]
		match key:
			"stress":
				Global.apply_stress(val, "LIB") # 使用 Global 的逻辑
			"pride":
				Global.pride += val
			"fin_security": # 假如有些事件影响钱
				Global.fin_security += val
			_:
				print("未处理的属性: ", key)

func show_ending():
	var ending_text = EndingManager.generate_verdict()
	# 复用那个漂亮的半月结算界面，或者新建一个
	var ui = load("res://_Scenes/UI_Settlement.tscn").instantiate()
	add_child(ui)
	ui.story_text.text = ending_text
	get_tree().paused = true
