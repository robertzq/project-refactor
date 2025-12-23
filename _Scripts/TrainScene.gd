extends Control

# --- 节点引用 ---
@onready var title_label = $Content/QuestionTitle
@onready var desc_label = $Content/QuestionDesc
@onready var options_container = $Content/OptionsContainer
@onready var sfx_player = $SFX

# --- 问卷数据配置 (纯数据版) ---
# 移除了所有的 func(): ... 
# 改为使用字典来描述要改变的属性
var questions = [
	{
		"title": "Q1. 囊中羞涩",
		"text": "父母塞给你的一沓生活费，摸起来是什么感觉？",
		"options": [
			{
				"text": "沉重 (全家积蓄)",
				# delta_stats: 表示在这个属性上 增加/减少 多少
				"delta_stats": {"fin_security": -1},
				# add_trait: 表示获得什么特质
				"add_trait": "背水一战"
			},
			{
				"text": "踏实 (够用就好)",
				# 什么都不写，就是无变化
			},
			{
				"text": "轻松 (零花钱)",
				"delta_stats": {"fin_security": 1},
				"add_trait": "退路"
			}
		]
	},
	{
		"title": "Q2. 曾经的战场",
		"text": "回想起高中那道物理压轴题，你的第一反应是？",
		"options": [
			{
				"text": "兴奋拆解 (Geek)",
				# set_global: 表示直接把 Global 里的变量设为这个值 (用于 exec 倍率)
				"set_global": {"base_exec": 1.2},
				"add_trait": "技术狂热"
			},
			{
				"text": "痛苦征服 (Striver)",
				"set_global": {"base_exec": 1.1},
				"add_trait": "卷王"
			},
			{
				"text": "枯燥死记 (Normal)",
				"set_global": {"base_exec": 0.9},
				"add_trait": "实用主义"
			}
		]
	},
	{
		"title": "Q3. 窗外的风景",
		"text": "看着窗外倒退的风景，你对这个世界的看法是？",
		"options": [
			{
				"text": "我要搞清楚规则",
				"delta_stats": {"entropy": 2}
			},
			{
				"text": "随波逐流吧",
				"delta_stats": {"entropy": -1}
			}
		]
	},
	{
		"title": "Q4. 落地之后",
		"text": "下了车，你想怎么休息来恢复这一路的疲惫？",
		"options": [
			{
				"text": "找老同学聚聚",
				"set_global": {"recovery_strategy": "Extrovert"}
			},
			{
				"text": "找个网吧呆着",
				"set_global": {"recovery_strategy": "Introvert"}
			},
			{
				"text": "随便逛逛",
				"set_global": {"recovery_strategy": "Explorer"}
			}
		]
	}
]

var current_index = 0

func _ready():
	# $BG_Sound.play() # 记得解开注释
	load_question()

func load_question():
	if current_index >= questions.size():
		finish_questionnaire()
		return
	
	var q_data = questions[current_index]
	title_label.text = q_data["title"]
	desc_label.text = q_data["text"]
	
	# 清空旧按钮
	for child in options_container.get_children():
		child.queue_free()
	
	# 生成新按钮
	for opt in q_data["options"]:
		var btn = Button.new()
		btn.text = opt["text"]
		btn.add_theme_font_size_override("font_size", 24)
		btn.custom_minimum_size.y = 60
		# 把整个 opt 数据字典传给处理函数
		btn.pressed.connect(_on_option_selected.bind(opt))
		options_container.add_child(btn)

# --- 核心修改：在这里解析数据并执行 ---
func _on_option_selected(opt_data):
	# --- 新增：防止重复点击 ---
	# 1. 遍历容器，把所有按钮设为不可用
	for btn in options_container.get_children():
		btn.disabled = true
	# -----------------------

	# 播放音效
	if sfx_player: sfx_player.play()
	
	# 1. 处理数值增减
	if opt_data.has("delta_stats"):
		var stats = opt_data["delta_stats"]
		for key in stats:
			var current_val = Global.get(key)
			Global.set(key, current_val + stats[key])
			print("属性变更: ", key, " ", stats[key])

	# 2. 处理直接赋值
	if opt_data.has("set_global"):
		var setters = opt_data["set_global"]
		for key in setters:
			Global.set(key, setters[key])
			print("属性设定: ", key, " = ", setters[key])

	# 3. 处理特质添加
	if opt_data.has("add_trait"):
		Global.add_trait(opt_data["add_trait"])

	# --- 稍微加一点点延迟，让玩家听到点击音效再切题 ---
	await get_tree().create_timer(0.2).timeout
	
	# 进入下一题
	current_index += 1
	load_question()

	# 2. 处理直接赋值 (set_global)
	if opt_data.has("set_global"):
		var setters = opt_data["set_global"]
		for key in setters:
			Global.set(key, setters[key])
			print("属性设定: ", key, " = ", setters[key])

	# 3. 处理特质添加 (add_trait)
	if opt_data.has("add_trait"):
		Global.add_trait(opt_data["add_trait"])

	# 进入下一题
	current_index += 1
	load_question()

func finish_questionnaire():
	print(">>> 问卷结束 <<<")
	print("Security: ", Global.fin_security)
	print("Exec: ", Global.base_exec)
	print("Traits: ", Global.traits)
	print("Strategy: ", Global.recovery_strategy)
	
	# 转场代码放在这
	# get_tree().change_scene_to_file("res://Scenes/MainDashboard.tscn")
