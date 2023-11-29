extends Node2D

@onready var player = $Player
@onready var camera = $Camera
@onready var boss_barrier_1 = $FillerBlocks/BossBarrier1
@onready var boss_barrier_2 = $FillerBlocks/BossBarrier2

func _ready():
	SoundPlayer.play_stage_1_music()
	player.connect_camera(camera)
	camera.limit_right = 3376
	camera.limit_top = 0
	camera.limit_bottom = 304
	camera.limit_left = -160
	player.global_position = GameData.player_spawn_position
	GameData.player_movement_disabled = false

func _process(_delta):
	if GameData.boss_1_dead:
		camera.limit_right = 9456
		boss_barrier_2.get_node("CollisionShape2D").set_deferred("disabled", true)

func _on_change_camera_area_body_entered(_body):
	camera.limit_bottom = 975
	camera.limit_left = 2816
	camera.limit_right = 9456
	camera.limit_top = 288

func _on_change_camera_area_3_body_entered(_body):
	camera.limit_right = 3376
	camera.limit_top = 0
	camera.limit_bottom = 304
	camera.limit_left = 0

func _on_change_camera_area_5_body_entered(_body):
	camera.limit_bottom = 304
	camera.limit_left = 5984
	camera.limit_top = 0

func _on_change_camera_area_6_body_entered(_body):
	camera.limit_bottom = 975
	camera.limit_top = 288

func _on_change_camera_area_7_body_entered(_body):
	camera.limit_bottom = 975
	camera.limit_left = 2816
	camera.limit_right = 9456
	camera.limit_top = 288

func _on_change_camera_area_8_body_entered(_body):
	camera.limit_bottom = 304
	camera.limit_left = 5984
	camera.limit_top = 0
	camera.limit_right = 9456

func _on_change_camera_area_2_body_entered(_body):
	camera.limit_bottom = 0
	camera.limit_right = 9456
	camera.limit_top = 0

func _on_disable_player_movement_area_area_entered(_area):
	SoundPlayer.stop_stage_1_music()
	boss_barrier_1.get_node("CollisionShape2D").set_deferred("disabled", false)
	boss_barrier_2.get_node("CollisionShape2D").set_deferred("disabled", false)
	camera.limit_left = 8576
	camera.limit_right = 9145
