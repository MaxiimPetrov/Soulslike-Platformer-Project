extends Node2D

@onready var player = $Player
@onready var camera = $Camera


func _ready():
	player.connect_camera(camera)

func _process(_delta):
#	GameData.camera.shake(5)
	pass
