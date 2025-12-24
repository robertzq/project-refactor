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
# @onready var ap_label = $StatsPanel/APLabel 

var current_event: Dictionary = {}

func _ready():
	panel_root.visible = false
	# 初始隐藏，防止挡住视线
	update_hud()

func _process(_delta):
	# 实时刷新 HUD
	update_hud()

# ========================================================
# 1. HUD 刷新逻辑
# ========================================================
func update_hud():
	if money_label:
		money_label.text = "资金: ¥%d" % Global.money # 确保 Global.gd 里有 money
	
	if anxiety_label:
		# 假设 Global 里叫 anxiety 或者 current_anxiety，请保持一致
		# 这里假设你 Global 里用的是 'sensitivity' 来代表焦虑阈值，或者你有单独的 anxiety
		# 为了跑通，我先用假数据代替，你记得换成 Global.xxx
		var current = Global.get("anxiety") if Global.get("anxiety") else 0.0
		var limit = 100.0 
		
		anxiety_label.text = "焦虑: %.1f / %.1f" % [current, limit]
		if current >= limit * 0.5:
			anxiety_label.modulate = Color.RED
		else:
			anxiety_label.modulate = Color.WHITE

# ========================================================
# 2. 事件弹窗逻辑
# ========================================================
func show_event(event_data: Dictionary):
	current_event = event_data
	print("UI 显示事件: ", event_data.get("id"))
	
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
				# 核心：效率乘区！
				var efficiency = Global.get_efficiency().value
				var actual_gain = val * efficiency
				Global.project_progress += actual_gain
				print("   -> 项目进度: +%.1f (基础%s x 效率%.1f)" % [actual_gain, parts[1], efficiency])
				Global.record_journal("PROGRESS", actual_gain, current_title)
				# 记录故事：如果这真的是在干活
				story_fragment = "在图书馆死磕项目，进度推进了 %.1f%%。" % actual_gain
			_:
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
		print("⚠️ Global.gd 缺少 apply_stress 函数！模拟扣除...")
		# 模拟逻辑，防止报错卡死
		if not Global.get("anxiety"): Global.set("anxiety", 0)
		Global.anxiety += val
