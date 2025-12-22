extends Node

# 存储解析后的事件字典
var event_db: Dictionary = {}
@export var ui_event: CanvasLayer
func _ready():
	print("GameManager initialized. Ready to Refactor!")
	
	# 1. 初始化角色 (目前是测试代码)
	Global.init_character("STRIVER")
	print("Current Efficiency: ", Global.get_efficiency())
	
	# 2. 加载 CSV 数据
	load_events_from_csv("res://Data/events_chapter1.csv")

# ========================================================
# CSV 加载器 (The Loader)
# ========================================================
func load_events_from_csv(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		printerr("Failed to open CSV: ", path)
		return
		
	# 跳过标题行
	var headers = file.get_csv_line()
	
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 5: continue # 空行保护
		
		# 解析每一列 (根据上面 CSV 的顺序)
		var event_id = line[0]
		var data = {
			"id": event_id,
			"title": line[1],
			"desc": line[2],
			"type": line[3],
			"base_stress": int(line[4]),
			"cond_type": line[5],
			"cond_val": int(line[6]),
			"raw_options": line[7] # 稍后在 UI 里解析选项
		}
		
		event_db[event_id] = data
		
	print("Event Database Loaded. Count: ", event_db.size())

# ========================================================
# 事件触发器 (The Trigger)
# ========================================================
func try_trigger_event():
	var keys = event_db.keys()
	if keys.is_empty(): return
	
	var random_key = keys[randi() % keys.size()]
	var evt = event_db[random_key]
	
	if check_condition(evt):
		print("Triggering Event: ", evt.title)
		
		# --- 新增：调用 UI 显示 ---
		if ui_event:
			ui_event.show_event(evt)
		else:
			printerr("UI_Event not found! Check node path in GameManager.")
	else:
		print("Condition not met: ", evt.title)

# 检查事件是否符合当前玩家属性
func check_condition(evt: Dictionary) -> bool:
	match evt.cond_type:
		"MAX_FIN": # 穷人限定
			return Global.fin_security <= evt.cond_val
		"MIN_ENTROPY": # 高认知限定
			return Global.entropy >= evt.cond_val
		"NONE":
			return true
	return true
	
func _input(event):
	if event.is_action_pressed("ui_accept"): # 按空格键
		try_trigger_event()
