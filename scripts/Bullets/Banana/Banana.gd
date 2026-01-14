extends Area2D

@export var speed: float = 400.0
@export var blast_radius: float = 250.0
@export var damage: int = 100
var direction: Vector2 = Vector2.RIGHT

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(_body: Node):
	explode()

func explode():
	# Find all enemies in a circle around the impact point
	var enemies = get_tree().get_nodes_in_group("Enemy")
	for enemy in enemies:
		if global_position.distance_to(enemy.global_position) < blast_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
	
	# Spawn explosion particles here if you have them!
	queue_free()
