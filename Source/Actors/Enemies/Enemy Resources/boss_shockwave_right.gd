extends CharacterBody2D

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var marker_2d = $Marker2D

var speed = 350

func _physics_process(_delta):
	velocity.x = speed
	move_and_slide()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
