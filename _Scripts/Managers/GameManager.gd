extends Node

# 定义游戏状态的枚举
enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER
}

# 当前状态变量
var current_state: GameState = GameState.MENU

# 信号：当状态改变时发出通知，UI或其他组件可以监听这个信号
signal state_changed(new_state)

func _ready():
	print("GameManager initialized. Ready to Refactor!")
	# 初始化时，可以先不做操作，或者加载主菜单
	change_state(GameState.MENU)

# 改变状态的函数
func change_state(new_state: GameState):
	if current_state == new_state:
		return
	
	current_state = new_state
	emit_signal("state_changed", current_state)
	
	match current_state:
		GameState.MENU:
			print("State: MENU")
			# TODO: 暂停游戏逻辑，显示鼠标，显示菜单UI
		GameState.PLAYING:
			print("State: PLAYING")
			# TODO: 恢复游戏逻辑，隐藏鼠标
		GameState.PAUSED:
			print("State: PAUSED")
			# TODO: 暂停时间，显示暂停菜单
		GameState.GAME_OVER:
			print("State: GAME_OVER")
			# TODO: 停止一切逻辑，显示结算画面
