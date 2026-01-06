extends Area2D

@export var item_id: String = "bomb"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.has_method("push_and_autoshoot"):
		body.call("push_and_autoshoot", item_id)
		queue_free()
