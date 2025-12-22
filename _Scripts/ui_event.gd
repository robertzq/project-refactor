extends CanvasLayer

# 引用 UI 节点 (请确保节点路径和你的场景一致)
@onready var panel_root = $Control
@onready var title_label = $Control/Panel/TitleLabel # 你可能需要新建这个Label，或者用现有的
@onready var content_label = $Control/Panel/Label
@onready var option_container = $Control/Panel/OptionContainer
@onready var result_log_label = $Control/Panel/ResultLog # 新建一个 Label 用来显示结算结果，如果没有就用 print

# 引用 HUD 节点 (左上/右上角的属性条)
@onready var money_label = $StatsPanel/MoneyLabel
@onready var anxiety_label = $StatsPanel/AnxietyLabel
@onready var ap_label = $StatsPanel/APLabel # 假设你有这个，如果没有先忽略

var current_event: Dictionary = {}

func _ready():
	panel_root.visible = false
	update_hud()

func _process(delta):
	# 实时刷新 HUD，方便观察数值变化
	update_hud()

# ========================================================
# 1. HUD 刷新逻辑 (对接 Global 新属性)
# ========================================================
func update_hud():
	# 资金
	if money_label:
		money_label.text = "资金: ¥%d" % Global.money
	
	# 焦虑条 (显示为 "当前 / 阈值")
	if anxiety_label:
		# 比如: 焦虑: 45.2 / 96.0 (重伤)
		var limit = Global.max_anxiety_limit
		var current = Global.current_anxiety
		var status = ""
		if current >= limit: status = "(崩溃)"
		elif current >= limit * 0.5: status = "(重伤)"
		
		anxiety_label.text = "焦虑: %.1f / %.1f %s" % [current, limit, status]
		
		# 变色提醒
		if current >= limit * 0.5:
			anxiety_label.modulate = Color(1, 0.3, 0.3) # 变红
		else:
			anxiety_label.modulate = Color(1, 1, 1)

# ========================================================
# 2. 事件弹窗逻辑 (The Display)
# ========================================================
func show_event(event_data: Dictionary):
	current_event = event_data
	
	# 1. 填充文本
	# 如果 CSV 里有 title 字段就用，没有就用 ID
	if title_label:
		title_label.text = event_data.get("title", "事件")
	content_label.text = event_data.get("desc", "")
	
	# 2. 清空旧按钮
	for child in option_container.get_children():
		child.queue_free()
	
	# 3. 解析选项字符串 "A:xxx|B:xxx"
	var raw_options = event_data.get("raw_options", "")
	var options_list = raw_options.split("|")
	
	for i in range(options_list.size()):
		var opt_text = options_list[i]
		add_choice_button(opt_text, i)
	
	# 4. 暂停游戏并显示
	panel_root.visible = true
	get_tree().paused = true

func add_choice_button(text: String, index: int):
	var btn = Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 20)
	# 连接信号：传递 index，以便区分选了 A 还是 B
	btn.pressed.connect(_on_choice_selected.bind(index))
	option_container.add_child(btn)

# ========================================================
# 3. 核心结算逻辑 (The Core Loop)
# ========================================================
func _on_choice_selected(index: int):
	var evt_id = current_event.get("id", "")
	var base_stress = current_event.get("base_stress", 0)
	var type = current_event.get("type", "GEN")
	
	print("Player chose option: ", index, " for event: ", evt_id)
	
	# --- 针对 Demo 的特殊分支逻辑 (Hardcoded for MVP) ---
	# 只要 Demo 跑通，后续我们再把这些逻辑移到 CSV 或单独的脚本里
	
	if evt_id == "evt_scholarship": # 贫困生助学金 (EGO)
		if index == 0: # A: 大声说出 (要钱，丢人)
			Global.money += 2000
			Global.pride -= 2
			apply_stress(base_stress, "EGO") # 正常承受 EGO 伤害
		else: # B: 放弃 (没钱，保面子)
			# 放弃虽然没钱，但也会因为"错失机会"而焦虑，但类型是普通 GEN
			apply_stress(15, "GEN") 
			
	elif evt_id == "evt_bitcoin": # 比特币 (VISION)
		if index == 0: # A: 记下来
			# 这里应该解锁地图节点，MVP先只加个日志
			print(">>> 解锁节点：加密货币论坛")
			Global.entropy += 1 # 提升认知
		else: # B: 觉得是传销
			print(">>> 错失机会")
	
	elif evt_id == "evt_laptop_break": # 电脑坏了 (MONEY)
		if index == 0: # A: 修 (花大钱)
			Global.money -= 2000 # 巨款
			apply_stress(10, "GEN") # 破财消灾，压力较小
		else: # B: 硬抗
			apply_stress(base_stress, "MONEY") # 没钱修，承受完整伤害
			
	else:
		# --- 通用逻辑 (对于填充事件) ---
		if index == 0: # 默认 A 选项承受事件压力
			apply_stress(base_stress, type)
		else: # 默认 B 选项为逃避/放弃 (承受一半通用压力)
			apply_stress(base_stress * 0.5, "GEN")
	
	# 关闭弹窗
	panel_root.visible = false
	get_tree().paused = false

# 封装调用 Global 的公式
func apply_stress(val, type):
	# 这是一个关键点：调用 Global 的计算器
	# 可以在这里判断是否在打工 (is_working)，目前先传 false
	var result = Global.apply_stress(val, type, false)
	
	# 打印详细计算日志到控制台 (非常爽)
	print("------------------------------------------------")
	print("【结算报告】")
	print("事件类型: ", type, " | 基础压力: ", val)
	print("公式日志: ", result.log)
	print("最终伤害: ", result.damage)
	print("当前焦虑: ", result.current_anxiety)
	if result.breakdown:
		print("!!! 玩家崩溃 !!!")
	print("------------------------------------------------")
