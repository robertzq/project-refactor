extends CanvasLayer

@onready var root_control = $Control
@onready var tree_container = $Control/ScrollContainer/TreeContainer # 确保路径对

func _ready():
	visible = false
	root_control.visible = false
	Global.vision_improved.connect(_on_vision_improved)

func _input(event):
	if event.is_action_pressed("ui_focus_next"): # TAB
		toggle_ui()

func toggle_ui():
	visible = !visible
	root_control.visible = visible
	
	if visible:
		refresh_forest() # 每次打开都重画，确保状态最新
		get_tree().paused = true
	else:
		get_tree().paused = false

func _on_vision_improved(new_val, msg):
	if visible: refresh_forest()

# === 核心：森林渲染逻辑 ===
func refresh_forest():
	# 1. 清空现有树
	for child in tree_container.get_children():
		child.queue_free()
	
	# 2. 将路径按 Tier 分组
	# 结构: { 0: [data1, data2], 1: [data3] ... }
	var tiers_data = {}
	var max_tier = 0
	
	for id in Global.life_path_db:
		var data = Global.life_path_db[id]
		data["id"] = id # 把ID塞进去方便读取
		var t = int(data.get("tier", 0))
		
		if not tiers_data.has(t): tiers_data[t] = []
		tiers_data[t].append(data)
		
		if t > max_tier: max_tier = t
	
	# 3. 从上往下 (Tier Max -> Tier 0) 生成 UI 行
	# 这样在 VBox 里，Tier Max 在上面，Tier 0 在下面，符合“树往上长”的视觉
	for t in range(max_tier, -1, -1):
		if not tiers_data.has(t): continue
		
		create_tier_row(t, tiers_data[t])

# 创建每一层的行 (HBox)
func create_tier_row(tier_idx: int, nodes: Array):
	# A. 创建行容器
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER # 居中对齐
	row.add_theme_constant_override("separation", 20) # 节点间距
	tree_container.add_child(row)
	
	# (可选) 加个层级标签
	# var label = Label.new()
	# label.text = "Tier %d" % tier_idx
	# tree_container.add_child(label) 
	
	# B. 在行里添加节点按钮
	for node_data in nodes:
		var btn = create_node_button(node_data)
		if btn: row.add_child(btn)

# 创建单个节点按钮
func create_node_button(data: Dictionary) -> Button:
	var id = data["id"]
	var status = Global.get_path_status(id)
	
	# 如果是完全隐藏，就不生成 (或者生成一个空的占位符保持排版?)
	# 这里选择直接不生成
	if status == Global.PathStatus.HIDDEN:
		return null
		
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(160, 100) # 调大一点，像个卡片
	btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	btn.clip_text = true
	
	# --- 样式逻辑 ---
	match status:
		Global.PathStatus.BLURRED:
			btn.text = "???\n(眼界不足)"
			btn.disabled = true
			btn.modulate = Color(0.3, 0.3, 0.3, 0.8) # 深灰色
			
		Global.PathStatus.LOCKED:
			btn.text = data["name"] + "\n[已锁死]"
			btn.disabled = true
			btn.modulate = Color(0.8, 0.2, 0.2, 0.5) # 红色半透明
			
		Global.PathStatus.AVAILABLE:
			btn.text = "【" + data["name"] + "】\n" + data.get("desc", "")
			btn.disabled = false
			btn.modulate = Color(1, 1, 1, 1) # 正常亮
			# 绑定点击
			btn.pressed.connect(_on_node_clicked.bind(id))
			
		Global.PathStatus.SELECTED:
			btn.text = "★ " + data["name"] + " ★\n(已点亮)"
			btn.disabled = true # 选过了就不能再点
			btn.modulate = Color(1, 0.8, 0.2, 1) # 金色
			
	return btn

func _on_node_clicked(id):
	Global.select_path(id)
	refresh_forest() # 选完立刻刷新，为了让互斥锁立刻生效
