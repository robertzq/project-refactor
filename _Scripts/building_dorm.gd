# 修改后：extends Area3D 而不是 StaticBody3D
extends Area3D

@export var building_id: String = "DORM" # 在编辑器里可以改为 LIB

func _ready():
	add_to_group("Buildings")
	# 关键步骤：代码连接信号 (防止你忘记在编辑器里连)
	# 只有 Area3D 才有这个信号
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# 这里的 "Player" 取决于你主角根节点的 Name，或者你可以判断 body.is_in_group("Player")
	if body.name == "Player" or body.is_in_group("Player"): 
		print(">>> 进入建筑区域: ", building_id)
		
		# 1. 尝试触发事件
		# 映射一下：如果是 DORM 就找 dorm_enter，如果是 LIB 就找 lib_enter
		var trigger_type = ""
		match building_id:
			"DORM": trigger_type = "dorm_enter"
			"LIB":  trigger_type = "lib_enter"
		
		# 调用之前的 EventManager (它负责查 CSV)
		var evt = EventManager.check_for_event(trigger_type)
		
		if evt:
			print("触发事件: ", evt["title"])
			# 2. 呼出 UI
			# 这种查找方式虽然暴力，但在 MVP 阶段完全可行
			var ui_node = get_tree().current_scene.find_child("UI_Event", true, false)
			if ui_node:
				ui_node.show_event(evt)
			else:
				print("❌ 错误：场景里找不到名字叫 'UI_Event' 的节点！")
		else:
			print("平安无事，这里只是个冰冷的建筑。")
