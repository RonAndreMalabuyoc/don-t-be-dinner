# Coconut.gd
extends Area2D

@export var damage: int = 35
@export var proj_gravity: float = 950.0 
var velocity: Vector2 = Vector2.ZERO
var hit_list: Array = [] # Tracks who we already hit so we don't hit them twice

func setup(dir: Vector2):
	# Toss it up slightly for the arc
	velocity = (dir + Vector2.UP * 0.4).normalized() * 700.0

func _physics_process(delta):
	velocity.y += proj_gravity * delta
	position += velocity * delta
	rotation = velocity.angle()

func _on_body_entered(body):
	if body.is_in_group("Enemy") and not body in hit_list:
		body.take_damage(damage)
		hit_list.append(body) 
		# No queue_free() = Piercing!
