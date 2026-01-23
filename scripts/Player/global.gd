extends Node

var node_creation_parent = null  # Add this line!
var max_health: float = 30.0
var current_health: float = 100.0
var player_alive: bool = true
var playerbody: CharacterBody2D

var health: int = 30
var run_time: float = 0.0
var enemies_defeated: int = 0
var waves_survived: int = 0
var current_score: int = 0

func reset_run_stats():
	run_time = 0.0
	enemies_defeated = 0
	waves_survived = 0
	current_score = 0
	# Reset health for fresh start
	if "max_health" in playerbody:
		health = playerbody.max_health
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
