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
# 核心灵魂属性 (0-10)
var soul_stats = {
	"security": 3,  # 安全感: 决定抗压能力
	"entropy": 3,   # 信息熵: 决定视野广度
	"pride": 5,     # 自尊: 决定精神杠杆
	"focus": 5      # 执行力: 决定长线效率
}
# --- 迷雾树配置 (Life Path Tree) ---
# visibility_req: 解锁视野需要的属性阈值
#   - entropy: 信息熵 (见世面)
#   - security: 安全感 (兜底能力)
# cost: 执行需要的资源 (比如钱/沉淀值)

var life_path_db = {
	"part_time": {
		"name": "兼职打工",
		"desc": "出卖廉价劳动力换取金钱。",
		"type": "work",
		"req_entropy": 0,   # 谁都知道能打工
		"req_security": 0,
		"status": "unlocked" # 默认解锁
	},
	"postgrad": {
		"name": "国内考研",
		"desc": "千军万马过独木桥，延缓就业压力。",
		"type": "study",
		"req_entropy": 2,   # 稍微有点认知就知道考研
		"req_security": 3,  # 需要一点家里支持(不能马上工作)
		"status": "locked"
	},
	"study_abroad": {
		"name": "出国留学",
		"desc": "去看看外面的世界。需要极高的认知和家底。",
		"type": "study",
		"req_entropy": 8,   # 【高门槛】没见过世面的人根本想不到这条路
		"req_security": 6,  # 【高门槛】没钱不敢想
		"status": "locked"
	},
	"startup": {
		"name": "休学创业",
		"desc": "九死一生的赌博。要么财富自由，要么负债累累。",
		"type": "risk",
		"req_entropy": 5,
		"req_security": 9,  # 【极高门槛】只有输得起的人才敢看这条路
		"status": "locked"
	},
	"gap_year": {
		"name": "间隔年 (Gap Year)",
		"desc": "停下来，去流浪，去寻找自我。",
		"type": "special",
		"req_entropy": 9,   # 极高认知：意识到人生不是轨道而是旷野
		"req_security": 5,
		"status": "locked"
	}
}

# 辅助函数：计算节点的可见性
# 返回: 0=隐形(Invisible), 1=模糊(Blurred), 2=清晰(Clear)
func check_path_visibility(path_id: String) -> int:
	var node = life_path_db[path_id]
	var score = 0
	
	# 检查信息熵 (视野)
	if soul_stats["entropy"] >= node["req_entropy"]:
		score += 1
	# 检查安全感 (胆量)
	if soul_stats["security"] >= node["req_security"]:
		score += 1
		
	# 特殊逻辑：如果已经解锁了，就保持清晰
	if node["status"] == "unlocked":
		return 2
		
	return score
# 初始点数池
const MAX_SOUL_POINTS = 20

# 职业/出身预设 (Elden Ring 风格)
var origins = {
	"做题家": {"security": 2, "entropy": 1, "pride": 5, "focus": 10},
	"野蛮人": {"security": 8, "entropy": 3, "pride": 2, "focus": 5},
	"书香门第": {"security": 2, "entropy": 9, "pride": 8, "focus": 3},
	"无用之人": {"security": 5, "entropy": 5, "pride": 5, "focus": 5}
}

# 辅助：重置属性
func set_soul_stats(new_stats: Dictionary):
	soul_stats = new_stats.duplicate()
	
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
	
