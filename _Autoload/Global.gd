extends Node

# 引用子系统 (确保路径正确)
const TimeSys = preload("res://_Scripts/Systems/TimeSystem.gd")
const PathSys = preload("res://_Scripts/Systems/LifePathSystem.gd")
const JournalSys = preload("res://_Scripts/Systems/JournalSystem.gd")

var time_sys: Node
var path_sys: Node
var journal_sys: Node

# ==============================================================================
# 1. 核心属性库 (Stats Core)
# ==============================================================================
var money: int = 0
var fin_security: int = 5
var pride: int = 5
var entropy: int = 5
var sedimentation: int = 0
var sensitivity: float = 1.0
var base_exec: float = 1.0

var current_anxiety: float = 0.0
var is_in_breakdown: bool = false
var traits: Array = []
var recovery_strategy: String = "Explorer"
var current_study_buff: Dictionary = {}
var relations: Dictionary = {}

# --- 代理属性 (兼容旧代码调用) ---
var current_week: int:
	get: return time_sys.current_week
var time_slots: int:
	get: return time_sys.time_slots
var current_active_project_id: String:
	get: return path_sys.active_project_id
var project_progress: float:
	get: return path_sys.project_progress
	set(val): path_sys.project_progress = val
var life_path_db: Dictionary:
	get: return path_sys.db
var journal_logs: Array:
	get: return journal_sys.logs
var active_mutex_groups: Array:
	get: return path_sys.active_mutex_groups

# --- 信号 ---
signal vision_improved(new_entropy, message)
signal time_advanced(week) # 桥接信号

# ==============================================================================
# 2. 初始化
# ==============================================================================
func _ready():
	time_sys = TimeSys.new()
	path_sys = PathSys.new()
	journal_sys = JournalSys.new()
	
	add_child(time_sys)
	add_child(path_sys)
	add_child(journal_sys)
	
	path_sys.setup(self)
	
	# 连接子系统信号
	time_sys.period_ended.connect(_on_biweekly_settlement)

	time_sys.initialize()

	time_sys.time_updated.connect(func(w, _d, _s): emit_signal("time_advanced", w))
	
	print("✅ Global Refactored.")

func init_character(archetype: String):
	print(">>> 初始化角色: ", archetype)
	current_anxiety = 0
	project_progress = 0
	traits = []
	recovery_strategy = "Explorer"
	is_in_breakdown = false
	current_study_buff = {}
	journal_sys.clear()

	# 数值设定 (完全保留原逻辑)
	match archetype:
		"ARCH_ELITE":
			money = 5000; fin_security = 8; pride = 6; entropy = 5
			add_trait("多才多艺"); add_trait("原生家庭")
		"ARCH_LOCAL":
			money = 2000; fin_security = 5; pride = 4; entropy = 4
			add_trait("本地人")
		"ARCH_SURVIVOR":
			money = 500; fin_security = 1; pride = 8; sensitivity = 1.5; entropy = 3
			add_trait("早熟")
		"ARCH_COUNTY_STAR":
			money = 4000; fin_security = 7; pride = 9; entropy = 2
			add_trait("宁做鸡头")
		"ARCH_STRIVER":
			money = 800; fin_security = 3; base_exec = 1.3; pride = 7; entropy = 1
			add_trait("意难平")
		_:
			fin_security = 5; pride = 5; base_exec = 1.0; sensitivity = 1.0; money = 2000

# ==============================================================================
# 3. 核心公式 (Logic Core) - 完全保留
# ==============================================================================
func get_boldness() -> float:
	return (fin_security * 0.4) + (pride * 0.6)

func get_max_anxiety_limit() -> float:
	return 80.0 * base_exec

func get_efficiency() -> Dictionary:
	var final_eff = base_exec
	var active_factors = []
	
	if not current_study_buff.is_empty() and current_study_buff.has("eff_mod"):
		var seat_mod = current_study_buff["eff_mod"]
		final_eff *= seat_mod
		if seat_mod != 1.0: active_factors.append("座位(x%.2f)" % seat_mod)

	var boldness = get_boldness()
	if fin_security > 7 and current_anxiety < 30:
		final_eff *= 0.7
		active_factors.append("安逸诅咒")
	elif boldness < 4.0:
		final_eff *= 0.8
		active_factors.append("胆怯诅咒")
	
	if current_anxiety > 80 and "背水一战" in traits:
		final_eff *= 1.2
		active_factors.append("背水一战")

	return {"value": final_eff, "desc": ", ".join(active_factors) if active_factors.size() > 0 else "正常"}

func apply_stress(base_val: float, type: String, is_working: bool = false) -> Dictionary:
	# 回血逻辑
	if base_val < 0:
		var heal_amount = base_val * sensitivity
		current_anxiety += heal_amount
		if current_anxiety < 0: current_anxiety = 0
		print(">> [Global] 治愈: %.1f" % heal_amount)
		return {"damage": heal_amount, "current_anxiety": current_anxiety}

	# 扣血逻辑
	var modified_base = base_val
	if not current_study_buff.is_empty() and current_study_buff.has("stress_fix"):
		modified_base += current_study_buff["stress_fix"]
			
	var omega = 0.0
	match type:
		"MONEY": omega = modified_base - (fin_security * 2.0)
		"EGO":   omega = modified_base + (pride * 0.5)
		"WORK", "STUDY":
			var entropy_mult = 0.8 + (entropy * 0.05)
			omega = modified_base * entropy_mult
		_: omega = modified_base

	if is_working and fin_security < 3:
		omega -= 8.0 
	
	if omega < 0: omega = 0
	var final_damage = omega * sensitivity
	current_anxiety += final_damage
	
	var is_broken = current_anxiety >= get_max_anxiety_limit()
	if is_broken: trigger_breakdown()

	return {"damage": final_damage, "current_anxiety": current_anxiety, "is_breakdown": is_broken}

func check_is_distracted() -> bool:
	var final_chance = 0.05
	if not current_study_buff.is_empty():
		final_chance += current_study_buff.get("distraction_chance", 0.0)
	return randf() < final_chance

func trigger_breakdown():
	if is_in_breakdown: return
	is_in_breakdown = true
	journal_sys.record("BREAKDOWN", 0, "精神崩溃")
	log_story("【崩溃】那根紧绷的弦终于断了... 你在医院昏睡了三天。")
	
	current_anxiety = get_max_anxiety_limit() * 0.5
	project_progress = max(0.0, project_progress - 10.0)
	
	call_deferred("_switch_to_breakdown_scene")

func _switch_to_breakdown_scene():
	var path = "res://_Scenes/bkend.tscn"
	if ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)
	else:
		printerr("❌ 找不到崩溃场景")

# ==============================================================================
# 4. 桥接与交互 (Bridge Methods)
# ==============================================================================

# --- 时间 ---
func advance_time(days: int = 1):
	# 旧代码只有days参数，默认视为睡觉过一天
	time_sys.sleep_and_advance()
	return false # 返回false兼容旧代码

func consume_time_slot(amount: int = 1) -> bool:
	return time_sys.consume_slot(amount)

# --- 路径与项目 ---
func get_path_status(id: String) -> int:
	return path_sys.get_path_status(id)

func start_project(id: String):
	var data = path_sys.start_project(id)
	var loc = data.get("location_bind", "LIB")
	print(">>> 立项: %s (需前往: %s)" % [data["name"], loc])

func advance_project_progress(val: float):
	var is_done = path_sys.advance_progress(val)
	if is_done: check_project_completion()

func check_project_completion() -> bool:
	if project_progress >= 100.0:
		var data = path_sys.complete_project()
		if data:
			_apply_all_rewards(data) # 🔥 补全了奖励结算
			emit_signal("vision_improved", entropy, "项目【%s】已完成！" % data["name"])
			return true
	return false

# 🔥 通用奖励结算 (补漏)
func _apply_all_rewards(data: Dictionary):
	if data.has("gain_entropy"): entropy += data["gain_entropy"]
	if data.has("gain_sed"): add_sedimentation(data["gain_sed"])
	if data.has("gain_money"): money += data["gain_money"]
	if data.has("gain_security"): fin_security += data["gain_security"]
	if data.has("gain_pride"): pride += data["gain_pride"]
	
	if data.get("tier", 0) >= 6:
		_on_biweekly_settlement() # 结局检查

# --- 日记 ---
func record_journal(type, val, desc):
	journal_sys.record(type, val, desc)

func log_story(text):
	journal_sys.log_story(text)

func clear_journal():
	journal_sys.clear()

# ==============================================================================
# 5. 辅助功能
# ==============================================================================
func add_trait(t_name):
	if t_name not in traits:
		traits.append(t_name)
		print(">> [Global] 获得特质: ", t_name)

func has_trait(t_name) -> bool: return t_name in traits

func update_relation(npc_id: String, val: int):
	if not relations.has(npc_id): relations[npc_id] = 0
	relations[npc_id] += val

func unlock_hidden_path(branch_id: String):
	log_story("命运的分歧点：你解锁了 [%s]" % branch_id)

func clear_study_buff():
	if not current_study_buff.is_empty():
		current_study_buff.clear()

func add_sedimentation(amount: int):
	# 简单的累加，阈值判断在 UI_LifePathSystem 里做了，这里主要负责加数值和眼界
	var old_level = int(sedimentation / 5)
	sedimentation += amount
	var new_level = int(sedimentation / 5)
	if new_level > old_level:
		var gain = new_level - old_level
		entropy += gain
		emit_signal("vision_improved", entropy, "眼界提升 +%d" % gain)

# 建筑事件查找
func get_random_event(building_id: String) -> Dictionary:
	var trigger_type = "GEN"
	match building_id:
		"DORM": trigger_type = "dorm_enter"
		"LIB":  trigger_type = "lib_enter"
		"CAFE": trigger_type = "cafe_enter"
		"LAB":  trigger_type = "lab_enter"
	
	if has_node("/root/EventManager"):
		var evt = get_node("/root/EventManager").check_for_event(trigger_type)
		if evt != null: return evt

	return {"id": "none", "title": "无事发生", "desc": "周围很安静。", "options": "离开", "effect_a": ""}

func _on_biweekly_settlement():
	await get_tree().process_frame
	show_settlement()

func show_settlement():
	var ui = load("res://_Scenes/UI_Settlement.tscn").instantiate()
	get_tree().root.add_child(ui)

# ==============================================================================
# 6. 存档与读档系统 (Save & Load System)
# ==============================================================================
const SAVE_PATH = "user://savegame.json" # Godot 的用户数据目录，跨平台安全
var current_archetype_key
var completed_events

func save_game():
	# 1. 打包数据 (把所有需要持久化的变量都放进去)
	var save_data = {
		# --- 基础属性 ---
		"money": money,
		"fin_security": fin_security,
		"pride": pride,
		"entropy": entropy,
		"sedimentation": sedimentation,
		"sensitivity": sensitivity,
		"base_exec": base_exec,
		"current_anxiety": current_anxiety,
		
		# --- 角色构建 ---
		"archetype": current_archetype_key, # 记得之前让你加的这个变量
		"traits": traits,
		"relations": relations,
		"recovery_strategy": recovery_strategy,
		
		# --- 时间系统 (从 TimeSys 获取) ---
		"current_week": time_sys.current_week,
		"current_day": time_sys.current_day,
		"time_slots": time_sys.time_slots,
		
		# --- 进度与剧情 (最重要！) ---
		"completed_events": completed_events, # 记录哪些事件发生过
		"project_progress": project_progress,
		"active_project_id": path_sys.active_project_id
	}

	# 2. 写入文件
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_str = JSON.stringify(save_data)
		file.store_string(json_str)
		file.close()
		print("💾 [System] 游戏已保存至: ", SAVE_PATH)
		emit_signal("vision_improved", entropy, "游戏进度已保存") # 借用这个信号弹个窗提示
	else:
		printerr("❌ 保存失败！")

func load_game() -> bool:
	# 1. 检查文件是否存在
	if not FileAccess.file_exists(SAVE_PATH):
		print("⚠️ 没有找到存档文件")
		return false
		
	# 2. 读取文件
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_str = file.get_as_text()
	file.close()

	# 3. 解析 JSON
	var json = JSON.new()
	var error = json.parse(json_str)
	if error != OK:
		printerr("❌ 存档损坏！")
		return false
		
	var data = json.data

	# 4. 恢复数据 (把字典里的值填回去)
	# --- 基础属性 ---
	money = data.get("money", 0)
	fin_security = data.get("fin_security", 5)
	pride = data.get("pride", 5)
	entropy = data.get("entropy", 0)
	sedimentation = data.get("sedimentation", 0)
	sensitivity = data.get("sensitivity", 1.0)
	base_exec = data.get("base_exec", 1.0)
	current_anxiety = data.get("current_anxiety", 0.0)

	# --- 角色构建 ---
	current_archetype_key = data.get("archetype", "ARCH_STRIVER")
	traits = data.get("traits", [])
	relations = data.get("relations", {})
	recovery_strategy = data.get("recovery_strategy", "Explorer")

	# --- 进度 ---
	completed_events = data.get("completed_events", [])
	project_progress = data.get("project_progress", 0.0)

	# --- 恢复时间 (需要手动设置 TimeSys) ---
	time_sys.current_week = data.get("current_week", 1)
	time_sys.current_day = data.get("current_day", 1)
	time_sys.time_slots = data.get("time_slots", 3)

	# --- 恢复项目 ---
	var proj_id = data.get("active_project_id", "")
	if proj_id != "":
		path_sys.start_project(proj_id) # 重新激活项目逻辑
		path_sys.project_progress = project_progress # 覆盖进度

	print("📂 [System] 读档成功！")

	# 5. 🔥 关键：读档后刷新当前场景
	# 建议重新加载一次主场景，确保 UI 和画面跟数值同步
	get_tree().reload_current_scene()

	return true

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)