# Coconut.gd
extends Area2D

@export var damage: int = 35
@export var proj_gravity: float = 950.0
var velocity: Vector2 = Vector2.ZERO
var hit_list: Array = [] # Tracks who we already hit so we don't hit them twice


func _ready() -> void:
	# Ensure we collide with enemies (most enemies are on physics layer 2).
	# Mirror BreadBullet defaults so this works out of the box.
	monitoring = true
	monitorable = true
	if collision_layer == 1:
		collision_layer = 15
	if collision_mask == 1:
		collision_mask = 15

	# Coconut scene doesn't wire the signal by default, so do it in code.
	var be := Callable(self, "_on_body_entered")
	if not is_connected("body_entered", be):
		connect("body_entered", be)


func setup(dir: Vector2):
	# Toss it up slightly for the arc
	velocity = (dir + Vector2.UP * 0.4).normalized() * 700.0


func _physics_process(delta):
	velocity.y += proj_gravity * delta
	position += velocity * delta
	rotation = velocity.angle()


func _on_body_entered(body):
	if body.is_in_group("Enemy") and not body in hit_list:
		if body.has_method("take_damage"):
			body.take_damage(damage)
		hit_list.append(body)
		# No queue_free() = Piercing!
