extends StaticBody2D

@onready var collision_shape_2d = $CollisionShape2D
@onready var actor_detection_zone = $ActorDetectionZone

var platform_detected_player = false

func _process(_delta):
	if Input.is_action_pressed("Down") and Input.is_action_just_pressed("Jump") and platform_detected_player:
		collision_shape_2d.set_deferred("disabled", true)

func _on_actor_detection_zone_body_entered(_body):
	platform_detected_player = true

func _on_actor_detection_zone_body_exited(_body):
	platform_detected_player = false
	collision_shape_2d.set_deferred("disabled", false)
