extends CharacterBody2D

enum{IDLE, EXPOSE, ATTACKSTART, ATTACKEND, WAIT, WANDER, DEATH}

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var actor_detection_zone = $ActorDetectionZone
@onready var mimic = $"."
@onready var label = $Label
@onready var animation_player = $AnimationPlayer
@onready var actor_detection_zone_attack = $ActorDetectionZoneAttack
@onready var hurtbox = $Hurtbox
@onready var wait_timer = $Timers/WaitTimer
@onready var standing_timer = $Timers/StandingTimer
@onready var walking_timer = $Timers/WalkingTimer
@onready var health_bar_empty = $Health/HealthBarEmpty
@onready var healthbar_full = $Health/HealthbarFull
@onready var health_bar_empty_1 = $Health/HealthBarEmpty1
@onready var health_bar_empty_2 = $Health/HealthBarEmpty2
@onready var health_bar_timer = $Timers/HealthBarTimer
@onready var hurtbox_entered_timer = $Timers/HurtboxEnteredTimer
@onready var hitbox = $Hitbox
@onready var wall_check_right = $WallCheckRight
@onready var wall_check_left = $WallCheckLeft

@export var facing_right = false

#Attack Start state variables
var player_position = Vector2.ZERO
var flip_h_adjusted = false
var player_to_the_left = false

#Attack End state variables
var attack_end_animation_played = false
var velocity_stopeed = false

#Wait state variables
var wait_timer_started = false

#Wander state variables
var standing_timer_started = false
var walking_timer_started = false
var wander_direction = 1
var num_of_direction_changed = 0

#Death state variables
var death_animation_played = false

#Other variables
var initial_direction_set = false
var state = IDLE
var attack_speed = 125
var idle_speed = 25
var acceleration = 750
var activated = false
var gravity = 900
var health = 10
var health_bar_timer_started = false
var hurtbox_entered_timer_started = false
var health_bar_initial_size = 0

func _ready():
	set_physics_process(false)

func _physics_process(delta):
	if health_bar_timer.time_left == 0 and health_bar_timer_started:
		health_bar_empty.visible = false
		healthbar_full.visible = false
		health_bar_empty_1.visible = false
		health_bar_empty_2.visible = false
		health_bar_timer_started = false
	if hurtbox_entered_timer.time_left == 0 and hurtbox_entered_timer_started:
		animated_sprite_2d.self_modulate.r = 1
		animated_sprite_2d.self_modulate.g = 1
		animated_sprite_2d.self_modulate.b = 1
		hurtbox_entered_timer_started = false
	match state:
		IDLE:
			idle_state()
		EXPOSE:
			expose_state()
		ATTACKSTART:
			attackstart_state()
		ATTACKEND:
			attackend_state(delta)
		WAIT:
			wait_state(delta)
		WANDER:
			wander_state(delta)
		DEATH:
			death_state(delta)

#Idle state functions-------------------------------------------------------------------------------
func idle_state():
	if !initial_direction_set:
		if !facing_right:
			animated_sprite_2d.flip_h = true
		adjust_sprite_position()
		health_bar_initial_size = healthbar_full.size.x
		hitbox.get_node("CollisionShape2D").disabled = true
		initial_direction_set = true
	
	if actor_detection_zone.can_see_player():
		label.visible = true
	else:
		label.visible = false
	
	if actor_detection_zone.can_see_player() and Input.is_action_just_pressed("Interact"):
		label.visible = false
		state = EXPOSE

#Expose state functions-----------------------------------------------------------------------------
func expose_state():
	label.visible = false
	activated = true
	animated_sprite_2d.play("Expose")
	await animated_sprite_2d.animation_finished
	entering_attackstart_state()
	state = ATTACKSTART

#AttackStart state functions------------------------------------------------------------------------
func attackstart_state():
	if !flip_h_adjusted:
		player_position.x = roundf(GameData.player_position.x)
		player_position.y = roundf(GameData.player_position.y)
		hitbox.get_node("CollisionShape2D").disabled = false
		if mimic.global_position.x > player_position.x:
			player_to_the_left = true
			animated_sprite_2d.flip_h = true
		else:
			animated_sprite_2d.flip_h = false
		adjust_sprite_position()
		flip_h_adjusted = true
	animated_sprite_2d.play("Attack(Start)")
	await animated_sprite_2d.animation_finished
	entering_attackend_state()
	if state != DEATH:
		state = ATTACKEND

func entering_attackstart_state():
	flip_h_adjusted = false
	player_to_the_left = false

#AttackEnd state functions--------------------------------------------------------------------------
func attackend_state(delta):
	apply_gravity(delta)
	if !attack_end_animation_played:
		animation_player.play("AttackEnd")
		attack_end_animation_played = true
	
	if !velocity_stopeed:
		if player_to_the_left:
			velocity.x = move_toward(velocity.x, -attack_speed, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, attack_speed, acceleration * delta)
	
	move_and_slide()

func entering_attackend_state():
	attack_end_animation_played = false
	velocity_stopeed = false

func stop_velocity():
	velocity.x = 0
	velocity_stopeed = true

func leave_attackend_state():
	entering_wait_state()
	state = WAIT

#Wait state functions-----------------------------------------------------------------------------
func wait_state(delta):
	apply_gravity(delta)
	velocity.x = 0
	animated_sprite_2d.play("ActivatedIdle")
	
	if !wait_timer_started:
		wait_timer.start()
		wait_timer_started = true
	
	if wait_timer.time_left == 0 and wait_timer_started and state != DEATH:
		if actor_detection_zone_attack.can_see_player():
			entering_attackstart_state()
			state = ATTACKSTART
		else:
			entering_wander_state()
			state = WANDER
	
	move_and_slide()

func entering_wait_state():
	wait_timer_started = false

#Wander state functions-----------------------------------------------------------------------------
func wander_state(delta):
	apply_gravity(delta)
	
	if actor_detection_zone_attack.can_see_player() and state != DEATH:
		entering_attackstart_state()
		state = ATTACKSTART
	
	if !standing_timer_started:
		animated_sprite_2d.play("ActivatedIdle")
		standing_timer.start()
		standing_timer_started = true
		velocity.x = 0
	
	if standing_timer.time_left == 0 and standing_timer_started:
		if !walking_timer_started:
			walking_timer.start()
			walking_timer_started = true
			velocity.x = idle_speed * wander_direction
			animated_sprite_2d.play("Crawl")
			animated_sprite_2d.flip_h = velocity.x < 0
			adjust_sprite_position()
			num_of_direction_changed += 1
			if num_of_direction_changed % 2 != 0:
				wander_direction *= -1
	
	if walking_timer.time_left == 0 and walking_timer_started:
		standing_timer_started = false
		walking_timer_started = false
	
	if velocity.x > 0:
		if wall_check_right.is_colliding():
			velocity.x = 0
			animated_sprite_2d.play("ActivatedIdle")
	else:
		if wall_check_left.is_colliding():
			velocity.x = 0
			animated_sprite_2d.play("ActivatedIdle")
	
	move_and_slide()

func entering_wander_state():
	standing_timer_started = false
	walking_timer_started = false

#Death state functions------------------------------------------------------------------------------
func death_state(delta):
	apply_gravity(delta)
	velocity.x = 0
	hitbox.get_node("CollisionShape2D").disabled = true
	hurtbox.get_node("CollisionShape2D").disabled = true
	health_bar_empty.visible = false
	healthbar_full.visible = false
	health_bar_empty_1.visible = false
	health_bar_empty_2.visible = false
	if !death_animation_played:
		SoundPlayer.play_enemy_death_sound()
		animation_player.play("Death")
		var world = get_tree().current_scene
		var death_effect = load("res://Source/Effects/enemy_death_effect.tscn")
		var death_effect_instance = death_effect.instantiate()
		world.add_child(death_effect_instance)
		death_effect_instance.global_position.x = mimic.global_position.x
		death_effect_instance.global_position.y = mimic.global_position.y - 10
		var coin_collectible = load("res://Source/World/World Resources/Collectibles/coin_collectible.tscn")
		var coin_collectible_instance = coin_collectible.instantiate()
		world.add_child(coin_collectible_instance)
		coin_collectible_instance.global_position.x = mimic.global_position.x
		coin_collectible_instance.global_position.y = mimic.global_position.y - 5
		animation_player.play("Death")
		death_animation_played = true
	
	move_and_slide()

func death_queue_free():
	queue_free()

#Other functions------------------------------------------------------------------------------------
func set_initial_direction():
	if !initial_direction_set:
		if !facing_right:
			animated_sprite_2d.flip_h = true
		else:
			animated_sprite_2d.flip_h = false
		adjust_sprite_position()
		initial_direction_set = true

func adjust_sprite_position():
	if animated_sprite_2d.flip_h == true:
		animated_sprite_2d.position.x = -1
	else:
		animated_sprite_2d.position.x = 1

func apply_gravity(delta):
	velocity.y += gravity * delta

func _on_hurtbox_area_entered(area):
	if !activated:
		state = ATTACKSTART
		label.visible = false
		activated = true
	health_bar_timer.start()
	health_bar_timer_started = true
	health_bar_empty.visible = true
	healthbar_full.visible = true
	health_bar_empty_1.visible = true
	health_bar_empty_2.visible = true
	animated_sprite_2d.self_modulate.r = 255
	animated_sprite_2d.self_modulate.g = 255
	animated_sprite_2d.self_modulate.b = 255
	hurtbox_entered_timer.start()
	hurtbox_entered_timer_started = true
	health -= area.damage
	healthbar_full.size.x = (health_bar_initial_size / 10) * health
	if health <= 0:
		state = DEATH

func _on_visible_on_screen_notifier_2d_screen_entered():
	set_physics_process(true)

func _on_visible_on_screen_notifier_2dlarge_screen_exited():
	set_physics_process(false)
