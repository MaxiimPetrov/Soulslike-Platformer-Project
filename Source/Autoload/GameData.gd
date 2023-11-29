extends Node

enum{NONE, BOOMERANG, ARCHINGDISC, FIREBALL}

signal health_updated
signal stamina_updated
signal mana_updated
signal potions_updated
signal ability_updated
signal player_dead
signal coins_updated
signal boss_1_activated
signal boss_1_health_updated
signal boss_1_now_dead

var camera : Camera2D

var blood_effect_in_scene = false

var player_facing_left = false

var player_max_health = 100
var player_health = player_max_health : set = set_health

var player_max_stamina = 100
var player_stamina = player_max_stamina : set = set_stamina

var player_max_mana = 100
var player_mana = player_max_mana : set = set_mana

var player_max_potions = 3
var player_potions = player_max_potions : set = set_potions
var player_potions_saved = 3 : set = set_player_potions_saved

var player_ability = NONE : set = set_player_ability
var player_coins = 0 : set = set_player_coins
var player_coins_saved = 0 : set = set_player_coins_saved

var player_attack_upgrade_received = false : set = set_player_upgrade_received

var player_position = Vector2.ZERO : set = set_player_position
var player_spawn_position = Vector2(-95, 288) : set = set_player_spawn_position
var can_save_checkpoint = false : set = set_can_save_checkpoint
var player_can_kneel = false : set = set_player_can_kneel
var player_movement_disabled = false : set = set_player_movement_disabled

var player_is_dead = false : set = set_player_dead

var boss_1_active = false : set = set_boss_1_activated 
var boss_1_max_health = 100
var boss_1_health = boss_1_max_health : set = set_boss_1_health
var boss_1_dead = false : set = set_boss_1_dead

func set_health(value):
	player_health = value
	
	if player_health > player_max_health:
		player_health = player_max_health
	if player_health < 0:
		player_health = 0
	
	emit_signal("health_updated")

func set_stamina(value):
	player_stamina = value
	
	if player_stamina > player_max_stamina:
		player_stamina = player_max_stamina
	if player_stamina < 0:
		player_stamina = 0
	
	emit_signal("stamina_updated")

func set_mana(value):
	player_mana = value
	
	if player_mana > player_max_mana:
		player_mana = player_max_mana
	if player_mana < 0:
		player_mana = 0
	
	emit_signal("mana_updated")

func set_potions(value):
	player_potions = value
	
	if player_potions > player_max_potions:
		player_potions = player_max_potions
	if player_potions < 0:
		player_potions = 0
	
	emit_signal("potions_updated")

func set_player_ability(value):
	player_ability = value
	
	emit_signal("ability_updated")

func set_player_position(value):
	player_position = value

func set_player_can_kneel(value):
	player_can_kneel = value

func set_can_save_checkpoint(value):
	can_save_checkpoint = value

func set_player_spawn_position(value):
	player_spawn_position = value

func set_player_dead(value):
	player_is_dead = value
	emit_signal("player_dead")

func set_player_coins(value):
	player_coins = value
	emit_signal("coins_updated")

func set_player_movement_disabled(value):
	player_movement_disabled = value

func set_boss_1_activated(value):
	boss_1_active = value
	emit_signal("boss_1_activated")

func set_boss_1_health(value):
	boss_1_health = value
	emit_signal("boss_1_health_updated")

func set_boss_1_dead(value):
	boss_1_dead = value
	emit_signal("boss_1_now_dead")

func set_player_coins_saved(value):
	player_coins_saved = value

func set_player_potions_saved(value):
	player_potions_saved = value

func set_player_upgrade_received(value):
	player_attack_upgrade_received = value
