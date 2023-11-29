extends CharacterBody2D

enum {WANDER, CHASE, SLOWDOWN, WAIT, DEATH}

@onready var wander_wait_timer = $Timers/WanderWaitTimer
@onready var wander_walk_timer = $Timers/WanderWalkTimer
@onready var actor_detection_zone = $ActorDetectionZone
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var player_detected_timer = $Timers/PlayerDetectedTimer
@onready var mushroom_enemy = $"."
@onready var chase_timer = $Timers/ChaseTimer
@onready var hitbox = $Hitbox
@onready var wait_timer = $Timers/WaitTimer
@onready var poof_effect_timer = $Timers/PoofEffectTimer
@onready var hurtbox_entered_timer = $Timers/HurtboxEnteredTimer
@onready var health_bar_timer = $Timers/HealthBarTimer
@onready var hurtbox = $Hurtbox
@onready var ledge_check_right = $Raycasts/LedgeCheckRight
@onready var ledge_check_left = $Raycasts/LedgeCheckLeft
@onready var wall_check_right = $Raycasts/WallCheckRight
@onready var wall_check_left = $Raycasts/WallCheckLeft
@onready var health_bar_empty = $Health/HealthBarEmpty
@onready var healthbar_full = $Health/HealthbarFull
@onready var health_bar_empty_1 = $Health/HealthBarEmpty1
@onready var health_bar_empty_2 = $Health/HealthBarEmpty2

#Wander state variables
var wander_wait_timer_started = false
var wander_walk_timer_started = false
var wander_direction = 1
var num_of_direction_changed = 0
var player_detected_timer_started = false
var pulse_effect_instance_added = false

#Chase state variables
var player_to_the_left = false
var chase_timer_started = false

#Wait state variables
var wait_timer_started = false

#Death state variables
var death_animation_played = false

#Other variables
var wander_speed = 25
var chase_speed = 85
var state = WANDER
var gravity = 900
var acceleration = 60
var rng = RandomNumberGenerator.new()
var hurtbox_entered_timer_started = false
var health = 10
var health_bar_initial_size = 0
var health_bar_timer_started = false

func _ready():
	set_physics_process(false)
	health_bar_initial_size = healthbar_full.size.x
	var random_wait_timer_number = rng.randi_range(0,2)
	if random_wait_timer_number == 0:
		wander_wait_timer.wait_time = 3
	elif random_wait_timer_number == 1:
		wander_wait_timer.wait_time = 4
	else:
		wander_wait_timer.wait_time = 5
	
	animated_sprite_2d.play("Idle")
	wander_wait_timer.start()
	wander_wait_timer_started = true

func _physics_process(delta):
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
		WANDER:
			wander_state(delta)
		CHASE:
			chase_state(delta)
		SLOWDOWN:
			slowdown_state(delta)
		WAIT:
			wait_state()
		DEATH:
			death_state(delta)

#Wander state functions-----------------------------------------------------------------------------
func wander_state(delta):
	apply_gravity(delta)
	
	if !actor_detection_zone.can_see_player():
		if wander_wait_timer.time_left == 0 and wander_wait_timer_started:
			animation_player.play("RunSlow")
			wander_wait_timer_started = false
			wander_walk_timer.start()
			wander_walk_timer_started = true
			velocity.x = wander_speed * wander_direction
			num_of_direction_changed += 1
			if num_of_direction_changed % 2 != 0:
				wander_direction *= -1
			animated_sprite_2d.flip_h = velocity.x < 0
	else:
		animation_player.stop()
		animated_sprite_2d.play("Idle")
		if mushroom_enemy.global_position.x > GameData.player_position.x:
			player_to_the_left = true
			animated_sprite_2d.flip_h = true
		else:
			player_to_the_left = false
			animated_sprite_2d.flip_h = false
		if not pulse_effect_instance_added:
			var world = get_tree().current_scene
			var pulse_effect_1 = load("res://Source/Effects/enemy_pulse_effect.tscn")
			var pulse_effect_2 = load("res://Source/Effects/enemy_pulse_effect.tscn")
			var pulse_effect_1_instance = pulse_effect_1.instantiate()
			var pulse_effect_2_instance = pulse_effect_2.instantiate()
			pulse_effect_2_instance.left = true
			world.add_child(pulse_effect_1_instance)
			world.add_child(pulse_effect_2_instance)
			pulse_effect_1_instance.global_position.x = mushroom_enemy.global_position.x + 10
			pulse_effect_1_instance.global_position.y = mushroom_enemy.global_position.y - 20
			pulse_effect_2_instance.global_position.x = mushroom_enemy.global_position.x - 10
			pulse_effect_2_instance.global_position.y = mushroom_enemy.global_position.y - 20
			pulse_effect_instance_added = true
		
		velocity.x = 0
		if not player_detected_timer_started:
			player_detected_timer.start()
			player_detected_timer_started = true
		if player_detected_timer.time_left == 0 and player_detected_timer_started:
			state = CHASE
	
	
	if wander_walk_timer.time_left == 0 and wander_walk_timer_started:
		animation_player.stop()
		animated_sprite_2d.play("Idle")
		wander_walk_timer_started = false
		velocity.x = 0
		wander_wait_timer.start()
		wander_wait_timer_started = true
	
	if wander_walk_timer_started:
		if velocity.x < 0:
			if !ledge_check_left.is_colliding() or wall_check_left.is_colliding():
				velocity.x = 0
				animation_player.stop()
				animated_sprite_2d.play("Idle")
		if velocity.x > 0:
			if !ledge_check_right.is_colliding() or wall_check_right.is_colliding():
				velocity.x = 0
				animation_player.stop()
				animated_sprite_2d.play("Idle")
	
	if player_detected_timer.time_left == 0 and player_detected_timer_started and !actor_detection_zone.can_see_player():
		pulse_effect_instance_added = false
		player_detected_timer_started = false
	
	move_and_slide()

func entering_wander_state():
	wander_wait_timer.start()
	wander_wait_timer_started = true
	wander_direction = 1
	num_of_direction_changed = 0
	wander_walk_timer_started = false

#Chase state functions-----------------------------------------------------------------------------
func chase_state(delta):
	apply_gravity(delta)
	animation_player.play("RunFast")
	if not chase_timer_started:
		chase_timer.start()
		chase_timer_started = true
	
	if player_to_the_left:
		animated_sprite_2d.flip_h = true
		velocity.x = move_toward(velocity.x, -chase_speed, acceleration * 2 * delta)
	else:
		animated_sprite_2d.flip_h = false
		velocity.x = move_toward(velocity.x, chase_speed, acceleration * 2 * delta)
	
	if chase_timer.time_left == 0 and chase_timer_started:
		chase_timer_started = false
		player_to_the_left = false
		state = SLOWDOWN
	
	if velocity.x < 0:
		if wall_check_left.is_colliding():
			entering_wander_state()
			animation_player.stop()
			animated_sprite_2d.play("Idle")
			entering_wander_state()
			chase_timer_started = false
			player_to_the_left = false
			state = WANDER
	if velocity.x > 0:
		if wall_check_right.is_colliding():
			entering_wander_state()
			animation_player.stop()
			animated_sprite_2d.play("Idle")
			entering_wander_state()
			chase_timer_started = false
			player_to_the_left = false
			state = WANDER
	
	move_and_slide()

func _on_hitbox_area_entered(_area):
	if state == CHASE:
		chase_timer_started = false
		player_to_the_left = false
		state = SLOWDOWN

func _on_actor_detection_zone_top_body_entered(_body):
	if state == CHASE:
		chase_timer_started = false
		player_to_the_left = false
		state = SLOWDOWN

var poof_effect_timer_started = false

#Slowdown state functions-----------------------------------------------------------------------------
func slowdown_state(delta):
	if not poof_effect_timer_started:
		poof_effect_timer.start()
		poof_effect_timer_started = true
	
	if poof_effect_timer.time_left == 0 and poof_effect_timer_started:
		if is_on_floor():
			spawn_trail_effect()
		poof_effect_timer_started = false
	
	
	apply_gravity(delta)
	animation_player.stop()
	animated_sprite_2d.play("Idle")
	velocity.x = move_toward(velocity.x, 0, acceleration * delta)
	move_and_slide()
	
	if velocity.x == 0 and is_on_floor():
		poof_effect_timer_started = false
		state = WAIT

#Wait state functions-------------------------------------------------------------------------------
func wait_state():
	if not wait_timer_started:
		wait_timer.start()
		wait_timer_started = true
	
	if wait_timer.time_left == 0 and wait_timer_started:
		wait_timer_started = false
		entering_wander_state()
		state = WANDER

#Death state functions------------------------------------------------------------------------------
func death_state(delta):
	apply_gravity(delta)
	health_bar_empty.visible = false
	healthbar_full.visible = false
	health_bar_empty_1.visible = false
	health_bar_empty_2.visible = false
	hurtbox.get_node("CollisionShape2D").disabled = true
	hitbox.get_node("CollisionShape2D").disabled = true
	if not death_animation_played:
		SoundPlayer.play_enemy_death_sound()
		var world = get_tree().current_scene
		var death_effect = load("res://Source/Effects/enemy_death_effect.tscn")
		var death_effect_instance = death_effect.instantiate()
		world.add_child(death_effect_instance)
		death_effect_instance.global_position.x = mushroom_enemy.global_position.x
		death_effect_instance.global_position.y = mushroom_enemy.global_position.y - 18
		animation_player.play("Death")
		death_animation_played = true
	velocity.x = 0
	move_and_slide()

func death_queue_free():
	queue_free()

#Other functions
func apply_gravity(delta):
	velocity.y += gravity * delta

func spawn_trail_effect():
	if is_on_floor():
		var world = get_tree().current_scene
		var poof_effect = load("res://Source/Effects/poof_effect.tscn")
		var poof_effect_instance = poof_effect.instantiate()
		world.add_child(poof_effect_instance)
		if animated_sprite_2d.flip_h:
			poof_effect_instance.global_position.x = mushroom_enemy.global_position.x - 5
		else:
			poof_effect_instance.global_position.x = mushroom_enemy.global_position.x + 5
		poof_effect_instance.global_position.y = mushroom_enemy.global_position.y

func _on_hurtbox_area_entered(area):
	health_bar_timer.start()
	health_bar_timer_started = true
	health_bar_empty.visible = true
	healthbar_full.visible = true
	health_bar_empty_1.visible = true
	health_bar_empty_2.visible = true
	hurtbox_entered_timer.start()
	hurtbox_entered_timer_started = true
	health -= area.damage
	healthbar_full.size.x = (health_bar_initial_size / 10) * health
	if health <= 0:
		state = DEATH
	animated_sprite_2d.self_modulate.r = 255
	animated_sprite_2d.self_modulate.g = 255
	animated_sprite_2d.self_modulate.b = 255

func _on_visible_on_screen_notifier_2d_screen_entered():
	set_physics_process(true)

func _on_visible_on_screen_notifier_2dlarge_screen_exited():
	set_physics_process(false)
