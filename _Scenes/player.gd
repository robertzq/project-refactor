extends CharacterBody3D


# Player.gd
@onready var anim = $AnimationPlayer

func _physics_process(delta):
	# 移动逻辑...
	if velocity.length() > 0:
		anim.play("walk")
	else:
		anim.play("idle")
