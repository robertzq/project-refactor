extends Control

# --- 节点引用 ---
@onready var sliders = {
	"security": %SecuritySlider,
	"entropy":  %EntropySlider,
	"pride":    %PrideSlider,
	"sensitivity": %SensitivitySlider
}

# 用于存储显示的 Label
var value_labels = {} 

@onready var desc_label = $HBoxTop/VBox/RichTextLabel # 请确保这个路径是对的
@onready var remain_points_label = $HBoxTop/VBox/RemainPointsLabel
@onready var origin_option = $HBoxTop/VBox/OptionButton
@onready var comment_label = $HBoxTop/LeftPanel/VBoxContainer/CommentLabel
@onready var truth_shape = $HBoxTop/LeftPanel/VBoxContainer/TruthShape

const MAX_POINTS = 20

# --- 状态记录 ---
var last_voice_time = -10.0 # 初始设为负数，保证第一次操作必定触发语音
var voice_cooldown = 1.5 
var last_zones = {"security": -1, "entropy": -1, "pride": -1, "sensitivity": -1}
var current_voice_id = "" 

func _ready():
	print("--- 场景初始化开始 ---")
	
	# 1. 强制全屏
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# ============================================================
	# 🎨 UI 布局微调
	# ============================================================
	
	# 获取主要容器
	var hbox_top = $HBoxTop
	var left_panel = $HBoxTop/LeftPanel
	var right_panel = $HBoxTop/VBox 
	
	if hbox_top and left_panel and right_panel:
		hbox_top.set_anchors_preset(Control.PRESET_FULL_RECT)
		
		# --- 左右分屏 ---
		left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		left_panel.size_flags_stretch_ratio = 1.0 
		
		right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		right_panel.size_flags_stretch_ratio = 1.0
		right_panel.add_theme_constant_override("separation", 30)
		
		# [关键] 防止左侧面板被挤压为0
		left_panel.custom_minimum_size.x = 400 
		right_panel.custom_minimum_size.x = 400

		# --- [核心修复] 解决字竖着排的问题 ---
		if comment_label:
			# 1. 开启智能换行
			comment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			# 2. 撑满横向空间
			comment_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL 
			# 3. [这一行救命] 给它一个最小宽度，防止被挤成一条线
			comment_label.custom_minimum_size.x = 300 
			# 4. 居中对齐 (可选，看你喜好)
			comment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# ============================================================
	# 🔧 下拉框专项整形
	# ============================================================
	
	origin_option.add_theme_font_size_override("font_size", 32) 
	var popup = origin_option.get_popup()
	popup.add_theme_font_size_override("font_size", 32)
	
	origin_option.size_flags_vertical = Control.SIZE_SHRINK_CENTER 
	origin_option.custom_minimum_size.y = 80 

	# ============================================================
	# 🎚️ 滑块整形
	# ============================================================
	for key in sliders:
		var s = sliders[key]
		if s:
			s.size_flags_vertical = Control.SIZE_EXPAND_FILL
			s.custom_minimum_size.y = 50 
	
	# ============================================================
	# ⚙️ 逻辑初始化
	# ============================================================

	# 智能查找 ValueLabel
	for key in sliders:
		var s = sliders[key]
		if s == null: continue
		var lbl = s.get_parent().get_node_or_null("ValueLabel")
		if lbl == null:
			for child in s.get_parent().get_children():
				if child is Label and child != s:
					lbl = child
					break
		if lbl: 
			value_labels[key] = lbl
			lbl.add_theme_font_size_override("font_size", 32)

	# TTS 初始化
	var voices = DisplayServer.tts_get_voices()
	if not voices.is_empty():
		for v in voices:
			if v.has("language") and v["language"].begins_with("en"):
				current_voice_id = v["id"]
				print(">> 选中英文神音: ", v["name"])
				break
		if current_voice_id == "": current_voice_id = voices[0]["id"]

	# 下拉菜单内容
	origin_option.clear()
	origin_option.add_item("--- 选择出身 (Archetype) ---", 0)
	var idx = 1
	var origins = ["小镇做题家", "落魄书香", "野蛮生长", "温室花朵"]
	for origin_name in origins:
		origin_option.add_item(origin_name, idx)
		idx += 1
	origin_option.item_selected.connect(_on_origin_selected)

	# 连接滑块信号
	for key in sliders:
		var slider = sliders[key]
		if slider:
			slider.min_value = 0
			slider.max_value = 10
			slider.step = 0.1
			if slider.value_changed.is_connected(_on_slider_changed):
				slider.value_changed.disconnect(_on_slider_changed)
			slider.value_changed.connect(_on_slider_changed.bind(key))
	
	update_ui()
	print("--- 场景初始化完成 ---")
	
	await get_tree().create_timer(0.5).timeout
	speak_truth("So... you wish to reconstruct a soul?", "那么……你想重构一个灵魂？")
# --- 核心交互 ---
func _on_slider_changed(value_discarded, key):
	# 调试打印：如果你拖动滑块看不到这行字，说明信号没连上
	# print("[滑块移动] Key: ", key, " | Value: ", sliders[key].value)
	
	update_ui()
	
	# 视觉反馈
	if truth_shape:
		var tween = create_tween()
		var target_scale = 1.0 + (sliders[key].value * 0.05)
		tween.tween_property(truth_shape, "scale", Vector2.ONE * target_scale, 0.2)

	trigger_truth_commentary(key, sliders[key].value)

# --- 界面刷新 ---
func update_ui():
	var current_total = 0
	for key in sliders:
		var val = sliders[key].value
		current_total += val
		# 更新 Label
		if value_labels.has(key):
			# 这里加了 str() 确保转字符串
			value_labels[key].text = str(int(val))
	
	var remain = MAX_POINTS - current_total
	if remain_points_label:
		remain_points_label.text = "剩余点数: " + str(int(remain))
		if remain < 0:
			remain_points_label.modulate = Color.RED
		else:
			remain_points_label.modulate = Color.WHITE

# --- 说话逻辑 ---
func trigger_truth_commentary(key: String, value: float):
	var current_time = Time.get_ticks_msec() / 1000.0
	var current_zone = int(value / 2.1) # 0-2.1 为第一档，2.1-4.2 为第二档...
	
	# 1. 实时刷新文字 (无视冷却，只要变了就刷)
	var commentary = get_commentary(key, value)
	if comment_label:
		# 只有当中文字幕发生变化时，才重新打印
		if comment_label.text != commentary.cn:
			comment_label.text = commentary.cn
			comment_label.visible_ratio = 0.0
			var tween = create_tween()
			tween.tween_property(comment_label, "visible_ratio", 1.0, 0.5)

	# 2. 语音播放 (必须跨越区间 OR 距离上次说话很久)
	# 这里的 4.0 是“沉默保护”，如果神很久没说话了，即使你在同一个区间微调，它也会重新念一遍
	if current_time - last_voice_time > voice_cooldown:
		if current_zone != last_zones[key] or (current_time - last_voice_time > 4.0):
			
			# 播放声音
			speak_truth(commentary.en, commentary.cn, false) # false 表示不重置字幕动画，防止打断上面
			
			last_zones[key] = current_zone
			last_voice_time = current_time

# --- TTS 执行 ---
# update_text_anim: 是否要在这里重置字幕动画 (默认 true)
func speak_truth(text_en: String, text_cn: String, update_text_anim: bool = true):
	DisplayServer.tts_stop()
	
	if comment_label and update_text_anim:
		comment_label.text = text_cn
		comment_label.visible_ratio = 0.0
		var tween = create_tween()
		tween.tween_property(comment_label, "visible_ratio", 1.0, 1.5)
	
	if not current_voice_id.is_empty():
		# 参数: text, voice_id, volume, pitch, rate
		# Pitch 0.6 = 低沉巨人音
		# Rate 0.75 = 缓慢压迫感
		DisplayServer.tts_speak(text_en, current_voice_id, 60, 0.6, 0.75)

# --- 文案库 (保持不变) ---
func get_commentary(type: String, val: float) -> Dictionary:
	var v = int(val)
	match type:
		"security":
			if v <= 2: return {"en": "Survival mode. The dirt tastes bitter.", "cn": "生存模式。土的味道很苦吧？"}
			if v <= 4: return {"en": "Just enough to starve slowly.", "cn": "这点钱，刚够你慢慢饿死。"}
			if v <= 6: return {"en": "Mediocrity. Safe, but boring.", "cn": "平庸。安全，但也无聊。"}
			if v <= 8: return {"en": "Comfortable. You forgot how to run.", "cn": "很舒适。你已经忘了怎么奔跑。"}
			return {"en": "The golden parachute. Don't choke.", "cn": "金色的降落伞。别被噎死了。"}
		"pride":
			if v <= 2: return {"en": "A doormat. Everyone wipes their feet.", "cn": "一块地垫。谁都能踩两脚。"}
			if v <= 4: return {"en": "Weak knees. You want to kneel.", "cn": "膝盖很软。你本能地想跪下。"}
			if v <= 6: return {"en": "A healthy ego. How common.", "cn": "健康的自尊。多么普通。"}
			if v <= 8: return {"en": "Nose high. You will drown in rain.", "cn": "鼻孔朝天。下雨时会被淹死的。"}
			return {"en": "Stiff neck. Perfect for hanging.", "cn": "脖子真硬。很适合挂在绞刑架上。"}
		"entropy":
			if v <= 2: return {"en": "Blind. Blissfully ignorant.", "cn": "瞎子。无知是福。"}
			if v <= 6: return {"en": "You see what they want you to see.", "cn": "你只看得到别人想让你看的。"}
			return {"en": "You see the chaos. Can you handle it?", "cn": "你看见了混沌。但你能承受吗？"}
		"sensitivity":
			if v <= 3: return {"en": "Stone heart. Nothing hurts.", "cn": "铁石心肠。什么都伤不了你。"}
			if v >= 8: return {"en": "Exposed nerves. Breathing hurts.", "cn": "神经裸露。连呼吸都会痛。"}
			
	return {"en": "Interesting choice...", "cn": "有趣的选择……"}

# --- 职业选择 ---
func _on_origin_selected(index):
	if index == 0: return
	var origin_name = origin_option.get_item_text(index)
	# 选职业时，只播放一句总结性的悲剧，不触发滑块语音，防止吵闹
	speak_truth("Ah, " + origin_name + ". A classic tragedy.", "啊，" + origin_name + "。一出经典的悲剧。")
	
	# 设置数值 (这里不会触发 value_changed 信号)
	match origin_name:
		"小镇做题家":
			sliders["security"].value = 2
			sliders["pride"].value = 6
			sliders["sensitivity"].value = 8 
			sliders["entropy"].value = 3
		"落魄书香":
			sliders["security"].value = 4
			sliders["pride"].value = 9
			sliders["sensitivity"].value = 9
			sliders["entropy"].value = 7
		"野蛮生长":
			sliders["security"].value = 3
			sliders["pride"].value = 1
			sliders["sensitivity"].value = 2
			sliders["entropy"].value = 5
		"温室花朵":
			sliders["security"].value = 9
			sliders["pride"].value = 5
			sliders["sensitivity"].value = 5
			sliders["entropy"].value = 4
	
	# 手动刷新 UI 数值显示
	update_ui()

func _on_start_button_pressed():
	var total = 0
	for key in sliders: total += sliders[key].value
	if total > MAX_POINTS:
		speak_truth("Greedy soul. Too much.", "贪婪的灵魂。你索取得太多了。")
		var tween = create_tween()
		tween.tween_property(remain_points_label, "position:x", remain_points_label.position.x + 10, 0.05).set_trans(Tween.TRANS_SINE)
		tween.tween_property(remain_points_label, "position:x", remain_points_label.position.x - 10, 0.05).set_trans(Tween.TRANS_SINE)
		tween.tween_property(remain_points_label, "position:x", remain_points_label.position.x, 0.05)
		return

	Global.fin_security = sliders["security"].value
	Global.pride = sliders["pride"].value
	Global.entropy = sliders["entropy"].value
	Global.sensitivity = 0.8 + (sliders["sensitivity"].value * 0.07) 
	
	print(">>> 灵魂注入完成。")
	get_tree().change_scene_to_file("res://_Scenes/MainWorld.tscn")
