extends Node2D


func _ready():
	print(">>> 进入崩溃演出场景...")
	
	# 1. (可选) 可以在这里播放音效，比如救护车声或心跳声
	# $AudioStreamPlayer.play()
	
	# 2. 等待 3 秒
	await get_tree().create_timer(3.0).timeout
	
	# 3. 切回主场景
	print(">>> 休息结束，重返现实。")
	_return_to_main_world()

func _return_to_main_world():
	# 确保这里是你主场景的正确路径
	var main_scene_path = "res://_Scenes/MainWorld.tscn"
	get_tree().change_scene_to_file(main_scene_path)
