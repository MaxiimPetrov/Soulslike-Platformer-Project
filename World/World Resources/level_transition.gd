extends Node2D

enum {IDLE, TRANSITIONBUFFER, TRANSITION}
enum{NONE, BOOMERANG, ARCHINGDISC, FIREBALL}

@onready var actor_detection_zone = $ActorDetectionZone
@onready var checkpoint = $"."
@onready var label = $Label
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer

@export_file("*.tscn") var level_transition: String

var state = IDLE

func _ready():
	GameData.can_save_checkpoint = true
	label.visible = false
	set_process(false)

func _process(_delta):
	match state:
		IDLE:
			idle_state()
		TRANSITIONBUFFER:
			transition_buffer_state()
		TRANSITION:
			transition_state()

func idle_state():
	if actor_detection_zone.can_see_player():
		label.visible = true
	else:
		label.visible = false
	if Input.is_action_just_pressed("Interact") and actor_detection_zone.can_see_player():
		label.visible = false
		state = TRANSITIONBUFFER

func transition_buffer_state():
	animated_sprite_2d.position.y = -49.5
	animated_sprite_2d.play("Transition(START)")
	await animated_sprite_2d.animation_finished
	state = TRANSITION

func transition_state():
	GameData.player_movement_disabled = true
	animated_sprite_2d.play("Transition(END)")
	animation_player.play("Transition")

func change_level():
	SoundPlayer.stop_tutorial_music()
	SoundPlayer.stop_shop_music()
	GameData.player_health = GameData.player_max_health
	GameData.player_mana = 0
	GameData.player_stamina = GameData.player_max_stamina
	GameData.player_ability = NONE
	get_tree().change_scene_to_file(level_transition)

func _on_visible_on_screen_notifier_2d_screen_entered():
	set_process(true)

func _on_visible_on_screen_notifier_2d_screen_exited():
	set_process(false)
