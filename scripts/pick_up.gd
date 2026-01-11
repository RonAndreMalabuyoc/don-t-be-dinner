extends Area2D

@export var item_id: String = "fruit"
@export var duration: float = 5.0

var _collected := false

func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	_collected = true

	print(item_id, "touched by:", body.name, " path:", body.get_path())
	print("pickup is:", name, " path:", get_path())

	# try to grant powerup
	if body.has_method("push_powerup"):
		body.call("push_powerup", item_id, duration, true)
	else:
		# common case: the body is a child collider, but the player script is on the parent
		var p := body.get_parent()
		if p and p.has_method("push_powerup"):
			p.call("push_powerup", item_id, duration, true)

	queue_free()
