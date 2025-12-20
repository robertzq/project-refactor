extends CanvasLayer

@onready var content_label = $Control/Panel/Label
@onready var panel_root = $Control

# 引用刚才新建的两个 Label
@onready var money_label = $StatsPanel/MoneyLabel
@onready var anxiety_label = $StatsPanel/AnxietyLabel

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

# 显示弹窗 (修改版：我们要把 event_data 存下来)
func show_event_popup(event_data: Dictionary):
	current_event_data = event_data # 存起来，一会儿结算用！
	
	content_label.text = event_data["description"]
	
	# 这里可以加个逻辑：显示事件带来的预览后果 (可选)
	# content_label.text += "\n\n(预计: 资金 " + str(event_data["money_change"]) + ")"
	
	panel_root.visible = true
	get_tree().paused = true

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
