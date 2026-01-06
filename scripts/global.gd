extends Node

var playerbody: CharacterBody2D
var playerWeaponEquip: bool = true # Default to true for a shooter
var node_creation_parent: Node = null
var player_alive := true # <--- ADD THIS

func instance_node(scene: PackedScene, location: Vector2, parent: Node) -> Node:
	var inst := scene.instantiate()
	parent.add_child(inst)
	if inst is Node2D:
		inst.global_position = location
	return inst
