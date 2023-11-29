extends Area2D

@onready var timer_high = $TimerHigh
@onready var timer_middle = $TimerMiddle
@onready var timer_low = $TimerLow

var player_detected = false

var timer_high_started = false
var timer_middle_started = false
var timer_low_started = false

var world = null

func _ready():
	world = get_tree().current_scene

func _process(_delta):
	if player_detected:
		if !timer_high_started:
			timer_high.start()
			timer_high_started = true
		
		if !timer_middle_started:
			timer_middle.start()
			timer_middle_started = true
		
		if !timer_low_started:
			timer_low.start()
			timer_low_started = true
		
		if timer_high.time_left == 0 and timer_high_started:
			var flying_eye_constant = load("res://Source/Actors/Enemies/flying_eye_constant.tscn")
			var flying_eye_constant_instance = flying_eye_constant.instantiate()
			world.add_child(flying_eye_constant_instance)
			flying_eye_constant_instance.global_position.x = GameData.player_position.x + 400
			flying_eye_constant_instance.global_position.y = 30
			if timer_high.wait_time == 3:
				timer_high.wait_time = 4
			elif timer_high.wait_time == 4:
				timer_high.wait_time = 5
			elif timer_high.wait_time == 5:
				timer_high.wait_time = 3
			
			timer_high_started = false
		
		if timer_middle.time_left == 0 and timer_middle_started:
			var flying_eye_constant = load("res://Source/Actors/Enemies/flying_eye_constant.tscn")
			var flying_eye_constant_instance = flying_eye_constant.instantiate()
			world.add_child(flying_eye_constant_instance)
			flying_eye_constant_instance.global_position.x = GameData.player_position.x + 400
			flying_eye_constant_instance.global_position.y = 130
			if timer_middle.wait_time == 3:
				timer_middle.wait_time = 4
			elif timer_middle.wait_time == 4:
				timer_middle.wait_time = 5
			elif timer_middle.wait_time == 5:
				timer_middle.wait_time = 3
			timer_middle_started = false
		
		if timer_low.time_left == 0 and timer_low_started:
			var flying_eye_constant = load("res://Source/Actors/Enemies/flying_eye_constant.tscn")
			var flying_eye_constant_instance = flying_eye_constant.instantiate()
			world.add_child(flying_eye_constant_instance)
			flying_eye_constant_instance.global_position.x = GameData.player_position.x + 400
			flying_eye_constant_instance.global_position.y = 220
			if timer_low.wait_time == 3:
				timer_low.wait_time = 4
			elif timer_low.wait_time == 4:
				timer_low.wait_time = 5
			elif timer_low.wait_time == 5:
				timer_low.wait_time = 3
			timer_low_started = false
	else:
		timer_high_started = false
		timer_middle_started = false
		timer_low_started = false
		timer_high.stop()
		timer_middle.stop()
		timer_low.stop()

func _on_body_entered(_body):
	player_detected = true

func _on_body_exited(_body):
	player_detected = false
