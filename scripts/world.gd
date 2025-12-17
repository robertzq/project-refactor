extends Node


# 挂在 World 节点上的脚本

func _on_xuan_speak(text):
	if text == "你直接转行吧":
		trigger_awakening_event()
	else:
		# 普通的压制：屏幕弹出红色报错
		spawn_error_popup("RuntimeError: Career path access denied.")

func trigger_awakening_event():
	# 1. 世界静止
	Engine.time_scale = 0.05  # 极慢速
	
	# 2. 压抑的报错消失
	$CanvasLayer/ErrorPopupContainer.hide()
	
	# 3. 播放音效：类似于服务器启动的风扇声或电流声
	#AudioStreamPlayer.play("system_boot_up.wav")
	
	# 4. 弹出那个关键的系统提示（ICEY风格的打字机效果）
	var terminal = $CanvasLayer/SystemTerminal
	terminal.show()
	terminal.print_log("Scanning User Core...")
	await get_tree().create_timer(1.0).timeout
	terminal.print_log("Identity Confirmed: [Coder]")
	
	# 5. 关键选择
	# 这里不需要玩家按键，而是自动执行，代表你潜意识的觉醒
	terminal.print_log("Compiling Weapon: 'The Engine'...")
	
	# 6. 给玩家加 Buff
	$Player.add_buff("Only_Code") # 头顶出现代码光环
	
	# 7. 恢复时间，bgm 变奏
	Engine.time_scale = 1.0
