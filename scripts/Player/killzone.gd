extends Area2D

@onready var timer: Timer = $Timer

# Inside killzone.gd
func _on_body_entered(body):
	if body == Global.playerbody:
		if body.has_method("die"):
			body.die()
		# DELETE ANY reload_current_scene() CALLS HERE
	

func _on_timer_timeout() -> void:
	get_tree().reload_current_scene()
