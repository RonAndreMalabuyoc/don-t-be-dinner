extends Node2D

@export var explosion_scene: PackedScene

func setup(_dir: Vector2, target_pos: Vector2) -> void:
	global_position = target_pos

func _ready() -> void:
	if explosion_scene:
		var e := explosion_scene.instantiate()
		if e is Node2D:
			e.global_position = global_position
		get_tree().current_scene.add_child(e)

	queue_free()
