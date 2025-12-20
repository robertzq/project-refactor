extends StaticBody3D

@export var building_id: String = "LIB" # 默认ID

func _ready():
	add_to_group("Buildings") # 关键！给它贴个标签，叫“我是建筑”
