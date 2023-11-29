extends Control

enum{NONE, BOOMERANG, ARCHINGDISC, FIREBALL}

@onready var health_bar_icon_color_bg = $HealthBar/HealthBarIconColorBG
@onready var health_bar = $HealthBar/HealthBar
@onready var health_bar_full = $HealthBar/HealthBarFull
@onready var health_bar_empty = $HealthBar/HealthBarEmpty
@onready var stamina_bar = $StaminaBar/StaminaBar
@onready var stamina_bar_full = $StaminaBar/StaminaBarFull
@onready var stamina_bar_empty = $StaminaBar/StaminaBarEmpty
@onready var mana_bar = $ManaBar/ManaBar
@onready var mana_bar_full = $ManaBar/ManaBarFull
@onready var mana_bar_empty = $ManaBar/ManaBarEmpty
@onready var potion_ui_1 = $Potions/PotionUI1
@onready var potion_ui_2 = $Potions/PotionUI2
@onready var potion_ui_3 = $Potions/PotionUI3
@onready var potion_ui_4 = $Potions/PotionUI4
@onready var potion = $Potions/Potion
@onready var boomerang = $Abilities/Boomerang
@onready var arching_disc = $Abilities/ArchingDisc
@onready var fireball = $Abilities/Fireball
@onready var boss_label = $Boss1Healthbar/BossLabel
@onready var boss_1_health_empty = $Boss1Healthbar/Boss1HealthEmpty
@onready var bar_outline_1 = $Boss1Healthbar/BarOutline1
@onready var bar_outline_2 = $Boss1Healthbar/BarOutline2
@onready var bar_outline_3 = $Boss1Healthbar/BarOutline3
@onready var boss_1_health_full = $Boss1Healthbar/Boss1HealthFull
@onready var coins_label = $Coins/CoinsLabel
@onready var potion_ui_11 = $Coins/PotionUI11
@onready var potion_ui_33 = $Coins/PotionUI33
@onready var coins_label_2 = $Coins/CoinsLabel2
@onready var animated_sprite_2d = $Coins/AnimatedSprite2D
@onready var pause_overlay = $PauseOverlay

var health_bar_initial_size = 0
var stamina_bar_initial_size = 0
var mana_bar_initial_size = 0
var boss_1_health_bar_initial_size = 0

var paused = false : set = set_paused

func _ready():
	set_player_potions_ui()
	set_player_ability_ui()
	health_bar_initial_size = health_bar_full.size.x
	stamina_bar_initial_size = stamina_bar_full.size.x
	mana_bar_initial_size = mana_bar_full.size.x
	boss_1_health_bar_initial_size = boss_1_health_full.size.x
	GameData.health_updated.connect(update_interface)
	GameData.stamina_updated.connect(update_interface)
	GameData.mana_updated.connect(update_interface)
	GameData.potions_updated.connect(update_interface)
	GameData.ability_updated.connect(update_interface)
	GameData.player_dead.connect(update_interface)
	GameData.coins_updated.connect(update_interface)
	GameData.boss_1_activated.connect(update_interface)
	GameData.boss_1_health_updated.connect(update_interface)
	GameData.boss_1_now_dead.connect(update_interface)

func update_interface():
	if GameData.player_is_dead:
		disable_all_ui()
	else:
		health_bar_full.size.x = (health_bar_initial_size / GameData.player_max_health) * GameData.player_health
		stamina_bar_full.size.x = (stamina_bar_initial_size / GameData.player_max_stamina) * GameData.player_stamina
		mana_bar_full.size.x = (mana_bar_initial_size / GameData.player_max_mana) * GameData.player_mana
		boss_1_health_full.size.x = (boss_1_health_bar_initial_size / GameData.boss_1_max_health) * GameData.boss_1_health
		coins_label.text = "%s" % GameData.player_coins
		set_player_potions_ui()
		set_player_ability_ui()
	
	set_boss_ui()

func disable_all_ui():
	health_bar_icon_color_bg.visible = false
	health_bar.visible = false
	health_bar_full.visible = false
	health_bar_empty.visible = false
	stamina_bar.visible = false
	stamina_bar_full.visible = false
	stamina_bar_empty.visible = false
	mana_bar.visible = false
	mana_bar_full.visible = false
	mana_bar_empty.visible = false
	potion_ui_1.visible = false
	potion_ui_2.visible = false
	potion_ui_3.visible = false
	potion_ui_4.visible = false
	potion.visible = false
	boomerang.visible = false
	arching_disc.visible = false
	fireball.visible = false
	coins_label.visible = false
	potion_ui_11.visible = false
	potion_ui_33.visible = false
	coins_label_2.visible = false
	animated_sprite_2d.visible = false
	boss_label.visible = false
	boss_1_health_empty.visible = false
	boss_1_health_full.visible = false
	bar_outline_1.visible = false
	bar_outline_2.visible = false
	bar_outline_3.visible = false

func set_boss_ui():
	if GameData.boss_1_dead or !GameData.boss_1_active:
		boss_label.visible = false
		boss_1_health_empty.visible = false
		boss_1_health_full.visible = false
		bar_outline_1.visible = false
		bar_outline_2.visible = false
		bar_outline_3.visible = false
	elif GameData.boss_1_active and !GameData.player_is_dead:
		boss_label.visible = true
		boss_1_health_empty.visible = true
		boss_1_health_full.visible = true
		bar_outline_1.visible = true
		bar_outline_2.visible = true
		bar_outline_3.visible = true

func set_player_potions_ui():
	if GameData.player_potions == 3:
			potion.play("PotionFull")
	elif GameData.player_potions == 2:
		potion.play("PotionHalfFull")
	elif GameData.player_potions == 1:
		potion.play("PotionAlmostEmpty")
	else:
		potion.play("Empty")

func set_player_ability_ui():
	if GameData.player_ability == NONE:
		boomerang.visible = false
		arching_disc.visible = false
		fireball.visible = false
	if GameData.player_ability == BOOMERANG:
		boomerang.visible = true
		arching_disc.visible = false
		fireball.visible = false
	if GameData.player_ability == ARCHINGDISC:
		boomerang.visible = false
		arching_disc.visible = true
		fireball.visible = false
	if GameData.player_ability == FIREBALL:
		boomerang.visible = false
		arching_disc.visible = false
		fireball.visible = true

func set_paused(value):
	paused = value
	get_tree().paused = value
	pause_overlay.visible = value

func _unhandled_input(event):
	if event.is_action_pressed("Pause") and GameData.player_health > 0:
		self.paused = !paused

func _on_quit_button_down():
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
	get_tree().change_scene_to_file("res://Source/UI and Screens/Screens/main_menu.tscn")

func _on_resume_button_up():
	SoundPlayer.play_button_press_sound()
	self.paused = !paused
