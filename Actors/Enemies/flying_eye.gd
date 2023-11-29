extends CharacterBody2D

enum {IDLE, CHASE, WAIT, RETURN, DEATH}

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var actor_detection_zone = $ActorDetectionZone
@onready var flying_eye_enemy = $"."
@onready var player_detected_timer = $Timers/PlayerDetectedTimer
@onready var chase_windup_timer = $Timers/ChaseWindupTimer
@onready var wait_timer = $Timers/WaitTimer
@onready var hurtbox_entered_timer = $Timers/HurtboxEnteredTimer
@onready var health_bar_timer = $Timers/HealthbarTimer
@onready var hitbox = $Hitbox
@onready var hitbox_2 = $Hitbox2
@onready var hurtbox = $Hurtbox
@onready var animation_player = $AnimationPlayer
@onready var world_collision = $WorldCollision
@onready var health_bar_empty = $Health/HealthBarEmpty
@onready var healthbar_full = $Health/HealthbarFull
@onready var health_bar_empty_1 = $Health/HealthBarEmpty1
@onready var health_bar_empty_2 = $Health/HealthBarEmpty2

#Idle state variables
var player_position = Vector2.ZERO
var pulse_effect_instance_added = false
var player_detected_timer_started = false

#Chase state variables
var chase_windup_timer_started = false
var player_to_the_left = false
var windup_finished = false

#Return state variables
var flip_h_decided = false

#Death state variables
var death_falling_played = false
var sprite_postition_adjusted = false
var death_effect_added = false

#Wait state variables
var wait_timer_started = false

#Other variables
var state = IDLE
var speed = 125
var return_speed = 35
var acceleration = 500
var starting_position = Vector2.ZERO
var health = 6
var hurtbox_entered_timer_started = false
var health_bar_timer_started = false
var health_bar_initial_size = 0
var gravity = 450

var rng = RandomNumberGenerator.new()

func _ready():
	set_physics_process(false)
	world_collision.disabled = true
	health_bar_initial_size = healthbar_full.size.x
	starting_position = flying_eye_enemy.global_position
	animated_sprite_2d.play("Idle")
	var random_flip_h = rng.randi_range(0,1)
	if random_flip_h == 0:
		animated_sprite_2d.flip_h = true
	else:
		animated_sprite_2d.flip_h = false

func _physics_process(delta):
	adjust_sprite_position()
	if hurtbox_entered_timer.time_left == 0 and hurtbox_entered_timer_started:
		animated_sprite_2d.self_modulate.r = 1
		animated_sprite_2d.self_modulate.g = 1
		animated_sprite_2d.self_modulate.b = 1
		hurtbox_entered_timer_started = false
	if health_bar_timer.time_left == 0 and health_bar_timer_started:
		health_bar_empty.visible = false
		healthbar_full.visible = false
		health_bar_empty_1.visible = false
		health_bar_empty_2.visible = false
		health_bar_timer_started = false
	match state:
		IDLE:
			idle_state()
		CHASE:
			chase_state(delta)
		WAIT:
			wait_state()
		RETURN:
			return_state(delta)
		DEATH:
			death_state(delta)

#Idle state functions-------------------------------------------------------------------------------
func idle_state():
	velocity.x = 0
	velocity.y = 0
	if actor_detection_zone.can_see_player():
		if flying_eye_enemy.global_position.x > GameData.player_position.x:
			animated_sprite_2d.flip_h = true
		else:
			animated_sprite_2d.flip_h = false
		
		if !player_detected_timer_started:
			player_detected_timer.start()
			player_detected_timer_started = true
		
		if not pulse_effect_instance_added:
			var world = get_tree().current_scene
			var pulse_effect_1 = load("res://Source/Effects/enemy_pulse_effect.tscn")
			var pulse_effect_2 = load("res://Source/Effects/enemy_pulse_effect.tscn")
			var pulse_effect_1_instance = pulse_effect_1.instantiate()
			var pulse_effect_2_instance = pulse_effect_2.instantiate()
			pulse_effect_2_instance.left = true
			world.add_child(pulse_effect_1_instance)
			world.add_child(pulse_effect_2_instance)
			pulse_effect_1_instance.global_position.x = flying_eye_enemy.global_position.x + 15
			pulse_effect_1_instance.global_position.y = flying_eye_enemy.global_position.y
			pulse_effect_2_instance.global_position.x = flying_eye_enemy.global_position.x -15
			pulse_effect_2_instance.global_position.y = flying_eye_enemy.global_position.y
			pulse_effect_instance_added = true
		
	if player_detected_timer.time_left == 0 and player_detected_timer_started:
		player_detected_timer_started = false
		pulse_effect_instance_added = false
		if actor_detection_zone.can_see_player():
			player_position.x = roundf(GameData.player_position.x)
			player_position.y = roundf(GameData.player_position.y)
			state = CHASE
	
	move_and_slide()

#Chase state functions------------------------------------------------------------------------------
func chase_state(delta):
	actor_detection_zone.scale.x = 1.5
	actor_detection_zone.scale.y = 1.5
	
	if flying_eye_enemy.global_position.x > player_position.x:
		player_to_the_left = true
	
	if not windup_finished:
		if player_to_the_left:
			animated_sprite_2d.flip_h = true
			adjust_sprite_position()
			velocity.x = move_toward(velocity.x, 20, acceleration * delta)
			if not chase_windup_timer_started:
				chase_windup_timer.start()
				chase_windup_timer_started = true
		else:
			animated_sprite_2d.flip_h = false
			adjust_sprite_position()
			velocity.x = move_toward(velocity.x, -20, acceleration * delta)
			if not chase_windup_timer_started:
				chase_windup_timer.start()
				chase_windup_timer_started = true
	
	if chase_windup_timer.time_left == 0 and chase_windup_timer_started:
		velocity.x = 0
		player_position.x = roundf(GameData.player_position.x)
		player_position.y = roundf(GameData.player_position.y)
		if player_to_the_left:
			player_position.x -= 40
		else:
			player_position.x += 40
		player_position.y -= 30
		chase_windup_timer_started = false
		windup_finished = true
	
	if windup_finished:
		flying_eye_enemy.global_position = flying_eye_enemy.global_position.move_toward(player_position, speed * delta)
		if flying_eye_enemy.global_position == player_position:
			chase_windup_timer_started = false
			player_to_the_left = false
			windup_finished = false
			state = WAIT
	
	move_and_slide()

#Wait state functions-------------------------------------------------------------------------------
func wait_state():
	if not wait_timer_started:
		wait_timer.start()
		wait_timer_started = true
	
	if wait_timer.time_left == 0 and wait_timer_started:
		if actor_detection_zone.can_see_player():
			if flying_eye_enemy.global_position.x > GameData.player_position.x:
				animated_sprite_2d.flip_h = true
			else:
				animated_sprite_2d.flip_h = false
			
			if !player_detected_timer_started:
				player_detected_timer.start()
				player_detected_timer_started = true
			
			if not pulse_effect_instance_added:
				var world = get_tree().current_scene
				var pulse_effect_1 = load("res://Source/Effects/enemy_pulse_effect.tscn")
				var pulse_effect_2 = load("res://Source/Effects/enemy_pulse_effect.tscn")
				var pulse_effect_1_instance = pulse_effect_1.instantiate()
				var pulse_effect_2_instance = pulse_effect_2.instantiate()
				pulse_effect_2_instance.left = true
				world.add_child(pulse_effect_1_instance)
				world.add_child(pulse_effect_2_instance)
				pulse_effect_1_instance.global_position.x = flying_eye_enemy.global_position.x + 15
				pulse_effect_1_instance.global_position.y = flying_eye_enemy.global_position.y
				pulse_effect_2_instance.global_position.x = flying_eye_enemy.global_position.x -15
				pulse_effect_2_instance.global_position.y = flying_eye_enemy.global_position.y
				pulse_effect_instance_added = true
		else:
			player_detected_timer_started = false
			pulse_effect_instance_added = false
			wait_timer_started = false
			state = RETURN
		
		if player_detected_timer.time_left == 0 and player_detected_timer_started:
			player_detected_timer_started = false
			pulse_effect_instance_added = false
			wait_timer_started = false
			if actor_detection_zone.can_see_player():
				player_position.x = roundf(GameData.player_position.x)
				player_position.y = roundf(GameData.player_position.y)
				state = CHASE

#Return state functions-----------------------------------------------------------------------------
func return_state(delta):
	actor_detection_zone.scale.x = 1
	actor_detection_zone.scale.y = 1
	
	if !actor_detection_zone.can_see_player():
		flying_eye_enemy.global_position = flying_eye_enemy.global_position.move_toward(starting_position, return_speed * delta)
	
	if actor_detection_zone.can_see_player():
		if flying_eye_enemy.global_position.x > GameData.player_position.x:
			animated_sprite_2d.flip_h = true
		else:
			animated_sprite_2d.flip_h = false
			
		if !player_detected_timer_started:
			player_detected_timer.start()
			player_detected_timer_started = true
			
		if not pulse_effect_instance_added:
			var world = get_tree().current_scene
			var pulse_effect_1 = load("res://Source/Effects/enemy_pulse_effect.tscn")
			var pulse_effect_2 = load("res://Source/Effects/enemy_pulse_effect.tscn")
			var pulse_effect_1_instance = pulse_effect_1.instantiate()
			var pulse_effect_2_instance = pulse_effect_2.instantiate()
			pulse_effect_2_instance.left = true
			world.add_child(pulse_effect_1_instance)
			world.add_child(pulse_effect_2_instance)
			pulse_effect_1_instance.global_position.x = flying_eye_enemy.global_position.x + 15
			pulse_effect_1_instance.global_position.y = flying_eye_enemy.global_position.y
			pulse_effect_2_instance.global_position.x = flying_eye_enemy.global_position.x -15
			pulse_effect_2_instance.global_position.y = flying_eye_enemy.global_position.y
			pulse_effect_instance_added = true
	
	if player_detected_timer.time_left == 0 and player_detected_timer_started:
		player_detected_timer_started = false
		pulse_effect_instance_added = false
		flip_h_decided = false
		if actor_detection_zone.can_see_player():
			player_position.x = roundf(GameData.player_position.x)
			player_position.y = roundf(GameData.player_position.y)
			state = CHASE
		else:
			state = RETURN
	
	if !flip_h_decided:
		if flying_eye_enemy.global_position.x < starting_position.x:
			animated_sprite_2d.flip_h = false
		else:
			animated_sprite_2d.flip_h = true
		flip_h_decided = true
	
	if flying_eye_enemy.global_position == starting_position:
		flip_h_decided = false
		state = IDLE

#Death state functions------------------------------------------------------------------------------
func death_state(delta):
	if !sprite_postition_adjusted:
		animated_sprite_2d.position.y -= 13
		sprite_postition_adjusted = true
	velocity.x = 0
	world_collision.disabled = false
	health_bar_empty.visible = false
	healthbar_full.visible = false
	health_bar_empty_1.visible = false
	health_bar_empty_2.visible = false
	apply_gravity(delta)
	hitbox.get_node("CollisionShape2D").disabled = true
	hitbox_2.get_node("CollisionShape2D").disabled = true
	hurtbox.get_node("CollisionShape2D").disabled = true
	
	if not death_effect_added:
		SoundPlayer.play_enemy_death_sound()
		var world = get_tree().current_scene
		var death_effect = load("res://Source/Effects/enemy_death_effect.tscn")
		var death_effect_instance = death_effect.instantiate()
		world.add_child(death_effect_instance)
		death_effect_instance.get_node("AnimatedSprite2D").scale.x = 0.35
		death_effect_instance.get_node("AnimatedSprite2D").scale.y = 0.35
		death_effect_instance.global_position.x = flying_eye_enemy.global_position.x
		death_effect_instance.global_position.y = flying_eye_enemy.global_position.y - 5
		death_effect_added = true
	
	if not death_falling_played:
		animated_sprite_2d.play("DeathFalling")
		death_falling_played = true
	
	if is_on_floor():
		animation_player.play("Death (Ground)")
	
	move_and_slide()

func death_queue_free():
	queue_free()

#Other functions------------------------------------------------------------------------------------
func adjust_sprite_position():
	if animated_sprite_2d.flip_h:
		animated_sprite_2d.position.x = 5
	else:
		animated_sprite_2d.position.x = -5

func _on_hurtbox_area_entered(area):
	health_bar_timer.start()
	health_bar_timer_started = true
	health_bar_empty.visible = true
	healthbar_full.visible = true
	health_bar_empty_1.visible = true
	health_bar_empty_2.visible = true
	health -= area.damage
	healthbar_full.size.x = (health_bar_initial_size / 6) * health
	hurtbox_entered_timer.start()
	hurtbox_entered_timer_started = true
	if health <= 0:
		state = DEATH
	else:
		animated_sprite_2d.self_modulate.r = 255
		animated_sprite_2d.self_modulate.g = 255
		animated_sprite_2d.self_modulate.b = 255

func apply_gravity(delta):
	velocity.y += gravity * delta

func _on_visible_on_screen_notifier_2d_screen_entered():
	set_physics_process(true)

func _on_visible_on_screen_notifier_2dlarge_screen_exited():
	set_physics_process(false)
