extends Area2D

@onready var timer = $Timer

@export var timer_wait_time : float
var timer_started = false

func _ready():
	timer.wait_time = timer_wait_time

func _on_area_entered(_area):
	GameData.player_movement_disabled = true
	timer.start()
	timer_started = true

func _process(_delta):
	if timer.time_left == 0 and timer_started:
		GameData.player_movement_disabled = false
		queue_free()
