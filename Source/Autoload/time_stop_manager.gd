extends Node

func stop_time():
	if GameData.player_is_dead:
		Engine.time_scale = 0.2
	else:
		Engine.time_scale = 0.6
		await get_tree().create_timer(0.1, true, false, true).timeout
		Engine.time_scale = 1
