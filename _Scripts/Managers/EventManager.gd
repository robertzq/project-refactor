extends Node

var event_db = {} 

func _ready():
	load_events_from_csv("res://Data/events_chapter1.csv")

func load_events_from_csv(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("❌ 无法打开事件表: ", file_path)
		return
		
	print("📂 开始加载事件表 (智能模式)...")
	event_db.clear()
	
	# 1. 动态读取表头 (id, title, desc, type...)
	var headers = file.get_csv_line()
	
	# 2. 遍历每一行数据
	while not file.eof_reached():
		var line = file.get_csv_line()
		
		# 这是一个非常好的习惯：确保数据列数和表头列数一致
		if line.size() != headers.size():
			continue 
		
		# 3. 自动组装字典 (Key = 表头, Value = 数据)
		var evt_data = {}
		for i in range(headers.size()):
			var key = headers[i].strip_edges() # 去除表头可能存在的空格
			var val = line[i]
			evt_data[key] = val
		
		# 4. 存入数据库 (必须有 id 且 id 不为空)
		if evt_data.has("id") and evt_data["id"] != "":
			event_db[evt_data["id"]] = evt_data
			
	print("✅ 事件表加载完毕，共加载 ", event_db.size(), " 个事件")
	
	# --- 调试：看看是不是真的读到了 type ---
	if event_db.size() > 0:
		var first = event_db.values()[0]
		print("🔍 抽查第一条数据的 Type: ", first.get("type", "读取失败"))

# 检查是否有事件需要触发
func check_for_event(trigger_type: String):
	var candidates = []
	for id in event_db:
		var evt = event_db[id]
		
		# 🔴 原代码: if evt.get("type") == trigger_type: 
		# ✅ 修正为: 读取 CSV 里的 "trigger" 列
		if evt.get("trigger") == trigger_type:
			candidates.append(evt)
	
	if candidates.size() > 0:
		return candidates.pick_random()
	return null
