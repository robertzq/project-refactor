extends Node

# --- 核心数值 (从你的策划案直接搬运) ---
var stats = {
	"fin_security": 0,    # P_fin: 经济安全感 (0-10)
	"pride": 5,           # P_pride: 自尊 (0-10)
	"sensitivity": 1.0,   # P_sens: 敏感度
	"money": 2000,        # 现金
	"anxiety": 20.0,      # A_t: 当前焦虑
	"settlement": 0,      # S_total: 沉淀值
	"ap": 100             # AP: 行动力
}

# --- 事件数据库 ---
# 结构: { "事件ID": { name, type, desc... } }
var event_db = {}

# --- 初始化 ---
func _ready():
	load_events_from_csv()
	print("大脑已上线。当前加载事件数: ", event_db.size())

# --- CSV 解析器 (Godot 4.x版) ---
func load_events_from_csv():
	var file_path = "res://Data/events_chapter1.csv"
	
	if not FileAccess.file_exists(file_path):
		printerr("错误：找不到CSV文件！请检查路径: ", file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	
	# 跳过第一行 (标题行: ID,Name,Type...)
	var headers = file.get_csv_line()
	
	while not file.eof_reached():
		var line = file.get_csv_line()
		
		# 防止空行报错
		if line.size() < 2:
			continue
			
		# 解析每一列 (根据你的CSV结构: ID, Name, Type, BaseStress...)
		var id = line[0]
		var data = {
			"id": id,
			"name": line[1],
			"type": line[2],
			"base_stress": int(line[3]),
			"ap_cost": int(line[4]),
			"money_change": int(line[5]),
			"settlement_change": int(line[6]),
			"description": line[7] # 对应 Notes/Story
		}
		
		event_db[id] = data

# --- 功能函数：根据地点获取随机事件 ---
func get_random_event(building_id: String):
	# 暂时写个简单的：如果是 LIB 就返回机房通宵，否则返回默认
	# 后续我们会在这里写复杂的随机权重逻辑
	
	if building_id == "LIB":
		# 尝试返回 "机房通宵" 事件，如果CSV没读到，就返回一个假数据防止报错
		return event_db.get("EVT_108", _get_fallback_event())
	elif building_id == "DORM":
		return event_db.get("EVT_100", _get_fallback_event())
	else:
		return _get_fallback_event()

func _get_fallback_event():
	return {
		"name": "无事发生",
		"description": "这里空荡荡的，什么也没有。",
		"options": []
	}
	
