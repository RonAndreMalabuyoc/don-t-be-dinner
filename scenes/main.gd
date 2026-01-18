extends Node

func _ready():
	Global.node_creation_parent = self
	
func _exit_tree():
	Global.node_creation_parent = null
	


func _on_pause_pressed() -> void:
	get_tree().paused = true 


func _on_quit_pressed() -> void:
	get_tree().quit()
