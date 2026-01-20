extends CharacterBody2D

@export var speed := 450.0
@export var damage := 8

var direction := Vector2.ZERO

func setup(dir: Vector2, new_speed: float, dmg: int) -> void:
	direction = dir.normalized()
	speed = new_speed
	damage = dmg
	velocity = direction * speed

func _physics_process(_delta: float) -> void:
	move_and_slide()

func _on_area_2d_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
