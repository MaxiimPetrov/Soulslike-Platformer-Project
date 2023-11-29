extends CharacterBody2D

enum{IDLE, CHASE, ATTACK, WAIT, EXPOSED, RUN, DEATH}

@onready var ledge_check_right = $Raycasts/LedgeCheckRight
@onready var ledge_check_left = $Raycasts/LedgeCheckLeft
@onready var wall_check_left_bottom = $Raycasts/WallCheckLeftBottom
@onready var wall_check_left_middle = $Raycasts/WallCheckLeftMiddle
@onready var wall_check_left_top = $Raycasts/WallCheckLeftTop
@onready var wall_check_left_above = $Raycasts/WallCheckLeftAbove
@onready var wall_check_right_bottom = $Raycasts/WallCheckRightBottom
@onready var wall_check_right_middle = $Raycasts/WallCheckRightMiddle
@onready var wall_check_right_top = $Raycasts/WallCheckRightTop
@onready var wall_check_right_above = $Raycasts/WallCheckRightAbove
@onready var idle_timer = $Timers/IdleTimer
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var idle_walk_timer = $Timers/IdleWalkTimer
@onready var actor_detection_zone_close = $ActorDetectionZoneClose
@onready var actor_detection_zone_far = $ActorDetectionZoneFar
@onready var player_detected_timer = $Timers/PlayerDetectedTimer
@onready var goblin = $"."
@onready var attack_hitbox = $Marker2D/AttackHitbox
@onready var animation_player = $AnimationPlayer
@onready var marker_2d = $Marker2D
@onready var run_timer = $Timers/RunTimer
@onready var exposed_timer = $Timers/ExposedTimer
@onready var wait_timer = $Timers/WaitTimer
@onready var hurtbox_entered_timer = $Timers/HurtboxEnteredTimer
@onready var health_bar_timer = $Timers/HealthBarTimer
@onready var health_bar_empty = $Health/HealthBarEmpty
@onready var healthbar_full = $Health/HealthbarFull
@onready var health_bar_empty_1 = $Health/HealthBarEmpty1
@onready var health_bar_empty_2 = $Health/HealthBarEmpty2
@onready var hurtbox = $Hurtbox
@onready var hitbox = $Hitbox

#Idle state variables
var idle_timer_started = false
var idle_walk_timer_started = false
var direction = 1
var num_of_direction_changed = 0
var y_velocity_updated = false
var played_idle_when_unable_to_jump = false
var player_detected_timer_started = false
var player_position = Vector2.ZERO
var pulse_effect_instance_added = false

#Chase state variables
var player_to_the_left_set = false
var player_to_the_left = false
var reached_player_position = false
var run_animation_played = false

#Attack state variables
var attack_played = false
var attack_landed = false
var player_position_set = false
var attacked_to_the_left = false

#Run state variables
var run_timer_started = false
var run_player_position_set = false

#Exposed state variables
var exposed_timer_started = false

#Wait state variables
var wait_timer_started = false

#Death state variables
var death_animation_played = false
var death_effect_added = false

#Other variables
var state = IDLE
var idle_speed = 35
var chase_speed = 75
var gravity = 900
var rng = RandomNumberGenerator.new()
var health = 7
var health_bar_timer_started = false
var health_bar_initial_size = 0
var hurtbox_entered_timer_started = false

func _ready():
	set_physics_process(false)
	health_bar_initial_size = healthbar_full.size.x
	var random_wait_timer_number = rng.randi_range(0,2)
	if random_wait_timer_number == 0:
		idle_timer.wait_time = 2
	elif random_wait_timer_number == 1:
		idle_timer.wait_time = 3
	else:
		idle_timer.wait_time = 3.5
	attack_hitbox.get_node("CollisionShape2D").disabled = true
	animated_sprite_2d.play("Idle")

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
		IDLE:
			idle_state(delta)
		CHASE:
			chase_state(delta)
		ATTACK:
			attack_state(delta)
		WAIT:
			wait_state(delta)
		RUN:
			run_state(delta)
		EXPOSED:
			exposed_state(delta)
		DEATH:
			death_state(delta)

#Idle state functions-------------------------------------------------------------------------------
func idle_state(delta):
	apply_gravity(delta)
	if !idle_timer_started:
		idle_timer.start()
		idle_timer_started = true
	
	if !actor_detection_zone_far.can_see_player():
		if idle_timer.time_left == 0 and idle_timer_started:
			if not idle_walk_timer_started: 
				idle_walk_timer.start()
				idle_walk_timer_started = true
				velocity.x = idle_speed * direction
				animated_sprite_2d.flip_h = velocity.x < 0
				num_of_direction_changed += 1
				if num_of_direction_changed % 2 != 0:
					direction *= -1
		
		if idle_walk_timer_started:
			if y_velocity_updated:
				animated_sprite_2d.play("Idle")
			elif !played_idle_when_unable_to_jump and (ledge_check_right.is_colliding() and ledge_check_left.is_colliding()) and velocity.x != 0:
				animated_sprite_2d.play("Run (SLOW)")
			check_for_ledge()
			jump()
		
		if idle_walk_timer.time_left == 0 and idle_walk_timer_started and is_on_floor():
			animated_sprite_2d.play("Idle")
			velocity.x = 0
			idle_timer_started = false
			idle_walk_timer_started = false
			played_idle_when_unable_to_jump = false
	
	if is_on_floor():
		if actor_detection_zone_close.can_see_player():
			entering_attack_state()
			state = ATTACK
		elif actor_detection_zone_far.can_see_player():
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
			if goblin.global_position.x > player_position.x:
				animated_sprite_2d.flip_h = true
			else:
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
				pulse_effect_1_instance.global_position.x = goblin.global_position.x + 15
				pulse_effect_1_instance.global_position.y = goblin.global_position.y - 20
				pulse_effect_2_instance.global_position.x = goblin.global_position.x - 15
				pulse_effect_2_instance.global_position.y = goblin.global_position.y - 20
				pulse_effect_instance_added = true
	
	if player_detected_timer.time_left == 0 and player_detected_timer_started and !actor_detection_zone_far.can_see_player():
		pulse_effect_instance_added = false
		player_detected_timer_started = false
	
	var x_velocity_before_collision = velocity.x
	move_and_slide()
	velocity.x = x_velocity_before_collision
	
	if is_on_floor():
		y_velocity_updated = false

func entering_idle_state():
	y_velocity_updated = false
	played_idle_when_unable_to_jump = false
	idle_timer_started = false
	idle_walk_timer_started = false
	direction = 1
	num_of_direction_changed = 0
	player_detected_timer_started = false
	pulse_effect_instance_added = false

#Chase state functions------------------------------------------------------------------------------
func chase_state(delta):
	if actor_detection_zone_close.can_see_player() and is_on_floor():
		entering_attack_state()
		state = ATTACK
	else:
		apply_gravity(delta)
		if not player_to_the_left_set:
			if goblin.global_position.x > player_position.x:
				player_to_the_left = true
			elif goblin.global_position.x < player_position.x:
				player_to_the_left = false
			player_to_the_left_set = true
		
		if player_to_the_left:
			if goblin.global_position.x > player_position.x + 20:
				velocity.x = -chase_speed
			else:
				reached_player_position = true
				if is_on_floor() and !actor_detection_zone_far.can_see_player():
					velocity.x = 0
		else:
			if goblin.global_position.x < player_position.x - 20:
				velocity.x = chase_speed
			else:
				reached_player_position = true
				if is_on_floor() and !actor_detection_zone_far.can_see_player():
					velocity.x = 0
		
		if reached_player_position and is_on_floor():
			if actor_detection_zone_far.can_see_player() and !wall_check_left_above.is_colliding() and !wall_check_right_above.is_colliding():
				entering_chase_state()
				player_position.x = roundf(GameData.player_position.x)
				player_position.y = roundf(GameData.player_position.y)
				state = CHASE
			else:
				entering_wait_state()
				state = WAIT
		else:
			jump()
			check_for_ledge()
			animated_sprite_2d.flip_h = velocity.x < 0
		
		if velocity.x != 0:
			if is_on_floor():
				if !run_animation_played:
					if animated_sprite_2d.animation != "Run (FAST)":
						animated_sprite_2d.play("Run (FAST)")
						run_animation_played = true
			else:
				animated_sprite_2d.play("Idle")
				run_animation_played = false
		
		var x_velocity_before_collision = velocity.x
		move_and_slide()
		velocity.x = x_velocity_before_collision
		
		if is_on_floor():
			y_velocity_updated = false

func entering_chase_state():
	player_to_the_left_set = false
	player_to_the_left = false
	reached_player_position = false
	played_idle_when_unable_to_jump = false
	run_animation_played = false

#Attack state functions-----------------------------------------------------------------------------
func attack_state(delta):
	apply_gravity(delta)
	velocity.x = 0
	if !player_position_set:
		player_position.x = roundf(GameData.player_position.x)
		if goblin.global_position.x > player_position.x:
			animated_sprite_2d.flip_h = true
			attacked_to_the_left = true
			marker_2d.scale.x = -1
		else:
			animated_sprite_2d.flip_h = false
			marker_2d.scale.x = 1
		player_position_set = true
	
	if !attack_played:
		animation_player.play("Attack")
		attack_played = true
	move_and_slide()

func _on_attack_hitbox_area_entered(_area):
	attack_landed = true

func entering_attack_state():
	attack_played = false
	attack_landed = false
	player_position_set = false
	attacked_to_the_left = false

func leaving_attack_state():
	if attack_landed:
		entering_run_state()
		state = RUN
	else:
		entering_exposed_state()
		state = EXPOSED

#Run state functions--------------------------------------------------------------------------------
func run_state(delta):
	apply_gravity(delta)
	if not run_timer_started:
		run_timer.start()
		run_timer_started = true
	
	if run_timer.time_left == 0 and run_timer_started and is_on_floor():
		if actor_detection_zone_close.can_see_player():
			entering_attack_state()
			state = ATTACK
		elif actor_detection_zone_far.can_see_player():
			entering_chase_state()
			player_position.x = roundf(GameData.player_position.x)
			player_position.y = roundf(GameData.player_position.y)
			state =  CHASE
		else:
			entering_wait_state()
			state = WAIT
	
	if !run_player_position_set:
		player_position.x = roundf(GameData.player_position.x)
	
	if goblin.global_position.x > player_position.x:
		velocity.x = chase_speed
		animated_sprite_2d.flip_h = false
	else:
		velocity.x = -chase_speed
		animated_sprite_2d.flip_h = true
		
	jump()
	check_for_ledge()
	
	move_and_slide()
	
#	if is_on_floor():
#		if !played_idle_when_unable_to_jump:
#			animated_sprite_2d.play("Run (FAST)")
#		y_velocity_updated = false

func entering_run_state():
	run_timer_started = false
	played_idle_when_unable_to_jump = false
	run_player_position_set = false

#Exposed state functions----------------------------------------------------------------------------
func exposed_state(delta):
	apply_gravity(delta)
	velocity.x = 0
	if not exposed_timer_started:
		animated_sprite_2d.play("Idle")
		exposed_timer.start()
		exposed_timer_started = true
	
	if exposed_timer.time_left == 0 and exposed_timer_started:
		entering_wait_state()
		state = WAIT
	
	move_and_slide()

func entering_exposed_state():
	exposed_timer_started = false

#Wait state functions-------------------------------------------------------------------------------
func wait_state(delta):
	apply_gravity(delta)
	velocity.x = 0
	animated_sprite_2d.play("Idle")
	if !wait_timer_started:
		wait_timer.start()
		wait_timer_started = true
	
	if actor_detection_zone_close.can_see_player() and is_on_floor():
		if not pulse_effect_instance_added:
			var world = get_tree().current_scene
			var pulse_effect_1 = load("res://Source/Effects/enemy_pulse_effect.tscn")
			var pulse_effect_2 = load("res://Source/Effects/enemy_pulse_effect.tscn")
			var pulse_effect_1_instance = pulse_effect_1.instantiate()
			var pulse_effect_2_instance = pulse_effect_2.instantiate()
			pulse_effect_2_instance.left = true
			world.add_child(pulse_effect_1_instance)
			world.add_child(pulse_effect_2_instance)
			pulse_effect_1_instance.global_position.x = goblin.global_position.x + 15
			pulse_effect_1_instance.global_position.y = goblin.global_position.y - 20
			pulse_effect_2_instance.global_position.x = goblin.global_position.x - 15
			pulse_effect_2_instance.global_position.y = goblin.global_position.y - 20
			pulse_effect_instance_added = true
		entering_attack_state()
		state = ATTACK
	elif actor_detection_zone_far.can_see_player() and is_on_floor():
		entering_chase_state()
		player_position.x = roundf(GameData.player_position.x)
		player_position.y = roundf(GameData.player_position.y)
		state = CHASE
	
	if wait_timer.time_left == 0 and wait_timer_started:
		entering_idle_state()
		state = IDLE
	
	move_and_slide()

func entering_wait_state():
	wait_timer_started = false
	pulse_effect_instance_added = false

#Death state functions------------------------------------------------------------------------------
func death_state(delta):
	velocity.x = 0
	apply_gravity(delta)
	health_bar_empty.visible = false
	healthbar_full.visible = false
	health_bar_empty_1.visible = false
	health_bar_empty_2.visible = false
	attack_hitbox.get_node("CollisionShape2D").disabled = true
	hitbox.get_node("CollisionShape2D").disabled = true
	hurtbox.get_node("CollisionShape2D").disabled = true
	
	if not death_effect_added:
		SoundPlayer.play_enemy_death_sound()
		var world = get_tree().current_scene
		var death_effect = load("res://Source/Effects/enemy_death_effect.tscn")
		var death_effect_instance = death_effect.instantiate()
		world.add_child(death_effect_instance)
		death_effect_instance.get_node("AnimatedSprite2D").scale.x = 0.35
		death_effect_instance.get_node("AnimatedSprite2D").scale.y = 0.35
		death_effect_instance.global_position.x = goblin.global_position.x
		death_effect_instance.global_position.y = goblin.global_position.y - 20
		death_effect_added = true
	
	if !death_animation_played:
		animation_player.play("Death")
	
	move_and_slide()

func death_queue_free():
	queue_free()

#Other functions------------------------------------------------------------------------------------
func jump():
	if is_on_floor():
		if velocity.x > 0 or animated_sprite_2d.flip_h == false:
			if wall_check_right_bottom.is_colliding() and !wall_check_right_middle.is_colliding():
				if not y_velocity_updated:
					animated_sprite_2d.play("Idle")
					velocity.y = -200
					y_velocity_updated = true
			elif wall_check_right_bottom.is_colliding() and wall_check_right_middle.is_colliding() and !wall_check_right_top.is_colliding():
				if not y_velocity_updated:
					animated_sprite_2d.play("Idle")
					velocity.y = -250
					y_velocity_updated = true
			elif wall_check_right_bottom.is_colliding() and wall_check_right_middle.is_colliding() and wall_check_right_top.is_colliding() and !wall_check_right_above.is_colliding():
				if not y_velocity_updated:
					animated_sprite_2d.play("Idle")
					velocity.y = -300
					y_velocity_updated = true
			elif wall_check_right_bottom.is_colliding() and wall_check_right_middle.is_colliding() and wall_check_right_top.is_colliding() and wall_check_right_above.is_colliding():
				velocity.x = 0
				if !played_idle_when_unable_to_jump:
					animated_sprite_2d.play("Idle")
					played_idle_when_unable_to_jump = true
		elif velocity.x < 0 or animated_sprite_2d.flip_h == true:
			if wall_check_left_bottom.is_colliding() and !wall_check_left_middle.is_colliding():
				if not y_velocity_updated:
					animated_sprite_2d.play("Idle")
					velocity.y = -200
					y_velocity_updated = true
			elif wall_check_left_bottom.is_colliding() and wall_check_left_middle.is_colliding() and !wall_check_left_top.is_colliding():
				if not y_velocity_updated:
					animated_sprite_2d.play("Idle")
					velocity.y = -250
					y_velocity_updated = true
			elif wall_check_left_bottom.is_colliding() and wall_check_left_middle.is_colliding() and wall_check_left_top.is_colliding() and !wall_check_left_above.is_colliding():
				if not y_velocity_updated:
					animated_sprite_2d.play("Idle")
					velocity.y = -300
					y_velocity_updated = true
			elif wall_check_left_bottom.is_colliding() and wall_check_left_middle.is_colliding() and wall_check_left_top.is_colliding() and wall_check_left_above.is_colliding():
				velocity.x = 0
				if !played_idle_when_unable_to_jump:
					animated_sprite_2d.play("Idle")
					played_idle_when_unable_to_jump = true

func check_for_ledge():
	if velocity.x > 0:
		if !ledge_check_right.is_colliding() and !y_velocity_updated:
			animated_sprite_2d.play("Idle")
			velocity.x = 0
			if state == CHASE:
				entering_wait_state()
				state = WAIT
		elif state == RUN:
			animated_sprite_2d.play("Run (FAST)")
	else:
		if !ledge_check_left.is_colliding() and !y_velocity_updated:
			animated_sprite_2d.play("Idle")
			velocity.x = 0
			if state == CHASE:
				entering_wait_state()
				state = WAIT
		elif state == RUN:
			animated_sprite_2d.play("Run (FAST)")

func apply_gravity(delta):
	velocity.y += gravity * delta

func _on_hurtbox_area_entered(area):
	health_bar_timer.start()
	health_bar_timer_started = true
	health_bar_empty.visible = true
	healthbar_full.visible = true
	health_bar_empty_1.visible = true
	health_bar_empty_2.visible = true
	health -= area.damage
	healthbar_full.size.x = (health_bar_initial_size / 7) * health
	hurtbox_entered_timer.start()
	hurtbox_entered_timer_started = true
	if health <= 0:
		state = DEATH
	else:
		animated_sprite_2d.self_modulate.r = 255
		animated_sprite_2d.self_modulate.g = 255
		animated_sprite_2d.self_modulate.b = 255

func _on_visible_on_screen_notifier_2d_screen_entered():
	set_physics_process(true)

func _on_visible_on_screen_notifier_2dlarge_screen_exited():
	set_physics_process(false)
