extends Area3D

# 不需要 building_id 了，因为这个脚本专门给图书馆用
# 但为了保持统一，留着也可以

func _ready():
	add_to_group("Buildings")
	# 确保连接信号
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player" or body.is_in_group("Player"):
		print(">>> 玩家抵达图书馆入口")
		
		# 1. 找到 UI 层的 LibraryView 节点
		# 方法A: 既然大家都在 MainWorld 下，可以直接通过 Group 找，或者路径找
		var lib_ui = get_tree().current_scene.get_node_or_null("LibraryView")
		
		if lib_ui:
			# 2. 暂停游戏，显示界面
			get_tree().paused = true
			lib_ui.setup("LIB_MAIN") # 调用 LibraryView 的初始化函数
		else:
			print("❌ 错误：场景里找不到 'LibraryView' 节点！请检查场景树。")
