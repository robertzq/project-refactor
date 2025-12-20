extends CharacterBody3D

# --- 配置参数 ---
const TILE_SIZE = 2.0  # 格子大小，必须和你的GridMap格子尺寸一致！
const MOVE_TIME = 0.2  # 移动一格需要多少秒（越小越快）

# --- 节点引用 ---
@onready var ray = $RayCast3D
@onready var anim_player = $AnimationPlayer
@onready var sprite = $Sprite3D
signal hit_building(building_id)
# --- 状态变量 ---
var is_moving = false  # 是否正在移动中（防止连按）

func _physics_process(delta):
	# 如果正在移动，就不接受新指令，直接返回
	if is_moving:
		return

	# 1. 监听输入 (上下左右)
	var input_dir = Vector3.ZERO
	
	if Input.is_action_pressed("ui_up"):
		input_dir.z = -1
	elif Input.is_action_pressed("ui_down"):
		input_dir.z = 1
	elif Input.is_action_pressed("ui_left"):
		input_dir.x = -1
	elif Input.is_action_pressed("ui_right"):
		input_dir.x = 1
	
	# 2. 如果有输入，尝试移动
	if input_dir != Vector3.ZERO:
		try_move(input_dir)
	else:
		# 没输入时，播放待机动画
		anim_player.play("idle")

func try_move(direction: Vector3):
	# A. 处理朝向翻转 (Flip H)
	# 如果向左走，flip_h = true；向右走，flip_h = false
	if direction.x != 0:
		sprite.flip_h = (direction.x < 0)
	
	# B. 更新射线检测方向
	# 我们要先看看目标格子里有没有墙
	ray.target_position = direction * TILE_SIZE
	ray.force_raycast_update() # 强制立刻检测
	
	if ray.is_colliding():
		# 1. 获取我们撞到了谁
		var collider = ray.get_collider()
		
		# 2. 检查它是不是建筑 (通过组名)
		if collider.is_in_group("Buildings"):
			print("撞到了建筑！ID是: ", collider.building_id)
			# TODO: 这里稍后会呼叫 UI 弹窗函数
			emit_signal("hit_building", collider.building_id)
			# event_ui.show_event(collider.building_id)
			
		# 3. 既然撞到了，就停止移动
		return
	
	# C. 开始移动 (使用 Tween)
	move_to_target(direction)

func move_to_target(direction: Vector3):
	is_moving = true
	anim_player.play("walk") # 播放走路动画
	
	# 计算目标位置 (当前位置 + 方向 * 格子大小)
	var target_pos = global_position + (direction * TILE_SIZE)
	
	# 创建动画补间 (Tween)
	var tween = create_tween()
	# 属性：让 "global_position" 在 "MOVE_TIME" 秒内 变到 "target_pos"
	tween.tween_property(self, "global_position", target_pos, MOVE_TIME)
	
	# 这里的回调很重要：移动结束后，把 is_moving 设回 false
	tween.tween_callback(func(): is_moving = false)
	
