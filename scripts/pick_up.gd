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
	# try to grant powerup
# IMPORTANT: always pass auto_fire = false.
# We only want pickups to fill slots; shooting should only happen from player input.
	if body.has_method("push_powerup"):
		body.call("push_powerup", item_id, duration, false)
	else:
	# common case: the body is a child collider, but the player script is on the parent
		var p := body.get_parent()
		if p and p.has_method("push_powerup"):
			p.call("push_powerup", item_id, duration, false)

	queue_free()
