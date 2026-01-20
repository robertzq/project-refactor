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
			
func _on_session_started(seat_data, event_data):
	# 1. 存入 Buff
	Global.current_study_buff = seat_data
	
	# 2. 如果有随机事件的直接效果 (比如 stress +10)，立即执行
	if event_data.has("effect"):
		var eff = event_data.effect
		if eff.has("stress"):
			Global.apply_stress(eff.stress, "ENV") # 环境压力
		if eff.has("pride"):
			Global.pride += eff.pride
	
	# 3. 开始执行工作 (这里会调用 Global.get_efficiency)
	_start_working_process()

func _start_working_process():
	# ... 你的工作循环 ...
	
	# 在循环中检查分心
	if Global.check_is_distracted():
		print("你看着窗外发呆了一会儿...")
		# 触发分心惩罚：比如扣除一点时间，或者当前进度不增加
		#create_popup("你看着窗外发呆了一会儿...")
	else:
		# 正常增加进度
		var eff = Global.get_efficiency().value
		Global.project_progress += 5.0 * eff
		
	# ... 循环结束 ...
	
	# 4. 离开时清理
	# Global.clear_study_buff()
