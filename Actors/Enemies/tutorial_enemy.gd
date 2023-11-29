extends CharacterBody2D

@onready var hurtbox = $Hurtbox
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var timer = $Timer

var gravity = 900
var timer_started = false

func _physics_process(delta):
	if timer_started and timer.time_left == 0:
		animated_sprite_2d.self_modulate.r = 1
		animated_sprite_2d.self_modulate.g = 1
		animated_sprite_2d.self_modulate.b = 1
		timer_started = false
	velocity.y += gravity * delta
	move_and_slide()

func _on_hurtbox_area_entered(_area):
	animated_sprite_2d.self_modulate.r = 255
	animated_sprite_2d.self_modulate.g = 255
	animated_sprite_2d.self_modulate.b = 255
	timer_started = true
	timer.start()
