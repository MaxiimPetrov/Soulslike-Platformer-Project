extends Node2D

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer

func _ready():
	animated_sprite_2d.scale.x = 1
	animated_sprite_2d.scale.y = 1
	animated_sprite_2d.play("Startup")

func delete():
	queue_free()

func _process(_delta):
	if GameData.player_is_dead:
		queue_free()

func _on_animated_sprite_2d_animation_finished():
	animation_player.play("Explode")
