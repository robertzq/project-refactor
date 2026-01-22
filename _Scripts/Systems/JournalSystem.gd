extends Node

var logs: Array = []
var story_logs: Array = []

func record(type, val, desc):
	logs.append({"type": type, "val": val, "desc": desc})
	print(">> [Journal] %s: %s (%.1f)" % [type, desc, val])

func log_story(text):
	story_logs.append(text)

func clear():
	logs.clear()
	story_logs.clear()

func generate_report_data() -> Dictionary:
	return {"logs": logs.duplicate(), "stories": story_logs.duplicate()}