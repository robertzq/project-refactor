extends Node

# ==============================================================================
# 1. 核心属性库 (The Internal Engine)
# ==============================================================================

# [基础资源]
var money: int = 0          # 资金 (影响生存)
var project_progress: float = 0.0 # 项目进度 (影响通关)

# [时间系统]
var current_week: int = 1   # 当前周数 (1-2周为上半月，3-4周为下半月)
const WEEKS_PER_SETTLEMENT = 2  # 每 2 周结算一次
signal time_advanced(week)      # 时间推进信号
var current_cycle_log: Array = [] # 存储这半个月发生的所有事情（用于写周报）

# [项目系统]
const PROGRESS_GOAL = 100.0 # 目标
var current_active_project_id: String = "" # 当前正在攻克的节点ID

# [四大维度的核心参数]
var fin_security: int = 5   # 家境 (P_fin): 提供金钱抗性
var pride: int = 5          # 自尊 (P_pride): 增加 EGO 伤害
var entropy: int = 5        # 熵/视野: 影响工作难度
var sensitivity: float = 1.0 # 敏感度 (P_sens): 全局伤害乘区
var base_exec: float = 1.0  # 执行力基数 (E_base): 影响工作效率

# [状态记录]
var current_anxiety: float = 0.0 # 当前焦虑值
var traits: Array = []           # 特质列表 (如 "背水一战", "卷王")
var recovery_strategy: String = "Explorer" # <--- 【已补回】回血策略 (Extrovert/Introvert/Explorer)
var is_employed: bool = false
var current_study_buff: Dictionary = {}  # <--- 新增这一行
var sedimentation: int = 0   # 沉淀值
# 1. 定义信号 (通知 UI 刷新)
signal vision_improved(new_entropy, message) # 当眼界提升时发出信号

# 2. 定义阈值
const SEDIMENTATION_THRESHOLD = 5 # 每积攒 5 点沉淀，提升 1 点眼界

# --- 新增：人生路径数据库 (从 JSON 加载) ---
var life_path_db: Dictionary = {}
var selected_paths: Array = []        # 已选择的路径 ID
var active_mutex_groups: Array = []   # 已激活的互斥组 (如 "junior_choice")
var current_archetype_code = ""
# === 状态枚举 ===
enum PathStatus {
	HIDDEN = 0,      # 眼界不够，完全不可见
	BLURRED = 1,     # 眼界快到了，或者是可见但条件不满足（迷雾）
	AVAILABLE = 2,   # 条件满足，可选
	IN_PROGRESS = 3, # 🔥 新增：正在攻克中
	COMPLETED = 4,   # ✅ 改名：已彻底完成 (原 SELECTED)
	LOCKED = 5       # 互斥锁死
}
# [日记系统]
# 存储结构: [{ "type": "WORK", "val": 25, "desc": "死磕二叉树" }, ...]
var journal_logs: Array = []
# ==============================================================================
# 2. 游戏初始化 (Game Flow)
# ==============================================================================
func _ready():
	# 游戏启动时，加载 JSON 数据
	load_life_paths_from_json("res://Data/life_paths.json")
	
# 初始化角色模板 (在游戏开始或重开时调用)
func init_character(archetype: String):
	print(">>> 正在初始化角色模板: ", archetype)
	
	# 1. 重置所有动态状态
	current_anxiety = 0
	project_progress = 0
	traits = []
	recovery_strategy = "Explorer" # 默认值，会在火车问卷中被修改
	current_archetype_code  = archetype
	# 2. 根据出身设定初始数值
	match archetype:
		# 1. 都会精英 (The Golden Child)
		"ARCH_ELITE":
			money = 5000
			fin_security = 8
			pride = 6
			entropy = 5 # 视野开阔，不需要太努力也能看到好路
			add_trait("多才多艺") # 社交回血
			add_trait("原生家庭") # 每月生活费+

		# 2. 城市土著 (The Local Normie)
		"ARCH_LOCAL":
			money = 2000
			fin_security = 5
			pride = 4
			entropy = 4 # 中规中矩
			add_trait("本地人") # 周末回家回血

		# 3. 霓虹暗面 (The Concrete Weed)
		"ARCH_SURVIVOR":
			money = 500
			fin_security = 1
			pride = 8
			sensitivity = 1.5 # 高敏
			entropy = 3 # 虽穷，但见识过社会残酷，比做题家稍微懂点
			add_trait("早熟") # 打工减焦虑

		# 4. 县城显贵 (The County Star)
		"ARCH_COUNTY_STAR":
			money = 4000
			fin_security = 7
			pride = 9 # 极高自尊
			entropy = 2 # 信息闭塞，容易盲目自信
			add_trait("宁做鸡头")

		# 5. 错位过客 (The Disillusioned Striver) - 主角模板
		"ARCH_STRIVER":
			money = 800
			fin_security = 3
			base_exec = 1.3 # 执行力极强
			pride = 7
			entropy = 1 # 开局眼界极低！只知道死读书！
			add_trait("意难平") # 没拿第一就焦虑
			
		_: # 默认 (Default)
			fin_security = 5
			pride = 5
			base_exec = 1.0
			sensitivity = 1.0
			money = 2000
	
	print("初始眼界: ", entropy, " | 初始家境: ", fin_security)

# ==============================================================================
# 3. 核心数学公式 (The Soul Algorithm v3.2)
# ==============================================================================

# [3.1] 获取胆量 (Boldness)
func get_boldness() -> float:
	return (fin_security * 0.4) + (pride * 0.6)

# [3.2] 获取焦虑上限 (Breakdown Limit)
func get_max_anxiety_limit() -> float:
	return 80.0 * base_exec

# [3.3] 获取当前工作效率 (Efficiency)
func get_efficiency() -> Dictionary:
	var final_eff = base_exec
	var curse = "无"
	
	# --- 新增：应用图书馆座位 Buff ---
	if not current_study_buff.is_empty() and current_study_buff.has("eff_mod"):
		var seat_mod = current_study_buff["eff_mod"]
		final_eff *= seat_mod
		# 只有当加成显著时才记录，避免日志太乱
		if seat_mod != 1.0:
			print("   >> [Buff] 座位加成: x%.2f" % seat_mod)
	# -------------------------------
	# 简单的诅咒判定示例
	if fin_security > 7 and current_anxiety < 30:
		final_eff *= 0.7
		curse = "安逸诅咒"
	elif get_boldness() < 4.0:
		final_eff *= 0.8
		curse = "胆怯诅咒"
		
	return {"value": final_eff, "curse": curse}

# [3.4] 压力结算核心公式
# base_val: 基础数值
# type: 类型 (MONEY, EGO, GEN, STUDY, WORK)
# is_working: 是否处于兼职/工作状态 (影响避难所判定)
func apply_stress(base_val: float, type: String, is_working: bool = false) -> Dictionary:
	
	# --- A. 回血逻辑 (负数) ---
	if base_val < 0:
		# 可以在这里加入 recovery_strategy 的判断逻辑
		# 比如: 如果是 Extrovert 且 type=="SOCIAL"，回血加倍
		var heal_amount = base_val
		
		# 简单示例: 高敏感的人回血也快
		heal_amount *= sensitivity
		
		current_anxiety += heal_amount
		if current_anxiety < 0:
			current_anxiety = 0
			
		print(">> [Global] 治愈: %.1f | 当前焦虑: %.1f" % [heal_amount, current_anxiety])
		return {"damage": heal_amount, "current_anxiety": current_anxiety}

	# --- B. 扣血逻辑 (正数) ---
	
	# Step 1: 计算原始压力 (Omega)
	var omega = base_val
	var log_reason = ""
	
	# --- 新增：应用座位带来的额外压力 (固定值) ---
	if not current_study_buff.is_empty() and current_study_buff.has("stress_fix"):
		var fix_val = current_study_buff["stress_fix"]
		if fix_val != 0:
			omega += fix_val
			log_reason += "[座位%+d]" % fix_val
	# ----------------------------------------
	
	match type:
		"MONEY":
			# 没钱时伤害巨高：基础值 - (家境 * 2.0)
			# 例如：家境2，减免4；家境8，减免16
			omega = base_val - (fin_security * 2.0)
			log_reason = "家境修正"
			
		"EGO":
			# 自尊越高伤害越高：基础值 + (自尊 * 0.5)
			omega = base_val + (pride * 0.5)
			log_reason = "自尊修正"
		
		"WORK", "STUDY":
			# 熵越高(迷茫)，做同样的事越累
			# 公式: 基础值 * (0.8 + 熵 * 0.05)
			# 例: 熵5 -> 1.05倍; 熵10 -> 1.3倍; 熵0 -> 0.8倍
			var entropy_mult = 0.8 + (entropy * 0.05)
			omega = base_val * entropy_mult
			log_reason = "认知修正(熵%d)" % entropy
				
		_:
			omega = base_val
			log_reason = "通用"

	# Step 2: 避难所修正 (穷人打工保护机制)
	if is_employed and fin_security < 3:
		omega -= 8.0
		log_reason += "+避难所"
	
	if omega < 0: omega = 0 # 伤害不能为负

	# Step 3: 全局敏感度放大
	var final_damage = omega * sensitivity
	
	# 应用结果
	current_anxiety += final_damage
	if current_anxiety >= get_max_anxiety_limit():
		trigger_breakdown()
	# 打印战斗日志
	print("---------------------------------------")
	print("   [Global] 压力结算 (%s)" % type)
	print("   公式: (基础%.0f -> 修正%.1f [%s]) x 敏感%.1f = 最终%.1f" % [base_val, omega, log_reason, sensitivity, final_damage])
	print("   当前焦虑: %.1f / %.1f" % [current_anxiety, get_max_anxiety_limit()])
	print("---------------------------------------")

	return {
		"damage": final_damage,
		"current_anxiety": current_anxiety,
		"is_breakdown": current_anxiety >= get_max_anxiety_limit()
	}

func trigger_breakdown():
	print(">>> ⚠️ 玩家崩溃！ <<<")
	# 1. 强制清空当前项目进度 (作为惩罚)
	# project_progress *= 0.5 
	
	# 2. 强制休息几天 (这需要你在 MainWorld 处理信号)
	# emit_signal("player_breakdown")
	
	# 3. 记录惨痛日记
	record_journal("BREAKDOWN", 0, "精神崩溃")
	log_story("【崩溃】那根紧绷的弦终于断了。你在医院躺了三天，错过了很多截止日期。")
	
	# 4. 恢复部分焦虑 (因为休息了)
	current_anxiety = get_max_anxiety_limit() * 0.5
# ==============================================================================
# 4. 辅助工具
# ==============================================================================

func add_trait(t_name):
	if t_name not in traits:
		traits.append(t_name)
		print(">> [Global] 获得特质: ", t_name)

# 建筑交互 -> 事件查找器桥梁
func get_random_event(building_id: String) -> Dictionary:
	var trigger_type = "GEN"
	match building_id:
		"DORM": trigger_type = "dorm_enter"
		"LIB":  trigger_type = "lib_enter"
		"CAFE": trigger_type = "cafe_enter"
	
	if has_node("/root/EventManager"):
		var evt = get_node("/root/EventManager").check_for_event(trigger_type)
		if evt != null: return evt

	# 兜底空事件
	return {"id": "none", "title": "无事发生", "desc": "周围很安静。", "options": "离开", "effect_a": ""}

# --- 核心：增加沉淀并检查顿悟 ---
# --- 1. 沉淀值逻辑 ---
func add_sedimentation(amount: int):
	var old_level = int(sedimentation / SEDIMENTATION_THRESHOLD)
	
	sedimentation += amount
	print(">> [Global] 沉淀增加: %d (当前: %d)" % [amount, sedimentation])
	
	var new_level = int(sedimentation / SEDIMENTATION_THRESHOLD)
	if new_level > old_level:
		var gain = new_level - old_level
		entropy += gain # 提升眼界
		var msg = "灵光一闪！眼界提升了 +%d" % gain
		print("✨ " + msg)
		emit_signal("vision_improved", entropy, msg)

# --- 2. JSON 数据加载逻辑 ---
func load_life_paths_from_json(path: String):
	if not FileAccess.file_exists(path):
		printerr("❌ 找不到人生路径配置文件: ", path)
		return
		
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(content)
	
	if error == OK:
		life_path_db = json.data
		print("✅ 人生路径树加载完成，共 ", life_path_db.size(), " 条路径。")
	else:
		printerr("❌ JSON 解析失败: ", json.get_error_message())
		
# --- 顿悟逻辑 (Epiphany) ---
func trigger_epiphany(level_gain: int):
	# 提升眼界 (Entropy)
	# 设定里: Entropy 代表"视野半径"。数值越大，能看到的节点越远。
	entropy += level_gain
	
	var msg = "灵光一闪！经过长时间的沉淀，你的眼界提升了！(视野 +%d)" % level_gain
	print("✨✨✨ " + msg + " ✨✨✨")
	
	# 发出信号，让 UI_LifePath (迷雾树) 知道该解锁新层级了
	emit_signal("vision_improved", entropy, msg)
	
	# 播放一个全局提示音效 (可选)
	# if has_node("/root/MainWorld/SFX_LevelUp"): ...
# --- 3. 核心：迷雾检测逻辑 (0:不可见, 1:模糊, 2:清晰) ---
func check_path_visibility(path_id: String) -> int:
	if not life_path_db.has(path_id): return 0
	
	var path_data = life_path_db[path_id]
	var req_entropy = path_data.get("req_entropy", 0) # 需求眼界
	
	# 逻辑设定：
	# 1. 如果眼界 >= 需求 -> 清晰 (2)
	if entropy >= req_entropy:
		return 2
	# 2. 如果眼界只差一点点 (比如差2点以内) -> 模糊 (1)
	elif entropy >= req_entropy - 2:
		return 1
	# 3. 差距太大 -> 隐形 (0)
	else:
		return 0
		
# Global.gd



# --- 新增：记录故事的函数 ---
func log_story(text: String):
	current_cycle_log.append(text)
	print(">> [Story] 记录: ", text)

	
# --- 记录日记的接口 ---
func record_journal(type: String, val: float, desc: String):
	journal_logs.append({
		"type": type,
		"val": val,
		"desc": desc
	})
	print(">> [Journal] 已记录: [%s] %s (%.1f)" % [type, desc, val])

# --- 清空日记 (每半月调用) ---
func clear_journal():
	journal_logs.clear()


# --- 3. 选择路径 ---
func select_path(path_id: String):
	if get_path_status(path_id) != PathStatus.AVAILABLE:
		return
		
	print(">>> 选择了人生路径: ", path_id)
	selected_paths.append(path_id)
	
	var data = life_path_db[path_id]
	
	# 激活互斥锁
	if data.has("mutex_group"):
		active_mutex_groups.append(data["mutex_group"])
		
	# 扣除代价 (示例)
	if data.has("cost_money"): money -= data["cost_money"]
	if data.has("cost_stress"): apply_stress(data["cost_stress"], "WORK")
	
	# 获得收益 (示例)
	if data.has("gain_sed"): add_sedimentation(data["gain_sed"])
	
# --- 时间推进逻辑 ---
func advance_time():
	current_week += 1
	print(">> [Time] 进入第 %d 周" % current_week)
	emit_signal("time_advanced", current_week)
	
	# 检查是否需要半月结算 (偶数周结束时触发)
	# 比如第2周结束进入第3周前，或者第2周刚过完
	# 这里逻辑是：当 current_week 变成 3, 5, 7 时，说明前两周过完了
	if (current_week - 1) % WEEKS_PER_SETTLEMENT == 0:
		return true # 需要结算
	return false

# --- 路径状态检查 (更新) ---
func get_path_status(path_id: String) -> int:
	if not life_path_db.has(path_id): return PathStatus.HIDDEN
	
	# 1. 已经彻底完成的
	if path_id in selected_paths:
		return PathStatus.COMPLETED
	
	# 2. 🔥 正在做的
	if path_id == current_active_project_id:
		return PathStatus.IN_PROGRESS
		
	var data = life_path_db[path_id]
	var req_entropy = data.get("req_entropy", 0)
	var mutex = data.get("mutex_group", "")
	
	# 3. 互斥锁死
	if mutex != "" and mutex in active_mutex_groups:
		return PathStatus.LOCKED
	
	# 4. 迷雾逻辑
	if entropy < req_entropy - 2: return PathStatus.HIDDEN
	if entropy < req_entropy: return PathStatus.BLURRED
	
	# 5. 父节点检查 (必须父节点COMPLETED才能选子节点)
	if data.has("parent"):
		if data["parent"] not in selected_paths:
			return PathStatus.BLURRED
			
	return PathStatus.AVAILABLE

# --- 开始一个项目 (立项) ---
func start_project(path_id: String):
	current_active_project_id = path_id
	project_progress = 0.0 # 进度归零，开始肝！
	print(">>> 立项成功: ", life_path_db[path_id]["name"])

# --- 检查项目是否完成 (每次加进度后调用) ---
func check_project_completion() -> bool:
	if current_active_project_id == "": return false
	
	if project_progress >= 100.0:
		project_progress = 100.0 # 锁死在 100%
		complete_active_project()
		return true
	return false

# --- 完成项目 (结算) ---
func complete_active_project():
	var id = current_active_project_id
	print(">>> 🎉 项目完成: ", id)
	
	# 1. 正式加入已完成列表
	selected_paths.append(id)
	
	# 2. 激活互斥锁
	var data = life_path_db[id]
	if data.has("mutex_group"):
		active_mutex_groups.append(data["mutex_group"])
	
	# 3. 获得一次性收益 (如眼界、沉淀)
	if data.has("gain_entropy"): entropy += data["gain_entropy"]
	if data.has("gain_sed"): add_sedimentation(data["gain_sed"])
	
	# 4. 清空当前项目
	current_active_project_id = ""
	project_progress = 0.0
	
	# 5. 发信号通知 UI
	emit_signal("vision_improved", entropy, "项目完成！") # 复用刷新信号

func show_settlement():
	# 延迟一点点，等当前事件框关掉
	await get_tree().create_timer(0.5).timeout
	
	var settlement = load("res://_Scenes/UI_Settlement.tscn").instantiate()
	# 假设 UI_Settlement 会自动添加到 CanvasLayer
	get_tree().root.add_child(settlement)
	settlement.setup_report() # 生成报告

# --- 辅助：检查是否分心 ---
# 返回 true 表示分心了，false 表示专注
func check_is_distracted() -> bool:
	var base_chance = 0.05 # 基础分心率 5%
	
	# 叠加座位的分心风险
	if not current_study_buff.is_empty():
		base_chance += current_study_buff.get("distraction_chance", 0.0)
	
	# 进行判定
	if randf() < base_chance:
		print(">> [Global] 哎呀！分心了！(概率: %.0f%%)" % (base_chance * 100))
		return true
	
	return false

# --- 辅助：清理 Buff (重要！) ---
# 每次离开图书馆或结算完成后必须调用
func clear_study_buff():
	if not current_study_buff.is_empty():
		print(">> [Global] 离开座位，Buff失效。")
		current_study_buff.clear()
