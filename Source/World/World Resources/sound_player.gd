extends Node

@onready var button_press = $ButtonPress
@onready var player_hurt = $PlayerHurt
@onready var player_dead = $PlayerDead
@onready var ability = $Ability
@onready var coin = $Coin
@onready var ability_pickup = $AbilityPickup
@onready var player_attack = $PlayerAttack
@onready var enemy_death = $EnemyDeath
@onready var potion = $Potion
@onready var stage_1_music = $Stage1Music
@onready var stage_1_boss_music = $Stage1BossMusic
@onready var boss_death = $BossDeath
@onready var player_dodge = $PlayerDodge
@onready var main_menu_music = $MainMenuMusic
@onready var tutorial_music = $TutorialMusic
@onready var shop_music = $ShopMusic

func play_button_press_sound():
	button_press.play()

func play_player_hurt_sound():
	player_hurt.play()

func play_player_dead_sound():
	player_dead.play()

func play_ability_sound():
	ability.play()

func play_coin_sound():
	coin.play()

func play_ability_pickup_sound():
	ability_pickup.play()

func play_player_attack_sound():
	player_attack.play()

func play_enemy_death_sound():
	enemy_death.play()

func play_potion_sound():
	potion.play()

func play_stage_1_music():
	stage_1_music.play()

func stop_stage_1_music():
	stage_1_music.stop()

func play_stage_1_boss_music():
	stage_1_boss_music.play()

func stop_stage_1_boss_music():
	stage_1_boss_music.stop()

func play_boss_death_sound():
	boss_death.play()

func play_player_dodge_sound():
	player_dodge.play()

func play_main_menu_music():
	main_menu_music.play()

func stop_main_menu_music():
	main_menu_music.stop()

func play_tutorial_music():
	tutorial_music.play()

func stop_tutorial_music():
	tutorial_music.stop()

func play_shop_music():
	shop_music.play()

func stop_shop_music():
	shop_music.stop()
