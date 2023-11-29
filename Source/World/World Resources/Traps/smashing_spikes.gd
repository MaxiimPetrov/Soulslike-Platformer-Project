extends StaticBody2D

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var recharge_timer = $RechargeTimer
@onready var animation_player = $AnimationPlayer
@onready var hitbox_small = $HitboxSmall
@onready var from_below_collision = $FromBelowCollision

@export var from_below = false
@export var recharge_timer_wait_time = 0.1

var recharge_timer_started = false

func _ready():
	if from_below:
		from_below_collision.get_node("CollisionShape2D").disabled = false
		animated_sprite_2d.flip_v = true
		hitbox_small.get_node("CollisionShape2D").position.y = -8
	else:
		hitbox_small.get_node("CollisionShape2D").position.y = -72
	recharge_timer.wait_time = recharge_timer_wait_time

func _process(_delta):
	if !recharge_timer_started:
		recharge_timer.start()
		recharge_timer_started = true
	if recharge_timer.time_left == 0 and recharge_timer_started:
		recharge_timer_started = false
		if !from_below:
			animation_player.play("SmashAbove")
		else:
			animation_player.play("SmashBelow")
