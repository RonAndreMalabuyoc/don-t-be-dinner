extends Area2D

@export var item_id: String = "orange"
@export var duration: float = 5.0

func _on_body_entered(body: Node) -> void:
	if body.has_method("push_powerup"):
		body.call("push_powerup", item_id, duration, true)
		queue_free()
