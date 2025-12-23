extends CanvasLayer

@onready var path_list = $Control/ScrollContainer/PathList 
@onready var root_control = $Control

func _ready():
	visible = false
	root_control.visible = false
	
	# --- ✅ 关键修改：监听 Global 的眼界提升信号 ---
	# 这样当你在事件里获得了 sed -> 触发 entropy 提升 -> 这里的 UI 就会自动刷新
	Global.vision_improved.connect(_on_vision_improved)

func _input(event):
	if event.is_action_pressed("ui_focus_next"): # TAB
		toggle_ui()

func toggle_ui():
	visible = !visible
	root_control.visible = visible
	
	if visible:
		refresh_tree()
		get_tree().paused = true
	else:
		get_tree().paused = false

# 当眼界提升时，刷新列表并（可选）弹出提示
func _on_vision_improved(new_val, msg):
	# 如果 UI 正开着，就刷新一下
	if visible:
		refresh_tree()
	# 这里其实可以加一个 HUD 的 Toast 弹窗提示玩家“发现新路径”

func refresh_tree():
	# 1. 清空旧按钮
	for child in path_list.get_children():
		child.queue_free()
	
	# 2. 遍历 Global 的配置 (现在是从 JSON 加载的了)
	# 为了好看，我们可以按 req_entropy 排序 (JSON 是无序的)
	var keys = Global.life_path_db.keys()
	
	# 3. 生成按钮
	for id in keys:
		var config = Global.life_path_db[id]
		# 调用 Global 写好的迷雾检测逻辑
		var visibility = Global.check_path_visibility(id)
		
		# 情况 A: 隐形 (Invisible)
		if visibility == 0:
			continue 
			
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 80) # 高一点，因为有描述
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT # 左对齐比较好看
		
		# 情况 B: 模糊 (Blurred)
		if visibility == 1:
			btn.text = " [ 迷雾重重 ]\n (???) "
			btn.disabled = true
			btn.tooltip_text = "你的[眼界(Entropy)]不足。\n多去经历一些[深度沉淀]的事件吧。"
			btn.modulate = Color(0.4, 0.4, 0.4, 0.5) # 灰色半透明
			
		# 情况 C: 清晰 (Clear)
		elif visibility == 2:
			btn.text = " 【" + config["name"] + "】\n  " + config["desc"]
			btn.disabled = false
			btn.modulate = Color(1, 1, 1, 1)
			btn.pressed.connect(_on_path_selected.bind(id))
			
		path_list.add_child(btn)

func _on_path_selected(path_id):
	print("玩家选择了路径: ", path_id)
	# MVP 阶段：这里可以仅仅打印
	# 后续：弹出确认框 "确定要致力于这条道路吗？"
