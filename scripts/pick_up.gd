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

	# try to grant powerup (debug version)
	var granted := false

	if body.has_method("push_powerup"):
		print("calling push_powerup on BODY:", body.name)
		body.call("push_powerup", item_id, duration, true)
		granted = true

	elif body.get_parent() and body.get_parent().has_method("push_powerup"):
		print("calling push_powerup on PARENT:", body.get_parent().name)
		body.get_parent().call("push_powerup", item_id, duration, true)
		granted = true

	else:
		print("ERROR: No push_powerup found on body or parent. body script = ", body.get_script())

	if granted:
		queue_free()
	else:
		_collected = false
