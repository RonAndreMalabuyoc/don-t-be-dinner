extends Area2D

@export var speed := 600
@export var lifetime := 2.0

var direction := Vector2.RIGHT

func _ready():
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _process(delta):
	position += direction * speed * delta
