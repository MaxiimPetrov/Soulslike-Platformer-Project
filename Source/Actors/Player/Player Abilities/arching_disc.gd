extends CharacterBody2D

@onready var animated_sprite_2d = $AnimatedSprite2D

var speed = 100
var gravity = 600
var y_velocity_cap = 800
var not_on_screen = false

func _ready():
	if GameData.player_facing_left:
		velocity.x = -speed
		animated_sprite_2d.flip_h = true
	else:
		velocity.x = speed
		animated_sprite_2d.flip_h = false
	velocity.y = -325

func _physics_process(delta):
	if not_on_screen and velocity.y == y_velocity_cap:
		queue_free()
	velocity.y += gravity * delta
	if velocity.y > y_velocity_cap:
		velocity.y = y_velocity_cap
	move_and_slide()

func _on_visible_on_screen_notifier_2d_screen_exited():
	not_on_screen = true

func _on_hitbox_area_entered(_area):
	SoundPlayer.play_player_attack_sound()
