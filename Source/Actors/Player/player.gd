extends CharacterBody2D

#test resolution for mac: 1920, 1200
#test resolution for windows 1280, 720

enum {MOVE, CROUCH, ATTACK, GROUND_POUND, POGO, HURT, DODGE, DEAD, HEAL, ABILITY, CHECKPOINT}
enum {NONE, BOOMERANG, ARCHINGDISC, FIREBALL}

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var player = $"."
@onready var animation_player = $AnimatedSprite2D/AnimationPlayer
@onready var attack_1_hitbox = $"Hitbox Pivot/Attack1Hitbox"
@onready var attack_2_hitbox = $"Hitbox Pivot/Attack2Hitbox"
@onready var attack_3_hitbox = $"Hitbox Pivot/Attack3Hitbox"
@onready var attack_4_hitbox = $"Hitbox Pivot/Attack4Hitbox"
@onready var crouch_attack_1_hitbox = $"Hitbox Pivot/CrouchAttack1Hitbox"
@onready var crouch_attack_2_hitbox = $"Hitbox Pivot/CrouchAttack2Hitbox"
@onready var hitbox_pivot = $"Hitbox Pivot"
@onready var ground_pound_end_hitbox = $"Hitbox Pivot/GroundPoundEndHitbox"
@onready var ground_pound_start_hitbox = $"Hitbox Pivot/GroundPoundStartHitbox"
@onready var move_state_hurtbox = $MoveStateHurtbox
@onready var crouch_state_hurtbox = $CrouchStateHurtbox
@onready var ground_pound_start_hurtbox = $GroundPoundStartHurtbox
@onready var ground_pound_end_hurtbox = $GroundPoundEndHurtbox
@onready var effects_player = $AnimatedSprite2D/EffectsPlayer
@onready var coyote_jump_timer = $Timers/CoyoteJumpTimer
@onready var i_frames_timer = $Timers/iFramesTimer
@onready var dodge_downtime_timer = $Timers/DodgeDowntimeTimer
@onready var remote_transform_2d = $RemoteTransform2D
@onready var death_background = $DeathBackground
@onready var traps_standing_hurtbox = $TrapsStandingHurtbox
@onready var traps_crouched_hurtbox = $TrapsCrouchedHurtbox
@onready var platform_detector = $PlatformDetector
@onready var level_transition_detection_zone = $LevelTransitionDetectionZone

#Movement variables
var speed = 90 
var jump_velocity = 335
var gravity = 900
var acceleration = 1500
var y_velocity_cap = 350

#Move state variables
var is_jumping = false
var just_landed
var coyote_jump_timer_started = false
var already_jumped_once = false
var can_set_checkpoint = false #Also used in crouch state

#Crouch state variables
var leaving_crouch_state = false

#Attack state variables
var attack_1_played = false
var attack_1_finished_playing = false
var attack_2_played = false
var attack_2_finished_playing = false
var attack_3_played = false
var attack_3_finished_playing = false
var attack_4_played = false
var attack_2_can_be_buffered = false
var attack_3_can_be_buffered = false
var attack_4_can_be_buffered = false
var attack_2_buffered = false
var attack_3_buffered = false
var attack_4_buffered = false
var fliph_updated_mid_combo = false
var fliph_availible = false
var attacking_in_air = false
var air_attack_stamina_applied = false

#Pogo state variables
var pogo_velocity_added = false
var leaving_pogo_state = false

#Hurt state variables
var blood_effect_played = false
var jump_impulse_velocity_applied = false
var hurt_animation_in_air_played = false
var was_in_the_air = false
var blood_effect = null
var blood_effect_instance = null
var blood_effect_flipped = false
var iframes_timer_started = false
var player_health_updated = false
var damage_to_be_taken = 0
var previous_animation_stopped = false

#Dodge state variables
var dodge_downtime_timer_started = false
var stamina_updated = false

#Ground pound state variables
var ground_pound_start_stamina_applied = false
var ground_pound_end_stamina_applied = false

#Heal state variables
var heal_state_health_updated = false

#Ability state variables
var ability_attack_played = false

#Checkpoint state variables
var checkpoint_animation_played = false

#Dead state variables
var dead_animation_played = false

#Other variables
var state = MOVE
var world = null
var colliding_with_platform = false

func _ready():
	GameData.player_mana = 0
	#Gets current scene to then add instances of other scenes, such as effects
	world = get_tree().current_scene
	#Ensures that once player is instantiated, all attack hitboxes are disabled
	attack_1_hitbox.get_node("CollisionShape2D").disabled = true
	attack_2_hitbox.get_node("CollisionShape2D").disabled = true
	attack_3_hitbox.get_node("CollisionShape2D").disabled = true
	attack_4_hitbox.get_node("CollisionShape2D").disabled = true
	crouch_attack_1_hitbox.get_node("CollisionShape2D").disabled = true
	crouch_attack_2_hitbox.get_node("CollisionShape2D").disabled = true
	ground_pound_end_hitbox.get_node("CollisionShape2D").disabled = true
	ground_pound_start_hitbox.get_node("CollisionShape2D").disabled = true

func _physics_process(delta):
	update_player_damage()
	set_player_position()
	adjust_player_facing_left_autoload_variable()
	var input_axis = Input.get_axis("Left", "Right") #Receives the direction player is pressing towards
	end_i_frames() #Checks if i frames timer has ended and if so sets the iframes_timer_started timer to false, allowing all other functions to adjust thier hurtboxes
	end_dodge_downtime()
	if GameData.player_movement_disabled:
		player_movement_disabled()
	else:
		match state: 
			MOVE:
				move_state(input_axis, delta)
			CROUCH:
				crouch_state(input_axis, delta)
			ATTACK:
				attack_state(input_axis, delta)
			GROUND_POUND:
				ground_pound_state()
			POGO:
				pogo_state(input_axis, delta)
			HURT:
				hurt_state()
			DODGE:
				dodge_state(delta)
			DEAD:
				dead_state()
			HEAL:
				heal_state(delta)
			ABILITY:
				ability_state(input_axis, delta)
			CHECKPOINT:
				checkpoint_state()

#Move state funcitons-------------------------------------------------------------------------------
func move_state(input_axis, delta):
	GameData.player_can_kneel = true #Indicates to checkpoint that player is able to set thier checkpoint
	GameData.player_stamina += 30 * delta #Updates player stamina
	
	#Resets sprite position because it is changed in the heal state
	animated_sprite_2d.position.x = 0
	
	#Enables necessary hurtbox for move state, disables all other hurt boxes
	if not iframes_timer_started:
		crouch_state_hurtbox.get_node("CollisionShape2D").disabled = true
		ground_pound_start_hurtbox.get_node("CollisionShape2D").disabled = true
		ground_pound_end_hurtbox.get_node("CollisionShape2D").disabled = true
		move_state_hurtbox.get_node("CollisionShape2D").disabled = false
		traps_crouched_hurtbox.get_node("CollisionShape2D").disabled = true
		traps_standing_hurtbox.get_node("CollisionShape2D").disabled = false
	
	handle_animations(input_axis)
	handle_move_state_movement(input_axis, delta)
	
	#Changes to crouch state
	if Input.is_action_pressed("Down") and is_on_floor():
		animated_sprite_2d.play("Crouch")
		state = CROUCH
	
	#Changes to ground pound state
	if Input.is_action_pressed("Down") and Input.is_action_just_pressed("Attack") and not is_on_floor() and GameData.player_max_stamina >= 10:
		if velocity.y > -75: #Ensures player has at least some air time before being able to ground pound
			GameData.player_can_kneel = false #Indicates to checkpoint that player is unable to set thier checkpoint
			state = GROUND_POUND
	#Changes to ability state
	elif Input.is_action_pressed("Up") and Input.is_action_just_pressed("Attack") and GameData.player_mana >= 25 and GameData.player_stamina >= 15 and GameData.player_ability != NONE:
		ability_attack_played = false #Resets variable to original value to ensure that the next time player enters the ability state, the ability will trigger
		GameData.player_can_kneel = false #Indicates to checkpoint that player is unable to set thier checkpoint
		state = ABILITY
	#Changes to attack state
	elif Input.is_action_just_pressed("Attack") and GameData.player_stamina >= 10:
		GameData.player_can_kneel = false #Indicates to checkpoint that player is unable to set thier checkpoint
		state = ATTACK
	elif is_on_floor() and can_set_checkpoint and Input.is_action_just_pressed("Interact"):
		state = CHECKPOINT
	
	#Changes to dodge state, takes into account dodge downtime timer
	if Input.is_action_just_pressed("Dodge") and not dodge_downtime_timer_started and is_on_floor() and GameData.player_stamina >= 15:
		GameData.player_can_kneel = false #Indicates to checkpoint that player is unable to set thier checkpoint
		state = DODGE
	
	#Changes to heal state
	if Input.is_action_just_pressed("Heal") and is_on_floor() and GameData.player_potions != 0:
		GameData.player_can_kneel = false #Indicates to checkpoint that player is unable to set thier checkpoint
		state = HEAL

func handle_move_state_movement(input_axis, delta):
	if not is_on_floor(): #If statement ensures that when player hugs wall, gravity is still applied
		#Checks if previous state was ground pound state, if so maintains the velocity of that state as it is different from the regular gravity
		if leaving_pogo_state:
			velocity.y += 13
		else:
			apply_gravity(delta)
	
	#Halves gravity when player reaches the apex of thier jump
	update_jump_apex_gravity()
	
	#Acclerates x velocity towards direction player is pressing
	velocity.x = move_toward(velocity.x, speed * input_axis, acceleration * delta)
	
	#Checks if player is allowed to jump
	if is_on_floor() or coyote_jump_timer.time_left > 0:
		#Checks already_jumped_once as to make sure player cannot jump multiple times while coyote jump timer is active, also checks if player just left crouch state so that they can jump without needing to press jump button again
		if (Input.is_action_just_pressed("Jump") or leaving_crouch_state) and not already_jumped_once: 
			velocity.y = -jump_velocity
			already_jumped_once = true
	#If player lets go of jump key, velocity is set to 0 and starts falling
	elif !Input.is_action_pressed("Jump") and not is_on_floor() and velocity.y < 0 and not leaving_pogo_state:
		velocity.y = 0
	
	#Ensures the y velocity does not exceed y_velocity_cap
	clamp_y_velocity()
	
	var was_in_air = not is_on_floor() #Checks if player is the air before velocity is calculated
	var was_on_floor = is_on_floor() #Checks if player is on floor before velocity is calculated
	var y_velocity_before_collision = velocity.y #Stores y velocity before new y velocity is calculated
	move_and_slide()
	just_landed = was_in_air and is_on_floor() #Checks was_in_air and if is on floor after calculations
	var just_left_ledge = not is_on_floor() and was_on_floor and velocity.y >= 0 #Checks if was on floor before and after calculation, and checks if y velocity is positive to make sure player is in fact falling and not jumping 
	
	#Checks just_left_ledge to start coyote timer, no need to ever stop timer
	if just_left_ledge:
		coyote_jump_timer.start()
	
	#Checks if players velocity is negative, meaning the player is jumping, updated value accordingly
	if velocity.y < 0:
		is_jumping = true
	
	#Checks if player landed
	if just_landed:
		#Spawns dust effect if landing from high enough distances
		if y_velocity_before_collision == y_velocity_cap:
			spawn_dust_landing_effect()
		#Resets value to be used in update_jump_apex_gravity function
		is_jumping = false
		#Resets values to be used in the above jump if statement
		already_jumped_once = false
		leaving_crouch_state = false

func update_jump_apex_gravity():
	#Checks if player is jumping and not just falling, and if they are at the apex of thier jump
	if is_jumping and velocity.y > -35 and velocity.y < 35:
		gravity = 450 #Halves gravity
	#Checks if player is jumping and if velocity of the jump has reached past its apex
	if (is_jumping and velocity.y > 35) or is_on_floor():
		gravity = 900 #Reverts gravity back to original value

func handle_animations(input_axis):
	#Changes flip_h of sprite respective to player input
	if input_axis != 0:
		animated_sprite_2d.flip_h = input_axis < 0
	
	#Checks if player is jumping
	if not is_on_floor():
		#Once player is descending, fall animation plays
		if velocity.y > 25:
			animated_sprite_2d.play("Fall")
		#Once player is ascending, jump animation plays
		else:
			animated_sprite_2d.play("Jump")
	#Checks if player is holding both right and left at the same time, meaning they are standing still
	elif Input.is_action_pressed("Left") and Input.is_action_pressed("Right"):
		animated_sprite_2d.play("Idle") #Plays idle animation
	#Checks if just one of the buttons are pressed, either left or right, meaning the player is moving
	elif Input.is_action_pressed("Left") or Input.is_action_pressed("Right"):
		animated_sprite_2d.play("Walk") #Plays walk animation
	#Checks if there is no player input
	else:
		animated_sprite_2d.play("Idle") #Plays idle animation

#Crouch state funcitons-----------------------------------------------------------------------------
func crouch_state(input_axis, delta):
	if !is_on_floor():
		animated_sprite_2d.play("Fall") #If player is falling through platform, plays fall
	else:
		animated_sprite_2d.play("Crouch") #If player is not falling, plays crouch
	
	GameData.player_can_kneel = true #Indicates to checkpoint that player is able to set thier checkpoint
	GameData.player_stamina += 30 * delta #Updates player stamina
	
	#Enables necessary hurtbox for crouch state, disables all other hurt boxes
	if not iframes_timer_started:
		crouch_state_hurtbox.get_node("CollisionShape2D").disabled = false
		ground_pound_start_hurtbox.get_node("CollisionShape2D").disabled = true
		ground_pound_end_hurtbox.get_node("CollisionShape2D").disabled = true
		move_state_hurtbox.get_node("CollisionShape2D").disabled = true
		traps_crouched_hurtbox.get_node("CollisionShape2D").disabled = false
		traps_standing_hurtbox.get_node("CollisionShape2D").disabled = true
	
	#Forces x velocity to remain 0 and keep player in place, no need to adjust y velocity as player already needs to be on floor when entering the state
	velocity.x = 0
	
	#Chnages back to move state once down key is released
	if Input.is_action_just_released("Down"):
		state = MOVE
	
	#Changes flip_h of sprite respective to player input
	if input_axis != 0:
		animated_sprite_2d.flip_h = input_axis < 0
#	animated_sprite_2d.play("Crouch") #Plays crouch animation
	
	#Allows player to jump while crouched, changing to move state and setting leaving_crouch_state to true, being used when checking if player should be jumping in move state
	if Input.is_action_just_pressed("Jump") and !colliding_with_platform: #Makes sure that if player presses jump when on a platform, they do not jump, and instead fall through the platform.
		leaving_crouch_state = true
		state = MOVE
	
	#Changes to ability state
	if Input.is_action_pressed("Up") and Input.is_action_just_pressed("Attack") and GameData.player_mana >= 25 and GameData.player_stamina >= 15 and GameData.player_ability != NONE:
		ability_attack_played = false #Resets variable to original value to ensure that the next time player enters the ability state, the ability will trigger
		GameData.player_can_kneel = false #Indicates to checkpoint that player is unable to set thier checkpoint
		state = ABILITY
	#Changes to attack state
	elif Input.is_action_just_pressed("Attack") and GameData.player_stamina >= 5:
		GameData.player_can_kneel = false #Indicates to checkpoint that player is unable to set thier checkpoint
		state = ATTACK 
	
	#Changes to dodge state, takes into account dodge downtime timer
	if Input.is_action_just_pressed("Dodge") and not dodge_downtime_timer_started and GameData.player_stamina >= 15:
		GameData.player_can_kneel = false #Indicates to checkpoint that player is unable to set thier checkpoint
		state = DODGE
	
	if is_on_floor() and can_set_checkpoint and Input.is_action_just_pressed("Interact"):
		state = CHECKPOINT
	
	#Changes to heal state
	if Input.is_action_just_pressed("Heal") and is_on_floor() and GameData.player_potions != 0:
		GameData.player_can_kneel = false #Indicates to checkpoint that player is unable to set thier checkpoint
		state = HEAL
	
	apply_gravity(delta) #If player chooses to fall through platform, applies gravity
	move_and_slide()

#Attack state functions-----------------------------------------------------------------------------
func attack_state(input_axis, delta):
	handle_attack_state_hurtboxes_after_iframes()
	
	#When entering attack state, chekcks if player is facing left or right, and flipping the attack hitboxes accordingly
	handle_hitbox_pivot()
	
	#Checks if player is in the air, if so starts air attack
	if not is_on_floor():
		air_attack(input_axis, delta) #Plays air attack
	#Checks if player is not in the air, and if they are pressing inputs to do either a ground attack or crouch attack
	if not attacking_in_air:
		#Ensures velocity coming out of attack state will be 0
		velocity.x = 0
		#Checks for ground attack input
		if Input.is_action_pressed("Down") and is_on_floor():
			crouch_attack(input_axis) #Plays crouch attack
		#Checks if there is no other player input, meaning a ground attack is intended
		else:
			ground_attack(input_axis) #Plays ground attack
	
	#Checks if player is mid air attack and lands on floor
	if attacking_in_air and is_on_floor():
		#Cancels air attacks and changes back to move state, creating a castlevania SOTN type mechanic, enabling the player to swiftly attack twice when landing
		change_out_of_attack_state()

func air_attack(input_axis, delta):
	attacking_in_air = true #Sets value to true, to be checked further down in the attack state
	handle_move_state_movement(input_axis, delta) #Maintains movement of move state 
	if not air_attack_stamina_applied:
		air_attack_stamina_applied = true
	animation_player.play("AttackAir") #Plays air attack

func crouch_attack(input_axis):
	#Entering this attack, plays attack 1 by default
	if not attack_1_played: #Makes sure attack is only played once
		animation_player.play("CrouchAttack1")
		attack_1_played = true
	
	#Checks if attack 2 can be buffered and if so checks for attack input
	if attack_2_can_be_buffered:
		if Input.is_action_just_pressed("Attack"):
			attack_2_buffered = true
	
	#Checks if attack 1 has finished playing
	if attack_1_finished_playing:
		#Checks if within the time frame that players flip h and be changed, and fliph_updated_mid_combo ensures it can only happen once during this time frame. Attack buffered check to make sure that when flip h becomes availible by the end of the animation, if player inputs in opposite direction without buffering, attack will not flip sides last second.
		if not fliph_updated_mid_combo and fliph_availible and attack_2_buffered:
			if input_axis != 0:
				animated_sprite_2d.flip_h = input_axis < 0
				fliph_updated_mid_combo = true
		#Checks if attack 2 has been buffered from before and if so, plays the attack
		if attack_2_buffered and GameData.player_stamina >= 5:
			if not attack_2_played:
				animation_player.play("CrouchAttack2")
				attack_2_played = true

func ground_attack(input_axis):
	#Entering this attack, plays attack 1 by default
	if not attack_1_played:
		animation_player.play("Attack1")
		attack_1_played = true
	
	#Checks if attacks 2, 3, and 4 can be buffered and if so checks for attack input
	if attack_2_can_be_buffered and not attack_3_can_be_buffered and not attack_4_can_be_buffered:
		if Input.is_action_just_pressed("Attack"):
			attack_2_buffered = true
	elif attack_2_can_be_buffered and attack_3_can_be_buffered and not attack_4_can_be_buffered:
		if Input.is_action_just_pressed("Attack"):
			attack_3_buffered = true
	elif attack_2_can_be_buffered and attack_3_can_be_buffered and attack_4_can_be_buffered:
		if Input.is_action_just_pressed("Attack"):
			attack_4_buffered = true
	
	#Checks if attack 1 finished playing, and not attack 2 or 3 to ensure that full attack combo is played, chekcing attack 4 is not necessary as it is the last of the combo
	if attack_1_finished_playing and not attack_2_finished_playing and not attack_3_finished_playing:
		if not fliph_updated_mid_combo and fliph_availible and attack_2_buffered: #Checks if within the time frame that players flip h and be changed, and fliph_updated_mid_combo ensures it can only happen once during this time frame. Attack buffered check to make sure that when flip h becomes availible by the end of the animation, if player inputs in opposite direction without buffering, attack will not flip sides last second.
			if input_axis != 0:
				animated_sprite_2d.flip_h = input_axis < 0
				fliph_updated_mid_combo = true
		if attack_2_buffered and GameData.player_stamina >= 5: #Checks if attack 2 has been buffered and if so plays attack 2
			if not attack_2_played:
				animation_player.play("Attack2")
				attack_2_played = true
	#Checks if both attack 1 and 2 finished playing, but not 3
	elif attack_1_finished_playing and attack_2_finished_playing and not attack_3_finished_playing:
		if not fliph_updated_mid_combo and fliph_availible and attack_3_buffered: #Checks if within the time frame that players flip h and be changed, and fliph_updated_mid_combo ensures it can only happen once during this time frame. Attack buffered check to make sure that when flip h becomes availible by the end of the animation, if player inputs in opposite direction without buffering, attack will not flip sides last second.
			if input_axis != 0:
				animated_sprite_2d.flip_h = input_axis < 0
				fliph_updated_mid_combo = true
		if attack_3_buffered: #Checks if attack 3 has been buffered and if so plays attack 3
			if not attack_3_played and GameData.player_stamina >= 5:
				animation_player.play("Attack3")
				attack_3_played = true
	#Checks if attack 1, 2 and 3 have finished playing
	elif attack_1_finished_playing and attack_2_finished_playing and attack_3_finished_playing:
		if not fliph_updated_mid_combo and fliph_availible and attack_4_buffered: #Checks if within the time frame that players flip h and be changed, and fliph_updated_mid_combo ensures it can only happen once during this time frame. Attack buffered check to make sure that when flip h becomes availible by the end of the animation, if player inputs in opposite direction without buffering, attack will not flip sides last second.
			if input_axis != 0:
				animated_sprite_2d.flip_h = input_axis < 0
				fliph_updated_mid_combo = true
		if attack_4_buffered and GameData.player_stamina >= 10: #Checks if attack 4 has been buffered and if so plays attack 4
			if not attack_4_played:
				animation_player.play("Attack4")
				attack_4_played = true

func attack_2_can_be_buffered_():
	#Used in animation player to indicate that attack 2 is ready to be buffered
	attack_2_can_be_buffered = true 

func attack_3_can_be_buffered_():
	#Used in animation player to indicate that attack 3 is ready to be buffered
	attack_3_can_be_buffered = true 

func attack_4_can_be_buffered_():
	#Used in animation player to indicate that attack 4 is ready to be buffered
	attack_4_can_be_buffered = true 

func trigger_attack_1_finished():
	#Used in animation player 
	attack_1_finished_playing = true #Indicates that attack 1 is done playing and player can initiate attack 2
	fliph_availible = true #Opens time frame for player to adjust the direction they are facing in during the attack combo
	fliph_updated_mid_combo = false #Sets value to indicate that flip h is able to be modified, ensures flip h is only update once during combo transitions

func trigger_attack_2_finished():
	#Used in animation player
	attack_2_finished_playing = true #Indicates that attack 2 is done playing and player can initiate attack 3
	fliph_availible = true #Opens time frame for player to adjust the direction they are facing in during the attack combo
	fliph_updated_mid_combo = false #Sets value to indicate that flip h is able to be modified, ensures flip h is only update once during combo transitions

func trigger_attack_3_finished():
	#Used in animation player
	attack_3_finished_playing = true #Indicates that attack 3 is done playing and player can initiate attack 4
	fliph_availible = true #Opens time frame for player to adjust the direction they are facing in during the attack combo
	fliph_updated_mid_combo = false #Sets value to indicate that flip h is able to be modified, ensures flip h is only update once during combo transitions

func remove_fliph_availibility():
	#Used in animation player
	fliph_availible = false #Disables ability for player to adjust flip h during their attack combo

func reset_all_attack_state_variables():
	#Resets all variables modified by the attack state, ensuring when attack state is entered again, the variables are at thier default values
	attack_1_played = false
	attack_1_finished_playing = false
	attack_2_played = false
	attack_2_finished_playing = false
	attack_3_played = false
	attack_3_finished_playing = false
	attack_4_played = false
	attack_2_can_be_buffered = false
	attack_2_buffered = false
	attack_3_can_be_buffered = false
	attack_3_buffered = false
	attack_4_can_be_buffered = false
	attack_4_buffered = false
	attacking_in_air = false
	leaving_pogo_state = false
	air_attack_stamina_applied = false

func change_out_of_attack_state():
	#Resets ground pound variables to original value
	ground_pound_start_stamina_applied = false
	ground_pound_end_stamina_applied = false
	#Used in animation player and attack state
	reset_all_attack_state_variables()
	already_jumped_once = false #Variable is only set to false when landing in move state, so it is set to false here as well, allowing player to jump once more once leaving this state
	#Once leaving attack state, checks player input as to set state in respect to that input, otherwise, there will be one frame where state is set to move state
	if Input.is_action_pressed("Down") and is_on_floor():
		state = CROUCH
	else:
		#if player is attcking and gets hurt during attack, since animation player is still going, it will swtich to move state before player touches the ground (When player is getting hurt mid-air)
		if state != HURT:
			state = MOVE

func handle_hitbox_pivot():
	#Changes scale of hitbox pivot relative to the direction the player is facing
	if animated_sprite_2d.flip_h == true:
		hitbox_pivot.scale.x = -1
	else:
		hitbox_pivot.scale.x = 1

func handle_attack_state_hurtboxes_after_iframes():
	#If player is attacking while i frames are over, this will check which attack they are doing and adjust the proper hitbox to become active
	if not iframes_timer_started:
		if animated_sprite_2d.animation == "Attack1" or animated_sprite_2d.animation == "Attack2" or animated_sprite_2d.animation == "Attack3" or animated_sprite_2d.animation == "Attack4" or animated_sprite_2d.animation == "AttackAir":
			crouch_state_hurtbox.get_node("CollisionShape2D").disabled = true
			ground_pound_start_hurtbox.get_node("CollisionShape2D").disabled = true
			ground_pound_end_hurtbox.get_node("CollisionShape2D").disabled = true
			move_state_hurtbox.get_node("CollisionShape2D").disabled = false
		elif animated_sprite_2d.animation == "CrouchAttack1" or animated_sprite_2d.animation == "CrouchAttack2":
			crouch_state_hurtbox.get_node("CollisionShape2D").disabled = false
			ground_pound_start_hurtbox.get_node("CollisionShape2D").disabled = true
			ground_pound_end_hurtbox.get_node("CollisionShape2D").disabled = true
			move_state_hurtbox.get_node("CollisionShape2D").disabled = true

func adjust_attack_stamina():
	if animation_player.current_animation == "Attack1" or animation_player.current_animation == "Attack2" or animation_player.current_animation == "Attack3" or animation_player.current_animation == "CrouchAttack1" or animation_player.current_animation == "CrouchAttack2":
		GameData.player_stamina -= 10
	elif animation_player.current_animation == "AbilityAttack" or animation_player.current_animation == "AttackAir":
		GameData.player_stamina -= 20
	else: #Checks if player is performing the final attack in the combo
		GameData.player_stamina -= 15

#Ability state functions----------------------------------------------------------------------------
func ability_state(input_axis, delta):
	if not ability_attack_played: #Makes sure that ability is only played once (and that stats are updated only once)
		SoundPlayer.play_ability_sound()
		animation_player.play("AbilityAttack")
		GameData.player_mana -= 25 #Updates player mana
		ability_attack_played = true
	
	#Makes sure player stands still if entering state on the ground
	if is_on_floor(): 
		velocity.x = 0
		velocity.y = 0
	#Maintains player velocity if entering state in the air
	else:
		handle_move_state_movement(input_axis, delta)

func spawn_ability():
	if GameData.player_ability == BOOMERANG:
		var boomerang = load("res://Source/Actors/Player/Player Abilities/boomerang.tscn")
		var boomerang_instance = boomerang.instantiate()
		world.add_child(boomerang_instance)
		if GameData.player_facing_left:
			boomerang_instance.global_position.x = player.global_position.x - 15
		else:
			boomerang_instance.global_position.x = player.global_position.x + 15
		boomerang_instance.global_position.y = player.global_position.y -25
	if GameData.player_ability == ARCHINGDISC:
		var arching_disc = load("res://Source/Actors/Player/Player Abilities/arching_disc.tscn")
		var arching_disc_instance = arching_disc.instantiate()
		world.add_child(arching_disc_instance)
		if GameData.player_facing_left:
			arching_disc_instance.global_position.x = player.global_position.x - 15
		else:
			arching_disc_instance.global_position.x = player.global_position.x + 15
		arching_disc_instance.global_position.y = player.global_position.y -25
	if GameData.player_ability == FIREBALL:
		var fireball = load("res://Source/Actors/Player/Player Abilities/fireball.tscn")
		var fireball_instance = fireball.instantiate()
		world.add_child(fireball_instance)
		if GameData.player_facing_left:
			fireball_instance.global_position.x = player.global_position.x - 20
		else:
			fireball_instance.global_position.x = player.global_position.x + 20
		fireball_instance.global_position.y = player.global_position.y -25

func change_from_ability_to_move_state():
	ability_attack_played = false #Resets variable to original value to ensure that the next time player enters the ability state, the ability will only trigger once
	state = MOVE

#Ground pound state functions-----------------------------------------------------------------------
func ground_pound_state():
	#When jumping and transitioning into ground_pound state, this variable will not longer be set to false when landing as it is only done so in the move state, if not reverted back to false, adjusting gravity for apex of player jump will happen when its not sopposed to
	is_jumping = false
	#leaving_crouch_state allows player to jump while holding crouch input, the variable is set to false when player lands in the move state, when in ground pound state this does not happen to it is set to false here as well, if not, if player jumps out of crouch state, ground pounds and lands, and releases crouch input, player will be forced to jump 
	if leaving_crouch_state:
		leaving_crouch_state = false
	#When diving down, y velocity is increased and player is unable to move horizontally
	velocity.x = 0
	velocity.y = 350
	#When not on the floor player will be diving down, which can be inturrupted if player is diving into an enemy, making the player transition into the pogo state
	if not is_on_floor():
		if not ground_pound_start_stamina_applied:
			GameData.player_stamina -= 10 #Updates player stamins, if statemnet ensures it only happens once
			ground_pound_start_stamina_applied = true
		#Enables necessary hurtbox for ground pound attack (start), disables all other hurt boxes
		if not iframes_timer_started:
			crouch_state_hurtbox.get_node("CollisionShape2D").disabled = true
			ground_pound_start_hurtbox.get_node("CollisionShape2D").disabled = false
			ground_pound_end_hurtbox.get_node("CollisionShape2D").disabled = true
			move_state_hurtbox.get_node("CollisionShape2D").disabled = true
		animation_player.play("GroundPoundStart")
	#When player reaches the floor, player slams into the ground
	else:
		if not ground_pound_end_stamina_applied:
			GameData.player_stamina -= 10 #Updates player stamins, if statement ensures it only happens once
			ground_pound_end_stamina_applied = true
		#Enables necessary hurtbox for ground pound attack (end), disables all other hurt boxes
		if not iframes_timer_started:
			crouch_state_hurtbox.get_node("CollisionShape2D").disabled = true
			ground_pound_start_hurtbox.get_node("CollisionShape2D").disabled = true
			ground_pound_end_hurtbox.get_node("CollisionShape2D").disabled = false
			move_state_hurtbox.get_node("CollisionShape2D").disabled = true
		animation_player.play("GroundPoundEnd")
	
	move_and_slide()

func _on_ground_pound_start_hitbox_area_entered(_area):
	spawn_pogo_effect()
	SoundPlayer.play_player_attack_sound()
	ground_pound_start_stamina_applied = false #Ensures that when transitioning into the pogo state, variable is reset to original value
	#Transitions to pogo state once hitbox interacts with an enemy hurtbox
	state = POGO

#Pogo state functions-------------------------------------------------------------------------------
func pogo_state(input_axis, delta):
	#Disables ground pound start hitbox since it is only done so in the ground pound end animation, which is not played once entering this state
	ground_pound_start_hitbox.get_node("CollisionShape2D").disabled = true
	
	handle_pogo_state_velocity(input_axis, delta)
	handle_pogo_state_animations(input_axis)
	
	#Enables necessary hurtbox for pogo state, disables all other hurt boxes
	if velocity.y > -250: #This check is necessary to ensure that hitboxes do not change on the same frame the ground pound start hitbox enters and enemy, because if so, the move state hitbox will be inside of the enemy and plyer will get hit. NOTE: This check is done after the velocity is calculated, because on the first frame of this state, the y velocity is still 350 from the ground pound state.
		if not iframes_timer_started:
			crouch_state_hurtbox.get_node("CollisionShape2D").disabled = true
			ground_pound_start_hurtbox.get_node("CollisionShape2D").disabled = true
			ground_pound_end_hurtbox.get_node("CollisionShape2D").disabled = true
			move_state_hurtbox.get_node("CollisionShape2D").disabled = false
	
	#Saves y velocity before calculation
	var y_velocity_before_collision = velocity.y
	move_and_slide()
	
	#Checks if player inputs to the ability state
	if Input.is_action_pressed("Up") and Input.is_action_just_pressed("Attack") and GameData.player_mana >= 25 and GameData.player_stamina >= 15:
		pogo_velocity_added = false #Resets value so that once entering pogo state again, velocity can be adjusted
		leaving_pogo_state = true #Indicates to move state that the previous state was the pogo state, in turn the gravity is not overriden with the default gravity, and within the jump if statements, the y velocity will not be adjusted to 0 if player released jump input
		state = ABILITY
	#Checks if player presses the attack input
	elif Input.is_action_just_pressed("Attack") and not Input.is_action_pressed("Down") and GameData.player_stamina >= 5:
		pogo_velocity_added = false #Resets value so that once entering pogo state again, velocity can be adjusted
		leaving_pogo_state = true #Indicates to move state that the previous state was the pogo state, in turn the gravity is not overriden with the default gravity, and within the jump if statements, the y velocity will not be adjusted to 0 if player released jump input
		state = ATTACK
	
	#Checks if player will change to another ground pound attack
	if Input.is_action_pressed("Down") and Input.is_action_just_pressed("Attack") and GameData.player_stamina >= 10:
		if velocity.y > -75: #Ensures player has at least some air time before being able to ground pound
			pogo_velocity_added = false #Resets value so that once entering pogo state again, velocity can be adjusted
			state = GROUND_POUND
	
	if is_on_floor():
		#Spawns dust effect if landing from high enough distances
		if y_velocity_before_collision == y_velocity_cap:
			spawn_dust_landing_effect()
		pogo_velocity_added = false #Resets value so that once entering pogo state again, velocity can be adjusted
		already_jumped_once = false #Variable is only set to false when landing in move state, so it is set to false here as well, allowing player to jump once more once leaving this state
		state = MOVE

func handle_pogo_state_velocity(input_axis, delta):
	#Ensures that velocity in pogo state is only applied once
	if not pogo_velocity_added:
		velocity.y = -jump_velocity + 25
		pogo_velocity_added = true
	
	#When in pogo state, normal gravity is not applied, as to create a more bouncy feel to the pogo and avoids the bug where gravity is not consistently applied, leading to the player sometimes pogoing a small distance and sometimes a large distance
	velocity.y += 13
	
	#Clamps y velocity to y_velocity_cap
	clamp_y_velocity()
	
	#Acclerates x velocity towards direction player is pressing
	velocity.x = move_toward(velocity.x, speed * input_axis, acceleration * delta)

func handle_pogo_state_animations(input_axis):
	#Changes flip_h of sprite respective to player input
	if input_axis != 0:
		animated_sprite_2d.flip_h = input_axis < 0
	#Once player is descending, fall animation plays
	if velocity.y > 25:
		animated_sprite_2d.play("Fall")
	#Once player is ascending, jump animation plays
	else:
		animated_sprite_2d.play("Jump")

#Hurt state functions-------------------------------------------------------------------------------
func hurt_state():
	if !previous_animation_stopped: #Makes sure previous animation that is playing is stopped
		animation_player.stop()
		previous_animation_stopped = true
	#Reduces player health
	if not player_health_updated:
		GameData.player_health -= damage_to_be_taken
		if GameData.player_health <= 0: #Checks if player's health is less than or equal to 0 and if so lets the game know player will die
			GameData.player_is_dead = true
			death_background.visible = true
			SoundPlayer.stop_stage_1_boss_music()
			SoundPlayer.stop_stage_1_music()
			SoundPlayer.play_player_dead_sound()
		else:
			SoundPlayer.play_player_hurt_sound()
		player_health_updated = true
	
	#Disables all hitboxes when entering this state, will be activated once transitioning out of this state
	crouch_state_hurtbox.get_node("CollisionShape2D").disabled = true
	ground_pound_start_hurtbox.get_node("CollisionShape2D").disabled = true
	ground_pound_end_hurtbox.get_node("CollisionShape2D").disabled = true
	move_state_hurtbox.get_node("CollisionShape2D").disabled = true
	traps_crouched_hurtbox.get_node("CollisionShape2D").disabled = true
	traps_standing_hurtbox.get_node("CollisionShape2D").disabled = true
	
	#Sets the engine's time to 0.6 for 0.1 seconds
	TimeStopManager.stop_time()
	
	#Upon entering the state, disables the previously active attack hitboxes
	disable_attack_hitboxes()
	
	#When jumping and transitioning into hurt state, this variable will not longer be set to false when landing as it is only done so in the move state, if not reverted back to false, adjusting gravity for apex of player jump will happen when its not sopposed to.
	is_jumping = false
	
	#Checks if the player is getting hit on the floor or in the air
	if not is_on_floor():
		was_in_the_air = true
	
	#Checks if player is on the floor and was not previously in the air, as in not just landed
	if is_on_floor() and not was_in_the_air:
		velocity.x = 0 #Sets the x velocity to 0, keeping the player in place
		animation_player.play("Hurt") #Plays hurt animation within the animation player, will revert back to move state by the end of the animation
		if not blood_effect_played: #Ensures that blood effect is only played once
			spawn_blood_effect()
			blood_effect_played = true
		#Checks if sprite flip_h is true and if so flips the blood instance sprite to reach the desired look of the effect
		if animated_sprite_2d.flip_h:
			if not blood_effect_flipped:
				blood_effect_instance.get_node("AnimatedSprite2D").flip_h = true
				blood_effect_flipped = true
		#Sets position of blood effect to the position below
		if GameData.blood_effect_in_scene:
			blood_effect_instance.global_position.x = player.global_position.x
			blood_effect_instance.global_position.y = player.global_position.y - 20
	#Checks if player is on the floor and was in the air, as in just landed
	elif is_on_floor() and was_in_the_air:
		change_from_hurt_to_move_state() #Once player has landed on the ground after getting hurt, state is reverted back to move here, since the animation is played in the sprite and not the animation player, thus the change to move state function will not be called on its own
	#Checks if player is in the air
	else:
		if not hurt_animation_in_air_played: #Ensures that hurt animation will only play once
			animated_sprite_2d.play("Hurt")
			hurt_animation_in_air_played = true
		
		if not blood_effect_played: #Ensures that blood effect is only played once
			spawn_blood_effect()
			blood_effect_played = true
		
		if not jump_impulse_velocity_applied: #Ensures that the change to y velocity is only applied once
			velocity.y = -200
			jump_impulse_velocity_applied = true
		
		#Acts as the replacement of gravity for the hurt state
		velocity.y += 15
		
		#Checks if player is either facing left or right, and if so changes x velocity accordingly
		if animated_sprite_2d.flip_h:
			#Sets the position of the blood effect to the below position on every frame it is active
			if GameData.blood_effect_in_scene:
				blood_effect_instance.global_position.x = player.global_position.x - 5
				blood_effect_instance.global_position.y = player.global_position.y - 20
			velocity.x = 100
		else:
			#Checks if sprite flip_h is flase and if so flips the blood instance sprite to reach the desired look of the effect
			if not blood_effect_flipped:
				blood_effect_instance.get_node("AnimatedSprite2D").flip_h = true
				blood_effect_flipped = true
			#Sets the position of the blood effect to the below position on every frame it is active
			if GameData.blood_effect_in_scene:
				blood_effect_instance.global_position.x = player.global_position.x + 5
				blood_effect_instance.global_position.y = player.global_position.y - 20
			velocity.x = -100
	
	move_and_slide()

func _on_move_state_hurtbox_area_entered(area):
	#Sets damage that player will take
	damage_to_be_taken = area.damage
	#Upon an enemy hitbox entering the player's hurtbox, the player changes to the hurt state
	if state == ATTACK: #Checks if attack state because if player gets hit during an attack, the reset_all_attack_variables function will not be called as it is meant to be called at the end of the attack animation, which in this case gets canceled
		reset_all_attack_state_variables()
	state = HURT

func _on_crouch_state_hurtbox_area_entered(area):
	#Sets damage that player will take
	damage_to_be_taken = area.damage
	#Upon an enemy hitbox entering the player's hurtbox, the player changes to the hurt state
	if state == ATTACK: #Checks if attack state because if player gets hit during an attack, the reset_all_attack_variables function will not be called as it is meant to be called at the end of the attack animation, which in this case gets canceled
		reset_all_attack_state_variables()
	state = HURT

func _on_ground_pound_start_hurtbox_area_entered(area):
	#Sets damage that player will take
	damage_to_be_taken = area.damage
	#Upon an enemy hitbox entering the player's hurtbox, the player changes to the hurt state
	if state == ATTACK: #Checks if attack state because if player gets hit during an attack, the reset_all_attack_variables function will not be called as it is meant to be called at the end of the attack animation, which in this case gets canceled
		reset_all_attack_state_variables()
	state = HURT

func _on_ground_pound_end_hurtbox_area_entered(area):
	#Sets damage that player will take
	damage_to_be_taken = area.damage
	#Upon an enemy hitbox entering the player's hurtbox, the player changes to the hurt state
	if state == ATTACK: #Checks if attack state because if player gets hit during an attack, the reset_all_attack_variables function will not be called as it is meant to be called at the end of the attack animation, which in this case gets canceled
		reset_all_attack_state_variables()
	state = HURT

func _on_traps_standing_hurtbox_area_entered(area):
	#Sets damage that player will take
	damage_to_be_taken = area.damage
	#Upon an enemy hitbox entering the player's hurtbox, the player changes to the hurt state
	if state == ATTACK: #Checks if attack state because if player gets hit during an attack, the reset_all_attack_variables function will not be called as it is meant to be called at the end of the attack animation, which in this case gets canceled
		reset_all_attack_state_variables()
	state = HURT

func _on_traps_crouched_hurtbox_area_entered(area):
	#Sets damage that player will take
	damage_to_be_taken = area.damage
	#Upon an enemy hitbox entering the player's hurtbox, the player changes to the hurt state
	if state == ATTACK: #Checks if attack state because if player gets hit during an attack, the reset_all_attack_variables function will not be called as it is meant to be called at the end of the attack animation, which in this case gets canceled
		reset_all_attack_state_variables()
	state = HURT

func change_from_hurt_to_move_state():
	blood_effect_played = false
	jump_impulse_velocity_applied = false
	hurt_animation_in_air_played = false
	was_in_the_air = false
	blood_effect_flipped = false
	player_health_updated = false
	previous_animation_stopped = false
	#Resets variables that are meant to be reset in another state
	pogo_velocity_added = false 
	already_jumped_once = false
	#Resets variable to ensure that if player gets hit mid air after jumping out of the crouch state, they will not jump automatically when entering move state
	leaving_crouch_state = false
	#Changes player's state back to move
	start_i_frames()
	if GameData.player_is_dead: #Checks if player is dead and if so changes to the dead state
		state = DEAD
	else:
		if Input.is_action_pressed("Down"):
			state = CROUCH
		else:
			state = MOVE

func disable_attack_hitboxes():
	if attack_1_hitbox.get_node("CollisionShape2D").disabled == false:
		attack_1_hitbox.get_node("CollisionShape2D").disabled = true
	if attack_2_hitbox.get_node("CollisionShape2D").disabled == false:
		attack_2_hitbox.get_node("CollisionShape2D").disabled = true
	if attack_3_hitbox.get_node("CollisionShape2D").disabled == false:
		attack_3_hitbox.get_node("CollisionShape2D").disabled = true
	if attack_4_hitbox.get_node("CollisionShape2D").disabled == false:
		attack_4_hitbox.get_node("CollisionShape2D").disabled = true
	if crouch_attack_1_hitbox.get_node("CollisionShape2D").disabled == false:
		crouch_attack_1_hitbox.get_node("CollisionShape2D").disabled = true
	if crouch_attack_2_hitbox.get_node("CollisionShape2D").disabled == false:
		crouch_attack_2_hitbox.get_node("CollisionShape2D").disabled = true
	if ground_pound_start_hitbox.get_node("CollisionShape2D").disabled == false:
		ground_pound_start_hitbox.get_node("CollisionShape2D").disabled = true
	if ground_pound_end_hitbox.get_node("CollisionShape2D").disabled == false:
		ground_pound_end_hitbox.get_node("CollisionShape2D").disabled = true

func start_i_frames():
	if not GameData.player_is_dead: #Makes sure that i frames dont start if player took a hit that will kill them
		effects_player.play("I-Frames Flicker") #Plays flicker animation to indicate i frames are active
		if not iframes_timer_started: #Starts timer and sets started variable to true to make sure that when player changes state out of hurt state, the calls to enable and disable hurtboxes do not override the i frames
			i_frames_timer.start()
			iframes_timer_started = true

func end_i_frames():
	#Checks if i frames timer has reached its and and if so sets timer started variable to false, enabling the ability for hurtboxes to be reactivated
	if i_frames_timer.time_left == 0 and iframes_timer_started:
		effects_player.play("RESET") #Plays RESET to make sure the sprite is back to the default visual darkness
		iframes_timer_started = false

#Dodge state functions------------------------------------------------------------------------------
func dodge_state(delta):
	if not stamina_updated: #Ensures that stamina is not updated on every single frame of the dodge
		GameData.player_stamina -= 15
		stamina_updated = true
		SoundPlayer.play_player_dodge_sound()
	#Disables all hitboxes
	crouch_state_hurtbox.get_node("CollisionShape2D").disabled = true
	ground_pound_start_hurtbox.get_node("CollisionShape2D").disabled = true
	ground_pound_end_hurtbox.get_node("CollisionShape2D").disabled = true
	move_state_hurtbox.get_node("CollisionShape2D").disabled = true
	animation_player.play("Dodge")
	
	apply_gravity(delta)
	
	#Sets velocity to a constant speed for duration of the dodge depending on the direction the player is facing
	if animated_sprite_2d.flip_h:
		velocity.x = -175
	else:
		velocity.x = 175
	
	if not is_on_floor():
		if not dodge_downtime_timer_started:
			dodge_downtime_timer.start()
			dodge_downtime_timer_started = true
		#Changes state to move
		if state != HURT: #Ensures that if player rolls on the ground, then falls off of a ledge and gets hurt mid air, the ending of the dodge animation player animation will not go off, putting the player back into the move state when they are in the hurt state
			stamina_updated = false #Ensures that when player enters dodge state again, stamina will be updated
			state = MOVE
		state = MOVE
	
	move_and_slide()

func change_from_dodge_to_move_state():
	if is_on_floor():
		#Starts downtime timer and sets timer started variable to true to make sure player cannot roll in rapid succession
		if not dodge_downtime_timer_started:
			dodge_downtime_timer.start()
			dodge_downtime_timer_started = true
		#Changes state to move
		if state != HURT: #Ensures that if player rolls on the ground, then falls off of a ledge and gets hurt mid air, the ending of the dodge animation player animation will not go off, putting the player back into the move state when they are in the hurt state
			stamina_updated = false #Ensures that when player enters dodge state again, stamina will be updated
			state = MOVE

func end_dodge_downtime():
	#Checks if timer has reached its end and if so sets the timer started variable to false, allowing the player to dodge once more
	if dodge_downtime_timer.time_left == 0 and dodge_downtime_timer_started:
		dodge_downtime_timer_started = false

func spawn_dodge_frame_1_effect():
	if state == DODGE:
		var dodge_frame_1 = load("res://Source/Effects/dodge_effect.tscn")
		var dodge_frame_1_instance = dodge_frame_1.instantiate()
		dodge_frame_1_instance.get_node("AnimatedSprite2D").animation = "Frame1"
		if animated_sprite_2d.flip_h:
			dodge_frame_1_instance.get_node("AnimatedSprite2D").flip_h = true
		world.add_child(dodge_frame_1_instance)
		dodge_frame_1_instance.global_position = player.global_position

func spawn_dodge_frame_2_effect():
	if state == DODGE:
		var dodge_frame_2 = load("res://Source/Effects/dodge_effect.tscn")
		var dodge_frame_2_instance = dodge_frame_2.instantiate()
		dodge_frame_2_instance.get_node("AnimatedSprite2D").animation = "Frame2"
		if animated_sprite_2d.flip_h:
			dodge_frame_2_instance.get_node("AnimatedSprite2D").flip_h = true
		world.add_child(dodge_frame_2_instance)
		dodge_frame_2_instance.global_position = player.global_position

func spawn_dodge_frame_3_effect():
	if state == DODGE:
		var dodge_frame_3 = load("res://Source/Effects/dodge_effect.tscn")
		var dodge_frame_3_instance = dodge_frame_3.instantiate()
		dodge_frame_3_instance.get_node("AnimatedSprite2D").animation = "Frame3"
		if animated_sprite_2d.flip_h:
			dodge_frame_3_instance.get_node("AnimatedSprite2D").flip_h = true
		world.add_child(dodge_frame_3_instance)
		dodge_frame_3_instance.global_position = player.global_position

func spawn_dodge_frame_4_effect():
	if state == DODGE:
		var dodge_frame_4 = load("res://Source/Effects/dodge_effect.tscn")
		var dodge_frame_4_instance = dodge_frame_4.instantiate()
		dodge_frame_4_instance.get_node("AnimatedSprite2D").animation = "Frame4"
		if animated_sprite_2d.flip_h:
			dodge_frame_4_instance.get_node("AnimatedSprite2D").flip_h = true
		world.add_child(dodge_frame_4_instance)
		dodge_frame_4_instance.global_position = player.global_position

#Dead state functions-------------------------------------------------------------------------------
func dead_state():
	if !dead_animation_played:
		animated_sprite_2d.stop()
		animation_player.play("Dead")
		dead_animation_played = true

func change_to_death_screen():
	queue_free()
	get_tree().change_scene_to_file("res://Source/UI and Screens/Screens/death_screen.tscn")

#Heal state functions-------------------------------------------------------------------------------
func heal_state(delta):
	GameData.player_stamina += 30 * delta #Updates player stamina
	
	velocity.x = 0 #Ensures that velocity is 0 when re-entering the move state
	
	#Adjusts sprite position to compensate that the heal animation is 1 pixel off
	if animated_sprite_2d.flip_h:
		animated_sprite_2d.position.x = -1
	else:
		animated_sprite_2d.position.x = 1
	
	if not heal_state_health_updated: #Ensures player health is only updated once when entering this state
		animation_player.play("Heal") #Plays heal animation
		heal_state_health_updated = true
	
	await animation_player.animation_finished #Waits until the heal animation is complete to change back into the move state
	heal_state_health_updated = false #Resets variable back to original value to ensure that the next time this state is entered, the player health will be updated as intended
	state = MOVE #Changes to move state

func apply_health_update():
	SoundPlayer.play_potion_sound()
	GameData.player_potions -= 1
	GameData.player_health += 50

#Checkpoint state functions-------------------------------------------------------------------------
func checkpoint_state():
	if !checkpoint_animation_played: #Makes sure animation is only played once
		velocity.x = 0
		velocity.y = 0
		if level_transition_detection_zone.can_see_area():
			animation_player.play("LevelTransition")
		else:
			animation_player.play("Checkpoint")
		checkpoint_animation_played = true
	#Disables all hurtboxes
	crouch_state_hurtbox.get_node("CollisionShape2D").disabled = true 
	ground_pound_start_hurtbox.get_node("CollisionShape2D").disabled = true
	ground_pound_end_hurtbox.get_node("CollisionShape2D").disabled = true
	move_state_hurtbox.get_node("CollisionShape2D").disabled = true

func leave_checkpoint_state():
	checkpoint_animation_played = false #Resets variable to initial value
	state = MOVE

func _on_checkpoint_detection_area_entered(_area):
	can_set_checkpoint = true

func _on_checkpoint_detection_area_exited(_area):
	can_set_checkpoint = false

#Effects functions----------------------------------------------------------------------------------
func spawn_dust_landing_effect():
	#Loads in dust effect scene, instantiates it, adds it to the current scene, and sets its position to the position of the player
	var dust_effect = load("res://Source/Effects/dust_landing_effect.tscn")
	var dust_effect_instance = dust_effect.instantiate()
	world.add_child(dust_effect_instance)
	dust_effect_instance.global_position = player.global_position

func spawn_blood_effect():
	#Loads in blood effect scene, instantiates it then adds it to the current scene, variable declaration is outside of this function as to use the variable outside, and position is not set here as well as it will change depending on the circumstances of the hurt state
	blood_effect = load("res://Source/Effects/blood_effect.tscn")
	blood_effect_instance = blood_effect.instantiate()
	world.add_child(blood_effect_instance)

func spawn_pogo_effect():
	#Loads in pogo effect scene, instantiates it, adds it to the current scene, and sets its position to the position of the player
	var pogo_effect = load("res://Source/Effects/pogo_effect.tscn")
	var pogo_effect_instance = pogo_effect.instantiate()
	world.add_child(pogo_effect_instance)
	pogo_effect_instance.global_position.x = player.global_position.x
	pogo_effect_instance.global_position.y = player.global_position.y - 15

func spawn_heal_effect():
	#Loads in heal effect scene, instantiates it, adds it to the current scene, and sets its position to the position of the player
	var heal_effect = load("res://Source/Effects/heal_effect.tscn")
	var heal_effect_instance = heal_effect.instantiate()
	world.add_child(heal_effect_instance)
	heal_effect_instance.global_position.x = player.global_position.x
	heal_effect_instance.global_position.y = player.global_position.y - 27

#Other functions------------------------------------------------------------------------------------
func clamp_y_velocity():
	#Checks if y velocity ever exceeds the y_velocity_cap, and if so, sets the y velocity to y_velocity_cap
	if(velocity.y > y_velocity_cap):
		velocity.y = y_velocity_cap

func apply_gravity(delta):
	#Adds gravity * delta each frame to the y velocity
	velocity.y += gravity * delta

func connect_camera(camera):
	var camera_path = camera.get_path()
	remote_transform_2d.remote_path = camera_path

func adjust_player_facing_left_autoload_variable():
	#Changes the player_facing_left global variable depending on the animated sprites flip h
	if animated_sprite_2d.flip_h:
		GameData.player_facing_left = true
	else:
		GameData.player_facing_left = false

func _on_attack_1_hitbox_area_entered(_area):
	SoundPlayer.play_player_attack_sound()
	GameData.player_mana += 5 #If player hits an enemy with a regular attack, player gains mana

func _on_attack_2_hitbox_area_entered(_area):
	SoundPlayer.play_player_attack_sound()
	GameData.player_mana += 5 #If player hits an enemy with a regular attack, player gains mana

func _on_attack_3_hitbox_area_entered(_area):
	SoundPlayer.play_player_attack_sound()
	GameData.player_mana += 5 #If player hits an enemy with a regular attack, player gains mana

func _on_attack_4_hitbox_area_entered(_area):
	SoundPlayer.play_player_attack_sound()
	GameData.player_mana += 5 #If player hits an enemy with a regular attack, player gains mana

func _on_crouch_attack_1_hitbox_area_entered(_area):
	SoundPlayer.play_player_attack_sound()
	GameData.player_mana += 5 #If player hits an enemy with a regular attack, player gains mana

func _on_crouch_attack_2_hitbox_area_entered(_area):
	SoundPlayer.play_player_attack_sound()
	GameData.player_mana += 5 #If player hits an enemy with a regular attack, player gains mana

func _on_ground_pound_end_hitbox_area_entered(_area):
	SoundPlayer.play_player_attack_sound()
	GameData.player_mana += 5 #If player hits an enemy with a regular attack, player gains mana

func set_player_position():
	GameData.player_position = player.global_position

func player_movement_disabled():
	velocity.x = 0
	velocity.y = 225
	already_jumped_once = false #Makes sure to reset variable to original value, so that when movement is enabled again player can jump
	if state != CHECKPOINT:
		if !is_on_floor():
			animated_sprite_2d.play("Fall")
		else:
			animated_sprite_2d.play("Idle")
	move_and_slide()

func _on_platform_detector_area_entered(_area):
	colliding_with_platform = true

func _on_platform_detector_area_exited(_area):
	colliding_with_platform = false

func update_player_damage():
	if GameData.player_attack_upgrade_received:
		attack_1_hitbox.damage = 2
		attack_2_hitbox.damage = 2
		attack_3_hitbox.damage = 2
		attack_4_hitbox.damage = 3
		crouch_attack_1_hitbox.damage = 2
		crouch_attack_2_hitbox.damage = 2
		ground_pound_end_hitbox.damage = 4
	else:
		attack_1_hitbox.damage = 1
		attack_2_hitbox.damage = 1
		attack_3_hitbox.damage = 1
		attack_4_hitbox.damage = 2
		crouch_attack_1_hitbox.damage = 1
		crouch_attack_2_hitbox.damage = 1
		ground_pound_end_hitbox.damage = 2
