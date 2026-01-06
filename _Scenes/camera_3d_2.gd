extends Camera3D

@export var target: Node3D # 在编辑器里把你的角色节点拖进来
@export var focus_width: float = 10.0 # 清晰区域的宽度

func _process(delta):
	if not target:
		return
		
	# 1. 计算相机到角色的实际距离
	var dist = global_position.distance_to(target.global_position)
	
	# 2. 获取相机的属性资源 (确保你在编辑器里已经给相机挂了 CameraAttributesPractical)
	var cam_attributes = attributes as CameraAttributesPractical
	
	if cam_attributes:
		# 3. 设置远景虚化 (从角色身后开始糊)
		cam_attributes.dof_blur_far_enabled = true
		cam_attributes.dof_blur_far_distance = dist + (focus_width / 2.0)
		cam_attributes.dof_blur_far_transition = 5.0 # 过渡柔和度
		
		# 4. 设置近景虚化 (从角色身前开始糊)
		cam_attributes.dof_blur_near_enabled = true
		cam_attributes.dof_blur_near_distance = dist - (focus_width / 2.0)
		cam_attributes.dof_blur_near_transition = 5.0
