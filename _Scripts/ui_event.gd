extends CanvasLayer

@onready var content_label = $Control/Panel/Label
@onready var panel_root = $Control

# 引用刚才新建的两个 Label
@onready var money_label = $StatsPanel/MoneyLabel
@onready var anxiety_label = $StatsPanel/AnxietyLabel
@onready var option_container = $Control/Panel/OptionContainer # 引用刚才建的容器

# 当前正在处理的事件数据 (临时存一下)
var current_event_data = {}

func _ready():
	panel_root.visible = false
	update_hud() # 游戏开始时刷新一次

func _process(delta):
	# 偷懒写法：每一帧都刷新显示（MVP阶段没问题）
	# 这样只要 Global 里的数值变了，界面马上就变
	update_hud()

func update_hud():
	money_label.text = "资金: ¥" + str(Global.stats["money"])
	# 焦虑值保留一位小数
	anxiety_label.text = "焦虑: " + str(snapped(Global.stats["anxiety"], 0.1)) + "%"

# 预制一个简单的按钮场景 (或者直接代码new)
func show_event_popup(event_data: Dictionary):
	current_event_data = event_data
	content_label.text = event_data["description"]
	
	# 1. 先清空旧按钮
	for child in option_container.get_children():
		child.queue_free()
	
	# 2. 根据事件ID做特殊处理 (这里是暂时的逻辑，后期会读表)
	if event_data["id"] == "EVT_401": # 父亲的手术
		add_choice_button("A. 保守治疗 (花费 5000)", -5000, 40)
		add_choice_button("B. 就要最好的 (花费 40000)", -40000, -10)
	else:
		# 默认按钮
		add_choice_button("确定", event_data.get("money_change", 0), event_data.get("base_stress", 0))
	
	panel_root.visible = true
	get_tree().paused = true

# 辅助函数：添加一个按钮
func add_choice_button(text: String, money_cost: int, stress_change: int):
	var btn = Button.new()
	btn.text = text
	# 稍微调大一点字体
	btn.add_theme_font_size_override("font_size", 24) 
	
	# 关键：连接信号，要把后果传进去
	# 使用 bind 把参数绑定到信号上
	btn.pressed.connect(_on_choice_selected.bind(money_cost, stress_change))
	option_container.add_child(btn)

# 统一处理选择
func _on_choice_selected(money_cost, stress_change):
	Global.stats["money"] += money_cost
	Global.stats["anxiety"] += stress_change
	
	print("选择了分支。资金: ", money_cost, " 焦虑: ", stress_change)
	
	panel_root.visible = false
	get_tree().paused = false

func _on_button_pressed():
	# --- 核心修改：在这里结算数值！---
	apply_event_effects()
	
	panel_root.visible = false
	get_tree().paused = false

# 新增：结算函数
func apply_event_effects():
	if current_event_data.is_empty():
		return
		
	# 1. 扣钱/加钱
	var money_change = current_event_data.get("money_change", 0)
	Global.stats["money"] += money_change
	
	# 2. 焦虑/压力变化 (CSV里叫 base_stress)
	var stress_change = current_event_data.get("base_stress", 0)
	Global.stats["anxiety"] += stress_change
	
	# 3. 沉淀值变化
	var settlement_change = current_event_data.get("settlement_change", 0)
	Global.stats["settlement"] += settlement_change
	
	print("结算完成：资金变动 ", money_change, " 焦虑变动 ", stress_change)
	
	# 清空当前事件
	current_event_data = {}
