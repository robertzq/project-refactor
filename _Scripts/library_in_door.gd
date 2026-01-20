extends Control

# --- 信号：将座位数据 + 随机事件数据 打包发回主场景 ---
signal session_started(seat_data, random_event)

# --- 核心数据配置 ---
const SEAT_TYPES = {
	"WINDOW": {
		"name": "靠窗景观位",
		"desc": "阳光很好，但也容易看着窗外发呆。\n[效果]: 效率 x1.3 | 专注风险 ↑",
		"stats": {"eff_mod": 1.3, "stress_fix": 0, "distraction_chance": 0.25}
	},
	"CORNER": {
		"name": "角落幽闭位",
		"desc": "没有人会从你身后经过，极致的孤独。\n[效果]: 效率 x1.15 | 基础压力 +5",
		"stats": {"eff_mod": 1.15, "stress_fix": 5, "distraction_chance": 0.0}
	},
	"NORMAL": {
		"name": "普通阅览位",
		"desc": "普普通通，就像你的人生。\n[效果]: 标准效率 | 无特殊加成",
		"stats": {"eff_mod": 1.0, "stress_fix": 0, "distraction_chance": 0.1}
	}
}

# --- 随机氛围事件库 (你提供的) ---
var ATMOSPHERE_EVENTS = [
	{
		"id": "PEER_PRESSURE",
		"cond": func(): return Global.pride > 5, 
		"text": "你看到对面座位的书堆得像山一样，而你才刚翻开第一页。",
		"effect": {"stress": 10}
	},
	{
		"id": "RICH_GADGET",
		"cond": func(): return Global.fin_security < 3,
		"text": "旁边的同学拿出了最新的 iPad Pro 和 Apple Pencil，你默默把草稿纸往回缩了缩。",
		"effect": {"pride": -1, "stress": 5}
	},
	{
		"id": "FLOW_STATE",
		"cond": func(): return Global.base_exec > 1.1,
		"text": "刚坐下，你就闻到了旧书特有的香草味，心情意外地平静。",
		"effect": {"stress": -15}
	},
	{
		"id": "COUPLE_DISTRACT",
		"cond": func(): return true, 
		"text": "斜前方有一对情侣在窃窃私语，虽然声音很小，但很刺耳。",
		"effect": {"stress": 5}
	},
	{
		"id": "EMPTY_MIND",
		"cond": func(): return true,
		"text": "今天图书馆人不多，空气中弥漫着一种适合睡觉的慵懒感。",
		"effect": {"stress": -5}
	}
]

# --- 节点引用 (根据你的描述调整) ---
@onready var seats_container = $TextureRect/Seats_Container
# 假设你有一个确认面板 (Panel)
@onready var confirm_panel = $ConfirmPanel
@onready var seat_info_label = $ConfirmPanel/InfoLabel
@onready var confirm_seat_btn = $ConfirmPanel/ConfirmBtn
# 假设底部有一个结果展示面板 (Panel)
@onready var result_panel = $ResultPanel
@onready var result_log_label = $ResultPanel/LogLabel
@onready var start_action_btn = $ResultPanel/StartBtn

var current_selected_seat_btn = null
var current_seat_type_key = ""
var final_seat_data = {}
var final_event_data = {}

# --- 新增：初始化入口函数 ---
# 主场景在 add_child 或 show 之前会调用这个
func setup(_data = null):
	# 1. 确保界面可见
	show()
	
	# 2. 重置 UI 状态 (隐藏之前的弹窗)
	confirm_panel.hide()
	result_panel.hide()
	seat_info_label.text = ""
	result_log_label.text = ""
	
	# 3. 清空之前的选择
	current_selected_seat_btn = null
	current_seat_type_key = ""
	
	# 4. (可选) 每次进入都重新随机一下座位被占用的情况
	# 这样每天进图书馆，空座位都不一样
	_randomize_occupancy_reset() 

# --- 修改辅助函数：重置座位状态 ---
func _randomize_occupancy_reset():
	for seat in seats_container.get_children():
		if seat is TextureButton:
			# 先恢复默认状态
			seat.disabled = false 
			seat.modulate = Color(1, 1, 1) 
			
			# 再随机禁用 (30% 概率)
			if randf() < 0.3:
				seat.disabled = true
				seat.modulate = Color(0.5, 0.5, 0.5)
				
func _ready():
	# 1. 隐藏弹窗
	confirm_panel.hide()
	result_panel.hide()
	
	# --- 调试代码 ---
	if seats_container == null:
		printerr("!!! 严重错误: 找不到 Seats_Container，请检查路径 $TextureRect/Seats_Container 是否正确！")
		return
		
	var children = seats_container.get_children()
	print("--- 调试信息 ---")
	print("找到座位容器，其中的子节点数量: ", children.size())
	
	# 2. 连接所有座位的信号
	var connected_count = 0
	for seat in children:
		# 打印一下子节点的类型，看看是不是 TextureButton
		# print("子节点: ", seat.name, " 类型: ", seat.get_class()) 
		
		if seat is TextureButton:
			# 只要还没连过，就连上
			if not seat.pressed.is_connected(_on_seat_clicked):
				seat.pressed.connect(_on_seat_clicked.bind(seat))
				connected_count += 1
	
	print("成功连接信号的座位数: ", connected_count)
	print("----------------")

	# 3. 初始化占座
	_randomize_occupancy()
	
	# 4. (关键) 确保确认按钮和开始按钮也连接了！
	if confirm_seat_btn and not confirm_seat_btn.pressed.is_connected(_on_confirm_occupy_pressed):
		confirm_seat_btn.pressed.connect(_on_confirm_occupy_pressed)
	if start_action_btn and not start_action_btn.pressed.is_connected(_on_start_action_pressed):
		start_action_btn.pressed.connect(_on_start_action_pressed)
	

func _randomize_occupancy():
	for seat in seats_container.get_children():
		if seat is TextureButton:
			# 30% 概率被占
			if randf() < 0.3:
				seat.disabled = true
				seat.modulate = Color(0.5, 0.5, 0.5) # 变灰

# --- 第一步：点击座位，弹出确认框 ---
func _on_seat_clicked(seat_btn: TextureButton):
	print(">>> 点击了座位: ", seat_btn.name)
	current_selected_seat_btn = seat_btn
	
	# 核心修改：使用 Groups 判断类型
	if seat_btn.is_in_group("window_seats"):
		current_seat_type_key = "WINDOW"
	elif seat_btn.is_in_group("corner_seats"):
		current_seat_type_key = "CORNER"
	else:
		current_seat_type_key = "NORMAL" # 默认为普通
		
	# 更新 UI
	var data = SEAT_TYPES[current_seat_type_key]
	seat_info_label.text = "%s  %s" % [data.name, data.desc]
	
	# 显示确认框，隐藏之前的逻辑
	confirm_panel.show()
	result_panel.hide()

# --- 第二步：确认占座，计算随机事件，显示底部结果 ---
# 绑定到 ConfirmPanel 里的 "确认占座" 按钮
func _on_confirm_occupy_pressed():
	confirm_panel.hide()
	
	# 1. 锁定数据
	final_seat_data = SEAT_TYPES[current_seat_type_key]
	
	# 2. 抽取随机事件
	final_event_data = _pick_random_event()
	
	# 3. 在底部面板显示结果
	result_panel.show()
	
	var log_text = "你选择了 %s。\n" % final_seat_data.name
	log_text += "----------------\n"
	log_text += final_event_data.text + "\n"
	
	# 显示属性变化提示 (可选)
	var eff = final_event_data.effect
	if "stress" in eff:
		var sign_str = "+" if eff.stress > 0 else ""
		log_text += "(压力 %s%d) " % [sign_str, eff.stress]
	if "pride" in eff:
		log_text += "(自尊 %d) " % eff.pride
		
	result_log_label.text = log_text

# --- 辅助函数：抽取事件 ---
func _pick_random_event():
	var valid_events = []
	for evt in ATMOSPHERE_EVENTS:
		# 调用 lambda 检查条件
		if evt.cond.call():
			valid_events.append(evt)
	
	if valid_events.size() > 0:
		return valid_events.pick_random()
	else:
		# 兜底
		return {
			"id": "NONE", 
			"text": "图书馆很安静，什么也没发生。", 
			"effect": {}
		}

# --- 第三步：点击“开始学习/结算”，回到主场景 ---
# 绑定到 ResultPanel 里的 "开始" 按钮
func _on_start_action_pressed():
	# 可以在这里播放一个翻书音效
	
	# 发送信号，把两份数据传出去
	emit_signal("session_started", final_seat_data, final_event_data)
	
	# 关闭界面
	hide()
	# 如果你是 popup 模式，这里可能需要 queue_free() 或者 hide()
