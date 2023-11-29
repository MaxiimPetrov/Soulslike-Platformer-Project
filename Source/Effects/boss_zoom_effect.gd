extends Node2D

@onready var sprite_2d = $Sprite2D

func _process(_delta):
	sprite_2d.self_modulate.a -= 0.05
	if sprite_2d.self_modulate.a == 0:
		queue_free()
