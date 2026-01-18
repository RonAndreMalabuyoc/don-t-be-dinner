extends Node

func _ready():
	Global.node_creation_parent = self
	
func _exit_tree():
	Global.node_creation_parent = null
	


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MAIN.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_pause_button_pressed() -> void:
	get_tree().paused = true
