extends Node2D

@onready var text_box_sprite = $TextBoxSprite
@onready var text_label = $TextLabel
@onready var interact_label = $InteractLabel
@onready var actor_detection_zone = $ActorDetectionZone
@onready var close_label = $CloseLabel

var text_box_active = false

func _ready():
	text_box_sprite.visible = false
	text_label.visible = false
	interact_label.visible = false
	close_label.visible = false

func _process(_delta):
	if !text_box_active:
		text_box_sprite.visible = false
		text_label.visible = false
		close_label.visible = false
		if actor_detection_zone.can_see_player():
			interact_label.visible = true
		else:
			interact_label.visible = false
		
		if actor_detection_zone.can_see_player() and Input.is_action_just_pressed("Interact"):
			text_box_active = true
			GameData.player_movement_disabled = true
		
	else:
		interact_label.visible = false
		text_box_sprite.visible = true
		text_label.visible = true
		close_label.visible = true
		if Input.is_action_just_pressed("Interact"):
			text_box_active = false
			GameData.player_movement_disabled = false
