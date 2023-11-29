extends StaticBody2D

enum{IDLE, STARTUP, ACTIVATE, DEATIVATE}

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var recharge_timer = $RechargeTimer
@onready var collision_shape_2d = $CollisionShape2D
@onready var hitbox = $Hitbox
@onready var activated_timer = $ActivatedTimer

@export var always_on = false
@export var recharge_timer_wait_time = 0.1
@export var from_above = false
@export var activated_timer_wait_time = 0.1

var recharge_timer_started = false
var activated_timer_started = false
var activated_animation_played = false
var state = IDLE

func _ready():
	if from_above:
		animated_sprite_2d.flip_v = true
		collision_shape_2d.position.y = -60.5
	if always_on:
		animated_sprite_2d.play("Activated")
		hitbox.get_node("CollisionShape2D").disabled = false
	recharge_timer.wait_time = recharge_timer_wait_time
	activated_timer.wait_time = activated_timer_wait_time

func _process(_delta):
	if !always_on:
		match state:
			IDLE:
				idle_state()
			STARTUP:
				startup_state()
			ACTIVATE:
				activate_state()
			DEATIVATE:
				deactivate_state()

func idle_state():
	animated_sprite_2d.play("Idle")
	if !recharge_timer_started:
		recharge_timer.start()
		recharge_timer_started = true
	
	if recharge_timer.time_left == 0 and recharge_timer_started:
		recharge_timer_started = false
		state = STARTUP

func startup_state():
	animated_sprite_2d.play("Startup")
	await animated_sprite_2d.animation_finished
	state = ACTIVATE

func activate_state():
	if !activated_animation_played:
		animated_sprite_2d.play("Activated")
		hitbox.get_node("CollisionShape2D").disabled = false
		activated_animation_played = true
		activated_timer.start()
		activated_timer_started = true
		
	if activated_timer.time_left == 0 and activated_timer_started:
		activated_animation_played = false
		activated_timer_started = false
		state = DEATIVATE

func deactivate_state():
	hitbox.get_node("CollisionShape2D").disabled = true
	animated_sprite_2d.play("Deactivate")
	await animated_sprite_2d.animation_finished
	state = IDLE
