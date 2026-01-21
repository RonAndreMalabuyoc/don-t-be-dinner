extends Node

var node_creation_parent = null  # Add this line!
var max_health: float = 30.0
var current_health: float = 100.0
var player_alive: bool = true
var playerbody: CharacterBody2D

# Function to handle damage from ANY source
func take_damage(amount: float):
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	
	# Signal the UI to update
	# (We'll assume you have a signal or method to refresh the bar)
	
	if current_health <= 0 and player_alive:
		if is_instance_valid(playerbody) and playerbody.has_method("die"):
			playerbody.die()

func instance_node(scene: PackedScene, location: Vector2, parent: Node) -> Node:
	var inst := scene.instantiate()
	parent.add_child(inst)
	if inst is Node2D:
		inst.global_position = location
	return inst
