extends Node

var G: Node # Global引用

var db: Dictionary = {}
var selected_paths: Array = []
var active_mutex_groups: Array = []
var active_project_id: String = ""
var project_progress: float = 0.0

enum PathStatus { HIDDEN, BLURRED, AVAILABLE, IN_PROGRESS, COMPLETED, LOCKED }

func setup(global_ref):
	G = global_ref
	_load_json("res://Data/life_paths.json")

func _load_json(path):
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			db = json.data
			print("✅ LifePathSystem: 加载了 %d 条路径" % db.size())

# 核心状态逻辑 (补全了 req_sed 和 req_pride 检查)
func get_path_status(id: String) -> int:
	if not db.has(id): return PathStatus.HIDDEN
	
	if id in selected_paths: return PathStatus.COMPLETED
	if id == active_project_id: return PathStatus.IN_PROGRESS
	
	var data = db[id]
	if data.has("mutex_group") and data["mutex_group"] in active_mutex_groups:
		return PathStatus.LOCKED
	
	# 1. 视野检查 (Entropy)
	if G.entropy < data.get("req_entropy", 0) - 2: return PathStatus.HIDDEN
	if G.entropy < data.get("req_entropy", 0): return PathStatus.BLURRED
	
	# 2. 父节点检查
	if data.has("parent") and data["parent"] not in selected_paths:
		return PathStatus.BLURRED
		
	# 3. 🔥 硬性能力门槛 (补漏)
	if G.sedimentation < data.get("req_sed", 0): return PathStatus.LOCKED
	if G.pride < data.get("req_pride", 0): return PathStatus.LOCKED
		
	return PathStatus.AVAILABLE

func start_project(id: String):
	active_project_id = id
	project_progress = 0.0
	return db[id]

func advance_progress(amount: float) -> bool:
	if active_project_id == "": return false
	project_progress += amount
	if project_progress >= 100.0:
		project_progress = 100.0
		return true
	return false

func complete_project():
	if active_project_id == "": return null
	var data = db[active_project_id]
	
	if active_project_id not in selected_paths:
		selected_paths.append(active_project_id)
	if data.has("mutex_group"):
		active_mutex_groups.append(data["mutex_group"])
		
	active_project_id = ""
	project_progress = 0.0
	return data
