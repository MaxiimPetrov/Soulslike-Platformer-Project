extends Node2D

@onready var player = $Player
@onready var camera = $Camera

func _ready():
	SoundPlayer.play_tutorial_music()
	player.connect_camera(camera)
	GameData.player_health = 25
	GameData.player_mana = 0
	GameData.player_movement_disabled = false
	camera.limit_left = 0
	camera.limit_bottom = 304
	camera.limit_top = 0
	camera.limit_right = 4144
