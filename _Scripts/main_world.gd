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
# 处理图书馆选座回调
var current_session_mood_modifier: float = 1.0
func _on_library_session_started(seat_data, random_event):
	print(">>> 图书馆选座完毕，准备进入心流状态...")
	
	# 重置心情修正
	current_session_mood_modifier = 1.0

	# 1. 应用随机事件的“见面礼” (Instant Shock)
	# (例如看到别人iPad，先扣一波血)
	var effects = random_event.get("effect", {})
	if not effects.is_empty():
		var evt_id = random_event.get("id", "UNKNOWN")
		apply_effects_dict(effects, evt_id)
		if effects.has("stress") and effects["stress"] < 0:
			current_session_mood_modifier = 0.6
			print("✨ 心情不错！接下来的学习压力将大幅降低。")

	# 2. 激活座位 Buff
	if seat_data.has("stats"):
		Global.current_study_buff = seat_data["stats"]
	
	# 3. [核心修改] 并不是直接恢复游戏，而是开始“干活”
	# 我们模拟这次学习持续了 3 个小时 (你可以做成随机 2-4 小时)
	var study_duration = 3.0 
	
	# 4. 调用模拟函数 (填补缺失的环节)
	await simulate_study_session(study_duration)
	
	# 5. 学习结束，Buff 失效
	Global.clear_study_buff()
	
	# 6. 恢复游戏控制权
	get_tree().paused = false

# --- 模拟：直接结算两小时的学习成果 (示例) ---

# MainWorld.gd

# MainWorld.gd

func simulate_study_session(hours: float):
	# 1. 模拟时间流逝
	await get_tree().create_timer(1.0).timeout 
	
	# 🔒【安全检查 1】崩溃锁
	if Global.is_in_breakdown:
		Global.clear_study_buff()
		return

	print("--- 结算 %.1f 小时的学习成果 ---" % hours)

	# ==========================================================================
	# A. 计算收益 (Progress)
	# ==========================================================================
	var eff_data = Global.get_efficiency()
	var base_gain_per_hour = 5.0
	var total_progress = base_gain_per_hour * hours * eff_data.value
	
	# [地点匹配检查]
	if Global.current_project_location != "" and Global.current_project_location != "LIB":
		print("❌ 地点错误！这事儿得去 %s 做！" % Global.current_project_location)
		total_progress *= 0.1
	
	# [应用进度]
	var project_name = "无目标漫游"
	if Global.current_active_project_id != "":
		project_name = Global.life_path_db[Global.current_active_project_id]["name"]
		Global.project_progress += total_progress
		Global.record_journal("PROGRESS", total_progress, "推进项目: " + project_name)
		
		# 🔥 立即检查是否完成 (防止进度条溢出不结算)
		Global.check_project_completion()
	else:
		Global.add_sedimentation(1)
		Global.record_journal("WASTE", 0, "图书馆发呆")

	# ==========================================================================
	# B. 计算代价 (Stress & Anxiety)
	# ==========================================================================
	var base_cost_per_hour = 5.0 
	var raw_stress_base = base_cost_per_hour * hours
	
	# [心情红利计算]
	var final_stress_base = raw_stress_base * current_session_mood_modifier
	var mood_saved_amount = raw_stress_base - final_stress_base
	
	# 🔥 记录原始焦虑值
	var old_anxiety = Global.current_anxiety
	
	# [应用主压力]
	var stress_result = Global.apply_stress(final_stress_base, "STUDY")
	var actual_damage = stress_result.damage
	
	# 🔥 记录新的焦虑值 (如果崩溃了，Global会被重置，这里取结果即可)
	var new_anxiety = stress_result.current_anxiety
	
	if actual_damage > 0:
		Global.record_journal("STRESS", actual_damage, "学习压力")

	# 🔒【安全检查 2】如果学习直接导致崩溃
	# 我们不立即 return，是为了让玩家看到这一帧的结算单，死个明白。
	# 下面的文案逻辑会处理崩溃显示。

	# ==========================================================================
	# C. 额外风险 (Distraction)
	# ==========================================================================
	var distraction_damage = 0.0 # 用于统计
	
	if not Global.is_in_breakdown:
		var distracted = Global.check_is_distracted()
		if distracted:
			var dist_res = Global.apply_stress(5.0, "GEN")
			distraction_damage = dist_res.damage
			new_anxiety = dist_res.current_anxiety # 更新最终焦虑
			Global.log_story("学习期间没忍住刷了会儿手机，感到一阵空虚。")

	# ==========================================================================
	# D. 生成 UI 反馈 (Bill) - 文案优化版
	# ==========================================================================
	var report_text = "—— 学习结算 (%.1f小时) ——\n" % hours
	
	# 1. 进度行
	if Global.current_active_project_id != "":
		report_text += "📈 进度: +%.1f%% (%s)\n" % [total_progress, project_name]
	else:
		report_text += "📈 进度: 无 (未立项)\n"
	
	# 2. 焦虑变化行 (核心修改)
	if Global.is_in_breakdown:
		report_text += "🧠 焦虑: %.1f -> 💥 崩溃！\n(弦断了，你需要休息)" % old_anxiety
	else:
		var diff = new_anxiety - old_anxiety
		if diff > 0:
			report_text += "🧠 焦虑: +%.1f " % diff
			if diff < 15:
				report_text += "(压力也是动力)" # <--- 积极文案
			else:
				report_text += "(有些疲惫)"
		elif diff <= 0:
			report_text += "🧠 焦虑: %.1f (状态回升)" % diff
	
	# 3. 分心惩罚行
	if distraction_damage > 0:
		report_text += "\n📱 分心惩罚: +%.1f (刷手机)" % distraction_damage

	# 4. 心情红利行
	if mood_saved_amount > 0:
		var saved_final = mood_saved_amount * Global.sensitivity
		report_text += "\n✨ 心情好抵消了约 %.1f 点伤害" % saved_final
		
	# 5. 发送给 UI 显示
	if ui and ui.has_method("show_status_report"):
		ui.show_status_report(report_text, 3.0)
	else:
		print(report_text) 

	# ==========================================================================
	# E. 收尾与时间推进
	# ==========================================================================
	Global.clear_study_buff() 
	
	if not Global.is_in_breakdown:
		var need_settlement = Global.advance_time(1)
		if need_settlement:
			Global.show_settlement()


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
