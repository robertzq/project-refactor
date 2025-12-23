extends Node

# ==============================================================================
# 1. 核心属性库 (The Internal Engine)
# ==============================================================================

# [基础资源]
var money: int = 0          # 资金 (影响生存)
var project_progress: float = 0.0 # 项目进度 (影响通关)

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
# ==============================================================================
# 2. 游戏初始化 (Game Flow)
# ==============================================================================

# 初始化角色模板 (在游戏开始或重开时调用)
func init_character(archetype: String):
	print(">>> 正在初始化角色模板: ", archetype)
	
	# 1. 重置所有动态状态
	current_anxiety = 0
	project_progress = 0
	traits = []
	recovery_strategy = "Explorer" # 默认值，会在火车问卷中被修改
	
	# 2. 根据出身设定初始数值
	match archetype:
		"STRIVER": # 小镇做题家
			fin_security = 2
			pride = 7
			base_exec = 1.2
			sensitivity = 1.2
			money = 800
			add_trait("卷王")
			
		"SLACKER": # 摆烂富二代
			fin_security = 8
			pride = 4
			base_exec = 0.8
			sensitivity = 0.9
			money = 5000
			add_trait("松弛感")
			
		_: # 默认 (Default)
			fin_security = 5
			pride = 5
			base_exec = 1.0
			sensitivity = 1.0
			money = 2000

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
		if current_anxiety < 0: current_anxiety = 0
		print(">> [Global] 治愈: %.1f | 当前焦虑: %.1f" % [heal_amount, current_anxiety])
		return {"damage": heal_amount, "current_anxiety": current_anxiety}

	# --- B. 扣血逻辑 (正数) ---
	
	# Step 1: 计算原始压力 (Omega)
	var omega = base_val
	var log_reason = ""
	
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
	
	# 打印战斗日志
	print("---------------------------------------")
	print("🩸 [Global] 压力结算 (%s)" % type)
	print("   公式: (基础%.0f -> 修正%.1f [%s]) x 敏感%.1f = 最终%.1f" % [base_val, omega, log_reason, sensitivity, final_damage])
	print("   当前焦虑: %.1f / %.1f" % [current_anxiety, get_max_anxiety_limit()])
	print("---------------------------------------")

	return {
		"damage": final_damage,
		"current_anxiety": current_anxiety,
		"is_breakdown": current_anxiety >= get_max_anxiety_limit()
	}

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
