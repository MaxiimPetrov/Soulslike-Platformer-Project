extends CharacterBody2D

enum{WANDER, CHASE, ATTACK, RETURN, WAIT, DEATH}

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var actor_detection_zone_far = $ActorDetectionZoneFar
@onready var actor_detection_zone_close = $ActorDetectionZoneClose
@onready var skeleton_knight = $"."
@onready var animation_player = $AnimationPlayer
@onready var wander_wait_timer = $Timers/WanderWaitTimer
@onready var wander_walking_timer = $Timers/WanderWalkingTimer
@onready var attack_cooldown_timer = $Timers/AttackCooldownTimer
@onready var wait_state_timer = $Timers/WaitStateTimer
@onready var hurtbox_entered_timer = $Timers/HurtboxEnteredTimer
@onready var attack_hitbox = $AttackHitboxPivot/AttackHitbox
@onready var attack_hitbox_pivot = $AttackHitboxPivot
@onready var hitbox = $Hitbox
@onready var hurtbox = $Hurtbox
@onready var health_bar_timer = $Timers/HealthBarTimer
@onready var player_detected_timer = $Timers/PlayerDetectedTimer
@onready var wall_check_right = $Raycasts/WallCheckRight
@onready var wall_check_left = $Raycasts/WallCheckLeft
@onready var ledge_check_left = $Raycasts/LedgeCheckLeft
@onready var ledge_check_right = $Raycasts/LedgeCheckRight
@onready var ledge_check_bottom_right = $Raycasts/LedgeCheckBottomRight
@onready var ledge_check_bottom_left = $Raycasts/LedgeCheckBottomLeft
@onready var ledge_check_top_right = $Raycasts/LedgeCheckTopRight
@onready var ledge_check_top_left = $Raycasts/LedgeCheckTopLeft
@onready var health_bar_empty = $Health/HealthBarEmpty
@onready var healthbar_full = $Health/HealthbarFull
@onready var health_bar_empty_1 = $Health/HealthBarEmpty1
@onready var health_bar_empty_2 = $Health/HealthBarEmpty2

#Wander state variables
var player_position = Vector2.ZERO
var wander_wait_timer_started = false
var wander_walking_timer_started = false
var wander_direction = 1
var num_of_direction_changed = 0
var player_detected_timer_started = false

#Chase state variables
var player_to_the_left = false
var player_to_the_left_set = false
var reached_player_position = false

#Attack state variables
var attack_played = false
var attack_cooldown_timer_started = false
var attack_finished = false

#Return state variables
var direction_set = false
var walk_animation_played = false
var y_return_velocity_updated = false

#Wait state variables
var wait_state_timer_started = false

#Death state variables
var death_animation_played = false

#Other variables
var starting_position = Vector2.ZERO
var speed = 40
var gravity = 900
var state = WANDER
var rng = RandomNumberGenerator.new()
var health = 10
var y_velocity_updated = false
var health_bar_initial_size = 0
var hurtbox_entered_timer_started = false
var health_bar_timer_started = false
var pulse_effect_instance_added = false

func _ready():
	set_physics_process(false)
	health_bar_initial_size = healthbar_full.size.x
	attack_hitbox.get_node("CollisionShape2D").disabled = true
	var random_wait_timer_number = rng.randi_range(0,2)
	if random_wait_timer_number == 0:
		wander_wait_timer.wait_time = 3
	elif random_wait_timer_number == 1:
		wander_wait_timer.wait_time = 4
	else:
		wander_wait_timer.wait_time = 5
	animated_sprite_2d.play("Idle")
	starting_position = skeleton_knight.global_position
	wander_wait_timer.start()
	wander_wait_timer_started = true

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
		WANDER:
			wander_state(delta)
		CHASE:
			chase_state(delta)
		ATTACK:
			attack_state()
		RETURN:
			return_state(delta)
		WAIT:
			wait_state()
		DEATH:
			death_state(delta)

#Wander state functions-------------------------------------------------------------------------------
func wander_state(delta):
	apply_gravity(delta)
	
	if velocity.x == 0:
		animated_sprite_2d.play("Idle")
	
	if !actor_detection_zone_far.can_see_player() and !actor_detection_zone_close.can_see_player():
		if wander_wait_timer.time_left == 0 and wander_wait_timer_started:
			wander_wait_timer_started = false
			velocity.x = speed * wander_direction
			animated_sprite_2d.flip_h = velocity.x < 0
			adjust_sprite_position()
			num_of_direction_changed += 1
			if num_of_direction_changed % 2 != 0:
				wander_direction *= -1
			wander_walking_timer.start()
			wander_walking_timer_started = true
		
		if wander_walking_timer_started:
			jump()
			check_for_ledge()
		
		if wander_walking_timer.time_left == 0 and wander_walking_timer_started and is_on_floor():
			wander_walking_timer_started = false
			velocity.x = 0
			wander_wait_timer.start()
			wander_wait_timer_started = true
	elif is_on_floor():
		if actor_detection_zone_close.can_see_player():
			entering_attack_state()
			state = ATTACK
		if actor_detection_zone_far.can_see_player():
			velocity.x = 0
			if not player_detected_timer_started:
				player_detected_timer.start()
				player_detected_timer_started = true
			if player_detected_timer.time_left == 0 and player_detected_timer_started:
				entering_chase_state()
				state = CHASE
			
			animated_sprite_2d.play("Idle")
			player_position.x = roundf(GameData.player_position.x)
			player_position.y = roundf(GameData.player_position.y)
			if skeleton_knight.global_position.x > player_position.x:
				animated_sprite_2d.flip_h = true
				adjust_sprite_position()
			else:
				animated_sprite_2d.flip_h = false
				adjust_sprite_position()
			
			if not pulse_effect_instance_added:
				var world = get_tree().current_scene
				var pulse_effect_1 = load("res://Source/Effects/enemy_pulse_effect.tscn")
				var pulse_effect_2 = load("res://Source/Effects/enemy_pulse_effect.tscn")
				var pulse_effect_1_instance = pulse_effect_1.instantiate()
				var pulse_effect_2_instance = pulse_effect_2.instantiate()
				pulse_effect_2_instance.left = true
				world.add_child(pulse_effect_1_instance)
				world.add_child(pulse_effect_2_instance)
				if !animated_sprite_2d.flip_h:
					pulse_effect_1_instance.global_position.x = skeleton_knight.global_position.x + 15
					pulse_effect_1_instance.global_position.y = skeleton_knight.global_position.y - 43
					pulse_effect_2_instance.global_position.x = skeleton_knight.global_position.x - 5
					pulse_effect_2_instance.global_position.y = skeleton_knight.global_position.y - 43
				else:
					pulse_effect_1_instance.global_position.x = skeleton_knight.global_position.x + 5
					pulse_effect_1_instance.global_position.y = skeleton_knight.global_position.y - 43
					pulse_effect_2_instance.global_position.x = skeleton_knight.global_position.x - 15
					pulse_effect_2_instance.global_position.y = skeleton_knight.global_position.y - 43
				pulse_effect_instance_added = true
	
	if player_detected_timer.time_left == 0 and player_detected_timer_started and !actor_detection_zone_far.can_see_player():
		pulse_effect_instance_added = false
		player_detected_timer_started = false
	
	var x_velocity_before_collision = velocity.x
	move_and_slide()
	velocity.x = x_velocity_before_collision
	
	reset_y_velocity_updated()

func entering_wander_state():
	pulse_effect_instance_added = false
	player_position = Vector2.ZERO
	wander_wait_timer_started = true
	wander_wait_timer.start()
	wander_walking_timer_started = false
	wander_direction = 1
	num_of_direction_changed = 0
	player_detected_timer_started = false

#Chase state_functions------------------------------------------------------------------------------
func chase_state(delta):
	if actor_detection_zone_close.can_see_player() and is_on_floor():
		entering_attack_state()
		state = ATTACK
	else:
		apply_gravity(delta)
		if not player_to_the_left_set:
			if skeleton_knight.global_position.x > player_position.x:
				player_to_the_left = true
			elif skeleton_knight.global_position.x < player_position.x:
				player_to_the_left = false
			player_to_the_left_set = true
		
		if player_to_the_left:
			if skeleton_knight.global_position.x > player_position.x + 20:
				velocity.x = -speed
			else:
				reached_player_position = true
				if is_on_floor():
					velocity.x = 0
		else:
			if skeleton_knight.global_position.x < player_position.x - 20:
				velocity.x = speed
			else:
				reached_player_position = true
				if is_on_floor():
					velocity.x = 0
		
		if reached_player_position and is_on_floor():
			if actor_detection_zone_far.can_see_player() and !ledge_check_top_right.is_colliding() and !ledge_check_top_left.is_colliding():
				entering_chase_state()
				player_position.x = roundf(GameData.player_position.x)
				player_position.y = roundf(GameData.player_position.y)
				state = CHASE
			else:
				state = WAIT
		else:
			jump()
			check_for_ledge()
			animated_sprite_2d.flip_h = velocity.x < 0
			adjust_sprite_position()
		
		var x_velocity_before_collision = velocity.x
		move_and_slide()
		velocity.x = x_velocity_before_collision
		
		reset_y_velocity_updated()

func entering_chase_state():
	player_to_the_left = false
	player_to_the_left_set = false
	reached_player_position = false

#Attack state functions-----------------------------------------------------------------------------
func attack_state():
	velocity.x = 0
	if animated_sprite_2d.flip_h:
		attack_hitbox_pivot.scale.x = -1
	else:
		attack_hitbox_pivot.scale.x = 1

	if not attack_played:
		if skeleton_knight.global_position.x > GameData.player_position.x:
			animated_sprite_2d.flip_h = true
			adjust_sprite_position()
		else:
			animated_sprite_2d.flip_h = false
			adjust_sprite_position()
		animation_player.play("Attack")
		attack_played = true
		attack_cooldown_timer.start()
		attack_cooldown_timer_started = true
	
	if attack_finished:
		if attack_cooldown_timer.time_left == 0 and attack_cooldown_timer_started:
			attack_played = false
			attack_cooldown_timer_started = false
			if actor_detection_zone_close.can_see_player():
				entering_attack_state()
				state = ATTACK
			elif actor_detection_zone_far.can_see_player() and not actor_detection_zone_close.can_see_player():
				player_position.x = roundf(GameData.player_position.x)
				player_position.y = roundf(GameData.player_position.y)
				entering_chase_state()
				state = CHASE
			else:
				entering_return_state()
				state = RETURN

func end_attack():
	animated_sprite_2d.play("Idle")
	attack_finished = true

func entering_attack_state():
	attack_played = false
	attack_cooldown_timer_started = false
	attack_finished = false

#Return state functions-----------------------------------------------------------------------------
func return_state(delta):
	if skeleton_knight.global_position.x > starting_position.x:
			animated_sprite_2d.flip_h = true
	else:
		animated_sprite_2d.flip_h = false
	adjust_sprite_position()
	apply_gravity(delta)
	
	if not direction_set:
		if skeleton_knight.global_position.x < starting_position.x:
			velocity.x = speed
		else:
			velocity.x = -speed
		direction_set = true
	
	if direction_set:
		if velocity.x >= 0 and skeleton_knight.global_position.x > starting_position.x - 2:
			entering_wander_state()
			velocity.x = 0
			state = WANDER
		elif velocity.x <= 0 and skeleton_knight.global_position.x < starting_position.x + 2:
			entering_wander_state()
			velocity.x = 0
			state = WANDER
		jump()
	
	if actor_detection_zone_close.can_see_player() and is_on_floor():
		entering_attack_state()
		state = ATTACK
	var x_velocity_before_collision = velocity.x
	move_and_slide()
	velocity.x = x_velocity_before_collision
	reset_y_velocity_updated()

func entering_return_state():
	walk_animation_played = false
	direction_set = false

#Wait state functions-------------------------------------------------------------------------------
func wait_state():
	if not wait_state_timer_started:
		wait_state_timer.start()
		wait_state_timer_started = true
		animated_sprite_2d.play("Idle")
	if actor_detection_zone_close.can_see_player():
		wait_state_timer_started = false
		entering_attack_state()
		state = ATTACK
	if wait_state_timer.time_left == 0 and wait_state_timer_started:
		wait_state_timer_started = false
		entering_return_state()
		state = RETURN

#Death state functions------------------------------------------------------------------------------
func death_state(delta):
	apply_gravity(delta)
	health_bar_empty.visible = false
	healthbar_full.visible = false
	health_bar_empty_1.visible = false
	health_bar_empty_2.visible = false
	hurtbox.get_node("CollisionShape2D").disabled = true
	hitbox.get_node("CollisionShape2D").disabled = true
	attack_hitbox.get_node("CollisionShape2D").disabled = true
	if not death_animation_played:
		SoundPlayer.play_enemy_death_sound()
		var world = get_tree().current_scene
		var death_effect = load("res://Source/Effects/enemy_death_effect.tscn")
		var death_effect_instance = death_effect.instantiate()
		world.add_child(death_effect_instance)
		death_effect_instance.global_position.x = skeleton_knight.global_position.x
		death_effect_instance.global_position.y = skeleton_knight.global_position.y - 30
		animation_player.play("Death")
		death_animation_played = true
	velocity.x = 0
	move_and_slide()

func death_queue_free():
	queue_free()

#Other functions------------------------------------------------------------------------------------
func apply_gravity(delta):
	velocity.y += gravity * delta

func adjust_sprite_position():
	#Depending on the sprites flip_h, chnages sprites x position to account for pivot point not being centered
	if animated_sprite_2d.flip_h:
		animated_sprite_2d.position.x = 4
	else:
		animated_sprite_2d.position.x = -4

func _on_hurtbox_area_entered(area):
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

func jump():
	if is_on_floor():
		if velocity.x < 0:
			animated_sprite_2d.play("Walk") 
			if wall_check_left.is_colliding() and !ledge_check_top_left.is_colliding() and !y_velocity_updated:
				velocity.y = -250
				animated_sprite_2d.play("Idle")
				y_velocity_updated = true
			elif wall_check_left.is_colliding() and ledge_check_top_left.is_colliding() and !y_velocity_updated:
				state = WAIT
		if velocity.x > 0:
			animated_sprite_2d.play("Walk") 
			if wall_check_right.is_colliding() and !ledge_check_top_right.is_colliding() and !y_velocity_updated:
				velocity.y = -250
				animated_sprite_2d.play("Idle")
				y_velocity_updated = true
			if wall_check_right.is_colliding() and ledge_check_top_right.is_colliding() and !y_velocity_updated:
				state = WAIT

func check_for_ledge():
	if is_on_floor():
		if velocity.x < 0:
			if !ledge_check_left.is_colliding() and !ledge_check_bottom_left.is_colliding():
				state = WAIT
		if velocity.x > 0:
			if !ledge_check_right.is_colliding() and !ledge_check_bottom_right.is_colliding():
				state = WAIT

func reset_y_velocity_updated():
	if is_on_floor():
		y_velocity_updated = false

func _on_visible_on_screen_notifier_2d_screen_entered():
	set_physics_process(true)

func _on_visible_on_screen_notifier_2dlarge_screen_exited():
	set_physics_process(false)
