extends Control

func _on_button_button_down():
	SoundPlayer.stop_stage_1_boss_music()
	SoundPlayer.stop_stage_1_music()
	SoundPlayer.stop_shop_music()
	SoundPlayer.stop_tutorial_music()
	SoundPlayer.play_button_press_sound()
	GameData.player_is_dead = false
	GameData.player_health += GameData.player_max_health
	GameData.player_stamina = GameData.player_max_stamina
	GameData.player_mana = 0
	GameData.player_coins = 0
	GameData.player_potions = 3
	GameData.player_max_health = 100
	GameData.player_max_stamina = 100
	GameData.player_max_mana = 100
	GameData.boss_1_health = GameData.boss_1_max_health
	GameData.boss_1_active = false
	GameData.player_spawn_position = Vector2(-95, 288)
	await SoundPlayer.button_press.finished
	get_tree().change_scene_to_file("res://Source/UI and Screens/Screens/main_menu.tscn")
