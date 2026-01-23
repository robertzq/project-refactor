extends Control

# --- 绑定 UI 节点 ---
@onready var role_label = $PanelContainer/VBox/HBox/VBox/RoleLabel
@onready var money_label = $PanelContainer/VBox/Grid/MoneyLabel
@onready var pride_label = $PanelContainer/VBox/Grid/PrideLabel
@onready var sens_label = $PanelContainer/VBox/Grid/SensLabel
@onready var exec_label = $PanelContainer/VBox/Grid/ExecLabel
@onready var buff_label = $PanelContainer/VBox/BuffLabel
@onready var avatar = $PanelContainer/VBox/HBox/Avatar

# --- 角色中文名映射 ---
const ROLE_NAMES = {
	"ARCH_ELITE": "名门之后",
	"ARCH_LOCAL": "本地土著",
	"ARCH_SURVIVOR": "寒门学子",
	"ARCH_COUNTY_STAR": "小镇做题家", # 对应你的 COUNTY_STAR
	"ARCH_STRIVER": "卷王之王"
}

func _ready():
	# 初始化时刷新一次
	update_display()
	
	# 监听 Global 里的时间或属性变化信号，实现自动刷新
	# 如果 Global 有 signal stats_changed，这里 connect 一下最好
	# Global.connect("stats_changed", update_display)

# --- 核心刷新逻辑 ---
func update_display():
	# 1. 基础信息翻译
	var arch_key = Global.get("current_archetype_key") # 假设你在Global存了这个变量
	var role_name = ROLE_NAMES.get(arch_key, "普通大学生")
	role_label.text = "身份：[color=yellow]%s[/color]" % role_name
	
	# 2. 四维属性可视化 (带解释)
	_update_money()
	_update_pride()
	_update_sensitivity()
	_update_execution()
	
	# 3. 状态与 Buff (最重要的一栏)
	_update_buffs()

# --- 辅助函数：把数值变成“人话” ---

func _update_money():
	var val = Global.money
	var desc = ""
	if val < 500: desc = "(赤贫)"
	elif val < 2000: desc = "(拮据)"
	elif val > 5000: desc = "(富裕)"
	
	money_label.text = "💰 资金: %d %s" % [val, desc]
	# 赤贫时变红
	money_label.modulate = Color.RED if val < 500 else Color.WHITE

func _update_pride():
	var val = Global.pride
	var desc = ""
	if val >= 8: desc = "(死要面子)" # 提示玩家这会导致拒绝帮助
	elif val <= 2: desc = "(毫无底线)" # 提示玩家可以做卑微的事
	else: desc = "(正常)"
	
	pride_label.text = "🦁 自尊: %d %s" % [val, desc]

func _update_sensitivity():
	var val = Global.sensitivity
	var desc = ""
	# 敏感度大于 1.0 意味着受到的 Stress 会放大
	if val > 1.2: 
		desc = "[color=red](高敏：压力伤害 +%d%%)[/color]" % [(val - 1.0) * 100]
	elif val < 1.0:
		desc = "[color=green](钝感：压力伤害 -%d%%)[/color]" % [(1.0 - val) * 100]
	else:
		desc = "(正常)"
		
	sens_label.text = "💔 敏感度: %.1f %s" % [val, desc]

func _update_execution():
	var val = Global.base_exec
	var desc = ""
	# 基础执行力影响做事效率
	if val > 1.0:
		desc = "[color=green](高效：基础产出 +%d%%)[/color]" % [(val - 1.0) * 100]
	elif val < 1.0:
		desc = "[color=red](低效：基础产出 -%d%%)[/color]" % [(1.0 - val) * 100]
	
	exec_label.text = "⚡ 基础行动力: %.1f %s" % [val, desc]

func _update_buffs():
	# 获取 Global 计算好的综合效率
	var eff_data = Global.get_efficiency()
	var final_eff = eff_data["value"]
	var factors = eff_data["desc"] # Global 里返回的 "安逸诅咒, 座位加成" 等字符串
	
	var text = ""
	
	# 显示当前综合倍率
	text += "📊 [b]当前综合效率: %d%%[/b]\n" % (final_eff * 100)
	
	# 逐行解释原因
	if factors != "正常":
		text += "[color=gray]生效因子：[/color]\n"
		# 我们可以简单解析 Global 返回的字符串，或者直接显示
		text += " • " + factors.replace(", ", "\n • ")
	else:
		text += "[color=gray]无特殊状态修正[/color]"
		
	# 显示特质 (Traits)
	text += "\n\n🏷️ [b]人物特质:[/b]\n"
	if Global.traits.size() > 0:
		for t in Global.traits:
			text += " [%s] " % t
	else:
		text += " (无)"
		
	buff_label.text = text
