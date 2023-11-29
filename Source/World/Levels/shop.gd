extends Node2D

@onready var color_rect = $CanvasLayer/ColorRect

var player_movement_enabled_again = false

func _ready():
	SoundPlayer.play_shop_music()
	color_rect.visible = true
	GameData.player_movement_disabled = true

func _process(delta):
	color_rect.self_modulate.a -= 0.75 * delta
	if color_rect.self_modulate.a <= 0:
		if !player_movement_enabled_again:
			GameData.player_movement_disabled = false
			player_movement_enabled_again = true
