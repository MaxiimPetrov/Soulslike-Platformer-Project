extends Area2D

var player  = null
var area_ = null

func can_see_player():
	return player != null

func can_see_area():
	return area_ != null

func _on_body_entered(body):
	player = body

func _on_body_exited(_body):
	player = null

func _on_area_entered(area):
	area_ = area

func _on_area_exited(_area):
	area_ = null
