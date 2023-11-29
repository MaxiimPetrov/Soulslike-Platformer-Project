extends CharacterBody2D

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var off_screen_timer = $OffScreenTimer
@onready var hitbox = $Hitbox

var speed = 200
var velocity_set = false
var fireball_collided = false

func _ready():
	if GameData.player_facing_left:
		hitbox.position.x = -15
	off_screen_timer.start()

func _physics_process(_delta):
	if fireball_collided:
		hitbox.get_node("CollisionShape2D").disabled = true
	if off_screen_timer.time_left == 0:
		queue_free()
	if not velocity_set and not fireball_collided:
		if GameData.player_facing_left:
			animated_sprite_2d.flip_h = true
			velocity.x = -speed
		else:
			velocity.x = speed
		velocity_set = true
	move_and_slide()

func _on_hitbox_area_entered(_area):
	SoundPlayer.play_player_attack_sound()
	fireball_collided = true
	animation_player.play("Explosion")
	animated_sprite_2d.scale.x = 0.08
	animated_sprite_2d.scale.y = 0.08
	velocity.x = 0

func suicide():
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
