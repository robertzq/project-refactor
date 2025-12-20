extends CanvasLayer

@onready var content_label = $Control/Panel/Label
@onready var panel_root = $Control

func _ready():
	# 游戏开始时先隐藏界面
	panel_root.visible = false

# 这个函数给 Player 调用
# 修改 show_event_popup 函数，接收字典而不是字符串
func show_event_popup(event_data: Dictionary):
	content_label.text = event_data["description"]
	
	# 3. (进阶) 如果有选项，这里可以动态生成按钮...
	# 目前 MVP 先只显示文本
	panel_root.visible = true
	get_tree().paused = true # 暂停游戏，防止玩家乱跑

func _on_button_pressed():
	# 点击按钮关闭
	panel_root.visible = false
	get_tree().paused = false
