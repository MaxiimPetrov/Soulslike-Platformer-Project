extends Node2D

func _ready():
	GameData.blood_effect_in_scene = true

func _on_animated_sprite_2d_animation_finished():
	GameData.blood_effect_in_scene = false
	queue_free()
