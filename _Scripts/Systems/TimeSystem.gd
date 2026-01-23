extends Node

signal time_updated(week, day, slots)
signal period_ended # 半月结算信号

const MAX_SLOTS = 3 # 早/中/晚
const WEEKS_PER_SETTLEMENT = 2

var current_week: int = 1
var current_day: int = 1 # 1=周一, 7=周日
var time_slots: int = MAX_SLOTS

func initialize():
	# 强制发送一次信号，让 UI 收到初始的 "第1周 星期1"
	emit_signal("time_updated", current_week, current_day, time_slots)

# 消耗行动力
func consume_slot(amount: int = 1) -> bool:
	if time_slots >= amount:
		time_slots -= amount
		emit_signal("time_updated", current_week, current_day, time_slots)
		return true
	return false

# 睡觉 (恢复并推进到下一天)
func sleep_and_advance():
	time_slots = MAX_SLOTS
	_advance_day()

# 内部：日期推进
func _advance_day():
	current_day += 1
	if current_day > 7:
		current_day = 1
		current_week += 1
	
	print(">> [Time] 第 %d 周 - 星期 %d" % [current_week, current_day])
	emit_signal("time_updated", current_week, current_day, time_slots)
	
	# 检查半月结算 (奇数周的周一触发，比如第3周第1天结算前两周)
	# 结算逻辑解析：
	# current_week > 1：第1周不结算
	# (current_week - 1) % 2 == 0：
	#   当第3周第1天时 -> (3-1)%2 == 0 -> 触发 (结算第1-2周)
	#   当第5周第1天时 -> (5-1)%2 == 0 -> 触发 (结算第3-4周)
	if current_week > 1 and (current_week - 1) % WEEKS_PER_SETTLEMENT == 0 and current_day == 1:
		emit_signal("period_ended")
