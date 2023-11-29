extends CharacterBody2D

@onready var flip_velocity_timer = $FlipVelocityTimer
@onready var reactivate_hitbox_timer = $ReactivateHitboxTimer
@onready var hitbox = $Hitbox
@onready var actor_detection_zone = $ActorDetectionZone
@onready var animatd_sprite_2d = $AnimatedSprite2D

var flip_velocity_timer_started = true
var reactivate_hitbox_timer_started = false
var ready_to_collide_with_player = false

var speed = 175
var acceleration = 1000

var moving_left = false

func _ready():
	flip_velocity_timer.start()
	if GameData.player_facing_left:
		animatd_sprite_2d.flip_h = true
		moving_left = true

func _physics_process(delta):
	if moving_left:
		velocity.x = move_toward(velocity.x, -speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, speed, acceleration * delta)
	
	if flip_velocity_timer.time_left == 0 and flip_velocity_timer_started:
		moving_left = !moving_left
		ready_to_collide_with_player = true
		reactivate_hitbox_timer.start()
		hitbox.get_node("CollisionShape2D").disabled = true
		reactivate_hitbox_timer_started = true
		flip_velocity_timer_started = false
	
	if reactivate_hitbox_timer.time_left == 0 and reactivate_hitbox_timer_started:
		hitbox.get_node("CollisionShape2D").disabled = false
		reactivate_hitbox_timer_started = true
	
	if actor_detection_zone.can_see_player() and ready_to_collide_with_player:
		queue_free()
	
	move_and_slide()

func _on_visible_on_screen_notifier_2d_screen_exited():
	if ready_to_collide_with_player:
		queue_free()

func _on_sound_detection_area_entered(_area):
	SoundPlayer.play_player_attack_sound()
