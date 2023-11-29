extends Camera2D

var shake_amount : float = 0
var default_offset : Vector2 = offset

func _ready():
	set_process(false)
	GameData.camera = self

func _process(_delta):
	offset = Vector2(randf_range(-1, 1) * shake_amount, randf_range(-1, 1) * shake_amount)

func start_shake(amount):
	shake_amount = amount
	set_process(true)

func stop_shake():
	offset = Vector2.ZERO
	set_process(false)
