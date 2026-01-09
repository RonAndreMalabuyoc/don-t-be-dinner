extends Area2D

@export var speed := 950.0
@export var damage := 8
@export var lifetime := 1.8

var _dir := Vector2.RIGHT

func setup(dir: Vector2, _target_pos: Vector2) -> void:
	_dir = dir.normalized()
	rotation = _dir.angle()

func _ready() -> void:
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _process(delta: float) -> void:
	global_position += _dir * speed * delta
