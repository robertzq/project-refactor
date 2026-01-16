extends Control

signal seat_confirmed(seat_data)

# 定义座位类型的数据字典
const SEAT_TYPES = {
	"WINDOW": {
		"desc": "【靠窗黄金位】\n阳光很好，但也容易看着窗外发呆。\n(心情恢复↑，专注度波动)",
		"effect": {"mood": 5, "focus_risk": 0.2}
	},
	"CORNER": {
		"desc": "【死角面壁位】\n没有人会从你身后经过，极致的孤独。\n(专注度↑↑，心情恢复↓)",
		"effect": {"mood": -2, "focus_bonus": 1.2}
	},
	"PILLAR": {
		"desc": "【柱子后】\n视野受阻，但很有安全感。\n(焦虑降低↑)",
		"effect": {"anxiety_reduce": 10}
	},
	"NORMAL": {
		"desc": "【普通座位】\n普普通通，就像你的人生。\n(无特殊加成)",
		"effect": {}
	}
}

@onready var map_bg = $TextureRect
@onready var info_label = $Panel/Label
@onready var confirm_btn = $Panel/Button

var current_selected_seat = null

func _ready():
	# 初始化：连接所有座位的点击信号
	for seat in map_bg.get_children():
		if seat is TextureButton:
			# 假设你在编辑器里给按钮命名为 "Seat_Window_1", "Seat_Corner_2"
			# 或者我们可以利用 Godot 的 Meta 数据，或者简单的命名规则
			seat.pressed.connect(func(): _on_seat_clicked(seat))

func setup(building_id):
	show()
	info_label.text = "请选择一个空座位..."
	confirm_btn.disabled = true
	current_selected_seat = null
	
	# --- 核心玩法：随机占座 (幸存者偏差) ---
	# 每次进来，随机让 30%-50% 的座位变“有人”
	for seat in map_bg.get_children():
		if seat is TextureButton:
			var is_taken = randf() < 0.4 # 40% 概率被占
			seat.disabled = is_taken
			if is_taken:
				seat.modulate = Color(0.5, 0.5, 0.5) # 变灰，或者换成“书堆”图片
				# seat.texture_normal = load("res://Assets/seat_books.png") 
			else:
				seat.modulate = Color(1, 1, 1) # 恢复亮色

func _on_seat_clicked(seat_btn: TextureButton):
	current_selected_seat = seat_btn
	
	# 1. 解析座位类型 (通过名字判断，最简单)
	var type = "NORMAL"
	if "Window" in seat_btn.name:
		type = "WINDOW"
	elif "Corner" in seat_btn.name:
		type = "CORNER"
	elif "Pillar" in seat_btn.name:
		type = "PILLAR"
		
	# 2. 更新 UI 描述
	var data = SEAT_TYPES[type]
	info_label.text = data["desc"]
	confirm_btn.disabled = false
	
	# 3. 视觉反馈 (例如给选中的椅子加个框，这里先简化)
	print("选中了: ", type)

# 确认按钮点击
func _on_confirm_pressed():
	if current_selected_seat:
		hide()
		# 发送信号，把座位的效果传出去，给 MainWorld 结算
		# 这里重新解析一次类型，或者存个变量都行
		var type = "NORMAL"
		if "Window" in current_selected_seat.name: type = "WINDOW"
		elif "Corner" in current_selected_seat.name: type = "CORNER"
		elif "Pillar" in current_selected_seat.name: type = "PILLAR"
		
		emit_signal("seat_confirmed", SEAT_TYPES[type])

func _on_exit_pressed():
	hide()
	get_tree().paused = false
