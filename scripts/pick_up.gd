extends Area2D

@export var item_id: String = "bomb"
@export var duration := 5.0

func _on_body_entered(body):
	if body.has_method("push_powerup"):
		body.call("push_powerup", item_id, duration, true)
		queue_free()
