extends Area2D

@export var item_id: String = "fruit"
@export var duration: float = 5.0

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("push_powerup"):
		print("Picked up:", item_id)
		body.call("push_powerup", item_id, duration, true)
		get_parent().queue_free() # removes the whole pickup
	print("Touched by:", body.name)
