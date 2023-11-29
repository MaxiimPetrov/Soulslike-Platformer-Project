extends Node2D

@onready var animated_sprite_2d = $AnimatedSprite2D

func _ready():
	if GameData.player_facing_left:
		animated_sprite_2d.flip_h = true

func _on_animated_sprite_2d_animation_finished():
	queue_free()
