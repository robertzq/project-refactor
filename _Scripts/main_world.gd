extends Node3D

@onready var player = $Player
@onready var ui = %UI_Event
# 请确保场景树中该节点的路径正确，或者它是 MainWorld 的直接子节点
@onready var library_view = $LibraryView 

func _ready():
	# --- 1. 图书馆界面初始化 ---
	if library_view:
		library_view.hide()
		# 修复：只连接一次信号！之前连接了两次会导致逻辑跑双倍
		if not library_view.session_started.is_connected(_on_library_session_started):
			library_view.session_started.connect(_on_library_session_started)
	else:
		printerr("❌ 错误：MainWorld 下面找不到 'LibraryView' 节点！")
		
	# --- 2. 玩家交互事件 ---
	# 当玩家发出“撞墙”信号时，让 UI 显示那个 ID
	player.hit_building.connect(func(building_id):
		# 如果撞的是图书馆，直接显示选座界面，而不是弹通用事件框
		if building_id == "LIB":
			# 暂停游戏，防止玩家在选座时乱跑
			get_tree().paused = true
			if library_view: 
				library_view.setup() # 调用初始化函数
			else:
				printerr("LibraryView 未连接")
		else:
			# 其他建筑走通用事件逻辑
			var event_data = Global.get_random_event(building_id)
			if ui: ui.show_event(event_data)
	)

func _input(event):
	# 按 "P" 键模拟半个月结束，弹出结算报告 (调试用)
	if event.is_action_pressed("ui_accept"): 
		Global.show_settlement()
		
	# 按 "E" 键 (示例) 显示结局
	if event.is_action_pressed("ui_cancel"): 
		show_ending()

# ==============================================================================
# 核心逻辑：处理图书馆选座回调
# ==============================================================================
func _on_library_session_started(seat_data, random_event):
	print(">>> 图书馆选座完毕，开始结算...")
	
	# 1. 恢复游戏控制权
	get_tree().paused = false
	
	# 2. 应用随机事件的即时效果 (Instant Shock)
	# 比如：看到情侣（压力+5），看到学霸（压力+10）
	var effects = random_event.get("effect", {})
	if not effects.is_empty():
		# 传入 event_id 以便判断是不是自尊打击
		var evt_id = random_event.get("id", "UNKNOWN")
		apply_effects_dict(effects, evt_id)
	
	# 3. 激活“持续性 Buff” (Duration Buff)
	# seat_data["stats"] 结构: {"eff_mod": 1.3, "stress_fix": 0, "distraction_chance": 0.25}
	if seat_data.has("stats"):
		Global.current_study_buff = seat_data["stats"]
		print("✅ [MainWorld] 已激活学习状态: ", Global.current_study_buff)
	
	# 4. (后续逻辑建议) 
	# 这里只是“坐下了”。真正产生进度（project_progress）和累积压力（Apply Stress "STUDY"）
	# 通常需要玩家再执行“开始工作”的操作，或者自动进入一个“专注时钟”流程。
	# 下面是一个示例：直接模拟过了 2 小时
	# simulate_study_session(2.0) 

# --- 模拟：直接结算两小时的学习成果 (示例) ---
func simulate_study_session(hours: float):
	print("--- 开始模拟 %.1f 小时的高强度学习 ---" % hours)
	
	# 1. 计算产出 (受 Global.get_efficiency() 影响，那里包含了座位加成)
	var eff_data = Global.get_efficiency()
	var progress_gain = 5.0 * hours * eff_data.value
	
	Global.project_progress += progress_gain
	print("   > 进度增加: %.1f (效率: %.1f%% - %s)" % [progress_gain, eff_data.value * 100, eff_data.desc])
	
	# 2. 计算代价 (受 Global.entropy 和 座位 stress_fix 影响)
	# 使用 "STUDY" 类型，这会触发 Global 里关于 entropy 的惩罚公式
	Global.apply_stress(10.0 * hours, "STUDY")
	
	# 3. 检查是否分心
	if Global.check_is_distracted():
		print("   > 期间你玩了一会儿手机...")
		Global.apply_stress(5.0, "GEN") # 额外的内疚压力

	# 4. 离开座位，Buff 失效
	Global.clear_study_buff()


# --- 辅助工具：解析字典并应用效果 ---
func apply_effects_dict(effect_map: Dictionary, event_id: String = ""):
	for key in effect_map:
		var val = effect_map[key]
		match key:
			"stress":
				# 智能判断压力类型
				# 如果事件ID包含 PRESSURE (同辈压力) 或 GADGET (攀比)，视为 EGO 伤害
				var type = "GEN"
				if "PRESSURE" in event_id or "GADGET" in event_id:
					type = "EGO"
				
				Global.apply_stress(val, type)
				
			"pride":
				Global.pride += val
				print(">> 自尊变化: ", val)
				
			"money", "fin_security": 
				Global.money += val # 假设直接加钱
				
			_:
				print("未处理的属性: ", key)

func show_ending():
	print(">>> 触发结局！")
	
	# 1. 检查 EndingManager 是否存在
	if not has_node("/root/EndingManager"):
		printerr("❌ 严重错误：找不到 /root/EndingManager，无法生成结局！")
		return

	# 2. 让 EndingManager 算出一篇作文
	# 注意：这里调用的是你刚刚写的那个脚本里的函数
	var ending_text = get_node("/root/EndingManager").generate_verdict()
	
	# 3. 加载 UI 界面
	var ui_scene = load("res://_Scenes/UI_Settlement.tscn")
	if ui_scene:
		var ui = ui_scene.instantiate()
		
		# 4. 【关键】在 add_child 之前注入文案！
		# 这样当 UI 的 _ready() 运行时，它就知道"哦，这是结局模式"
		if ui.has_method("setup_as_ending"):
			ui.setup_as_ending(ending_text)
		
		# 5. 显示出来
		add_child(ui)
		
		# 暂停游戏 (虽然 UI 脚本里也写了，这里双重保险)
		get_tree().paused = true
	else:
		printerr("❌ 找不到 UI_Settlement.tscn 场景文件！")
