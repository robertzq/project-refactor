extends Node3D

@onready var player = $Player
@onready var ui = $UI_Layer

func _ready():
	# 当玩家发出“撞墙”信号时，让 UI 显示那个 ID
	player.hit_building.connect(func(building_id): 
		var event_data = Global.get_random_event(building_id)
		ui.show_event_popup(event_data) 
	)
	
	
