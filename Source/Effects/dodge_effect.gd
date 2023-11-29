extends Node2D

@onready var animated_sprite_2d = $AnimatedSprite2D

func _process(_delta):
	animated_sprite_2d.self_modulate.a -= 0.1
	if animated_sprite_2d.self_modulate.a == 0:
		queue_free()
