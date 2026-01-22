extends Node

signal time_updated(week, day, slots)
signal period_ended # 半月结算信号

const MAX_SLOTS = 3 # 早/中/晚
const WEEKS_PER_SETTLEMENT = 2

var current_week: int = 1
var current_day: int = 1 # 1=周一, 7=周日
var time_slots: int = MAX_SLOTS

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
	if current_week > 1 and (current_week - 1) % WEEKS_PER_SETTLEMENT == 0 and current_day == 1:
		emit_signal("period_ended")