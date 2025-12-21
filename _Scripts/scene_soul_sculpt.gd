extends Node3D

# --- 1. 节点引用 (使用唯一名称 %，最稳妥) ---
# 请确保你在场景里把对应节点右键设为 "Access as Unique Name"
@onready var sliders = {
	"security": %SecuritySlider,
	"entropy":  %EntropySlider,
	"pride":    %PrideSlider,
	"focus":    %FocusSlider
}

# 对应的数值标签 (也请设为唯一名称，或者检查路径是否正确)
# 假设你的结构是 HBox -> [NameLabel, Slider, ValueLabel]
# 这里的路径必须和你实际场景一致！如果不一致，请修改这里！
@onready var value_labels = {
	"security": %SecuritySlider.get_parent().get_node("ValueLabel"),
	"entropy":  %EntropySlider.get_parent().get_node("ValueLabel"),
	"pride":    %PrideSlider.get_parent().get_node("ValueLabel"),
	"focus":    %FocusSlider.get_parent().get_node("ValueLabel")
}

@onready var soul_mesh = $MeshInstance3D
@onready var desc_label = $CanvasLayer/Control/Panel/VBox/RichTextLabel
@onready var remain_points_label = $CanvasLayer/Control/Panel/VBox/RemainPointsLabel
@onready var origin_option = $CanvasLayer/Control/Panel/VBox/OptionButton # 职业下拉框

const MAX_POINTS = 20

func _ready():
	# --- A. 初始化材质 ---
	if soul_mesh.material_override == null:
		soul_mesh.material_override = StandardMaterial3D.new()
	soul_mesh.material_override = soul_mesh.material_override.duplicate()
	
	# --- B. 初始化下拉菜单 (修复问题2) ---
	origin_option.clear()
	origin_option.add_item("--- 请选择出身 ---", 0) # ID 0 是占位符
	var idx = 1
	for origin_name in Global.origins:
		origin_option.add_item(origin_name, idx)
		# 把名字存为元数据，方便后面取
		origin_option.set_item_metadata(idx - 1, origin_name) 
		idx += 1
	
	# 连接下拉菜单信号
	origin_option.item_selected.connect(_on_origin_selected)

	# --- C. 连接滑块信号 ---
	for key in sliders:
		var slider = sliders[key]
		# 连接信号，当滑块拖动时触发
		if not slider.value_changed.is_connected(_on_slider_changed):
			slider.value_changed.connect(_on_slider_changed.unbind(1))
	
	# 初始刷新
	update_ui()

# --- 职业选择逻辑 ---
func _on_origin_selected(index):
	if index == 0: return # 选了占位符
	
	# 获取选中的职业名字
	# 注意：get_item_text 的索引是列表索引
	var origin_name = origin_option.get_item_text(index)
	
	if origin_name in Global.origins:
		var preset = Global.origins[origin_name]
		
		# 应用数值到滑块 (这会自动触发 value_changed 信号吗？Godot里通常不会，需要手动刷新)
		sliders["security"].value = preset["security"]
		sliders["entropy"].value = preset["entropy"]
		sliders["pride"].value = preset["pride"]
		sliders["focus"].value = preset["focus"]
		
		# 手动刷新一次界面
		update_ui()
		update_soul_visuals()

# --- 滑块变动逻辑 ---
func _on_slider_changed():
	# 1. 计算当前总分
	var current_total = 0
	for key in sliders:
		current_total += sliders[key].value
	
	# 2. 检查是否超标 (修复问题3：点数变负)
	if current_total > MAX_POINTS:
		# 如果超标了，我们要把刚才动的那个滑块“退回去”
		# 这里做一个简单的处理：哪个滑块导致溢出，就扣哪个
		# 为了简化，我们只显示红色警告，阻止开始游戏即可
		# 或者，你可以强制锁死数值（逻辑会比较复杂，先用变红警告）
		pass

	update_ui()
	update_soul_visuals()

# --- 界面更新逻辑 ---
func update_ui():
	var current_total = 0
	
	# 遍历更新所有 Label (修复问题4)
	for key in sliders:
		var val = sliders[key].value
		current_total += val
		
		# 确保这里的 value_labels 字典里真的有节点
		if value_labels.has(key) and value_labels[key] != null:
			value_labels[key].text = str(val)
	
	# 更新剩余点数
	var remain = MAX_POINTS - current_total
	remain_points_label.text = "剩余点数: " + str(remain)
	
	if remain < 0:
		remain_points_label.modulate = Color.RED
		$CanvasLayer/Control/Panel/VBox/StartButton.disabled = true # 禁止开始
		desc_label.text = "[color=red]精力透支！请减少某些属性。[/color]"
	else:
		remain_points_label.modulate = Color.WHITE
		$CanvasLayer/Control/Panel/VBox/StartButton.disabled = false
		update_description() # 如果没超标，才显示正常的性格描述

func update_soul_visuals():
	# 获取材质 (强转为 StandardMaterial3D 以便有代码提示)
	var mat = soul_mesh.material_override as StandardMaterial3D
	
	# 1. 获取归一化的数值 (0.0 到 1.0)
	# 假设最大值是 10.0，避免除以零
	var s_val = sliders["security"].value / 10.0
	var e_val = sliders["entropy"].value / 10.0
	var p_val = sliders["pride"].value / 10.0
	var f_val = sliders["focus"].value / 10.0
	
	# --- 颜色混合 (Color Mixing) ---
	# 自尊(红), 执行力(绿), 安全感(蓝)
	# 为了防止全0时是纯黑，给一点点基础亮度 (0.1)
	var final_color = Color(p_val + 0.1, f_val + 0.1, s_val + 0.1)
	
	mat.albedo_color = final_color
	
	# --- 发光 (Emission) ---
	# 只有当颜色足够亮时才发光
	mat.emission_enabled = true
	mat.emission = final_color
	# 关键：自尊越高，光越刺眼 (Energy 从 0.5 到 3.0)
	mat.emission_energy_multiplier = 0.5 + (p_val * 2.5)
	
	# --- 材质质感 (PBR Properties) ---
	# 安全感越高 -> 越光滑 (Roughness 越低)
	# 安全感 10 -> Roughness 0.1 (像镜子)
	# 安全感 0  -> Roughness 1.0 (像粗糙的石头)
	mat.roughness = 1.0 - (s_val * 0.9)
	
	# 执行力越高 -> 越像金属 (Metallic 越高)
	# 代表一种冷酷的工具属性
	mat.metallic = f_val
	
	# --- 物理形态 (Transform) ---
	# 信息熵越高 -> 球越大 (代表世界观越大)
	# 基础大小 0.8，最大 1.4
	var target_scale = 0.8 + (e_val * 0.6)
	
	# 我们可以加一点点平滑过渡 (Lerp)，而不是瞬间变大
	# 注意：在 _process 里做 lerp 最好，但在函数里直接赋值也行，MVP这就够了
	soul_mesh.scale = Vector3.ONE * target_scale

func update_description():
	var s = sliders["security"].value
	var e = sliders["entropy"].value
	var p = sliders["pride"].value
	var f = sliders["focus"].value
	
	var text = ""
	
	if f > 8 and e < 3:
		text = "[color=yellow]【做题家】[/color]\n你极其擅长解决给定的问题，但从未想过问题是谁提出的。\n(考研成功率大幅上升，迷雾视野极窄)"
	elif p > 8 and s < 3:
		text = "[color=purple]【落魄书香】[/color]\n你宁愿饿死也不愿送外卖。你的傲骨是你唯一的资产，也是最大的负债。\n(无法从事低端兼职)"
	elif s > 8:
		text = "[color=green]【稳健派】[/color]\n父母给你铺好了路。你不需要冒险，因为终点就在家门口。\n(创业路径不可见)"
	else:
		text = "一个普通的灵魂，等待被时代的洪流重构。"
		
	desc_label.text = text

func _on_start_button_pressed():
	# 再次检查逻辑（双重保险）
	var total = 0
	for key in sliders:
		total += sliders[key].value
		
	if total > MAX_POINTS:
		return # 不允许开始
		
	var final_stats = {}
	for key in sliders:
		final_stats[key] = sliders[key].value
	
	Global.set_soul_stats(final_stats)
	
	# 请确认这个路径是正确的，注意大小写！
	get_tree().change_scene_to_file("res://_Scenes/MainWorld.tscn")
