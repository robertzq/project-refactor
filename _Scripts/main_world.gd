extends Node3D

@onready var player = $Player
@onready var ui = %UI_Event

func _ready():
	# 当玩家发出“撞墙”信号时，让 UI 显示那个 ID
	player.hit_building.connect(func(building_id): 
		var event_data = Global.get_random_event(building_id)
		ui.show_event(event_data) 
	)
	
	
func _input(event):
	# 按 "P" 键模拟半个月结束，弹出结算报告
	if event.is_action_pressed("ui_accept"): # 或者自定义按键
		Global.show_settlement()
		
	if event.is_action_pressed("ui_end"): # 比如按 E 键
		show_ending()



func show_ending():
	var ending_text = EndingManager.generate_verdict()
	# 复用那个漂亮的半月结算界面，或者新建一个
	var ui = load("res://_Scenes/UI_Settlement.tscn").instantiate()
	add_child(ui)
	ui.story_text.text = ending_text
	get_tree().paused = true
