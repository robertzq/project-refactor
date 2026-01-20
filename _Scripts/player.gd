extends CharacterBody3D

# --- 配置参数 ---
const TILE_SIZE = 2.0  
const MOVE_TIME = 0.2  

# --- 节点引用 ---
@onready var ray = $RayCast3D
@onready var anim_player = $AnimationPlayer
@onready var sprite = $Sprite3D
@onready var event_ui = %UI_Event

signal hit_building(building_id)

# --- 状态变量 ---
var is_moving = false 
var can_trigger_event = true 

# 新增：记录当前朝向的字符串，默认为 down (第一行)
# 对应你的动画名：walk_down, walk_left, walk_right, walk_up
var facing_direction = "down" 

func _physics_process(delta):
	if is_moving:
		return

	# 1. 监听输入
	var input_dir = Vector3.ZERO
	
	if Input.is_action_pressed("ui_up"):
		input_dir.z = -1
	elif Input.is_action_pressed("ui_down"):
		input_dir.z = 1
	elif Input.is_action_pressed("ui_left"):
		input_dir.x = -1
	elif Input.is_action_pressed("ui_right"):
		input_dir.x = 1
	
	# 2. 如果有输入
	if input_dir != Vector3.ZERO:
		try_move(input_dir)
	else:
		# 没输入时，播放待机动画
		# 这里的逻辑改为：播放 "idle_" + 当前朝向
		play_anim("idle")

func try_move(direction: Vector3):
	# A. 更新朝向 (核心修改)
	update_facing_direction(direction)
	
	# 注意：如果你之前使用了 flip_h，现在要确保它被关闭，
	# 因为现在的 SpriteSheet 里左和右是分开画的，不需要翻转
	sprite.flip_h = false 
	
	# B. 更新射线检测方向
	ray.target_position = direction * TILE_SIZE
	ray.force_raycast_update()
	
	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider.is_in_group("Buildings"):
			print("撞到了建筑！ID是: ", collider.building_id)
			emit_signal("hit_building", collider.building_id)
		# 撞墙停止
		return
	
	# C. 开始移动
	move_to_target(direction)

func move_to_target(direction: Vector3):
	is_moving = true
	
	# 播放走路动画：拼接字符串，例如 "walk_" + "up"
	play_anim("walk")
	
	var target_pos = global_position + (direction * TILE_SIZE)
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, MOVE_TIME)
	tween.tween_callback(func(): is_moving = false)

# --- 新增辅助函数：根据向量更新朝向字符串 ---
func update_facing_direction(dir: Vector3):
	if dir.z > 0:
		facing_direction = "down"
	elif dir.z < 0:
		facing_direction = "up"
	elif dir.x > 0:
		facing_direction = "right"
	elif dir.x < 0:
		facing_direction = "left"

func play_anim(action_name: String):
	var full_anim_name = action_name + "_" + facing_direction
	
	if anim_player.current_animation == full_anim_name and anim_player.is_playing():
		return
	
	if anim_player.has_animation(full_anim_name):
		# --- 核心修改 ---
		# 计算播放速度。
		# 假设标准动画是 1秒，我们想在 MOVE_TIME (0.2秒) 内播完它，
		# 速度倍率 = 动画原长 / 目标时长
		# 这里我们写死 1.0 作为你的动画原长，或者用 anim_player.get_animation(full_anim_name).length 获取
		
		var anim_length = anim_player.get_animation(full_anim_name).length
		var play_speed = anim_length / MOVE_TIME 
		
		# 第三个参数是播放速度 (speed_scale)
		# 现在它会以 5倍速播放，确保在 0.2秒内跑完一整圈动画
		anim_player.play(full_anim_name, -1, play_speed) 
		# ----------------
	else:
		if action_name == "idle":
			anim_player.stop()
