extends Node2D

@onready var interact_label = $InteractLabel
@onready var actor_detection_zone = $ActorDetectionZone
@onready var text_box_sprite = $TextBoxSprite
@onready var text_label = $TextLabel
@onready var close_label = $CloseLabel
@onready var health_upgrade = $"."

var interacted = false

func _ready():
	interact_label.visible = false
	text_box_sprite.visible = false
	text_label.visible = false
	close_label.visible = false

func _process(_delta):
	if !interacted:
		if actor_detection_zone.can_see_player():
			interact_label.visible = true
		else:
			interact_label.visible = false
		if actor_detection_zone.can_see_player() and Input.is_action_just_pressed("Interact"):
			GameData.player_movement_disabled = true
			text_box_sprite.visible = true
			text_label.visible = true
			close_label.visible = true
			interacted = true
	else:
		interact_label.visible = false
		if Input.is_action_just_pressed("Interact"):
			text_box_sprite.visible = false
			text_label.visible = false
			close_label.visible = false
			GameData.player_movement_disabled = false
			interacted = false
		if Input.is_action_just_pressed("Buy") and GameData.player_coins >= 5:
			text_box_sprite.visible = false
			text_label.visible = false
			close_label.visible = false
			GameData.player_movement_disabled = false
			GameData.player_max_health += 25
			GameData.player_coins -= 6
			var coin_collectible = load("res://Source/World/World Resources/Collectibles/coin_collectible.tscn")
			var coin_collectible_instance = coin_collectible.instantiate()
			var world = get_tree().current_scene
			world.add_child(coin_collectible_instance)
			coin_collectible_instance.global_position.x = health_upgrade.global_position.x
			coin_collectible_instance.global_position.y = health_upgrade.global_position.y - 5
			queue_free()
