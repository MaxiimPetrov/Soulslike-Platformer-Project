extends Node2D

@onready var animated_sprite_2d = $AnimatedSprite2D
@export var left = false

func _ready():
	if left:
		animated_sprite_2d.flip_h = true

func _process(_delta):
	if GameData.player_is_dead:
		queue_free()

func _on_animated_sprite_2d_animation_finished():
	queue_free()
