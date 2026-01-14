extends Area2D
@export var speed: float = 1200.0 # Very fast
@export var damage: int = 2        # Low damage
var direction: Vector2 = Vector2.RIGHT

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body: Node):
	if body.is_in_group("Enemy") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
