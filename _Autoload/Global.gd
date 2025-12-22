extends Node

# ========================================================
# 1. 核心属性定义 (The Soul) v3.2
# ========================================================

# 基础属性 (0-10)
var fin_security: int = 0      # 家境 (底气): 决定胆量，抵消金钱压力
var pride: int = 0             # 自尊 (骨气): 决定胆量，增加面子压力
var sensitivity: float = 1.0   # 敏感 (痛觉): 全局伤害倍率 (0.8 - 1.5)
var entropy: int = 0           # 熵值 (视野): 决定地图节点可见性
var base_exec: float = 1.0     # 执行力 (手): 基础效率系数

# 动态状态
var current_anxiety: float = 0.0
var max_anxiety_limit: float = 100.0 # 由 base_exec * 80 决定
var current_ap: int = 100
var money: int = 0

# 特质与Buff
var traits: Array = []         # 例如 ["背水一战", "退路"]
var active_curses: Array = []  # 例如 ["安逸诅咒"]

# 游戏进程
var current_day: int = 1
var current_time_slot: int = 0 # 0:早晨, 1:下午, 2:晚上

# ========================================================
# 2. 初始化逻辑 (Initialization)
# ========================================================

func init_character(archetype: String):
	# 重置状态
	current_anxiety = 0
	traits.clear()
	
	match archetype:
		"STRIVER": # 小镇做题家
			fin_security = 2
			pride = 6
			sensitivity = 1.2
			base_exec = 1.2
			entropy = 3
			traits.append("背水一战")
		"SCHOLAR": # 落魄书香
			fin_security = 4
			pride = 9
			sensitivity = 1.4
			base_exec = 0.9
			entropy = 7
		"HUSTLER": # 野蛮生长
			fin_security = 3
			pride = 1
			sensitivity = 0.9
			base_exec = 1.0
			entropy = 5
		"HEIR": # 温室花朵
			fin_security = 9
			pride = 5
			sensitivity = 1.0
			base_exec = 0.8
			entropy = 4
			traits.append("退路")
	
	# 计算初始阈值
	max_anxiety_limit = base_exec * 80.0
	print("Character Initialized: ", archetype, " | Limit: ", max_anxiety_limit)

# ========================================================
# 3. 核心公式计算器 (The Calculator)
# ========================================================

# 计算胆量 (公式 3.1)
func get_boldness() -> float:
	return (fin_security * 0.4) + (pride * 0.6)

# 计算并应用压力 (公式 3.2)
# event_type: "MONEY", "EGO", "GEN"
# is_working: 是否处于打工状态 (用于触发穷人避难所)
func apply_stress(base_stress: float, event_type: String, is_working: bool = false) -> Dictionary:
	var omega: float = base_stress
	var log_str: String = ""
	
	# Step 1: 原始压力
	match event_type:
		"MONEY":
			var reduction = fin_security * 2.0
			omega = base_stress - reduction
			log_str = "MoneyEvent: Base %s - Fin*2(%s)" % [base_stress, reduction]
		"EGO":
			var amp = pride * 0.5
			omega = base_stress + amp
			log_str = "EgoEvent: Base %s + Pride*0.5(%s)" % [base_stress, amp]
		_:
			log_str = "GenEvent: Base %s" % base_stress
			
	# Step 2: 避难所修正 (v3.2 修正值为 8)
	var refuge_bonus: float = 0.0
	if is_working and fin_security < 3:
		refuge_bonus = 8.0
		log_str += " - Refuge(8)"
	
	# Step 3: 最终结算
	var raw_val = max(0.0, omega - refuge_bonus)
	var final_delta = raw_val * sensitivity
	
	# 应用数值
	current_anxiety += final_delta
	log_str += " * Sens(%s) = %s" % [sensitivity, final_delta]
	
	# 检查崩溃
	var is_breakdown = current_anxiety >= max_anxiety_limit
	
	return {
		"damage": final_delta,
		"current_anxiety": current_anxiety,
		"breakdown": is_breakdown,
		"log": log_str
	}

# 获取当前工作/学习效率 (公式 3.3)
func get_efficiency() -> float:
	var boldness = get_boldness()
	var mu: float = 1.0
	active_curses.clear()
	
	# 判定诅咒
	# 1. 安逸诅咒
	if fin_security > 7 and current_anxiety < 30:
		mu *= 0.7
		active_curses.append("安逸")
	
	# 2. 胆怯诅咒
	if boldness < 4.0:
		mu *= 0.8
		active_curses.append("胆怯")
		
	# 3. 卷王 (特质加成)
	if current_anxiety > 80 and "背水一战" in traits:
		mu *= 1.2
		active_curses.append("卷王")
		
	return base_exec * mu
