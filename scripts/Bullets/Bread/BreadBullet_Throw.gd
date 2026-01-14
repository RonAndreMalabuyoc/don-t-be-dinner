extends Area2D
class_name Bullet

@export var speed: float = 800
@export var damage: int = 10
var direction: Vector2 = Vector2.RIGHT
@export var lifetime: float = 3.0

func _ready():
	monitoring = true
	monitorable = true
	connect("body_entered", Callable(self, "_on_body_entered"))
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body: Node):
	# Only hit enemies
	if body.is_in_group("Enemy") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
