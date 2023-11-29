extends CharacterBody2D

enum{IDLE, RISE, SCREAM, BUFFER, SLASHCHASE, SLASH, ZOOMSTARTUP, ZOOM, SPELL, SMASH, DEATH, PHASE2SCREAM}

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var scream_timer = $Timers/ScreamTimer
@onready var buffer_timer = $Timers/BufferTimer
@onready var stage_1_boss = $"."
@onready var melee_detection_zone = $MeleeDetectionZone
@onready var animation_player = $AnimatedSprite2D/AnimationPlayer
@onready var effects_player = $AnimatedSprite2D/EffectsPlayer
@onready var hitbox_pivot = $HitboxPivot
@onready var slash_hitbox = $HitboxPivot/SlashHitbox
@onready var rise_timer_smash_ = $"Timers/RiseTimer(SMASH)"
@onready var linger_timer_smash_ = $"Timers/LingerTimer(SMASH)"
@onready var smash_wait_timer_smash_ = $"Timers/SmashWaitTimer(SMASH)"
@onready var zoom_effect_timer = $Timers/ZoomEffectTimer
@onready var hurtbox = $Hurtbox
@onready var phase_2_wait_timer = $Timers/Phase2WaitTimer
@onready var hurtbox_entered_timer = $Timers/HurtboxEnteredTimer
@onready var blink_white_player = $AnimatedSprite2D/BlinkWhitePlayer
@onready var death_scream_timer = $Timers/DeathScreamTimer
@onready var body_hitbox = $BodyHitbox

#Scream state variables
var scream_timer_started = false

#Buffer state variables
var buffer_timer_started = false
var slash_attack_complete = false
var zoom_attack_complete = false
var smash_attack_complete = false
var spell_attack_complete = false
var rng = RandomNumberGenerator.new()

#Slash Chase state variables
var player_position_located = false #ALSO USED IN SPELL STATE
var player_position = Vector2.ZERO #ALSO USED IN SPELL STATE
var num_of_times_slashed = 0
var slashes_necessary = 2
var player_to_the_left = false #ALSO USED IN SPELL STATE

#Zoom Startup state variables
var zoom_startup_indicator_played = false
var on_left_side = false

#Zoom state variables
var arena_halfway_point : int
var started_zooming = false
var num_of_zooms = 0
var num_of_zooms_necessary = 3
var zoom_effect_timer_started = false

#Slash state variables
var attack_played = false

#Smash state variables
var rise_timer_started = false
var linger_timer_started = false
var smash_wait_timer_started = false
var acceleration = 1000000
var num_of_smashes = 0
var num_of_smashes_necessary = 3
var smash_instances_added = false

#Spell state variables
var num_of_spells_cast = 0
var num_of_spells_necessary = 2

#Death state variables
var death_scream_timer_started = false
var death_played = false

#Other variables
var state = IDLE
var speed = 100
var zoom_speed = 600
var phase_2_will_be_entered = false
var phase_2_scream_already_entered = false
var phase_2_wait_timer_started = false
var hurtbox_entered_timer_started = false

func _ready():
	hurtbox.get_node("CollisionShape2D").disabled = true
	
	arena_halfway_point = stage_1_boss.global_position.x - 165
	slash_hitbox.get_node("CollisionShape2D").disabled = true
	adjust_sprite_position()

func _physics_process(delta):
	adjust_sprite_position()
	match state:
		IDLE:
			idle_state()
		RISE:
			rise_state()
		SCREAM:
			scream_state()
		BUFFER:
			buffer_state()
		SLASHCHASE:
			slash_chase_state()
		SLASH:
			slash_state()
		ZOOMSTARTUP:
			zoom_startup_state()
		ZOOM:
			zoom_state()
		SMASH:
			smash_state(delta)
		SPELL:
			spell_state()
		DEATH:
			death_state()
		PHASE2SCREAM:
			phase_2_scream_state()
		

#Idle state functions-------------------------------------------------------------------------------
func idle_state():
	if GameData.player_movement_disabled:
		state = RISE

#Rise state functions-------------------------------------------------------------------------------
func rise_state():
	animated_sprite_2d.play("Rise")
	await animated_sprite_2d.animation_finished
	state = SCREAM

#Scream state functions-----------------------------------------------------------------------------
func scream_state():
	GameData.boss_1_active = true
	if !scream_timer_started:
		GameData.camera.start_shake(10)
		scream_timer.start()
		SoundPlayer.play_stage_1_boss_music()
		scream_timer_started = true
	
	if scream_timer.time_left == 0 and scream_timer_started:
		scream_timer_started = false
		GameData.camera.stop_shake()
		hurtbox.get_node("CollisionShape2D").disabled = false
		state = BUFFER

#Buffer state functions-----------------------------------------------------------------------------
func buffer_state():
	if slash_attack_complete and zoom_attack_complete and smash_attack_complete and spell_attack_complete:
		slash_attack_complete = false
		zoom_attack_complete = false
		smash_attack_complete = false
		spell_attack_complete = false
	
	animated_sprite_2d.play("Idle")
	
	if !buffer_timer_started:
		buffer_timer.start()
		buffer_timer_started = true
	
	if buffer_timer.time_left == 0 and buffer_timer_started:
		var rng_buffer_switch = rng.randi_range(0,3)
		
		if slash_attack_complete and rng_buffer_switch == 0:
			if !zoom_attack_complete:
				rng_buffer_switch = 1
			elif !smash_attack_complete:
				rng_buffer_switch = 2
			elif !spell_attack_complete:
				rng_buffer_switch = 3
		elif zoom_attack_complete and rng_buffer_switch == 1:
			if !slash_attack_complete:
				rng_buffer_switch = 0
			elif !smash_attack_complete:
				rng_buffer_switch = 2
			elif !spell_attack_complete:
				rng_buffer_switch = 3
		elif smash_attack_complete and rng_buffer_switch == 2:
			if !slash_attack_complete:
				rng_buffer_switch = 0
			elif !zoom_attack_complete:
				rng_buffer_switch = 1
			elif !spell_attack_complete:
				rng_buffer_switch = 3
		elif spell_attack_complete and rng_buffer_switch == 3:
			if !slash_attack_complete:
				rng_buffer_switch = 0
			elif !zoom_attack_complete:
				rng_buffer_switch = 1
			elif !smash_attack_complete:
				rng_buffer_switch = 2
		
		if rng_buffer_switch == 0:
			slash_attack_complete = true
			entering_slash_chase_state()
			if state != DEATH:
				state = SLASHCHASE
		elif rng_buffer_switch == 1:
			zoom_attack_complete = true
			if state != DEATH:
				state = ZOOMSTARTUP
		elif rng_buffer_switch == 2:
			smash_attack_complete = true
			entering_smash_state()
			if state != DEATH:
				state = SMASH
		else:
			spell_attack_complete = true
			entering_spell_state()
			if state != DEATH:
				state = SPELL

func entering_buffer_state():
	buffer_timer_started = false
	num_of_smashes = 0
	num_of_times_slashed = 0
	num_of_zooms = 0

#Slash Chase state functions------------------------------------------------------------------------
func slash_chase_state():
	if !player_position_located:
		player_position.x = roundf(GameData.player_position.x)
		player_position.y = roundf(GameData.player_position.y)
		if stage_1_boss.global_position.x > player_position.x:
			player_to_the_left = true
			hitbox_pivot.scale.x = -1
			animated_sprite_2d.flip_h = true
		else:
			animated_sprite_2d.flip_h = false
			hitbox_pivot.scale.x = 1
		player_position_located = true
	
	if !melee_detection_zone.can_see_player():
		animated_sprite_2d.play("Walk")
		if player_to_the_left:
			velocity.x = -speed
		else:
			velocity.x = speed
	else:
		num_of_times_slashed += 1
		if state != DEATH:
			state = SLASH
	
	move_and_slide()

func entering_slash_chase_state():
	player_position_located = false
	player_position = Vector2.ZERO
	player_to_the_left = false

#Slash state functions------------------------------------------------------------------------------
func slash_state():
	velocity.x = 0
	if !attack_played:
		animation_player.play("Slash")
		attack_played = true

func end_of_slash():
	attack_played = false
	entering_slash_chase_state()
	if num_of_times_slashed == slashes_necessary:
		if phase_2_will_be_entered and !phase_2_scream_already_entered:
				phase_2_scream_already_entered = true
				if state != DEATH:
					state = PHASE2SCREAM
		else:
			entering_buffer_state()
			if state != DEATH:
				state = BUFFER
	else:
		if state != DEATH:
			state = SLASHCHASE

#Zoom Startup state functions-----------------------------------------------------------------------
func zoom_startup_state():
	velocity.x = 0
	animated_sprite_2d.play("Idle(1Frame)")
	if stage_1_boss.global_position.x < arena_halfway_point:
		on_left_side = true
		animated_sprite_2d.flip_h = false
	else:
		animated_sprite_2d.flip_h = true
	if !zoom_startup_indicator_played:
		effects_player.play("Zoom Startup")
		zoom_startup_indicator_played = true

func zoom_startup_finished():
	zoom_startup_indicator_played = false
	if state != DEATH:
		state = ZOOM

#Zoom state functions-------------------------------------------------------------------------------
func zoom_state():
	if !zoom_effect_timer_started:
		zoom_effect_timer.start()
		zoom_effect_timer_started = true
	
	if zoom_effect_timer.time_left == 0 and zoom_effect_timer_started:
		var world = get_tree().current_scene
		var zoom_effect = null
		if animated_sprite_2d.flip_h:
			zoom_effect = load("res://Source/Effects/boss_zoom_effect_left.tscn")
		else:
			zoom_effect = load("res://Source/Effects/boss_zoom_effect_right.tscn")
		var zoom_effect_instance = zoom_effect.instantiate()
		world.add_child(zoom_effect_instance)
		zoom_effect_instance.global_position = stage_1_boss.global_position
		zoom_effect_timer_started = false
	
	if !started_zooming:
		num_of_zooms += 1
		started_zooming = true
		if !on_left_side:
			velocity.x = -zoom_speed
		else:
			velocity.x = zoom_speed
	
	move_and_slide()
	
	if started_zooming and is_on_wall():
		started_zooming = false
		velocity.x = 0
		on_left_side = false
		if num_of_zooms == num_of_zooms_necessary:
			if phase_2_will_be_entered and !phase_2_scream_already_entered:
				phase_2_scream_already_entered = true
				if state != DEATH:
					state = PHASE2SCREAM
			else:
				entering_buffer_state()
				if state != DEATH:
					state = BUFFER
		else:
			if state != DEATH:
				state = ZOOMSTARTUP

func spawn_zoom_blink_effect():
	var world = get_tree().current_scene
	var blink_effect_1 = load("res://Source/Effects/boss_zoom_blink_effect.tscn")
	var blink_effect_2 = load("res://Source/Effects/boss_zoom_blink_effect.tscn")
	var blink_effect_1_instance = blink_effect_1.instantiate()
	var blink_effect_2_instance = blink_effect_2.instantiate()
	world.add_child(blink_effect_1_instance)
	world.add_child(blink_effect_2_instance)
	blink_effect_1_instance.get_node("Sprite2D").flip_h = true
	if animated_sprite_2d.flip_h:
		blink_effect_1_instance.global_position.x = stage_1_boss.global_position.x - 24
		blink_effect_1_instance.global_position.y = stage_1_boss.global_position.y - 70
		blink_effect_2_instance.global_position.x = stage_1_boss.global_position.x - 1
		blink_effect_2_instance.global_position.y = stage_1_boss.global_position.y - 70
	else:
		blink_effect_1_instance.global_position.x = stage_1_boss.global_position.x + 1
		blink_effect_1_instance.global_position.y = stage_1_boss.global_position.y - 70
		blink_effect_2_instance.global_position.x = stage_1_boss.global_position.x + 24
		blink_effect_2_instance.global_position.y = stage_1_boss.global_position.y - 70

#Smash state functions------------------------------------------------------------------------------
func smash_state(delta):
	if !rise_timer_started:
		animated_sprite_2d.play("Idle(1Frame)")
		num_of_smashes += 1
		velocity.y = move_toward(velocity.y, -300, acceleration * delta)
		rise_timer_smash_.start()
		rise_timer_started = true
	
	if rise_timer_smash_.time_left == 0 and rise_timer_started:
		velocity.y = 0
		if !linger_timer_started:
			linger_timer_smash_.start()
			linger_timer_started = true
	
	if linger_timer_smash_.time_left == 0 and linger_timer_started:
		velocity.y = 1000
	
	if is_on_floor() and linger_timer_started:
		if !smash_instances_added:
			var world = get_tree().current_scene
			var smash_landing_effect = load("res://Source/Effects/boss_landing_effect.tscn")
			var smash_landing_effect_instance = smash_landing_effect.instantiate()
			world.add_child(smash_landing_effect_instance)
			smash_landing_effect_instance.global_position = stage_1_boss.global_position
			var shockwave_1 = load("res://Source/Actors/Enemies/Enemy Resources/boss_shockwave_right.tscn")
			var shockwave_2 = load("res://Source/Actors/Enemies/Enemy Resources/boss_shockwave_left.tscn")
			var shockwave_1_instance = shockwave_1.instantiate()
			var shockwave_2_instance = shockwave_2.instantiate()
			world.add_child(shockwave_1_instance)
			world.add_child(shockwave_2_instance)
			shockwave_1_instance.global_position = stage_1_boss.global_position
			shockwave_2_instance.global_position = stage_1_boss.global_position
			smash_instances_added = true
			
		if !smash_wait_timer_started:
			smash_wait_timer_smash_.start()
			smash_wait_timer_started = true
			animated_sprite_2d.play("Idle")
	
	if smash_wait_timer_smash_.time_left == 0 and smash_wait_timer_started:
		if num_of_smashes == num_of_smashes_necessary:
			if phase_2_will_be_entered and !phase_2_scream_already_entered:
				phase_2_scream_already_entered = true
				if state != DEATH:
					state = PHASE2SCREAM
			else:
				entering_buffer_state()
				if state != DEATH:
					state = BUFFER
		else:
			entering_smash_state()
			if state != DEATH:
				state = SMASH
	
	move_and_slide()

func entering_smash_state():
	rise_timer_started = false
	linger_timer_started = false
	smash_wait_timer_started = false
	smash_instances_added = false

#Spell state functions------------------------------------------------------------------------------
func spell_state():
	if !player_position_located:
		player_position.x = roundf(GameData.player_position.x)
		player_position.y = roundf(GameData.player_position.y)
		if stage_1_boss.global_position.x > player_position.x:
			player_to_the_left = true
			adjust_sprite_position()
			animated_sprite_2d.flip_h = true
		else:
			animated_sprite_2d.flip_h = false
			adjust_sprite_position()
		if phase_2_scream_already_entered:
			animated_sprite_2d.play("ShieldUp(FAST)")
		else:
			animated_sprite_2d.play("ShieldUp")
		player_position_located = true

func entering_spell_state():
	player_position_located = false
	player_to_the_left = false
	num_of_spells_cast = 0
	player_position = Vector2.ZERO

#Phase 2 Scream state functions---------------------------------------------------------------------
func phase_2_scream_state():
	animated_sprite_2d.play("Idle(1Frame)")
	if !phase_2_wait_timer_started:
		player_position.x = roundf(GameData.player_position.x)
		player_position.y = roundf(GameData.player_position.y)
		if stage_1_boss.global_position.x > player_position.x:
			animated_sprite_2d.flip_h = true
		else:
			animated_sprite_2d.flip_h = false
		phase_2_wait_timer.start()
		phase_2_wait_timer_started = true
	
	if phase_2_wait_timer.time_left == 0 and phase_2_wait_timer_started:
		if !scream_timer_started:
			hurtbox.get_node("CollisionShape2D").disabled = true
			GameData.camera.start_shake(15)
			scream_timer.start()
			scream_timer_started = true
	
	if scream_timer.time_left == 0 and scream_timer_started:
		GameData.camera.stop_shake()
		hurtbox.get_node("CollisionShape2D").disabled = false
		slashes_necessary =  4
		speed = 150
		num_of_zooms_necessary = 5
		zoom_speed = 900
		smash_wait_timer_smash_.wait_time = 0.2
		rise_timer_smash_.wait_time = 0.35
		num_of_smashes_necessary = 6
		num_of_spells_necessary = 4
		entering_buffer_state()
		if state != DEATH:
			state = BUFFER

#Death state functions------------------------------------------------------------------------------
func death_state():
	velocity.x = 0
	SoundPlayer.stop_stage_1_boss_music()
	body_hitbox.get_node("CollisionShape2D").disabled = true
	hurtbox.get_node("CollisionShape2D").disabled = true
	velocity.y = 300
	move_and_slide()
	
	if is_on_floor():
		if !death_scream_timer_started:
			SoundPlayer.play_boss_death_sound()
			animated_sprite_2d.play("Idle(1Frame)")
			death_scream_timer.start()
			GameData.camera.start_shake(10)
			death_scream_timer_started = true
	
	if death_scream_timer.time_left == 0 and death_scream_timer_started:
		if !death_played:
			animation_player.play("Death")
			GameData.camera.stop_shake()
			death_played = true

func delete():
	GameData.boss_1_dead = true
	queue_free()

#Other functions------------------------------------------------------------------------------------
func adjust_sprite_position():
	#Depending on the sprites flip_h, chnages sprites x position to account for pivot point not being centered
	if animated_sprite_2d.flip_h:
		animated_sprite_2d.position.x = 4
	else:
		animated_sprite_2d.position.x = -4

func _on_animated_sprite_2d_animation_finished():
	if state == SPELL:
		if num_of_spells_cast == num_of_spells_necessary:
			if phase_2_will_be_entered and !phase_2_scream_already_entered:
				phase_2_scream_already_entered = true
				if state != DEATH:
					state = PHASE2SCREAM
			else:
				entering_buffer_state()
				if state != DEATH:
					state = BUFFER
		var world = get_tree().current_scene
		var boss_spell = load("res://Source/Actors/Enemies/Enemy Resources/stage_1_boss_spell.tscn")
		var boss_spell_instance = boss_spell.instantiate()
		world.add_child(boss_spell_instance)
		boss_spell_instance.global_position.x = GameData.player_position.x
		boss_spell_instance.global_position.y = GameData.player_position.y - 30
		if phase_2_scream_already_entered:
			animated_sprite_2d.play("ShieldUp(FAST)")
		else:
			animated_sprite_2d.play("ShieldUp")
		num_of_spells_cast += 1

func _on_hurtbox_area_entered(area):
	GameData.boss_1_health -= area.damage
	blink_white_player.play("BlinkWhite")
	if GameData.boss_1_health <= 50 and !phase_2_will_be_entered:
		phase_2_will_be_entered = true
	if GameData.boss_1_health <= 0:
		animated_sprite_2d.stop()
		animation_player.stop()
		state = DEATH
