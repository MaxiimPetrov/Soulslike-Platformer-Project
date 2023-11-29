extends Node2D

enum {IDLE, BUFFERTOSAVED, SAVED, BUFFERTOIDLE}

@onready var actor_detection_zone = $ActorDetectionZone
@onready var interact_label = $InteractLabel
@onready var saved_label = $SavedLabel
@onready var checkpoint = $"."
@onready var buffer_to_saved_timer = $Timers/BufferToSavedTimer
@onready var saved_timer = $Timers/SavedTimer
@onready var buffer_to_idle_timer = $Timers/BufferToIdleTimer

var state = IDLE
var buffer_to_idle_timer_started = false
var buffer_to_saved_timer_started = false
var saved_timer_started = false

func _ready():
	GameData.can_save_checkpoint = true
	set_process(false)

func _process(_delta):
	match state:
		IDLE:
			idle_state()
		BUFFERTOSAVED:
			buffer_to_saved_state()
		SAVED:
			saved_state()
		BUFFERTOIDLE:
			buffer_to_idle_state()

func idle_state():
	GameData.can_save_checkpoint = true
	if actor_detection_zone.can_see_player() and GameData.can_save_checkpoint:
		interact_label.visible = true
	else:
		interact_label.visible = false
	
	if actor_detection_zone.can_see_player() and Input.is_action_just_pressed("Interact") and GameData.player_can_kneel:
		interact_label.visible = false
		state = BUFFERTOSAVED

func buffer_to_saved_state():
	interact_label.visible = false
	GameData.can_save_checkpoint = false
	
	if !buffer_to_saved_timer_started:
		var world = get_tree().current_scene
		var checkpoint_effect = load("res://Source/Effects/checkpoint_effect.tscn")
		var checkpoint_effect_instance = checkpoint_effect.instantiate()
		world.add_child(checkpoint_effect_instance)
		checkpoint_effect_instance.global_position.x = checkpoint.global_position.x + 0.5
		checkpoint_effect_instance.global_position.y = checkpoint.global_position.y - 47
		buffer_to_saved_timer.start()
		buffer_to_saved_timer_started = true
	
	if buffer_to_saved_timer.time_left == 0 and buffer_to_saved_timer_started:
		buffer_to_saved_timer_started = false
		saved_label.visible = true
		state = SAVED

func saved_state():
	GameData.player_spawn_position = checkpoint.global_position
	GameData.player_coins_saved = GameData.player_coins
	GameData.player_potions_saved = GameData.player_potions
	
	if !saved_timer_started:
		saved_timer.start()
		saved_timer_started = true
	
	if saved_timer.time_left == 0 and saved_timer_started:
		saved_timer_started = false
		state = BUFFERTOIDLE

func buffer_to_idle_state():
	if !buffer_to_idle_timer_started:
		buffer_to_idle_timer.start()
		buffer_to_idle_timer_started = true
	
	if buffer_to_idle_timer.time_left == 0 and buffer_to_idle_timer_started:
		buffer_to_idle_timer_started = false
		saved_label.visible = false
		state = IDLE

func _on_visible_on_screen_notifier_2d_screen_entered():
	set_process(true)

func _on_visible_on_screen_notifier_2d_screen_exited():
	set_process(false)
