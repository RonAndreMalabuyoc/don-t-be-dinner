extends Area2D

@export var speed := 900.0
@export var lifetime := 2.0

var direction: Vector2 = Vector2.RIGHT

func setup(dir: Vector2) -> void:
	direction = dir.normalized()

func _ready() -> void:
	# Auto-destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _process(delta: float) -> void:
	position += direction * speed * delta
