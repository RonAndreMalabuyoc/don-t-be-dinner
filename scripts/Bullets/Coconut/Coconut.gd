# Coconut.gd
extends Area2D

@export var damage: int = 35
@export var proj_gravity: float = 950.0

var velocity: Vector2 = Vector2.ZERO

# Track enemies we've already damaged (piercing, no double hits)
var hit_list: Array[Node] = []

func _ready() -> void:
	# Auto-connect signals so it works even if the scene has no connections.
	var c_body := Callable(self, "_on_body_entered")
	if not body_entered.is_connected(c_body):
		body_entered.connect(c_body)

	var c_area := Callable(self, "_on_area_entered")
	if not area_entered.is_connected(c_area):
		area_entered.connect(c_area)

func setup(dir: Vector2) -> void:
	# Toss it up slightly for the arc
	velocity = (dir + Vector2.UP * 0.4).normalized() * 700.0

func _physics_process(delta: float) -> void:
	velocity.y += proj_gravity * delta
	position += velocity * delta
	rotation = velocity.angle()

func _on_body_entered(body: Node) -> void:
	_try_damage(body)

func _on_area_entered(area: Area2D) -> void:
	_try_damage(area)

func _try_damage(hit: Node) -> void:
	var target: Node = hit

	# If we hit an enemy child (like a Hitbox Area2D), try its parent
	if not target.is_in_group("Enemy") and target.get_parent():
		if target.get_parent().is_in_group("Enemy"):
			target = target.get_parent()

	# Must be an enemy
	if not target.is_in_group("Enemy"):
		return

	# Piercing: don't hit the same enemy twice
	if target in hit_list:
		return

	# Apply damage using what your enemies actually implement
	if target.has_method("take_damage"):
		target.call("take_damage", damage)
		hit_list.append(target)
		return

	if target.has_method("hit"):
		target.call("hit", damage)
		hit_list.append(target)
		return

	if "current_health" in target:
		target.current_health -= damage
		hit_list.append(target)
		return
