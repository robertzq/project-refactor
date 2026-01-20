extends CanvasLayer

# --- 节点引用 ---
# 注意：确保这些路径在你的场景里真实存在
@onready var panel_root = $Control
@onready var title_label = $Control/Panel/TitleLabel 
@onready var content_label = $Control/Panel/Label
@onready var option_container = $Control/Panel/OptionContainer
# @onready var result_log_label = $Control/Panel/ResultLog # 如果还没做这个Label，先注释掉以免报错

# HUD 引用
@onready var money_label = $StatsPanel/MoneyLabel
@onready var anxiety_label = $StatsPanel/AnxietyLabel
@onready var time_label = $StatsPanel/TimeLabel
@onready var project_label = $StatsPanel/ProjectLabel
# @onready var ap_label = $StatsPanel/APLabel 
@onready var status_lbl = $StatusChangeLbl

var current_event: Dictionary = {}

func _ready():
	panel_root.visible = false
	# 初始隐藏，防止挡住视线
	update_hud()
	if status_lbl:
		status_lbl.hide()
		status_lbl.modulate.a = 0 # 透明度设为0

func _process(_delta):
	# 实时刷新 HUD
	update_hud()

# ========================================================
# 1. HUD 刷新逻辑
# ========================================================
func update_hud():
	if money_label:
		money_label.text = "资金: ¥%d" % Global.money 
	
	if time_label:
		time_label.text = "第 %d 周" % Global.current_week
	
	if project_label:
		if Global.current_active_project_id != "":
			var p_name = Global.life_path_db[Global.current_active_project_id]["name"]
			project_label.text = "目标: %s\n进度: %.1f%%" % [p_name, Global.project_progress]
		else:
			project_label.text = "当前无目标\n(按TAB规划)"
			
	if anxiety_label:
		var current = Global.current_anxiety
		
		# 🔥 核心修改：不再写死 100.0，而是读取 Global 的动态上限
		# 确保 Global.gd 里有 get_max_anxiety_limit() 函数
		var limit = Global.get_max_anxiety_limit() 
		
		# 显示格式：焦虑: 45.2 / 96.0
		anxiety_label.text = "焦虑: %.1f / %.1f" % [current, limit]
		
		# 颜色警示逻辑 (可调整)
		if current >= limit * 0.9:
			anxiety_label.modulate = Color(1, 0, 0) # 红色 (极危)
		elif current >= limit * 0.7:
			anxiety_label.modulate = Color(1, 0.5, 0) # 橙色 (警告)
		else:
			anxiety_label.modulate = Color(1, 1, 1) # 白色 (正常)

# ========================================================
# 2. 事件弹窗逻辑
# ========================================================
func show_event(event_data: Dictionary):
	current_event = event_data
	print("UI 显示事件: ", event_data.get("id")+ "=>"+ event_data.get("title"))
	
	# 1. 填充文本
	if title_label:
		title_label.text = event_data.get("title", "未知事件")
	if content_label:
		content_label.text = event_data.get("desc", "没有描述...")
	
	# 2. 清空旧按钮
	for child in option_container.get_children():
		child.queue_free()
	
	# 3. 解析选项 "A:硬抗|B:逃避"
	# 你的 CSV 必须有一列叫 'options' (或者 'raw_options')
	var options_str = event_data.get("options", "") # CSV表头如果是 options 就写 options
	if options_str == "":
		options_str = "继续" # 防止空选项导致卡死
		
	var options_list = options_str.split("|")
	
	for i in range(options_list.size()):
		add_choice_button(options_list[i], i)
	
	# 4. 暂停并显示
	panel_root.visible = true
	get_tree().paused = true

func add_choice_button(text: String, index: int):
	var btn = Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 24)
	btn.custom_minimum_size.y = 50
	# 绑定点击信号
	btn.pressed.connect(_on_choice_selected.bind(index))
	option_container.add_child(btn)

# ========================================================
# 3. 核心结算逻辑
# ========================================================
# --- UI_Event.gd ---

func _on_choice_selected(index: int):
	# 1. 动态获取指令字符串
	# 如果 CSV 表头叫 effect_a 和 effect_b，这里就能直接取到
	var effect_key = "effect_a" if index == 0 else "effect_b"
	var effect_str = current_event.get(effect_key, "")
	
	print(">>> 玩家选择: ", index)
	print(">>> 执行脚本: ", effect_str)
	
	# 2. 交给解析器处理
	parse_and_execute(effect_str)

	# 3. 关闭弹窗
	panel_root.visible = false
	get_tree().paused = false
	


# --- 通用指令解析器 (核心逻辑) ---
func parse_and_execute(command_str: String):
	if command_str == "" or command_str == null: 
		print("   (无指令)")
		return
	
	# 1. 按分号拆分多条指令 (例: "money:-300;pride:1")
	var commands = command_str.split(";")
	var story_fragment = ""
	var current_title = current_event.get("title", "未知事件")
	for cmd in commands:
		# 2. 按冒号拆分参数 (例: "stress:20:EGO")
		var parts = cmd.split(":")
		var action = parts[0].strip_edges() # 去除空格
		
		match action:
			"money":
				var val = int(parts[1])
				Global.money += val # 确保 Global里有money变量
				print("   -> 资金变动: ", val)
				# 只记录大额变动，买瓶水这种小事不用记
				if abs(val) >= 100:
					Global.record_journal("MONEY", val, current_title)
				
			"pride":
				var val = int(parts[1])
				Global.pride += val
				print("   -> 自尊变动: ", val)
				
			"entropy":
				var val = int(parts[1])
				Global.entropy += val
				print("   -> 熵变动: ", val)
				
			"trait":
				var t_name = parts[1]
				Global.add_trait(t_name)
				print("   -> 获得特质: ", t_name)
				
			"stress":
				# 语法: stress:数值:类型 (例如 stress:20:EGO)
				var val = float(parts[1])
				var type = "GEN"
				if parts.size() > 2: 
					type = parts[2]
				# 这里会调用我们在 Global 里写好的 v3.2 复杂公式
				var result = Global.apply_stress(val, type, false)
				var actual_damage = result.damage
				# ★ 记录：如果伤害很高，要重点记录
				if actual_damage > 0:
					Global.record_journal("STRESS", actual_damage, current_title)
				elif actual_damage < 0:
					Global.record_journal("HEAL", actual_damage, current_title)
				
			"work":
				# 特殊语法: work:true (标记这次事件属于工作性质，用于触发避难所计算)
				# 如果上一条指令是 stress，这里其实无法追溯修正上一条。
				# 更好的写法是把 work 参数传给 apply_stress，但为了简化 MVP，
				# 我们暂时认为 work:true 只是一个标记，或者你可以把它整合进 stress 指令里
				# 比如 stress:20:WORK:TRUE。
				# 目前简单起见，仅打印
				var state = parts[1] == "true"
				Global.is_employed = state
				print("   -> 工作状态更新: ", Global.is_employed)
				
			"sed":
				# 语法: sed:1
				var val = int(parts[1])
				# 调用 Global 写好的逻辑，它会自动处理阈值和信号
				Global.add_sedimentation(val)
				# ★ 记录：这是最重要的心态变化
				Global.record_journal("SED", val, current_title)
			
			"progress":
				var val = float(parts[1])
				
				# 如果当前没有立项，进度加了也没用 (或者你可以设定为加通用经验)
				if Global.current_active_project_id == "":
					print("   -> 没有活跃项目，进度被浪费了...")
					Global.record_journal("WASTE", 0, "无目标的努力")
				else:
					var eff = Global.get_efficiency().value
					var actual = val * eff
					Global.project_progress += actual
					
					# 记录日记
					var p_name = Global.life_path_db[Global.current_active_project_id]["name"]
					Global.record_journal("PROGRESS", actual, "推进项目: " + p_name)
					
					print("   -> 项目进度: +%.1f (当前: %.1f%%)" % [actual, Global.project_progress])
					
					# 🔥 核心检查：是否完工？
					if Global.check_project_completion():
						# 触发完工特效/弹窗
						# 这里可以暂停游戏，弹出一个“项目完成！”的庆祝框
						# 简单起见，我们先记入日记，下次半月结算时表扬
						Global.record_journal("COMPLETE", 100, "完成里程碑: " + p_name)
						Global.log_story("【里程碑达成】经过不懈努力，你终于拿下了《%s》！" % p_name)
			
			"time":
				if parts[1] == "pass":
					# 推进时间
					var need_settlement = Global.advance_time()
					
					if need_settlement:
						# 🛑 触发半月结算！
						Global.show_settlement()
			
			"relation": 
				# 语法: relation_hong:10 -> 拆分出 "relation_hong" 和 10
				# 或者 CSV 里写的是 relation_hong:10，那么 action 就是 "relation_hong"
				# 为了通用，建议 CSV 改写为 relation:hong:10，或者我们在 default 里处理
				pass 
			
			"path_branch":
				# 语法: path_branch:hong_wp
				# 这通常意味着解锁某个隐藏路径，或者设置某个剧情旗标
				var branch_id = parts[1]
				Global.unlock_hidden_path(branch_id) # 需要在 Global 加这个函数
				print("   -> 剧情分支解锁: ", branch_id)
							
			# --- 通用属性处理 (涵盖 relation_xxx, health, sanity 等) ---
			_:
				# 如果指令是 relation_hong:10
				if action.begins_with("relation_"):
					var val = int(parts[1])
					# 可以在 Global 里搞一个 relations 字典
					Global.update_relation(action, val)
				elif action == "sanity" or action == "health" or action == "charm":
					# 处理 CSV 里出现的这些额外属性
					var val = int(parts[1])
					print("   -> [未实装属性] %s 变动: %d" % [action, val])
				else:
					print("⚠️ 未知指令: ", action)
				
	# 循环结束后，把故事写入 Global
	if story_fragment != "":
		Global.log_story(story_fragment)
	else:
		# 如果没有特定的 progress 描述，可以用事件标题生成一个通用的
		var evt_title = current_event.get("title", "某事")
		Global.log_story("经历了事件：【%s】" % evt_title)
# 封装调用 Global
func apply_stress(val, type):
	# 确保 Global 里有这个函数，不然会报错
	if Global.has_method("apply_stress"):
		var result = Global.apply_stress(val, type, false)
		print("结算完毕。当前焦虑:", result.current_anxiety)
	else:
		print("Global.gd 缺少 apply_stress 函数！模拟扣除...")
		# 模拟逻辑，防止报错卡死
		if not Global.get("anxiety"): Global.set("anxiety", 0)
		Global.anxiety += val

var is_showing_status: bool = false

func _input(event):
	# 监听回车键或点击，且当前正在显示状态条
	if is_showing_status and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event is InputEventMouseButton):
		hide_status_report()
		# 消耗掉这个输入，防止穿透触发其他逻辑
		get_viewport().set_input_as_handled()

func show_status_report(text_content: String, _duration: float = 0.0): # duration 参数不再需要了
	if not status_lbl: return

	print(">>> UI 显示结算单 (等待按键关闭)")

	status_lbl.text = text_content + "\n\n[按回车键或点击关闭]" # 提示玩家
	status_lbl.show()
	status_lbl.modulate.a = 0.0

	# 淡入
	var tween = create_tween()
	tween.tween_property(status_lbl, "modulate:a", 1.0, 0.3)

	is_showing_status = true
	# 暂停游戏，防止玩家在看结算单时乱跑
	get_tree().paused = true 

func hide_status_report():
	if not status_lbl: return

	is_showing_status = false

	# 淡出并隐藏
	var tween = create_tween()
	tween.tween_property(status_lbl, "modulate:a", 0.0, 0.2)
	tween.tween_callback(status_lbl.hide)
	tween.tween_callback(func(): get_tree().paused = false) # 恢复游戏
