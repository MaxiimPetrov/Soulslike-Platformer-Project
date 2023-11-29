extends Control

@onready var tutorial_popup = $TutorialPopup
@onready var start = $VBoxContainer/Start
@onready var quit = $VBoxContainer/Quit

func _ready():
	get_tree().paused = false
	SoundPlayer.play_main_menu_music()

func _on_start_button_up():
	SoundPlayer.play_button_press_sound()
	start.disabled = true
	quit.disabled = true
	tutorial_popup.visible = true

func _on_quit_button_up():
	get_tree().quit()

func _on_yes_button_down():
	SoundPlayer.stop_main_menu_music()
	SoundPlayer.play_button_press_sound()
	get_tree().change_scene_to_file("res://Source/World/Levels/stage_1.tscn")

func _on_no_button_down():
	SoundPlayer.stop_main_menu_music()
	SoundPlayer.play_button_press_sound()
	get_tree().change_scene_to_file("res://Source/World/Levels/tutorial.tscn")
