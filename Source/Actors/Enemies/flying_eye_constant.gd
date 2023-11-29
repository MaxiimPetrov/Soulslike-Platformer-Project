extends CharacterBody2D

func _ready():
	velocity.x = -235

func _physics_process(_delta):
	move_and_slide()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
