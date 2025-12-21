extends CanvasLayer

@onready var path_list = $Control/ScrollContainer/PathList # 路径要对
@onready var root_control = $Control

func _ready():
	# 默认隐藏
	visible = false
	root_control.visible = false

func _input(event):
	# 监听 TAB 键开关界面
	if event.is_action_pressed("ui_focus_next"): # TAB 键默认映射
		toggle_ui()

func toggle_ui():
	visible = !visible
	root_control.visible = visible
	
	if visible:
		refresh_tree()
		# 暂停游戏，给玩家思考时间
		get_tree().paused = true
	else:
		get_tree().paused = false

func refresh_tree():
	# 1. 清空旧按钮
	for child in path_list.get_children():
		child.queue_free()
	
	# 2. 遍历 Global 里的配置，生成按钮
	for id in Global.life_path_db:
		var config = Global.life_path_db[id]
		var visibility = Global.check_path_visibility(id)
		
		# === 核心：迷雾渲染逻辑 ===
		
		# 情况 A: 隐形 (Invisible) -> 根本不生成按钮
		# 比如穷人看不见“创业”
		if visibility == 0:
			continue 
			
		var btn = Button.new()
		# 稍微设置一下最小高度，防止字挤在一起
		btn.custom_minimum_size = Vector2(0, 60)
		
		# 情况 B: 模糊 (Blurred) -> 能看见，但不知道是啥
		# 比如知道有“出国”这回事，但条件不够
		if visibility == 1:
			btn.text = "??? (未知的道路)"
			btn.disabled = true
			# 给他一点提示（诛心时刻）
			btn.tooltip_text = "你的[认知]或[安全感]不足以看清这条路。\n去图书馆读书，或者多存点钱吧。"
			
			# 视觉上弄成灰色
			btn.modulate = Color(0.5, 0.5, 0.5, 0.8)
			
		# 情况 C: 清晰 (Clear) -> 可以点击规划
		elif visibility == 2:
			btn.text = config["name"] + "\n" + config["desc"]
			btn.disabled = false
			# 绑定点击事件 (以后做月度规划用)
			btn.pressed.connect(_on_path_selected.bind(id))
			
		path_list.add_child(btn)

func _on_path_selected(path_id):
	print("玩家选择了路径: ", path_id)
	# 这里以后接月度规划系统
