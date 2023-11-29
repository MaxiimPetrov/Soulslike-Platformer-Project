extends CharacterBody2D

enum{NONE, BOOMERANG, ARCHINGDISC, FIREBALL}

@onready var timer = $Timer
@onready var animation_player = $AnimationPlayer

func _ready():
	SoundPlayer.play_ability_pickup_sound()
	velocity.y = -15
	GameData.player_ability = BOOMERANG
	timer.start()

func _physics_process(_delta):
	move_and_slide()
	if timer.time_left == 0:
		velocity.y = 0
		animation_player.play("Fade Out")

func remove_from_scene():
		queue_free()
