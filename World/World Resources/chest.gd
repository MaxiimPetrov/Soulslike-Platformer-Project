extends Node2D

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var actor_detection_zone = $ActorDetectionZone
@onready var chest = $"."
@onready var label = $Label

@export var facing_right = false
@export_file("*.tscn") var collectible: String

var opened = false
var direction_set = false

func _process(_delta):
	if !direction_set:
		if !facing_right:
			animated_sprite_2d.position.x = 0
			animated_sprite_2d.flip_h = true
		else:
			animated_sprite_2d.position.x = 2
		direction_set = true
	
	if actor_detection_zone.can_see_player() and Input.is_action_just_pressed("Interact") and !opened:
		animated_sprite_2d.play("Open")
		spawn_item()
		opened = true
		label.visible = false
	
	if !opened:
		if actor_detection_zone.can_see_player():
			label.visible = true
		else:
			label.visible = false

func spawn_item():
	var spawn_collectible = load(collectible)
	var spawn_collectible_instance = spawn_collectible.instantiate()
	var world = get_tree().current_scene
	world.add_child(spawn_collectible_instance)
	spawn_collectible_instance.global_position.x = chest.global_position.x
	spawn_collectible_instance.global_position.y = chest.global_position.y - 10
