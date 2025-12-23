extends Node

# 这里不需要 event_db 了，因为数据在 EventManager 里
# 这里也不需要 CSV 加载器了

func _ready():
	print("GameManager initialized. Ready to Refactor!")
	
	# 1. 初始化角色
	# 这个现在可以工作了，因为 Global 里有 init_character 了
	Global.init_character("STRIVER")
	
	print("角色初始化完成。")
	print("当前资金: ", Global.money)
	print("当前焦虑: ", Global.current_anxiety)
	
	# 2. 如果你需要确认数据是否加载，可以问 EventManager
	if has_node("/root/EventManager"):
		print("事件系统就绪。")
	else:
		printerr("❌ 警告：EventManager 未运行！请检查 Autoload 设置。")

# (原本的 try_trigger_event 逻辑已经移交给了 玩家撞击建筑 -> Global -> EventManager -> UI 的链路)
# GameManager 这里暂时可以留空，等待后续做“回合结束”逻辑
